# RV64 RTL Review Dispatch Log

## `axi-crossbar-naming-final-review`

- engineering object: local `AxiCrossbar` module/file/instance naming migration and AXI4 owner/handshake evidence
- task kind: `read-only-review`
- contract: `.github/task-runs/2026-07-31-rv64-axi-xbar-naming-refresh/subagent-contracts/axi-crossbar-naming-final-review.json`
- contract JSON SHA-256: `6173db733fe75509ac0038a626d2f8c2f7e2ff0ad003f592ef8d858ca893d204`
- hash boundary: the SHA-256 binds only the contract JSON
- workspace writes: none
- shell ownership: transferred to the reviewer only for the declared `rg`, `sed` and `sha256sum` read-only commands
- review state: findings addressed; superseded by versioned recheck contract
- reviewer result: `GAP`
- actionable findings:
  - active `ifu-access-current.json` and `ifu-axi-flush-drain-current.json` self-reported PASS while bound to retired `AxiXbar.v`
  - `check-rtl-style.sh` rejected every module containing the `Xbar` substring
  - the identifier-only source equivalence and focused logs lacked a fully replayable hash surface
- resolution:
  - original PASS payloads retained byte-for-byte under `evidence/historical-pre-crossbar-rename/`
  - active current paths publish explicit GAP tombstones; `IFU-AXI-G1` and `IFU-ACCESS-G1` are `STALE_EVIDENCE`
  - exact-name negative/positive self-test rejects `AxiXbar` and accepts `L2XbarAdapter`
  - `run-naming-migration-replay.sh` checks reversible source hash, retained log hashes, marker PASS values and GAP/history split

## `axi-crossbar-naming-final-review-v2`

- engineering object: read-only recheck of the three resolved findings above
- task kind: `read-only-review`
- contract: `.github/task-runs/2026-07-31-rv64-axi-xbar-naming-refresh/subagent-contracts/axi-crossbar-naming-final-review-v2.json`
- contract JSON SHA-256: `c36795f29e34862c38d9c4526da92485ebf137e1cf39933e1b500d796e75262c`
- hash boundary: the SHA-256 binds only the contract JSON
- workspace writes: none
- shell ownership: transferred to the reviewer only for the declared `rg`, `sed` and `sha256sum` read-only commands
- review state: `PASS`
- reviewer findings: none remaining within the v2 contract
- reviewer evidence:
  - exact `AxiXbar` rejection and legal `L2XbarAdapter` acceptance are hash-bound
  - active IFU evidence is GAP; historical PASS payloads remain byte-identical and hash-bound
  - `IFU-AXI-G1` and `IFU-ACCESS-G1` are fail-closed as `STALE_EVIDENCE`
  - reversible source hash, three focused AXI markers and `NpcTop.u_bus.u_crossbar` hierarchy are consistent
- remaining boundary: full IFU evidence replay, whole-architecture promotion and PPA qualification are outside this local naming PASS
- shell ownership: returned; no reviewer engineering process remains
