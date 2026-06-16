# Dispatch Log

## 基本信息

- `task_id`: `2026-06-03-rv64-immgen-port-cleanup`
- `task_slug`: `rv64-immgen-port-cleanup`
- `graph_template`: `verilator-tapeout-readiness-loop`
- `log_policy`: `append-only`

---

### [2026-06-03 17:40] `scan-active-rtl-waivers` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 持续推进“按照商业 ASIC 级别 RTL 推进项目”目标。
- `depends_on`: `2026-06-03-rv64-alu-fetch-fpr-reset-cleanup`
- `inputs`: `npc/rv64/vsrc`
- `action`: 扫描活动 RTL 中剩余 `lint_off/lint_on/UNUSED/UNOPT/BLKSEQ`。
- `outputs`: 发现 `ImmGen.v` 仍有 `UNUSED` waiver，原因是模块接收整条指令但不使用 opcode 低 7 位。
- `evidence`: `rg` 命中 `npc/rv64/vsrc/decode/ImmGen.v:9` 附近的 `verilator lint_off UNUSED`；同轮确认非 legacy `BLKSEQ` 已无命中。
- `handoff_to`: `rewrite-immgen-port`
- `next_step`: 用四段式 RTL 推导确认端口收窄不会改变立即数语义。
- `notes`: 选择 `ImmGen` 是因为它属于 DecodeStage 活动路径，改动范围小，且端口收窄比 dummy unused 更符合模块边界。

### [2026-06-03 17:42] `rewrite-immgen-port` - `completed`

- `owner_agent`: `Codex`
- `trigger`: RTL 推导确认完成。
- `depends_on`: `scan-active-rtl-waivers`
- `inputs`: `ImmGen.v`、`DecodeStage.v`、`tb_immgen.sv`
- `action`: 将 `ImmGen` 输入从完整 `inst_i[31:0]` 收窄为 `inst_imm_i[31:7]`，调用点显式传 `inst[31:7]`，删除 `opcode_bits_unused_w` 和 `UNUSED` waiver。
- `outputs`: `ImmGen` 不再包含 lint waiver；DecodeStage 的 DecodeUnit/ImmGen 职责边界更清楚。
- `evidence`: `rg` 对 `ImmGen.v/DecodeStage.v` 的 `lint_off|lint_on|UNUSED|UNOPT|BLKSEQ` 无命中。
- `handoff_to`: `verify-immgen-port`
- `next_step`: strict lint、focused decode/OoO tb、项目 lint/build、代表 smoke。
- `notes`: 不改 `DecodeUnit` 控制包、不改 OoO dispatch/issue/commit、不改 filelist。

### [2026-06-03 17:44] `verify-immgen-port` - `completed`

- `owner_agent`: `Codex`
- `trigger`: RTL 端口收窄完成。
- `depends_on`: `rewrite-immgen-port`
- `inputs`: 修改后的 decode RTL 与现有 testbench/smoke。
- `action`: 执行 strict Verilator lint、decode focused testbench、OoO decode/front-end focused testbench、项目级 lint/build、立即数敏感 smoke 与 whitespace 检查。
- `outputs`: 验证全部通过。
- `evidence`: `ImmGen` strict lint PASS；`tb_immgen/tb_decode_stage` 2/2 PASS；`tb_ooo_alu_decode_backend/tb_ooo_int_backend/tb_ooo_alu_fetch_core` 3/3 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；`smoke-jal-link/smoke-branch-raw/smoke-muldiv/smoke-sret-user-sv39` GOOD TRAP；focused `git diff --check` PASS。
- `handoff_to`: `record-memory`
- `next_step`: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
- `notes`: 剩余 active waiver 已更新为 CSR/OOO decode/backend/frontend 的 `UNUSEDSIGNAL/UNOPTFLAT` 类问题。
