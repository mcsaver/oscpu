# NEMU Agent

## 默认开发环境

NEMU 开发默认使用 NEMU-only profile，不再把集成 profile 当成普通 NEMU 开发入口：

- 快速 NEMU 开发合同：`scripts/agent-e2e.sh --profile nemu-dev`
- NEMU focused gate：`scripts/agent-e2e.sh --profile nemu-dev-gate`
- NEMU full Ubuntu 22.04 gate：`AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate`
- NEMU full soak：`AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-soak`
- NEMU full Ubuntu 性能 profile：`AGENT_E2E_NEMU_PROFILE_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-profile`

`nemu-dev*` 通过 `nemu-ubuntu-focused` 进入 `software-flow`、`nemu-ubuntu-static` 和 `nemu-ubuntu-slice-contract`，不得包含 `rv64-linux` 或 `npc-*` 节点。`nemu-ubuntu`、`nemu-ubuntu-gate`、`nemu-ubuntu-full-gate`、`nemu-ubuntu-full-soak` 保留为 NEMU Ubuntu 兼容入口；跨 NEMU/NPC/RV64 Linux 集成验证使用显式 `nemu-ubuntu-integrated` profile。

## 软件流程

NEMU 是用 C/Python/Shell/Make/Kconfig 写出的硬件和系统模型。涉及 NEMU C 侧、Linux tools、guest check、virtio/device model、QMP/GDB 或 host harness 的任务必须使用 `software-flow` 的 `hardware-aware-software-loop`：

`scope-contract -> hardware-semantic-contract -> design-plan -> implement -> software-focused-test -> system-or-hardware-gate -> review-record`

完成判定不能只看构建通过或外层退出码；必须结合 guest marker、BAD TRAP/GOOD TRAP、`__NEMU_CHECK_FAIL__` 负向扫描、task-run evidence 和 memory 更新。

## 当前边界

- NEMU-only 环境问题要在 `nemu-dev*` 或 focused make 中修，不从 `.github/db-backup` 绕答案。
- NPC/RTL/systemd 集成问题不应混入 NEMU-only 默认入口；需要跨栈时显式跑 `nemu-ubuntu-integrated` profile。
- full Ubuntu 22.04 的 hostless APT lifecycle 已闭合到 signed repo、upgrade、remove/purge 与 dpkg ownership；当前 blocker 转为 Python/PyLong transient corruption，按 known-issues [76] 继续定位，不能放松 Python/CNF hard gate。
- 性能分析默认使用 `nemu-ubuntu-profile`，它会打开 `NEMU_PROFILE=1`、full rootfs、大指令预算和性能 fast path，并关闭 guest 功能测试脚本；2026-06-15 的 1B instruction 证据显示串口 flush 仅约 0.01%，当前主要瓶颈在单线程解释器热路径。
- 诊断 NEMU interpreter/fast-path 时优先使用 runtime 开关而不是改 profile：`NEMU_INTERPRETER_BASIC_BLOCK=0`、`NEMU_INTERPRETER_WIDE_IFETCH=0`、`NEMU_INTERPRETER_DECODE_CACHE=0`、`NEMU_VADDR_HOST_FAST=0`、`NEMU_RISCV_MMU_TLB=0`、`NEMU_VIRTIO_BLK_SYNC=1`。慢速 full gate 应保留 `systemd.default_timeout_start_sec=300s` 和较大的 serial upload chunk 证据。
