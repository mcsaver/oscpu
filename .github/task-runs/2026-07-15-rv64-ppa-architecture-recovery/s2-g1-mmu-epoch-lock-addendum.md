# R4-S1-ID MMU epoch lock addendum

Status: **contract_frozen / implementation_RED**

This addendum replaces the earlier leaf-only, post-write vector-diff idea in
`s2-g1-exact-owner-provenance-rtl-derivation.md`.  A module that observes live
CSR values after commit and increments an epoch later is not sufficient: the
memory bridge may still be draining an accepted AXI transaction after MIQ was
flushed, and that transaction currently consumes live translation/protection
context.  Such an observer would detect the change only after the old owner had
already seen part of the new context.

The owner allocator may proceed independently.  `mmu_epoch` remains RED until
the complete pre-commit protocol below is implemented and verified.

## E0. Effective context event generation

The event is generated where the architectural candidate is known, before the
architectural state changes.  For CSR writes this is `npc/rv64/vsrc/core/CsrFile.v`,
after its actual WARL/sanitize/lock behavior has produced the candidate value.
Comparing raw CSR write data or `mmu_flush` is forbidden.

The effective data-memory context consists of:

- privilege mode;
- `satp` after implemented WARL behavior;
- data-relevant `mstatus` fields (`MXR`, `SUM`, `MPRV`, `MPP`);
- the implemented PBMTE enable derived from `menvcfg`;
- every implemented PMP configuration/address bit after PMP lock and sanitize;
- trap and xRET next privilege plus their next relevant `mstatus` values.

An actual old-to-candidate difference creates a held context-change request.
A legal SFENCE creates a held invalidate request even when the value vector is
unchanged.  A no-op write, a WARL-coerced no-op, and a write blocked by PMP lock
must not create an epoch event.

## E1. Epoch owner state machine

The epoch owner has three architectural states:

1. `UNLOCKED`: normal capture is allowed; a held effective-context/SFENCE event
   moves to `LOCKED_DRAIN`.
2. `LOCKED_DRAIN`: in the same cycle that lock is asserted, backend memory
   reservation capture and bridge request acceptance are blocked.  Younger
   killable owners are squashed, while already accepted AXI work and precise
   nonkill STORE work continue to their real drain terminals.
3. `COMMIT`: only after the complete quiet predicate is true, grant the held
   event, clear LR reservation, increment the two-bit epoch exactly once, and
   allow the corresponding CSR/trap/xRET/SFENCE architectural commit.  Return
   to `UNLOCKED` only after the grant is consumed.

The request and its candidate context remain stable throughout
`LOCKED_DRAIN`; a second event cannot overwrite it.

## E2. Complete quiet predicate

The grant predicate is a conjunction of independently registered/owned facts,
not an inference from `flush`:

- backend reservation/capture empty and no memory buffer/legacy atomic owner;
- MIQ has no surviving or killed owner awaiting a normal response/drop
  terminal;
- SQ has completed all precise STORE terminals and releases required before
  the context transition;
- bridge request station empty and bridge active FSM explicitly idle, including
  no residual AXI R/B drain;
- LR/SC reservation is cleared at grant;
- owner tracker live bitmap is empty.

`SQ empty` must not be used as an unconditional lock-side gate that also blocks
SQ drain, because that would deadlock a retired nonkill STORE.  The lock blocks
new capture but preserves the existing SQ drain path until its B/release
boundary is reached.

The bridge therefore needs an explicit registered idle/busy contract.  The
same-cycle lock must make `mem0_req_ready_o` false before a new station fire;
post-edge observation is too late.

## E3. Commit ownership

ROB/control/CSR state change is grant-gated:

- the context-changing head remains pending while `LOCKED_DRAIN` is active;
- CSR, trap and xRET architectural state must not update before epoch grant;
- SFENCE invalidation and epoch advance are the same granted event;
- a no-op effective candidate may commit without lock or epoch advance;
- the next memory capture sees the new context and the incremented epoch in the
  same architectural phase; no owner can be allocated in the transition gap.

This ordering supplies the proof that an accepted owner cannot consume a mix of
old and new translation/PMP context.  Response-side epoch equality is still
required as a fail-closed invariant, but it is not a substitute for this lock.

## E4. Implementation slices

| Slice | Owned files | Completion evidence |
|---|---|---|
| candidate old→actual comparison | `npc/rv64/vsrc/core/CsrFile.v`, focused CSR tests | satp WARL, PMP locked/sanitize, mstatus/PBMTE no-op vs effective change |
| held request and lock/grant FSM | new `npc/rv64/vsrc/memory/OooMmuEpochOwner.v` | request hold, single grant, four-step wrap, second-request exclusion |
| capture/request lock | `OooCoreTopGlue.v`, execute wrapper chain, `OooIntBackend.v`, `OooMemAxiBridge.v` | lock/request-fire same-edge negative test |
| full quiet/readback | backend, MIQ, SQ, bridge, owner tracker | active PTW/read/write residual drain and retired STORE nondeadlock tests |
| commit gating | `OooControlCommitSequencer.v`, pending-system/control integration, `CsrFile.v` | CSR/trap/xRET remain old until grant; grant commits once |

These slices are a later atomic stage.  They must not be mixed into the current
allocator/MIQ/SQ/bridge owner-tuple leaf work without their own RED evidence.

## E5. Mandatory RED→GREEN cases

- satp valid change, WARL-coerced no-op, and raw-write no-op;
- PMP unlocked effective change versus locked/sanitized no-op;
- `mstatus` relevant-bit change versus irrelevant-bit write;
- PBMTE effective change;
- trap and mret/sret next-context transition;
- SFENCE with unchanged value vector;
- request held while a bridge station, PTW read, partial write, A/D update, or B
  drain remains active;
- same-cycle lock versus backend capture and bridge station acceptance;
- retired nonkill STORE drains under lock without deadlock;
- no grant while any tracker token is live, including a flushed owner awaiting
  bridge drop terminal;
- LR reservation is cleared exactly at grant;
- four epoch advances wrap only with zero live owners;
- no response/cache/SQ side effect is accepted on an epoch mismatch.

Until all of the above pass, `mmu_epoch` is carried as an ABI field but the
epoch-completeness gate remains RED.  It must not be tied to zero, derived from
`mmu_flush`, or used to claim S1.5 completion.
