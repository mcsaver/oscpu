# T3F fresh 5 ns synthesis provenance

- start: 2026-07-13 11:24 +0800
- base HEAD: `eb9bd3b28d1e913dd35304674503fe503112836a`
- complete `npc/rv64/vsrc` binary diff SHA-256:
  `fc51ceba5058b9f82501a91b9bb88fab515a2900e40137b8ec59756b25319f68`
- `.config` SHA-256:
  `cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`
- Yosys: `0.66+197 (aa18c921a)`
- OpenSTA: `3.1.0`
- user runtime-log snapshot SHA-256:
  `3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`

Selected source SHA-256:

```text
e66944e6c381a152e2572e98cb9f69935e64c27d7adb705256b784430b7e9efe  OooFpIssueQueue.v
75da1a09c154d6aa5aa0d81763557c6281f5860782c46365876797d4677136bd  OooPhysRegFile.v
67c63fc36c4c214b81ed36ac9351025117ce8e431047fee62cd0dadbdb8b69f5  OooIntBackend.v
91feb917557b882c2703fd6b20d4990f5ca3134a39b197f235b53e1bea45a97b  OooFpBackend.v
7a02a4dcec8593f224f1daf88e7fc511f6b13c64378e74d16693dd5fcb06fd36  OooBranchResolveRecoveryGate.v
```

Command:

```sh
timeout --foreground 7200s nice -n 10 make -C npc/rv64 syn \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3f-int-to-fp-sticky-barrier/sta-build \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor" \
  STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
```

The result uses an ideal clock and four placeholder macro Liberty files. It is
for current-source pre-layout path-family, loop, and architecture diagnosis;
it is not physical 200 MHz signoff.

## Result and disposition

- Yosys completed with `Found and reported 0 problems`, `105/105` effective
  ABC mappings, `1414.13 s` elapsed time, and `3631.11 MB` peak memory.
- synthesized netlist SHA-256:
  `ed05a3609ff3c23109d3417506768511438bac00eb79f95d20e4fccc24f87654`
- top area: `1,572,786.04` (`428,920.80` sequential, `27.27%`)
- OpenSTA 5 ns result: `loops=0`, WNS `-12.838 ns`, TNS `-284551.97 ns`,
  estimated power `0.120 W`.
- top40 is now entirely DCache-started; the former integer WB/fast-wake to FP
  execute family is absent.  Flat fanout reports show both integer wake lanes
  terminate only at FP-IQ state flops.
- The T3F architecture cut is retained.  Physical 200 MHz is not achieved;
  the next target is the DCache/MEM same-cycle integer fast-wake path.
