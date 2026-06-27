# 派发日志

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-fetch-head-pair-gate`
- `task_slug`: `npc-rv64-fetch-head-pair-gate`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-06-27] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求继续优化 RV64 RTL。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/modules/npc.md`、RV64 RTL workflow、`OooAluFetchCore` 源码。
- `action`: 复核上一轮 `OooFetchHeadClassifyGate` 结果，扫描 `OooAluFetchCore` 剩余组合密集区和 head facts 下游引用。
- `outputs`: 选择 `OooFetchHeadPairGate` 作为下一刀。
- `evidence`: 对话工具输出。
- `handoff_to`: `spec`
- `next_step`: 落项目内 spec 与实施计划。
- `notes`: 当前工作树已有大量非本轮变更，后续继续路径限定编辑本任务相关文件。

### [2026-06-27] `spec` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要在 RTL 前完成需求、协议、状态机、不变量、数据通路推导。
- `depends_on`: `recall`
- `inputs`: head pair 逻辑和上一轮 classifier 边界。
- `action`: 写入 `npc/rv64/design/specs/ooo-fetch-head-pair-gate.md`。
- `outputs`: 项目内正式 spec。
- `evidence`: `npc/rv64/design/specs/ooo-fetch-head-pair-gate.md`
- `handoff_to`: `plan`
- `next_step`: 编写 implementation plan。
- `notes`: spec 明确 pair gate 内部持有两个 classifier 实例，父模块保留所有时序 owner。

### [2026-06-27] `plan` - `completed`

- `owner_agent`: `codex`
- `trigger`: spec 已落盘，需要执行级步骤。
- `depends_on`: `spec`
- `inputs`: `npc/rv64/design/specs/ooo-fetch-head-pair-gate.md`、`OooAluFetchCore` 当前 wire 命名、现有 testbench Makefile。
- `action`: 写入 `implementation-plan.md`，拆为 test、RTL、父模块接线、focused、regression、record。
- `outputs`: 可执行计划。
- `evidence`: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-pair-gate/implementation-plan.md`
- `handoff_to`: `test`
- `next_step`: 先写 failing module testbench。
- `notes`: 计划限定为纯组合 owner；不移动 pending、CSR、FIFO、RAS/BPU 或 PC/outstanding 状态。

### [2026-06-27] `test` - `completed`

- `owner_agent`: `codex`
- `trigger`: TDD 红灯要求。
- `depends_on`: `plan`
- `inputs`: spec 验证计划、上一轮 `OooFetchHeadClassifyGate` 接口。
- `action`: 新增 `tb_ooo_fetch_head_pair_gate.sv`，覆盖 idle、双槽 ALU、lane0 branch/stop/fault 抑制、lane1 fault、branch-spec block、IRQ/can-run、FS-off FP 和 direct branch0 alias；登记 Makefile 目标。
- `outputs`: focused testbench。
- `evidence`: `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_pair_gate" RESULT_DIR=../perf/results/20260627-fetch-head-pair/failing run` 因 `Unknown module type: OooFetchHeadPairGate` 失败，符合 RED 预期。
- `handoff_to`: `rtl`
- `next_step`: 实现最小 RTL 通过单测。
- `notes`: 初次 GREEN 前曾修正 testbench `tb_finish()` 参数，随后单测 PASS。

### [2026-06-27] `rtl` - `completed`

- `owner_agent`: `codex`
- `trigger`: RED 已确认。
- `depends_on`: `test`
- `inputs`: failing TB、`OooFetchHeadClassifyGate`、父模块原 head pair 组合逻辑。
- `action`: 新增 `frontend/OooFetchHeadPairGate.v`，登记 `filelist.mk`，内部实例化两个 classifier 并生成 fetch fault、branch-spec dispatch block、dispatch valid 和 dispatch0 facts。
- `outputs`: 新 pair gate RTL。
- `evidence`: `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_pair_gate" RESULT_DIR=../perf/results/20260627-fetch-head-pair/module run` PASS。
- `handoff_to`: `focused-verify`
- `next_step`: 接入 `OooAluFetchCore` 并跑 focused 回归。
- `notes`: 模块无寄存器、无 ready/valid 存储。

### [2026-06-27] `focused-verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: pair gate 单测 PASS。
- `depends_on`: `rtl`
- `inputs`: `OooAluFetchCore.v` 当前 head pair 内联逻辑。
- `action`: 用 `OooFetchHeadPairGate u_fetch_head_pair_gate` 替换父模块内两个 classifier 实例、`head*_decode_valid`、fetch fault、branch-spec dispatch block 和 dispatch0 facts 内联赋值；保留 ready/unsupported/fire、direct JAL/ret、RAS/BPU 和 pending/CSR 时序。
- `outputs`: 父模块接线更新。
- `evidence`: `rg` 旧实例/临时线/重复赋值扫描为空；focused `tb_ooo_fetch_head_pair_gate tb_ooo_fetch_head_classify_gate tb_ooo_alu_fetch_core tb_decode_unit` 4/4 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64` PASS。
- `handoff_to`: `regression`
- `next_step`: 跑默认 module regression 与 official smoke。
- `notes`: 一次 WSL 长输出读取返回 `0x8007274c`，最小命令和后续验证均正常，判断为桥接层偶发噪声。

### [2026-06-27] `regression` - `completed`

- `owner_agent`: `codex`
- `trigger`: focused 与 lint/build PASS。
- `depends_on`: `focused-verify`
- `inputs`: 最新 RTL 与 testbench。
- `action`: 运行默认 module testbench 和 official `rv64ui/rv64mi/rv64si` smoke。
- `outputs`: 回归证据。
- `evidence`: 默认 module testbench `RESULT_DIR=../perf/results/20260627-fetch-head-pair/full-rerun` 102/102 PASS；official run dir `npc/rv64/perf/results/20260627-fetch-head-pair/core-regress-official/20260627-124346-64026/`，`overall_rc=0`。
- `handoff_to`: `record`
- `next_step`: 更新 README、memory 与 task-run。
- `notes`: 第一次 full module 命令遇到 WSL `E_UNEXPECTED`，重跑通过；该异常未复现为测试失败。

### [2026-06-27] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 回归完成。
- `depends_on`: `regression`
- `inputs`: 验证输出和改动文件列表。
- `action`: 更新 `npc/rv64/vsrc/README.md`、`.github/memory/project-status.md`、`.github/memory/modules/npc.md` 和本 task-run 报告。
- `outputs`: 项目记录闭环。
- `evidence`: 相关 markdown 文件已更新；path-limited `git diff --check` 按 RTL/TB、项目文档、task-run、memory 四组运行均 PASS；`git status --short -- <本轮路径>` 显示本轮文件仍留在工作区，未 stage/commit。
- `handoff_to`: 无
- `next_step`: 等待下一轮优化指令。
- `notes`: 未 stage、未 commit，避免触碰工作区已有非本轮变更。
