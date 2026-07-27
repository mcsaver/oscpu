# V9Y local RV64 memory-owner terminal contract

## Scope

This task closes only the memory-owner phase boundary used by the pending
serialized-control path.

- Serialized kinds in scope:
  `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/IRQ`.
- Ordinary `FENCE` is a control case: it already requires complete
  `mem_idle`.
- Memory owners in scope:
  reservation, MIQ0/MIQ1, bridge0/bridge1 active and station holders,
  legacy buffer, AMO interphase, retry0/retry1, SQ ownership, the twelve
  `OooMemOwnerTerminalCollector` ingress lanes, collector pending entries,
  and the exact tracker free edge.

## Cycle contract

For every live `{kind, token, epoch}`:

1. An active holder retains the exact tracker token.
2. Its real completion or authorized cancellation emits exactly one matching
   terminal ingress, or an exact STORE release.
3. A collector transfer exists only when `ingress_accept_o` confirms the
   edge-old live tuple, kind, epoch, no duplicate, no pending collision, and
   no same-edge dequeue/re-enqueue. Raw ingress valid is not transfer
   authority.
4. The holder-death edge may transfer the token to accepted terminal ingress;
   the collector then retains that token until the tracker accepts the exact
   free.
5. A non-FENCE serialized side effect must not be generated while a live token
   remains in an active holder without a same-edge terminal transfer.
6. A token already represented only by a validated terminal ingress or
   collector-pending entry is not an active memory transaction and must not be
   confused with a missing terminal.

## Hard constraints

- Preserve all twelve terminal lanes and their exact
  `{kind, token, epoch}` identity.
- Do not suppress or merge duplicate terminal events.
- Do not weaken any RTL assertion or testbench oracle.
- Production holder census and `mem_owner_terminalized_o` must exist with
  `OOO_ASSERT` enabled or disabled; only fail-loud checks may be macro-guarded.
- Do not replace an owner/holder proof with a raw count-only assumption.
- Any behavioral RTL change requires a pre-fix RED and a compile-success
  negative RTL variant that the directed oracle rejects.
- Keep ordinary `FENCE` on the existing full-`mem_idle` contract.
- Do not claim `SERIALIZE-G1`, architecture-stable, or PPA closure from this
  sub-scope.

## Required evidence

- Twelve-lane ingress table and holder-death source for every lane.
- Edge-old to edge-new table for active holder, terminal ingress, collector
  pending, tracker live, and tracker free.
- A directed non-FENCE drain test distinguishing:
  active unterminated owner, same-edge terminal transfer, collector-pending
  only, and full idle.
- Focused collector/backend/control tests plus a compile-success negative RTL
  variant.
- Assertion-enabled and assertion-disabled tests for accepted transfer,
  wrong tuple, duplicate ingress, same-edge re-enqueue, and exact SQ release.
- Independent implementer/reviewer conclusions bound to the current design
  identity.
