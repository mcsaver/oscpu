# FP32 sqrt RTL 合同

> **实现阶段合同。** 本文冻结 project-owned `TensorNpuFp32Sqrt` 对固定开源 FPU 的最小封装、事务时序和 raw-bit oracle。该 primitive 是 RMS/L2 norm 与后续 rsqrt 的基础，不等于 norm、Qwen 算子或整模 PASS。禁止综合、STA、PPA、DPI/host 浮点代算、assert 默认开启或 waveform。

## 1. 固定第三方输入

唯一上游实现：

```text
repository = taneroksuz/fpu-sp
commit     = 14f7f9f88a97f96d2cbfa1988bdd958bfaaddae8
license    = MIT
mode       = fp_fdiv #(.PERFORMANCE(0)), op.fsqrt=1
```

固定源码永久链接：

- [`fp_fdiv.sv`](https://github.com/taneroksuz/fpu-sp/blob/14f7f9f88a97f96d2cbfa1988bdd958bfaaddae8/verilog/src/float/fp_fdiv.sv)
- [`fp_ext.sv`](https://github.com/taneroksuz/fpu-sp/blob/14f7f9f88a97f96d2cbfa1988bdd958bfaaddae8/verilog/src/float/fp_ext.sv)
- [`fp_rnd.sv`](https://github.com/taneroksuz/fpu-sp/blob/14f7f9f88a97f96d2cbfa1988bdd958bfaaddae8/verilog/src/float/fp_rnd.sv)
- [`fp_wire.sv`](https://github.com/taneroksuz/fpu-sp/blob/14f7f9f88a97f96d2cbfa1988bdd958bfaaddae8/verilog/src/float/fp_wire.sv)
- [upstream latency table](https://github.com/taneroksuz/fpu-sp/blob/14f7f9f88a97f96d2cbfa1988bdd958bfaaddae8/README.md#latency)
- [upstream TestFloat generator](https://github.com/taneroksuz/fpu-sp/blob/14f7f9f88a97f96d2cbfa1988bdd958bfaaddae8/tests/generate.sh)

固定版本的官方 Verilator/TestFloat 路径通过 `fp_unit` 使用默认 `PERFORMANCE=0`；README 虽标称 `PERFORMANCE=1` 为14 cycles，但该参数分支没有被固定版本的官方 SV regression直接验证。因此 v1 禁止启用 PERFORMANCE=1，也不得把其标称延迟当成本项目证据。

## 2. Module 接口

```systemverilog
module TensorNpuFp32Sqrt (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [31:0] operand_bits_i,
    input  wire [2:0]  rounding_mode_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_bits_o,
    output wire [4:0]  flags_o
);
```

外部 reset `rst_i` 使用项目约定的同步高有效语义；wrapper 必须把第三方 core 的同步低有效 `reset` 正确反相。reset期间 `req_ready_o=0`，并清除 busy、held response及所有本地 epoch。

单 outstanding 协议：

```text
req_fire = req_valid_i && req_ready_o
req_ready_o = !rst_i && !busy_q && !rsp_valid_q
```

- 只在 `req_fire` 周期把 `op.fsqrt` 拉高一拍；其它 operation位全0，`fmt=2'b00`，`rm=rounding_mode_i`。
- raw operand必须先通过 `fp_ext`，把其33-bit pseudo-extended result和10-bit classification送入 `fp_fdiv.data1/class1`；不得用raw拼接替代。
- sqrt不使用data2；data2/class2固定0。
- `fp_fdiv_o.ready` 是无背压的单拍 completion pulse；wrapper必须在该拍无条件捕获 `fp_rnd_o.result/flags` 到held response。
- `rsp_valid_o && !rsp_ready_i` 时result/flags保持稳定。response消费前不接受下一request；允许一个bubble，不做同拍consume/relaunch优化。
- busy期间新request不启动、不覆盖operand/rm；held-high req_valid只能在重新获得ready后形成新事务。

## 3. 第三方 core 接线

固定启动字段：

```text
fp_fdiv_i.op          = init_fp_operation
fp_fdiv_i.op.fsqrt    = req_fire
fp_fdiv_i.fmt         = 2'b00
fp_fdiv_i.rm          = rounding_mode_i
fp_fdiv_i.data1       = fp_ext_o.result
fp_fdiv_i.class1      = fp_ext_o.classification
fp_fdiv_i.data2       = 0
fp_fdiv_i.class2      = 0
fp_fdiv.clear         = 0
fp_mac_o              = 0
```

上游没有public `op_mod` port；项目接口不得发明或依赖该字段。`PERFORMANCE=0` 分支不使用MAC结果，因此不实例化 `fp_mac.sv`。

最小第三方 filelist：

```text
third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
third_party/fpu-sp/verilog/src/float/fp_wire.sv
third_party/fpu-sp/verilog/src/lzc/lzc_4.sv
third_party/fpu-sp/verilog/src/lzc/lzc_8.sv
third_party/fpu-sp/verilog/src/lzc/lzc_16.sv
third_party/fpu-sp/verilog/src/lzc/lzc_32.sv
third_party/fpu-sp/verilog/src/float/fp_ext.sv
third_party/fpu-sp/verilog/src/float/fp_fdiv.sv
third_party/fpu-sp/verilog/src/float/fp_rnd.sv
```

## 4. 周期、reset 与 clear

`PERFORMANCE=0` FSQRT固定 launch-inclusive latency为28 operation cycles：

```text
cycle 1     IDLE采样op/data/class/rm
cycles 2-26 25次逐位sqrt
cycle 27    形成mantissa/exponent/GRS
cycle 28    fp_fdiv_o.ready=1
```

wrapper TB必须检查：

- 每个 `req_fire` 恰好一个 completion；
- completion不早于launch-inclusive cycle 28；
- 固定正常向量在cycle 28出现；
- 32-cycle watchdog仍无 completion则FAIL；
- wrapper response可被背压3–5拍且payload稳定。

第三方 `clear` 只屏蔽当前ready，不取消状态机；若覆盖完成拍会永久丢结果。因此必须固定 `clear=0`，禁止把它暴露为transaction abort。项目取消只允许：

1. 同步高有效 `rst_i` 经过极性转换，在至少一个rising edge令第三方reset为0；或
2. future epoch/kill wrapper继续drain core completion但丢弃旧epoch。

v1采用第一种。mid-operation reset必须清除busy/response，deassert后至少32拍不得出现stale completion。

## 5. 舍入和flags

rounding mode：

```text
000 RNE
001 RTZ
010 RDN
011 RUP
100 RMM
```

flags顺序固定为：

```text
flags[4:0] = {NV,DZ,OF,UF,NX}
```

对合法正有限sqrt，只允许0或NX；对invalid负数只允许NV。FSQRT出现DZ/OF/UF视为接线或实现错误。

特殊值：

| input | result raw | flags |
|---:|---:|---:|
| `+0` | `00000000` | `00` |
| `-0` | `80000000` | `00` |
| `+Inf` | `7f800000` | `00` |
| negative finite / `-Inf` | `7fc00000` | `10` |
| qNaN | `7fc00000` | `00` |
| sNaN | `7fc00000` | `10` |

## 6. 固定 raw-bit oracle

TB至少使用以下15项；flags以hex显示5-bit数值：

| # | rm | input | expected | flags |
|---:|---:|---:|---:|---:|
| 1 | RNE | `00000000` | `00000000` | `00` |
| 2 | RNE | `80000000` | `80000000` | `00` |
| 3 | RNE | `40800000` | `40000000` | `00` |
| 4 | RNE | `00800000` | `20000000` | `00` |
| 5 | RNE | `00000001` | `1a3504f3` | `01` |
| 6 | RNE | `7f800000` | `7f800000` | `00` |
| 7 | RNE | `ff800000` | `7fc00000` | `10` |
| 8 | RNE | `bf800000` | `7fc00000` | `10` |
| 9 | RNE | `7fc12345` | `7fc00000` | `00` |
| 10 | RNE | `7f812345` | `7fc00000` | `10` |
| 11 | RNE | `40000000` | `3fb504f3` | `01` |
| 12 | RTZ | `40000000` | `3fb504f3` | `01` |
| 13 | RDN | `40000000` | `3fb504f3` | `01` |
| 14 | RUP | `40000000` | `3fb504f4` | `01` |
| 15 | RMM | `40000000` | `3fb504f3` | `01` |

除数值外必须覆盖busy request拒绝、held-high request只接受一次、response背压稳定、initial/mid-operation reset、ready/completion单拍和32-cycle deadlock timeout。禁止 `real/shortreal`、DPI或host libm oracle。

精确通过marker：

```text
[NPU-FP32-SQRT][PASS] cases=15 latency=28 performance=0 timeout=32 backpressure=stable reset=clean
```

固定Verilator配置为 `--binary --timing -O3 -Wall -Wno-fatal`，C++ `-O3 -DNDEBUG -march=native`，无 `NPU_ASSERT`、trace或waveform；所有build/log/cache/compiler temp只能位于项目 `tmp/`。

## 7. PASS/GAP 边界

当前 `TensorNpuFp32Sqrt` 已按本合同通过：15项 raw-bit/flags oracle全部一致，五种舍入模式、launch-inclusive 28-cycle latency、15/15/15 request/core-completion/response守恒、3–5拍response背压与mid-operation reset后32拍无stale completion均由O3、无assert、无wave Verilator定向测试覆盖。统一回归marker为 `[NPU-REGRESSION][PASS] tests=17 assertions=off waveform=off optimization=O3`。

本 module证据只能报告 FP32 sqrt wrapper primitive PASS。以下仍是GAP：

- reciprocal/rsqrt组合与其数值顺序；
- sum-of-squares reduction；
- RMS_NORM与L2_NORM逐row datapath；
- Qwen真实tensor `ne/nb`、DMA/LMEM、command/backend；
- exhaustive pinned TestFloat vector hash；
- PERFORMANCE=1独立五舍入模式验证；
- Qwen shell token或tokens/s。
