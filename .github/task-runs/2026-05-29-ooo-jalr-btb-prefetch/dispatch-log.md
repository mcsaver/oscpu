# Dispatch Log

## 基本信息

- `task_id`: `2026-05-29-ooo-jalr-btb-prefetch`
- `task_slug`: `ooo-jalr-btb-prefetch`
- `graph_template`: `rtl-regression-debug-loop`
- `log_policy`: `append-only`

---

### [2026-05-29] `recall-and-audit` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 用户询问 OoO 无 JALR BTB 与 BPU 是否冲突。
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、NPC memory、`BranchPredictor.v`、`IfStage.v`、`OooAluFetchCore.v`。
- `action`: 对比顺序核 `BranchPredictor` 与 OoO 前端。
- `outputs`: 确认 OoO 宏路径没有实例化顺序核 `IfStage/BranchPredictor`；普通 JALR 只在 drain 后 resolve。
- `evidence`: `NpcCoreTop.v` 的 OoO/顺序核互斥实例化；`OooAluFetchCore.v` 的 `pending_jump_q/pending_jump_resolved_target_w` 路径。
- `next_step`: 设计 OoO 内部等价 JALR BTB。

### [2026-05-29] `rtl-derivation` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 准备修改 OoO RTL。
- `inputs`: 原 BPU BTB/RAS 语义与 OoO shadow prefetch 状态机。
- `action`: 完成四段式推导：需求、协议/不变量、数据通路、验证计划。
- `outputs`: 选择在 OoO 内部实现 PC-tagged JALR BTB，并复用 `branch_prefetch_*` 影子槽；不新增端口 ABI。
- `evidence`: `task-report.md` 的 RTL 四段式推导。
- `next_step`: 修改 `OooAluFetchCore.v` 与 `NpcSimTop.sv`。

### [2026-05-29] `rtl-implementation` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 实现普通 JALR BTB 与统计 hit。
- `inputs`: `OooAluFetchCore.v`、`NpcSimTop.sv`。
- `action`: 增加 `jalr_btb_*` 表、JALR BTB lookup/hit/update、JALR shadow prefetch match/promote/discard；仿真顶层读取 `pending_jump_jalr_btb_hit_w`。
- `outputs`: 普通 JALR 可以在 pending drain 期间预取 BTB target；统计能区分 hit/miss。
- `evidence`: `OooAluFetchCore.v`、`NpcSimTop.sv` diff。
- `next_step`: 构建与 focused testbench。

### [2026-05-29] `focused-verify` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 初版 RTL 需要快速验证。
- `inputs`: `make -C npc/single/testbench run TESTS=tb_ooo_alu_fetch_core`、`make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4`。
- `action`: 运行 focused Icarus testbench 与 OoO Verilator build。
- `outputs`: 二者均 PASS。
- `evidence`: `tb_ooo_alu_fetch_core` PASS；OoO build PASS。
- `next_step`: 样本运行观察 BTB hit。

### [2026-05-29] `bad-trap-debug` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `hello-str` 初跑 BAD TRAP。
- `inputs`: `hello-str` 统计、JALR shadow hit/no-link commit 时序。
- `action`: 定位到 JALR shadow hit 转正时，`pending_jump_nolink_commit_w` 同拍 redirect 仍可能额外发一笔同目标 fetch；重复 response 之后污染前端。
- `outputs`: no-link JALR shadow hit 且同拍 redirect fire 时，用 `discard_fetch_rsp_q` 丢弃重复 response。
- `evidence`: 修复后 `hello-str` GOOD TRAP，`BTB JALR lookup=hit 6, miss 1`。
- `next_step`: 重新跑 focused 与代表样本。

### [2026-05-29] `sample-verify` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 验证 hit 非零与代表样本正确性。
- `inputs`: `add`、`hello-str`、`recursion`。
- `action`: 串行运行代表样本。
- `outputs`: 样本均 GOOD TRAP；`add` 只有 RAS return，BTB lookup 仍 0/0；`hello-str/recursion` 普通 JALR BTB hit 非零。
- `evidence`: `hello-str hit 6/miss 1`；`recursion hit 212/miss 6`。
- `next_step`: 全量 CPU-test。

### [2026-05-29] `full-regression` - `completed`

- `owner_agent`: `Codex`
- `trigger`: BPU/OoO 性能改动必须全量验证。
- `inputs`: `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine NPC_OOO_ALU_EXPERIMENT=1 NPC_SIM_HOME=/home/lyg/PA/ysyx-workbench/npc/single make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS="--max-cycles 20000000"`。
- `action`: 串行跑全量 CPU-test，并从日志生成 `/tmp/ysyx-ooo-full-cputests-jalr-btb.tsv`。
- `outputs`: `40/40 PASS`，`cycles=64582/commits=78679/weighted CPI=0.820829`。
- `evidence`: 终端 summary 40 项 PASS；TSV 聚合结果。
- `next_step`: 非 OoO build、最终 OoO rebuild、memory 更新。

### [2026-05-29] `final-builds-and-record` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 收尾验证与记录。
- `inputs`: 非 OoO/OoO 强制构建、memory/task-run。
- `action`: 跑 `NPC_OOO_ALU_EXPERIMENT=0 -B` build，随后 `NPC_OOO_ALU_EXPERIMENT=1 -B` 最终重建；更新 memory 与 task-run。
- `outputs`: 两种构建均 PASS，最终二进制为 OoO 配置。
- `evidence`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`。
- `next_step`: 若继续推进，应迁入动态 branch BHT 或做真正 selective control speculation。
