# V9X recovery/owner-birth task report

## Current result

V9X 的 recovery × owner-birth × holder-phase 子范围已经完成 root-cause
修正和最终设计绑定：

- 当前 RV64 RTL design id：
  `sha256:a2ccc0c2a61be3d8922245f7d145eadc186b701fca1f38ef534aafdd983e994b`；
- `stop_pending_o` 只由 accepted pending owner、exact CSR lease、canonical
  queue-head real-fire/inflight/kill、trap/exit holder 与 C1 reset 驱动；
- queue-head CSR 的 owner birth 不再由 merged backend fire 重构；
- pre-ROB trap/exit holder 在 C1 与 stop 同沿 reset；
- 两项 compile-success RTL mutation 均被 focused flag-on oracle 拒绝；
- 最终 module 111/111、functional aggregate、architecture hard gates 9/9
  均为 PASS/GREEN。

本 task-run 的 **V9X owner-birth 子范围可判 PASS**。总体
`SERIALIZE-G1` 仍为 **GAP/OPEN**：本轮没有证明
`OooMemOwnerTerminalCollector` 的非 FENCE serialized transaction terminal，
没有关闭七类 transaction exactly-once、完整 Linux flag-on、arch-stable
freeze 或 PPA qualification。最终 functional evidence 明确记录
`ppa=UNQUALIFIED`、`promotion_eligible=false`。

## Interface contract freeze — stage 0

The complete cross-module contract is
`npc/rv64/design/specs/ooo-serialize-owner-birth.md`.

Affected boundaries:

- data: no payload moves; existing PC/instruction/CSR/ProducerId holders remain;
- control: raw classification is replaced by accepted owner-birth facts;
- backpressure: queue-head CSR birth is ready-qualified dispatch fire;
- flush/recovery: pre-ROB clear, exact lease, queue-head inflight and C1 reset
  have distinct death rules;
- exception: trap/exit birth follows the trap/exit holder's validity and squash
  priority;
- performance: new logic terminates only at `stop_pending_o` D.

Same-edge priority is:

`reset/external/C1 > exact terminal > exact lease hold > queue-head inflight hold > accepted clear > accepted birth > normal hold`.

## RTL derivation

### Stage 1 — requirements

- Eliminate ownerless `stop_pending_o` after recovery/capture collisions.
- Preserve lane0/lane1 serialized-system capture priority.
- Preserve queue-head CSR first-cycle blocking, but only after real dispatch
  fire.
- Preserve the exact pending-CSR `ProducerId` lease across ordinary clear.
- Add no terminal-event deduplication and weaken no assertion.
- Out of scope: memory owner terminal proof, seven-kind exactly-once closure,
  PPA qualification.

### Stage 2a — protocol

- `pending_owner_birth_w` is a one-cycle combinational event sampled with the
  holder's own capture edge.
- `head0_csr_owner_birth_w` is a one-cycle ready-qualified event.
- `pending_owner_live_w`, exact lease and queue-head inflight are registered
  levels.
- Birth events may occur back-to-back only if the corresponding holder is
  empty on each accepted edge.
- Recovery never retries a rejected younger owner; the FIFO/ROB recovery path
  determines replay.

### Stage 2b — state machine

- `RUN --accepted birth--> STOP`.
- `STOP --matching death/C1--> RUN`.
- `STOP --live exact lease or live queue-head inflight--> STOP`.
- `RUN --rejected raw candidate--> RUN`.
- Illegal ownerless `STOP` is assertion-visible in the current ROB-walk
  configuration.

### Stage 2c — invariants

- rising stop has an accepted owner-birth witness;
- exact pending CSR lease implies stop;
- queue-head CSR inflight implies stop;
- capture plus accepted pre-ROB clear cannot create pending-system birth;
- terminal events are neither deduplicated nor masked.

### Stage 2d — datapath

- No architectural data path changes.
- Existing facts/capture outputs feed narrow Boolean accepted-birth logic.
- Existing `stop_pending_o` is updated by one priority mux and one sequential
  assignment.
- No new feedback enters ready, redirect, memory or CSR payload logic.

### Stage 2e — RTL topology and self-review

1. Module boundary: combinational birth/live/kill signals enter
   `OooStopPendingSequencer`; synchronous active-high reset.
2. State register: existing one-bit `stop_pending_o`, reset zero.
3. Combination: system accepted-birth, trap/exit accepted-birth,
   queue-head CSR birth/kill, stop next-state mux.
4. FSM: `RUN/STOP` encoded by the one-bit register.
5. Pipeline: no new stage; events are sampled on the holder/stop edge.
6. Priority: frozen stage-0 ordering above.
7. Resources: one shared owner-birth OR and explicit priority mux.
8. Critical path: capture/kill facts to stop D only.
9. Functions: none; arbitration and state remain explicit RTL.

Self-review: the topology does not recreate holder payload, does not add a
ready/valid loop, distinguishes pre-ROB clear from exact lease death, and
uses the same queue-head kill fact as the inflight register contract.

### Stage 3 — RTL

RED evidence established before RTL correction:

- TB: `tb_ooo_stop_pending_sequencer`
- collision: `branch_spec_resolve_valid_i` plus lane0 SYSTEM or lane1 barrier;
- observed: both cases produced `stop_pending_o=1`, expected zero;
- checker: `errors=2`, `[RESULT] FAIL status=1`;
- log:
  `evidence/red/logs/tb_ooo_stop_pending_sequencer.log`;
- SHA-256:
  `c9fbff11805f8ef20b6476e042998de92e7ff33c69f724283546b125c2cf53bc`.

An earlier run with `branch_resolve_untracked_i` passed, proving that signal is
already clear-wins in the existing `else-if` chain.  The implementation uses
the reproduced checkpoint-recovery failure rather than the broader static
claim.

第二项 RED 绑定 trap/exit squash collision：

- TB：`tb_ooo_pending_trap_exit_sequencer`；
- collision：`clear_exit && clear_arch_squash && capture_arch`；
- pre-fix log：`evidence/red-exit/logs/tb_ooo_pending_trap_exit_sequencer.log`；
- SHA-256：
  `a999f847744182f75523d7deb139d3fd4539190132161306727a90ab81fc91af`。

最终 RTL 修改：

1. `npc/rv64/vsrc/control/OooStopPendingSequencer.v`
   - 删除 raw lane/type classification birth 端口；
   - 消费 accepted pending birth/live、exact CSR lease、queue-head owner
     birth/live/kill 与 C1 reset；
   - 使用一个显式 priority next-state chain；
   - 保留并增加
     `[V9X-STOP-BIRTH-WITNESS]`、`[V9X-STOP-LEASE-HOLD]`、
     `[V9X-STOP-QCSR-HOLD]`、`[V9X-STOP-OWNER-LIVE]`。
2. `npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v`
   - squash clear 在同沿拒绝 wrong-path capture；
   - `[V9X-EXIT-SQUASH-COLLISION]` fail-loud。
3. `npc/rv64/vsrc/control/OooControlPlane.v`
   - 生成 accepted pending owner birth/live；
   - trap/exit sequencer reset 接入
     `rst || flush_i || core_local_flush_w`；
   - queue-head owner birth 直接消费 canonical
     `head0_csr_dispatch_fire_w`。
4. `npc/rv64/vsrc/frontend/OooFrontend.v`
   - 导出 canonical `head0_csr_dispatch_fire_w`。
5. `npc/rv64/vsrc/core/OooCoreTopGlue.v`
   - 完成 Frontend→ControlPlane 的 real-fire 接线。

该修改没有加入 terminal-event 去重，没有屏蔽重复 terminal，也没有削弱
assertion。

## Independent review

只读 reviewer 按 contract render 逐轮寻找 cycle-exact 反例：

| 轮次 | contract SHA-256 | 结论与处置 |
|---|---|---|
| V1 | `f7d5a4ecf4cdc87b743c7e2cb322d148cd311fbbdce08e60e010d9d136f87047` | 找到 raw birth 与 holder clear 的优先级分叉，形成首个 RED 与单一事实源修正方向。 |
| V2 | `f0e59a75a8687d45813e790d59d1822ab64292494c095f2170bc133d4dd6ef9c` | 找到 trap/exit C1 reset、merged-fire reconstruction、缺 flag-on 三个 GAP；均进入后续修正。 |
| V3 | `7b9b2991642bc0d6f0db77397d97ad46bbd6c437b2676a0c8ffb7842968a4dbc` | 静态证明 CSR dispatch-fire 与 drain-complete 同拍不可达，并运行 flag-on PASS；仍指出 real-fire 与 C1 两个边界，随后由 root 修正。 |
| V4 | `0c24142ece0c242655ac6f1b757a741dcb99071deebf33fd9c1c404746688708` | 最终只读终审核对四组 edge transition、8 个相关 RTL source-map identity、focused marker 与 2/2 mutation；未发现新 blocker，V9X owner-birth 子范围独立 PASS。 |

V1–V4 的 report 为 `reviewer-report-v1.md` 至
`reviewer-report-v4.md`。每轮 reviewer 都归还 WSL shell ownership；
未改生产 RTL。V4 保留两个非阻断证据边界：没有重新打开
`OooPendingDispatchArbiter`/C1 gate 的内部生成逻辑；mutation summary
只直接绑定 production `OooControlPlane.v` 的 before/after SHA，而不是
完整 mutant cohort/TB 的统一 aggregate hash。保存的 mutant source/log
hash、临时 vsrc 编译路径、最终 V9P marker 与 return code 已逐项核对，
没有产生当前 owner-birth 反例。

## Verification evidence

### Assertion negative

五个非法状态注入分别命中预期 ERROR/FATAL marker：

- `evidence/assert-negative/birth.log`：
  `[V9X-STOP-BIRTH-WITNESS]`；
- `evidence/assert-negative/lease.log`：
  `[V9X-STOP-LEASE-HOLD]`；
- `evidence/assert-negative/qcsr.log`：
  `[V9X-STOP-QCSR-HOLD]`；
- `evidence/assert-negative/live.log`：
  `[V9X-STOP-OWNER-LIVE]`；
- `evidence/assert-negative/exit-squash.log`：
  `[V9X-EXIT-SQUASH-COLLISION]`。

这些 negative case 证明 assertion 非 vacuous；它们不替代生产可达性证明。

### Focused RTL and flag-on

最终 `OOO_CSR_QUEUE_HEAD=1` CoreTopGlue 日志：

`evidence/post-v3/final-flag-on/results/logs/tb_ooo_core_top_glue_v9o_csr_qh.log`

- SHA-256：
  `c2dd45ed43e78bf76e1ecaf18308a541625578e7e138b2b52d029903a3fd2e65`；
- `[V9X-QCSR-REAL-FIRE-SOURCE][PASS] merged=1 real=0 birth=0`；
- `[V9X-TRAP-EXIT-C1-RESET][PASS] holder=0 stop=0`；
- V9O queue-head CSR C0/C1、pending CSR owner、memory-order marker PASS；
- V9P branch recovery、JALR recovery、callback-chain marker PASS；
- `[RESULT] PASS`，无 `[CHECK-FAIL]`、ERROR 或 FATAL。

默认配置下的 focused module 包括
`tb_ooo_stop_pending_sequencer`、
`tb_ooo_pending_trap_exit_sequencer`、
`tb_ooo_pending_system_sequencer`、
`tb_ooo_pending_dispatch_arbiter`、
`tb_ooo_ifu_lane1_fault_owner`、
`tb_ooo_priv_system` 和 `tb_ooo_core_top_glue`，均 PASS。

### Compile-success mutations

runner：`run-post-v3-owner-mutations.py`；结果：
`evidence/post-v3/owner-mutations/summary.json`，SHA-256
`e079df53f81939b5c3a9dbb2bb2ca029c3b3c9dfe5b0340d0e9fb368446a1e5b`。

- `drop-trap-exit-c1-reset`：编译并运行到最终 V9P marker 后，由
  `[CHECK-FAIL] V9X C1 clears pre-ROB exit holder` 拒绝，return code 2；
- `reconstruct-qcsr-birth-from-merged-fire`：编译并运行到最终 V9P marker
  后，由
  `[CHECK-FAIL] V9X merged fire cannot alias queue-head owner birth`
  拒绝，return code 2；
- 2/2 rejected，生产 `OooControlPlane.v` 的 before/after SHA-256 均为
  `8948204aa5d685ea327a87e37d32eab23159564b5e7cb713eb93bbf45e7bf399`。

第一次 mutation 尝试暴露了 testbench oracle 没有隔离 holder reset 和
merged-fire reconstruction 边界的问题；虽然 mutant source 确实参与编译，
但不能据此声称 rejected。随后 TB 强制 `dispatch0_facts_w[CSR]` 并隔离
ordinary clear，再执行上面的 2/2 最终 mutation；只有最终结果进入交付证据。

### Layered regression

- RTL static：`check-rtl-style` PASS；`check-contract` PASS，14 tests，
  assertion count `487 >= 89`；
- module：
  `evidence/final/module-current/summary.txt`，111/111，SHA-256
  `fd15bdfbfbdf3662cb25a9d6fb8d49f2bbdfd63c58cb374975643fdf95094658`；
- functional：
  `evidence/final/full-functional.log`，SHA-256
  `4be9e59d127077da4d2878c245659723a16080cd6cbf9a5aa3a53ffaec9e0bc0`；
  module 111/111、official 177/177、AM 59/59、DiffTest mismatch 0、
  CoreMark 10 次且 CRC `0xfcaf`、Dhrystone 10000、
  `[F0-G1-GATE] PASS`；
- architecture：
  `architecture/final-architecture-hard-gates.json`，SHA-256
  `b9f3e9e446a30835e252f7314bcc29bafd12ffcb07e27a8da85dca28af33b404`；
  DI-1..DI-5、OOO-1..OOO-4 共 9/9 GREEN，`exit_code=0`。

module 最终运行的第一次 driver 记录仅因 `tee` 在 `evidence/final`
目录建立前打开而返回 1；`make` 本体已经完成 111/111。随后立即在已存在目录
下重跑，`evidence/final/module-current-run.log` 返回 0；交付只引用后者及
`summary.txt`。

### Scope boundary

本轮证据只支持以下结论：

- accepted pending birth、exact lease、queue-head real-fire/inflight、C1
  death 在 stop/holder 边界 phase-aligned；
- recovery/capture collision 不再产生 orphan stop；
- merged backend fire 不能别名为 queue-head owner birth；
- trap/exit holder 与 stop 在 C1 同沿 reset。

下列范围明确保留为 GAP：

- `OooMemOwnerTerminalCollector` 入口 lane 对与 owner/holder 合同；
- 非 FENCE serialized transaction 的 memory-owner terminal；
- 七类 serialized transaction 的 exactly-once completion/retirement；
- 完整 Linux `OOO_CSR_QUEUE_HEAD=1`；
- arch-stable freeze、综合/STA/Power/PPA promotion。
