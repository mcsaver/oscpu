# RV64core interactive datasheet Rev C refresh

- Date: 2026-07-29
- Scope: `docs/rv64core/study/**`
- Production RTL mutation: none
- Task result: PASS within the static documentation/elaboration scope
- Global worktree guard: GAP, caused by unrelated pre-existing/concurrent paths

## Root cause

The previous HTML encoded an older CSR explanation and accepted a caller-supplied
Verilator XML file without proving that the XML was newer than the current
Makefile, product defaults, filelist and HDL sources.  The current product
configuration enables `OOO_CSR_QUEUE_HEAD=1`, so a stale XML or the old
all-pending CSR narrative could misrepresent the active core topology.

## Implemented result

- Added `docs/rv64core/study/tools/generate_elaboration_xml.sh`.
  It elaborates production `NpcTop` and assertion-enabled `NpcSimTop` from the
  current Makefile/filelist/product configuration.
- The HTML builder now rejects stale elaboration XML before writing output and
  records both the elaboration SHA-256 and a complete source fingerprint.
- The manuals and interactive payload now explain the split CSR domains:
  legal non-FP head0 CSR uses the queue-head ROB path; lane1/FP CSR and
  non-CSR SYSTEM/trap use pending full-drain.
- Added a seven-phase `csr-queue-head` transaction and a dedicated WaveDrom for
  `head0_csr_inflight`, `mem_idle`, C0 commit, C1 apply/serial flush and C2
  quiet.
- Independent review found that the `serial_flush_q` side branch was attached
  to the C1 apply phase.  It was moved to the C0 `CsrFile` phase, and the audit
  now rejects any non-`CsrFile` parent.

## Final artifact

- HTML: `docs/rv64core/study/index.html`
- Size: 1,066,834 bytes
- SHA-256: `73e6975aa440160c61531ce4a3cea236457d58ac2e7592e2ba0a5f8e63752002`
- Source fingerprint:
  `e7ee837ab46b329793bc53600b3809e2617649667f825ab79b36af71f4200add`
- NpcTop XML SHA-256:
  `6cf2f322655e8a49cae0a57aa58bcbb25ba432a6e7804809d985c32057829ead`
- Static inventory: 150 files, 136 modules, 195 instances, 9 transactions,
  38 WaveDrom diagrams, 58 primary phases, 2 side paths, 240 explicit data
  fields, 975 self-check answer slots, 1218 sequential targets and 0 external
  resources.

## Validation boundary

The task proves current-source elaborated topology, document/payload
consistency, embedded-resource integrity and fail-closed freshness behavior.
It does not claim browser dynamic-layout PASS, RTL testbench/DiffTest PASS,
synthesis, STA or PPA qualification.

The scoped strict guard for `docs/rv64core/study` passed with no required e2e
profile.  The full-worktree strict guard saw a large unrelated dirty scope and
lacked fresh `rv64-linux` and `npc-dev` evidence.  Those paths pre-existed or
were concurrent with this docs-only task; the global result remains an explicit
GAP and is not relabelled as a task failure or as RTL/system PASS.
