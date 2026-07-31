# RV64 V11T task report

- RTL object: `OooIntBackend.u_clmul_unit`, CLMUL/CLMULH full ProducerId lifecycle.
- Current design: `sha256:82febf4aa834d61be398197015257714cc53d81f9291a2ba998ba28644041ac4`; production RTL unchanged.
- Directed evidence: 22/22 profiles, nine compile-success mutation kinds at generation widths 1/4, and 4/4 regressions PASS.
- Semantic result: `clmul-producer=PASS`; current ledger 36 PASS / 8 GAP. Remaining units are `pending-system-producer` and seven FP producer paths.
- Evidence retention: authoritative attempt-2 logs/manifests/hashes retained; 36 secondary compile/generated artifacts absent by contract; superseded attempt-1 and five unit-test temporaries removed with a compact cleanup receipt. Total removed payload is 284,872,290 bytes. Negative-contract fixtures now use auto-removed runtime scratch; no repository-root `tmp*.json` remains.
- Workflow result: ordinary ledger baseline reduced from about 11.2 s / 1.5 GB to about 1.66 s / 50 MB by build-snapshot reuse and hash-bound compact Yosys projection; complete 97-test fail-closed suite PASS in 57.517 s, max RSS 96,896 KiB.
- Review: frozen-material independent review approves only the CLMUL producer unit. Eight-younger/global reuse, full-system, synthesis/STA/power and PPA remain outside scope.
- A3: original FAIL and strict 16/17 retained; no history was rewritten and no full system rerun was triggered.
