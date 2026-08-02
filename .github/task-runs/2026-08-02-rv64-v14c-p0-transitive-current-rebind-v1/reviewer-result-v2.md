# V14C P0 final frozen-material reviewer v2

RV64 RTL 结论｜对象=P0 九门、IFU-AXI-G1/IFU-FETCH-G2、`PmpChecker.entry_addr_w[-1]` 与 `AxiCrossbar` warning 证据｜周期/配置=design-id `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`、146-file current source-set、Icarus current-dynamic｜TB/EDA 观测=九门 `CURRENT_DYNAMIC_PASS`、124/124 RTL 反例、warning 2368 次/45 唯一行且 unexplained=0、Section13 RED/PPA BLOCKED｜范围=`APPROVED_CURRENT_SCOPE`（仅限冻结材料）

- 反例来源互斥闭合：V14B direct 39 + V14C dynamic five main 48 + FDG/XRET oracle 3 + IFU replay-elimination 34 = 124；113/113 正向聚合不计入反例。
- IFU 五个正向 testbench 由当前 source-set 动态执行；IFU-AXI 18/18、IFU-FETCH 16/16 当前编译成功 RTL 反例均被检出，`source_unchanged=true`，交付不依赖旧冻结执行。
- warning allowlist 只覆盖 `PmpChecker` 常量未选中 `entry_addr_w[-1]` 分支和 `PmpChecker/AxiCrossbar` 的 Icarus `@*` 全数组 sensitivity 诊断；`unexplained_warning_count=0`、`assertion_failure_observed=false`。
- `current-bind-1` 假 PASS、`current-bind-checker-replay-1` 布局 FAIL、`p0-replay-elimination-1` warning allowlist FAIL 均保留且不作为交付；`historical_status_rewritten=false`。
- Section13 只允许 P0=`GREEN_TASK_LOCAL`；P1 stale=7、holder semantic=`GAP`、functional aggregate 非当前绑定、freeze empty groups=12，故 architecture=RED、arch-stable=false、PPA=BLOCKED。
- unknowns：no-tools reviewer 未独立读取 124 个 mutant ID、45 条 warning 完整集合或 matcher 实现，也未提供 waveform、断言覆盖、综合或 STA；主 agent 必须以 task-local 静态审计补足 mutant 唯一性和 matcher 精确性。
- `scope_extension_request: none`；architecture/PPA 放行需另建合同补齐全部剩余 Section13 输入。
- `confidence_and_basis`：冻结材料内部一致性高；原始 JSON 独立复现中等。
