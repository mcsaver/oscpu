# V14C RV64 RTL reviewer dispatch log

- task: `v14c-p0-current-review-v1`
- contract JSON: `.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/subagent-contracts/v14c-p0-current-review-v1.json`
- contract JSON SHA-256: `0f2d177336bb7f4267f4537991333db88cf429bdf26b3b41f715814f8d0e3d2f`
- binding: SHA-256 only binds the JSON contract.
- mode: `prompt-supplied-self-contained`; no tools, shell ownership, file reads, or writes.
- review scope: current-design P0 9/9 task-local binding, active-cone 5 dynamic / 2 frozen replay split, driver false-PASS isolation, 85/85 RTL counterexamples, and Section13/PPA fail-closed boundary.

- task: `v14c-p0-current-review-v2`
- contract JSON: `.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/subagent-contracts/v14c-p0-current-review-v2.json`
- contract JSON SHA-256: `ad35b88036558b417fae17f6cd748222fac3bde764873f05179248aeca383d0e`
- binding: SHA-256 only binds the JSON contract.
- mode: `prompt-supplied-self-contained`; no tools, shell ownership, file reads, or writes.
- review scope: P0 9/9 current dynamic evidence, 124/124 counterexamples, IFU replay elimination, exact Icarus warning explanation set, and Section13/PPA fail-closed boundary.

- task: `v14c-p0-current-review-v3`
- contract JSON: `.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/subagent-contracts/v14c-p0-current-review-v3.json`
- contract JSON SHA-256: `1731a6622dc65d618e8fae1aa15f0107a12f0685de2513cd5a3a86ba52983646`
- binding: SHA-256 only binds the JSON contract.
- mode: `workspace-files`; read-only `rg`/`sed`/`sha256sum`, no writes or RTL execution.
- review scope: P0 9/9 current dynamic evidence; 121 P0 negative observations = 118 RTL mutation executions + 3 oracle probes; 114 unique RTL variant fingerprints with four explicit cross-gate aliases; three adjacent MIQ-FLUSH-G1 P1 observations excluded from P0; Section13/PPA fail-closed boundary.
- reviewer result: `reviewer-result-v3.md`; `APPROVED_CURRENT_SCOPE`.
