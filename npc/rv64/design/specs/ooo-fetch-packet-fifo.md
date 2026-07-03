# OooFetchPacketFifo Boundary Spec

> ⚠️ **状态(2026-07-03 RTL 重读)**：模块本体存活（enqueue/pop/clear/head 通路是取指主路径）；
> 但 **seed 通道当前恒不触发**——上游 `OooFetchPacketSeedMux` 的全部 set_seed 臂
> （fallthrough capture / branch-prefetch hit / JALR-prefetch hit）在
> `OOO_ROB_WALK_MODE=1'b1` + `BRANCH_APPEND_DISPATCH_ENABLE=1'b0` 下判死，
> `seed_valid_i` 恒 0；拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 1. Requirement

`OooFrontend`（原 `OooAluFetchCore`，已重构删除）previously owned fetch packet FIFO pointers, count and packet
storage directly.  The inline FIFO mixed packet storage with redirect, branch
prefetch, JALR prefetch, CSR trap and precise drain control.  This made the
front-end boundary difficult to audit.

`OooFetchPacketFifo` extracts only the packet storage primitive:

- store one fetch packet containing two decoded instruction slots;
- expose the current head packet to the parent;
- accept normal enqueue/pop actions from the parent;
- accept a clear-to-empty action from the parent;
- accept a seed-one-packet action used by redirect recovery when an already
  captured response is promoted to the normal FIFO.

The parent keeps ownership of fetch request/outstanding tracking, response
bypass, redirect priority, branch/JALR prefetch hit selection and precise
exception policy.

## 2. Interface Contract

Inputs:

- `enqueue_i`: writes the enqueue packet at the current tail.
- `pop_i`: advances the head when the parent consumed a stored packet.
- `clear_i`: clears pointers/count and makes the FIFO empty.
- `seed_valid_i`: clears old contents and writes exactly one packet into slot 0.
- `*_i` packet fields: PC, next PC, instruction and response code for both
  lanes plus packet next PC.

Outputs:

- `count_o`: number of valid stored packets, range `0..2^FETCH_PACKET_COUNT_W`.
- `head_valid_o`: true iff `count_o != 0`.
- `head_*_o`: packet fields selected by the current head pointer.
- `head1_pc0_o`（B2/F2 新增）: 下一条 FIFO entry（head+1）的 `pc0`，作 head 包的
  顺序流 `pred_npc` 预测后继，仅 `count_o >= 2` 时有效。

The parent must not use `head_*_o` unless `head_valid_o` or an external bypass
path provides a valid packet.  The module does not arbitrate between stored FIFO
data and same-cycle fetch-response bypass.

## 3. State Machine And Priority

Per clock edge:

1. `rst`: reset pointers/count and clear packet storage for deterministic sim.
2. `clear_i`: reset pointers/count to empty.
3. `seed_valid_i`: reset head to 0, set tail to 1, set count to 1 and write the
   seed packet into slot 0.
4. Normal enqueue/pop:
   - enqueue only: write tail, increment tail, increment count;
   - pop only: increment head, decrement count;
   - enqueue and pop: write tail, increment both pointers, keep count unchanged.

The parent drives `clear_i` and `seed_valid_i` mutually exclusive.  In the parent
action encoder, late precise trap clear keeps the highest priority and seed
actions mirror the old inlined non-blocking assignment order.

## 4. Data-Path Invariants

- `count_o == 0` implies `head_valid_o == 0`.
- `count_o != 0` implies `head_valid_o == 1`.
- `count_o` never exceeds FIFO depth when the parent respects its reserve
  contract.
- A seed action creates exactly one valid entry at slot 0, independent of prior
  head/tail/count.
- Clear and seed actions override normal enqueue/pop, matching the old parent
  behavior where redirect/trap assignments came after normal FIFO updates in the
  sequential block.

## 5. Parent Boundary

`OooFrontend` remains responsible for:

- deciding whether an incoming fetch response bypasses FIFO storage
  （mode=1 下 bypass 恒 0，配置性死路）;
- computing `fetch_rsp_enqueue_w`, `fifo_storage_pop_w` and reservation;
- encoding redirect/trap/drain clear and seed actions;
- selecting seed packet source（三源在当前配置下全为死路，见文首状态注记）:
  - branch fall-through current response;
  - branch prefetch hit promoted to FIFO;
  - JALR prefetch hit promoted to FIFO.

