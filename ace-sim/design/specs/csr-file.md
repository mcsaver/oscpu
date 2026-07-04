# CsrFile — CSR 文件 + trap 序列器

**文件**:`src/core/control/CsrFile.hh` · **↔ npc**:`CsrFile` + `Ooo*TrapRequestMux`(精确异常/中断)

## 职责
持特权 CSR(`mtvec`/`mepc`/`mcause` + 通用槽)。给出 trap/mret 的控制转移目标。
所有 CSR/trap 效应发生在 **commit 边界**(架构状态一致点);序列/squash 属 `CpuTop`(control glue),本模块只做**状态 + 目标计算**。

## 状态
- `csr_[CSR_COUNT]`:CSR 数组。命名索引 `CSR_MTVEC=0` / `CSR_MEPC=1` / `CSR_MCAUSE=2`,其余通用。

## 接口
- `read(idx)` / `write(idx, v)`:CSR 读写(commit 拍应用)。
- `trap(epc, cause)`:`mepc=epc; mcause=cause;` 返回 `mtvec`(handler PC)。
- `mret()`:返回 `mepc`(返回地址)。

## 系统 op 语义(ISA:`CSRW/CSRR/ECALL/MRET`)
- **CSRW** `csr[idx]=imm`、**CSRR** `rd=csr[idx]`:dispatch 即 `done`(不进 IQ),**dispatch 串行**(`system_stall_`,其 commit 前不再分派 → 不投机 CSR),效应在 commit;CSRR 的 `rd` 在 commit 写物理寄存器。
- **ECALL**:commit 拍 `trap(pc+1, CAUSE_ECALL)` → `fetch.redirect(mtvec)`。因串行,ECALL 后无更年轻指令被分派,故无需 squash ROB/IQ/SQ,仅清取指队列。
- **MRET**:commit 拍 `fetch.redirect(mepc)`。

## 精确异步中断(`CpuTop::take_interrupt`)
- `on_wakeup` 收 `EventKind::TimerInterrupt` → `pending_irq_`;在 `on_retire` 最老指令边界注入。
- `mepc = 最老在飞指令 PC`;`squash_all`(清全部在飞 + 归还 phys_dst)+ `rename ← RRAT`(已提交 rename map)
  + `sq.squash_uncommitted`(**保留已提交未落存 store**)+ `fetch.redirect(mtvec)`。
- 返回(MRET)后主程序从 `mepc` 续跑 → 中断对主程序**透明**。

## 不变量 / 行为
- 与 `FunctionalBackend` 同步语义逐位一致(ECALL:`mepc=pc+1, mcause=8, pc=mtvec`;MRET:`pc=mepc`)。
- RRAT 在每条有 `arch_dst` 的指令 commit 时 `remap(arch_dst, phys_dst)` 维护;是精确中断/异常回滚的检查点(与分支 squash 的 `rat_ckpt` 同构,只是 checkpoint = 已提交映射)。

## 测试
`make run-csr`:①同步 ECALL/MRET → handler → 续跑,regs bit-exact vs golden;②异步中断透明性 + handler 恰一次;
③注入周期 1..80 压力(每拍架构态与无中断基线一致 → RRAT/squash-all/已提交 store 保留 正确);
④fuzz 2 万程序 / 8.1 万系统 op(2.7 万 ECALL)对拍功能金标准(regs+mem)。
