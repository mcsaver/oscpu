# V13A reviewer dispatch log

## v13a-store-queue-ppa-review

- Role: independent read-only RV64 RTL/PPA reviewer.
- Contract JSON: `.github/task-runs/2026-08-01-rv64-v13a-current-ppa-baseline/subagent-contracts/v13a-store-queue-ppa-review.json`
- Contract JSON SHA-256: `855e98eb536b3b85b3c240cd4e49398102e9e223e8ad26104755a3d029b1f3ef`
- Binding: the SHA-256 above binds only the JSON contract.
- Shell ownership: transferred to the reviewer for the contract-listed read-only `rg`/`sed`/`sha256sum` commands; the main agent will not issue WSL engineering commands until ownership returns.
- Review state: returned `GAP`; shell ownership returned to the main agent.
- RTL finding: known two-state offset/mask arithmetic is equivalent, but ordinary
  `if` treated potentially participating internal SQ `X` state as false and could
  produce optimistic allow/forward in simulation.
- Contract finding: implementation serializes any IO query or older IO store
  against live older entries, while the previous spec wording suggested
  address-overlap-only behavior.
- Evidence finding: local/coarse diagnostics were valid, but full-core mapped/STA,
  fresh producer/holder graph and promotion-grade cohort remained absent.
- Resolution: pre-fix X injection preserved; final RTL uses a `SYNTHESIS`-excluded
  four-state poison overlay; TB adds X-poison/X-ignore, bank1 reverse offset and
  typed/IO cases; spec wording is aligned; promotion gaps remain explicit.

## v13a-store-queue-ppa-rereview

- Role: independent read-only RV64 RTL/PPA rereviewer.
- Contract JSON: `.github/task-runs/2026-08-01-rv64-v13a-current-ppa-baseline/subagent-contracts/v13a-store-queue-ppa-rereview.json`
- Contract JSON SHA-256: `56cb0dc7c9e531f3db47466578a0d03bead50ba3d51d25e72cb91ce6bec5dc18`
- Binding: the SHA-256 above binds only the JSON contract.
- Shell ownership: transferred for contract-listed read-only `rg`/`sed`/`sha256sum`, then explicitly returned with all commands stopped.
- Review state: `GAP`.
- Evidence finding: `opensta-top40.rpt` is sorted worst-first; its first path has
  slack `+2.380463839 ns`, while the initial final summary incorrectly copied
  the last shown path's `+2.500047445 ns`.
- Coverage finding: RTL statically ignores payload of a known-invalid SQ entry,
  but the testbench explicitly covered only known-terminal and known-younger
  payload `X` cases.
- Resolution: task report/summary corrected to `+2.380463839 ns`; TB now drives
  `valid_q[0]=0` with terminal/age/fill/type/PA/data/strb unknown and proves both
  queries remain allow, with final marker `x-ignore3`; focused simulation PASS.
- Promotion scope remains unchanged: full-core mapped/STA and promotion are GAP.

## v13a-store-queue-ppa-rereview-v2

- Role: final independent read-only RV64 RTL/PPA rereviewer.
- Contract JSON: `.github/task-runs/2026-08-01-rv64-v13a-current-ppa-baseline/subagent-contracts/v13a-store-queue-ppa-rereview-v2.json`
- Contract JSON SHA-256: `db6d958194abaa3d69efdbac1e5063013e92f72a2fcfbefffd453e8cd3a3f953`.
- Binding: the SHA-256 above binds only the JSON contract.
- Shell ownership: transferred for contract-listed read-only commands and explicitly
  returned after all WSL commands stopped.
- Review state: development checkpoint `PASS`; full-core mapped/STA and promotion `GAP`.
- Evidence finding: `opensta-top40.rpt` is worst-first and the exact worst slack is
  `+2.380463839 ns`, consistently recorded in the report and structured summary.
- Coverage finding: known-invalid payload `X` is explicitly accepted by both query lanes,
  while potentially participating valid/terminal/age/fill/PA/strb/data/head unknowns
  explicitly replay; the final log binds `x-ignore3/x-poison`, current design-id and PASS.
- Scope finding: the simulation-only overlay is excluded under `SYNTHESIS`; local ideal-clock
  STA and full-core coarse evidence do not establish full-core timing closure or promotion.
