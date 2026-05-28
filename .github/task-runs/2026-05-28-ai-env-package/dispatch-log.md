# Dispatch Log

## 2026-05-28

### `scope-audit`

- `owner`: `Codex`
- `inputs`: 用户要求打包 `.github` 等 AI 开发环境配置，便于压缩发送。
- `action`: 复核 `.github`、根 shim、`.cursor` 入口、关键 README/study/spec 文档，区分私有迁移包和可发送脱敏包。
- `outputs`: 选择生成可发送脱敏目录，默认不携带历史 `.github/task-runs/YYYY-*`。
- `next_step`: 生成包目录。

### `package-build`

- `owner`: `Codex`
- `inputs`: `.github/AGENTS.md`、`copilot-instructions.md`、`agentic-hardware-blueprint.md`、`agents/`、`instructions/`、`memory/`、`task-runs/templates/`、根 shim、关键工程文档。
- `action`: 创建 `outputs/manual-20260528-ai-dev-env-package/ysyx-ai-hardware-env-portable/`，复制配置和文档，并新增包内 `README.md`、`PACKAGING_MANIFEST.md`、`examples/env.example.sh`。
- `outputs`: 便携包目录生成完成。
- `next_step`: 机械脱敏。

### `sanitize`

- `owner`: `Codex`
- `inputs`: 包内 Markdown、shim、shell 示例和规则文件。
- `action`: 将本机路径和 ysyx 标识替换为 `${YSYX_HOME}`、`${LOCAL_BIN}`、`${RISCV_TOOLCHAIN_ROOT}`、`${TMPDIR}`、`<YSYX_ID_TOP>`、`<YSYX_ID_NUM>`。
- `outputs`: 包内文本完成脱敏。
- `next_step`: 敏感信息复扫。

### `verify`

- `owner`: `Codex`
- `inputs`: `outputs/manual-20260528-ai-dev-env-package/ysyx-ai-hardware-env-portable/`
- `action`: 执行严格凭证扫描、secret 文件候选扫描、常见本机路径和学号标识复扫，并统计包大小。
- `outputs`: 严格凭证扫描无命中；secret 文件候选无命中；`/home/lyg`、`/tmp/`、`26010035`、`ysyx_26010035` 复扫无命中；包内 66 个文件，大小约 916K。
- `next_step`: 更新 memory 与 task-run。

### `record`

- `owner`: `Codex`
- `inputs`: 打包产物与验证结果。
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/agent-system.md`，并写入本 task-run。
- `outputs`: 记录完成。
- `next_step`: 向用户汇报包路径和验证结论。
