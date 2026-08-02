# RV64 performance counter schema v4

本契约冻结一组“守恒但仍为局部”的双退役观测计数。一级账本先按完整 `ProducerId`
拆出 dependency、issue-terminal、execution-latency 与 memory-latency；memory-latency 再通过
exact owner token、双 memory bridge 的注册 FSM 状态和 LQ terminal 记录拆成六个互斥
holder-residency 子桶；其中 `memory_request_outstanding` 继续用独立子账本区分 cache、device
与 AXI phase。它不把既有 fetch/memory/hazard 重叠计数包装成可相加的全核因果 CPI 栈。

观测源仅在 `NpcSimTop.sv` 通过 XMR 读取 edge-old ROB、整数/FP IQ sticky-ready、
`OooMemOwnerTracker` 的 live token/ProducerId table、后端 registered holder mask、
`OooMemAxiBridge` lane0/lane1 的 station/active token 与 `state_q`，随后由
`cpu-exec.cpp` 的 DPI 累加器计数。观测值不进入 production core 的 ready、valid、
payload、flush 或状态输入，因此本轮不改变 elaborated DUT 的执行语义和 PPA 锥。

## 周期、槽与嵌套子账本守恒

周期只归入一个一级桶：本周期至少退休一条指令时归入 `cycle_useful`，否则继承 lane0 的唯一
阻塞原因。所有一级周期桶之和必须等于 `end_cycle-start_cycle`。

槽区间采用 committed-marker 半开语义：从 start marker 提交前，到 end marker 提交前。
精确容量为：

```text
slot_capacity = 2 * (end_cycle - start_cycle) + end_lane - start_lane
```

宿主累加器的完整周期差覆盖 `S+1..E`；槽账本再加上 start 周期的
`start_lane..1`，并减去 end 周期的 `end_lane..1`。同周期 lane0→lane1 的周期差为 0，
但区间容量和退休数均为 1。request-detail 槽账本执行相同端点修正，因此不会只校正一级 reason
而使嵌套 aggregate 漂移。

当前 baseline 仍要求 `start_lane == end_lane`，从而严格恢复
`slot_capacity = 2 * cycles`。不同 lane 相位的窗口可输出精确诊断，但不能取得基线资格。

## ROB-head 与 memory owner 生命周期

一级原因编码和完整优先级以 `performance-counter-schema-v4.json` 为规范。对 `done=0` 的 ROB
head，先查整数/FP IQ 中相同 full-`ProducerId` 的 resident entry：任一 enabled source 的
sticky-ready 为 0 时归 dependency，全部 ready 时归 issue-terminal。离开两个 IQ 后，
memory 仍优先于 execution，以覆盖 FP load 同时保留 FP completion identity 的合法重叠。

memory head 通过 `OooMemOwnerTracker.live_mask` 与 `producer_id_table` 反查零或一个 exact
token。一个 head 命中多个 token 是断言失败。六个互斥子桶按以下优先级选择：

1. `memory_response_terminal`：bridge `S_RESP`、collector accepted/pending terminal，或 exact
   LQ entry 已记录 `terminal_seen`；
2. `memory_translation_order`：bridge `S_WALK_AR/S_WALK_R/S_AD_UPDATE/S_SQ_QUERY`；
3. `memory_request_outstanding`：bridge `S_LOOKUP/S_DEVICE_WAIT/S_READ_ADDR/S_READ_DATA/
   S_WRITE_REQ/S_WRITE_RESP`；
4. active bridge state 未被本版本识别时直接归 `memory_lifecycle_unknown`；
5. `memory_retry`：registered retry0/retry1 holder；
6. `memory_reservation_queue`：reservation/buffer/MIQ/bridge station/SQ owner/AMO pending/
   request-fire/birth holder，或尚无 token 的 exact LQ/reservation residency；
7. 仍未解释的 memory resident head 归 `memory_lifecycle_unknown`。

该优先级解决同拍 holder handoff 的合法重叠；桶名表达 edge-old 驻留事实，不单独证明该 holder
是全部归属周期的排他因果根源。分类不使用 opcode 推测，也不新增 scoreboard。

## Request-outstanding 子账本

request detail 使用独立 3-bit 编码，不扩大或重排已经验证的 4-bit 一级 reason：

- `none`：一级 reason 不是 request-outstanding，不进入嵌套计数；
- `cache_lookup`：`S_LOOKUP`；
- `device_wait`：`S_DEVICE_WAIT`；
- `axi_read_address`：`S_READ_ADDR`；
- `axi_read_data`：`S_READ_DATA`；
- `axi_write_request`：`S_WRITE_REQ`；
- `axi_write_response`：`S_WRITE_RESP`；
- `unknown`：一级 reason 已是 request-outstanding，但没有一个版本化的单 bridge state 映射。

SV 断言要求 detail 非 `none` 当且仅当一级 reason 为 request-outstanding，并继续要求同一 exact
token 不能同时 active 于两个 bridge。宿主累加器再次验证该绑定；越界、缺失或非 request reason
携带 detail 都增加 `invalid_events`。cycle/slot 的七个非 `none` detail 之和必须分别等于对应
`memory_request_outstanding` aggregate。

`cycle_memory_latency`/`slot_memory_latency` 作为兼容聚合值保留，必须分别等于六个 memory
子桶之和。`cycle_head_not_complete`/`slot_head_not_complete` 也保留，并必须等于 dependency、
issue-terminal、execution-latency、memory-latency 与 head-lifecycle-unknown 之和。

`memory_request_detail_unknown`、`memory_lifecycle_unknown`、`head_lifecycle_unknown` 与
`unknown` 都参与 fail-closed unknown ratio，不能丢弃或重新分摊。资格检查还要求
`complete=1`、`available=1`、`overflow=0`、`invalid_events=0`、三个 aggregate 绑定与总账守恒。

## 当前结论边界

本契约状态为 `PARTIAL_CONSERVING_MEMORY_REQUEST_DETAIL_V4`。它已经形成互斥周期账本、双退役
lost-slot 账本、ROB-head lifecycle 子账本、memory owner/holder 子账本和 request phase 子账本，
但 `memory_reservation_queue` 仍合并 reservation、MIQ admission、bridge station 与 queue fallback；
`cache_lookup` 仍不等于排他的 cache-array 因果延迟。`rob_empty`、issue-terminal、全局 integer/FP
issue-slot 容量和 region-bound occupancy histogram 也仍是后续缺口。因此它是可审计的 CPI 优化
定位层，不授予完整因果 CPI 或性能基线资格。旧 v1/v2/v3 JSON 保留为 v5/v6/v7 历史证据的
不可变解释器。
