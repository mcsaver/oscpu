# Evidence Index: yosys-fp-arith-gate-ooc

## Context

- `context-brief.md`: DB bounded context for `OooFpArithGate` / Yosys OOC synthesis.
- `profile-resolve.md`: available agent-e2e profiles captured before final guard.

## Synthesis Evidence

- `evidence/syn-100mhz/make-syn-ooc-coarse.log.gz`
  - Full raw OOC coarse log, compressed.
- `evidence/syn-100mhz/make-syn-ooc-coarse.stats.log`
  - Concise stats: `2138 cells`, `16 $macc_v2`, `127 $alu`, `797 $mux`, `191 $sdff`, `10 $shl`.
- `evidence/syn-100mhz/make-syn-ooc-coarse.tail.log`
  - Tail for the coarse PASS.
- `evidence/syn-100mhz/make-syn-ooc-full.log.gz`
  - Full raw OOC full stdcell log, compressed.
- `evidence/syn-100mhz/make-syn-ooc-full.concise.log`
  - Concise markers showing `Found and reported 0 problems`, then ABC gate netlist extraction and `Terminated`.
- `evidence/syn-100mhz/make-syn-ooc-full.tail.log`
  - Tail for the full stdcell run.

## Functional Evidence

- `evidence/tb-ooo-fp-arith-gate.log`
  - Focused `tb_ooo_fp_arith_gate` PASS.
  - Result dir: `npc/rv64/perf/results/20260708-fp-arith-ooc/module-testbench`.
- `evidence/agent-e2e-guard-strict.log`
  - PASS: strict guard found required evidence for `agent-system`, `rv64-linux`, and `npc-dev`.

## Documentation Evidence

- `npc/rv64/design/specs/ooo-fp-arith-gate.md`
  - New active spec for current `OooFpArithGate` interface, state/timing model, invariants, synthesis status, and next tasks.
