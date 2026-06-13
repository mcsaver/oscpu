# Dispatch Log

- 复核 `CsrFile` 和 `AxiLiteClint`，确认已有 `sip/sie`、SSIP、CLINT MSIP 与 S-mode interrupt delivery 基础。
- 新增 `sbi-ipi-reset-hsm.c`，用 M-mode firmware handler 模拟 SBI IPI/HSM/SRST。
- 通过 SBI IPI `send_ipi(hart0)` 让 M handler 设置 `sip.SSIP`，S-mode 在 `wfi` 处接收 S software interrupt。
- S handler 记录 `scause/sepc/sstatus`，清 `sip.SSIP` 并 `sret`。
- 同测加入 HSM `hart_get_status(hart0)` 和 system reset `shutdown/no_reason` 参数检查。
- 串行运行 `sbi-ipi-reset-hsm` 单测，确认 PASS。
- 串行合跑 `linux-handoff sbi-base-console counteren-time sbi-timer sbi-ipi-reset-hsm`，确认五项 Linux/SBI early path smoke 互不破坏。
- 串行运行默认 `riscv64-npc` cpu-tests 全量回归，确认 48/48 PASS。
- 更新 project status、NPC/AM-Kernels 模块笔记、known issue [39] 和本 task-run。
