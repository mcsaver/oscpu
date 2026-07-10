# 任务报告：AXI4 化战役（S1-S5 全落地）

用户指令："axi 文件名带 lite，改成完整的 axi"。侦查确认现总线是自定义
single-beat AXI-like（非标 arstrb/aruser/abort 边带，缺 ID/LEN/SIZE/BURST/LAST）
——协议升级工程而非改名。spec：`npc/rv64/design/specs/axi4-bus.md`。

## 结果

- **主干完整 AXI4**：两 master 桥输出全信号集（IFU ID=0/LSU ID=1，LEN=0 单 beat，
  INCR，ARPROT[2] 区分 instruction/data，WLAST/RLAST=1，RID/BID 回环）；
  arstrb（非标）→ARSIZE、aruser→ARPROT、abort 边带→master 自吞
  （fetch 桥新增 S_DRAIN 排水态=战役唯一实质新逻辑；mem 桥复用 drop_rsp_q）。
- **外设保持 AXI4-Lite**（工业标准：CLINT/PLIC/UART/VirtioBlk 协议不动），
  AxiXbar=AXI4↔AXI4-Lite 转换互连；文件名全链去 Lite 前缀
  （AxiXbar/AxiToUart/AxiClint/AxiPlic/AxiVirtioBlk）。
- **零行为变化实证**：CoreMark 3342044 拍与战役前逐拍一致（cycle-exact）；
  difftest 收口 riscv 177/177+AM+CoreMark vs NEMU 零 mismatch；
  module TB 86/86+lint 零告警+contract 32。
- 顺手修复：NpcSimTop `active_port_q` 悬空引用（刀 M 遗留，
  CONFIG_NPC_DEBUG_PORTS 下编译失败的现存 bug）。
- 为 ysyxSoC 对接铺路：SoC 接口是 32-bit 完整 AXI4——本战役后只差
  64→32 降宽桥+len=1 burst（届时只改桥不动 xbar 信号集）。

提交链：`41f5e3c77`(spec)→`6db4acedd`(S1)→`5d79a0fdf`(S2)→`e3352c7fe`(S3-S5)。
侦查全文：evidence/recon.jsonl。
