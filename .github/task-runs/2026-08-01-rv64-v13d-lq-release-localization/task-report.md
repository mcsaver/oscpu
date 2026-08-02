# RV64 V13D OooLoadQueue release localization

Status: `NEGATIVE_CANDIDATE_ROLLED_BACK` / local PPA dominated / promotion ineligible

## 任务分类与父点

- class：`development`
- parent design-id：`29c0afe8…f483`
- 修改对象：`OooLoadQueue` ROB release lookup/commit 到 entry clear 的组合拓扑。
- PPA 假设：V13B mapped worst path 从 `producer_id_q[12]` 经过
  `release1_q_ready_o`、`release1_commit_i` 到 `paddr_q[6]` D；local fire bitmap 可移除
  global ready reduction 对全部 entry D mux 的回灌。

## 接口契约冻结

| 契约 | 本 slice 冻结内容 |
| --- | --- |
| 握手 | `release_valid + full ProducerId` 查询；`commit` 只在对应 ready 成立时产生 fire；外部端口/时序不变 |
| stall | `release_q_ready` 仍只读 registered `completed_q`；不得接 current completion，也不得形成 ROB C0 组合环 |
| flush/优先级 | reset > exact local release/killed terminal > recovery target > completion/query/launch > edge-old allocation；本次只重写 exact release 的组合表达式 |
| 异常序 | 只有 ROB 对应 lane 的真实 commit 可释放 retire-resident load；current WB bypass 不能单独 free |
| 访存序 | normal terminal 仍不 free；killed tombstone 仍只由 exact terminal free；LQ release 不改变 SQ/MIQ/AXI side effect |
| 投机恢复 | launched owner-pending entry 的 tombstone、terminal history 与 selective recovery 全部保持 |

## RTL 四段式推导

### 1. 需求

- 切断跨 entry `ready reduction → global fire → entry clear mux` 组合锥。
- 保持普通 ready 的 same-cycle formal-WB bypass、Q-only pregrant、双 lane release 与完整 PID 语义。
- assertion-off 非法 duplicate PID 状态下，不允许一个 completed duplicate 的 ready 清除另一个
  incomplete duplicate；unknown-only ready-hit 不得清除。
- out of scope：不加 pipeline register、不改 ROB 接口、不改 LQ entry 数或生命周期、不改 recovery。

### 2a. 协议规则

- `release_ready_hit[g]` 只在 lane valid、entry valid、full PID match 且本 entry completed/current
  completion 命中时为 1。
- `release_fire_hit[g]` 只在该 ready-hit 与对应 lane commit 同拍为 1。
- `release_fire_o = release_valid_i && release_ready_o && release_commit_i` 保持既有外部方程；
  entry `g` 只由本 entry fire bit 清除。
- 两 lane 同 PID 真实 fire 仍由 `[V8V-LQ-DUAL-RELEASE-SAME-PID]` 拒绝。

### 2b. 状态机

- 不新增状态或寄存器；FREE/RESERVED/LAUNCHED/ORDERED/TERMINAL_WAIT_COMPLETION/
  KILLED_DRAIN/COMPLETED 转移保持现有 §3.1。
- 唯一表达式变化是 `COMPLETED → FREE` 的 local fire 资格。

### 2c. 不变量

1. 真实 release：`fire_hit[g] -> match[g] && ready_hit[g] && commit`。
2. 不跨 entry 借 ready：entry `g` 的 clear 不依赖 `ready_hit[j!=g]`。
3. Q-only：`release_q_ready` 不读取 `completion[01]_hit`。
4. ordinary bypass：本 entry current completion 可在同拍使 ordinary `release_ready/fire` 成立。
5. unknown-only hit：四态仿真中不得产生 exact fire/clear。
6. release/terminal/recovery 同拍优先级不变。

### 2d/2e. 数据通路与 RTL 拓扑

1. module/端口：`OooLoadQueue` 端口及位宽不变，单 `clk/rst` 域。
2. 状态寄存器：现有 16-entry `valid/launched/pa_valid/ordered/completed/killed/
   terminal_seen/rob_idx/producer_id/paddr/attr/class/strb` 全部不变。
3. 组合块：每 entry CAM/qualification → ready-hit bitmap → commit AND local-fire bitmap；entry
   update 直接消费同 index fire bit，外部 fire 仍消费既有 ready 归约。
4. FSM：无新编码 FSM，逻辑状态转移同 §3.1。
5. pipeline：无新边界；release 仍为同拍 lookup/commit。
6. 优先级：reset > local release/killed terminal > recovery > ordinary update > allocation。
7. 资源：两 lane 各复制 16 个 local commit AND；既有 ready 归约仅驱动各自外部端口，不回灌
   entry mux。
8. critical path：预期从 PID CAM 到本 entry ready/fire/clear mux；禁止再经过全队列 ready OR。
9. function 划分：不新增 function；CAM、AND、归约与时序更新保持显式硬件。

拓扑自审：端口、状态、复位与优先级自洽；local fire 是现有 ready-hit 的更窄消费者，不引入新
组合环，也不把 current completion 接入 Q-only pregrant。

## 验证与 PPA 计划

1. 先用 assertion-off raw-Q 定向场景证明旧 global-fire 表达式会跨清 incomplete duplicate，
   新 local-fire 表达式只清 ready entry；另测 unknown-only hit。
2. 运行 focused LQ、producer semantic 四配置、parent、DI-5、style。
3. 复用 V13B 同口径做局部 coarse/mapped/OpenSTA 与 current `NpcTop` coarse。
4. 完成独立反例复核；promotion 缺口保持显式。

## 实验结果与回退

- 冻结 V13B RTL 加入 assertion-off raw-state discriminator 后，编译成功并以 3 个因果一致的
  check failure 拒绝旧表达式：lane0/1 incomplete duplicate 被跨 entry 清除，随后
  completion-bypass 因 entry 已丢失而失败。状态为 `EXPECTED_FAIL`，不是编译失败或 timeout。
- local-fire candidate 的 discriminator PASS，覆盖 lane0/lane1 commit 隔离、current-completion
  bypass、unknown-only、exact-1 加无关 X 以及 `commit=X` 的既有外部 fire 可见语义。
- candidate 上默认 `OOO_ASSERT` focused、producer semantic
  `GEN_W=1/4 × OOO_ASSERT on/off`、真实 `tb_ooo_int_backend` 和 DI-5 均 PASS；DI-5 为连续
  64 周期双发射、IPC 2.000、两 lane 各 64 次 completion。
- coarse A/B 完全持平：`4,568 cells / 1,790 $mux / 41,922 wire bits`。
- mapped A/B 由 `18,979 cells / 44,073.68 area` 变为
  `19,272 / 44,773.12`，即 `+293 cells / +699.44 area`；sequential area 均为 `9,264.64`。
- 5 ns ideal-clock OpenSTA 最差 slack 由 `+3.475173950 ns` 变为
  `+3.469281435 ns`，即 `-0.005892515 ns`。原 release global-reduction 路径退出首位，但新最差
  路径为 `valid_q[0]` 到 `paddr_q[7]`，candidate 在 area 与 timing 上同时被 parent baseline 支配。
- 按停止条件，不再运行约 4 分钟的 `NpcTop` coarse、full-core mapped/STA、style、31×2 mutation 或
  系统长测；这些动作不能改变“局部候选已被支配”的决策。
- candidate RTL/spec/TB、功能日志和 PPA 报告已冻结；live RTL/TB/spec 已回退到 V13B
  `5dc60f2f… / 1779aa1a… / e2d5f60d…`，回退后默认断言 focused 再次 PASS。
- candidate-only raw-state discriminator 的处置为 `OBSOLETE_WITH_EVIDENCE`：它验证被拒候选的
  非合同非法状态行为，未加入当前 aggregate；源码快照与 baseline/candidate 日志保留。

当前声明仅为 `diagnostic negative candidate`。V13B design-id `29c0afe8…f483` 保持当前 live
production baseline；本轮没有创建新的 production design-id，也不触发系统再认证。

## 独立终审

- 结论：`APPROVED_NOT_PROMOTION_ELIGIBLE`。
- 批准范围：负候选处置、紧凑证据留存及 V13B production 身份恢复。
- 不批准范围：candidate promotion、整核 PPA、power、system 或未运行 gate 的 PASS 声明。
- reviewer 确认：mapped cells `+293`、area `+699.44`、worst slack `-0.005892515 ns` 足以
  支持当前停止规则下的 rollback；candidate-only invalid duplicate-PID TB 保持
  `OBSOLETE_WITH_EVIDENCE`，没有并入 current aggregate。
