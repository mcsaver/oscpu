# Task Report

## 基本信息

- `task_id`: `2026-05-19-npc-pipeline-zicsr-trap`
- `task_slug`: `npc-pipeline-zicsr-trap`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-19 18:30 +0800`
- `updated_at`: `2026-05-19 20:05 +0800`

## 任务目标

- `source_request`: “学习 NEMU 中的实现，完成对应 NPC 的开发，顺便加上流水线”
- `goal`: 对照 NEMU RV32 `SYSTEM/Zicsr/trap` 语义，补齐 NPC 最小 M-mode CSR/trap，并将核心从单在途多周期改为可跑 AM/NPC 回归的顺序流水线。
- `scope`: `npc/single/vsrc/{define.v,DecodeUnit.v,WBU.v,NpcCore.v}`、`abstract-machine/am/src/riscv/npc/{cte.c,trap.S}`、项目记忆与 task-run 记录。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 本任务同时涉及 NEMU 参考学习、RTL 控制/数据通路、AM CTE 软件协定与回归验证，现有单一模板不能完整覆盖。
- `dynamic_nodes_added`: `rtl-derivation`、`pipeline-implementation`、`csr-trap-implementation`、`am-cte-implementation`、`hazard-debug`
- `why_dynamic_nodes_were_needed`: 流水线开发需要按握手协议、精确异常和冒险修复动态补节点。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | codex | completed | `.github/AGENTS.md`、Copilot instructions、memory、NPC study docs、NEMU RV32 system implementation | 约束、调用链、参考语义 | 已按项目规则读取并在实现前完成分析 |
| `rtl-derivation` | codex | completed | NEMU `inst.c/intr.c/isa-def.h`、NPC 原 `NpcCore/DecodeUnit`、AM NPC CTE | 四阶段 RTL 设计推导 | 需求/协议/FSM/不变量/数据通路见下文 |
| `pipeline-implementation` | codex | completed | 原单在途 NpcCore | IF/ID/EX/MEM/WB 顺序流水、fetch buffer、转发、stall、flush | `make -C npc/single lint` PASS，`cpu-tests` 35/35 PASS |
| `csr-trap-implementation` | codex | completed | NEMU Zicsr/trap 语义 | CSR block、Zicsr 读改写、ecall/mret/wfi/ebreak | `yield-os` 持续输出 `ABAB...` |
| `am-cte-implementation` | codex | completed | NEMU AM CTE 语义、NPC trap.S | NPC `yield/kcontext/iset/ienabled` 与 Context 返回切换 | `yield-os` 协作式切换烟测通过 |
| `hazard-debug` | codex | completed | 跑飞现场与 trace | 修复 IF 返回丢失、MEM 响应同拍转发 | `am-tests mainargs=i` 不再跑飞，完整 `cpu-tests` PASS |
| `records` | codex | completed | 实现与验证结果 | memory 与 task-run 更新 | `.github/memory/*`、本目录 |

## RTL 推导摘要

- 需求：保持现有 DPI IFU/LSU ready-valid 外壳和 commit/trap/exit 观测口，支持 RV32I 主路径、Zicsr、`ecall/ebreak/mret/wfi`、最小 M-mode CSR，并让 AM `yield-os` 能通过 trap handler 返回。
- 协议：IF 允许 1 个 outstanding 请求和 1 项返回缓存；ID 只在 EX 可接收且无 load-use 时推进；MEM 指令必须等 LSU response；redirect/trap/mret 清空年轻级；单周期最多向 WB 提交一条。
- FSM/寄存器：用 `fetch_pending/fetch_buf_valid/if_id_valid/id_ex_valid/ex_mem_valid/mem_pending/mem_wb_valid` 表达各级状态，不再使用全局单一状态机。
- 不变量：x0 不写；CSR 只读项不可写；异常、trap 和 mret 精确 flush；错误路径不提交；load 消费者必须通过 stall 或同拍转发拿到新值；`ebreak` 仍作为 host 退出协议。
- 数据通路：Decode 产生统一 ctrl bus；EX 做 ALU、Compare、CSR read-modify-write、trap/mret/branch target；MEM 做 LSU；WB 提供统一 commit 和 RF 写回。转发优先级为 LSU response load data、EX/MEM 非 load 结果、MEM/WB 结果、寄存器原值。

## 关键产物

- `artifacts`: NPC 流水线 RTL、NPC Zicsr/trap、AM NPC CTE/trap.S。
- `logs_or_traces`: 本轮终端验证命令与 PASS/timeout 证据。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/abstract-machine.md`、`.github/memory/known-issues.md`。

## 验证证据

- `make -C npc/single`: PASS。
- `make -C npc/single lint`: PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run`: PASS，`HIT GOOD TRAP`，`cycles=2319`，`commits=839`，`CPI=2.764`。
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 35/35 PASS。
- `timeout 12s make -C am-kernels/tests/am-tests ARCH=riscv32-npc run mainargs=i NPC_RUN_ARGS='-m 0'`: 进入 `Hello, AM World` 交互菜单并稳定运行到 1000 万条指令后被 timeout 终止，没有复现 PC 跑飞。
- `timeout 4s make -C am-kernels/kernels/yield-os ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0'`: 持续输出 `ABAB...` 后按预期 timeout，证明 `ecall -> mtvec -> handler -> mret` 与 Context 切换可用。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 尚未接入 NPC difftest、mtime/mtimecmp 与外部中断投递。
- `risk_assessment`: 当前 trap 支持 direct `mtvec`、M-mode 最小 CSR 与同步 ecall；未覆盖 S-mode/PMP/真实异步中断。流水线已过 RV32I cpu-tests，但后续扩设备和 difftest 时仍需复验精确提交。

## 下一步建议

1. 给 NPC 增加 difftest 或提交级对拍，覆盖流水线精确提交与 CSR 状态。
2. 补 `mtime/mtimecmp` 与 `mie/mip` 中断投递，再扩 `am-tests mainargs=i` 的真实 timer interrupt 证据。
3. 重新跑 `make -C npc/single syn` / `sta`，评估流水线化后的面积、时序和电气约束变化。

## 模板升级候选

- `repeated_dynamic_subgraph`: `reference-study -> rtl-derivation -> implementation -> smoke -> regression -> memory-update`
- `should_promote_to_static_template`: `yes`
- `reason`: NEMU 参考语义迁移到 NPC RTL 的工作会反复出现，适合沉淀成专门的 `npc-reference-rtl-loop`。

## 收尾结论

- `final_result`: NPC 已具备 RV32I 顺序流水线、最小 Zicsr/M-mode trap、AM CTE/yield/kcontext 闭环。
- `evidence_summary`: NPC 构建/lint 通过，`cpu-tests` 35/35 PASS，`yield-os` 可持续协作式切换。
- `notes`: 本轮未处理已有无关 NEMU/cache/BPU/文档改动，工作树仍包含用户或先前任务留下的其它修改。
