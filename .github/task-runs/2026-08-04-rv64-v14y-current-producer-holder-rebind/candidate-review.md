# V14Y current producer-holder candidate review

- contract: `subagent-contracts/v14y-current-producer-holder-review-v1.json`
- contract_sha256: `8ea0638f4c53752e29cdb898edd8aac5b53e23747dc8f8f78336e3a1a14c17df`
- result: current design-id/source closure/five-role evidence/static instance graph slice `PASS`.
- blocking findings: none.

## Verified identity

- Census, result and receipt bind design-id
  `sha256:06c5be5b83be0646e0eda9984ca486b70f1cb8055d2988417528566d4a040a5b`.
- The current RTL source closure contains 146 files. The exact ordered synthesis source list contains 127 files;
  result and receipt both bind list SHA-256
  `be206f46f3cbd976dba081e9952ac48648a2913af526292f41417af9ce593b57`.
- All five actual artifact hashes match the census declaration: result
  `30f0f3fac331aa6e5f81753e26928de56bdf952fb18c133dc130125a00b92a34`, receipt
  `01fc46a62b1eb9e54799b15d9743832bcb687a9ddde6e20441b9085fdf80311c`, compressed full graph
  `def7f928396e730131a6f19c8002adda6c95a7f06de3f564b6ae06e78d1cc4f4`, script
  `ba7cd306a1bed385f3d5f76c15aa9ac5de661d7165040641600fa19c117ea601`, and log
  `9e1beea36a898c5889e2830561de0206f7085ab3e78580e03a6a0629e4c12337`.

## Verified topology and checks

- The graph contains 15 holder modules and 17 instances. The duplicated modules are `OooMemAxiBridge`
  (`u_bridge0/u_bridge1`) and `OooMemInflightQueue`
  (`u_mem_inflight_queue/u_mem1_inflight_queue`).
- The retained census log records 21 instance-graph tests and 16 census tests passing. The aggregate contract log
  repeats those observations and records `507 >= 89` immediate assertions with final `check-contract: PASS`.
- The agent-flow candidate summary was not treated as RTL evidence; the review used the declared artifacts, hashes,
  graph and checker logs.

## Claim boundary

`semantic_complete=false`, `whole_architecture=RED` and `ppa_promotion=UNPROMOTED` remain unchanged. This review
does not qualify holder runtime lifecycle, full-system behavior, synthesis quality, STA, area, power or PPA. The
Yosys log contains memory-to-register replacement warnings but no reported error; those warnings are outside the
static instance-count claim. No scope extension was requested.

The reviewer used one bounded read-only command batch, started no EDA or simulation job, and returned the single
WSL command lane without residual engineering processes.
