# Agent E2E Workflow

## 场景隔离入口

- NEMU-only 开发：`scripts/agent-e2e.sh --profile nemu-dev`
- NEMU-only full gate：`AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate`
- NPC-only 开发：`scripts/agent-e2e.sh --profile npc-dev`
- 跨栈集成入口：`scripts/agent-e2e.sh --profile nemu-ubuntu-integrated`

`nemu-dev*` 和 `npc-dev` 是场景隔离入口；`nemu-ubuntu*` 保留 NEMU Ubuntu 兼容门禁，`nemu-ubuntu-integrated` 保留跨 NEMU/NPC/RV64 Linux 集成功能，不能为了隔离而删除集成 profile。NEMU 软件/系统模型任务使用 `software-flow` 的 `hardware-aware-software-loop`，再叠加 `nemu-dev` 或明确的 `nemu-ubuntu`/`nemu-ubuntu-integrated` gate。

运行时边界由 `scripts/agent-e2e.sh` 强制执行：`nemu-dev*` 展开后只能包含 `nemu` 与 `software-flow` 节点，不能拉入 `npc-*`、`rv64-linux` 或 NPC owner/function；`npc-dev` 展开后只能包含 `npc` 与 `software-flow` 节点，不能拉入 NEMU Ubuntu 节点。`--validate-profile`、`--validate-all-profiles` 和真实 dispatch 共用这条检查。

## 执行卫生

- 工程命令通过 WSL single-flight 执行，避免并发启动多个 `wsl.exe`。遇到 `Wsl/Service/E_UNEXPECTED` 先做 WSL 健康检查并串行重试。
- 真实构建/e2e 优先使用 `scripts/agent-run.sh`，让非交互环境加载 `scripts/agent-env.sh`。
- 外层工具控制符会污染命令字符串。多模式搜索优先使用 `rg -e foo -e bar`，不要依赖带 `|` 的单个正则穿过外层 shell。
- PowerShell 包裹 `wsl.exe -- bash -lc '...'` 时，不要在一次性命令中裸用 Bash `$var`；`$run`、`$p`、`$args` 等会被 PowerShell 先展开。优先写字面路径，或把复杂逻辑放进仓库脚本后调用。
- Windows `Start-Process wsl.exe` 传递复杂 Bash 命令时，必须把 `-- bash -lc "..."` 作为单个 argument string 保持完整；否则只会执行前半段命令，造成假 PASS/假退出。
- NEMU 慢速诊断 gate 若设置 `NEMU_INTERPRETER_BASIC_BLOCK=0`、`NEMU_INTERPRETER_WIDE_IFETCH=0`、`NEMU_INTERPRETER_DECODE_CACHE=0`、`NEMU_VADDR_HOST_FAST=0` 或 `NEMU_RISCV_MMU_TLB=0`，e2e 应自动提高 systemd start timeout，并使用较大的 serial input chunk，避免把上传过慢误判为 guest 行为。

## 完成判定

完成后必须查看 task-run report、profile resolve、关键 evidence、FAIL marker 和 memory 更新。不能只看外层退出码，也不能从 `.github/db-backup` 绕开当前 DB-first recall 问题。

NEMU-only full Ubuntu 22.04 开发使用 `nemu-dev-full-gate`，不要误走 NPC 或旧集成 profile。full userland runtime 的关键 evidence 需要看到 machine-id committed、`systemd-hostnamed` active、`hostnamectl status` 返回 `ysyx-ubuntu2204`、`systemd-sysusers` 创建用户/组、`systemd-tmpfiles --create`、journald active、`systemd-cat` 写入、`journalctl -t` 读回、`systemctl --root=/ enable/is-enabled/disable` 与 runtime unit start、默认 hard 的 Python/CNF/stdlib gate（`NEMU_SYSTEMD_PYTHON_CNF_DIAG_HARD=1`、`textwrap.py`/`textwrap.pyc`/`lsb_release` hash、`re,textwrap,optparse` import loop、`lsb_release -a` retry、`PYTHONPYCACHEPREFIX` retry、Python stdlib stress、`datetime`/`sqlite3`/`CommandNotFound`/`cnf-update-db`）、hostless signed APT 和 guest rc=0；涉及 `systemd-cat` 命令模式时使用 `/bin/sh -c 'printf ...'`，不要假设 `/bin/echo` 一定存在。hostless APT 的私有 repo gate 应保留 `99nemu-hostless-clear-hooks` 与 `#clear APT::Update::Post-Invoke-Success; #clear DPkg::Post-Invoke;` 证据，避免全局 hook 污染私有 repo 测试；`Dir::Etc::parts=-` 单独不足以阻止已加载 hook。Python/CNF hard gate PASS 是当前功能验收证据，但不要写成偶发 `lsb_release`/`textwrap` 问题根因已永久定位。若看到 `bit_length=276701161105643274181` 或 `ValueError: Exceeds the limit (4300)`，按 PyLong/int object corruption blocker 处理，并记录本轮排除矩阵：virtio-blk async、Sv39 TLB、decode cache、interpreter basic-block batching 已不足以解释该失败；wide ifetch/host fast path 仍需更短 reproducer 或更快 slow-diagnostic gate 继续切分。
