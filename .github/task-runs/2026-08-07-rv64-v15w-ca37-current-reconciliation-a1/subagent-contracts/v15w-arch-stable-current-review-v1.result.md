RV64 RTL 结论｜对象=`NpcTop` ca37 ARCH_STABLE candidate 与合同内本地证据｜周期/配置=5ns、single-hart RV64 dual-issue OoO｜TB/EDA 观测=九门 GREEN，L0–L3/holder/debt/historical 闭合，STA FAIL_NOT_PROMOTABLE｜范围=PASS

判定：`APPROVE_ARCH_STABLE`。

- 绑定：candidate SHA-256 `248d402011712088f9ccb1499f0eac5dfd890c06714662de05a2f13e47e97998`；合同 SHA-256 `5c14ea639be9182d7612b9e3e6e0cad1cff4c0d1f786bb3e3638cce6ebbf317e`；design-id `sha256:ca37187e08a3ed489a20d8e05942a2fe8b33ae85904d2edb43e1df08332f9b6f`。
- exact-input：pre-review 对 146 项 production RTL 重算得到 `drifted_or_missing=[]`，cohort、配置、约束、工具、测试源及 97 项 workflow binding 全部 PASS；唯一 GAP 是 `independent_review.exact_binding`。
- 九门：DI-1 `frontend_ii1`、DI-2 `width_continuity`、DI-3 `pair_matrix`、DI-4 `no_static_lane_semantics`、DI-5 `dual_memory_issue`、OOO-1 `true_ooo_long_latency`、OOO-2 `selective_scheduling`、OOO-3 `memory_ordering`、OOO-4 `speculation_recovery` 全 GREEN。
- 分层事务：L0 113/113、断言失败 0；L1 official 177/177、AM 61/61、DiffTest mismatch 0；L2 9,882,568 cycles/6,098,497 commits；L3 57,129,353 cycles/24,460,280 commits，GOOD TRAP、kernel power-down、syscon poweroff 等终态 marker 均各一次。
- ProducerId holder：17 个 holder instance、46/46 semantic units、52 个 instance binding，`global_no_live_reuse=GREEN`；V14G 4/4 baseline、22/22 compile-success mutation rejection。
- debt/historical：16 项 debt `CLOSED_CURRENT_DESIGN`，4 项按 cohort 明确排除；6 项 historical defect 全部 backfilled，VD3=3、VD4=3，VD0/VD1 blocker 为 0。
- 边界：`ppa=UNQUALIFIED`、`promotion_eligible=false`；5ns STA `target_200mhz_met=false`、WNS `-13.694396973ns`、TNS `-398171.5625ns`，保持 `FAIL_NOT_PROMOTABLE`。Ubuntu 22.04/systemd 为 `NOT_RUN`，不在本结论内。
- 反例复核：静态 census 的 `semantic_complete=false`、三个历史 `STALE_RTL_SOURCE` 记录以及 constituent receipt 的 `whole_architecture=RED` 均是防止低层证据自提升的边界；current semantic projection、46/46 coverage 与 pre-review canonical replay 已独立闭合。L2/L3 使用同设计身份的 sealed evidence replay，并非本轮 DUT/Ubuntu 重跑。
- `unknowns=[]`；`scope_extension_request=none`。本轮未运行 Python 单测、仿真或综合，因而没有非预期测试返回码；结论绑定上述 candidate/pre-review 快照，任何后续 RTL 或证据哈希漂移都会使批准失效。
- 置信度：高；依据为 canonical pre-review、原始九门/L0–L3/holder/debt/historical 收据及本轮独立 SHA 交叉核对。

[ARCH-STABLE-INDEPENDENT-REVIEW][APPROVE] design_id=sha256:ca37187e08a3ed489a20d8e05942a2fe8b33ae85904d2edb43e1df08332f9b6f candidate_sha256=248d402011712088f9ccb1499f0eac5dfd890c06714662de05a2f13e47e97998

收据物化注意：`build_independent_review_receipt()` 要求最终传入的 contract/report 各恰好包含一次上述 marker；当前绑定 JSON 未含完整 marker，不能直接作为其 marker-bearing `contract_path`。这属于同一 review receipt 的物化要求，不改变技术批准。

所有合同内只读命令已结束，无工程进程残留；唯一 Windows→WSL shell ownership 已归还主节点。
