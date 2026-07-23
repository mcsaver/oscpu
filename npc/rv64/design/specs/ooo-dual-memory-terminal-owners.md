# 规范：DI-3 双内存 issue terminal owner（v8p）

> 状态：合同冻结，待 RTL 与定向证据验证。本文只定义 DI-3 的 issue-side
> 双 owner；DI-5、OOO-3、全架构与 PPA 在各自独立证据完成前保持 RED。

## 1. 目的、范围与非目标

现有整数 IQ 能动态交换 Universal/ALU terminal，但 memory 只能进入一个
`mem_issue_res`，`issue1` memory 数据面被常零。其结果是 load-load、load-store、
store-load、store-store 无法在同一拍从 IQ 交给两个物理 memory terminal owner。

v8p 增加第二个非穿透 memory reservation、第二个 exact owner-token allocation 和
第二个 captured-data AGU。覆盖范围是普通整数 load/store；AMO/LR/SC、FP load/store
仍只能走 Universal terminal。本切片保守地让两个 reservation 按程序序串行进入既有
单 request/translation/cache/MIQ 通路。

明确不在范围内：真实双 translation、双 TLB hit、双 final-PA、双物理 SQ query、双
cache admission、双 completion、LQ、alias replay、DI-5 的 1.90 IPC，以及 OOO-3/PPA
晋级。不得把两个 issue owner 描述成完整 S2 dual-memory 数据通路。

## 2. 接口契约

### 2.1 边界、字段与 owner

| 边界 | 字段/握手 | owner 与时序 | 可判定契约 |
| --- | --- | --- | --- |
| dispatch -> integer IQ | 两路既有完整 payload、full `ProducerId`、FP 属性 | dispatch `valid && ready` 唯一接受点 | 每个 resident entry 额外保存 `plain_memory_terminal_capable`；不得从 dispatch slot 或 entry index 推导 |
| IQ -> selector | `valid/base_ready/memory/alu_capable/plain_memory_capable` | packed index 小者更老 | 仅队首两个均为 ready 普通整数 load/store 时形成 memory pair；AMO/FP/control/long-op 不得进入第二 memory terminal |
| IQ -> backend | 两路既有 payload + 两路 `valid/ready` | 两路 memory pair 是一个原子 package | pair 只允许 `{fire0,fire1}=2'b11` 或 `2'b00`；任一路 owner credit 缺失时两路都留在 IQ，payload 保持 |
| backend -> owner tracker | `alloc0/1_valid, kind, epoch, full ProducerId, ready, token` | tracker 只读 edge-old live/PID bitmap；双 valid 表示一个原子 allocation package | 两个 current uop 同拍必须取得两个不同 live token；双 valid 时 `alloc_fire0==alloc_fire1==ready0&&ready1`，任一 token/PID 冲突都禁止两个 birth；stale uop只可同拍丢弃，不能创建 owner |
| reservation -> AGU | 每 bank 捕获 ctrl、full PID、源值、store data、imm、PC、FP/目的字段、kind/token/epoch/tval | 两个 bank 各自为非穿透 Q owner | capture 后下一拍才可出现 AGU/request/local terminal；stall 时 payload 逐位稳定；AGU 地址只等于本 bank captured `src1 + imm` |
| reservation -> SQ | 两路 exact owner bind | SQ dispatch entry 是架构 store owner，bind 只赋能力句柄 | 同拍 store-store 必须按 full PID/ROB tag 分别命中两个不同 SQ entry，分别保存 kind/token/epoch/tval；不得压成一个 mux owner |
| reservation -> shared memory path | bank0、bank1 的 request/local terminal | bank0 年龄优先；bank1 只有 edge-old bank0 无效时可消费 | 共享 request mux 一拍至多一个 reservation grant；bank1 不得越过 bank0产生 request、forward、异常完成或 SQ terminal |
| holder -> terminal collector/tracker | exact kind/token/epoch terminal 或 STORE-qualified SQ release | token 从首次 reservation capture 到唯一 terminal/release 保持 | flush/kill/response/local complete 都不得泄漏、重复或凭 raw ROB index free token |

### 2.2 握手协议

1. selector 的 `issue*_valid` 只由 resident Q、ready-state metadata 与 owner-presence
   产生，不组合读取 backend `ready`。
2. memory pair 的 backend ready 方程只读两个 reservation 空 credit、current-PID
   查询与 tracker edge-old allocation ready；不得读取 bridge/cache/request ready。
3. pair fire 后两个 IQ entry 同沿离队；两个 reservation 都在下一沿可见。任何 split
   fire、单 token capture 或 raw-IQ memory fall-through 都是致命违约。
4. reservation 下游 valid 可长期保持；request `valid` 不依赖同级 `ready`，fire 前
   payload、owner tuple 与 full PID 不变。
5. 对 current-current memory pair，下式必须逐拍完全等价：

   ```text
   issue_fire0 == issue_fire1 == capture0 == capture1 ==
   tracker_alloc_fire0 == tracker_alloc_fire1
   ```

   store uop 对应的 SQ bind 与该 capture 同沿提交。任一输入/credit/恢复/槽位前置条件
   不满足时，IQ、reservation、tracker、SQ 与覆盖计数均不得部分更新。
6. tracker 的 `alloc0_ready` 可以独立计算，`alloc1_ready` 可以排除 alloc0 claim；但当
   `alloc1_valid=1` 表示原子 pair 时，tracker 状态更新必须把两个 ready 合取为共同 commit。
   这不是用 ready 生成 valid，而是 tracker 内 edge-old package-commit 规则。

### 2.3 反压 / stall 单向 DAG

```text
tracker live Q / PID-live Q ----> alloc0_ready ----> pair_ready
                         \------> alloc1_ready ----/
reservation edge-old valid -----------------------/

bridge/cache/request ready ----> reservation consume only
bridge/cache/request ready -----X----> IQ pair_ready
```

- pair stall 唯一来源：任一 reservation 非空、global/recovery gate、任一 current owner
  token/PID 无 credit；普通 load/store 不增加 ROB-head admission。
- bank0/1 captured 后可被单 request/MIQ 通路任意反压，IQ 已经离队且不可回退。
- bank0 owner 可与 raw ALU terminal 并行；bank1 owner 占用第二物理 terminal 时 raw
  ALU terminal 必须停住，避免同一 terminal 双 owner。
- pair ready 的允许根闭集只有：两路 resident valid/base-ready、两路 plain-memory
  capability、两 reservation 的 edge-old empty、recovery/global gate、两路 full-PID
  current 查询、tracker dual allocation ready。bridge、translation、cache、request、MIQ、
  response、同拍 reservation consume/free 均不得进入该组合锥。
- 本切片禁止 full+consume refill：即使 bank0/bank1 本拍下送或被 kill，edge-old valid 仍使
  pair credit 为 0；最早下一拍才可接收新 pair。

### 2.4 flush / kill「谁清谁保持」

| 事件 | 清除 | 保持 | token 终止规则 |
| --- | --- | --- | --- |
| hard reset | 两 reservation Q、tracker、IQ | 无 | tracker reset 统一清零 |
| global flush / checkpoint restore | 未发 reservation、buffer、IQ | 已发 AXI、nokill physical STORE、terminal pending | 非 STORE reservation 送 lossless collector；STORE 仅在 SQ authority 同拍结束后 qualified release |
| branch mispredict | strictly-younger bank0/bank1 reservation | boundary/older owner、已发需 drain owner | full PID/ROB age 决定 kill；非 STORE tagged terminal，STORE 由 SQ selective squash exact release |
| local completion | 对应 reservation Q | 其它 bank 与下游 owner | LOAD tagged terminal；STORE 先形成 exact SQ terminal，后由精确 ROB commit release |
| request/buffer handoff | 对应 reservation Q | MIQ/buffer/SQ/tracker owner | 不是 token terminal；owner tuple 原样迁移 |

`OooMemOwnerTerminalCollector` 的 ingress 是不可反压的 token-mask capture，而不是
valid/ready sink；合同要求任一合法非 STORE cancel 在清 reservation 的同一沿被 collector
无损吸收。若 ingress token 重复、非 exact-live 或集合容量不守恒，立即 `$fatal`，不得先清
最后 holder 再静默丢事件。STORE cancel 仍不走 generic tagged free，只能以 SQ exact authority
结束产生 qualified release。

v8p 将 collector 参数从 6 个扩为 7 个并行 ingress；新增 bank1 reservation lane 与既有
response/drop0/drop1/bank0/buffer/AMO-interphase 六 lane 同拍逐 token 解码写入。collector 的
容量不是七项 FIFO，而是与 tracker 同构的 32-bit pending token set：每个 edge-old live token
最多占一个 bit。一个尚未 pending 的 live reservation cancel 总能写自己的空 bit；当 32 bit
全满时，所有 32 live token 都已 pending，因而不可能再存在另一个合法非pending reservation
owner。这一集合论不变量使 ingress 无需 credit，也不得进入 pair-ready。

双 bank cancel 以及最坏七路 ingress 必须满足：所有 valid tuple 逐一 exact-live、同 batch token
互异、`pending_next=(pending-old_deq) OR accepted_ingress`，计数变化等于 accepted popcount 减
双 dequeue fire。输出只有两个并行 dequeue port，但 pending bit/metadata 可无损等待任意周期。

### 2.5 同拍优先级

每个 reservation 的状态更新全序为：

```text
reset/global flush/restore > selective kill > downstream consume > IQ capture > hold
```

组合授权全序为：

```text
recovery mask > bank0 age owner > bank1 age owner > shared request grant
```

tracker 继续使用 edge-old birth/death 代数；同沿 free 的 token/PID 不能被 v8p pair 重用。

双 allocation 的 tracker 事件代数补充为：

```text
pair_alloc = alloc0_valid && alloc1_valid
pair_commit = pair_alloc && alloc0_ready && alloc1_ready
birth0 = pair_alloc ? pair_commit : (alloc0_valid && alloc0_ready)
birth1 = pair_commit
```

`alloc1_valid` 在生产连接中只表示与 alloc0 同包的第二 owner；不得单独提交 alloc1。

### 2.6 六类可判定跨模块契约

1. **握手**：memory pair 同拍双 fire；无 split；两 bank 均 non-fallthrough、stall stable。
2. **反压**：IQ pair ready 不读 bridge/cache/MIQ pop ready；alloc1 可依赖 alloc0 claim，
   alloc0 ready 不反向依赖 alloc1。
3. **flush/redirect**：按 §2.4/§2.5；已发请求只 drain，不回滚。
4. **异常序**：bank1 不越过 live bank0；local exception 携带 exact full PID，经 formal
   completion 后只在 ROB head 精确提交。
5. **访存序**：本切片保持保守程序序下送；store 仍走 probe->SQ->ROB-head physical
   request->aggregate B->ROB terminal/release，不能因双 capture 提前产生外部写。
6. **投机恢复/单一真源**：reservation Q 是 captured payload 真源，tracker table 是
   token->full PID 真源，SQ 是 store authority 真源；port/slot/raw index 均不是身份。

## 3. 状态与时序模型

### 3.1 状态寄存器

| 状态 | 位宽/复位 | 写入条件 | 保持条件 |
| --- | --- | --- | --- |
| `mem_issue_res_*_q` (bank0) | 既有完整 payload；valid=0 | exact issue0 capture | 无 reset/kill/consume/capture |
| `mem_issue1_res_*_q` (bank1) | 与 bank0 同构；valid=0 | exact issue1 pair capture | 无 reset/kill/consume/capture |
| IQ `plain_memory_terminal_capable_q[0:7]` | 1 bit/entry；0 | accepted dispatch/compaction | resident 未移动 |
| SQ `owner_*_q[entry]` | 既有 tuple；owner_valid=0 | bind0 或 bind1 exact CAM onehot | 未 release/squash |
| tracker live/kind/epoch/PID | 既有 32-token Q | alloc0/1 birth、exact death | 无事件 |

两个 reservation 不是 FIFO 的同一写口副本：各自有 valid、完整 payload、owner token、kill、
consume、AGU 和终止事件。共享的仅是更下游 request/translation/cache/MIQ push。

IQ 的年龄域由 packed resident array 唯一定义：任意时刻 `valid_q[i] && valid_q[j] && i<j`
即 entry `i` 严格更老，不存在同龄、epoch 或 wrap tie；dispatch/issue/kill 后的 compaction
保持该全序。memory pair 必须选择所有 eligible resident 中最老两个，bank0 绑定更老 entry，
bank1 绑定次老 entry，不能按物理端口重新编号。

### 3.2 状态转移

| 当前 | 条件 | 下一状态 | 副作用 |
| --- | --- | --- | --- |
| both empty | ready LL/LS/SL/SS pair + dual owner credit | bank0=older, bank1=younger | IQ 双 pop、tracker 双 birth、可选 SQ 双 bind |
| bank0 valid | local terminal 或 request/buffer handoff | bank0 empty | exact completion/owner handoff；bank1 本拍仍不得越过 edge-old bank0 |
| bank1 valid, bank0 empty | local terminal 或 request/buffer handoff | bank1 empty | 使用 bank1 AGU/owner tuple，经共享 mux进入既有下游 |
| bankX valid | global/selective cancel | bankX empty | non-STORE collector terminal 或 STORE-qualified SQ release |
| any valid | 下游 stall | hold | payload/token/PID/tval 逐位稳定 |

无新增 FSM 编码；每个 reservation 是 `EMPTY/FULL` 两态 Moore owner，shared request arbiter
仍为组合 onehot grant。

bank1 consume eligibility 只能读取 edge-old `bank0.valid==0`。bank0 在当前沿被 consume、kill、
flush 清除时，bank1 同沿仍不得产生 request、MIQ push、local completion 或 SQ terminal；最早
下一拍才可下送。

### 3.3 立即断言清单

- `[V8P-MEM-PAIR-ATOMIC]`：pair 两路 fire/capture/stale-drop 守恒且禁止 split。
- `[V8P-MEM-PAIR-SIDE-EFFECT]`：current-current pair 的双 fire、双 capture、双 tracker
  birth 与对应 SQ bind package 逐拍等价；单 credit 时无半事务。
- `[V8P-MEM-DUAL-TOKEN]`：双 capture token/PID 均不同、tracker next-Q exact-live。
- `[V8P-MEM-RES1-CAPTURE/HOLD]`：bank1 next-Q capture 与 stall payload稳定。
- `[V8P-MEM-RES1-NO-FALLTHROUGH]`：capture 拍无 request/local completion。
- `[V8P-MEM-AGE]`：bank0 live 时 bank1 无 consume/request/local terminal。
- `[V8P-MEM-AGU]`：两个 AGU 分别只读本 bank captured address/store payload。
- `[V8P-SQ-DUAL-BIND]`：bind0/1 各 CAM onehot、不同 entry/token/PID，store-store 不丢 bind。
- `[V8P-MEM-OWNER-CONSERVATION]`：任一 resident bank token 属于 tracker live set，取消/迁移
  后无 orphan 或重复 terminal。
- `[V8P-TCOLL-SEVEN-INGRESS]`：七个不同 exact-live tuple 可同沿全部进入 32-bit pending
  set；双 bank cancel 不覆盖，pending 满时不存在合法的额外 nonpending live owner。
- `[V8P-MEM-SPECIAL-EXCLUDE]`：AMO/LR/SC/FP memory 不得选择 issue1 memory、申请
  alloc1、写 bank1 或 SQ bind1。

每条承重断言必须至少有一个 compile-success 临时 mutation 激活；编译失败、未激活或仅超时
不算 kill。

## 4. RTL 级电路拓扑（实现前冻结）

1. **module 边界**：`OooIntIssueQueue` 内 resident metadata ->
   `OooIntIssueSelect8`；两路既有 IQ valid/ready payload -> `OooIntBackend`；backend 的
   dual alloc -> `OooMemOwnerTracker`；dual bind -> `OooStoreQueue`。均为单 `clk` 同步域，
   active-high synchronous reset。
2. **状态寄存器**：§3.1 全量；bank1 字段与 bank0 同构，独立时序块或同块独立 enable，
   禁止用数组循环隐藏两条不同 owner enable。
3. **组合块**：packed-age selector、pair-credit DAG、每 bank capture predicate、两个
   captured-data `src1+imm`/`LSU`、bank0-priority shared request mux、dual SQ bind CAM。
4. **FSM**：无新增多位 FSM；bank0/bank1 各为 valid bit 两态，转移见 §3.2。
5. **pipeline/握手**：IQ resident Q -> 原子 pair fire -> reservation Q -> AGU -> shared
   request/buffer/MIQ；每个箭头至少一个 edge-old owner，禁止 IQ->request fall-through。
6. **优先级**：逐 bank `reset/flush/restore > kill > consume > capture > hold`；共享资源
   `SQ drain > AMO write > buffer > bank0 > bank1`，bank1 只在 edge-old bank0 empty 时 eligible。
7. **复制/共享**：复制 reservation Q、owner allocation、AGU/LSU、SQ bind；共享 bridge、
   translation、cache、MIQ push、memory response。共享处有显式 onehot mux/grant。
8. **critical path**：新增最敏感路径预计为 tracker alloc0 claim -> alloc1 token scan ->
   atomic pair ready -> IQ compact enable；不得加入 bridge/cache ready。第二 AGU 位于 reservation
   Q 后，不进入 IQ ready。综合/STA在全架构 GREEN 前仅作诊断。
9. **function 划分**：`mem_owner_kind_from_ctrl` 与 terminal-capability predecode 仅作小型纯组合
   helper；reservation 状态、SQ bind CAM、共享 grant、flush/kill 必须显式 `assign`/
   `always @(*)`/`always @(posedge clk)` 或子 module，不用软件式 task/function 隐藏状态。

## 5. 定向验收与 claim 边界

release 与 `OOO_ASSERT` 均须覆盖以下 15 个不可重复规范键：

```text
alu_alu, alu_branch, branch_alu, alu_jal, jal_alu,
alu_jalr, jalr_alu, alu_load, load_alu, alu_store, store_alu,
load_load, load_store, store_load, store_store
```

覆盖位只能由 accepted/resident 冻结的真实 ctrl kind、plain-memory capability、canonical
双 fire 与最终 bank/token 身份共同生成，禁止由场景名或循环序号直接置位。

memory pair 证据以 accepted resident payload 为根：两 entry 至少驻留一个完整周期，随后同沿
双 fire，下一沿同时看到两个 reservation、两个不同 token、两个 non-zero-generation full PID
及两个 AGU 结果。反压、split-credit、stale-PID、store-store dual bind、branch/global cancel
与串行下送均需独立反例。

四个 memory 场景必须使用不同基址、立即数、访问宽度和 store data；在 bank0 被下游阻塞且
两 bank 同时 valid 时，两份 AGU address/wdata/wstrb/misalignment 必须已同时形成并保持。
capture 后扰动 raw PRF/IQ 输入不得改变任一结果。另以 AMO、LR、SC、FP load/store 分别与
普通 memory 配对，证明特殊类别不会消耗 issue1/alloc1/bank1/bind1。

SQ bind miss、multi-hit、同 entry、token 交叉或单侧 bind 都是不可恢复的设计错误。生产
不把 SQ CAM 加入 pair-ready；而是依赖“每个 accepted plain store 已在 dispatch exact 分配
一个 SQ entry”的既有不变量，并用 bind0/bind1 onehot、互斥及
`{bank,full PID,ROB,token}` 精确关联的立即断言 fail fast。任何该类错误都不得发布证据。

mutation 至少增加：单 credit 下 alloc0 独生、单 AGU 时间复用/bank0 结果复制、特殊 memory
误准入、SQ token 交叉/单侧 bind、bank1 同沿 consume bypass。每个变异必须分别记录
`compile_success/elaborated/activated/target_assertion_failed`，四者全真才算 kill。

collector leaf 另需构造七个不同 live token 同拍 ingress、双 bank cancel 与双 dequeue stall，
证明 pending popcount/metadata 完整并最终恰好一次排空；单 ingress 写口、丢 bank1 lane、同 token
覆盖与 pending 满时错误接受第 33 owner 的 compile-success 变异必须被拒绝。

DI-3 只有在 pair matrix 15/15、source dual-terminal 检查、完整 provenance 与 mutation-negative
全部通过后才可 GREEN。DI-5 必须因单 translation/cache/completion/credit 继续 RED；OOO-3 因
缺真实 LQ/物理双查询/replay 继续 RED；不得发布 PPA 数字。
