# `OooPendingDrainResolveGate` 三快照演化证据

## 1. 复核对象与结论边界

对象：

```text
npc/rv64/vsrc/control/OooPendingDrainResolveGate.v
```

本文件只复核三个不可变 Git 快照中的源码身份、局部合同和已有验证材料。它支持以下有限主张：

> `OooPendingDrainResolveGate` 的可执行合同先以 ROB/IQ 等后端状态定义排空，随后纳入退休/SQ 侧存储静默，最后为 ordinary FENCE 增加完整内存 owner graph 的专用静默条件。

它不支持以下外推：

- 不把三个时间点当作只改变一个变量的受控实验；
- 不把跨快照 CPI、WNS 或测试数量的变化归因于单条布尔条件；
- 不把有限二值枚举称为完整形式化证明；
- 不把指定负向变体全部检出称为 RTL 全局正确；
- 不把快照 C 的历史 full-design design-id 自动迁移到当前可能已变化的其他 RTL 文件。

## 2. 快照身份

| 快照 | 日期 | Git commit | 文件 SHA-256 | 主要来源 |
|---|---|---|---|---|
| A | 2026-06-28 | `0bb371593315afe507752dc134cabf122ed9751c` | `e0ac0be2253d84ffd41bb83314f1d24f65a861a0d8b45cd6555a2b222a6a38c7` | `.github/task-runs/2026-06-28-npc-rv64-ooo-perf-opt/campaign-report.md` |
| B | 2026-07-13 | `8532bad0794cb34199c8adf49b080e1773b1f16f` | `574fc78abebb587937e828ba961d1a6405cb20463d8f0ff0b7a9251d84e5628f` | `.github/task-runs/2026-07-13-rv64-t3i-drain-retire-redundancy/task-report.md` |
| C | 2026-07-23 | `c29532ead32bf2a268b821cef9665a44aec58f9f` | `6be380f766d03dfffbbe970b696226c14fd6eea4c6d741b491108c760be108b6` | `.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/task-report.md` |

快照 C 的完整 RTL 集合在 V9M 中绑定：

```text
design-id =
sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2
```

2026-07-24 复核时，工作树中的该单个 Verilog 文件 SHA-256 仍为
`6be380f766d03dfffbbe970b696226c14fd6eea4c6d741b491108c760be108b6`，且
`git status --short -- <file>` 无输出。这个事实只说明该文件与快照 C 字节一致，不说明
整个当前工作树仍等于 V9M 的 full-design design-id。

## 3. 快照 A：基本后端排空

源码：

```verilog
assign backend_drained_o = (rob_count_i == {ROB_COUNT_W{1'b0}}) &&
                           (issue_count_i == {ISSUE_COUNT_W{1'b0}}) &&
                           (core_retire_count_i == 2'b00) &&
                           !synth_lane1_ret_pending_i &&
                           !synth_lane1_branch_drop_pending_i;

assign drain_complete_o =
    stop_pending_i && backend_drained_o && pending_control_ready_i &&
    !pending_replay_wait_o;
```

可观察语义：

1. ROB 与 issue queue 均空；
2. 当拍没有 retirement；
3. 两个 synthetic lane1 尾部事件均不存在；
4. pending control 已 ready，且没有 replay wait。

在这个模块中尚看不到：

- 退休 store 可能仍驻留 SQ 的显式静默条件；
- MIQ、bridge buffer、retry、reservation、live owner、terminal pending 的完整静默条件；
- ordinary FENCE 与其他 system event 的专用区分。

`campaign-report.md` 记录的优化任务从 `0bb371593` 到 `e7ff03a1d`；该模块在两个端点具有相同文件 SHA。任务结束时得到 module 112/112、official 271/0、AM 56/56 和整体 workload 指标。这些是“包含该模块版本的系统曾通过任务级门禁”的证据，不是该局部合取式每一项必要性的负向证明。

证据等级：源码身份为 `SUPPORTED`；局部谓词必要性为 `OBSERVATIONAL_ONLY`。

## 4. 快照 B：退休/SQ 静默与冗余条件消除

源码：

```verilog
// commit0_fire -> count_q != 0
// commit1_fire -> commit0_fire
// therefore rob_count == 0 -> retire_count == 0
assign backend_drained_o = (rob_count_i == {ROB_COUNT_W{1'b0}}) &&
                           (issue_count_i == {ISSUE_COUNT_W{1'b0}}) &&
                           !synth_lane1_ret_pending_i &&
                           !synth_lane1_branch_drop_pending_i &&
                           mem_retire_quiet_i;
```

两个变化需要分开解释：

1. 在快照 A 与 B 之间的历史差异中，`mem_retire_quiet_i` 已经存在；源码注释将其与 LSQ/SQ 演进相关联，因为“ROB 空”不再蕴含“退休 store 已全部落存”。
2. T3I 的直接基线是 `0b0d71673a40a8e582106857176cd6c106bb847d`，其特定切片只删除 `core_retire_count_i`，依据是合法状态域中 `rob_count==0 -> retire_count==0`；这不是对快照 A→B 之间所有 refactor 的统一归因。

T3I 报告中的推导链：

```text
commit0_fire -> count_q != 0
commit1_fire -> commit0_fire
commit{0,1}_valid = commit{0,1}_fire
rob_count = count_q
retire_count = commit0_valid + commit1_valid
therefore rob_count == 0 -> retire_count == 0
```

已有反例能力：

- 从真实 RTL 抽取唯一 continuous assignment；
- 枚举 16-entry ROB 的 2176 个有限、二值、合法域用例；
- 删除 count guard 的 mutation 被拒绝；
- 保留 guard 文本但增加顶层 `|| 1'b1` 的 mutation 被拒绝；
- negative assertion 曾暴露 `$error` 后仍打印 PASS 的 runner 假绿，修复后 runner 19/19；
- module 96/96、contract 86/86、official+privileged 177/177；
- CoreMark 10 的 cycles、commits 与 CRC 相对前一切片逐项一致。

物理边界：

```text
baseline WNS = -10.10 ns
T3I WNS      =  -9.38 ns
target       =   5.00 ns period
```

报告记录代理 STA 中 WNS 变得较少负，但该变化不能仅由这组纵向快照归因于某一谓词删除，且目标仍未达到。T3I 可以声明局部切片和指定配置下的等价/路径证据，不能声明 200 MHz 物理完成；PPA 状态保持 `UNQUALIFIED`。2176 个二值合法域用例也不是完整 formal/model checking。

## 5. 快照 C：ordinary FENCE 等待完整内存 owner graph

源码：

```verilog
wire pending_fence_mem_quiet_w =
    !pending_system_fence_i || mem_idle_i;

assign drain_complete_o =
    stop_pending_i && backend_drained_o && pending_control_ready_i &&
    !pending_replay_wait_o && pending_fence_mem_quiet_w;
```

这里保留了两个不同层级的静默条件：

- `mem_retire_quiet_i`：退休/SQ 侧没有尚待排空的 store；
- `mem_idle_i`：MIQ、bridge/pending buffer、retry、issue reservation、live owner 与 terminal pending 共同静默。

`pending_fence_mem_quiet_w` 只对 `pending_system_fence_i` 为真时消费 `mem_idle_i`。因此普通 FENCE 获得更强顺序条件，其他 system control 继续使用既有 drain/priority 合同；没有新增 FSM。

V9M 报告明确说明，任务开始时 production RTL 已呈现这条逻辑；V9M 的主要动作是刷新并增强与该 design-id 绑定的验证证据，不是重新实现 `pending_fence_mem_quiet_w`。

V9M 的正向证据：

```text
focused=2/2
module=109/109
validator=12/12
architecture_targets_refreshed=9/9
```

V9M 的两个可编译负向 RTL：

| 变体 | 实际改变 | 动态结果 | 唯一目标标记 |
|---|---|---|---|
| `fence_full_memory_idle_removed` | 把 ordinary-FENCE full-memory-idle 谓词替换为常真 | 编译成功；testbench 返回 make rc=2；被拒绝 | `[CHECK-FAIL] fence waits for MIQ bridge reservation idle got=1 expected=0` |
| `core_glue_fence_mem_idle_binding_constantized` | 把 CoreGlue→ControlPlane 的 `mem_idle` 连接常量化 | 编译成功；testbench 返回 make rc=2；被拒绝 | `[CHECK-FAIL] fence control plane consumes core memory idle got=0 expected=1` |

原始结构化摘要：

```text
.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/
  evidence/rtl-variants/summary.json
```

摘要同时记录：

```text
compile_success=2
dynamic_rejected=2
required=2
source_unchanged=true
```

这里的 `make rc=2` 是预期的动态拒绝，不是编译失败。变体通过构建变量替换单个 RTL 文件，production source 前后 SHA 不变。

V9M 发布边界：

```text
FENCE-G1=CLOSED
full_core=GAP
blockers=38
ppa=UNQUALIFIED
promotion=false
```

因此，V9M 支持“指定 design-id 下的 FENCE-G1 定向合同对两个指定错误具有辨识力”，不支持“全核 architecture freeze 完成”“PPA 合格”或“所有 FENCE 错误均已覆盖”。

## 6. 三快照比较的科学解释

三个源码快照回答的是“合同如何被显式化”：

```text
快照 A
ROB/IQ/retire/synthetic pending quiet
        |
        v
快照 B
ROB/IQ/synthetic pending quiet
AND retired-store/SQ quiet
        |
        v
快照 C
快照 B 的 backend drain
AND ordinary-FENCE-specific full memory-owner quiet
```

它们不是配对消融，原因包括：

1. 快照之间同时发生 LSQ/SQ、pending memory/FP、CSR cancellation 和其他 RTL 变化；
2. 三个快照使用的 module test 数量和 full-core 工具条件不同；
3. 快照 A 缺少谓词级负向 oracle；
4. V9M 的主要任务是刷新并加强快照 C 的 current-design evidence，而不是重新修改 production drain logic；
5. 只有部分切片保存了可直接比较的 baseline/candidate 配置。

若要估计某个条件的独立因果效应，应从同一个 base design 派生 paired variant，只开关目标条件，并固定 workload、工具、约束、随机种子和预算。

## 7. 只读复核命令

以下命令只读取 Git 对象和现有 task-run：

```bash
git show 0bb371593315afe507752dc134cabf122ed9751c:npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  | sha256sum

git show 8532bad0794cb34199c8adf49b080e1773b1f16f:npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  | sha256sum

git show c29532ead32bf2a268b821cef9665a44aec58f9f:npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  | sha256sum

git diff 0bb371593315afe507752dc134cabf122ed9751c \
  8532bad0794cb34199c8adf49b080e1773b1f16f -- \
  npc/rv64/vsrc/control/OooPendingDrainResolveGate.v

git diff 8532bad0794cb34199c8adf49b080e1773b1f16f \
  c29532ead32bf2a268b821cef9665a44aec58f9f -- \
  npc/rv64/vsrc/control/OooPendingDrainResolveGate.v
```

报告与结构化证据：

```text
.github/task-runs/2026-06-28-npc-rv64-ooo-perf-opt/campaign-report.md
.github/task-runs/2026-07-13-rv64-t3i-drain-retire-redundancy/task-report.md
.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/task-report.md
.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/rtl-derivation.md
.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/evidence/rtl-variants/summary.json
```
