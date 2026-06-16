# NPC systemd Ubuntu wrapper-marker gate

- 日期：2026-06-15/16（本地 +08，run 结束于 2026-06-16T00:04:05+08:00）
- 范围：`ARCH=riscv64-npc BOOT=ubuntu-rootfs`，systemd-minimal Ubuntu 22.04 rootfs，virtio-blk ext4。
- 结论：PASS，`run.rc=0`。

## 关键证据

- `__NPC_SYSTEMD_CHECK_DONE__ rc=0`
- `__NPC_CHECK_PASS__:os-release-ubuntu-2204`
- `__NPC_CHECK_PASS__:bin-sh`
- `__NPC_CHECK_PASS__:bin-bash`
- `__NPC_CHECK_PASS__:systemd-binary`
- `__NPC_CHECK_PASS__:systemd-autocheck-script`
- `root@ysyx-ubuntu2204:~#`
- `systemd 249.11-0ubuntu3.21 running in system mode`
- `NPC_GUEST_EXPECT='Ubuntu 22.04'` matched
- `exit via guest-watch, code=0, cycles=205697714, commits=104071780`

## 说明

本轮将默认 hard gate 从“等待 sysinit.target 中的 autocheck service 完成”改为两段式：rootfs wrapper 先用 shell builtin 做 guest-side preflight marker，NPC 继续运行到 systemd/Ubuntu banner 才由 `NPC_GUEST_EXPECT=Ubuntu 22.04` 停止。这样避免 NPC 上 systemd unit 图过慢导致默认 gate 超长，同时仍要求 guest marker、root prompt marker 和真实 systemd/Ubuntu boot evidence 同时存在。

边界：该 gate 不等价于完整 multi-user/sysinit/getty 闭合；后续仍应继续推进 systemd autocheck service 或真实 serial getty/root shell。
