# v8t/F3 RTL 四段式推导

## 1. 行为需求与不变量

目标行为是让 canonical dual-memory load 在完成 Sv39/PMP/PMA/PBMT 后、进入任何
cache/AXI/device target 前，按最终物理字节地址查询所有更老、未 terminal 的 SQ
store。结果只有 `allow/forward/replay` 三种，且 query 不分配新 owner、不产生外部
side effect。两路 bridge 各自保持 owner 与 payload，SQ 提供两个独立读端口。

关键不变量：physical-byte equality 是 alias 的唯一判据；full ProducerId 是年龄/ABA
身份的唯一判据；typed class 决定普通 memory 与 IO 顺序；forward 仍走正式 bridge
response/MIQ/WB；flush/kill 优先于 query decision；replay通过exact bank-local retry
handoff释放bridge，再以同owner重新准入，不能原地占住其依赖的store progress资源。

dispatch 为每个 plain store 先建立 program-ordered SQ placeholder，故 unissued 或 operand
未 ready 的 older store 仍以 `valid && !filled` 出现在 CAM census。SQ 的 `filled` 沿原子
锁存 PA/class/mask/data；SQ `terminal` 仅表示 probe fault 的 no-effect，或 physical B 后的
global visibility，绝不等同 probe success、ROB done、commit 或 AW/W fire。

F2 的每次bank request fire在translation/query之前原子消费reservation/retry owner、push对应
bank MIQ expected tuple 并锁存该 bank bridge active Q。因此 F3 query/forward 不新增 MIQ
push：`S_SQ_QUERY -> S_RESP` 始终复用原bank-local entry，直至exact response XOR drop；
replay的唯一例外是同沿 `MIQ head -> retry slot` nonterminal handoff，后续普通request fire再push。
每个 bank bridge 只有一个 active transaction，每 bank 每拍也至多一个 request fire；两套
query face 是 bank0/bank1 face，而不是两个 owner 可在同一 bank 并发的 issue-lane face。

## 2. 状态、转换与组合方程

bridge 新增 `S_SQ_QUERY`。所有 successful ordinary-load final-PA paths 转入该态：

- station advance 中的 bare/DTLB-hit；
- PTW leaf 且无需 A/D update；
- A/D B success 后续 load。

fault、store probe、ordinary write、AMO 与 walk transport 不进入 query。

令 `Q` 为 requested byte mask，`C` 为被合法更老 store 覆盖的 byte mask，`O` 为
是否存在物理重叠，`P` 为 unknown/invalid/IO ordering poison：

```text
replay = query_valid && (P || (O && ((C & Q) != Q)))
forward = query_valid && !P && O && ((C & Q) == Q)
allow = query_valid && !P && !O
```

IO load 有任何更老非 terminal store 时令 `P=1`；无更老 store 时 `allow=1`。
查询 tuple 不精确时 backend 强制 `replay=1`但不允许retry handoff，bridge保持到exact owner
恢复或kill/drop。三结果在 query-valid 拍 one-hot。

`forward_data[8*l +: 8]` 由 head-to-tail 扫描中最后一个匹配
`store_paddr+s == query_paddr+l` 的 entry byte 覆盖，因而是每字节 youngest-older
store。`replay` 在retry slot无credit时保持状态；exact retry fire把MIQ完整head/full PID捕获进
本bank retry slot、pop MIQ并令bridge回到可服务态；`forward`捕获data进入`S_RESP`；`allow`对CACHED
同拍发 SRAM lookup 并转 `S_LOOKUP`，对 NC/IO 转入既有寄存 target state。

forward decision 的沿把 data/class/owner/fault provenance 原子捕获进 held-response Q；
decision 本身不 pop MIQ、不占 WB、不形成 terminal。后续 response valid/ready 走原有
credit DAG。allow 对 cache 的提交点是同步 macro lookup capture，对 NC/IO 的提交点是
registered target state；外部 AXI/device VALID 不在 decision 拍出现。跨 4KiB page 的
multi-byte access 已在 query 前本地异常，不从首字节 PA 推导后续页。

captured forward 后的 flush/kill 直接继承 F2 `S_RESP` 生命周期：architectural WB/wakeup
立即被 kill gate 禁止，held response snapshot、同 bank MIQ 与 tracker holder仍保留到 exact
drop0，且 response/drop 互斥。allow 后分别继承 `S_LOOKUP`、`S_READ_ADDR` 与
`S_DEVICE_WAIT` 的 cancel/hold/drain 规则；F3 不新增 owner release 或 PID recycle 点。

request fire后、query前的translation/PTW/A-D fault与kill也继承F2全状态conservation：local
fault必须形成exact response，已呈现transport按AR/AW/W协议drain后exact drop，任何active exit
都不能静默遗失MIQ/tracker holder。retry slot被kill时走新增的lossless tagged local drop，
它是owner terminal而不是MIQ retry pop。

## 3. 结构划分与关键路径

- `OooStoreQueue`：保存的 PA/data/strb/class 与 head order 是 CAM 真源；增加两套纯读
  query 组合块，不修改 alloc/fill/terminal/release 状态机。
- `OooIntBackend`：做两路 query tuple 的 tracker exact check、token->full PID 映射并把 SQ
  decision 回送；增加每bank一个exact retry slot、MIQ-to-slot pop/capture和edge-old
  re-admission；每次普通bank request fire建立对应MIQ entry，query不得重复push；
  canonical dual mode 关闭旧 issue-stage VA blind/forward gate。
- `OooMemAxiBridge`：增加 query state、active-Q query 输出、decision 输入和 target gate；
  forward 生成普通 held response。
- `OooDualMemBridgeWrapper` 与 core hierarchy：逐层机械透传两路 face；不得聚合。

SQ CAM 的 PA/data 输入与 bridge payload均为 Q。CAM 结果只进入 bridge next-state、
forward-data capture 和 cache lookup enable，不进入 SRAM address bits、request-ready、
owner allocation 或 AXI payload；因此不会把 wide compare 链接回发射/dispatch ready。

结构不变量还包括：bankN query只能匹配bankN bridge active Q和bankN MIQ head；同 bank 的
第二个 reservation owner仍在 request allocator 前等待，不能同时出现第二个 query。两个
bank 的 forward response各自使用已有 bank-local held response，随后才竞争全局 WB/terminal
credit，peer backpressure不得反向修改另一 bank query decision。

为使单retry slot可证明充分，本bank retry valid或active/station已有ordinary LOAD时，不再接受
第二个ordinary LOAD；store probe/SQ drain/head AMO不受此load-only fence。retry与store
reservation以edge-old full PID仲裁，older store先行；若无older store则retry可重发。holder
census在 `bridge+MIQ -> retry slot -> bridge+MIQ` 两个handoff沿均连续，token从不重分配。

## 4. RTL 映射、验证与反例

实现顺序：先加 SQ 双 query 与 unit vectors，再加 bridge query state及 hit/miss/A-D
汇合，再做 backend full-PID mapping与 canonical legacy-gate exclusion，最后逐层接线。

验证顺序：source checker -> SQ byte-CAM release/assert -> bridge hold/forward/hit/PTW
directed -> backend dual-query/identity/FP sink directed -> full-top lint/elaboration ->
compile-success mutation -> F0/F1/F2 predecessor。每个反例以 asymmetric address/token/data
构造，避免 swap/tie mutation 假绿；Icarus force/release 场景使用不同 full PID 并在场景间
reset，避免残值被误判为新行为。

除 byte-CAM 反例外，必须定向证明 original request fire -> exact bank MIQ enrollment ->
query -> held response -> response XOR drop 的 conservation；覆盖两个 bank 同拍 forward、
两个 issue owner落同 bank 时仅较老者成为 active query、forward capture 后 flush exact drop，
以及 allow capture 在 cache/NC/IO 各 target boundary 前后的 kill。对应 compile-success
mutation包括删除/重复/反向 MIQ push-pop、同 bank 两 active、直接清 held response、只屏蔽
WB但不 drop，以及过早 PID reuse。

progress证据必须构造older unfilled same-bank store与younger replay load：load先进入query后
exact yield，store随后从IQ/reservation进入同bank完成fill/drain，load用同token重发并完成；同时
覆盖每bank一个retry、retry期间禁止第二load但允许store、retry slot selective/global kill、
translation/PTW/A-D fault与kill conservation。原地hold、静默MIQ pop、重复token allocation、
retry固定高优先级和“恢复所有load盲阻塞”都必须有compile-success mutation。

任何一个 query 路径未覆盖、mutation 仅因编译失败、或 reviewer 发现未解决的 P0/P1，
本节点只能保持 candidate，不得扩张到 DI-5/OOO-3/PPA 结论。focused runner 对功能 RTL、TB、
checker、mutator、proof、spec/contract 计算稳定 functional source closure；review disposition
作为独立 SHA overlay 绑定同一 closure。只有合同 SHA、38/37 mutation、11 profiles、holder proof、
F0/F1/F2、P0/P1 空集和 `architecture=RED/PPA=UNQUALIFIED/promotion=false` 全部精确匹配时，
promotion-only finalizer 才为同一 run-id 生成独立 `final_pa_sq_ordering_checkpoint` artifact。
它必须同时绑定 candidate result 与 mutation-summary 的 SHA，且不得覆盖被审 candidate；任何
stale/wrong-run reviewer overlay 都 fail-closed。
