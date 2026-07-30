# V10E dispatch log

## Round start

- primary classification: `verification`
- auxiliary classification: `tooling/workflow`
- local object: current RV64 design `c1b531…bb594`, queue-head serialize
  enabled, assertion-on systemd-strict rootfs transaction
- original system observation: historical `c358ce…c07e8d` reached 16/17
  strict labels and 710,753,508 commits, then exhausted 3B cycles before
  `dmesg-no-critical`, strict done and poweroff
- current debt: `SERIALIZE-G1=P1 OPEN`
- experiment budget: 6B guest cycles / 100,000 host seconds
- promotion: `architecture_freeze=GAP`, `ppa=UNQUALIFIED`,
  `promotion_eligible=false`
- shell ownership: primary agent

No production RTL is modified in runner preparation. The expanded cycle
budget preserves all guest checks, assertions and terminal success criteria.

## Pre-launch runner review

- task: `v10e_runner_prelaunch_review_v1`
- mode: read-only independent counterexample review
- contract:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/subagent-contracts/v10e_runner_prelaunch_review_v1.json`
- contract SHA-256:
  `cdad55c378c961f0a6444643975db16488bdbd9cba50eede421ce0887de5766a`
- contract pipeline: `create → validate → render` PASS
- review boundary: current design/config/assertion/rootfs/17-label/terminal-exit
  binding and false-green paths
- shell ownership: transferred to the contracted reviewer for its bounded
  read-only commands; primary and other agents run no WSL engineering command
  until ownership returns
- parent status: active; the long system simulation is not launched before
  review reconciliation

### Reviewer v1 result and implementation reconciliation

- reviewer conclusion: `GAP`; shell ownership returned with no residual
  engineering process
- counterexample 1: `restore_npc_config` could re-enable `errexit` before
  `task_run_status_finalize`, leaving a failed run at `RUNNING`
- counterexample 2: printed `OOO_*` values did not prove the generated
  `NpcSimTop` contained the three required Verilator defines
- counterexample 3: a missing/non-executable post-run simulator skipped the
  post-hash comparison
- counterexample 4: V10E and the historical V9S launcher used different lock
  inodes, while kernel/OpenSBI/DTB were not post-hash checked
- scope request: include
  `Linux/scripts/prepare-npc-rootfs-run-image.sh` in the next review

Implemented before launch:

- cleanup no longer changes the shell `errexit` mode; dynamic status fixture
  records `FAIL rc=7 stage=cleanup-fixture ... cleanup_rc=7`
- the generated `VNpcSimTop__verFiles.dat` must contain `--assert`,
  `+define+OOO_CSR_QUEUE_HEAD=1`, `+define+OOO_ASSERT` and
  `+define+OOO_TERMINAL_HOLDER_ASSERT=1`
- NPC Makefile, generated Verilator manifest, Kconfig outputs, simulator,
  kernel, OpenSBI firmware and DTB receive pre/post hashes; a missing or
  non-executable simulator is an explicit binding failure
- V10E and V9S launchers share
  `.github/runtime-artifacts/rv64-engineering-single-flight.lock`
- the rootfs copy helper is hash-bound; the guest binding must prove the
  writable run image started from the current template hash
- static negative matrix: 28/28 counterexamples rejected
- dynamic rootfs fixture: initial copy/hash PASS; existing run image rejected
  with rc=4

The long system simulation remains unlaunched pending versioned reviewer v2.

## Pre-launch runner review v2

- task: `v10e_runner_prelaunch_review_v2`
- contract:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/subagent-contracts/v10e_runner_prelaunch_review_v2.json`
- contract SHA-256:
  `9ea21c8a9a038762e9817ef40c0ddd7f822efcff11cfad844b41c223b58ecbb6`
- contract pipeline: `create → validate → render` PASS
- expanded inputs: rootfs copy helper, V10E/V9S launchers, generated
  Verilator manifest binding and immutable boot-artifact post hashes
- shell ownership: transferred to the v2 reviewer; primary and other agents
  run no WSL engineering command until ownership returns
- launch condition: reviewer v2 must accept the corrected fail-closed chain

### Reviewer v2 result and implementation reconciliation

- reviewer conclusion: `GAP`; shell ownership returned with no residual
  engineering process
- new counterexamples: PASS status write failure, cleanup signal window,
  post-binding output failure, assertion-query read error, runtime control
  script drift and background lock-loss without status publication
- `scripts/task-run-status.sh` now treats a failed PASS write as a non-zero
  result and attempts a FAIL fallback carrying `status_write_rc`
- cleanup defers HUP/INT/TERM, records the signal, captures terminal-query and
  post-binding write return codes, then finalizes status before exit
- `rg` return `1` remains the only accepted no-match result; return `>1` is a
  run failure, including missing assertion logs
- runner, status helper, Linux/NPC Makefiles, guest checker, strict checker,
  transaction parser and rootfs copy helper are pre/post hash-bound
- actual V10E/V9S background `flock` uses explicit contention rc=73; if the
  child exits before status initialization, the launcher publishes
  `FAIL stage=launcher-lock-or-init`
- pre-launch self-test output is durable at `prelaunch-contract.log` and is
  itself hash-bound by the runner
- static negative matrix: 40/40 counterexamples rejected
- dynamic fixtures: PASS-write fallback PASS; shared-lock contention rc=3;
  cleanup rc=7; cleanup TERM rc=143; post-binding output rc=1; missing
  assertion log `rg rc=2`; rootfs reuse rc=4
- terminal success now requires exactly one strict-done, poweroff-begin,
  syscon terminal, system-reset exit and `HIT GOOD TRAP` marker

The long system simulation remains unlaunched pending versioned reviewer v3.

## Pre-launch runner review v3

- task: `v10e_runner_prelaunch_review_v3`
- task kind: verification
- contract:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/subagent-contracts/v10e_runner_prelaunch_review_v3.json`
- contract SHA-256:
  `0af8b5154790a3ecff4a879f9d8d4de0852d518ae65a42933a3fd965fae023dc`
- contract pipeline: `create → validate → render` PASS
- write scope:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v3`
- verification boundary: syntax, task-status suite, 40 static negative
  variants, seven dynamic fixtures, current design-id and V2 reconciliation
- shell ownership: transferred to the V3 verifier; primary and other agents
  run no WSL engineering command until ownership returns

### Reviewer v3 result and implementation reconciliation

- reviewer conclusion: `GAP`; shell ownership returned with no residual
  engineering process
- exact production assertion regex returned `rg rc=2` because the
  single-quoted runner argument contained two backslashes before literal
  brackets
- the prior self-test only queried the simplified `RTL assertion` pattern,
  so its 40/40 static and 7/7 dynamic PASS did not prove that the production
  regex compiled
- V3 did not independently recompute `rtl_binding()` because its validated
  contract did not include `npc/rv64/vsrc/**`; this remains a scope GAP, not
  an inferred design-id PASS
- runner now defines one `assertion_failure_regex` value with the correct
  single-backslash bracket escapes; the self-test extracts that production
  value and observes match/no-match/read-error return codes `0/1/2`
- a new `overescape-assertion-regex` compile-success static mutation is
  rejected; the corrected matrix is 41/41 static negative mutations plus
  7/7 dynamic fixtures
- primary-agent syntax, self-test and launcher validate-only checks pass
  after the correction

The long system simulation remains unlaunched pending versioned reviewer v4.

## Pre-launch runner review v4

- task: `v10e_runner_prelaunch_review_v4`
- task kind: verification
- contract:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/subagent-contracts/v10e_runner_prelaunch_review_v4.json`
- contract SHA-256:
  `e15a69c817ff6ee1e45e84419be653fae70c3502cc477b0de6748e216654c931`
- contract pipeline: `create → validate → render` PASS
- write scope:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v4`
- verification boundary: runner and launcher syntax, task-status suite,
  41 static negative variants, seven dynamic fixtures, the exact production
  assertion regex, current `rtl_binding()` design-id and V3 reconciliation
- expanded read scope: `npc/rv64/vsrc/**` and
  `npc/rv64/eval/ppa/tools/**`, solely to recompute the current RTL binding
- launch condition: reviewer v4 must independently close both V3 gaps and
  find no new fail-closed or false-green path

### Reviewer v4 result

- reviewer conclusion: pre-launch `PASS`; shell ownership returned and the
  workspace-global lock was reacquired nonblocking with rc=0, then released
- runner/V10E launcher/V9S launcher/status-helper syntax: rc=0
- status-helper directed suite: rc=0
- static negative matrix: 41/41 rejected, including the exact production
  assertion regex over-escape mutation
- dynamic fixtures: 7/7; the production assertion regex observes
  match/no-match/read-error rc=`0/1/2`
- live `architecture_hard_gates.rtl_binding()` over 146 RTL source files:
  pre/post `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`
- 16 declared control inputs show no pre/post drift; the V4 evidence checksum
  manifest verifies 15/15 files
- five terminal-marker success guards remain `-eq 1`; no deduplication path
  was introduced and no assertion was weakened
- scope boundary: no long simulation was run, so 17/17 guest transactions,
  natural poweroff, reset-syscon, `GOOD TRAP` and clean simulator exit remain
  unobserved

The current run is eligible for one fail-closed, single-flight launch after
the primary agent repeats the final pre-launch checks.

## Launch attempt a1 and preflight reconciliation

- label: `rootfs-c1b531-systemd-strict-6b-a1`
- launcher result: initial `RUNNING` was published, then the runner finalized
  `FAIL rc=1 stage=runner-preflight evidence_complete=0 cleanup_rc=2`
- no simulator build or guest cycle executed; no RTL conclusion is permitted
- root cause: tracked file
  `Linux/scripts/check-npc-systemd-guest.sh` has Git mode `100644` and is
  invoked as `bash "${guest_checker}"`, while the runner incorrectly required
  `test -x "${guest_checker}"`
- cleanup rc=2 is secondary: terminal evidence inputs did not yet exist at
  this early stage and the evidence queries correctly rejected those missing
  paths
- correction: require the Bash input to be readable and nonempty, retain its
  pre/post SHA-256 binding, and do not change its tracked mode
- new static mutation `require-guest-checker-executable` is rejected
- new dynamic fixture executes a readable non-executable mode-0644 Bash input
  with rc=0
- corrected primary-agent matrix: 42/42 static negative mutations and 8/8
  dynamic fixtures; `a2` launcher validate-only PASS

Attempt a1 evidence is immutable and retained. Attempt a2 remains unlaunched
pending a versioned independent reviewer v5.

## Pre-launch runner review v5

- task: `v10e_runner_prelaunch_review_v5`
- task kind: verification
- contract:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/subagent-contracts/v10e_runner_prelaunch_review_v5.json`
- contract SHA-256:
  `fe7adac029fa7341f8b44c74b734ce21d3ce804403919740aedaaac36e7f1760`
- contract pipeline: `create → validate → render` PASS
- write scope:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v5`
- verification boundary: a1 preflight root cause, tracked/current helper mode,
  Bash invocation semantics, 42 static mutations, eight dynamic fixtures,
  a2 validate-only, production assertion regex, live RTL binding, target
  vacancy and workspace-global lock
- launch condition: reviewer v5 must independently accept the corrected
  preflight contract before a2 can start

### Reviewer v5 result

- reviewer conclusion: corrected pre-launch `PASS`; shell ownership returned
  and the workspace-global lock was reacquired nonblocking with rc=0, then
  released
- a1 is bound to `runner-preflight` with no config/build/simulator/guest
  artifact; no RTL cycle or RTL conclusion occurred
- guest checker tracked/current mode is `100644`, current file is readable,
  nonempty and non-executable, and production invocation is through Bash
- static negative matrix: 42/42, including rejection of a reverted
  `test -x "${guest_checker}"` preflight
- dynamic fixtures: 8/8, including a mode-0644 Bash input with rc=0
- a2 validate-only: rc=0; result/status/runtime targets remain absent
- production assertion regex: match/no-match/read-error rc=`0/1/2`
- live RTL binding over 146 files:
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`
- 22 immutable inputs show no drift; 26/26 V5 evidence checksums verify
- five terminal-marker guards remain exactly `-eq 1`; assertions and raw
  terminal-event semantics are unchanged

Attempt a2 is eligible for one fail-closed, single-flight launch after the
primary agent repeats the final target-vacancy and lock checks.

## Launch attempt a2

- label: `rootfs-c1b531-systemd-strict-6b-a2`
- launched at: `2026-07-27T18:46:03.051259024+08:00`
- launcher PID: `634431`
- initial status: `RUNNING`
- bound limits: 6,000,000,000 guest cycles, 100,000 host seconds,
  1,000,000-cycle commit gap and 5,000,000-cycle progress interval
- first observation: canonical NPC config completed and the runner entered
  `rootfs-template-rebuild`; this is beyond the a1 preflight failure
- current boundary: simulator build, guest commits, strict transactions and
  terminal markers have not yet been observed
- ownership: the background runner exclusively holds the workspace-global
  RV64 engineering lane; status inspection uses Windows PowerShell read-only
  access to WSL files

### Attempt a2 result and define-binding reconciliation

- final status:
  `FAIL rc=1 stage=simulator-define-binding evidence_complete=0 cleanup_rc=2`
- rootfs build/static check and simulator build completed; no guest cycle
  started and no RTL conclusion is permitted
- generated `VNpcSimTop__verFiles.dat` contains `--assert`,
  `+define+OOO_CSR_QUEUE_HEAD=1`, `+define+OOO_ASSERT` and
  `+define+OOO_TERMINAL_HOLDER_ASSERT`
- root cause: the runner incorrectly required the last token as
  `+define+OOO_TERMINAL_HOLDER_ASSERT=1`
- `npc/rv64/Makefile` intentionally emits the no-value macro because the RTL
  consumes it with `` `ifdef OOO_TERMINAL_HOLDER_ASSERT``; the make variable
  value `1` controls whether the macro is emitted, not the macro replacement
  text
- correction plan: bind the runner grep to the Makefile-emitted token, add a
  cross-check fixture that extracts the Makefile definition, and reject a
  mutation that restores the incorrect `=1` expectation

Attempt a2 evidence and its isolated simulator build remain immutable. Attempt
a3 remains unlaunched pending corrected self-tests and a versioned reviewer.

## Pre-launch runner review v6

- task: `v10e_runner_prelaunch_review_v6`
- task kind: verification
- contract:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/subagent-contracts/v10e_runner_prelaunch_review_v6.json`
- contract SHA-256:
  `7c62fba90d357837866db7e3654a9fa34047e7d190607264a738eb9d9b7f7792`
- contract pipeline: `create → validate → render` PASS
- write scope:
  `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v6`
- verification boundary: a2 stage/artifacts, Makefile definition source,
  actual a2 Verilator manifest, corrected runner pattern, 43 static
  mutations, nine dynamic fixtures, a3 validate-only, live RTL binding,
  target vacancy and workspace-global lock
- launch condition: reviewer v6 must independently accept the three-way
  define binding before a3 can start

### Reviewer v6 result

- reviewer conclusion: corrected pre-launch `PASS`; single-flight shell
  ownership returned and the workspace-global lock was reacquired
  nonblocking with rc=0, then released
- a2 is bound to `simulator-define-binding`; its rootfs and simulator builds
  completed, but no guest cycle, transaction checker or terminal event ran
- `npc/rv64/Makefile`, the actual a2
  `VNpcSimTop__verFiles.dat` and the corrected runner agree on the
  presence-only `+define+OOO_TERMINAL_HOLDER_ASSERT` token; the incorrect
  `=1` oracle has zero production occurrences
- static negative matrix: 43/43; dynamic fixtures: 9/9, including the
  Makefile/manifest/runner define binding
- a3 validate-only: rc=0; result/status/runtime targets remained absent
- production assertion regex: match/no-match/read-error rc=`0/1/2`
- live RTL binding over 146 files:
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`
- 26 immutable inputs show no drift; 25/25 V6 evidence checksums verify
- five terminal-marker guards remain exactly `-eq 1`; no terminal-event
  deduplication was added and no assertion was weakened
- scope boundary: 17/17 guest transactions, natural poweroff,
  reset-syscon, `GOOD TRAP` and clean simulator exit remain unobserved

Attempt a3 is eligible for one fail-closed, single-flight launch after the
primary agent repeats the final syntax, contract, target-vacancy, live
design-id, process-vacancy and workspace-lock checks.

## Launch attempt a3 result and frozen-oracle classification

- source status remains immutable:
  `FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`
- A3 executed 5,071,521,696 cycles and committed 1,223,536,213 instructions
- strict history is 16/17, `done_rc=1`, with the sole FAIL marker
  `__NPC_CHECK_FAIL__:dmesg-no-critical`
- the SHA-bound raw guest console contains strict-done, poweroff-begin,
  kernel power-down, syscon poweroff, `GOOD TRAP` and system-reset clean exit
  exactly once and in order
- `rtl-assertion-failures.txt` is empty; design-id, simulator, configuration,
  kernel, OpenSBI, DTB and rootfs launch bindings show no pre/post drift
- the failing oracle was the embedded unbounded `BUG:` token, which matched
  two `printk: debug:` lines

The raw A3 FAIL is retained. Its system transaction is classified separately
as `SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE`.

## A4 interruption

- source status:
  `FAIL rc=143 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=143 signal=TERM`
- the exact process group was terminated after the four full-rerun triggers
  were checked and found absent
- no A4 file was deleted or promoted; A4 is not system PASS evidence

## V10F checker replay V2

- canonical task-run:
  `.github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2`
- the actual checker extracted read-only from the frozen A3 rootfs has
  SHA-256 `83b6a538…053f9a`, equal to A3 `strict_checker_sha256`
- extracted legacy regex over the frozen A3 console reproduces exactly two
  `printk: debug:` matches; the current bounded regex has zero A3 matches
- directed checker tests are 3/3: benign debug text is accepted and a real
  `BUG:` fixture remains rejected
- independent contract-bound reviewer verdict:
  `APPROVED_NOT_PROMOTION_ELIGIBLE`; contract SHA-256
  `f4db46c5…bc21`; single-flight shell ownership returned
- nonblocking reviewer note: a future replay-tool version should compare the
  A3/A4 generated filename sets bidirectionally; the approved V2 remains
  immutable
