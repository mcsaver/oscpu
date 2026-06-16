# Task Report

## 基本信息

- `task_id`: `2026-06-07-nemu-ubuntu-log-gap-fixes`
- `task_slug`: `nemu-ubuntu-log-gap-fixes`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-07 13:15 CST`
- `updated_at`: `2026-06-07 13:31 CST`

## 任务目标

- `source_request`: 用户要求修复启动日志中的缺口。
- `goal`: 消除 NEMU Ubuntu rootfs 启动日志中的 jobserver、autofs4 alias 和 cgroup-BPF firewalling 三类非致命 warning，同时保持 rootfs 启动链路可用。
- `scope`: `Makefile`、`Linux/Makefile`、`Linux/scripts/build-linux.sh`，以及 NEMU Ubuntu rootfs 启动日志验证。

## 选图说明

- `selected_template`: `rv64-ubuntu-rootfs-loop`
- `why_this_graph`: 缺口来自 `make ARCH=riscv64-nemu run` 的真实 Ubuntu rootfs 启动日志，必须以 Linux Image 配置和 NEMU 启动日志验证收口。
- `dynamic_nodes_added`: `jobserver-root-cause`、`kernel-config-gap-fix`、`console-warning-scan`
- `why_dynamic_nodes_were_needed`: 原始 warning 分别来自构建递归 make、kernel autofs 能力和 systemd cgroup-BPF 探测，不属于同一代码层。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `log-triage` | codex | completed | 用户粘贴启动日志 | 确认无 panic/Oops/Bad Trap，定位三类 warning | 原日志到 `Reached target Login Prompts` |
| `jobserver-root-cause` | codex | completed | `Linux/Makefile`、根 `Makefile`、NEMU build 输出 | 递归 `$(MAKE)` 入口加 `+`，包含 `flock ... .git_commit` | `make -C Linux ARCH=riscv64-nemu sim` 无 `jobserver unavailable` |
| `kernel-config-gap-fix` | codex | completed | `Linux/scripts/build-linux.sh`、kernel `.config` | 启用 `CONFIG_AUTOFS_FS`、`CONFIG_BPF_SYSCALL`、`CONFIG_CGROUP_BPF` | `grep` 显示三项为 `y`，`MODULES/NETFILTER` 仍关闭 |
| `linux-image-build` | codex | completed | 更新后的 build script | Linux Image 重新构建 | `bash Linux/scripts/build-linux.sh` PASS |
| `console-warning-scan` | codex | completed | 新启动 console log | 三类 warning 与致命模式均不存在 | `console.log` 扫描全部 `ABSENT`，并到 root shell |

## 关键产物

- `artifacts`: `Makefile`、`Linux/Makefile`、`Linux/scripts/build-linux.sh`
- `logs_or_traces`: `Linux/env/logs/linux-front/riscv64-nemu-ubuntu-rootfs/console.log`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`

## 验证证据

- `bash -n Linux/scripts/build-linux.sh Linux/scripts/check-nemu-systemd-guest.sh Linux/scripts/check-nemu-performance-config.sh` PASS。
- `bash Linux/scripts/build-linux.sh` PASS，生成 kernel `#17 Sun Jun 7 13:21:00 CST 2026`。
- `Linux/env/src/linux/.config`:
  - `CONFIG_BPF_SYSCALL=y`
  - `CONFIG_CGROUP_BPF=y`
  - `CONFIG_AUTOFS_FS=y`
  - `# CONFIG_MODULES is not set`
  - `# CONFIG_NETFILTER is not set`
- `make -C Linux ARCH=riscv64-nemu sim` PASS，输出中无 `jobserver unavailable`。
- `timeout 360s make -C Linux ARCH=riscv64-nemu run` 到 `Reached target Login Prompts`、`login: root (automatic login)` 和 `root@ysyx-ubuntu2204:~#` 后由 timeout 终止。
- 新 console 扫描确认以下模式均不存在：
  - `jobserver unavailable`
  - `Failed to look up module alias.*autofs4`
  - `does not support BPF/cgroup firewalling`
  - `Kernel panic`
  - `Oops`
  - `Call Trace`
  - `HIT BAD TRAP`
  - `EXT4-fs error`
  - `I/O error`

## 边界

本轮只修复启动日志中的三类缺口和对应 kernel 能力探测，不声明 QEMU 级完整 VM、virtio-net、SMP、多队列/异步 block、snapshot/GDB/monitor、完整 TB cache/code-page invalidation 或 DBT/JIT 完成。
