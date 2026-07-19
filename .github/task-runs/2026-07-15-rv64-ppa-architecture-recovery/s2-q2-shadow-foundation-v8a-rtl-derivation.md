# S2-Q2 v8a neutral shadow RTL 推导

> 日期：2026-07-19
>
> 设计状态：`intermediate_checkpoint`；只实现行为中性的 shadow foundation，不构成
> `complete_design_point`，不得进入 Pareto/promotion。

## 0. Completion definition 与父状态

- 父状态是本轮开工时的当前 dirty worktree，不假定 `HEAD` 等于 live RTL。九个承重 RTL 与
  `tb_ooo_rob.sv` 的 pre-edit SHA-256 分别为：
  `050d6ff7...fb2c`、`78e1ebd8...c5c`、`84b36789...567`、
  `5e9eb957...c6e`、`ca0ad029...685`、`16207393...00f`、
  `4bd97615...45f`、`290430e3...f86`、`c4a1f8d6...9a8`、
  `70a73161...bdd`；最终 runner 必须保存完整路径/hash，不以这些缩写作机器证据。
- 联合修改块：26 个 context/epoch ABI 宏；ROB 的 2 permit、3 observation、precommit/base-ready
  分解和 lane1 shadow classifier；七层 wrapper transport；`NpcCoreTop` exact tie-high；所有直接
  module TB 的中性接线；ROB focused positive/equivalence/negative。
- 本切片完成条件：v8a checker 在 release/`OOO_ASSERT` 两变体均 0 RED；17/17 checker mutation；
  ROB 动态语义、七层直接 TB、module aggregate、lint/style/contract/full default build 均真实执行；
  严格 lint/build 若命中父工作树既有 RED，只允许在归一化诊断集合与 pre-edit 快照逐项相同且
  非致命解析/展开通过时交付 **scoped GREEN + global RED**，不得写成全核通过；故意破坏
  observation invariant 会触发唯一目标断言；source pre/post/evidence 有 SHA-256 绑定。
- 最大结论边界：`v8a shadow RTL/interface GREEN`。Q1、active permit、full identity provenance、
  context payload、FENCE.I transaction、selective squash、dynamic epoch、双 memory、Linux、
  physical 200 MHz、Area/Power/PPA 均不在本 completion definition 内。
- 回退点：只回退本文件列出的 v8a 新增端口/组合影子/宏/TB/spec；不得覆盖工作树既有 Q0、P4
  或其它用户改动。

## 1. 阶段 0：接口契约冻结

### 1.1 端口与方向

```text
NpcCoreTop
  -> OooCoreTopGlue -> OooExecuteBackend -> OooAluCoreSlice
  -> OooAluDecodeBackend -> OooIntBackend -> OooDispatchBackend -> OooRob

downstream inputs : head0_context_permit_i, fencei_retire_permit_i
upstream outputs  : head0_retire_candidate_valid_o,
                    head0_identity_valid_o,
                    head0_identity_o[OOO_CONTEXT_ID_W-1:0]
```

所有 wrapper 只作同名、同宽、无状态端口映射。`NpcCoreTop` 是唯一 tie-high owner；三个 observation
只能由锁名 child 输出驱动，宿主不得增加第二 writer。

### 1.2 六类跨模块契约

| 类别 | v8a 冻结规则 |
| --- | --- |
| 握手 | permit 是组合 level qualification，不是 valid/ready 事务；无 hold/payload 义务。observation 是只读 facts，不接受 backpressure。 |
| stall DAG | 新路径只有 `NpcCoreTop constant -> ROB commit qualification` 单向下传和 `ROB facts -> NpcCoreTop` 单向上返；observation 禁止回灌 permit/commit/dispatch，故不形成组合环。 |
| flush/redirect | wrapper 无状态。`flush_i` 仍按既有 ROB reset/flush 分支清 `valid/count`；下一组合拍 `identity_valid=0`。kill/recovery 只令 retire candidate 为 0，identity-valid 仍只回答当前 head 是否 live。trap/redirect/CSR 原优先级不变。 |
| 异常序 | `commit0_fire` 仅在旧 base-ready 上附加两个 permit；顶层恒 1。`commit1_fire` 禁止依赖 lane1 shadow，原 exception-lane0-only 和 CSR 单发规则不变。 |
| 访存序 | 不新增 request、owner、SQ/MIQ/cache/AXI consumer；`mem_quiet_i` 与现有 CSR hold 方程不变。 |
| 投机恢复/单一真源 | head identity 的 v8a 唯一真源是 ROB `head_q`；identity-valid 的真源是 `count_q && valid_q[head_q]`。该 8-bit 值只是零扩展的观察 identity，不宣称 generation/reuse 安全。 |

### 1.3 精确组合方程

```verilog
head0_retire_candidate_valid_o =
    !recovering_w && (count_q != 0) && valid_q[head_q] && head_done_w;
head0_identity_valid_o = (count_q != 0) && valid_q[head_q];
head0_identity_o = zero_extend(head_q, OOO_CONTEXT_ID_W);

head0_base_ready_w =
    !recovering_w && commit_ready_i && (count_q != 0) &&
    valid_q[head_q] && head_done_w && !head0_csr_mem_hold_w;
commit0_fire_w = head0_base_ready_w &&
                 head0_context_permit_i && fencei_retire_permit_i;
```

lane1 raw CSR/SFENCE.VMA/xRET/FENCE.I classifier 采用 v8a contract 的 exact equation；
`head1_context_boundary_shadow_w` 只读 `valid/done/exception/raw-class`，禁止进入 `commit1_fire_w`。

### 1.4 同拍优先级与 flush 保持表

| 事件 | ROB 原状态 | v8a 组合输出/行为 |
| --- | --- | --- |
| `rst || flush_i` | 既有最高优先级清 ROB | wrapper 无状态；清空后 identity-valid/candidate 均 0 |
| `recover_q` | 既有 walk 优先，冻结 commit/dispatch | candidate=0；live head identity 仍可观察 |
| `kill_valid_i` | 既有 kill 当拍冻结 commit/dispatch | candidate=0；不新建 shadow 状态 |
| normal + permit=1/1 | 既有 commit | 与旧 commit0 逐位等价 |
| normal + 任一 permit=0 | ROB 项保持 live | `commit1 -> commit0` 前缀关系令两 lane 都不退休；v8a 顶层不可到达，供 v8b 激活 |

## 2. RTL 四段式推导

### 2.1 需求

1. 提供 commit-ready-independent 的 head0 retire candidate 和 done-independent 的 live head
   identity-valid/identity 观察口。
2. 预埋两路 future permit，但在 live top 精确 tie-high，保证本切片不改变 retirement。
3. 形成 lane1 potential context boundary shadow，且不得激活 commit1 gate。
4. 所有直接 TB 显式 tie-high，禁止未连接 `Z` 造成假回退。
5. out-of-scope 维持 v8a blocker 表，不实例化 Q1、不捕获 payload、不推进 epoch。

### 2.2 协议规则

- 三个 observation 当拍组合反映 ROB Q；不存在 request/ack、持有或重试。
- permit 在同拍参与 commit0 qualification；0 时 ROB head 保持，重新拉高后按原条件退休。
- wrapper 不解释、不寄存、不重编码任何字段；identity 宽度全链固定为
  ``[`OOO_CONTEXT_ID_W-1:0]``。

### 2.3 状态机

v8a 新增状态机：无；新增寄存器：无。继续复用 ROB 既有优先级：
`reset/flush > recover walk > kill-start > normal commit/writeback/dispatch`。

### 2.4 不变量

- `V8A-I1`：live top 的两 permit 恒为 1；因此 new commit0 等于 old base-ready。
- `V8A-I2`：candidate 为 1 必须同时 identity-valid、done 且不在 recovering。
- `V8A-I3`：identity-valid 不依赖 done/recovering/commit-ready/commit-fire。
- `V8A-I4`：每级 observation 只有 canonical child driver，permit 只有 canonical parent driver。
- `V8A-I5`：lane1 shadow 为 1 不得因该 shadow 自身阻断 commit1。
- `V8A-I6`：任何 v8a 输出不得成为 SQ/MMU/FENCE/CSR apply 或 epoch consumer。
- `V8A-I7`：`commit1_fire_w` 蕴含 `commit0_fire_w`；任何 permit 拉低时都不得越过 head0
  单独退休 lane1。

`V8A-I2` 转为 `OOO_ASSERT` 立即断言；focused negative 在 candidate 非真空后强制破坏
identity-valid，证明断言会响。其余由 exact structural checker、动态 permit/commit TB 与 source
dependency negative 联合覆盖，避免只重述同一 RTL 方程。

### 2.5 数据通路约束

- 关键状态只含既有 `head_q/count_q/valid_q/done_q/exception_q/inst_q`；无新增 state。
- 新组合网络是 head select、四个 lane1 equality/class compare、两个 permit AND，以及纯 wire spine。
- identity 只允许零扩展 `head_q`，不得拼 generation 或 live payload。
- 新增逻辑不共享算术资源、不引入 function/for-loop/memory port。
- 潜在路径为 ROB Q→candidate/identity→wrapper top observation；它没有 active consumer。
  commit path 仅多两个恒 1 qualification，综合可常量折叠；本切片不据此声称 timing 改善。

### 2.6 RTL 级电路拓扑自审（9 项）

1. module 边界：八层均为单 `clk/rst` 域；新增端口方向和宽度见 §1.1。
2. 状态寄存器：新增 0；全部更新仍归既有 OooRob 时序块。
3. 组合块：ROB 六个 exact `assign` + lane1 classifier；wrapper 只有 port net。
4. FSM：新增 0；既有 ROB recovery FSM 不改 transition。
5. pipeline/valid-ready：新增 0 个拍界；不改变 dispatch/WB/commit valid-ready。
6. 控制优先级：保持 §1.4；permit 只在 normal commit 资格末端。
7. 资源：无复制/共享资源；lane1 compare 仅 shadow 门级逻辑。
8. critical path：candidate/identity 无 consumer；commit 多两级恒值 AND，不能越级作 PPA 结论。
9. function 划分：不新增 function；控制/仲裁不封装进 function。

自审结论：拓扑没有双向组合边、状态复制、活跃 side effect 或未定义 flush owner，可进入 RTL
翻译；若 checker/编译显示任一 wrapper 方向或直接 TB 漏接，先回到本合同修正而非局部绕过。

## 3. 实现后 completion audit（2026-07-19）

- exact chain 已落入 7 个 RTL 实例和 8 个直接 TB 实例；补充 checker 的全树 census=15，
  五个 named port 均存在、permit 输入非空、无 positional 旁路。
- 冻结 checker 在 release/`OOO_ASSERT` 均为 0 RED，17/17 mutation 通过；实现补充 checker
  exact 锁定旧 `commit1_fire_w` RHS、六类 lane1 classifier 非依赖、identity 零扩展、标量 ABI、
  base-ready 限域，其 canonical fixture 与 4/4 定向 mutation 通过。
- focused 双变体、显式 ``OOO_CSR_QUEUE_HEAD=0/1``、candidate-live assertion negative 均通过；
  两个 ready entry 下分别拉低两个 permit 时两 lane 均不退休且 count 保持 2，双高恢复双退休；
  CSR/SFENCE.VMA/xRET/FENCE.I 四类 lane1 边界均实际触发且不改变原 commit0/1。
- candidate 与 SHA-256 `812fa351...ab9a5` 的 pre-edit source bundle 在 release 和
  `OOO_ASSERT` 下，各自 1036 行 legacy ABI trace 字节相同。该证据是 bounded simulation
  equivalence，不是形式等价。
- module aggregate 为 104/104；RTL style 与 contract 通过（立即断言 289，基线 89）。
- strict lint 与强制 `make -B default` 均因 115 条父工作树告警保持 RED；最新规范化签名与
  pre-edit 快照逐字节相同：108 `TIMESCALEMOD`、2 `PINCONNECTEMPTY`、4 `LATCH`、
  1 `UNOPTFLAT`；`-Wno-fatal` 解析/展开通过。既有 RED 未豁免。

结论严格限定为 **v8a tie-high scoped neutral shadow foundation GREEN**。全核 lint/build
仍为 RED；active permit/Q1/full identity 与 generation/epoch/FENCE.I transaction/形式等价/
Linux/200 MHz/面积/功耗/PPA 均未证明。
