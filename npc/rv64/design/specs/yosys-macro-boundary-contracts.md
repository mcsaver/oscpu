# 规范：Yosys 宏边界合同（NpcTop 四黑盒）

> 范围：`NpcTop` 100MHz full stdcell synthesis 中显式 blackbox 的宏/OOC 边界。
> 状态：ACTIVE，综合/时序准备用合同；不是 RTL 行为 spec 的替代品。

## 1. 背景

2026-07-08 四黑盒探针已证明：

- `NpcTop` 在 `OooFetchPacketCache`、`OooDataWordCache`、`OooFpArithGate`、
  `OooBranchDirectionPredictor` 作为 synthesis blackbox boundary 时可以写出
  `NpcTop.netlist.v`。
- 完整 Yosys log 后续两处 `check` 为 0 problems。
- 四个黑盒在 `stat` 中均为 unknown area，因此当前网表只能作为结构 sanity 与后续 STA
  接口准备，不能作为完整 PPA/STA-ready 结论。
- `STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0` 是 bounded synthesis probe 的
  fast-name 组合；可读 autoname 只能作为单独审查路径。
- 2026-07-08 `NpcTop` 四黑盒网表已通过 iEDA parser 兼容 preflight：不含 `$print/$assert/$check`
  等仿真/形式 side-effect cell，不含 `defparam`，不含 parameterized blackbox instance。
  iEDA STA smoke 已能越过 Verilog parser 并进入 timing/data propagation；`2400s` 窗口仍未写出
  `NpcTop.rpt/.pwr`，因此 STA smoke completion 仍 open。

## 2. 合同表

| Module | RTL/source | Netlist instance | Boundary kind | Timing/area status | Semantic audit | Next task | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OooFetchPacketCache | `vsrc/cache/OooFetchPacketCache.v`; dedicated spec `ooo-fetch-packet-cache.md`; bridge owner `ooo-fetch-axi-bridge.md` | `u_fetch_packet_cache` | fetch packet memory macro / blackbox candidate | Placeholder v0 defined: 0-cycle lookup read, next-cycle fill/invalidate visibility, clear-valid-only, 819200 state-bit lower bound; Liberty/LEF/OOC timing still open | Partial: dedicated spec, `OooFetchPacketCacheFacts.vh`, `OooFetchPacketCacheChecker.sv`, and `tb_ooo_fetch_packet_cache` cover context/hit/fill/invalidate/clear; no top XMR non-vacuum evidence yet | Provide real Liberty/LEF macro model or OOC timing report and top-level constraints; if hooked to SIM_TOP, record non-vacuum debug evidence | `.github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/` plus four-blackbox runs |
| OooDataWordCache | `vsrc/cache/OooDataWordCache.v`; dedicated spec `ooo-data-word-cache.md`; bridge owner `ooo-mem-axi-bridge-fsm.md` | `u_dcache` | data cache memory macro / blackbox candidate | Placeholder v0 defined: 0-cycle req/walk read, next-cycle write visibility, fill-then-store priority, 466944 state-bit lower bound; Liberty/LEF/OOC timing still open | Partial: dedicated spec, `OooDataWordCacheFacts.vh`, `OooDataWordCacheChecker.sv`, and `tb_ooo_data_word_cache` cover hit/fill/window/store/invalidate; no top XMR non-vacuum evidence yet | Provide real Liberty/LEF macro model or OOC timing report and top-level constraints; if hooked to SIM_TOP, record non-vacuum debug evidence | `.github/task-runs/2026-07-08-data-word-cache-macro-placeholder/` plus semantic/four-blackbox runs |
| OooFpArithGate | `vsrc/execute/OooFpArithGate.v`; `ooo-fp-arith-gate.md` | `u_fp_arith` | FP arithmetic macro / OOC split candidate | Decision placeholder v0 defined: production semantic boundary remains 5-cycle `OooFpArithGate`; module-level blackbox only non-signoff OOC boundary; OOC coarse PASS but full stdcell still open; Liberty/LEF/OOC timing still open | Partial: dedicated spec, focused `tb_ooo_fp_arith_gate`, contract assert, deterministic mixed precision, kill/flush/meta checks; no common/debug facts required while boundary remains local; if latency/backend boundary changes, add facts/checker | Provide full-module OOC timing report or production child split for Mul/FMA cones and top-level constraints; add random B-FP pressure if latency/boundary changes | `.github/task-runs/2026-07-08-fp-arith-macro-decision/`, `.github/task-runs/2026-07-08-fp-arith-internal-cones/`, and four-blackbox run |
| OooBranchDirectionPredictor | `vsrc/frontend/OooBranchDirectionPredictor.v`; `ooo-branch-direction-predictor.md` | `u_branch_direction_predictor` | predictor table macro / blackbox candidate | Placeholder v0 defined: 0-cycle two-lookup read, next-cycle issue-resolve update visibility, valid-only table clear plus GHR zero, 26892 state-bit lower bound; Liberty/LEF/OOC timing still open | Partial: dedicated spec, `OooBranchDirectionPredictorFacts.vh`, `OooBranchDirectionPredictorChecker.sv`, and `tb_ooo_branch_direction_predictor` cover static fallback/counter/GHR/dual-lookup/update; no top XMR non-vacuum evidence yet | Provide real Liberty/LEF macro model or OOC timing report and top-level constraints; if hooked to SIM_TOP, record non-vacuum debug evidence | `.github/task-runs/2026-07-08-branch-direction-predictor-macro-placeholder/` plus four-blackbox runs |

## 3. 关闭条件

四个边界只有同时满足以下条件，才能从 “blackbox probe” 升级为 “STA 可解释宏边界”：

1. **结构合同**：端口方向、时序假设、复位/flush/update 可见行为有明确文档。
2. **Timing/area 合同**：有真实 macro model、校准 placeholder，或明确 OOC 替代物；报告中不得再把
   unknown area 当成闭合面积。
3. **语义合同**：`vsrc/debug` 与 `vsrc/common` 的 facts/checker 或 focused/random TB 能覆盖该边界的
   spec 语义。若选择不使用 debug/common，必须在 task-run 说明边界为何足够局部。
4. **STA 入口**：`NpcTop` synthesis + iEDA STA 使用同一组 macro assumptions，并在报告中列出所有未闭合假设。

## 4. 任务清单

- [x] 产出四黑盒 `NpcTop.netlist.v`，并记录 unknown-area 限制。
- [x] 将 fast-name Yosys flow 版本化，避免依赖 ignored 本机目录。
- [x] 建立本合同文档，列出四个宏边界的 timing/area/语义缺口。
- [x] 增加 checker，确认合同覆盖四个模块且当前网表保留四个实例。
- [x] 为 `OooFetchPacketCache` 建 dedicated spec、debug/common checker，并接入 focused TB。
- [x] 为 `OooFetchPacketCache` 定义 timing/area placeholder v0 与 OOC/blackbox contract。
- [ ] 为 `OooFetchPacketCache` 接入真实 Liberty/LEF macro model 或 OOC timing report。
- [x] 为 `OooDataWordCache` 建 dedicated spec、debug/common checker，并增强 focused TB。
- [x] 为 `OooDataWordCache` 定义 timing/area placeholder v0 与 OOC/blackbox contract。
- [ ] 为 `OooDataWordCache` 接入真实 Liberty/LEF macro model 或 OOC timing report。
- [x] 为 `OooFpArithGate` 定义 module-level macro/OOC decision placeholder v0。
- [ ] 为 `OooFpArithGate` 接入 full-module OOC timing report 或 production child split/top constraints。
- [x] 为 `OooBranchDirectionPredictor` 建 predictor table macro/OOC placeholder v0 与 predict/update 语义 checker。
- [ ] 为 `OooBranchDirectionPredictor` 接入真实 Liberty/LEF macro model 或 OOC timing report。
- [x] 修复 Yosys->iEDA netlist 方言：清除仿真/形式 side-effect cell，禁止 `defparam` 和 parameterized blackbox instance。
- [x] 重跑四黑盒 `NpcTop` synthesis，生成 iEDA parser-compatible netlist。
- [ ] 完成 iEDA STA smoke 并生成 `NpcTop.rpt`/`NpcTop.pwr`；当前 `2400s` 窗口停在 data backward propagation。
- [ ] 在真实 macro assumptions 明确后，重跑 `NpcTop` synthesis 与 iEDA STA smoke，并列出所有未闭合假设。

## 5. Checker

本合同的最低可执行检查：

```bash
python3 yosys-sta/scripts/check_macro_contracts.py \
  --spec npc/rv64/design/specs/yosys-macro-boundary-contracts.md \
  --netlist npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v
```

该命令只证明 contract 覆盖与 netlist 实例存在，不证明 timing/area/语义已经闭合。

iEDA STA smoke 前还必须跑：

```bash
python3 yosys-sta/scripts/check_ieda_netlist_compat.py \
  npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v
```

该命令只证明当前网表避开已知 iEDA parser 不兼容语法，不证明 timing/area/语义已经闭合。

## 6. 变更记录

- 2026-07-08：新增四黑盒 macro-boundary contract。目标是把 `NpcTop` 四黑盒综合后的下一步任务
  落到可检查文档和后续 timing/area/OOC 工作清单中。
- 2026-07-08：`OooDataWordCache` 行更新为 placeholder v0：0-cycle read、next-cycle write
  visibility、fill-then-store priority、466944 state-bit lower bound。真实 Liberty/LEF/OOC timing
  仍保持 open。
- 2026-07-08：`OooFetchPacketCache` 行更新为 placeholder v0：0-cycle lookup read、next-cycle
  fill/invalidate visibility、clear-valid-only、819200 state-bit lower bound。真实 Liberty/LEF/OOC
  timing 仍保持 open。
- 2026-07-08：`OooBranchDirectionPredictor` 行更新为 placeholder v0：0-cycle two-lookup read、
  next-cycle issue-resolve update visibility、valid-only table clear plus GHR zero、26892 state-bit
  lower bound。真实 Liberty/LEF/OOC timing 仍保持 open。
- 2026-07-08：`OooFpArithGate` 行更新为 decision placeholder v0：生产语义边界保持 5-cycle RTL；
  module-level blackbox 只作 non-signoff OOC boundary；OOC coarse PASS/full stdcell open，
  后续仍需 full-module OOC timing report 或 production child split/top constraints。
- 2026-07-08：修复 Yosys->iEDA 网表方言前置问题。`yosys.tcl` 在写 mapped netlist 前删除
  `$print/$assert/$assume/$cover/$check` 等仿真/形式 side-effect cell，并不再用 `-defparam`
  写出参数覆盖；Fetch/D-cache 默认容量改由宏驱动，避免四黑盒实例写成 `Module #(...)`。
  新增 `check_ieda_netlist_compat.py`。四黑盒 `NpcTop` synthesis PASS，新网表 preflight PASS；
  iEDA STA smoke 可越过 parser，但 `2400s` 内仍停在 data backward propagation，未生成
  `NpcTop.rpt/.pwr`。
