# terminal-collector-v2 review dispatch

- class: tooling/workflow
- contract: `subagent-contracts/terminal-collector-v2-review.json`
- contract-sha256: `7820613471d0611a74c93ff81f82a3b4bd34a18150dd81c8f5bd992807bae0ae`
- contract-validate: PASS
- mode: read-only-review
- shell-ownership: single-flight transferred to the contracted reviewer for declared read-only commands only
- output: reviewer response; no reviewer-created workspace files
- result: GAP; details in `review-v1.md`
- shell-ownership-returned: yes

## v2 verification dispatch

- contract: `subagent-contracts/terminal-collector-v2-review-v2.json`
- contract-sha256: `bd8b92419a6773072eb12ba05644dac1d3685e6e20181a342cf066ce2c3b975b`
- contract-validate: PASS
- reason: close the five v1 counterexamples with executable negative tests
- shell-ownership: single-flight transferred to the contracted verifier
- output: reviewer response; optional scratch is restricted to `.github/runtime-artifacts/npc-systemd-terminal-v2/review-v2-scratch`
- result: PASS; details in `review-v2.md`
- tests: transaction 21/21 PASS; guest host 21/21 PASS
- shell-ownership-returned: yes; no background process
- scratch: four small logs migrated to `logs/`; empty runtime scratch directory removed
