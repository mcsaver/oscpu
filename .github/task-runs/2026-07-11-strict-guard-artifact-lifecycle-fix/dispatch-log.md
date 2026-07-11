# 派发日志

| worker | scope | status | result |
| --- | --- | --- | --- |
| `archive_evidence_workflow` | 核对 evidence archive/index 命令与副作用 | completed | `index-evidence/archive-evidence` 只建索引，不移动 raw；解除跟踪需独立 `git rm --cached`。 |
| `guard_fix_review` | 独立复核 strict guard 根因与最小修复 | completed | 临时 Git index 模拟证明解除唯一超限 raw 跟踪后 `artifact-audit` 可由 FAIL 变 PASS。 |
| `topo40_reference_audit` | 审计 raw 资产、文档引用与 legacy run 边界 | completed | 三份 raw 共 2,629,949 bytes；应增补派生索引，不应为 legacy/manual run 伪造 e2e manifest。 |

主线程负责串行执行 WSL 命令、保持现有 staged rename、不覆盖用户工作树，并完成 DB memory 回写与最终验证。
