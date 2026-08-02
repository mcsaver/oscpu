# V13R evidence index

| Claim | Evidence | Status | Reuse boundary |
|---|---|---|---|
| DECERR snapshot survives three full bridge stall edges after live B poison | `evidence/v13r-focused/logs/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.log`, `evidence/v13r-focused/result.json` | PASS | One lane0 bridge store; bounded three-edge hold |
| Backend simple-ALU traffic cannot extend the fallback with a second full wave because lane1 refill is blocked | `evidence/v13r-focused/logs/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.log` marker `[V13R-BACKEND-FAIRNESS]` | PASS | Simple integer ALUs only; not long-op/FP/dual-memory |
| Exact DECERR formal-WB/cause7/original VA and single DRAIN/SQ/MIQ terminal | same backend log and `critical-source-binding.sha256` | PASS | Isolated lane0 store, exact producer/token |
| Three complete `commit_ready=0` edges retain exact ROB/SQ/owner state without replay | same backend log marker `[V13R-BACKEND-B-HOLD]` | PASS | Current `OooRob` commit-valid means commit fire |
| S_RESP hold, DECERR snapshot and commit-ready oracles are mutation-sensitive | `evidence/mutation-*/result.json`, `evidence/mutation-suite-result.json` | PASS | Three declared compile-and-run variants only |
| V13Q/V13P/V8X affected neighborhood remains green | `evidence/regressions/result.json` and four bounded logs | PASS | Named focused regressions only |
| Initial second-full-wave and WB0-only hypotheses were rejected | `evidence/schedule-falsification.md` | FAIL preserved / corrected | Diagnostic evidence; not a positive result |
| Full focused compile/source closure and common receipt generation | 61-entry `evidence/v13r-focused/critical-source-binding.sha256`; focused/mutation/regression receipts; `reviewer-result.md` | PASS | Current named V13R Make cohorts and drivers |
| Lightweight workflow completion and explicit changed-path trace | `evidence/agent-flow/agent-flow-result.md` and sibling TSV records | PASS | Advisory overhead accounting; no Git enumeration or release e2e |

Normative round narrative is in `task-report.md`; implementer result and gaps
are in `verification-result.md`; independent evidence review is in
`reviewer-result.md`; bounded review dispatch history is in `dispatch-log.md`.
Production RTL and every focused compile input are
bound by manifest SHA `75691729...74aaa`, and no rebuildable VVP is an
archival artifact.
