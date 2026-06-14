# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-npc-bpu-local-pht-pcbits`
- `task_slug`: `npc-bpu-local-pht-pcbits`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-22 10:25] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户提供弱跳转初值后的 CoreMark 复跑截图。
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study README。
- `action`: 读取项目规则、当前 BPU 状态与已知问题。
- `outputs`: 确认本轮继续从 BPU top miss PC 和 local predictor alias 入手。
- `evidence`: 用户截图与本地弱跳转结果一致，branch miss 仍为 `2458726`。

### [2026-05-22 10:32] `analyze-result` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `recall`
- `inputs`: 用户截图、CoreMark 反汇编。
- `action`: 反查 `0x800007bc/0x80000c56/0x80000c4a/0x80000c02/0x80000bfa/0x80000b8e/0x80000726/0x80000cf2`。
- `outputs`: miss 仍集中在链表遍历和 `core_state_transition` 字符分类；多个状态机分支在旧 local PHT 的 `pc[2:1]` 桶中别名。
- `evidence`: 反汇编显示 `0x80000c02/0x80000c4a/0x80000bfa/0x80000cf2` 等均在 `core_state_transition` 内。

### [2026-05-22 10:36] `implement` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `analyze-result`
- `inputs`: `BranchPredictor.v`、`tb_branch_predictor.sv`。
- `action`: 将 local PHT index 改为 `{pc[4:1], local_history[7:0]}`，PHT 从 1024 项增至 4096 项；新增低位 alias 规避单测。
- `outputs`: RTL 与 testbench 修改。
- `evidence`: `git diff`。

### [2026-05-22 10:42] `ab-test` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `implement`
- `inputs`: strong-local 与 valid-local 两种 mux 策略。
- `action`: 临时改成 local valid 直接覆盖 gshare，跑 testbench/lint/CoreMark。
- `outputs`: valid-local 更差，恢复 strong-local。
- `evidence`: valid-local CoreMark `cycles=390099474`、branch miss `2267352`；strong-local final `cycles=389956180`、branch miss `2196215`。

### [2026-05-22 10:48] `verify` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `ab-test`
- `inputs`: 最终 RTL。
- `action`: 运行模块 testbench、lint、build、CoreMark、cpu-tests。
- `outputs`: 全部验证通过。
- `evidence`: 模块 testbench 21/21 PASS；lint PASS；build PASS；CoreMark GOOD TRAP；cpu-tests 38/38 PASS。

### [2026-05-22 10:56] `record` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `verify`
- `inputs`: 本轮结论和验证数据。
- `action`: 更新 project status、NPC module memory 和 task-run。
- `outputs`: 记录落盘。
- `evidence`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、本目录。
