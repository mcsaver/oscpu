# V14I independent review v2

RV64 RTL 结论｜对象=SoC fast/scheduled/candidate 九字段 gate、V14E/V14H 收据边界｜周期/配置=generation=6，design-id sha256:093c2380…a7488｜TB/EDA 观测=两个候选 gate 新执行 PASS、13 个负例 PASS｜范围=PASS

原 GAP 已关闭：execution/retention 负例分别只修改 `candidate.$6` 与 `fast.$7`，保持合法 TSV
结构；promotion authority、eligible classes、execution、retention、跨-tier reuse 五个字段级变异均先
验证为四行、每行九列，再确认 checker 拒绝。canonical 三行九字段 exact binding 可阻断字段弱化及
跨-tier 交换。generation=6 两个 gate 均无 `:reused`，未复用旧 candidate。

其余结论保持：A2 PASS、A1 原始 FAIL、17/17 strict、7/7 terminal、零 RTL assertion、45 checker
tests；V14H global receipt 仍为 `system=REQUIRED`，仅聚合账本提升至 `PASS_CURRENT_CONFIG`，
`whole_architecture=RED`、`ppa=UNPROMOTED`。

`scope_extension_request=none`；置信度高；WSL ownership returned。合同
SHA-256=`92a42783e096e9e58a8720e08fcf35d9da133f19e6788e228fba262888073d57`。
