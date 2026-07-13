# T3E fresh 5 ns synthesis provenance

- start: 2026-07-13 10:30 +0800
- base HEAD: `eb9bd3b28d1e913dd35304674503fe503112836a`
- complete `npc/rv64/vsrc` binary diff SHA-256:
  `9d9bea5a29bc18f7a08e79018823a2b1fa11622d629d29f6ac4048eeba1c2b85`
- `.config` SHA-256:
  `cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`
- Yosys: `0.66+197 (aa18c921a)`
- OpenSTA: `3.1.0`
- user runtime-log snapshot SHA-256:
  `3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`

Selected source SHA-256:

```text
7a02a4dcec8593f224f1daf88e7fc511f6b13c64378e74d16693dd5fcb06fd36  OooBranchResolveRecoveryGate.v
19bf9109d076ea78fc65b69cf3cec0b4c7bfaa6c32b12466d5c2070b11e83c67  OooIntBackend.v
91feb917557b882c2703fd6b20d4990f5ca3134a39b197f235b53e1bea45a97b  OooFpBackend.v
1e5bbb3036c549958b7b18ba6765f94d6a9758e8744ed193e1f333e060b11ef6  OooIntIssueQueue.v
1d34697a15fd6442e71be66f8dab08bd848f8b515c698dbd776ee263f6500903  OooPhysRegFile.v
4971aa0e2c30a240f9fc9a5b41f9b2ffdb9f6a2d6840a5f71a33979ad9eab4db  OooDispatchBackend.v
```

Command:

```sh
timeout --foreground 7200s make -C npc/rv64 syn \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3e-checkpoint-capture-isolation/sta-build \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor" \
  STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
```

The result uses an ideal clock and four placeholder macro Liberty files.  It is
for current-source pre-layout path-family, loop, and architecture diagnosis;
it is not physical 200 MHz signoff.

## Result and disposition

- synthesis: `105/105` ABC target blocks; `synth_check` errors `0`
- Yosys time / peak RSS: `1369.86 s` / `3627.29 MB`
- netlist SHA-256:
  `9e466824c50fa13b56b452ef99c4c50693bd3ea1e04dbaecf8ae9f8efb310917`
- cell area: `1,571,315.20`
- OpenSTA combinational loops: `0` (T3E input: `16`; original baseline: `109`)
- OpenSTA WNS / TNS: `-17.23 ns` / `-291670.31 ns`
- total power estimate: `0.120 W`
- OpenSTA summary SHA-256:
  `64f8064d6b37829edffede178b7c92af3c566a7d78973f60917368e24a156d26`
- OpenSTA check-setup SHA-256:
  `9dfdcc9ede24b064e1cce61a03d3754370fa163e77293fa5828f8b66b540785d`

Disposition: **T3E structural cut accepted; overall timing candidate rejected**.
The local mode gate eliminates every reported combinational loop and is kept.
However, once loop cutting no longer truncates the graph, a real DCache to
integer issue/branch/long-op kill to FP issue/convert path measures about
`22.23 ns`.  This snapshot is T3F input evidence, not a 200 MHz result.
