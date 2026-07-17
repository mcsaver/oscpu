# S2-G1 lossless terminal collector leaf RTL 推导

> 状态：`leaf pre-RTL companion derivation`。
>
> 本文是
> `s2-g1-exact-owner-provenance-{completion-definition,rtl-derivation,errata}.md`
> 的伴随实施记录，不修改 hash-bound typed ABI、架构/PPA 合同或
> R4-P0A/R3.6 基线。本 leaf 只收集 terminal accounting event，不授权
> WB、SQ fill/release、cache maintenance、architectural fault 或其它副作用。

## 0. 接口/控制契约冻结

### 0.1 接口契约

| 方向 | 字段 | 契约 |
| --- | --- | --- |
| ingress | `ingress_valid_i[INGRESS_N-1:0]` + flattened `{kind[1:0],token[4:0],epoch[1:0]}` | terminal 源是单拍 event，不依赖 collector ready；`INGRESS_N>=6` |
| tracker snapshot | `live_mask_i[31:0]` + token-indexed kind/epoch tables | 必须是本沿更新前的 edge-old owner truth |
| dequeue 0/1 | registered `valid + {kind,token,epoch}` / `ready` | `valid && !ready` 期间 valid 与 tuple 逐位保持；两路可独立 fire |
| observability | `pending_mask_o[31:0]`, `pending_count_o[5:0]` | 覆盖 backlog 和两个 output-resident token 的全部未消费 event |

owner identity 严格为 `{kind,token,epoch}` 共9 bit。`fault_tval` 是 provenance
payload，不进 collector 端口、不进 identity compare，也不能被本模块重建。

### 0.2 stall / ready 语义

- ingress 无 ready：32-entry token bitmap 与 tracker 最多 32 个 live token 同容量；
  合法且尚未 pending 的 terminal event 必有唯一 token slot。
- dequeue ready 只影响对应 registered output slot 是否消费，不进 ingress
  exact-match 判定，也不授权任何外部副作用。
- 新 ingress 先进 pending bitmap，下一拍才能被装入 registered output；
  因此没有 ingress-to-tracker-free 的组合通路。

### 0.3 reset / dequeue / enqueue 同拍优先级

`reset > edge-old dequeue accounting > exact unique ingress capture > output refill`。

- dequeue fire 只删除对应 edge-old pending bit。
- ingress 总是用 edge-old `pending_q` 验证；即使同 token 本拍正在
  dequeue fire，也必须拒绝再入，关闭最短 ABA 窗口。
- output refill 只从 edge-old pending 且未被停滞 slot 保留的 token 中选择；
  本拍 ingress 不能组合穿透到 output。

### 0.4 fail-closed 规则

对每个 ingress lane，下列任一成立则该 lane 不入队：

1. `kind==RESERVED`；
2. token 在 edge-old tracker 中 nonlive；
3. live kind 或 epoch 不等；
4. 与同拍另一 ingress 同 token（重复双方都拒绝）；
5. token 已在 edge-old pending bitmap 中；
6. token 正在本沿 dequeue fire。

违规 lane 不能影响同拍其它不同 token 的 exact ingress。`OOO_ASSERT`
下每类违规必须 fatal；non-assert build 保留 live owner 等显式恢复，
不伪造 free。

## 1. 需求

1. 一拍捕获至少6个不同token、与tacker edge-old metadata 精确匹配的
   tagged terminal event，不丢失。
2. 令32-token bitmap + per-token kind/epoch 保存全部待消费 event。
3. 两路 registered dequeue 支持独立反压，保持 tuple，连续每拍最多消费2个。
4. 对 duplicate/nonlive/mismatch/same-edge reuse fail closed，并提供非真空
   assertion negative。
5. 本 leaf 不连 backend/top/bridge/tracker，不变更任何既有路由或
   architecture gate，不声称 timing/PPA 合格。

## 2. 协议、状态机与不变量

### 2.1 协议规则

- ingress 是已发生的 terminal accounting pulse；正常路径不允许 retry 或
  依赖 collector 的 accept 结果。所以容量必须在结构上覆盖全部live token。
- `deqN_fire = deqN_valid_o && deqN_ready_i`；只有 fire 删除 pending bit。
- 两个 output slot 不得指向同 token；新装载时第二路排除第一路grant。
- token selection 只决定清算顺序，不表示 architectural age/order，
  不能作为副作用权限。

### 2.2 状态机

无全局枚举 FSM，每个 token 是 `EMPTY/PENDING`，每个 output slot 是
`EMPTY/HELD`：

```text
token EMPTY -- exact unique ingress --> PENDING
token PENDING -- selected into output --> PENDING (output-resident)
token PENDING -- output fire --> EMPTY

slot EMPTY -- old pending candidate --> HELD
slot HELD -- !ready --> HELD (tuple stable)
slot HELD -- ready + candidate --> HELD (same-edge refill)
slot HELD -- ready + no candidate --> EMPTY
```

### 2.3 不变量

| ID | 表达式 / 后果 |
| --- | --- |
| TC-I01 | `pending_count == popcount(pending_mask)`；否则守恒破坏 |
| TC-I02 | `next_count = old_count + accepted_ingress - dequeue_fire`；否则终止事件丢失/重复 |
| TC-I03 | output valid -> 该 token pending 且 output tuple == per-token table；否则错 free |
| TC-I04 | output0/1 valid -> token0 != token1；否则双 free |
| TC-I05 | output valid && !ready -> 下拍 valid+tuple 稳定；否则 ready/valid 违约 |
| TC-I06 | accepted ingress -> edge-old live 且 kind/epoch exact；否则 stale 事件释放新 owner |
| TC-I07 | accepted ingress 在本拍/旧 pending 中token唯一；否则重复terminal被去重掩盖 |
| TC-I08 | dequeue token 本拍不能再入；否则最短 ABA |
| TC-I09 | collector 输出只是 tagged accounting event，不能直连副作用授权 |

## 3. 数据通路与 RTL 级拓扑

```text
6+ ingress tuple -- exact/duplicate matrix --+--> pending_q[31:0]
edge-old live/kind/epoch tables --------------+    kind_q[32]
                                                   epoch_q[32]
                                                        |
                     +----------------------------------+
                     v
      old-pending minus held/fire mask -> two-level first-set select
                     |                         |
                     v                         v
              output0 registers         output1 registers
             valid/kind/token/epoch     valid/kind/token/epoch
                     | ready0                  | ready1
                     +----------- fire mask ---+
```

### 3.1 状态寄存器

- `pending_q[31:0]`，reset=0；含 backlog 与 output-resident event。
- `kind_q[0:31]` / `epoch_q[0:31]`，只在 exact unique ingress capture 沿写。
- `out{0,1}_{valid,kind,token,epoch}_q`，reset valid=0；只在 slot 空或fire时装载。
- assertion-only 守恒期望值和 output hold snapshot。

### 3.2 主要组合网络

1. `INGRESS_N x tracker table` exact compare；
2. `INGRESS_N x INGRESS_N` token duplicate matrix；
3. accepted-token one-hot OR 写 pending next-state；
4. 两级 32-bit first-set selector，第二路排除第一路token；
5. popcount 只做 observability/assertion，不进 dequeue ready。

所有 `for` 循环在 RTL 中标明展开硬件：入口比较矩阵、32路优先编码器、
32位 popcount 或 32 个并行寄存器写使能。

### 3.3 critical path / function 边界

- 潜在路径1：ingress token -> live/pending table mux + cross-ingress duplicate compare
  -> pending D；本 leaf 尚未做STA，不宣称200 MHz。
- 潜在路径2：32-bit pending -> first-set select -> registered output D；不组合到
  tracker free ready。
- function 仅用于小型纯组合 popcount；ingress arbitration、pending next-state、
  output refill 全部是显式 `always @(*)` / `always @(posedge clk)`。

## 4. 拓扑自审与验证门禁

- 容量证明：tracker 最多32个 live token；collector 以同token域的32bit保存
  每个livetoken最多一个尚未消费terminal。因此所有合法新event总有slot；
  满时任何仍然live的ingress必与pending重复，属于契约违规。
- 反例审查：不能只用组合priority output，否则stall期间新的低位token会
  改变payload；因此必须有两个output register slot。
- focused positive 必须覆盖：同拍6输入、连续6+6 burst、双输出反压/非对称ready、
  最终一次且仅一次收到所有token。
- non-assert fail-closed 覆盖：intra-batch duplicate、pending duplicate、nonlive、
  kind/epoch mismatch、same-edge dequeue/re-enqueue，且违规lane不吞掉无关合法lane。
- `OOO_ASSERT` negative 要求每类独立命中目标marker；叶模块Yosys check
  只证明可综合/结构合法。未进filelist、backend/top，未跑full regression、STA、
  area/power，所以 timing/PPA/architecture 全部 `UNQUALIFIED/RED`。

自审通过：端口、状态、复位优先级、资源仲裁、反压与 fail-closed 语义
自洽，可进入 leaf RTL 翻译。
