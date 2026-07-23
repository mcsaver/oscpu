# V9C INSTRET-G1 frozen independent-review packet

## Scope and claim boundary

The object is the authorized local RV64 Verilog/SystemVerilog dual-issue OoO processor, its testbenches, local EDA
simulation, and generated architecture evidence.  No network, remote host, account, credential, or external service
is involved.  Hardware terms refer only to pipeline transactions, precise exceptions, commit lanes and verification
source variants.

The implementation claims only `INSTRET-G1=CLOSED` for the current RTL
`design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`.
It does not claim full-core architecture stability or formal PPA: the fresh audit is
`architecture_freeze=GAP`, `blockers=45`, `ppa=UNQUALIFIED`, `promotion_eligible=false`.

## Frozen datapath contract

```text
ROB/core commits -----------+
control pseudo-commit ------+--> OooCommitOutputMux final lanes
branch append --------------+                  |
                                                +--> retire_count_o
                                                        |
                                                        v
                                               NpcCoreTop / CsrFile minstret
```

The production RTL was already correct and was not changed in V9C:

```systemverilog
wire commit0_isa_retire_w = commit0_valid_o && !commit0_exception_o;
wire commit1_isa_retire_w = commit1_valid_o && !commit1_exception_o;
assign retire_count_o = {
    commit0_isa_retire_w && commit1_isa_retire_w,
    commit0_isa_retire_w ^ commit1_isa_retire_w
};
```

`NpcCoreTop` connects `.instret_inc_i(retire_count_o)`.  `OooWriteback` independently recomputes the final-lane
population count under `OOO_ASSERT`; `CsrFile` accumulates the two-bit input when counting is enabled and
`mcountinhibit.IR` is clear.

## Program oracle added to the existing Sv39 full-core test

Every non-reset cycle checks:

1. `retire_count == popcount(final_valid && !final_exception)` and count is not 3;
2. the visible pre-edge `csr_minstret_q` equals the prior sampled value plus the prior sampled final count;
3. a lane-0 precise exception adds zero and suppresses lane 1; a lane-1 exception contributes zero relative to lane 0;
4. final MRET/SRET/SFENCE.VMA control pseudo-commits must be lane 0, non-exceptional, lane 1 suppressed and count 1.

The deterministic program-end inventory is exact, not merely nonzero:

```text
[INSTRET-G1-PROGRAM] exception_lanes=2 exception_zero_delta=2 mret=1 sret=6
sfence_vma=1 control_exact=8 control_total=8 csr_delta_checks=1052 PASS
```

The program does not write `minstret` or set `mcountinhibit.IR`.  WFI remains a separate product-scope decision;
FENCE.I was not inserted into this Sv39 program.  The invariant still applies to any instruction that actually forms
a legal final control pseudo-commit.

## Compile-success current-source RTL variants

Each variant is reconstructed into a temporary file, compiled and elaborated with the current full-core source set,
then required to fail dynamically while the live source SHA remains unchanged:

| variant | local RTL change | required observation |
| --- | --- | --- |
| `exception_filter_removed` | lane-0 count becomes `commit0_valid_o` | `[INSTRET-G1-FINAL-EQ]` |
| `final_control_source_removed` | final lane-0 count becomes pre-mux core lane-0 count | `[INSTRET-G1-FINAL-EQ]` |
| `csr_uses_core_count` | CsrFile input becomes `ooo_core_retire_count_w` | program CsrFile edge-delta failure |

Aggregate: required 3, compile-success 3, dynamic rejection 3, source unchanged true.  Compile success is established
by a fresh per-variant build directory containing the generated `.vvp`, an exact `[COMPILE]` row, and no compile
failure classification; dynamic rejection additionally requires nonzero make status, the named marker and exact
`[RESULT] FAIL`, with no `[RESULT] PASS`.

## Evidence hardening

- The permanent command is `make -C npc/rv64 check-instret-retirement`.
- It force-runs the dynamically derived module inventory and produces 109/109 PASS, then reuses the four relevant
  logs for program/focused interpretation and runs all three RTL variants.
- The builder derives the 109 names from `testbench/Makefile`, requires exact summary lines and exact log membership,
  validates each test's exact PASS/result markers, and records every log path and SHA-256.
- `arch_stable_freeze.py` independently recomputes the full RTL design identity, source bindings, program event
  inventory, 109 module records, focused logs, and all three variant source/log hashes before accepting CLOSED.
- Eight targeted positive/counterexample tests plus the pre-existing 38 arch-stable tests pass: 46/46 total.
- The nine directed architecture gates were canonically refreshed and remain GREEN on the same design ID.

## Frozen artifact hashes

- INSTRET JSON: `4165cb39f7028e1195861ebe6f842a79f127f7b81137707a8a52278bf9a44109`
- INSTRET raw summary: `716fe0e9aaf9732d5dd90a3210ec354f75ee9e3bb39b7b2640602990056525ed`
- module summary: `2ee1a212e6fb048ed9f81453ee59af31cf8a8d23364797fc4d46c1baf84e97b4`
- RTL variant summary: `550b0449c92f24782951d6d6565f099b337ad1ad9479fa277bca8a95a6b046bc`
- nine-gate architecture manifest: `ef71af234e7059fda5fff0cc304b964212e647dd0654dc0cf72c5749e80f0777`
- full-core arch-stable audit: `d93558cd684d717f4253ca50dab0aacd1a2bae21fbafec13c47eeec1e1ad49ad`

## Reviewer questions

1. Is the testbench edge-sampling model sound under Verilog active/NBA scheduling, including reset exit?
2. Can any exceptional or control final-commit event escape, double-count, or make the exact inventory vacuous?
3. Do the three compiling source variants establish behavioral sensitivity at both final-mux and CsrFile boundaries?
4. Can stale, partial, aliased or fabricated module/variant evidence pass the independent semantic validator?
5. Is any wording or result an overclaim relative to the remaining 45 full-core blockers and unqualified PPA state?

Return P0/P1/P2 findings with a concrete counterexample.  If none, state `VERDICT=PASS`, list residual limitations,
and explicitly preserve `ARCH_STABLE=GAP` and `PPA=UNQUALIFIED`.
