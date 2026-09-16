# OooFrontendBackendDispatchMux Spec

> ⚠️ **状态（2026-07-03 RTL 重读）**：本 mux 的多个输入臂在当前配置下已被形式化证死——
> branch prefetch（`BRANCH_PREFETCH_DISPATCH_ENABLE=1'b0`）、pending jump / pending
> memory（capture 被 `OOO_ROB_WALK_MODE=1` 门死，valid 恒 0）、return-continuation
> （`return_cont_attempt_o=1'b0`）、branch target / fallthrough append
> （`BRANCH_APPEND_DISPATCH_ENABLE=1'b0`）；`jump_dispatch_fire_o` /
> `mem_dispatch_fire_o` 恒 0。活臂仅剩 pending system CSR 与 head slot0/slot1
> （含 direct JAL/RET 的 next-PC 修饰）。拆除计划见 `../arch/ooo-core-architecture.md`
> §8.3。下文保留原优先级与死臂的设计语义描述。

## Scope

`OooFrontendBackendDispatchMux` owns the pure combinational source selection
between front-end/pending control sources and the two dispatch ports of
`OooAluCoreSlice`.

The module does not allocate ROB/IQ entries, update rename state, create or
clear pending owners, or change ready/valid timing. It only preserves the
legacy priority mux and fire predicates.

## Inputs

- Dispatch source valid facts:
  - branch prefetch dispatch
  - pending system CSR dispatch
  - normal front-end packet dispatch
  - direct branch/JAL/RET dispatch
  - lane1 barrier replay
  - pending jump dispatch
  - pending memory dispatch
  - return-continuation/branch-target/fallthrough lane1 append attempts
- Source payloads from fetch packet head, fetch response decode, branch
  prefetch buffer, pending system/jump/memory state, return-continuation state,
  branch target cache, and direct return target.
- `dispatch0_ready_i` from the backend dispatch port.
- 【F2】`dispatch1_ready_i`、`dispatch1_squash_i`（solo 分支/非返回 JALR 拍禁
  d1 影子）、`d0_ctrlflow_fired_i` / `d1_ctrlflow_fired_i`（本拍 fire 的控制流标记）、
  `direct_fire_succ_i`（本拍 direct fire 的实际重取目标，pred_npc 单一真源）。

## Outputs

- `core_dispatch0/1_valid_o`
- `core_dispatch0/1_pc/next_pc/inst_o`
- `core_dispatch0_csr_rdata_o`
- `core_dispatch0_fire_o`
- `jump_dispatch_fire_o`
- `mem_dispatch_fire_o`
- 【F2】`core_dispatch0/1_pred_npc_o`（per-uop 预测后继，后端 mispredict 判据）

## Priority

Dispatch0 payload priority:

1. Branch prefetch buffered packet
2. Branch prefetch same-cycle response packet
3. Pending system CSR
4. Pending jump
5. Pending memory
6. Direct RET next-PC override
7. Current head slot0 packet

Dispatch1 payload priority:

1. Branch prefetch buffered packet
2. Branch prefetch same-cycle response packet
3. Return-continuation
4. Branch target append
5. Direct RET next-PC override
6. Current head slot1 packet

## Invariants

- Pending jump and pending memory fire only when their dispatch source is valid
  and backend dispatch0 is ready.（两臂现均为死通道，valid 恒 0，fire 恒 0。）
- 【F2】`core_dispatch1_valid_o` 在 `dispatch1_squash_i` 拍强制无效（solo 分支/
  非返回 JALR 免 flush 后必须砍 d1 影子，防 wrong-path fall-through 顺序提交）。
- 【F2】pred_npc 三臂：本 lane 是本拍 fire 的控制流 → `direct_fire_succ_i`；
  d0 非控制流且 d1 实际双发 → d0 后继 = d1.pc；其余顺序流 → `next_fetch_pc_i`
  （FIFO count<2 时为 64'h1 哨兵，恒判 mispredict 兜底）。
- Dispatch0 fire is `core_dispatch0_valid && dispatch0_ready`.
- Dispatch0 CSR read data is nonzero only for pending system CSR dispatch.
- Branch fallthrough append only asserts dispatch1 valid; its payload remains
  the current head slot1 payload, matching the legacy parent expression.
