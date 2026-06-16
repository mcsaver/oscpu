# Dispatch Log

## 基本信息

- `task_id`: `2026-06-07-nemu-ubuntu-log-gap-fixes`
- `task_slug`: `nemu-ubuntu-log-gap-fixes`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `log_policy`: `append-only`

---

### [2026-06-07 13:15] `log-triage` - `completed`

- `owner_agent`: codex
- `trigger`: 用户询问启动日志中是否有 bug，并要求修复缺口。
- `depends_on`: 用户粘贴日志。
- `inputs`: `C:\Users\17279\.codex\attachments\a90df73f-63fd-478b-b973-0f97b08515c2\pasted-text.txt`
- `action`: 扫描 panic/Oops/Bad Trap/EXT4/I/O 与 warning/fail 模式。
- `outputs`: 确认启动可到 login prompt，主要缺口为 jobserver、autofs4 alias、cgroup-BPF firewalling。
- `evidence`: 原日志末尾 `Started Serial Getty on ttyS0`、`Reached target Login Prompts`。
- `next_step`: 定位 Makefile 和 kernel config 根因。

### [2026-06-07 13:18] `jobserver-root-cause` - `completed`

- `owner_agent`: codex
- `trigger`: `make[2]: warning: jobserver unavailable`
- `depends_on`: `log-triage`
- `inputs`: `Linux/Makefile`、根目录 `Makefile`、NEMU build 输出。
- `action`: 给 Linux 递归 `$(MAKE)` 入口加 `+`，并给根 `Makefile::git_commit` 中 `flock ... $(MAKE)` 加 `+`。
- `outputs`: jobserver token 可传入 NEMU build 内部 tracer 子 make。
- `evidence`: `make -C Linux ARCH=riscv64-nemu sim` 输出无 `jobserver unavailable`。
- `next_step`: 修 kernel autofs/BPF 配置。

### [2026-06-07 13:21] `kernel-config-gap-fix` - `completed`

- `owner_agent`: codex
- `trigger`: systemd autofs4 alias 和 cgroup-BPF firewalling warning。
- `depends_on`: `log-triage`
- `inputs`: `Linux/scripts/build-linux.sh`、`Linux/env/src/linux/.config`
- `action`: 启用 `CONFIG_AUTOFS_FS`、`CONFIG_BPF_SYSCALL`、`CONFIG_CGROUP_BPF`；保留 `CONFIG_MODULES` 和 `CONFIG_NETFILTER` 关闭。
- `outputs`: Ubuntu systemd 所需的最小 autofs 与 cgroup-BPF 能力成为内建 kernel 功能。
- `evidence`: `.config` 中三项为 `y`，`# CONFIG_MODULES is not set`、`# CONFIG_NETFILTER is not set`。
- `next_step`: 重建 kernel 并跑真实启动。

### [2026-06-07 13:30] `console-warning-scan` - `completed`

- `owner_agent`: codex
- `trigger`: 需要确认修复不是静态配置假象。
- `depends_on`: `kernel-config-gap-fix`
- `inputs`: 新 Linux Image、NEMU rootfs 启动入口。
- `action`: `timeout 360s make -C Linux ARCH=riscv64-nemu run`，随后扫描 console log。
- `outputs`: 新内核到 login prompt 和自动 root shell；原三类 warning 和致命模式均不存在。
- `evidence`: `Linux/env/logs/linux-front/riscv64-nemu-ubuntu-rootfs/console.log` 含 `Reached target Login Prompts`、`login: root (automatic login)`、`root@ysyx-ubuntu2204:~#`；扫描结果全部 `ABSENT`。
- `next_step`: 记录 memory，保留后续 QEMU 级 VM 路线边界。
