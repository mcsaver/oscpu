# V10G dispatch log

## 2026-07-28 initial state

- Local RV64 RTL source-set is
  `sha256:5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a`.
- The previously replayed architecture ledger and records are bound to
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`.
- Exact source-map comparison found one changed input:
  `npc/rv64/vsrc/sim/NpcSimTop.sv`. The source edit marks
  `debug_ooo_flags_o[63]` as a configuration-valid simulation diagnostic bit.
- Frozen A3/A4 evidence reports `actual_elaborated_rtl_changed=false`:
  51 generated Verilator files have 50 exact matches and one source-line-only
  normalized match; eight device-model objects match. A3 original checker FAIL
  and A4 TERM interruption remain immutable.
- `SERIALIZE-G1` is the sole active `P1 OPEN` architecture entry. PPA and
  historical-defect backfill remain blocked.

## 2026-07-28 current-design closure

- Product RTL defaults now select `OOO_CSR_QUEUE_HEAD=1`; the canonical live
  design-id is
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`.
- Queue-head CSR C0/C1/C2 evidence passed in assertion and release builds.
  Two compile-success C2 RTL versions were dynamically rejected. The
  product-default SYSTEM matrix passed 3/3 baselines and rejected 14/14
  compile-success RTL versions.
- The product-default current-design replay completed 26/26 stages with
  module 113/113, official 177/177, AM 59/59, DiffTest mismatch 0 and both
  benchmark semantic markers.
- Independent final review v2 returned
  `APPROVED_FOR_CURRENT_SCOPE`. `SERIALIZE-G1` is therefore CLOSED for the
  Phase1 split-domain contract only; later serialization phases remain open.
- A3 remains an immutable published FAIL. Its execution, DUT terminal chain,
  binding and raw artifacts are complete/current; its prior dmesg oracle is
  invalid. No full system rerun was required.

## 2026-07-28 checker/currentness maintenance

- Historical-defect backfill is now a schema-checked freeze gate. Two VD1
  items remain blocking; the selected item is
  `HIST-SER-QH-YOUNGER-STORE-CYCLE`.
- Nine closed-debt checkers were replayed from frozen module/program logs and
  compile-success RTL-version summaries. Result: 9/9 PASS, all replay inputs
  unchanged, no module or system simulation rerun.
- XRET negative evidence was regenerated and its checker marker aligned with
  the current `arch/system holder onehot` assertion.
- Four cohort exclusion contracts were rebound to the current design-id.
- DI-1/DI-2 roots rebuilt the complete directed architecture record:
  9/9 GREEN and 30/30 negative tests PASS.
- Holder census and SQ-retry evidence were rebound; the V9O evidence index
  rebuilt and verified 167/167 artifacts with module 113/113.
- `test_arch_stable_freeze` passed 48/48. The final current audit has 32
  honest blockers: two VD1 defects, incomplete whole-core holder census and
  absent formal freeze-input inventory. No CLOSED debt semantic/provenance
  blocker remains. Architecture remains GAP and PPA remains UNQUALIFIED.

## 2026-07-29 independent currentness review v3

- An isolated, read-only RV64 reviewer rechecked the historical depth gate,
  9/9 checker replay, XRET holder-onehot negative, four cohort contracts,
  V9O 167/167 artifact verification and A3/A4 state boundaries against
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`.
- Decision: `APPROVED_FOR_CURRENT_SCOPE`. No reproducible false-green was
  found in SERIALIZE Phase1 currentness closure.
- The reviewer preserved `ARCH_STABLE=GAP`, 32 current blockers,
  `PPA=UNQUALIFIED` and `promotion_eligible=false`; A3 remains oracle-invalid
  FAIL and A4 remains TERM/rc=143 FAIL.
- The reviewer used only contract-allowed read-only commands, changed no
  file, launched no simulation, synthesis or STA job, and returned the sole
  WSL shell ownership.
