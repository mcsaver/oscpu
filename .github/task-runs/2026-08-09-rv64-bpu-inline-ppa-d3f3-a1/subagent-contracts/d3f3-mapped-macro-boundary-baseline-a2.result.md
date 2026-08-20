# d3f3 macro-boundary baseline A2

RV64 RTL 结论｜对象=`NpcTop` / `traceable-d3f3-macro-boundary-a2/summary.json`｜周期/配置=5.000 ns、200 MHz、128-source、4 类 placeholder macro boundary｜TB/EDA 观测=Yosys/OpenSTA/parser/Top40/registry binding 完成，WNS=-11.550187111 ns｜范围=evidence baseline PASS；timing/PPA hard gate GAP

- 唯一执行 exit=0；status=`PASS`；marker=`[TRACEABLE-MAPPED-CURRENT][PASS] run=2026-08-09-rv64-bpu-inline-ppa-d3f3-mapped-baseline-a2 evidence=traceable-d3f3-macro-boundary-a2`。
- `command-status.txt`：preflight、manifest、synth、opensta、parser、trace、binding、cleanup 全部 rc=0。
- production manifest before/after 均为 206 条唯一绝对路径，SHA-256 同为 `80dfd7a747789dc28ab3b69e9bd5ef39265b31c52094c6b0708e004d6e82ee54`，逐项 current；summary design-id 精确为 `sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af`。
- synthesis closure 为 128 source；manifest SHA-256=`8c7aa3cdfce5c37bc5d7343d284a25caef5d3d3f5964cda03e9b7ecf01a37fd5`。BPU 9 项源与 FP 15 项 standalone source 均在 closure；两个 FP helper 以 include 进入 production manifest。
- placeholder boundary：`Sram4096x199×1`、`Sram4096x113×2`、`OooFpArithGate×1`、`OooBranchDirectionPredictor×1`。
- area：known standard cells=929250；logic area proxy excluding unknown macros=`2181777.92`；sequential area=`570206.56`。vectorless fixed-toggle total=`0.136 W`，仅为 relative-only，宏功耗未计。
- timing：OpenSTA COMPLETE；WNS=`-11.550187111 ns`；TNS=`-287464.78125 ns`；Top40=40/40 violated；loops=0；200 MHz 与 0.1 ns margin 均 false。约束缺口为 missing input delay=304、missing output delay=1906、unconstrained endpoints=1908。
- trace：`[TRACEABLE-PATH-INVENTORY][PASS] paths=40 public_registers=80 opaque=0`；35 条终止于 `OooMemOwnerTerminalCollector`，5 条终止于 `OooControlPlane`。BPU/FP placeholder 命中为 0，不代表宏内部时序 PASS。
- cleanup：删除 `1,470,889,796` bytes；runtime 删除、netlist 不保留、仅留 SHA；无工程进程。
- A1→A2：source manifest、netlist SHA/size、synth stat、area/timing/power、Top40、traceability 全部相同，delta=0；唯一差异是 A2 manifest 去重并将 runner canonical 化，使 `binding_rc: 2→0` 并获得 d3f3 design-id。

未知项保持为四类 placeholder 内部 timing/area/power、macro-inclusive total area、qualified Power、完整 SDC/corner 与 physical 200 MHz。未运行功能 TB，功能结论不扩展。WSL shell ownership 已归还。
