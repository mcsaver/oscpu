# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-npc-mcycle-csr`
- `task_slug`: `npc-mcycle-csr`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-22 15:00] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求按 RISC-V 特权架构手册补齐 `mcycle`。
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study/instructions。
- `action`: 读取现有 CSR/trap 框架和项目记录。
- `outputs`: 确认本轮应收敛在 `NpcCore` 内的 machine CSR block，不改外部端口。
- `evidence`: 现有 `NpcCore` 已有 CSR known/writable/read/write mux 与 illegal CSR trap。

### [2026-05-22 15:05] `spec-check` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `recall`
- `inputs`: RISC-V privileged architecture snapshot。
- `action`: 确认 `mcycle` 计核心周期、RV32 `mcycleh` 分半读写、`cycle` shadow、`mcountinhibit.CY` inhibit 语义。
- `outputs`: 本轮实现范围定为 `mcycle/mcycleh/cycle/cycleh/mcountinhibit.CY`。
- `evidence`: 官方 spec 与本地抽取笔记一致。

### [2026-05-22 15:12] `rtl-derive` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `spec-check`
- `inputs`: 现有 `NpcCore` CSR 写回路径。
- `action`: 按需求、协议、状态机、不变量、数据通路四阶段推导实现。
- `outputs`: 形成无新 FSM、无端口变更、CSR 写覆盖默认递增的实现方案。
- `evidence`: `task-report.md` 的 “RTL 推导摘要”。

### [2026-05-22 15:20] `implement` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `rtl-derive`
- `inputs`: `NpcCore.v`、`define.v`、testbench Makefile。
- `action`: 新增 CSR 宏、`csr_mcycle_q`、`csr_mcountinhibit_q`、CSR decode/read/write 逻辑和专用 testbench。
- `outputs`: RTL 与测试文件修改完成。
- `evidence`: `git diff`。

### [2026-05-22 15:35] `verify` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `implement`
- `inputs`: 最终 RTL 与新增单测。
- `action`: 运行模块 testbench、Verilator lint、Verilator build、全量 cpu-tests。
- `outputs`: 全部验证通过。
- `evidence`: testbench 22/22 PASS；lint PASS；build PASS；cpu-tests 38/38 PASS。

### [2026-05-22 15:50] `record` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `verify`
- `inputs`: 本轮结论和验证数据。
- `action`: 更新 project status、NPC module memory 和 task-run。
- `outputs`: 记录落盘。
- `evidence`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、本目录。
