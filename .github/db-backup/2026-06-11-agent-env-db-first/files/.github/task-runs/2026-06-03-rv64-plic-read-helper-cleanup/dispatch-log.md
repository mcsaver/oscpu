# Dispatch Log

## 基本信息

- `task_id`: `2026-06-03-rv64-plic-read-helper-cleanup`
- `task_slug`: `rv64-plic-read-helper-cleanup`
- `graph_template`: `verilator-tapeout-readiness-loop`
- `log_policy`: `append-only`

---

### [2026-06-03 17:58] `scan-platform-rtl-waivers` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 持续推进 RV64 商业 ASIC RTL 风格收敛。
- `depends_on`: `2026-06-03-rv64-freelist-blkseq-cleanup`
- `inputs`: `npc/rv64/vsrc`
- `action`: 扫描活动 RTL 中剩余 `lint_off/lint_on/BLKSEQ/UNOPT` 与全表 reset/scan 风格风险。
- `outputs`: 发现 `AxiLitePlic.read_plic_word()` 仍有函数局部 blocking 赋值导致的 `BLKSEQ` waiver。
- `evidence`: `Select-String` 显示 `AxiLitePlic.v` line 164 附近存在 `verilator lint_off BLKSEQ`；同轮还记录 `OooAluFetchCore` 有更大范围 reset waiver，留作后续更大 cleanup。
- `handoff_to`: `rewrite-plic-read-helper`
- `next_step`: 按 RTL 四段式推导后删除 helper 局部临时变量。
- `notes`: 选择 PLIC 是因为它属于 `NpcTop` 平台活动路径，改动范围小且有专用 testbench。

### [2026-06-03 18:02] `rewrite-plic-read-helper` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 方案确认。
- `depends_on`: `scan-platform-rtl-waivers`
- `inputs`: `npc/rv64/vsrc/bus/AxiLitePlic.v`
- `action`: 删除 `read_plic_word()` 的局部 `word_index` reg 和 `BLKSEQ` waiver，直接用 `addr_low[21:2]` 读取当前 source priority，并用 `addr_low[21:2] + 1` 读取高半相邻 source priority。
- `outputs`: `AxiLitePlic.v` 不再包含 `BLKSEQ` waiver。
- `evidence`: `Select-String -Pattern 'lint_off|lint_on|BLKSEQ'` 无命中。
- `handoff_to`: `verify-plic-read-helper`
- `next_step`: strict lint、PLIC/IRQ focused tb、项目级 lint/build、代表 smoke。
- `notes`: 不改 AXI-Lite read/write 状态机、claim/complete side effect 或 filelist。

### [2026-06-03 18:15] `verify-plic-read-helper` - `completed`

- `owner_agent`: `Codex`
- `trigger`: RTL helper 改写完成。
- `depends_on`: `rewrite-plic-read-helper`
- `inputs`: 修改后的 `AxiLitePlic.v` 与现有 PLIC/IRQ testbench/smoke。
- `action`: 执行单模块 strict Verilator lint、PLIC/IRQ focused testbench、项目级 lint/build、代表性 top-level smoke 和 whitespace 检查。
- `outputs`: 验证全部通过。
- `evidence`: `AxiLitePlic` strict lint PASS；`tb_axi_lite_plic/tb_axi_lite_to_uart/tb_ooo_priv_system` 3/3 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；`smoke-jal-link/smoke-virtio-blk` GOOD TRAP；`git diff --check` PASS。
- `handoff_to`: `record-memory`
- `next_step`: 更新 `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md`。
- `notes`: Windows/WSL 偶发不稳定仍按 known issue [34] 处理；验证命令本轮均已完成。
