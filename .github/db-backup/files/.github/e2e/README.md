# Agent E2E Profiles

## 场景隔离入口

- `nemu-dev`: NEMU-only static/slice/software-flow contract。
- `nemu-dev-gate`: NEMU-only focused gate。
- `nemu-dev-full-gate`: NEMU-only full Ubuntu 22.04 gate。
- `nemu-dev-full-soak`: NEMU-only full soak gate。
- `npc-dev`: NPC-only sim/single/soc/rv64 contracts。

旧 `nemu-ubuntu`、`nemu-ubuntu-gate`、`nemu-ubuntu-full-gate`、`nemu-ubuntu-full-soak` 保留为集成 profile，继续覆盖 NEMU/NPC/RV64 Linux 组合，不作为普通 NEMU 开发默认入口。

## 常用命令

```bash
scripts/agent-e2e.sh --profile nemu-dev
AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate
scripts/agent-e2e.sh --profile npc-dev
scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate
```

## 执行卫生

不要并发启动多个 `wsl.exe` 跑工程命令；遇到 `Wsl/Service/E_UNEXPECTED` 先确认 WSL 状态，再串行重试。需要加载开发环境时使用 `scripts/agent-run.sh`。外层工具控制符可能拆坏命令，检索多个词使用 `rg -e`。

## 软件流程

`nemu-dev`、`nemu-ubuntu-focused` 和旧集成 `nemu-ubuntu` 都必须消费 `software-flow`。NEMU 这类软件实现硬件或系统语义的任务使用 `hardware-aware-software-loop`，再由对应系统 gate 证明 guest/设备/ISA 可见行为。
