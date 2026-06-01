# Dispatch Log

- 读取 AGENTS/rv64 Linux bring-up/RV64GC userland 指令与 memory，确认本轮必须分层记录 QEMU reference、NPC gate、官方 `/bin/sh`。
- 复核 shell initramfs/OpenSBI/Linux/Image/DTB/NpcSimTop 产物存在。
- 运行 QEMU shell reference，确认 `[ysyx-sh] /bin/sh -c marker` 在 QEMU 中可达。
- 运行 NPC `smoke-ubuntu-shell-watch`，发现 OpenSBI `fw_boot_hart` 循环。
- 反汇编 `fw_jump.elf`，确认 `0x80000680` 是 `fw_boot_hart`，且 recent commit 表明 JAL link 被写为 target。
- 新增 `jal-link-smoke.S` 和 Makefile gate，复现 BAD TRAP code=1。
- 按 RTL 四阶段推导修复 `OooAluFetchCore` direct JAL dispatch/link 与 commit next_pc 语义。
- 重建 Verilator `NpcSimTop`，随后运行 focused smoke 和 FP 短回归。
- 重跑 NPC shell watch，确认已推进到 Linux driver init，但 12 亿 cycles 到期未到 `/init`。
- 更新 project-status、NPC module memory、known-issues 与本 task-run。
