# 任务报告

## 目标

继续推进 `[112] RV64 Yosys full stdcell synthesis`，在正确性门禁恢复后，对 `NpcTop + OooFetchPacketCache blackbox` 后暴露的 `OooFpArithGate` 长尾做单模块 OOC 拆账。本轮仍不启动 Ubuntu/rootfs。

## 实现者人格

本轮没有修改功能 RTL，完成三件事：

1. 对 `OooFpArithGate` 做 Yosys OOC synthesis 拆账。
2. 新增 active spec：`npc/rv64/design/specs/ooo-fp-arith-gate.md`。
3. 更新 memory / known-issues，使 `[112]` 的下一步任务从“笼统 OooFpArithGate 长尾”细化为“拆 addsub/mul/fma 或 FMA 内部 shift-jam/LZC/round 子路径”。

关键事实：

- 当前 `OooFpArithGate` 已经是 5 级 FP arith 流水/自流水接口，不是旧纯组合巨石。
- 模块保留旧 pending `start_i/done_o` 接口，也有 B-FP `launch_valid_i/out_valid_o` 自流水接口。
- active spec 明确了接口契约、meta kill、不变量、验证缺口和综合任务清单。

## 关键证据

- OOC coarse 100MHz PASS，`synth_check` 0 problems。
- coarse 规模：`2138 cells`，含 `16 $macc_v2`、`127 $alu`、`797 $mux`、`191 $sdff`、`1 $sdffe`、`10 $shl`。
- OOC full stdcell 强制重跑，在 `1200s` 窗口内终止于：
  - `7.6. Executing ABC pass`
  - `Extracting gate netlist of module \OooFpArithGate ...`
  - `Terminated`
- `tb_ooo_fp_arith_gate` PASS，确认本轮没有功能 RTL 改动导致的局部行为退化。
- 相关大日志已压缩，保留 concise marker、stats 和 tail。
- `scripts/agent-e2e.sh --profile npc-dev --task-slug yosys-fp-arith-gate-ooc --stop-on-fail` PASS，证据目录 `.github/task-runs/2026-07-08-yosys-fp-arith-gate-ooc-2/`。
- `scripts/agent-e2e.sh --profile yosys-sta --task-slug yosys-fp-arith-gate-ooc --stop-on-fail` PASS，证据目录 `.github/task-runs/2026-07-08-yosys-fp-arith-gate-ooc-3/`。
- `scripts/agent-e2e.sh --guard --guard-mode strict` PASS。

## 审查者人格

未闭合项与风险：

- `OooFpArithGate` full stdcell 尚未通过，不能据 coarse PASS 宣称 STA-ready。
- 当前 TB 只实例化旧 `start/done` 接口，未覆盖 B-FP `launch/out` 自流水接口。
- full run 的 shell 退出码曾被 PowerShell/WSL 包装层干扰，因此结论以日志内 `Terminated` 和终止阶段为准，不以外层退出码为准。
- 全模块 full OOC 不适合作为后续内循环 gate；应拆更细子路径，否则每轮都会耗在 ABC 长尾。
- `OooFetchPacketCache` 存储宏边界仍是另一个 active blocker，本轮未处理。

## 下一步

1. 把 `OooFpArithGate` 的 addsub/mul/fma 三条路径拆为更小 OOC 目标，先定位是否 FMA 独占主要 mapping 压力。
2. 对 FMA 内部 128-bit shift-jam、LZC、round/pack 子路径做结构化拆账。
3. 给 B-FP `launch/out` 自流水接口补 dedicated TB 或断言，覆盖 meta kill、kind 合法性和 value/fflags 对齐。
4. 继续把 `OooFetchPacketCache` 定成真实 SRAM/memory macro 或 Yosys 保留 memory 边界。
