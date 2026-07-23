# V9L current-design closure definition

- `status`: completed
- `parent_goal`: active
- `design_id`: `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`
- `architecture_debt`: `F0-G1=CLOSED`
- `scope`: local RV64 Verilog/SystemVerilog processor RTL, local simulator/program images,
  testbench/ISA/AM/DiffTest/benchmark evidence, architecture-freeze metadata and the
  executable AI-development workflow that publishes those results
- `production_rtl_changed`: true
- `ppa_qualification`: `UNQUALIFIED`
- `parent_architecture_freeze`: `GAP`

## Completion conditions and results

The V9L design point is complete only because one current design ID now binds all of the following:

1. ROB launch admission and post-launch exact-owner authorization are separate signals; SQ keeps
   exact ROB-index/full-ProducerId ownership after launch, including selective recovery.
2. AXI station lookup is response-credit qualified, and retry residency rejects only the same exact
   token rather than a valid different token in the same bank.
3. The dynamically derived module inventory passes `109/109`; the exact local official inventory
   passes `177/177`; AM cpu-tests pass `59/59` with DiffTest mismatch `0`.
4. CoreMark runs 10 iterations with CRC `0xfcaf` and one GOOD TRAP; Dhrystone runs 10000 iterations
   and reaches one GOOD TRAP.
5. Functional evidence mutations are rejected `11/11`; four current-source RTL verification
   variants compile successfully and are rejected by their intended independent consequences.
6. V8L holder evidence passes `8/8` baselines and rejects `9/9` compile-success RTL variants; two
   canonical reruns produce byte-identical normalized lifecycle/mutation summaries.
7. Nine directed architecture gates replay GREEN on the same design ID. The full arch-stable
   evaluator passes `134/134` unit tests but deliberately remains `GAP` with 39 blockers and
   `promotion_eligible=false`.
8. `npc-dev`, `am-kernels`, `difftest` and `agent-system` e2e profiles publish completed task-runs.
   The NEMU reference-smoke selector accepts only `CONFIG_TARGET_NATIVE_ELF=y` with an explicit
   `CONFIG_ISA="riscv32"` or `CONFIG_ISA="riscv64"`; an executable contract rejects AM, SHARE,
   native non-RISC-V, native missing-ISA and missing configurations, and the real RV64 add smoke
   is `1/1 PASS`.

## Evidence identity

- functional result SHA-256: `3e632a4a8f00ab8d69fc880c8a1e3e8fbf0cbedf240b25a400a8a06f0c25f296`
- functional aggregate SHA-256: `c09c03742fc26dd99ff638baaf2848496328ee264340f8c9f05f08a5df202793`
- architecture-current SHA-256: `a364e78b6e7fbc92619cb8c09ee33e3732ad7186f84597db6f4c24d8c357c6b1`
- architecture hard-gate SHA-256: `2e501a4cb367d02b77cecdfbb14f439ba8e02cf2707fab24aa2f721226e0ba70`
- arch-stable-current SHA-256: `784b4953c1db766e4e8efa5a4189d770a6b88d886e86eecdd09e51a741966b00`
- V8L lifecycle/mutation SHA-256: `82143f9e166465572fc58cdf42c3d07b4a3e9d1d3a78224edb2b9748c6b43a97` /
  `494048b7248b2b1d3c76c3c034c91003fb102b1677ab4e0b0919cb8bc773b707`
- preserved NEMU `.config` SHA-256: `78fc4445c5ed41264d5b9688520b592f3265101d4a8ddd83bc40383ee9fc8a0d`

## Non-promotion boundary

This closure does not claim complete producer-holder census, cohort/freeze-input closure, physical
signoff, power signoff or a qualified PPA comparison. Those remain explicit parent-goal work.
