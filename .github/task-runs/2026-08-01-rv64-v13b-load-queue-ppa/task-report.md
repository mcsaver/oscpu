# RV64 V13B `OooLoadQueue` PPA checkpoint

Status: DEVELOPMENT CHECKPOINT PASS / independent review PASS / evidence-quality GAP / promotion GAP

## Scope

This development checkpoint changes only the local `OooLoadQueue` combinational
lookup aggregation and edge-old free-slot priority encoding.  Ports, 16-entry
capacity, registered state, full-`ProducerId` CAM qualification, recovery and
terminal lifecycle, update priority, assertion set and clock boundaries are
unchanged.

- Baseline production design ID: `sha256:5a8333287115eb28f58e8a2712ab2e3836ebfe31e1b855fb15c6990f9acd9bd9`.
- Candidate production design ID: `sha256:29c0afe820a5ce58a1299da1faaefabce6f9038156f628e9f0f3ff3b6e23f483`.
- Baseline `OooLoadQueue.v` SHA-256: `4287aa7c746391d522bebcfceb481c01127d35f248da3cc025b5efdef15cf427`.
- Candidate `OooLoadQueue.v` SHA-256: `5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f`.

## RTL change

Ten loop-carried lookup result chains were replaced by per-entry qualified-hit
vectors and reduction ORs.  The synthesized binary network receives the same
full-PID, state, metadata, completion-bypass and pair-conflict qualifications.
The simulation branch opens a port only when the reduction is exactly `1'b1`,
preserving the old procedural-`if` behavior for unknown qualifiers.
This means an unknown-only lookup closes, while an exact hit still dominates an
unrelated unknown (`1 | X == 1`), exactly as before.  The claim therefore relies
on registered-state knownness and unique-PID invariants; it is not a claim of
global closure under arbitrary internal state corruption.

The dual allocator now derives the first and second edge-old free slots with
lowest-onehot priority encoders.  In simulation only `valid_q[i] === 1'b0`
contributes a free bit; unknown validity therefore remains occupied.  It still
cannot borrow same-edge release or recovery slots, and lane1 allocation remains
a prefix extension of a real lane0 fire.

## Functional evidence

- `tb_ooo_load_queue`: PASS with `OOO_ASSERT`; includes exact-positive lookup
  behavior, unknown-PID closure for issue/query/response/release and unknown-valid
  allocation backpressure.  Markers: `[V13B-LQ-LOOKUP-REDUCTION-X]`,
  `[V13B-LQ-ALLOC-REDUCTION-X]`, `[PASS]`, current `[RTL-DESIGN-ID]`, `[RESULT] PASS`.
- Independent stimulus-owned raw-Q model: PASS for
  `GEN_W=1/4 × OOO_ASSERT on/off`; RTL/TB pre/post hashes are identical.
- `tb_ooo_int_backend`: PASS under the current design ID with assertions enabled.
- `tb_ooo_dual_memory_sustained_issue`: PASS under the current design ID with
  assertions enabled.
- `make -C npc/rv64 check-rtl-style`: PASS.

The historical V11H 31×2 compile-success mutation cohort is not replayed in this
lightweight checkpoint.  It remains required before architecture or system
promotion; the current checkpoint instead binds the changed four-state and
allocation surfaces to direct negative oracles plus the four positive raw-Q
profiles.

## Local synthesis and timing

Both local runs use `OooLoadQueue`, 200 MHz, `flatten=1`, `share=0`, Yosys
`0.66+197`, the same icsprout55 library and no `OOO_ASSERT` definition.

| Metric | Baseline | Candidate | Delta |
| --- | ---: | ---: | ---: |
| coarse generic cells | 4,825 | 4,568 | -257 (-5.326%) |
| coarse `$mux` | 2,039 | 1,790 | -249 (-12.212%) |
| coarse wire bits | 42,037 | 41,922 | -115 (-0.274%) |
| mapped cells | 19,547 | 18,979 | -568 (-2.906%) |
| mapped area | 44,828.56 | 44,073.68 | -754.88 (-1.684%) |
| sequential area | 9,264.64 | 9,264.64 | unchanged |

Both `synth_check.txt` files report zero problems.  The local OpenSTA diagnostic
uses a 5 ns ideal clock and zero external I/O delay.  The worst path remains in
the release-ready/entry-update cone:

| Metric | Baseline | Candidate | Delta |
| --- | ---: | ---: | ---: |
| worst slack | +3.438781738 ns | +3.475173950 ns | +0.036392212 ns |
| TNS / WNS | 0 / 0 | 0 / 0 | unchanged |

This module-level diagnostic is not a full-core timing claim.

## Independent RTL review

The canonical read-only review contract
`subagent-contracts/v13b-load-queue-review.json` (SHA-256
`262aa4e044740a20ee2496d89ebb56ba8f1f4b1c40456f487a8f71c981525dbe`)
returned development checkpoint PASS.  The reviewer independently matched the
candidate RTL hash, functional markers, local synthesis/STA values and the exact
local-to-`NpcTop` coarse deltas.  It also preserved these limits:

- the four-state contract is “exact hit exists”, not blanket closure for every
  mixture of exact and unknown hit bits;
- current positive tests do not enumerate every reduction/encoder mutation;
- local baseline source binding is weaker than promotion-grade two-run evidence;
- full-core mapped/STA, 31×2 mutation replay, system and qualified power remain GAP.

The full review is retained at `evidence/final/review-result.md`.
After review, the 24 KiB baseline/candidate module snapshots and
`evidence/final/source/source-hashes.sha256` were retained to make the local
comparison independently inspectable.  This improves evidence hygiene but does
not retroactively turn the single-run local synthesis into promotion-grade
pre/post source binding, so the reviewer's evidence-quality GAP remains recorded.

## Full-core structural propagation

The candidate `NpcTop` coarse run uses 200 MHz, `flatten=0`, `share=0`,
`stop_after_coarse=1` and fail-closed status handling.  It completed in
`257.11 s`, reported zero structural problems and preserved the current design
ID before and after synthesis.

| Metric | V13A baseline | V13B candidate | Delta |
| --- | ---: | ---: | ---: |
| total generic cells | 51,386 | 51,129 | -257 |
| total `$mux` | 15,720 | 15,471 | -249 |
| total wire bits | 1,690,717 | 1,690,602 | -115 |

All three absolute deltas exactly match the local `OooLoadQueue` coarse deltas;
no parent-level structural cost transfer is observed.  The V13A baseline is the
archived final StoreQueue checkpoint; its final simulation-only four-state
overlay was proven synthesis-identical to the retained coarse baseline reports.

## Evidence and claim boundary

The retained evidence is under `evidence/final/`: focused/integration logs,
four raw-Q semantic logs, RTL style output, local coarse/mapped statistics and
checks, local OpenSTA path reports, and full-core coarse statistics/checks plus
design-ID/status records.  Regenerable `.vvp`, Verilog/RTLIL/JSON netlists and
duplicate Yosys work products are not part of the retained task-run.

This is a development checkpoint only.  It does not include current-design
full-core mapped synthesis, full-core STA, repeated synthesis, qualified power,
the complete architecture cohort or a new system run.  PPA promotion and
system-level conclusions therefore remain GAP.

## Runtime cleanup

After evidence publication, the exact V13B simulation/synthesis runtime, temporary
memory-materialization directory and post-archive agent-flow state are removed.
The reclaimed payload is `257,010,874` bytes: 8 VVP images, 18 netlists and other
reproducible Yosys/OpenSTA/workflow files.  `evidence/final/cleanup-summary.md`
records the exact targets and post-delete verification; retained logs, reports,
hashes, compact flow records and source snapshots remain under the task-run.
