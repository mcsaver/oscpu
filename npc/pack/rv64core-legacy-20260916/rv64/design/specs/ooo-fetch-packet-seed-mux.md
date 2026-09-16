# OooFetchPacketSeedMux Boundary Spec

> **T3V 状态**：seed 数据面已物理删除，模块现为 clear-only action gate。
> 原 set-seed 真源均结构性恒假：fallthrough capture 由
> `BRANCH_APPEND_DISPATCH_ENABLE=0` 关死，branch-prefetch hit-to-FIFO 与
> JALR-prefetch hit 在父模块 tie 0。不能只依赖跨层级常量折叠，因为保层级综合会保留
> payload mux 与 FIFO seed D mux。

## 1. Requirement

`OooFrontend` owns redirect and recovery policy, but the conversion from
already-computed events into `OooFetchPacketFifo.clear_i` is a pure combinational
action encoder.

`OooFetchPacketSeedMux` extracts only that encoder:

- decide whether the fetch packet FIFO should clear;
- preserve the original priority/no-op blockers；
- for a legacy dead seed control combination, clear and refetch as the safe fallback.

The parent keeps ownership of all event predicates, packet decode, branch/JALR
target validation, pending sequencing, trap/interrupt recovery and FIFO storage.

## 2. Interface Contract

Inputs are parent-generated event predicates:

- high-priority CSR trap and direct frontend flush;
- branch speculative restore, pending branch commit/resolve, untracked branch;
- pending JALR/jump resolve and redirect cases;
- memory replay dispatch, CSR dispatch and CSR commit boundaries;
- drain-complete pending owner classification.

The only output is `clear_o`. There are no packet payload or seed-valid ports.

The module does not generate event predicates, does not pop/enqueue FIFO
storage, and does not update `next_fetch_pc`.

## 3. State Machine

There is no internal state.

Combinational priority mirrors the old parent logic:

1. Start from no clear.
2. CSR trap clears and is re-applied as the final override.
3. Direct frontend flush clears；原 fallthrough seed 情形回退为 clear+refetch。
4. Branch speculative restore clears.
5. Pending branch commit/resolve clears；原 branch-prefetch seed 情形回退为 clear+refetch。
6. Untracked branch resolve clears.
7. Pending jump/JALR resolve在 misalignment 或 redirect 时清空；原 JALR seed
   情形回退为 clear+refetch。
8. Pending memory replay dispatch and CSR dispatch are explicit no-op blockers.
9. CSR commit clears.
10. Drain-complete pending owners clear，pending jump 同样 clear+refetch。

## 4. Invariants

- `csr_trap_i` always forces `clear_o=1`.
- 模块无 data payload、seed-valid 或 FIFO 写入口。
- Memory replay dispatch and CSR dispatch do not mutate FIFO storage and block
  lower-priority drain/commit actions in the same combinational decision.
- 在三个 set-seed 真源固定为 0 的生产约束下，T3V clear-only gate 必须与旧模块
  `clear_o` 逐组合等价，旧 `seed_valid_o` 必须恒 0；持久化 2^20 穷举脚本作为证据。
