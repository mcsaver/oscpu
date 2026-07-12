# IFU-ACCESS-G1 fresh 5 ns synthesis provenance

- start: 2026-07-13 00:47:50 +0800
- base HEAD: `b1b1156db64ee49e0f21c375b55c3b944cc260f0`
- complete `npc/rv64/vsrc` binary diff SHA-256:
  `ade664147af14bd34109a3e1b64b882e4013ca97820714465fc958b94fc82b43`
- `.config` SHA-256:
  `cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`

Selected source SHA-256:

```text
5e303442e3af5c1d4c114a298db3c0bd49f48691ddf5d0f2ba254f4fbcd7defd  OooFetchAxiBridge.v
5d577d5ff6ff9d75c2c308d3a2b80a5ce16ceb52f4948bcd3f999a29d3e7ba29  AxiXbar.v
a64d74295f417c4135d0521c43e9b2c3d76c6c96d27097b8f9eda4fe38647574  NpcAxiBus.v
7250364ea4773d7ea27a7e81471bf6fd93c523b6fa7478f45abed8267337b878  NpcTop.v
1c5959529fdb555b086b561cec54e543a252007c3f9ec2550739a3fc49436070  OooFetchHeadPairGate.v
89de85b5302b8a54427b754c0398065c2c02d8c5baddbf85942ab68ad8f61da3  OooFrontendDispatchGate.v
7f201682709af56fca8ac1e9c5df5ae1271da6d4c58345c1c2b71bd7d3da6c4b  OooPendingDispatchArbiter.v
```

Command:

```sh
timeout --foreground 7200s make -C npc/rv64 syn \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-ifu-access-g1/sta-build \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor" \
  STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
```

该结果使用 ideal clock 与四个 placeholder macro Liberty；只作当前源码的 pre-layout
path-family/架构诊断，不是 physical 200 MHz signoff。
