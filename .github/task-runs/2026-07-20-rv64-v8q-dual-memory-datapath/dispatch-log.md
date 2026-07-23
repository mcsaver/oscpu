# v8q/F0 子 agent 派发记录

本文件记录自包含 no-tools 合同的路径/SHA、原始渲染提示、review 状态和可操作反例。
在合同生成与审查完成前，不记录技术 PASS。

## F0 合同独立反例复核

- task id：`v8q-dual-memory-fabric-contract-review`
- 状态：`gap_resolved_in_contract_pending_executable_evidence`
- 合同 JSON：`.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/subagent-contracts/v8q-dual-memory-fabric-contract-review.json`
- 合同 JSON SHA-256：`80cdbc9c6fbf1cca3e322acf2ef872bc0b521bd1dc719109c93dbcadd3ce255d`
- 哈希边界：只绑定上述 JSON，不绑定 spec、`contract.md`、RTL 或测试。
- 执行边界：原生 `self-contained-no-tools`；`allowed_commands=[]`、`write_paths=[]`、
  无 shell/文件访问/网络/账号/凭据/外部服务。
- 派发对象：已存在的独立 reviewer `v8o_di4_contract_review`；派发内容为该 JSON 的
  `render` 原样输出，未附加或扩大权限。
- 原始问题：检查 registered owner 是否覆盖完整 AR->R/AW-W->B 生命周期、AW/W
  独立反压、非 owner response 隔离、terminal 后 bounded fairness、非法 read+write、
  reset/flush 边界以及 F0 不越级到 DI-5。
- reviewer 返回 `gap`，blocker 为 F0-G01..G05；完整结构化摘要保存于
  `contract-review-result.json`，逐项闭合映射保存于 `contract-review-resolution.md`。
- 合同修订没有扩大权限或改变父目标；所有可操作反例都已映射到 TB、mutation 或
  fail-closed checker，待执行结果通过后再申请复核。

## F0 最终合同复审

- task id：`v8q-dual-memory-fabric-final-contract-rereview`
- 状态：`pass`（F0-G01..G05 全部 closed，remaining blockers=0）
- 合同 JSON：`.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/subagent-contracts/v8q-dual-memory-fabric-final-contract-rereview.json`
- 合同 JSON SHA-256：`ddfc6d7898c77b2cc660f60579660ba421064e6d6057e95278db7ab0d39b8487`
- 执行边界：原生 `self-contained-no-tools`；无命令、无 shell/文件访问/网络/账号/
  凭据/外部服务/写入。
- 绑定事实：最终 run `v8q-f0-20260720T030925Z-849762`、closure
  `d271ddf5fca6c6c8ef552fb1c1111b691e43e77714aeb51f3720dedbe18a5186` 与 canonical
  design id `sha256:79e445cd976f7a2ace1da6288866b2442846677520052a95eea7c14504ab2cca`。

## F0 最终实现审查

- task id：`v8q-dual-memory-fabric-final-review`
- 状态：`pass`（blockers=0，same-digest publication 与 claim boundary 均为 true）
- 合同 JSON：`.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/subagent-contracts/v8q-dual-memory-fabric-final-review.json`
- 合同 JSON SHA-256：`191ff2dc5506253ad0c82a3db8eb8f768e72535f8f0de3a44c0d9baaf382e46d`
- 派发对象：独立 reviewer `v8o_di4_implementation_review`；只消费 prompt 内冻结材料。
- reviewer 明确声明 `tools_used=false`、`filesystem_reads=false`、`writes=false`、
  `network=false`；完整结构化结论保存于 `implementation-review-result.json`。
- 审查结论只授权 `dual_axi_miss_fabric_leaf_verified`；DI-5、OOO-3、overall 保持 RED，
  PPA 保持 UNQUALIFIED；长期父目标保持 `active`。

## e2e startup recall 纠偏记录

- 首次 `agent-system` run `2026-07-20-no-tools-rtl-subagent-contract-v8q` 与首次
  `github-index` run `2026-07-20-db-first-stored-memory-audit-v8q` 保留为 blocked：业务节点
  PASS 不能覆盖 startup recall 的 `v8q` primary-focus 缺失。
- root cause：task slug 归一化误把末尾迭代标签当作 non-history AND focus；不属于 RTL
  技术内容、子 agent 权限或外部访问问题。
- 第一版末尾词形启发式被 provisional no-tools reviewer 以 `SLUG-G01/G02` 否决：短
  lifecycle slug 会假非空，JavaScript V8/v2ray 会被误删；该派发缺少预绑定 JSON，明确不作
  最终 provenance，gap 与修订分别保存在 `task-slug-review-gap.json` 和
  `task-slug-review-resolution.md`。
- canonical 修复：只删除受控相邻片段 `revtag-v<数字><可选字母>`，并在 stopword/数字/
  去重/八词截断前处理；裸版本词保留，畸形或重复 marker 非零。实现位于
  `scripts/e2e/lib/report.sh`，正反回归接入 `scripts/e2e/modules/agent_system.sh`，规则同步到
  `AI_ENVIRONMENT.md`、e2e README 和 path-specific instruction。
- 最终复审 task id `v8q-task-slug-revision-review`；合同 JSON
  `subagent-contracts/v8q-task-slug-revision-review.json`，SHA-256
  `46fe3b4d3cd33b088d4f32292b196f598a7d7a8f24bef139d706dbce8d040c82`。原生
  `self-contained-no-tools`，无命令/文件/网络/写入；reviewer 裁决 G01/G02 closed、
  blockers=0，结果保存于 `task-slug-review-result.json`。
- `2026-07-20-no-tools-rtl-subagent-contract-revtag-v8q` 已 completed/10 节点 PASS/
  recall complete，strict guard 接受。task slug 原文保留在 task/report/manifest/DB，只改变
  focus terms；两次旧 freshness 失败保留，fresh run 前后 live source SHA/mtime 不变。
- 最终 memory/DB/task-run 同步后的 freshness runs：
  `2026-07-20-no-tools-rtl-subagent-contract-revtag-v8q-final`（agent-system 10/10）、
  `2026-07-20-db-first-stored-memory-audit-revtag-v8q-final`（github-index 1/1）、
  `2026-07-20-dual-memory-axi-fabric-revtag-v8q-final`（npc-dev 5/5），均 completed 且
  recall complete。
