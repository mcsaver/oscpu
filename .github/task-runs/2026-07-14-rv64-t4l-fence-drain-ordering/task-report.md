# T4L ordinary FENCE drain ordering

## Scope

- Product contract: single hart, no multi-master coherence.
- Ordinary `FENCE` is a serialized ISA retirement, not a backend no-op.
- Retirement waits for ROB/IQ, synthetic owners, SQ, MIQ, memory reservation,
  and bridge-side transactions to drain.
- Existing `FENCE.I` / `SFENCE.VMA` / `WFI` / `ECALL` behavior and IRQ
  priority remain unchanged.

## Root cause

`DecodeUnit` marked ordinary `FENCE` legal but `OooFetchHeadClassifyGate`
did not include `CTRL_FENCE_BIT` in `system_raw_o`.  The instruction therefore
entered the ordinary backend path instead of the pending-system serialization
path.  A younger device read could contend with, and take priority over, an
older committed-store SQ drain request.

## Implementation

- `OooFetchHeadClassifyGate` maps legal ordinary `CTRL_FENCE_BIT` (excluding
  FENCE.I) to the existing SYSTEM/STOP facts.
- `OooPendingSystemSequencer` is reused unchanged: ordinary FENCE is a generic
  pending system instruction with no CSR/xRET/WFI/SFENCE/FENCE.I payload bit.
- `OooPendingDrainResolveGate` keeps the common ROB/IQ/synthetic/SQ predicate
  and adds `mem_idle_i` only when the pending instruction is ordinary FENCE.
  `mem_idle_i` covers MIQ, legacy pending, bridge-facing buffer, and memory
  reservation; an accepted bridge transaction remains in MIQ until response.
- The existing generic control-commit arm produces one normal ISA retirement;
  the same drain edge clears the pending owner.  `OooCommitOutputMux` was not
  edited.

## RED / GREEN evidence

| Evidence | Result |
| --- | --- |
| `evidence/red-classify/logs/tb_ooo_fetch_head_classify_gate.log` | RED: 4 failures; FENCE had neither SYSTEM nor STOP facts |
| `evidence/red-integration/logs/tb_ooo_priv_system.log` | RED: lane1 capture absent; FENCE retired before store drain; younger device read overtook drain |
| `evidence/green-unit/logs/tb_ooo_fetch_head_classify_gate.log` | PASS |
| `evidence/green-unit/logs/tb_ooo_fetch_head_pair_gate.log` | PASS |
| `evidence/green-unit/logs/tb_ooo_pending_dispatch_arbiter.log` | PASS (IRQ priority, lane1 capture, flush clear) |
| `evidence/green-unit/logs/tb_ooo_pending_drain_resolve_gate.log` | PASS (FENCE-specific full memory idle; non-FENCE predicate unchanged) |
| `evidence/green-unit/logs/tb_ooo_control_commit_sequencer.log` | PASS (one-cycle FENCE commit) |
| `evidence/green-integration/logs/tb_ooo_priv_system.log` | PASS (store probe=1, drain=1, FENCE retire=1, device read=1, no overtaking) |
| `evidence/check-rtl-style.log` | PASS |

The full `tb_ooo_priv_system` run also re-executed its existing ECALL/MRET,
IRQ/WFI, S-mode SFENCE, delegated trap and illegal-xRET modes; all remained
GREEN before the new FENCE ordering mode completed.

## Implementer / reviewer adversarial pass

- Implementer: the fix changes the real functional event equation.  It does
  not hide the defect behind decode-only no-op behavior or an assertion.
- Reviewer counterexample 1: `mem_retire_quiet=1` while MIQ/bridge/reservation
  is still occupied.  The drain-gate unit test holds `mem_idle=0` and proves
  FENCE cannot complete; a non-FENCE system event still can.
- Reviewer counterexample 2: store and FENCE share a packet.  Full-core
  integration requires lane0 store fire plus lane1 pending capture, then
  closes the request port so a broken younger device load would win when it
  reopens.  RED observed the overtake; GREEN exposes the SQ drain first.
- Reviewer counterexample 3: IRQ coincides with head/lane1 FENCE.  Focused
  arbiter tests prove IRQ remains the capture owner.  Direct flush still owns
  pending clear and cannot create a FENCE commit.
- Reviewer counterexample 4: duplicate retirement.  The integration counts
  the architectural FENCE commit and requires exactly one; the control
  sequencer test separately requires a one-cycle pulse.
- No unresolved functional conflict was found.  This focused slice does not
  claim fresh synthesis/STA or the repository-wide 200 MHz target.

## Guard status

`scripts/agent-e2e.sh --guard --guard-mode strict` was run and returned 1
because the shared worktree has 4542 changed paths spanning unrelated
`am-kernels` and `npc-dev` owners.  The suggested broad profiles are explicitly
outside this subtask's no-long-full-run scope; root must run them after the
parallel tree is consolidated.  See `evidence/strict-guard.log`.
