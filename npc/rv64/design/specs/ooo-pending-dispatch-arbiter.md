# OoO Pending Dispatch Arbiter Spec

## 1. 需求

- `OooPendingDispatchArbiter` 承接 `OooAluFetchCore` 中 pending owner
  capture/clear 的纯组合仲裁。
- 输入来自当前 fetch packet head、dispatch classification、direct frontend
  flush、branch/jump resolve、CSR trap 和 drain 状态。
- 输出只包含已有 pending sequencer 消费的事件：
  branch/jump/memory/FP/system/trap-exit capture 与 clear，以及 trap/exit
  capture payload。
- 本模块不保存状态、不读 GPR/FPR、不访问 CSR、不更新 BPU/RAS/BTB、不发起
  fetch redirect，也不决定最终 commit/trap 输出。

## 2a. 协议规则

- 本模块是纯组合模块，没有 ready/valid 或内部寄存器。
- `capture_base` 只在 `!csr_trap_mem && !direct_frontend_flush && can_run &&
  fifo_has_packet` 时成立；所有普通 head/lane1 capture 都必须从该条件派生。
- `csr_irq_pending` 在 `capture_base` 内优先于 lane0/lane1 指令分类，生成
  system IRQ capture，并清理 stale trap/exit pending。
- lane0 分类优先级保持旧父模块顺序：
  fetch fault -> architectural trap -> exit -> FP -> SYSTEM/CSR -> branch
  serialized boundary -> jump serialized boundary -> lane1 barrier ->
  unsupported trap。
- lane1 barrier 只生成通用 lane1 capture 事件；是否成为 branch/jump/mem/FP/
  SYSTEM/trap/exit valid entry，仍由下游 sequencer 的 lane1 raw/valid 输入决定。
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
| `capture_base && lane0 arch trap/exit/FP/system/branch/jump` | 对应 pending capture 或 trap capture |
| `capture_base && lane1 barrier` | lane1 generic capture |
| `capture_base && unsupported` | illegal-instruction trap capture |
| resolve/drain/system CSR commit | 对应 pending clear |

## 2c. 不变量

- I1：普通 capture 必须被 `csr_trap_mem` 和 direct frontend flush 阻断。
- I2：IRQ capture 与 lane0/lane1 指令 capture 互斥。
- I3：lane0 branch serialized capture 与 lane0 jump serialized capture 互斥。
- I4：lane1 generic capture 只能在 lane0 不需要 pending owner 时产生。
- I5：unsupported trap capture 只能在 lane0/lane1 都未被更高优先级分类消费时产生。
- I6：trap cause/tval mux 必须保持旧优先级：
  fetch fault > lane0 arch trap > lane0 CSR illegal > lane1 barrier >
  unsupported。
- I7：本模块不得引入任何时序状态；所有 precise boundary 仍由现有 sequencer
  的寄存器和 `late_clear_i` 保证。

## 2d. 数据通路约束

- 数据通路只有组合 priority network 和 trap/exit payload mux。
- 位宽来自 `define.v`：`XLEN`、`INST_W`、`TRAP_CAUSE_W`。
- 不向 dispatch ready、memory ready、CSR ready 形成新的反向组合环。
- 下游 payload 寄存器仍属于 `OooPendingBranchSequencer`、
  `OooPendingJumpSequencer`、`OooPendingMemorySequencer`、
  `OooPendingFpSequencer`、`OooPendingSystemSequencer` 和
  `OooPendingTrapExitSequencer`。

## 3. RTL 映射

- `OooPendingDispatchArbiter.v` 直接编码 2b 的组合分类表。
- `OooAluFetchCore` 保留 pending sequencer 实例、payload mux、CSR/FPR side
  effect、flush/recovery 和 final trap/exit 输出。
