# 规范：serialize-at-retire（域 B 拆除最后一步）—— 可行性评估 + 分阶段实施计划

> 状态：**spec 先行 + Phase1 flag-gated 落地（2026-07-07 生命周期校正）**。宪法 §8.4 step 4。
> `serialize-at-retire-phase1.md` 已实现 head0-CSR 队头化的 `OOO_CSR_QUEUE_HEAD` 编译期开关，
> 但默认仍为 0；2026-07-07 已补齐 glue TB CsrFile stub 的 head0 commit 接线与 flag-ON focused Linux smokes。
> 翻默认 1 前仍需完整 rootfs boot 与 `-v-`/full-state difftest 护航。
> 定位：把 system/trap 指令从"全局 stop_pending + 全后端 drain"改为"ROB 队头执行 + 退休刷 younger"，
> **架构语义不变**（cycle 会变，故 cycle-exact 中性不适用），之后物理删除
> `OooStopPendingSequencer`/`OooPendingDrainResolveGate`/`OooPendingDispatchArbiter` 等机制。
> 配套：宪法 `ooo-core-architecture.md` §8.3/§8.4、真相基线 `rtl-ground-truth-2026-07-03.md` §2.2/§4。

## 0. 结论先行

**判定：这是"系统指令执行模型整体重做"级别的大重写，高风险，触碰精确异常/CSR/特权全路径，
应作为专项（对标 B2 F2 的多会话工程量），spec 先行 + Linux boot smoke 护航，不宜作为快速改动。**

宪法把它写成"改一个标志位、去掉 stop_pending 依赖、语义不变、复用队头精确异常"——**严重低估**。
RTL 真相：**除 CSR 外的系统指令（ecall/mret/sret/wfi/sfence/IRQ/arch-trap）今天根本不进 ROB**，
副作用完全由 pending 控制面在 drain-complete 拍合成产生；CSR 也只在 drain 后作为孤儿单独再注入。
要做 serialize-at-retire，必须先把这些指令改造成真正的 ROB 公民、把 CSR 读点/副作用整体下沉到
队头/commit——**这不是删机制，是新建一条系统指令数据通路。**

## 1. 当前 system/trap 串行机制（现状映射，file:line）

域 B 是**两条并行子机制**：CSR 走"drain→再注入 ROB→commit 写"，其余系统/trap 走"drain→控制面纯合成 fire"。

- **stop_pending 置位源**：`control/OooStopPendingSequencer.v:106-140`（IRQ/取指fault/arch-trap/exit/
  CSR-illegal/system 全族；branch/jal 臂已 `!rob_walk_mode` 门死；lane1 barrier；unsupported）。
- **drain 机制**：`control/OooPendingDrainResolveGate.v`——`backend_drained`(:49-54,含 LSQ 后新增
  `mem_retire_quiet`) + `drain_complete`(:81-83) 被几乎所有 trap/CSR mux 消费；`OooBackendDrainTracker.v`
  寄存版；`OooPendingDispatchArbiter.v` 现为纯 system/trap 事件仲裁。
- **执行五步（csrrw 例）**：①dispatch 读旧值(`OooCsrAccessRequestMux.v:74-78`+锁进 `OooPendingSystemSequencer`)
  →②stop+drain(`OooFetchFlowControl.v:47-72` 三闸停派 + 后端排空)→③重锁 rdata 用架构终值
  (`ControlPlane.v:495-497`,修 fsflags 读0坑)→④单条注入(`OooFrontendBackendDispatchMux.v:84-131`
  把 pending 的 pc/inst/rdata 作 operand 灌进 core_dispatch0,CSR 才作真 ROB uop)→⑤commit 写副作用
  (`OooCsrAccessRequestMux.v:47-49` → `CsrFile.csr_commit_i`)+清 stop。
- **非 CSR 系统指令不走 ④⑤，从不进 ROB**：drain-complete 后控制面直接合成 fire——
  ecall/arch-trap/IRQ/mret 走 `OooCsrTrapRequestMux.v:57-100`；合成"提交"占退休计数走
  `OooControlCommitSequencer.v:54-104`→`OooCommitOutputMux.v:84-110`；sfence/satp TLB flush 走
  `OooCsrAccessRequestMux.v:80-86`→`OooMemoryRequestGate.v:60-62 mmu_flush`(兼 `ifu_axi_abort`)；
  exit/misalign 兜底走 `OooTrapExitEventMux`/`OooTrapExitOutputSequencer`。IRQ 在 dispatch 边界采样、
  drain 后注入="不打断在飞指令"靠 drain 保证。
- **可复用的队头精确异常模板（域 A 已有）**：`OooRob.v:263-266`(head0 异常阻 commit1) +
  `:299 commit0_exception`→`OooCsrTrapRequestMux.v:60-72 trap_mem`→`OooControlFlushSequencer.v:25-29`
  (trap→flush+redirect)。**这正是 serialize-at-retire 要的形状，但只服务随 uop 携带 exception 字段的域 A 指令。**

## 2. 目标形态需要什么

让系统指令：(a) 正常进 ROB（分配 entry）；(b) uop/ROB entry 带 `serialize` + `sys_op` 子类
（csr/ecall/mret/sret/sfence/wfi/irq）+ `csr_addr/csr_wdata` 载荷；(c) commit 拍把标记翻译成
CsrFile 写 / trap / mret / sfence-flush + **flush younger + redirect**。**CSR 读点必须从 dispatch 拍
迁到队头执行拍**（读架构态，因更老已提交；否则读未提交的更老 CSR 写=错值，今天靠 drain+refresh 规避）。

**改造后可删（§8.3 DELETE 项）**：StopPendingSequencer/PendingDrainResolveGate/PendingDispatchArbiter/
PendingSystemSequencer/PendingTrapExitSequencer/ControlCommitSequencer/BackendDrainTracker/
PendingOperandReadGate/PendingLane1CaptureGate + glue 布线。**但有隐藏依赖不能无痛删**：mmu_flush 触发
时机与保持窗、IRQ 队头注入边界、satp 作 RAS/BTB 精确清理边界、wrong-path 系统指令 residual 清理
（`clear_arch_squash`）都深度绑 pending 状态机，删 drain 后须在新框架重建。

## 3. 风险最高的边界（专项开工必读）

1. **CSR 读值时机**：队头读须读到"之前所有已提交写"值；序错会破坏架构态。当前全状态 difftest 已能比较
   确定性 CSR+priv+fflags/frm，但仍需 riscv-tests 特权集与 Linux smoke 覆盖时序/异步边界。
2. **mret/sret 后 flush + priv 切换 + pred 清理**（`priv_predictor_boundary`）：漏/多做→取指走错特权/地址空间。
3. **CSR 写后 hazard**：写 mstatus/satp/pmp 后紧邻指令用新值的可见性（今天靠 drain 天然隔离）。
4. **sfence 后 TLB flush 时序**：`mmu_flush` 从 drain 电平改 commit 脉冲，须冲 ITLB + 在飞取指；脉冲宽窄错→漏刷/误刷。
5. **IRQ 从 drain 边界采样改队头注入**：epc 取哪条、mip/mie 采样拍、与同拍 commit 异常的优先级。
6. **wrong-path 系统指令**：F2 投机把 CSR/ecall 预取到 lane1，进 ROB 后被 mispredict squash 的 residual 清理
   须在 ROB-walk 框架重证不产 spurious trap。
7. **LR/SC/AMO/MMIO 队头独占** 与新 serialize 队头逻辑抢 ROB 队头独占语义的交互。

## 4. 分阶段实施路线（依赖排序；每阶段独立跨 355/0 + difftest + CoreMark，阶段 2 起加 Linux smoke）

- **阶段 0 — spec 先行（不改 RTL）**：定 ROB `serialize/sys_op/csr_payload` 字段契约 + "系统op在 head 的
  commit-fire + flush-younger + redirect"时序图 + CSR 读点迁队头的正确性论证 + 各 sys_op 的 commit 语义；
  **先补定向 TB**（系统op-at-head / CSR-RAW hazard / sfence-TLB / mret-priv / IRQ-at-commit）作红线。
- **阶段 1 — CSR 队头化**（半成品已在）：CSR 改正常程序序进 ROB（不 drain 全后端），读点移队头，commit 写+flush younger。
  仍保留 stop_pending 停派 younger（先不删 drain）。战场 = `rv64mi` CSR 用例。详细实施 spec = `serialize-at-retire-phase1.md`。
  **⚠️【2026-07-04 实现尝试遇方法级障碍】**：读点/rd 覆写/serial_flush 复活机制验证成立（riscv 355/0+模块 TB 82/82+
  difftest 绿），**但 commit 拍 fire-and-forget 的 serial_flush 会中止在飞 LSU AXI 事务（`mem_flush=core_local_flush→
  lsu_axi_abort`），使更老 store 的 probe 永不完成 → backend 永不 drain → drain-based trap 死锁**（3 AM 回归）。
  **共性前置（所有触发 flush 的阶段 1-4 都受此约束）**：serial_flush 必须先与 mem 静默协调（延迟到 MIQ 空阻塞 commit /
  或 flush 对 LSU 像 ROB-walk 不 abort 在飞读）。详见 phase1 spec §9。
- **阶段 2 — sfence/satp 队头化**：进 ROB，commit 产 mmu_flush 脉冲 + flush younger + 冲在飞取指。**起用 Linux smoke**。
- **阶段 3 — ecall/ebreak/arch-trap/illegal 队头化**：携 exception 字段进 ROB，**直接并入现成域 A 队头精确异常路径**
  （重叠度最高、最顺），退休 TrapExitEventMux drain 臂。
- **阶段 4 — mret/sret + IRQ 队头化**：特权切换最险；Linux smoke + `rv64mi/si` 中断用例决定性护栏。
- **阶段 5 — 删机制 + 文档收口**：四类全队头化后物理删除 §2 机制 + 退休 ~15 TB；doc-lifecycle 更新宪法 §8.3
  （标 DELETE 完成）/rtl-ground-truth/ROADMAP。最终 355/0 + difftest + CoreMark + Linux boot 全绿。

**中间态警戒**：阶段 1-4 每阶段会同时存在"已队头化"与"仍走 drain"两套系统op语义，都抢 ROB 队头独占——
**这是最脆弱的中间态，每阶段须显式验证两套路径在队头独占/redirect 上互斥，否则死锁**。
stop_pending/drain 物理删除**只能在阶段 5** 一次性做。

## 5. 验证方案（cycle-exact 不适用 → 语义守正确性）

1. **riscv-tests 355/0 全套**（含 `rv64mi/si` 特权，`make core-regress`）——唯一直接覆盖 trap/CSR/mret/特权的护栏。
2. **difftest 逐指令**（NEMU，全状态比较 GPR/PC + 确定性 CSR/priv + FPR + fflags/frm）——
   对 CSR 队头化已不再是盲区，但 xret/fcvt 等时序 artifact、counter/FS 掩码和异步中断同步仍须按既有策略审查。
3. **CoreMark 0xfcaf** + AM/Dhrystone 全 GOOD TRAP。
4. **Linux boot smoke（本任务必需）**：sfence.vma/satp/mret/S-mode page fault/IRQ 是内核热路径，覆盖
   difftest 难以单独证明的系统级时序与设备/中断交互；
   QEMU 参考 + NPC/Verilator 分层，按 `/init`/内核 print/S-mode 切换 gate 收口。**没有 Linux smoke = CSR/特权侧无护栏。**
5. **定向 + 对抗性 TB**：系统op-at-head 提交→younger squash+redirect+CSR写；CSR-RAW；mret-priv；sfence-TLB；IRQ-at-commit。

## 6. 关键文件索引
- 串行总闸：`control/OooStopPendingSequencer.v`、`OooPendingDrainResolveGate.v`、`OooPendingDispatchArbiter.v`
- 系统op状态/副作用：`control/OooPendingSystemSequencer.v`、`OooPendingTrapExitSequencer.v`、
  `OooCsrTrapRequestMux.v`、`OooCsrAccessRequestMux.v`、`OooTrapExitEventMux.v`、`writeback/OooControlCommitSequencer.v`
- 可复用队头精确异常模板：`writeback/OooRob.v:263-266,299`、`OooCsrTrapRequestMux.v:60-72`、`control/OooControlFlushSequencer.v:25-29`
- CSR 再注入/执行：`frontend/OooFrontendBackendDispatchMux.v:84-131`、`core/CsrFile.v`、`core/NpcCoreTop.v:359-408`
- TLB flush：`memory/OooMemoryRequestGate.v:60-62`
- 装配：`control/OooControlPlane.v`、`core/OooCoreTopGlue.v`

## 7. 变更记录
- 2026-07-04：只读调查 + 可行性评估 + 6 阶段路线（本文件建立）。判定=高风险大重写、走专项、spec 先行 + Linux smoke 护航。
  B4 死硅物理删除完成后接续；宪法 §8.3 的 DELETE 机制项在本计划阶段 5 完成前保持"KEEP（在用）"。
