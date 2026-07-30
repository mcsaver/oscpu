# V10C dispatch log

## XRET lane1 marker review v1

- contract:
  `.github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/subagent-contracts/xret-lane1-marker-review-v1.json`
- contract SHA-256:
  `eab2ce44e00594705019c670d0104986400c1d404704c9c84086b41eba22e0bb`
- rendered prompt SHA-256:
  `b4ae4ca261be7b5a167186c5527d4a41ad7ca58b0ca8c3a068e61aede8e80122`
- mode: `read-only-review`, `workspace-files`, no write paths
- shell ownership: returned
- verdict: `APPROVED_FOR_CURRENT_SCOPE`

The compile-success
`lane1_arch_trap_system_exclusion_removed` RTL variant removes
`OooPendingLane1CaptureGate.system_capture_o`'s `!arch_trap_raw_w` term.
At cycle 1717, `tb_ooo_priv_system` observes simultaneous
`pending_arch_trap_q` and `pending_system_q`; the production assertion
`[V10A-SERIAL-OWNER-ONEHOT] arch and system holders overlap` terminates the
variant before the older CSR-request oracle executes. The reviewer approved
replacing only that variant's expected marker with this exact assertion marker.
Generic nonzero return codes, `[RESULT] FAIL`, line numbers, timestamps, and an
old/new-marker OR remain disallowed.

Required replay: baseline PASS, variant compile success plus exact marker FAIL,
matrix `8/8`, oracle probes `2/2`, and `source_unchanged=true`.

## V10C current-design evidence final review v1

- contract:
  `.github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/subagent-contracts/final-reviewer-v1.json`
- contract SHA-256:
  `8ae95b07d436ab20cb5b7782947570f6147b19022ee3e199a068014e0f101123`
- rendered prompt SHA-256:
  `321fbe40b3b7a96db10d5885b3e7192be00dd9e979b36958073f049b2f9966f3`
- mode: `read-only-review`, `workspace-files`, no write paths
- shell ownership: returned
- verdict: `CHANGES_REQUIRED`

The isolated reviewer must independently inspect the current RTL, exact
compile-success mutation logs, ledger/artifact hashes, attempt-6 stage order,
historical V9P binding, and the explicit arch-stable/PPA GAP boundary. It may
not run simulation, synthesis, or STA and must return the single
Windows→WSL engineering-command lane when finished.

The reviewer independently accepted attempt-6 stage order, current design-id,
`9/9` architecture gates, `15/15` closed entries, `35/35` referenced artifact
hashes, exact negative markers and the honest GAP/PPA boundary. It found one
P1 workflow blocker: the long replay runner lacked the standard explicit
evidence-complete bit and HUP/INT/TERM stage/signal/cleanup publication.

The main node corrected only the runner status framework, passed
`scripts/tests/test-task-run-status.sh`, and completed attempt 7 from the final
currentness audit with both `task-run.status=PASS` and detailed
`replay.status=PASS`. An isolated v2 rereview is required before final
publication.

## V10C status-contract final rereview v2

- contract:
  `.github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/subagent-contracts/final-reviewer-v2.json`
- contract SHA-256:
  `8b020f1ff0deceae2bbd9be2384d7d52b366afd3f5a4006cd905109ade3cfccd`
- rendered prompt SHA-256:
  `cf15b521d8f23f315a5c58ab26718db34f81560fc47d62cad097a6e4bc921d44`
- mode: `read-only-review`, `workspace-files`, no write paths
- shell ownership: returned
- verdict: `CHANGES_REQUIRED`

The isolated v2 node reviews only the v1 status-contract blocker and its
attempt-7 evidence. It may not rerun simulation, synthesis, or STA and may not
reinterpret the final-audit-only replay as a full simulation replay.

The reviewer found a deterministic initialization window: HUP/INT/TERM traps
were installed before the EXIT finalizer, so a signal in that interval could
leave standard `RUNNING` and stale detailed `PASS`. It also required INT/TERM
coverage and runner-level stale-state tests rather than only the helper HUP
case.

The runner now pre-seeds its standard status fields, installs EXIT before the
signal handlers, and atomically replaces detailed state on every exit. The
global helper test covers HUP/INT/TERM. The V10C runner test covers
`pre-init`/`active-stage` times HUP/INT/TERM (`6/6`) with stale standard and
detailed PASS inputs. Attempt 8 reran only the final currentness audit and
finished with the unchanged design-id, `15/15` closed entries, `35/35`
artifact hashes, standard PASS, and detailed PASS/complete. An isolated v3
rereview is required before final publication.

## V10C status-initialization final rereview v3

- contract:
  `.github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/subagent-contracts/final-reviewer-v3.json`
- contract SHA-256:
  `cc3eb28ed2ed60ed84e9a57bd326a0642c13da56ea8d77a0d9e31419de12903b`
- rendered prompt SHA-256:
  `3ef26f04421ab0b6c48e0e62033fc245fa16b3cbc6dc733e281a3c76efb43c50`
- mode: `read-only-review`, `workspace-files`, no write paths
- shell ownership: returned
- verdict: `APPROVED_FOR_CURRENT_SCOPE`

The isolated v3 reviewer confirmed that the runner pre-seeds its standard
status fields and installs EXIT before HUP/INT/TERM handlers. It independently
checked helper coverage for all three signals, the six runner stale-PASS
cases, the default-disabled signal test hook, the fail-closed PASS ordering,
and attempt 8's explicit final-audit-only stage boundary. It observed no
production RTL, assertion, testbench oracle, compile-success variant,
`SERIALIZE-G1`, architecture-freeze, or PPA boundary change. It ran no new RTL
simulation, synthesis, or STA and returned the single Windows→WSL command
lane without a residual process.
