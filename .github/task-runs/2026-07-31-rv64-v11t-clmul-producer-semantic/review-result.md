# V11T frozen-material review result

RV64 RTL 结论｜对象=OooIntBackend.u_clmul_unit 的 CLMUL/CLMULH ProducerId 生命周期（`summary.json`、`producer-holder-semantic-coverage.json`）｜周期/配置=request capture→RUN/RESP→WB0→accepted-terminal/full_flush，generation-width=1/4 release profiles｜TB/EDA 观测=22/22 focused、4/4 ordinary regression PASS，18/18 mutation profiles（9 类×2 配置）命中声明阶段失败 marker；综合/STA/PPA 未运行｜范围=冻结材料内 CLMUL producer 单元级 PASS；eight_younger_pressure、global_no_live_reuse、整核与 PPA 保持 GAP/UNPROMOTED

## Review decision

- `{generation=1,index=2}` is stimulus-owned and is not sampled from the DUT holder or ROB; both CLMUL and CLMULH traverse the real `OooIntBackend.u_clmul_unit` product path.
- Same-index/wrong-generation exact-open rejection and the request, owner/live-mask, completion-query, WB0, terminal-release and full-flush observations form a consistent lifecycle chain.
- The nine compile-success mutations cover the declared lifecycle cut points and are rejected by stage-specific markers rather than by compile failure.
- Compact cleanup is internally consistent: 22 focused `.vvp` + 4 regression `.vvp` + 9 generated-negative `OooIntBackend.v` + 1 generated focused TB = 36 retired secondary artifacts.
- The current instance graph shares design-id `sha256:82febf4aa834d61be398197015257714cc53d81f9291a2ba998ba28644041ac4`; the ledger accounting is consistent at 36 PASS + 8 GAP = 44 units.

## Preserved GAPs and unknowns

- V11T did not run eight-younger pressure and does not prove global no-live-reuse under wrap/reuse, concurrent long operations, ROB flush or replay combinations.
- The nine mutations prove sensitivity to the named faults, not exhaustive timing-interleaving coverage; combined response backpressure, flush and same-index reissue remains outside the frozen material.
- The evidence approves the observable ProducerId transaction contract, not a unique internal holder implementation.
- A3 original `FAIL` remains immutable; no system rerun occurred, so the legacy dmesg-oracle interpretation cannot promote whole-architecture status.
- Contract and artifact hashes provide local audit binding, not an external signature over a writable workspace.

`scope_extension_request=none` for the bounded unit verdict. Whole-core or PPA promotion requires a separate contract and additional pressure, system, synthesis, STA and PPA evidence.

Review contract: `.github/task-runs/2026-07-31-rv64-v11t-clmul-producer-semantic/subagent-contracts/rv64-v11t-clmul-frozen-review.json`, SHA-256 `13beb54fda379afd0d14c5adf1ad5367f80163d6a7ecfae0b22cdc45cfab0fd6`.
