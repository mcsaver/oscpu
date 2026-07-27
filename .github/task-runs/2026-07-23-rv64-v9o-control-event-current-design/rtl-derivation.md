# V9O RTL derivation

## 实现前拓扑快照

- `OooFrontend.u_redirect_arbiter` 已按年龄律生成唯一
  `{valid, pc, kill_idx, reason, flush_fetch, flush_backend}`。
- `pc` 已被 `OooFetchRequestMux` 与 `OooFetchPcOutstandingSequencer` 消费。
- `kill_idx/reason/flush_backend` 当时仍在 `OooFrontend` 内部 unused sink。
- E3 分支误预测在 `OooIntBackend` 内直接由 `branch_resolve_mispredict_w` 扇出到
  ROB walk、rename、IQ、执行 completion、MIQ/SQ、FP 与多周期单元。
- E1/E2 全后端清空由 `core_trap_flush_q` / `core_serial_flush_q` 在提交事件后一拍产生，
  再由 `OooCoreSliceControlGate` 扁平 OR 成 `core_local_flush_w`。

## 初始根因

当前不是 PC 赢家错误，而是同一个架构控制事件存在三份不等价表示：

1. 前端当拍的 arbiter winner；
2. 后端当拍的原始 branch mispredict；
3. 下一拍无类型标签的 trap/serial nuke pulse。

因此 simultaneous source 的赢家、恢复边界与施加周期不能由一个结构化对象重建。

## 待独立复核的设计问题

1. branch winner 改为后端唯一选择性恢复输入后，是否形成 frontend↔backend 组合环；
2. commit winner 与 younger branch 同拍时，现有下一拍 nuke 之前是否存在 completion
   副作用窗口；
3. `reason` 是否需要为 queue-head CSR、pending xRET、SFENCE/FENCE.I 扩展编码；
4. request event 是否应由小型 sequencer 保存为 apply event，从而保持 E1/E2 的一拍时序；
5. 哪些 raw signal 只能保留为 shadow assertion，哪些必须从生产 consumer 物理拆除。

## Recall 记录

`github_index_db.py brief RV64 open architecture debt control event serialize WFI
--profile npc-dev --focus-scope non-history` 返回
`no independent primary focus match`。本轮以 ledger、ROADMAP、架构宪法、flush/redirect spec
与 live RTL 为权威输入；该结果登记为索引召回缺口，不作为 RTL blocker。

补充的定向 recall：

```text
python3 scripts/github_index_db.py brief \
  "RV64 OoO control event ROB commit redirect branch" \
  --profile hardware-flow --focus-scope non-history
```

返回 `recall_status=complete`，并召回 RV64 OoO 宪法、硬件流程 profile 与当前
project-status。实现仍以 live RTL 和本文件冻结的接口合同为准。

## 独立根因复核结论

`control-event-root-cause-review-v2b` 对 live RTL 的只读复核给出以下约束：

1. 最终前端仲裁结果不能直接回送 `OooDispatchBackend`。真实组合路径为
   `branch winner → dispatch freeze → dispatch ready → E4 direct fire →
   OooRedirectArbiter.branch_win`，会形成前端/后端组合闭环。
2. 当前 raw E3 分支误预测不是“无状态清理”：它会冻结 ROB 提交、启动 ROB walk，
   并改变 rename/IQ/MIQ/SQ/LQ/FP 状态。因此更老的队头精确异常或队头 CSR 同拍时，
   raw E3 必须先被一个不依赖本拍恢复输入的队头预授权屏蔽。
3. ROB 必须从 edge-old Q 状态产生：

   ```text
   head_commit_pregrant =
       !rst && !flush && !recover_q
       && commit_ready
       && head_valid && head_done
       && !head0_csr_mem_hold
       && head0_context_permit
       && fencei_retire_permit

   head0_full_flush_pregrant =
       head_commit_pregrant
       && (head_exception
           || (OOO_CSR_QUEUE_HEAD && head0_is_csr))

   branch_selective_apply =
       branch_mispredict_request
       && !head0_full_flush_pregrant
   ```

   这里必须读取 `!recover_q`，不能读取包含本拍
   `kill_valid_i` 的 `recovering_w`。
4. 队头全清空事件使用两阶段时序：C0 允许 lane0 队头精确异常/CSR 提交，
   同拍建立控制屏障；C1 由寄存的 typed apply event 执行全后端清空。
5. 物理总线边界不改变：尚未建立 AXI owner 的 `S_LOOKUP` /
   `S_DEVICE_WAIT` 发起在 C0 保持；已经寄存的 AR/AW/W VALID 及已接受事务继续
   按原 owner/terminal 合同完成。

## 阶段 0 — 跨模块接口契约冻结

### 受影响的 module / wrapper 链

```text
OooRob
  -> OooDispatchBackend
  -> OooIntBackend
  -> OooAluDecodeBackend
  -> OooAluCoreSlice
  -> OooExecuteBackend
  -> OooCoreTopGlue
       -> OooFrontend / OooRedirectArbiter
       -> OooControlEventApplySequencer
       -> NpcCoreTop
            -> OooDualMemBridgeWrapper
                 -> OooMemAxiBridge lane0/lane1

OooIntBackend -> OooFpBackend
```

### 六类跨模块合同

| 类别 | 冻结合同 |
| --- | --- |
| 握手 | C0 屏障不得伪造任何 `valid && ready` 接受。dispatch、INT/FP issue、memory reservation、memory request 和 bridge station 接受均为 0。已经寄存的 AXI VALID 不撤回，payload 保持到 READY。 |
| 反压 | `head0_control_event_pregrant` 只读 ROB Q、提交准入、Q-only memory quiet 和 exact pending CSR owner，不读取 dispatch/direct/branch-apply；因此 `pregrant → dispatch ready` 是单向路径，不回到 pregrant。`head0_full_flush_pregrant` 是其中需要 C0/C1 full 行为的子集。 |
| 清空/重定向 | `backend_action` 为单一 typed 字段：`NONE`、`SELECTIVE_NOW`、`FULL_NEXT`。C0 branch 只执行严格年轻选择性恢复；C0 full 只建立屏障；C1 typed apply 执行全后端清空。 |
| 异常序 | full 事件只能来自 ROB lane0/head。C0 必须保留 `commit0` 与 CSR/trap 架构写，`commit1=0`；更年轻 completion/PRF write/wakeup/retirement 不得可见。exact pending CSR 提交为 action `NONE`，只关闭 dispatch/branch，不建立 full completion cut。 |
| 访存序 | C0 不建立新的 MIQ/SQ/bridge owner，不接受年轻 memory completion；已登记的 STORE/AMO/AXI owner 继续驻留并完成。C1 保持既有 committed/nokill/DRAIN survivor 规则。 |
| 投机恢复/单一真源 | raw branch 只形成 `branch_mispredict_request` 和 shadow assertion；所有生产恢复消费者只读取 `branch_selective_apply`。fetch 侧 control event 统一携带 `valid/pc/reason/kill_younger_than/flush_fetch/backend_action`。 |

### 清什么 / 保持什么

| 事件阶段 | 清除或阻断 | 必须保持 |
| --- | --- | --- |
| branch `SELECTIVE_NOW` C0 | 严格年轻 ROB suffix、rename/IQ/LQ/SQ/MIQ/FP/long-op 成员；严格年轻 completion | boundary 本身与更老项；committed store；已登记 AXI owner |
| full `FULL_NEXT` C0 | 只阻断新的 dispatch/issue/request/owner 与严格年轻 completion；不启动 ROB walk | lane0 trap/CSR commit、CSR/trap operand、ROB head、所有已登记物理事务 owner |
| full apply C1 | 清除推测性 ROB/rename/IQ/FP/LSQ 状态，前端重新取指 | C0 已完成的架构写；committed/nokill/DRAIN/已登记 AXI owner 的终结记录 |

### 同拍优先级

```text
rst
  > external flush
  > C1 typed full-flush apply
  > C0 head full-flush pregrant
  > C0 branch selective apply
  > direct frontend redirect
  > normal dispatch / issue / completion
```

`head0_full_flush_pregrant` 与 `branch_selective_apply` 由构造互斥。E5 pending
CSR 已纳入 exact `{type, ProducerId}` 队头预授权：其 action 为 `NONE`，但在同拍优先于
更年轻 branch。E6 drained redirect 与在飞 branch 的同拍碰撞仍由 stop/drain 结构排除，
并继续由立即断言检查；两者都不把最终前端赢家回送到后端 ready 锥。

## 阶段 1 — 需求

### 功能目标

1. 为每个前端控制事件提供统一字段：
   `valid, pc, reason, kill_younger_than, flush_fetch, backend_action`。
2. `REDIR_REASON_W` 扩为 4 位，至少独立编码 `CSR_COMMIT`；branch 与 JALR
   误预测按真实解析类别编码。
3. raw branch request 在队头 full pregrant 同拍不得启动 ROB walk，也不得影响
   lane0 提交。
4. 队头精确异常/CSR 在 C0 建立屏障，在 C1 用寄存 typed event 执行全后端清空。
5. 两个数据桥在 C0 只阻止 pre-owner 发起，不改变已寄存 AXI owner 的协议行为。
6. exact pending-system CSR owner 提交在 C0 关闭新 dispatch 与同拍更年轻 branch，但
   不产生 full barrier、completion cut 或 C1 apply。

### 时序/性能边界

- branch-only 仍在解析拍执行选择性恢复，不增加一拍。
- trap/CSR 的全后端清空仍为提交后下一拍，不前移、不延后。
- pregrant 增加的是 ROB head Q 的窄组合判定；不得引入
  frontend-arbiter → backend-ready 的返回路径。
- AXI registered VALID 路径不增加组合屏障门。

### 不在范围内

- 不改变 MMU flush、cache policy、TLB/PMP/PMA 语义。
- 不把 E5/E6 legacy pending owner 迁回 ROB。
- 不据本切片声明 full-core architecture freeze 或 PPA promotion。

## 阶段 2a — 协议规则

1. `head0_control_event_pregrant` 是单周期组合 pregrant；只有 C0 提交条件完整成立且
   队头为 full 事件或 exact pending CSR owner 时为 1。
2. `head0_full_flush_pregrant` 是 `head0_control_event_pregrant` 的 full-action 子集；
   只有它建立 C0 barrier、strict-younger completion cut 与 C1 request。
3. `branch_selective_apply` 是单周期组合 grant；其 payload 与已寄存 branch resolve
   packet 同源。
4. `OooControlEventApplySequencer` 在 C0 接受 `{reason, kill_idx}`，C1 输出
   `apply_valid` 与稳定 payload；C1 后自动清除。
5. `redirect_valid` 与 `control_event_valid` 分离：misaligned branch 可以执行后端
   选择性恢复而不产生 fetch redirect。
6. bridge 屏障拍：
   - `mem0_req_ready_o=0`；
   - `stage_advance_w=0`；
   - `S_LOOKUP` miss 与 `S_DEVICE_WAIT` release 不拉高新的 ARVALID，也不推进到
     registered AR owner；
   - `S_WALK_AR/S_READ_ADDR/S_WRITE_REQ/S_AD_UPDATE` 已寄存 VALID 保持原样。

## 阶段 2b — 状态机

### typed full-flush apply sequencer

| 当前状态 | C0 request | 下一拍状态 / 输出 |
| --- | --- | --- |
| idle (`apply_valid_q=0`) | 0 | idle |
| idle | 1 | `apply_valid_q=1`，锁存 reason/kill_idx |
| apply (`apply_valid_q=1`) | 0 | idle |

`rst` 或 external `flush_i` 高于 request。合法结构下 C1 不会出现新的 request；
若出现，立即断言报告连续 full event。

### bridge 局部保持

| edge-old state | C0 barrier 行为 |
| --- | --- |
| `S_IDLE/S_RESP` + station | station 不 advance |
| `S_LOOKUP` miss | 留在 `S_LOOKUP`，不建立 AR owner |
| `S_DEVICE_WAIT` + release | 留在 `S_DEVICE_WAIT`，不建立 AR owner |
| `S_WALK_AR/S_READ_ADDR` | 已寄存 ARVALID 保持到 READY |
| `S_WRITE_REQ/S_AD_UPDATE` | 已寄存 AW/W VALID 及 payload 保持 |
| response state | backend ready 为 0；bridge 可吸收总线 terminal 并保存 response |

## 阶段 2c — 不变量

| 编号 | 触发 | 必须成立 | 违反后果 |
| --- | --- | --- | --- |
| CE-I1 | `head0_full_flush_pregrant` | `!recover_q` 且 head valid/done，提交准入完整，head 为 exception 或 queue-head CSR | older commit 被错误屏蔽或错误建立屏障 |
| CE-I2 | full pregrant | `!branch_selective_apply` 且 ROB walk 不启动 | younger branch 影响更老架构提交 |
| CE-I3 | branch apply | full pregrant 为 0，选择性边界等于 branch ROB idx | 恢复边界错配 |
| CE-I4 | full pregrant C0 | lane1 commit、dispatch、INT/FP issue、memory request/accept、年轻 completion 均为 0 | 年轻状态越过提交边界 |
| CE-I5 | full request C0 | C1 typed apply 恰好一拍，reason/kill_idx 与 C0 相同 | 全清空阶段提前、延后或 payload 漂移 |
| CE-I6 | control event valid | `backend_action` 与 reason/source 同源；`flush_backend` 只由 action 派生 | 布尔 ABI 与 typed event 分叉 |
| CE-I7 | bridge barrier | speculative AR launch、station accept/advance 为 0 | 建立新的物理事务 owner |
| CE-I8 | barrier + registered AXI VALID | VALID/payload 不因 barrier 撤回或改变 | AXI 协议 owner 被破坏 |
| CE-I9 | completion cut | `(producer-head) > (boundary-head)` 才失效；等于 boundary 的 producer 存活 | 环形年龄或 strict-younger 语义错误 |
| CE-I10 | exact pending CSR owner | pending type 为 CSR，ProducerId 精确匹配 ROB head；`control_event_pregrant=1`、`full_flush_pregrant=0` | stale/wrong owner 获得提交优先级或误发 C1 full apply |
| CE-I11 | canonical frontend winner | frontend `SELECTIVE_NOW/FULL_NEXT` 与 cycle-free backend branch/full 投影双向等价 | 前端年龄赢家与生产后端动作分叉 |
| CE-I12 | trap/CSR architectural commit | trap commit 当且仅当 `TRAP` full pregrant；queue-head CSR commit 当且仅当 `CSR_COMMIT` full pregrant | 从提交脉冲重建晚到 C1 request，C0 屏障缺失 |

## 阶段 2d — 数据通路约束

- ROB pregrant 组合锥：
  `head_q → valid/done/exception/inst/ProducerId → commit permits/mem_quiet/exact pending owner → pregrant`。
  其中 LQ retire permit 的 candidate 读取 `recover_q`，不得读取含 current branch
  `kill_valid_i` 的 `recovering_w`；LQ terminal permit 只读取 registered
  `completed_q`，不得读取 current formal-WB hit；实际 commit 仍读取 `recovering_w`
  和普通 `release_ready`。
- branch grant 组合锥：
  `registered branch resolve packet → raw request → !pregrant → selective apply`。
- typed event 前端锥：
  三路 source age 比较 → winner mux；`redirect_valid =
  event_valid && winner.flush_fetch`。该 winner 是规范参考与前端真源；生产后端使用
  cycle-free 投影，二者以双向断言绑定，不能直接形成组合反馈。
- full apply 时序锥：
  `pregrant/reason/head_idx → apply_q → legacy trap/serial typed views →
  core_local_flush`。
- completion 资格锥：
  ROB Q exact ProducerId + strict-younger event boundary；不得回到 source
  ready 或 pregrant。
- 预计新增关键路径仅为窄 ROB head 判定和 2-bit action mux；AXI VALID 路径保持
  只读既有 owner Q。

## 阶段 2e — RTL 级电路拓扑

1. `OooRob` 新增三个组合输出：any-control pregrant、full pregrant 与 full reason；无新状态。
   exact pending CSR owner 以 `{slot_generation, rob_idx}` 匹配。
   `head0_retire_candidate_valid_o` 改为 edge-old `!recover_q` 观察，切断经 LQ
   retire-permit 返回 commit-ready 的组合环；实际 commit 继续以 `!recovering_w` 关门。
   `commit_pregrant_ready_i` 与 `commit_ready_i` 分离，前者只消费 LQ
   `release0_q_ready_o` 的 registered-completion view，切断 completion-cut/WB 返回环。
2. `OooDispatchBackend` 透传两个 pregrant；any-control pregrant 加入 dispatch freeze。
3. `OooIntBackend` 将 raw request 与 apply 分离；full pregrant 加入 INT/memory issue
   block，并送 `OooFpBackend` 作为仅阻断 launch/visible completion 的 C0 barrier。
   any-control pregrant 关闭更年轻 branch event；pending CSR action-NONE 不误作 full barrier。
4. wrapper 链只透传 bool/reason，不新增状态或仲裁。
5. `OooFrontend/OooRedirectArbiter` 新增 2-bit `backend_action` 字段，并把
   `control_event_valid` 与 fetch `redirect_valid` 分开。
6. `OooControlEventApplySequencer` 是唯一新增状态：
   `apply_valid_q + reason_q + kill_idx_q`。
7. `OooCoreTopGlue` 的 C1 request valid/reason 只直接读取
   `control_full_flush_barrier/reason`；typed apply 输出生成 legacy trap/serial 观察信号。
   实际 trap commit 与 queue-head CSR commit 分别和 `TRAP/CSR_COMMIT` pregrant 做双向
   等价断言；旧两个 sequencer 输出只保留为 shadow-equivalence。
8. `NpcCoreTop → OooDualMemBridgeWrapper → OooMemAxiBridge` 透传 C0 barrier；
   bridge 只在 station/pre-owner 组合臂读取它。
9. `OOO_CSR_QUEUE_HEAD=1` 下，普通 memory reservation 不要求“当前 ROB head”：
   CSR dispatch 后的 `head0_csr_inflight` 阻止 younger 接收，而已经驻留 backend 的 memory
   都是 older，必须继续 issue/drain 才能满足 CSR `mem_quiet`；AMO 仍保留专用 head 规则。
10. reset/优先级：每个新时序块均为 `rst || external flush > normal capture`；
   C0 barrier 本身不作为 leaf flush。

## 阶段 3 — RTL 实现状态

已实现并进入证据闭合阶段：

- C0 any-control/full pregrant、exact pending CSR ProducerId 匹配与 branch 优先级已接入；
- C1 typed apply sequencer、frontend typed action、full/branch 投影双向断言已接入；
- dispatch、INT/FP、memory station、dual bridge 与 registered AXI owner 边界已接入；
- default focused、`OOO_CSR_QUEUE_HEAD=1` focused/generic aggregate及 11 项
  compile-success RTL 变异已通过当前 task-run 的指定 oracle；其中新增变异把 C0 request
  错接为 trap commit pulse，并由真实 queue-head CSR C1 oracle 拒绝；另有 1 项由 full-cone
  Verilator 重现组合 SCC，live baseline 为 `UNOPTFLAT=0`。
- ROB 定向验证用 `head=15/younger=0` 的环绕布局，在真实 exception full pregrant 下
  同拍切断 8/8 completion query；双 memory wrapper 定向验证让两 lane 同时驻留
  `S_READ_ADDR`，在 4 个 barrier 周期及 2 个 R terminal 期间保持两份 AR payload 和共享
  arbiter owner，两个 owner token 各完成一次。
- focused 10/10、宏配置 3/3 与 module aggregate 110/110 的每份日志均写入运行时
  `[RTL-DESIGN-ID]`；runner 在执行前后复算 146-file canonical RTL digest。

最终状态仍以本 task-run 的 fresh aggregate、canonical architecture gate、证据哈希与独立
终审为准；未完成这些步骤前不得把本切片或全核标记为架构冻结。
