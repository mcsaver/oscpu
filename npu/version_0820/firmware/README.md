# 固定 RV64 NPU service firmware（ABI v1.3）

该目录把原先由宿主 C++ 为每个 GGML 节点临时拼出的 RV64 程序，收敛为一份可重复构建、固定装载地址的
service firmware。固件本身不解析 `command.bin` 的 64-byte 文件头，也不处理 metadata/relocation；
Host Runtime 完成验证和重定位后，只把每条命令的 30 个 little-endian `uint64_t` payload word 搬入
NC SDRAM command 区。

## 地址与所有权

- firmware load/entry：`0x80000000`，最大 4 KiB；
- mailbox：`0xA0000000`，64 bytes；
- command records：`0xA0000100`，每条 240 bytes；
- completion records：`0xA0100000`，每条 64 bytes；
- pre/post DMA copy table：`0xA0200000`，每条 48 bytes；
- RTL DMA MMIO：`0xA0300000`，src/dst/bytes/start/status；
- 最大 batch：4368 条，命令区恰好在 completion 区之前结束。

`0xA0000000` 属于当前 RV64 RTL 的 SDRAM window，`OooTypedPmaChecker` 将它分类为
`OOO_MEM_CLASS_NC`。仿真 Host Runtime 仍需把这个区间接到 DPI memory callback；不能把 mailbox
退回 `0x80000000` 的 cached PMEM。

mailbox 的 64-byte 布局由 `npu_service_mailbox_abi.h` 冻结：

| offset | field | type | owner/含义 |
| ---: | --- | --- | --- |
| 0 | magic | u32 | `0x4d55504e`（内存字节为 `NPUM`） |
| 4/6 | abi_major/minor | u16/u16 | 当前 `1.3` |
| 8 | state | u32 | `FREE/READY/RUNNING/DONE/ERROR` |
| 12 | count | u32 | 本 batch 的 record 数 |
| 16 | command_stride | u32 | v1 必须为 240 |
| 20 | reserved0 | u32 | bit 0 为 RAW_COPIES，其余 bit 必须为 0 |
| 24 | generation | u64 | Host 每次提交的非零、单调换代标识；同一 boot 内不得复用 |
| 32 | command_base | u64 | v1 必须为 `0xA0000100` |
| 40 | completion_base | u64 | v1 必须为 `0xA0100000` |
| 48 | completed | u32 | Firmware release-publish 的完成数 |
| 52 | error | u32 | mailbox/精确 NPU fault 错误码 |
| 56 | boot_count | u64 | 每次从 reset entry 启动递增 |

completion record 保存 `generation/index/status`，并从 descriptor word 2/3/4 原样回传
`sequence_id/producer_id/user_tag`。ABI 1.1 将原先保留的最后 24 bytes 定义为：

| offset | field | type | 含义 |
| ---: | --- | --- | --- |
| 40 | fault_tval | u64 | 失败时原始 `mtval`；成功为 0 |
| 48 | fault_pc | u64 | 失败时原始 `mepc`；成功为 0 |
| 56 | fault_cause | u64 | 失败时原始 `mcause`；成功为 0 |

`status=0` 表示成功，`status=1` 表示一条 recoverable NPU fault completion，`status=2` 表示
已精确归属但要求 reset 的 fatal NPU fault completion。NPU 失败记录也计入 `mailbox.completed`，
因此在第 `index` 条命令失败后发布的值是 `index + 1`；该记录是终止记录，同一 batch 的后续命令
不会执行。

## 单生产者协议

1. Host 只在 `FREE`、`DONE` 或 `ERROR` 时写 command/completion/header，先写 payload 和所有
   header 字段，最后以 release 语义写 `READY`。每次提交必须使用非零且不同于上一次已接受提交的
   `generation`。
2. Firmware 轮询 `READY`，执行 acquire fence，验证 magic/version/stride/count/固定地址，
   再检查 `generation != 0 && generation > last_generation`。只有全部验证成功、即将进入
   `RUNNING` 时才更新内部 `last_generation`；随后清 `completed/error`，并以 release 顺序发布
   `RUNNING`。
3. 设置 RAW_COPIES 时先完成本命令 pre-DMA，再执行同一段静态 `30 × (LD, NOP, CONFIG, NOP)`，随后执行唯一且 8-byte 对齐的相邻
   `0x0220305b / 0x0bf0305b` LO/HI pair。
4. LO/HI 是一个精确 ROB-owned Tensor transaction。只有 matching NPU terminal 成功并退休后，
   Firmware 才执行 post-DMA；DMA DONE 后写 completion record、release-publish `completed`，再处理下一条命令。
5. 列表结束后 release-publish `DONE` 并继续轮询下一次 `READY`；不重启 CPU，也不重新生成代码。

## ABI 1.3 的 RTL DMA

copy table 的每条记录为六个 little-endian u64：
`pre_src/pre_dst/pre_bytes/post_src/post_dst/post_bytes`。长度为零的 triple 不启动 DMA。
Host 在发布 READY 前完成全部 capability、范围、权限、地址溢出和不重叠检查。

| MMIO offset | 字段 | 含义 |
| ---: | --- | --- |
| 0 | src | 原始字节源地址 |
| 8 | dst | 原始字节目的地址 |
| 16 | bytes | 原始字节长度 |
| 24 | start | 写 1 提交 |
| 32 | status | bit 0 busy、bit 1 done、bit 2 error |

Firmware 通过普通 committed MMIO store 配置 `TensorNpuServiceDma`，轮询 DONE/ERROR；
没有 CPU raw-copy 循环。仿真 MMIO bridge 只驱动 RTL 配置和端口输入，DMA 的真实
request/response 才能移动 arena 原始字节。每次新 START 清除旧 DONE，最后 write response
被消费后才发布新的 DONE。DMA error 发布 mailbox ERROR / code 11，不发布该命令的成功
completion；Host Runtime 保留整代 private output，不暴露已完成的前缀。

Runtime 独立验证 pre/post copy 顺序、exact-once START/DONE、实际 masked-write 字节数、
registered capability 以及 DMA 与 NPU 不并发竞争同一命令数据。
组件背压、对齐和错误测试由 `check-npu-service-dma` 运行；完整 Firmware + DMA 的原子发布
与精确恢复测试由 `check-npu-model-artifact` 运行。

## 精确 NPU fault 与恢复

Firmware 在启动时设置 direct-mode `mtvec`，并在寄存器中维护 trap re-entry guard。CPU 对已拥有的
Tensor/NPU transaction 报错时使用同步 `mcause=24`，`mtval` v1 布局为：

| bits | 含义 |
| --- | --- |
| 63 | fatal/reset-required |
| 62:56 | 基础 NPU error code |
| 55:48 | 完整 CPU ProducerId |
| 47:40 | Tensor opclass |
| 39 | npu_required |
| 38 | 64-bit logical command |
| 37:32 | fault payload version，当前必须为 1 |
| 31:0 | logical command 的低 32-bit（paired macro 的 LO） |

只有 `mcause=24` 且 `mtval[37:32]=1`、fatal bit 为 0 才能走 recoverable 路径。Handler 先保存原始
`mcause/mtval/mepc`，再执行唯一的 `0x0be04fdb`：这是 CONFIG index 30、`rs1=x0` 的无值 clear
命令。它与主循环中从 `t2/x7` 读取 descriptor value 的 30 条 CONFIG 不同；PairOwner 接受单字
CONFIG，SystemTop 的 index-30 分支不读取 `rs1` value。CONFIG-30 自身也是精确 Tensor 指令，只有
NPU clear terminal 成功后才会继续执行。

clear 成功后，Handler 写入失败 completion 的精确
`generation/index/sequence_id/producer_id/user_tag/status/fault_*`，发布 `error=NPU_FAULT` 和
`state=ERROR`，把 `mepc` 改为 mailbox poll 后才 `mret`。因此失败的 LO/HI pair 永远不会被重执行；
Host 可用更大的 generation 提交下一批命令，而无需 reset。

若 `mcause/version` 有效但 `mtval[63]=1`，Handler 不发 CONFIG-30，但仍先写 status=2 的精确
completion（包含原始 identity 和 fault fields），再发布 `error=NPU_FATAL`、`state=ERROR` 并永久
自旋。unexpected trap 或 clear re-entry 的当前 command 上下文不再可信，只发布 mailbox fatal。
以下任一情况最终都以 reset 作为唯一出口：

- `mtval[63]=1`，NPU 明确要求 reset；
- trap cause 不是 24，或 fault payload version 不是 1；
- CONFIG-30 clear 自身再次 trap。re-entry guard 保证不会递归执行第二次 clear。

## v1.3 的明确边界

- v1.3 是 polling、single-producer firmware；尚无 queue/doorbell IRQ。
- mailbox 格式错误会写 `error` 并进入 `ERROR`，Host 修复内容后可以重新发布 `READY`。
- generation 为 0、重复或小于本次 boot 内最后接受值会得到 `BAD_GENERATION`；固件不会
  进入 CONFIG block，因此重复写 `READY` 不会重放旧 command。reset 会开启新的 boot epoch，
  Host 还应结合 `boot_count` 区分 reset 前后的 completion。
- recoverable NPU terminal fault 可跨 batch 恢复；fatal NPU fault、unexpected trap 和 clear
  自身失败明确要求 reset，不允许 Host 把 `ERROR` 改回 `READY` 后继续使用同一 boot。
- Runtime 必须在发布 `READY` 前完成 artifact 校验、relocation、buffer/IOMMU window 建立；
  Firmware 不会重新验证 descriptor 内的业务字段。
- v1 不做 graph optimize、fusion、tiling 或 memory planning；这些属于上游 NPU Compiler。

## 构建与检查

在 `runtime/llama-npu-backend` 的 CMake build tree 中：

```sh
cmake --build <build-dir> --target npu-rv64-service-firmware
cmake --build <build-dir> --target test-npu-rv64-service-firmware
```

前者用 stock `riscv64-linux-gnu-gcc/objcopy` 生成 ELF、flat binary 和可供 C++ Runtime
嵌入的 header；后者先用 `riscv64-linux-gnu-objdump` 检查 ELF entry，再验证
entry/address/容量、anti-ABA generation gate、30 个唯一有序 CONFIG index、既有
`LD/NOP/CONFIG/NOP` 调度形状以及 LO/HI 的唯一、相邻、对齐关系。静态镜像测试还检查
ABI 1.1 fault 字段、`mtvec/mcause/mtval/mepc/mret` CSR 路径、re-entry/cause/version/fatal gate
全部汇聚到 `NPU_FATAL`，以及独立且唯一的 CONFIG-30 `rs1=x0` clear。
