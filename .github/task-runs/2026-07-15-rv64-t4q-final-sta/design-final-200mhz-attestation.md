# T4Q final 200 MHz proxy attestation design

## Scope and claim boundary

This task-run is the fresh timing closure for the final functional RTL.  A
successful run may claim only:

- Yosys synthesis of the frozen `NpcTop` RTL at a 200 MHz flow parameter;
- exact `5.0 ns` global OpenSTA analysis using the recorded typical standard
  cell library and four recorded macro Liberty models;
- zero reported combinational loops, exactly 40 reported max paths, and a
  fail-closed MET decision with non-negative worst path slack;
- complete pre/post input, parameter, tool-version, synthesis, setup-member,
  and mutation-test binding.

It is a typical-library RTL/netlist timing proxy.  It is not physical-design,
clock-tree, extracted-parasitic, multi-corner, IR-drop, or silicon signoff.

## Expected fresh synthesis shape

- synthesis RTL inputs: `115`;
- mapped Verilog modules/endmodules: `117`;
- previous byte-identity comparator: the T4I netlist;
- required retained `PipeStageReg` parameterization: 147 bits;
- synthesis top: exactly one `NpcTop`.

`audit-t4q-synthesis.py` first executes the frozen T3P provenance auditor, then
repairs its historical child-first sequential-area extraction.  The T4Q parser
accepts exactly one adjacent pair:

```text
Chip area for top module '\NpcTop': AREA
  of which used for sequential elements: SEQ (PERCENT%)
```

It requires `AREA > 0`, `0 <= SEQ <= AREA`, and
`abs(100*SEQ/AREA - PERCENT) <= 0.0051` percentage points.  Child module rows,
including an earlier `AxiPlic` row, cannot supply the sequential fields.

## Setup-member closure

The post-DMA input can change both warning counts and internal endpoint names,
so T4Q does not guess them.  `run-global-opensta.sh` performs this sequence:

1. run a separate frozen OpenSTA setup-only probe;
2. normalize all three warning classes and every member into a sorted manifest;
3. cross-check missing input members against all scalar `NpcTop` inputs except
   `clk`, missing output members against scalar outputs, and require all missing
   outputs to be unconstrained endpoints;
4. bind the manifest SHA into the full exact-5ns OpenSTA completion record;
5. compare the full run member-for-member with the manifest;
6. rerun the independent probe after STA and require byte-identical probe and
   manifest output.

This closes equal-count endpoint substitution as well as count drift.

## Fail-closed target decision

`target_200mhz_met` is true only when all of the following hold:

- period is exactly `5.0 ns`;
- 40 path blocks and zero combinational loops;
- zero `VIOLATED` states;
- worst path slack is non-negative;
- WNS and TNS are positive-sign `+0.0` (OpenSTA violation-only convention);
- exact setup members match;
- synthesis binding, OpenSTA freeze, setup pre/post probe, and hardening
  mutations are all finalized PASS.

Negative zero is deliberately rejected because it can hide a rounded negative
violation in an otherwise boolean-looking zero.

## Required mutation controls

`test-t4q-evidence-hardening.py` executes before OpenSTA and is itself frozen
and hash-bound.  It requires:

| Mutation/control | Expected result |
| --- | --- |
| exact positive slack, `+0.0` WNS/TNS | accept |
| `VIOLATED` state | reject target |
| negative worst slack | reject target |
| `-0.0` WNS or TNS | reject target |
| equal-count setup member substitution | reject checker |
| child stat row before `NpcTop` | still select `NpcTop` |
| duplicate or missing `NpcTop` row | reject audit |
| sequential area greater than total area | reject audit |
| sequential percent mismatch | reject audit |

## Run contract

From repository root, after all RTL and functional regressions are frozen:

```bash
.github/task-runs/2026-07-15-rv64-t4q-final-sta/run-fresh-synthesis.sh
STA_RUN_TAG=-final STA_EXPECT_TARGET=met \
  .github/task-runs/2026-07-15-rv64-t4q-final-sta/run-global-opensta.sh
```

Both runners refuse stale output directories.  For an intentional miss audit,
set `STA_EXPECT_TARGET=miss`; `any` records evidence without making a MET/MISS
expectation, but is not sufficient for the final 200 MHz goal claim.

## Prepared-only status

The scripts in this directory were prepared without running synthesis or
OpenSTA.  Syntax and mutation self-tests are lightweight preparation evidence;
the final claim requires the fresh runner outputs and final attestation JSON.
