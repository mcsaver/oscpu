# v8s/F2 canonical 双 memory RTL 推导

## 阶段 1：需求

- 在 reusable hierarchy 默认关闭的前提下，让 canonical `NpcCoreTop` 显式启用两条 ordinary
  memory admission/response 路径。
- 两个 captured reservation 在不同 bank 时可同拍发射，在同 bank 时按 edge-old ROB head
  distance 只发较老者；每个 owner 只被自己的 local terminal 或 request fire 消费。
- 两个 bank 各有独立 MIQ、expected identity、ROB-open query、bridge response/drop/residency；
  全局共享 WB、SQ terminal/fill 和 terminal pending set 必须一次分配、不可各自猜 free count。
- 保持 ordinary store probe 与物理写权限分层；bank0 继续承载 SQ drain 和 LEGACY
  AMO/LR/SC singleton，bank1 只承载 ordinary LOAD/PROBE。
- F2 不实现 final-PA SQ query/forward/replay、64-cycle IPC/system gate、等总容量双 bank 或 PPA
  晋级；唯一候选结论为 `architecture_checkpoint`。

## 阶段 2a：协议规则

- Request：`valid && ready` 才产生对应 MIQ push；captured address、bank 与完整 owner tuple 在
  backpressure 下稳定。bank 使用 canonical byte address `addr[3]`。
- Response：只有 bank-local MIQ head、tracker tuple 与独立 ROB-open query 精确匹配，且拿到
  terminal/SQ/WB 所需全部 grant 时才 ready/fire。
- Drop：flush/kill 可先切断架构副作用，但 transport/tracker identity 保留到 exact response 或
  exact bridge drop；response 与 drop 对同一 token 互斥。
- Singleton：AMO/LR/SC launch 仅在两 MIQ edge-old 均空时成立，并在同拍优先于两 bank
  ordinary admission；final response release 拍仍按 edge-old LEGACY live 阻断 ordinary。

## 阶段 2b：状态机与更新优先级

- 两个 reservation Q 独立使用 `reset/global restore > selective kill > consume > capture > hold`。
- 两个 MIQ 复用既有 FIFO 状态机但实例独立；full flush 清 speculative MIQ，bridge 已接受 owner
  通过 drop 终结。
- LEGACY/SQ/bridge FSM 保持既有状态；F2 只改变 admission/global sink allocation，不新增对
  physical write 的授权来源。

## 阶段 2c：不变量

- 同一 captured owner 不能同时 local-complete 与 external-grant；一个 token 不能同时驻留两 MIQ。
- 同 bank 双候选只允许 edge-old 较老者；ROB raw index 跨零时仍以环形 distance 判定。
- mem0/mem1 同拍 formal completion 必须占不同 WB slot，且不能与 edge-old EX0/EX1 重叠；
  两槽都被 EX 占用时两 response 必须保持，释放后 exactly once 恢复。
- terminal collector 是 32-token pending set；10 ingress 的合法不同 token 同拍原子并入，
  duplicate/nonlive/mismatch fail closed。
- ordinary store 永远只发 probe；physical write 只来自 SQ drain 或合法 LEGACY path。
- kill/flush 后被取消的 ordinary owner不能产生 WB/SQ fill/cache side effect，但 identity 不得早释。

## 阶段 2d：数据通路

```text
reservation0/1 Q
  -> captured addr[3] + ROB-distance allocator
  -> bank0 request / bank1 request
  -> MIQ0 / MIQ1
  -> OooDualMemBridgeWrapper lane0 / lane1
  -> bank-local response + exact identity/open checks
  -> one global WB/SQ/terminal allocator
  -> WB0/WB1 + SQ fill/terminal + 32-token pending set
```

`NpcCoreTop -> OooCoreTopGlue -> OooExecuteBackend -> OooAluCoreSlice ->
OooAluDecodeBackend -> OooIntBackend` 逐层传递默认关闭的 `ENABLE_DUAL_MEM`；只有 canonical
`NpcCoreTop` 置 1。wrapper 内两个 bridge 只在 raw AXI miss fabric 汇合。

## 阶段 2e：拓扑自审

- 复制：MIQ、ROB completion-open query、完整 bridge station/DTLB/D-cache/FSM、response/drop face。
- 共享：两个 formal WB slot、SQ fill/terminal ports、terminal pending set、bank0 singleton 与最终
  AXI miss fabric；共享点都有单一全局 allocator 或 registered owner。
- 关键路径候选：reservation bank/age selection 到 request valid，以及两个 bank response exact
  classification 到 terminal/SQ/WB grant；未增加 response-ready 到 request-valid 的反向组合路径。
- 复位/恢复：新增 state 与既有同步高有效 reset 域一致；full flush 对 speculative MIQ 与不可撤销
  bridge/SQ owner 的处理分层。

## 阶段 3：RTL 映射与实战纠偏

- `OooIntBackend.v` 增加第二 MIQ、mem1 face、bank/age allocator、双 response global WB、双 SQ
  fill/terminal、10-ingress collector 和跨 bank holder/disjoint assertions。
- `OooRob.v`/`OooDispatchBackend.v` 增加 completion7 query；decode/slice/execute/glue/core 逐层接线；
  `NpcCoreTop` 用一份 `OooDualMemBridgeWrapper` 替代旧单 bridge；`NpcSimTop` 增加双路观测。
- Reviewer 反例被转成真实门：新增 ROB head=15、raw 15/0 的 same-bank age directed case；新增
  EX0/EX1 同时占满 WB0/WB1 时双 response hold/recovery；两者在 release/assert 下通过并由
  marker-removal checker mutation 承重。
- F1 前置门从“永久禁止 canonical wrapper”改为精确识别 `F1_UNINTEGRATED` 或
  `F2_PROMOTED`，并要求 F2 contract/spec handoff；F2 runner fresh 调用 F1 永久 target。

## 结论边界

本推导与同 closure 验证只支持 `architecture_checkpoint`。DI-5、OOO-3、overall 仍 RED，PPA
UNQUALIFIED，promotion=false；F3/F4 仍是下一阶段任务。
