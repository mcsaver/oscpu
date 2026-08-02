# RV64 V12A subagent dispatch log

## v12a-semantic-rebind-review-v1

- task kind: `read-only-review`
- local object: RV64 producer/holder selected RTL/TB macro projection, V11U input closure, V12a holder graph and 44-unit semantic ledger
- contract JSON: `.github/task-runs/2026-08-01-rv64-v12a-holder-cohort-rebind/subagent-contracts/v12a-semantic-rebind-review-v1.json`
- contract JSON SHA-256: `2b3af755192098c91ce82596ac7a2829caad9e757874b7d93a9ca63ae18858a8`
- binding note: the SHA-256 above binds only that JSON contract
- shell ownership: transferred to the reviewer for the contract's read-only `rg`/`sed`/`git diff`/`sha256sum` commands; the primary agent and other agents run no WSL engineering command until ownership returns
- expected output: independent APPROVE/BLOCK/inconclusive with exact RTL/evidence fields, counterexamples, unknowns, scope-extension request and confidence basis

## v12b-v11u-compile-input-closure-review

- task kind: `read-only-review`
- local object: RV64 `OooRob` pending-system producer birth/exact retirement release, three control-plane modules, V11U attempt-9 actual `iverilog` argv/module dependencies, compile-success RTL mutations, V11H replay and 44-unit local semantic ledger
- contract JSON: `.github/task-runs/2026-08-01-rv64-v12a-holder-cohort-rebind/subagent-contracts/v12b-v11u-compile-input-closure-review.json`
- contract JSON SHA-256: `4095fcd6a664fe4bc6b6dca985dfd199cd4f54510ee5add6cf5d858ef6b16979`
- binding note: the SHA-256 above binds only that JSON contract
- compression note: attempt-6/7 each retained 48 untracked `.deps` files after their failed run; those 96 secondary compiler products (about 608 KiB total) and resulting empty directories were removed, while status, profile JSON and logs remain; attempt-6/7/9 now retain no `.vvp`, `.deps`, `.argv`, negative RTL variant or temporary compiler wrapper
- shell ownership: transferred to the reviewer for the contract's read-only `rg`/`sed`/`git diff`/`sha256sum` commands; the primary agent and other agents run no WSL engineering command until ownership returns
- expected output: independent PASS/GAP/inconclusive with exact compiler-input closure fields, RTL/TB counterexamples, unknowns, local/global boundary, scope-extension request and confidence basis
- reviewer result: `PASS` for `pending-system-producer` local semantic closure; saved in `reviewer-result-v12b.md`. The reviewer found the contract's TB path omitted `tests/`; the actual `npc/rv64/testbench/tests/tb_ooo_priv_system.sv` remains byte-bound by attempt-9 and the checker, so no repeat review was required for this closure claim.
