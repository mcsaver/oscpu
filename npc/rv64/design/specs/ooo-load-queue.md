# OooLoadQueue：retire-resident Load Queue

> 状态：v8v OOO-3 active RTL。共享 LQ 已接入 `OooIntBackend` 的双 dispatch、双 memory
> reservation、双 MIQ launch、最终 PA/SQ ordering query、双 response、formal WB、memory
> terminal、双 ROB retirement 与 recovery 路径。该模块规范不单独构成 overall architecture
> 或 PPA promotion 结论。

## 1. 目的与范围

`OooLoadQueue` 为所有 ordinary integer/FP load 提供从 dispatch 到 ROB retirement 的架构生命周期。
它解决三个边界问题：

1. 两个 bank-local `OooMemInflightQueue` 只保存传输顺序，不能表达已完成但尚未退休的 load；
2. 最终 PA 到达后必须以完整 `ProducerId` 记录 SQ 的 allow/forward/replay disposition；
3. recovery 后，尚未 launch 或已记录 terminal 的 load 可直接释放；已经 launch、
   未完成且 physical owner 尚未 terminal 的 load 必须保留 killed tombstone，直到精确
   memory-owner terminal 到达。

LQ 不负责 store 顺序判定、数据合并或 store side effect。`OooStoreQueue` 是唯一 physical byte
disambiguation oracle；LQ 只记录并强制执行其结果。AMO/LR/SC 不进入本 LQ，继续使用既有
singleton/StoreQueue 生命周期。

默认 `ENTRY_N=16`，等于当前 ROB 容量。4-entry LQ 会在两个连续双-load dispatch 后满，破坏
已验证的 steady dual-memory issue；因此生产配置不能把 focused TB 的 4-entry 参数误当成默认值。

## 2. 接口契约

### 2.1 端口分组

| 边界 | 方向 | 时序 | 语义与 owner |
| --- | --- | --- | --- |
| `alloc[01]` | dispatch → LQ | Q credit + edge fire | ordinary load dispatch 后，以完整 `ProducerId` 和 ROB index 建立 retire-resident entry；lane1 是 lane0 的 prefix extension |
| `issue[01]` | reservation → LQ | 组合 CAM lookup | entry live、非 killed、非 completed 才 `open`；只读，不形成 response-ready→request-valid 组合环 |
| `launch[01]` | MIQ request fire → LQ | edge event | 精确 bank request fire 置 `launched`；retry 对同一 `ProducerId` 幂等 |
| `query[01]` | final-PA SQ query ↔ LQ | 组合授权 + edge update | 必须命中 launched live entry；首次记录 PA/attr/class/strb，重试必须 metadata 完全一致；disposition 必须 allow/forward/replay onehot |
| `response[01]` | MIQ response → LQ | 组合授权 | successful response 仅在 `ordered=1` 时开放；fault 可绕过 ordered，但不能绕过 live full-PID ownership |
| `completion[01]` | formal WB → LQ | edge event | 任意 WB port 的完整 `ProducerId` CAM 命中后置 `completed`；非 load WB 自然 miss |
| `terminal[01]` | collector dequeue + tracker edge-old token→PID → LQ | edge event | 只允许 `deq_valid && deq_ready && kind==LOAD`；PID 必须在 tracker exact-free 同沿读取 edge-old table。killed launched tombstone 直接释放；normal load 置 `terminal_seen_q`，结束 physical-owner lifetime，但不结束 retire residency |
| `release[01]` | ROB retirement ↔ LQ | Q lookup + commit/fire | `release_valid` 查询队头 load 的完成资格；`release_ready` 保留 leaf-level current formal-WB bypass，`release_q_ready` 只接受 registered `completed_q` 并专供 C0 pregrant；只有真实 `commit` 与 `ready` 同拍才 `fire/free`；双 retirement 必须是不同 `ProducerId` |
| `producer_live_mask` | LQ → global birth fence | Q-state observation | 所有 live entry 的完整 `ProducerId` 位图，阻止有限 generation 在旧 load 生命周期结束前复用 |
| `flush_*` | recovery → LQ | edge event | global flush、accepted checkpoint restore apply 或 wrap-safe selective suffix recovery；处理规则见 §3.2 |

### 2.2 双分配与背压

分配器只观察 edge-old `valid_q`：

```text
free0 = first(!valid_q)
free1 = second(!valid_q)
alloc0_fire = alloc0_valid && free0_found && !flush_valid
alloc1_fire = alloc1_valid && free1_found && alloc0_fire
```

因此不能借用同拍 retirement/recovery 释放的槽位，也不会产生 allocation→retirement ready 环。
`OooDispatchBackend` 在普通 load 的 dispatch ready 中合取对应 LQ credit；已经形成 dispatch fire
却无 LQ credit 是集成违约。

### 2.3 典型时序

```text
cycle       N        N+1       N+2 ... response      WB/retire
dispatch    fire
LQ          alloc    issue-open launched  ordered      completed/free
reservation          consume
bank request                    fire
SQ final PA                       allow|forward|replay
MIQ response                                      valid/open
formal WB                                                   fire
ROB lookup                                        valid/ready
ROB commit                                                  fire/free
```

`response` 不是 `completion`。response 只有在 formal WB arbiter 真正授予 credit 后，才经 generic
WB port 把 LQ entry 标记 completed。ROB 的 Q-only lookup 先读取 LQ `ready` 并形成 active commit
permit；entry 只在真实 commit edge 上释放，同拍 completion 可进入普通
`release_ready` bypass，但不得进入 `release_q_ready` 或 ROB C0 pregrant。

## 3. 状态与时序模型

### 3.1 逻辑状态

物理实现使用 `valid/launched/pa_valid/ordered/completed/killed` 位，而非编码 FSM；合法组合等价为：

```text
FREE
  └─ dispatch alloc ───────────────> RESERVED
RESERVED
  ├─ request fire ─────────────────> LAUNCHED
  └─ targeted recovery ────────────> FREE
LAUNCHED
  ├─ SQ allow/forward ─────────────> ORDERED
  ├─ SQ replay ────────────────────> LAUNCHED(pa_valid=1, ordered=0)
  ├─ formal WB/fault completion ───> COMPLETED
  ├─ normal owner terminal ────────> TERMINAL_WAIT_COMPLETION
  └─ targeted recovery ────────────> KILLED_DRAIN
ORDERED
  ├─ formal WB ────────────────────> COMPLETED
  ├─ normal owner terminal ────────> TERMINAL_WAIT_COMPLETION
  └─ targeted recovery ────────────> KILLED_DRAIN
TERMINAL_WAIT_COMPLETION
  ├─ formal WB ────────────────────> COMPLETED
  └─ targeted recovery ────────────> FREE
KILLED_DRAIN
  └─ exact memory terminal ────────> FREE
COMPLETED
  └─ exact ROB retirement ─────────> FREE
```

成功数据 response 只能从 `ORDERED` 取得授权。fault response 可以从 launched live entry 取得授权，
从而形成精确异常，但仍不能命中 stale generation、killed 或 completed entry。

### 3.2 recovery 保持表

| recovery 类型 | 清除/阻塞 | 保持 |
| --- | --- | --- |
| global `flush_all` | 所有 unlaunched、completed 或 `terminal_seen` entry | launched、incomplete、尚未 terminal 的 owner 变为 killed tombstone，等待 lossless terminal |
| checkpoint request/hold | 阻塞新 dispatch、issue、reservation capture、MIQ push 与 bridge request；不产生破坏性清除 | edge-old response/formal WB 可继续；若已有 physical store/AMO write lease，只允许该精确 ROB-head owner 在 lane0 退休，lane1 禁止退休 |
| checkpoint restore apply | ROB/IQ/rename/PRF/FP/SQ/MIQ/execution holder 与所有 unlaunched/completed/terminal-seen LQ entry 同步恢复 | 已 launch、未完成且 owner 尚未 terminal 的 load 只在 LQ 保留 tombstone，等待 bridge 精确 terminal；apply 前已发射的 physical store/AMO 必须已完成 B、formal WB、lane0 ROB retirement 与 SQ release |
| branch selective recovery | wrap-safe younger suffix 中的 unlaunched/completed/terminal-seen entry | younger launched、incomplete、owner-pending entry 变 killed tombstone；older prefix 原样保持 |
| non-target entry | 无 | 全部状态位与 metadata |

`checkpoint_restore_i` 是请求，`checkpoint_restore_hold_w` 是准入冻结条件，
`checkpoint_restore_apply_w` 是唯一 backend-wide 破坏性恢复脉冲。physical write 从 bank0
`req_fire` 到同一完整 `ProducerId` 的 lane0 ROB retirement 持有不可撤回 lease；apply 同时要求
lease 为空、SQ 无 `request_sent`、DRAIN 不在飞。内存控制面只接收 accepted apply，不能用 raw request
提前清 bridge/MIQ owner。

selective age 使用 `rob_dist(idx, head)=idx-head` 的模 ROB 距离；target 条件是 entry distance 大于
boundary distance，覆盖 `15→0` wrap。

### 3.3 同拍更新优先级

每个 edge-old live entry 的优先级为：

1. exact ROB release 或 killed terminal：清 entry；
2. recovery target：unlaunched/completed/terminal-seen 清除，只有
   launched、incomplete、owner-pending entry 转 killed tombstone；
3. formal completion、query disposition、launch：更新现有 entry；
4. edge-old free slot allocation：写入新 entry。

allocation 只选择 edge-old free slot，因此第 4 项不会覆盖 1–3 项处理的 live entry。

## 4. 承重不变量

1. **Full-PID ownership**：所有 CAM 比较使用 generation+ROB index；ROB index 只用于年龄与一致性检查。
2. **唯一驻留**：任意两个 live entry 的 `ProducerId` 不得相同；所有 lookup hit 向量 onehot0。
3. **容量真实回压**：`count==ENTRY_N` 时无 dispatch credit；不能覆盖或静默丢 entry。
4. **最终 PA 稳定**：第一次 query 后，PA、attr-valid、class、strb 的任一变化均 fail closed。
5. **有序响应**：成功 response 要求 allow/forward；replay 状态不得完成。fault 只绕过 ordered 位。
6. **formal completion 承重**：normal memory terminal 只置 `terminal_seen_q`，不释放
   retire-resident entry；ROB retirement 不能早于 formal WB。terminal-seen entry 的
   issue/query/response 全闭合，但仍可接受同一 PID 的滞后 formal completion。
7. **lossless recovery**：launched incomplete 且 owner-pending load 的 recovery 不得立即清
   entry；killed entry issue/query/response 全闭合，只有 exact terminal 可释放。若 exact
   terminal 已先发生，recovery 必须直接清 entry，不得制造等待第二个 terminal 的 tombstone。
8. **双端口无别名**：双 final-PA query 若携带同一 PID，两个端口均 fail closed；双 release 同拍不得使用同一 PID；双 dispatch 分配必须使用不同 edge-old free slot。
9. **C0 pregrant 无环**：`release_q_ready` 只由 entry 的 registered `completed_q`
   产生，不读取当拍 completion/WB；普通 `release_ready` 的兼容 bypass 不得连接到
   `commit_pregrant_ready_i`。
9. **birth fence 完整**：每个 live entry 的完整 PID 位必须出现在 `producer_live_mask_o`，count 与 valid popcount 相等。
10. **集成边界闭合**：dispatch fire、reservation consume、MIQ LOAD launch 与 ROB load retirement 分别接受 LQ credit/open/live/complete 资格；retire lookup 对 ROB commit 形成 production 反压，模块内断言和 parent 断言相互独立。
11. **post-clear terminal one-shot**：LQ entry 因 exact release/recovery 清除后，
    同一旧 physical owner 不得再次产生 terminal。collector pending 在 tracker free 前
    保持 token→PID 映射；free 同沿不能复用 token。token 未来环回复用时，旧 source 必须
    已无任何发射资格；否则同 `{kind,token,epoch}` 会错误绑定新 PID。该 source 违约必须
    fail-loud，不能用 raw-event 去重或吞事件掩盖。

上述可编码项由 `` `ifdef OOO_ASSERT `` 下的 `[V8V-LQ-*]` 与
`[V8V-LQ-INTEGRATION-*]` 立即断言承载。断言不是状态机真源，production 组合门控仍然 fail closed。

## 5. 关键路径与 PPA 考量

- dispatch 路径新增 16-entry free scan 与两个 credit，但不借用同拍 free，避免 ROB retirement 回环。
- issue、query、response、release 各是 16-entry full-PID CAM/OR。query 还比较 64-bit PA、class 与 mask，
  是本实现最需综合/STA 复核的新增组合锥。
- `producer_live_mask` 是 Q-only 全展开位图，进入 global ProducerId birth fence；它不读取 request/response ready。
- 两个 bank-local MIQ 保持原 2-entry transport 结构，未重写 scheduler 或跨 bank response arbiter。
- 当前只有 RTL 与动态功能证据；没有同 design-id 的正式综合、STA、物理功耗，故 PPA 状态保持
  `UNQUALIFIED`，不得从功能门绿推导 200 MHz 或功耗结论。

## 6. 验证计划与证据

### 6.1 focused dynamic

- `tb_ooo_load_queue`：双 alloc、完整 PID generation mismatch、allow/replay/fault、PA 稳定、normal
  terminal 驻留、prior-terminal→recovery、completion-to-release、registered-completion-only
  pregrant view、容量、wrap recovery、killed tombstone drain。
- `tb_ooo_load_queue_producer_semantic`：刺激侧独立 4-entry edge model，在
  `GEN_W=1/4 × OOO_ASSERT on/off` 下逐沿扫描 raw Q；assertion-off compile-success
  mutation 覆盖 full-PID CAM、knownness、terminal history、recovery 和同拍优先级。
- `tb_ooo_store_queue`：physical byte query 的 allow/forward/merge/youngest/partial/poison/terminal/dual，
  store request/B/retirement 三事件与 flush exactly-once。
- `tb_ooo_int_backend`：真实 parent wiring、SQ forward/local WB、late-B precise trap、store ordering、
  killed LOAD response 零副作用与双 memory owner；`V8S_DUAL_MEMORY_FOCUSED` 额外覆盖 checkpoint 后
  unlaunched load/store 与 ROB/IQ 同拍清除、两条 launched tombstone 的精确 drain、无 reset redispatch/retire、
  LQ-ready 对 ROB commit 的主动反压、final-PA retry 生命周期，以及 delayed-OKAY B、raw-restore 与
  error-B 同拍、AMO write 三种不可撤回 physical write drain；三者分别验证 request/response/commit、
  SQ release、restore apply 和无 reset redispatch/retire 的精确次数。
- `tb_ooo_dual_memory_sustained_issue`：64 周期、每周期两个 AGU/translation/SQ query/cache
  admission/completion，确认 16-entry生产 LQ 未破坏 DI-5 throughput。
- `tb_ooo_core_top_glue`：在 backend accepted apply 被 physical-write owner 阻塞时注入 raw checkpoint
  restore，要求 `core_local_flush_w` 与两个 memory request gate 的 flush 同拍保持为 0。
- V11I parent focused：首次 LOAD terminal 后完成 LQ release 与 tracker exact-free，
  连续建立/结束 owner 直到 32-token cursor 环回，再让同 token 的新 LOAD reservation
  稳定驻留；assert/release 均要求旧 source 全程无 ingress/accept、new PID 的 tracker/LQ
  状态不变。compile-success stale-source variant 在 assertion 配置命中
  `[V9Y-HOLDER-TERMINAL-NEXT]`，在 release 配置由 stimulus-owned
  `[V11I-LATE-TUPLE-ABA][FAIL]` 拒绝。

### 6.2 compile-success mutation

`run-lq-mutations.py` 必须使以下 mutation 均编译成功并被精确 dynamic oracle 拒绝：index-only
identity、killed issue bypass、metadata bypass、ordered response bypass、normal terminal early release、
launched recovery drop、completion 前 release、双 allocation 同槽、同 PID 双 query 门控旁路。

V11H 的 producer semantic runner 将该集合扩展为 31 项，并在
`PRODUCER_GEN_W=1/4`、`OOO_ASSERT` 关闭的 62 次仿真中由 stimulus-owned raw-Q oracle
全部拒绝；新增覆盖 `terminal_seen_q` knownness/记录、terminal 后 issue/query/response
关闭、prior-terminal recovery、same-edge launch/completion/terminal priority 与
same-edge release credit 不可借用。

此外，production holder 自身必须在 `OOO_ASSERT` 下检查每个
`valid_q[i]` 对应的完整 `producer_id_q[i]` knownness。GEN_W=4 定向
unknown-generation probe 必须在 `[V11H-LQ-PID-KNOWN]` 处失败；四个合法
profile 及 ordinary LQ/parent 回归不得出现该 marker。

parent 集成回归另以 compile-success mutation 分别切断 accepted restore apply 到 LQ、
Dispatch/ROB/IQ 与 SQ 的 recovery，切断 `LQ retire permit → ROB commit`，并旁路 physical-write
lease apply guard 或 pending-restore lane1 retirement block；它们必须分别被 checkpoint
owner-recovery、irrevocable-write drain 与 retire-authority 场景检出。另一个 compile-success parent
mutation 将 raw restore 错接到 `core_local_flush_o`，必须被 core-glue 双 memory-gate 集成 oracle 检出。
F2 parent mutation 总数为 18。

### 6.3 架构门

OOO-3 只在同一 design-id 下同时满足完整 source topology、LQ/SQ/backend/dual-backend focused logs、
core-glue raw/apply 隔离场景、9 项 LQ mutation、18 项 F2 parent mutation、45 项 canonical source、
60 项固定 provenance inventory 与 architecture
`memory_ordering` 的 11 个硬指标时才可
为 GREEN。该结论不提升 DI-1、DI-2、OOO-4、overall 或 PPA。

V11H production RTL 改变后，旧 architecture directed-suite 不再具有当前 design-id；
当前 hard-gate 观察必须保持 RED。focused attempt-4 的原始
`FAIL@semantic-ledger-unit` 不得反写；独立 checker replay 仅在 4 个正向配置、1 个
raw-Q assertion probe、31×2 负向仿真、focused/full RTL pre/post 输入均冻结时生成新
PASS receipt，并明确不重跑 RTL。`scope.system_rerun` 必须精确区分
`required_for_local_closure=false`、`required_before_system_promotion=true`
和 `run=false`，字段缺失或弱化均须被负向单测拒绝。
新的完整系统运行是后续 system-level promotion 的前置条件。

## 7. 风险与回退

- 风险：64-bit metadata compare 进入 final-PA query 路径；正式 STA 若失败，应先考虑把 metadata
  stability check 寄存化或分层比较，不能删除 full-PID/PA 资格。
- 风险：大量 launched killed tombstone 会暂时耗尽 LQ；这是 lossless drain 所需的真实背压，不能以
  overwrite 或提前 free 回避。
- 风险：新增 recovery 源时必须明确它是否能取消已发 memory transaction；未证明可取消时，一律按
  launched tombstone 保持。
- 回退点：可整体移除 LQ parent wiring 并恢复先前 OOO-3 RED，但不得保留“只发布证据、不承载
  production gate”的半接入状态。

## 8. 变更记录

- 2026-07-21：v8v 新增 16-entry shared retire-resident LQ，接入完整 ordinary load 生命周期；补齐
  request/hold/apply checkpoint 协议、physical store/AMO exact-ProducerId drain、backend-wide owner recovery、
  launched load tombstone、Q-only retire lookup/active commit permit 和同 PID 双 query fail-closed。11 项
  memory-ordering 指标、9 项 LQ mutation 与 18 项 F2 parent mutation 必须在同 design-id 下通过；
  overall=RED、PPA=UNQUALIFIED。
- 2026-07-30：V11H 证明 normal terminal 先于 formal completion 后若再遇 recovery，旧 RTL 会
  生成永远等不到第二个 terminal 的 killed tombstone。新增 `terminal_seen_q` 作为
  physical-owner lifetime history；normal terminal 后保持 retire residency并关闭 physical
  operation，再由 completion→release 或 recovery→clear 结束。修复前 assertion-off raw-Q
  reproducer、四配置正向矩阵和 assertion-off compile-success mutation 均纳入 source-bound
  evidence。raw-Q full-PID knownness assertion 与定向 probe 随后闭合；
  原 attempt-4 FAIL 与独立 checker-replay PASS 分别保存；普通
  `tb_ooo_load_queue` 和父级 `tb_ooo_int_backend` 在断言开启下通过。版本化
  独立终审给出 `load-queue-producers` bounded APPROVE，不外推全局
  architecture、系统或 PPA。
