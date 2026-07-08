# NpcTop cache+FP blackbox synthesis probe

## 目标

在不启动 Ubuntu/rootfs 的前提下，验证 `NpcTop` 在 `OooFetchPacketCache` 与
`OooFpArithGate` 均作为综合黑盒边界时，full stdcell synthesis 能推进到哪里，并据此判断
`[112]` 的下一处真实综合瓶颈。

## 命令

```bash
timeout 900s make -B -C /home/lyg/PA/ysyx-workbench/npc/rv64 syn \
  STA_DESIGN=NpcTop \
  STA_CLK_FREQ_MHZ=100 \
  STA_SYNTH_PUBLIC_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="OooFetchPacketCache OooFpArithGate"
```

执行脚本：`run_npctop_cache_fp_blackbox.sh`

## 结果

状态：未产出 `NpcTop.netlist.v`，进程在 `OooDataWordCache` gate extraction 阶段被
`timeout` 终止，外层命令返回失败。

关键证据来自 `evidence/NpcTop-cache-fp-blackbox-full.log.gz`：

- line 615-616：`OooFetchPacketCache` 与 `OooFpArithGate` 均被标记为 synthesis blackbox boundary。
- line 184653：Yosys `check` 报 `Found and reported 0 problems`。
- line 4391780：`OooBranchDirectionPredictor` 在优化阶段曾膨胀到 `443077` cells。
- line 4466672：`OooDataWordCache` 在优化阶段曾膨胀到 `2418361` cells。
- line 5148510：ABC 前另一轮 `OooDataWordCache` hash 仍为 `2237909` cells。
- line 5148513：`OooSv39Tlb` 同阶段为 `20991` cells。
- line 5151037：`OooBranchDirectionPredictor` ABC 已通过，提取 `140384` gates / `167328` wires。
- line 5153514：`PmpChecker` ABC 已通过，提取 `53095` gates / `54258` wires。
- line 5153557：`AxiLitePlic` ABC 已通过，提取 `33607` gates / `35074` wires。
- line 5154004-5154006：进入 `OooDataWordCache` gate extraction 后，`NpcTop.netlist.v` 目标被终止。

## 结论

1. `OooFpArithGate` 黑盒边界有效：本轮不再停在 FP arith gate，`OooFpBackend` 已能继续参与后续优化/ABC。
2. `OooBranchDirectionPredictor`、`PmpChecker`、`AxiLitePlic` 虽然规模大，但本轮都已通过 ABC，不是第一个阻断点。
3. `OooDataWordCache` 是 cache+FP blackbox 后的下一处全顶 full stdcell synthesis 阻断点；当前 RTL 的 data cache 存储阵列表达会被 Yosys 展开到 200 万级 cells，并在 gate extraction 阶段超出当前探针预算。
4. 下一步应优先为 `OooDataWordCache` 建立 memory macro/SRAM/blackbox 或 memory-preserve 综合边界，并用 `debug/` 与 `common/` 的 facts/checker/TB 口径审核 RTL 是否仍符合 spec 语义；随后再恢复全顶 full stdcell 与 STA。

## 边界

本轮未修改生产 RTL，未启动 Ubuntu/rootfs，未产出完整标准单元网表，也不构成 STA-ready 结论。
