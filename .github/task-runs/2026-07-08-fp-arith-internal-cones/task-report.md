# 任务报告

## 目标

继续推进 `[112] RV64 Yosys full stdcell synthesis` 中 `OooFpArithGate` 的 Mul/FMA 长尾定位。上一轮 output cone probe 已证明 AddSub full stdcell 可过，而 Mul/FMA 输出锥在 `600s` 内卡 ABC gate netlist extraction；本轮在不启动 Ubuntu/rootfs、不改生产 RTL 的边界下，用 task-run-only standalone probe 拆 Mul/FMA 内部阶段。

## 实现者人格

本轮完成了 `OooFpArithGate` 内部 cone OOC 拆账：

1. 新增临时 probe：`evidence/probes/OooFpArithInternalConeProbes.v`。
2. 新增复现实验脚本：`run_internal_ooc.sh`，使用 `STA_SYNTH_FLATTEN=1`、`STA_SYNTH_PUBLIC_AUTONAME=0`、100MHz 约束和 `make -B`。
3. 分别运行 5 个内部 probe 的 coarse 与 full stdcell OOC。
4. probe 只放在 task-run evidence 内，不进入生产 filelist。

关键结果：

| Probe | 含义 | Coarse 结果 | Full stdcell 结果 |
| --- | --- | --- | --- |
| `OooFpMulProductProbe` | FMUL double/single raw product | `2 $macc_v2` | PASS，`19488` gates，area `41726.44`，delay `35.00`，Yosys `80.47s` |
| `OooFpMulNormRoundProbe` | FMUL normalize/shift-jam/round/pack | `368 cells`，`25 $alu`，`146 $mux` | PASS，`5345` gates，area `9883.16`，delay `46.00`，Yosys `16.67s` |
| `OooFpFmaRefProbe` | FMA S2 ref/LZC/shift 计算 | `170 cells`，`8 $macc_v2` | PASS，`3284` gates，area `6006.00`，delay `38.00`，Yosys `8.34s` |
| `OooFpFmaAlignAddProbe` | FMA S3 128-bit align/shift-jam/add-sub | `276 cells`，`126 $mux`，`4 $shl` | PASS，`12001` gates，area `22277.92`，delay `48.00`，Yosys `62.82s` |
| `OooFpFmaNormRoundProbe` | FMA S4/S5 128-bit LZC/normalize/round/pack | `316 cells`，`17 $alu`，`147 $mux` | PASS，`5635` gates，area `11052.44`，delay `43.00`，Yosys `23.19s` |

结论：Mul/FMA 内部 standalone 子段都能在 100MHz full stdcell 下完成，且最大 standalone 压力是 raw multiplier product 与 FMA align/add。上一轮 Mul/FMA output cone timeout 不能再归因于某个单独 helper “不可综合”，更像是完整输出锥里 double/single 双路径、product、align/add、normalize/round、输出 mux 与保留公共逻辑同时进入 ABC 后的累计映射成本。

## 关键证据

- 5 个 coarse probe 均 PASS，日志中 `Found and reported 0 problems`。
- `OooFpMulProductProbe-full.log.gz`：`ABC: netlist ... nd = 19488 ... area =41726.44 delay =35.00`，`Chip area ... 41726.440000`，`End of script ... time: 80.47s`。
- `OooFpMulNormRoundProbe-full.log.gz`：`ABC: netlist ... nd = 5345 ... area =9882.04 delay =46.00`，`Chip area ... 9883.160000`，`End of script ... time: 16.67s`。
- `OooFpFmaRefProbe-full.log.gz`：`ABC: netlist ... nd = 3284 ... area =6006.00 delay =38.00`，`Chip area ... 6006.000000`，`End of script ... time: 8.34s`。
- `OooFpFmaAlignAddProbe-full.log.gz`：`ABC: netlist ... nd = 12001 ... area =22277.92 delay =48.00`，`Chip area ... 22277.920000`，`End of script ... time: 62.82s`。
- `OooFpFmaNormRoundProbe-full.log.gz`：`ABC: netlist ... nd = 5635 ... area =11051.32 delay =43.00`，`Chip area ... 11052.440000`，`End of script ... time: 23.19s`。

## 方法边界

- 这些 probe 是 standalone 结构化切片，适合定位 synthesis 长尾；它们不是正式 RTL 模块抽取，也不是等价证明。
- `OooFpFmaRefProbe` 和 `OooFpFmaNormRoundProbe` 的 coarse 中出现少量 `$macc_v2`，来自宽算术表达式/减法等 generic arithmetic 归类，不等同于新增生产乘法器。
- 本轮没有修改生产 RTL，因此没有新增功能回归；正确性边界仍依赖此前 `tb_ooo_fp_arith_gate`、`OOO_ASSERT`、riscv-tests/full-state difftest 等证据。
- `npc/rv64/vsrc/common` 与 `npc/rv64/vsrc/debug` 的作用之一是审核 RTL 是否符合 spec 语义。后续若把当前 probe 结论转成正式 Mul/FMA 模块边界，尤其触碰 B-FP meta、kill age、redirect/facts 或异常标志对齐，应先查/补 common facts 与 debug checker，再宣称时序优化语义正确。

## 审查者人格

未闭合项与风险：

- 本轮证明“内部子段可 full stdcell”，但没有证明完整 Mul/FMA output cone 或 `OooFpArithGate` full stdcell 已闭合。
- 最大 standalone pressure 是 `OooFpMulProductProbe` 与 `OooFpFmaAlignAddProbe`；若正式 RTL 继续把这些与 normalize/round/output mux 合在同一 ABC cone，仍可能重复 timeout。
- 若采用 macro/blackbox 边界，报告必须保留“未知面积/未实现 stdcell”的限制，不能越级宣称 STA-ready。
- `OooFetchPacketCache` 的 memory macro/SRAM 边界仍是全顶 synthesis 的另一条 active blocker，本轮未处理。

## 下一步

1. 优先把当前 task-run probe 结论转成正式结构策略：先考虑把 FMUL product 与 normalize/round 边界显式化，并给 double/single output mux 降低同 cone 累计压力。
2. 对 FMA 优先拆 product、S3 align/add 与 S4/S5 normalize/round 的模块边界或 pipeline 边界；每次改生产 RTL 都要用 FP focused TB 与 B-FP meta/fflags 对齐 checker 审核。
3. 用 `debug/common` 作为语义审核层：跨 B-FP、backend、redirect、kill age 的拆分先查 facts/checker，缺失时补 checker，而不是只看综合日志。
4. 当前仍停留在正确性验证与综合准备阶段，不启动 Ubuntu/rootfs；待 full stdcell 或明确 macro 边界证据更完整后再恢复 OS 启动计划。
