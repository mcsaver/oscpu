# Dispatch Log

## 2026-05-30

- 复核当前 RV64 Linux 前置记录：已有 S-mode/delegation/Sv39/fault trap/flush-drain 覆盖，但真实 Linux/OpenSBI 风格 S-mode SBI ecall 尚未被 focused test 明确覆盖。
- 选择最小可验证推进点：在 `tb_ooo_priv_system` 中新增一个模式，而不是直接改 RTL 或尝试完整 Linux 镜像。
- 新增 `MODE_SBI_ECALL`：
  - M-mode 设置 `mtvec`。
  - `medeleg` 保持 0，确保 S-mode ecall 不委托。
  - `mret` handoff 到 S-mode。
  - S-mode `ecall` trap 到 M-mode handler。
  - M handler 读取 `mcause/mepc/mstatus`，写回 `mepc+4`，`mret` 回 S-mode。
- 初跑失败：测试直接检查 `x9` 为原始 `mepc`，但 handler 后续用同一寄存器执行 `mepc += 4`，最终观测到的是返回 PC。
- 修正测试观察点：handler 用 `x12` 保存原始 `mepc`，`x9` 保留写回后的返回 PC。
- 复验 `tb_ooo_priv_system` PASS。
- 复验 Linux 前置 focused 组合 `tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_mem_axi_bridge tb_ooo_int_backend` 4/4 PASS。
- 继续补相邻 Linux 前置边界：新增 `MODE_S_EXT_IRQ`，覆盖 M-mode 设置 `stvec/mideleg`、S-mode 打开 `sie.SEIE/sstatus.SIE`、外部中断进入 S handler、读取 `scause/sepc/sstatus`、`sret` 返回 WFI/fallthrough。
- 单跑 `tb_ooo_priv_system` 到 `/tmp/rv64-priv-sirq` PASS。
- 复验 Linux 前置 focused 组合到 `/tmp/rv64-linux-sbi-sirq-focused` 仍为 4/4 PASS。
- 结论：现有 RTL 已能通过 focused test 证明 SBI 风格 S-mode ecall 与 S-mode external interrupt 的基本 trap/return 边界；本轮补的是覆盖缺口，不声称真实 Linux 已启动。
