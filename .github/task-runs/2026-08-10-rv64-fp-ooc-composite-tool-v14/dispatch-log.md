# Dispatch log

- parent object: RV64 `OooFpAddSubPipe` 5.0ns OOC output-family evidence.
- live RTL design: `sha256:9d8bb6af7534717f6ed4b9f93b14f63aef407f5b2bc57feb43aef37ccbfbef5d`.
- A7 executed exactly once and is frozen `FAIL / child-OooFpAddSubPipe-opensta-max / rc=1 / CLEANUP_RC=0`.
- AddSub synthesis/retained manifest completed: 7,146 mapped stdcells,
  `15252.16 um^2`, 273 raw bits to 11 canonical families. The first OpenSTA
  failure is `clk_to_q/addsub_d_fflags_q_o has no real timing path`.
- retained synthesis evidence shows at least canonical bit 3 of
  `addsub_d_fflags_q_o` is driven by `TIELOH7L`; FADD/FSUB DZ is architecturally
  constant zero. This is a root-cause hypothesis, not yet a complete proof that
  the whole family lacks Q-to-port paths.
- A7 remains diagnostic GAP; no A7 retry or new production run is authorized.
- next action is an independent read-only driver/path census that must attack
  the constant-bit explanation and freeze the smallest fail-closed artifact
  model before any implementation.
- v1 root-cause review contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-addsub-constant-output-root-cause-review-v1.json`
  - SHA-256: `83d70aebf53b981d55571733de81159b139570cc881540c2089bb9f18f385836`
  - canonical create, validate and render were executed sequentially with rc=0.
    The reviewer is read-only and must produce a per-bit driver/path census;
    it cannot assume that one tied bit explains a family-wide path miss.
  - v1 stopped without write/test/EDA for a valid scope extension: the actual
    lexical helpers are under `npc/rv64/vsrc/execute/`, not `vsrc/include/`,
    and exact tie-cell function proof requires the concrete bound ics55
    Liberty. Preliminary mapped census is retained: nets 201/202/203/205 are
    uniquely driven by `DFFQX1H7L.Q`; net 204 is uniquely driven by
    `TIELOH7L.Z` and feeds both d/s fflags bit 3.
- v2 root-cause review contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-addsub-constant-output-root-cause-review-v2.json`
  - SHA-256: `33c60da023153087bced7f049b1a82414eeba367846e559d167c229de520ed5c`
  - canonical create, validate and render were executed sequentially with rc=0.
    It adds only the actual execute helpers and the exact A7-bound ics55
    Liberty, preserving a read-only/no-EDA scope.
  - v2 stopped without write/test/EDA for one final minimal scope extension:
    `npc/rv64/vsrc/include/define.v` owns the exact FP flag bit macros needed
    by the success criterion. Exact stdlib facts are retained: SHA-256 prefix
    `55c129ca`, `DFFQX1H7L.Q function="IQ"` with CK/D state, and
    `TIELOH7L.Z function="0"` (`TIEHIH7L.Z function="1"`).
- v3 root-cause contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-addsub-constant-output-root-cause-review-v3.json`
  - SHA-256: `44b97fbb3547a9b672c52ffc60e70d97251d7438fa534eb9a48d9d463ad76487`
  - command-clean read-only review completed with no write/test/EDA. It closed
    fflags `[4:0]=NV,DZ,OF,UF,NX`: bits 0/1/2/4 are unique
    `DFFQX1H7L.Q` drivers, bit 3 is unique `TIELOH7L.Z/function="0"`.
    `collect_paths` errors immediately on that zero-path bit, so it is a
    sufficient A7 failure trigger but not evidence that the whole family lacks
    Q paths. RTL is RETAIN; current evidence model is BLOCK; fresh-run=0.
- primary Liberty/OpenSTA facts and the derived diagnostic-only fail-closed
  policy are preserved in
  `evidence/liberty-constant-output-primary-sources-v1.md`.
- v4 constant-output evidence implementation contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-constant-output-evidence-model-v4.json`
  - SHA-256: `95d07e62e6f8f2ad5cc75efe410e2d26b6492af7e398d0d130e54cf9e3e3143d`
  - canonical create, validate and render were executed sequentially with rc=0.
    It changes only the OOC evidence/Registry/Liberty toolchain, focused tests,
    documentation and new evidence. FP RTL and frozen A7 remain read-only;
    production EDA execution count must remain zero.
  - v4 stopped before any write/gate/EDA because the implementer read one
    undeclared existing helper,
    `npc/rv64/eval/ppa/tools/traceable_mapped_sta.py:1170-1285`, while looking
    for a Liberty pin-function parser. The read was non-mutating, but v4 is
    candidate-only. A versioned v5 adds exactly that read-only dependency;
    write paths and technical semantics remain unchanged.
- v5 constant-output evidence implementation contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-constant-output-evidence-model-v5.json`
  - SHA-256: `5d2505ee10dc6cccbe8b1022c2f5fe72107c3d7c8b97e116eea94c8c6fea8412`
  - canonical create, validate and render were executed sequentially with rc=0.
    It adds `npc/rv64/eval/ppa/tools/traceable_mapped_sta.py` as read-only
    context and otherwise preserves v4 semantics, write paths and no-production-
    EDA boundary. The implementer must bind per-bit mapped-driver evidence,
    dynamic/constant OpenSTA semantics and per-bit sequential Liberty through
    the single Registry/runner/parser/schema entry before independent review.
  - v5 stopped after the main production-tool patch was partially written but
    before any final gate or EDA because the implementer used one undeclared
    read-only `tail` command on an allowed test file. No test, OpenSTA harness,
    Registry render/check, bash syntax gate or production EDA had run. The
    source-path read itself was non-mutating; v5 remains candidate-only.
- v6 constant-output evidence implementation contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-constant-output-evidence-model-v6.json`
  - SHA-256: `90bbeb9a9039ae529a501fd0f41d23b86521e41d855c41a2c349f7f0f37d9142`
  - canonical create, validate and render were executed sequentially with rc=0.
    It freezes the v5 command deviation and reauthorizes the current partial
    implementation with the canonical `rg`/`sed` read commands only. Technical
    semantics, write scope, A7 freeze and production-EDA count remain unchanged;
    new evidence is written under the v6 evidence directory.
  - v6 executed its final gate exactly once and stopped at
    `targeted-unittest-and-focused-opensta`: six methods passed and the A7
    mixed-output method reached the final Tcl marker, where double-quoted
    square brackets were interpreted as command substitution. The harness
    returned rc=1 with `invalid command name "FP-OOC-CONSTANT-OUTPUT-HARNESS"`.
    Registry render/check, runner bash-n and scoped audit remained unexecuted;
    production EDA and A7 rerun counts remained zero. The original v6 status,
    log and result are immutable and must not be overwritten or rerun.
- v7 marker-fix verification contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-constant-output-harness-marker-fix-v7.json`
  - SHA-256: `7271c9d555bc5607532f417ca039f6419ccfb93e44bd196bf8f5de7ad0ac5cce`
  - canonical create, validate and render were executed sequentially with rc=0.
    It permits only the Tcl-safe test marker edit, binds the immutable v6
    failure receipts, reruns the one affected mixed-output method and real
    focused OpenSTA harness, then executes only the previously unrun Registry,
    bash syntax and scoped audit gates. Production sources, FP RTL, A7 and the
    other six v6 PASS methods are frozen.
  - v7 executed once and stopped before every test/gate at
    `marker-diff-audit`. The reverse replacement had already proven the test
    file differs from v6 only at the Tcl-safe marker, but the evidence runner
    then incorrectly required the coordination `dispatch-log.md` hash to equal
    its older v6 value. The dispatch log had necessarily changed when v7 was
    recorded. No unittest, OpenSTA harness, Registry render/check, bash-n,
    scoped audit, production EDA or A7 rerun executed; the v7 failure receipts
    are immutable.
- v8 marker-audit verification contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-constant-output-marker-audit-fix-v8.json`
  - SHA-256: `edb022cf54e08ff469d396b674add9c89b6a740121bc20f1072062956c70322e`
  - canonical create, validate and render were executed sequentially with rc=0.
    It changes no test or production source. The new runner binds the current
    dispatch log only within the v8 before/after window, while technical inputs
    remain checked against v6 and original v6/v7 failure receipts remain
    immutable. It then executes the still-unrun affected method and gates once.
  - v8 completed its unique dependency-cropped gate with rc=0. The affected A7
    method and one real focused OpenSTA mixed DFF+TIE harness passed; Registry
    render/check, production-runner bash-n and the 14-path scoped audit each ran
    once and passed. The A7 structural marker reports 138 classified output
    bits, `d_fflags` dynamic indexes 0/1/2/4, constant-zero index 3 and shared
    net 204. Registry snapshot is `sha256:70fc20a0...`; product state remains
    GAP. The other six v6 PASS methods and all production EDA/A7 reruns remained
    at zero. Independent read-only production-path review is the next gate.
- v9 independent constant-output review contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-constant-output-independent-review-v9.json`
  - SHA-256: `6c4fee921c6bfa358d8756ca573cd0394cbe674dd2134811c5a8c3a216bbe0e6`
  - canonical create, validate and render were executed sequentially with rc=0.
    A fresh isolated reviewer is restricted to read-only rg/sed/hash/scoped-diff
    commands and must attack production false accepts/rejects across the A7
    driver contract, bit inventory, Liberty, top macro, receipts and Registry.
    No test or EDA may run; RETAIN can authorize only one fresh diagnostic run.
  - v9 completed command-clean read-only review and returned BLOCK/fresh-run=0.
    The production stdlib parser uses the literal substring `timing (` to decide
    whether a literal-function output has timing. It therefore rejects a legal
    isolated `tied_off:true` SI timing group, while legal whitespace variants
    such as `timing()` or a newline before `(` can hide an ordinary related-pin
    timing group and create a format-sensitive false accept. Current ics55 tie
    cells contain no timing group, so frozen A7 classification remains valid.
    Minimal repair is a structured nested timing-group parser plus legal
    tied-off and whitespace-variant negative coverage before any fresh run.
- v10 tied-off parser implementation contract:
  - JSON: `.github/task-runs/2026-08-10-rv64-fp-ooc-composite-tool-v14/subagent-contracts/fp-ooc-liberty-tied-off-parser-fix-v10.json`
  - SHA-256: `57199852e4a92501128e42a044463dc26d68888a36cc775e923c3a3d5b51499f`
  - canonical create, validate and render were executed sequentially with rc=0.
    It replaces the string probe with a structured nested timing-group policy,
    adds legal tied-off and whitespace-variant negative coverage, and requires
    a focused OpenSTA wrapper that actually links the generated AddSub macro
    before another independent review. FP RTL, A7 and production EDA stay frozen.
