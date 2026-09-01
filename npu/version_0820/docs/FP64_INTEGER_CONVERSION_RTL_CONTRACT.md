# FP64 / signed-I32 conversion RTL contract

> **确定性 range-reduction 基础合同。** 本文冻结 AOR EXP32/LOG32 profile 所需的
> IEEE binary64 与 signed I32 转换 primitive。它本身不是 EXP、LOG、UNARY、
> SWIGLU 或 Qwen node；primitive PASS 不得外推为这些功能 PASS。只允许 Verilator
> 功能仿真，禁止 CPU/DPI 数值代算、assert、waveform、综合、STA 与 PPA。

## 1. 固定输入与 HardFloat 边界

- Berkeley HardFloat Release 1 archive SHA-256：
  `6b3757c9fbfa2230c6a2b84605e39372cb589dd7500e979c4f0b8ecc8a03b14b`；
- 固定 `RISCV` specialization，include 顺序只允许
  `third_party/hardfloat/source/RISCV` 与 `third_party/hardfloat/source`，不得混入
  8086-SSE 或 ARM-VFPv2 specialization；
- `control=1'b1`，`roundingMode=3'b100` (`round_near_maxMag`)，signedness固定；
- HardFloat converter 均为组合逻辑，外部 wrapper 提供同步 reset、single-
  outstanding holding slot 与 response backpressure。

F64→I32 的 `recFNToIN.intExceptionFlags` 位序固定：

```text
raw_int_flags[2:0] = {invalid, integer_conversion_overflow, inexact}
```

映射为标准 `{NV,DZ,OF,UF,NX}` 时：

```text
flags = {invalid | integer_conversion_overflow, 1'b0, 1'b0, 1'b0, inexact}
```

integer conversion overflow 不得错误映射为 FP `OF`。固定 RISCV specialization
使 NaN/+Inf/正溢出返回 `0x7fffffff`，-Inf/负溢出返回 `0x80000000`；上层不得在
raw invalid/overflow 时把该饱和值当作合法 table index。

I32→F64 对全部 signed 32-bit 输入精确，HardFloat `exceptionFlags` 必须恒为0；
wrapper仍真实输出该5位 flags，以便 parameter/filelist/接线错误可被 TB 观测。

## 2. Module 与事务协议

### 2.1 `TensorNpuFp64ToInt32Rmm`

```text
clk_i / synchronous active-high rst_i
req_valid_i / req_ready_o / operand_i[63:0]
rsp_valid_o / rsp_ready_i
result_o[31:0]
int_flags_o[2:0]
flags_o[4:0]
```

组合 topology：

```text
IEEE F64 raw
 -> fNToRecFN(11,53)
 -> recFNToIN(11,53,32, signedOut=1, RMM)
 -> registered result/raw-int-flags/standard-flags holding slot
```

### 2.2 `TensorNpuInt32ToFp64`

```text
clk_i / synchronous active-high rst_i
req_valid_i / req_ready_o / operand_i[31:0]  // two's-complement raw bits
rsp_valid_o / rsp_ready_i
result_o[63:0]
flags_o[4:0]
```

组合 topology：

```text
signed I32 raw
 -> iNToRecFN(32,11,53, signedIn=1, RMM)
 -> recFNToFN(11,53)
 -> registered result/flags holding slot
```

两模块均采用最保守的 EMPTY/FULL Moore transaction：

- `req_ready_o = !rst_i && !rsp_valid_q`；只在
  `req_valid_i&&req_ready_o` 的上升沿捕获组合结果；
- 捕获后的下一周期 `rsp_valid_o=1`；`rsp_valid_o&&!rsp_ready_i` 时所有 response
  字段逐 bit 保持，输入变化与 busy request 均无影响；
- FULL 中即使 `rsp_ready_i=1`，当拍 `req_ready_o` 仍为0；禁止 retire+accept 同拍，
  旧 response 退休后的下一周期才重新接受 request；
- synchronous `rst_i` 优先于 capture/retire；reset 高时两侧资格均组合压为0，
  上升沿清 valid/result/flags，取消 resident response，deassert 后不得复现 stale
  completion；
- outstanding cardinality始终0或1，每个 request 最多产生一次 response retire。

## 3. 最小 HardFloat filelist

F64→I32：

```text
third_party/hardfloat/source/HardFloat_primitives.v
third_party/hardfloat/source/HardFloat_rawFN.v
third_party/hardfloat/source/fNToRecFN.v
third_party/hardfloat/source/recFNToIN.v
third_party/hardfloat/source/RISCV/HardFloat_specialize.v
rtl/TensorNpuFp64ToInt32Rmm.v
tests/tb_fp64_to_int32_rmm.sv
```

I32→F64：

```text
third_party/hardfloat/source/HardFloat_primitives.v
third_party/hardfloat/source/HardFloat_rawFN.v
third_party/hardfloat/source/iNToRecFN.v
third_party/hardfloat/source/recFNToFN.v
rtl/TensorNpuInt32ToFp64.v
tests/tb_int32_to_fp64.sv
```

两者 include path 均固定 `source/RISCV` 后 `source`。不加入 add/mul/FMA/
div/sqrt，也不把65-bit recFN 暴露为外部 transaction ABI。

## 4. F64→I32 RMM raw-bit oracle

`int_flags` 位序为 `{invalid,integer-overflow,inexact}`，`flags` 位序为
`{NV,DZ,OF,UF,NX}`：

| input F64 | result I32 | int_flags | flags |
|---:|---:|---:|---:|
| `0000000000000000` | `00000000` | `000` | `00` |
| `8000000000000000` | `00000000` | `000` | `00` |
| `0000000000000001` | `00000000` | `001` | `01` |
| `8000000000000001` | `00000000` | `001` | `01` |
| `3fe0000000000000` | `00000001` | `001` | `01` |
| `bfe0000000000000` | `ffffffff` | `001` | `01` |
| `3ff8000000000000` | `00000002` | `001` | `01` |
| `bff8000000000000` | `fffffffe` | `001` | `01` |
| `4004000000000000` | `00000003` | `001` | `01` |
| `c004000000000000` | `fffffffd` | `001` | `01` |
| `3fdfffffffffffff` | `00000000` | `001` | `01` |
| `3fe0000000000001` | `00000001` | `001` | `01` |
| `bfdfffffffffffff` | `00000000` | `001` | `01` |
| `bfe0000000000001` | `ffffffff` | `001` | `01` |
| `41dfffffffc00000` | `7fffffff` | `000` | `00` |
| `c1e0000000000000` | `80000000` | `000` | `00` |
| `41dfffffffd00000` | `7fffffff` | `001` | `01` |
| `c1e0000000080000` | `80000000` | `001` | `01` |
| `41dfffffffe00000` | `7fffffff` | `010` | `10` |
| `c1e0000000100000` | `80000000` | `010` | `10` |
| `41e0000000000000` | `7fffffff` | `010` | `10` |
| `c1e0000000200000` | `80000000` | `010` | `10` |
| `7ff0000000000000` | `7fffffff` | `100` | `10` |
| `fff0000000000000` | `80000000` | `100` | `10` |
| `7ff8000000000000` | `7fffffff` | `100` | `10` |
| `7ff0000000000001` | `7fffffff` | `100` | `10` |
| `fff8000000000000` | `7fffffff` | `100` | `10` |

上表 `flags=10` 是5-bit十六进制 `5'h10`，验证 NV=1、FP OF=0。TB不得只检查
standard flags而遗漏 raw `int_flags`，否则无法区分 invalid 与 integer overflow。

## 5. I32→F64 raw-bit oracle

| input I32 | result F64 | flags |
|---:|---:|---:|
| `00000000` | `0000000000000000` | `00` |
| `00000001` | `3ff0000000000000` | `00` |
| `ffffffff` | `bff0000000000000` | `00` |
| `7fffffff` | `41dfffffffc00000` | `00` |
| `80000000` | `c1e0000000000000` | `00` |
| `00001000` | `40b0000000000000` | `00` |
| `ffffed40` | `c0b2c00000000000` | `00` |
| `01000001` | `4170000010000000` | `00` |
| `feffffff` | `c170000010000000` | `00` |

最后两项 `±(2^24+1)` 防止实现错误地退化为 F32 precision。

## 6. Testbench 协议与负向

两个 TB 都必须只用 fixed raw-bit table，不使用 `real/shortreal`、DPI 或 host
浮点。每个普通 case 只在 request handshake 后撤销 valid，只在 response
handshake 比较并消费 oracle，设置不超过32 cycles的 timeout。

共同覆盖：

1. response 至少5拍 backpressure，result/flags稳定且 `req_ready_o=0`；
2. HOLD 时持续驱动不同 busy request，不得覆盖 resident response；
3. 旧 response `rsp_ready_i=1` 同拍保持新 request valid，必须只 retire、不得
   accept；下一周期新 request仍valid才可 capture；
4. accepted/retired守恒且差值始终0或1，每个 response只消费一次；
5. IDLE reset、resident response reset、reset与retire同拍均以 reset优先；reset
   flush 的 request不计 retired，deassert 后无 stale response且 clean recovery；
6. reset高时 `req_ready_o/rsp_valid_o` 均0，response registers在同步reset edge后清0。

固定 marker：

```text
[NPU-FP64-I32-RMM][PASS]
[NPU-I32-FP64][PASS]
```

失败路径不得先打印 PASS；正式配置不启用 RTL assertions，因此协议检查使用
procedural monitor与 `$fatal`。

## 7. AOR internal-NX 边界

F64→I32 wrapper 忠实输出所有 flags。AOR range-reduction 顶层必须另行执行：

```text
range_fault = invalid || integer_overflow || k<K_MIN || k>K_MAX
internal_nx = inexact
```

`internal_nx=1` 且 k 在范围内是正常 range rounding，可以继续，但不得直接 OR
进最终 EXP architectural NX。NaN/Inf/顶层 overflow-underflow saturation 应在进入
converter 前由 EXP special classifier 旁路。I32→F64 的任意非零 flags 均为内部
合同失败。

## 8. Verilator PASS 与 GAP

固定功能配置：

```text
verilator --binary --timing --sv -O3 -Wall -Wno-fatal
C++: -O3 -DNDEBUG -march=native
assertions=off, waveform=off
Mdir/log/TMPDIR/cache全部位于项目tmp/
```

PASS 要求两份新增 RTL/TB 均零 warning/error、各自 build/run rc=0、精确 marker、
无 wave，并保留首次反例与 root cause。仍是 GAP：AOR ROM/多项式/特殊值顶层、
EXP/LOG source-replay oracle 实现、UNARY/GLU、backend/Qwen整图、shell对话、
tokens/s，以及全部综合/STA/PPA。

### 8.1 2026-08-21 Verilator 功能证据

两项 primitive 已按机器合同
`tmp/contracts/fp64_integer_conversions_v1.json`（SHA-256
`94a94bf654c1f6ea9c9504dbee5bba65f2554aaf18e093a5bdd340867b7b00be`）
落盘并通过定向功能仿真：

- F64→I32 实际执行全部27项 result/raw-int-flags/standard-flags oracle；
- I32→F64 实际执行9项 oracle，包括 `±(2^24+1)` 防 F32 精度退化反例；
- 两组均覆盖5拍 response hold、变化中的 busy request、禁止同拍 retire+accept、
  单次消费、IDLE/resident/reset-over-retire 与 reset 后 clean recovery；
- 两组定向 build/run 均 `rc=0`，精确 marker 分别为
  `[NPU-FP64-I32-RMM][PASS]` 与 `[NPU-I32-FP64][PASS]`；
- 新增四文件无 Verilator warning/error；定向 build 保留的 diagnostics 全部来自
  未修改 HardFloat Release 1，类别为 `DECLFILENAME/TIMESCALEMOD/GENUNNAMED/
  WIDTH*/UNUSEDSIGNAL`；
- 加入 `scripts/run_npu_regression.sh` 后的一次固定总回归 `rc=0`，最终 marker
  为 `[NPU-REGRESSION][PASS] tests=29 assertions=off waveform=off
  optimization=O3`；aggregate 只对上述已审计 vendor 类别做定向 waiver；
- aggregate build/run 日志的 `%Warning/%Error/[NPU-*][FAIL]` 零匹配，构建与
  日志树中波形扩展名零文件；未运行综合、STA 或 PPA。

固定证据 SHA-256：

```text
445a3475982d2ce47bb1f2aa201ffe67262ae202e16d4e0bfcdfce990ae45f18  rtl/TensorNpuFp64ToInt32Rmm.v
b9d0a142d92a1a92c6ec75bab356eb11caf368860cf47392c1e3622eea158f0c  rtl/TensorNpuInt32ToFp64.v
c887e54f34a527c1261e4645376a874095b39b870fd7080e663b8b6b16d50712  tests/tb_fp64_to_int32_rmm.sv
880e0f2fc4380da4b320dd18104fe19ad734c98cdf6389908d781d333f34dc73  tests/tb_int32_to_fp64.sv
26b7315be154448af659eb0a2eb0faf56e85838743a4ce71359f5dd049f0a868  tmp/logs/fp64-integer-conversions/fp64-to-i32-rmm.build.log
99a2374ae823684425b637605ddc8813f3d05ac59b14ff1e1f6ed3a925248ae6  tmp/logs/fp64-integer-conversions/fp64-to-i32-rmm.run.log
fc1c2b7e96be288bd4ec87022c76e16123346dd8e29f3ad1fbba866632274cc1  tmp/logs/fp64-integer-conversions/i32-to-fp64.build.log
3e7936e3d55054104c446d68595a6a34f059514049b81e98a0604a1847e0a90a  tmp/logs/fp64-integer-conversions/i32-to-fp64.run.log
01b3d7a7ff235e2a0d3fcfb4b576718af7054e9ad30d9eead9109c4efea68f02  tmp/logs/npu-regression/tb_fp64_to_int32_rmm.build.log
a2ca2028e9ab1810cc03fd221637cc52cc2fa62fd6ba6b47ff2f29a627daab10  tmp/logs/npu-regression/tb_fp64_to_int32_rmm.run.log
18a87e24d6ff0c699f18d293b42d00691092194f6a92f1769e65f4e15607b847  tmp/logs/npu-regression/tb_int32_to_fp64.build.log
453a8ca02b5600da1fda45e0826957e73918ad817208033cd3b566e66ea573be  tmp/logs/npu-regression/tb_int32_to_fp64.run.log
```

本轮没有项目 RTL/TB 首次功能失败；定向 `-Wall` 首次诊断即为已锁定 vendor
源码类别，项目四文件路径命中为零。该 PASS 只关闭两项转换 primitive，不关闭本节
列出的 AOR/UNARY/Qwen 系统级 GAP。
