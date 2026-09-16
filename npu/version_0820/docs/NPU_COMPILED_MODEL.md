# 真实 Qwen 的 NPU Compiler / Host Runtime / 固定 Firmware 路径

当前真实模型入口为 `libggml-npu-model.so`。它接收 llama.cpp 实际建立、分配 storage 的
GGML NPU dispatch，在 launch 前完成整个子图的准离线编译，再由独立的 Host Runtime
重新读取三份产物并提交。一代包含 1080 条 NPU command，仍有 1080 次真实硬件 launch；
没有把批量提交称为算子融合。

`libggml-npu-compiled.so` 的 artifact v3 / P00 验证入口继续用于边界回归；旧
`libggml-npu.so` 保留作为既有基线。实际模型 runner 显式加载唯一的
`libggml-npu-model.so`，禁止 required tensor 进入 CPU backend。

## 数据流和生命周期

```text
llama.cpp 加载原始 GGUF，实际建立 bootstrap / steady GGML 图
    ↓ strict canonical graph admission，1080 required nodes exact-cover
NPU Compiler（整个 dispatch，一次编译）
    ├─ command.bin：64-byte header + 1080 × 240-byte 未重定位 command
    ├─ weights.bin：原始 Q8_0 / F32 / F16 权重字节
    └─ metadata.json：owner、identity、ledger、BufferId、relocation、DMA、publication
    ↓ Host Runtime 重新读取并验证 SHA-256 / bounds / permissions
dispatch-private arena + relocated command records + launch descriptor
    ↓ 发布 NC mailbox READY，generation 严格递增
同一个 RV64 SystemTop / 同一份固定 Firmware
    └─ 每条：pre-DMA → 静态 30 CONFIG → 固定 LO/HI → terminal → post-DMA → completion
    ↓ 整代 completion、identity、实际端口 ledger 全闭合
原始字节发布到 GGML output / recurrent state / KV state
    ↓ 后端 ARGMAX 产生真实 token，llama.cpp 建立下一代图
```

CPU Host 负责元数据处理、原始输入装载和最终字节发布；RV64 Firmware 负责控制流、DMA
寄存器配置和 NPU 指令提交。Tensor 的 Q8 反量化、量化、乘加、F32 运算、范数、
Attention、状态运算和 ARGMAX 均由既有 RTL owner 执行。

## Compiler

实现位于 `compiler/npu-model-compiler.inc` 和 `compiler/npu-model-*-profiles.cpp`。
前端复用冻结的 canonical GGML descriptor 匹配规则；独立的 profile 文件只保留整数
形状推导、workload 和 command contract 构造，不链接旧 per-node executor。

每个 compute node 必须精确匹配一个 owner family：

| Family | 执行范围 |
| --- | --- |
| Q8 get-rows | 从原始 Q8_0 embedding 表取行 |
| Q8 GEMV | Q8 权重的线性层 |
| F32 ALU | ADD、MUL、SCALE 及冻结的 zero-cardinality profile |
| F32 mover | GET_ROWS、REPEAT |
| exact remaining | 范数、UNARY/GLU、SSM、SUM_ROWS、CPY、SET_ROWS、ROPE、F16 Attention、SOFT_MAX 等 |
| sampler ARGMAX | 严格 greedy 的设备端 token 选择 |

无法匹配、匹配多个 owner、缺失 canonical binding 或命令数不等于 required 覆盖时，
编译失败，不提交部分子图。

内存规划先解析 VIEW 的 storage root，再合并真实 GGML allocator 的重叠区间，保留
in-place reuse 和 state alias。权重保持只读；普通 binding 与 transient 使用
dispatch-private arena。目的窗口与所有源窗口不相交时直接写 private logical buffer；
可能相交时使用串行共享的 command destination。局部写入先 DMA 保留旧目的内容，
成功 terminal 后再 DMA 更新 logical buffer。空命令不产生字节搬运。

steady 图的空 SCALE VIEW 可能位于合并分配区内部。零长度 source window 以实际数据
地址所在的对齐位置为 base；Runtime 验证这个位置属于注册分配区，而非强制等于分配区
起点。该 capability 仍授予零字节权限，RTL 的冻结空 profile 必须以零端口读写完成。

`command.bin` 沿用中性 ABI 1.1：所有地址和窗口基址模板 word 为零。metadata relocation
只允许修改 word 10/11/12/13/23/26/28，并以 BufferId 索引和 addend 表示地址。
模板中不保存 host 指针。当前 Compiler 提供 IOVA 规划，Runtime 校验 capability 后解析
重定位；还没有通用 target allocator、跨设备地址分配或权重重排搜索。

模型产物使用独立 schema `npu-compiled-model-v1`，不冒充 Python P00 工具的
`npu-artifact-bundle-v3`。每代的目录为 `artifacts/dispatch-N/`。当前准离线入口在
实际 storage 分配后编译整代；没有独立全模型离线 CLI 或跨代编译缓存。

## Host Runtime

`npu-model-artifact.cpp` 接收产物目录、预期 metadata SHA-256、外部 raw binding 和
persistent session。它重新读取文件，验证 metadata identity、command/weight 完整
SHA-256、command header、relocation 许可和范围、capability overlap/permission、
command identity、DMA copy 范围和 publication 范围。

Runtime 在私有 arena 中装载输入和权重，提交完整命令流；任何 preflight、硬件、
timeout 或 completion 错误都不发布输出。只有整代成功后才将 publication 指定的
output/state 原始字节复制回 GGML buffer。文件和 descriptor 预检错误指出失败的文件、
command 或 ABI word；硬件执行失败补充 command index、原图 index、节点名、canonical ID、
generation、completed 和可用的精确 fault CSR。

`npu-system-session` 为所有 family 提供原始 GMEM、Q8、F32 ALU、F32 mover 和 DMA
端口模型。模型只响应真实 accepted request，不做数值运算。每条 terminal 都检查
完整 identity 和独立的 request/response/byte/MAC/vector/state ledger。
实际总线读出的 8-byte beat 与某些 owner 的语义 read-byte 计数分别核对。

## 固定 Firmware 和真实 RTL DMA

service mailbox ABI 当前为 1.3；command 文件 ABI 仍为 1.1。完整协议见
[firmware/README.md](../firmware/README.md)。

| 地址 | 用途 |
| --- | --- |
| `0x80000000` | 固定 RV64 Firmware entry，当前 image 1224 bytes |
| `0xa0000000` | 64-byte launch mailbox |
| `0xa0000100` | 30-word command records |
| `0xa0100000` | completion records |
| `0xa0200000` | 每命令 48-byte pre/post DMA copy table |
| `0xa0300000` | DMA MMIO：src、dst、bytes、start、status |

`TensorNpuServiceDma.v` 是原始字节 DMA 引擎。它保持请求到 ready，按对齐位置产生
masked writes，等待 write response 后才 DONE；读错、写错、地址溢出和重叠范围均报错。
Firmware 只通过提交后的 MMIO store 配置引擎和轮询 completion，没有 RV64 tensor
copy 循环。SystemTop 的仿真 MMIO bridge 只驱动 RTL 的寄存器输入，真实字节搬运由
该 RTL 的 memory request 完成。

LO/HI 仍经过真实 CPU PairOwner / ROB / NPU 生命周期。recoverable NPU fault 保存
原始 `mcause=24/mtval/mepc`，执行唯一 CONFIG-30 clear 后发布 ERROR；fatal fault
明确要求 reset。不能通过隐式重建 SystemTop 掩盖错误。

## 运行与可审计验收

使用当前已配置的 build tree：

```sh
bash scripts/run_qwen_compiled_model.sh
```

也可指定新的输出目录。脚本拒绝覆盖已有目录，在 build、真实生成和全部证据校验完成后
才写 `STATUS=PASS`。完整运行需要已构建的冻结 llama.cpp 和正确 bootstrap/steady
canonical manifest；首次配置可设置 `NPU_BOOTSTRAP_MANIFEST` /
`NPU_STEADY_MANIFEST`。CMake 的通用默认示例路径不能替代实际冻结 manifest。

固定模型与生成条件：

- `models/Qwen3.5-0.8B-Q8_0.gguf`；
- SHA-256：`37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f`；
- llama.cpp source commit：`95c409c13625a23da2aa37270339ce9179215a18`；
- raw prompt `x`，prompt token `87`，batch/ubatch 1、context 256、Flash Attention 关闭；
- seed 1、temperature 0、top-k 1、backend sampling、生成两 token；
- 冻结 oracle 要求 token IDs 精确为 `[283, 220]`。

`qwen_compiled_model_validate.py` 同时要求两代真实 dispatch 各完成 1080 个 required
node、每条 command 的 launch/terminal 顺序和 cardinality 精确相同、constructor/reset/boot
始终为 1、fallback/host tensor arithmetic/coverage/error 计数全零、所有产物 SHA-256
仍一致。只执行模型前缀、只出现命令 PASS、只有 admission 或只回放 manifest 均不能通过。

相关最小回归：

```sh
cmake --build <build-dir> --target check-npu-model-artifact check-npu-service-dma
cmake --build <build-dir> --target check-npu-command-abi check-npu-compiled-bundle-system \
  check-npu-host-runtime-system check-npu-compiled-backend test-npu-rv64-service-firmware
```

model artifact 测试覆盖真实 Firmware + DMA 的跨命令依赖、跨代复用、文件损坏、
非法 relocation、capability overlap、只读权重写入、publication 越界、成功前缀后精确
fault 不发布、无 reset 恢复，以及分配区内部空 VIEW 的错误窗口拒绝和零读写完成。DMA 组件测试覆盖 64 种对齐组合、4 种长度、背压、
延迟 response、零长度、重叠、读错和写错。

另有 `test-npu-model-argmax <真实产物目录> <临时目录>`，直接复用完整模型 Compiler
生成的最后一条 ARGMAX command，检查 248,320 元素的原始 GMEM 读取、4-byte publication、
并列最大值和唯一最大值。冻结 GGML 的并列规则为选择最后一个索引；该测试在单次 boot
中完成两代。它只补充末尾 owner 的接口与数值合同验证，不替代真实模型 token 验收。

完整真实模型验收已通过，运行目录为
`tmp/npu-compiled-model-run-20260909-j/`，`STATUS=PASS`，实际 prompt token 为
`[87]`，实际生成 token 精确为 `[283, 220]`。

| 实际 dispatch | Required commands | RTL cycles | DMA copy records | Publication records |
| --- | ---: | ---: | ---: | ---: |
| 1 / bootstrap | 1080 | 365874323 | 428 | 52 |
| 2 / steady | 1080 | 343776789 | 392 | 52 |

两代共享一次 SystemTop constructor、一次 reset release 和一次 Firmware boot。两次
strict audit 均闭合 1080 个 required nodes；coverage missing/duplicate/hash mismatch、
completion identity mismatch、unsupported、RTL/GMEM/timeout error、
CPU fallback attempt 和 Host tensor arithmetic 均为零。两个独立的命令文件分别保存
bootstrap 和 steady lowering，weights SHA-256 相同。

可审计证据：

- [独立验证器结果](../tmp/npu-compiled-model-run-20260909-j/result.json)；
- [完整真实运行日志](../tmp/npu-compiled-model-run-20260909-j/run.log)和
  [验证器日志](../tmp/npu-compiled-model-run-20260909-j/validation.log)；
- [实际模型身份](../tmp/npu-compiled-model-run-20260909-j/model-identity.json)、
  [进程实际映射的文件哈希](../tmp/npu-compiled-model-run-20260909-j/mapped-project-files.json)、
  [输入完整性复核](../tmp/npu-compiled-model-run-20260909-j/input-integrity-check.log)；
- `artifacts/dispatch-1/` 和 `artifacts/dispatch-2/` 下的 command、weights、metadata；
- `binaries/` 下保存的实际后端、CLI 和 Firmware 快照，以及 `source-hashes.json`。
  运行结束后复核的 133 个相关源文件哈希均未变化。

这次真实生成修复了 steady 图空 SCALE VIEW 位于合并分配区内部时的窗口定位错误。
实际第二代 36 条空 SCALE 都保留了硬件 launch/terminal，零读写合同由端口 ledger
验证；没有通过删除 required node 或放宽非空访问范围完成运行。

本验收范围为上述冻结 Qwen 模型、batch/ubatch 1、context 256、unfused/nonflash、
greedy 两 token。当前不声明通用模型支持、长上下文或长文本验收，也未实现跨代编译缓存
或算子融合。
