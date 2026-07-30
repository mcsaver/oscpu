# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: rv64-systemd-contract
- `terms`: npc systemd guest
- `focus_scope`: non-history
- `token_estimate`: 1718 / 2400

## Profile Suggestions
- `rv64-systemd-contract` score=13 matched=guest, npc, requested-profile, systemd command=`scripts/agent-e2e.sh --profile rv64-systemd-contract`
- `npc` score=8 matched=guest, npc, systemd command=`scripts/agent-e2e.sh --profile npc`
- `rv64-linux` score=5 matched=guest, npc, systemd command=`scripts/agent-e2e.sh --profile rv64-linux`
- `nemu` score=3 matched=guest, npc, systemd command=`scripts/agent-e2e.sh --profile nemu`
- `npc-dev` score=3 matched=npc command=`scripts/agent-e2e.sh --profile npc-dev`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile rv64-systemd-contract`

## Missing Paths
- `.github/e2e/modules/rv64-systemd-contract.md`
- `.github/agents/rv64-systemd-contract.agent.md`
- `.github/memory/modules/rv64-systemd-contract.md`

## Chunks

### .github/AGENTS.md#chunk-0001

- `kind`: agent-rule
- `lines`: 1-15
- `tokens`: 328
- `heading`: AGENTS.md — YSYX 工作区 Agent 通用工作流规范
- `summary`: > 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent / > （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等） / > 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。 / > / > 与本文件协作的入口文件分两类： / > 根...

# AGENTS.md — YSYX 工作区 Agent 通用工作流规范

> 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent
> （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等）
> 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。
>
> 与本文件协作的入口文件分两类：
> 根目录 `AGENTS.md` / 其他兼容入口文件是兼容 shim，保留最小可执行契约并回链本文件；
> `.github/copilot-instructions.md` 不是薄指针，而是 GitHub Copilot 专属工程级补充规则。
> 多份文件出现重叠时，以本文件作为跨 agent 通用基线；Copilot 的额外构建、调试与记录细则再叠加读取 `copilot-instructions.md`。
>
> 当前阶段的目标是“工程规则自动发现与会话恢复”，不是“插件式 UI 扩展”。因此本仓库优先补齐兼容 shim，不主动引入 `.codex-plugin/` 或 `.agents/plugins/marketplace.json`。

---

### .github/e2e/profiles/rv64-systemd-contract.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-1
- `tokens`: 76
- `heading`: rv64-systemd-contract.tsv
- `summary`: npc-rv64-systemd-guest-check-contract|npc|e2e_npc_rv64_systemd_guest_check_contract|npc|RV64 systemd guest checker + terminal transaction + isolated rootfs + debug-valid diagnostic contract|Checker 正反例、真实 power-down/syscon/system-reset 事务、rootfs 工作副本与 debug...

npc-rv64-systemd-guest-check-contract|npc|e2e_npc_rv64_systemd_guest_check_contract|npc|RV64 systemd guest checker + terminal transaction + isolated rootfs + debug-valid diagnostic contract|Checker 正反例、真实 power-down/syscon/system-reset 事务、rootfs 工作副本与 debug-valid 合同 PASS

### .github/memory/modules/nemu.md#chunk-0006

- `kind`: memory-module
- `lines`: 22-24
- `tokens`: 1254
- `heading`: 当前状态
- `summary`: - 2026-07-01: NEMU RV64 system 设备配置已改为以 `Linux/platform/npc-rv64.yml`/generated DTB 为准，并接入 ACT4/riscv-tests 风格 `tohost` 退出监控。root cause：旧 `riscv64-npc_defconfig`/Kconfig 仍沿用 AM/legacy MMIO 默认值，`HAS_DISK=y` 时 `DISK_CTL_MMIO=0xa0000300` 与 `SERIAL_MMIO=0xa0000...

- 2026-07-01: NEMU RV64 system 设备配置已改为以 `Linux/platform/npc-rv64.yml`/generated DTB 为准，并接入 ACT4/riscv-tests 风格 `tohost` 退出监控。root cause：旧 `riscv64-npc_defconfig`/Kconfig 仍沿用 AM/legacy MMIO 默认值，`HAS_DISK=y` 时 `DISK_CTL_MMIO=0xa0000300` 与 `SERIAL_MMIO=0xa00003f8` 发生区间重叠，且整体设备图与 Linux `uart0=0x10000000`、`virtio_blk=0x10001000`、`virtio_rng=0x10002000`、`goldfish_rtc=0x10003000`、`virtio_net=0x10004000`、`reset_syscon=0x00100000` 不一致。修复：`nemu/src/device/Kconfig` 在 RV64 system native 下默认使用 Linux UART/blk 地址并关闭 legacy timer/keyboard/VGA/audio；`nemu/configs/riscv64-npc_defconfig` 显式采用 1GiB PMEM、PMEM malloc、A/M/B/C/F/D、Linux UART/virtio-blk/rng/net/rtc/syscon 地址图；`Linux/scripts/check-nemu-performance-config.sh` 将这些地址和 legacy 设备关闭纳入门禁。`--tohost=ADDR` 默认关闭，开启后在 paddr PMEM/DMA 写和 vaddr host-fast 写路径检测非零 tohost，值 `1` 判 PASS，其他非零按 ACT4/riscv-tests 编码解码为失败并结束 NEMU；`machine-info` 输出 runtime tohost 状态。验证：`make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j2` PASS；`NEMU_CONFIG=... NEMU_AUTOCONF=... bash Linux/scripts/check-nemu-performance-config.sh` PASS；`make -C am-kernels/arch-test smoke` PASS，日志确认 PMEM `[0x80000000, 0xbfffffff]` 与 Linux MMIO 地址图，且 `TOHOST PASS`/`HIT GOOD TRAP`；`make -C am-kernels/arch-test run-nemu ACT4_SUITES=rv64i/I ACT4_LIMIT=3` PASS。
- 2026-06-25: NEMU full Ubuntu 22.04 full gate 已从 `systemd-logind` root ttyS0 serial session hard gate 推进到 root 用户 manager/session-bus hard gate，并修复早于 logind 的 serial autologin 时序问题。root cause：NEMU autologin drop-in 只等 `plymouth-quit-wait/getty-pre/rc-local`，root shell 可在 `systemd-logind.service` 尚未完整接管前进入，导致 `XDG_SESSION_ID` 缺失、`loginctl` 找不到当前 root session、`user@0.service`/`session-c1.scope` 建立超时；首次 login timeout 后遗留的 failed `session-*.scope` 又会让 `systemd --failed` gate 误判。`Linux/scripts/build-ubuntu-rootfs.sh` 现在让 NEMU `serial-getty@ttyS0.service.d/autologin.conf` 生成 `Wants=systemd-logind.service` 与 `After=systemd-logind.service systemd-user-sessions.service plymouth-quit-wait.service getty-pre.target rc-local.service`，NPC early login 分支保持旧的早登录 ordering。`Linux/scripts/check-ubuntu-rootfs.sh` 新增 NEMU serial-getty logind ordering readiness 检查；`Linux/scripts/check-nemu-systemd-guest.sh` 在 `systemd-running` 前只 reset stale failed `session-*.scope`，并新增 root logind user manager/session bus gate：要求 `XDG_RUNTIME_DIR=/run/user/0`、`user@0.service` active、runtime dir 为 `root:root:700`、`/run/user/0/systemd/private` 与 `/run/user/0/bus` 为 socket、`loginctl show-user root` 的 Sessions 含当前 ttyS0 root session、`busctl --user` 可见 `org.freedesktop.DBus` 和 `org.freedesktop.systemd1`，且 root `systemctl --user` 启动的 `nemu-full-root-user-manager-session.service` 输出 `root-user-manager-ok`、cgroup 位于 `/user.slice/user-0.slice/user@0.service/`。`scripts/e2e/modules/nemu.sh` 和 `.github/e2e/modules/nemu.md` 已固化 source/rootfs/focused hard markers。验证：`bash -n` PASS；`git diff --check` PASS；`make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-full` 重建 full rootfs 后 PASS；静态 `.github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/` PASS；真实 `.github/task-runs/2026-06-25-nemu-full-root-user-manager-session-full-gate-v3/` 的 `nemu-dev-full-gate` 4 节点 PASS。full console 行 470 为 stale `session-c1.scope` reset rc=0，行 773-827 为 root user manager/session bus 证据，其中 `XDG_RUNTIME_DIR=/run/user/0`、`user@0.service:active`、runtime dir `root:root:700:/run/user/0`、private/bus socket=1、`loginctl show-user root` 为 Name=root/UID=0/State=active/RuntimePath=/run/user/0/Sessions=c2 且 session seen=1、busctl rc=0/DBus=1/systemd=1、user unit reload/start rc=0、service active/output/cgroup ok，行 827 为 `full-userland-logind-root-user-manager-session`；行 13733 为 guest rc=0，行 13838 为 GOOD TRAP。负向扫描 console 无 `__NEMU_CHECK_FAIL__`/BAD TRAP/panic/Oops/SIGILL/Illegal instruction/unhandled signal/I/O error/budget stop，残留进程无真实 NEMU/e2e/check。边界：该 gate 证明 root serial login 后 logind/PAM/systemd-user/root session bus 链路闭合；不代表 GNOME/桌面 session、display manager、Wayland/Xorg、DRM/GPU、输入 seat、外部网络/mirror、长期性能签核、SMP/PCI/snapshot、QEMU 等价或完整 Ubuntu 2204 目标全部闭合。

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-2
- `tokens`: 8
- `heading`: YSYX 项目状态总览
- `summary`: YSYX 项目状态总览

# YSYX 项目状态总览

### .github/memory/known-issues.md#chunk-0001

- `kind`: memory
- `lines`: 1-4
- `tokens`: 35
- `heading`: 已知问题与调试历史
- `summary`: > 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

### .github/e2e/README.md#chunk-0001

- `kind`: markdown
- `lines`: 1-2
- `tokens`: 6
- `heading`: Agent E2E Profiles
- `summary`: Agent E2E Profiles

# Agent E2E Profiles
