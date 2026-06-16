# Task Report

## 基本信息

- `task_id`: `2026-05-25-npc-single-mul-pipeline`
- `task_slug`: `npc-single-mul-pipeline`
- `graph_template`: `npc-sim-regression`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-25`
- `updated_at`: `2026-05-25`

## 任务目标

- `source_request`: 将 single 核心中的乘法器从组合实现改为 5 级流水线。
- `goal`: RV32M 乘法指令 `MUL/MULH/MULHSU/MULHU` 不再走 `NpcCore` 内部组合乘法函数，而是通过独立 5 级流水乘法单元返回结果。
- `scope`: 限定 `npc/single`；不同步修改 `npc/soc` 复制版。

## 选图说明

- `selected_template`: `npc-sim-regression`
- `why_this_graph`: 改动落在 NPC single RTL 核心，需要模块测试、lint、Verilator build 与 AM on NPC 回归形成证据链。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## RTL 推导摘要

### 需求

- 功能目标：支持 RV32M 乘法四条指令，结果语义与原组合函数一致。
- 接口边界：新增 `Rv32Multiplier`，采用 `req_valid/req_ready` 请求和 `rsp_valid/rsp_ready` 响应；`NpcCore` EX 级发起请求并通过 `ex_wait` 等待响应。
- 时序目标：乘法内部为固定 5 个寄存级，不再在 `NpcCore` EX 组合路径直接使用 `*`。
- 范围外：不改变除法器、译码、WBU、提交端口和 SoC 后端。

### 协议规则

- 请求 payload 为 `funct3/src1/src2`，仅在 `req_valid && req_ready` 时采样。
- 响应 payload 在 `rsp_valid` 拉高后保持稳定，直到 `rsp_ready` 消费。
- `flush_i` 或 `rst` 清空全部流水级，旧响应不得继续提交。
- `NpcCore` 用 `mul_req_issued_q` 保证同一条 ID/EX 乘法指令等待期间只发一次请求。

### 状态机

- 乘法器内部使用 5 个 `valid_s0_q..valid_s4_q` 表示流水占用。
- reset/flush：全部 valid 清 0。
- 正常推进：若下一级 ready，则本级 payload 前移；若输出级未被消费，则上游级保持。
- EX 级：乘法响应未 valid 时 `ex_wait=1`，响应 valid 后允许 `ex_fire` 把结果送入 EX/MEM。

### 不变量

- 任意周期同一条 ID/EX 乘法最多有一个在途请求。
- 输出级 `rsp_valid=1 && rsp_ready=0` 时，`rsp_data` 保持不变。
- flush/reset 后所有 stage valid 为 0，不会提交旧路径乘法结果。
- 结果仍只经 WBU/EX-MEM/MEM-WB 统一写回，提交语义不绕过流水线。

### 数据通路

- 请求阶段先按 `funct3` 判断符号属性，将 signed operand 转为绝对值并记录最终符号。
- 5 个流水级按 bit 范围 `0..6`、`7..13`、`14..19`、`20..25`、`26..31` 累加部分积。
- 最后一阶段按符号恢复 64-bit product，再按 `funct3` 选择低 32 位或高 32 位。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | AGENTS、Copilot、memory、study | 约束与调用链 | 已定位 `NpcCore.rv32m_mul_result` 与 `PipelineControl.ex_wait_i` |
| implement | Codex | completed | RTL 推导 | `Rv32Multiplier`、`NpcCore` 接入、testbench/filelist | `tb_multiplier`、`tb_npc_core_smoke` PASS |
| verify | Codex | completed | 修改后工作树 | lint/build/test 结果 | 见下方证据 |
| record | Codex | completed | 本轮结论 | task-run 与 memory 更新 | 本文件、`dispatch-log.md`、memory 条目 |

## 关键产物

- `artifacts`: `npc/single/vsrc/execute/Rv32Multiplier.v`、`npc/single/vsrc/core/NpcCore.v`、`npc/single/testbench/tests/tb_multiplier.sv`
- `logs_or_traces`: `/tmp/npc-single-mul-full-results`、`/tmp/npc-single-mul-pipe-results`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 收尾结论

- `final_result`: single 核心乘法已切到 5 级流水乘法单元，组合乘法函数已从 `NpcCore` 删除。
- `evidence_summary`: `make -C npc/single lint` PASS；模块 testbench 27/27 PASS；pipe/stage pipe PASS；`make -C npc/single -j4` PASS；`mul-longlong`、`matrix-mul`、`div` on `riscv32-npc` PASS；`git diff --check` PASS。
- `notes`: 当前本地 single 配置为 Difftest OFF，AM 回归为裸跑 GOOD TRAP 证据。
