# T3B/T3C/T3D fresh 5 ns synthesis provenance

- start: 2026-07-13 03:51 +0800
- base HEAD: `eb9bd3b28d1e913dd35304674503fe503112836a`
- complete `npc/rv64/vsrc` binary diff SHA-256:
  `6980418b7b0dd48badc019ab3f2a5845aa6637ff527942361855bdf8ed648990`
- `.config` SHA-256:
  `cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`
- Yosys: `0.66+197 (aa18c921a)`
- OpenSTA: `3.1.0`
- user runtime-log snapshot SHA-256:
  `3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`

Selected source SHA-256:

```text
19bf9109d076ea78fc65b69cf3cec0b4c7bfaa6c32b12466d5c2070b11e83c67  OooIntBackend.v
91feb917557b882c2703fd6b20d4990f5ca3134a39b197f235b53e1bea45a97b  OooFpBackend.v
1e5bbb3036c549958b7b18ba6765f94d6a9758e8744ed193e1f333e060b11ef6  OooIntIssueQueue.v
1d34697a15fd6442e71be66f8dab08bd848f8b515c698dbd776ee263f6500903  OooPhysRegFile.v
4971aa0e2c30a240f9fc9a5b41f9b2ffdb9f6a2d6840a5f71a33979ad9eab4db  OooDispatchBackend.v
4946e8070db1c5243c412610790cbcddbaee08c3402847e509d02fe1237b9c58  OooFreeList.v
1a2d2abd94ea4dee8fb4d850820e853aa50041408b8c0d847a25eb029b794789  OooRenameMap.v
44dc6289103ee615b9d3e6f61acbfb9404a0329a649fd9a6f0f89829ace0fc12  OooBusyTable.v
```

Command:

```sh
timeout --foreground 7200s make -C npc/rv64 syn \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3b-longop-fast-broadcast/sta-build \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor" \
  STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
```

该结果使用 ideal clock 与四个 placeholder macro Liberty，仅作当前源码的 pre-layout
path-family/组合环/架构诊断，不是 physical 200 MHz signoff。

## Result and disposition

- synthesis: `105/105` ABC target blocks completed; Yosys `synth_check` errors `0`
- source-diff SHA-256 at completion:
  `6980418b7b0dd48badc019ab3f2a5845aa6637ff527942361855bdf8ed648990`
- cell area: `1,571,309.60` (`+675.64`, `+0.043%` versus the recorded baseline)
- OpenSTA combinational loops: `16` (baseline `109`)
- OpenSTA WNS: `-16.37 ns` (baseline `-10.001 ns`)
- OpenSTA TNS: `-273561.75 ns` (baseline `-120125.49 ns`)
- total power estimate: `0.120 W` (baseline `0.118 W`)

Disposition: **rejected**.  The candidate materially reduces loop count but does not
eliminate loops, and its WNS/TNS regress beyond the T3 acceptance gates.  This
snapshot is retained as negative architecture evidence and must not be cited as a
200 MHz result.
