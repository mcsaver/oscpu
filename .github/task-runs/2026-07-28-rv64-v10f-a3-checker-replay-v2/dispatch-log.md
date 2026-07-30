# V10F A3 checker replay V2 dispatch log

## Implementer

- owner: `/root`
- action: preserve A3 FAIL, extract the A3 rootfs checker read-only, replay
  legacy/current regexes over the same frozen console and package hashes
- result: `a3-checker-replay-v2.status=PASS`
- marker:
  `[V10F-A3-CHECKER-REPLAY-V2] ... printk_debug=ACCEPT real_bug=REJECT terminal=6/6 cycles=5071521696 commits=1223536213 PASS`
- full-system rerun: not started; A4 preserved as interrupted, not PASS

## Independent reviewer

- task: `/root/v10f_a3_checker_replay_final_review`
- task kind: `read-only-review`
- contract pipeline: canonical `create → validate → render`
- contract:
  `subagent-contracts/v10f-a3-checker-replay-final-review-v1.json`
- contract SHA-256:
  `f4db46c50967c2464b624a35adcec6369e15c9277703de45b10ec61de9edbc21`
- context: only declared local RV64 checker, A3/A4 evidence, replay artifacts,
  `NpcSimTop.sv` and `cpu-exec.cpp`
- commands: `rg`, `sed`, `sha256sum`, scoped `git diff`; read-only
- shell ownership: explicitly transferred before review and returned after
  all commands stopped
- verdict: `APPROVED_NOT_PROMOTION_ELIGIBLE`
- blockers: none
- nonblocking note: add A3/A4 generated filename-set equality to a future
  replay-tool version; do not mutate the approved V2 result

## Record closure

- owner: `/root`
- DB memory: four complete stored documents updated, snapshotted and
  `audit-db-first` PASS
- checker profile:
  `.github/task-runs/2026-07-28-rv64-a3-checker-replay/`, completed
- agent-system profile:
  `.github/task-runs/2026-07-28-a3-printk-debug-replay/`, 11/11 nodes PASS
  after final memory publication
- scoped strict guard: PASS, twelve implementation/documentation/memory paths,
  exactly
  `rv64-systemd-contract` plus `agent-system`
- full dirty-worktree strict guard: FAIL only for unrelated `rv64-linux` and
  `npc-dev` evidence requirements at `changed_paths=836`; preserved as an
  explicit mixed-origin worktree exemption, not rewritten as PASS
