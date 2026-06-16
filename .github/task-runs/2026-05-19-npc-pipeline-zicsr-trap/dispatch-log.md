# Dispatch Log

## 基本信息

- `task_id`: `2026-05-19-npc-pipeline-zicsr-trap`
- `task_slug`: `npc-pipeline-zicsr-trap`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-19 18:30] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求学习 NEMU 并完成 NPC 开发/流水线化。
- `depends_on`: 无。
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/*`、NPC study docs、NEMU RV32 `inst.c/intr.c/isa-def.h`。
- `action`: 读取项目规则、NEMU 参考实现、NPC 当前 RTL/AM 接口，明确跨模块调用链。
- `outputs`: 实现边界与验证计划。
- `evidence`: 开工前完成规则和相关模块文档读取。
- `handoff_to`: `rtl-derivation`
- `next_step`: 输出 RTL 推导并开始落地。
- `notes`: 工作树已有大量无关改动，本任务只触碰 NPC/AM 和记录文件。

### [2026-05-19 18:45] `rtl-derivation` - `completed`

- `owner_agent`: `codex`
- `trigger`: RTL 修改前需先做四阶段推导。
- `depends_on`: `recall`
- `inputs`: NEMU Zicsr/trap 语义、NPC 原单在途核心、IFU/LSU ready-valid 协议。
- `action`: 形成需求、协议、FSM/valid 位、不变量、数据通路推导。
- `outputs`: 顺序五级流水 + 最小 M-mode CSR/trap 设计。
- `evidence`: 已写入 `task-report.md` 的 “RTL 推导摘要”。
- `handoff_to`: `pipeline-implementation`
- `next_step`: 修改 Decode/control/WBU/NpcCore。
- `notes`: trap 目标先支持 direct `mtvec`，`wfi` 作为合法 no-op。

### [2026-05-19 19:20] `pipeline-implementation` - `completed`

- `owner_agent`: `codex`
- `trigger`: 实现 NPC 流水线。
- `depends_on`: `rtl-derivation`
- `inputs`: 原 `NpcCore.v`、`define.v`、`DecodeUnit.v`、`WBU.v`。
- `action`: 扩控制总线和 CSR 写回选择；重写核心为 IF/ID/EX/MEM/WB；接入转发、stall、flush 和 fetch buffer。
- `outputs`: `npc/single/vsrc/{define.v,DecodeUnit.v,WBU.v,NpcCore.v}`。
- `evidence`: 后续 `make -C npc/single` 与 `make -C npc/single lint` PASS。
- `handoff_to`: `csr-trap-implementation`
- `next_step`: 接入 CSR/trap/mret 语义。
- `notes`: `ebreak` 保留为 host 退出协议。

### [2026-05-19 19:35] `am-cte-implementation` - `completed`

- `owner_agent`: `codex`
- `trigger`: NPC `ecall/mret` 需要 AM trap handler 配合。
- `depends_on`: `csr-trap-implementation`
- `inputs`: NEMU AM CTE 语义、NPC `cte.c/trap.S`。
- `action`: 补 `EVENT_YIELD/SYSCALL` 映射、`mepc += 4`、`kcontext()`、`ienabled()/iset()`、trap.S handler 返回 Context 切换。
- `outputs`: `abstract-machine/am/src/riscv/npc/{cte.c,trap.S}`。
- `evidence`: `yield-os` 持续输出 `ABAB...`。
- `handoff_to`: `hazard-debug`
- `next_step`: 跑 AM/NPC 验证并修复流水线冒险。
- `notes`: `trap.S` 在恢复现场前执行 `mv sp, a0` 是支持调度的关键。

### [2026-05-19 19:50] `hazard-debug` - `completed`

- `owner_agent`: `codex`
- `trigger`: `am-tests mainargs=i` 初版出现 PC 跑飞。
- `depends_on`: `pipeline-implementation`
- `inputs`: 失败现场 PC `0x00007980`、跳表/load-use 线索。
- `action`: 修复 IF 返回缓存容量计算；为 EX 操作数加入 LSU load response 同拍前递。
- `outputs`: 稳定 fetch/LSU 冒险处理。
- `evidence`: `am-tests mainargs=i` 能进入交互菜单并运行到 1000 万条指令；完整 `cpu-tests` 35/35 PASS。
- `handoff_to`: `verify`
- `next_step`: 跑最终验证矩阵。
- `notes`: 该问题已同步写入 `known-issues.md` 的 resolved 条目。

### [2026-05-19 20:05] `verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: 实现完成后做闭环验证。
- `depends_on`: `pipeline-implementation`、`am-cte-implementation`、`hazard-debug`
- `inputs`: 当前工作树。
- `action`: 运行 NPC 构建、lint、单项 add、完整 cpu-tests、am-tests 交互 smoke、yield-os smoke。
- `outputs`: PASS/timeout 证据。
- `evidence`: `make -C npc/single` PASS；`make -C npc/single lint` PASS；`ALL=add` PASS；`cpu-tests` 35/35 PASS；`yield-os` 输出 `ABAB...` 后 timeout。
- `handoff_to`: `records`
- `next_step`: 更新 memory 与 task-run。
- `notes`: `am-tests mainargs=i` 是交互/持续运行测试，timeout 本身不是失败；本轮重点用它确认不再跑飞。

### [2026-05-19 20:05] `records` - `completed`

- `owner_agent`: `codex`
- `trigger`: 项目规则要求任务完成后更新 memory 与 task-runs。
- `depends_on`: `verify`
- `inputs`: 实现摘要与验证结果。
- `action`: 更新 project status、NPC/AM 模块笔记、resolved known issue，并新增本 task-run 报告。
- `outputs`: `.github/memory/project-status.md`、`.github/memory/modules/{npc,abstract-machine}.md`、`.github/memory/known-issues.md`、本目录。
- `evidence`: 文件已落盘。
- `handoff_to`: 无。
- `next_step`: 最终答复用户。
- `notes`: 无。
