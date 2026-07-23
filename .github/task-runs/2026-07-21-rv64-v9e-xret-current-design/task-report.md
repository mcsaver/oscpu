# V9E XRET-G1 current-design evidence report

## Implementer checkpoint

Production RTL was already correct and remains unchanged by V9E. The slice
reconstructed the real xRET owner/dataflow and rebound XRET-G1 to the current
complete RTL identity:

- legality: `OooFetchHeadClassifyGate`;
- head0 exception-versus-system capture: `OooPendingDispatchArbiter`;
- lane1 exception-versus-system capture: `OooPendingLane1CaptureGate`;
- precise transaction retention: `OooPendingTrapExitSequencer`;
- final exception/xRET selection: `OooCsrTrapRequestMux`;
- architectural consumer: `CsrFile`, without duplicate mode-legality decode.

The classifier now has exact current-design evidence for MRET legal only in M
mode, SRET illegal in U mode, S-mode SRET blocked by TSR, and M-mode SRET not
blocked by TSR. Illegal xRET instructions select the precise architectural
exception path rather than the pending-system return path.

Canonical command: `make -C npc/rv64 check-xret-current-mode`.

## Current evidence

- design identity:
  `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`;
- focused matrix: 7 cases, 3 legal, 4 illegal, raw instruction preserved 7/7;
- four full-core programs: legal MRET/SRET each request, commit, return and
  drain once; illegal MRET/SRET each capture one precise exception, issue zero
  xRET CSR requests, commit zero faulting instructions, reach the handler,
  return, and match cause/PC/tval plus CSR `mepc/mtval`; lane1 illegal SRET also
  retires the older lane0 instruction;
- dynamically derived module aggregate: 109/109 PASS;
- compile-success local RTL verification variants: 8/8 dynamically rejected;
- request/commit zero-observer sensitivity configurations: 2/2 dynamically
  rejected;
- production source before/after the variants: unchanged;
- XRET fail-closed unit tests: 10/10 PASS;
- combined arch-stable/FDG/XRET/INSTRET semantic tests: 68/68 PASS.

Two consecutive canonical replays produced identical SHA-256 values:

- XRET result:
  `26f29205929a75a9b824f1ab2b3ac938bb453b8e027f041a0f1e02b364d257a1`;
- raw log:
  `ebe48e34963706ef10fe61bf3c3fd848196961c7d600618f20ca3ca6b7310569`;
- RTL variant/observer aggregate:
  `14a1463121c772c05431e5604cd15a98316369b4af7859e00ae0e1a8b2607f7d`;
- module summary:
  `69a69e741561e6cfef68794c788a1e4235e791404ed9482e676117badfafd5ad`;
- focused/program logs:
  `1fbde9ba1245760f85e62cc1ef00520766a0b027643667f3cc9b6e79db0091c7` /
  `c3b317b3f40846ff4551db002384ba5cfee23d1e25cf602d75dfea4701636935`.

## Verification variant boundary

The eight source cuts remove MRET mode legality, SRET U-mode legality, SRET
S-mode TSR legality, overgate legal MRET, remove head0 or lane1
architectural-exception/system-request exclusion, offset precise exception PC,
or force precise exception tval to zero. All compile and are rejected by exact
directed markers. Two verification-only compile configurations redirect the
request and commit zero observers to a known setup MRET; both are rejected,
which prevents a vacuous zero-observer claim.

These checks prove sensitivity to the listed error models. They are not a
formal completeness claim for every privileged-state sequence.

## Architecture evidence workflow correction

The new independent XRET Makefile target changed a shared workflow source hash
used by all nine directed architecture records. The first architecture run
correctly failed every gate only at `provenance_files` and
`provenance_digest`. A task-local fail-closed utility required:

1. the exact nine-record inventory and current complete RTL design binding;
2. no failed architecture check beyond those two provenance checks;
3. exactly one live mismatch per record, `npc/rv64/Makefile`;
4. unchanged non-source-binding semantic projection;
5. a candidate evaluation with all nine gates GREEN before atomic replacement.

The next arch-stable forward test found four optional `source_manifest`
objects that the architecture gate does not consume. This first-pass coverage
gap remains recorded. The utility was corrected to inspect both `provenance`
and optional `source_manifest`, require every old aggregate to bind its recorded
map, reject any other live mismatch, and verify all source-binding files live
after replacement. The second pass changed exactly four sections and retained
a byte-identical non-source-binding projection.

A separate byte-level proof removes the exact ten-line, 598-byte V9E
`check-xret-current-mode` target block from the live Makefile and reconstructs
the old hash
`81c2cb305f0b3d0a9bd77c64f508ebe06562c658b9034256ccb93378080263e9`.
The live bytes match the new hash
`c7183f85d6f0bfa47f46e18bbde1cfb3698300727b7da6af9241e06ecee7b535`.
Therefore no unrelated Makefile byte is hidden by the rebind.

Final directed architecture gates are 9/9 GREEN. Architecture result SHA-256:
`00b7467f7c51ccaab74ab81ea6c593d28270c26b6f2e2d36bba85f5a9a6dfd88`.

## Architecture and PPA boundary

The independent arch-stable validator accepts the XRET result/ledger binding,
all eight variants, both observer configurations, both focused logs, and the
109-module aggregate. It also recomputes all nine directed architecture gates
under the same RTL identity.

Full core remains an honest `GAP` with 44 blockers. Open/stale architectural
debts, incomplete full-core holder/lifecycle census evidence, missing
same-design full functional aggregate, and incomplete freeze inputs remain.
The result is `ppa=UNQUALIFIED` and `promotion_eligible=false`; no formal area,
timing, power, 200 MHz, or Pareto improvement is claimed. Arch-stable artifact
SHA-256:
`04e8ff709f0b37daf7ea052b06adb58854aebc029d1e77b26cb00733a82d14cc`.

## Reviewer checkpoint

Contract SHA-256
`6e8fb3ae753c124ce4b22d81ab4cd3f809e1826c17a4db3ed36f01b834a504be`
was generated through `create → validate → render` and dispatched verbatim to
a self-contained no-tools reviewer. It returned `PASS` with no P0/P1 and no
unresolved P2. It accepted the seven-case matrix, legal/illegal request and
commit routing, lane1 older-instruction behavior, 8/8 variants, 2/2 observer
configurations, deterministic replay, and corrected two-section provenance
binding.

The reviewer retained explicit limitations: frozen-summary review is not
line-by-line repository reproduction, the listed error models are not formal
completeness, and the result must not be promoted beyond current-design
XRET-G1 closure. The first provenance-only output remains historical evidence;
the final claim binds the corrected second pass.

## AI workflow and database closeout

The stable lessons to publish through the DB-owned memory interface are:

- shared workflow-source changes invalidate every bound architecture record
  even when production RTL and dynamic logs are unchanged;
- architecture evidence may have both `provenance` and optional
  `source_manifest`, so a repair must enumerate every source-binding section;
- a permitted single-file rebind must also prove the actual byte delta, not
  only the path name;
- forward-running the stricter downstream arch-stable consumer is required;
  the first pass's missed field must remain visible as a counterexample;
- precise local RV64 module/signal/transaction wording and no-tools bounded
  review preserve engineering capability while keeping task scope explicit.

- `npc-dev` completed at
  `.github/task-runs/2026-07-22-rv64-xret-current-design-revtag-v9e/`;
- `agent-system` completed at
  `.github/task-runs/2026-07-22-rv64-xret-current-mode-revtag-v9e/`;
- `github-index` completed at
  `.github/task-runs/2026-07-22-xret-current-design-revtag-v9e/`;
- the first `agent-system` attempt at
  `.github/task-runs/2026-07-22-architecture-source-binding-rebind-revtag-v9e/`
  is retained as blocked: its terms matched only profile-owned rule/memory
  paths, so the independent-primary-focus gate correctly failed. Reusing the
  already published NPC fact `rv64 xret current mode` supplied a genuinely
  independent focus and completed without weakening recall policy;
- all profile definitions validate;
- `snapshot-stored` published 6852 DB-owned documents with 6954 manifest
  entries;
- DB-first audit passes with 6962 candidates, 7004 stored records, 6755
  materialized documents, 25 shims, and 6963 backup entries;
- Markdown coverage passes with 9179 active Markdown files, 6962 DB-owned
  files, 25 shims, zero live evidence files, and two live rule files.

Final XRET plus architecture-gate unit tests pass 40/40, the contract hash
revalidates, the Makefile delta proof replays, 11 critical JSON files parse,
and `git diff --check` passes. Strict guard reports 2045 changed paths, derives
exactly `agent-system`, `npc-dev`, and `github-index`, and accepts the three
completed task-runs above.
