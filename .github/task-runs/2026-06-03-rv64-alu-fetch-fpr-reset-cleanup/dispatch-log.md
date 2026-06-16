# Dispatch Log

## 基本信息

- `task_id`: `2026-06-03-rv64-alu-fetch-fpr-reset-cleanup`
- `task_slug`: `rv64-alu-fetch-fpr-reset-cleanup`
- `graph_template`: `verilator-tapeout-readiness-loop`
- `log_policy`: `append-only`

---

### [2026-06-03 18:20] `scan-alu-fetch-waivers` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 持续推进 RV64 商业 ASIC RTL 风格收敛。
- `depends_on`: `2026-06-03-rv64-plic-read-helper-cleanup`
- `inputs`: `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`
- `action`: 扫描活动 RTL 中剩余 `BLKSEQ` waiver，并定位 `OooAluFetchCore` 中的 FPR reset loop。
- `outputs`: 发现 `fpr_q[fpr_reset_idx] = 0` 是活动 RTL 中最后一处非 legacy `BLKSEQ` waiver。
- `evidence`: `OooAluFetchCore.v` reset 分支内存在 `verilator lint_off BLKSEQ` 包裹的 FPR blocking 清零 loop；其它命中来自 `UNOPTFLAT/UNUSEDSIGNAL` 或 legacy。
- `handoff_to`: `rewrite-fpr-reset`
- `next_step`: 按 RTL 四段式推导后把 FPR reset 改为 nonblocking 状态落库。
- `notes`: 本轮选择 FPR reset 是因为改动边界小，且可直接补 FP smoke 验证。

### [2026-06-03 18:25] `rewrite-fpr-reset` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 方案确认。
- `depends_on`: `scan-alu-fetch-waivers`
- `inputs`: `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`
- `action`: 删除 FPR reset loop 周围的 `BLKSEQ` lint waiver，把 `fpr_q[fpr_reset_idx] = 0` 改为 `fpr_q[fpr_reset_idx] <= 0`。
- `outputs`: `OooAluFetchCore` 活动 reset 路径不再包含 `BLKSEQ` waiver。
- `evidence`: 活动 RTL 扫描排除 `legacy/` 后 `BLKSEQ` 无命中。
- `handoff_to`: `verify-fpr-reset`
- `next_step`: focused tb、项目级 lint/build、FP smoke、diff check。
- `notes`: 不改 FP pending 状态机、FPR 正常写回路径、CSR/fcsr 或 filelist。

### [2026-06-03 18:35] `verify-fpr-reset` - `completed`

- `owner_agent`: `Codex`
- `trigger`: RTL reset 写法改写完成。
- `depends_on`: `rewrite-fpr-reset`
- `inputs`: 修改后的 `OooAluFetchCore.v` 与现有 frontend/privileged/FP smoke。
- `action`: 执行 focused testbench、项目级 lint/build、FP 代表性 smoke、活动 RTL waiver 扫描和 whitespace 检查。
- `outputs`: 验证全部通过。
- `evidence`: `tb_ooo_alu_fetch_core/tb_ooo_fetch_trap_gate/tb_ooo_priv_system` 3/3 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；`smoke-fp-loadstore/smoke-fp-fcsr/smoke-fp-fmv-fclass/smoke-fp-convert` GOOD TRAP；活动 RTL 排除 legacy 后 `BLKSEQ` 无命中；focused `git diff --check` PASS。
- `handoff_to`: `record-memory`
- `next_step`: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
- `notes`: Windows Git 全仓 `diff --check` 会对 WSL 符号链接/换行输出环境警告但返回 0；最终以 WSL Git focused check 作为本轮触及文件证据。
