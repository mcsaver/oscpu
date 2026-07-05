---
name: coremark-mode1-spec-wrongpath
description: CoreMark mode=1(OOO_ROB_WALK_MODE)跑通的 spurious-trap corner-case 链与修复点
metadata: 
  node_type: memory
  type: project
  originSessionId: f1fe0282-f035-4090-8cb2-559e132112ac
---

RV64 OoO 核 mode=1(`OOO_ROB_WALK_MODE`,纯乱序超标量,B2 ROB-walk recovery)下 CoreMark 跑通。crcfinal=0xfcaf, `CoreMark PASS 7 Marks`, 2.618 CoreMark/MHz, 10 iterations。

**根本约束**: CoreMark(AM npc 平台)objdump 里**没有 `csrw mtvec`**, mtvec=0。任何 spurious trap → redirect 到 0x0 → 卡死/loop。所以 mode=1 的每个投机 wrong-path 误 trap 都会卡死。

**corner-case 链(每个修复揭示下一个,全是投机 wrong-path 误触发真实 trap)**:
1. **get_seed_32 computed-jump redirect 优先级** — `OooFetchRequestMux` redirect_fetch_pc 必须让 backend mispredict 真 target(`branch_resolve_untracked_redirect`)优先于投机 BTB stale target(`direct_jump_spec_fire`)。影响所有 jump-table(jr/jalr computed jump)。
2. **lane1 barrier capture cause residual** — `OooPendingDispatchArbiter` lane1 capture 让 pending_trap_cause 落到 default=`EXC_INST_ACCESS_FAULT` 并残留 → drain_trap_payload 误用。用 cause-based gate(只 gate cause==INST_ACCESS_FAULT)修, 保留真实 lane1 illegal(cause=ILLEGAL)。
3. **lbu wrong-path(untracked-over-flush)** — `OooFetchPcOutstandingSequencer`: jr a4 computed-jump 投机 fall-through 时,older backend mispredict redirect(untracked, brnext=真 target)与同拍 younger wrong-path 的 direct dispatch flush(beqz fall-through) 冲突, line 207 的 `!direct_frontend_flush_i` 把 untracked gate 掉,sequential next_fetch_pc 续取 wrong-path → 读到已 squash 指令 stale src(a5=preg32 width=0) → LOAD_ACCESS_FAULT。修复:在 csr_trap_mem 块前加 override `if (flush && untracked && !misaligned) next_fetch_pc <= core_branch_resolve_next_pc`(untracked 优先于 direct flush, 与 OooFetchRequestMux 一致)。
4. **0x800033ec head illegal residual(clear_arch_squash)** — 投机越过 printf ret(.text 段尾最后一条)取到段尾之后越界地址,head decode illegal(cause=2)经 dispatch0_arch_trap capture 进 pending_trap_pc,被 jr/ret squash 后 cause/pc 残留 → drain_trap_payload(pc!=0)误用 spurious illegal trap。修复:`OooPendingDispatchArbiter` 新增 `pending_trap_exit_clear_arch_squash_o`(来源=branch resolve/untracked/frontend flush, 不含 drain_clear/pending_system_csr_commit), `OooPendingTrapExitSequencer` 在 clear_arch_squash 且 `pending_trap_cause==EXC_ILLEGAL_INST` 时一并清 cause/pc/tval residual。cause-gate 保证 sv39 真实 page fault(12)/ecall(8)/load fault(13)不被清。

**验证(全部 mode=1 绿)**: riscv-tests 135/0(含 rv64mi-p-illegal/rv64si-*)、am-cpu-tests、CoreMark(crcfinal=0xfcaf)、sv39 boot、**module TB 113/113**。

**⑤ sv39 fetch fault gate(已解决)**: 原 mode=1 把 fetch-fault dispatch-capture gate 掉(`OooStopPendingSequencer` head_fetch_fault0 `&& !rob_walk_mode_i` + `OooPendingDispatchArbiter` trap_exit_capture_fetch_fault0 同款),本意挡 CoreMark 投机 fetch fault,却把 sv39 S-mode 真实 inst page fault(cause=12)也 gate 掉 → boot 卡死(known-issues 原 [T3])。**关键实测:CoreMark 根本没有投机 fetch fault** —— 它的投机预取停在 1GB pmem range,取到 padding → decode illegal(走 ④ clear_arch_squash),不走 fetch fault 路径;那个 gate 是为不存在的场景加的过度防御。去掉两处 `!rob_walk_mode_i`(mode=1 也 capture fetch fault)后,CoreMark 仍 PASS + sv39 boot PASS。

**⑥ de-pend 单元 TB 契约对齐(片4 引入,本轮修)**: `OooBranchResolveRecoveryGate` 加 `core_branch_resolve_mispredict_i` 后 mode=1 redirect 只在显式 mispredict 时触发(mode=0 pending/prefetch-block 契约 bypass),单元 TB 硬接 `mispredict_i(1'b0)` 测旧契约 → FAIL;`OooPendingControlResolveGate`(纯组合,无 mispredict 输入)的 TB 的 misaligned-JALR 用例本就 born-broken(JALR 强制清 LSB→永远对齐)。修法:mode-guard mode=0 契约断言(`\`ifndef OOO_ROB_WALK_MODE`)+ 加 `\`ifdef OOO_ROB_WALK_MODE` 的 mode=1 mispredict/de-pend 非空断言。注意 `OOO_ROB_WALK_MODE` 是 presence-based(始终 defined 才能编译),mode-guard 用 `\`ifdef/\`ifndef`。

调试方法见 [[single-line-cross-signal-probe-debug]](CM_TRAP_DBG 单行对照表把 commit/next_fetch_pc/redirect 信号排同一 cycle 轴定位)。
