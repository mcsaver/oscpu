# NpcTop cache/data/FP/BPU blackbox synthesis report

## Objective

Prepare a Yosys-synthesizable `NpcTop` version before OS bring-up by moving known memory/large-state cones behind explicit macro boundaries and keeping the result inside the correctness/synthesis/timing-prep phase.

## What changed

- The RV64 `syn` entry can pass `STA_SYNTH_DFF_AUTONAME` through to the local Yosys flow.
- The local Yosys flow supports a fast machine-netlist mode where DFF/cell autoname and public-net autoname can be disabled independently.
- The task-run script uses four explicit synthesis blackbox boundaries: `OooFetchPacketCache`, `OooDataWordCache`, `OooFpArithGate`, and `OooBranchDirectionPredictor`.

Note: `/home/lyg/PA/ysyx-workbench/yosys-sta/` is ignored by the top-level repository. The local flow file is still part of this run's actual execution environment, but this is a versioning risk until the reusable flow customization is moved to a tracked wrapper/script or an explicit allowlist.

## Evidence

- Full run log: `evidence/NpcTop-cache-data-fp-bpu-blackbox-full.log.gz`.
- Earlier partial run showing the DFF/autoname bottleneck: `evidence/NpcTop-cache-data-fp-bpu-blackbox-dff-autoname-partial.log.gz`.
- Key markers: `evidence/key-markers.md`.
- Output netlist: `/home/lyg/PA/ysyx-workbench/npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v`, `62190606` bytes.
- Yosys completed in `1077.94s` with `1754.15 MB` peak memory.

## Result

This run completed successfully and produced the first current `NpcTop` 100MHz synthesis netlist under the four-boundary macro model. The full Yosys log marks all four blackbox boundaries, reports two later `check` passes with `0 problems`, skips both DFF/cell autoname and public-net autoname, and reaches `End of script`.

The early `synth_check.txt` still records seven `$print` warnings from `OooIntBackend`; this is not the final verdict because the full run later reaches clean checks. It should remain visible as a cleanup item for simulation/debug display hygiene.

## Meaning

The previous BPU blocker has been crossed by making `OooBranchDirectionPredictor` an explicit macro boundary. This is a synthesis-structure milestone, not a correctness or timing closure claim.

The reported top area, `1463302.120000`, excludes real area for `OooFetchPacketCache`, `OooDataWordCache`, `OooFpArithGate`, and `OooBranchDirectionPredictor`, all of which appear as unknown-area cells. iEDA STA should wait until these boundaries have either real liberty/LEF-style models, calibrated placeholder models, or an out-of-context replacement strategy with clear caveats.

## Correctness boundary

`debug/` and `common/` are part of the RTL/spec semantic audit layer. Any future optimization that turns predictor/cache/FP arithmetic state into a macro, SRAM, blackbox, or split OOC block must use that layer to audit invariants and observable semantics before claiming equivalence. For this task, no production RTL behavior was intentionally changed and Ubuntu/rootfs was not started.

## Next optimization

1. Move the reusable Yosys flow customization out of the ignored local tool directory or explicitly allowlist the required script/wrapper.
2. Build macro/OOC contracts for the four blackbox boundaries, starting with timing and area placeholders for STA experiments.
3. Add or connect focused semantic checks through `debug/` and `common/`: BPU predict/update/redirect facts, cache hit/fill/invalidate facts, FP metadata/fflags facts.
4. Re-run `NpcTop` synthesis with the same fast-name mode and then attempt iEDA STA only after the macro-boundary assumptions are explicit.
