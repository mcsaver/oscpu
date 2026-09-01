# Q8_0 stream GEMV RTL 合同

> **实现阶段合同。** 本文冻结 `TensorNpuQ8StreamGemv` 的 module-level transaction、FSM、计数和失败语义。它是 Q8_0 权重 × 单个 F32 activation vector 的内部 NPU stream primitive，不是 GMEM/LMEM command、ggml backend PASS 或 Qwen token PASS 证据。禁止综合、STA、PPA、host/DPI 浮点代算和 CPU required-op fallback。

数值语义继承 [`Q8_0_RTL_SEMANTICS.md`](Q8_0_RTL_SEMANTICS.md)：activation 每 32 项由 `TensorNpuQ8ReferenceQuantizer` 量化，row dot 由 `TensorNpuQ8ScaleAccumulator` 按 b10507 portable generic 的 block 地址顺序执行。不得改用 FP16 scale 反算 activation `id`、FMA contraction、跨 block reduction tree或 host double accumulator。

## 1. 固定模型事实与范围

固定输入是 `models/Qwen3.5-0.8B-Q8_0.gguf`：

```text
size   = 833592096
sha256 = 37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f
GGUF   = v3, little-endian, tensors=335
dtype  = Q8_0:195, F32:140
```

项目内固定 `gguf_dump.py --json` 观测到 Q8_0 tensor shape/count：

| `[ne0,ne1]` | count | `K/32` blocks |
|---:|---:|---:|
| `[1024,16]` | 36 | 32 |
| `[1024,512]` | 14 | 32 |
| `[1024,2048]` | 18 | 32 |
| `[1024,3584]` | 50 | 32 |
| `[1024,4096]` | 7 | 32 |
| `[1024,6144]` | 18 | 32 |
| `[1024,248320]` | 1 | 32 |
| `[2048,1024]` | 26 | 64 |
| `[3584,1024]` | 25 | 112 |

因此该模型的 Q8_0 reduction 维 `K=ne0` 只出现 1024、2048、3584，最大为 112 blocks。4096、6144、248320 是输出行数 `M=ne1`，不得误当成 K。默认 `MAX_BLOCKS=128` 覆盖当前最大 K 并保留 16-block 余量；这不是对其它模型的无限 capability。

本 primitive 只实现：

```text
A: Q8_0 [K,M], x: F32 [K], y: F32 [M]
y[m] = portable_q8_0_dot(A[:,m], reference_quantize_q8_0(x))
```

它不实现 prompt `N>1` batch matmul、`MUL_MAT_ID`、bias/activation、GET_ROWS、任意 `ne[]/nb[]`、IOVA、DMA、LMEM 或 top-k。严格 runtime 固定 `-ub 1 -b 1` 后，每次 dense arithmetic graph 节点可按 N=1 使用该 primitive；这不消除其它 Qwen 算子闭包。

## 2. Module 接口

```systemverilog
module TensorNpuQ8StreamGemv #(
    parameter integer MAX_BLOCKS = 128,
    parameter integer MAC_LANES  = 8,
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd4096,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd1000000000
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [31:0]  row_count_i,
    input  wire [31:0]  block_count_i,

    input  wire         activation_valid_i,
    output wire         activation_ready_o,
    input  wire [31:0]  activation_bits_i,

    input  wire         weight_valid_i,
    output wire         weight_ready_o,
    input  wire [271:0] weight_block_i,

    output wire         result_valid_o,
    input  wire         result_ready_i,
    output wire [31:0]  result_bits_o,
    output wire [31:0]  result_row_index_o,

    output wire         done_o,
    output wire         error_o,
    output wire [7:0]   error_code_o,
    output wire [63:0]  active_cycles_o,
    output wire [31:0]  activation_words_accepted_o,
    output wire [63:0]  weight_blocks_accepted_o,
    output wire [31:0]  rows_emitted_o
);
```

`MAX_BLOCKS<1` 必须在 elaboration fail。正式默认只接受：

```text
row_count_i   >= 1
1 <= block_count_i <= MAX_BLOCKS
K = 32 * block_count_i
```

32×32 的 `row_count_i*block_count_i` 以完整 64-bit 计算；禁止截断后用于计数或终止判断。

## 3. Transaction 协议

- `ready_o` 仅在非 reset 的 IDLE 为 1；`start_i && ready_o` 接受命令并锁存 shape。
- busy 中的 `start_i` 不采样 shape、不重启 child、不改变 bank/counter。
- activation 按 block index递增，每个 block恰好接收 32 个 F32 raw word；`activation_ready_o` 只在当前 quantizer 的 LOAD32 credit有效时为 1。
- 成功量化的 272-bit block写入 `activation_block_bank[block_index]`；所有 activation block完成前，`weight_ready_o` 必须保持0。
- weight 按 `(row=0..M-1, block=0..B-1)` row-major输入。每次 `weight_valid_i && weight_ready_o` 把 weight block 与 `activation_block_bank[block]` 成对交给 `TensorNpuQ8ScaleAccumulator`。
- 每行只发布一个 F32 raw result。`result_valid_o && !result_ready_i` 时 result bits与row index保持稳定；不得为下一行覆盖。
- 最后一行 result handshake 后才进入单拍 DONE；ERROR同样单拍。terminal拍仍属于 busy，下一拍回 IDLE。
- 新命令接受时公开 result/counter/error清零。reset优先级最高，并取消两个 child 的 resident transaction；reset后禁止 stale response或result。

result stream 是 NPU 内部的**临时 transaction payload**，不是允许 CPU 读取全词表 logits 的 host 接口。若较晚一行出错，已发送给下游的早期行也属于 poisoned command，只有最终 DONE 才允许下游原子提交其聚合状态；ERROR 必须使下游丢弃该 command 的全部 provisional rows。未来 LM-head 必须把该 stream直接接 NPU top-k/argmax，CPU 最多接收最终不超过20个候选。

## 4. FSM 与 child 边界

固定父 FSM：

```text
IDLE
  -> QUANT_START
  -> QUANT_LOAD32
  -> QUANT_WAIT
  -> (QUANT_START for next block | ROW_START)
  -> WEIGHT_STREAM
  -> ROW_WAIT
  -> RESULT_HOLD
  -> (ROW_START for next row | DONE)
  -> IDLE

any validation/numeric/watchdog/internal failure -> ERROR -> IDLE
```

约束：

- `TensorNpuQ8ReferenceQuantizer` 每个 activation block一条 child command；父级只在 child DONE 捕获 block。
- `TensorNpuQ8ScaleAccumulator` 每个 output row一条 child command，`block_count_i` 为锁存 B；父级只在 child成功 terminal捕获 result。
- request state持有/重试直到 child ready；wait state才授予 response credit。父级错误拍同步 reset全部 child，防止 timeout后的 stale completion污染下一命令。
- quantizer child error编码为 `0x2q`，其中 `q` 是 child 4-bit error；accumulator child error编码为 `0x3a`。

其它错误码：

| code | 语义 |
|---:|---|
| `0x10` | `row_count_i==0` |
| `0x11` | `block_count_i==0` |
| `0x12` | `block_count_i>MAX_BLOCKS` |
| `0x40` | activation/quantizer progress stall |
| `0x41` | weight/accumulator progress stall |
| `0x42` | result consumer stall |
| `0x50` | whole-command timeout |
| `0xff` | illegal/internal state |

## 5. Counter 与 watchdog

- `active_cycles_o` 为 start接受边沿至 DONE/ERROR发布边沿的 launch-inclusive 周期数；只在 terminal锁定。
- `activation_words_accepted_o` 只在 activation handshake递增，成功必须等于 `32*B`。
- `weight_blocks_accepted_o` 只在 weight handshake递增，成功必须等于 `M*B`。
- `rows_emitted_o` 只在 result handshake递增，DONE时必须等于 M。
- command counter对包括外部背压在内的整个事务计数，达到 `COMMAND_TIMEOUT_CYCLES` 前未完成则 `0x50`。
- stall counter在父 state变化、任一 external handshake、child terminal或观测到下一 child credit时清零；否则递增。默认4096必须高于 quantizer/accumulator的合法 resident latency。按阶段分别报 `0x40/0x41/0x42`。
- watchdog failure清 `result_valid_o` 并取消 child；不产生 DONE，不伪增任何未发生的 handshake counter。

## 6. 数据通路与拓扑

```text
F32 activation stream
  -> TensorNpuQ8ReferenceQuantizer
  -> activation_block_bank[MAX_BLOCKS] (272 bits/entry)

Q8_0 weight stream + activation_block_bank[block]
  -> TensorNpuQ8ScaleAccumulator
  -> held F32 row result
  -> internal NPU result consumer
```

默认 bank 为 `128*272 = 34816` bits。只存 activation blocks，不缓存 weight matrix或全部 M 个 result。该串行拓扑以数值/事务可追踪性优先；本项目禁止综合、STA、PPA，因此不得给出面积、频率或 Pareto结论。

## 7. 定向 Verilator oracle

主正向 case固定 `M=2,B=2,K=64`：

Activation block 0 是 TV1：

```text
[-127,-64,-1,0,1,63,64,127, 24*0]
```

Activation block 1 是 32 个 `127.0f`。两者都量化成 half scale `0x3c00`；block 0 q等于TV1，block 1的32个q均为`0x7f`。

Weight row/block：

```text
row0 block0 = TV1
row0 block1 = scale 0x3c00, q[0..31]=+1
row1 block0 = scale 0x3800(+0.5), q[0..31]=+2
row1 block1 = scale 0xc000(-2.0), q[0..31]=+1
```

严格 block顺序结果：

```text
row0: 44421 + 4064 = 48485  -> FP32 0x473d6500
row1: 63 + (-8128) = -8065 -> FP32 0xc5fc0800
```

TB 必须再覆盖：

1. activation与weight随机化空泡、result至少3拍背压，payload/index稳定且输出顺序0、1；
2. busy activation/weight/terminal期间start被忽略；成功计数精确为64 words、4 blocks、2 rows；
3. row=0、block=0、block=129在任何 input/output handshake前fail；
4. late activation NaN/Inf传播quantizer错误；weight half scale NaN/Inf传播accumulator错误；均无success terminal；
5. reset分别取消真实 quantizer divider与accumulator在途事务，之后无stale result；
6. 小参数实例确定性触发activation/weight/result stall和whole-command timeout，检查error code、计数与child cancel；
7. 任一错误命令无 DONE；若已有 provisional row，ERROR使整条命令poison，TB下游模型必须丢弃；
8. 无 `real/shortreal`、DPI、host FP oracle、`NPU_ASSERT`、trace或waveform。

固定仿真配置是 Verilator `--binary --timing -O3 -Wall -Wno-fatal`、C++ `-O3 -DNDEBUG -march=native`，所有 build/log/cache/compiler temp只在项目 `tmp/`。精确通过 marker：

```text
[NPU-Q8-GEMV][PASS]
```

本 marker只证明 stream primitive；接入统一回归、DMA/LMEM、command ABI、真实 GGUF row向量与 strict backend audit前，不得报告 `GGML_OP_MUL_MAT` 或 Qwen token PASS。
