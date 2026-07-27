# V9O unified control event

## 状态

`CONTROL_EVENT_CLOSED_CURRENT_DESIGN_FULL_CORE_GAP`。长期 RV64 OoO/PPA goal 保持
active。

## 当前选择

从权威架构债务 ledger 的开放 P1 项中选择 `CONTROL-EVENT-G1`。该项位于
`SERIALIZE-G1` 之前，负责把前端重定向赢家、后端选择性恢复和提交后全后端清空收敛成
可重建的事件身份与阶段合同。

## 当前证据边界

- full-core architecture freeze：`GAP`；
- 当前 canonical candidate blocker：59；
- PPA：`UNQUALIFIED`；
- promotion：false。

当前 candidate 仍绑定旧设计摘要
`sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`，
而本切片 live RTL 为
`sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`。
因此 9 项 directed architecture gate GREEN 不等于 full-core freeze，也不产生正式 PPA
结论。

## 接口契约冻结

本轮已在 `rtl-derivation.md` 冻结：

- ROB edge-old 队头 full-flush pregrant；
- raw branch request 与生产 selective-apply 的分离；
- C0 屏障 / C1 typed apply 的两阶段时序；
- dispatch、issue、completion、dual-memory 与 bridge pre-owner 的 consumer set；
- strict-younger 环形年龄边界；
- committed/nokill/DRAIN/registered AXI owner 的保持集合；
- `NONE / SELECTIVE_NOW / FULL_NEXT` typed backend action。

冻结结论禁止最终前端仲裁结果直接回送 backend ready 锥；采用
`OooRob` Q-only pregrant 作为无环年龄律投影。对应独立复核合同：

- `control-event-stage-proof-v1`
- `control-event-root-cause-review-v1`
- `control-event-root-cause-review-v2b`

`control-event-root-cause-review-v2` 因遗漏 `define.v` 输入被标为 superseded，未作为
实现依据。

## RTL 实现结果

- `REDIR_REASON_W=4`，新增 `CSR_COMMIT`；backend action 明确区分
  `NONE/SELECTIVE_NOW/FULL_NEXT`。
- ROB 从 edge-old Q、commit permits、Q-only LQ terminal permit 和 exact pending CSR
  ProducerId 产生 any-control/full pregrant；实际 commit 路径仍保留普通 ready。
- branch 生产恢复只在 `authorized_request && !head0_control_event_pregrant` 时成立；
  canonical frontend winner 与 cycle-free backend branch/full 投影有双向立即断言。
- `OooControlEventApplySequencer` 是唯一 C0→C1 功能状态 owner。
  `request_valid/reason` 只读取 ROB full pregrant；trap commit 与 queue-head CSR commit
  分别同 `TRAP/CSR_COMMIT` pregrant 做双向等价断言。
- C0 full barrier 已贯通 dispatch、INT/FP issue、8 类 completion authorization、memory
  station/pre-owner launch 和两个 data bridge；registered AR/AW/W owner 继续 drain。
- exact pending-system CSR owner 为 `CSR_COMMIT/NONE`，关闭同拍 dispatch/younger branch，
  不建立 completion cut 或 C1 apply。

## current-design 验证

所有下列 runtime log 均写入
`[RTL-DESIGN-ID] sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`，
对应 runner 在执行前后复算 146-file canonical RTL source set：

- focused：10/10 PASS；
- `OOO_CSR_QUEUE_HEAD=1`：ROB、真实 queue-head/pending CSR focused、generic core aggregate
  共 3/3 PASS；
- default module aggregate：110/110 PASS；
- compile-success RTL 变异：11/11 编译成功且 11/11 被指定 oracle 拒绝，其中 10 项动态、
  1 项 full-cone SCC lint；baseline `UNOPTFLAT=false`，完整 RTL 摘要前后不变；
- ROB 真实 full-C0 completion matrix：8/8 class，环绕
  `head=15/younger=0` PASS；
- dual memory registered-AR barrier：2 lane、4 hold cycle、2 terminal、两个精确 token
  各一次 PASS；
- canonical architecture hard gates：9/9 GREEN，hard-gate negative tests 30/30 PASS；
- `make -C npc/rv64 check-contract`：holder census PASS、471 个立即断言、13/13 单测 PASS。

## full-core 边界审计

`run-arch-stable-audit.sh` 的 135 项 workspace 正例/反例套件没有全绿：历史 full-core
证据仍按 109-module inventory 和旧 RTL 摘要构建，因而 live positive fixtures
fail closed。该失败没有被豁免成 PASS。

随后使用同一 `arch_stable_freeze.py` 对 canonical candidate 直接执行 `audit` 和 `verify`，
结果均为：

```text
architecture_freeze=GAP
blockers=59
ppa=UNQUALIFIED
promotion_eligible=false
candidate_same_as_current_design=false
```

因此本切片不把 directed gate GREEN 外推为 full-core freeze；其它 full-core blocker、
`SERIALIZE-G1` 与正式 PPA 工作保持原状态。

## 独立终审与合同纠偏

- final-review-v1/v2 将生产 winner、pending CSR owner、source identity、真实
  full-C0×8 completion 与双 lane persistent-barrier AR 轨迹识别为 closure 缺口；
  这些反例均已落成 RTL 双向断言、定向 TB、source-bound runner 或 compile-success
  RTL 变异。
- final-review-v3 对技术链给出 7 项 PASS，但发现合同成功条件中的 design ID 只有
  62 个十六进制字符；该轮严格保持 source-binding GAP，没有口头修补或追认。
- final-review-v4 使用完整
  `sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`
  重新独立签收，唯一 C0 request、TRAP/CSR 双向等价、C0/C1、无环前后端投影、
  8 类 strict-younger completion、pending CSR ProducerId、LQ edge-old permit、
  双路 registered AR 与 current source binding 共 8/8 PASS。
- v4 合同 SHA-256：
  `cbad928e3e6e88a1063b3e5426e29516cabb25878ef8b6b704d83c4c189a61bb`。

## ledger 与 fail-closed 消费

`architecture-debt-ledger.json` 已将 `CONTROL-EVENT-G1` 更新为 `CLOSED`，绑定本轮
current RTL/verification source identity、正向/反例覆盖与 11 个 compile-success RTL
变异。共享 `arch_stable_freeze.py` 同时新增该 debt 的专用语义验证器，独立复核：

- 146-file RTL 与 133-file verification source set；
- focused 10/10、CSR queue-head config 3/3、module 110/110；
- 11/11 compile-success variants，其中 10 个动态、1 个 SCC lint；
- completion matrix、双路 registered AR、C0/C1 和 ProducerId 承重 marker；
- canonical architecture gates 9/9 GREEN 与 30/30 negative tests；
- 164 个非自指 evidence-index artifact；
- full-core `GAP` / PPA `UNQUALIFIED` / promotion false 边界。

首次 publication replay 暴露 local evidence-index 反向哈希正在生成的 full-core
audit/log，形成 `index → ledger → audit → index` 证据拓扑环。修复后局部索引只保留
full-core 边界标量，不把下游 audit/log 作为局部 closure 产物；最终
evidence-index `--verify` 与 audit/verify 均稳定通过。

最终 full-core 结果仍为：

```text
architecture_freeze=GAP
blockers=59
ppa=UNQUALIFIED
promotion_eligible=false
candidate_same_as_current_design=false
```

其中 `debt.CONTROL-EVENT-G1.semantic_evidence=PASS`，而
`debt.CONTROL-EVENT-G1.closed_binding=GAP` 只说明旧 full-core candidate
`sha256:2eff...c8b2` 不能消费当前 `sha256:08d3...8c6a` 的局部闭合证据。它不回退
本轮 RTL 技术结论，也不允许外推为 full-core freeze 或正式 PPA 结果。

## ledger validator 独立复核与修订

三轮独立复核均使用 versioned JSON 合同，输出只落在本 task-run：

- v1 要求把 exact provenance、完整语义重放、11 项 RTL 变异映射、动态 Makefile module
  inventory 与 live full-core candidate identity 都纳入共享 validator；对应缺口已实现并转为
  定向单测。
- v2 证明 `mutations/summary.json` 当时可添加一条指向下游 boundary audit 的嵌套 artifact，
  而完整 validator 仍返回接受。修订后 mutation summary 使用 exact 顶层/result schema，并递归拒绝
  boundary-generated path；动态 module inventory 也由硬编码 109 改为 live 110。
- v3 证明 architecture hard-gates result 当时未绑定 canonical path：把结果 JSON 复制到另一
  workspace-relative 路径并内嵌 ledger artifact reference 后，完整 validator 仍返回接受。修订后
  architecture result、manifest 和 refresh log 都绑定精确路径；result/manifest 使用 exact schema、
  9 个 gate ID/status 和 current RTL source identity，并递归拒绝 boundary-generated reference。

v3 reviewer 已先写出
`validator-review-v3/review.md` 与 replay fixtures，随后其最终自然语言回复在 Codex UI 展示阶段
中断；该节点按 `review_pending` 保留合同 SHA、报告和中断状态，不把未显示的最终回复追认为正式
`PASS`。报告中的可操作 RTL 证据校验反例已由主 agent 转成共享 validator 修订与定向单测。

修订后的 current-design 结果：

```text
[V9O-EVIDENCE-INDEX-VERIFY] design_id=sha256:08d3...8c6a
verification_id=sha256:300d...3c1 artifacts=164 status=PASS
CurrentWorkspaceTests selected=5/5 PASS
make -C npc/rv64 check-contract: 471 assertions, 13/13 tests PASS
```

evidence-index SHA-256 为
`d73a69cdfd92f42ed87e9e60a0c5389c343e4261ab6cf8b6fddc957245124da0`；
mutation summary SHA-256 为
`28d594c312a893acc250814f356fef23b03cac1991f84d8b34caf93fbf4f319d`。

## 子 agent 最终回复模板修订

本轮将子 agent 最终回复首段固化为：

```text
RV64 RTL 对象或本地证据文件
→ 周期或编译配置
→ testbench/EDA 观测
→ PASS/GAP/inconclusive 范围
```

本地 JSON 证据校验出现意外接受或拒绝时，回复必须给出具体 schema 字段、工作区相对路径、
定向单测和返回结果。该规则只调整证据叙述顺序，不建立关键词黑名单，不删减
`workspace-files`、shell、RTL 实现、负向 RTL 变体、断言、覆盖矩阵、未知项、替代假设或
`scope_extension_request`。

## AI 环境与收尾证据

- `npc-dev` task-specific run
  `.github/task-runs/2026-07-23-control-event-rtl-evidence/`：5/5 nodes，completed。
- `agent-system` final run
  `.github/task-runs/2026-07-23-rtl-task-contract-final-response-revtag-v9q/`：10/10 nodes，
  completed；其 `rtl-task-contract` 节点包含 generator audit、28 项 self-test 与 20 项
  CLI self-test。
- 两类 blocked run 原样保留：未跟踪 Python bytecode 使 discovery fail；默认 2400-token
  bounded brief 放不下必需完整 skill chunk。随后使用受支持的
  `E2E_CONTEXT_BRIEF_MAX_TOKENS=4000` 保持 canonical/profile/focus 全部必需 chunk，不降低
  non-history recall 门禁。
- `scripts/agent-maintain.sh --mode check` 最终 PASS；三份 DB-owned memory 与
  `.github/db-backup` 哈希一致，`audit-db-first` PASS。
- `scripts/agent-e2e.sh --guard --guard-mode strict` 最终同时接受
  `agent-system` 与 `npc-dev` 的 fresh completed evidence。
