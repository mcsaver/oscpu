# Agent E2E Workflow

## 场景隔离入口

- NEMU-only 开发：`scripts/agent-e2e.sh --profile nemu-dev`
- NEMU-only full gate：`AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate`
- NPC-only 开发：`scripts/agent-e2e.sh --profile npc-dev`
- 旧集成入口：`scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate`

`nemu-dev*` 和 `npc-dev` 是场景隔离入口；旧 `nemu-ubuntu*` profile 保留集成功能，不能为了隔离而删除 NPC/RV64 Linux 节点。NEMU 软件/系统模型任务使用 `software-flow` 的 `hardware-aware-software-loop`，再叠加 `nemu-dev` 或明确的 `nemu-ubuntu` 集成 gate。

## 执行卫生

- 工程命令通过 WSL single-flight 执行，避免并发启动多个 `wsl.exe`。遇到 `Wsl/Service/E_UNEXPECTED` 先做 WSL 健康检查并串行重试。
- 真实构建/e2e 优先使用 `scripts/agent-run.sh`，让非交互环境加载 `scripts/agent-env.sh`。
- 外层工具控制符会污染命令字符串。多模式搜索优先使用 `rg -e foo -e bar`，不要依赖带 `|` 的单个正则穿过外层 shell。

## 完成判定

完成后必须查看 task-run report、profile resolve、关键 evidence、FAIL marker 和 memory 更新。不能只看外层退出码，也不能从 `.github/db-backup` 绕开当前 DB-first recall 问题。
