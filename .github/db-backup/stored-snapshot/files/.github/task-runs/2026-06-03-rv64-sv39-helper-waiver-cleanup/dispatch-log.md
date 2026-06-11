# Dispatch Log

## 基本信息

- `task_id`: `2026-06-03-rv64-sv39-helper-waiver-cleanup`
- `task_slug`: `rv64-sv39-helper-waiver-cleanup`
- `graph_template`: `verilator-tapeout-readiness-loop`
- `log_policy`: `append-only`

---

### [2026-06-03 17:15] `scan-active-rtl-waivers` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 持续推进 RV64 商业 ASIC RTL 风格收敛。
- `depends_on`: `2026-06-03-rv64-bpu-valid-vector`
- `inputs`: `npc/rv64/vsrc`
- `action`: 扫描活动 RTL 中剩余 `BLKSEQ/lint_off` 与全表 reset/invalidate 结构。
- `outputs`: 选中 Sv39 TLB/IFU/LSU page-walk helper 的函数级 waiver 作为本轮低风险 cleanup。
- `evidence`: `rg` 扫描结果显示 `OooSv39Tlb`、`OooFetchAxiBridge`、`OooMemAxiBridge` 有同类 `leaf_paddr()` waiver。
- `handoff_to`: `rewrite-sv39-helper`
- `next_step`: 按 RTL 四段式推导后改写纯组合 helper。
- `notes`: `OooDataWordCache` 已是 valid-only reset，本轮不改。

### [2026-06-03 17:20] `rewrite-sv39-helper` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 方案确认。
- `depends_on`: `scan-active-rtl-waivers`
- `inputs`: `OooSv39Tlb.v`, `OooFetchAxiBridge.v`, `OooMemAxiBridge.v`
- `action`: 将 `leaf_paddr()` 改为单表达式组合 mux；将 LSU data permission helper 拆成纯组合 read/user helper。
- `outputs`: 三个活动路径文件删除对应 `BLKSEQ` waiver。
- `evidence`: 相关三文件 `BLKSEQ/lint_off` 搜索无命中。
- `handoff_to`: `verify-sv39-helper`
- `next_step`: focused tb、项目级 lint/build、Sv39/Linux-tools smoke。
- `notes`: 不改 FSM、接口或 filelist。

### [2026-06-03 17:28] `verify-sv39-helper` - `completed`

- `owner_agent`: `Codex`
- `trigger`: RTL helper 改写完成。
- `depends_on`: `rewrite-sv39-helper`
- `inputs`: 修改后的 Sv39 helper RTL 与现有 testbench/smoke。
- `action`: 执行 focused module testbench、项目级 lint/build、Sv39/页尾跨页/virtio smoke、`git diff --check`。
- `outputs`: 验证全部通过。
- `evidence`: `tb_ooo_fetch_axi_bridge/tb_ooo_mem_axi_bridge/tb_ooo_sv39_boot` PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；`smoke-sret-user-sv39/smoke-sret-user-sv39-halfword/smoke-virtio-blk` GOOD TRAP；`git diff --check` PASS。
- `handoff_to`: `record-memory`
- `next_step`: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
- `notes`: 单模块 strict lint 的宽输入 unused 告警作为后续 commercial lint cleanup 候选记录。

