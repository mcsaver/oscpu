# Task Report

## 基本信息

- `task_id`: `2026-05-20-npc-asic-timing-rv32m-divider`
- `task_slug`: `npc-asic-timing-rv32m-divider`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-20 00:38`
- `updated_at`: `2026-05-20 01:03`

## 任务目标

- `source_request`: 自上而下分析 NPC 结构，优化时序逻辑，推进 ASIC 代码风格。
- `goal`: 先处理最明确的 ASIC 时序风险：EX 阶段 RV32M DIV/REM 组合除法/取模。
- `scope`: `npc/single/vsrc/NpcCore.v`、`PipelineControl.v`、新增 `Rv32Divider.v`、`npc/single/Makefile`。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 本轮是 RTL 时序优化 + difftest 回归，既要做结构分析，也要执行 RTL 四段式推导、实现和长测。
- `dynamic_nodes_added`: `benchmark-smoke`
- `why_dynamic_nodes_were_needed`: 用户前序要求 benchmark，RTL 改动完成后补跑 Dhrystone 作为长程序压力证据。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | `codex` | `completed` | `.github/*` 规则、NPC study 文档、当前 RTL | 时序风险排序 | 已读取 AGENTS/copilot/memory/study/checklist |
| `derive-rtl` | `codex` | `completed` | RV32M 语义、当前流水控制 | 四段式 RTL 推导 | 本报告“RTL 推导摘要” |
| `implement-divider` | `codex` | `completed` | `NpcCore/PipelineControl` | 多周期 `Rv32Divider` 和 `ex_wait` 接入 | `make -C npc/single lint` 通过 |
| `verify-cputest` | `codex` | `completed` | Verilator NPC + NEMU diff | 38 个 cpu-tests 全量 PASS | `timeout 600s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'` |
| `benchmark-smoke` | `codex` | `completed` | Dhrystone benchmark | benchmark PASS + diff 长测 | `timeout 600s make -C am-kernels/benchmarks/dhrystone ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0 -F default'` |
| `eda-env-check` | `codex` | `blocked` | `npc/single` STA targets | 工具链缺失结论 | `make -C npc/single syn-check-env` 报缺 `/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys` |

## RTL 推导摘要

### 需求

- 移除 EX 级 `rv32m_result` 中的组合 `/` 和 `%`，避免综合生成不可收敛的长组合除法器。
- 保持 RV32M DIV/DIVU/REM/REMU 的 ISA 语义、提交顺序、difftest 接口不变。
- 遵守“一个文件一个 module”，将除法器单独放入 `Rv32Divider.v`。

### 协议规则

- ID/EX 中遇到合法 DIV/REM 指令时，`NpcCore` 在源操作数稳定后向除法器发起 `req_valid`。
- 除法器 `rsp_valid` 前，`PipelineControl` 通过 `ex_wait_i` 禁止当前指令 `ex_fire`。
- 结果被 EX 消费时用 `rsp_ready_i = ex_fire_w && id_ex_divrem_w` 清掉响应。
- fetch fault / illegal 指令不启动长延迟除法，避免异常被错误的 EX wait 推迟。
- `mem_fault/halt/fatal` 会 flush 尚未提交的除法状态。

### 状态机

- `idle`: `req_ready_o=1`，等待请求。
- `busy`: 普通除法每周期推进 1 bit，32 周期后生成商或余数。
- `response`: `rsp_valid_o=1`，等待 EX 消费；特殊情况（除零、有符号溢出）直接进入 response。

### 不变量

- ID/EX stall 期间 funct3、rs1、rs2 不变，除法请求只能发起一次。
- EX 等待只阻塞当前 ID/EX 指令，不阻塞老的 MEM/WB 正常离开。
- 写回仍只发生在既有 WBU/EX-MEM/MEM-WB 提交路径，除法器不直接改 RF。
- DIV/REM 特殊值遵守 RISC-V：除零 DIV* 返回全 1，REM* 返回被除数；`INT_MIN / -1` 返回 `INT_MIN`，余数为 0。

### 数据通路骨架

- `rv32m_mul_result` 仅保留 MUL/MULH/MULHSU/MULHU 组合乘法结果。
- `Rv32Divider` 负责 DIV/DIVU/REM/REMU 的符号预处理、迭代恢复除法、符号恢复和响应保持。
- `ex_ext_result_w` 对 M 扩展按 `id_ex_divrem_w` 在 `ex_div_result_w` 与 `ex_mul_result_w` 间选择。
- `PipelineControl` 新增 `ex_wait_i`，在 `ex_fire_o` 处统一收口长延迟执行等待。

## 关键产物

- `artifacts`: `npc/single/vsrc/Rv32Divider.v`、`NpcCore.v`、`PipelineControl.v`、`Makefile`
- `logs_or_traces`: 终端验证记录
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 综合/STA 未跑，因为本机缺少 `oss-cad-suite/bin/yosys`。
- `missing_dependencies`: `/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys`
- `risk_assessment`: 乘法和 bitmanip 仍是组合路径；I/D cache 仍是 reg-array 阻塞 cache，尚未替换为 SRAM macro 风格接口。

## 验证证据

- `make -C npc/single lint`: PASS
- `make -C npc/single`: PASS
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=div run NPC_RUN_ARGS='--diff=default -m 0'`: PASS
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=mul-longlong run NPC_RUN_ARGS='--diff=default -m 0'`: PASS
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--diff=default -m 0'`: PASS
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=load-store run NPC_RUN_ARGS='--diff=default -m 0'`: PASS
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=bitmanip run NPC_RUN_ARGS='--diff=default -m 0'`: PASS
- `timeout 600s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`: 38/38 PASS
- `timeout 600s make -C am-kernels/benchmarks/dhrystone ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0 -F default'`: PASS，`230019182` commits，CPI `3.124`，仿真约 `671831 inst/s`
- `make -C npc/single syn-check-env`: blocked，缺少 yosys

## 下一步建议

1. 将 MUL/MULH 路径改为可选迭代或流水乘法器，避免 `*` 继续落在 EX 单周期组合路径。
2. 把 Zb 中的 `clmul/clmulh/clmulr`、`cpop/clz/ctz` 从大组合 loop 拆成专用单元或多周期路径。
3. 设计 ICache/DCache 的 SRAM macro 风格 tag/data RAM 接口，替换当前仿真友好的 reg array 读法。
4. 恢复 `oss-cad-suite` 后跑 `make -C npc/single syn/sta`，用真实 WNS/TNS/cap/fanout 验证 PPA。

## 模板升级候选

- `repeated_dynamic_subgraph`: `rtl-timing-optimize-loop`
- `should_promote_to_static_template`: `yes`
- `reason`: 未来每轮 ASIC 时序优化都需要 “结构风险排序 -> RTL 四段式推导 -> 实现 -> lint/build -> cpu-tests diff -> benchmark/STA”。

## 收尾结论

- `final_result`: EX 组合除法/取模已移出主组合路径，改为独立多周期迭代除法器；功能回归与 benchmark 长测通过。
- `evidence_summary`: Verilator lint/build PASS，cpu-tests 38/38 diff PASS，Dhrystone diff PASS。
- `notes`: CoreMark 默认 1000 iterations 的长跑在 3.6 亿条指令处人工终止，未作为最终 benchmark 证据；Dhrystone 提供完整 benchmark PASS。
