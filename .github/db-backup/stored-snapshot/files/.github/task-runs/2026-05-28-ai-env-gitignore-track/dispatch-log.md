# Dispatch Log

## 2026-05-28

### `audit-ignore`

- `owner`: `Codex`
- `inputs`: `.gitignore`、`.git/info/exclude`、`core.excludesfile`、AI 环境相关路径。
- `action`: 检查本地忽略规则与 Git 状态。
- `outputs`: `.github` 主配置已在 Git 索引中；新打包目录显示为 `??` 未跟踪，不是 `!!` 被忽略；未发现额外全局 ignore 文件。
- `next_step`: 在 `.gitignore` 追加显式 allowlist。

### `edit-gitignore`

- `owner`: `Codex`
- `inputs`: `.gitignore`
- `action`: 追加 AI 开发环境 allowlist，覆盖 `.github/**`、根 shim、`.cursor/rules/agents.mdc` 和脱敏便携包。
- `outputs`: `.gitignore` 更新完成。
- `next_step`: 验证跟踪状态。

### `verify`

- `owner`: `Codex`
- `inputs`: 修改后的 `.gitignore`
- `action`: 运行 `git check-ignore`、`git status --short --ignored -uall` 与 `git diff --check`。
- `outputs`: 核心 `.github` 与 shim 未被忽略；新 task-run 与便携包显示为 `??` 可跟踪状态；`git diff --check` PASS。
- `next_step`: 更新 memory 与 task-run。

### `record`

- `owner`: `Codex`
- `inputs`: 修改与验证结果。
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/agent-system.md`，并写入本 task-run。
- `outputs`: 记录完成。
- `next_step`: 向用户汇报改动与验证。
