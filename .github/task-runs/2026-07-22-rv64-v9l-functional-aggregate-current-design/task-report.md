# V9L current-design functional, ownership and workflow closure

## Status

- `status`: completed
- `parent_goal`: active
- `design_id`: `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`
- `F0-G1`: `CLOSED`
- `architecture_freeze`: `GAP`
- `ppa`: `UNQUALIFIED`
- `promotion_eligible`: false

## Implementer evidence

- Production RTL now separates ROB first-launch admission from exact unfinished-head ownership,
  carries that owner contract through dispatch/SQ, response-credit qualifies AXI station lookup,
  and permits a different station token beside a retry token while rejecting exact duplication.
- Focused positive tests pass for owner-open, post-launch SQ ownership, lookahead credit and distinct
  retry residency. Four compile-success RTL variants each reach stimulus and are rejected by
  `[V9L-SQ-POST-LAUNCH-OWNER]`, `[V9L-SQ-LOOKAHEAD-CREDIT]` or
  `[V9L-RETRY-OWNER-DISJOINT]` as intended.
- The canonical functional aggregate passes module `109/109`, official `177/177`, AM `59/59`,
  DiffTest mismatch `0`, CoreMark 10/CRC `0xfcaf`, Dhrystone 10000 and evidence mutations `11/11`.
  Result/aggregate SHA-256 values are
  `3e632a4a8f00ab8d69fc880c8a1e3e8fbf0cbedf240b25a400a8a06f0c25f296` and
  `c09c03742fc26dd99ff638baaf2848496328ee264340f8c9f05f08a5df202793`.
- V8L holder evidence passes `8/8` baselines and rejects `9/9` compile-success variants. Two clean
  canonical executions produce byte-identical lifecycle/mutation artifacts with SHA-256
  `82143f9e166465572fc58cdf42c3d07b4a3e9d1d3a78224edb2b9748c6b43a97` and
  `494048b7248b2b1d3c76c3c034c91003fb102b1677ab4e0b0919cb8bc773b707`.
- Nine current-design directed architecture gates are GREEN. The arch-stable audit passes `134/134`
  evaluator tests and honestly returns `GAP`, 39 blockers, PPA `UNQUALIFIED` and no promotion.

## Workflow correction and publication

- The old NEMU e2e selector incorrectly treated `CONFIG_TARGET_AM=y` as the executable reference
  target. Root-cause replay showed this creates recursive `platform/nemu.mk -> NEMU run` builds.
  Temporary attempts to make that wrong AM path compile were reverted from production NEMU source.
- The selector and `quick`/`nemu` profiles now use host-native RISC-V reference semantics. The new
  `nemu-reference-config-contract` accepts only native plus an explicit `riscv32`/`riscv64` ISA,
  and rejects AM, SHARE, native non-RISC-V, native missing-ISA and missing configurations,
  including when the historical force variable is present.
- A real host-native RV64 `cpu-tests/add` run executes 844 guest instructions, reaches GOOD TRAP and
  passes `1/1`; NEMU `.config` is restored byte-identically with SHA-256
  `78fc4445c5ed41264d5b9688520b592f3265101d4a8ddd83bc40383ee9fc8a0d`.
- Completed profile evidence:
  - `npc-dev`: `2026-07-22-rv64-memory-ownership-functional-aggregate-revtag-v9l`
  - `am-kernels`: `2026-07-22-functional-aggregate-rv64-memory-ownership-revtag-v9l`
  - `difftest`: `2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2`
  - `agent-system`: `2026-07-23-rv64-hardware-professional-revtag-v9l-4`
- DB-first retained memory was updated for project status, NPC, AM kernels, NEMU, agent-system and
  known issues `[122]`/`[123]`; a stored-document snapshot was refreshed.

## Reviewer findings

- Positive execution alone was not used for closure: all functional and RTL contracts have
  independent negative variants or configuration counterexamples.
- Earlier blocked AM-config runs remain counterexamples only. They are not counted as completed
  DiffTest evidence, and the final profile explicitly binds the corrected eight-node graph.
- The current census still declares `instance_graph_complete=false` and `semantic_complete=false`.
  Cohort inventory, freeze inputs, remaining architecture debt and physical PPA/signoff are open;
  therefore the parent goal remains active and no `ARCH_STABLE` or PPA promotion is claimed.
