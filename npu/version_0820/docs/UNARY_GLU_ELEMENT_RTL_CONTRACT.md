# Unary/GLU FP32 单元素 RTL 合同

## 1. 状态与边界

本合同冻结 `TensorNpuUnaryGluElement` 的 Phase A reference transaction。该模块在一个时钟域内接受一个
binary32 raw-bit 元素请求，按 `TENSOR_NPU_UNARY_GLU_F32_RNE_V1` 顺序驱动现有 EXP、LOG、ADD/MUL、DIV
child，随后原子发布一个 raw result、逐节点 sticky flags、错误状态、实际 child launch mask 和
launch-inclusive active cycles。

本合同只证明单元素事务，不证明以下范围：

- 整个 tensor 的全量 finite preflight、双 bank 或 operator 原子提交；
- `LANES=4/8` 静态 striping、多元素乱序完成或 natural-order output gather；
- GGML backend `supports_op`、Qwen required-op dispatch、CPU fallback=0；
- Qwen shell 对话或 tokens/s；
- 综合、STA、PPA、面积、频率或功耗。

数值输入绑定：

- `docs/UNARY_GLU_F32_ORACLE_CONTRACT.md`；
- oracle generator SHA-256
  `a2156150de724babce4805e53f3a51115927b080deec22e06d9017df795ded6c`；
- canonical vectors SHA-256
  `0bc73dba6d65597a78d8b0d9451e787334a5feb81ca677407a7cb4aa61d1c908`；
- mutation audit SHA-256
  `696fbc2beb0ca0419ae86f542272f382e0cbca76d251608f8689643fd8a6ac16`；
- AOR EXP/LOG 语义与 child quarantine 绑定 `docs/AOR_EXP_LOG_RTL_CONTRACT.md`。

## 2. Module 接口

```verilog
module TensorNpuUnaryGluElement #(
    parameter integer COMMAND_TIMEOUT_CYCLES = 256
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [2:0]  opcode_i,
    input  wire [31:0] src0_bits_i,
    input  wire [31:0] src1_bits_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_bits_o,
    output wire [4:0]  flags_o,
    output wire        error_o,
    output wire [3:0]  error_code_o,
    output wire [4:0]  child_call_mask_o,
    output wire [31:0] active_cycles_o
);
```

所有端口属于 `clk_i` 时钟域。`rst_i` 为同步、高有效；reset 周期 `req_ready_o=0`、`rsp_valid_o=0`。

Opcode：

| `opcode_i` | 运算 |
|---:|---|
| `3'd0` | SIGMOID |
| `3'd1` | SOFTPLUS |
| `3'd2` | SILU |
| `3'd3` | SWIGLU_SPLIT，`src0` 为 nonlinear gate、`src1` 为 linear up |
| `3'd4..7` | unsupported |

Error code：

| code | 含义 |
|---:|---|
| `4'd0` | OK |
| `4'd1` | unsupported opcode 或被消费的 external operand nonfinite |
| `4'd2` | child 显式 error、unexpected NV/DZ 或 child NaN result |
| `4'd3` | command timeout |
| `4'd4` | protocol/owner/illegal-state fault |

`flags_o[4:0]={NV,DZ,OF,UF,NX}`。成功事务发布逐级 response flags 的 OR。失败事务固定
`result_bits_o=0`、`flags_o=0`；`child_call_mask_o` 仍报告本事务实际已握手的 child request，便于区分
preflight rejection 与执行中止。

`child_call_mask_o` 位序固定：

| bit | child |
|---:|---|
| 0 | AOR EXP32 |
| 1 | FP32 ADD |
| 2 | FP32 DIV |
| 3 | AOR LOG32 |
| 4 | FP32 MUL |

## 3. 逐级数值 DAG

所有中间 raw 都必须由对应 child response handshake 后锁存，禁止 FMA、reciprocal×MUL、LOG1P、代数重关联
或跨节点旁路。

```text
SIGMOID:
  nx = src0_bits_i ^ 0x80000000
  e  = AOR_EXP32(nx)
  d  = FP32_ADD_RNE(0x3f800000, e)
  y  = FP32_DIV_RNE(0x3f800000, d)

SOFTPLUS:
  if ordered_finite(src0_bits_i) && src0_bits_i > 0x41a00000:
      y = raw bitcopy(src0_bits_i), no child launch
  else:
      e = AOR_EXP32(src0_bits_i)
      d = FP32_ADD_RNE(0x3f800000, e)
      y = AOR_LOG32(d)

SILU:
  nx = src0_bits_i ^ 0x80000000
  e  = AOR_EXP32(nx)
  d  = FP32_ADD_RNE(0x3f800000, e)
  y  = FP32_DIV_RNE(src0_bits_i, d)

SWIGLU:
  nx = src0_bits_i ^ 0x80000000
  e  = AOR_EXP32(nx)
  d  = FP32_ADD_RNE(0x3f800000, e)
  s  = FP32_DIV_RNE(src0_bits_i, d)
  y  = FP32_MUL_RNE(s, src1_bits_i)
```

SOFTPLUS 的 bypass 比较严格为 `>`，因此 `0x41a00000` 必须执行 EXP→ADD→LOG，`0x41a00001`
才可 0-child raw bitcopy。ADD operand 顺序固定为 `{1.0,e}`；SWIGLU MUL operand 顺序固定为 `{s,src1}`。

## 4. External preflight 与 internal special-value policy

在任何 child request 前检查：

- 所有 opcode 消费 `src0_bits_i`，其 exponent `8'hff` 时返回 `ERR_UNSUPPORTED`；
- 只有 SWIGLU 消费 `src1_bits_i`，其 exponent `8'hff` 时返回 `ERR_UNSUPPORTED`；
- 非 SWIGLU 的 `src1_bits_i` 不参与 preflight，也不影响结果；
- unsupported opcode 返回 `ERR_UNSUPPORTED`。

上述 rejection 的 `child_call_mask_o=0`。

child 生成的 Inf 是合法内部数据，必须继续送入下一节点。例如 `src0=-100` 时 EXP(+100)=+Inf，
SIGMOID 必须得到 `+0`，SILU 必须得到 `-0`，sticky flags 为 `OF|NX`。finite SWIGLU 最末 MUL
overflow 到 signed Inf 是成功事务，不得提升为 error。

任一 child 显式 `error_o=1`、response flags 含 NV/DZ、或 response raw 是 NaN 时进入 `ERR_CHILD`。
OF/UF/NX 与 signed Inf/zero 按冻结 DAG 继续传播。

## 5. Ready/valid、owner 与 FSM

### 5.1 外部协议

- 只在 `req_valid_i && req_ready_o` 锁存 opcode/src0/src1；busy request 不采样。
- 从 request handshake 到 response retire 最多一个 command resident。
- `rsp_valid_o && !rsp_ready_i` 时 result/flags/error/code/call-mask/cycles 全位稳定。
- response retire 同拍不接受下一 request；下一周期回到 clean IDLE 才重新提供 credit。
- reset 取消 resident command，不发布 stale response；reset 后新请求必须得到独立 clean response。

### 5.2 FSM

```text
IDLE
PREFLIGHT
EXP_REQ -> EXP_WAIT
ADD_REQ -> ADD_WAIT
DIV_REQ -> DIV_WAIT
LOG_REQ -> LOG_WAIT
MUL_REQ -> MUL_WAIT
ABORT_RESET
HOLD_RESPONSE
```

每个 `*_REQ` 状态保持 child request payload，直到 `valid&&ready`；对应 `*_WAIT` 独占该 child 的
`rsp_ready`。状态本身就是 owner；任一时刻所有 child outstanding 总和不超过 1。

成功 cardinality：

| op | EXP | ADD | DIV | LOG | MUL |
|---|---:|---:|---:|---:|---:|
| SIGMOID | 1 | 1 | 1 | 0 | 0 |
| SOFTPLUS slow | 1 | 1 | 0 | 1 | 0 |
| SOFTPLUS bypass | 0 | 0 | 0 | 0 | 0 |
| SILU | 1 | 1 | 1 | 0 | 0 |
| SWIGLU | 1 | 1 | 1 | 0 | 1 |
| preflight rejection | 0 | 0 | 0 | 0 | 0 |

任何 child response 只可在对应 WAIT 状态被消费。IDLE/REQ/错误 child/其它 WAIT 出现 response 是
protocol fault；没有 resident command 的 ghost response必须先 reset child cluster，且不得制造无 request
对应的外部 response。

### 5.3 Reset、timeout、quarantine 优先级

同拍优先级固定：

```text
rst_i
  > illegal state / wrong-owner response / child error
  > command timeout
  > normal request/response progress
```

deadline 同拍的 child response仍由 timeout 胜出，语义结果不得提交。

`child_rst = rst_i || (state==ABORT_RESET) || (state==HOLD_RESPONSE)`。ABORT_RESET 至少完整一拍；
HOLD_RESPONSE 全段继续 reset 所有 child，包含 response retire edge。下一周期 IDLE 才允许新 owner。
执行中错误发布恰好一个 error response；无 resident command 的 ghost fault只清洗 child并回 IDLE，禁止产生
unmatched response。

## 6. Child 实例与固定配置

模块独占下列 child，不跨 element 共享：

- `TensorNpuAorExp32 #(.COMMAND_TIMEOUT_CYCLES(128))`；
- `TensorNpuAorLog32 #(.COMMAND_TIMEOUT_CYCLES(128))`；
- 一个 `TensorNpuFp32AddMul`，ADD/MUL phase 共享但不得同时在途；
- `TensorNpuFp32Div`，内部 `fp_fdiv PERFORMANCE=0`。

本地既有证据：

- AOR EXP normal active cycles = 26；
- AOR LOG normal active cycles = 24；
- FP32 ADD/MUL request→response visible latency = 2；
- FP32 DIV request→response visible latency = 28。

父模块默认 timeout 256，必须覆盖最长 SWIGLU 顺序路径。父级 exact launch-inclusive cycles由 Phase 2
拓扑推导后写入 TB localparam；禁止只检查非零或宽松上限。

## 7. 不变量

1. `accepted_requests - retired_responses` 始终属于 `{0,1}`。
2. 每个 child `accepted_requests - consumed_responses` 属于 `{0,1}`，所有 child outstanding 总和 `<=1`。
3. child request payload 从 valid 首拍到 handshake保持；response只由 matching WAIT owner消费。
4. sticky flags只在 matching child response handshake OR；bypass/rejection flags为0。
5. `child_call_mask_o` 只在 child request handshake置位，不在 request valid或response时推测。
6. error/timeout 前的中间 raw、flags不得进入成功 response；失败 payload/flags固定0。
7. HOLD_RESPONSE 背压期间所有公开 payload、call mask、cycle snapshot稳定，active cycles不再增加。
8. reset/ABORT/HOLD 清洗所有 child；新 command不得消费上一 command 的 ghost response。
9. busy `req_valid_i`/payload变化不改变 resident opcode/src0/src1/phase/intermediate raw。
10. illegal state和wrong-owner fail closed；没有 resident command时不得发布 unmatched response。

## 8. Testbench 与证据

新增 `tests/tb_unary_glu_element.sv`，只使用 raw-bit常量，不使用 real/shortreal/DPI/C++/host math。

### 8.1 正向数值

至少覆盖并逐 bit核对 result/flags/error/code/call-mask/active-cycles：

- SIGMOID、SOFTPLUS slow、SILU、SWIGLU 的 ordinary ±1；
- `+0/-0` signed-zero路径；
- `src0=-100` 的 internal Inf继续路径；
- SOFTPLUS `0x419fffff/0x41a00000/0x41a00001`；
- SILU reciprocal×MUL 首 witness `src0=0x3a7ff807`；
- SWIGLU numerator-first witness `src0=0x00000001,src1=0x40000000`；
- SWIGLU role witness `src0=1,src1=2`；
- positive/negative minsub 与 source-role signed zero；
- finite SWIGLU positive/negative overflow Inf。

### 8.2 负向与协议

- 每个 opcode 的 consumed external ±Inf/qNaN/sNaN；SWIGLU 独立覆盖 src1 nonfinite；
- `opcode_i=3'd4` unsupported；
- preflight rejection必须 child mask0；
- request busy不采样，response backpressure全 payload稳定，terminal恰好一拍 retire；
- reset注入 EXP/ADD/DIV/LOG/MUL WAIT 与 HOLD，之后无 stale response且可 clean recovery；
- 小 timeout实例覆盖 deadline与child response冲突，必须 code3、payload/flags0、完整 child quarantine、无 reset recovery；
- child error和wrong-owner/ghost定向注入覆盖 code2/code4；
- owner scoreboard逐 handshake检查0/1 cardinality、成功 call mask与固定 DAG一致。

TB 精确 marker：

```text
[NPU-UNARY-GLU-ELEMENT][PASS]
```

### 8.3 Verilator 固定配置

- `verilator --binary --timing --sv -O3 -Wall -Wno-fatal`；
- C++ `-O3 -DNDEBUG -march=native`；
- 不定义 `NPU_ASSERT`，不使用 `--assert`；
- 不使用 `--trace/--trace-fst/--coverage`，不得生成 waveform；
- build/log/cache只写 `tmp/build/unary-glu-element` 与 `tmp/logs/unary-glu-element`；
- pinned third-party warning只可用 source-scoped waiver；新增 RTL/TB 在未豁免 `-Wall` 下必须零 warning/error。

## 9. PASS/GAP 判定

PASS 需要同时满足：

- 四条 DAG raw/flags 与当前 60-case oracle中所选定向向量逐 bit一致；
- 三项 mutation witness由定向 TB检出；
- owner/cardinality、call mask、busy/reset/hold/timeout/quarantine负向全部通过；
- exact parent cycle oracle已写入 TB并通过，不以非零/上限代替；
- build/run原生 rc=0，精确 PASS marker一次，新增文件零 warning/error；
- no assert/no waveform/O3身份与所有产物路径审计通过；
- 保留首次真实 FAIL及 root cause，若无 FAIL则明确记录首次 build/run即通过。

即使本模块 PASS，仍必须报告 GAP：整 vector preflight/atomic bank、多 lane、backend、Qwen和 tokens/s均未实现。
