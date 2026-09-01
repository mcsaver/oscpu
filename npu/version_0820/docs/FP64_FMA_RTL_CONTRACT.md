# FP64 MUL/FMA RTL contract

> **基础算术合同。** 本文冻结后续 deterministic `EXP32/LOG32` profile 所需的
> IEEE binary64 `a*b+c` 单轮舍入 primitive。它本身不是超越函数、UNARY、
> SWIGLU 或 Qwen node；primitive PASS 不得外推为上述任何功能 PASS。只允许
> Verilator 功能仿真，禁止 CPU/DPI 数值代算、综合、STA 与 PPA。

## 1. 固定输入与第三方边界

- Berkeley HardFloat Release 1 archive SHA-256：
  `6b3757c9fbfa2230c6a2b84605e39372cb589dd7500e979c4f0b8ecc8a03b14b`。
- 许可证：BSD-3-Clause；wrapper 保留 SPDX 和上游 license 文件。
- 只实例化 `fNToRecFN(11,53)`、`mulAddRecFN(11,53)`、
  `recFNToFN(11,53)`；`op=2'b00`，`roundingMode=RNE(000)`，
  `control=tininess-after-rounding(1)`。
- 三个 IEEE raw binary64 输入均允许正负、零、subnormal、normal、Inf 和 NaN；
  special value、canonical NaN 和 `{NV,DZ,OF,UF,NX}` flags 采用这份 pinned
  HardFloat specialization 的结果。父级 deterministic profile 若需要另一 NaN
  policy，必须在进入本 primitive 前分类或在其后显式 canonicalize。

## 2. Module 与事务

```text
module TensorNpuFp64Fma
  clk_i / synchronous active-high rst_i
  req_valid_i / req_ready_o
  operand_a_i[63:0], operand_b_i[63:0], operand_c_i[63:0]
  rsp_valid_o / rsp_ready_i
  result_o[63:0], flags_o[4:0]
```

语义严格为：

```text
result,flags = RN64_RNE(a*b+c) with one fused rounding
```

`c=+0` 即 MUL；不得把 FMA 拆成先 `RN64(a*b)` 再 ADD。wrapper 是
single-outstanding EMPTY/FULL Moore transaction：只在
`req_valid_i&&req_ready_o` 采样三个 raw operand；接受边沿把组合 HardFloat 结果
写入 holding register，下一周期 `rsp_valid_o=1`。response backpressure 期间
`result/flags` 逐 bit 保持且 `req_ready_o=0`；busy request 不采样。response
handshake 后回 EMPTY。`rst_i` 期间两侧资格均为0；同步 reset 取消 resident
response且不得在 deassert 后复现 stale completion。

## 3. RTL topology 与不变量

```text
IEEE a/b/c
 -> three fNToRecFN(11,53)
 -> one combinational mulAddRecFN(11,53, op=00, RNE, tininess-after)
 -> recFNToFN(11,53)
 -> registered result/flags holding slot
```

- outstanding cardinality 始终为0或1；
- 无 request handshake 不得改变 held response；
- FULL 时输入变化或 busy request 不得影响 resident payload；
- flags 与 result 在同一 request 边沿原子捕获；
- reset 优先级高于 request/response；
- 不使用 `real/shortreal`、DPI、host 浮点、assert、trace 或 waveform；
- 不隐藏握手/FSM于 function，不增加未声明 pipeline 或共享仲裁。

该组合关键路径很长，但本阶段明确不综合、不做 STA/PPA；不得因物理推断改变
数值/事务语义。以后若插入 pipeline，必须保持请求顺序、flags 绑定与 backpressure
合同，并建立新的 cycle profile。

## 4. Raw-bit directed oracle

TB 至少冻结以下 raw vector；flags 位序为 `{NV,DZ,OF,UF,NX}`：

| case | `a` | `b` | `c` | result | flags |
|---|---:|---:|---:|---:|---:|
| exact positive | `3ff8000000000000` | `4000000000000000` | `3fe0000000000000` | `400c000000000000` | `00` |
| exact signed | `bff8000000000000` | `4000000000000000` | `3fe0000000000000` | `c004000000000000` | `00` |
| fused-only discriminator | `3ff0000000000001` | `3feffffffffffffe` | `bff0000000000000` | `b970000000000000` | `00` |
| tie retained-even | `3ff0000000000000` | `3ff0000000000000` | `3ca0000000000000` | `3ff0000000000000` | `01` |
| tie retained-odd | `3ff0000000000001` | `3ff0000000000000` | `3ca0000000000000` | `3ff0000000000002` | `01` |
| exact subnormal | `0010000000000000` | `3fe0000000000000` | `0000000000000000` | `0008000000000000` | `00` |
| half-min-subnormal | `0000000000000001` | `3fe0000000000000` | `0000000000000000` | `0000000000000000` | `03` |
| overflow | `7fefffffffffffff` | `4000000000000000` | `0000000000000000` | `7ff0000000000000` | `05` |
| invalid zero-times-inf | `0000000000000000` | `7ff0000000000000` | `3ff0000000000000` | `7ff8000000000000` | `10` |
| invalid inf-minus-inf | `7ff0000000000000` | `3ff0000000000000` | `fff0000000000000` | `7ff8000000000000` | `10` |
| signed zero | `8000000000000000` | `4000000000000000` | `8000000000000000` | `8000000000000000` | `00` |

`fused-only discriminator` 的精确值为
`(1+2^-52)*(1-2^-52)-1 = -2^-104`；若实现错误地分两次舍入会得到0。
TB 还必须覆盖至少3拍 response hold、busy request ignored、response单次消费、
inflight reset取消和 deassert 后 clean recovery，marker 固定为
`[NPU-FP64-FMA][PASS]`。

## 5. PASS 与 GAP

截至 2026-08-21，`rtl/TensorNpuFp64Fma.v` 与
`tests/tb_fp64_fma.sv` 已按机器合同
`tmp/contracts/fp64_fma_v1.json`（SHA-256
`9a04d9f90cfd9b1dfa31ad68af6af17fa3e0f2787f123b2d880695eec0f5bbac`）
落盘。定向 Verilator build/run 均返回0，运行日志
`tmp/logs/fp64-fma/verilator-run.log` 精确命中
`[NPU-FP64-FMA][PASS]`。新增 RTL/TB 无 warning/error；build log 只保留
pinned HardFloat `HardFloat_localFuncs.vi` 的两条既有 `VARHIDDEN` 诊断。

该 primitive 也已作为独立 filelist 纳入 `scripts/run_npu_regression.sh`
的第25项。2026-08-21 的一次固定 aggregate build/run 返回0，末行精确为
`[NPU-REGRESSION][PASS] tests=25 assertions=off waveform=off optimization=O3`；
全部 build/run log 的 warning/error/FAIL 扫描及 waveform 文件扫描均为零匹配。
aggregate 回归只对上述已审计 vendor `VARHIDDEN` 类别做定向 waiver，项目
RTL/TB 仍保持 `-Wall`。

PASS 仅表示 pinned HardFloat + wrapper 对上述 raw-bit transaction 在
Verilator `--binary --timing --sv -O3 -Wall -Wno-fatal`、C++
`-O3 -DNDEBUG -march=native`、assert/wave关闭下通过。仍是 GAP：TestFloat
全域回归、EXP/LOG ROM/多项式、F64-to-int/int-to-F64、父级 flags policy、
UNARY/SWIGLU、backend/Qwen/tokens/s，以及全部综合/STA/PPA。
