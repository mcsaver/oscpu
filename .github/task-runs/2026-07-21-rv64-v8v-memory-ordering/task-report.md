# RV64 v8v OOO-3 memory-ordering task report

## Status

- Slice result: `OOO-3=GREEN` for the hash-bound memory-ordering scope.
- Live RTL design-id:
  `sha256:ba9666a7a612bfcb7a07ce58f7953712d4c050eed24da00824b61b74af5e1d27`.
- Architecture vector: `DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3=GREEN`;
  `DI-1/DI-2/OOO-4/overall=RED`.
- PPA: `UNQUALIFIED`; `promotion_eligible=false`.
- Long-running complete-OoO/PPA objective remains active.

`contract.md` and `rtl-derivation.md` are frozen pre-run proof inputs.  This
report records the post-run status so those SHA-bound inputs need not be edited
after publication.

## Implementer result

- Added one shared 16-entry retire-resident `OooLoadQueue`, full-`ProducerId`
  ownership, final-PA SQ disposition, exact completion/terminal/retire lifecycle
  and backend-wide checkpoint request/hold/apply behavior.
- Preserved physical store/AMO ownership through B, formal WB and exact lane0
  retirement; accepted apply waits for physical-write lease, SQ active-write
  state and DRAIN owner closure.
- Bound `OooCoreSliceControlGate`, MIQ and owner tracker into the OOO-3 source
  and provenance inventory, with an integration oracle that keeps raw restore
  out of local/memory flush until accepted apply.
- Generalized the F2 parent-mutation audit: all 18 mutations are rebuilt from
  live RTL, must change bytes and must reproduce the same-name summary SHA-256.
- Added four focused unit cases for a real owner-token cut, byte-identical cut,
  missing anchor and ambiguous anchor set.

## Verification evidence

- Canonical command: `make -C npc/rv64 check-memory-ordering`.
- Fresh run: `v8v-ooo3-20260721T025332Z-1584072`.
- Result:
  `evidence/final-run/result.json` reports 11/11 OOO-3 metrics and 9/9
  compile-success dynamically detected LQ mutations.
- Parent mutation audit:
  `npc/rv64/eval/ppa/evidence/memory-ordering.log` reports
  `f2_compile_success_mutations=18` and
  `f2_reconstructed_non_noop_mutations=18`.
- Architecture unit suite: 37 tests PASS, including four reconstruction
  positive/negative cases.
- Source/provenance: 46 canonical source files and 61 provenance files;
  pre/post source manifests are byte-identical.
- Aggregate: OOO-3 GREEN, DI-1/DI-2/OOO-4 and overall RED.

## Reviewer result

- v1-v4.1 found and drove closure of LQ lifecycle, recovery-domain split,
  irrevocable physical-write ownership and ControlGate evidence-sensitivity
  gaps.
- v5 accepted the RTL protocol but suspected an empty parent mutation.  Direct
  byte comparison disproved that specific premise; the broader trust gap was
  nevertheless converted into an all-18 reconstruction gate.
- Versioned v6 frozen-material review passed byte non-identity, mutation-set
  closure and SHA reconstruction.  It explicitly did not replace compile or
  dynamic-oracle evidence; the canonical runner supplies those properties.

## AI workflow correction

- `rv64-hardware-professional` now starts with a positive local RV64 RTL scope
  and requires ambiguous terms to carry object, level, scope and engineering
  purpose.
- The rule does not scan a keyword blacklist, rewrite RTL identifiers or
  reduce tools, shell, context, counterexample search or reasoning exits.
- Generator audit, 25 contract self-tests, 20 CLI self-tests and a real
  versioned no-shell reviewer dispatch passed.
- `agent-system` completed 10/10 nodes in
  `.github/task-runs/2026-07-21-rv64-hardware-professional-task-contract-revtag-v10b/`.
  Earlier v10/v10a blocked runs are retained as evidence of the generated
  bytecode-cache and stale wording-hook corrections.

## Remaining RED/UNKNOWN scope

- DI-1 frontend initiation interval and DI-2 width continuity remain RED.
- OOO-4 global speculation/recovery remains RED beyond this OOO-3 slice.
- Full-core architecture is not arch-stable; formal PPA A/B, qualified Power,
  physical signoff and Pareto promotion remain unavailable.
- Directed simulations and mutation gates are not an exhaustive formal proof.

## Next step

Continue architecture closure at DI-1/DI-2 and OOO-4.  If a PPA probe is run
before full-core arch-stable, label it diagnostic and
`promotion_eligible=false`.
