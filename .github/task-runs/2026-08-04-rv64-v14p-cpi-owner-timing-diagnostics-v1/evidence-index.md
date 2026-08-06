# V14P owner timing link evidence index

- status: `owner-timing-diagnostics.status` = `PASS`
- command rc: `evidence/owner-timing-diagnostics/command-status.txt`
- bounded link log: `evidence/owner-timing-diagnostics/check.log`, SHA-256
  `e3e0a08b37276378665e45c275331e43f7de783de4b95750ed2f9e251317ccd6`
- frozen input identity: `evidence/owner-timing-diagnostics/input-identity.sha256`, SHA-256
  `69234a19ea4f0ed90d13f3a56951a14e951c0d86ddf0b053d34445f69cc0fb83`
- implementer conclusion: `evidence/owner-timing-diagnostics/implementer-summary.md`
- independent review: `evidence/owner-timing-diagnostics/independent-review-status.md` = `PASS`
  for diagnostic infrastructure only; workload/RTL candidate/PPA remain unauthorized
- current checker replay: `.github/task-runs/2026-08-04-rv64-v14p-owner-timing-checker-replay-v5`
- historical negative replay: V2 remains `FAIL`; it proved that an omitted command-line override
  still inherited `CONFIG_NPC_OOO_STATS=y` from `auto.conf`. The corrected negative injects explicit
  `CONFIG_NPC_OOO_STATS=n`; later versions are separate task-runs and do not rewrite V2.

No Verilator object tree, diagnostic binary or unbounded build log is retained.
