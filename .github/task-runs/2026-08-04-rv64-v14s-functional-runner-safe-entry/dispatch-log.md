# RV64 full-core runner review dispatch

- Invalid candidate contract: `subagent-contracts/full-core-runner-independent-review-v1.json`; rejected because `workspace-files` was incorrectly supplied as a command and produced an empty canonical purpose. It was not dispatched.
- Valid contract: `subagent-contracts/full-core-runner-independent-review-v2.json`
- Contract SHA-256: `f1ea170d1fec486fda5f02bf649d4dacfa4cd48a88c98e52912a889948f510e1`
- Binding scope: the SHA-256 binds only the v2 JSON contract.
- Candidate gates supplied as read-only evidence:
  - `rv64-soc-delivery-gates`: PASS
  - `flow-self-test`: PASS
  - `rv64-full-core-runner-contract`: PASS
- WSL single-flight ownership: transferred to the read-only reviewer for the bounded `rg`/`sed`/`sha256sum` batch; the primary agent runs no workspace command until ownership is returned.

## V2 review result

- Conclusion: GAP. The reviewer identified publication-before-execution-PASS, semantic-empty aggregate acceptance, source-tree AM archive reuse, and benchmark-clean source-tree mutation paths.
- Disposition: all four counterexamples were converted into implementation changes and directed tests; the superseded generation-5 candidate is not reused.

## V3 independent review

- Valid contract: `subagent-contracts/full-core-runner-independent-review-v3.json`
- Contract SHA-256: `dae952cf09796960e48a1705318e8dc0d8be4c52abc811295f2afb6fdccd3948`
- Binding scope: the SHA-256 binds only the v3 JSON contract.
- Candidate generation: 7; `rv64-soc-delivery-gates`, `flow-self-test`, and `rv64-full-core-runner-contract` are PASS.
- WSL single-flight ownership: transferred to a fresh read-only reviewer for one bounded `rg`/`sed`/`sha256sum` batch; the primary agent runs no workspace command until ownership is returned.

## V3 review result

- Conclusion: GAP. Missing execution-stage PASS marker enforcement, aggregate terminal-log semantic revalidation, exact 14-case mutation inventory, and benchmark Makefile gate mapping were converted into generation-8 code and directed tests.

## V4 independent review

- Valid contract: `subagent-contracts/full-core-runner-independent-review-v4.json`
- Contract SHA-256: `38a8459f6db92da5fcc85c761158ca44722809aef66fe7bfeccba0a2b32cfd1a`
- Binding scope: the SHA-256 binds only the v4 JSON contract.
- Candidate generation: 8; all three selected C-pointer gates are PASS.
- WSL single-flight ownership: transferred to a new read-only reviewer for one bounded `rg`/`sed`/`sha256sum` batch; the primary agent runs no workspace command until ownership is returned.

## V4 review result

- Conclusion: GAP. This review is superseded by the subsequent generation-10 candidate and does not authorize a PASS claim.

## V5 independent review

- Valid contract: `subagent-contracts/full-core-runner-independent-review-v5.json`
- Contract SHA-256: `a6c116c4214cf4b2fdf76026e3c3a3d937ccc87f0b827b8f41fa9fde27b3ea80`
- Binding scope: the SHA-256 binds only the v5 JSON contract.
- Candidate generation: 10; all four selected C-pointer gates were PASS before review.
- WSL single-flight ownership: transferred for one bounded read-only review batch and explicitly returned before implementation resumed.

## V5 review result

- Conclusion: GAP. The source F0 consumer accepted a minimal run-result without a same-run module/status/input/retention closure.
- Counterexamples: official membership was count-only, mutation output was shape-checked without downstream replay, benchmark metrics were not reparsed from guest lines, module log receipts could point to another run, AM `.result`/`Makefile.*` side products were outside the isolation watch, and task-run-status changes selected only the helper test.
- Disposition: generation 10 is invalidated. The fixes use one shared live-input collector, exact run-local receipts, downstream read-only mutation replay, guest-line parsing, dynamic secondary-product observation, and combined helper/full-core C gate mapping.

## V6 independent review

- Valid contract: `subagent-contracts/full-core-runner-independent-review-v6.json`
- Contract SHA-256: `2af38f5736d0c8508093eb24ba059d2ff13913642ff88c4600b9676ba470be99`
- Binding scope: the SHA-256 binds only the v6 JSON contract.
- Candidate generation: 11; `rv64-soc-delivery-gates`, `flow-self-test`, `rv64-full-core-runner-contract`, and `rv64-arch-stable-checker-contract` are PASS.
- WSL single-flight ownership: transferred to the read-only reviewer for one bounded `rg`/`sed`/`sha256sum` batch; the primary agent runs no workspace command until ownership is returned.

## V6 review result

- Conclusion: GAP. Generation 11 is not eligible for formal delivery.
- Counterexamples: a run-local parent directory symlink could alias module/status/log/input evidence to another run; rebound official/AM wrapper source sections were not reparsed; pre-existing `.result`/`Makefile.*`/`build`/`obj_dir` products survived an isolation smoke; CoreMark/Dhrystone accepted correct and contradictory guest values together; four functional control inputs were missing from the C gate map.
- Disposition: each counterexample now has a directed negative test. Run-local inputs reject symlinks at every path component; the consumer reopens every official/AM source section; benchmark metrics have exact-one cardinality and reject conflicting values; isolation starts and ends with no AM/benchmark secondary products; the DiffTest schema, architecture identity helper, official inventory runner and AM result checker map to the full-core contract gate.
- Ownership: the reviewer returned the sole WSL shell ownership and reported no residual process before implementation resumed.

## V7 independent review

- Contract is prepared before the replacement candidate so coordination metadata does not invalidate reviewed implementation evidence afterward.
- Valid contract: `subagent-contracts/full-core-runner-independent-review-v7.json`
- Contract SHA-256: `41f488167f0a0f408aaeb69509d1c6cd9d97bc3812bc34b27ab9d47d1473c1d6`
- Binding scope: the SHA-256 binds only the v7 JSON contract.
- Candidate requirement: every selected C-pointer gate must report `CANDIDATE_PASS`; this is an environment/checker claim only and is not an official-177, ARCH_STABLE, system or PPA claim.

## V7 review result

- Conclusion: GAP. Generation 12 is not eligible for formal delivery.
- Counterexamples: `full_core_current_evidence.safe_output_dir()` accepted a lexical parent symlink into another task-run, and `artifact()` accepted a final-file symlink because both helpers resolved before checking. Existing tests covered the consumer but not these producer helpers.
- Disposition: producer paths now walk lexical components before creation or hashing; directed tests cover a foreign-run parent alias and a final-file alias. Suite source-log checks were also tightened to exact-one architectural terminal and exact-one AM DiffTest-ON state.
- Ownership: the reviewer returned the sole WSL shell ownership and reported no residual process before implementation resumed.

## V8 independent review

- Contract is prepared before the replacement candidate; the result is retained in agent-flow evidence/decision records so a PASS-only coordination update does not invalidate the reviewed generation.
- The scope includes the legacy functional runner requested by V7 for producer provenance review.
- Valid contract: `subagent-contracts/full-core-runner-independent-review-v8.json`
- Contract SHA-256: `f75d1e05037f7016ce7e8660de26bdc9c39c925e30efcae01c4886ad6574c85b`
- Binding scope: the SHA-256 binds only the v8 JSON contract.

## V8 review result

- Conclusion: GAP. Generation 13 is not eligible for formal delivery.
- Counterexamples: retained official/AM raw logs were not rebound after wrapper creation; `compact_copy()` lost source aliases through early resolution; the shell entry accepted a dangling final `--run-dir` alias; aggregate output preparation resolved parent/final aliases before checking.
- Disposition: wrappers now bind exact same-run raw path/hash and byte-equal source sections for build, official, AM and benchmarks; compact and legacy copy helpers reject source aliases; the shell constructs the run path lexically under the canonical task-run root; aggregate outputs reject every lexical symlink component including dangling final files. All four cases have directed negative tests.
- Ownership: the reviewer returned the sole WSL shell ownership and reported no residual process before implementation resumed.

## V9 independent review

- Contract is prepared before the replacement candidate; a PASS result will be recorded in agent-flow evidence without editing the reviewed generation.
- Valid contract: `subagent-contracts/full-core-runner-independent-review-v9.json`
- Contract SHA-256: `64af9c2b61490c33a81486251b27bb1981032ef88a0c22d32b665fe523464640`
- Binding scope: the SHA-256 binds only the v9 JSON contract.

## V9 review result

- Conclusion: GAP. Generation 15 is not eligible for formal delivery.
- Counterexamples: universal-newline text decoding allowed a CRLF-only retained raw-log mutation to satisfy apparent equality; canonical publication did not reject parent/final/dangling temporary aliases before writing.
- Disposition: wrapper delimiters and source sections are now parsed as bytes and compared directly with retained raw bytes before UTF-8 semantic parsing. Publication reuses a lexical output helper for both destination and temporary paths, and opens the temporary file with exclusive/no-follow flags. Directed tests cover CRLF-only mutation plus parent, final and temporary aliases.
- Ownership: the reviewer returned the sole WSL shell ownership and reported no residual process before implementation resumed.

## V10 independent review

- Contract is prepared before the replacement candidate; a PASS result will be recorded in agent-flow evidence without editing the reviewed generation.
- Valid contract: `subagent-contracts/full-core-runner-independent-review-v10.json`
- Contract SHA-256: `5f71ec908a23705155f0c8ea00e68ee2425718b8a5603da4a7aceef8154dd433`
- Binding scope: the SHA-256 binds only the v10 JSON contract.
