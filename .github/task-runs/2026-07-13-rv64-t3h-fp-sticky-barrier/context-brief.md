# T3H bounded context brief

- command: `python3 scripts/github_index_db.py brief "T3H FP wake sticky FpIssueQueue IntIssueQueue FpPhysRegFile DCache fpld_wb" --profile npc-dev --max-tokens 1800`
- source: `live-or-stored`
- profile: `npc-dev`
- token estimate: `1209 / 1800`
- selected scope: workspace rules, current project status/known issues, `npc-dev` profile,
  and the T3G fresh path-family evidence.
- root cause carried forward: T3G WNS `-12.979 ns`; top1 traverses
  `DCache -> fpld_wb/fp_wake1 -> IntIQ resident FP-store same-cycle select ->
  integer ALU/control -> FetchPacketCache en_i`.
- bounded decision: T3H must cut both FP consumer domains and their data bypass together;
  changing only `OooFpIssueQueue` leaves the proven FP-load-to-store top path intact.
