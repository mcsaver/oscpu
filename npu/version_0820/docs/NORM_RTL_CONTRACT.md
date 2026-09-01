# RMS/L2 norm RTL 数值与事务合同

> **实现阶段合同。** 本文冻结 llama.cpp b10507 portable CPU 路径中 `GGML_OP_RMS_NORM` 与 `GGML_OP_L2_NORM` 的逐行数值顺序，并据此划分本地 RV64 NPU 的 RTL primitive。当前既有 FP32 multiply/divide/conversion 与已通过15项raw-bit oracle的 `TensorNpuFp32Sqrt` 可作为子模块；本文本身不是 norm、Qwen token 或 tokens/s PASS。禁止 CPU/DPI 数值代算、综合、STA 与 PPA。

固定源码版本：llama.cpp b10507 commit [`95c409c13625a23da2aa37270339ce9179215a18`](https://github.com/ggml-org/llama.cpp/commit/95c409c13625a23da2aa37270339ce9179215a18)。

关键源码：

- [RMS_NORM CPU loop](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/ops.cpp#L3533-L3616)
- [L2_NORM CPU loop](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/ops.cpp#L3895-L3957)
- [`ggml_float` 为 binary64/double](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/vec.h#L13-L14)
- [RMS/MUL CPU fusion gate](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/ggml-cpu.c#L2870-L2947)
- [Qwen3.5 graph construction](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/src/models/qwen35.cpp)

## 1. Tensor 行语义

两种 op 的输入和输出 dtype 均为 F32，shape 不变：

```text
src/dst ne = [D, N1, N2, N3]
row        = fixed (i1,i2,i3)
row_count  = N1*N2*N3
lane       = i0 = 0..D-1
```

portable CPU 对每一行独立处理，同一行的 reduction 不跨线程。RMS 要求 `src.nb0=4`；L2 CPU 可按任意 `src.nb0` 逐元素取数。Qwen v1 NPU 前端应把真实 `nb[]` 转成恰好 D 项的 row stream，norm core 不得读取高维 stride gap 或 padding。

Qwen3.5-0.8B 主图需要的行长：

| 路径 | mode | D | decode T=1 的每次调用行数 |
|---|---|---:|---:|
| hidden pre/post/final norm | RMS | 1024 | 1 |
| full-attention Q norm | RMS | 256 | 8 |
| full-attention K norm | RMS | 256 | 2 |
| GDN q/k norm | L2 | 128 | 各16 |
| GDN recurrent output norm | RMS | 128 | 16 |

主 decoder 有 79 个 RMS_NORM 节点、36 个 L2_NORM 节点。prompt 时行数随 token 数增长，但 D 仍只为 128、256、1024。

## 2. RMS_NORM portable 数值顺序

每个源码舍入边界都必须保留：

```text
sum64 = +0.0(binary64)

for i = 0 .. D-1, strictly increasing:
    sq32   = RN32(x[i] * x[i])
    term64 = exact_widen_f32_to_f64(sq32)
    sum64  = RN64(sum64 + term64)

mean64  = RN64(sum64 / binary64(D))
mean32  = RN32_from_F64(mean64)
arg32   = RN32(mean32 + eps32)
root32  = sqrt_RNE(arg32)
scale32 = RN32(1.0f / root32)

for i = 0 .. D-1:
    y[i] = RN32(x[i] * scale32)
```

Qwen 的 D 都是二次幂，因此 `sum64/D` 可以用精确 binary64 exponent scaling；不得把它改成 F32 除法。

禁止的重关联：

- 用 F64 先算 `x*x`；
- 用 F32 accumulator；
- 对同一行做 tree/partial-sum reduction；
- 把 epsilon 加在 sum 上后再除 D；
- 用近似 `rsqrt` 替代独立 correctly-rounded sqrt 与 divide；
- 把最终 norm multiply 与 learned weight multiply 收缩成一个高精度表达式。

若后续支持 fused RMS+weight，必须仍执行：

```text
tmp32 = RN32(x * scale)
out32 = RN32(tmp32 * weight)
```

## 3. L2_NORM portable 数值顺序

L2 与 RMS 共享相同的 F32-square/F64-serial reduction，但不除 D，且 epsilon 位于 sqrt 之后：

```text
sum64 = +0.0(binary64)

for i = 0 .. D-1, strictly increasing:
    sq32   = RN32(x[i] * x[i])
    term64 = exact_widen_f32_to_f64(sq32)
    sum64  = RN64(sum64 + term64)

sum32   = RN32_from_F64(sum64)
norm32  = sqrt_RNE(sum32)
den32   = maximumNumber(norm32, eps32)
scale32 = RN32(1.0f / den32)

for i = 0 .. D-1:
    y[i] = RN32(x[i] * scale32)
```

`maximumNumber` 对应 finite accepted domain 下的 `fmaxf`。不得使用 `sqrt(sum+eps)`、`sqrt(max(sum,eps))` 或 `rsqrt(max(sum,eps*eps))` 作为 portable bit contract。

## 4. Accepted domain 与 fail-closed

本项目 v1 比 release C 路径更严格，命令入口和 reduction 必须拒绝：

- epsilon 为 NaN、Inf、负数或 negative zero；
- 任意 input 为 NaN/Inf；
- F32 square 产生 NV、OF 或非有限结果；
- F64 accumulator 产生 NV、DZ、OF 或非有限结果；
- F64→F32 产生 NV、DZ、OF 或非有限结果；
- RMS 的 `mean32+eps` 产生 NV、OF 或非有限结果；
- sqrt 产生 NV、DZ、OF 或结果非有限；
- denominator 为 ±0；
- reciprocal 或 replay multiply 产生 NV、DZ、OF 或非有限结果。

NX 是正确舍入的正常结果，不能当作命令错误；gradual-underflow 路径中的 UF|NX 也必须保留结果并允许继续。换言之，flags 是位级正确性证据和父状态机的分类输入，而不是“任一非零即失败”的布尔错误。只有上述 fatal 类别或 nonfinite/zero-denominator 才触发整行 ERROR。

subnormal 采用 gradual-underflow 语义，不允许静默 FTZ/DAZ。若未来实现无法支持，必须在 capability/preflight 明确返回 unsupported，不得静默改值。

任一 ERROR 对整行 fail-closed：在 scale 完成前不发布 output；若 replay 中出现错误，已发布的 row lane 视为 provisional，只有 row DONE 后下游才可原子提交。

## 5. 分阶段 RTL 拓扑

### Phase A：FP32 sqrt wrapper

`TensorNpuFp32Sqrt` 直接封装固定 `fpu-sp fp_fdiv #(.PERFORMANCE(0))` 的 fsqrt 路径；事务与 oracle见 [`FP32_SQRT_RTL_CONTRACT.md`](FP32_SQRT_RTL_CONTRACT.md)。通过该 primitive 只证明 sqrt，不证明 norm。

### Phase A.5：HardFloat 有序 binary64 primitive

F32 square 之后的 widen、逐项 F64 add 与最终 F64→F32 采用 Berkeley HardFloat Release 1。输入供应链固定为：

```text
upstream       = https://www.jhauser.us/arithmetic/HardFloat.html
version        = Release 1
archive        = tmp/downloads/HardFloat-1.zip
archive_sha256 = 6b3757c9fbfa2230c6a2b84605e39372cb589dd7500e979c4f0b8ecc8a03b14b
source         = third_party/hardfloat
license        = BSD-3-Clause
```

`third_party/SOURCES.lock.json` 必须在 build 前通过 `scripts/verify_locked_inputs.py`。只允许使用官方归档中的以下最小 Verilog 闭包与两个 include 目录；不得运行上游 Makefile、下载未锁定 TestFloat 依赖或把第三方临时文件写到项目外：

```text
third_party/hardfloat/source/HardFloat_primitives.v
third_party/hardfloat/source/HardFloat_rawFN.v
third_party/hardfloat/source/isSigNaNRecFN.v
third_party/hardfloat/source/fNToRecFN.v
third_party/hardfloat/source/recFNToRecFN.v
third_party/hardfloat/source/recFNToFN.v
third_party/hardfloat/source/addRecFN.v

include order/search:
  -Ithird_party/hardfloat/source/RISCV
  -Ithird_party/hardfloat/source
```

RISC-V specialization固定：

```text
control      = flControl_tininessAfterRounding
roundingMode = round_near_even
FTZ/DAZ      = disabled
flags[4:0]   = {NV,DZ,OF,UF,NX}
```

project-owned wrapper 不透出 recoded format；只接收/返回 IEEE raw bits，并采用统一的 single-outstanding request/held-response 协议。request 仅在 `req_valid && req_ready` 时采样；response 产生后必须在 `rsp_valid && rsp_ready` 前保持 result、flags 与 error；busy request 不得覆盖在途事务；reset 取消在途事务且不得产生 stale response。

三个 wrapper 的数值链固定为：

```text
TensorNpuFp32ToFp64:
  IEEE F32 -> fNToRecFN#(8,24)
           -> recFNToRecFN#(8,24,11,53)
           -> recFNToFN#(11,53) -> IEEE F64

TensorNpuFp64Add:
  each IEEE F64 -> fNToRecFN#(11,53)
                -> addRecFN#(11,53), subOp=0
                -> recFNToFN#(11,53) -> IEEE F64

TensorNpuFp64ToFp32:
  IEEE F64 -> fNToRecFN#(11,53)
           -> recFNToRecFN#(11,53,8,24)
           -> recFNToFN#(8,24) -> IEEE F32
```

wrapper accepted domain 与错误策略：

- F32→F64 接受全部有限 F32，包括负数、subnormal 与 `-0`；转换必须精确且 flags=0。NaN/Inf 原子失败，result清零，domain error置位。
- F64 add 仅接受 raw sign=0 且 finite 的两个操作数，即 `+0`、正 subnormal、正 normal；`-0` 也不在 accepted domain。合法有限输入导致的 `+Inf, OF|NX` 是 IEEE primitive结果，不在 wrapper 内伪装成 domain error；Norm 父状态机必须因 nonfinite/OF fail-closed。
- F64→F32 仅接受 raw sign=0 且 finite 的输入。合法 finite 大数可产生 `+Inf, OF|NX`；合法 tiny值可产生 `UF|NX`。primitive 不把 NX/UF 擅自提升为 domain error。
- 非法 domain 的 response 必须稳定返回 `error=1`、result=0，且不得把第三方 NaN payload提交给上层。

raw-bit oracle 以 SoftFloat 3e commit `5c06db33fc1e2130f67c045327b0ec949032df1d`、RNE、tininess-after为独立参考。TB 至少覆盖：

```text
F32->F64:
  00000000 -> 0000000000000000 / 00
  80000000 -> 8000000000000000 / 00
  00000001 -> 36A0000000000000 / 00
  007FFFFF -> 380FFFFFC0000000 / 00
  00800000 -> 3810000000000000 / 00
  7F7FFFFF -> 47EFFFFFE0000000 / 00

F64 add:
  3FF8000000000000 + 3FF8000000000000 -> 4008000000000000 / 00
  000FFFFFFFFFFFFF + 0000000000000001 -> 0010000000000000 / 00
  3FF0000000000000 + 3CA0000000000000 -> 3FF0000000000000 / 01
  3FF0000000000001 + 3CA0000000000000 -> 3FF0000000000002 / 01
  3FF0000000000000 + 3CA4000000000000 -> 3FF0000000000001 / 01
  3FF0000000000000 + 0000000000000001 -> 3FF0000000000000 / 01
  7FEFFFFFFFFFFFFF + 7FEFFFFFFFFFFFFF -> 7FF0000000000000 / 05

F64->F32:
  3FF0000010000000 -> 3F800000 / 01
  3FF0000030000000 -> 3F800002 / 01
  3FF0000010000001 -> 3F800001 / 01
  36A0000000000000 -> 00000001 / 00
  3690000000000000 -> 00000000 / 03
  380FFFFFC0000000 -> 007FFFFF / 00
  380FFFFFE0000000 -> 00800000 / 03
  380FFFFFE1000000 -> 00800000 / 03
  380FFFFFF0000000 -> 00800000 / 01
  47EFFFFFEFFFFFFF -> 7F7FFFFF / 01
  47EFFFFFF0000000 -> 7F800000 / 05
```

其中 `380FFFFFE0000000` 与 `380FFFFFF0000000` 必须同时存在，用来阻止把“最终结果 exponent 非零”误当成 tininess-after 的完整判据。

定向 Verilator 证据：

```text
[NPU-FP32-FP64][PASS]
[NPU-FP64-ADD][PASS]
[NPU-FP64-FP32][PASS]
```

三个 wrapper 均为一拍 registered response、single-outstanding、held response；新增 RTL/TB 在未屏蔽 `-Wall` 的定向 build 中零 warning。未修改的 HardFloat Release 1 源仍有 `DECLFILENAME/TIMESCALEMOD/GENUNNAMED/WIDTH/UNUSEDSIGNAL` 上游告警，必须按来源审计，不能把它们误报成 project-owned warning 或通过修改 vendor 源清除。

### Phase B：ordered square-sum

建议模块 `TensorNpuFp32SquareSum64`：

```text
parameters:
  MAX_D=1024
  INDEX_WIDTH=clog2(MAX_D)
  bounded STALL_TIMEOUT_CYCLES / COMMAND_TIMEOUT_CYCLES

command:
  start/ready/busy, element_count in 1..MAX_D

input:
  lane_valid/lane_ready, raw F32 lane bits

terminal:
  one-cycle done; error + error_code; raw F64 sum; OR-reduced IEEE flags

replay:
  committed_row_valid, committed_count, combinational replay_index/read_bits

evidence:
  elements_accepted, active_cycles

storage:
  one MAX_D-entry F32 row buffer; payload may be written while busy but is
  architecturally visible only after the entire square-sum succeeds
```

父状态机固定串行顺序：

```text
IDLE
 -> WAIT_LANE
 -> SQUARE_REQ -> SQUARE_WAIT
 -> WIDEN_REQ  -> WIDEN_WAIT
 -> ADD64_REQ  -> ADD64_WAIT
 -> (WAIT_LANE | DONE)
any invalid input / fatal flags / timeout / corrupt state -> ERROR
```

每次 input handshake先缓存 x，再通过现有 `TensorNpuFp32AddMul` 的 multiply 模式产生 `sq32`，经 `TensorNpuFp32ToFp64` 精确扩大，最后送入单个 `TensorNpuFp64Add`。只有 add response成功写回 `sum64` 后才能推进同一行的 index 并接受下一项；允许未来交错多行，但禁止重排或拆分同一行。

事务不变量：

- `start` 只在 IDLE/ready 接受；busy start不得改变 D、index、accumulator、row buffer可见性或child payload。
- 每个 REQ 态持有 child valid/payload 到 child ready；只有对应 WAIT 态返回 response credit。
- `lane_ready` 只能在 WAIT_LANE 且没有 child transaction 时为1；计数只在真实 lane handshake递增。
- square 的 UF/NX、F64 add 的 NX以及最终其它合法 UF/NX只累积到 row flags，不触发错误；NV/DZ/OF或任何 nonfinite result触发整行 ERROR。
- `row_committed` 与 `sum64` 只在最后一个 ADD64成功后发布。ERROR 时即使内部 RAM 已写入部分输入，`row_committed=0`，外部不得观察为有效行。
- output terminal为单拍；reset优先取消任意 child transaction，清除 committed validity，并且不得产生 stale done/error。
- stall/command watchdog 必须覆盖缺少lane输入、child credit/response丢失及非法FSM；timeout进入整拍 ERROR并同步reset children。

定向 TB 必须包含严格有序反例：

```text
D=4
x raw = 3F800000, 32000000, 32000000, 32000000
sq32  = 3F800000, 24800000, 24800000, 24800000
term64= 3FF0000000000000, 3C90000000000000 ×3

serial RN64 result = 3FF0000000000000, row flags includes NX
tree/exact-once    = 3FF0000000000001  // forbidden counterexample
```

还必须覆盖 D=4 的 `(+2,-2,+2,-2)->sum64=16`、MAX_D=1024 全零、input NaN/Inf、square overflow、invalid count、input backpressure、busy start、reset取消、watchdog以及 committed replay的界内/越界读。

### Phase C：norm postprocess + replay

RMS 的 `sum64/D` 不需要真正的 F64 divider。对 accepted provenance，非零 square term 至少为 widened F32 min-subnormal `2^-149`，而最大 D 为 `2^10`；因此非零 quotient 至少为 `2^-159`，仍远高于 F64 min-normal `2^-1022`。固定 scaler 只接受 `D={128,256,1024}` 与 `sum64=+0` 或正 normal provenance：

```text
D=128:  k=7
D=256:  k=8
D=1024: k=10

if sum64 == +0:
    mean64 = +0
else:
    require sign=0, exp in [11'h36A,11'h488], exp>k
    mean64 = {1'b0, exp-k, fraction}

division flags = 5'b00000
```

fraction 原样保留，所以这一步逐 bit 等价于一次真正的 binary64 division by power-of-two，且没有舍入。任意更小的 normal/subnormal F64 不在该专用 domain；它们需要 shift/jam/RNE，不能盲目减 raw exponent。scaler 输出随后再进入 `TensorNpuFp64ToFp32`，后者的 UF/NX 属于窄化转换，不得错误归因给除法阶段。

推荐父 FSM：

```text
IDLE
 -> ROW_LOAD_SQUARE
 -> SUM64_WAIT
 -> MODE_POSTPROCESS
    RMS: DIV_POW2 -> F64_TO_F32 -> ADD_EPS
    L2 : F64_TO_F32
 -> SQRT_REQ/WAIT
 -> L2_MAX_OR_RMS_PASS
 -> RECIP_REQ/WAIT
 -> ROW_REPLAY_MUL
 -> ROW_DONE
 -> NEXT_ROW / COMMAND_DONE
any fault -> ERROR
```

`out_valid && !out_ready` 时 raw bits、lane index、row index和last标志必须稳定。busy start不得改变 resident row或 mode/eps/D。

### Phase C v1：`TensorNpuNormEngine` 冻结接口与事务

v1 一次命令只处理一条 dim-0 row；outer `nb[1..3]` gather、跨行循环和
DMA/LMEM 提交留给后续前端。端口固定为：

```text
parameters:
  MAX_D=1024
  STALL_TIMEOUT_CYCLES=256
  COMMAND_TIMEOUT_CYCLES=262144

command:
  clk_i, synchronous active-high rst_i
  start_i / ready_o / busy_o
  mode_i[1:0]: 0=RMS, 1=L2；其它编码非法
  element_count_i[$clog2(MAX_D+1)-1:0]
  eps_bits_i[31:0]

input row:
  lane_valid_i / lane_ready_o / lane_bits_i[31:0]

committed output stream:
  out_valid_o / out_ready_i
  out_bits_o[31:0]
  out_index_o[$clog2(MAX_D+1)-1:0]
  out_last_o

terminal/evidence:
  one-cycle done_o
  error_o / error_code_o[4:0]
  flags_o[4:0] = {NV,DZ,OF,UF,NX}
  elements_accepted_o / elements_emitted_o
  active_cycles_o[31:0]
```

固定 Qwen3.5-0.8B capability allowlist：

```text
RMS: D in {128,256,1024}
L2 : D == 128
eps: +0 or positive finite binary32
```

项目 v1 有意比 host C 更严格：negative zero、负有限、NaN 和 Inf epsilon
都在消费 row 前原子失败；不复刻 host 对 `-0`/`+Inf` 的宽松接受。非法
mode/D/epsilon 不得启动 `TensorNpuFp32SquareSum64`，也不得给输入 lane
credit。当前模型的 `eps=1e-6f` raw bits 是 `0x358637bd`，但数值核心不把
它硬编码成唯一合法值。

父事务必须实例化且只通过 ready/valid 边界复用：

```text
TensorNpuFp32SquareSum64
TensorNpuFp64Pow2Scale       // RMS only
TensorNpuFp64ToFp32
TensorNpuFp32AddMul          // eps add, replay multiply
TensorNpuFp32Sqrt
TensorNpuFp32Div
```

固定执行序列：

```text
IDLE -> SUM_START -> SUM_RUN

RMS:
  SCALE_REQ/WAIT -> F64_TO_F32_REQ/WAIT -> EPS_ADD_REQ/WAIT

L2:
  F64_TO_F32_REQ/WAIT

common:
  SQRT_REQ/WAIT -> (L2_MAX | RMS_PASS)
  -> RECIP_REQ/WAIT
  -> REPLAY_LOAD -> OUTPUT_MUL_REQ/WAIT  // index 0..D-1
  -> COMMIT -> OUTPUT_STREAM -> DONE

any header/protocol/child/timeout/corrupt-state fault -> ERROR
```

`TensorNpuFp32SquareSum64` 的 committed replay row 是输入二次读取的唯一
来源。每个输出乘法成功后先写入父级私有 `MAX_D x 32` output buffer；只有
全部 D 个乘法均成功后才进入 `OUTPUT_STREAM`。因此第一拍 `out_valid_o`
出现后不再存在会令本行失败的数值阶段。`out_valid_o && !out_ready_i`
期间 bits/index/last 必须稳定；最后一个 output handshake 后才进入单拍
`DONE`。任何 ERROR 均须保持 `out_valid_o=0`、`elements_emitted_o=0`，并
同步 reset 所有 resident child transaction。

flag 策略固定为：每条命令从零开始 sticky OR；UF/NX 合法继续，
NV/DZ/OF、child domain error、nonfinite result 或 zero denominator 原子失败。
L2 的 `fmaxf` 在 accepted positive-finite/+0 domain 内按 binary32 正数 raw
bits比较即可；相等时保持 `norm32`，不产生 flags。reset 优先级最高，随后
是当拍 domain/child fatal，再是 command timeout、stall timeout，最后才是
正常进展。默认 stall timeout 必须大于固定 sqrt/div 的 28-cycle latency。

v1 不支持 arbitrary D、weighted RMS fusion、多 row command、任意 stride、
NaN payload compatibility、host/DPI math、tree/Kulisch reduction或近似 rsqrt；
这些情况必须 capability/preflight fail-closed。

## 6. Raw-bit directed oracle

Phase C v1 的定向 Verilator TB 只使用 capability allowlist 内的真实维度：

```text
RMS, D=128, eps=12.0f (0x41400000):
  x 按 +2/-2 交替
  sum64=512, mean32=4, arg32=16, root32=4, scale32=0.25
  y 按 +0.5/-0.5 交替，即 0x3f000000/0xbf000000

L2, D=128, eps=4.0f (0x40800000):
  x[0]=+2，其余按 +0/-0 混合
  sum64=4, norm32=2, den32=max(2,4)=4, scale32=0.25
  y[0]=0.5 (0x3f000000)，其余零保持输入符号

L2, D=128, eps=4.0f:
  x[0]=+4，其余按 +0/-0 混合
  sum64=16, norm32=4, den32=4, scale32=0.25
  y[0]=1.0 (0x3f800000)，其余零保持输入符号
```

下面的 D=4/two-row/padding 向量是 portable 数值顺序与未来 stride/DMA
集成 oracle；`TensorNpuNormEngine` v1 不得为了运行 D=4 而扩大 capability。

### RMS：epsilon 位置、两行和padding

```text
D=4, rows=2, eps=12.0f (0x41400000)
src row stride=32 bytes; 每行16-byte payload后16-byte poison gap

row0 input:  +2,-2,+2,-2
row0 bits:   40000000 c0000000 40000000 c0000000
sum=16, mean=4, mean+eps=16, root=4, scale=0.25
expected:    3f000000 bf000000 3f000000 bf000000

row1 input:  +0,-0,+0,-0
expected:    00000000 80000000 00000000 80000000
```

poison gap填 NaN/Inf；任何误读padding都会破坏结果或触发ERROR。该向量可区分正确 `mean+eps` 与错误 `(sum+eps)/D`。

### L2：epsilon 在 sqrt 之后

```text
D=4, rows=2, eps=4.0f (0x40800000)

row0 input:  +2,+0,-0,+0
row0 bits:   40000000 00000000 80000000 00000000
expected:    3f000000 00000000 80000000 00000000

row1 input:  +4,+0,-0,+0
row1 bits:   40800000 00000000 80000000 00000000
expected:    3f800000 00000000 80000000 00000000
```

### Qwen 行长边界

```text
RMS D=1024, eps=0:
  x按 +1/-1交替；sum=1024, mean=1, scale=1；输出逐bit等于输入。

L2 D=128, eps=0:
  x[0]=+1，其余为混合+0/-0；sum=1, scale=1；输出逐bit等于输入。
```

### 负向

- `D=1, x=2^64 (0x5f800000), eps=1`：F32 square溢出，必须 `ERR_SQ_OVF`；
- 全零行且eps=0：必须 `ERR_DEN_ZERO`；
- qNaN/Inf input：必须在任何output提交前ERROR；
- output backpressure、busy start、resident child reset与watchdog均需定向覆盖。

所有 oracle由纯 SV 32/64-bit literal驱动和比较；禁止 `real/shortreal`、DPI或host math。

## 7. Optimized 路径边界

CUDA/Metal等实现常用 F32 partial/tree reduction、近似 `rsqrt` 或 fused kernel；它们可用于误差评估，不能作为本文 portable raw-bit oracle。CPU `RMS_NORM+MUL` fusion只在特定F32权重和图条件下发生，也不改变本文要求的两个独立F32 multiply舍入边界。

## 8. 验证配置与当前 GAP

固定 Verilator 配置：`--binary --timing -O3 -Wall -Wno-fatal`，C++ `-O3 -DNDEBUG -march=native`，无 `NPU_ASSERT`、trace或waveform；build/log/cache/compiler temp只能进入项目 `tmp/`。

当前状态：FP32 sqrt、F32→F64、F64 RNE add、F64→F32、`TensorNpuFp32SquareSum64`、`TensorNpuFp64Pow2Scale` 与单行 `TensorNpuNormEngine` 已进入 `[NPU-REGRESSION][PASS] tests=23 assertions=off waveform=off optimization=O3`；聚合 build/run 日志无 warning/error marker且项目 `tmp/` 无波形文件。Norm 定向日志以精确 `[NPU-NORM][PASS]` 收口，23 个 case 覆盖 RMS D=128/256/1024、L2 D=128、epsilon floor、signed zero、UF|NX继续、非法 header、input/square/convert fault、zero denominator、两类 watchdog、busy/reset、precommit零输出、全 child cardinality以及 committed stream 反压保持。scaler 的231项检查继续覆盖 fraction保持、provenance exponent边界与复位期credit抑制；有序 square-sum 的tree反例、OF原子失败、MAX_D=1024和replay也均有动态证据。HardFloat Release 1 供应链在实现前再次得到 `[LOCK][PASS] sources=4 models=1`。当前 GAP 是 outer stride/DMA/LMEM、多行command/backend、Qwen required-node接线以及token/tokens/s；本文没有综合、STA、PPA或系统吞吐结论。
