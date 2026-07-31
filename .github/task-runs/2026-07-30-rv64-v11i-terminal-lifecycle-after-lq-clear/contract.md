# V11I：LoadQueue 清除后的 memory terminal 生命周期合同

> 状态：**FROZEN / APPROVED_FOR_CURRENT_SCOPE / blocker=0**
> 范围：本地 RV64 `OooMemOwnerTerminalCollector` →
> `OooMemOwnerTracker` → `OooLoadQueue` 与 `OooIntBackend` production
> terminal source。  
> 当前基线 design-id：
> `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`。

## 1. 问题分类与裁决边界

V11H 已证明 normal LOAD terminal 先于 formal completion 时，LQ 必须保存
`terminal_seen_q`，并在后续 recovery 直接清除 entry。V11H 的局部结论没有覆盖：

```text
old LQ entry clear
  -> collector dequeue
  -> tracker exact-free
  -> 32-token allocator cursor 环回
  -> same token 绑定 new ProducerId
```

本轮冻结三项假设：

- **H1 / verification gap**：当前 production source 在 accepted terminal 同沿结束
  holder，之后不存在可重放旧 tuple 的状态；缺少上述完整 token-wrap 端到端证据。
- **H2 / production counterexample**：旧 `{kind,token,epoch}` 在 token 复用后仍可由
  production source 到达，collector 会把它解释为新 PID。
- **H3 / same-edge PID sampling error**：collector dequeue 与 tracker free 同沿，
  LQ 读取了 free 后或新 birth 的 PID。

独立只读预审裁决为 **H1**，排除 H3；H2 仅在 raw-ingress 合同被破坏的局部模型中
成立。H1 在 assertions-on/off、token-wrap 与 compile-success source variant
完成前保持 `GAP`，不得晋级 architecture 或 PPA。

## 2. 六类可判定接口合同

| 类别 | 周期级合同 | 失败观测 |
| --- | --- | --- |
| handshake | raw terminal 只表示 source event；只有 collector `ingress_accept_o` 才能进入 pending。`deq*_valid && deq*_ready` 同沿同时形成 tracker exact-free 与 LQ LOAD terminal。 | raw valid 未被接受却改变 pending/tracker/LQ；一个 accepted event 形成两个 dequeue/fire。 |
| backpressure | collector pending 与双 output stall 保持 exact `{kind,token,epoch}`；tracker lease 在 dequeue fire 前保持 live；allocation 只读 edge-old free token，不能借用同沿 death。 | stalled output tuple 漂移；death 同沿 token birth；同 token 双 free。 |
| flush/recovery | normal terminal 只结束 physical owner；LQ retire residency 由 completion/ROB release 结束。terminal-seen entry 被 recovery 命中时直接清除，不等待第二个 terminal。 | prior-terminal entry 进入 killed tombstone；recovery、flush 或 retirement 生成第二个 terminal。 |
| exception order | local/fault response 的 formal completion 与 owner terminal 是两个事件；terminal 不得绕过 ROB completion 资格，completion 也不得代替 tracker exact-free。 | terminal 造成未授权 WB；completion 提前释放 tracker token；第二个 terminal 被当成合法异常完成。 |
| memory ordering | terminal-seen 或 killed LQ entry 的 issue/query/response 均关闭；LQ 清除后旧 terminal 不得改变后续 load 的 ordering/response 资格。STORE 继续走 SQ-qualified release，不进入本合同的 LOAD terminal。 | 旧 terminal 关闭新 load、写新 LQ `terminal_seen_q` 或误 free 新 tracker owner。 |
| single source of truth | pending 前 `{kind,token,epoch}` 来自唯一 production holder；pending 后 collector Q 是 tuple 真源；dequeue fire 同沿 tracker edge-old token→PID 表是 LQ PID 真源。accepted transfer 后 production source 必须永久结束该旧 tuple 的发射资格。 | hidden/stale source 在 token 复用后重放旧 tuple；LQ PID 由 raw ROB index、端口号或 free 后 metadata 推导。 |

## 3. 冻结周期模型

设旧 LOAD owner 为 `A={PID_A,T,LOAD,00}`：

| 周期 | production 状态与事件 | 可判定结果 |
| --- | --- | --- |
| C0 | 唯一 holder 产生 raw terminal，collector 接受 `T`；holder 同沿清除。 | `pending_d[T]=1`；tracker 仍为 `T→PID_A`。 |
| C1 | collector registered output 装载 `T`；LQ 可因已登记 completion/ROB release 清除 A entry。 | output stall 时 tuple 保持；tracker 仍 live。 |
| C2 | `deq_valid && deq_ready`。 | LQ 组合读取 edge-old `producer_id_table[T]=PID_A`；tracker exact-free；同沿 allocation 看不到 T。 |
| C3…CR-1 | allocator 使用其它 edge-old free token；所有旧 A production source 静默。 | no ingress/no accept/no LQ terminal for A。 |
| CR | cursor 环回，T 绑定新 LOAD `PID_B`，B 的 reservation/LQ holder 驻留。 | current tuple 属于 B；旧 A source 仍必须静默。 |
| CR+1… | B 依照自身 request/terminal/completion/release 生命周期结束。 | A 不得改变 B 的 tracker/LQ/ROB 状态。 |

双 dequeue lane 对称地读取 edge-old tracker table；`free1_same_as_free0_w`
禁止同 token 双 free。H3 因此在当前 RTL 结构下不成立。

## 4. 最小判别实验

### 4.1 production 正向

在真实 `OooIntBackend` 中让 32 个 LOAD owner 依次完成
`request → MIQ → response terminal lane0 → formal WB → ROB/LQ release`，
使 tracker cursor 完成一圈。保留首个 `token=T/PID_A`；当 T 再绑定
`PID_B` 时：

1. B reservation 至少稳定保持两个完整周期；
2. `mem_terminal_ingress_valid_w == 0`、
   `mem_terminal_ingress_accept_w == 0`；
3. tracker 保持 `T→PID_B`，LQ 对 B 保持 live 且 `terminal_seen_q=0`；
4. 随后只由 B 自身的合法 terminal/complete/release 排空；
5. assertions-on 与 assertions-off 使用同一刺激并分别 PASS。

### 4.2 compile-success source variant

只在冻结副本中保存首次 token-T 的 lane0 response
`{kind,token,epoch,old_pid}`。当 token T 已环回复用、new PID reservation live
且 collector pending 尚空时，在 lane0 额外重放一次旧 response tuple。
variant 必须编译和展开成功：

- assertions-on：accepted pulse 后新 B holder 仍驻留，必须由
  `[V9Y-HOLDER-TERMINAL-NEXT]` fail-loud；
- assertions-off：stimulus-owned oracle 必须以
  `[V11I-LATE-TUPLE-ABA][FAIL] old_pid=... new_pid=... token=...`
  拒绝，不依赖 V11H 已清 entry 的 duplicate marker。

该 variant 是合同敏感性证据，不是允许的生产输入。禁止把它修成 raw-event 去重、
静默吞事件、延迟 PASS 或断言关闭。

## 5. 成本、停止条件与升级规则

- 预算：focused 编译与四次仿真，预期低于 15 分钟；Windows→WSL single-flight。
- 若 production 正向出现旧 tuple、new B tracker/LQ 被提前终止或 holder assertion，
  立即停止 H1，升级为 H2 root-cause；先保存 pre-fix RED，再讨论 RTL。
- 若 source variant 未编译、未激活、只超时或命中无关 marker，不算 mutation kill。
- production/elaborated RTL 未改变时，不触发 A4；若本轮后来修改 production core
  语义，则新的完整系统运行仍只作为 system promotion 前置，不自动启动。
- A3 原始 strict `16/17 rc=1` 永久保留；checker replay 与本合同相互独立。

## 6. 成功条件与 claim 边界

V11I 只有在以下条件同时满足时才能把本子范围登记为 PASS：

1. assertions-on/off production token-wrap 2/2；
2. assertions-on/off compile-success source variant 2/2 精确拒绝；
3. ordinary collector/tracker/LQ/parent 回归无新增失败；
4. source/RTL pre/post、simulator/config 与日志 marker 均冻结；
5. 独立 reviewer 对 H1、oracle 独立性、variant 激活和 claim 边界给出
   bounded APPROVE。

该 PASS 只证明当前 production source 的 LOAD terminal one-shot 与
collector→tracker→LQ token-wrap 生命周期；不证明任意非法 raw ingress 安全、
全局 no-live-reuse、whole architecture、system、synthesis/STA/power 或 PPA。
