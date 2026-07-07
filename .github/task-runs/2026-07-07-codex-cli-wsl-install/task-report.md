# 任务报告

## 基本信息

- `task_id`: `2026-07-07-codex-cli-wsl-install`
- `task_slug`: `codex-cli-wsl-install`
- `graph_template`: `agent-env-refactor`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-07-07 14:30 Asia/Shanghai`
- `updated_at`: `2026-07-07 14:50 Asia/Shanghai`

## 任务目标

- `source_request`: 用户要求“请你在wsl中安装codex的cli，不知道为什么我感觉cli更加好用一些”。
- `goal`: 在 Ubuntu WSL2 中安装可直接使用的 Codex CLI，并确保 WSL 交互 shell 优先命中 Linux 原生 CLI。
- `scope`: 仅安装用户级 Codex CLI、调整 WSL 用户 shell PATH、验证 CLI/doctor；不改工程构建代码，不触碰现有大规模本地改动。

## 选图说明

- `selected_template`: `agent-env-refactor`
- `why_this_graph`: 任务属于 AI 开发环境/agent 工具链维护，需按 agent-system 规则读取说明、选择轻量 profile 并留下证据。
- `dynamic_nodes_added`: `codex-cli-install`, `path-precedence-fix`, `codex-doctor-verify`
- `why_dynamic_nodes_were_needed`: 仓库现有 profile 不直接覆盖“宿主 WSL 用户级 CLI 安装”，因此以直接命令证据补齐。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall` | `Codex` | `completed` | `AGENTS.md`、agent-system memory、agent-e2e workflow、e2e README、官方 Codex CLI 页面 | 明确 WSL single-flight 与 agent-system profile 约束 | 已读文件与 `scripts/agent-e2e.sh --list-profiles` 输出 |
| `codex-cli-install` | `Codex` | `completed` | 官方 Linux standalone installer | `codex-cli 0.142.5` 安装到 `/home/lyg/.codex/packages/standalone/releases/0.142.5-x86_64-unknown-linux-musl` | installer 输出 `Detected platform: Linux (x64)`、`Resolved version: 0.142.5`、`installed successfully` |
| `path-precedence-fix` | `Codex` | `completed` | WSL PATH 中 Windows Codex App 路径先于用户本地入口 | `/home/lyg/.profile` 与 `/home/lyg/.bashrc` 前置 `~/.local/bin` | `bash -i -c 'type codex'` 输出 `codex is /home/lyg/.local/bin/codex` |
| `codex-doctor-verify` | `Codex` | `completed` | 新安装 CLI | CLI 可执行、auth/config/runtime 基本健康 | `codex --version` 输出 `codex-cli 0.142.5`；`codex doctor --summary --ascii` 输出 `16 ok | 1 idle | 1 notes | 1 warn | 0 fail degraded` |
| `agent-system-profile-validate` | `Codex` | `completed` | `.github/e2e/profiles/agent-system.tsv` | profile 解析成功 | `scripts/agent-e2e.sh --validate-profile --profile agent-system` 9 节点 OK |
| `bashrc-color-restore` | `Codex` | `completed` | 用户反馈 WSL 变纯黑白；`/home/lyg/.bashrc.bak.1776653713` | 恢复原 `.bashrc` 彩色 prompt、`ls --color=auto` 和工程环境变量，仅在开头保留 Codex PATH 前置块 | `alias ls='ls --color=auto'`；PS1 含 ANSI 颜色；`codex is /home/lyg/.local/bin/codex` |

## 关键产物

- `artifacts`: `/home/lyg/.codex/packages/standalone/releases/0.142.5-x86_64-unknown-linux-musl`、`/home/lyg/.local/bin/codex`、`/home/lyg/.profile`、`/home/lyg/.bashrc`
- `logs_or_traces`: 本报告的节点证据摘要；安装与 doctor 原始输出在当前 Codex 线程终端记录中。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/agent-system.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 唯一 doctor warning 来自非交互执行环境的 1x1 terminal size，正常 WSL 终端不应受影响。极简 `.bashrc` 导致颜色丢失的问题已通过备份恢复闭合。

## 下一步建议

1. 首次手动运行 `codex` 时按提示登录 ChatGPT 或配置 API key。
2. 若以后升级 standalone 安装，按官方建议重新运行 installer 或使用 `codex update`。

## 模板升级候选

- `repeated_dynamic_subgraph`: WSL 中安装/升级 Codex CLI 并修 PATH 优先级。
- `should_promote_to_static_template`: `false`
- `reason`: 这是一次性本机环境维护，不需要沉淀成工程 e2e 模板。

## 收尾结论

- `final_result`: WSL 原生 Codex CLI 已安装并通过 doctor，交互 WSL shell 会优先使用 `/home/lyg/.local/bin/codex`。
- `evidence_summary`: `type codex` 命中本地入口；`codex-cli 0.142.5`；Doctor 16 ok、0 fail；`alias ls='ls --color=auto'` 与彩色 PS1 恢复；agent-system profile validate PASS。
- `notes`: 官方 Codex manual helper 在 Windows 侧 DNS 解析 `developers.openai.com` 失败，后续通过官方 web 页面确认 Linux standalone installer 命令；WSL 自身网络可访问 `https://chatgpt.com/codex/install.sh`。
