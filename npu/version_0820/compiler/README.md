# NPU Compiler

完整模型入口是 `compiler/npu-model-compiler.inc`：在实际 llama.cpp GGML dispatch 分配 storage 后
准离线编译全部 1080 required nodes，输出 `npu-compiled-model-v1` metadata 与 command/weights。
其六类 owner、内存规划、真实 Firmware DMA 和完整模型运行方法见
[完整模型 Compiler/Runtime 路径](../docs/NPU_COMPILED_MODEL.md)。

以下文档描述保留的 Python artifact v3 / P00 边界回归工具；该 schema 与全模型 metadata 独立。

# Python compiler artifact v3

这一目录先冻结编译器与 runtime 之间的可验证边界。它不在 host 上执行任何 tensor
计算；权重只作为原始字节装入 `weights.bin`，哈希只用于控制完整性。

编译输出恰好是三个文件：

- `command.bin`：64-byte little-endian header，后接 `N * (30 * u64)` 的固定记录；
- `weights.bin`：每个权重对象的起始 offset 至少 64-byte 对齐，可按完整字节去重；
- `metadata.json`：唯一 canonical JSON 编码，绑定两个二进制文件的完整长度和 SHA-256，
  并保存 source/GraphIR provenance、buffer、command identity/workload、publication 和 relocation 表。

输入 schema 必须精确为 `npu-compiler-graph-v3`，输出 metadata schema 必须精确为
`npu-artifact-bundle-v3`；v2 输入、v2 metadata 和 command ABI 1.0 都会被 fail-closed
拒绝。artifact schema v3 的 command ABI 与历史 service 合同标识保持 1.1。
当前 Host Runtime 使用 Firmware mailbox ABI 1.3 提交兼容的 30-word records；
v3 本身没有全模型 pre/post DMA metadata。

v3 的 `provenance` 被 `bundle_id` 覆盖，并且必须 exact-cover 所有 command node 与 artifact
buffer。source 同时绑定 manifest 和 GraphIR 的 schema/hash、raw source hash、profile、source commit
与 graph scope。node binding 分开保存：

- `manifest_graph_index`；
- `source_schedule_position` 与 artifact 内从 0 连续的 `artifact_schedule_position`；
- canonical source ID；
- `source_descriptor_sha256` 与最终 `command_descriptor_sha256`。

buffer binding 同时保存 logical tensor origin 和 normalized storage-root origin、各自 descriptor hash、
alias offset、logical size 与 storage size。offset-zero VIEW 因而仍是一个 artifact capability，但不会丢失
它来自 VIEW 节点、实际 storage 来自 root 节点的事实。Python compiler 与 C++ loader 对同一 exact-key
schema 做对称验证。`bundle_id` 是无密钥完整性 hash，不是签名；调用方仍必须固定预期 manifest/GraphIR
identity，才能防止攻击者整体替换三件套并重新计算所有 hash。

## `command.bin` header

| Offset | Type | 字段 |
|---:|---|---|
| `0x00` | `u8[8]` | magic `NPUCMD\0\0` |
| `0x08` | `u16` | ABI major，固定为 1 |
| `0x0a` | `u16` | ABI minor，固定为 1 |
| `0x0c` | `u16` | header bytes，固定 64 |
| `0x0e` | `u16` | record bytes，固定 240 |
| `0x10` | `u32` | command count |
| `0x14` | `u32` | flags，ABI 1.1 必须为 0 |
| `0x18` | `u64` | payload bytes，必须等于 `count * 240` |
| `0x20` | `u8[32]` | payload SHA-256 |

每条 30-word record 与当前 `npu-verilator-exact-runner.cpp` 的 macro descriptor
一一对应。模板内的地址 word 保存 addend；`metadata.json` relocation 只能修改以下字段：

- `iova64`：word 10、11、12、13；
- `window_base64`：word 23、26、28。

同一 command word 只能有一条 relocation。加载器会拒绝未知 buffer、越界 addend、
base/addend 溢出、非对齐 base 和非许可的 buffer overlap。weight 去重只允许相同
offset、相同 size、相同内容哈希的精确 alias。

ABI 1.1 要求 10/23、11/26、13/28 三组 address/window-base relocation 成对且绑定同一
buffer；word 12 只能显式 alias 已声明的 src0/src1/dst window。当前 30-word wire ABI
没有 scratch window，因此 word 14 和 word 17 高 32-bit `scratch_bytes` 必须为零。

编译和加载还会按 command 顺序证明 transient read-before-write。对 src0、src1 的每个
transient read window，其全部 byte 必须已由严格更早 command 的 destination window 写入；
同一 command 的 destination 只有在 source 检查之后才计入，不能为自身读提供初始化。
多个早期 destination window 可以合并覆盖，但任何 gap、越界、零长度或 u64 overflow 都会
fail closed。word 12 的 `src2` 没有独立 window；它 alias 到哪个已声明 window，该 window
若属于 transient 就按同样规则视为读。Python compiler 与 C++ bundle loader 都执行这项检查，
因此重新计算 artifact/hash 也不能让未初始化 transient 进入 runtime。

## command identity、workload 与 cycle 上界

v3 每条 graph command 必须声明 `owner`、`workload` 和 `cycle_upper_bound`。当前可执行
owner 只接受 `f32_alu`，并与 kernel `0x514e0010` 双向绑定，不允许 runtime 再按形状猜测
owner。`cycle_upper_bound` 是正的 u64；编译器和加载器还会用 checked addition 验证所有
command 上界之和可由 u64 表示，runtime 可直接以该和设置整批提交的超时上界。

metadata 的十字段 `identity` 不由 graph 重复提供，而是在 node count/hash 注入以及
relocation addend 归一化完成后，直接从最终 30-word descriptor 模板派生：

| Identity 字段 | Descriptor 来源 |
|---|---|
| `kernel_id` | word 0 low 32-bit |
| `command_flags` | word 0 high 32-bit |
| `context_id` | word 1 low 32-bit |
| `sequence_id` | word 2 |
| `producer_id` | word 3 |
| `user_tag` | word 4 |
| `covered_node_count` | word 5 low 32-bit |
| `node_hash_lo` | word 6 |
| `node_hash_hi` | word 7 |
| `local_profile` | word 9 low 32-bit |

加载时会再次从 `command.bin` 派生并逐字段比较，metadata 中任何 identity substitution
即使重新计算了 `bundle_id` 也会被拒绝。word 5 high 的 `vector_op` 和 word 1 high 的
`capability_epoch` 继续由完整 descriptor SHA-256 绑定，不在 completion identity 中重复。

`f32_alu` 的 workload schema 固定为 `f32-alu-v1`，除 `schema` 外恰好包含：
`request_groups`、`response_groups`、`read_groups`、`write_groups`、`input_words`、
`output_words`、`read_bytes`、`write_bytes`、`completion_vector_elements` 和
`expected_starts`。所有计数都是严格 u64（JSON boolean 不算 integer），并满足：

- `request_groups == read_groups + write_groups`，加法不得溢出；
- `response_groups == request_groups`；
- `read_bytes == input_words * 4`、`write_bytes == output_words * 4`，乘法不得溢出；
- `expected_starts <= 1`；为 0 时其余九个 ledger 计数必须全部为 0。

内置两命令 fixture 的每条 workload 是
`4,4,2,2,32,16,128,64,16,1`，每条 `cycle_upper_bound` 是 `100000`。

## bundle-atomic publication

graph v3 必须提供严格排序的 `publications`；metadata 将它们放入
`publication={"mode":"bundle_atomic","entries":[...]}`，并在 `runtime.service_abi`
中固定 `{major:1,minor:1}`。每个 publication entry 恰好包含 `buffer_id`、
`source_offset`、`target_offset` 和 `bytes`，排序键为
`(buffer_id,target_offset,source_offset,bytes)`。

publication 只允许引用 permissions 精确为 `w` 的 `output` buffer。source 与 target
range 都必须落在对应 buffer 内，并分别对每个 output 形成 `[0,size)` 的无 gap、无
overlap 完备覆盖；每个 output 都必须至少出现一次。runtime 因而可以把所有结果保留在
private shadow，待整批 completion/identity/workload 全部闭合后按 entries 一次性发布，
中途失败时不暴露部分 tensor。内置 fixture 只有一项：将 `output` 的 private bytes
`[0,64)` 发布到 public target `[0,64)`。

## 命令行

生成可读的两命令输入 fixture：

```sh
python3 -m compiler.npu_compile --emit-tiny-graph /tmp/tiny-npu-graph.json
```

编译 fixture 或实际 low-level graph：

```sh
python3 -m compiler.npu_compile /tmp/tiny-npu-graph.json -o /tmp/npu-bundle
python3 -m compiler.npu_compile --tiny -o /tmp/npu-bundle
```

从 exact Qwen manifest 与 GGUF 原始权重编译第一个真实 P00 单节点 slice：

```sh
python3 -m compiler.npu_compile \
  --qwen-manifest /path/to/dispatch.manifest.json \
  --canonical-node 1e3dac5ab4a21eb84d4d473de864ce2aa3129e1d4f248ee44d766549a51e6f3f \
  --model /path/to/Qwen3.5-0.8B-Q8_0.gguf \
  --output-dir /tmp/qwen-p00-bundle
```

该 production slice 要求 exact owner coverage，拒绝 structural fixture；它选择 manifest graph index 30、
source schedule position 15，保留 node29 VIEW -> node28 storage root，并按 external index 8 与完整 tensor
descriptor 从 GGUF 精确读取 `blk.0.ssm_dt.bias` 的 64 个原始 bytes。它不做 host F32 arithmetic、cast 或
weight 重排。compiler 生成后立即调用 `load_bundle()` 自校验。该产物现已自动绑定完整 manifest 回放的
GGML descriptor 图，并在同一次固定 firmware/SystemTop boot 中执行两代；此结果不代表完整模型 token。

runtime 必须先调用等价于 `load_bundle()` 的逻辑闭合验证三件套，再注册运行时
buffer base 并应用 relocation。relocation 后会重新计算 `command.bin` 内部 payload
hash；metadata 继续描述不可变的未重定位模板，避免 metadata 与 command header 形成
循环哈希依赖。

## 当前 GGML compiled backend vertical slice

`runtime/llama-npu-backend` 现在提供独立的 `libggml-npu-compiled.so`，与 legacy
`libggml-npu.so` 并存。compiled module 不链接 per-node `npu-verilator-runner` 或生成的
profile header，而是只经 `npu-host-runtime` 执行 compiler artifact。调用方通过动态
backend registry 取得 versioned proc。以下 v1 手工流程用于 synthetic fixture；canonical artifact 使用下文 v2 自动入口：

1. `plan_load_v1(backend, bundle_dir)` 加载并严格验证 artifact；
2. `plan_bind_node_v1(...)` 按 artifact node id 绑定 GGML tensor 指针和完整图 index；
3. `plan_bind_buffer_v1(...)` 精确绑定每个 BufferId、tensor offset 和完整 byte size；weight
   和 transient 也必须绑定，不能只提供外部 input/output；
4. `plan_seal_v1(backend, full_graph)` 接收 scheduler 切分前的完整 GGML graph，验证
   command/node/source 顺序、relocation-to-tensor edge 和全图 transient consumer closure；
5. scheduler 分配 storage 后，NPU split 的第一次合法 `graph_compute()` 再验证完整图 snapshot、
   split 指针序列、storage range、weight identity 和 raw artifact，随后惰性创建 production
   Host Runtime；以后各代复用同一个 persistent runtime/SystemTop/固定 firmware；
6. `plan_clear_v1()` 或 backend destruction 撤销 admission 和 session。

bind/seal 的静态路径允许 `tensor->data == nullptr`，所以 `supports_op()` admission 不要求提前
分配 tensor。compute op 在 seal 前一律不被广告；seal 后也只接受精确绑定的 tensor 指针。
错误完整图、partial/wrong split、storage/weight 变化等 preflight 失败不会创建 runtime、不会
消费 generation，也不会通过 CPU tensor fallback 继续。

seal 会扫描完整图的所有 source edge：private transient 必须由更晚的已绑定 command 消费，
不能 fan-out 给 unbound/CPU node；没有后继的 bundle terminal 必须写 output。这项 GGML consumer
closure 与 artifact 的 byte-window read-before-write 是两层独立证明。

当前 backend v1 **只**接受 descriptor-compatible P00-shaped F32 ADD tiny slice：只允许 exact T16、
offset-zero metadata VIEW，不允许 broadcast、非零 tensor offset、任意其它 VIEW、独立 src2 或 scratch。
deterministic fixture 含两个 16-element ADD command，第一条从真实 VIEW edge 产生 private
`intermediate`，第二条消费它并 bundle-atomic 发布 `output`。整个 fixture 是 synthetic graph，不能称作
canonical Qwen P00。artifact ABI 能表达更多字段，不代表 GGML backend 已经支持其它 profile 或 owner。

集成测试由真实 GGML backend loader 动态加载 compiled DSO；测试端不直链 bundle/runtime/session。
测试先在 no-alloc 完整图上 seal，再由 GGML scheduler 形成一个显式 CPU-prefix/NPU-bundle split，
分配 storage 并连续执行两个 generation。CPU prefix 是图中刻意保留的前置 CPU 节点，不是 NPU
节点失败后的 fallback。可用以下 target 复验：

```sh
cmake --build /path/to/npu-backend-build \
  --target check-npu-compiled-backend -j1
```

这个 PASS 只证明 synthetic P00-shaped vertical slice 的编译 artifact、GGML admission/split、Host Runtime、固定
RV64 firmware 与 NPU F32 portal 端到端闭合，不代表真实 Qwen 已经生成或输出 token。


## Canonical graph binding and launch API v2

真实 compiler artifact 使用 `load_v1 -> bind_graph_v2 -> launch_v2 -> audit_v2`。
调用方提供 bundle 目录、exact manifest 路径和 scheduler 切分前的完整 GGML graph。
`bind_graph_v2` 自动解析 node/BufferId 映射并 seal；调用方不再手工绑定每个节点或 buffer。
所有 proc 均由 registry 查询，声明见 `npu-compiled-backend-api.h`；必须检查 proc 和调用返回值，
失败时读取 `plan_last_error_v1`，不得继续 CPU tensor 运算。

绑定会核对 manifest 原始字节与 source identity、整图及 external descriptor（name/op/type/ne/nb/flags/
op_params）、source edges、canonical node ID、manifest graph index、source schedule，以及 logical VIEW
与 storage root。v1 手工 node/buffer binding 和 seal 禁止用于 canonical artifact。
绑定时允许未分配 storage；graph/tensor 必须保持存活。每次 launch 重新验证完整图与 external descriptor，
之后检查 storage 和 weight bytes，失败不创建 runtime、不消耗 generation、不发布 output。

`launch_v2` 仅执行 compiler 明确选择的子图，外部输入由调用方事先准备，执行链不调用 GGML CPU backend。
通过 scheduler 提交完整 canonical 图时，所有 required compute node 保留 NPU admission，artifact 未覆盖的
节点返回含 graph index/name/op 的精确错误。单个 P00 artifact 不能把其余 required node 静默转交 CPU。

`plan_audit_v2` 提供实际 SystemTop constructor/reset/boot、NPU launch/terminal/start 和 portal traffic
计数。运行时失败信息包含 generation、command index、canonical ID、completion status 与原始
mcause/mtval/mepc。当前 F32 portal 的 wire word 8 必须为 **0**；`cycle_upper_bound=9072` 留在 metadata
作为 Host 有界等待合同。两个 loader 均拒绝误写为非零 deadline 的 artifact，即使其所有 hash 自洽。
RTL capability 和 timeout 校验保持有效。

复验需要冻结 profile 对应的原始 manifest 和 GGUF；同名旧 manifest 不一定匹配 source identity：

```sh
cmake -S runtime/llama-npu-backend -B /path/to/backend-build \
  -DNPU_COMPILED_CANONICAL_MANIFEST=/path/to/exact/dispatch.manifest.json \
  -DNPU_COMPILED_CANONICAL_MODEL=/path/to/Qwen3.5-0.8B-Q8_0.gguf
cmake --build /path/to/backend-build --target check-npu-compiled-canonical -j4
```

该 target 重新编译 bundle，动态加载 compiled DSO 后执行两代 P00。第二代改变 input，结果逐位对比独立
测试 oracle；要求 constructor/reset/boot 各为 1。错误 VIEW 名称、weight stride、storage root、source edge、
weight bytes、seal 后 producer op_params，以及用局部 artifact 调度完整图都必须失败。

测试完整 GGML descriptor 图来自 exact manifest 回放，未执行模型其余节点。这证明真实 P00 artifact 的
compiler/runtime/firmware 执行闭合，不代表 live llama 图捕获、完整模型 codegen 或 token loop。

## Canonical Qwen manifest → GraphIR

`qwen_graph_ir.py` 是 GGML manifest 与上述低层 artifact compiler 之间的前端边界：

```sh
python3 -m compiler.qwen_graph_ir /path/to/dispatch.manifest.json \
  -o /tmp/qwen.graph-ir.json
```

导入器先验证 canonical JSON、envelope/payload SHA-256、连续 graph/external index、
所有 canonical node identity、descriptor/source identity，以及每一条 node source 的
拓扑顺序。随后排除 634 个 metadata operation（它们仍以 buffer alias 保留），按原始
拓扑输出 1080 个 compute/mover GraphIR node。

生产模式不会自行重写 owner 表，而是联合调用现有 profile oracle 的公开审计入口；
冻结的 Qwen3.5-0.8B v5 manifest 必须形成以下无交集完备分区：

| Lowering family | Node count | Authority |
|---|---:|---|
| `f32_alu` | 367 | `qwen_f32_alu_profiles.audit_manifest_object` |
| `q8_get_rows` | 1 | remaining-owner 的 exact partition + singleton adapter |
| `q8_gemv` | 187 | `qwen_q8_gemv_profiles.audit_q8_gemv_manifest` |
| `f32_gather_repeat` | 91 | `qwen_f32_gather_repeat_profiles.audit_manifest` |
| `remaining` | 433 | `qwen_remaining_profiles.audit_manifest_object` |
| `sampler_argmax` | 1 | `qwen_sampler_argmax_profile.audit_manifest_object` |

每个 GraphIR node 保留 canonical ID、GGML source edges、稳定 `BufferId` 和 lowering
family/profile，但所有 IOVA 都明确为 `unresolved`。这个 Python GraphIR import 本身不融合节点、
不规划内存，也不生成 30-word command descriptor；其 v3 codegen 回归仍限定为第一个真实 P00。
不能把 1080-node GraphIR import 成功等同于完整模型执行成功。

实际全模型由独立的 C++ 准离线入口 `npu-model-compiler.inc` 生成 1080-node command、
完整 weights 和 `npu-compiled-model-v1` metadata；表中的六个 owner 已接入
`libggml-npu-model.so`。该路径及两 token 验收状态见
[完整模型路径](../docs/NPU_COMPILED_MODEL.md)。运行脚本显式选择该 DSO，旧 backend 保留作为基线。

默认快速测试使用仅含一个 P00 ADD 和一个 metadata VIEW 的 canonical 小 fixture：

```sh
python3 -B tests/test_qwen_graph_ir.py -v
```

真实 1714-node manifest 的 opt-in exact-cover 测试：

```sh
NPU_QWEN_GRAPH_MANIFEST=/path/to/dispatch.manifest.json \
  python3 -B tests/test_qwen_graph_ir.py -v
```

`--structural-fixture` 只允许用于小 fixture 的 parser/identity 测试；它只调用公开
F32 profile matcher，不能用于生产 artifact codegen。
