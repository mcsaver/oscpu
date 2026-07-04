# Phase 1 实施 Spec：CSR 队头化（serialize-at-retire step 1）

> 状态：**spec 完成（2026-07-04），实现待落地**。父规范 `serialize-at-retire.md`。
> 范围：**只 head0 CSR 队头化，lane1 CSR 仍走 drain 路**（两路结构互斥，天然最小面）。
> 保留 stop_pending（停派 younger 直到 CSR commit）；不删任何 drain 机制；不碰非 CSR 系统 op。

## 0. 核心结论
Phase 1 可行且比路线图预想更顺——CSR 写机器（addr/rs1/新值）**今天已在 commit 拍从
`core_commit0_inst` + `debug_gprs` + 组合 `csr_rdata_o` 算出**（`OooCsrAccessRequestMux.v:54-78` +
`CsrFile.v:539-543,726`），只被 `pending_system` 的 drain 门控挡住。真正要新建的只有：
(a) 让 head0 CSR 正常进 ROB；(b) commit 拍把架构 `csr_rdata_o` 覆写进 `commit0_rd_data`；
(c) commit 后复用「trap flush 整机」做 flush-younger + redirect。
RAW/satp/wrong-path 三重灾区在 Phase 1 因**保留 stop_pending**（同时至多一条 CSR 在飞）而基本不暴露。

## 1. CSR 读点迁队头（机制）
- `CsrFile.v:560-603 csr_rdata_o` 是纯组合读；CSR 到 ROB 队头时更老全提交 → `csr_addr_i=core_commit0_inst[31:20]`
  时 `csr_rdata_o` 即架构值。**队头读架构值 = commit 拍组合读，无需新读端口/额外锁存。**
- **rd 回写（csrr rd=旧值）是唯一真正要改的读点**：队头化后 head0 CSR 的 `core_dispatch0_csr_rdata=0`
  → 物理寄存器/ROB `data_q` 是垃圾。修法：**`OooCommitOutputMux` commit 拍把 `csr_rdata_i` 覆写进
  `commit0_rd_data_o`（仅 core_commit0 是 CSR 且 !exception 时）** → ArchRegFile + difftest 拿到正确旧值；
  物理寄存器垃圾由 commit 后的**全 flush**（`recover_i`/`recover_gprs_i` 从架构 GPR 重载 phys、
  RenameMap 复位 identity，`OooIntBackend.v:493`/`OooRenameMap.v:100`）修正。

## 2. commit-flush-younger + redirect（复活 core_serial_flush）
1:1 镜像现成 trap flush 时序（trap 已 rv64mi/si 全绿）：
- `head0_csr_commit_w = core_commit0_csr_w && !pending_system_csr_q`（head0 路 CSR 从不进 pending_system
  故 `pending_system_csr_q=0` 唯一识别；lane1 drain 路=1 走老 `pending_system_csr_commit`，二者互斥）。
- **复活 `core_serial_flush`（当前恒 0 死信号，下游布线已完整）**：`OooCoreSliceControlGate.v:39-40`
  `core_local_flush ⊇ core_serial_flush`（→flush ROB/IQ/rename/freelist + phys-recover）、`:42-43`
  `core_commit_ready` 被它关（T+1 不再提交）、`OooFrontendActionGate.v:85` fetch-block、`OooFrontendRunGate.v:55`
  can_run 关——天生为此留的挂点。令 `core_serial_flush_q <= head0_csr_commit`（1 拍，放 `OooControlFlushSequencer`
  与 trap flush 同构）。
- redirect：`OooFetchPacketSeedMux.v:164` 加 `|| head0_csr_commit → set_clear`（清 FIFO）；
  `OooFetchPcOutstandingSequencer.v:206-210` 加 `head0_csr_commit → next_fetch_pc=core_commit0_next_pc + 清 outstanding + discard`。
- **flush 必需的三个理由**：①复位 phys 修 §1 垃圾 rd；②清前端 FIFO 里 stop 生效前投机取的 younger 包
  （用旧 mstatus/satp 上下文取的）；③用新 satp/mstatus/priv 重取。

## 3. stop_pending 保留用法
- 置位臂**不动**（head0 CSR 仍经 `OooStopPendingSequencer.v:126 dispatch0_system_i` 置 stop；CSR∈system 天然为真）。
- 清 stop **加源**：`:104-105` 那组加 `|| head0_csr_commit`（原只 `pending_system_csr_commit` drain 路）。
- drain 判定对 head0 CSR 自然旁路（head0 CSR 不进 pending_system → `system_csr_dispatch_valid` 不触发；
  ROB 非空 → `backend_drained` 不真）——**无需删，lane1 CSR 仍用**。

## 4. 精确最小改动清单（逐模块 + 风险）
`dispatch0_csr_w = dispatch0_facts_w[OOO_SLOT_FACT_CSR]`（bit30）。head0 CSR = `dispatch0_system_w && dispatch0_csr_w`。

1. **`frontend/OooFrontendDispatchGate.v`**：`:149-155 frontend_dispatch_to_backend_valid` 的 `!dispatch0_system_i`
   放宽为 `!(dispatch0_system_i && !dispatch0_csr_i)`（放行 head0 CSR 进正常派发）。**保持 `lane1_base`(:71-78) 不放宽
   → 天然单发**（head1 不与 CSR 同拍进 ROB）。⚠️风险：误放 lane1_base → younger 混入。
2. **`frontend/OooFrontendActionGate.v`**：`:53-67 stop_head` 的 `dispatch0_system_i` 改 `&& !dispatch0_csr_i`
   （CSR 不停头）；`:69-73 fifo_pop` 加 head0-CSR 单发 fire（否则 FIFO 不 pop 死锁）。⚠️漏加 pop → 前端卡死。
3. **`frontend/OooFrontendBackendDispatchMux.v`**：确认 head0 CSR 时 `core_dispatch1_valid` 被 squash（单发）；
   `core_dispatch0_csr_rdata=0` 无害（commit 覆写）。
4. **`control/OooPendingDispatchArbiter.v`**：`:147 pending_system_capture_head0` 的 `dispatch0_system_w` 改
   `&& !dispatch0_csr_w`（**head0 CSR 不 capture**；ecall/mret/wfi/sfence 仍 capture）。**lane1(:148) 不动**。
   ⚠️**最高危**：漏 gate → head0 CSR 既进 ROB 又进 pending → 双写 CsrFile/双提交。**必须 TB 钉死**。
5. **`control/OooStopPendingSequencer.v`**：清 stop 加 `head0_csr_commit`（§3）。置位臂不动。
6. **`control/OooCsrAccessRequestMux.v`**：`csr_commit` 泛化为 `pending_system_csr_commit || head0_csr_commit`
   （或上层 `csr_commit_i=core_commit0_csr`，commit=架构恒安全）；`:80-83 satp_write_commit` 泛化含 head0 路
   （**satp 裸写必须带 mmu_flush**）。`:84-86 sfence_commit` 不动（Phase 2）。
7. **`writeback/OooCommitOutputMux.v`**：新增 `csr_rdata_i`；`core_commit0_rd_data` 在 `core_commit0 是 CSR && !exception`
   时 = `csr_rdata_i`（rd 覆写=读点迁队头落点）。
8. **`control/OooControlFlushSequencer.v`**：`core_serial_flush_q <= head0_csr_commit`（1 拍，与 trap flush 同构）。
9. **`frontend/OooFetchPacketSeedMux.v` / `OooFetchPcOutstandingSequencer.v`**：加 head0_csr_commit 的 set_clear /
   next_fetch_pc=core_commit0_next_pc 平行分支（§2）。
10. **`control/OooControlPlane.v` / `core/OooCoreTopGlue.v` / `core/NpcCoreTop.v`**：算 `head0_csr_commit_w`、布
    `csr_rdata_w`→commit mux、`head0_csr_commit`→seed/pc-seq/stop/flush、`dispatch0_csr_w`→dispatch/action gate、
    `core_commit0_next_pc`→pc seq；`NpcCoreTop.v:371 csr_commit_i` 接合并信号。

**净新增**：`dispatch0_csr`(切 facts)、`head0_csr_commit`、`csr_rdata`→commit mux、`core_commit0_next_pc`→pc seq。
**无 ROB 新字段。不动 CsrFile 写机器、非 CSR drain 路。**

## 5. satp 必选（隐藏点）
`csrw satp` 是 CSR → 走 head0 路（路线图把 satp 划 Phase 2 指的是 **sfence.VMA**，裸 satp 写 Phase 1 就碰到）。
必须 §4#6 泛化 `satp_write_commit` 带 `mmu_flush`（`ifu_axi_abort` 中止在飞取指）。ITLB 以 satp 整值为 tag
（satp 变旧 tag 自动 miss）+ flush+refetch → 功能正确，mmu_flush 只为干净中止在飞 AXI。不处理则 rv64si satp 用例挂。

## 6. 定向 TB（红线）
1. **capture 互斥（最高危）**：`tb_ooo_pending_dispatch_arbiter`——head0=CSR 时 `pending_system_capture_head0==0`；
   head0=ecall/mret/wfi/sfence 时仍 `==1`；lane1=CSR 时 `pending_system_capture_lane1==1`（不回归）。
2. **rd 覆写=架构旧值**：`tb_ooo_commit_output_mux`——core_commit0 为 csrrs 且 csr_rdata_i=V 时 commit0_rd_data==V。
3. **写机器 head0 路**：`tb_ooo_csr_access_request_mux`——head0_csr_commit 时 csr_commit==1、addr==inst[31:20]、
   satp_write_commit 对 csrw satp 拉高。
4. **serial flush 时序**：`tb_ooo_control_flush_sequencer`——head0_csr_commit 后一拍 core_serial_flush_q==1 且仅 1 拍。
5. **集成（core_top_glue_csr.svh）**：CSR-at-head→younger squash+redirect+CsrFile 写；CSR-write→dependent-CSR-read
   RAW（靠 stop+flush+refetch）；csrr rd=旧值；fflags RAW（队头读优势）。
6. **回归红线**：riscv-tests **355/0**（尤其 rv64mi/si CSR）+ 模块 TB 全绿 + difftest 无退化 + CoreMark 0xfcaf。

## 7. 实现纪律
- **先 de-risk serial_flush**：先单发一个 `core_serial_flush` 脉冲（临时接某可控条件），用 `NPC_COMMITWATCH` 确认
  「flush 后一拍不再提交 + 从 next_pc 重取」，再接 CSR 触发——避免复活死信号踩隐藏组合环/时序错配。
- **GPR 一致性护栏**：head0-CSR-flush 复用的 `recover_i`(=flush_i) phys 重载 + rename identity **与 trap flush 同一机制**
  （trap 已 rv64mi/si 全绿），flush 后 younger 重取读对 GPR 是**继承**的既有正确性，非新风险。
- 验证安全网（difftest 不比 CSR）：riscv 355/0(rv64mi/si) + AM 57 + difftest 38/3 + CoreMark 0xfcaf +
  里程碑 OpenSBI banner(M-mode CSR/mret 秒级) → Linux `Linux version`(S-mode satp/sfence,~5min)。

## 8. 变更记录
- 2026-07-04：只读深挖 CSR 五步执行流 + 产出 Phase 1 实施 spec（head0-CSR-only，复活 core_serial_flush，
  rd 覆写，保留 stop_pending，satp 必选）。核心洞察=写机器已在 commit 拍就绪、serial_flush 挂点天生留好。
