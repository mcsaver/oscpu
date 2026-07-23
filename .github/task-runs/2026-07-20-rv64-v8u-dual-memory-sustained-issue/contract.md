# v8u/F4 dual-memory sustained-issue contract

> 状态：接口契约已按 production trace 反例增补，RTL、局部 directed evidence 与 64-cycle
> production trajectory 已落地，正式同设计架构汇总与独立复核尚待绑定。任何 directed PASS 只证明其声明的
> 局部性质；在 64-cycle integration trajectory、compile-success mutation、system aggregate、
> same-design manifest 和独立复核全部通过前，DI-5/OOO-3/overall architecture 均保持 RED，
> PPA 保持 `UNQUALIFIED`。

## 1. 目标与边界

F3 已保证普通 load 只在最终物理地址和 typed memory class 锁存后查询 SQ。当前每个
`OooMemAxiBridge` 的热命中路径仍为 `S_SQ_QUERY -> S_LOOKUP -> S_SQ_QUERY`，同步 D-cache
虽可每拍接收一次 lookup，但 bridge 每两拍才发一次，因此双 bank 总吞吐约为每拍一个请求。

首轮 production `NpcCoreTop` 轨迹还证明了一个更上游的确定瓶颈：两个
`mem_issue*_res_valid_q` 在旧 owner 请求握手前硬关 IQ ready，且握手沿不能捕获后继 owner。
即使 I-cache 与 D-cache 均预热，每对 load 的 AGU request 仍只有四拍一次，MIQ 永远只有
current owner，bridge lookahead 因而没有可观察的 next owner。继续追踪 request grant还确认
F3 的 bank-local `active_load || station_load` admission fence会在 bridge READY 之前直接禁止下一
load；F4 必须以真实 station READY取代这两个 residency近似，只保留 `retry_valid`保守 fence。

F4 优化 canonical `ENABLE_DUAL_MEM=1` 热命中路径的两个连续弹性边界：

1. 当前 reservation Q owner 发生精确 request/local-terminal consume 的同沿，允许从 IQ 捕获
   下一对 ordinary memory owner；捕获数据仍只写 reservation Q，新 owner不得组合穿透成当拍
   request；
2. 当本 bank 当前 load 的 cache-hit
response 在本拍被正式接受、station 同时持有下一条已得到最终 PA 的 ordinary cached load、
且该下一条恰是 MIQ 的 next head 时，允许同拍对 next head 做 final-PA SQ query；仅在 exact
`allow` 时启动下一次同步 D-cache lookup，并把 station owner 原子提升为 active owner。

本节点不增加 speculative cache admission，不增加 MIQ pop port，不改变 token allocation、
store drain、NC/IO、PTW、AMO/LR/SC 或 legacy 单 memory 路径，也不以降低 1.90 IPC 门槛换取闭合。

### 1.1 reservation turnover 契约

- 普通 reservation capture credit 仍为 Q-empty；occupied reservation 不因单 lane consume直接开放普通
  IQ pop。持续路径使用独立 pair-turnover face：只有两个 edge-old reservation 同拍精确 consume、IQ
  注册 entry0/1 同时形成 ordinary memory pair、两份 tracker token 均可分配时，才原子 pop2/capture2。
- same-edge consume+capture 时，当拍 request/terminal payload只能来自 edge-old reservation Q；
  edge-new IQ payload只能在沿后成为 reservation Q，禁止 raw IQ -> AGU/request 组合穿透。
- 两个 memory terminal必须原子 turnover：memory pair capture、tracker 双 token allocation和两份
  reservation payload要么同时发生，要么均不发生。
- kill/flush/restore优先于 turnover；old owner被 kill时不得借其 credit捕获 younger owner。
- ordinary singleton、AMO/LR/SC、store exception/forward和 legacy单 memory模式保留原语义；只有
  canonical双 ordinary-memory pair可形成持续双 bank turnover。
- 单 lane consume 不形成 singleton turnover：已消费 reservation清空，另一 reservation保持，IQ 中的
  后继 pair不 pop；旧 pair完全排空后再按普通 pair capture恢复。这一非对称轨迹允许出现有限气泡，
  不外推为双 bank稳态 2 IPC 声明。
- turnover允许桥 `ready`进入 reservation elastic ready锥，但不得进入 payload D mux、PRF data、
  owner identity或当前 request payload；PPA证据必须单独检查该 control cone。
- active/station load residency不再作为 bank admission fence；MIQ slot、bridge station
  `req_ready`和 bank-local `retry_valid`共同给出真实容量。retry holder有效时仍禁止新 load，
  queued current owner的 replay保持原地等待，不得分配第二 retry holder。

## 2. 接口与 identity 契约

- `OooMemInflightQueue` 新增只读 next-head face；至少输出 next entry 的 valid、kind、
  owner kind/token/epoch、fault、ROB index、killed/effective-killed，以及 backend/bridge 做
  exact query 所需的完整既有 payload。next head 定义为 edge-old head 的后一 resident entry，
  包括环回；深度不足两个时 `next_valid=0`。
- current response 的唯一真源仍是 current MIQ head。next-head SQ query 的只读展示资格使用 exact
  registered response candidate：response tuple、current MIQ head、tracker full `ProducerId` 与 active
  owner必须精确一致且未 kill，但不含 `rsp_ready`。真正的 SQ lookup、station promotion和 current-head
  pop仍必须同时满足 `response_fire`，因此 held response 可保持 B query稳定而不产生任何状态转移。
- tracker token table仍是 full `ProducerId` 唯一真源。next-head tuple 必须与 tracker 的
  live/kind/token/epoch 精确匹配；不得用 raw ROB index、数组位置、station payload或 current
  head identity代替。
- bridge 的 lookahead query payload只来自已锁存 station Q 的最终 PA、byte mask、typed
  class和 owner tuple；不得来自组合 request bus、VA或 peer bank。

## 3. 握手、状态与优先级

热命中连续路径为：

```text
cycle N:   active A in S_LOOKUP returns hit + exact response candidate
           station B final-PA exact query against MIQ next head -> allow
           A rsp_ready makes response_fire; D-cache captures B lookup address
edge N:    MIQ pops A exactly once; bridge promotes B to active and enters S_LOOKUP
cycle N+1: D-cache returns B hit; B is current MIQ head and may response_fire
```

- 每个 bank 同拍最多一次 MIQ pop；它只属于该 bank 的 current response A。bank0/bank1
  各有独立 MIQ，故 aggregate 同拍最多两次 pop，不存在全局单 dequeue。lookahead decision
  不 pop B、不释放 B token、不形成 B terminal，也不得使用 retry holder handoff。
- A response fire还必须同时证明 current MIQ head tuple、tracker live/kind/epoch、token表中的
  full `ProducerId`/ROB identity与 A精确一致且 A未 effective-kill；否则不得启动 B fast path。
- station SQ query 可在 `current_lookup_hit && exact current response candidate && station_valid &&
  station ordinary cached load && station final-PA-ready && exact next-head && !flush && !effective_kill`
  时展示；它不含 `current_rsp_ready`，以切断 query/decision 到 response-ready 的组合反馈。
- 只有 `current_rsp_ready` 使 A `response_fire` 且 SQ decision 为 `allow`，才能发 B cache lookup并提升
  station；`forward/replay/非法或非 one-hot decision` 均不得发 lookup。
  这些非 allow 情况下 A 仍可正常完成，B 沿既有慢路径成为 active 后重新查询。
- lookahead query 的 `retry_ready` 固定为 0；否则 current response pop 与 B retry pop 会要求
  同拍双 pop。若 B 需要 replay/forward，必须在成为 current head 后走 F3 正常路径。
- production D-cache lookup口没有 backpressure；`lookup_en`就是该拍真实 capture/fire。
  B lookup capture 与 station->active promotion 是同一个沿；promotion 后 state 直接为
  `S_LOOKUP`，因为同步 SRAM read 已经发出。不得再次进入 `S_SQ_QUERY` 重复 lookup。
- 同一沿若 request bus又接受 C，则 active只捕获 edge-old station B，station只捕获 C；
  A token terminal、B token residency与 C token allocation必须互不混淆。若没有 C，station清空。
- 全局优先级为：reset > flush/effective kill > current terminal/drop > exact lookahead allow >
  normal station advance。lookahead 永远不能阻止 A 的 exact response/drop。

## 4. stall、flush、ordering 与 side effect

- `rsp_ready` 只作为 current response是否完成以及 B lookup/promotion是否真实 fire 的 credit；不得由
  next SQ decision反向影响。next query可在 READY-low时保持组合稳定，但 decision不得进入
  response-ready、request-ready、reservation capture、MIQ push或 tracker allocation。
- 当 lookahead 条件不全时，原 F3 路径逐拍等价；translation miss、fault、NC/IO、forward、
  replay、backpressure 和 station 空均不得使用 fast path。
- flush、MMU flush、current/next effective kill或 tuple mismatch优先阻断 next lookup和
  station fast promotion；不得出现 killed owner 的 cache/AXI/device admission。若 B lookup
  已于前拍合法 capture而 B在返回拍被 kill，返回数据不得产生 WB/wakeup/architectural
  completion；只允许沿既有 exact closed-response/drop terminal释放 B owner。
- D-cache lookup必须蕴含 exact final-PA SQ `allow`。禁止只凭 non-alias 推测、VA比较、
  current-head decision或前一拍 residual decision启动 lookup。
- fast path与 F3 normal path必须复用同一个 `OooStoreQueue` physical-byte CAM和同一 edge-old
  SQ snapshot；unfilled older store、同拍 fill/terminal不确定性或任何 tuple/provenance不确定
  均只能保守 replay，不得由第二套简化判定产生 allow。
- lookahead 只优化 target admission时刻，不改变 F3 physical-byte ordering：unknown older
  store、部分覆盖、typed-class冲突和 IO barrier仍 replay；完整覆盖仍 forward且不读 D-cache。
- bank0/bank1独立计算 next head、query和 lookup；任何一侧 stall/replay不得压低另一侧。

## 5. 可执行证据与 mutation 门

P0 directed evidence至少覆盖：

1. reservation A精确 request fire与 B IQ capture同沿发生，A request仍绑定 A Q payload、沿后
   reservation精确绑定 B；stall、kill、token不足时不得错误 turnover；
2. MIQ 含 A/B/C 时，A exact pop同拍 next face精确给出 B；head环回、单 entry、flush/kill均正确；
3. backend 只在 A exact registered response candidate存在时以 B next-head匹配 lookahead query；无 exact
   candidate、wrong token/epoch/kind、B killed时 fail-closed。READY-low时 query可保持，但 current pop、
   B lookup/promotion必须为零；
4. bridge热命中 A/B/C 连续请求可逐拍 lookup/response，held response/backpressure时保持 B query并关闭
   lookup/promotion fast path；
5. B replay/forward/fault/NC/IO时无 lookahead cache admission，随后沿 F3路径得到正确结果；
6. 双 bank 64-cycle independent alternating-bank cache-hit integration trajectory：
   `trace_cycles>=64`、`memory_issue_ipc>=1.90`、`dual_issue_cycles>=58`，且两 bank 的
   `agu_accepts`、`translation_accepts`、`physical_lsq_queries`、`cache_admissions`、
   `completions`各自均 `>=58`；
7. release-mode assertions证明每次 fast lookup均与 next exact identity和同拍 current pop绑定，
   次拍 response owner为提升后的 B，且 current/next没有双 pop、ghost或 stale completion；
   还应覆盖 `$past(fast_lookup_fire)`、kill-over-result和 B提升/C refill的寄存器归属。

compile-success mutation至少拒绝：

- occupied reservation无 consume仍开放 IQ capture；
- turnover时request payload误取新 IQ owner，或 consume后丢失同沿 captured owner；
- next query错误比较 current head；
- 无 current exact response candidate仍展示 lookahead query，或无 response_fire仍启动 lookup/promotion；
- 忽略 next token/epoch/kind/effective-kill；
- SQ非 allow仍启动 D-cache lookup；
- lookahead开启 retry-ready或形成第二个 MIQ pop；
- station promotion后仍进入 `S_SQ_QUERY`；
- 两 bank next/query/lookup交叉接线；
- 64-cycle证据由不同运行或不同 design-id拼接。

## 6. promotion 边界

F4 candidate必须记录精确命令、exit code、source closure、test SHA、metrics SHA、mutation
summary SHA和同一 design-id。独立 reviewer只能检查被绑定 candidate，不得覆盖 candidate。
即便 F4 局部闭合，只有 architecture checker在相同 design-id下同时接受全部 predecessor、
DI-5、OOO-3和系统 aggregate，architecture才可进入下一状态；arch-stable freeze和等总容量
bank宏 PPA证据仍是单独门。
