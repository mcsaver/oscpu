# Ooo slot facts bus 设计说明

## 目标

`OooFetchHeadClassifyGate` 和 `OooFetchHeadPairGate` 已经把 fetch head 的分类逻辑从
`OooAluFetchCore` 内联逻辑中拆出，但父模块和 pair gate 之间仍主要依赖几十根
`head0_*/head1_*` 散线。本切片在 `vsrc/common/` 中新增统一 packed facts bus 定义，
作为后续 pending capture、owner arbiter 和前端控制边界继续收口的共同载体。

本轮保持等价迁移：旧散线端口全部保留，新增 `facts_o/head*_facts_o` 与散线一一对应。
父模块先只接入 facts bus，不删除旧消费者。

## 范围

本切片负责：

- 新增 `common/OooSlotFacts.vh`，定义单槽组合事实总线位号和 `OOO_SLOT_FACTS_W`。
- `OooFetchHeadClassifyGate` 输出 `facts_o`，每个 bit 直接 alias 现有分类输出。
- `OooFetchHeadPairGate` 输出 `head0_facts_o/head1_facts_o`，内部 lane1 可见性、
  branch-spec dispatch block 和 dispatch0 facts 改用 facts bus bit。
- `OooAluFetchCore` 连接 `head0_facts_w/head1_facts_w`，为后续收口预留统一入口。
- `filelist.mk` 把 common header 纳入 `RTL_HEADER_SRCS`，保证头文件变更触发重建。

不在范围内：

- 不改变任何 facts 的生成条件、优先级或时序。
- 不删除旧 `head0_*/head1_*` 散线端口。
- 不移动 pending payload、CSR side effect、fetch FIFO、PC/outstanding、RAS/BPU 或 recovery 状态。
- 不引入 SystemVerilog `struct`，继续使用 Verilog packed bus + 宏切片。

## 协议规则

- `facts_o[OOO_SLOT_FACT_*]` 必须等于同名旧散线输出。
- facts bus 只表达单槽组合事实，不携带 ready/fire、owner、payload valid 或时序状态。
- lane1 可见性仍由 lane0 fetch fault、lane0 branch/jump/stop 和 slot1 response 决定。
- `dispatch0_jump_o` 保持旧语义：只表示 lane0 JALR dispatch fact；JAL 仍走
  `dispatch0_jal_o`。
- `branch_spec_dispatch_block_o` 保持旧语义，只是从 facts bus bit 读取 stop/control/mem。

## 状态机

无状态机。本切片只增加组合 alias bus。

## 不变量

- facts bus 任一 bit 不得引入额外门控；所有门控来自既有散线。
- `OOO_SLOT_FACT_JUMP` 表示 `jal || jalr`，但 dispatch0 JALR fast path 继续使用
  `OOO_SLOT_FACT_JALR`。
- fetch fault 不是独立 facts bit；它仍通过 `ARCH_TRAP` 和 `STOP` 进入 slot facts。
- `head0_facts_o/head1_facts_o` 可用于后续 owner 收口，但本轮不改变父模块最终决策。

## 验证计划

- `tb_ooo_fetch_head_classify_gate` 增加 facts alias 断言，覆盖普通、FP、CSR、semihost、
  SRET/TSR 和 fetch fault 场景。
- `tb_ooo_fetch_head_pair_gate` 增加 head0/head1 facts 断言，覆盖 lane0 branch/illegal、
  lane1 fault、branch-spec memory/control、JAL/JALR dispatch0 语义和 FS-off FP。
- focused 回归覆盖 `tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate
  tb_ooo_alu_fetch_core tb_decode_unit`。
- 默认 module testbench、Verilator lint 和整机构建作为集成验证。

## 验证结果

- focused 2/2：`tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate` PASS，证据
  `npc/rv64/perf/results/20260627-ooo-slot-facts-common/focused/`。
- focused 4/4：`tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate
  tb_ooo_alu_fetch_core tb_decode_unit` PASS，证据同上。
- 默认 module testbench：102/102 PASS，证据
  `npc/rv64/perf/results/20260627-ooo-slot-facts-common/all/`。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
