# RV64 V9T 12-lane terminal collector report

## Result

The local `OooMemOwnerTerminalCollector` topology and bounded owner/holder
contract are PASS for production RTL design
`sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`.
The full systemd-strict guest gate remains RED because the 36,000-second host
window expired before the final three guest checks and natural poweroff.

No production `.v` equation changed in V9T. The minimal production fix remains
the V9R producer-side C0 barrier repair already present in this design:

- `OooIntBackend` closes both SQ-query retry READY paths during
  `control_full_flush_barrier_w`.
- `OooMemAxiBridge` closes `sq_query_retry_fire_w` during
  `control_full_flush_barrier_i`.
- Existing duplicate/conservation assertions in
  `OooMemOwnerTerminalCollector` remain enabled and fail-loud.

## Twelve ingress lanes

| Lane | Production terminal source |
| ---: | --- |
| 0 | bank0 response |
| 1 | bank1 response |
| 2 | bank0 active drop0 |
| 3 | bank0 station drop1 |
| 4 | bank1 active drop0 |
| 5 | bank1 station drop1 |
| 6 | reservation0 terminal |
| 7 | reservation1 terminal |
| 8 | legacy buffer terminal |
| 9 | AMO interphase terminal |
| 10 | retry0 terminal |
| 11 | retry1 terminal |

The focused testbench now drives twelve distinct `{kind,token,epoch}` tuples on
one edge with both dequeue ports stalled, checks a peak pending count of 12,
holds both registered output tuples stable, then drains all twelve tuples
exactly once.

## Verification evidence

- Focused `OOO_ASSERT`:
  `focused/assert/logs/tb_ooo_mem_owner_terminal_collector.log`,
  SHA-256
  `8b96f8bc1e002d6174be9d1d7467f9df244dc084481f0ed33a1a12cc73c0c1e9`.
- Focused release:
  `focused/release/logs/tb_ooo_mem_owner_terminal_collector.log`,
  SHA-256
  `442a7b2c4492d9a0a2d87e5e2912e83652b14d5cf0e01543ad37eafc997f3080`.
- Exact markers in both configurations:
  `[V8P-TCOLL-12INGRESS-CAPTURE] pending=12`,
  `[V8P-TCOLL-12INGRESS-DRAIN] seen=12`, and `[RESULT] PASS`.
- Canonical pair matrix:
  8/8 baselines, 15/15 pair keys, 4/4 ordinary memory pairs, 10/10 special
  exclusions, and 15/15 compile/elaborate-success verification variants
  rejected. `collector_ingress_peak=12`,
  `collector_exact_drains=12`.
- Architecture result:
  `.github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/evidence/focused/static/architecture-result.json`,
  SHA-256
  `7389debf325985e8d06636797db9cc8b474e723ca756ceef3844fe03e6236828`.
  `source.twelve_ingress_terminal_collector`,
  `metric.pair.collector_ingress_peak`, and
  `metric.pair.collector_exact_drains` are GREEN; DI-3 is GREEN.
- Hard-gate unit tests: 33/33 PASS, including an in-memory lane10/lane11 order
  swap that makes `source.twelve_ingress_terminal_collector` RED.
- Current module aggregate:
  `module-aggregate/summary.txt`, 110/110 PASS, SHA-256
  `5bb89dc4f299d5d0c6f7fb9431120ecf9f06a015a205bfde462f9fb1c744c1a2`.
  All 110 logs bind RTL design SHA
  `c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`
  and verification source SHA
  `73466b559c293cc34c9825aabca7c0f2490ce1e846f04a7d710af1e76daccca3`.
- V9R source binding still matches the live `OooIntBackend`,
  `OooMemAxiBridge` and focused testbenches. Its baseline is 2/2 PASS and the
  three compile-success variants opening bank0 READY, bank1 READY or bridge
  retry fire during C0 are rejected 3/3 by their exact assertions.

The V8P runner also no longer assumes that `architecture-current.json` contains
only four historical sibling records. It preserves an arbitrary current-design
superset, proves that pair publication changes no pre-existing record except
`pair_matrix`, requires the scoped GREEN gates, and keeps the overall RED
result fail-closed.

## System observation and remaining GAP

The historical strict run raised
`[S2-G1-TCOLL-INGRESS-DUP]` near 340 million committed instructions. The V9R
diagnostic design reached 405 million and the current V9S design reached
640,000,001 committed instructions without `S2-G1-TCOLL`, `V9Q-`, or
`Assertion failed` markers. This is bounded non-recurrence, not proof of the
historical exact ingress pair; that pair remains unknown because the historical
failure did not print per-lane tuples.

V9S rerun3 is therefore classified exactly as:

- `FAIL rc=2 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`;
- guest checks 14/17 PASS;
- missing `virtio-blk-direct-read`, `virtio-irq-growth`, and
  `dmesg-no-critical`;
- no natural poweroff, reset-syscon terminal transaction, driver PASS, or
  `GOOD TRAP`;
- no observed RTL assertion marker.

The next system action is a new uniquely labelled run with a larger host
window. Queue-head defaults must remain unchanged until a 17/17 guest result,
natural poweroff, reset-syscon completion and `GOOD TRAP` are all bound to the
same design/simulator/rootfs evidence.

## Promotion declaration

- Local 12-lane collector topology: PASS.
- V9R producer/holder C0 handoff: PASS within focused evidence.
- Current module aggregate: PASS, 110/110.
- systemd-strict guest: RED/incomplete.
- full-core architecture freeze: not established.
- formal same-condition PPA A/B: not started for this candidate.
- PPA/promotion: UNQUALIFIED.
