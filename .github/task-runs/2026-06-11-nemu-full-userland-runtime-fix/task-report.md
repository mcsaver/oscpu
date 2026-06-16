# Task Report

## 基本信息

- `task_id`: 2026-06-11-nemu-full-userland-runtime-fix
- `task_slug`: nemu-full-userland-runtime-fix
- `graph_template`: regression-debug-loop
- `status`: completed
- `owner`: nemu + rv64-linux + agent-system

## 任务目标

- `source_request`: 继续优化 NEMU 启动完整规模 Ubuntu 22.04，并把 e2e 完成判据闭环。
- `goal`: 将 full rootfs 从静态包/路径存在推进到 guest 内 server-like 用户态 runtime gate。
- `scope`: full Ubuntu rootfs 的 chrootless maintainer-defaults、readiness、guest runtime 和 e2e contract；不声明桌面 Ubuntu、外网、TAP/NAT、SMP/PCI/snapshot 或长期 soak。

## 失败复现

- `nemu-full-userland-real-run`: 首轮真实 full profile FAIL，`sshd -T` 报 `/etc/ssh/sshd_config` 缺失，`rsyslogd -N1` 报 `syslog` 用户缺失，`rsyslog.service` dependency fail。
- `full-rootfs-check-before-runtime-defaults.log`: 新 readiness gate 对旧 full ext4 FAIL，确认缺 OpenSSH config、syslog passwd/group 和 syslog alias。
- `nemu-full-userland-runtime-real-run-after-fix`: 修复 syslog 后继续 FAIL，暴露 `Privilege separation user sshd does not exist`。
- `nemu-full-userland-runtime-real-run-after-sshd-user`: 修复 sshd 用户后继续 FAIL，暴露 `sshd: no hostkeys available -- exiting`。

## 根因

当前无 sudo/debootstrap 时，full rootfs 走 Ubuntu Base + `dpkg-deb -x` overlay。该路径不会执行 openssh-server/rsyslog 的 maintainer scripts/postinst，因此不会生成默认 `sshd_config`、`syslog`/`sshd` 系统账户、`syslog.service` alias 或 SSH host keys。

## 修复

- `Linux/scripts/build-ubuntu-rootfs.sh` 与 `Linux/scripts/build-ubuntu-systemd-overlay.sh` 在 full flavor 下补 chrootless runtime defaults：默认 `sshd_config`、`syslog`/`sshd` 用户组、rsyslog spool、`syslog.service` alias、`ssh-keygen -A -f "$ROOTFS"` host keys。
- `Linux/scripts/check-ubuntu-rootfs.sh` 用 debugfs 检查 OpenSSH config、syslog/sshd passwd/group entry、ed25519/rsa host key 和 syslog alias。
- `Linux/scripts/check-nemu-systemd-guest.sh` 新增 full-only userland runtime gate，并修正 `rsyslogd -N1` 必须看退出码、`full-userland-runtime` 不能在子项失败时 PASS。
- `scripts/e2e/modules/nemu.sh` 追踪 build/check/guest/wrapper hook，并让 full focused wrapper 要求 `full-userland-runtime` marker。

## 验证

- `bash -n` PASS。
- `full-rootfs-rebuild-after-ssh-hostkeys.log` PASS。
- `full-rootfs-check-after-ssh-hostkeys.log` PASS，含 OpenSSH config、syslog/sshd 账户、ed25519/rsa host key、syslog alias 和 readiness passed。
- `.github/task-runs/2026-06-11-nemu-full-userland-hostkeys-contract/` PASS。
- `.github/task-runs/2026-06-11-nemu-full-userland-runtime-real-run-after-hostkeys/` PASS，full focused gate 含 `full-userland-runtime`、host runtime markers、guest rc=0 和 GOOD TRAP。

## 边界

- 该切片证明 full server-like 用户态组件可查询/可启动，不证明外网 SSH 登录、TAP/NAT、完整 apt 网络源、桌面 Ubuntu、SMP/PCI/snapshot 或长期 soak。
