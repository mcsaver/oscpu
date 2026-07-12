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

### 1.1 v1 边界迁移(2026-07-08 SRAM 化)

`OooFetchPacketCache`/`OooDataWordCache` 已完成 SRAM 宏化重构：两模块的控制逻辑
(tag 比较/valid FF/盲失效)改为可综合 stdcell，存储阵列下沉为模块内部的
`Sram4096x199`/`Sram4096x113`(1RW 同步读，`vsrc/sram/` 独立管理)。因此 `NpcTop`
综合的 blackbox 集从"四模块"迁移为 `Sram4096x199 Sram4096x113 OooFpArithGate
OooBranchDirectionPredictor`；netlist 实例检查对两 cache 改为检查其内部 SRAM 宏实例。

## 2. 合同表

| Module | RTL/source | Netlist instance | Boundary kind | Timing/area status | Semantic audit | Next task | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OooFetchPacketCache | `vsrc/cache/OooFetchPacketCache.v`; dedicated spec `ooo-fetch-packet-cache.md`; bridge owner `ooo-fetch-axi-bridge.md` | `u_fetch_packet_cache` (control logic now stdcell; internal `Sram4096x199` is the blackbox) | fetch packet payload SRAM macro inside module | SRAM macro v1: 1-cycle sync lookup read, next-lookup-issue fill/invalidate visibility, blind 7-neighbor invalidate, clear-valid-only, 819200 state-bit lower bound (815104 SRAM macro + 4096 valid FF); Liberty/LEF/OOC timing still open | Partial: dedicated spec v1, `OooFetchPacketCacheFacts.vh`, `OooFetchPacketCacheChecker.sv` (判决拍打拍), and `tb_ooo_fetch_packet_cache` two-phase protocol cover context/hit/fill/invalidate/clear; no top XMR non-vacuum evidence yet | Provide real Liberty/LEF macro model (fakeram/工艺) for `Sram4096x199` or OOC timing report and top-level constraints | `.github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/` plus SRAM refactor runs |
| OooDataWordCache | `vsrc/cache/OooDataWordCache.v`; dedicated spec `ooo-data-word-cache.md`; bridge owner `ooo-mem-axi-bridge-fsm.md` | `u_dcache` (control logic now stdcell; internal `Sram4096x113` is the blackbox) | data cache tag+data SRAM macro inside module | SRAM macro v1.1: 1-cycle sync lookup read (merged req/walk single port), next-cycle write visibility, 2-cycle RMW store write-update via per-bit `wmask_i` (bit-write-mask macro variant; cross-line p1 与 A/D 维护路保守失效; `rmw_busy` 压 stage_advance(P5 刀 M 后; 原 req_ready)=store 后 1 bubble), 466944 state-bit lower bound (462848 SRAM macro + 4096 valid FF); Liberty/LEF/OOC timing still open | Partial: dedicated spec v1.1, `OooDataWordCacheFacts.vh`, `OooDataWordCacheChecker.sv` (判决拍打拍 + RMW busy/port/b2b), and `tb_ooo_data_word_cache` two-phase protocol cover hit/fill/window/store-RMW-write-update; no top XMR non-vacuum evidence yet | Provide real Liberty/LEF macro model (fakeram/工艺) for `Sram4096x113` (bit-write-mask variant) or OOC timing report and top-level constraints | `.github/task-runs/2026-07-08-data-word-cache-macro-placeholder/` plus SRAM refactor runs |
| OooFpArithGate | `vsrc/execute/OooFpArithGate.v`; `ooo-fp-arith-gate.md` | `u_fp_arith` | FP arithmetic macro / OOC split candidate | Decision placeholder v0 defined: production semantic boundary remains 5-cycle `OooFpArithGate`; module-level blackbox only non-signoff OOC boundary; OOC coarse PASS but full stdcell still open; Liberty/LEF/OOC timing still open | Partial: dedicated spec, focused `tb_ooo_fp_arith_gate`, contract assert, deterministic mixed precision, kill/flush/meta checks; no common/debug facts required while boundary remains local; if latency/backend boundary changes, add facts/checker | Provide full-module OOC timing report or production child split for Mul/FMA cones and top-level constraints; add random B-FP pressure if latency/boundary changes | `.github/task-runs/2026-07-08-fp-arith-macro-decision/`, `.github/task-runs/2026-07-08-fp-arith-internal-cones/`, and four-blackbox run |
| OooBranchDirectionPredictor | `vsrc/frontend/OooBranchDirectionPredictor.v`; `ooo-branch-direction-predictor.md` | `u_branch_direction_predictor` | predictor table macro / blackbox candidate | Placeholder v0 defined: 0-cycle two-lookup read with one scalar static-fallback bit per lane, two-cycle issue-resolve table-update visibility, valid-only table clear plus GHR zero, 17674 state-bit lower bound; F1a same-input 5ns A/B removes about 0.50pF sign-net placeholder load/lane while WNS remains -12.90ns；TNS improves 0.661451% but also has 126 fewer placeholder setup endpoints, so it is only supporting evidence; real Liberty/LEF/OOC timing still open | Partial: dedicated spec, `OooBranchDirectionPredictorFacts.vh`, `OooBranchDirectionPredictorChecker.sv`, and `tb_ooo_branch_direction_predictor` cover static fallback/counter/GHR/dual-lookup/update; no top XMR non-vacuum evidence yet | Provide real Liberty/LEF macro model or OOC timing report and top-level constraints; if hooked to SIM_TOP, record non-vacuum debug evidence | `.github/task-runs/2026-07-08-branch-direction-predictor-macro-placeholder/` plus F1a scalar-ABI run |

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

- 2026-07-09：**DWC 行升 SRAM macro v1.1(store write-update 赎回)**。`Sram4096x113` 加
  per-bit `wmask_i[112:0]`(bit-write-mask 宏变体，占位 lib pin 表同步再生成)；store 维护从
  unconditional invalidate 改 2-cycle RMW write-update(`rmw_busy` 压 stage_advance=store 后
  1 bubble；跨线 p1 与 A/D 维护路保守失效)；`check_dcache_macro_contract.py` 冻结措辞同步。
- 2026-07-08：**FPC/DWC 迁移到 SRAM macro v1**。两 cache 控制逻辑 stdcell 化，存储下沉
  `Sram4096x199`/`Sram4096x113`(1RW 同步读+1 拍，`vsrc/sram/`)；桥 FSM 各加 S_LOOKUP 判决态；
  DWC store 改无条件失效(一期取舍)；FPC SMC 失效改 7 邻域盲失效；顶层 blackbox 集同步迁移。
  focused TB×4 + 全量 module TB 84/84 + lint 全绿。dedicated spec 均升 v1。
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
- 2026-07-12：F1a 将 BPU lookup fallback ABI 从每 lane 64-bit immediate 收窄为 1-bit
  `static_taken`，同步 placeholder Liberty；并按当前 1024-entry BHT 校正 lower bound 为 17674 bit。
  同输入 fresh 5ns A/B 中 WNS 保持 -12.90ns，TNS 改善 0.661451%，两路 sign-net placeholder
  output-net total cap 各下降约 0.50pF；TNS 同时受少 126 个 placeholder setup endpoint 影响，
  只作辅助证据。top40 仍由后端主导，真实 macro timing/signoff 保持 open。
- 2026-07-08：`OooFpArithGate` 行更新为 decision placeholder v0：生产语义边界保持 5-cycle RTL；
  module-level blackbox 只作 non-signoff OOC boundary；OOC coarse PASS/full stdcell open，
  后续仍需 full-module OOC timing report 或 production child split/top constraints。
- 2026-07-08：修复 Yosys->iEDA 网表方言前置问题。`yosys.tcl` 在写 mapped netlist 前删除
  `$print/$assert/$assume/$cover/$check` 等仿真/形式 side-effect cell，并不再用 `-defparam`
  写出参数覆盖；Fetch/D-cache 默认容量改由宏驱动，避免四黑盒实例写成 `Module #(...)`。
  新增 `check_ieda_netlist_compat.py`。四黑盒 `NpcTop` synthesis PASS，新网表 preflight PASS；
  iEDA STA smoke 可越过 parser，但 `2400s` 内仍停在 data backward propagation，未生成
  `NpcTop.rpt/.pwr`。
