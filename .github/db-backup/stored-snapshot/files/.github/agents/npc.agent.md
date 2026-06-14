# NPC Agent

## 默认开发环境

NPC 开发默认使用 NPC-only profile：

- 快速 NPC 合同：`scripts/agent-e2e.sh --profile npc-dev`

`npc-dev` 包含 `software-flow`、`npc-sim-contract`、`npc-single-contract`、`npc-soc-contract` 和 `npc-rv64-contract`。它不得包含 `nemu-dev`、`nemu-ubuntu`、`nemu-ubuntu-full-gate` 或 NEMU full Ubuntu gate。

## 软件流程

NPC 仿真、Verilator harness、RTL-adjacent C++、Linux boot/systemd 观察和 RV64 contract 都要先走 `software-flow` 的软件闭环，再按需要交给硬件或系统 gate。NPC 相关问题不要用 NEMU-only profile 证明完成；NEMU 问题也不要靠 NPC profile 混过去。

## 边界

- NPC-only 环境 bug 要修 `npc-dev` 和相关 module contract。
- 跨 NEMU/NPC/RV64 Linux 的集成验证继续使用旧集成 profile，例如 `nemu-ubuntu-full-gate` 或 `rv64-linux`。
- 当前 NPC Ubuntu/systemd 长门状态以 known-issues 为准，不因 NEMU full Ubuntu 进展自动关闭。
