# Dispatch Log

- 复核当前 SBI/console 与 UART 路径，确认 `Uart` TX offset 0、`NpcSimTop` UART event 和真实 UART base `0x10000000` 可用于 mini console 输出。
- 新增 `sbi-base-console.c`，用 M-mode trap handler 模拟最小 SBI base extension 与 legacy console putchar。
- 串行运行 `sbi-base-console`，确认 PASS，且 guest 串口输出 `OK`。
- 串行合跑 `sbi-base-console counteren-time sbi-timer`，确认 base/console 不破坏 counter/time/timer 早期路径。
- 串行执行 rv64 lint、rv64 build smoke 和 `add` smoke。
- 更新 `.github/memory/` 与本 task-run，记录已覆盖能力和真实 Linux boot 剩余缺口。
