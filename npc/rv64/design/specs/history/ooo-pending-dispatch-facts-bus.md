# OooPendingDispatchArbiter facts bus 接入说明

## 目标

上一轮已经把 fetch/decode slot facts 收敛到 `common/OooSlotFacts.v` 定义的 packed bus。
本轮把该 bus 接入 `control/OooPendingDispatchArbiter.v`，让 pending capture/clear
仲裁开始消费统一 facts，而不是继续只依赖 `dispatch0_*` / `head1_*` 散线。

后续切片已经删除旧事实散线兼容端口；当前 `dispatch0_facts_i/head1_facts_i`
是 slot facts 进入 arbiter 的唯一事实输入。不改变 capture 优先级、payload 所有权
或任一 pending sequencer 的时序。

## 范围

本切片负责：

- `OooPendingDispatchArbiter` include `common/OooSlotFacts.v`。
- 输入 `dispatch0_facts_i` 与 `head1_facts_i`。
- 在 arbiter 内部用 facts bus 建立本地 alias：
  `dispatch0_arch_trap/exit/ecall/ebreak/fp/system/branch/jal/jump` 和
  `head1_system/exit/ecall/ebreak/arch_trap/illegal/fp_disabled/priv_illegal/semihost`。
- 后续切片把 lane1 facts alias 和 trap/exit payload mux 移入
  `control/OooPendingLane1CaptureGate.v`；`OooPendingDispatchArbiter` 仍负责
  lane1 barrier base 和全局 capture/clear 优先级。
- `OooAluFetchCore` 生成 `dispatch0_facts_w = dispatch_valid_w ? head0_facts_w : 0`，
  并把 `dispatch0_facts_w/head1_facts_w` 接给 arbiter。
- `tb_ooo_pending_dispatch_arbiter` 用标量 stimulus 自动构造 facts bus，验证旧场景
  在新 bus 主路径下仍通过。

不在范围内：

- 不删除 direct fast-path、unsupported、barrier fire 或 CSR illegal probe 等非 slot-facts
  控制输入。
- 不改变 `head0_csr_illegal/head1_csr_illegal` 等 CSR probe 结果来源。
- 不改变 pending branch/jump/mem/FP/system/trap-exit sequencer 的状态机。
- 不移动 pending payload、backend drain、CSR side effect、fetch redirect、PC/outstanding、
  RAS/BPU 或 precise recovery 时序。

## 协议规则

- `dispatch0_facts_i` 是 dispatch-valid 门控后的 lane0 facts。
- `dispatch0_fp` 使用 `OOO_SLOT_FACT_FP_ENABLED`，FS-off FP 仍走 arch trap，不走 pending FP。
- `dispatch0_jump` 保持旧 JALR 语义，因此从 `OOO_SLOT_FACT_JALR` 读取，不从
  `OOO_SLOT_FACT_JUMP` 读取。
- `head1_facts_i` 是 lane1 raw slot facts；lane1 是否参与 capture 仍由
  `dispatch1_barrier_fire_i` 和 lane0 优先级表决定。
- CSR illegal 仍来自 `head0_csr_illegal_i/head1_csr_illegal_i`，因为它依赖 CSR probe，
  不是纯 decode slot facts。
- direct branch/JAL fire、return hint、unsupported 和 lane1 barrier fire 仍是控制边界输入，
  不塞进 slot facts bus。

## 状态机

无新增状态机。本切片只改变 pending arbiter 的组合输入表示。

## 不变量

- IRQ、head0 fetch fault、head0 arch trap、exit、FP、SYSTEM、serialized branch/jump
  的优先级不变。
- lane1 barrier capture 的 branch/jump/FP/mem 开门条件不变。
- trap/exit payload 选择不变：lane0 unsupported 取 slot0，lane1 unsupported 取 slot1；
  semihost EBREAK tval 仍为 0。
- `dispatch0_facts_i[OOO_SLOT_FACT_JUMP]` 即使包含 JAL，也不能影响 old `dispatch0_jump`
  判定；JALR 仍由 `OOO_SLOT_FACT_JALR` 表达。

## 验证结果

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-bus/focused TESTS="tb_ooo_pending_dispatch_arbiter" run` PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-bus/focused TESTS="tb_ooo_pending_dispatch_arbiter tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit" run` PASS 5/5。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-bus/all run` PASS 102/102。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
