# V13R independent reviewer result

## Initial final review

The independent reviewer rated the directed RTL/TB behavior as bounded PASS
but the overall evidence as GAP.  The original 15-source manifest matched its
own contents and both positive logs were authentic, yet the manifest omitted
actual backend compile inputs including `OooDispatchBackend.v`,
`OooIntIssueQueue.v`, `OooIntIssueSelect8.v`, `PipeStageReg.v` and
`OooLoadQueue.v`.  The regression receipt did not cite that manifest, and the
mutation driver invalidated a later variant's old receipt only when that
variant began.

No RTL or test PASS was reclassified to hide these findings.

## Implementer correction

- Make target `print-v13r-store-b-source-closure` now expands the same two
  V13R `TB_SRCS/TB_DEPS` cohorts used by `RUN_TEST`, plus `define.v`, common
  headers, result checker and Makefile.
- The focused driver normalizes and hashes that closure together with
  `filelist.mk`, the store-B spec and all three V13R evidence drivers before
  running; it compares the same 61-source manifest after the run.
- Focused, mutation-suite and regression receipts were regenerated and all
  cite manifest SHA-256
  `75691729620e5cf093bd08accf5bd48dc59742f78dd6d75c21cdba640fe74aaa`.
- Mutation startup now removes the suite receipt and every old per-variant
  receipt plus both possible focused logs before the first variant.

## Delta review

Independent read-only review returned PASS:

- `sha256sum -c` verified all 61 manifest entries against the current
  workspace;
- the manifest includes every previously named missing dependency and the
  focused/mutation/regression drivers;
- all three final receipts reference the same manifest SHA;
- the mutation pre-clean happens before any `run_one`, while successful
  receipts remain staged and published by same-filesystem `mv`.

Final reviewer disposition:
`VERIFICATION_PASS_WITH_DECLARED_GAPS` for the V13R directed scope.  It does
not authorize system, CPI, synthesis, STA or PPA conclusions.  The reviewer
did not execute a dynamic signal-interruption campaign; pre-clean ordering is
source-bound static evidence.
