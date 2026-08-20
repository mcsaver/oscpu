# Dispatch log

- task: `fp-ooc-child-opensta-pathend-arrival-v1`
- contract JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v12/subagent-contracts/fp-ooc-child-opensta-pathend-arrival-v1.json`
- contract SHA-256: `dd3f3d84548d6a106231223153ee9935c63f309168d715a108b514ab7e20f8a2`
- dispatch input: canonical `create -> validate -> render` output, passed without semantic edits
- parent state: active
- A6 production status: frozen `FAIL / child-OooFpAddSubPipe-opensta-max / rc=1 / CLEANUP_RC=0`
- v1 outcome: read-only analysis only; writes=0, final gates=0, production EDA=0.
  Dispatch was stopped before implementation because its checkpoint proposed
  applying `sta::time_sta_ui` to `get_property Path arrival`, which is already
  in UI nanoseconds. The unit-domain fact is now incorporated into the v2
  research input and must not be retroactively attributed to v1.
- v2 contract outcome: JSON was created successfully, but the main node
  accidentally launched its `validate` and `render` WSL read-only commands in
  parallel. Both returned rc=0 and no process remained, but this violates the
  workspace single-flight shell rule. The v2 prompt is therefore retained as
  candidate-only and is not dispatched. A v3 contract must bind this record
  and run `validate` then `render` sequentially.
- v3 canonical dispatch:
  - contract JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v12/subagent-contracts/fp-ooc-child-opensta-pathend-arrival-v3.json`
  - contract SHA-256: `2795bfc8a77de08b5883e418c89ae80824c6b2c44c58b74d960d2a34b655fae6`
  - create, validate, and render were executed sequentially; each returned rc=0.
  - final gate was executed once and preserved as `RESULT=FAIL`,
    `STAGE=affected-unittest-and-real-opensta-harness`, `RETURN_CODE=1`.
    The affected unittest batch and real OpenSTA harness each ran once;
    Registry render/check, runner bash-n, scoped audit, production EDA and A6
    rerun each remained zero.
  - sealed v3 hashes: `gate-status.txt`=`02f3e150e0238287c7eb1a33374c166ce188e6a0b4878dda994e76f4b95de46d`,
    `affected-unittest.log`=`11dee2cb0fc5209b00b79fb7cb373a086d34f77a0f26a6cdb84d450300a349e2`,
    input manifest=`7a28b43043a9286641cf07d17e61f8068db271fd7cc581d019e835c529d665bb`,
    A6 frozen manifest=`15daaa37f7cd106c01b486a763247a7328eac6b56aca6505aa43fdb97d3ba465`.
  - one deterministic validator error is the undefined `child_sta` name at
    `architecture_registry.py:2171`; its declared argument is
    `child_sta_tcl`.
  - the real harness returned `-11` after four consecutive
    `find_timing_paths` calls. Local OpenSTA source commit
    `ceb7e6389dbd92875f7999b509f84e162df3ee0a` states that `PathEnd` objects
    are owned by Search PathGroups and deleted on the next call. The harness
    retained four `PathEnd*` values before consuming any, so its first three
    values were dangling. The source-bound root-cause note is
    `evidence/pathend-lifetime-root-cause-v1.md`.
- v4 dependency-cropped implementation dispatch:
  - contract JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v12/subagent-contracts/fp-ooc-child-opensta-pathend-lifetime-fix-v4.json`
  - contract SHA-256: `59a22ef3fe0c97ec90609c3f058d2940e1ca053444c2872cd417fc6340687298`
  - create, validate, and render were executed sequentially; each returned
    rc=0. The rendered prompt is dispatched without semantic edits.
  - authorized input revision is limited to the `child_sta_tcl` name fix,
    immediate consumption of each Search-owned `PathEnd`, and migration from
    deprecated `-group_count` to `-group_path_count`. A6, FP RTL and production
    EDA remain frozen.
  - the v4 final gate ran once and is sealed as `RESULT=FAIL`,
    `STAGE=scoped-diff-and-text-audit`, `RETURN_CODE=1`. The two affected
    methods, one real OpenSTA harness, Registry render/check, runner bash-n
    and `git diff --check` all passed; production EDA and A6 rerun remained
    zero.
  - real OpenSTA marker:
    `[OPENSTA-PATHEND-ARRIVAL-HARNESS][PASS] input_delta_ns=0.030926 clock_to_q_ns=0.169135 q_to_output_delta_ns=0.087796 pseudo_rejections=3 negative_mutations=4 unit_domain=PropertyValue_UI_ns`.
    This both closes the use-after-free and proves that endpoint-minus-Q
    (`0.087796 ns`) would omit the real register clock-to-Q contribution from
    the cumulative endpoint arrival (`0.169135 ns`).
  - the only v4 failure is in the evidence runner itself: its text audit uses
    `test.index("        script = f'''{proc_prefix}")`, which can match the
    same eight-space suffix inside an earlier twelve-space-indented fixture.
    It therefore audited the wrong Tcl string and emitted
    `group_path_count replacement is incomplete`, even though the production
    Tcl and the executed harness both used `-group_path_count`.
  - sealed v4 hashes: `gate-status.txt`=`45089fdb0cd4967b8d5df30cef444994141f7dd4ada8d84d95ffb1a11c3e4929`,
    `affected-unittest.log`=`b3f5003db9d951bc38eabdf726a57da56279f915c690e98a3a8d3a75c5953563`,
    `registry-render.log`=`a63d80a434e823f198da03a7316c376ee42159a487e4475138c56a838ce1290d`,
    `registry-check.log`=`08379b2297aec41c9056d18a136fe5ef4a1cf59672ae15098a8ec52a922df958`,
    `text-audit.log`=`8521cc470dd4deefb521959b5c887003a79f79f4438dc8e91c634334c4bf23d8`.
- v5 dependency-cropped audit closure:
  - contract JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v12/subagent-contracts/fp-ooc-child-opensta-pathend-audit-closure-v5.json`
  - contract SHA-256: `9b4adcb8d2ca044de9e1ff6ae1a9317d2a1fa69b42e772f1659014ef3e6c7bde`
  - create, validate, and render were executed sequentially; each returned
    rc=0. Only a new method-bounded evidence audit may execute; all v4 PASS
    gates, real OpenSTA, Registry render/check, A6 and production EDA are
    dependency-cropped to zero executions.
  - the v5 closure ran once and is sealed as `RESULT=FAIL`,
    `STAGE=method-bounded-closure-audit`, `RETURN_CODE=1`; no functional,
    Registry, runner or EDA gate was re-executed.
  - the sole marker was
    `harness lifetime marker is not unique: foreach property {path_delay delay arrival}`.
    The method is Python f-string source and therefore contains
    `foreach property {{path_delay delay arrival}}`; the audit compared the
    runtime Tcl spelling against source spelling. This is a v5 evidence-only
    input error and does not challenge the sealed v4 real OpenSTA result.
  - sealed v5 hashes: `gate-status.txt`=`dd74dc741afcb4a3d35380be5cb9e23ff2339329521f6968444bbabaf99db9df`,
    `closure-audit.log`=`90f394dfee7ebb1f05702688173028b19acc9bf068ec5b44c3e7abaca5be0d64`,
    `run-final-gates.sh`=`df23578d60340061adf9a792112a66653b68f3ac46d987a604708fcab2579614`.
- v6 final dependency-cropped audit closure:
  - contract JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v12/subagent-contracts/fp-ooc-child-opensta-pathend-audit-closure-v6.json`
  - contract SHA-256: `262c8f6e2532f3ff2109b0e230fb95d0c61dcd60fb2edef507d7801074441c2d`
  - create, validate, and render were executed sequentially; each returned
    rc=0. The only authorized execution is one method-bounded source-form
    closure using the correct Python f-string double-brace spelling. No prior
    PASS gate, Registry command, runner check or EDA action may run again.
  - the v6 closure executed once and passed:
    `[FP-OOC-PATHEND-AUDIT-CLOSURE-V6][PASS] ast_method_boundary=1 source_form=double_brace pathend_segments=4 reused_opensta=PASS production_eda=0 ppa=GAP`.
    All input, v4, v5 and A6 before/after manifests were byte-identical;
    unittest, OpenSTA, Registry, runner bash-n and production EDA executions
    remained zero.
  - sealed v6 hashes: `gate-status.txt`=`0ab302e77294797e6c505f68f5e23c9ae5f1dad375f6122c05969a76b69c5d8e`,
    `result.json`=`cc2dead3185eba15466c275151f01dcdd8d2612a2698c10dc345789c27bc8c4a`.
- v7 independent read-only review:
  - contract JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v12/subagent-contracts/fp-ooc-child-opensta-pathend-independent-review-v7.json`
  - contract SHA-256: `64fc119056602c1561433f5e6567a0fa3bcd0e0e064d67e473cd11e92796ac21`
  - create, validate, and render were executed sequentially; each returned
    rc=0. The reviewer may run only declared read-only commands and must decide
    RETAIN/BLOCK before any fresh production run-id is authorized.
  - final review verdict: `BLOCK`; no fresh production run-id is authorized.
  - blocker 1: production `collect_arc_family` retains `selected_path` across
    later per-port `find_timing_paths` calls and dereferences it only after the
    loop. This is the same Search-owned `PathEnd` lifetime violation that v4
    fixed only in its harness.
  - blocker 2: `fp_ooc_composite.py::_port_object_matches_family` accepts
    scalar, bracket and `__vN` names but not the `family_N_` underscore form
    already proven by A6 retained netlist evidence and accepted by production
    Tcl. A fresh run would therefore be rejected by the downstream parser.
  - review confirmed the UI-ns, zero-seed input delta and cumulative
    clock-to-Q definitions themselves; v4 measured `0.030926 ns`,
    `0.169135 ns`, and `0.087796 ns` respectively. The v8 implementation must
    fix only the two production blockers and add a multi-bit non-final-worst
    PathEnd harness plus strict underscore index/style parser tests.
