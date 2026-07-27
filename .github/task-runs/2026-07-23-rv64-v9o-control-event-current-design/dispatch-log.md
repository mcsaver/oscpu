# V9O dispatch log

## control-event-root-cause-review-v1

- task kind：本地 RV64 OoO 控制事件 request/apply 调用链只读复核。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-root-cause-review-v1.json`。
- contract SHA-256：
  `3d729806c0512a0cc407fd5a8c0ed9acc5be0120eccc85290d177a9cb3e461c3`。
- contract pipeline：canonical `create → validate → render` 已通过。
- write paths：空；工程命令仅 `rg` / `sed` read-only。
- reviewer：`/root/v9n_owner_residency_review`。
- WSL shell ownership：派发时由主 agent 交给 reviewer；返回前主 agent 与其它节点不运行
  工程命令。
- reviewer interim：确认完整 arbiter winner 直接回送后端会读入
  `backend ready → frontend direct fire → arbiter` 组合锥，存在 SCC 风险；branch source
  本身是寄存解析，且授权路径刻意避开 killed-now cone。E3 若改到下一拍会放开本拍
  WB/PRF/wakeup 与 memory request，违反现有同拍切断。
- scope extension：需要 `OooWriteback`、DispatchBackend/ROB/IQ/SQ/FP/AXI 等内部 holder
  路径来闭合完整 fanout 与事务边界。主 agent 未在 v1 上口头扩域，已建立 v2 合同。
- reviewer final：`GAP`。确认 E3 若整体寄存到下一拍会打开本拍
  WB/PRF/wakeup/memory-request 窗口；完整 winner 回送则有 direct-ready SCC 风险。建议 typed
  action=`NONE|SELECTIVE_NOW|FULL_NEXT`，raw E3 与旧 trap/serial q 在迁移期仅作
  shadow-equivalence。
- WSL shell ownership：reviewer 已停止全部工程命令并明确归还。
- status：`REVIEW_COMPLETE_SCOPE_EXTENSION_REQUIRED`。

## control-event-stage-proof-v1

- task kind：本地 RV64 OoO 控制事件冻结材料周期证明复核。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-stage-proof-v1.json`。
- contract SHA-256：
  `f94e03c3272aba616b03c7835121376207cf09c6e052588c15aeb71b87d0f8b9`。
- contract pipeline：canonical `create → validate → render` 已通过。
- execution mode：`self-contained-no-tools`；不读取仓库、不执行工程命令、不持有 WSL shell。
- reviewer：`/root/v9l_owner_signal_review`。
- status：`DISPATCHED`。

## control-event-root-cause-review-v2

- task kind：本地 RV64 OoO typed backend grant 与 C0/C1 全 consumer 扩展只读复核。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-root-cause-review-v2.json`。
- contract SHA-256：
  `3c8a478d0b19f9d6caeeebefe12a9fb7efb6bdc6f45c0895232a6258df068e49`。
- contract pipeline：canonical `create → validate → render` 已通过。
- write paths：空；工程命令仅 `rg` / `sed` read-only。
- reviewer：`/root/v9n_owner_residency_review`。
- scope correction：新增 writeback、rename/allocate、scheduling、memory、FP/long-op 与相关 TB；
  旧 v1 结果只保留为范围发现，不外推为完整证明。
- WSL shell ownership：派发时重新交给 reviewer；返回前主 agent 与其它节点不运行工程命令。
- status：`SUPERSEDED_BEFORE_DISPATCH`；V1 明确要求同时纳入 `define.v` 以冻结
  reason/action enum，故不派发此 JSON。

## control-event-root-cause-review-v2b

- task kind：本地 RV64 OoO typed backend grant 与 C0/C1 全 consumer 扩展只读复核。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-root-cause-review-v2b.json`。
- contract SHA-256：
  `c7b791acc6ec0a2b582f251bffd4c6246d2cb2b519483fd9f7444f94ba5ec31b`。
- contract pipeline：canonical `create → validate → render` 已通过。
- scope correction：在 v2 路径集上补入 `npc/rv64/vsrc/include/define.v`；v2 未派发。
- write paths：空；工程命令仅 `rg` / `sed` read-only。
- reviewer：`/root/v9n_owner_residency_review`。
- WSL shell ownership：派发时交给 reviewer；返回前主 agent 与其它节点不运行工程命令。
- status：`DISPATCHED`。

## control-event-final-review-v1

- task kind：本地 RV64 CONTROL-EVENT-G1 current-design 全链路只读终审。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-final-review-v1.json`。
- contract SHA-256：
  `de9b6cdfc98377d7e06bd2ee7ea70b4fb71fa04d137d61c0c9dbe122ecd3ad0f`。
- reviewer：`/root/v9o_control_event_final_review`。
- reviewer result：`GAP`。确认 C0/C1 基本时序和 registered AXI owner 局部成立，但当时
  production winner、pending CSR owner、真实 completion matrix 与证据 source binding 尚未闭合。
- disposition：所有可操作反例均进入后续 RTL/TB/变异与 evidence-index 修订；该轮结果不用于关闭
  ledger。
- WSL shell ownership：reviewer 已显式归还。

## control-event-final-review-v2

- task kind：扩展本地 RV64 控制事件 RTL/spec/TB/evidence 输入后的只读复核。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-final-review-v2.json`。
- contract SHA-256：
  `e58d4183df497927263cefe6299bb5c355b1a0e5508e203ce33c43a9b143e105`。
- reviewer：`/root/v9o_control_event_final_review_v2`。
- reviewer result：合同内叶机制 `PASS`，ledger closure 仍为 `GAP`。四个承重缺口为：
  C0 request 仍可能由 trap/CSR pulse 重构、日志没有 current source identity、没有真实
  full-C0×8 completion matrix、没有双 lane registered-AR×persistent-barrier oracle。
- disposition：新增唯一 ROB pregrant request 源和 TRAP/CSR 双向断言；全部 runtime log 绑定
  146-file RTL/133-file verification source set；新增 8/8 completion 与双路 AR 定向轨迹；
  mutation 从 10 扩为 11。
- WSL shell ownership：reviewer 已显式归还。

## control-event-final-review-v3

- task kind：包含 CSR mux、ControlPlane、execute/decode transport、8 类 completion 与双路 AXI
  路径的扩展只读终审。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-final-review-v3.json`。
- contract SHA-256：
  `531155c38ba4a7ee8a13516d548d0abfd2f894f7a922e38230664a89f7d3d833`。
- reviewer：`/root/v9o_control_event_final_review_v3`。
- reviewer result：7 项 RTL/验证机制 `PASS`，1 项合同 source-binding `GAP`。v3 成功条件误写
  62 个十六进制字符的 design ID `...f8048c`，而 current source identity 为合法 64 字符
  `...f8048c6a`。
- disposition：该轮技术观察保留，但 exact-contract 裁决不追认为 PASS；未口头修补旧合同，
  新建 v4。
- WSL shell ownership：reviewer 已显式归还。

## control-event-final-review-v4

- task kind：修正完整 64 字符 design ID 后，对同一 current-design RTL/验证集合重新独立签收。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-final-review-v4.json`。
- contract SHA-256：
  `cbad928e3e6e88a1063b3e5426e29516cabb25878ef8b6b704d83c4c189a61bb`。
- reviewer：`/root/v9o_control_event_final_review_v4`。
- reviewer result：唯一 C0 request、TRAP/CSR 双向等价、C0/C1、无环投影、8 类 strict-younger
  completion、pending CSR ProducerId、LQ edge-old permit、双路 registered AR 与 current
  source binding 共 8/8 `PASS`；建议仅将 `CONTROL-EVENT-G1` 更新为 `CLOSED`。
- residual boundary：无全状态形式证明；双路 AR 为 wrapper-level persistent-barrier oracle；
  full-core candidate 仍绑定旧 `2eff...c8b2`。
- WSL shell ownership：reviewer 已显式归还。
- status：`REVIEW_COMPLETE_LOCAL_CLOSURE_APPROVED`。

## ledger semantic publication

- `architecture-debt-ledger.json` 已把 `CONTROL-EVENT-G1` 更新为 `CLOSED`，绑定 live RTL
  `sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`
  与 verification source
  `sha256:300da14d23d25c35168fa62277be014c255ab5198ef5d786ffe28348b700c3c1`。
- `arch_stable_freeze.py` 新增 debt-specific semantic validator，独立复算 source sets、164 个
  非自指索引产物、focused/config/module markers、11 个 compile-success RTL 变异及 full-core
  GAP/PPA 边界。
- 首轮下游 replay 暴露 evidence-index→audit/log→ledger→evidence-index 的自指哈希环；
  修复为局部索引只记录 full-core 边界标量，不反向绑定正在生成的 audit/log。
- 最终 boundary audit/verify：`GAP`、59 blockers、`PPA=UNQUALIFIED`、
  `promotion_eligible=false`。`debt.CONTROL-EVENT-G1.semantic_evidence=PASS`；
  `closed_binding=GAP` 仅表示旧 full-core candidate design ID 不能消费当前局部闭合证据。

## control-event-ledger-validator-review-v1

- task kind：本地 RV64 `CONTROL-EVENT-G1` ledger/evidence validator 只读复核。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-ledger-validator-review-v1.json`。
- contract SHA-256：
  `5972ce3407a19eaa361e49735d3872eac7524082ac383c0356ae43f37588361e`。
- reviewer result：`GAP`。要求 validator 独立复算 exact provenance、完整语义 evidence、
  11 项 RTL mutation mapping、live Makefile module inventory 和 live full-core candidate
  identity，不能只信任 builder 自报字段。
- disposition：五项均已实现为共享 validator 检查和定向单测。

## control-event-ledger-validator-review-v2

- task kind：修订后 validator 的 workspace-files 复核与本地 JSON 负向形状验证。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-ledger-validator-review-v2.json`。
- contract SHA-256：
  `0bbc76666726d66ab1dd6224d4e2d7718f5e7e3231dd182ea2e83c5edb1248f8`。
- reviewer report：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/validator-review-v2/review.md`
  (`sha256:531cd4c384c73da4fae3f927b6222f0d90ec3c8e3bdfece33936dc1b397a4d3a`)。
- reviewer result：`GAP`。`mutations/summary.json` 可额外内嵌指向
  `gates/arch-stable-audit.json` 的 artifact，而完整 validator 当时仍接受。
- disposition：mutation summary/result 使用 exact schema；递归拒绝 boundary-generated
  reference；逐项绑定 result 类型、source、make variable、returncode、marker、log 和 baseline；
  full-core inventory 单测改为 live 110。

## control-event-ledger-validator-review-v3

- task kind：v2 反例关闭后的 architecture hard-gates artifact 路径与内容复核。
- contract JSON：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/subagent-contracts/control-event-ledger-validator-review-v3.json`。
- contract SHA-256：
  `d6dc3fc808fa859b97a6bc415ba3ac0fb0f98b40d92867479cf31f9616da368c`。
- reviewer report：
  `.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/validator-review-v3/review.md`
  (`sha256:e227150f98d74536a9c144dc2234158f82738f1a92f40e1d17159113ce8a2a0c`)。
- reviewer technical result：canonical verify 164 artifacts PASS，v2 两个 mutation-summary
  反例均被拒绝；另发现 architecture result 可被替换为另一 workspace-relative JSON，并在副本中
  内嵌 ledger artifact reference，而完整 validator 当时仍接受。
- coordination state：reviewer 已写入 report/replay fixtures，最终自然语言回复在 Codex UI 展示阶段
  中断；节点记为 `REVIEW_PENDING_DISPLAY_INTERRUPTION`，未把该最终回复追认为正式 PASS。
- disposition：architecture result/manifest/refresh log 绑定 canonical path；result/manifest
  exact schema、9 gate identity/status、current RTL source identity 与递归 boundary-reference
  检查已落地。新增 architecture JSON relocation/reference 两项定向单测。

## post-review current-design replay

- evidence index：
  `sha256:d73a69cdfd92f42ed87e9e60a0c5389c343e4261ab6cf8b6fddc957245124da0`，
  164 artifacts，current design `sha256:08d3...8c6a`，PASS。
- selected validator tests：5/5 PASS。
- `make -C npc/rv64 check-contract`：471 assertions，13/13 tests PASS。
- full-core boundary：candidate `sha256:2eff...c8b2` 与 current design 不同，59 blockers，
  `PPA=UNQUALIFIED`，promotion false。

## RV64 final-response evidence order

- contract/config/tool/docs/e2e 已统一要求子 agent 首段按“RV64 RTL 对象或本地证据文件 →
  周期或编译配置 → testbench/EDA 观测 → PASS/GAP 范围”组织。
- 本地 JSON evidence validator 的意外接受或拒绝必须写明具体 schema 字段、工作区相对路径、
  定向单测和返回结果。
- 该规则不建立关键词黑名单，也不改变模型、`workspace-files`、shell、实现、验证、PPA、
  负向 RTL 变体、断言、覆盖、未知项或范围扩展能力。

## workflow replay and strict guard

- `npc-dev`：
  `.github/task-runs/2026-07-23-control-event-rtl-evidence/`，5/5 nodes，completed。
- `agent-system` 首次 run 因本轮 `py_compile` 生成的单一未跟踪 bytecode 在 discovery
  节点被拒绝；清除该临时文件后，第二次 run 的 10 个功能节点均 PASS，但默认 2400-token
  bounded brief 无法容纳必需的完整 skill chunk，publication 保持 blocked。
- 使用受支持的 `E2E_CONTEXT_BRIEF_MAX_TOKENS=4000` 后，
  `.github/task-runs/2026-07-23-rtl-task-contract-final-response-revtag-v9p/` completed。
  memory backup 同步发生在该 run 之后，freshness guard 正确要求再重放。
- final fresh run：
  `.github/task-runs/2026-07-23-rtl-task-contract-final-response-revtag-v9q/`，
  10/10 nodes，completed。
- `agent-maintain --mode check` 与 `audit-db-first` 最终 PASS；strict guard 对
  `agent-system` 和 `npc-dev` 均 PASS。
