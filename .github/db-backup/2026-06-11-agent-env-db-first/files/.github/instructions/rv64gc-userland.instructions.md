---
description: "RV64GC/lp64d Ubuntu 用户态约束。处理官方 Ubuntu riscv64 /bin/sh、动态链接器、libc、F/D 扩展或用户态 ABI 时使用。"
applyTo: "npc/rv64/**"
---

# RV64GC / lp64d 用户态约束

## 核心判断

官方 Ubuntu riscv64 用户态默认面向 `rv64gc/lp64d`。当前 rv64imac/lp64 syscall-only probe 只能证明 Linux 已经执行自定义 `/init`，不能证明官方 Ubuntu `/bin/sh` 或动态链接用户态已可运行。

## 最低 gate

要声称 Ubuntu Base shell 可运行，至少需要：

1. F/D CSR 与 FS 状态行为不破坏 Linux 用户态。
2. FPR load/store、FPR-GPR move、基础 FP 算术/转换、比较、舍入模式与异常标志覆盖常见 libc/shell 路径。
3. `ld-linux-riscv64-lp64d.so.1` 可以启动。
4. 一个动态链接 hello 或 busybox/glibc 小程序可以运行。
5. `/bin/sh` 或等价 Ubuntu Base 程序在 NPC 上有日志证据。

## 禁止误判

- 不把 `fp-loadstore-smoke` 当作完整 F/D 支持。
- 不把 QEMU 能跑 `/bin/sh` 当作 NPC 能跑 `/bin/sh`。
- 不把自定义静态 syscall-only init 的 PASS 叫做完整 Ubuntu 用户态。

## 建议测试阶梯

```text
fp-loadstore -> fcsr/fmv/fclass -> fp-arith-convert -> static lp64d hello -> dynamic linker -> libc hello -> /bin/sh
```

每一级失败都应先定位 ISA/ABI 根因，再考虑设备或 rootfs 问题。
