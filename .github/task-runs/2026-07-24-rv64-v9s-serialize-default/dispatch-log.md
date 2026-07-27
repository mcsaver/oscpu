# V9S dispatch log

- `serialize-evidence-review-v1`
  - mode: self-contained no-tools RTL evidence review
  - contract:
    `.github/task-runs/2026-07-24-rv64-v9s-serialize-default/subagent-contracts/serialize-evidence-review-v1.json`
  - contract SHA-256:
    `5b35956cecfe20bb1d4455c2f57f737909639f284b1cdb165cea904e1061d047`
  - status: completed
  - result: `GAP`
  - reviewer finding:
    the current-design module contract is supported, but defaults must remain
    unchanged until the current-design flag-on strict guest reaches natural
    poweroff; explicit flag-on tests do not prove default propagation.
  - remaining evidence:
    current-design strict rootfs, current-design compile-success mutation
    binding, and a no-override replay after the defaults are changed.

- `strict-systemd-zero-uart-v1`
  - RV64 object:
    current design with `OOO_CSR_QUEUE_HEAD=1` and
    `OOO_TERMINAL_HOLDER_ASSERT=1`
  - configuration:
    rootfs-resident systemd strict helper, zero UART RX
  - result:
    `FAIL`, last checkpoint 320,000,000 retired instructions at
    `pc=0x0000003f8eeca18a`
  - evidence:
    `rootfs-csr-qh-on-current-systemd-strict/driver.log`,
    `guest/console.log`, `binding.txt`,
    `false-pass-classification.md`
  - finding:
    child/outer `make` ended with `Hangup`; strict helper and natural-poweroff
    markers were not observed. The former `PASS` status was a runner
    state-machine false green and has been corrected.

- `task-run-status-fail-closed`
  - status:
    completed
  - implementation:
    `scripts/task-run-status.sh`, both v9s runners,
    detached single-flight launcher
  - verification:
    `scripts/tests/test-task-run-status.sh` PASS;
    `agent-system` profile binding PASS;
    dynamic `e2e_agent_system_task_run_status_fail_closed` PASS;
    all profile bindings PASS
  - boundary:
    no RTL, assertion, coverage, rootfs success criterion, or PPA threshold was
    changed.

- `strict-systemd-zero-uart-rerun1`
  - status:
    `FAIL`, intentionally terminated before a functional conclusion
  - result label:
    `rootfs-csr-qh-on-current-systemd-strict-rerun1`
  - finding:
    shared strict ext4 hash was `d5126b...`, not the pristine `d4cda5...`;
    `NpcSimTop --block` pointed to that shared writable image
  - evidence:
    fail-closed status records `signal=TERM`;
    `rootfs-provenance-classification.md`

- `strict-rootfs-work-image-isolation`
  - status:
    completed
  - implementation:
    `Linux/scripts/prepare-npc-rootfs-run-image.sh`, Linux Makefile/checker
    plumbing, template post-run hash check
  - verification:
    isolated-copy positive PASS; mismatched template SHA rejected;
    RV64 Linux guest-check contract PASS; all profile bindings PASS

- `strict-systemd-zero-uart-rerun2`
  - status:
    `FAIL`, stopped before RTL compilation
  - result label:
    `rootfs-csr-qh-on-current-systemd-strict-rerun2`
  - finding:
    fixed historical ext4/CPIO hashes were invalid clean-build invariants;
    current builder does not normalize ext4 UUID or staged-file timestamps
  - evidence:
    fail-closed status records `stage=rootfs-template-rebuild`;
    `rootfs-build.log`, `rootfs-template-post.txt`

- `strict-rootfs-per-run-attestation`
  - status:
    completed
  - implementation:
    bind the freshly rebuilt template, CPIO, and builder inputs per run;
    compare template/CPIO pre/post hashes and require the work-copy pre-hash
    to equal the fresh template
  - boundary:
    no RTL flag, assertion, guest check, terminal marker, or poweroff
    criterion changed

- `strict-systemd-zero-uart-rerun3`
  - status:
    pending launch
  - result label:
    `rootfs-csr-qh-on-current-systemd-strict-rerun3`
  - success criteria:
    same design/simulator/rootfs bindings, zero UART RX, strict helper PASS,
    natural syscon poweroff, `HIT GOOD TRAP`, template SHA unchanged,
    cleanup rc=0, final status PASS
