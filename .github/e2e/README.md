# Agent E2E Profiles

## 场景隔离入口

- `nemu-dev`: NEMU-only static/slice/software-flow contract。
- `nemu-dev-gate`: NEMU-only focused gate。
- `nemu-dev-full-gate`: NEMU-only full Ubuntu 22.04 gate。
- `nemu-dev-full-soak`: NEMU-only full soak gate。
- `npc-dev`: NPC-only sim/single/soc/rv64 contracts。

`nemu-ubuntu`、`nemu-ubuntu-gate`、`nemu-ubuntu-full-gate`、`nemu-ubuntu-full-soak` 保留为 NEMU Ubuntu 兼容入口，不作为普通 NEMU 开发默认入口；跨 NEMU/NPC/RV64 Linux 组合验证使用 `nemu-ubuntu-integrated`。

`scripts/agent-e2e.sh` 在展开 profile 后会立即执行运行时边界检查：`nemu-dev*` 只允许 `nemu`/`software-flow` 节点闭包，若拉入 `npc-*`、`rv64-linux` 或 NPC owner/function 会失败；`npc-dev` 只允许 `npc`/`software-flow` 节点闭包，若拉入 NEMU Ubuntu 节点会失败。真实 dispatch 还会做 active scenario runtime isolation：默认 `AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=warn`，NEMU-only 入口发现活跃 NPC e2e/task-run/`ARCH=riscv64-npc`/`npc-systemd`/UART 慢测进程时只告警并继续，NPC-only 反向检查活跃 NEMU Ubuntu/PyLong/profile 进程也只告警并继续；需要单场景复现时显式设置 `AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=strict` 才会失败，设置为 `off` 可完全跳过检查。`nemu-ubuntu-integrated` 不套用 NEMU-only/NPC-only 隔离策略，以保留跨模块 bring-up 流程。

## 常用命令

```bash
scripts/agent-e2e.sh --profile nemu-dev
AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate
scripts/agent-e2e.sh --profile npc-dev
scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate
```

## 执行卫生

不要并发启动多个 `wsl.exe` 跑工程命令；遇到 `Wsl/Service/E_UNEXPECTED`、stale `wsl.exe` 客户端，或 NEMU/NPC 场景互相拖慢，先确认 WSL 状态和 active scenario runtime isolation。日常 NEMU/NPC 并行开发保持默认 `warn`，严谨复现实验再切到 `strict`。需要加载开发环境时使用 `scripts/agent-run.sh`。外层工具控制符可能拆坏命令，检索多个词使用 `rg -e`。PowerShell 包裹 `wsl.exe -- bash -lc '...'` 时不要裸用 Bash `$var`，否则会先被 PowerShell 展开；一次性命令优先写字面路径或用脚本文件承载复杂逻辑。

Windows `Start-Process wsl.exe` 启动长门时，`-- bash -lc "..."` 必须作为单个 argument string 传入。NEMU slow diagnostic 环境变量关闭 interpreter/fast-path 时，full focused gate 应保留自动 bootargs timeout 与 `NEMU_SYSTEMD_INPUT_CHUNK_BYTES=512` 证据，避免 serial 上传耗时被误判成 guest/NEMU 根因。

## 软件流程

`nemu-dev`、`nemu-ubuntu-focused` 和旧集成 `nemu-ubuntu` 都必须消费 `software-flow`。NEMU 这类软件实现硬件或系统语义的任务使用 `hardware-aware-software-loop`，再由对应系统 gate 证明 guest/设备/ISA 可见行为。

## NEMU Full Ubuntu 22.04 Runtime

`nemu-dev-full-gate` 是普通 NEMU-only full Ubuntu 开发的默认长门禁。当前 full gate 的 server/userland 完成钩子包括 hostless signed APT、machine-id committed、`systemd-hostnamed` + `hostnamectl status`、`systemd-sysusers`、`systemd-tmpfiles --create`、cron/rsyslog workload、journald active、`systemd-cat` 写入、`journalctl -t` 读回、`systemctl --root=/ enable/is-enabled/disable` + runtime start 的 unit 管理面，以及默认 hard 的 Python/CNF/stdlib gate（`NEMU_SYSTEMD_PYTHON_CNF_DIAG_HARD=1`，覆盖 `textwrap.py`/`textwrap.pyc`/`lsb_release` hash、`re,textwrap,optparse` import loop、`lsb_release -a` retry、`PYTHONPYCACHEPREFIX` retry、Python stdlib stress、`datetime`/`sqlite3`/`CommandNotFound`/`cnf-update-db`）。检查 `systemd-cat` 时不要假设 `/bin/echo` 是 rootfs 外部命令；使用已由 rootfs readiness 保证的 `/bin/sh -c 'printf ...'` 作为命令载体。hostless APT 的私有 repo gate 会临时写入 `/etc/apt/apt.conf.d/99nemu-hostless-clear-hooks`，用 `#clear APT::Update::Post-Invoke-Success;` 和 `#clear DPkg::Post-Invoke;` 隔离全局 hook；`Dir::Etc::parts=-` 只是记录/辅助参数，不足以阻止已加载的 `50command-not-found`。不要把 hostless APT clear-hooks PASS 写成 command-not-found 根因已修，也不要把一次 Python/CNF PASS 写成 transient 根因已定位。当前 Python/PyLong blocker 的已排除项包括 virtio-blk async、Sv39 TLB、decode cache 和 interpreter basic-block batching；`NEMU_VADDR_HOST_FAST=0` 的 systemctl-lite run 已能复现 datetime/PyLong transient，因此 host-fast 不是必要条件或不是唯一触发条件。后续 focused/staged reproducer 必须保留 CPython `PyLongObject` sentinel，输出 `PYLONG_LAYOUT_AVAILABLE`、`PYLONG_*_OB_SIZE`、`PYLONG_*_OB_DIGIT*` 和 mismatch/error marker，用对象头/digit 证据继续切分 wide ifetch、guest memory 与 Python object state。
