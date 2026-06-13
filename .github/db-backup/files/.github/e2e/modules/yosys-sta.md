# yosys-sta E2E Contract

- **范围**: Yosys 综合、iEDA STA/功耗、PPA 下游节点。
- **上游**: NPC 可综合 RTL filelist、SDC、PDK。
- **下游**: tapeout-readiness、PPA regression。
- **L0 gate**: `yosys-sta-contract` 检查 Makefile、memory 和工具状态。
- **L1 gate**: 后续升级为 `make -C npc/single syn-check-env`。
- **证据**: syn/sta env check、netlist、timing/power report。
- **升级路线**: 将 STA 结果纳入 profile diff，跟踪频率/面积/功耗变化。
