# V9U 本地 RV64 CsrFile 向量陷阱上下文

- RTL 对象：`npc/rv64/vsrc/core/CsrFile.v`，以及从 `OooCoreTopGlue` 到
  `NpcCoreTop` 的 trap/interrupt 事务路径。
- 当前设计：`sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。
- 原始观测：首次 F0 在 `rv64mi-p-illegal` 停于 `PC=0x800001fc`，达到
  2,000,000 cycle ceiling；测试写 `mtvec.MODE=01`、置 `mip.SSIP`/`mie.SSIE`
  后等待未委派 supervisor software interrupt 进入 M。
- 直接根因：MODE=01 被保留后，旧 `m_irq_enabled_pending_w` 仍只消费
  `MACHINE_INT_MASK`，未委派 SSIP/STIP/SEIP 没有 M-mode pending 路径；
  同时旧 trap delegation 由 cause 类别推断，而不是查询 `mideleg[cause]`。
- 允许动作：最小 CsrFile 组合路由修复、定向 SystemVerilog testbench、可编译
  负向 RTL 版本、官方 RV64 用例与完整功能聚合、证据/账本重绑定。
- 禁止外推：不得将局部 trap PASS 写成 full-core architecture freeze 或 PPA
  promotion；不得用 terminal-event 去重或削弱断言制造 PASS。

