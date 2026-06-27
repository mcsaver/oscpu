# OooFetchHeadPairGate 设计说明

## 目标

上一轮已经把单槽 fetch head 分类收敛到 `OooFetchHeadClassifyGate`。本轮继续
沿同一条工业化边界推进：把 `OooAluFetchCore` 中紧邻 head0/head1 classifier 的
双槽可见性、fetch fault、branch-spec dispatch block 和 lane0 dispatch facts 收敛到
`frontend/OooFetchHeadPairGate.v`。

新模块是纯组合 head-pair owner：内部实例化两个 `OooFetchHeadClassifyGate`，
根据 slot0 fault、slot0 control-stop 和 slot1 response 决定 lane1 是否可见，并输出
父模块当前下游消费的 head facts 与 dispatch0 facts。父模块继续负责 fetch FIFO、
pending owner、CSR side effect、RAS/BPU、PC/outstanding、trap capture 和 precise
recovery 时序。

## 范围

本模块负责：

- `head_fetch_fault0/1` 与 `head_fetch_fault` 的组合判断。
- `head0_decode_valid` 与 `head1_decode_valid` 的组合可见性。
- head0/head1 单槽分类器实例化与 facts 输出。
- `branch_spec_dispatch_block` 的组合判断。
- `dispatch_valid` 与 dispatch0 的 ECALL/EBREAK/exit/arch-trap/system/FP/branch/JAL/JALR
  facts。
- `direct_branch0_dispatch_valid` 作为 lane0 branch fast path 的组合别名。

不在范围内：

- 不新增寄存器、状态机或 ready/valid 存储。
- 不计算 `direct_branch0_fire`、`direct_jal0_dispatch_valid` 或 direct ret fire；
  这些仍受 ready/unsupported/RAS/dispatch mux 下游约束。
- 不写 CSR、FPR、GPR、ROB、pending entry、fetch FIFO 或 BPU/RAS。
- 不改变 `OooFetchHeadClassifyGate`、`DecodeUnit`、`OooFpDecode` 的分类语义。
- 不改变 branch-spec、pending dispatch、trap/exit 或 flush 的时序优先级。

## 协议规则

- `fifo_has_packet_i` 为 0 时，所有 head/dispatch facts 必须为 0。
- `head_fetch_fault0_o = fifo_has_packet_i && head_resp0_i != 0`。
- lane1 只有在 FIFO 有包、lane0 无 fetch fault、lane0 不是 branch/jump/stop 且
  slot1 response 正常时可见。
- lane1 fetch fault 只有在 lane1 本可见、但 `head_resp1_i != 0` 时成立。
- `branch_spec_dispatch_block_o` 必须保持旧父模块语义：
  branch-spec active 时，任一 head fault/stop/control/mem 会阻止普通 dispatch。
- `dispatch_valid_o` 必须保持旧父模块语义：
  FIFO 有包、can-run、无 IRQ、无 lane0 fetch fault、无 branch-spec dispatch block。
- dispatch0 facts 只给 lane0 加 `dispatch_valid_o` 门控，不消费 ready/unsupported；
  fire 仍由下游模块判定。

## 状态机

无状态机。本模块是纯组合 owner。

## 不变量

- `head_fetch_fault0_o=1` 时，`head1_decode_valid` 内部为 0，lane1 分类 facts 为 0。
- head0 branch/jump/stop 会抑制 lane1 decode 和 lane1 fetch fault。
- `head_fetch_fault_o = head_fetch_fault0_o | head_fetch_fault1_o`。
- branch-spec dispatch block 不应在 `branch_spec_active_i=0` 时拉高。
- `dispatch0_fp_o` 只在 head0 FP enabled 时拉高；FS-off FP 应走 arch trap，而不是
  dispatch0 FP。
- `direct_branch0_dispatch_valid_o == dispatch0_branch_o`。
- 模块不读取或修改 pending、CSR 文件、ROB、FIFO storage、PC/outstanding、RAS 或 BPU 状态。

## 数据通路骨架

1. 根据 `fifo_has_packet_i/head_resp0_i` 生成 lane0 fetch fault 与 lane0 decode valid。
2. 实例化 head0 `OooFetchHeadClassifyGate`，传入 slot1 作为 semihost exit peer。
3. 根据 head0 branch/jump/stop 与 slot1 response 生成 lane1 fetch fault/decode valid。
4. 实例化 head1 `OooFetchHeadClassifyGate`，传入 slot0 作为 semihost enter peer。
5. 汇总 branch-spec dispatch block。
6. 生成 `dispatch_valid` 和 lane0 dispatch facts。

## 验证计划

新增 `npc/rv64/testbench/tests/tb_ooo_fetch_head_pair_gate.sv`，覆盖：

- idle 时所有 head/dispatch facts 为 0。
- 普通双槽 ALU：lane0/lane1 可见，`dispatch_valid` 为 1。
- lane0 branch 抑制 lane1 decode 与 lane1 fetch fault。
- lane0 illegal/stop 抑制 lane1 decode。
- lane0 fetch fault 抑制 lane1 decode，并阻止 dispatch。
- lane1 fetch fault 在 lane0 正常且 slot1 response fault 时成立，并纳入 head fault。
- branch-spec active 时被 head0 mem、head1 control 或 lane1 fetch fault 阻塞。
- IRQ 或 can-run 关闭时只抑制 dispatch，不抑制 head 分类 facts。
- FS-off head0 FP 产生 arch trap/stop，但不产生 dispatch0 FP。
- head0 branch dispatch fact 等于 direct branch0 dispatch valid。

实现后最小回归：

- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_pair_gate" RESULT_DIR=../perf/results/20260627-fetch-head-pair/failing run`
- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_pair_gate" RESULT_DIR=../perf/results/20260627-fetch-head-pair/module run`
- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_pair_gate tb_ooo_fetch_head_classify_gate tb_ooo_alu_fetch_core tb_decode_unit" RESULT_DIR=../perf/results/20260627-fetch-head-pair/focused run`
- `make -C npc/rv64 lint`
- `make -C npc/rv64 -j2`
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-fetch-head-pair/full-module-testbench run`
- 预算允许时追加 `rv64ui,rv64mi,rv64si` official smoke。

## 验证结果

- RED：`tb_ooo_fetch_head_pair_gate` 在 RTL 未实现时因 `Unknown module type: OooFetchHeadPairGate` 失败，符合预期。
- GREEN：`tb_ooo_fetch_head_pair_gate` PASS。
- 父模块接入后 focused：`tb_ooo_fetch_head_pair_gate tb_ooo_fetch_head_classify_gate tb_ooo_alu_fetch_core tb_decode_unit` 4/4 PASS，证据 `npc/rv64/perf/results/20260627-fetch-head-pair/focused/`。
- 默认 module testbench：102/102 PASS，证据 `npc/rv64/perf/results/20260627-fetch-head-pair/full-rerun/`。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64` PASS。
- official smoke：`rv64ui/rv64mi/rv64si` `overall_rc=0`，证据 `npc/rv64/perf/results/20260627-fetch-head-pair/core-regress-official/20260627-124346-64026/`。
