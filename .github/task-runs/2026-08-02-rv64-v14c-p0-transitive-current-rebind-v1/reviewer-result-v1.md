# V14C P0 frozen-material reviewer v1

RV64 RTL 结论｜对象=P0 九门及 `active-cone-2/active-cone-audit.json`、`current-bind-checker-replay-2/receipt.json`、`section13-current-1/section13-current-audit.json`｜周期/配置=design-id `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`、146-file source-set｜TB/EDA 观测=动态 18/18、module aggregate 113/113、反例 82/82+3/3、driver rc=17/0｜范围=PASS（APPROVED_CURRENT_SCOPE；仅 P0 task-local current binding，architecture=RED、PPA=BLOCKED）

- reviewer 确认 V14B 两门与 V14C 七门恰好覆盖 P0 9/9，源状态假绿已隔离，canonical 未写入。
- reviewer 指出 IFU-AXI/FETCH 的冻结重放还依赖编译参数、宏、generated include、DPI ABI 与工具版本等行为决定输入。
- 该 caveat 已触发后续 replay elimination：使用当前 113/113 聚合的五个 IFU 正向日志，并补跑 34/34 当前 RTL 反例；因此 v1 不是最终交付审查。
- `scope_extension_request`：若晋级 architecture/PPA，需补齐 P1、holder semantic、functional aggregate、freeze inventory 与综合/STA/PPA。
- `confidence_and_basis`：冻结材料范围内约 0.88；no-tools 节点未独立重算原始 JSON。
