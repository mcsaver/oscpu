# V9E XRET-G1 current-design independent review packet

## Review scope and claim boundary

- The engineering object is the authorized local RV64 Verilog/SystemVerilog
  dual-issue OoO processor, its testbench, and local evidence artifacts only.
- V9E changes verification and evidence workflow files. Production RTL is
  unchanged by this slice.
- Current complete RTL identity is
  `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`.
- The claim under review is only `XRET-G1=CLOSED` for that exact identity:
  MRET/SRET current-mode legality, routing of illegal xRET instructions to the
  precise architectural-exception owner, and legal xRET request/commit/return.
- Full-core architecture freeze and formal PPA promotion are outside this
  claim. The current full-core result remains `ARCH_STABLE=GAP`,
  `PPA=UNQUALIFIED`, and `promotion_eligible=false`.

## RTL owner and dataflow audit

- `OooFetchHeadClassifyGate` is the sole xRET legality source:
  MRET is legal only in M mode; SRET is illegal in U mode; SRET is illegal in S
  mode when `mstatus.TSR=1`; M-mode SRET is not blocked by TSR.
- Head0 routing is owned by `OooPendingDispatchArbiter`, whose pending-system
  capture excludes `dispatch0_arch_trap`.
- Lane1 routing is owned by `OooPendingLane1CaptureGate`, whose pending-system
  capture excludes `arch_trap_raw` and whose exception path retains exact
  cause, PC, and tval.
- `OooPendingTrapExitSequencer` holds the precise exception transaction.
  `OooCsrTrapRequestMux` selects the held exception metadata or a legal xRET
  request. `CsrFile` consumes the selected request and does not independently
  redecode current-mode legality.
- Therefore an illegal xRET must not be captured as a system-return request or
  commit, while a legal xRET must request `CsrFile`, commit once, and return.

## Exact dynamic evidence

- Canonical command: `make -C npc/rv64 check-xret-current-mode`.
- The focused classifier matrix covers seven cases:
  MRET@M legal, MRET@S illegal, MRET@U illegal, SRET@S+TSR0 legal,
  SRET@S+TSR1 illegal, SRET@U illegal, and SRET@M+TSR1 legal. It also checks
  raw instruction preservation in all seven cases. Exact marker:
  `[XRET-G1-FOCUSED] cases=7 legal=3 illegal=4 raw_preserved=7 legal_system=3 illegal_arch_trap=4 PASS`.
- Four full-core programs record non-vacuous request, commit, return, exception,
  handler, metadata, and pipeline-drain counters:
  - legal MRET: `csr_request=1 commit=1 return=1 backend_drained=1`;
  - legal SRET: `csr_request=1 commit=1 return=1 backend_drained=1`;
  - illegal MRET: one precise exception capture, zero xRET CSR requests, zero
    faulting-instruction commits, cause 2, exact capture/CSR PC and tval, one
    known request-observer hit and one known commit-observer hit;
  - illegal lane1 SRET: the same zero/request/commit and exact metadata checks,
    plus `older_lane0=1` to prove the older instruction retires.
- The dynamically derived local testbench inventory passed 109/109.

## Compile-success RTL verification variants and observer sensitivity

Eight current-source RTL variants compiled successfully and were each rejected
by a directed local oracle:

1. remove MRET current-mode legality;
2. remove SRET U-mode legality;
3. remove SRET S-mode TSR legality;
4. overgate legal MRET as illegal;
5. remove head0 architectural-exception/system-request exclusion;
6. remove lane1 architectural-exception/system-request exclusion;
7. offset the precise exception PC;
8. force the precise exception tval to zero.

The head0 routing cut is detected by the independent
`[FLUSH-CONTRACT INV-7]` assertion. Two verification-only compile
configurations redirect the illegal-xRET zero observers to known legal setup
MRET transactions; both compile and are dynamically rejected. Aggregate:
8/8 RTL variants rejected, 2/2 observer configurations rejected, and
`source_unchanged=true`.

Two consecutive canonical runs produced identical hashes:

- XRET result:
  `26f29205929a75a9b824f1ab2b3ac938bb453b8e027f041a0f1e02b364d257a1`;
- raw log:
  `ebe48e34963706ef10fe61bf3c3fd848196961c7d600618f20ca3ca6b7310569`;
- variant/observer summary:
  `14a1463121c772c05431e5604cd15a98316369b4af7859e00ae0e1a8b2607f7d`;
- 109-module summary:
  `69a69e741561e6cfef68794c788a1e4235e791404ed9482e676117badfafd5ad`;
- focused log:
  `1fbde9ba1245760f85e62cc1ef00520766a0b027643667f3cc9b6e79db0091c7`;
- full-core program log:
  `c3b317b3f40846ff4551db002384ba5cfee23d1e25cf602d75dfea4701636935`.

The dedicated XRET evidence tests pass 10/10. The combined arch-stable,
FDG-G1, XRET-G1, and INSTRET-G1 suite passes 68/68 and independently
reconstructs the source variants, observer configurations, exact logs, source
hashes, module inventory, and ledger binding.

## Architecture evidence provenance correction

Adding the independent XRET Makefile target changed only the live hash of
`npc/rv64/Makefile` in the existing nine-record architecture evidence manifest.
All nine dynamic logs, metrics, commands, statuses, artifacts, and the complete
RTL `design_id` were unchanged.

- A fail-closed task-local utility first required all nine gates to be RED only
  at `provenance_files` and `provenance_digest`, required every record's sole
  live mismatch to be that Makefile, proved the manifest projection excluding
  source-binding metadata unchanged, and required the candidate to make all
  nine gates GREEN before atomic replacement.
- The next arch-stable forward test found four optional `source_manifest`
  objects that the architecture gate does not consume but arch-stable does.
  This coverage gap was retained in the first audit. The utility was corrected
  to inspect both `provenance` and optional `source_manifest`, require every
  old aggregate to bind its recorded file map, allow no other live mismatch,
  and verify all source-binding files live after replacement.
- The second pass changed exactly four `source_manifest` sections. Its semantic
  projection was unchanged and the architecture gates remained GREEN.
- Audit hashes are
  `8049e669374b6771d12add5b4998f8c16b4c87cb979a69abbe20939b965625c0`
  and
  `862d22c1a8c126f453649ad259d3bb615343b8f39139010fd4d2aebe85210427`.
- The final architecture result is 9/9 GREEN with SHA-256
  `00b7467f7c51ccaab74ab81ea6c593d28270c26b6f2e2d36bba85f5a9a6dfd88`.
- The subsequent arch-stable result has no architecture provenance-drift or
  canonical-reevaluation blocker. It remains an honest GAP with 44 unrelated
  blockers, PPA UNQUALIFIED, and promotion disabled; artifact SHA-256 is
  `04e8ff709f0b37daf7ea052b06adb58854aebc029d1e77b26cb00733a82d14cc`.

## Independent review questions

1. Does the seven-case matrix correctly distinguish MRET and SRET legality for
   the stated current-mode and TSR scope, including the M-mode SRET positive
   control?
2. Can an illegal head0 or lane1 xRET still reach a legal return request or
   commit, or lose exact PC/tval, without violating a supplied counter,
   assertion, or source-cut variant?
3. Are the eight RTL variants and two observer configurations non-vacuous for
   the stated claim, including false-open, false-closed, routing, metadata, and
   zero-observer behavior?
4. Does the corrected two-section provenance utility permit any non-source-
   binding semantic change, stale/cross-design result, or unrecorded file drift
   to be relabeled as current?
5. Does any statement improperly promote XRET closure or 9/9 directed gates
   into full-core architecture stability or qualified PPA?

Return `VERDICT=PASS` or `VERDICT=FAIL`. List P0/P1/P2 findings with a concrete
local RTL/evidence counterexample, explicitly adjudicate the two-pass
provenance correction, and restate the residual limitations and exact claim
boundary.
