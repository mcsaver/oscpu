# v8u/F4 RTL derivation

## 1. Microarchitecture decomposition

当前 bank-local datapath含 backend reservation、MIQ、bridge station和active transaction。
D-cache为同步单读端口，本身可每拍启动 lookup。leaf TB首先暴露 bridge在每个 owner上串行
占用独立 `S_SQ_QUERY` 状态；production trace随后证明 reservation又禁止 consume/capture同沿
turnover，使 MIQ无法形成相邻 owner。完整最小修复因此包含两个相邻弹性级的逐拍 turnover：
reservation Q 精确发出 A 的同沿捕获 B，以及 bridge active A正式退休的同沿把 station B视为
下一拍 current head，提前完成 B的精确顺序查询与 cache read capture。

### 1.1 production counterexample

在第一遍顺序执行预热128个 I-cache packet并提交回环 JAL后，从双 bank各8次 D-cache hot-hit
之后无条件记录64拍。原 reservation逻辑得到每 bank仅16次
`AGU -> translation -> SQ query -> cache lookup -> completion`，固定为每四拍一对，MIQ next
face从未持续有效。进一步cone trace显示F3 `active_load || station_load` admission fence即使在
bridge具备真实station READY时也禁止下一请求。这两份失败日志保留为反例，不能被后续 PASS
覆盖或删除。

## 2. State and next-state table

| current | current terminal | station B | B next exact | B SQ decision | next state | lookup |
| --- | --- | --- | --- | --- | --- | --- |
| `S_LOOKUP` hit | response fire | cached/final-PA | yes | allow | `S_LOOKUP(B)` | B |
| `S_LOOKUP` hit | response fire | cached/final-PA | yes | forward/replay | F3 normal B state | none |
| `S_LOOKUP` hit | stalled | cached/final-PA | yes | allow query may remain visible | hold A | none |
| `S_LOOKUP` miss | none | any | any | any | existing refill/AXI | none |
| any | flush/kill | any | any | any | existing drop/flush | none |

“F3 normal B state”由 station 的 translation/fault/class事实选择，ordinary final-PA load进入
`S_SQ_QUERY`；其它类型沿原状态机，不复制 classification。

## 3. Combinational DAG

```text
IQ registered pair C/D + old reservation A/B dual consume -> A/B request from Q + C/D atomic capture to Q
MIQ current head + response tuple + tracker -> current exact response candidate
MIQ next head + tracker table      -> next full ProducerId exactness
bridge station final-PA Q          -> next SQ query CAM
current exact response candidate   -> query presentation (independent of READY)
current exact response_fire
  AND next exact
  AND SQ allow
  AND no flush/kill                -> D-cache lookup enable + station fast promotion
```

reservation turnover只允许“双 old-Q精确 consume + registered IQ pair + 双 tracker credit”控制原子
pop2/capture2；单 lane consume不开放 turnover。request payload和identity仍完全来自old Q，new IQ
payload只进寄存器。禁止 raw IQ payload -> request、`SQ decision -> rsp_ready`、`next face -> MIQ pop`、
`station request bus -> lookup` 和跨 bank组合依赖。READY-low允许只读 query保持，cache lookup enable
仍必须由 response fire限定；SRAM address始终由已锁存 station PA驱动。

## 4. Sequential ownership proof obligation

edge前：A恰为 current MIQ head和 bridge active，并由 tracker token表还原出与 MIQ ROB字段
一致的 full `ProducerId`；B恰为 MIQ next head和 bridge station。
edge上：A response_fire只 pop A；bridge同时把 B station Q复制到 active Q；B的 MIQ entry与
tracker token保持 resident/live。若 request bus同拍接受 C，station在同一沿写入 C而不是被
stage advance清空。edge后：B自然成为 current head，D-cache返回的同步结果与 B active Q对应。
若任何 exactness条件不成立，禁止 fast lookup，B只能走原 F3序列。

若 A response exact candidate成立但 READY-low，B的只读 SQ query仍可由同一 edge-old station/MIQ/
tracker tuple稳定展示；A不 pop、B不发 lookup也不提升。将 query qualification从 `response_fire`拆成
不含 READY 的 exact candidate，消除了
`MIQ pop identity -> rsp_ready -> station query -> replay/retry -> MIQ pop`组合反馈；状态改变仍由
READY-qualified fire统一封闭。

每个 bank的同步 D-cache lookup无 ready信号，`lookup_en`即真实 capture。两个 bank各有
独立 MIQ和独立 pop端口，因此“每 bank一次 pop”允许 aggregate同拍两次，不引入跨 bank仲裁。

## 5. Implementation order

1. MIQ导出组合 next-head只读 face并补单元测试；
2. backend reservation增加 exact consume/capture turnover，补 payload/kill/stall断言；
3. backend增加 current-pop-qualified next identity选择，lookahead retry credit固定关闭；
4. bridge增加 station final-PA query face选择和 allow-qualified同步 lookup fast path；
5. wrapper/core glue贯通两 bank独立信号；
6. 加断言、release runner、64-cycle metrics和compile-success mutations；
7. 刷新 same-design architecture manifest、系统 aggregate和独立 review。

## 6. Pending questions resolved by evidence

- 若 next face暴露payload过宽导致明显时序回归，只能在保持 exact owner/kill证明的前提下缩窄，
  不得退化为 token-only近似。
- 若 actual full-core trajectory无法稳定构造，允许新增专用 integration harness，但必须实例化
  production backend、双 bridge、MIQ和D-cache路径；两个独立 leaf TB不能拼成 DI-5证据。
- 若 64-cycle trace前有warm-up，只能从所有 bank进入steady-state后的明确边界计数，并保留
  warm-up原始日志；不得从窗口中删除 stall周期。
