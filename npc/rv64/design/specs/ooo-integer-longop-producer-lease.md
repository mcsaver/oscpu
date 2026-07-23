# 规范：整数 MulDiv / CLMUL ProducerId lease 与完成授权

> 影响模块：`OooMulDivUnit`、`OooClmulUnit`、`OooIntBackend`、
> `OooDispatchBackend`、`OooRob`。
>
> 状态：v8h 合同冻结；只覆盖两个整数长延迟 singleton holder。
> FP、branch resolve、pending-system/CSR、全核 holder census 与 global no-live-reuse
> 不在本地 GREEN 声明内。

## 1. 目的与范围

现有 MulDiv/CLMUL 在多周期状态中只保存 raw ROB index，响应进入 shared WB 时也只凭 raw
index。ROB slot 的 generation 回绕后，如果仍有旧 holder，旧响应可能与新 incarnation 同名；
仅靠局部 branch kill 不能构成 last-reference/no-live-reuse 证明。

本切片建立以下闭环：

1. IQ issue 的 `ProducerId={generation,rob_idx}` 被两个 unit 作为唯一身份寄存；raw index 只从
   ProducerId 低位投影，用于环形年龄和既有 WB ABI。
2. unit 从 request capture 到 response transport terminal 全程导出 Q-only lease；dispatch 对
   memory、MulDiv、CLMUL 三类 lease 的并集做 indexed collision lookup。
3. long-op response 的运输准入与架构副作用分权：raw response 获得物理 WB slot 后即可被 unit
   消费；只有 ROB `valid && exact generation && !done && !killed-now` 且未被同拍更高优先完成源
   claim 时，才产生 WB/PRF/Busy/IQ/public completion。
4. lease 在 kill/flush/response-consume 的时钟沿仍按 edge-old Q 生效；同沿不得重用，下一拍
   holder 真正 IDLE 后才释放。

不在范围内：不改变乘除/CLMUL 数值算法、延迟和吞吐；不改变 shared-WB source priority；不把
FP/branch 纳入本次 mask；不声称 generation 位宽本身足够、全核 identity GREEN、arch-stable、
200 MHz 或 PPA promotion。

## 2. 接口契约

### 2.1 端口与时序

| 边界 | 信号 | 方向/位宽 | 时序与决定状态 | 语义 |
| --- | --- | --- | --- | --- |
| IQ→unit | `req_valid_i` / `req_ready_o` | 1 / 1 | ready 只由 unit `state_q==IDLE` 和 reset/flush/kill guard 决定 | valid 不读 ready；fire 后完整 payload capture |
| IQ→unit | `req_producer_id_i` | `PRODUCER_ID_W` | request fire 沿写 unit 唯一 `producer_id_q` | generation+ROB index，不得另存 raw identity owner |
| unit→WB | `resp_valid_o` / `resp_ready_i` | 1 / 1 | valid 在 RESP 保持；ready 只由 raw shared-WB transport arbitration 决定 | mismatch 也必须可 consume-and-drop |
| unit→WB | `resp_producer_id_o` | `PRODUCER_ID_W` | 组合投影 `producer_id_q`，valid 期间稳定 | ROB exact-open query 的完整身份 |
| unit→dispatch | `owner_valid_o` / `owner_producer_id_o` | 1 / `PRODUCER_ID_W` | 只读 Q：`state_q!=IDLE` 与 `producer_id_q` | 不得读取 kill、ready、query 或 next-state |
| backend→ROB | completion query 3/4 | valid+PID / match | query 只读 ROB Q 与 recovery facts | match 不得进入 response ready 或 unit state advance |
| backend→dispatch | `producer_live_mask_i` | `2^PRODUCER_ID_W` | memory registered mask 与两个 Q-only onehot lease 的 OR | 每 lane 只做 candidate PID indexed lookup，无 holder CAM |

request payload 在 fire 前由 IQ 保持；unit 不接受同拍 reset、flush 或 branch-kill 下的新 request。
response payload在 `resp_valid && !resp_ready` 期间保持。`resp_ready` 表示 transport terminal，
不是完成授权；因此 stale/done/killed response 也必须最终释放 unit，而不能因 exact-open=0 永久阻塞。

### 2.2 典型时序

```text
cycle       N              N+1 ... K              K+1
request     valid&ready
PID Q       old       <- capture full PID ->      clear only after terminal edge
owner_live  0               1 ... 1                0
response                              valid&ready
ROB open                               exact?----+
WB sidefx                              grant && exact
transport                              grant (exact or stale)
```

### 2.3 stall / backpressure

- 非 IDLE unit 对新 request 反压；本切片不增加队列或并发实例。
- shared-WB physical priority保持 `EX > MEM > MulDiv > CLMUL > FP`。高优先 stale long-op 可占一个
  transport slot 并在该拍静默释放；低优先 source 只能使用剩余 slot 或等待。
- exact-open query 不进入 `muldiv_resp_ready_w`、`clmul_resp_ready_w`、route predicate、dispatch
  mask 生成或 unit FSM next-state；否则形成 authority→transport 或 ROB→ready 回边。
- dispatch collision 只在 candidate PID 命中 edge-old lease 时阻塞；不扫描 holder，不把算法
  busy、response data 或 query match 拉入 ready cone。

### 2.3a 同拍完成 claim 全序

ROB exact-open query 只观察 edge-old Q；它本身不能排除多个 source 在同一拍以同一 PID 同时看见
open。因此 actual side effect 使用固定的逐源 claim 链：

```text
EX0 > EX1 > memory > MulDiv > CLMUL
```

- 每一级只排除“更高优先 actual source 与自己 PID 相同”的情况；不同 PID 可并行完成。
- memory 的既有 done-now fence 纳入同一条链；MulDiv 再观察 EX0/EX1/memory actual claim，CLMUL
  再观察 EX0/EX1/memory/MulDiv actual claim。
- claim fence 只门控 actual WB/PRF/Busy/IQ/ROB/public side effect；禁止反馈到 raw route、response
  ready、unit FSM、owner mask 或 dispatch candidate mask。
- 同 PID MulDiv/CLMUL 同拍 response 时，MulDiv 可取得 actual claim；CLMUL raw response仍按 shared
  transport规则等待或静默核销。下一拍若 ROB 已 done，CLMUL 必须作为 stale 消费且零 side effect。

FP 尚无 full ProducerId，不在本次 per-PID claim 证明域；该事实必须继续作为全局 RED 风险列出。

### 2.4 flush / redirect「谁清谁保持」与优先级

| 事件 | unit state / PID | response | dispatch lease | ROB/其它 holder |
| --- | --- | --- | --- | --- |
| reset | 沿上清 IDLE/零 PID | 当拍 valid=0 | ready/dispatch 同拍冻结 | 按各自 reset |
| global flush | 沿上清 IDLE/零 PID | 当拍 valid=0 | dispatch 同拍冻结；edge-old 不授权新 alloc | memory 等按既有合同 |
| branch selective kill 命中 | 当拍 mask response，沿上清 IDLE/零 PID | 不产生 side effect | kill 沿前仍由旧 Q lease 阻止同 PID birth | 存活 older/equal 保持 |
| branch kill 未命中 | 全保持 | 正常握手 | lease 保持 | 正常恢复 |
| response transport fire | 沿上从 RESP→IDLE并清 PID | exact 才 WB；stale 静默 | fire 当拍仍保持 old lease，下一拍释放 | ROB 仅 exact side effect |

同拍全序固定为：`reset/global flush > matching selective kill > normal FSM`。normal FSM 内只有
当前状态合法的 request/response fire 可更新。unit `req_ready_o` 在 reset/flush/任意 kill-valid
拍为 0；不把“上游通常不会发”当成接口契约。

### 2.5 异常序与访存序

MulDiv/CLMUL 本身不产生精确异常或 memory side effect。ROB done 仍只由 formal WB 在时钟沿
落账，退休继续读下一拍 ROB Q；本切片不改变 commit 顺序、SQ/MIQ/AXI 或 store authorization。

### 2.6 投机恢复与单一真源

- `producer_id_q` 是每个 unit 的唯一 owner identity；`resp_rob_idx_o`、kill age 和 debug raw index
  全部从其低位投影。禁止并行保存可漂移的 `req_rob_idx_q/resp_rob_idx_q` owner 副本。
- ROB exact-open 定义为 `query_valid && !rst && !flush && valid_q[idx] && !done_q[idx] &&
  slot_generation_q[idx]==query.generation && !producer_target_killed_now(idx)`。
- owner lease 由 unit Q 直接产生；不能以 response valid 代替，因为 request buffer/run 期同样是
  live last-reference。
- 本地 lease 只阻止 MulDiv/CLMUL live PID collision；FP、branch、pending owner 未并入时，
  `global_no_live_reuse` 必须继续 RED。

## 3. 状态与时序模型

### 3.1 MulDiv

```text
IDLE --request fire--> REQ_BUF --mul--> MUL_RUN --last--> RESP --transport--> IDLE
                              \--div--> DIV_RUN --last--/
                              \--special/zero----------/
```

### 3.2 CLMUL

```text
IDLE --request fire--> RUN --iter63--> RESP --transport--> IDLE
```

### 3.3 状态寄存器

| 寄存器 | 位宽 | reset | 更新 |
| --- | ---: | --- | --- |
| each `state_q` | 3 / 2 | IDLE | reset/flush、matching kill、normal FSM |
| each `producer_id_q` | `PRODUCER_ID_W` | 0 | request fire capture；reset/flush/kill/response terminal 清零 |
| pdest/data/algorithm state | 既有 | 既有零值 | 保持既有算法条件；不拥有独立 ROB identity |

`owner_valid_o=(state_q!=IDLE)` 是 Moore Q 投影。response exact-open 是 parent 组合观察，不写回
unit state。所有新 onehot mask 都是寄存 owner facts 的组合 decode，不新增状态。

## 4. 不变量

1. **LONGOP-ID-SINGLE-SOURCE**：任一 non-IDLE 周期，request capture 的 full PID 逐位保持到
   terminal；raw response index 必须等于 PID 低位。违反会把旧 incarnation 误投影到新 slot。
2. **LONGOP-LEASE-FULL-LIFETIME**：REQ_BUF/RUN/RESP 全部 `owner_valid=1`；只有 IDLE 为 0。
   违反会允许 generation wrap 在运行或背压期同名 birth。
3. **LONGOP-DEATH-BEFORE-BIRTH**：kill/response terminal 同沿仍用 edge-old lease 阻塞同 PID
   dispatch，下一拍才释放；禁止 ready/kill 组合提前清 mask。
4. **LONGOP-TRANSPORT-AUTH-SEPARATION**：raw route/ready 不读 exact-open；actual WB、GPR write、
   wake、ROB done、public completion 必须逐源包含 exact-open。
5. **LONGOP-OPEN-EXACT**：vacant、done、wrong generation、strictly-younger killed target 均返回
   false；合法 current unfinished survivor 返回 true。
6. **LONGOP-MASK-UNION**：dispatch mask 是 memory、MulDiv、CLMUL lease 的并集；mandatory pair
   任一 candidate collision 时不得部分 fire，optional lane1 collision 只阻 lane1。
7. **LONGOP-REQUEST-GUARD**：reset/flush/kill-valid 拍 `req_ready=0`，不会宣告一个被高优先级分支
   静默丢弃的新 capture。
8. **LONGOP-SAME-EDGE-CLAIM**：对任意完整 PID，每拍 EX0/EX1/memory/MulDiv/CLMUL 的 actual
   completion popcount 至多为 1；比较必须使用 full PID，且只处于 side-effect cone。
9. **DISPATCH-PAIR-PID-DISTINCT**：ROB mandatory/optional pair 的两个 Q-only candidate PID 必须
   永不相等。当前 ROB 深度至少为 2，两个 candidate 的低 `ROB_INDEX_W` 位分别为 `tail` 与
   `tail+1`，故不依赖 live mask 即可证明不同；该结构不变量必须有断言、定向测试与 mutation。

上述可编码项使用 `OOO_ASSERT` 立即断言；每个承重断言必须有 compile-success mutation 或定向
负例证明非真空。文本搜索只作补充，不能单独签收。

## 5. 关键路径与时序考量

- 算法 datapath、迭代拍数与 response priority 不变。
- 新路径是 unit Q PID/state → onehot decode → existing 256-bit lease OR → dispatch indexed lookup；
  输入全为寄存事实，无 response-ready/ROB-query 回边。
- ROB completion query 增加两个只读 array-select/equality cone，只进入 long-op actual WB valid；
  不进入 transport route/ready。此切片未授权 synthesis/STA promotion，若运行只能标 diagnostic。

## 6. 验证计划

- `tb_ooo_muldiv_unit` / `tb_ooo_clmul_unit`：full PID capture/hold/projection、RUN/RESP lease、背压、
  reset/flush/kill request guard、terminal 后释放。
- `tb_ooo_int_backend`：两类正常 exact completion；wrong-generation 与 done-closed response 均
  transport-drain 且零 WB/PRF/Busy/IQ/ROB/public side effect；MulDiv/CLMUL RUN/RESP lease 分别阻塞
  lane0、mandatory pair 与 optional lane1 candidate；覆盖 EX0/EX1/memory/MulDiv/CLMUL 同 PID
  同拍 claim、MulDiv+CLMUL 同/异 PID、stale 高优先 source 与 exact 低优先 source 的有限进展。
- `tb_ooo_rob`：新增 query 3/4 的 valid/done/generation/kill/recovery矩阵。
- `tb_ooo_dispatch_backend`：mandatory/optional candidate PID 结构不相等，不依赖 fire；删除或削弱
  pair comparator/assertion 的 mutation 必须失败。
- compile-success mutation：PID 截断、lease 缩成 RESP-only、mask 漏项、query generation/done/kill
  缺项、actual-valid 绕过 open、same-edge claim 漏源、ready 读取 open、death-edge 提前释放等。
- broader gates：focused release + `OOO_ASSERT`、module aggregate、RTL style、contract、strict lint
  与全局 architecture inventory（预期仍 RED）。

## 7. 风险与回退

- 256-bit onehot 是当前 v8g 已有 mask 形态的扩展，未来可在全 holder census 后收敛成集中式
  scoreboard；本切片不得提前替换为 CAM 或 raw-index-only mask。
- 如果新增 query 进入 ready cone或 strict lint出现新 SCC，立即回退该结构并保持 scope RED，
  不用 false path、lint waiver 或削弱断言解决。
- 回退边界是五个受影响 RTL 文件与三份 canonical TB；memory lease v8g 行为必须保持。

## 8. 变更记录

- 2026-07-19：冻结 v8h MulDiv/CLMUL ProducerId lease、transport/authority 分权和 edge-old
  collision 合同；实现与证据待本 task-run 生成。
- 2026-07-19：合同评审修订 v8h.1；加入 `EX0 > EX1 > memory > MulDiv > CLMUL` 的 full-PID
  same-edge actual-claim 链，并把 dual-dispatch PID 不碰撞固化为 ROB 结构不变量。
