# Dispatch log

- parent object: RV64 `OooFpAddSubPipe` 5.0ns OOC composite timing evidence.
- live RTL design: `sha256:9d8bb6af7534717f6ed4b9f93b14f63aef407f5b2bc57feb43aef37ccbfbef5d`.
- prior production A6 remains frozen `FAIL / child-OooFpAddSubPipe-opensta-max / rc=1 / CLEANUP_RC=0`; PPA remains GAP.
- v12/v4 real OpenSTA harness closed the PropertyValue UI-ns and immediate
  harness lifetime behavior. It measured input-to-D `0.030926 ns`, cumulative
  clock-to-Q-to-output `0.169135 ns`, and Q-to-output-only `0.087796 ns`.
- v12/v7 independent review blocked a fresh production run on two concrete
  production defects:
  1. `collect_arc_family` retains a Search-owned `selected_path` across later
     per-port `find_timing_paths` calls and dereferences it after the loop;
  2. `_port_object_matches_family` rejects the `family_N_` underscore form
     already present in A6 retained netlist evidence and accepted by the Tcl
     collector.
- these are EDA evidence-path defects, not a CPU microarchitecture decision;
  no CPU Architect Agent is triggered and FP RTL remains unchanged.
- no fresh production run-id is authorized until a versioned implementation,
  a real multi-bit non-final-worst OpenSTA harness, strict underscore parser
  mutations, and independent read-only review all pass.
- v8 implementation contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v13/subagent-contracts/fp-ooc-child-production-pathend-parser-fix-v8.json`
  - SHA-256: `4ae3da68f38b70c20ccf4d563a580a17969fbbb9a782e8b57cc0b027577b0567`
  - canonical create, validate and render were executed sequentially and each
    returned rc=0. The rendered prompt is dispatched without semantic edits.
  - the v8 final gate ran once and is sealed `RESULT=FAIL`,
    `STAGE=scoped-diff-and-text-audit`, `RETURN_CODE=1`. Three directed methods,
    one real 2-bit OpenSTA harness, Registry render/check and diff-check all
    passed; production EDA and A6 rerun remained zero.
  - real production-collector marker:
    `[OPENSTA-PRODUCTION-MULTIBIT-PATHEND][PASS] selected_startpoint=data_i[0] selected_endpoint=u_state0_q/D last_query=data_i[1] bit0_delay_ns=0.0902 bit1_delay_ns=0.030926 bit0_slack_ns=4.875257 bit1_slack_ns=4.934493 selected_from_nonfinal_query=1`.
  - A6 parser marker:
    `[A6-ARC-PORT-FAMILY-PARSER][PASS] actual_style=underscore actual_width=64 positive_styles=4 negative_mutations=7`.
  - the sole failure is an evidence assertion comparing the first occurrence
    of `set selected_startpoint`, which is its initialization, against the
    later path-value materialization. The exact candidate assignment itself is
    present and both functional gates passed.
  - sealed v8 hashes: `gate-status.txt`=`5604d12d8c4b51faec069b8ea46acf175eadc9360b539e91b8d3e2d8c569374c`,
    `affected-unittest.log`=`c7ffa6aae60b88dda82f05a9cd95da80c884285f134d9ae1a388e9508b4dbba8`,
    `run-final-gates.sh`=`d7b0b202209c40d48969c84457120d066540454a4129719d5dab0c39d0e728a0`.
- v9 contract is retained as candidate-only and was not dispatched. Its
  PowerShell create command expanded Tcl `$observation`, `$path_startpoint`
  and `$path_endpoint` tokens inside double-quoted natural-language fields,
  so the validated/rendered prompt lost those identifiers. A v10 contract
  must restate the same closure without shell-expanded tokens and run the
  canonical create, validate, render sequence again.
- v10 dependency-cropped closure contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v13/subagent-contracts/fp-ooc-child-production-fix-audit-closure-v10.json`
  - SHA-256: `8ad879877c5781fc9707c35664d0906eaba5eeb0e509129050d99bee95ccabb9`
  - canonical validate and render were rechecked sequentially with rc=0; the
    rendered prompt is dispatched without edits.
  - scope is evidence-only: preserve the v8 FAIL plus its functional PASS
    receipts, bind current production/A6 hashes, and execute exactly one v10
    closure. It must not rerun unittest, OpenSTA, Registry, Yosys, STA, RTL
    simulation, or A6.
  - v10 closure completed rc=0 with marker
    `[FP-OOC-PRODUCTION-FIX-AUDIT-CLOSURE-V10][PASS]`; no functional or EDA
    gate was rerun and production sources did not change. Sealed hashes:
    `gate-status.txt`=`8116247e2f7b928ed1d5e979ef3e70998a79f47085dbb4770facc96a8b590eb6`,
    `closure-audit.log`=`684912d2e7671777aceab26a2c5654d1743ea392762a95d6514eace7dff9c742`,
    `input-manifest.json`=`86ba552e1f66c26567b64079f445ab22032e5ebdbedc61b59cd45fae827fb638`,
    `result.json`=`e47563a9ebaa46149062c9769858752455fb34c85237c01ff9efdc863c142aa8`.
- v11 independent review contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v13/subagent-contracts/fp-ooc-child-production-fix-independent-review-v11.json`
  - SHA-256: `136b75575dfb25994f003f607cf983c51ca2707c0239a9cc06d709f2f7a7f837`
  - canonical create, validate and render were executed sequentially and each
    returned rc=0. The reviewer receives the rendered prompt without edits,
    has read-only workspace access, and may authorize at most one fresh
    diagnostic run-id while production PPA remains GAP.
  - independent verdict: BLOCK. `fp_ooc_composite.py` normalizes each
    `arc_inventory[*].object_names` member with `rsplit('/', 1)[-1]`, so a
    forged continuous set such as `u0/frs1_value_i_0_` through
    `u63/frs1_value_i_63_` is accepted even though production Tcl obtains
    these families from anchored top-level `get_ports` and can never emit
    hierarchical owners. Existing mutations only create duplicate index 0
    and do not kill this different-owner/different-index counterexample.
  - all other reviewed boundaries retained: immediate PathEnd materialization,
    worst-slack/max-min-delay selection, real non-final-worst two-bit oracle,
    A6 underscore 0..63 acceptance, and v8/v10/A6 identities. Fresh-run
    authorization remains zero and PPA remains GAP until this parser/Tcl
    isomorphism defect is fixed and independently reviewed.
- v12 port-owner isomorphism implementation contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v13/subagent-contracts/fp-ooc-arc-port-owner-isomorphism-fix-v12.json`
  - SHA-256: `67d4599012d7f190ad83f4763ce4cb3f13f814cf81724d26999d0b6308f55b42`
  - canonical create, validate and render were executed sequentially with rc=0.
    The change is limited to PORT-family object identity, its Registry source
    contract, directed mutations, specification text and new evidence. It must
    not change FP RTL or rerun production EDA/A6.
  - its only final-gate invocation is sealed FAIL at `registry-check` rc=2
    because generated `npc/rv64/ARCHITECTURE.md` is stale and the v12 contract
    did not authorize that write. The two affected methods passed: A6 real
    underscore width 64, 11 mutations, cross-owner public validation and
    hierarchical-pin preservation all closed. Sealed hashes:
    `gate-status.txt`=`af0194ca2c7b0daa1f0080c32155a5d6648cfe0def99836cb6905f87e0b7e450`,
    `affected-unittest.log`=`24cde6b7a0a3edbb10aaa817beb446b424388e8b43506c6fb5c159b740caed13`,
    `registry-check.log`=`9310a72001eb858fadbb4d46806c488b35d59e6d37dcce24e40741f85a9c4687`.
    Production EDA/A6 execution count remained zero.
- v13 dependency-cropped single-entry closure contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v13/subagent-contracts/fp-ooc-arc-port-owner-single-entry-closure-v13.json`
  - SHA-256: `79fa281d53a383cc6355b367cf3555e335498f67a85cc2e7b48879e12f0150a5`
  - canonical create, validate and render were executed sequentially with rc=0.
    It may only reuse the v12 affected-test PASS, render/check the Registry
    single entry and perform a scoped audit; all functional and production EDA
    execution counts must remain zero.
  - v13 completed PASS: Registry render/check and scoped audit each executed
    once; all functional/EDA counts remained zero. Registry snapshot is
    `sha256:efdd71682b7b600a990afd5fea8ae4fcd4928c2602b41006ff2cba9194458ecb`.
    Sealed hashes: `gate-status.txt`=`7aef7f410a4a013ad569854239c36c55903796e47274565203c2201e6b151bd9`,
    `result.json`=`d8b0f20f886626e41a38197d92099bc4587f6ee0d0fb3232567beaf189ffadae`;
    non-ARCH before/after manifest is identical at
    `96b84d03fba46b545e5bd83497c1dbab5ca76ee4f9e5b80a178717341184bcf6`.
- v14 independent review contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v13/subagent-contracts/fp-ooc-arc-port-owner-independent-review-v14.json`
  - SHA-256: `ced6bb2c0ec6ecf862531636fb74052238bc1eab4300c81fd876d75f2b6d6a13`
  - canonical create, validate and render were executed sequentially with rc=0.
    A new read-only reviewer must attack full PORT object identity, legitimate
    hierarchical-pin preservation, public parser reachability, PathEnd
    non-regression and all sealed identities before any fresh run is allowed.
  - the first v14 agent dispatch was interrupted before shell ownership or any
    engineering command because one rendered formatting token was transcribed
    without its original space. It is candidate-only and produces no technical
    evidence. The same validated contract is redispatched to a fresh isolated
    reviewer using the exact render below.
  - the exact-render reviewer found no technical blocker and returned RETAIN,
    but one `rg` pattern containing Markdown backticks triggered unintended
    shell command substitution and attempted nonexistent command `PORT`.
    It caused no write or process residue, yet falls outside the declared
    command set; this v14 result remains candidate-only and does not authorize
    a production run. A fresh command-clean reviewer is required.
- v15 command-clean independent review contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v13/subagent-contracts/fp-ooc-arc-port-owner-command-clean-review-v15.json`
  - SHA-256: `a59e68a7523d7a5a3f1da1748b4fd929e46625c5d086f32756108a531c84c9ca`
  - canonical create, validate and render were executed sequentially with rc=0.
    A fresh isolated reviewer must derive its own conclusion using only the
    declared read-only command classes; v14 cannot be inherited as hard proof.
  - v15 completed command-clean RETAIN. It used only `rg`, `sed`, `sha256sum`
    and `git diff`, performed no write/test/EDA action, and found no production
    owner false-accept or hierarchical-pin false-reject. It confirmed current
    Tcl/parser/Registry/test/spec identities match v13 and A6 remains frozen
    FAIL. Exactly one new run-id is authorized for one 5.0ns diagnostic;
    production PPA remains GAP/noncanonical/nonchampion.
- A7 production diagnostic contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v13/subagent-contracts/fp-ooc-composite-production-ppa-9d8b-a7.json`
  - SHA-256: `e2bb0062c1ab8a0eeed3fc61286818b66bb84e557fc8d0748432f171b1d7223f`
  - canonical create, validate and render were executed sequentially with rc=0.
    After fresh-run/A1-A6/Registry/tool preflight, it may start exactly one
    A7 runner with at least a ten-hour host budget. While active there may be
    no side query or retry; any terminal result remains diagnostic GAP.
