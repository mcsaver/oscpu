# Full-core single-hart RV64 OoO cohort scope v1

> **Normative cohort ID**:
> `full-core-single-hart-rv64-dual-issue-ooo-v1`
>
> **Bound RTL design ID**:
> `sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`

This document freezes product-capability boundaries that are not inferred from
test availability.  Each exclusion has a machine-readable
`npc-rv64-architecture-debt-exclusion-v1` contract and is valid only for the
exact cohort and RTL design ID above.  A later RTL design ID must reissue and
re-audit every exclusion.

## 1. A-extension reservation cohort

The cohort contains one RV64 hart and no autonomous coherent/exclusive peer
that may write the hart's active LR/SC reservation granule.  The production
reservation is local to `OooIntBackend`: a successful LR response creates it;
SC consumption and hart-issued store/AMO write paths invalidate it.

Multi-master reservation invalidation, cache-coherent snoop transport and
exclusive AXI transactions are not product capabilities of this cohort.
Adding an autonomous writer or coherent peer changes the cohort and reopens
`A-COHERENCE-G1`; a synchronous simulation-side device maintenance pulse does
not constitute that transport.

## 2. WFI execution contract

Legal WFI is a serialized immediate-resume hint.  It waits for the existing
pending-system drain boundary, retires once, and then continues at the next
PC.  `mstatus.TW=1` below M-mode still produces the required illegal-instruction
path.

The cohort makes no promise of a clock-gated or power-gated sleep state,
minimum residency, interrupt-only wakeup, or wakeup latency.  Those true
sleep/wakeup capabilities are excluded by `WFI-G1`; the WFI instruction itself
is not removed or decoded as an illegal instruction.

## 3. SFENCE.VMA and Svinval contract

Every accepted `SFENCE.VMA`, `SINVAL.VMA`, `SFENCE.W.INVAL` and
`SFENCE.INVAL.IR` encoding enters the serialized pending-system path.  The
commit event produces the existing global `mmu_flush` boundary, so all
rs1/rs2 operand combinations conservatively invalidate the whole local
translation/fetch state.

The cohort does not promise address- or ASID-selective invalidation.  This
over-fencing behavior is the normative implementation; operand-scoped
performance behavior is excluded by `SFENCE-SINVAL-G1`.  Reserved encodings
remain illegal, and the existing TVM distinction remains unchanged.

## 4. Debug and trigger contract

The cohort does not advertise a RISC-V Debug Module, debug mode, halt/resume,
abstract command transport, or executable trigger action.  `tselect` reports
no usable trigger and `tdata1/tdata2/tcontrol` are legal WARL no-ops.
Simulation observability ports, `OOO_ASSERT` checkers and semihost EBREAK exit
are verification/platform interfaces, not architectural debug entry.

Adding a debug-mode state owner, trigger action or external halt/resume
transport changes the cohort and reopens `DEBUG-TRIGGER-G1`.

## 5. Executable evidence and non-claims

| Scope | Current executable evidence |
| --- | --- |
| local LR/SC reservation | `tb_ooo_int_backend` width/misalignment/local invalidation matrix; official `rv64ua-p-lrsc` in the 177/177 aggregate |
| immediate-resume WFI | `tb_ooo_fetch_head_classify_gate` TW matrix; `tb_ooo_priv_system` WFI retirement/interrupt/fallthrough paths |
| global SFENCE/Svinval | `tb_decode_unit` legal/reserved encoding matrix; `OooMemoryRequestGate` registered global `mmu_flush`; `tb_ooo_priv_system` SFENCE retirement |
| no architectural trigger | `tb_csr_file` tselect/tdata/tcontrol WARL no-op matrix |

The generic `arch_stable_freeze.py` cohort-exclusion validator supplies
fail-closed negative coverage for a missing rationale, stale contract hash,
wrong design ID, wrong cohort ID and candidate/ledger membership drift.

These scope decisions do not by themselves close `SERIALIZE-G1`, complete the
producer/holder census or qualify area, timing or power.  Those prerequisites
are evaluated by separate current-design receipts.  PPA promotion remains
`UNPROMOTED` until the full architecture and PPA signoff layers pass.
