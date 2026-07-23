# V8Y RTL derivation and holder map

## Control-flow chain

`OooIntIssueSelect8` selects the oldest eligible registered IQ entry for the
Universal terminal.  `OooIntBackend` permits control flow only on lane0 and
writes the branch result plus full ProducerId into `u_branch_resolve_stage` on
the same edge as raw EX0.  On the next cycle, `OooRob` exact-open authorization
and raw EX0 identity coherence jointly authorize the public resolve packet.

An authorized mispredict fans out in the same cycle to:

- integer/FP issue gates;
- ROB reverse-walk recovery with the branch index as the surviving boundary;
- integer/FP/long-operation completion age gates;
- memory reservation, MIQ/LQ/SQ and bridge selective-recovery identities.

The ROB walk clears only the suffix after the branch, absorbs survivor WB
during recovery, restores rename/free-list state for removed destinations and
sets tail to boundary+1.  The IQ uses the same circular age relation.

## V8Y dynamic ledger

Each control case records immutable full ProducerIds for D, A and B.  Before A
fires, A and B are both ROB-open, IQ-resident, source-ready and control-flow
eligible.  The ledger then requires:

| Owner | completion fire | retirement fire | post-recovery holder |
| --- | ---: | ---: | ---: |
| D, older survivor | 1 | 1 | 0 after retirement |
| A, recovery boundary | 1 | 1 | 0 after retirement |
| B, younger wrong path | 0 | 0 | 0 immediately after recovery |

Linear indices are D0/A1/B2.  Seven retired dual-ALU packets advance the empty
ROB to head=tail=14 before the wrapped case, producing D14/A15/B0 without
changing the ledger.

## Memory drain witness

The integrated V8X subcase places owner A in the active bridge FSM and owner B
in its registered station.  Exactly one shared AR for A fires.  Recovery marks
both identities killed; A drains a late R into one exact drop/pop/terminal,
then B promotes and terminates before any target AR.  Final bridge, MIQ,
tracker and terminal counts are zero.

