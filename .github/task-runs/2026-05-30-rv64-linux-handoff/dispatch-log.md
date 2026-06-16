# Dispatch Log

- 复核当前缺口，确认多镜像 loader 已有，下一块是 Linux boot protocol 的 `a0=hartid`、`a1=DTB paddr` handoff。
- 新增 `linux-handoff.c`，用 M-mode firmware `mret` 到 S-mode payload，并传入 hartid/DTB 指针。
- 在 payload 中解析 fake FDT big-endian header，并用测试 SBI `ecall` 回 M-mode。
- M-mode trap handler 记录 `mcause/a0/a1/a7`，payload 验证 ecall cause 为 S-mode。
- 串行运行 `linux-handoff` 单测，确认 PASS。
- 串行合跑 `linux-handoff sbi-base-console counteren-time sbi-timer`，确认四条 Linux/SBI early path smoke 互不破坏。
- 更新 memory 与 task-run，记录 handoff 能力和真实 Linux 启动剩余缺口。
