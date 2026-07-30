# V11H implementation report

## Architecture delta

`OooLoadQueue.v` adds one bit of exact terminal history per entry:
`terminal_seen_q[]`.

- allocation/reset/release/clear reset the bit;
- exact normal terminal sets it while preserving ROB-retire residency;
- issue, query and response no longer reopen physical work after terminal;
- recovery creates a killed tombstone only for launched, incomplete entries
  that have not already seen the exact terminal;
- a terminal-seen recovery target clears directly;
- a second exact normal terminal is rejected by
  `[V11H-LQ-DUP-TERMINAL]`.
- every live raw entry now asserts that the complete `producer_id_q[]` is
  known; the directed unknown-generation probe is rejected by
  `[V11H-LQ-PID-KNOWN]`.

No terminal event is deduplicated or discarded to manufacture PASS, and no
existing assertion was weakened.

## Evidence result

- Pre-fix discriminator: compile rc=0, simulation rc=1,
  `count=1/live=1/killed=1`.
- Post-fix attempt-4 matrix: 4/4 positive profiles PASS at GEN_W=1/4 with
  assertions on/off; one assertion-enabled raw-Q PID knownness probe is
  rejected at the intended RTL marker.
- Compile-success RTL variants: 31 cases × 2 generation widths; all 62 are
  rejected by the assertion-independent raw-Q oracle.
- Current `NpcTop` instance graph v2 at design-id
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`:
  15 holder modules, 17 holder instances and 194 reachable instances; fresh
  Yosys output is byte-identical to canonical.
- Original focused attempt-4 remains FAIL at `semantic-ledger-unit` after all
  RTL simulations completed because the new checker omitted one local Python
  variable binding. Independent frozen-input checker replay is PASS with no
  RTL simulation reexecution: replay builder 5/5, LoadQueue evidence checker
  10/10 and semantic ledger 24/24.
- Attempt-4 scope uses exact fields:
  `required_for_local_closure=false`,
  `required_before_system_promotion=true`, `run=false`; omission or weakening
  is rejected by negative tests.
- Ordinary regression: `tb_ooo_load_queue` and parent
  `tb_ooo_int_backend` attempt-3 PASS with `OOO_ASSERT`, GEN_W=4 and neither
  duplicate-terminal nor raw-Q-knownness assertion marker.
- Semantic ledger: 11 PASS / 33 GAP / 44. Whole architecture remains RED.
- Independent versioned final review v3: bounded APPROVE for
  `load-queue-producers`, blocker=0. It does not close terminal
  collector/tracker end-to-end behavior, the full system, architecture or PPA.

## Promotion boundary

This is a production core semantic change. A new full-system run is therefore
required before system-level promotion. It was not automatically started in
this focused round. PPA remains prohibited while architecture is RED.
