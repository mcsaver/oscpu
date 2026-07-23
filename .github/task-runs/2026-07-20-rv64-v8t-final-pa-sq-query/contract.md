# v8t/F3 final-PA SQ byte-query contract

> 状态：F3 executable closure 已完成；focused runner 永远先生成并保留 candidate。
> `final_pa_sq_ordering_checkpoint` 只能由精确绑定该 candidate run-id、functional source
> closure、candidate result SHA 与 mutation-summary SHA 的独立实现审查 JSON overlay 授权。
> promotion-only finalizer 还必须校验合同 SHA、review result SHA、P0/P1 空集与 claim boundary，
> 并生成独立 checkpoint artifact，禁止覆盖被审 candidate。在 F4 的 64-cycle IPC、全量系统证据、
> 等总容量 bank 宏和 arch-stable PPA 证据闭合前，DI-5、OOO-3、overall
> architecture 仍为 RED，PPA 仍为 `UNQUALIFIED`，不得据此 promotion。

## 1. 现状、目标与非目标

F2 已把两个 captured-data AGU owner 接入两套 MIQ、bridge、DTLB、D-cache、
response/WB 路径，但 load 仍在发射拍用 VA 扫描 SQ：Sv39 开启时直接退化为
“任意更老 store 都阻塞”，前递也只允许未翻译模式。F3 把 canonical
`ENABLE_DUAL_MEM=1` 路径的普通 load 消歧移到每个 bridge 已锁存最终 PA、typed
memory class 且尚未进入 cache/NC/IO target 的边界。

每个 bridge 输出当前 active load 的 exact owner tuple、最终 PA、byte mask 和 typed
class。backend 用 token 的 edge-old tracker 表取回 full `ProducerId`，再由
`OooStoreQueue` 的两套只读 physical-byte CAM 独立返回 `allow/forward/replay`。
DTLB hit、PTW miss、A/D update 后续访问必须汇合到同一个 query state。

所有 plain store 在 dispatch/ROB allocation 同拍按程序序分配 SQ placeholder；SQ
credit 是 dispatch admission 的必要条件。因此任何仍 live 的 older plain store，哪怕
AGU、地址操作数或数据操作数尚未 ready，也已经出现在 SQ 的 valid census 中，并以
`filled=0` 强制更年轻 final-PA query replay。AMO/LR/SC 不属于该 SQ 集合，继续由既有
ROB-head singleton ordering gate 全局串行，不允许更年轻 ordinary load 与其并发。

本节点不实现“load 已访问内存后发现次序冲突”的 ROB recovery，也不新增 LQ。
这里的 `replay` 精确定义为 bank-local exact retry handoff：bridge 在 retry slot 可接收前保持
active owner/query payload且不呈现 cache/AXI/device side effect；`retry_fire` 同沿把完整 MIQ
head payload与 full ProducerId 捕获进该 bank retry slot、exact pop 当前 MIQ entry并释放 bridge，
但不释放 tracker token、不形成 ROB terminal。retry slot 随后与新 reservation owner按 edge-old
年龄重新竞争同一 bank，胜出后以普通 request fire 重新 push MIQ。它不是 squash、redirect、
新 token allocation 或 architectural completion。legacy `ENABLE_DUAL_MEM=0` 兼容路径可以保留
既有 VA gate，但 canonical dual path 不得再以它代替 final-PA query。

## 2. 六类接口契约

### 2.1 端口、位宽、时钟、复位和 identity

- bank0/bank1（层级信号名沿用 mem0/mem1；不是可动态迁移的 issue lane）各有独立
  query face：`valid`、`owner_kind[1:0]`、
  `owner_token[4:0]`、`mmu_epoch[1:0]`、`paddr[63:0]`、`wstrb[7:0]`、
  `attr_valid`、`class[1:0]`，以及返回的 one-hot
  `allow/forward/replay` 和 `forward_data[63:0]`。
- query payload 只来自 bridge active Q；不得从当前 request bus、另一 lane、AXI
  payload 或组合 MIQ tail 重构。两路 query 不共享选择器、buffer 或返回 mux。
- backend 只有在 tracker 的 live/kind/token/epoch 与 query tuple 精确一致时才把
  `token -> full ProducerId` 结果交给 SQ；tuple 不精确时必须返回 `replay`，不得用
  raw ROB index 或 token 数值猜年龄。
- query state、active owner、最终 PA、typed class 和 forward response 均在现有
  active-high synchronous reset 域。reset/flush 清除可取消的 query owner；已接受的
  `nokill` SQ physical write 继续遵守既有 B-terminal 生命周期。

### 2.2 请求、query 和 target admission 握手

普通 LOAD 的成功 final-PA 路径严格为：

```text
request fire -> station -> translate/PMP/PMA/PBMT -> final-PA Q
  -> SQ_QUERY --allow--> cache lookup / NC AR staging / IO wait
              --forward--> held bridge response
              --replay--> exact bank retry slot --edge-old re-admit--> request fire
```

- 这里的 `request fire` 是 backend bank allocator 与对应 bridge 的 canonical request
  handshake。该沿在 translation/query **之前**原子完成三件事：从 reservation 消费 exact
  owner、把同一 expected tuple push 到所选 bank 的 MIQ、由该 bank bridge 锁存 active
  request。query/forward 不创建第二个 MIQ entry，也不做 synthetic push；从 `S_SQ_QUERY`
  到 held response 的整个生命周期，原 entry 必须继续驻留且是该 bank exact MIQ head，
  直到最终 `response XOR drop` 才 exact pop。唯一非 terminal 例外是 exact `retry_fire`：
  同沿 MIQ head -> retry slot holder handoff并pop；后续重新准入仍通过普通 request fire
  重新 push一次，不得直接伪造 MIQ residency。
- 一个 bank bridge 同时最多只有一个 active transaction，而 allocator 对每个 bank 每拍至多
  接受一个 request；因此 `query0` 只可能来自 bank0 的唯一 active owner，`query1` 只可能
  来自 bank1 的唯一 active owner。“两路同拍 forward”必然是不同 bank，不存在同 bank
  双 query/双 forward，也不得为它新增仲裁或 MIQ push port。若未来允许每 bank 多 active，
  必须另立版本化合同并新增 tag-indexed residency/response 规则。
- `SQ_QUERY` 只对 exact ordinary LOAD owner 有效；PROBE、DRAIN、AMO/LR/SC、fault
  response 与 PTE walk transport 不进入该查询。
- query-valid 不得依赖 query decision；decision 不得进入 request-ready、MIQ push、
  tracker allocation 或另一 lane request-valid。
- `allow/forward/replay` 在 query-valid 拍必须严格 one-hot。它们是 decision，不是
  terminal：裸 decision 不得释放 owner、pop MIQ、产生 WB/wakeup 或 terminal；唯一允许的
  MIQ pop 是下述另有 `retry_ready` credit 的 exact retry holder-handoff，它仍不释放 owner、
  不产生 WB/wakeup/terminal。
  `allow` 才能产生对应 cache lookup capture，或在时钟沿捕获到后续 NC/IO target
  state；`forward` 在时钟沿把 exact owner/class/data 原子捕获到已有 held-response
  register 后才离开 query state；`replay` 在 `retry_ready=0` 时必须保持 active tuple、PA、
  mask、class和数据来源不变。只有 `query_valid && replay && retry_ready` 的 exact
  `retry_fire` 才能原子转换 holder：retry slot捕获完整 MIQ payload/full PID，MIQ exact pop，
  bridge回到可服务状态。任何非法/非 one-hot decision 均保持 query，不得按优先级猜测。
- cache lookup 可以在 `allow` 判决拍发射并于下一 `S_LOOKUP` 拍判决；SQ CAM 只进入
  lookup enable/next-state，不得进入 SRAM address bits。NC/IO 在下一寄存态才可呈现
  外部 AR，避免 SQ decision 直达 AXI VALID。
- forward decision 与 response fire 分离。已捕获的 held response 在
  `rsp_valid && !rsp_ready` 时 owner tuple、full-PID 对应关系、class、data、fault
  provenance 全部稳定；SQ 后续 fill/terminal/release 不得改写它。forward 复用 bridge
  原有 response identity、MIQ head pairing、terminal collector、global WB allocator 和
  FP-load sink；只有正式 response fire 才形成相应 completion/terminal，不得恢复发射拍
  的 EX0/EX1 本地前递捷径。
- held forward response 继承 F2 的 bank-local MIQ/bridge/tracker holder census，而不是只靠
  SQ query 组合 tuple 保活：`S_SQ_QUERY || S_RESP` 必须蕴含唯一的同 bank exact MIQ
  residency 和未复用 tracker PID。反向 bank 的 MIQ 不得匹配、pop 或替代该 entry。
- 每 bank retry slot 是显式 holder，至少保存 full ProducerId、ROB index、pdest/FP sink、
  size/unsigned、原始有效地址、wdata/wstrb、owner kind/token/epoch与 fault-tval；不得从当前
  request bus、SQ data或另一 bank重构。retry slot valid时其 token仍live但不在MIQ，且
  `retry slot XOR same-token MIQ/bridge active`；重新 request fire 是允许的同沿
  `retry slot -> MIQ/station` handoff，不是第二 owner。

### 2.3 physical-byte ordering 与数据语义

对 query owner `L`，SQ 按 `head -> tail` 程序序扫描所有 valid、比 `L` 更老且
`terminal=0` 的 store。`request_sent=1` 的 resident store 始终视为更老；其它 entry
用 edge-old ROB head 的环形距离比较。这里的 SQ `terminal` 不是 probe success、ROB done
或 owner execution completion：它只可能是无物理 side effect 的 probe fault，或已经收到
physical write B terminal 且完成相应 cache/peer maintenance 的 store。故只有
`terminal=1` 才能证明 `no_effect || globally_visible` 并从 effect-pending scan 排除；
successful probe/fill、ROB done、commit、AW fire、W fire 均不得排除 entry。

每个 SQ entry 的 byte `s` 表示 `paddr+s`，数据为 `data[8*s +: 8]`；query byte
`l` 表示 `query_paddr+l`，仅 `query_wstrb[l]=1` 时参与。扫描后命中的更年轻旧 store
逐字节覆盖更老 store，形成每个 load byte 的 youngest-older producer。

决策优先级固定为：

1. query tuple/typed class 非法、byte mask 为零、任一更老非 terminal store 尚未 fill、
   typed provenance 非法，或任一更老 IO store 构成全局设备顺序屏障：`replay`。SQ
   `filled` 必须是 PA、typed class、完整 byte mask 和所有 enabled data byte 的同沿原子
   valid；不存在“address filled 但 data invalid”的中间态；
2. query 本身为 IO 且仍有任一更老非 terminal store：`replay`；无此 store 才 `allow`
   进入既有 `S_DEVICE_WAIT`，仍须等 exact ROB-head release；IO 永不 forward；
3. CACHED/NC query 若与更老 store 无物理字节重叠：`allow`；
4. 有重叠且所有 requested byte 都由 legal CACHED/NC store 覆盖：`forward`，数据低位
   对齐 query 起始 PA，可由一个或多个 store 合成；
5. 有重叠但覆盖不全、重叠 class 不一致或 byte provenance 不可证明：`replay`，直到
   对应 store terminal 后再允许读 memory。

不同 VA 映射到同一 PA 必须命中；相同 VA 映射到不同 PA 必须不命中。DTLB hit 与 PTW
miss 后得到同一 PA 时必须给出相同决策。SQ fill/terminal 与 query 同拍可以保守多 replay
一拍，但不得提前 allow 或读到半更新组合状态。

跨页访问不得用首字节 PA 线性推出第二页：现有 precise pre-query gate 对任何跨 4KiB
page 的 multi-byte ordinary access 形成本地 exception，不进入 bridge/query。若未来改为
split translation，必须另立版本化合同，为每个 fragment 独立生成 final PA、query mask、
owner/terminal conservation；本节点不授权该扩展。

### 2.4 stall/ready DAG 与双 lane 并发

允许的组合方向：

```text
bridgeN active Q -> queryN payload
queryN exact tuple -> tracker full ProducerId Q -> SQ queryN CAM
SQ queryN decision -> bridgeN query next-state / cache lookup enable
bridgeN response Q -> bankN MIQ head -> global terminal/WB credits
SQ replay + retry-ready -> bankN retry slot capture + exact MIQ pop
bankN retry slot + reservation ages -> bankN request allocator -> normal MIQ push
```

禁止的方向：

- query decision -> bridge request-ready / backend reservation capture / owner allocation；
- lane0 query/decision -> lane1 payload、valid 或 identity，反向亦同；
- response-ready、WB free count、terminal dequeue-ready -> query payload 或 SQ CAM；
- retry-ready 只能来自本 bank retry-slot空 credit与 exact MIQ/tracker匹配，不得读取 peer
  bank、WB credit、terminal dequeue-ready或组合 request-ready；
- SQ query -> SRAM address bits、AXI address/data payload；
- 当拍 SQ fill/terminal D input -> 提前修改 query decision；query 只观察 edge-old SQ Q。

两个 bank query 可同拍独立得到任意组合：`allow/allow`、`allow/forward`、
`forward/forward`、任一路 `replay`。一个 lane replay 不得压低另一 lane 的 target
admission 或 response。双 forward 仍须等待各自正式 WB/FP sink credit，不能把
“query 可 forward”误当成已经完成。

同一 bank 内不存在第二个 concurrent query owner；同 bank 的多个 reservation owner 仍由
F2 allocator 在 canonical request fire 前按 edge-old age 选一个，loser 留在 reservation，
尚未拥有 bridge active Q 或 MIQ residency。source checker/assert 必须证明每个 query face
只连接对应 bank bridge与对应 bank MIQ，不得把“issue lane 数=2”误读成“每 bank query 数=2”。

每 bank只需一个retry slot，但必须同时满足以下结构约束：当本 bank已有retry owner，或bridge
active/station中已有ordinary LOAD时，不再向该bank接受第二个ordinary LOAD；plain STORE probe、
ROB-head SQ drain和head-only AMO仍可进入。这样active load背后不会再排入第二个load station，
不存在两个同时需要yield而单slot溢出的状态。retry load与可入bank的store reservation按
edge-old full ProducerId比较：更老store优先；retry更老或无store candidate时retry可重发；
ROB-head SQ drain/AMO优先级更高。固定让retry压住older store、固定让无穷younger store压住retry、
或以raw index/arrival order仲裁均非法。

### 2.5 flush、kill、recovery 与 side effect

- `flush_i`、effective kill 或 owner tuple 失配在 query 拍优先于 allow/forward：不得发
  cache lookup、AR、response、WB、wakeup、SQ fill/terminal 或 peer maintenance。
- `S_SQ_QUERY` 尚未呈现外部 target，可像 `S_LOOKUP` speculative arm 一样直接 drop；
  drop terminal 必须携带原 active tuple，且与正常 response 互斥。
- forward decision 只在 exact held-response register 可无条件捕获的沿推进；它不依赖
  MIQ/WB/FP sink 当拍 credit。response 被 backpressure 时，forward data、typed class、
  fault provenance 和 response owner snapshot 必须保持；后续 SQ 变化不得改写已捕获
  response。allow-to-cache 以同步 macro lookup enable 作为无反压 capture；allow-to-NC/IO
  只捕获 registered target state，AXI/device VALID 最早下一拍出现。
- forward capture 后发生 flush/kill 时，复用 F2 已冻结的 `S_RESP` exact-drop 生命周期：
  kill 立即阻断 WB、wakeup、cache fill 和其它 architectural completion，但 held owner
  snapshot、bank-local MIQ entry 与 tracker holder 保留到 exact `response XOR drop`；drop0
  携带该 response snapshot 并 exact pop 本 bank MIQ，旧 PID 在 holder census 清零前不得
  复用。不得直接清 held Q，也不得只屏蔽 WB 而泄漏 MIQ。
- allow capture 后同样继承 F2 target-state kill 规则：尚未被同步 cache lookup/registered
  NC/IO target 接受的 arm 可 exact drop；已发 AR 的 `S_READ_ADDR` 按既有 hold/drain 合同
  完成 transport 后 drop，`S_DEVICE_WAIT` 在 ROB-head release 前可取消。query 不改变这些
  boundary，也不新增任何提前 release。
- branch selective kill、global restore、MMU flush 和 token recycle 必须继续由 MIQ、bridge、
  tracker、SQ、retry-slot residency 的 exact terminal 证明闭合。query/retry handoff不新建或
  释放 owner。retry slot发生global/selective kill时必须产生lossless tagged exact drop并清除
  slot；不得重发killed owner、静默清slot或提前释放token。
- 从每个 bank request fire 起，translation、PTW、A/D、SQ_QUERY、target和S_RESP所有状态都
  受同一个 `push - exact response/drop/retry-pop == MIQ resident` conservation约束。pre-query
  fault形成exact exception response；pre-query kill禁止新side effect并按现有AR/AW/W drain
  boundary最终exact drop；晚到PTW/A-D response只能命中原bank/token/epoch，不得命中新PID。
- replay不得饥饿其所依赖的更老store：active load完成retry handoff后释放bridge/MIQ，older
  same-bank store一旦ready即可进入reservation并在edge-old allocator胜出，完成probe/fill及
  最终drain/B。source checker和directed test必须同时拒绝“query原地无限hold”和canonical
  dual path退回issue拍阻塞所有load这两种错误修法。

### 2.6 source of truth

| 事实 | 唯一真源 | 禁止替代 |
| --- | --- | --- |
| query owner/payload | bridge active tuple、final `paddr_q`、`wstrb_q`、typed attr Q | request bus、VA、另一 lane |
| query full identity | owner tracker token table的 edge-old full `ProducerId` | raw ROB index、token 顺序 |
| store program age | SQ full ProducerId/ROB index + edge-old ROB head；`request_sent` residency exception | SQ array index、bridge bank、terminal lane |
| byte overlap | final physical byte address + valid byte mask | VA line、cache index、单 entry 区间猜测 |
| youngest byte data | SQ head-to-tail scan中最后一个匹配该 byte 的更老 store | 最老 match、固定 lane priority |
| target class | final-PA typed classifier/PBMT provenance Q | VA region、legacy cacheable Boolean |
| completion owner | bank-local bridge response snapshot + MIQ head + tracker/ROB-open | query combinational tuple、另一 MIQ |
| replay lifetime | bridge `S_SQ_QUERY`到exact retry handoff，再由bank retry slot持有 | IQ重发、ROB done清除、新token分配、静默MIQ pop |

## 3. P0/P1 反例与可执行证据

P0 directed evidence 至少覆盖：

1. Sv39 两个不同 VA 映射同一 PA，load 命中更老 store 并 forward；将比较改回 VA 后测试失败；
2. DTLB miss/PTW leaf 得到 alias PA，必须经过 query，删除 walk->query 路由后测试失败；
3. 一个 store 的完整覆盖、两个 store 的逐字节合成、同一 byte 多 store 时最年轻者获胜；
4. 部分覆盖、unknown fill、非法 attr、older IO、load IO 屏障均 replay，且 cache/AXI/device
   event 为零；对应判定逐项做 compile-success mutation；
5. 非重叠 final PA allow；terminal store 不再阻塞；同拍 fill/terminal 只允许保守晚一拍；
6. 两路 query 同拍 asymmetric payload，覆盖 allow/forward、forward/forward 和 lane-local
   replay；交换 PA/token/decision wiring 的 mutation 必须被捕获；
7. forward response backpressure、flush/query、kill/query、tuple mismatch/token recycle；
8. integer/FP load 都经正常 bridge response sink，forward 不产生 AXI/cache admission；
9. full-top elaboration/lint与 fail-closed source checker证明 canonical hierarchy 两路完整接线、
   hit/miss/A-D 三条成功路径都汇合 query、legacy VA shortcut 在 dual mode 不参与判定。
10. older store 的地址/数据 operand 未 ready 时，dispatch SQ placeholder 已 valid 且 query
    必须判 replay并经exact retry handoff让出bank；删除 placeholder/unfilled census gate 的
    compile-success mutation 必须失败。
11. successful probe、ROB done/commit、AW/W fire 后而 B 尚未返回时，同地址 load 仍须
    forward 或 replay，绝不能 allow；只有 probe fault 或 exact B terminal 能解除 effect-pending。
12. forward decision 后长期阻塞 MIQ/WB/FP sink，并在期间改变/释放 SQ entry，held response
    payload 仍稳定且最终 exactly one response XOR drop；把 capture 错移到 response fire 或
    直接用 live SQ data 驱动 response 的 mutation 必须失败。
13. 原始 request fire 已在所选 bank 建立 exact MIQ residency；forward query 不额外 push，
    empty/full 伪造、删除 request-fire MIQ push、query 时重复 push、反向 bank push/pop 或
    允许 `S_SQ_QUERY/S_RESP` 无 exact head 的 compile-success mutation 必须失败。
14. bank0/bank1 同拍 forward 可以各自捕获并独立 backpressure；构造两个 issue owner 映射
    同一 bank 时，只允许 edge-old owner成为该 bank active query，另一 owner留在 reservation。
    交换 query face、允许单 bank 两 active owner或让 replay bank压低 peer bank的 mutation
    必须失败。
15. forward capture 后长期 backpressure 再 flush，必须禁止 killed WB/wakeup并产生本 bank
    exact drop；allow 后在 cache capture、NC/IO target capture、AR fire 前后分别 kill，均须
    满足 F2 target-specific response XOR drop 和 PID holder conservation。直接清 held Q、
    只屏蔽 WB、过早 pop MIQ或过早复用 PID的 mutation必须失败。
16. older unfilled same-bank store、younger load先到query replay；retry handoff必须exact pop
    MIQ并释放bridge，store ready后必须先完成probe/fill，load再以同token普通request fire重发
    并最终allow/forward。把replay改回原地hold、删除retry capture/pop、重复分配token或固定让
    retry压过older store的mutation必须失败。
17. retry slot有效时禁止第二个ordinary load进入本bank active/station，但older store probe、
    ROB-head drain仍能进入；两个bank可各持一个retry并独立推进。删除load admission fence、
    cross-bank slot接线、raw-index仲裁、peer replay压低本bankstore的mutation必须失败。
18. DTLB permission fault、PTW leaf fault、A/D write fault，以及每个pre-query state中的
    flush/kill和late response，均须证明request-fire MIQ entry最终exact exception response或drop；
    active直接clear不pop、late response命中新PID的mutation必须失败。
19. retry slot在global/selective kill时进入lossless tagged terminal collector并exact free；
    同拍retry capture/reissue/kill必须互斥且holder census连续。静默清slot、kill后重发或未把
    retry token纳入PID reuse fence的mutation必须失败。

P1 predecessor/closure evidence：F0、F1、F2 focused gate 在同一 post-source closure 下通过；
release 与 `OOO_ASSERT` 均通过；所有 mutation 必须“能编译且 focused gate 失败”，不能把语法错
冒充语义捕获。最终 manifest 明确 `architecture=RED`、`ppa=UNQUALIFIED`、
`promotion_eligible=false`。

## 4. 退出条件与声明边界

只有以下条件同一 closure 全部成立，才可登记
`claim=final_pa_sq_ordering_checkpoint`：

- 六类接口契约的 source check、release/assert directed simulation 全绿；
- P0 mutation 全部 compile-success 且非 vacuous；
- F0/F1/F2 predecessor 复跑全绿；
- 独立实现审查没有未解决 P0/P1 反例；
- task-run 记录 pre/post source hashes、命令、原始日志、结果 JSON 和 reviewer provenance。

reviewer provenance/dispatch log/checkpoint artifact 不进入 functional source closure，避免“记录
审查结果本身改变被审 closure”的自引用环；它们由 checkpoint artifact 以独立 SHA 绑定。
任何 run-id、candidate/result/mutation SHA、合同 SHA、reviewed closure、P0/P1 或
RED/unqualified 边界不匹配都必须拒绝 checkpoint，而不是静默复用其它 run 的 reviewer 回执。

这不等于 F4 sustained dual-load IPC，不等于完整 load-violation recovery，不等于 Linux/
full-system、formal、CDC/reset、综合/STA 或 PPA signoff。
