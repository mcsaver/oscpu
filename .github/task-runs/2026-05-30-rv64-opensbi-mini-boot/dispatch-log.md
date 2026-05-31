# Dispatch Log

- 解析旧卡点：`pc=0x80006656` 经 `addr2line/objdump` 对应 OpenSBI `sbi_hart_hang()`。
- 追踪 OpenSBI 初始化：`sbi_init()` 在 `sbi_domain_init()` 后进入 hang，原因是 `scratch->fw_rw_offset` sanity check 失败。
- 排查链接布局：旧构建使用 `FW_TEXT_START=0x80001000`，`_fw_start=0x80001000`、`_fw_rw_start=0x80040000`，offset 为 `0x3f000`，不是 power-of-2。
- 修正固件构建策略：取消为 trampoline 预留 text hole，使用 OpenSBI 默认 text start，并用 `FW_FDT_PATH=/home/lyg/PA/ysyx-workbench/npc/rv64/tools/build/npc-rv64.dtb` embedded FDT。
- 新卡点：OpenSBI semihosting probe 执行 `slli x0,x0,0x1f; ebreak; srai x0,x0,7`，NPC 把 `ebreak` 当 AM halt。
- RTL 修复：在 `OooAluFetchCore` 中仅识别 semihost magic sequence 的 `ebreak` 为架构 `EXC_BREAKPOINT` trap；保留普通 `ebreak` 作为 AM/NPC halt。
- 测试补齐：新增 `semihost-ebreak` 验证 magic breakpoint trap，新增 `misa-priv` 验证 OpenSBI early probe 所需 `misa` 扩展位，扩展 `compressed` 的 RV64C 覆盖。
- 工具补齐：新增 `smoke-opensbi` target 和 `mini-linux-payload.S`，把 OpenSBI、payload、DTB 组成真实固件 handoff smoke。
- Payload 修正：FDT magic `0xedfe0dd0` 需要用 `lwu` 读取，避免 `lw` sign-extend 后误判。
- 验证闭环：OpenSBI v1.8 banner 完整输出，Domain0 handoff 到 `0x80200000`，payload 检查 DTB 并通过 UART 打印 `S` 后 GOOD TRAP。
