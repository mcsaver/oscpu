# Dispatch log

- 读取工程规则与既有 RV64/NPC 记忆，确认本轮属于跨模块 RTL 拆分，需要先按拓扑分析协议与数据流。
- 梳理当前真实路径：`NpcCoreTop -> OooFetchAxiBridge/OooMemAxiBridge/OooAluFetchCore`，旧 legacy 路径不作为活动 RTL。
- 设计拆分边界：bridge/core 保留 ready/valid、AXI、fault、flush 与精确控制；cache/TLB/BPU 表项作为 leaf module。
- 实现 IFU 拆分：`OooFetchPacketCache` 与共享 `OooSv39Tlb`。
- 实现 LSU 拆分：`OooDataWordCache` 与共享 `OooSv39Tlb`。
- 实现 frontend BPU 拆分：`OooBranchDirectionPredictor`、`OooJalrBtb`、`OooBranchTargetCache`。
- 同步 `vsrc/filelist.mk` 与 `npc/rv64/testbench/Makefile`。
- 验证 `git diff --check`、rv64 lint/build 和 focused bridge/Sv39/priv tests 通过。
- 记录残余风险：宽口径 `tb_ooo_alu_fetch_core` 仍失败，需后续独立重基线/修复。
