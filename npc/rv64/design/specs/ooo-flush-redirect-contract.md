# rv64 OoO 核 flush / redirect 契约（现状冻结 v2）

> **类型**：跨模块架构级 **接口契约（contract spec）** —— 非重写方案。本文件只**描述现状 + 指出缺口 + 冻结不变量**，不落地任何 RTL 改动。
>
> **依据**：
> - 编排层 `decisions [38]`：将 ①flush 契约冻结 ②C-OBJ-REDIR 重写评估 ③对抗审查 三份逆向结果**融为一份可落盘、可进 check-contract 的契约**。
> - 宪法 `design/arch/ooo-core-architecture.md` **§7 / C7**（fetch redirect PC 已有年龄律
>   arbiter；后端 kill/reason/flush 与 pending/事务层仍未形成统一 control event）。
> - 宪法 **§5.5 C-OBJ-REDIR**（`ooo-core-architecture.md:304-322`，`redirect_event` 目标统一格式）+ **§C7 年龄律 + arbiter 删档记录**（`:407-416`）。
> - 现状活跃度真源：`design/arch/rtl-ground-truth-2026-07-11.md`。
> - 逆向来源：四子系统 JSON（fetch / 后端 flush / AXI / stop-pending）+ 本轮 C-OBJ-REDIR 重写评估 + 对抗审查（含一处跨子系统纠正 GAP-5、一处漏项 FP/MulDiv 簇）。
>
> **契约先行声明（SPEC-TEMPLATE §2 强制）**：**本表是一切"触碰 flush / redirect / trap 序 / 投机恢复"改动的前置契约**。触碰 §1 列出的任一汇合点、或新增/删除任一 flush 源，动 RTL 前必须先在此更新 §2 源总表 + §2 优先级全序 + §4 不变量断言，并保证 `make -C npc/rv64 check-contract` 计数不回退。填不出 = 未理解上下游 = 禁止改 RTL。
>
> **证据分层**：`[验证]` = 本轮亲自开该 file:line 复核；`[逆向]` = 取自四子系统 JSON 未复核；`[审查]` = 对抗审查独立开 RTL 亲验、本 spec 采信但未逐行复核。存疑点显式标 **存疑**，不粉饰。
>
> **⚠️ 行号会漂移**：全文 `:NNN` 行号为**冻结拍（2026-07-05）**快照，任一 RTL 插行即失准。**权威锚点是信号名 + 模块名**（可被 `check-rtl-style` / `check-contract` grep），行号仅供当拍追溯。真源不在本 .md 的行号里，而在 §4 落地为 `` `ifdef OOO_ASSERT $error `` 的 ratcheted 立即断言里（见 §4 与 §未闭合项 UC-11）。

---

## 1. 目的与范围

**解决什么**：把散落在 fetch / 后端 / AXI / stop-pending / FP 簇的 flush·redirect·kill 施加点，归并成**单一去重视图**，钉住"三条铁律 + 优先级全序 + 承重不变量"，作为 C7「补丁总线」收口与 `OOO_CSR_QUEUE_HEAD=1` 全 Linux 推进的前置产物。

**边界（不负责）**：
- E11 `mmu_flush` 与控制流 redirect **正交**，但它会清 TLB/cache/请求上下文并影响桥
  FSM；因此在源表和铁律②中冻结它与事务 drain 的边界，不参与 PC winner 仲裁。
- 铁律②的 AXI 事务级 drain-vs-kill 与“选哪个 PC / squash 谁”分层，但仍是本契约必须
  给出 CURRENT/KNOWN GAP 裁决的承重合同。
- `fetch_fault_i` 是槽分类事实，经 pending arch-trap 捕获并等待 drain 后进入 trap 边界；
  它不是 ROB committed exception，也不是独立 redirect 源。
- 不重写、不拆任何模块（重写裁决见 §5）。

### 0. 约定与默认编译 flag

默认构建 flag（`vsrc/include/define.v` [验证]）：

| flag | 行 | 默认值 | 影响 |
|---|---|---|---|
| `OOO_ROB_WALK_MODE` | :541 | `1'b1` | 分支走投机 + ROB-walk；关掉一批 domain-B / checkpoint 死臂 |
| `OOO_DBRANCH_DOMAIN_A` | :548 | `1'b1` | direct 分支经普通 dispatch 进 ROB，不再 stop+drain |
| `OOO_CSR_QUEUE_HEAD` | :557 | `1'b0` | **serialize-at-retire 队头化 + serial_flush 整条链默认休眠**；CSR 走 drain 路 |

**活跃度标注**：**[活]** = 默认构建下会触发；**[休]** = 默认 flag 下恒 0（仅 flag ON 活）；**[死]** = 端口接常量 / 结构性从不触发；**[半死]** = 非 flag 门控但默认模式下运行时几乎不命中（对照 `rtl-ground-truth-2026-07-11.md`）。

> ⚠️ **幸存者偏差告警（对抗审查挑战#3，系统性）**：默认 `OOO_CSR_QUEUE_HEAD=0` 下 **E2 serial_flush / E5-head0 支 / GAP-8 head0_csr_inflight / GAP-5「serial 恒在 SQ 空拍」整条 serialize 机理全部休眠 [休]**。本契约引用的头号绿证据（riscv 355/0 + AM 57/58 + CoreMark 0xfcaf + sv39 boot + linux-mini）**全部跑在 flag=0**。因此**凡触及 serialize 的"成立"，其证据强度 = "flag=0 下不触发"，而非"flag=1 绿回归背书"**（memory「翻 1 待完整 Linux boot」尚未完成）。§3/§4 凡属此类，一律带此 caveat，不得读作 settled。

三铁律（契约根律，SPEC-TEMPLATE §2 强制）：
- **铁律①** committed store 不得被任何 flush 清除（提交拍已离 ROB 进 SQ）。
- **铁律②** 已发出的 AXI 事务不得被 kill，只能 drain 到完成。
- **铁律③** CSR 写在 commit 拍即架构可见，flush 不得撤销。

> **2026-07-12 CURRENT 裁决**：IFU 已发读与 A-update AW/W/B 都具备本地 drain owner，
> `IFU-AXI-G1` 已关闭；D-side 读/write/A-D 也由本地 `drop_rsp_q`/write owner 排水，不再依赖
> xbar abort。全局铁律②仍因 AMO/LR/SC nokill 分类未完成专项核实（UC-D）保守判为**部分满足**。

---

## 2. 接口契约

### 2.1 flush / redirect 源总表（CURRENT overlay + 历史冻结底稿）

#### 2.1.1 2026-07-11 CURRENT overlay

下表只列 07-09 P4 后发生 owner/活跃度变化的源；它覆盖随后 2026-07-05 详细表中的
fetch 落点与活跃度列。未列源继续使用详细表，但仍受 §2.2 current arbiter 裁决约束。

| 源 | 当前 fetch owner / 活跃度 | 当前裁决 |
| --- | --- | --- |
| E1 committed trap/exit | `OooFrontend` commit-family pre-mux -> `OooRedirectArbiter` trap port | [活]；不再直接拥有 Sequencer PC 写 |
| E3 branch mispredict | `OooRedirectArbiter` branch port，携真实 `rob_idx` | [活]；赢家单点回注 fetch |
| E4 direct dispatch | `OooRedirectArbiter` direct port，使用 head-1 年龄哨兵 | [活]；严格年轻于在飞 branch/commit 源 |
| E5 CSR commit | commit-family pre-mux -> arbiter trap port | pending-system 支 [活]；head0 支默认 [休] |
| E6 drain complete | commit-family pre-mux 只保留 arch-trap/system/xRET 主路径 | branch/jump/memory owner 已删除或 tie-off，不再是当前域 B 家族 |
| E7 pending branch resolve | Sequencer 遗留排除臂；capture owner 已删、默认不可达 | [死/遗留]，不作为 current branch redirect |
| E8 pending jump resolve | `OooFrontend` tie-0 的 Sequencer 遗留臂 | [死]，不作为 current JALR redirect |
| E11 `mmu_flush` | I/D bridge 正交事务边界 | IFU 已发读进 `S_DRAIN`，A-update 写以 sticky drop 补齐 AW/W/B；D-side 独立本地 drain，见 §3 |

#### 2.1.2 2026-07-05 详细冻结表（历史底稿）

> 下表保留当时的多点施加和清/保持推导，便于追踪 assertion 来源；其中 E1/E3-E8 的
> fetch file:line 与活跃度是 pre-P4 记录，不得覆盖上面的 CURRENT overlay。

同一逻辑事件在多点施加者归并为一行，"施加点"列全部落点。汇合信号 `core_local_flush` / `mem_flush` 不列为独立源（它们是 E1/E2/E9 的 OR 漏斗，见 §2.3）。

| # | 事件族 | 产生 / 施加点（信号 @ file:line） | 触发 | 作用域 | 清什么 | 保持什么 | 活 |
|---|---|---|---|---|---|---|---|
| **E1** | **csr_trap_mem_valid**（committed 精确 trap/ECALL/IRQ/xRET，绝对最高） | 决策 `OooTrapExitEventMux.v:99-131`→`OooControlPlane.v:339` [逆向]；fetch `OooFetchPcOutstandingSequencer.v:271-276` [验证]；后端 nuke `core_trap_flush` `OooControlFlushSequencer.v:25`→`OooCoreSliceControlGate.v:39` [验证]；取指闸 `OooFrontendActionGate.v:83-88` [逆向]；**FP 簇入口** `OooIntBackend.v:2410 .flush_i(flush_i)`→`OooFpBackend` [验证] | ROB 队头提交拍判定 committed exception/ecall/mret/sret/IRQ | both | fetch: `outstanding_valid/pc/discard←0`, `next_fetch_pc←csr_trap_target`；后端: `core_trap_flush_q`(晚 1 拍)→ROB 整阵列复位 / RenameMap / FreeList / BusyTable / IntIssueQueue 全清、mem_flush、SQ flush_all 清未 committed、MIQ 弃非 DRAIN、pending late_clear 全清、stop_pending←0；**+FP 簇全清（对抗审查补，见 2.1a）：FpIssueQueue 全清 + FP rename map/freelist walk_fp 恢复 + FpArith 多周期 meta 链 (`rst\|\|flush_i`) 清 + MulDiv/FpDiv/FpSqrt 在飞清 + FpBackend DONE_FIFO killed-entry squash** | **committed store、已发 nokill AXI、arch RF、arch FPR、CSR 架构写**（mepc/mcause/mstatus 本拍已落，晚 1 拍 flush 不撤） | [活] |
| **E2** | **core_serial_flush**（head0-CSR 退休次拍脉冲，serialize Phase1） | `serial_flush_q<=head0_csr_commit_i` `OooControlCommitSequencer.v:91` [验证]→`OooCoreSliceControlGate.v:40` OR 入 `core_local_flush` [验证]；触发 `head0_csr_commit_w = OOO_CSR_QUEUE_HEAD && core_commit0_csr_w && !pending_system_csr_commit` `OooControlPlane.v:307` [验证] | head0-CSR 在 `mem_quiet`(mem_idle && mem_retire_quiet) 下退休，次拍 1 拍脉冲 | both | 后端 nuke（同 E1 后端路 + FP 簇，squash CSR 之后 younger）+ mem_flush；stop_pending 清 | committed store、已发 nokill AXI、**CSR 写**（commit 拍在前，脉冲晚 1 拍） | **[休]** |
| **E3** | **branch mispredict — untracked / ROB-walk**（后端显式误预测，架构真值） | fetch `OooFetchPcOutstandingSequencer.v:178-187` + override `:263-269` [验证]；mux `OooFetchRequestMux.v:70` [验证]；源 `OooBranchResolveRecoveryGate.v:55-66,102-105` [逆向]；后端 kill `OooDispatchBackend.v:456-465`→walk `OooRob.v:395-431` [逆向]；MIQ `OooIntBackend.v:1011-1016` [逆向]；**FP kill 入口** `OooIntBackend.v:2412-2413 .kill_valid_i(branch_resolve_mispredict_w)/.kill_rob_idx_i(branch_resolve_rob_idx_o)` [验证] | `rob_walk_mode && core_branch_resolve_valid && mispredict && !misaligned` | both | fetch: `next_fetch_pc←core_branch_resolve_next_pc`；后端 **部分 squash**：ROB 从 tail-1 反向 walk 到 `kill_rob_idx+1` 清严格更年轻 valid/done；RenameMap 定向恢复 `map[arch_rd]←old_pdest`；FreeList 回收；BusyTable/IQ squash younger；MIQ kill younger-than-boundary 的 load/probe；stop_pending←0；**+FP 簇 age-squash（对抗审查补，见 2.1a）：FpIssueQueue age-kill + FP walk_fp rename 恢复 + FpArith meta 链 `fp_meta_killed` age-kill + FpBackend DONE_FIFO 静默丢弃** | **boundary 及更老全保**（存活分支自身不 squash）；存活项 in-flight 写回被吸收；committed store；boundary-老 AXI（MIQ 只 kill younger） | [活] |
| **E4** | **direct_frontend_flush**（dispatch 拍预测重定向：BPU/RAS/JAL/投机 JALR） | `OooFrontendActionGate.v:47-53` OR [逆向]；fetch `OooFetchPcOutstandingSequencer.v:115-135` [验证]；stop 清 `OooStopPendingSequencer.v:70-77` [验证] | `direct_jal/branch0/branch1/ret0/ret1/jump_spec_fire` 之或 | **fetch only** | fetch: `outstanding` 重置、`discard_fetch_rsp`、`next_fetch_pc←direct_fire_succ`（单源 `OooFrontend.v:1562-1574`）；domain-A stop_pending←0；清投机 pending_system/pending_arch_trap 标志 | committed/SQ/AXI/CSR 全保持；**不 squash 后端已 dispatch 项**（那由 E3 ROB-walk 负责）；`branch_fallthrough_keep_outstanding` 时保 outstanding | [活] |
| **E5** | **head0_csr_commit / pending_system_csr_commit**（CSR 提交拍取指重定向） | fetch `OooFetchPcOutstandingSequencer.v:210-216` [验证]；stop 清 `:113` [验证] | `!direct_flush && (pending_system_csr_commit ‖ head0_csr_commit)` | both | fetch: `outstanding←0`, `next_fetch_pc← head0?core_commit0_next_pc:pending_system_next_pc`（CSR **写后**下条 PC）；stop_pending←0 | **CSR 写本身不撤**（消费写后 next_pc）；committed/SQ/AXI 保持 | pending_system 支 [活]；head0 支 **[休]** |
| **E6** | **drain_complete 终态**（域 B 全排空后 pending owner 重定向：arch_trap/xret/system/branch/jump/mem） | `OooFetchPcOutstandingSequencer.v:217-255` [验证]；判据 `OooPendingDrainResolveGate.v:49-54,81` [逆向] | `!csr_trap && !direct_flush && stop_pending && drain_complete`；内部 arch_trap>system>branch>jump>mem | both | fetch: `next_fetch_pc← csr_trap_target/csr_ret_target/system_next_pc/…`；对应 pending 影子解析 | 不撤任何已 commit 副作用（drain 后架构写已完成，只做 PC 重取） | [活]（arch_trap/system 支）；branch/jump 支 [半死] |
| **E7** | **pending_branch drain-resolve**（commit_resolve / match_clear，域 B） | fetch `OooFetchPcOutstandingSequencer.v:151-177`（**无 !flush 门**）[验证]；源 `OooPendingDrainResolveGate.v:65-75` [逆向]；stop `OooStopPendingSequencer.v:92-95` [验证] | `stop_pending && backend_drained && pending_branch dispatched`，分 commit_resolve / match_clear(prefetch 命中) | both | `outstanding` 按 prefetch 命中重置、`next_fetch_pc←pending_branch_next_pc / prefetch_hit_next_pc`；stop←0 | prefetch 命中的在飞取指不丢；misaligned 保 next_fetch_pc；committed/SQ/AXI/CSR | **[半死]**（domain-A 下 pending_branch 罕捕获） |
| **E8** | **pending_jump drain-resolve**（域 B JALR/nolink） | `OooFetchPcOutstandingSequencer.v:188-209` [验证]；stop `:98-107` [验证] | `!direct_flush && pending_jump_resolve_ready`；misaligned / nolink / redirect_after_dispatch | both | `next_fetch_pc← jalr_prefetch_hit_next_pc / pending_jump_resolved_target`；stop←0 | jalr prefetch 命中在飞取指；committed/SQ/AXI/CSR | **[半死]** |
| **E9** | **branch_spec_restore / checkpoint**（legacy 单级 checkpoint 恢复） | fetch `OooFetchPcOutstandingSequencer.v:137-149` [验证]；mem `OooControlFlushSequencer.v:29`→`OooMemoryRequestGate.v:60` [逆向]；MIQ `OooIntBackend.v:999` [逆向] | `!direct_flush && branch_spec_resolve_valid && !pred_match`；`rob_walk_mode` 下 `branch_spec_active≡0` | both | checkpoint rename/free 单级回滚；`checkpoint_mem_flush`→dcache/AXI；MIQ 清被 restore 项 | committed/arch RF/CSR；不整清 ROB | **[死]**（rob_walk 下失活） |
| **E10** | **trap_redirect_squash**（priv 边界 redirect 屏蔽，非清除） | `OooControlFlushSequencer.v:26-28` [逆向]；消费 `OooBranchResolveRecoveryGate.v:74-75,93-94,102-103`、`OooDirectBranchResolveGate.v:105-106` [逆向] | `priv_predictor_boundary`(trap/mret/sret 边界) 置位，sticky 到 `backend_drained` 落 | fetch（掩码） | **不清任何状态**；把 younger branch redirect 拍平为 0，保证 priv drain 期 trap/xret 目标不被 younger 覆盖 | 全部后端/前端状态 | [活] |
| **E11** | **mmu_flush**（satp / sfence.vma / **fence.i** 提交） | `OooMemoryRequestGate` 汇合后送 I/D bridge | `pending_system_satp_write_commit ‖ pending_system_sfence_commit ‖ pending_system_fencei_commit` | backend+fetch | 清 TLB/取指 cache/旧请求语义；IFU 已发读转 `S_DRAIN`，A-update write sticky-drop 后补齐 AW/W/B | committed store；全部已呈现 IFU AXI owner；D-side 由独立本地 drain 合同保持 | [活] |
| **E12** | **pending 影子 capture / clear**（dispatch 拍投机捕获 + squash 清） | capture `OooPendingDispatchArbiter.v:156-165,197-288` [逆向]；clear/squash `:190-195,313-333`→`OooPendingTrapExitSequencer.v:42-88` [逆向] | capture_base 下队头 irq/system/fault/arch_trap/exit 快照进单寄存器；清由 E1/E3/E4/drain 各源 OR | backend（影子态） | 写/清 `pending_system`、`pending_arch_trap/exit/cause/pc/tval` 单寄存器；`clear_arch_squash` 仅当 `cause==ILLEGAL_INST` 抹 residual | committed/AXI/CSR/arch RF 全不动（只动投机影子） | [活] |
| **E13** | **global flush_i（顶层核 flush 端口）** | `OooFrontend.v:1828 .rst(rst‖flush_i)`；`NpcCoreTop.v:249 .flush_i(1'b0)` [逆向] | 恒 0 | fetch | `rst‖flush_i` 退化为 rst | — | **[死]**（tied 0，建议标 dead port，见 UC-10） |

#### 2.1.3 FP / MulDiv flush+kill 簇展开（对抗审查挑战#1 补漏 —— E1/E3 的物理扇出）

> **为何补**：`branch_resolve_mispredict_w` / `flush_i` 一条线同拍扇进 IntIQ + **FpIQ + FpArith + FpBackend DONE_FIFO** + MIQ + ROB-walk + SQ boundary。原逆向仅列 Int 侧，漏掉一整个**活跃、已测（rv64uf/ud 23/23 正跑）**的 FP 多周期在飞 squash 路径。此漏项**加重**而非减轻 C7 判词——真实 flush sink 扇出比契约原画更宽。入口 `OooIntBackend.v:2410-2413` 本轮 [验证]；下列内部落点 [审查]（对抗审查亲验，本 spec 采信）。

| 落点 | 信号 @ file:line | 归属 | 语义 |
|---|---|---|---|
| FP 发射队列 | `OooFpIssueQueue` `flush_i` 全清 `:272` / `kill` age-squash `:263-267` [审查] | E1 全清 / E3 age-squash | 同 IntIQ 语义的 FP 版 |
| FP 重命名 | `OooFpBackend` walk_fp rename/freelist 恢复 `:630-631` [审查] | E3 定向恢复 | FP rename map 定向回滚（对应 E3 Int 侧 RenameMap 恢复） |
| FP 多周期算术 | `OooFpArithGate` FMA/ADD/MUL 5 级 meta 链 `rst\|\|flush_i` 清 `:1293/:1471` + `fp_meta_killed` age-kill `:1410-1414` [审查] | E1 全清 / E3 age-kill | **承重正确性**：`:44` 注释「防晚到 wb 写脏已回收 preg」 |
| 整数乘除 | `OooMulDivUnit` 在飞清 `:213` [审查] | E1/E3 | 多周期在飞 kill |
| FP 除/开方 | `OooFpDivIter :45` / `OooFpSqrtIter :47` 在飞清 [审查] | E1/E3 | 迭代器在飞 kill |
| 完成事务去重 | `OooFpBackend` DONE_FIFO killed-entry squash `df_killed_q :826-901` [审查] | E1/E3 | 防被 kill 指令的完成事务撞同号 ROB → 状态分叉（静默丢弃） |

**去重说明**：E1 吸收子系统2的 `core_trap_flush_q`、子系统3的 `late_clear`/`OooMemAxiBridge.flush_i`(trap 分量)/SQ flush_all(trap 分量)/MIQ flush(trap 分量)、子系统4的 stop 清(trap)、**+FP 簇 flush 分量**——同一 committed-trap 事件的多点施加。E3 吸收子系统2的 ROB-walk kill + 子系统1的 untracked + untracked-over-flush、**+FP 簇 kill 分量**。E12 吸收子系统3/4 的 pending capture/clear/clear_arch/clear_arch_squash/clear_exit 全家族。

### 2.2 优先级全序（高 → 低）—— ✅ P4 切消费点后：单真源（2026-07-09）

**【P4 切消费点(2026-07-09)】redirect PC 已收敛单真源**：`OooRedirectArbiter`（年龄律
`age = rob_idx − rob_head` 环形 argmin 单赢家，`OooFrontend` 内生产实例）仲裁三口：

- **trap 口** = commit 家族 pre-mux（E1 > E5 > E6，家族内序照原 Sequencer 文本序在
  `OooFrontend` 组合编码——E1/E5/E6 同为 commit-time、同 rob_idx(head, age≡0)，arbiter
  年龄律无法区分家族内成员，家族内序必须 pre-mux），rob_idx = head（age≡0 恒最老）。
- **branch 口** = E3（valid=`branch_resolve_untracked_redirect`，rob_idx = 后端 resolve
  真 rob_idx）。
- **direct 口** = E4（valid/pc = e4 构造式即 direct_fire_succ + fallthrough-capture 覆写，
  rob_idx = head−1 哨兵 age=2^W−1 恒最年轻——direct 是 dispatch 拍事件，构造上严格年轻
  于任何本拍后端 resolve 分支）。

赢家输出喂两个原汇合点：`OooFetchRequestMux`（三元链已删，`redirect_valid ? redirect_pc
: core_branch_resolve_next_pc` 兜底）与 `OooFetchPcOutstandingSequencer`（E1/E3/E4/E5/E6
六处 PC 写已删，换 always 块文本最后的唯一 arb 终写）。**同拍两源都赢由构造不可能**
（§5.4 论证兑现）。保留在 Sequencer 内的 PC 写者 = 顺序推进 + E7/E8/E9（半死/死硅排除集，
shadow 无等价证据，原样保留；arb 终写与它们同拍仅限 E1 拍，由 INV-3c 钉住）。
kill/reason/flush_backend 输出本刀 unused-sink——后端 kill/nuke 通道未动（GAP-4 后续刀）。

<details>
<summary>切换前双机制历史形态（供追溯；行号为 2026-07-05 冻结拍）</summary>

**机制 A — 取指请求 PC（`OooFetchRequestMux` 组合 first-match ternary `:66-82`）** [验证]，纯人工排序、无年龄字段：
`untracked > direct_jump_spec > direct_jal > direct_ret > direct_branch0_lane1_ret > branch_target_dispatch > branch_fallthrough > direct_branch_resolve > pending_jump > branch_spec > 顺序`

**机制 B — 状态锁存 `next_fetch_pc`（`OooFetchPcOutstandingSequencer` always 块 nonblocking 后写胜 `:93-277`）** [验证]，程序序 = 有效优先级：

| 优先级（高→低） | 源 | 行 | 门控 |
|---|---|---|---|
| 1（绝对最高） | **E1 csr_trap_mem_valid** | :271 | 无条件末位 if |
| 2 | **E3 untracked-over-flush** | :263 | `direct_flush && untracked` 时压过 E4 与整条 else-if |
| 3 | else-if 链（互斥 first-match）：E7 commit_resolve(:151, **无 flush 门**) → E7 match_clear(:159, **无 flush 门**) → E3 untracked(:178) → E8 pending_jump(:188) → E5 csr_commit(:210) → E6 drain 终态(:217) | :151-255 | 178 起 `!direct_flush`；217 加 `!csr_trap` |
| 4 | **E4 direct_frontend_flush 臂** | :115 | 被 :151/:159/:263/:271 覆盖 |
| 5 | E9 branch_spec_restore | :137 | `!direct_flush`（[死]） |
| 6（最低） | 顺序推进 | :100-112 | — |

</details>

**后端（`core_local_flush` 扁平 OR `OooCoreSliceControlGate.v:39-40`）** [验证]：`flush_i(死) ‖ core_trap_flush ‖ core_serial_flush` —— **三源无优先级区分，纯 OR**（语义上互斥/叠加均等效整清）。ROB 全清 `rst‖flush_i`(`OooRob.v:349`) 优先级最高，压过 E3 的 ROB-walk `recover`。故后端实序：**E1/E2 整清 nuke > E3 ROB-walk 部分 squash**。

**访存/AXI（`OooMemAxiBridge`）** [验证]：`nokill_busy`(committed store 落存) **压过** `cpu_kill`(mem_flush)——`:565 (flush‖drop)&&!nokill_busy_w`。即**退休 store 写必达 > flush 清在飞**（铁律②裁决面，事务层，不并入控制流仲裁）。

#### 与宪法目标序对照

目标序：`trap/exit > CSR/xRET > branch mispredict > BPU/RAS > 顺序PC`。

| 目标层 | 现状源 | 一致? |
|---|---|---|
| trap/exit | E1（:271 绝对最高） | ✅ 一致 |
| CSR/xRET | E5 head0_csr_commit(:210) / E6 xret(:217) | ⚠️ **不一致（GAP-2）**：取指 else-if 链里 E5/E6 排在 **E3 untracked(:178) 之后**，即 branch mispredict 反而**高于** CSR/xRET；且 E3 的 :263 override 压过一切非-trap。目标序要求 CSR/xRET > branch |
| branch mispredict | E3（:178/:263, mux:70） | ✅ 高于 BPU/RAS |
| BPU/RAS | E4 direct_frontend_flush(:115) | ⚠️ 除被 E3 正确压过外，还被**未加 flush 门的 E7 commit_resolve/match_clear(:151/:159)** 压过（域 B，[半死]） |
| 顺序PC | :100-112 最低 | ✅ 一致 |

**结论**：宏观骨架与目标序一致（trap 恒顶、顺序 PC 恒底、branch>BPU），但两处偏离：**(a)** CSR/xRET 与 branch mispredict 相对序被倒置（:178 先于 :210/:217），靠"队头 CSR 提交拍与 younger 分支误预测不同拍"这一**未证明的互斥不变量**兜底（GAP-2，且该不变量**只可能在 flag=1 被违反**，见 §0 幸存者偏差告警）；**(b)** 域 B 的 E7 两臂缺 `!direct_frontend_flush` 门，程序序上可覆盖 E4，仅因 domain-A 下 [半死] 而未暴露。

### 2.3 汇合点清单（§7「≥5 汇合点、无统一优先级链」实证）

> **【P4 切消费点(2026-07-09)更新】汇合点 1/2 的 redirect PC 择一已合并进
> `OooRedirectArbiter`（年龄律单赢家，`OooFrontend.u_redirect_arbiter`）**：#1 只剩
> 「赢家透传 or 默认兜底」+ valid/流控职责；#2 只剩 outstanding/discard 记账 + 保留臂
> （E7/E8/E9）+ arb 终写。GAP-1 双落点人工同步由构造消灭。#3-#7（后端 OR/AXI/pending/
> stop_pending）本刀未动，arbiter 的 kill/reason/flush_backend 输出 unused-sink 留给
> GAP-4 后端收敛刀。

| # | 汇合点 | 信号 @ file:line | 仲裁形态 |
|---|---|---|---|
| 1 | 取指请求 PC | `OooFetchRequestMux.v`（redirect_fetch_pc_o 二择） | ✅ arbiter 赢家透传（P4 收敛） |
| 2 | next_fetch_pc / outstanding | `OooFetchPcOutstandingSequencer.v`（arb 终写 + 记账臂） | ✅ arbiter 赢家单点回注（P4 收敛） |
| 3 | 后端全清 | `OooCoreSliceControlGate.v:39-40 core_local_flush` | 扁平 OR，无类型标签 |
| 4 | AXI 级 squash 漏斗 | `OooMemoryRequestGate.v:60 mem_flush = core_local_flush ‖ checkpoint_mem_flush` | OR |
| 5 | pending 出口 trap/exit 决策 | `OooTrapExitEventMux.v:53-131` | 最长 AND 门控隐式优先级 |
| 6 | stop_pending | `OooStopPendingSequencer.v:64-159` | 单 always 块隐式优先链 |
| 7 | 铁律②裁决面 | `OooMemAxiBridge.v:565 nokill_busy vs cpu_kill` | 事务层旁路 |

**CURRENT 裁决**：fetch PC 的两处人工择一已由 arbiter 单赢家取代，GAP-1/GAP-2 在
fetch 侧关闭；但全控制面仍没有统一 event 类型。后端靠扁平 OR（GAP-4）、stop_pending
靠语句顺序（GAP-7）、事务层靠各 bridge 的 drain/nokill owner（铁律②）。因此 C7 当前
应读作“fetch-PC 已收敛、其它消费面仍分散”，不能再概括为“全核无 arbiter”。

---

## 3. 三条铁律 + 现状核对（成立 / 存疑 / 违反，逐条证据）

### 铁律① committed store 不得被清 —— **✅ 成立**

- 直接执行者 `OooStoreQueue.v:143-152` [验证] `survive_r[k]=valid && (committed_q ‖ mark_hit0/1 ‖ (!flush_all && rob_dist<=boundary_dist))` —— **committed 与本拍标记恒存活**，flush_all 只清未 committed。
- `OooMemInflightQueue` 压缩保 `KIND_DRAIN`（退休 store 落存）；`kill_valid`(mispredict)
  只标 LOAD/PROBE，不动 DRAIN。**T4K 同拍全序**：若 DRAIN response pop 与 flush 同拍，pop
  已是最终消费事件，flush keep-set 必须取 `filter_DRAIN(Q_old - fired_head)`；flush 拍 push 不接收，
  kill 对 survivor DRAIN 无效。该规则避免 SQ/bridge 已释放而 MIQ 把旧 owner 压回的 ghost。
- **✅ 跨子系统纠正（GAP-5，对抗审查复核确认准）**：子系统4 称"serial/trap_flush 不碰 SQ（`sq_flush_valid=flush_i‖branch_mispredict`）"。实测 `OooExecuteBackend.v:150 .flush_i(core_local_flush_w)` [验证] → `OooIntBackend.v:2590 sq_flush_valid_w = flush_i || branch_resolve_mispredict_w` [验证] → `OooStoreQueue.flush_all_i` = **core_local_flush（含 trap/serial）**。故 trap/serial **确实进 SQ flush_all**，清 CSR-之后 younger 的未 committed store（这正是 serialize 应做的），committed 仍恒存活。**铁律①结论不变，但子系统4 陈述的机制不准**：正确性来自"committed survive + serial_flush 恒在 mem_quiet(SQ 空) 拍"，**非**"serial 被排除出 SQ 路"。此为 §4 INV-4 挂靠的构造不变量。

### 铁律② 不得 kill 已发 AXI（只能 drain 完）—— **⚠️ 全局部分满足 / IFU-AXI-G1 CLOSED**

- `OooMemAxiBridge`：nokill committed-store 对 flush/drop 免疫，`write_drain` 排空已发 beat。
- D-side 普通可取消读不再交给 xbar abort/drop；`S_WALK_R/S_READ_DATA` 在 flush 下由
  `drop_rsp_q` 保持本地 R owner 并禁止 cache/TLB fill，迟到 R 到达后才回 IDLE。D-side
  写与 A/D update 同样补齐 AW/W/B 后 drop；它没有 IFU 同名 `S_DRAIN` 状态，但语义等价。
- `OooMemoryRequestGate.v:49 mem_req_nokill_o = core_mem_req_nokill_i` [验证] **直通**不受 flush 门控。
- `OooFetchAxiBridge`：已发读响应由 `S_DRAIN` 消费，不再依赖旧 xbar read-abort 描述。
- **IFU-AXI-G1 CLOSED 2026-07-12**：进入 `S_AD_UPDATE` 即视为 AW/W 已呈现；
  `mmu_flush` 只能 sticky-drop 旧 fetch 语义，必须保持 PTE payload 与各 channel accepted 位，
  补齐缺失 AW/W 并持续 `BREADY`。完整消费 B 后，有 drop 则回 IDLE 且忽略 BRESP，无 drop
  才允许 re-walk/产生 B-error access fault。`rst > flush/drop > completion outcome > normal`
  是同拍全序；flush 与最后 channel/B 同拍时 fire 有效而 drop 后继胜出，重复 flush 幂等。
- **xbar 验收已通过**：bridge 排水消费 B 后，`AxiXbar` 释放 owner；预先排队的后一 master
  以精确 AWADDR/WDATA 到达 slave 并收到 B。bridge 22 RED、bridge+xbar 3 RED 均在同一
  用例转 GREEN；12 个独立 shadow 条件逐条负探针非真空，contract ratchet 50/50。
- AMO/LR/SC 的 nokill 分类仍应由 memory-path spec 独立冻结，不能由本节直通线推定。

### 铁律③ CSR 写 commit 拍即架构可见、flush 不撤 —— **⚠️ 结构上成立，但默认回归零覆盖（对抗审查挑战#2 降级）**

- serial_flush 是 head0_csr_commit 的**次拍脉冲**：`OooControlCommitSequencer.v:91 serial_flush_q <= head0_csr_commit_i` [验证]（寄存 → 晚 1 拍）。CSR 架构写在 commit 拍，flush 脉冲在 commit+1，**物理上不可撤**。
- E1 用 `csr_trap_target`(trap 后 PC)、E5 用 `core_commit0_next_pc`(CSR 写后下条 PC)、E6 用 drain 后架构 PC —— **全部消费写后 PC，不撤 mepc/mcause/mstatus**。
- pending 影子清（E12 `late_clear`）清的是**未架构化影子**，trap 已迁入 CSR，非撤已提交 CSR。
- **⚠️ 降级理由（对抗审查）**：铁律③的次拍时序论证**完全挂在 serial_flush，而 serial_flush 在默认 `OOO_CSR_QUEUE_HEAD=0` 下恒不触发 [休]**。用"读一条默认永不执行的代码"判"成立"= 把 code-reading 当运行证据。**结论从"成立"降级为"结构上成立、但默认绿回归对该路径零覆盖"**，flag=1 全 Linux 绿之前不得读作 settled（§0 幸存者偏差）。
- **存疑（承子系统3/4）**：需邻域确认 CSR 架构写确在 commit 拍落地于 `OooRob`/CsrFile 写路径（超本轮四子系统范围）；给定次拍时序，铁律③在本层结构性成立。

### 铁律现状裁决速览

| 铁律 | 裁决 | 证据强度 |
|---|---|---|
| ① committed store 不清 | **✅ 成立** | `OooStoreQueue.v:145-149 survive_r` [验证] + GAP-5 纠正复核 |
| ② 不 kill 已发 AXI | **⚠️ 全局部分满足** | backend nokill、I/D read/write drain 与 IFU A-update 均有 owner；AMO/LR/SC nokill 分类仍待专项核实（UC-D） |
| ③ CSR 写不撤 | **⚠️ 结构成立 / 默认回归零覆盖** | 次拍时序 [验证]，但挂 serial_flush（默认 [休]），无 flag=1 绿背书 |

---

## 4. 不变量（Invariants）—— 承重条款与历史断言草案

> **2026-07-11 状态**：本节代码块是 2026-07-05 的落地草案，不是 current RTL 的逐字
> 镜像。GAP-1/GAP-2 的 fetch-PC 形态已被 P4 arbiter 从构造上关闭；当前实际 assertion
> 名称、数量与比较点以 RTL 和 `check-contract` ratchet 为准。本节只保留不变量意图，
> 不得复制其中 pre-P4 双落点 wire 名作为新实现。

> **落地机制（对抗审查挑战#4/#5 纠正，承重）**：断言机制**必须**是可综合 `.v` 内的 `` `ifdef OOO_ASSERT ... $error(...) `endif ``，**不是** TB 侧 SV `assert`。理由 [验证]：全核回归走 Verilator 编译 `.v` + `csrc/cpu/difftest.cpp` 跑 CoreMark/Linux/difftest；`tb_*.sv` 是**逐模块单元 TB，从不包裹全核跑 CoreMark**——SV assert 装在模块 TB 里永远看不到全核 workload。真正接进全核回归的机制是 `Makefile:122 VERILATOR_FLAGS += +define+OOO_ASSERT` + `--assert`，`make check-contract`（`eval/check-contract.sh` [验证]）ratchet `$error(` 计数不回退（基线 `eval/contract-assert-baseline.txt`）。
>
> **2026-07-05 当时状态**：gate 已存在但近乎空转——全核可综合 RTL 只有 1 条
> `$error`（baseline=1）。随后 INV-1/2/3 使当时基线上调到 4；2026-07-11 current
> baseline 已为 20，见 §5.7/§8。本段只保存 ratchet 的起点历史。
>
> **每条断言写完须故意制造一次违约确认会响**（防真空通过，SPEC-TEMPLATE §4 强制），且**编码独立于 RTL 真理**（防同盲区）。

### 承重不变量清单（可编码为立即断言）

| # | 不变量 | 为何成立 | 断言落点（模块 · 信号） | flag=0 覆盖 | 挂 gate |
|---|---|---|---|---|---|
| **INV-1** | ~~GAP-1 双落点一致~~ **P4 改口径(2026-07-09)**：arbiter branch 口赢家拍，统一 redirect PC == core_branch_resolve_next_pc（branch 口 pc 源接线守卫） | 双落点已单源化，旧断言对象消失；新守卫钉 arbiter 接线不被错改（负测试 623 fire→复原 0 实证） | `OooFrontend` · redirect_reason==BRANCH_MISS 拍比较 | ✅ 有（活路径每拍走） | ✅ |
| **INV-2** | **同拍至多一个 next_fetch_pc 终态写者赢**（P4 重写：写者集缩为 {E9, E7cr/E7mc/E8 保留臂, arb 终写}） | E1/E3/E4/E5/E6 六族 PC 写已并入 arb 终写；保留臂与 arb 的文本序优先编码器护栏 | `OooFetchPcOutstandingSequencer` · 手工 win 计数 ≤1；**+INV-3c**（arb 终写压过保留臂仅限 E1 拍/不可达拍） | 部分（保留臂半死/死硅） | ✅ |
| **INV-3** | **GAP-2 互斥**：`!(csr_commit_redirect && younger_branch_mispredict_same_cycle)` | 现状是**未证明**的兜底不变量；断言把它变显式 | `OooControlPlane` / `OooFetchPcOutstandingSequencer` · csr_commit 与 younger-branch mispredict 谓词 | ❌ **仅 flag=1 exercise**（默认 head0_csr_commit≡0） | ✅（含 caveat） |
| **INV-4** | **committed store 不在任何 flush 的 clears 里** / **head0-CSR serial_flush 只从 mem-idle 退休派生** | 铁律① 靠 `survive_r` 的 committed 恒存活 + head0-CSR 退休受 `mem_idle` 门控；§10.4 已证明不能等 SQ empty，否则 younger store 死锁 | `OooStoreQueue` · `!(flush_valid && committed/mark && !survive_r)`；`OooRob` · `!(head0 CSR commit0_fire && !mem_quiet_i)`，其中 `mem_quiet_i` 当前接 `mem_idle_o` | committed 支 ✅；serial 支 ❌**仅 flag=1** | ✅（2026-07-07 已落） |
| **INV-5** | **不得 kill 已发 nokill AXI**（铁律②） | `nokill_busy` 对 `cpu_kill` 免疫 | `OooMemAxiBridge` · `!(cpu_kill_fire && nokill_q && state!=IDLE && 事务被撕裂)` | ✅ 有 | ✅ |

**覆盖 caveat（对抗审查纠正，不粉饰）**：INV-3 与 INV-4-serial 支**只在 `OOO_CSR_QUEUE_HEAD=1` 被 exercise**。默认绿回归里 serial_flush 恒不触发 → 这两条在 flag=1 真跑起来之前**仍是未被默认 workload 充分锻炼的重断言**。2026-07-07 已把 INV-4 两半接进 in-RTL `$error`，但它仍不等价于 flag=1 Linux boot 背书。

### 断言草案（in-RTL，`` `ifdef OOO_ASSERT ``，drop 进对应 `.v`）

```verilog
// INV-1 @ OooFetchPcOutstandingSequencer.v —— untracked 两落点一致
`ifdef OOO_ASSERT
  always @(posedge clk) if (!rst && untracked_redirect_valid_w)
    if (mux_untracked_pc_w !== seq263_override_pc_w)
      $error("[FLUSH-CONTRACT INV-1] untracked redirect PC 两落点不一致: mux=%h seq=%h",
             mux_untracked_pc_w, seq263_override_pc_w);
`endif

// INV-2 @ OooFetchPcOutstandingSequencer.v —— 同拍至多一源赢
`ifdef OOO_ASSERT
  always @(posedge clk) if (!rst)
    if (!$onehot0({e1_win_w, e3_win_w, e4_win_w, e5_win_w,
                   e6_win_w, e7_win_w, e8_win_w}))
      $error("[FLUSH-CONTRACT INV-2] 同拍多个 redirect 源赢: %b",
             {e1_win_w,e3_win_w,e4_win_w,e5_win_w,e6_win_w,e7_win_w,e8_win_w});
`endif

// INV-3 @ OooControlPlane.v —— CSR-commit ⊥ younger-branch-mispredict（flag=1 才 exercise）
`ifdef OOO_ASSERT
  always @(posedge clk) if (!rst)
    if (head0_csr_commit_w && younger_branch_mispredict_w)
      $error("[FLUSH-CONTRACT INV-3] CSR-commit 与 younger-branch-mispredict 同拍(未证明互斥被违反)");
`endif

// INV-4-serial @ OooRob.v —— head0 CSR 退休必须已无在飞内存事务(mem_idle)
`ifdef OOO_ASSERT
  always @(posedge clk) if (!rst)
    if (`OOO_CSR_QUEUE_HEAD && commit0_fire_w && head0_is_csr_w && !mem_quiet_i)
      $error("[FLUSH-CONTRACT INV-4] head0 CSR 在 mem_idle=0 时退休");
`endif
```

> 上列信号名（`untracked_redirect_valid_w`、`mux_untracked_pc_w`、`e{1..8}_win_w`…）为**契约要求引出的比较点**，非现有即取 —— 落地时需在对应模块 threading 出这些 wire（对抗审查纠正：这是真 plumbing，不是免费的一行 guard；仍便宜、仍零行为风险，但不是"接进现成断言框架"）。

---

## 5. 历史迁移评估与当前剩余：C-OBJ-REDIR

> **生命周期说明**：§5.1-§5.7 保存 2026-07-05“是否复活 arbiter、如何 shadow
> 切换”的评估过程。fetch-PC 切片已于 2026-07-09 完成，因此“arbiter 已删/待复活”、
> “mux+sequencer 两个 PC 生产者”和“现有系统全绿”均是历史前提，不裁决 current。
> 当前剩余仅是让后端消费 arbiter 的 kill/reason/flush_backend，并继续保持事务层独立合同。

### 5.1 关键更正（先说，因为它改设计）：年龄律，不是优先编码器

任务/宪法初稿把目标表述为「统一 redirect_request + **单一优先编码**」。但宪法本身已把「优先编码」这条路**否掉并撤回**：

- `ooo-core-architecture.md:407-416` + `design/arch/history/b2-branch-spec-redirect.md §3.2` [验证] 明确：初稿 `IMMEDIATE > DEFERRED > TRAP_COMMITTED` **固定优先级序不正确**——「会让一条更年轻的 direct 覆盖更老的 trap/branch」。**正解是年龄律**：`age = rob_idx − rob_head`（环形），同拍多源取 age 最老者胜；trap/xret 因恒在 ROB head（最老）而天然最高；`reason` 只做**同 age 平手** tiebreak（`trap > branch > direct`），**不是覆盖序**。
- 这条更正承重：**任务书里的"优先编码器"正是 GAP-2 的成因**——静态 onehot 优先编码器排错序，同拍两源里照样选错赢家。真正让「同拍两源都赢由构造不可能」成立的**不是**优先编码器，而是**单一生产者 + 年龄全序 selector**（`argmin_age`，输出恰好一个赢家）。

### 5.2 两个 grounding 事实（决定"值不值"）

1. **历史事实与当前状态**：`OooRedirectArbiter` 曾在 2026-07-03 因未接线删除；P4 已将其
   恢复并在 `OooFrontend` 生产实例化，13 例年龄律 TB 继续作为局部合同证据。
2. **年龄字段已进入 fetch winner**：branch 使用真实 `rob_idx`，commit 家族使用 head，
   direct 使用 head-1 哨兵。当前缺口不再是“取指侧无 age”，而是 arbiter 的
   `kill_younger_than/reason/flush_backend` 尚未成为后端唯一消费源。

### 5.3 可行性：改动面

**已完成切片**：`OooFetchRequestMux` 与 `OooFetchPcOutstandingSequencer` 的 redirect PC
择一已收进 `OooRedirectArbiter`；GAP-1/GAP-2 的 fetch 侧目标已关闭。

**当前剩余**：后端两套 squash（E1/E2 nuke 与 E3 walk，GAP-4）仍由分散信号消费。
后续若收敛，应使用 arbiter 已产生的 `reason + kill_younger_than + flush_backend` 表达，
同时保留 `mmu_flush` 与 AXI drain/nokill 的正交 owner。

**必须保持分离、不并入 arbiter**：E11 mmu_flush（正交）、铁律②的 AXI nokill_busy（事务层）、E10 trap_redirect_squash（年龄律会**吸收**它，最终可删但不是第一步）。

**改动面结论**：~4–6 模块（FetchRequestMux、FetchPcOutstandingSequencer、复活的 OooRedirectArbiter、SliceControlGate + direct-dispatch rob_idx 前端 plumbing）。**不是整核重写**。

### 5.4 设计草案（年龄律，非优先编码）

```text
redirect_request {
  valid
  pc                 // 各源上游已算好，arbiter 只透传
  reason             // trap | xret | serial_csr | branch_miss | jalr_miss
                     //   | sfence | fence_i | direct(bpu/ras/jal) | debug
  age                // rob_idx(环形，主判据)；commit-time 源(trap/csr)=head→age=0
  kill_younger_than  // 胜者 rob_idx；后端 squash age 比它大者
  flush_fetch        // 冲前端取指 PC
  flush_backend      // 冲后端(nuke 或 walk，由 reason 区分)
}
// 无 `priority` 三档字段——被 age(主) + reason(同 age tiebreak) 取代
// winner = argmin_age(valid sources)；age 平手按 reason 类序取一；透传胜者，不发明 flush 策略
```

**「同拍两源都赢由构造不可能」的三条构造性论证（非运行时祈祷）**：
1. **单一生产者**：pre-P4 的 mux+sequencer 两个 PC 生产者可能不一致；P4 已把 redirect
   winner 收成 arbiter 单一生产者，该失败模式在当前 fetch-PC 结构中不再可表示。
2. **全序函数**：`argmin_age` 是函数，输出基数=1。不存在"两个都赢"的可表示状态（对比静态优先编码器排错序 = GAP-2，仍可选错）。
3. **年龄律吻合现有正确直觉**：`OooFetchRequestMux.v:66-69` 注释已在手工逼近年龄律（后端已解析 mispredict 真 target 压过 younger dispatch 投机）。年龄律只是**把手工序形式化并推广**，是当前脆弱手排序的**正确泛化**。

### 5.5 判据裁决（architecture-first，两条判据诚实各过一遍）

- **判据甲「非法状态随源数组合爆炸且无单一收敛点 → 重写」**：§7 证据真——≥12 源、≥7 汇合点、GAP-1 双落点、GAP-2 靠未证明互斥、GAP-8 单寄存器靠 hold 防死锁。**支持收敛到单一 arbiter，目标正当，不回避。**
- **判据乙「边界清晰状态小 → 立即断言够」**：活路径承重不变量**少且可命名**（INV-1..5），大量 gap 落在 [死]/[半死] 域 B 臂（E7/E8/E9），重写它们对活路径**零收益**。**支持先断言。**

**裁决：不是二选一 —— 立即断言（强制、便宜、高价值）+ 增量收敛（正确、不紧急、挂触发条件）。**

- **当时不做 big-bang 重写**，三条理由：(1) 2026-07-05 汇总层把活路径记录为绿，
  因而收敛主要是维护性动作；2026-07-11 已发现 module/AM 聚合假绿，该前提不得用于
  current 验证声明；(2) 本核有控制面 big-bang 活锁判死史；(3) 收益主要来自单一 owner
  与可审计恢复语义，而不是直接性能红利。
- **但不回避 C-OBJ-REDIR**：诚实动作正是 **assert-then-converge** —— 先把隐式不变量钉成运行时断言（判据乙落地），再用 **shadow-equivalence** 逐源迁进已验证 arbiter（判据甲落地），**每步 difftest 全绿门控，旧机制不证明等价不拆**。

**「值不值」——挂触发条件，不搞美学重写**：纯为当前绿 workload，收敛不值一个 big-bang（低紧急度）；作为 **`OOO_CSR_QUEUE_HEAD=1` 全 Linux boot**（roadmap 既定，memory「翻 1 待完整 Linux boot」）+ **B-LSQ 投机 load 越分支**的**使能前置**，收敛变得**值**——这两个目标恰会往补丁总线堆源、正是**压垮 GAP-2/GAP-8 未证明互斥不变量的应力源**。故：**断言无条件现在做；arbiter 收敛作为下一次 serialize/Linux 推进的去风险前半段做，不单独立项。**

### 5.6 历史成本 / 风险评估（2026-07-05 汇总前提）

| 路径 | 工时量级 | 回归风险 | 备注 |
|---|---|---|---|
| **Big-bang 重写** | 数天~ | **高**——取指侧 prefetch/outstanding/fallthrough-keep 大量 corner，一处漏改 CoreMark 卡死，bisect 难 | b2 §2.x 控制面 big-bang 活锁判死史 |
| **Step 0 断言钉现状** | **数小时**（但非免费，见下） | **零行为风险** | 立即把 GAP-1 静默地雷变响亮断言；安全翻 `OOO_CSR_QUEUE_HEAD=1` 前置 |
| **Step 1..N shadow-equivalence 逐源迁** | 每步 ~1 天 + 全回归 | **低**——切换前先有 cycle-exact 等价证据 | 历史计划；fetch-PC 切片已按此完成，后端消费仍开放 |

**shadow-equivalence 是黄金路径**：复活 `OooRedirectArbiter` 用同批源信号驱动、**输出先不接**，每拍 `assert(arbiter.winner_pc == 活 next_fetch_pc && arbiter.flush_backend == 活 core_local_flush)`，跑全绿回归（CoreMark + sv39 boot + riscv-tests）。断言在全回归守住 = **证明** arbiter 复现当前行为，然后才切消费，切换近零风险。**断言即等价检查**，直接复用 13-test 已验证 arbiter + 现成 difftest。

### 5.7 最小第一步（若推进，唯一安全小步）

**Step 0：把 §4 承重不变量落成 in-RTL `` `ifdef OOO_ASSERT $error ``（进 check-contract ratchet），零行为改变。** 已落 INV-1/2/3、GAP-6 payload-lifetime、UC-A producer-sentinel 和 INV-4 两半；2026-07-07 当时 baseline=11，2026-07-11 文件值为 20。INV-4 的 serial 半边按 §10.4 生命周期校正为 `mem_idle`，不是旧版 `SQ empty`。

> **对抗审查对 Step 0 的三处纠正（已并入）**：(1) 机制用 in-RTL `$error` under `OOO_ASSERT`（进 check-contract），**不是** TB SV assert（跑不到全核 workload）；(2)「数小时零风险」偏乐观——baseline=1，每条是**新写的 in-RTL 组合交叉核对 + threading 比较点**，仍便宜零行为风险但非"接现成框架"；(3)「钉住现状」对 INV-3/INV-4-serial **只在 flag=1 成立**（默认 serial_flush 恒不触发）。

**做完 Step 0 再决定要不要走 Step 1** —— Step 0 本身可能给出"值不值"的答案：断言在全回归 + `OOO_CSR_QUEUE_HEAD=1` 试翻下**从不触发** ⇒ 现状不变量足够硬、收敛可继续推迟；**一翻 flag 就触发** ⇒ 收敛触发条件到了，按 §5.6 shadow 路径推进。

---

## 6. 未闭合项（backlog）—— 对抗审查缺口/存疑清单

> 忠实证据、存疑不粉饰。凡触碰下列条目的改动，回到 §2/§4 更新契约并保 check-contract 不回退。

### 6.1 契约缺口（宪法 §7 / C7「补丁总线」症状实证）

| GAP | 摘要 | 锚点 | 状态 |
|---|---|---|---|
| **GAP-1** | ~~取指 redirect 优先级无单一真源~~ **✅已根治(2026-07-09 P4 切消费点)**：redirect PC 单真源 = `OooRedirectArbiter`（`OooFrontend` 内），「untracked>direct」由年龄律构造给出（branch 真 rob_idx 恒老于 direct head−1 哨兵），双落点人工同步物理消灭；INV-1 改口径为 arbiter branch 口接线守卫（负测试 623 fire→复原 0 实证） | §2.2 单真源 | ✅ 根治 |
| **GAP-2** | ~~CSR/xRET 与 branch mispredict 相对序倒置~~ **✅年龄律修复(2026-07-09 P4)**：甲门（shadow `!branch_resolve_untracked_w`）删除，commit 家族(age0)构造性胜过 younger 分支 = 宪法目标序。**caveat**：该同拍在全部 flag=0 负载不可达（INV-3b 全程 0 fire 实证）→ 行为变化面零可观测；**flag=1(OOO_CSR_QUEUE_HEAD) 是唯一可能可达域**，INV-3/INV-3b 升格为不可达性哨兵在位，翻 flag 验证按 serialize §10.6 另立 | §2.2/§3 行为变化面 | ✅ 修复（flag=1 caveat） |
| **GAP-3** | 两个「direct redirect」定义不一致：`FrontendActionGate.direct_frontend_flush`(含 branch1/jump_spec、无 pending_jump) ≠ `FetchRequestMux.direct_redirect_fetch`(含 pending_jump*/direct_branch_resolve、无 branch1) | E4 | 待收口统一 |
| **GAP-4** | 后端 flush 扁平 OR、双 squash 机制（E1/E2 nuke vs E3 walk）无统一仲裁器 | `SliceControlGate:39-40` | reason+kill_younger_than 统一 |
| **GAP-5** | 「清/保持」靠不变量而非机制（含子系统4 陈述错，已纠）：serial/trap **确进 SQ flush_all**，committed 靠 `survive`；head0-CSR serial 退休靠 `mem_idle` 避免 abort 在飞事务，younger 未 committed store 允许在 flush_all 下被丢弃 | §3 铁律① | ✅ INV-4 已断言显式化（2026-07-07） |
| **GAP-6** | ~~wrong-path trap payload 残留~~ **✅已修(2026-07-05)**：删 OooPendingTrapExitSequencer:59-60 的 cause==EXC_ILLEGAL_INST 症状补丁, squash 无条件清 payload(对齐:55 validity)。payload-lifetime 立即断言实证 sv39 boot 修前 fire **7 次**(cause=12 INST_PAGE_FAULT residual)→修后 **0**, 全回归绿 | E12 | ✅已修+断言守住(baseline→5) |
| **GAP-7** | stop_pending 优先级 = 单 always 块语句顺序（隐式，`OooStopPendingSequencer.v:64-159`）；SET 谓词在 sequencer 与 `OooPendingDispatchArbiter` 两处人工镜像，无单一真源易漂移 | 汇合点6 | 待收口 |
| **GAP-8** | pending_system 单寄存器无队列：head0-CSR 在飞与 younger drain-CSR 共存会覆写→死锁，靠 `head0_csr_inflight` hold(`:157`) 防（**flag ON 时脆弱不变量**） | E5/E12 | 仅 flag=1 应力；serialize §10.4 修复史 |
| **GAP-9** | pending 清扁平 OR + fetch-only 无条件清：`pending_system_clear`(`:190-195`) 扁平 OR 无内部优先级；`direct_frontend_flush` **无条件**清 pending_system/pending_arch_trap，依赖"pending 只承载投机项"不变量、无显式强制 | E12 | 待显式化 |

### 6.2 死端口 / 死臂（待 doc-lifecycle 判死，保留接线但默认从不触发）

- **UC-10** E13 `global flush_i` —— `NpcCoreTop.v:249 .flush_i(1'b0)`，建议标 dead port。
- E9 checkpoint/branch_spec 全家族 —— rob_walk 下 `branch_spec_active≡0` 失活，仍接线。
- E7/E8 域 B pending_branch/jump 臂 —— domain-A 下 [半死]，活跃度对照 `rtl-ground-truth §4`。
- `SliceControlGate.core_checkpoint_quiesce/mem_issue_block`(`:34-37`)、stop_pending branch/jal/jump SET 臂(`:137-142`)、arbiter branch/jump capture —— rob_walk/domain-A 下恒 0。

### 6.3 对抗审查专项存疑（不粉饰）

- **UC-A｜整数 MulDiv/CLMUL 缺 mispredict-kill 端口**：**✅已修(2026-07-05 先证据后修)**——A1 生产者身份哨兵实证 rv64uzbc-p-clmul 撞号(CLMUL wrong-path 写复用 ROB 槽,之前被 valid_q 静默兜住)→给 MulDiv+CLMUL 补 kill 三端口+age-squash(逐字照 FP fp_meta_killed)+组合 gate resp_valid→A1 静默、全绿(baseline 5→7)。原文存:已补入 §2.1a（入口 `OooIntBackend.v:2410-2413` [验证]，内部 [审查]）。方向性提醒：此漏项**加重**而非减轻 C7 判词——真实 flush sink 扇出比原画更宽（`branch_resolve_mispredict_w` 同拍扇进 IntIQ+FpIQ+FpArith+FpBackend DONE_FIFO+MIQ+ROB-walk+SQ boundary）。契约在**低估自己要证明的乱**。
- **UC-B｜铁律③默认回归零覆盖**：见 §3 降级。挂 serial_flush（默认 [休]），flag=1 全 Linux 绿之前不得读作 settled。
- **UC-C｜系统性幸存者偏差**：头号绿证据全 flag=0；memory「flag ON real workload 全绿」**不在本契约证据集且本身不完整**。凡 serialize 类"成立" = "flag=0 不触发"，非 flag=1 背书。
- **UC-D｜铁律② AMO/LR/SC nokill 未核实**：`mem_req_nokill_o` 直通，真正 nokill 判定在上游 IntBackend AMO 通道，本轮未打开，存疑保留（§3 铁律②）。
- **UC-E｜铁律② IFU A-update partial write（✅ CLOSED 2026-07-12）**：IFU read 由
  `S_DRAIN` 自吞；A-update write 由 `ad_drop_q` 保持 payload/accepted 位、补齐 AW/W 并消费
  B 后回 IDLE。bridge+xbar 已证明 owner 释放与后一 master 进展；断言 ratchet 防回退。

### 6.4 活文档强制（对抗审查挑战#5 —— 本契约不沦为死文档的唯一结构性保证）

> `Makefile:202 check-contract → eval/check-contract.sh` 强制三条：(1) `--assert` 在场、
> (2) `+define+OOO_ASSERT` 在场、(3) 可综合 `.v` 的 `$error` 计数不回退（对照
> `eval/contract-assert-baseline.txt`）。2026-07-11 baseline 文件值为 **20**；这证明 ratchet
> 数量合同存在，不等于所有开放合同已有动态覆盖。

- **UC-11｜本契约的落盘纪律**（三条，缺一即退化为"填一次不更新"的死文档）：
  1. **锚点迁信号名**：全文 `:NNN` 行号只作追溯，权威锚点是**模块名 + 信号名 + grep 模式**（可被 check-rtl-style/check-contract 机检）。RTL 插一行行号即漂，散文契约不得充当真源。
  2. **四条承重不变量编码进 `.v`**：INV-1（`OooFetchPcOutstandingSequencer`）、INV-2（同拍 onehot）、INV-3（`OooControlPlane`）、INV-4（`OooRob` + `OooStoreQueue`）；当前 baseline **20**，ratchet 物理阻止静默删。
  3. **散文契约降级为导航索引**：真源活在"RTL 一旦背离即 fail build"的 ratcheted 断言里，本 .md 指向那些断言，**不**充当真源。这与 doc-lifecycle 协议、interface-contract-first gate 完全同构。
- **动作项（当前状态）**：Step 0 承重断言已分批落地并 ratchet 到 baseline=20；本文仍保留 GAP-3/GAP-4/GAP-7/GAP-8/GAP-9 作为后续 redirect/serialize 收敛 backlog。下一步不再是“补 INV-4”或“补 glue TB CsrFile stub”（后者已于 2026-07-07 接入 head0 commit 并验证），而是按 `serialize-at-retire-phase1.md §10.6` 补 flag ON 前置：完整 Linux boot 与 `-v-`/full-state difftest。

---

## 7. 风险与回退

- **不收敛回退点**：本契约不改 RTL，无回退需求。若后续按 §5.7 落 Step 0 断言导致误报，删 `Makefile:122` 的 `+define+OOO_ASSERT` 单行即全关（`check-contract.sh` 注释指明）。
- **历史踩坑引用**：控制面 big-bang 活锁判死史 `design/arch/history/b2-branch-spec-redirect.md §2.x`；serialize flag-ON 中间态死锁修复史 memory `serialize-at-retire-flush-lsu-obstacle` + `design/arch/serialize-at-retire-phase1.md §10.4`；F2 减 flush 类优化 kill-窗口逃逸家族 memory `f2-true-branch-prediction-landed`。

## 8. 变更记录

- **2026-07-09 P4 切消费点（GAP-1 根治 / GAP-2 年龄律修复）**：`OooRedirectArbiter` 从
  shadow 转正为 redirect PC 单真源（`OooFrontend.u_redirect_arbiter`，trap 口=E1>E5>E6
  pre-mux age0 / branch 口=E3 真 rob_idx / direct 口=E4 head−1 哨兵）。
  `OooFetchRequestMux` 三元链删除（赢家透传+默认兜底，valid/流控职责与 valid 成员集
  未动）；`OooFetchPcOutstandingSequencer` E1/E3/E4/E5/E6 六处 PC 写删除（记账全保留，
  含 :263 系 override 臂记账），换文本最后唯一 arb 终写；E7/E8/E9 保留臂原样。
  GAP-2 甲门删除 = 唯一行为变化面，全 flag=0 负载不可达（INV-3b 0 fire 实证），
  INV-3/INV-3b 升格为不可达性哨兵。glue shadow 段删除（SHADOW-EQ-PC/KILL 使命完成，
  SHADOW-EQ-NUKE 保留改名 NUKE-SRC-EQ 钉 nuke 源）；INV-1 改口径（arbiter branch 口
  守卫，负测试 tb_ooo_sv39_boot 错接 623 fire→复原 0）；INV-2 重写+INV-3c 新增；
  断言基线 21→20（−2 shadow +1 INV-3c）。后端 kill/nuke 通道零触碰（arbiter
  kill/reason/flush_backend unused-sink，GAP-4 另立刀）。切换前置刀 0 探针
  （mux E4 链 vs direct_fire_succ 两平行编码）module TB 86 + CoreMark 全程 0 fire。
  验证：module TB 86/86、lint 双变体、check-contract 20≥20、CoreMark 0xfcaf 持平。
  sim 观测层：MuxChecker 重写（单源透传守卫）、MergeChecker 退役（跨器一致性由构造
  给出）、SeqChecker INV-S1/S2 保留（target XMR 迁 u_frontend 作用域）。

- **2026-07-05 v1（冻结）**：四子系统逆向 + C-OBJ-REDIR 重写评估 + 对抗审查三份融合落盘。本轮 [验证] 复核全部承重断言（define.v flags、Sequencer:93-277、Mux:47-87、CoreSliceControlGate:39-40、StopPending:64-159、IntBackend:2410-2413/2590、ExecuteBackend:150、StoreQueue:128-152、Rob:59-64、MemAxiBridge:278-565、MemoryRequestGate:49-62、ControlCommitSequencer:91、ControlPlane:307、check-contract.sh、contract-assert-baseline.txt=1）。**纳入对抗审查五处修正**：①源表补 FP/MulDiv 簇（§2.1a）；②铁律③降级为"结构成立/默认零覆盖"（§3）；③系统性幸存者偏差告警（§0/UC-C）；④Step 0 机制由 TB SV assert 纠为 in-RTL `$error` under OOO_ASSERT（§4/§5.7）；⑤活文档强制挂 check-contract gate（§6.4）。**GAP-5 跨子系统纠正**（serial/trap 确进 SQ flush_all）经复核确认，铁律①结论不变。未改任何 RTL/配置，纯只读综合冻结。
- **历史待办状态迁移**：Step 0 断言已分批落地并在 2026-07-07 ratchet 到 baseline=11；剩余待办转为 GAP-3/GAP-4/GAP-7/GAP-8/GAP-9 的收敛与 B7 flag-ON 前置验证。
- 2026-07-05: INV-1/2/3 落成 in-RTL `ifdef OOO_ASSERT $error 立即断言（commit a336bf973），baseline 1→4；全核+177 riscv+am 全绿 0 误报，INV-2 制造违约验证能响；当时 INV-4 尚未覆盖（2026-07-07 已补 baseline 9→11）。
- 2026-07-05: **GAP-6 root-cause 修复**——删 OooPendingTrapExitSequencer squash-clear 的 cause==EXC_ILLEGAL_INST 症状补丁(payload 生命周期对齐 validity 位:55)。先加 payload-lifetime 立即断言实证 sv39 boot 现有测试 fire 7 次(cause=12 wrong-path page-fault residual)=confirmed-bug, 删补丁后 0 fire、module113+riscv177+am 全绿, baseline 4→5。
- 2026-07-05: **UC-A root-cause 修复**——整数 MulDiv/CLMUL 独缺 mispredict-kill 端口(FP 全家有)。先加 ROB 生产者身份哨兵(OooRob)实证 rv64uzbc-p-clmul wrong-path clmul 结果撞号复用槽(A1 fire)=confirmed→给 OooMulDivUnit+OooClmulUnit 补 kill_valid/kill_rob_idx/rob_head_idx 三端口+age-squash(逐字照 OooFpArithGate fp_meta_killed 严格年轻>)+组合抹 resp_valid_o+父层接 branch_resolve_mispredict_w→A1 静默、module113+riscv177+am+CoreMark(0xfcaf)全绿。baseline 5→7。
- 2026-07-06: **fence.i 引入新 flush 语义(#111 #3B 修复,commit 21252d2cb)**——fence.i 折进 system_raw→pending_system 序列化→退休拍 pending_system_fencei_commit 拉 mmu_flush(整块清取指 cache OooFetchPacketCache)+复用 E6 drain pending_system redirect(next_pc=pc+4)。E11 触发加 fencei_commit、校正其清取指 cache(非仅 DTLB,sfence 本就如此)。契约先行工作流要求触碰 flush 源更契约,此为落地收尾。
- 2026-07-07: **INV-4 两半落成 in-RTL `OOO_ASSERT` 断言，baseline 9→11**。`OooRob` 新增 head0-CSR commit 不得发生在 `mem_quiet_i=0` 的断言；注意按 Phase1 §10.4 生命周期校正，`mem_quiet_i` 当前接 `mem_idle_o`，不含 `mem_retire_quiet/sq_empty`，否则 younger-store 会形成死锁。`OooStoreQueue` 新增 flush 不得清除 committed 或同拍 mark store 的断言。验证：`make -C npc/rv64 check-contract` PASS（11/11），`make -C npc/rv64 -j2` PASS，focused `tb_ooo_store_queue tb_ooo_rob` PASS。
- 2026-07-11：现状源切到 07-11 snapshot；fetch fault 改为 drained pending trap；
  铁律②按 IFU read-drain 与 A-update write-gap 分层，裁决降为部分满足。
- 2026-07-12：关闭 IFU-AXI-G1；E11/铁律②/UC-E 改为 sticky-drop write drain 当前事实，
  并校正 D-side 已使用本地 `drop_rsp_q`、不再依赖已删除的 xbar abort/drop。全局铁律②
  仍因 UC-D 保守保持部分满足。
