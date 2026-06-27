# OooFetchFlowControl Boundary Spec

## 1. Requirement

`OooAluFetchCore` owns many front-end policies.  The request/response
ready-valid equations are pure combinational flow control and can be separated
from PC sequencing, outstanding response tracking and redirect recovery state.

`OooFetchFlowControl` extracts only the handshake policy:

- decide whether a fetch request is valid;
- decide whether a fetch response is ready;
- derive response fire, enqueue, bypass-consumed and FIFO-storage pop;
- report whether a normal sequential request may issue.

The parent keeps ownership of all state: `next_fetch_pc_q`,
`outstanding_valid_q`, `outstanding_pc_q`, `discard_fetch_rsp_q`, redirect PC
selection, branch prefetch state, precise trap/drain state and FIFO storage.

## 2. Interface Contract

Inputs are already-decoded predicates from the parent:

- request sources: redirect, branch prefetch and normal sequential issue;
- request blockers: trap/serial flush, stop-head, response-control-stop,
  discard flag and FIFO reserve;
- response conditions: response valid, outstanding present, FIFO count/depth,
  FIFO pop, dispatch bypass, direct frontend flush, drop conditions.

Outputs:

- `fetch_req_valid_o`, `fetch_req_fire_o`;
- `fetch_rsp_ready_o`, `fetch_rsp_fire_o`;
- `can_issue_request_o`;
- `fifo_storage_pop_o`, `fifo_can_accept_rsp_o`;
- `fetch_rsp_can_enqueue_o`, `fetch_rsp_can_drop_o`;
- `direct_fetch_drop_o`, `fetch_rsp_bypass_consumed_o`,
  `fetch_rsp_enqueue_o`.

The module does not select `fetch_req_pc_o`, does not update `next_fetch_pc`,
does not modify outstanding/discard state, and does not inspect instruction
contents.

## 3. State Machine

There is no internal state.

Combinational ordering mirrors the old equations:

1. `fetch_rsp_fire_o = fetch_rsp_valid_i && fetch_rsp_ready_o`.
2. Normal request issue requires run, no stop-head, no current response control
   stop, no discard, FIFO reserve and either no outstanding response or a
   same-cycle response fire.
3. Request valid is true when trap/serial blockers are clear and any request
   source is active: redirect, branch prefetch or normal issue.
4. Response ready is true when it can enqueue, bypass, drop or direct-drop.
5. Enqueue requires valid response, enqueue allowance, no direct drop and no
   bypass-consumed path.

## 4. Invariants

- `fetch_req_fire_o` is gated by the module's own `fetch_req_valid_o`.
- `fifo_storage_pop_o` is false for same-cycle dispatch bypass packets; bypass
  consumption is reported separately.
- `fetch_rsp_enqueue_o` is false when a response is directly dropped or consumed
  by dispatch bypass.
- FIFO accept allows a pop in the same cycle to make space even when count is
  at depth.

