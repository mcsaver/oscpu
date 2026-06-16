# Dispatch Log

- 2026-05-22: 读取工程规则、NPC 记忆、RTL 工作流与 RISC-V CSR 学习笔记，确认身份 CSR 应收口在 `CsrFile`。
- 2026-05-22: 搜索 `DecodeUnit/CsrFile/define.v/tb_npc_core_mcycle`，确认 `CSRRS` 译码和读改写路径已有骨架，缺口是身份 CSR 常量与显式测试覆盖。
- 2026-05-22: 新增 `CSR_MVENDORID/CSR_MARCHID` 宏，在 `CsrFile` known/read mux 中加入只读常量。
- 2026-05-22: 扩展 `tb_npc_core_mcycle`，使用 `CSRRS rd, csr, x0` 读取 `mvendorid/marchid` 并检查返回值。
- 2026-05-22: 首轮测试发现 `marchid` 后紧跟 illegal CSR 写导致提交观测被提前 trap 截断，给测试程序补两条 NOP 后通过。
- 2026-05-22: 完成模块 testbench、lint、Verilator build 和全量 cpu-tests 验证。
