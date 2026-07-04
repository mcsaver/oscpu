# OooPendingControlResolveGate Spec

> ⚠️ **状态(2026-07-03 RTL 重读)**:活文件中的死通道——`OOO_ROB_WALK_MODE=1` 下输入侧 pending_branch/pending_jump 恒 0(序列器 capture 被 `!rob_walk_mode_i` 门死),除 `pending_control_ready_o` 恒 1 外,jump resolve/return/call/nolink/redirect 全输出恒 0;拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## Scope

`OooPendingControlResolveGate` owns the combinational facts for pending branch
and pending jump resolution in `OooFrontend`.

It does not store pending state, compare branch operands, update RAS/BTB state,
commit control instructions, raise traps, or update fetch PC. The parent remains
the owner of pending branch/jump registers, `CompareUnit`, RAS/BTB tables,
commit/trap state, and PC/outstanding/discard sequencing.

## Inputs

- Pending branch target, fallthrough next PC, and taken result.
- Pending jump PC, immediate, RS1 data, JALR flag, pending/dispatched state, and
  backend drained state.
- Pending jump instruction RD field and RS1 register number for call/return
  classification.
- `jump_dispatch_fire` and `commit_ready`.
- Pending branch valid for shared control readiness.

## Outputs

- Pending branch fallthrough, selected next PC, and taken-target misaligned.
- Pending jump JALR sum LSB, resolved target, target misaligned, and resolve
  ready.
- Pending JALR return/call/no-link classification plus fire/commit/redirect
  predicates.
- Shared `pending_control_ready`.

## Invariants

- Pending branch next PC is target when branch is taken, otherwise fallthrough.
- Pending branch misaligned is only true when the branch is taken and the target
  address bit 0 is set.
- Pending jump resolves only when `stop_pending && pending_jump &&
  !pending_jump_dispatched && backend_drained`.
- JALR resolved target clears bit 0 of `rs1 + imm`; JAL uses `pc + imm`.
- Pending jump misaligned reflects the resolved target bit 0, preserving the
  existing design semantics.
- Return hint requires pending JALR, `rd=x0`, `rs1=x1/x5`, `imm=0`, and non-empty
  RAS.
- Call hint requires pending jump with `rd=x1/x5`.
- No-link JALR requires pending JALR, not a return hint, and `rd=x0`.
- Return/call fire requires resolve-ready, `jump_dispatch_fire`, and not
  misaligned.
- No-link commit requires resolve-ready, not misaligned, and `commit_ready`.
- Redirect-after-dispatch requires resolve-ready, not misaligned, not no-link,
  and `jump_dispatch_fire`.
- Pending control ready is true when there is no pending branch or commit is
  ready.

## Non-Goals

- No registers or state transitions.
- No branch operand compare.
- No RAS/BTB mutation.
- No fetch request priority.
- No trap/CSR side effects.
