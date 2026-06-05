# Dispatch Log

## 基本信息

- `task_id`: `2026-06-03-rv64-bpu-valid-vector`
- `task_slug`: `rv64-bpu-valid-vector`
- `graph_template`: `verilator-tapeout-readiness-loop`
- `log_policy`: `append-only`

---

### [2026-06-03 17:00] `analyze-bpu-valid-reset` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 继续 RV64 core 商业 RTL/PPA 优化。
- `depends_on`: `2026-06-03-rv64-branch-target-cache-valid-vector`
- `inputs`: `OooJalrBtb.v`, `OooBranchDirectionPredictor.v`, `OooAluFetchCore.v`, `define.v`
- `action`: 分析 lookup/update/clear 协议，确认 payload 在 invalid 时不可见；方向预测器需要 local-history valid gate 才能安全去掉 history reset。
- `outputs`: 采用 packed valid vector、invalid-first train、local history valid gate 的实现方案。
- `evidence`: 设计推导记录在 `task-report.md`。
- `handoff_to`: `implement-bpu-valid-vector`
- `next_step`: 修改 RTL 并跑单模块 strict lint。
- `notes`: 保持 BTFNT cold fallback 与 `BPU_COUNTER_INIT` 首次训练语义。

### [2026-06-03 17:05] `implement-bpu-valid-vector` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 方案确认。
- `depends_on`: `analyze-bpu-valid-reset`
- `inputs`: `npc/rv64/vsrc/frontend/OooJalrBtb.v`, `npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v`
- `action`: 将 valid arrays 改为 packed vectors，reset/clear 只清 valid；方向预测器新增 local-history valid gate 与 `counter_train()`。
- `outputs`: 两个前端子模块删除 reset loops 和 `BLKSEQ` waiver。
- `evidence`: 单模块 strict Verilator lint PASS。
- `handoff_to`: `verify-bpu-valid-vector`
- `next_step`: focused testbench、项目级 lint/build、Linux/tools smoke。
- `notes`: `unused_predictor_input_bits_w` 仅服务单模块 lint，综合无可见 fanout。

### [2026-06-03 17:12] `verify-bpu-valid-vector` - `completed`

- `owner_agent`: `Codex`
- `trigger`: RTL 修改完成。
- `depends_on`: `implement-bpu-valid-vector`
- `inputs`: 修改后的 BPU/BTB RTL 与既有 testbench/smoke。
- `action`: 执行单模块 strict lint、focused module testbench、项目级 lint/build、Linux/tools jump/branch/RAS smoke、`git diff --check`。
- `outputs`: 验证全部通过。
- `evidence`: `tb_branch_predictor/tb_ooo_alu_fetch_core/tb_ooo_fetch_trap_gate` PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；`smoke-jal-link/smoke-branch-raw/smoke-ras-trap-boundary` GOOD TRAP；`git diff --check` PASS。
- `handoff_to`: `memory-update`
- `next_step`: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
- `notes`: WSL 期间出现过一次服务短暂错误，已用 PowerShell/UNC 直接读写文档绕开。

