# OoO Pending Dispatch Arbiter Spec

> ⚠️ **状态（2026-07-03 RTL 重读）**：branch/jump capture 全部臂（direct/head0/lane1）被 `!rob_walk_mode_i` 门死（`OOO_ROB_WALK_MODE=1'b1`，`OooPendingDispatchArbiter.v:100-103,160-183`）；mem capture 因 lane1 barrier 条件与 `FACT_MEM` 经 DecodeUnit 单 case 结构严格互斥而恒 0（形式化终裁见 task-run answers.json #5）；lane1 FP capture 在本模块内悬空（`lane1_fp_capture_w` 无输出端口，FP 已迁域 A）；mode=1 下 unsupported 的 arch-trap capture 亦被门控关闭（`:304-323`）——活功能仅剩 system（CSR/ecall/xret/wfi/sfence）/IRQ/trap-exit 的捕获与 clear 优先级网络；拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述（FP 相关句已按现行 RTL 修正）。

## 1. 需求

- `OooPendingDispatchArbiter` 承接 `OooAluFetchCore` 中 pending owner
  capture/clear 的纯组合仲裁。
- 输入来自当前 fetch packet head、dispatch classification、direct frontend
  flush、branch/jump resolve、CSR trap 和 drain 状态。
- 输出只包含已有 pending sequencer 消费的事件：
  branch/jump/memory/system/trap-exit capture 与 clear，以及 trap/exit
  capture payload（FP capture 输出已随 pending-FP 拆除移除，仅剩悬空内部 wire）。
- 本模块不保存状态、不读 GPR/FPR、不访问 CSR、不更新 BPU/RAS/BTB、不发起
  fetch redirect，也不决定最终 commit/trap 输出。

## 2a. 协议规则

- 本模块是纯组合模块，没有 ready/valid 或内部寄存器。
- `capture_base` 只在 `!csr_trap_mem && !direct_frontend_flush && can_run &&
  fifo_has_packet` 时成立；所有普通 head/lane1 capture 都必须从该条件派生。
- slot 分类事实只从 `dispatch0_facts_i/head1_facts_i` 进入本模块；不再保留
  `dispatch0_*` / `head1_*` 事实散线兼容端口。
- direct fast-path、return、unsupported、barrier fire 和 CSR illegal probe 仍是独立
  控制输入，不属于 slot facts bus。
- `csr_irq_pending` 在 `capture_base` 内优先于 lane0/lane1 指令分类，生成
  system IRQ capture，并清理 stale trap/exit pending。
- lane0 分类优先级保持旧父模块顺序：
  fetch fault -> architectural trap -> exit -> SYSTEM/CSR -> branch
  serialized boundary -> jump serialized boundary -> lane1 barrier ->
  unsupported trap（lane0 FP 臂已随 FP 迁域 A 删除，head0=FP 与普通
  ALU 指令同构，不再参与 pending capture/clear 门控）。
- lane1 barrier 先形成 `lane1_barrier_base`；branch/jump/mem/SYSTEM
  capture 输出必须再由 `head1_facts_i` 对应 bit 分型，不再对所有 owner
  同时拉高 generic capture；具体 lane1 typed capture 和 trap/exit payload 由
  `OooPendingLane1CaptureGate` 计算（gate 的 fp_capture 输出在 arbiter 侧悬空），
  arbiter 只保留全局优先级。
- trap-exit lane1 capture 保留旧 scrub 语义：任意 lane1 barrier 都会触发
  trap/exit sequencer capture，具体是否留下 exit/arch valid 由 lane1 exit/trap
  facts 决定；这样非 trap/exit owner 仍会清掉 stale trap/exit valid bit。
- clear 事件继续保留旧语义差异：
  branch clear 不由 direct flush 直接触发；
  jump/memory/system clear 会被 direct flush 触发；
  trap-exit arch clear 与 exit clear 的 direct/pending-jump 处理不同。

## 2b. 状态机

本模块无内部状态。可把组合决策看成以下优先分类表：

| 条件 | 主要输出 |
| --- | --- |
| `csr_trap_mem` | 抑制普通 capture；各 pending sequencer 的 late clear 仍由父模块直连 |
| `direct_frontend_flush && direct branch fire` | direct branch capture，jump/mem/system/trap-exit 清理 |
| `capture_base && csr_irq_pending` | system IRQ capture，清 stale branch/jump/mem/trap-exit |
| `capture_base && head0 fetch fault` | trap-exit architectural capture |
| `capture_base && lane0 arch trap/exit/system/branch/jump` | 对应 pending capture 或 trap capture |
| `capture_base && lane1 barrier` | lane1 typed owner capture；trap-exit scrub/capture |
| `capture_base && unsupported` | illegal-instruction trap capture |
| resolve/drain/system CSR commit | 对应 pending clear |

## 2c. 不变量

- I1：普通 capture 必须被 `csr_trap_mem` 和 direct frontend flush 阻断。
- I2：IRQ capture 与 lane0/lane1 指令 capture 互斥。
- I3：lane0 branch serialized capture 与 lane0 jump serialized capture 互斥。
- I4：lane1 typed capture 只能在 lane0 不需要 pending owner 且对应 lane1 fact
  为真时产生。
- I5：unsupported trap capture 只能在 lane0/lane1 都未被更高优先级分类消费时产生。
- I6：trap cause/tval mux 必须保持旧优先级：
  fetch fault > lane0 arch trap > lane0 CSR illegal > lane1 barrier >
  unsupported。
- I6a：trap-exit lane1 capture 是 scrub/capture 边界，不等同于
  branch/jump/mem/FP/SYSTEM typed owner capture。
- I7：本模块不得引入任何时序状态；所有 precise boundary 仍由现有 sequencer
  的寄存器和 `late_clear_i` 保证。

## 2d. 数据通路约束

- 数据通路只有组合 priority network 和 trap/exit payload mux。
- 位宽来自 `define.v`：`XLEN`、`INST_W`、`TRAP_CAUSE_W`。
- lane1 owner capture 类型来自 `common/OooSlotFacts.v` 的
  `OOO_SLOT_FACT_BRANCH/JUMP/MEM/FP_ENABLED/SYSTEM`。
- lane1 barrier 的局部 payload mux 由 `OooPendingLane1CaptureGate` 承接；
  本模块仍负责 lane0/IRQ/direct/resolve/clear 的全局优先级表。
- `dispatch0_facts_i` 必须已经由父模块按 `dispatch_valid` 门控，避免 slot0 无效时
  仍触发 pending owner capture。
- 不向 dispatch ready、memory ready、CSR ready 形成新的反向组合环。
- 下游 payload 寄存器仍属于 `OooPendingBranchSequencer`、
  `OooPendingJumpSequencer`、`OooPendingMemorySequencer`、
  `OooPendingSystemSequencer` 和 `OooPendingTrapExitSequencer`
  （`OooPendingFpSequencer` 已随 pending-FP 拆除删除；branch/jump/mem
  三个 sequencer 为死通道驻留，见顶部状态注记）。

## 3. RTL 映射

- `OooPendingDispatchArbiter.v` 直接编码 2b 的全局组合分类表，并实例化
  `OooPendingLane1CaptureGate` 承接 lane1 局部 facts 分型和 trap/exit payload。
- 上层（历史巨石 `OooAluFetchCore`，现为 `OooControlPlane` wrapper 与
  `OooCoreTopGlue` 接线）保留 pending sequencer 实例、payload mux、CSR side
  effect、flush/recovery 和 final trap/exit 输出。
