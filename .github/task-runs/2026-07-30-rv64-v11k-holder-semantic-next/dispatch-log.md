# V11K subagent dispatch log

## 候选预审

- 合同：
  `.github/task-runs/2026-07-30-rv64-v11k-holder-semantic-next/subagent-contracts/v11k-holder-semantic-candidate-pre-review.json`
- 合同 JSON SHA-256：
  `a044b39271759e835d012a24d3d32acee39ffa4078ea4acd00acbc6fd7dbfed0`
- 模式：`read-only-review`、`workspace-files`、`fork_turns="none"`。
- 结果：GAP；建议只闭合 `miq-owner-tokens`，并补齐完整 tuple X/Z、
  双实例 cross reject、idle stability 与 occupancy exact-set 证据。
- shell ownership：已归还。

## 独立终审

- 合同：
  `.github/task-runs/2026-07-30-rv64-v11k-holder-semantic-next/subagent-contracts/v11k-miq-holder-semantic-final-review.json`
- 合同 JSON SHA-256：
  `559c2a312b6f17cf09979a837505a9f120fd492f5eb7bc7b9d919023c5c89c06`
- 合同状态：canonical `create → validate → render` PASS。
- 模式：`read-only-review`、`workspace-files`、`fork_turns="none"`。
- 状态：已准备派发，single-flight shell ownership 交给终审节点。
- 审查重点：功能 RTL 是否保持不变、两个产品实例是否精确绑定、
  assertion/release 变体是否真实编译并被独立观测拒绝、两态
  elaboration 恒等证据是否足以支持“不触发 V11K 系统重跑”、局部 PASS
  是否越界。
- attempt 1 结果：GAP；未发现功能 RTL 反例，发现两项证据 blocker：
  push/pop tuple marker 无直接 X/Z profile，以及三个普通回归缺少执行时
  source/vvp/post-hash 绑定。
- 结果文件：`final-review-result-attempt-1.md`。
- shell ownership：已归还。
- 后续动作：生成新的 verification 增量并在重建证据后使用 versioned
  read-only-review 合同复审；attempt 1 保留，不改写。

## 独立复审 attempt 2

- 合同：
  `.github/task-runs/2026-07-30-rv64-v11k-holder-semantic-next/subagent-contracts/v11k-miq-holder-semantic-final-review-v2.json`
- 合同 JSON SHA-256：
  `d0f7816e66e3de3826e0aafd06bf421deab048f55088b1da996feeeca1d526cb`
- 合同状态：canonical `create → validate → render` PASS。
- 模式：`read-only-review`、`workspace-files`、`fork_turns="none"`。
- 状态：已准备派发，single-flight shell ownership 交给复审节点。
- 复审重点：attempt-3 的四个 push/pop X/Z probe、release 固定状态
  oracle、三回归 source/vvp/post-hash、生产 MIQ SHA、双产品路径与两态
  elaboration 恒等。
- 结果：局部 PASS；attempt-1 两项 blocker 均 CLOSED，无
  `scope_extension_request`。
- 结果文件：`final-review-result.md`。
- shell ownership：已归还。

## 环境证据与严格门禁

- project/module memory 以完整正文分别写回 stored DB：
  99698 bytes、100818 bytes；随后恢复 live shim 并刷新 stored snapshot。
- `npc-dev`：
  `.github/task-runs/2026-07-30-OooMemInflightQueue/`，5/5 节点 PASS，
  canonical completion publication PASS。
- `agent-system`：
  `.github/task-runs/2026-07-30-rtl-task-contract/`，11/11 节点 PASS，
  canonical completion publication PASS。
- 第一次 scoped strict guard 未显式传入 `--evidence-dir`，候选集合为空，
  原始结果为 FAIL；文件 mtime 均早于 profile 完成时间，不是证据陈旧。
- 显式绑定
  `.github/task-runs/2026-07-30-OooMemInflightQueue` 后，同一组 11 条路径
  strict guard PASS。
- `audit-db-first`、`audit-markdown-coverage --fail-on-live-evidence`、
  producer/holder 统一门禁与 `check-rtl-style` 最终均以顶层 rc=0 完成。
- 同一独立 reviewer 在不运行 shell、不读取新材料、不扩展范围的
  follow-up 中给出
  `reviewer_conclusion=APPROVED_FOR_CURRENT_SCOPE`；结果单独保存在
  `final-review-enum-followup.md`，原终审正文未改写。
