# d3f3 BPU-inline mapped A2 result

RV64 RTL 结论｜对象=`NpcTop` / `OooBranchDirectionPredictor` / `traceable-d3f3-bpu-inline-a2`｜周期/配置=5.000 ns、d3f3、`mapped-5ns-bpu-inline-v1`｜TB/EDA 观测=唯一 runner exit=0、evidence PASS；WNS=-50.241458893 ns、TNS=-719693.1875 ns、Top40=40/40 BPU internal violated、loops=0｜范围=evidence PASS；timing/PPA hard gate GAP

## Execution and binding

- runner 严格执行一次，wall=2140.5 s；marker=`[TRACEABLE-MAPPED-CURRENT][PASS]`，无 signal，status=`PASS`。
- `preflight/manifest/synth/opensta/parser/trace/binding/cleanup` rc 全为 0。
- summary SHA-256=`70a4f5ed55941fa55aa516fbd0ff3ca94fb44fe3833ac52fc87c112904f5a882`。
- v2 binding schema=`npc-rv64-mapped-architecture-binding-v2`；design-id=`sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af`；physical configuration=`mapped-5ns-bpu-inline-v1`。
- policy/config/projection SHA 分别为 `718445d2c2d7a11b2c26327e98f0c81bbd1f8884aaa84581f62668114efee5bc`、`a44871be11a576565ba90017846903225f36b49a6c38cff669617fbb63a95131`、`ed72ca8b7282c948a64c1e3b7ed90f8bfc714cacc7db69b1b39c0f20ebb0b794`。
- production manifest before/after 均为 205 项且 SHA-256=`b1ec234c81aded81595b8e344454c7de7733d7082337d47e79d2b3f46137d2f9`。
- 128-source manifest SHA-256=`8c7aa3cdfce5c37bc5d7343d284a25caef5d3d3f5964cda03e9b7ecf01a37fd5`，与 inline A1、四宏 A2 bit-identical。
- STA input manifest SHA-256=`75b2071c471a21f8ec4856f6155ce7c594a2d4304da607bb98d3f7d300448a2c`；OpenSTA completion 记录 `macro_lib_count=3`。

## Mapping and PPA

- raw unknown census=`Sram4096x199×1`、`Sram4096x113×2`、`OooFpArithGate×1`；无 `OooBranchDirectionPredictor`。
- BPU inline=`87,601` cells、logic area=`283,823.40`、sequential area=`109,068.96`。
- whole core known cells=`1,016,851`；cells including unknown=`1,016,855`；logic area proxy=`2,465,601.32`；sequential area=`679,275.52`。
- netlist SHA-256=`89689be960cc9b4c60770d4a527888518c7321fce065ab77a8339492ac2f45d4`；size=`1,234,369,912` bytes。
- vectorless fixed-toggle power=`0.162 W`，仅 `RELATIVE_ONLY_FIXED_TOGGLE_0P1`；macro power 未计。
- setup closure：missing input delay=304、missing output delay=1906、unconstrained endpoints=1907、loops=0。

| metric | inline A2 | inline A1 delta | four-placeholder A2 | delta vs four-placeholder |
|---|---:|---:|---:|---:|
| known cells | 1,016,851 | 0 | 929,250 | +87,601 |
| total cells | 1,016,855 | 0 | 929,255 | +87,600 |
| logic area | 2,465,601.32 | 0 | 2,181,777.92 | +283,823.40 |
| sequential area | 679,275.52 | 0 | 570,206.56 | +109,068.96 |
| netlist bytes | 1,234,369,912 | 0 | 1,172,491,804 | +61,878,108 |
| vectorless power | 0.162 W | unmeasured | 0.136 W | +0.026 W |
| WNS | -50.241458893 ns | unmeasured | -11.550187111 ns | -38.691271782 ns |
| TNS | -719693.1875 ns | unmeasured | -287464.78125 ns | -432228.40625 ns |
| Top40 violated | 40/40 | unmeasured | 40/40 | 0 |

## Top40

- traceability marker=`[TRACEABLE-PATH-INVENTORY][PASS] paths=40 public_registers=80 opaque=0`。
- 40/40 startpoint 和 endpoint 都在 `u_core_u_ooo_core_u_frontend_u_branch_direction_predictor`；四宏 A2 的 BPU internal Top40 为 0。
- 最坏路径从 `..._update_taken_i_DFFQX1H7L_D/Q` 经 local-PHT counter update logic 到 `..._local_pht_q_0__0__DFFQX1H7L_Q/D`。
- 关键 `..._upd_lpht_ctr_q_0__AOI21X0P5H7L_A1/Y` arc delay=54.784690857 ns；arrival=55.933452606 ns、required=5.691995621 ns、slack=-50.241458893 ns。
- Top40 SHA-256=`24154946a41c8ab0ef3de091403fa698cc59a86d4cab0f8c41098d98de57e145`。

## Boundary

- evidence PASS 不等于 200 MHz timing PASS；`target_200mhz_met=false`。
- A1 的固定四宏工具问题已关闭；当前 blocker 是真实 BPU internal timing。
- local-PHT register-array 展开与集中 update fanout 是中等置信度主假设；17,706 DFF、5,377 ICG、5,460 MUX4 与 54.78 ns AOI21 arc 支持该解释。理想时钟、无布线 stdcell proxy/library load 模型放大该结构是替代假设。
- SRAM、FP macro 内部 PPA、macro-inclusive area、qualified activity power、完整 SDC/multicorner/CTS 仍未知。
- 未运行功能 TB，不新增功能正确性结论。

runtime 删除 1,566,158,238 bytes，netlist 未保留，runtime base absent；runner/launcher 已结束，shell ownership 已归还。继续工作应进入 BPU production child-split 架构裁决，不应把 whole-predictor inline 作为 promotion 候选。
