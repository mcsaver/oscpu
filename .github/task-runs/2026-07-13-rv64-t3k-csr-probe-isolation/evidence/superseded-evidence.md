# T3K superseded evidence map

Only the following results are canonical for delivery:

- executable contract: `current-contract-root-final-v2/`
- reviewer-repaired focused function: workspace
  `tmp/.../functional-evidence-fix-final-v2/result/`
- final module regression: `module-final-v2/results/` (96/96)
- full core regression: `core-regress/20260713-180949-3008402/`
- synthesis audit: `synthesis/audit.json`
- netlist structure: `netlist-structure-root-final-v6/`
- old/fresh focused STA: `opensta-focused-{old-t3j,fresh-t3k}-root-final-v6/`
- OpenSTA freeze: `opensta-freeze-root-final-v6/`
- global 5ns STA: `opensta-fresh-t3k-root-final-v6/`

The following retained paths are intentionally non-canonical:

- `/tmp/ysyx-t3k-integration-focused/` failed before the common glue TB gained
  the four probe inputs; `integration-focused-final/` is the repaired run.
- `current-contract-final/`, `negative-contract-final/`, and
  `current-contract-root-rerun/` predate the final fail-closed checker fixes or
  were invalidated by scripts changing during the run. They are replaced by
  `current-contract-root-final-v2/`.
- `functional-evidence-fix/` and `functional-evidence-fix-final/` predate the
  final reachable S-mode construction and exact lane1 integration event;
  `functional-evidence-fix-final-v2/` is canonical.
- `module-current/` predates the reviewer test repair; `module-final-v2/` is
  the final 96/96 run. The production RTL did not change between the protected
  177-test core regression and that test-only repair.
- netlist/focused/freeze/global OpenSTA directories without `-v6` are retained
  as failed methodology development. They variously selected output pins as
  sources, required a nonexistent register-Q boundary, overconstrained all
  commit-to-pending paths, or produced an empty hierarchy-crossing pin set.
- `opensta-fresh-t3k-provisional-global-root/` has the same global metrics but
  is not the final frozen wrapper run; `root-final-v6/` is canonical.

The v6 proof is deliberately narrower than “all commit paths disappeared.” It
proves that the old shared main-access legality cone no longer reaches pending
trap endpoints and that a live head/state/probe legality cone replaces it.
Commit-controlled pending clear and priority paths remain architecturally
valid and are not false-pathed.
