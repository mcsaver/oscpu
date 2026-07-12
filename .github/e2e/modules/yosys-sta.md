# yosys-sta E2E Contract

- **范围**: Yosys 综合、iEDA STA/功耗、PPA 下游节点。
- **上游**: NPC 可综合 RTL filelist、SDC、PDK。
- **下游**: tapeout-readiness、PPA regression。
- **L0 gate**: `yosys-sta-contract` 检查 Makefile、memory 和工具状态。
- **L1 gate**: 后续升级为 `make -C npc/single syn-check-env`。
- **RV64 flow contract**: 可复现 flow 入口必须是 Git 可见的 `yosys-sta/Makefile`、`yosys-sta/scripts/*.tcl` 与 `yosys-sta/scripts/pdk/*.tcl`；`result/`、`bin/`、顶层 `pdk/`、日志和网表仍作为本地产物忽略。
- **Fast probe contract**: bounded full-chip synthesis probe 默认可使用 `STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0`，把机器网表生成和人类可读命名分离；若打开可读 autoname，需要单列 runtime/log-size 风险。
- **Macro boundary contract**: `STA_SYNTH_BLACKBOX_MODULES` 只能用于显式宏/OOC 边界实验；unknown-area cell 必须在报告里作为未闭合 timing/area 边界列出。
- **Macro checker contract**: 四黑盒 `NpcTop` synthesis 后续任务必须维护 `npc/rv64/design/specs/yosys-macro-boundary-contracts.md`，并可用 `python3 yosys-sta/scripts/check_macro_contracts.py` 检查 spec/RTL/netlist 覆盖。
- **BPU placeholder contract**: `OooBranchDirectionPredictor` 的 macro/OOC placeholder 必须同步维护 dedicated spec、四黑盒当前行、RTL/frontend/debug ABI、生成器与 Liberty；可用 `python3 yosys-sta/scripts/check_bpu_macro_contract.py` 检查 0-cycle two-lookup read、每 lane 1-bit static fallback、two-cycle issue-resolve table update、valid-only table clear plus GHR zero 和当前 17674 state-bit lower bound。checker 只允许从 dedicated spec §8 与当前表格行取事实，历史变更记录不得让陈旧合同假绿。
- **Fetch-cache placeholder contract**: `OooFetchPacketCache` 的 macro/OOC placeholder 必须同步维护 dedicated spec 与四黑盒总表；可用 `python3 yosys-sta/scripts/check_fetch_cache_macro_contract.py` 检查 0-cycle lookup read、next-cycle fill/invalidate、clear-valid-only 和 819200 state-bit lower bound。
- **D-cache placeholder contract**: `OooDataWordCache` 的 macro/OOC placeholder 必须同步维护 dedicated spec 与四黑盒总表；可用 `python3 yosys-sta/scripts/check_dcache_macro_contract.py` 检查 0-cycle read、next-cycle write、fill-then-store 和 466944 state-bit lower bound。
- **FP-arith decision contract**: `OooFpArithGate` 的 macro/OOC decision placeholder 必须同步维护 dedicated spec 与四黑盒总表；可用 `python3 yosys-sta/scripts/check_fp_arith_macro_contract.py` 检查 5-cycle latency、1 op/cycle launch、OOC coarse PASS/full stdcell open、internal cone evidence，以及 latency/边界变化时必须补 common/debug 语义审核的约束。
- **iEDA netlist compatibility contract**: `NpcTop` 四黑盒 netlist 进入 iEDA STA 前必须通过 `python3 yosys-sta/scripts/check_ieda_netlist_compat.py`，确认不含仿真/形式 side-effect cell、`defparam` 或 parameterized blackbox instance；该检查只证明 parser 兼容，不证明 timing/area closure。
- **证据**: syn/sta env check、tracked flow script status、netlist、macro-boundary marker、timing/power report。
- **升级路线**: 将 STA 结果纳入 profile diff，跟踪频率/面积/功耗变化。
