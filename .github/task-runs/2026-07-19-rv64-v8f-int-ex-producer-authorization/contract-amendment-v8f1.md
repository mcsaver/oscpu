# v8f.1 contract amendment: completion authorization / WB credit decoupling

Status: active amendment.  This file preserves the original pre-RTL contract
and supersedes only the statements identified below; it does not widen the
v8f functional scope or promote any parent hard gate.

## Why this amendment exists

Independent static review found a counterexample to the broad statements in
`contract.md` section 3 and `rtl-derivation.md` items 3/4/7:

```text
ROB exact-open query
-> exN_wb_valid
-> shared-WB free credit
-> memory/long/FP response ready
-> issue1 ready (and conditional swapped issue0 ready)
```

Therefore the original claims that the query/PID did not enter issue or
transport ready, and that a wrong-generation EX packet released its WB lane in
the same cycle, were not simultaneously true.  The narrower statement that
ProducerId does not enter integer-IQ eligibility/onehot/select-valid remains
valid.

## Superseding behavior contract

1. `exN_pre_auth_valid = raw_stage_valid && !selective_kill && !reset &&
   !flush && !checkpoint_restore` is the physical shared-WB lane occupancy
   owner.
2. `exN_wb_valid = exN_pre_auth_valid && completion_exact_open` remains the
   sole authorization for actual WB, ROB done/data, GPR write, Busy/IntIQ/FP-IQ
   wake, registered forwarding, and public completion.
3. Shared-WB free count plus memory/MulDiv/CLMUL/FP lane grants use only
   `exN_pre_auth_valid`; `completion_exact_open`, ROB generation, valid, and
   done may not enter that availability cone.
4. A legal current/open producer is cycle-identical to v8f: pre-auth and exact
   valid are both one, so lane ownership, priority, payload, and throughput do
   not change.
5. A live but wrong-generation/done/reused EX packet is consumed without side
   effects but conservatively reserves its physical lane for that cycle.  A
   lower source may use the other free lane; when both lanes are reserved it is
   backpressured until the raw stages drain.
6. A selectively killed/flushed/restored packet has pre-auth zero and still
   releases its lane in the same cycle.  Raw `exN_valid_q` is forbidden as the
   credit owner because it would regress this recovery behavior.
7. Zero added state is permitted for this amendment.  Retaining both complete
   exact-query-to-ready decoupling and wrong-generation same-cycle replacement
   would require a different buffered/registered architecture and is outside
   this candidate.

## Machine-verifiable exit conditions

- A structural audit finds exactly nine pre-auth occupancy uses: two free-count
  operands and seven memory/MulDiv/CLMUL/FP grant guards; it finds no exact-open
  or raw EX valid in those availability regions.
- EX0 stale + EX1 free: EX0 has no completion side effects, reserves WB0, and a
  held lower source uses WB1 with intact identity/data.
- EX0 legal + EX1 stale: both lanes are reserved, the lower source observes
  ready zero, and it becomes ready with intact identity/data after the raw EX
  stages drain.
- Selective-kill age-matrix checks still prove killed EX0/EX1 release their lane
  to the older lower source in the same cycle.
- Compile-success mutations changing occupancy ownership to exact WB valid or
  raw stage valid must all reach simulation and fail on the named consequence.
- Fresh synthesis/STA must use a distinct post-fix output cohort.  Pre-fix run1
  remains diagnostic evidence and may not be relabeled as post-fix.

## Claim boundary

This amendment only repairs the integer EX/shared-WB availability topology.
Async memory, MulDiv/CLMUL/FP ProducerId authorization, branch/global lease,
generation wrap, Linux, power, physical timing, and Pareto promotion remain
RED or unqualified exactly as in the original contract.
