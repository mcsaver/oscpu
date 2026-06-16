# Dispatch Log

## 基本信息

- `task_id`: `2026-06-03-rv64-freelist-blkseq-cleanup`
- `task_slug`: `rv64-freelist-blkseq-cleanup`
- `graph_template`: `verilator-tapeout-readiness-loop`
- `log_policy`: `append-only`

---

### [2026-06-03 17:35] `scan-rename-rtl-waivers` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 持续推进 RV64 商业 ASIC RTL 风格收敛。
- `depends_on`: `2026-06-03-rv64-sv39-helper-waiver-cleanup`
- `inputs`: `npc/rv64/vsrc/ooo/rename`
- `action`: 扫描 rename/free-list 活动 RTL 中剩余 `BLKSEQ` 与仿真式 normal-path 写法。
- `outputs`: 选中 `OooFreeList` normal allocate/free path 的 `push_count/next_count` blocking 临时变量作为本轮低风险 cleanup。
- `evidence`: `OooFreeList.v` normal path 存在 `BLKSEQ` waiver，且不涉及接口或状态机改动。
- `handoff_to`: `rewrite-freelist-normal-path`
- `next_step`: 按 RTL 四段式推导将 count/tail/free 接受条件前移为组合 wires。
- `notes`: reset/flush/checkpoint 循环本轮保持原结构。

### [2026-06-03 17:40] `rewrite-freelist-normal-path` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 方案确认。
- `depends_on`: `scan-rename-rtl-waivers`
- `inputs`: `npc/rv64/vsrc/ooo/rename/OooFreeList.v`
- `action`: 删除时序块内 `push_count/next_count` blocking 临时变量，新增组合 wires 推导 normal path 的 free 接受、push 数量、下一拍 count 和 free1 tail。
- `outputs`: `OooFreeList` normal sequential block 只保留 FIFO/head/tail/count 的 nonblocking 状态更新。
- `evidence`: `OooFreeList.v` 中 `BLKSEQ` 搜索无命中；新逻辑保留 2-wide alloc/free、free0/free1 顺序和 checkpoint 语义。
- `handoff_to`: `verify-freelist-normal-path`
- `next_step`: 单模块 lint、FreeList/dispatch/backend focused tb、项目级 lint/build、Linux-tools smoke。
- `notes`: 不改端口、不改 filelist、不改 testbench 协议。

### [2026-06-03 17:55] `verify-freelist-normal-path` - `completed`

- `owner_agent`: `Codex`
- `trigger`: RTL cleanup 完成。
- `depends_on`: `rewrite-freelist-normal-path`
- `inputs`: 修改后的 `OooFreeList.v` 与现有 rename/backend testbench/smoke。
- `action`: 执行 strict 单模块 lint、focused module testbench、项目级 lint/build、代表性 Linux-tools smoke 和 whitespace 检查。
- `outputs`: 验证全部通过。
- `evidence`: `OooFreeList` strict Verilator lint PASS；`tb_ooo_free_list` PASS；`tb_ooo_free_list/tb_ooo_dispatch_backend/tb_ooo_int_backend/tb_ooo_alu_fetch_core` 4/4 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；`smoke-jal-link/smoke-branch-raw/smoke-muldiv` GOOD TRAP；`git diff --check` PASS。
- `handoff_to`: `record-memory`
- `next_step`: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
- `notes`: 验证后 WSL 服务偶发 `E_UNEXPECTED`，文档更新改用 PowerShell/UNC 与 `apply_patch` 完成；不影响已完成验证结果。
