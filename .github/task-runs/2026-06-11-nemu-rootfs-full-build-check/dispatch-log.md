# Dispatch Log

## RECALL

- 读取 `.github/AGENTS.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 和 `.github/memory/modules/nemu.md`。
- 确认当前 full flavor 只有产物隔离和 dry-run 入口，尚无实物构建/检查证据。

## DISPATCH

- 检查当前产物和环境：默认 2G rootfs 存在，full ext4 缺失；`fakeroot`、`mkfs.ext4`、`debugfs`、`curl`、`dpkg-deb`、`apt-get` 可用；`debootstrap` 和 `qemu-riscv64-static` 缺失，非交互 sudo 不可用，因此走 Ubuntu Base + fakeroot + apt/dpkg-deb overlay 路线。
- 执行 `make -C Linux ARCH=riscv64-nemu ubuntu-rootfs-full-image` 并记录 `evidence/full-rootfs-build.log`。
- 首次构建已生成 full ext4/cpio，但 final readiness check 失败在 `MISSING Ubuntu interactive command ping: /usr/bin/ping`。
- 用 `debugfs -R "stat /bin/ping"` 确认实物路径为 `/bin/ping`。
- 修正 `Linux/scripts/ubuntu-rootfs-flavors.sh` 的 required path，并在 `scripts/e2e/modules/nemu.sh` 中加入 `/bin/ping` slice contract。
- 执行 `make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-full` 并记录 `evidence/full-rootfs-check.log`。
- 记录 full/default rootfs artifact stat 到 `evidence/full-rootfs-artifacts.stat`。
- 执行 `scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-rootfs-full-build-check-e2e`，确认 `/bin/ping` 和 full artifact dry-run 纳入 e2e。

## VERIFY

- `make -C Linux ARCH=riscv64-nemu ubuntu-rootfs-flavors-check`: PASS。
- `make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-full`: PASS。
- `scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-rootfs-full-build-check-e2e`: PASS。

## RECORD

- 稳定结论已同步到 `.github/memory/project-status.md` 与 `.github/memory/modules/nemu.md`。
- 该任务不关闭长期 goal；下一步候选是运行 `check-nemu-systemd-guest-full`，把 full rootfs 从实物检查推进到真实 NEMU guest focused gate。
