# T3H fresh 5 ns synthesis / STA provenance

- synthesis start: 2026-07-13 14:00:47 +0800
- base HEAD: `bd9bfe3bcfaa12683561b778164360077b17a986`
- synth RTL manifest: 110 files, SHA-256
  `c1d8467998b9cdb667c9182da3ed2ad827fbe4e0ef0e6b0825a9697a06f2dbe0`
- complete `npc/rv64/vsrc` manifest: 128 files, SHA-256
  `e14811d9aec8ac16d0813280e4bd9df929ca1154fc2ce2ade6edfefe04267551`
- flow/config manifest: 5 files, SHA-256
  `bd2e2441042d7d9478a23a85afed879f651d2e491120fda260136b92da178586`
- `npc/rv64/.config` SHA-256:
  `cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`
- Yosys: `0.66+197 (aa18c921a)`
- OpenSTA: `3.1.0 ceb7e6389d`
- preserved user runtime-log SHA-256:
  `3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`

Selected synthesis-input SHA-256:

```text
31a751890180671e1a4e919d3d9e6a58b09aa42173c24a5816f2b10420441af8  OooFpIssueQueue.v
f07cb1586d7dbb77474210e9c20e274d75287df86f1259ecaa7de048fe4bbafa  OooIntIssueQueue.v
7237911b33f9b0992d9fc32529505be27ac246f527f57d3b8d656baaf87275f0  OooFpPhysRegFile.v
```

Command:

```sh
timeout --foreground 7200s nice -n 10 make -C npc/rv64 syn \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3h-fp-sticky-barrier/sta-build \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor" \
  STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
```

The pre/post manifests compare byte-for-byte equal.  This run uses an ideal
clock and placeholder Liberty for four black boxes; it is architecture timing
evidence, not physical signoff.

## Synthesis result

- exit code 0; one normal `End of script`; three Yosys checks plus
  `synth_check.txt` each report zero problems.
- two ABC passes, each with 110 candidates, 5 empty cones and 105 effective
  mappings. Runtime `1416.62 s`, peak memory `3609.84 MB`.
- `NpcTop.netlist.v`: 68,022,941 bytes, 110 `module` / 110 `endmodule`, SHA-256
  `f27b937f50fcccec453a5823983de6c26f0efc13baac6823373ea5ad3af2a8f7`.
- known standard-cell area `1,572,550.00`, of which `428,920.80` sequential
  (`27.28%`). Relative to T3G, area is `-806.12` (`-0.051236%`). Macro area is
  unknown.
- 81 unique / 166 total warnings match T3G; no ERROR, latch, multiple-driver or
  combinational-loop warning was found. Twelve pre-existing keep-hierarchy
  selector misses remain a flow risk.

## Independent OpenSTA result

- exact period: 5.0 ns; top40 count 40; no combinational-loop diagnostic.
- WNS `-10.10 ns`, TNS `-201564.20 ns`, estimated power `0.120 W`.
- compared with T3G (`-12.979/-287092.31`), T3H removes the FP-load wake/data
  long arcs but does not meet 200 MHz.
- directed legal DCache control residuals to int ex0/ex1 and FP exec1 are
  `+1.468/+1.373/+0.155 ns`.
- 20 forbidden wake/write-through reports are `NO_TIMING_PATH`; six wake/write
  fanout reports terminate only in their owning state. The fail-closed checker
  passes on fresh T3H and fails on the exact T3G netlist.
- FpIQ Q to FP exec1 remains `-3.516 ns`. Global top1 is now EX0 state through
  integer fast wake/select and PRF fast bypass, then ALU/ROB/redirect to the
  FetchPacketCache payload SRAM enable, slack `-10.097 ns`.
