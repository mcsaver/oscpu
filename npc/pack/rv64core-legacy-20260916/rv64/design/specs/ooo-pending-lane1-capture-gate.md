# OooPendingLane1CaptureGate Spec

> ⚠️ **状态（2026-07-03 RTL 重读）**：`mem_capture_o` 被形式化证死——barrier 触发条件（fault/exit/system/arch_trap/branch/jalr 残臂）与 `FACT_MEM` 经 DecodeUnit 单 case 结构严格互斥，恒 0（终裁见 task-run answers.json #5）；`fp_capture_o` 在上游 arbiter 内悬空（FP 已迁域 A）；branch/jump capture 下游被 `!rob_walk_mode_i` 门死——活功能仅剩 SYSTEM capture 与 trap/exit scrub/payload 计算；拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 1. 需求

- `OooPendingLane1CaptureGate` 承接 lane1 barrier 之后的局部 owner 分型和
  trap/exit payload 组合计算。
- 输入只包含 lane1 本槽信息：`barrier_base_i`、`head_fetch_fault_i`、
  `head_resp_i`、`head_pc_i`、`head_inst_i`、`facts_i` 和 `csr_illegal_i`。
- 输出 lane1 typed owner capture：SYSTEM、branch、jump、FP、memory，以及
  trap-exit scrub/capture、exit valid/ecall/ebreak、arch valid、cause/tval。
- 本模块不判断 lane0 优先级，不产生 clear，不保存 payload，不访问 CSR，也不改变
  pending sequencer 状态。

## 2a. 协议规则

- 本模块是纯组合 helper，没有 ready/valid、寄存器或复位。
- `barrier_base_i` 必须由上游 arbiter 已经按全局优先级过滤：无 CSR trap memory、
  无 direct frontend flush、可运行、有 fetch packet、无 IRQ、无 lane0 fault/trap/exit/
  SYSTEM/branch/jump owner，并且 lane1 barrier fire（lane0 FP 过滤项已随 FP
  迁域 A 删除）。
- typed owner capture 只由 `facts_i` 的 `OOO_SLOT_FACT_BRANCH/JUMP/MEM/
  FP_ENABLED/SYSTEM` 打开。
- SYSTEM capture 额外要求 `!csr_illegal_i && !ARCH_TRAP`，保持 lane1 CSR illegal
  与 privilege/FP/illegal trap 先进入 trap-exit。
- trap-exit capture 保留 scrub 语义：只要 `barrier_base_i=1`，就拉高
  `trap_exit_capture_o`；是否留下有效 exit/arch payload 由 `*_valid_o` 决定。
- exit ecall/ebreak payload 输出保持 raw facts，不额外用 valid gate 包住，和旧父模块
  mux 语义一致。

## 2b. 状态机

无内部状态机。组合分类表如下：

| 条件 | 输出 |
| --- | --- |
| `!barrier_base_i` | capture/valid 全部为 0 |
| `barrier_base_i && BRANCH/JUMP/MEM/FP_ENABLED` | 对应 typed owner capture |
| `barrier_base_i && SYSTEM && !csr_illegal && !ARCH_TRAP` | SYSTEM typed capture |
| `barrier_base_i && EXIT` | trap-exit capture 且 exit valid |
| `barrier_base_i && (fetch_fault || csr_illegal || ARCH_TRAP)` | trap-exit capture 且 arch valid |
| `barrier_base_i && none` | 只产生 trap-exit scrub capture，valid 均为 0 |

## 2c. 不变量

- I1：所有 typed owner capture 必须被 `barrier_base_i` 门控。
- I2：SYSTEM typed capture 与 lane1 CSR illegal/architectural trap 互斥。
- I3：trap-exit capture 与 arch/exit valid 分离；空 barrier 仍 scrub stale valid bit。
- I4：cause/tval 旧优先级不变：semihost EBREAK > illegal > FP disabled >
  privilege-system illegal > CSR illegal > fetch resp page/access fault。
- I5：本模块不得读取 lane0、resolve、drain、dispatch unsupported 或 direct flush 输入；
  这些全局优先级仍属于 `OooPendingDispatchArbiter`。

## 2d. 数据通路约束

- 数据通路只有 facts bit alias、typed capture AND gate、arch/exit valid gate、
  cause/tval priority mux。
- 位宽来自 `define.v` 和 `common/OooSlotFacts.v`：`XLEN`、`INST_W`、
  `TRAP_CAUSE_W`、`OOO_SLOT_FACTS_W`。
- `trap_exit_tval_o` 对 semihost EBREAK 输出 0；对 illegal/FP disabled/
  privilege-system illegal/CSR illegal 输出 `head_inst_i`；否则输出 `head_pc_i`。
- `head_resp_i == 2'b10` 表示 instruction page fault；其它 fetch fault 类响应走
  instruction access fault。

## 3. RTL 映射

- `control/OooPendingLane1CaptureGate.v` 直接实现 2b 的组合分类表。
- `control/OooPendingDispatchArbiter.v` 继续持有全局 capture/clear 优先级，
  并实例化本模块承接 lane1 typed capture 与 trap/exit payload。
- `tb_ooo_pending_lane1_capture_gate` 覆盖 idle、empty barrier scrub、typed
  branch/jump/mem/FP、SYSTEM legal/blocker、exit、semihost、illegal、FP disabled
  和 fetch page/access fault。

## 验证结果

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-capture-gate/focused TESTS="tb_ooo_pending_lane1_capture_gate" run`: 1/1 PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-capture-gate/focused TESTS="tb_ooo_pending_lane1_capture_gate tb_ooo_pending_dispatch_arbiter tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit" run`: 6/6 PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-capture-gate/all run`: 103/103 PASS。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。

