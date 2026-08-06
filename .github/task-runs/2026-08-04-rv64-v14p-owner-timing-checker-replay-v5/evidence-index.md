# V14P owner timing checker replay V5 evidence index

- current fast status: `owner-timing-diagnostics.status` = `PASS`
- frozen-link replay status: `owner-timing-link-replay.status` = `PASS`
- current bounded fast log: `evidence/owner-timing-diagnostics/check.log`, SHA-256
  `7c7779dde9a9cb583ac05e114c90af536ca75074ef8f02c866ec0968ba2099b6`
- replay receipt: `evidence/owner-timing-link-replay/replay.txt`, SHA-256
  `4cb087226f74466361b3e433331ab008f88a068273899b42edb165a815204022`
- replay rc: `evidence/owner-timing-link-replay/command-status.txt`
- immutable source link run:
  `.github/task-runs/2026-08-04-rv64-v14p-cpi-owner-timing-diagnostics-v1`

The replay compares the source simulator/log/input identities, current fast result, tool identity,
148-file production manifest, and exact contract/probe/collector/Make fragment hashes. It does not
authorize workload conclusions, production RTL optimization or PPA promotion.

