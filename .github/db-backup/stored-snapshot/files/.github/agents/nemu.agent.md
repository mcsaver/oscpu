# NEMU Agent

## 默认开发环境

NEMU 开发默认使用 NEMU-only profile，不再把集成 profile 当成普通 NEMU 开发入口：

- 快速 NEMU 开发合同：`scripts/agent-e2e.sh --profile nemu-dev`
- NEMU focused gate：`scripts/agent-e2e.sh --profile nemu-dev-gate`
- NEMU full Ubuntu 22.04 gate：`AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate`
- NEMU full soak：`AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-soak`

`nemu-dev*` 通过 `nemu-ubuntu-focused` 进入 `software-flow`、`nemu-ubuntu-static` 和 `nemu-ubuntu-slice-contract`，不得包含 `rv64-linux` 或 `npc-*` 节点。旧 `nemu-ubuntu`、`nemu-ubuntu-gate`、`nemu-ubuntu-full-gate`、`nemu-ubuntu-full-soak` 保留为跨 NEMU/NPC/RV64 Linux 集成 profile，只在明确需要集成验证时使用。

## 软件流程

NEMU 是用 C/Python/Shell/Make/Kconfig 写出的硬件和系统模型。涉及 NEMU C 侧、Linux tools、guest check、virtio/device model、QMP/GDB 或 host harness 的任务必须使用 `software-flow` 的 `hardware-aware-software-loop`：

`scope-contract -> hardware-semantic-contract -> design-plan -> implement -> software-focused-test -> system-or-hardware-gate -> review-record`

完成判定不能只看构建通过或外层退出码；必须结合 guest marker、BAD TRAP/GOOD TRAP、`__NEMU_CHECK_FAIL__` 负向扫描、task-run evidence 和 memory 更新。

## 当前边界

- NEMU-only 环境问题要在 `nemu-dev*` 或 focused make 中修，不从 `.github/db-backup` 绕答案。
- NPC/RTL/systemd 集成问题不应混入 NEMU-only 默认入口；需要跨栈时显式跑旧 `nemu-ubuntu*` 集成 profile。
- full Ubuntu 22.04 hostless APT lifecycle 当前 install 已有 preinst/postinst 证据，remove 与 empty-status download 仍按 known-issues 独立追踪。
