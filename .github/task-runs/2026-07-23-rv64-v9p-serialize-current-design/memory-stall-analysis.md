# V9P dual-memory replay-capacity stall analysis

## Scope and verdict

- Object: `OooIntBackend` bank-local MIQ/retry/admission logic and
  `OooMemAxiBridge` active/station/`S_SQ_QUERY` residency.
- Configuration: the instrumented Linux run used
  `OOO_CSR_QUEUE_HEAD=1` plus `CONFIG_NPC_DEBUG_PORTS=y`.
- Dynamic window: zero-based last commit `#42095411`, total committed
  instructions `42095412`, followed by 512 cycles with no further commit.
- Current verdict: `GAP`.  The trace proves a reachable finite-capacity
  no-progress cycle, but the current 64-bit diagnostic packet does not expose
  enough identity and reason fields to name the exact blocking StoreQueue
  entry or its replay reason.
- Independent review contract:
  `.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/subagent-contracts/memory-stall-review-v1.json`,
  SHA-256
  `62f3a7c76cfbbaad410e9cfc29f2904504dc86e82b6496921a149ebbd9e38666`.

## Dynamic facts

The last committed instruction is at `0xffffffff802b5204`.  The following 512
cycles do not change the commit count.  The final 32-cycle ring contains a
repeating three-cycle pattern:

| Cycle phase | Bank 0 | Bank 1 | Shared state |
|---|---|---|---|
| `3k` | bridge state 12 (`S_SQ_QUERY`), station valid, exact active LOAD query, replay, retry credit low, retry0 valid/selected/granted | bridge state 12, exact active LOAD query, replay, retry credit high | SQ nonempty; no SQ drain, ordinary issue, or store grant |
| `3k+1` | unchanged | bridge idle; retry1 valid/selected/granted | both retry requests selected; no SQ grant |
| `3k+2` | unchanged | bridge idle with station valid; retry1 cleared and MIQ load resident | next cycle returns to the `3k` state |

The three packed diagnostic values are:

- `0xcbc00417fcfca5cc`: both bridges in state 12; bank0 replay has no retry
  credit; bank1 replay has retry credit.
- `0x49400c3d5450250c`: bank0 in state 12 and bank1 idle; both retry candidates
  are selected.
- `0xcbc004155450270c`: bank0 in state 12 and bank1 idle; bank1 retry has
  re-entered station/MIQ residency.

External AXI request/response outstanding counts are zero throughout the
terminal snapshot.  Therefore this is not an external AXI response wait.

## RTL derivation

The following statements are RTL derivations rather than direct trace fields:

1. Bank0 contains three distinct capacity holders:
   an active exact LOAD in `S_SQ_QUERY`, a registered station owner, and the
   single retry0 holder.  `S_SQ_QUERY` does not advance the active request,
   while the full station keeps retry0 request READY low.  The active replay
   cannot capture because retry0 is already valid.
2. Bank1 repeatedly captures an active replay into retry1, reissues the retry
   into the station/MIQ, and returns it to the active query.  Each individual
   holder changes state, but the transaction has no terminal transition.
3. The current F4 admission fence is only
   `mem_retry{0,1}_valid_q`.  It permits a second same-bank load to enter while
   another load occupies active/station residency.  If the older load later
   replays behind an older nonterminal SQ owner, the sole retry holder and
   bridge station can become mutually capacity-blocked.
4. `issue0_sq_block_r` and `issue1_sq_block_r` already implement the
   candidate-specific age fact required for the earliest safe prevention
   edge: a valid, nonterminal SQ entry is older when it has sent its request or
   when `rob_idx_older_than()` orders it before the candidate reservation.

Token disjointness proves only that the retry holder is not a duplicate copy
of an active/station token.  It does not prove bounded progress.

## Unknowns

The current diagnostic packet does not expose:

- full ProducerId/ROB index for active, station, retry, and blocking SQ owners;
- full SQ/MIQ counts and the exact blocking SQ entry;
- SQ entry `fill`, `request_sent`, `terminal`, class, overlap, or poison
  reason;
- the selected StoreQueue replay reason;
- explicit bridge request READY/fire and retry capture/fire.

Consequently the reachable capacity loop is proven, but the Linux trace alone
cannot distinguish an older-SQ unfilled/unknown-class replay from an
attribute, head-authority, overlap, or identity-related replay.  The
candidate-specific older-SQ relation is established by the RTL admission
path, not by a dynamically decoded owner-age tuple.

## Candidate correction

Preferred correction: preserve the retry-valid fence and additionally block a
candidate ordinary load only when both conditions hold:

1. `issue*_sq_block_r` says the candidate has an older nonterminal SQ owner;
2. the selected bank already contains an active or station LOAD.

This keeps the SQ-empty F4 current/next handoff and adds no architectural
owner state.  It does add the existing SQ age scan to the dual-memory issue
admission cone, so it is an architecture correction requiring synthesis and
STA evidence; it is not a PPA improvement claim.

Rejected for this round:

- Restoring the F3 active/station fence for every load is safe but suppresses
  the proven SQ-empty F4 handoff.
- Adding a second retry holder duplicates a wide transaction packet and
  requires new age/fairness, flush, terminal, and residency rules; additional
  capacity alone does not establish progress.

## RED/GREEN evidence plan

1. Add a focused bank0/bank1 admission matrix to
   `tb_ooo_int_backend.sv`.
2. With retry empty, force a real live LOAD identity into active and station
   query sources.  Present a same-bank ordinary LOAD candidate and force only
   the already-derived `issue*_sq_block_r` age result.
3. Current RTL must fail because it admits the candidate.  Corrected RTL must
   hold it.
4. Clear the older-SQ relation while keeping active/station residency; the
   candidate must remain admitted, preserving the F4 control case.
5. Add an immediate RTL assertion for an actual request selected across
   `older_sq && same_bank_load_residency`.
6. Use a compile-success mutation that removes only the new
   older-SQ/residency term; the focused marker/assertion must reject it.
7. Regress retry capture/repush, exact owner terminal, selective recovery,
   clean-load F4 handoff, both bridge modules, the live 110-module inventory,
   330-case fullstate, and strict Linux rootfs natural poweroff.

## Post-correction strict rootfs observation

The first same-design strict run after the candidate-specific admission
correction used RTL design ID
`sha256:9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a`
with `OOO_CSR_QUEUE_HEAD=1`.  It did not satisfy the promotion gate:

- the run passed the former terminal UART point at kernel time `0.443147`;
- it mounted the ext4 root, completed the wrapper preflight, entered systemd
  PID1, printed the Ubuntu 22.04 banner, and reached
  `Hostname set to <ysyx-ubuntu2204>` at kernel time `2.326394`;
- it did not print `__NPC_CONSOLE_SHELL_READY__` or reach natural poweroff
  before the declared 10800-second host window;
- `timeout` returned 124, the guest checker rejected the run, and the
  task-run status is `FAIL rc=2`.

This is evidence that the old `0xffffffff802b5204` terminal state was crossed,
but it is not evidence that the new terminal point is another RTL
no-progress cycle.  The ordinary rootfs build had debug ports disabled and
the host timeout did not emit a final commit snapshot.

The next diagnostic therefore uses a default-off host observer,
`NPC_COMMIT_GAP_LIMIT_CYCLES`, in `cpu-exec.cpp`.  Once at least one RV64
instruction has committed, the observer records the latest commit cycle and
count.  If the declared number of RTL cycles elapses without another commit,
it reports the existing recent-commit ring, recent-cycle ring, and
`debug_mem_diag_o` packet, then exits with diagnostic return code 3.  It does
not modify RTL, architectural state, guest memory, or the normal simulator
path when the environment variable is absent.

## Post-correction commit-continuity diagnostic

The observer was first checked against `rv64mi-p-csr.bin`.  The local RV64
smoke reached `TOHOST PASS` after 3,549 RTL cycles and 279 commits without
firing the observer.  The same debug-port simulator was then run against the
rootfs stack with a 1,000,000-cycle commit-gap limit and a 7,200-second host
budget.

The rootfs run is bound to:

- RTL design ID
  `sha256:9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a`;
- simulator SHA-256
  `3fc03a73ab5b8e4481ab521055c8cab4d4720d805d000dc062bbcd3fceb3c727`;
- `OOO_CSR_QUEUE_HEAD=1` and `CONFIG_NPC_DEBUG_PORTS=y`.

Within the declared host budget the run:

- crossed the former 42,095,411-commit terminal point;
- mounted the ext4 root, passed the wrapper preflight, executed systemd PID1,
  printed the Ubuntu 22.04.5 banner, and set the expected hostname;
- reached the fixed progress marker at 145,000,001 commits;
- recorded a later U-mode sample at commit 146,027,279;
- was interrupted by the host budget at PC `0x0000003fbdba3808` after
  560,316,484 RTL cycles;
- never emitted the 1,000,000-cycle commit-gap expiration marker.

This result is `PASS` for the bounded commit-continuity diagnostic:
`diagnostic_outcome=no_commit_gap_within_host_budget`.  It proves that the
old bank-local replay-capacity loop did not recur through this much longer
execution window.  It is not a strict rootfs promotion result because the
run did not reach `__NPC_CONSOLE_SHELL_READY__` or natural poweroff.

The first version of the one-shot runner expected only diagnostic return code
3 and therefore wrote `FAIL rc=1` after GNU `timeout` returned 124.  That
status is retained as historical harness evidence.  The independent
classification is recorded in
`rootfs-commit-gap-diagnostic.classification.json`, with
`rootfs_gate_status=UNRESOLVED` and
`rootfs_promotion_eligible=false`.  The runner now persists its simulator
return code before classification and accepts either:

1. return code 3 with the recent commit/cycle/memory snapshot; or
2. return code 124 with ongoing commit progress, a host-budget interrupt, and
   no commit-gap expiration.

The next system gate must use the strict guest command path and a larger host
budget.  Only shell-ready plus the declared guest checks and natural
reset-syscon poweroff can make that gate GREEN.
