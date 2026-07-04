# Phase 1 实施 Spec：CSR 队头化（serialize-at-retire step 1）

> 状态：**flag-gated 半落地（2026-07-05）**。§9 mem-quiescence 安全机制**已实现并落地（sound，3 refute
> agent 对抗验证）**，§4 CSR 队头化核心机制验证成立（riscv rv64mi/si 23/23 + FP 全绿），但中间态
> （head0-CSR 与 lane1-drain-CSR 共存）有未解死锁，故全特性收在编译期 flag `OOO_CSR_QUEUE_HEAD`
> （默认 0=基线，树保持绿：module TB 82/82 + lint 0 + riscv 177/0 + AM 57/58）。**详见 §10。**
> （历史：2026-07-04 首次尝试遇 §9 flush↔LSU 障碍未落地；本轮 §9 修向① 已解，暴露更深的中间态死锁。）
> 父规范 `serialize-at-retire.md`。
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

## 9. ⚠️ 关键障碍：flush-on-every-CSR ↔ 异步 LSU 冲突（实现尝试确认，未解决）

按 §4 全量实现后 spec 本体成立：**riscv-tests 355/0（含 rv64mi/si CSR/特权）+ 模块 TB 82/82（含新增定向 TB）
+ difftest 无退化**。读点迁队头、rd 架构 GPR 覆写（真修=`OooAluCoreSlice` 写 ArchRegFile 处，非 OooCommitOutputMux
——后者只喂 difftest/观测=假绿点）、复活 `core_serial_flush`（原家 `OooControlCommitSequencer`）、ROB 禁 CSR
commit1 均验证正确。

**但 3 个 AM 测试死锁回归（counteren-time / sbi-base-console / uart-plic-sirq，AM 54/3 vs 基线 57/1）**，
root-cause 同族（方法级）：
- `OooMemoryRequestGate.v:60 mem_flush_o = core_local_flush`（= flush || trap_flush || **serial_flush**）→
  `lsu_axi_abort`。∴**每次 head0-CSR 的 serial_flush 都中止在飞 LSU AXI 事务**（store 地址 probe 经 MIQ）。
- 典型（counteren-time）：非法 S-mode `rdtime` 正确路由到 drain→csr_illegal arch-trap 且被 capture，但更老的
  `sd ra`(0x5c) 卡在 ROB 队头 `head_done=0`——它在 SQ、probe 已发但被 serial_flush 中止、永不完成 → 永不提交 →
  `backend_drained=0` 恒假 → **drain-based trap 死锁**。
- 即 **serial_flush 不能是 commit 拍的 fire-and-forget**，它与异步 LSU/MIQ 根本冲突（原始 serialize-at-retire
  调查已预判"精确异常/访存交织"是重灾区，此处坐实）。

**修向（Y，下一迭代，LSU-recovery 级）**：①**延迟 serial_flush 到 `mem_idle`**（MIQ 空+无在飞 probe/drain），
期间阻塞 commit，让在飞 probe 先完成再 flush；或 ②**serial_flush 对 LSU 像 ROB-walk**（不 AXI-abort 在飞读、
孤儿响应静默丢弃、不孤儿化 MIQ 项）。（试过并回退的两招：把 head0_csr 做真 stop_pending owner——stuck store
比非法 CSR 更老、停 younger 够不到；只从 lsu_axi_abort 摘 serial_flush——死锁仍在，证明是 probe-completion/MIQ
响应路由被 backend flush 破坏，非单纯 AXI abort。）

**结论**：Phase 1 读点/rd/serial_flush 机制正确且已验证，但落地前**必须先做 serial_flush 与 mem 静默的协调
（§9 修向）**——这是本方法成立的前置，也是后续所有阶段（sfence/mret/IRQ 同样触发 flush）的共性前置。

## 8. 变更记录
- 2026-07-04：只读深挖 CSR 五步执行流 + 产出 Phase 1 实施 spec（head0-CSR-only，复活 core_serial_flush，
  rd 覆写，保留 stop_pending，satp 必选）。核心洞察=写机器已在 commit 拍就绪、serial_flush 挂点天生留好。
- 2026-07-04（**实现尝试，未落地**）：按 §4 全量实现，riscv 355/0 + 模块 TB 82/82 + difftest 绿，**但遇 §9
  flush↔LSU 方法级障碍，3 AM 死锁回归**。落地中确认的 spec↔RTL 偏差：serial_flush 生成家实为
  `OooControlCommitSequencer`（非 §4#8 FlushSequencer）；rd 覆写真落点 `OooAluCoreSlice` 写 ArchRegFile
  （§1 的 OooCommitOutputMux 只喂 difftest=假绿点）；satp mmu_flush 队头拍死锁取指桥故关（靠 serial_flush+
  discard+ITLB satp-tag miss 保正确，rv64si-p-dirty 过）；FP CSR 排除本阶段（squash 在飞 FP 活锁）；CSR 必须
  单独提交（禁 commit0/1 CSR dual-commit）。**stop_pending 对 head0 CSR 是孤儿自清 no-op、正确性全靠 serial_flush**
  ——正是它与 LSU 冲突暴露之因。补丁未合入（待 §9 修向）。

## 10. §9 修向① 实现 + §4 落地 + 中间态死锁（2026-07-05，flag-gated 半落地）

> 状态：**§9 mem-quiescence 安全机制实现并落地（sound，已对抗验证）；§4 CSR 队头化核心机制验证成立
> （riscv rv64mi/si 23/23 + FP 全绿）；但中间态（head0-CSR 与 lane1-drain-CSR 共存）有未解死锁，
> 故全特性收在编译期 flag `OOO_CSR_QUEUE_HEAD`（默认 0=基线行为，树保持绿）。** flag ON 需先解中间态串行化。

### 10.1 §9 修向① 落地：mem_quiet 门控（sound）
- **门控信号 = `mem_idle && mem_retire_quiet`**（二者）。mem_idle(OooIntBackend:1082,miq_empty)覆盖 younger
  在飞 load/probe/active-drain；mem_retire_quiet(:1086,sq_empty)覆盖 committed 但未 drain 的更老 SQ store。
  二者 AND = 完全 mem 静默 → serial_flush(mem_flush→lsu_axi_abort)中止不了任何东西、破坏不了 MIQ 响应路由。
  选 both（非单 mem_idle）使 head0-CSR 路的 **liveness 包络与现成 drain 路(backend_drained 已含 mem_retire_quiet)
  完全一致** = 继承已验证机制的活性边界，且结构性消除边界 drain race。
- **落点=OooRob commit0_fire（loop-free）**，非 ControlPlane commit_ready mask：后者 core_commit0_csr 依赖
  commit0_valid=commit0_fire=依赖 commit_ready → 组合环。改用 ROB 内部 `head0_is_csr_w`（从 inst_q/done/
  exception 判，不依赖 commit_ready）门控 commit0_fire → 无环。head0_csr_commit 天然只在 mem 静默拍拉高
  （因 core_commit0_csr=commit0_fire 已含门控）。mem_idle&&mem_retire_quiet 在 OooIntBackend 生成，同域下路
  由 OooDispatchBackend→OooRob（mem_quiet_i）。
- **对抗验证**：3 个独立 refute agent（new-deadlock/correctness/sq-flush）全 REFUTED=False，high conf：
  ①mem_idle 时无在飞 AXI→死锁结构性不可能且有界可达；②读旧值/写副作用/rd 回写架构正确（等待期 CSR 态冻结）；
  ③committed store 恒存活 flush_all + 边界 drain nokill 免疫 → mem_idle 单独已够（本实现更保守用 both）。

### 10.2 §4 落地实现（当前行号，flag ON 生效）
- §4#1 前端放行(OooFrontendDispatchGate:152) + §4#2 stop_head/fifo_pop(OooFrontendActionGate) +
  §4#3 dispatch1_squash(OooFrontend) + §4#4 capture 互斥(OooPendingDispatchArbiter:147)。
- rd 覆写真落点：**OooAluCoreSlice commit0_data 覆写**（commit0_data 同喂 ArchRegFile + core_commit0_rd_data
  difftest 流 = 同 wire，覆写 1 处修两者），值=commit 拍架构组合读 csr_rdata（NON dispatch-time：fsflags 坑）。
- serial_flush 复活：OooControlCommitSequencer:85 `serial_flush_q<=head0_csr_commit_i`。下游全 born-ready。
- redirect：OooFetchPacketSeedMux/OooFetchPcOutstandingSequencer 加 head0_csr_commit 臂(next_pc=core_commit0_next_pc)。
- CSR state 写：NpcCoreTop csr_commit_i `|= head0_csr_commit`（satp mmu_flush 不在 head0 拍开，靠 ITLB satp-tag miss）。

### 10.3 落地中发现并修复的 4 个真 bug
1. **commit1-CSR 漏 head0_csr_commit**：CSR 经 commit1（双提交第二条）退休时 head0_csr_commit（只看 commit0）
   漏掉 → mtvec 静默不写。修：OooRob commit1_fire 加 `!head0_is_csr && !head1_is_csr`（CSR 恒单发经 commit0）。
2. **pending_system_csr_q 全局抑制**：head0-CSR 与另一条 lane1-drain-CSR 共存时，后者 pend_csr_q=1 误抑制前者
   head0 提交。修：head0_csr_commit 用 `!pending_system_csr_commit_w`（pc 精确匹配那条）而非全局 pend_csr_q。
3. **FP CSR 未排除**：fcsr/fflags/frm(0x001/2/3)走 head0 路 → serial_flush squash 在飞多周期 FP → fdiv/fmadd 挂。
   修：frontend + arbiter 的 dispatch0_csr_w 排除 FP CSR（仍走 drain）。
4. **serial_flush 未清 pending_system**：head0-CSR commit 刷 younger 但 younger 的 pending 系统op残留。
   修：arbiter pending_system_clear `|= head0_csr_commit`（部分缓解，未根治，见 10.4）。

### 10.4 ⚠️ 未解中间态死锁（flag ON 时 sbi-base-console / fp-difftest-probe 挂死）
父 spec §4 已警告「阶段 1-4 中间态两套系统op语义共抢 ROB 队头独占=最脆弱、易死锁」，此处坐实两层：
- **两条 lane1-CSR 覆写单个 pending 寄存器**：mtvec+mstatus 在重叠窗口都被捕获到 pending_system（单寄存器），
  第二个覆写第一个 → 第一个 drain 状态丢失（pc mismatch 既不走 drain 又靠 hack 走 head0）。根源=head0-CSR 的
  stop_pending 未有效串行化 lane1-CSR 捕获（baseline 靠 stop 串行化能过，§4 扰动之）。
- **ecall-drain stuck-store**：sbi 后段 ecall 捕获到 pending 后 drain 永不完成——`backend_drained=0`（ROB 空但
  `mem_retire_quiet=0`=一个 store 卡 SQ，§9 家族残留）→ stop_pending 卡死 → 前端冻结（CANRUN0: stopbusy=1/sys=1）。
- **诊断方法学**：NPC_COMMITWATCH（退休真相）+ 自插 CSRWRITE_PROBE/CANRUN_PROBE（ifdef，已移除）逐层定位
  csr_commit fire→head0_csr_commit→pending_system 转换→can_run blocker→stop_pending owner。

### 10.5 验证矩阵
| 状态 | module TB | lint | riscv | AM | 结论 |
|---|---|---|---|---|---|
| flag OFF（提交默认）| 82/82 | 0 | 177/0 | 57/58* | **= 精确基线**（*fp-difftest-probe 预存在失败，与本工作无关）|
| flag ON | 82/82 | 0 | rv64mi16+si7+FP 全绿 | sbi/fp-difftest-probe 挂死 | 核心 sound，中间态未解 |

### 10.6 下一步（flag ON 前置）
解中间态串行化：使 head0-CSR 的 stop_pending 有效阻止 lane1-CSR 捕获（或让 lane1-CSR 也队头化 = 每 CSR
单发经 head0，消除共存），并根治 ecall-drain 的 SQ stuck-store（核对是否 serial_flush/中间态扰动致某 store 未 drain）。
