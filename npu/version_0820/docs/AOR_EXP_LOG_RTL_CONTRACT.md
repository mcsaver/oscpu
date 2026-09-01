# AOR EXP32 / LOG32 RTL contract

> **本地 RV64 NPU 非线性 primitive 合同。** 本文把纯整数 oracle
> `AOR_AARCH64_FMA_RNE_V1` 映射为三个可综合 Verilog-2001 module：
> `TensorNpuFp64ToFp32Finite`、`TensorNpuAorExp32` 和
> `TensorNpuAorLog32`。本切片只允许 Verilator 功能仿真；禁止
> host/DPI 浮点代算、assert、waveform、综合、STA 与 PPA。primitive PASS
> 不得外推为 UNARY/GLU、GDN、attention、Qwen 整图或 shell 对话 PASS。

## 1. 固定身份与许可

- 上游算法：Arm optimized-routines commit
  `67126040cf80f956676fbf473c2d9bebdb475283`；
- profile：`AOR_AARCH64_FMA_RNE_V1`；
- flags profile：`AOR_STEP_STICKY_V1`；
- manifest canonical SHA-256：
  `4d7b403b5f835adfc4465f920a9322ddf71b7568aaf0f1790c84e0b81371f004`；
- oracle generator SHA-256：
  `d18d79a44940d2e7ce915b64bc6cf65383f2307d9d16ec792d6e4077c2d59e95`；
- fixed JSONL SHA-256：
  `e635c1ce963bb814f746dc828d715bd6cc39841f11ed8551aa7b15f128fcaa41`；
- mutation audit SHA-256：
  `08be44d7812edfd8ff72d70478cc84801e10e6cd8f38d9ff57b5628852c0630d`；
- HardFloat Release 1 archive SHA-256：
  `6b3757c9fbfa2230c6a2b84605e39372cb589dd7500e979c4f0b8ecc8a03b14b`。

表项、常量和多项式顺序派生自 Arm optimized-routines，选择其 MIT
许可路径。嵌入表项的 RTL 必须保留固定 commit、来源文件、Arm copyright
和 MIT SPDX/notice；不得把本 profile 冒充所有编译器/ISA 下的 `libm`
raw-bit 行为。上游六个源文件当前未 vendoring，逐文件 SHA 仍是
`GAP_SOURCE_FILES_NOT_VENDORED_NO_LOCAL_CONTENT_SHA256`；本合同只绑定上述
commit、已审计 manifest、oracle 和向量身份。

## 2. Module 接口

### 2.1 `TensorNpuFp64ToFp32Finite`

现有 `TensorNpuFp64ToFp32` 只接受非负输入，不能承载 `log(x<1)` 的负
有限结果。必须新增独立 wrapper，不得放宽或改写旧模块合同。

```text
clk_i / synchronous active-high rst_i
req_valid_i / req_ready_o / operand_i[63:0]
rsp_valid_o / rsp_ready_i
result_o[31:0]
flags_o[4:0] = {NV,DZ,OF,UF,NX}
error_o
```

合法域是全部有限 IEEE binary64，包括正负 normal、subnormal 与 `+0/-0`。
exponent 全1的 NaN/Inf 输入原子 fail-closed：`result=0,flags=0,error=1`。
组合 topology 固定为：

```text
F64 raw -> fNToRecFN(11,53)
        -> recFNToRecFN(11,53 -> 8,24, RNE, tininess-after)
        -> recFNToFN(8,24)
        -> registered EMPTY/FULL holding slot
```

EMPTY/FULL 协议与已有 FP wrapper 相同：请求 handshake 的下一周期形成
resident response；FULL 反压期间 payload 保持；FULL retire 当拍不接受新请求；
reset 高时两侧资格为0并在上升沿清除 resident response。

### 2.2 `TensorNpuAorExp32` / `TensorNpuAorLog32`

两个顶层使用同一接口与 error code：

```text
parameter integer COMMAND_TIMEOUT_CYCLES = 128

clk_i / synchronous active-high rst_i
req_valid_i / req_ready_o / operand_i[31:0]
rsp_valid_o / rsp_ready_i
result_o[31:0]
flags_o[4:0] = {NV,DZ,OF,UF,NX}
error_o
error_code_o[3:0]
active_cycles_o[31:0]
```

错误码固定：

```text
0 OK
1 UNSUPPORTED_NAN_OR_LOG_NEGATIVE
2 CHILD_OR_PROFILE_FAULT
3 COMMAND_TIMEOUT
4 INTERNAL_PROTOCOL_FAULT
```

`error_o=1` 时 `result_o=0,flags_o=0`，不得暴露部分数值。成功特殊值分支
可以返回 Inf：EXP 的 `+Inf`、LOG 的 `±0 -> -Inf,DZ` 和 `+Inf` 都是
`error_o=0`。一个 response 未 retire 前不接受下一 request；response hold 期间
`result/flags/error/error_code/active_cycles` 全部稳定。最保守实现禁止 retire 与
下一 request 同拍 accept。

`active_cycles_o` 是 launch-inclusive：request handshake 后第一拍计1，到 terminal
payload 写入 holding slot 的边沿为止；response backpressure 不再增加该值。计数器饱和，
禁止 wrap。

## 3. 共享 child topology

每个 AOR 顶层各自实例化以下资源；本切片不在 EXP 与 LOG 之间跨 module 共享：

```text
1 x TensorNpuFp32ToFp64
1 x TensorNpuFp64Fma
1 x TensorNpuFp64ToInt32Rmm   // EXP only
1 x TensorNpuInt32ToFp64
1 x TensorNpuFp64ToFp32Finite
```

LOG 不实例化 F64→I32；其 `k` 来自 integer range-reduction ASR。EXP 与 LOG
内部所有 F64 MUL 都必须通过 `TensorNpuFp64Fma(a,b,+0)`，LOG 的独立
`y0+r` ADD 必须通过 `TensorNpuFp64Fma(+1,y0,r)`。在本 module 接受的有限
数据域内，这两种接法与各自单次舍入 MUL/ADD 同一 raw/flags；不得把相邻 AOR
节点融合、重结合或拆成两次舍入。每个顶层只有一个 FMA 实例，FSM 显式提供
operand mux、request enable 和 response owner；任意周期最多一个 child request
outstanding。

child wrappers 都是 registered single-outstanding response。父 FSM 的 REQ 状态在
`valid&&!ready` 时保持 op/operands；request handshake 后进入唯一 WAIT 状态并只给
该 child response credit。错误 child response、非预期 flag/class、非法 FSM state 或
幽灵 response 必须 fail-closed。

所有 child reset 由 `rst_i || abort_reset || terminal_quarantine` 驱动，其中
`terminal_quarantine` 在 `ST_HOLD_RESPONSE` 整段为 1。父 response 一旦原子发布，
所有 child resident/ghost 状态必须在 retire 前同步清空；不得在 HOLD 退出后产生一个
没有新 request 对应的额外 error response。command timeout 若发生在未接受的 REQ，
可直接取消；若发生在已经接受的 WAIT，先进入一个整拍 `ABORT_RESET` 同步取消 resident
child，再发布 timeout response。新请求只能在 abort 后 terminal response retire、
所有 child 回到 EMPTY 后接受。

## 4. EXP32 固定数据流与 FSM

### 4.1 special classifier

分类先于任何 child request：

| input | result | flags | error |
|---:|---:|---:|---:|
| `+0/-0` | `3f800000` | `00` | 0 |
| `-Inf` | `00000000` | `00` | 0 |
| `+Inf` | `7f800000` | `00` | 0 |
| qNaN/sNaN | `00000000` | `00` | 1/code1 |
| finite `x > 42b17217` | `7f800000` | `05` (`OF|NX`) | 0 |
| finite `x < c2cff1b4` | `00000000` | `03` (`UF|NX`) | 0 |

比较必须是 ordered numeric 且严格 `>`/`<`。`42b17217`、`c2cff1b4`
自身进入正常 DAG；`42b00000` 只允许作为 coarse gate，不能当真实 overflow
threshold。

### 4.2 normal DAG

固定状态顺序（每个 `*_REQ` 后必须有独立 `*_WAIT`）：

```text
IDLE -> CLASSIFY
 -> X64_REQ/WAIT       xd = exact F32_TO_F64(x)
 -> Z_REQ/WAIT         z  = RN64(invln2_scaled*xd)
 -> K_REQ/WAIT         k  = F64_TO_I32_RMM(z)       // source必须是z
 -> KD_REQ/WAIT        kd = exact I32_TO_F64(k)
 -> KD_ZERO_SIGN       if k==0, kd.sign=z.sign
 -> R_REQ/WAIT         r   = FMA(-1,kd,z)
 -> SCALE_INTEGER      idx=k[4:0], scale=tab[idx]+(sext64(k)<<47) mod2^64
 -> P01_REQ/WAIT       p01 = FMA(C0,r,C1)
 -> R2_REQ/WAIT        r2  = RN64(r*r)
 -> P2_REQ/WAIT        p2  = FMA(C2,r,+1)
 -> P_REQ/WAIT         p   = FMA(p01,r2,p2)
 -> Y_REQ/WAIT         y   = RN64(p*scale)
 -> PACK_REQ/WAIT      out = F64_TO_F32_RNE(y)
 -> HOLD_RESPONSE
```

`K_REQ` 绝不能消费 `kd`。转换 NX 只用于 trace/协议检查，不进入 API flags；
raw int flags 的 invalid/overflow 或 `k<-4800 || k>4096` 是 code2。`KD` conversion
任意 flag 是 code2。F32 widen 必须 flags0/error0。

EXP ROM 长度严格32，case index `0..31` 逐项等于 manifest。负 `k` 先符号扩展为
64-bit two's-complement，再左移47并做64-bit modulo；禁止 signed `%32`、饱和或
浮点 scale 构造。

### 4.3 EXP flags

F64 FMA/MUL 的 step flags 与 final pack flags全部 sticky OR；只有 K conversion
的 NX 屏蔽。normal DAG 的 F64 intermediate 必须 finite；unexpected NaN/Inf 或
F64 child `NV/DZ/OF/UF` 是 code2。final pack 的 `OF|NX`、`UF|NX` 与普通 NX
均是合法成功 flags。

## 5. LOG32 固定数据流与 FSM

### 5.1 special classifier

| input | result | flags | error |
|---:|---:|---:|---:|
| `3f800000` | `00000000` | `00` | 0 |
| `+0/-0` | `ff800000` | `08` (`DZ`) | 0 |
| `+Inf` | `7f800000` | `00` | 0 |
| 负有限非零、`-Inf` | `00000000` | `00` | 1/code1 |
| qNaN/sNaN | `00000000` | `00` | 1/code1 |

### 5.2 positive subnormal normalize

对 `frac=input[22:0]` 的正 subnormal：

```text
m      = floor(log2(frac))                    // 0..22
y_exp  = m+1
y_frac = (frac << (23-m)) & 007fffff
iy     = (y_exp<<23) | y_frac
ix     = u32(iy-0b800000)
```

highest-one 逻辑允许小型纯组合 function/case，必须在注释中说明综合为23-bit priority
encoder；不能调用 real、DPI 或 host helper。normal 正数令 `ix=input_raw`。

### 5.3 range reduction 与 normal DAG

```text
tmp = u32(ix-3f330000)
i   = (tmp>>19)&15
k   = asr32(tmp,23)
iz  = u32(ix-(tmp&ff800000))
```

随后按固定状态：

```text
IDLE -> CLASSIFY -> NORMALIZE -> REDUCE
 -> Z64_REQ/WAIT      z    = exact F32_TO_F64(iz)
 -> R_REQ/WAIT        r    = FMA(z,invc[i],-1)
 -> KD_REQ/WAIT       kd   = exact I32_TO_F64(k)
 -> Y0_REQ/WAIT       y0   = FMA(kd,ln2,logc[i])
 -> R2_REQ/WAIT       r2   = RN64(r*r)
 -> P12_REQ/WAIT      p12  = FMA(A1,r,A2)
 -> P0_REQ/WAIT       p0   = FMA(A0,r2,p12)
 -> TAIL_REQ/WAIT     tail = RN64(y0+r)      // FMA(+1,y0,r)
 -> Y_REQ/WAIT        y    = FMA(p0,r2,tail)
 -> PACK_REQ/WAIT     out  = signed-finite F64_TO_F32_RNE(y)
 -> HOLD_RESPONSE
```

LOG ROM 必须精确包含16对 `{invc,logc}`。`tmp>>19` 是 logical slice，`k` 是
signed arithmetic shift；`iz` 所有减法是 U32 modulo。`invln10` 不得接入本 DAG。

### 5.4 LOG flags

F64 FMA/MUL 和 final pack 的所有 step flags sticky OR。widen/I32→F64 任意 flag
是 code2。正有限 normal DAG 的所有 F64 intermediate 必须 finite；unexpected
NaN/Inf 是 code2。AOR primitive返回其真实 sticky flags；是否把某些内部 OF/UF
提升为 tensor fatal 由后续 Unary/GLU 父事务决定，本模块不得根据最终 raw 反推或
静默抹掉 flags。

## 6. FSM、优先级与不变量

两个顶层必须在写 RTL 前按阶段1/2a--2e留痕，并至少证明：

1. `req_ready_o` 只在 IDLE 且 `!rst_i`；busy request不采样。
2. 任意周期 child outstanding 总数为0或1；REQ/WAIT owner与当前状态唯一对应。
3. child request `valid&&!ready` 时 operand稳定；WAIT 只消费匹配 child一次。
4. 任一中间寄存器只在对应 child response handshake成功后更新。
5. flags accumulator在新 request handshake清零，只OR实际完成节点；K NX不OR。
6. success/error response只在 terminal staging边沿原子写入；此前外部无credit。
7. response hold期间所有payload稳定；retire当拍不接受新request。
8. reset取消父/child resident事务并清response valid；deassert后不得出现stale completion。
9. timeout/error先经过 `ABORT_RESET`，新事务不能与旧child response混淆。
10. active cycle与command watchdog均饱和，不wrap；terminal hold不继续计数。
11. 非法FSM编码转 code4，并先同步reset child。
12. 所有 ROM case有default，但default只能触发内部fault，不能猜表项。
13. `ST_HOLD_RESPONSE` 期间 `child_rst=1`，所有 child `rsp_valid=0`；父 response
    payload保持不变，retire后直接回 IDLE，不得排队或发布第二个 terminal。
14. TB维护0/1 child outstanding owner：每次 request handshake建立owner，仅匹配
    response handshake清除；outstanding存在时禁止任何其它child request handshake。

同拍优先级固定：

```text
rst_i
> child/profile/internal fatal
> command timeout
> normal child response/progress
> response hold/retire
```

`COMMAND_TIMEOUT_CYCLES=128` 必须大于默认固定DAG正常 latency。TB另实例化小
timeout配置制造有界 code3；timeout与child response同拍时timeout优先，且不得先发布
success。`HOLD_RESPONSE` 不运行command watchdog。

## 7. RTL topology 约束

- 可综合 module写 `.v`，只用 Verilog-2001 `wire/reg/always @(*)/always
  @(posedge clk)`；禁 `logic/always_comb/always_ff`。
- FSM、valid/ready、resource mux、watchdog、flags/active counters必须显式逻辑，
  不得封装function。
- function只允许 ROM case、leading-one、finite/raw predicate等小型纯组合helper。
- 一个顶层仅一个 FMA resource；状态显式选择A/B/C及request enable。
- 所有 state/output/temporary/flags/error/cycle register由单一posedge owner更新；
  组合输出块先给默认值，禁止latch。
- 最长算术路径留在 HardFloat FMA/format-conversion child；parent组合路径只允许
  ROM mux、raw classify、index/shift/add和状态译码。
- 不新增 assertion、trace、DPI、`real/shortreal`、wave dump或host FPU oracle。

## 8. Testbench 与 oracle 覆盖

新增纯 raw-bit TB：

```text
tests/tb_fp64_to_fp32_finite.sv
tests/tb_aor_exp32.sv
tests/tb_aor_log32.sv
```

每个 TB 使用procedural monitor和`$fatal`，不启用RTL assert/wave。所有 expected
来自已冻结 JSONL/mutation audit，必须在注释中写源 case ID/input/raw/flags；不得使用
`real/shortreal`、DPI、C++/Python在线oracle或libm。

### 8.1 signed-finite pack TB

至少覆盖：`±0`、`±1`、正负F32 normal/subnormal边界、retained-even/odd tie、
正负 overflow、NaN/Inf fail-closed、5拍response hold、busy request、禁止retire+accept
同拍、resident reset与clean recovery。

tininess-after边界必须绑定新纯整数oracle，不得用最终exponent field猜`UF`：

- `380fffffdfffffff -> 007fffff, UF|NX`；
- `380fffffe0000000 -> 00800000, UF|NX`；
- SoftFloat FAQ `380fffffe1000000 -> 00800000, UF|NX`；
- 真正precision-only carry边界`380ffffff0000000 -> 00800000, NX`；
- 上述四项全部覆盖负数sign-bit镜像，flags必须相同。

marker：

```text
[NPU-FP64-FP32-FINITE][PASS]
```

### 8.2 EXP TB

至少覆盖：

- JSONL内全部32个EXP table index directed case，并观察内部index/scale与trace一致；
- `±0`、`±Inf`、qNaN/sNaN；
- `42b17217/42b17218`、`c2cff1b4/c2cff1b5`；
- `±minsub` 的 `1.0,NX`；
- `k=-33,-32,-31,-1,0,1,31,32,33`；
- M09/M10/M12 witness的内部 `p01/p2/p` 或对应stage raw；
- M11只保留bounded GAP说明，不宣称FMA拆分等价；
- output 5拍backpressure、busy start、reset in-flight/response、timeout实例、
  terminal单次消费、active cycle稳定、下一事务flags清零；
- special、normal DAG、code1、code3的launch-inclusive精确active-cycle oracle；
- timeout与已接受child response同拍时code3优先，完整经过`ABORT_RESET`，且无
  stale completion；
- child/profile fatal的code2、ghost/illegal-state的code4；两者均清零payload、只发布
  一个terminal，并在无外部reset时恢复下一事务。

marker：

```text
[NPU-AOR-EXP32][PASS]
```

### 8.3 LOG TB

至少覆盖：

- JSONL内全部16个LOG table index directed case；
- 六个正subnormal normalize seed和23种leading-one位置；
- `1.0`、`±0`、`+Inf`、负normal/`-Inf`、qNaN/sNaN；
- `3f7fffff/3f800000/3f800001`；
- M23/M24/M26 witness内部 `r/y0/y` raw；
- output hold、busy/reset/timeout、单次消费、active cycle与flags无泄漏；
- special、normal DAG、code1、code3的launch-inclusive精确active-cycle oracle；
- timeout与已接受child response同拍时code3优先，完整经过`ABORT_RESET`，且无
  stale completion；
- child/profile fatal的code2、ghost/illegal-state的code4；两者均清零payload、只发布
  一个terminal，并在无外部reset时恢复下一事务。

marker：

```text
[NPU-AOR-LOG32][PASS]
```

## 9. Verilator 配置与成功边界

每个 directed build/run只执行固定一次，输入/设计变化后才重建：

```text
verilator --binary --timing --sv -O3 -Wall -Wno-fatal
C++ flags: -O3 -DNDEBUG -march=native
assertions=off
waveform=off
```

include顺序固定 HardFloat `source/RISCV` 后 `source`。filelist只加入实际依赖的
HardFloat module、现有 child、新增 RTL 与对应 TB。build/log/TMPDIR/cache全部位于：

```text
tmp/build/aor-exp-log-rtl/
tmp/logs/aor-exp-log-rtl/
```

新增 RTL/TB 必须零 warning/error。仅允许对逐条确认属于未修改 HardFloat Release 1
源码的已知 warning做source-scoped waiver；禁止用全局 `-Wno-*` 隐藏project-owned
diagnostic。build/run均rc0、精确marker各一次、FAIL零匹配、无wave/core文件。

同一fail-closed evidence receipt必须绑定RTL/TB/vector SHA、完整Verilator command与
精确filelist、`*__verFiles.dat`、实际运行binary哈希或等价build identity、exec rc的
外部观察权限说明、run-log SHA及唯一PASS marker。单独的source SHA与单行PASS log
不能证明当前source、binary和执行结果属于同一事务身份。

成功只关闭三个 primitive的本地Verilator功能合同。仍为GAP：上游六文件本地逐文件SHA、
all-NaN raw profile、共享/流水化吞吐优化、Unary/GLU tensor engine、GDN/attention、
llama backend required-op执行、Qwen shell对话与tokens/s。禁止执行综合、STA或PPA。
