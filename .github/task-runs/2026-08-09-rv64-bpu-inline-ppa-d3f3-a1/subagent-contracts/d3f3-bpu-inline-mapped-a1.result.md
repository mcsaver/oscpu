# d3f3 BPU-inline mapped A1 result

RV64 RTL 结论｜对象=`NpcTop` / `OooBranchDirectionPredictor` / `traceable-d3f3-bpu-inline-a1`｜周期/配置=5.000 ns、`mapped-5ns-bpu-inline-v1`、d3f3｜TB/EDA 观测=Yosys mapped synthesis PASS；OpenSTA 因历史驱动固定四宏检查拒绝合法三宏投影，outer exit=1｜范围=综合切片 PASS；evidence/timing/PPA GAP

- 唯一执行耗时 2037 s；无 signal、未重跑。
- task-run 终态：`FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0`。
- command status：`preflight=0 manifest=0 synth=0 opensta=1 parser=1 trace=1 binding=2 cleanup=0`。parser/trace 未执行；binding 因没有 `summary.json` 返回 2。
- 精确根因：历史 `opensta-v15p-exact5ns.tcl` 要求 `macro_count == 4`，而 registry 授权的 BPU-inline 投影只有 `Sram4096x199`、`Sram4096x113`、`OooFpArithGate` 三个 Liberty。
- runtime/netlist 已删除，runner 与 launcher 已退出；原 run-dir 不改写、不重跑。

## Run-start binding

- RTL design-id：`sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af`
- physical configuration：`mapped-5ns-bpu-inline-v1`
- blackbox：`Sram4096x199 Sram4096x113 OooFpArithGate`
- inline：`OooBranchDirectionPredictor`
- synthesis source count：128；source manifest 与四宏 A2 bit-identical。
- raw unknown census：`Sram4096x199×1`、`Sram4096x113×2`、`OooFpArithGate×1`，BPU predictor 已从 unknown 集合移除。

## Yosys slice versus A2

| 量 | BPU-inline A1 | 四宏 A2 | delta |
|---|---:|---:|---:|
| known standard cells | 1,016,851 | 929,250 | +87,601 |
| total cells including unknown | 1,016,855 | 929,255 | +87,600 |
| logic area proxy | 2,465,601.32 | 2,181,777.92 | +283,823.40 |
| sequential area | 679,275.52 | 570,206.56 | +109,068.96 |
| netlist bytes | 1,234,369,912 | 1,172,491,804 | +61,878,108 |

`OooBranchDirectionPredictor` 自身映射为 87,601 cells、logic area 283,823.40、sequential area 109,068.96。

OpenSTA 未读取网表，因此本 run 的 WNS/TNS/Top40/power/BPU timing path 全部 inconclusive。A2 对照仍为 WNS -11.550187111 ns、TNS -287464.78125 ns、40/40 violated、loops=0；不得复制为本 run 结果。

反例：合法三宏 registry 投影被固定四宏工具常量拒绝。该反例证明根因属于 STA flow/config，而非 Yosys timeout、BPU RTL elaboration 或 predictor 数组不可综合。置信度：综合切片与根因高；timing/PPA 未测。
