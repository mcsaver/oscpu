# T3G fresh 5 ns synthesis provenance

- start: 2026-07-13 12:34 +0800
- base HEAD: `c4a97fbda`
- complete `npc/rv64/vsrc` content-chain SHA-256:
  `1726f947fa182f574bfe045fbf568c64f41d7dbadce9ca7c7ab47f883c278124`
- `.config` SHA-256:
  `cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`
- Yosys: `0.66+197 (aa18c921a)`
- OpenSTA: `3.1.0`
- preserved user runtime-log SHA-256:
  `3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`

Selected source SHA-256:

```text
f0c922c5bdbd001865634d4b973ba16d6dcfd10eac748484fab319b185e81140  OooIntBackend.v
55a614f9e093acffa2d50f1f6375251b152c9a353dc4af2184a13bccee8870b5  OooIntIssueQueue.v
aa014d8e8726f60d7f34c27a3804dfc2ca2b74f99b58e21117e3effbc9b760ea  OooDispatchBackend.v
75da1a09c154d6aa5aa0d81763557c6281f5860782c46365876797d4677136bd  OooPhysRegFile.v
```

After synthesis, one contradictory comment at `OooIntBackend.v:2410` was
corrected from "full/fast" to "formal-only" without changing any declaration,
expression, preprocessor branch, or executable RTL.  The final source-file hash
is `400b4bcbfd3d8d58f8f9afc5a159cc76f3c3a7ba9a25b66786eae63bcdbcad5b`;
the hash above remains the exact synthesis input for reproducibility.

Command:

```sh
timeout --foreground 7200s nice -n 10 make -C npc/rv64 syn \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3g-mem-formal-only/sta-build \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor" \
  STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
```

本结果使用 ideal clock 与四个 placeholder macro Liberty，仅用于 current-source
pre-layout 路径族、组合环和架构切点诊断，不是 physical signoff。

## Result and disposition

- Yosys completed with three `Found and reported 0 problems` checks, one normal
  `End of script`, and `105/105` effective ABC mappings in each mapping pass
  (`110` candidates minus `5` empty cones). Runtime was `1403.92 s`; peak memory
  was `3643.16 MB`.
- synthesized netlist: `68,328,773` bytes, `110 module / 110 endmodule`, SHA-256
  `95bac1a0e1ecc0fe3154d1461997098caf0f8182760fb9b111aacd95f79ef7b4`.
- top mapped stdcell area: `1,573,356.12` (`428,920.80` sequential, `27.26%`;
  `1,144,435.32` combinational). Relative to T3F this is `+570.08` / `+0.03625%`;
  placeholder macro area remains unknown.
- independent OpenSTA at 5 ns: `loops=0`, WNS `-12.979 ns`, TNS `-287092.31 ns`,
  estimated power `0.120 W`.
- top40 is entirely DCache-started. The integer MEM fast payload was removed, but
  the new top1 is the remaining FP-load `fpld_wb/fp_wake1` to IntIQ FP-store
  same-cycle issue path, ending at FetchPacketCache payload SRAM `en_i`.
- focused reports: DCache to int ex0/ex1 stage `-4.900/-7.150 ns`, DCache to FP
  exec1 `-8.149 ns`, FpIQ Q to FP exec1 `-3.484 ns`, and DCache to fetch payload
  `en_i` `-12.979 ns`. T3G is retained as a verified architecture cut; 200 MHz
  remains open and the FP wake domains are the next physical target.
