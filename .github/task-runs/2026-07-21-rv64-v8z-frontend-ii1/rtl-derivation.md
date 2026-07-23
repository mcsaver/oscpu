# V8Z DI-1 RTL 推导与事务守恒图

## 工程与声明边界

本推导只覆盖本地 RV64 Verilog/SystemVerilog 处理器的 cache-hit 取指包路径：`OooFetchAxiBridge`、`OooFrontend`、`OooFetchFlowControl`、`OooFetchPcOutstandingSequencer`、`OooFetchPacketDecode`、`OooFetchPacketFifo` 以及真实 rename/dispatch/backend sink。目标是证明预热后的 packet initiation interval 为一拍，并闭合阻塞恢复和尾部事务守恒；不覆盖 DI-2 全流水宽度连续性、cache miss 性能、redirect 性能、overall architecture 或 PPA。

## 请求、响应与 sink 调用链

```text
request PC owner
  -> OooFrontend / OooFetchRequestMux
  -> OooFetchFlowControl.fetch_req_fire_o
  -> OooFetchPcOutstandingSequencer.outstanding_valid_q + owner PC
  -> OooFetchAxiBridge registered lookup token
  -> S_CACHE_READ (H1 result window)
  -> cache_hit_resp_w / fetch_rsp_fire_w
  -> OooFetchFlowControl.fetch_rsp_enqueue_o
  -> OooFetchPacketDecode
  -> OooFetchPacketFifo registered entry
  -> fifo_storage_pop_w
  -> rename / dispatch / backend
```

`OooFetchAxiBridge` 只在已注册的 `S_CACHE_READ` H1 窗口把 SRAM/ITLB/PMP 结果解释为 cache-hit response。该 response 被接收时，同一拍允许 successor request；状态在 closing edge 回到下一次 `S_CACHE_READ`。若下游未 ready，则 payload 进入既有 `S_RESP` registered skid owner，valid 和 payload 保持到 fire。

完整 frontend 的 recurrence 不是只看 Bridge leaf：`OooFetchFlowControl` 同时要求 `fifo_reserve_available_i`，且只有 `!outstanding_valid_i || fetch_rsp_fire_o` 时才允许下一 request。`OooFetchPcOutstandingSequencer` 在 response 与 successor request 同拍 fire 时保留一个新的 outstanding owner，因此 steady window 内每拍完成旧 owner、建立新 owner，而不会产生空拍或两个 owner。

## Stateful-holder census

| 层级 | holder / source-of-truth | 建立条件 | 释放或替换条件 |
| --- | --- | --- | --- |
| Bridge lookup | request-fire 对应的 registered H1 candidate/context | `fetch_req_fire_w` | H1 closing edge；hit turnover 可同时装入 successor candidate |
| Bridge response skid | `S_RESP` 及其 registered response payload | H1 response 未被接收或 slow path 完成 | `fetch_rsp_fire_w`；可同时接收 successor request |
| Frontend request owner | `outstanding_valid_q` 与 owner PC | `fetch_req_fire_i` | response fire 无 replacement 时清除；同拍 replacement 时保持 valid 并更新 owner |
| Packet storage | `OooFetchPacketFifo` registered entry | `fetch_rsp_enqueue_w` | `fifo_storage_pop_w` |
| Backend owners | ROB / issue-queue / physical-register allocation | FIFO packet 被真实 dispatch | retirement/drain；focused epilogue 要求全部归零 |

关键容量不变量为 `fifo_count + outstanding_count <= FIFO depth`。每个合法 outstanding request 在产生 response 前已预留一个 FIFO slot，因此存在 outstanding response 时，FIFO full 不是合法可达状态。由此，commit stall 会在下一 request 发出前耗尽 reserve；验证阻塞点选择 `run_i=0`，用于覆盖真实 outstanding response 的 valid/payload/owner 保持和恢复，而不是构造违反容量合同的 full-FIFO 状态。

## 独立事务账本

focused testbench 使用两个互不复用 fire 计数的 PC ledger：

1. request ledger 在 request fire 时记录 PC；response owner 到达时必须与队首 request PC 完全相同。
2. FIFO ledger 在 response enqueue 时记录 decode packet PC；真实 FIFO dequeue 时必须与队首 enqueue PC 完全相同。
3. 同拍 successor request PC 必须等于当前 response owner 的 `packet_next_pc`；本测试的双 32-bit 整数 NOP packet 因而要求 `successor_pc = owner_pc + 8`。

这三个关系把 accepted request、response、enqueue 和 produced packet 分成独立观测点，避免用同一个 response-fire 信号重复命名为多个吞吐指标。

## 动态证明窗口

- assert 与 release 各自独立运行 Bridge 和完整 Frontend focused 配置。
- Bridge bare 与 paged 上下文都完成 64 个连续 H1 response + successor-request turnover，并覆盖 elastic skid replacement。
- 完整 Frontend 在预热后的连续 64 拍中得到 `accepted=responses=enqueues=dequeues=64`、`max_ii=1`、`sequential=64`、`redirects=0`、`stalls=0`。
- 阻塞子段在真实 outstanding response 上令 `run_i=0` 四拍，要求 valid、owner 和双 lane payload 稳定，同时禁止 response fire、重复 enqueue 和 replacement request；解除后连续完成 16 次 turnover。
- epilogue 只关闭外部 successor admission，继续允许尾 response、FIFO 与 backend 排空；最终 `requests=responses=enqueues=dequeues=83`，outstanding/FIFO/ROB/IQ/ghost 为零，free-list count 回到 32。

## Compile-success RTL 验证变异矩阵

这里的 mutation 仅指在临时副本中对本地处理器 RTL 施加单点验证变异，以确认动态 oracle 能拒绝指定错误；生产 RTL 源文件 pre/post 不变。

| 变异 | 被切断的本地 RTL 合同 | 主要 oracle 维度 |
| --- | --- | --- |
| `bridge_h1_ready_cut` | Bridge H1 response/next-request ready recurrence | accepted、produced、II |
| `bridge_h1_state_turnover_cut` | Bridge H1 closing-edge state replacement | produced、II |
| `bridge_semantic_lookup_cut` | 真实 cache semantic lookup qualification | produced |
| `flow_outstanding_turnover_cut` | FlowControl response-fire 后 successor admission | accepted、II |
| `flow_enqueue_credit_cut` | response enqueue 的 FIFO credit | produced、II |
| `sequencer_replacement_clear` | response+request 同拍时 outstanding owner replacement | accepted、produced |
| `sink_dequeue_cut` | registered FIFO 到真实 sink 的 dequeue | produced |
| `successor_pc_old_owner` | response owner 到 successor PC 的身份递推 | PC ledger |
| `blocked_response_tail_ghost` | 阻塞 response 的尾部 owner 清除 | backpressure recovery、final conservation |

九项变异均 `compile_rc=0`，且均由对应仿真 oracle 以非零退出拒绝；`production_sources_unchanged=true`。

## 同一设计与发布边界

最终 suite `v8z-di1-20260721T082600Z-1762933` 绑定完整 145-file RTL `design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。29 项 proof-source 清单在运行前后逐字相同，56 项 provenance 与 frontend gate log 受精确哈希约束。发布 `frontend_ii1` 前后的七个 sibling record 逐项不变并绑定同一 design_id。

因此只允许声明 DI-1 scoped GREEN。DI-2 仍为 RED，overall architecture 仍为 RED，PPA 仍为 UNQUALIFIED，`promotion_eligible=false`。
