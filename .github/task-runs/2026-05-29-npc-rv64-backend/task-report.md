# Task Report

## 基本信息

- `task_id`: `2026-05-29-npc-rv64-backend`
- `task_slug`: `npc-rv64-backend`
- `graph_template`: `npc-sim-regression`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-29`
- `updated_at`: `2026-05-29`

## 任务目标

- `source_request`: 用户要求在 `npc` 下另开 `rv64` 目录，从 `single` 复制并改成 RV64 核，修改仿真顶层和 AM 顶层，以跑过 cpu-tests 全量为完成标准。
- `goal`: 新增 `npc/rv64` 后端，打通 `ARCH=riscv64-npc -> npc/sim BACKEND=rv64 -> NpcSimTop -> RV64 core`，并通过 CPU-test 基础全量。
- `scope`: `npc/rv64/**`、`npc/sim` backend/Kconfig/defconfig、`abstract-machine/scripts/riscv64-npc.mk`、`abstract-machine/klib/include/limits.h`、`am-kernels/tests/cpu-tests/Makefile`、项目 memory 与 task-run 记录。

## 选图说明

- `selected_template`: `npc-sim-regression`
- `why_this_graph`: 本任务横跨 RTL、DPI host、仿真后端选择、AM 构建入口和 cpu-tests 回归，核心验收是 NPC 仿真回归闭环。
- `dynamic_nodes_added`: `rv64-isa-width`, `rv64-am-toolchain`, `rv64-difftest-policy`
- `why_dynamic_nodes_were_needed`: RV64 迁移不只是新增目录，还需要 64-bit 数据通路、工具链 freestanding ABI 和当前 NEMU reference 能力边界的额外决策。

## RTL 推导摘要

- `需求`: 在不破坏现有 `npc/single` RV32 核的前提下，派生一个独立 `npc/rv64` 后端；默认目标是 RV64IM_Zicsr_Zifencei 基础 CPU-test，而不是一次性支持 RV64B/RV64C 或 ysyxSoC。
- `协议`: 保持 `NpcCoreTop` 对外 IFU/LSU single-beat AXI-like 边界，仿真壳仍通过 `NpcAxiBus + AxiDpiSlave` 接 PMEM/MMIO；AM 侧只通过 `npc/sim` 选择后端，避免把上层绑定到 `npc/rv64` 私有路径。
- `状态机`: 顺序流水控制、提交/退出/CSR/trap 边界沿用 `single`，但 PC/GPR/CSR/AXI payload、DPI payload 全部按 `XLEN=64` 扩宽；`*W` 指令在 EX 级形成 32-bit 子结果后 sign-extend 到 64-bit 写回。
- `不变量`: x0 恒零；load/store lane 由 byte address low bits 与 `WSTRB[7:0]` 决定；`LW` sign-extend、`LWU` zero-extend、`LD` 直通；JAL/JALR/branch/imm 目标必须保持 64-bit 符号扩展；当前 RV64 cacheable 范围关闭，避免复制 RV32 cache line 假设时误称 64-bit cache 已验证。
- `数据通路`: `ImmGen/BranchPredictor` 负责 RV64 sign extension；`DecodeUnit` 增加 RV64 opcode/funct 识别；`NpcCore` 对普通 ALU、word ALU、mul/div operand 和结果扩展分流；`LSUDataPath/LSUControl` 负责 8-byte bus word 的 lane extract/merge；`AxiDpiSlave` 和 host PMEM API 以 `npc_word_t=uint64_t` 传递地址/数据/mask。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `copy-backend` | Codex | completed | `npc/single` | `npc/rv64` 复制目录，排除 build/testbench/perf 产物 | `npc/rv64/` 存在 |
| `sim-backend` | Codex | completed | `npc/sim` | `rv64` backend mk、Kconfig、`rv64_defconfig`、help 文案 | `make -C npc/sim rv64_defconfig` PASS |
| `am-backend` | Codex | completed | AM riscv/npc 平台 | `riscv64-npc.mk`、freestanding lp64、klib `limits.h` | `ARCH=riscv64-npc ALL=add run` PASS |
| `rtl-width` | Codex | completed | `single` RTL | XLEN/PC/CSR/AXI/LSU/ALU/muldiv RV64 化 | `make -C npc/sim BACKEND=rv64 lint` PASS |
| `host-width` | Codex | completed | `single` C/DPI host | `npc_word_t`/`npc_paddr_t` 64-bit、DPI longint、RV64 disasm/log | `make -C npc/sim BACKEND=rv64 -j4` PASS |
| `difftest-policy` | Codex | completed | NEMU RV64 能力检查 | `CONFIG_NPC_DIFFTEST=n`，`difftest-ref` 显式提示不可用 | known issue [31] |
| `regression` | Codex | completed | cpu-tests | RV64 基础全量 `38/38 PASS` | `ARCH=riscv64-npc run` |

## 关键产物

- `artifacts`: `npc/rv64/**`, `npc/sim/backends/rv64.mk`, `npc/sim/configs/rv64_defconfig`, `abstract-machine/scripts/riscv64-npc.mk`, `abstract-machine/klib/include/limits.h`, `am-kernels/tests/cpu-tests/Makefile`
- `logs_or_traces`: 终端回归输出显示 `test list [38 item(s)]` 且 38 项全部 PASS；`add` smoke HIT GOOD TRAP；lint/build 均 PASS。
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/modules/abstract-machine.md`, `.github/memory/modules/am-kernels.md`, `.github/memory/known-issues.md`

## 验证结果

| test | command | result |
| ---- | ------- | ------ |
| `rv64 config` | `make -C npc/rv64 default_defconfig` | PASS |
| `sim config` | `make -C npc/sim rv64_defconfig` | PASS |
| `rv64 lint` | `make -C npc/sim BACKEND=rv64 lint` | PASS |
| `rv64 build` | `make -C npc/sim BACKEND=rv64 -j4` | PASS |
| `cpu-tests add` | `ARCH=riscv64-npc ALL=add run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"` | PASS |
| `cpu-tests full` | `ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"` | `38/38 PASS` |

## 当前阻塞点

- `blockers`: 无功能验收阻塞；RV64 基础 CPU-test 已通过。
- `missing_dependencies`: 当前 NEMU RV64 reference 不完整，不能启用 RV64 difftest。
- `risk_assessment`: `bitmanip/compressed` 被排除是因为现有测试与目标扩展是 RV32 口径；这不是 RV64B/RV64C 的通过证明。`npc/rv64` 当前禁用 RTL cacheable 范围，后续恢复 RV64 I/D cache 需要单独回归 self-modifying、unalign、store/load ordering。

## 下一步建议

1. 若要 RV64 difftest，先补 NEMU RV64 reference，再打开 `npc/rv64` 的 `CONFIG_NPC_DIFFTEST`。
2. 若要扩展到 RV64B/RV64C，先新增 RV64 语义版本的 `bitmanip/compressed` 测试，再实现核心对应扩展。
3. 若要恢复 RV64 RTL cache，先把 cache line、word offset、wstrb merge 和 `fence.i` 以 64-bit bus word 重新设计并跑专项 + 全量。

## 模板升级候选

- `repeated_dynamic_subgraph`: `copy-backend -> sim backend -> AM arch -> width migration -> cpu-tests`
- `should_promote_to_static_template`: `false`
- `reason`: 当前是一次性 RV64 派生任务，后续若频繁新增 ISA/backend 再抽模板。

## 收尾结论

- `final_result`: `npc/rv64` 后端、`npc/sim BACKEND=rv64`、`ARCH=riscv64-npc` AM 入口均已打通，RV64 基础 CPU-test 全量通过。
- `evidence_summary`: lint PASS、build PASS、`add` GOOD TRAP、cpu-tests `38/38 PASS`。
- `notes`: 当前完成标准按用户“cpu-test 全量”执行；由于现有 `bitmanip/compressed` 是 RV32 扩展测试，RV64 基础全量为 38 项。
