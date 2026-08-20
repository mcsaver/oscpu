# d3f3 macro-boundary baseline A1

RV64 RTL 结论｜对象=`NpcTop` / `traceable-d3f3-macro-boundary-a1`｜周期/配置=5.000 ns、200 MHz、128-source placeholder macro-boundary｜TB/EDA 观测=Yosys、OpenSTA、parser 与 Top40 trace 完成，registry binding rc=2｜范围=GAP

- task-run：`FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0`；`command-status.txt` 中仅 `binding_rc=2`，其余 preflight、manifest、synthesis、OpenSTA、parser、trace、cleanup 均为 0。
- timing：WNS `-11.550187111 ns`，TNS `-287464.78125 ns`，Top40 为 40/40 violated，loops=0；200 MHz 与 0.1 ns margin 均未满足。
- area：929,250 个已知标准单元；logic area proxy `2,181,777.92`、sequential area `570,206.56`，均不含未知宏内部面积。
- placeholder blackbox：`Sram4096x199×1`、`Sram4096x113×2`、`OooFpArithGate×1`、`OooBranchDirectionPredictor×1`。
- Top40：40 startpoints、40 endpoints、80 个 public register 描述、opaque=0；35 条终止于 memory-owner collector，5 条终止于 control plane。BPU/FP 边界命中为 0，两个宏的内部时序仍为 GAP。
- binding root cause：production manifest 将 `npc/rv64/vsrc/filelist.mk` 同时从目录枚举和显式列表收录，并以相对 `$0` 收录 runner；严格 verifier 报 `duplicates input` 与 `non-canonical`，因此 summary 未获得 `design_id` 或 `architecture_registry_binding`。
- cleanup：删除 `1,470,889,796` bytes，runtime 已删除、netlist 未保留，仅保留 netlist SHA；无工作区 WSL client。

本次只可作为 frozen diagnostic 使用，不得称为 current d3f3 baseline PASS、PPA promotion、宏含面积/功耗或 BPU/FP internal timing 证据。命令未重跑，WSL shell ownership 已归还。
