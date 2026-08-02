RV64 RTL 结论｜对象=OooLoadQueue.v per-entry release local-fire 负候选及 `.github/task-runs/2026-08-01-rv64-v13d-lq-release-localization/evidence/{source,logs,ppa}`｜周期/配置=parent/candidate A/B、GEN_W=1/4×OOO_ASSERT on/off、DI-5 64 周期、5ns ideal-clock｜TB/EDA 观测=raw-state TB 中 parent 出现 3 个预期 failure、candidate PASS；focused/backend/DI-5 PASS；candidate mapped area 与 slack 均退化；live RTL 已恢复 V13B 身份｜范围=PASS（APPROVED_NOT_PROMOTION_ELIGIBLE）

最终判定：`APPROVED_NOT_PROMOTION_ELIGIBLE`。批准的是负候选处置、证据留存和 production 回退，不批准 candidate promotion。

- 未发现假绿：candidate-only invalid duplicate-PID TB 被标为 `OBSOLETE_WITH_EVIDENCE`，没有并入当前 aggregate，也没有伪装成 production PASS；`NpcTop coarse`、full-core mapped/STA、style、31x2 mutation、power、system 均明确为 `NOT_RUN`。
- 功能反例真实但范围受限：parent 的 global fire 会跨 lane 清除 incomplete duplicate，继而令 completion bypass 因 entry 丢失失败；candidate 的 local-fire 修复了该 raw state，并覆盖 unknown-only、`1|X`、`commit=X`。但该 TB 驱动的是无效 duplicate-PID 状态；producer semantic 四档 PASS 支持当前 producer invariant。它不是完整可达性证明，若未来允许 duplicate PID，该反例必须重新升级为 production correctness 问题。
- PPA 没有超等级声明：coarse 指标相同；mapped cells 从 18979 增至 19272（约 +1.54%），area 从 44073.68 增至 44773.12（约 +1.59%），worst slack 从 +3.475173950ns 降至 +3.469281435ns（退化 5.892515ps）。`DOMINATED` 仅适用于该局部 mapped/STA 配置，不能外推为全芯片功耗或所有角落结论。
- 早停合理：在“局部 mapped area 与 timing 任一退化即阻断 promotion”的门槛下，未运行项目只能增加否决证据，不能消除已测回归；因此不会改变 rollback。若工程采用允许 area/timing 换 power 或系统级收益的加权策略，则需要 full-core/power 数据，当前材料不支持那种 promotion 判断。
- production 语义恢复链一致：current design-id 及 `OooLoadQueue.v`、TB、spec 三个哈希均报告与 V13B parent 一致，candidate 快照独立保留；回退后 focused assertion 再次 PASS，且没有删除或削弱 assertion。故 `full_system_rerun_required=NO` 仅表示无需为该已回退候选重跑，不代表未运行的 system gate 获得 PASS。
- 清理没有破坏审计链：删除的是 260235414 bytes、38 个可再生 runtime artifacts；18 个 PPA 原始文件中 16 个非空，另两个空文件是 OpenSTA 无 setup 检查项的原始输出；功能正负日志和源码快照仍保留，原始 A3/A4 状态未触碰。

未知项：冻结摘录未给出完整哈希、raw-state TB 与各日志 basename，也未提供 producer invariant 的形式证明；本节点依合同未重新读取或执行，因此只能确认冻结记录内部一致性，不能作文件系统级重新认证。替代解释是 global fire 依赖唯一 PID 所有权而更省逻辑，local-fire 则用 mapped 成本换取非法状态鲁棒性；若后者成为正式规格要求，应另立候选并补正式可达性、全芯片及系统验证。

置信度：对“不 promotion、回退有效、无假绿”的结论为高；对 duplicate-PID 全局不可达性及全芯片 PPA 为中等。无 `scope_extension_request`。
