# OooFetchFlowControl Boundary Spec

> **T3V 状态**：原 dispatch-bypass 在生产配置结构性不可达，但保层级综合仍保留其 mux。
> 现已从 RunGate、FlowControl 与 HeadMux 物理删除；response 只可 enqueue、drop 或 direct-drop。

## 1. Requirement

`OooFrontend`（原 `OooAluFetchCore`，已重构删除）owns many front-end policies.  The request/response
ready-valid equations are pure combinational flow control and can be separated
from PC sequencing, outstanding response tracking and redirect recovery state.

`OooFetchFlowControl` extracts only the handshake policy:

- decide whether a fetch request is valid;
- decide whether a fetch response is ready;
- derive response fire, enqueue and FIFO-storage pop;
- report whether a normal sequential request may issue.

The parent keeps ownership of all state: `next_fetch_pc_q`,
`outstanding_valid_q`, `outstanding_pc_q`, `discard_fetch_rsp_q`（现由子模块
`OooFetchPcOutstandingSequencer` 持有）, redirect PC
selection, branch prefetch state, precise trap/drain state and FIFO storage.

## 2. Interface Contract

Inputs are already-decoded predicates from the parent:

- request sources: redirect, branch prefetch and normal sequential issue;
- request blockers: trap/serial flush, stop-head, response-control-stop,
  discard flag and FIFO reserve;
- response conditions: response valid, outstanding present, FIFO count/depth,
  FIFO pop, direct frontend flush, drop conditions.

Outputs:

- `fetch_req_valid_o`, `fetch_req_fire_o`;
- `fetch_rsp_ready_o`, `fetch_rsp_fire_o`;
- `can_issue_request_o`;
- `fifo_storage_pop_o`, `fifo_can_accept_rsp_o`;
- `fetch_rsp_can_enqueue_o`, `fetch_rsp_can_drop_o`;
- `direct_fetch_drop_o`, `fetch_rsp_enqueue_o`.

The module does not select `fetch_req_pc_o`, does not update `next_fetch_pc`,
does not modify outstanding/discard state, and does not inspect instruction
contents.

## 3. State Machine

There is no internal state.

Combinational ordering mirrors the old equations:

1. `fetch_rsp_fire_o = fetch_rsp_valid_i && fetch_rsp_ready_o`.
2. Normal request issue requires run, no stop-head, no current response control
   stop, no discard, no same-cycle direct frontend flush（F2 新增：flush 拍
   `next_fetch_pc_q` 仍是旧值，须在源头封死顺序取指臂）, FIFO reserve and either
   no outstanding response or a same-cycle response fire.
3. Request valid is true when trap/serial blockers are clear and any request
   source is active: redirect, branch prefetch or normal issue.
4. Response ready is true when it can enqueue, drop or direct-drop.
5. Enqueue requires valid response, enqueue allowance and no direct drop.

## 4. Invariants

- `fetch_req_fire_o` is gated by the module's own `fetch_req_valid_o`.
- `fifo_storage_pop_o == fifo_pop_i`；不存在 response bypass 对 storage pop 的分流。
- `fetch_rsp_enqueue_o` is false when a response is directly dropped.
- T3U 起 FIFO response credit 只读取寄存的 `fifo_count_i < fifo_depth_i`，
  禁止把本拍 `fifo_pop_i` 组合 look-through 成本拍 response-ready。系统级承重
  不变量是 `fifo_count + outstanding <= depth`：当存在 outstanding response
  时 FIFO 不可能已经满，因此旧 full+pop 旁路只覆盖非法状态、没有合法吞吐收益；
  删除它同时切断 FIFO head/decode/backend-ready 经 pop 返回 request/next-PC 的长链。
- 若 response 因容量反压，T3R `OooFetchAxiBridge.S_RESP` 必须保持 valid 与完整
  payload；寄存 count 在 pop 后下降的下一拍再接收，不得丢包或重复。
