# T3A current-top retry fresh 5 ns synthesis provenance

- start: 2026-07-13 01:58:07 +0800
- parent HEAD: `851049ecea559c79318c1be9604999427cd335e6`
- candidate: physically remove the two RAW-I1-forbidden
  `issue0_current_result -> issue1 operand` muxes in `OooIntBackend`
- candidate `OooIntBackend.v` SHA-256:
  `53cd64847ed0eb87092adf72ce45215564deda2c15030b25bb6d90db1fe64d69`
- complete candidate `npc/rv64/vsrc` binary diff from the archived A base
  `b1b1156db64ee49e0f21c375b55c3b944cc260f0` SHA-256:
  `f58b83d693cad66b6d62d608c1c6f28ad22d713b6f59e7fc7fa1f0ee63a3ab1d`
- `.config` SHA-256:
  `cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`

## Exact A/B input identity

The A baseline is the verified archive
`tmp/2026-07-13-rv64-ifu-access-g1/NpcTop-200MHz-fresh.tar.zst`. Its provenance
records complete `vsrc` binary-diff SHA-256 `ade664147af14bd34109a3e1b64b882e4013ca97820714465fc958b94fc82b43`.

Before this B run, a temporary Git index was populated from the current worktree and only
`OooIntBackend.v` was restored to its parent-HEAD blob
`48a1196bf53e9c1779b52e5121035376c63c9d82`. The resulting complete binary diff from the same
`b1b1156db` base was exactly
`ade664147af14bd34109a3e1b64b882e4013ca97820714465fc958b94fc82b43`.
Thus the archived fresh A and this fresh B have identical RTL inputs except for the candidate;
the pre-existing local frontend/debug/simulation edits are present identically on both sides.

## Command

```sh
timeout --foreground 7200s make -C npc/rv64 syn \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-t3a-retry/sta-build \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES='Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor' \
  STA_KEEP_HIERARCHY_MODULES='OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue'
```

This is an ideal-clock, no-SPEF/CTS/OCV pre-layout diagnostic using four placeholder macro
Liberty models. It can compare path families and architecture cuts, but it is not physical
200 MHz signoff.
