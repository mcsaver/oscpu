# RV64 F1：FDG-G1 arch-trap 不得送 backend

## 基本信息

- `task_id`: 2026-07-12-rv64-f1-fdg-g1
- `task_slug`: rv64-f1-fdg-g1
- `graph_template`: regression-debug-loop + npc-sim-regression
- `graph_mode`: static+dynamic
- `status`: completed
- `owner`: root + f1_backlog_audit
- `started_at`: 2026-07-12 10:06:21 +0800
- `updated_at`: 2026-07-12 10:40:12 +0800

## 任务目标

- `source_request`: 持续优化架构，直到完整功能与 200 MHz 同时闭合。
- `goal`: 关闭 `FDG-G1`：任何已经分类为 head0 architectural trap 的指令都不得呈现给 backend dispatch。
- `scope`: `OooFetchHeadClassifyGate -> OooFrontendDispatchGate -> OooFrontendBackendDispatchMux`；不修改 pending trap、redirect、FIFO、后端执行或提交时序。

## 选图说明

- `selected_template`: 先走 regression-debug-loop 的 RED/localize/fix/rerun，再走 npc-sim-regression 的 focused/full gate。
- `why_this_graph`: 缺口已有代码优先复现与明确 source-to-sink 链，适合单合同 TDD；修复后仍必须回到整核真实 rc 回归。
- `dynamic_nodes_added`: `assert-negative-probe`，专门证明立即断言非真空。
- `why_dynamic_nodes_were_needed`: 普通正向回归只能证明实现结果，不能证明合同断言在故意违约时会响。

## 节点概览

| node_id | owner_agent | depends_on | 状态 | inputs | outputs | success_criteria | fallback |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `recall-contract` | root | 无 | PASS | current snapshot、ROADMAP、active spec、F1 审计 | root cause 与 source-to-sink 链 | active 文档与当前 RTL 一致 | 回到代码优先复审 |
| `red-path-matrix` | root | recall-contract | PASS | 四类非法 FP + 合法 FADD.S | 常驻整链 TB | 旧 RTL 精确失败于 backend-valid | 缩到 gate TB + classifier TB |
| `freeze-contract` | root | recall-contract | PASS | SPEC-TEMPLATE、六类契约 | §2/§3 表 + RTL 拓扑 | 所有受影响格子已填 | 禁止写 RTL |
| `implement-gate` | root | red-path-matrix,freeze-contract | PASS | 冻结合同 | 单方程门控 + 立即断言 | focused GREEN | 回滚本刀 |
| `assert-negative-probe` | root | implement-gate | PASS | 故意 force 违约 | 非真空日志 | 合同断言明确 fire | 修正断言观测点 |
| `full-regression` | root | implement-gate | PASS | current RTL | module/AM/official/lint/contract | 原始子层 rc 全绿 | localize 后重跑 |
| `record-review` | root | full-regression | PASS | 全部证据 | memory/task-run/guard | reviewer 无未解反例 | 仅交付子任务状态 |

## 接口契约冻结（RTL 阶段 0）

### 六类合同

1. **握手**：本 gate 不持有事务；`frontend_dispatch_to_backend_valid_o` 只表示当拍呈现，actual fire 由下游 valid/ready 决定。valid 只依赖 head 分类事实，禁止依赖 `dispatch*_ready_i`。
2. **stall**：stall 状态由父级 FIFO/dispatch owner 持有；head 在 stall 时冻结，本纯组合 gate 不增加状态。新增 arch-trap 排除项不形成 ready→valid 回边。
3. **flush/redirect/trap**：同拍优先级为 `arch_trap/exit/system 排除普通 backend present > 普通 branch/jump/FP/ALU present`。本模块不清任何状态；pending trap 与 frontend action gate 继续捕获/停止，已发 AXI、committed store、CSR commit 均不在本刀范围。
4. **异常序**：head0 arch-trap 只走精确 trap owner，不得复制成 backend uop；更年轻 lane1 由既有 lane1-base 阻断。
5. **访存序**：无访存状态或副作用，本刀不改变 SQ/MIQ/AXI。
6. **投机恢复/单一真源**：`dispatch0_arch_trap_i` 继续由 `OooFetchHeadClassifyGate` facts 单一产生；dispatch gate 只消费，不复制第二份分类逻辑。

### 同拍优先级与清/保持

| 同拍事件 | 普通 backend valid | lane1 | pending trap/stop | AXI/store/CSR |
| --- | --- | --- | --- | --- |
| `dispatch0_arch_trap_i=1` | 强制 0 | 既有 lane1-base 强制阻断 | 保持既有 owner，继续捕获/停止 | 不触碰 |
| `dispatch0_exit_i/system_i=1` | 保持既有排除语义 | 保持既有阻断 | 保持既有 owner | 不触碰 |
| 普通合法指令 | 按既有 branch/jal/jump/barrier 方程呈现 | 既有双发合同 | 不新增动作 | 不触碰 |

## RTL 推导摘要（写 RTL 前冻结）

### 阶段 1：需求

- 功能：`dispatch_valid_i && dispatch0_arch_trap_i` 时，普通 backend valid 恒为 0。
- 正对照：合法 FADD.S 与普通 ALU 的 backend valid 保持 1。
- 性能/时序：只在已有 valid AND 树加入一个分类位；无新寄存器、FSM、端口或跨域。
- out-of-scope：不改变 trap capture、stop、redirect、FIFO pop、后端 decode/ROB、xRET 等其他 F1 项。

### 阶段 2a：协议

- 纯组合、零周期返回；无事务保持责任。
- `dispatch*_ready_i` 只参与 fire，不参与本次 backend-valid 排他合同。
- arch-trap 与 ordinary backend present 同拍互斥，不重试为普通 uop。

### 阶段 2b：状态机

- 无状态、无寄存器、无 FSM；唯一“状态”由父级 FIFO/head owner 持有。

### 阶段 2c：不变量

- `FDG-I1`: `dispatch0_arch_trap_i -> !frontend_dispatch_to_backend_valid_o`；违反会让非法/保留编码进入 FP/IQ/ROB，可能悬死或错误执行。
- `FDG-I2`: 合法普通 head0 不因本刀被阻断；由合法 FADD.S/普通 dispatch 正对照覆盖。
- `FDG-I3`: backend valid 不依赖 ready；结构审查与 lint 覆盖组合环风险。

### 阶段 2d：数据通路

`classifier.arch_trap_raw -> dispatch0_arch_trap -> backend-valid AND 排除项 -> BackendDispatchMux core_dispatch{0,1}_valid`。无共享资源、无 mux 新 owner。

### 阶段 2e：RTL 级拓扑

- module 边界：只修改 `OooFrontendDispatchGate` 的组合输出方程；父 `OooFrontend` 旁挂时钟立即断言。
- 状态寄存器/FSM/pipeline：均无新增。
- 主要组合块：现有 normal-dispatch predicate AND 树加入 `!dispatch0_arch_trap_i`。
- reset/flush/kill/stall：无本地状态；trap exclusion 结构优先，父级继续负责 hold/flush。
- 资源：无复制/共享资源变化。
- critical path：classification predicate → backend-valid；新增单 bit 排除项不延长数据 payload 路径。
- function 划分：无 function；显式 assign。

## 当前结论

- `root_cause`: lane1/unsupported 辅助方程已经排除 `dispatch0_arch_trap_i`，但主 `frontend_dispatch_to_backend_valid_o` 复制了一份不完整 stop predicate，漏掉同一排除项；下游 mux 直接消费该 valid，故是真实 source-to-sink 合同洞。
- `blockers`: 无。
- `final_result`: FDG-G1 已关闭；memory、evidence index、npc-dev 与 strict guard 均完成，
  独立 reviewer 无剩余阻断。本 task-run 不把该功能刀越级解释为 200 MHz 已达标。

## RED → GREEN 证据

### RED（旧 RTL）

- fixture：`testbench/tests/tb_ooo_fp_legality_dispatch_path.sv`，连接真实 DecodeUnit、
  FP legality、`OooFetchHeadClassifyGate` 与 ordinary dispatch admission。
- 旧 RTL runner rc=1；unknown OP-FP funct7、reserved FMA fmt、reserved static rm、
  DYN+reserved frm 四类都满足 illegal/arch-trap/FP-disabled，但 backend valid 仍为 1；
  日志精确报告 `errors=4`，没有其它功能检查失败。
- 证据：`evidence/red/logs/tb_ooo_fp_legality_dispatch_path.log`。

### 实现与 focused GREEN

- `OooFrontendDispatchGate` 的唯一 ordinary backend-valid 方程加入
  `!dispatch0_arch_trap_i`；没有新增状态、端口、ready 依赖或第二份 decode。
- `OooFrontend` 在 `OOO_ASSERT` 下加入 `FDG-I1` 时钟立即断言。
- focused 4/4 PASS：整链 legality/admission、dispatch gate、classifier、frontend trap gate；
  合法 FADD.S 继续进入 backend，防止“全部关断”假修复。
- 证据：`evidence/focused-green/summary.txt`。

### 断言非真空

- 显式 `FDG_G1_NEGATIVE_PROBE` 强制 `arch_trap && backend_valid`；日志出现唯一目标 marker
  `[FDG-CONTRACT FDG-I1]`，runner 按预期 rc=1，且探针立即退出，没有后续 TB 场景污染。
- 正常 module 回归不定义该宏，87 项断言静默。
- 证据：`evidence/assert-negative/logs/tb_ooo_fetch_trap_gate.log`。

## 全量回归与环境裁决

### 可信 GREEN

- bundled 环境 run：`evidence/core-regress-agent-env/20260712-101738-1337411/`，
  Verilator 5.051，`overall_rc=0`。
- module 87/87；Verilator lint PASS；NPC build PASS。
- current-config AM 59/59 PASS，但该 run 明确 Difftest OFF；不得冒充逐退休对拍。
- official riscv-tests：177 tests attempted，177/177 PASS。
- 独立 `default_defconfig` Difftest-ON AM：`Difftest: ON` 59 次、reference enabled 59 次、
  59/59 PASS，末尾 `result check passed: 59 test(s)`，工具观测 rc=0。
- Difftest-ON 脚本退出时恢复 NPC/NEMU 共六个配置文件；当前哈希与 backup 逐字节一致，
  见 `evidence/config-restore.sha256`。
- 配置恢复后不能只依赖旧 mtime：Difftest-ON `NpcSimTop/difftest.o` 曾仍留在 build。随后用
  bundled 环境 `make clean && make -j2` 从已恢复的 OFF 配置干净重建，并以 fresh `add`
  AM smoke 验证 runtime 明确打印 `Difftest: OFF`、1/1 PASS。证据：
  `evidence/restored-config-rebuild.log`。
- structural 终态：`check-rtl-style` PASS；`check-contract` 显示
  `current=35 baseline=35`；Verilator 5.051 lint PASS。证据：`evidence/structural/`。
- final fresh `npc-dev` task-run completed；strict guard `changed_paths=51`、required profile 仅
  `npc-dev`，结果 PASS，选择证据 `2026-07-12-rv64-f1-fdg-g1-final-npc-dev`。raw guard 输出：
  `evidence/strict-guard.log`。

### 不采信的失败尝试

- `evidence/core-regress/20260712-101529-1308548/` 是环境调用错误的失败 run：未走
  `scripts/agent-run.sh`，system Verilator 5.020 不支持 `PROCASSINIT`，NPC build/AM
  exit=2，`overall_rc=1`。
- 该 run 后续 177 条虽显示 PASS，但 build 已失败，可能复用了旧 binary；全部排除出 GREEN。
  正确性结论只采信上面的 bundled run。

## 证据边界与审查

- 新整链 TB 止于 dispatch gate 的 ordinary-admission 输出；下游
  `OooFrontendBackendDispatchMux` 对该信号是直接 OR sink，结构审查与既有 mux TB 覆盖。
- assertion baseline 从陈旧 20 ratchet 到当前真实 35；已保存
  `current=35, baseline=35` 的 `check-contract` 复跑，不以早先 `35>=21` 代替终态证据。
- 本切片只关闭 FDG 功能合同。未用它声称 5 ns 时序改善或 200 MHz 达标；正式 target-driven
  重综合/STA 在后续架构切片做同模型 A/B。
- 独立 reviewer 结论：RTL root cause、RED/GREEN 与负探针可信；active docs、task-run、
  memory、artifact reconciliation、structural gate 与 strict guard 阻断均已消除。
