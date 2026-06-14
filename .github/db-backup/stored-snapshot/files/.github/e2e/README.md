# Agent E2E Profiles

## 场景隔离入口

- `nemu-dev`: NEMU-only static/slice/software-flow contract。
- `nemu-dev-gate`: NEMU-only focused gate。
- `nemu-dev-full-gate`: NEMU-only full Ubuntu 22.04 gate。
- `nemu-dev-full-soak`: NEMU-only full soak gate。
- `npc-dev`: NPC-only sim/single/soc/rv64 contracts。

旧 `nemu-ubuntu`、`nemu-ubuntu-gate`、`nemu-ubuntu-full-gate`、`nemu-ubuntu-full-soak` 保留为集成 profile，继续覆盖 NEMU/NPC/RV64 Linux 组合，不作为普通 NEMU 开发默认入口。

`scripts/agent-e2e.sh` 在展开 profile 后会立即执行运行时边界检查：`nemu-dev*` 只允许 `nemu`/`software-flow` 节点闭包，若拉入 `npc-*`、`rv64-linux` 或 NPC owner/function 会失败；`npc-dev` 只允许 `npc`/`software-flow` 节点闭包，若拉入 NEMU Ubuntu 节点会失败。旧 `nemu-ubuntu*` 集成 profile 不套用该隔离策略，以保留跨模块 bring-up 流程。

## 常用命令

```bash
scripts/agent-e2e.sh --profile nemu-dev
AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate
scripts/agent-e2e.sh --profile npc-dev
scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate
```

## 执行卫生

不要并发启动多个 `wsl.exe` 跑工程命令；遇到 `Wsl/Service/E_UNEXPECTED` 或 stale `wsl.exe` 客户端，先确认 WSL 状态，再串行重试。需要加载开发环境时使用 `scripts/agent-run.sh`。外层工具控制符可能拆坏命令，检索多个词使用 `rg -e`。PowerShell 包裹 `wsl.exe -- bash -lc '...'` 时不要裸用 Bash `$var`，否则会先被 PowerShell 展开；一次性命令优先写字面路径或用脚本文件承载复杂逻辑。

## 软件流程

`nemu-dev`、`nemu-ubuntu-focused` 和旧集成 `nemu-ubuntu` 都必须消费 `software-flow`。NEMU 这类软件实现硬件或系统语义的任务使用 `hardware-aware-software-loop`，再由对应系统 gate 证明 guest/设备/ISA 可见行为。

## NEMU Full Ubuntu 22.04 Runtime

`nemu-dev-full-gate` 是普通 NEMU-only full Ubuntu 开发的默认长门禁。当前 full gate 的 server/userland 完成钩子包括 hostless signed APT、machine-id committed、`systemd-hostnamed` + `hostnamectl status`、`systemd-sysusers`、`systemd-tmpfiles --create`、cron/rsyslog workload、journald active、`systemd-cat` 写入、`journalctl -t` 读回、`systemctl --root=/ enable/is-enabled/disable` + runtime start 的 unit 管理面，以及默认 hard 的 Python/CNF/stdlib gate（`NEMU_SYSTEMD_PYTHON_CNF_DIAG_HARD=1`，覆盖 `textwrap.py`/`textwrap.pyc`/`lsb_release` hash、`re,textwrap,optparse` import loop、`lsb_release -a` retry、`PYTHONPYCACHEPREFIX` retry、Python stdlib stress、`datetime`/`sqlite3`/`CommandNotFound`/`cnf-update-db`）。检查 `systemd-cat` 时不要假设 `/bin/echo` 是 rootfs 外部命令；使用已由 rootfs readiness 保证的 `/bin/sh -c 'printf ...'` 作为命令载体。hostless APT 的私有 repo gate 会临时写入 `/etc/apt/apt.conf.d/99nemu-hostless-clear-hooks`，用 `#clear APT::Update::Post-Invoke-Success;` 和 `#clear DPkg::Post-Invoke;` 隔离全局 hook；`Dir::Etc::parts=-` 只是记录/辅助参数，不足以阻止已加载的 `50command-not-found`。不要把 hostless APT clear-hooks PASS 写成 command-not-found 根因已修，也不要把一次 Python/CNF PASS 写成 transient 根因已定位。
