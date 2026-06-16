# 2026-05-29 OoO branch shadow prefetch

## Context

- Goal: continue moving the experimental OoO superscalar core toward full-program `CPI=0.5`.
- Current verified baseline: `NPC_OOO_ALU_EXPERIMENT=1` AM `cpu-tests/add` GOOD TRAP with `cycles=1150`, `commits=839`, `CPI=1.371`.
- Remaining profile bottleneck is unresolved branch stop-pending. A previous attempt that put branch prefetch responses into the normal FIFO was reverted because it broke precise control-flow ownership.

## RTL 推导摘要

### 需求

- While a dispatched branch is pending resolve, allow one predicted-path fetch request to be issued early.
- The predicted response must not enter the normal fetch FIFO until the branch resolve PC proves the prediction correct.
- If the prediction is wrong or the branch target is misaligned, discard the shadow response/outstanding request and preserve the existing precise redirect/trap behavior.
- This is not full branch speculation: no younger predicted-path instruction may dispatch before branch resolve, and no backend rollback is required in this increment.

### 协议规则

- Branch shadow prefetch uses the existing single outstanding fetch request slot.
- A prefetch request may fire only when `stop_pending_q && pending_branch_q && pending_branch_dispatched_q`, no old outstanding request remains, no stale response is being discarded, and no shadow prefetch is already active.
- Prefetch response is consumed while `stop_pending_q` is true, decoded with the same RVC packet decoder, and stored in a private one-packet shadow buffer.
- On branch resolve:
  - predicted PC matches and shadow buffer/current response is available: move the packet into the normal FIFO and resume without issuing a duplicate redirect fetch.
  - predicted PC matches but response is still outstanding: clear stop-pending and let the outstanding response enqueue normally after it returns.
  - predicted PC mismatches: discard shadow state and use the existing resolved redirect path.

### 状态机

- `IDLE`: no shadow prefetch active.
- `OUTSTANDING`: predicted fetch request has fired; response has not returned.
- `BUFFERED`: response returned and is parked in the shadow buffer.
- Resolve transition:
  - match + `BUFFERED` or same-cycle response -> normal FIFO gets one packet.
  - match + `OUTSTANDING` -> outstanding request becomes the normal post-resolve fetch response.
  - mismatch/trap/flush/reset -> shadow state is cleared.

### 不变量

- Shadow buffer contents are never visible to `dispatch*_valid` before branch resolve.
- At most one shadow packet exists because the fetch interface still has at most one outstanding request.
- A wrong predicted PC cannot leave any packet in the normal FIFO after resolve.
- Correctly matched shadow response preserves the decoded `pc/next_pc/packet_next_pc/resp` fields exactly as a normal fetch response would.
- Any direct frontend flush, global flush, trap, or branch resolve clears shadow metadata unless a matching outstanding response is intentionally carried into normal execution.

### 数据通路

- Add `branch_prefetch_active_q`, `branch_prefetch_buffer_valid_q`, `branch_prefetch_pc_q`, and one packet worth of shadow decoded fields.
- Add a static predictor for this conservative increment: backward branches predict taken; forward branches predict fallthrough.
- Extend fetch request mux priority: resolved/direct redirect, then branch shadow prefetch, then normal sequential fetch.
- Extend branch resolve mux so a shadow hit either fills FIFO from the shadow/current response or preserves the matching outstanding request.

## Validation

- Focused fetch-core regression: `/tmp/ysyx-ooo-branch-shadow-prefetch-tb/summary.txt` -> `total: 1`, `passed: 1`, `failed: 0`.
- Full module regression: `/tmp/ysyx-ooo-branch-shadow-prefetch-module/summary.txt` -> `total: 38`, `passed: 38`, `failed: 0`.
- Experimental OoO AM `cpu-tests/add`: `/tmp/ysyx-ooo-branch-shadow-prefetch-add.log` -> GOOD TRAP, `cycles=1086`, `commits=839`, `CPI=1.294`.
- Default non-experimental AM `cpu-tests/add`: `/tmp/ysyx-default-branch-shadow-prefetch-add.log` -> GOOD TRAP, `cycles=1509`, `commits=838`, `CPI=1.801`.
- Scoped whitespace check: `git diff --check -- npc/single/vsrc/ooo/OooAluFetchCore.v npc/single/testbench/tests/tb_ooo_alu_fetch_core.sv .github/task-runs/2026-05-29-ooo-branch-shadow-prefetch/task-report.md` -> PASS.

## Result

- Implemented and kept.
- This reduced the experimental AM `add` CPI from the previous `1.371` baseline to `1.294`.
- The full goal is still not complete: reaching full-program `CPI=0.5` still needs real backend speculation/checkpoint work beyond this one-packet fetch shadow.
