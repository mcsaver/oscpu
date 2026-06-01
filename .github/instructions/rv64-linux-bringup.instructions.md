---
description: "RV64 Linux/Ubuntu 22.04 bring-up 约束。处理 npc/rv64 的 OpenSBI、Linux、DTB、initramfs/rootfs、QEMU reference 或 Verilator Ubuntu 启动任务时使用。"
applyTo: "npc/rv64/**"
---

# RV64 Linux / Ubuntu Bring-up 约束

## 总目标

近期目标是用 **Verilator** 启动尽量真实的完整 Linux/Ubuntu 22.04 路线；暂不把 Vivado/FPGA 作为前置。长期目标是让 core 和平台边界能继续走向可综合、可验证、可流片水准。

## 必读

- `.github/memory/project-status.md`
- `.github/memory/known-issues.md`
- `.github/memory/modules/npc.md`
- `npc/rv64/README.md`
- `npc/rv64/env/README.md`
- `npc/rv64/design/study/README.md`

## 证据层级

任何结论必须标注当前处于哪一层：

1. `env-built`：OpenSBI/Linux/DTB/initramfs/rootfs 构建完成。
2. `qemu-reference-pass`：QEMU 使用同一产物跑通 reference。
3. `opensbi-handoff`：NPC/Verilator 出现 OpenSBI banner 与 next-stage handoff。
4. `linux-kernel-progress`：Linux kernel 进入 high-half 并持续退休或打印日志。
5. `init-executed`：出现 `Run /init as init process` 与 guest 用户态自定义输出。
6. `ubuntu-probe-visible`：NPC 日志完整出现 Ubuntu `/etc/os-release` 关键字段。
7. `ubuntu-shell-initramfs`：官方 Ubuntu `/bin/sh` 或等价 lp64d 用户态在 initramfs 中运行。
8. `ubuntu-rootfs`：真实 rootfs mount 成功并进入 shell/init。

禁止从低层证据越级声称高层目标完成。

## 图任务优先级

- probe 路线：`rv64-ubuntu-probe-loop`
- rootfs 路线：`rv64-ubuntu-rootfs-loop`
- 显示路线：`linux-display-loop`
- 官方用户态：`rv64gc-userland-loop`

## 关键约束

- QEMU 是 reference，不是 NPC target 证据；NPC 必须有独立日志。
- Ubuntu Base tarball/rootfs 构建成功不等于 guest 已运行 Ubuntu。
- rv64imac/lp64 syscall-only probe 只证明 kernel -> initramfs -> 用户态链路，不等同于 rv64gc/lp64d 官方用户态。
- 不把 toy payload、mini SBI handler、AM legacy 设备 PASS 当作完整 Linux 设备栈证据。
- 每个跨模块或长链调试任务必须更新 `.github/task-runs/<日期-任务名>/`。
