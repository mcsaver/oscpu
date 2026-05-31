# Dispatch Log

## 基本信息

- `task_id`: `2026-05-29-ooo-simtop-stats-audit`
- `task_slug`: `ooo-simtop-stats-audit`
- `graph_template`: `regression-debug-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-29] `recall` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 用户询问 OoO/superscalar 顶层与统计失效。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`、NPC study 索引。
- `action`: 按项目规则读取 RECALL 上下文。
- `outputs`: 明确当前 OoO 统计历史位于 `NpcSimTop.sv/cpu-exec.cpp`，且曾有 cache 统计迁移经验。
- `evidence`: 相关 memory 已记录 core-top、bridge cache 与 OoO pipeline 统计。
- `handoff_to`: `simtop-stat-chain-audit`
- `next_step`: 搜索并阅读统计 DPI 调用链。
- `notes`: 任务只读，不涉及 RTL 生成四段式改码。

### [2026-05-29] `simtop-stat-chain-audit` - `completed`

- `owner_agent`: `Codex`
- `trigger`: Branch/BPU 统计全 0，但 cache/OoO 统计有数据。
- `depends_on`: `recall`
- `inputs`: `npc/single/vsrc/sim/NpcSimTop.sv`、`npc/single/vsrc/core/NpcCoreTop.v`、`npc/single/vsrc/ooo/OooAluFetchCore.v`、`npc/single/csrc/cpu/cpu-exec.cpp`
- `action`: 追踪 `npc_control_flow_event`、`npc_bpu_lookup_event`、`npc_bpu_resolve_event` 与 OoO 统计事件的宏分支和层次化采样源。
- `outputs`: 确认 OoO 模式下 Branch/BPU 统计被 tie-off；cache/OoO 统计有实际采样源。
- `evidence`: `NpcSimTop.sv:559-583`、`NpcSimTop.sv:639-674`、`NpcSimTop.sv:699-721`、`cpu-exec.cpp:243-318`
- `handoff_to`: `verify`
- `next_step`: 运行当前构建冒烟确认。
- `notes`: `branch_prefetch_hit_available_w` 是状态可用信号，当前打印名 `fire/hit` 容易误导。

### [2026-05-29] `verify` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 需要确认当前工作树的 OoO 构建状态。
- `depends_on`: `simtop-stat-chain-audit`
- `inputs`: `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -j4`
- `action`: 运行构建命令。
- `outputs`: 构建系统报告当前目标 up-to-date。
- `evidence`: `make: Nothing to be done for 'default'.`
- `handoff_to`: `record`
- `next_step`: 更新 memory 和 task-run。
- `notes`: 没有跑完整 CoreMark；用户截图已提供 PASS 与非零 cache/OoO 统计，当前任务是统计链路审计。

### [2026-05-29] `record` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 完成审计。
- `depends_on`: `verify`
- `inputs`: 审计结论。
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md` 与本 task-run。
- `outputs`: 稳定结论已记录。
- `evidence`: 本目录 `task-report.md`。
- `handoff_to`: 无
- `next_step`: 如需修复，新增 OoO 只读统计端口或 DPI 事件。
- `notes`: 无源码逻辑改动。

### [2026-05-29] `host-stat-fix` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 用户要求“请你修复”。
- `depends_on`: `simtop-stat-chain-audit`
- `inputs`: `npc/single/csrc/cpu/cpu-exec.cpp` 的 commit event、BPU 统计累加函数与 OoO cycle event。
- `action`: 在 `NPC_OOO_ALU_EXPERIMENT` 下从 `npc_commit_event(pc, inst, next_pc, ...)` 解码 opcode，恢复 B-type/JAL/JALR/ret 分类和静态 backward-taken/forward-not-taken 的 branch direction accuracy；将 `branch_prefetch_hit_available` 的统计改为上升沿事件计数。
- `outputs`: OoO 模式 Branch/Jump 与基础 BPU resolve 统计不再全 0；`branch prefetch hit` 不再按状态保持周期重复累加。
- `evidence`: `npc/single/csrc/cpu/cpu-exec.cpp`
- `handoff_to`: `verify-fix`
- `next_step`: 运行 OoO/非 OoO 构建与 OoO CPU-test 冒烟。
- `notes`: 未修改 RTL；BTB/RAS lookup hit/miss 没有可用 OoO 事件源，保持未恢复状态。

### [2026-05-29] `verify-fix` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 修复后需要验证统计恢复且不破坏非 OoO 构建。
- `depends_on`: `host-stat-fix`
- `inputs`: `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -j4`、`./npc/single/build/NpcSimTop ./am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress --max-cycles 2000000`、`make -C npc/single NPC_OOO_ALU_EXPERIMENT=0 -B -j4`、`make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4`
- `action`: 先构建 OoO，再跑 `add` CPU-test 冒烟，然后强制构建非 OoO，最后强制重建回 OoO 二进制。
- `outputs`: OoO/非 OoO build 均 PASS；OoO 冒烟 GOOD TRAP，控制流统计恢复。
- `evidence`: `conditional branch=145 (taken 0, not-taken 145)`、`JAL=75`、`JALR=74`、`total jump/branch=294`、`branch accuracy=73/145`、`branch prefetch fire/hit=62/61`
- `handoff_to`: `record`
- `next_step`: 更新 memory 与 task-run 收尾。
- `notes`: 观察到普通 `make -C npc/single` 在切换 `NPC_OOO_ALU_EXPERIMENT` 后可能报告 up-to-date；验证非 OoO 时使用了 `-B`，这是相邻构建系统风险，未在本任务内修复。

### [2026-05-29] `simtop-lookup-fix` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 用户要求通过层次化引用从仿真顶层修复 BTB 和 RAS lookup 统计。
- `depends_on`: `host-stat-fix`
- `inputs`: `npc/single/vsrc/sim/NpcSimTop.sv`、`npc/single/vsrc/ooo/OooAluFetchCore.v` 内部 JALR/RAS 信号。
- `action`: 在 `NPC_OOO_ALU_EXPERIMENT` 分支中增加 `sim_ooo_pending_jalr_*`、`sim_ooo_direct_ras_lookup_w`、`sim_ooo_ras_*`、`sim_ooo_btb_lookup_event_w` 等顶层只读统计线，并复用 `npc_bpu_lookup_event` 上报。普通非 return JALR 和 RAS underflow fallback 计为 JALR target miss；RAS 有 top 的 return 计 hit；push 满栈计 overflow。
- `outputs`: OoO 模式下 `BTB JALR lookup` 与 `RAS lookup` 不再因事件源缺失保持 0/0。
- `evidence`: `NpcSimTop.sv` OoO 宏分支层次化引用 `u_core.u_ooo_core.pending_jump_*`、`direct_ret*`、`ras_empty_w/ras_full_w`。
- `handoff_to`: `verify-lookup-fix`
- `next_step`: 构建并用含 return/普通 JALR 的样本验证。
- `notes`: 当前 OoO 没有 JALR BTB 预测器，因此 BTB hit 预期仍为 0，miss 代表未预测的 JALR target 解析。

### [2026-05-29] `verify-lookup-fix` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 需要证明 lookup 统计恢复且宏隔离不破坏非 OoO。
- `depends_on`: `simtop-lookup-fix`
- `inputs`: `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4`、OoO `add/switch/recursion/hello-str` CPU-test 冒烟、`make -C npc/single NPC_OOO_ALU_EXPERIMENT=0 -B -j4`、最终 OoO 重建。
- `action`: 强制构建 OoO，运行多个短样本观察 lookup 统计，再强制构建非 OoO，最后强制重建回 OoO。
- `outputs`: 构建均 PASS；样本均 GOOD TRAP；RAS 与 BTB/JALR lookup 统计恢复。
- `evidence`: `add`: `RAS lookup hit 74, miss 0`；`recursion`: `BTB JALR lookup hit 0, miss 218`、`RAS lookup hit 129, miss 0`；`hello-str`: `BTB miss 7`、`RAS hit 43`；`switch`: `RAS hit 17`。
- `handoff_to`: `record`
- `next_step`: 更新 memory 与 task-run 收尾。
- `notes`: `BTB hit 0` 是当前 OoO 无 JALR BTB 的实现结果，不是统计未接入。
