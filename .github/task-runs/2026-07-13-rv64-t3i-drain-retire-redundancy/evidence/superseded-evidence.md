# Superseded / invalid intermediate evidence

- `evidence/core-regress/20260713-151246-2400522/` is an interrupted partial run.
  PowerShell expanded Bash variables before `bash -lc`, so its protection wrapper
  was not trustworthy. It stopped before AM/ISA and is not a functional verdict.
  The protected log hash was checked unchanged afterward. The valid replacement is
  `evidence/core-regress/20260713-152814-2442438/`.
- `evidence/red/theorem-proof.log` is an early runner output with the obsolete
  `4224` case count. It is retained as history, not used for the theorem verdict.
  The current evidence is `evidence/green/theorem-proof-final.log` (`2176` cases)
  plus the two mutation rejections in `evidence/proof-mutation/`.
- `evidence/negative-fail-open-before-runner-fix/` records the discovered Icarus
  `$error` followed by an exact PASS false-green. It is deliberately retained as
  RED evidence; the hardened result runner and final negative probes replace it.
- `evidence/opensta-script-smoke-old-t3h-review/` used the wrong H7CR liberty and
  linked 204 unknown standard-cell module types as black boxes. Current checkers
  reject it. `*-h7cl-review` directories are intermediate hierarchy-pin query
  failures. Only the two `*-final` smoke directories and the official
  `evidence/opensta-focused-{old-t3h,fresh}/` / `evidence/opensta-fresh/` outputs
  participate in the STA verdict.
