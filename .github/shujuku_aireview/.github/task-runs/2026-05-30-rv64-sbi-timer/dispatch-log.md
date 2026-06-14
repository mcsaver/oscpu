# Dispatch Log

- 复核 `AxiLiteClint`、`tb_axi_lite_clint`、已有 `plic-sirq/uart-plic-sirq` cpu-test，确认 Linux early timer 的缺口在 RV64 LSU aligned lane 与 CLINT 高半访问。
- 推导 CLINT 修改边界：不改 AXI-Lite FSM，只把 `mtime/mtimecmp` 的低地址读写扩展为 64-bit aligned word，并保留精确 `+4` 的 32-bit 兼容视角。
- 修改 `AxiLiteClint`，新增 `apply_wstrb64_aligned`、`apply_wstrb64_high_word`、`read64_aligned`、`read32_zero_extend`。
- 扩展 `tb_axi_lite_clint`，增加 64-bit DUT 和 aligned lane 读写任务。
- 新增 `sbi-timer.c`，用裸汇编 trap handler 模拟最小 SBI TIME extension 和 S-mode timer trap。
- 串行执行 focused testbench、rv64 lint/build、`sbi-timer` 与 `add` smoke，避免当前 WSL/vsock 不稳定被并发命令放大。
- 更新 memory 与本任务记录。
