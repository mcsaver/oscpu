# Q8_0 GET_ROWS RTL 合同

> **实现阶段合同。** 本文冻结 b10507 `GGML_OP_GET_ROWS` 的 Q8_0→F32 数值、index/stride/address和分阶段 RTL 边界。Phase A 先实现一个 34-byte block 的 lane-stream dequant primitive；Phase B 再实现 I32 ids、row stride、GMEM跨线拼接与 destination row stream。任一阶段的 module PASS 都不等于 backend GET_ROWS、Qwen embedding或token PASS。禁止CPU/DPI数值代算、综合、STA和PPA。

固定 llama.cpp：b10507 commit [`95c409c13625a23da2aa37270339ce9179215a18`](https://github.com/ggml-org/llama.cpp/commit/95c409c13625a23da2aa37270339ce9179215a18)。

## 1. ggml tensor 映射

对Q8_0 source：

```text
src0 Q8_0 [D,V,I1,I2]
src1 I32  [N,I1,I2,1]
dst  F32  [D,N,I1,I2]
```

构造器要求：

```text
src1.type == I32
src1.ne3  == 1
src0.ne2  == src1.ne1
src0.ne3  == src1.ne2
D % 32    == 0
```

精确语义：

```text
id = src1[n,h1,h2]
require 0 <= id < V before any source-row read
dst[d,n,h1,h2] = dequant_q8_0(src0[d,id,h1,h2])
```

CPU row地址使用真实stride：

```text
src_row = src0_base + id*src0.nb1 + h1*src0.nb2 + h2*src0.nb3
idx     = idx_base  + n *src1.nb0 + h1*src1.nb1 + h2*src1.nb2
dst_row = dst_base  + n *dst.nb1  + h1*dst.nb2  + h2*dst.nb3
```

Q8 row内部要求 `src0.nb0==34`，但 `src0.nb1` 可以大于 packed payload `34*(D/32)`；row tail padding不得读取。若本地backend只支持packed row，必须对 padded `nb1` 返回unsupported，不能返回支持后按packed stride误读。

固定源码入口：

- [`ggml_get_rows`](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml.c#L3665-L3684)
- [`ggml_compute_forward_get_rows_q`](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/ops.cpp#L4524-L4564)
- [GET_ROWS dtype dispatch](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/ops.cpp#L4680-L4732)
- [loader no-alloc probe](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/src/llama-model-loader.cpp#L837-L870)

## 2. 单 block dequant 数值顺序

一个block为34 bytes：little-endian binary16 scale + 32个signed int8。reference语义：

```text
d32 = exact_fp16_to_fp32(block.d)
for lane=0..31:
    q32 = exact_signed_int8_to_fp32(block.qs[lane])
    out[lane] = RN32(q32 * d32)
```

没有累加、clamp、FMA或跨lane依赖。对任意finite binary16和int8 `[-128,127]`，乘积有效位不超过F32精度且范围不溢出，因此结果实际精确；正常路径不应产生任何fflags。

必须支持：

- raw `0x80=-128`；
- finite负scale；
- binary16 normal/subnormal；
- `+0/-0` scale与signed-zero结果。

signed-zero不能用“scale为零则整block写+0”替代。乘积零的符号为q符号与scale符号异或。例如：

```text
+0 * negative q -> -0
-0 * positive/zero q -> -0
-0 * negative q -> +0
```

b10507 CPU path没有拒绝Inf/NaN scale，但NaN payload/quieting不是跨编译器稳定raw contract。本项目v1选择更严格的资产/执行门禁：scale exponent全1立即ERROR，不发布任何lane；backend/load-time必须相同，不得声称支持后静默清洗。

参考源码：[`dequantize_row_q8_0`](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-quants.c#L516-L530)。

## 3. Phase A：`TensorNpuQ8DequantBlock`

```systemverilog
module TensorNpuQ8DequantBlock (
    input  wire         clk_i,
    input  wire         rst_i,
    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [271:0] block_i,

    output wire         lane_valid_o,
    input  wire         lane_ready_i,
    output wire [5:0]   lane_index_o,
    output wire [31:0]  lane_bits_o,
    output wire         lane_last_o,

    output wire         done_o,
    output wire         error_o,
    output wire [3:0]   error_code_o,
    output wire [15:0]  active_cycles_o
);
```

推荐拓扑：

```text
latched 272-bit block
  -> TensorNpuFp16ToFp32(scale)
  -> signed extend selected int8
  -> TensorNpuInt32ToFp32
  -> TensorNpuFp32AddMul(op_mul=1)
  -> held lane valid/ready
```

FSM：

```text
IDLE -> VALIDATE -> MUL_REQ -> MUL_WAIT -> LANE_HOLD
     -> (MUL_REQ next lane | DONE) -> IDLE
any error -> ERROR -> IDLE
```

不变量：

- start只在IDLE接受；busy start不改变resident block/lane；
- block在start handshake完整锁存，之后输入可变化；
- multiplier request valid/payload保持到ready，wait态才接response；
- lane backpressure期间index/bits/last稳定；
- lane handshake后才递增index；最后lane handshake后才DONE；
- scale nonfinite、multiplier NV/DZ/OF/UF/NX或nonfinite result均ERROR；
- ERROR/DONE单拍且busy，reset取消child与held lane，无stale response；
- 成功必须恰好32个lane handshake，lane index严格0..31。

Phase A 精确marker：

```text
[NPU-Q8-DEQUANT][PASS]
```

## 4. Phase A raw-bit oracle

### Oracle A：完整signed domain与负scale

Block 0：scale `+1.0h=0x3c00`：

```text
q[0..4] = [-128,-1,0,+1,+127]
expected = [c3000000,bf800000,00000000,3f800000,42fe0000]
```

Block 1：scale `-2.0h=0xc000`：

```text
q[0..3] = [-128,-1,+1,+127]
expected = [43800000,40000000,c0000000,c37e0000]
q[4..31]=0 -> each lane raw 80000000 (-0)
```

### Oracle B：half subnormal与zero sign

Scale `0x0001=2^-24`：

```text
q[0]=+64   -> 2^-18  = 36800000
q[1]=-128  -> -2^-17 = b7000000
```

Scale `-0=0x8000`：

```text
q[0]=-1 -> +0 = 00000000
q[1]= 0 -> -0 = 80000000
q[2]=+1 -> -0 = 80000000
```

TB还必须覆盖至少3拍lane背压稳定、busy start忽略、mid-multiply reset取消、scale Inf/NaN零lane发布、child fault/timeout fail-closed和精确32-lane计数。禁止`real/shortreal`、DPI或host浮点oracle。

## 5. Phase B：row gather / memory transaction

Phase B对每个固定 `(h1,h2)` slice发命令，至少包含：

```text
src_slice_base, idx_slice_base, dst_slice_base : u64
source_row_count V, index_count N               : u32
block_count=D/32                                : u16+
src_row_stride, idx_stride, dst_row_stride      : u64
```

FSM：

```text
IDLE -> FETCH_I32_ID -> SIGNED_RANGE_CHECK -> COMPUTE_ROW_BASE
     -> FETCH_34B_BLOCK -> DEQUANT32 -> NEXT_BLOCK/NEXT_ID
     -> DONE
```

signed id bounds check必须在任何source row GMEM request前完成。loader会用no-alloc I32 `[512]` probe；`supports_op`不得解引用dummy data，backend只有在能通过loop/tiling执行N=512时才可返回true。

34-byte block天然跨512-byte line。若Qwen embedding row从512B边界开始，block15起点为510：scale在510..511，q从512开始；block30起点1020并再次跨界。fetch engine必须按byte address拆分并合并，不得假设scale和q处于同一line。

### Phase B v1：`TensorNpuQ8GetRowsEngine` 冻结事务

v1 是固定 `(h1,h2)` slice 的 read-only gather core；outer slice loop、LMEM/DMA
destination write和backend tiling留给上层。为了让 invalid id、GMEM fault 或
任一 block 数值错误都不会泄漏部分 tensor，命令先预扫描全部 I32 ids，再读取
source rows；所有 dequant lane 先写入父级私有 output buffer，整条命令成功后
才开放 committed stream。

```text
parameters:
  MAX_D=1024
  MAX_IDS=16
  STALL_TIMEOUT_CYCLES=512
  COMMAND_TIMEOUT_CYCLES=1048576

command:
  clk_i, synchronous active-high rst_i
  start_i / ready_o / busy_o
  src_slice_base_i[63:0]
  idx_slice_base_i[63:0]
  gmem_floor_i[63:0], gmem_limit_i[63:0]  // [floor,limit)
  source_row_count_i[31:0]                // V
  index_count_i[$clog2(MAX_IDS+1)-1:0]    // N in 1..MAX_IDS
  element_count_i[$clog2(MAX_D+1)-1:0]    // D
  src_row_stride_i[63:0]
  idx_stride_i[63:0]

single-outstanding GMEM read:
  gmem_req_valid_o / gmem_req_ready_i
  gmem_req_write_o=0
  gmem_req_addr_o[63:0]                    // 8-byte aligned
  gmem_req_wdata_o=0 / gmem_req_wstrb_o=0
  gmem_rsp_valid_i / gmem_rsp_ready_o
  gmem_rsp_rdata_i[63:0] / gmem_rsp_error_i

committed output stream:
  out_valid_o / out_ready_i / out_bits_o[31:0]
  out_id_position_o
  out_source_id_o[31:0]
  out_lane_index_o
  out_row_last_o / out_last_o

terminal/evidence:
  one-cycle done_o
  error_o / error_code_o[4:0]
  ids_scanned_o / blocks_done_o / outputs_emitted_o
  gmem_beats_o / payload_bytes_o / active_cycles_o
```

Header 在任何 GMEM request 前必须验证：

```text
V>0
1<=N<=MAX_IDS
32<=D<=MAX_D and D%32==0
packed_row_bytes = 34*(D/32)
src_row_stride>=packed_row_bytes
idx_stride>=4
floor<limit
idx_base + (N-1)*idx_stride + 4 does not wrap and lies in [floor,limit)
N*D <= MAX_IDS*MAX_D
```

I32 必须按 little-endian signed 32-bit 解释。engine 对 `n=0..N-1` 依次
fetch `idx_slice_base+n*idx_stride` 的4个语义字节；若地址不对齐，自动合并
两个 aligned 8-byte beats。header check 还必须对每个 index 的实际读取窗口做
扩展位宽检查：`align_down(idx_addr,8)>=floor`，且覆盖 byte3 的最后一个 aligned
8-byte beat 结束地址不超过 `limit`；语义4字节在界内但物理beat越界也必须在
任何 GMEM request 前失败。每个 id 在写入私有 id buffer 前检查
`0<=id<V`。任一 id 非法时可立即终止剩余 index scan，但在此之前和之后都
不得发 source-row request。

全部 ids 合法后，先对每个 buffered id 做纯地址 preflight：

```text
row_base = src_slice_base + zero_extend(id)*src_row_stride
row_end  = row_base + packed_row_bytes
```

乘法、加法和最后一个 aligned 8-byte beat 的上界都用扩展位宽检查；wrap、
`row_base<floor`、`align_down(row_base,8)<floor` 或最后beat结束超过limit均
在 source read 前失败。只有全部 row 地址都通过后才进入 gather。

每个 Q8_0 block 的 target byte range 为 `[row_base+34*b,+34)`。fetcher 从
`align_down(block_addr,8)` 起逐 beat 请求，到覆盖 byte33 的 aligned beat为止：

```text
beat_count = ceil(((block_addr & 7) + 34)/8)
           = 5, except offset 7 -> 6
```

response 的每个 byte按绝对地址只在落入 target range 时写入272-bit block
buffer；同一beat中位于相邻row padding的byte可以被总线物理读取，但必须被
mask掉，既不能进入block，也不能影响oracle。aligned 8-byte beat不会跨512B
line，因此block跨line自然表现为相邻line上的两个或更多request。

父FSM固定为：

```text
IDLE -> HEADER_CHECK
 -> ID_PREP -> ID_REQ/WAIT -> ID_CAPTURE -> (NEXT_ID | ROW_PREFLIGHT)
 -> ROW_PREFLIGHT for all buffered ids
 -> BLOCK_PREP -> BLOCK_REQ/WAIT until 34 bytes assembled
 -> DEQUANT_START -> DEQUANT_RUN, collect exactly lanes 0..31
 -> (NEXT_BLOCK | NEXT_ID | COMMIT)
 -> OUTPUT_STREAM -> DONE

any precommit header/address/id/GMEM/child/watchdog/corrupt-state fault -> ERROR
```

`TensorNpuQ8DequantBlock` 是唯一数值 child。每个 child lane handshake 写入：

```text
flat = id_position*D + block_index*32 + lane_index
```

lane index/last、block terminal、32-lane cardinality和buffer bounds必须闭合。
所有 `N*D` lanes 完成后经过独立 COMMIT 状态，下一拍才允许首个
`out_valid_o`。output backpressure期间 bits、id position、source id、lane
index与last保持；最后一个 output handshake 后才DONE。与Norm一样，逐beat
接口在首个 committed output后不再产生timeout ERROR；外层runner负责有界
TERM+kill-after。

优先级固定 `reset > corrupt-state > GMEM/child/domain fatal > command timeout >
stall timeout > normal progress`。ERROR 整拍同步reset child、清
`outputs_emitted_o`并保持 `out_valid_o=0`。busy start不得改变resident header、
request payload、id/block/output buffer或计数。GMEM request在
`valid&&!ready`时地址/write/wdata/wstrb稳定；response只在专属WAIT态给credit。

任何已经完成 request handshake 的 GMEM transaction 都必须先消费其唯一匹配
response，才能暴露 ERROR 或回到 IDLE。watchdog 在 REQ 态、request 尚未接受时
可以直接终止；watchdog 在 WAIT 态命中时必须锁存原始 timeout cause、继续只给该
response credit并进入 drain 状态，response handshake 后才发单拍 ERROR。drain
期间禁止新 request、payload merge、计数推进和 output；迟到 response 自带 error
时按 `GMEM fatal > timeout` 报 `ERR_GMEM_RESPONSE`。不得依赖 testbench/总线 reset
清除 outstanding，也不得让下一条命令消费上一条命令的 stale response。

v1直接支持 `N<=16`；backend可以把 loader的 I32 `[512]` no-alloc probe
判定为可tile，但 capability query本身不得解引用dummy地址。真实执行按连续
id-position tile串行调用，保持输出顺序，任一tile错误时上层tensor commit
仍须fail-closed。若backend没有跨tile scratch/commit，不得对N>16返回支持。

## 6. Phase B directed oracle

### v1 canonical cross-line / padded-row oracle

TB 的首个正向事务固定为：

```text
gmem_floor=0x1000, gmem_limit=0x2000
idx_slice_base=0x1026, idx_stride=7
src_slice_base=0x1194                    // address mod 512 = 404
D=64, V=3, N=4
packed_row_bytes=68, src_row_stride=96
ids=[1,0,2,1]                            // little-endian I32
all 28 padding bytes after each packed row = 0xa5
```

index addresses are `0x1026,0x102d,0x1034,0x103b`; the first two require two aligned
beats and the latter two require one, so the exact index-read count is 6 beats.  The
first selected row starts at `0x11f4` (address mod 512 = 500), therefore its block0
crosses the 512-byte boundary.  Every row has block starts at offsets 4 and 6 modulo
8, so each selected row consumes exactly ten source beats.  Final evidence must be:

```text
ids_scanned=4
blocks_done=8
outputs_emitted=256
gmem_beats=46                            // 6 index + 4*10 source
payload_bytes=288                        // 4*4 index + 4*68 Q8 payload
```

`payload_bytes` counts only semantic index/block bytes accepted by the parent, not
alignment over-fetch or row padding.  The GMEM model fills every alignment byte and
all padding with poison; only bytes in each target 4-byte index or 34-byte Q8 block
may affect the result.

Row1 block0 uses scale `0x3c00` (+1.0) and q lanes
`[-128,-1,0,1,127]` followed by zero.  Its first five output raw bits are:

```text
c3000000 bf800000 00000000 3f800000 42fe0000
```

Row1 block1 uses scale `0xb800` (-0.5) and q lanes
`[-128,-2,-1,0,1,2,127]` followed by zero.  Its first seven output raw bits are:

```text
42800000 3f800000 3f000000 80000000
bf000000 bf800000 c27e0000
```

Row0 block0 uses scale `0x4000` (+2.0), `q0=3`, `q31=-4`; the corresponding raw
outputs are `40c00000` and `c1000000`.  Row2 block0 uses minimum positive half
subnormal scale `0x0001`, `q0=1`, `q1=-1`; outputs are `33800000,b3800000`.
Row2 block1 uses scale `0x8000` (-0), `q0=1`; output is `80000000`.  All unspecified
lanes are zero.  The committed row order must be row1,row0,row2,row1, and the repeated
row1 must be raw-bit identical to its first occurrence.

### v1 required negative and protocol cases

- ids `[1,-1,2]` and `[1,V,2]` must produce zero source-row request, zero output and
  one terminal error even though a valid id preceded the invalid one;
- index semantic bytes in range but its first or last aligned beat outside the GMEM
  window must fail before the first request;
- any row multiply/add wrap, row semantic range failure, or last aligned source beat
  outside the window must fail before the first source request;
- GMEM response error during index scan or block fetch, child error/illegal lane
  cardinality, stall timeout, command timeout and resident reset must expose no output;
- request 已接受后的 response-stall/command-timeout 必须先 drain 迟到 response 再
  ERROR；不复位 GMEM model 即刻启动下一条合法命令仍须成功，且不能消费 stale data；
- request backpressure must hold all request payload fields, output backpressure must
  hold all six output payload/position fields, and busy `start_i` must not mutate the
  resident command;
- a maximum-width `D=1024,N=1` transaction must exercise block15 and block30 crossing
  512-byte lines and publish exactly 1024 ordered lanes before DONE.

### Padded row

```text
src ne=[64,3], packed_row_bytes=68, src.nb1=80
ids=[2,0,2]
padding bytes=0xa5
```

source row2含负scale/subnormal数据，row0含raw -128；输出顺序必须row2,row0,row2。支持stride的实现必须只访问base `0,80,160`；packed-only实现必须在backend拒绝 `nb1=80`。

### Qwen width跨512B

```text
src_base mod 512=0
src ne=[1024,2], row_bytes=stride=1088
ids=[1,0]
```

row0 block15：scale2，`q0=3,q31=-4`：

```text
lane480 = +6.0  = 40c00000
lane511 = -8.0  = c1000000
```

row0 block30：scale0.5，`q0=-128,q1=127,q2=-2`：

```text
lane960 = -64.0 = c2800000
lane961 = +63.5 = 427e0000
lane962 = -1.0  = bf800000
```

row1 block13跨1536边界，scale1，`q0=-1,q4=5`：

```text
lane416 = -1.0 = bf800000
lane420 = +5.0 = 40a00000
```

## 7. Qwen与复用边界

本地固定GGUF的embedding是Q8_0 `[1024,248320]`：每token读取32 blocks/1088 bytes并输出1024 F32/4096 bytes。单tokenids `[1]` 输出 `[1024,1]`；prompt `[T]` 输出 `[1024,T]`。

可与GEMV复用：34-byte parser、FP16 converter、boundary-aware fetch、row address/stride generator、block buffer与command/error基础设施。

不能直接复用：

- GEMV activation cache是运行时量化、固定驻留的临时row；embedding是随机id选择的持久weight row；tag/lifetime/coherence必须分开；
- GET_ROWS输出32个独立F32 lane，GEMV输出一个row reduction scalar；
- embedding Q8 raw row不能绕过F32 graph直接冒充下一层activation Q8 cache，必须先dequant并经过真实中间算子，之后按reference activation量化器重新量化；
- 若共用SRAM，必须区分pinned activation与random embedding replacement。

## 8. 验证配置和GAP

默认Verilator配置：`--binary --timing -O3 -Wall -Wno-fatal`，C++ `-O3 -DNDEBUG -march=native`，无`NPU_ASSERT`、trace/wave；所有build/log/cache/compiler temp只在项目`tmp/`。

当前状态：Phase A `TensorNpuQ8DequantBlock` 已通过 O3、无 assert、无 waveform
的 Verilator raw-bit 定向验证，marker 为 `[NPU-Q8-DEQUANT][PASS]`；4 个成功
block 共发布128个有序lane，Inf/NaN scale、child flags、child timeout 与
mid-operation reset均在1024-bit原子结果缓冲发布前fail-closed。

Phase B v3 `TensorNpuQ8GetRowsEngine` 也已通过相同配置的定向验证，marker 为
`[NPU-Q8-GET-ROWS][PASS]`。canonical D64/V3/N4闭合
`ids=4, blocks=8, gmem_beats=46, payload_bytes=288, outputs=256`；其中语义
payload严格为 `4*4+8*34=288`，不计alignment/padding over-fetch。D1024/N1闭合
`blocks=32, gmem_beats=161, payload_bytes=1092, outputs=1024`，并覆盖block15/30
跨512B。17个错误事务、一次resident reset、3个accepted-request timeout drain
与3个不复位GMEM的恢复事务通过；迟到response error覆盖timeout cause，COMMIT前
始终零output。v1的错误304计数预期、v2未覆盖stale-response的局限及v3根因修复
日志均保留在 `tmp/logs/q8-get-rows/`。

全量微回归已一次通过精确 marker
`[NPU-REGRESSION][PASS] tests=24 assertions=off waveform=off optimization=O3`。
仍未覆盖/实现：NaN payload冻结、outer `(h1,h2)` loop、N>16跨tile父级原子
scratch、command ABI、LMEM/DMA destination写入、backend `supports_op`/required-op
绑定，以及Qwen embedding node、token或tokens/s；这些边界不得由当前module PASS
外推。
