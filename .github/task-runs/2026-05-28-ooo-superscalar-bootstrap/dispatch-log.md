# Dispatch Log

## 基本信息

- `task_id`: `2026-05-28-ooo-superscalar-bootstrap`
- `task_slug`: `ooo-superscalar-bootstrap`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-28 22:20] `recall` - `completed`

- `owner_agent`: codex
- `trigger`: 用户设定目标“完成一个乱序超标量处理器，cpi=0.5”
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、project-status、known-issues、npc memory、NPC study README/checklist
- `action`: 读取项目规则、NPC 当前状态和现有流水线结构。
- `outputs`: 明确当前核心为顺序单发流水线，提交口在 MEM/WB，已有 DiffTest/CSR/cache/BPU 闭环。
- `evidence`: 读取命令输出；`make -C npc/sim status` 显示当前 backend 为 single。
- `handoff_to`: `arch-cut`
- `next_step`: 选择不破坏主路径的第一阶段 OoO 基础件。
- `notes`: 工作树已有与本任务无关的 outputs 目录修改/删除，未触碰。

### [2026-05-28 22:32] `rtl-implement` - `completed`

- `owner_agent`: codex
- `trigger`: RTL 推导完成
- `depends_on`: `recall`、`arch-cut`、`rtl-derive`
- `inputs`: 需求、协议、状态机、不变量、数据通路约束
- `action`: 新增 `OooRenameMap`、`OooFreeList`、`OooRob`，同步接入 filelist 和模块 testbench。
- `outputs`: OoO 基础件 RTL 与 3 个 testbench。
- `evidence`: 文件落盘。
- `handoff_to`: `verify`
- `next_step`: 运行新增 testbench、lint、全量模块回归和 smoke。
- `notes`: 新模块暂不接入 `NpcCore` 主路径。

### [2026-05-28 22:43] `verify` - `completed`

- `owner_agent`: codex
- `trigger`: RTL/testbench 落盘完成
- `depends_on`: `rtl-implement`
- `inputs`: 新增 OoO 模块和 testbench
- `action`: 运行新增 testbench、NPC single lint、全量模块 testbench、Verilator build、AM/NPC smoke 与 diff check。
- `outputs`: 验证全部通过。
- `evidence`: `tb_ooo_rename_map` PASS；`tb_ooo_free_list` PASS；`tb_ooo_rob` PASS；`make -C npc/single lint` PASS；全量模块 30/30 PASS；`make -C npc/single -j4` PASS；`cpu-tests add` GOOD TRAP；`git diff --check` PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory 与 task-run。
- `notes`: 第一次 `cpu-tests` smoke 未显式设置 `AM_HOME`，失败于 `/Makefile` include；设置 `AM_HOME/NPC_HOME/NEMU_HOME` 后复跑通过，判定为调用环境问题而非 RTL 问题。

### [2026-05-28 22:50] `record` - `completed`

- `owner_agent`: codex
- `trigger`: 验证通过
- `depends_on`: `verify`
- `inputs`: 验证结果与改动清单
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md` 和本 task-run。
- `outputs`: 长期记忆与任务证据链更新。
- `evidence`: 本文件与 `task-report.md`。
- `handoff_to`: 无
- `next_step`: 下一阶段接入 2-wide decode/rename bundle adapter。
- `notes`: 完成的是 OoO bootstrap，不是完整目标。

