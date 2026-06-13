# Task Report

## 基本信息

- `task_id`: `2026-05-22-npc-mcycle-csr`
- `task_slug`: `npc-mcycle-csr`
- `graph_template`: `custom`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-22`
- `updated_at`: `2026-05-22`

## 任务目标

- `source_request`: 用户要求“按照 RISC-V 特权架构手册，完成 mcycle 相关内容”。
- `goal`: 在 NPC 的现有 Zicsr/machine CSR 框架内补齐 RV32 `mcycle` 相关最小实现。
- `scope`: `NpcCore.v`、`define.v`、`tb_npc_core_mcycle.sv`、testbench Makefile、项目记忆。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | AGENTS、memory、NPC study docs | 当前 CSR/trap 边界 | 已读取必读链 |
| spec-check | codex | completed | RISC-V privileged spec snapshot | `mcycle/mcycleh/cycle/cycleh/mcountinhibit.CY` 语义 | 官方 spec 与本地摘要一致 |
| rtl-derive | codex | completed | 现有 CSR 写回路径 | 四阶段 RTL 推导 | 本文件“RTL 推导摘要” |
| implement | codex | completed | `NpcCore.v`、`define.v` | mcycle 计数、CSR 读写、cycle shadow、mcountinhibit.CY | 文件修改 |
| verify | codex | completed | 新增单测和现有回归 | testbench/lint/build/cpu-tests 通过 | 见“验证证据” |
| record | codex | completed | 本轮结论 | memory 与 task-run 更新 | `.github/memory/*` 与本目录 |

## RTL 推导摘要

### 阶段 1 - 需求

- 功能目标：实现 RV32 `mcycle`/`mcycleh` 64 位机器周期计数器，支持 `cycle`/`cycleh` 用户计数器只读镜像。
- 控制目标：实现 `mcountinhibit.CY`，只允许 bit0 控制 `mcycle` 暂停递增，其余 bit 作为未实现计数器位读 0。
- 兼容目标：保留现有 M-mode bring-up 边界，不新增 privilege filtering、`mcounteren`、`time`/`timeh` 或 `minstret`。
- 端口边界：不改变 `NpcCore` 外部端口，不新增总线或提交观测口。

### 阶段 2a - 协议规则

- `mcycle` 在非 reset、非 halt/fatal 状态下按核心时钟周期递增；流水 stall、cache miss 等等待周期也计入。
- `mcountinhibit.CY=1` 时 `mcycle` 保持不变；清零后从下一个周期继续递增。
- `mcycle` 写低 32 位，`mcycleh` 写高 32 位，另一半保持原值。
- `cycle`/`cycleh` 只读映射到 `mcycle`/`mcycleh`；对 `cycle`/`cycleh` 执行写类 CSR 指令应沿用现有 CSR illegal 路径触发非法指令异常。

### 阶段 2b - 状态机

- 本轮没有新增 FSM。
- reset：`csr_mcycle_q=0`，`csr_mcountinhibit_q=0`。
- normal：每拍先给 `csr_mcycle_q` 默认递增或保持。
- CSR write：在同一个时序块内覆盖默认递增；`mcycle/mcycleh/mcountinhibit` 写入按对应 CSR 规则更新。

### 阶段 2c - 不变量

- `cycle/cycleh` 永远不是 writable CSR，只能作为 `mcycle/mcycleh` 的只读 shadow。
- `mcountinhibit` 只保留 `CY` bit，读回值不会暴露未实现的 `IR/HPMn` inhibit 位。
- 既有 unknown CSR 仍保持 illegal；新增 CSR 不改变其它 CSR 地址合法性。
- `mcycle` 不等同于平台 `mtime`，本轮不把它接到 RTC/MMIO 时间源。

### 阶段 2d - 数据通路约束

- `define.v` 新增 CSR 地址宏和 `MCOUNTINHIBIT_CY` 掩码。
- `NpcCore` 新增 `csr_mcycle_q[63:0]` 和 `csr_mcountinhibit_q[31:0]`。
- CSR read mux 增加 `mcountinhibit/mcycle/mcycleh/cycle/cycleh`。
- CSR writable/known decode 区分可写机器计数器和只读 shadow CSR。

## 验证证据

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-mcycle-module-tests-final run`: 22/22 PASS，新增 `tb_npc_core_mcycle` 覆盖读写、shadow、inhibit 和只读写异常。
- `make -C npc/single lint`: PASS。
- `make -C npc/single -j14`: PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 38/38 PASS。

## 收尾结论

- `final_result`: NPC 已实现特权架构手册要求的最小 `mcycle` 相关 CSR 语义。
- `evidence_summary`: CSR 单测覆盖计数器半字写、`cycle` shadow、`mcountinhibit.CY` 暂停/恢复、写只读 `cycle` illegal；模块回归、lint、build、cpu-tests 均通过。
- `risk_assessment`: 本轮没有实现 `minstret/time/mcounteren` 和更细粒度 privilege 访问控制；若后续接 S/U mode 或完整 counter delegation，需要重新扩展 CSR 权限模型。
