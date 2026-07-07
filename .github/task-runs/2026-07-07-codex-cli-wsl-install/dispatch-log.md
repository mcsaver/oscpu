# 派发日志

## 基本信息

- `task_id`: `2026-07-07-codex-cli-wsl-install`
- `task_slug`: `codex-cli-wsl-install`
- `graph_template`: `agent-env-refactor`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-07-07 14:30] `recall` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 用户要求在 WSL 中安装 Codex CLI。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/agent-system.md`、`.github/instructions/agent-e2e-workflow.instructions.md`、`.github/e2e/README.md`
- `action`: 读取仓库 agent 规范和 OpenAI Codex CLI 官方安装说明；运行 `scripts/agent-e2e.sh --list-profiles` 选择 agent-system 轻量验证路径。
- `outputs`: 采用官方 Linux standalone installer；WSL 命令保持 single-flight。
- `evidence`: 官方页面列出 `curl -fsSL https://chatgpt.com/codex/install.sh | sh`；`--list-profiles` 输出含 `agent-system`。
- `handoff_to`: `codex-cli-install`
- `next_step`: 在 WSL 中执行安装。
- `notes`: Windows 侧 Codex manual helper DNS 失败，改用官方 web 页面和 WSL 网络验证。

### [2026-07-07 14:37] `codex-cli-install` - `completed`

- `owner_agent`: `Codex`
- `trigger`: WSL 网络可访问官方 installer。
- `depends_on`: `recall`
- `inputs`: `curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh`
- `action`: 运行官方 non-interactive installer。
- `outputs`: 安装 `codex-cli 0.142.5` 到 `/home/lyg/.codex/packages/standalone/releases/0.142.5-x86_64-unknown-linux-musl`，创建 `/home/lyg/.local/bin/codex` symlink。
- `evidence`: installer 输出 `Detected platform: Linux (x64)`、`Resolved version: 0.142.5`、`Codex CLI 0.142.5 installed successfully`。
- `handoff_to`: `path-precedence-fix`
- `next_step`: 确认 `codex` 解析路径。
- `notes`: 初始 PATH 仍可能命中 Windows Codex App 路径，需单独验证。

### [2026-07-07 14:42] `path-precedence-fix` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 新 shell 中 `codex` 曾优先解析到 `/mnt/c/Program Files/WindowsApps/OpenAI.Codex_.../app/resources/codex`。
- `depends_on`: `codex-cli-install`
- `inputs`: `/home/lyg/.local/bin/codex` 已存在；WSL 用户 shell 启动文件缺失。
- `action`: 新增 `/home/lyg/.profile` 与 `/home/lyg/.bashrc`，把 `~/.local/bin` 放到 PATH 前面。
- `outputs`: 交互 bash 中 `codex` 命中 `/home/lyg/.local/bin/codex`。
- `evidence`: `bash -i -c 'type codex; codex --version'` 输出 `codex is /home/lyg/.local/bin/codex`、`codex-cli 0.142.5`。
- `handoff_to`: `codex-doctor-verify`
- `next_step`: 运行 doctor。
- `notes`: 不能只看版本号，因为 Windows App 路径也能输出同版本。

### [2026-07-07 14:45] `codex-doctor-verify` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 安装与 PATH 修复完成。
- `depends_on`: `path-precedence-fix`
- `inputs`: `codex doctor --summary --ascii`
- `action`: 运行 Codex Doctor。
- `outputs`: 本地安装、配置、auth、network、updates 均健康。
- `evidence`: `Codex Doctor v0.142.5 · linux-x86_64`，`install consistent`，`auth is configured`，`websocket connected`，总结 `16 ok | 1 idle | 1 notes | 1 warn | 0 fail degraded`。
- `handoff_to`: `agent-system-profile-validate`
- `next_step`: 验证 agent-system profile 可解析。
- `notes`: warning 仅为非交互终端 width/height 过小。

### [2026-07-07 14:48] `agent-system-profile-validate` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 仓库要求 AI 开发环境任务选择 profile 并生成证据。
- `depends_on`: `codex-doctor-verify`
- `inputs`: `scripts/agent-e2e.sh --validate-profile --profile agent-system`
- `action`: 验证 agent-system profile 展开与节点定义。
- `outputs`: 9 个节点全部 OK。
- `evidence`: 输出 `validate profile=agent-system nodes=9`，`recall-discovery`、`tool-env-check`、`three-layer-contract`、`runtime-artifact-boundary`、`state-machine-traceback` 等均 OK。
- `handoff_to`: 无
- `next_step`: 更新 memory 并交付。
- `notes`: 未运行 NEMU/NPC 重型门禁，符合本任务范围。

### [2026-07-07 15:05] `bashrc-color-restore` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 用户反馈新打开 WSL 后变成纯黑白。
- `depends_on`: `path-precedence-fix`
- `inputs`: `/home/lyg/.bashrc.bak.1776653713`、当前 `/home/lyg/.bashrc`
- `action`: 从备份恢复原 `.bashrc`，保留 Ubuntu 彩色 prompt、`ls --color=auto`、YSYX/RISC-V/Vivado/oss-cad-suite 环境，再在文件开头补 Codex PATH 前置块。
- `outputs`: WSL 交互 shell 同时恢复颜色与 Codex 本地入口优先级。
- `evidence`: `bash -i -c 'alias ls; declare -p PS1; type codex; codex --version'` 显示 `alias ls='ls --color=auto'`、PS1 含 `033[01;32m/033[01;34m`、`codex is /home/lyg/.local/bin/codex`、`codex-cli 0.142.5`。
- `handoff_to`: 无
- `next_step`: 用户重新打开 WSL 或执行 `source ~/.bashrc` 即可看到颜色恢复。
- `notes`: 根因是 PATH 修复时不应以极简 `.bashrc` 替换原用户配置。
