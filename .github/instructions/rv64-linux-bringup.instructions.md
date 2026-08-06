---
description: "RV64 Linux/Ubuntu 22.04 bring-up 约束。处理 Linux/、npc/rv64 target 的 OpenSBI、Linux、DTB、initramfs/rootfs、QEMU reference 或 Verilator Ubuntu 启动任务时使用。"
applyTo: "Linux/**,npc/rv64/**"
---

# RV64 分层 Linux / Ubuntu Bring-up 约束

## 总目标

近期默认目标是用 **Verilator** 闭合 L0 directed RTL、L1 full-core DiffTest、L2 mini-system 与最高优先级
L3 轻量 Linux；暂不把 Vivado/FPGA 作为前置。Ubuntu 22.04/systemd 全量仿真只在用户明确要求时运行，
不作为默认系统签核的必要条件。长期目标是让 core 和平台边界继续走向可综合、可验证、可流片水准。

## 必读

- `.github/memory/project-status.md`
- `.github/memory/known-issues.md`
- `.github/memory/modules/npc.md`
- `npc/rv64/README.md`
- `Linux/README.md`
- `Linux/env/README.md`
- `npc/rv64/design/README.md`（当前导航；早期学习笔记已归档到
  `npc/rv64/design/history/study/README.md`，只在历史追溯时读取）

## 证据层级

任何结论必须标注当前处于哪一层：

1. `l0-directed-rtl`：受影响 module/transaction TB、assertion 与 oracle mutation 闭合。
2. `l1-full-core-difftest`：official/AM/DiffTest 与完整核提交链闭合。
3. `l2-mini-system`：`run-mini-system-current.sh` 的 OpenSBI + S/U payload 闭合 M→S→U、Sv39、
   timer/PLIC/UART、原子操作与自然 poweroff；七个定向 case 中只有 `all` 声明完整 L2。
4. `l3-lightweight-linux`：`run-lightweight-linux-current.sh` 的 OpenSBI/Linux 6.6/PID1 闭合
   COW/process、timer/tmpfs、UART IRQ 与终端 exact-once；九个短事务中只有 `all` 声明完整 L3。
5. `ubuntu2204-optional-recertification`：只有显式请求的完整 Ubuntu `/etc/os-release`、systemd/rootfs 与严格终态证据。

禁止从低层证据越级声称高层目标完成。

## 图任务优先级

- 默认系统路线：按影响面运行 L0/L1、L2 `run-mini-system-current.sh` 与最高优先级 L3
  `run-lightweight-linux-current.sh`；完整层使用各自 `--case all`
- 可选 Ubuntu probe 路线：`rv64-ubuntu-probe-loop`
- rootfs 路线：`rv64-ubuntu-rootfs-loop`
- 显示路线：`linux-display-loop`
- 官方用户态：`rv64gc-userland-loop`

## 关键约束

- QEMU 是 reference，不是 NPC target 证据；NPC 必须有独立日志。
- 新 guest/boot 产物需要 reference 时只运行对应轻量产物；不得由此自动启动 Ubuntu 22.04 全量仿真。
- `run-system-recertification-current.sh` 的真实执行必须来自用户本轮明确请求并带
  `--user-authorized-full-ubuntu`；自动化、候选收尾或其它层失败都不能隐式授权。
- Ubuntu Base tarball/rootfs 构建成功不等于 guest 已运行 Ubuntu。
- rv64imac/lp64 syscall-only probe 只证明 kernel -> initramfs -> 用户态链路，不等同于 rv64gc/lp64d 官方用户态。
- 不把 toy payload、mini SBI handler、AM legacy 设备 PASS 当作完整 Linux 设备栈证据。
- 长时间系统回放按 durable task-run 保留 fail-closed 状态、身份、bounded 日志与终端/断言摘要；
  可再生 kernel/OpenSBI/Verilator 二级产物留在 runtime 并按缓存策略清理。
