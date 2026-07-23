# v8n OOO-1 derivation

## Gate gap

The architecture contract already requires an old load miss, MUL, and DIV to
be bypassed by at least eight younger completed uops, with ROB peak at least
nine and zero retire-order violations.  The checker currently accepts any
non-empty command plus self-reported metrics for `true_ooo_long_latency`; there
is no exact proof inventory or current design-bound record.  OOO-1 is therefore
correctly RED even though the existing backend regression contains a strong
DIVU case.

## Production dataflow

The relevant issue path is:

```text
old load: dispatch -> integer IQ -> registered memory issue station
          -> request/MIQ/tracker -> withheld response -> exact memory WB

old MUL/DIV: dispatch -> integer IQ -> OooMulDivUnit owner
             -> iterative state -> exact MulDiv WB

young ALUs: two-wide dispatch -> integer IQ -> physical ALU terminals
            -> EX0/EX1 formal WB -> done ROB entries
```

`OooIntBackend.issue1_ready_w` currently depends on flush, checkpoint restore,
global issue block, and memory-response WB starvation.  It does not depend on
`miq_head_valid_w` or `muldiv_owner_valid_w`.  Thus an old outstanding memory
or MulDiv owner does not structurally impose a global younger-ALU freeze.

The ROB independently enforces architectural order: commit0 is derived only
from a done head entry, and commit1 additionally requires commit0 plus a done
second entry.  Young completion may therefore precede old completion without
young retirement preceding it.

## Existing proof and missing cases

`run_r3p1_divu_eight_younger_contract` already dispatches a real iterative
DIVU plus eight younger ALUs and observes ROB occupancy nine, an `ff` younger
WB mask, no early retirement, and nine ordered commits.  It uses raw ROB index
membership and is not yet a dedicated hash-bound OOO-1 proof.

`run_t3s_mem_issue_reservation_contract` proves one younger ALU can complete
while a memory reservation is held, but it does not prove eight younger
completions after a real accepted load request remains outstanding.  No
equivalent eight-younger iterative MUL case exists.  v8n closes those gaps and
strengthens identity to full ProducerId for all three classes.

## Intended implementation footprint

No functional RTL change is expected.  Planned changes are limited to the
focused backend test, compile-success mutator/runner, exact OOO-1 checker
command and provenance checks, checker negative tests, atomic evidence merge,
a durable Make target, and task-run/memory documentation.  If a focused case
finds a production defect, this derivation must be reopened before any gate is
promoted.
