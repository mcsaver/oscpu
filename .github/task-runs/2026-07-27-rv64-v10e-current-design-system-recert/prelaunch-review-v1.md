# V10E pre-launch review v1

## Conclusion

`GAP`: do not launch the current-design 6B-cycle systemd-strict run until the
runner evidence chain is corrected.

Contract JSON:
`.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/subagent-contracts/v10e_runner_prelaunch_review_v1.json`

Contract SHA-256:
`cdad55c378c961f0a6444643975db16488bdbd9cba50eede421ce0887de5766a`

## Counterexamples

1. `restore_npc_config` changed `errexit` state inside `finish`; a cleanup or
   later hash failure could exit before `task_run_status_finalize` and leave
   `.status` at `RUNNING`.
2. The runner printed the three `OOO_*` configuration values without proving
   that the generated Verilator command contained their defines. The design-id
   covers RTL sources, not the Makefile mapping.
3. Post-run simulator verification was conditional on `-x`; a missing or
   non-executable simulator could bypass the hash comparison.
4. V10E and V9S used different lock files despite sharing generated NPC config,
   kernel, OpenSBI, DTB and rootfs inputs. Boot artifacts had no post hash.
5. The review scope did not include
   `Linux/scripts/prepare-npc-rootfs-run-image.sh`, so the isolated image copy
   contract was not independently visible.

## Reconciliation

- cleanup does not change `errexit`; a dynamic cleanup fixture proves rc=7
  publishes `FAIL rc=7 stage=cleanup-fixture ... cleanup_rc=7`;
- `VNpcSimTop__verFiles.dat` proves `--assert` and all three required defines;
- the NPC Makefile and generated manifest are hash-bound;
- a missing/non-executable simulator is an explicit post-binding failure;
- config, Makefile, manifest, kernel, OpenSBI and DTB receive pre/post hashes;
- both asynchronous system launchers use one workspace-global lock;
- the rootfs copy helper is hash-bound and the guest binding must show that
  template and initial run-image hashes match;
- 28/28 static counterexample variants are rejected;
- the dynamic rootfs fixture accepts the first copy and rejects reuse with
  rc=4.

No production Verilog/SystemVerilog file changed in this reconciliation.
Versioned reviewer v2 must independently accept the corrected runner before
the long simulation starts.
