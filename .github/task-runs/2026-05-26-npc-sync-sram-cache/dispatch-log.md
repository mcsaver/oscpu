# Dispatch Log

## 基本信息

- `task_id`: `2026-05-26-npc-sync-sram-cache`
- `task_slug`: `npc-sync-sram-cache`
- `graph_template`: `npc-sim-regression`
- `log_policy`: `append-only`

---

### [2026-05-26 10:10] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户指出 cache 组合 hit 可能违反外部 SRAM 读写规则，并要求修正。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study。
- `action`: 读取仓库规则和 NPC 记忆，定位 `CacheControl.v` 只是 fence.i 控制，真实组合路径在 `Sram1Rw/Sram2R1W` 与 `ICache/DCache` 的 `S_IDLE cur_*` hit 逻辑。
- `outputs`: 确认修复目标是同步 SRAM wrapper 和 cache FSM，而不是修改 fence.i 控制器；`npc/soc` 复制版需要保留 MROM cacheable 特例后同步。
- `evidence`: `rg` 与 `sed/nl` 检查 `CacheControl.v`、`ICache.v`、`DCache.v`、`Sram1Rw.v`、`Sram2R1W.v`。
- `handoff_to`: `implement`
- `next_step`: 将 array 读改为同步，并拆开 cache lookup/fill/store/flush 状态。
- `notes`: 按 RTL 工作流先完成需求、协议、状态机、不变量、数据通路推导。

### [2026-05-26 10:25] `implement` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 推导完成。
- `depends_on`: `recall`
- `inputs`: ICache/DCache 2-way write-back cache、SRAM wrapper、front-end/MEM ready-valid 控制。
- `action`: `Sram1Rw/Sram2R1W` 改为寄存输出；移除 ICache/DCache `cur_*` 组合 hit response；新增 refill replay、store allocate read/update、flush read 等同步 SRAM 状态；更新仿真性能事件和 testbench/pipe 期望；同一语义同步到 `npc/soc`，保留 SoC ICache MROM cacheable 特例。
- `outputs`: CPU request 只发 read address，hit/miss 在后一拍 `S_LOOKUP` 消费 SRAM 输出；`cpu_rsp_valid` 只从 `S_RESP` 出来。
- `evidence`: ICache/DCache testbench 已改为检查 no immediate response 与 sync response；pipe 默认不再要求 hit wait zero。
- `handoff_to`: `verify`
- `next_step`: 运行 lint、模块 testbench、pipe/stage pipe、AM 回归。
- `notes`: SoC DCache flush test 的固定 128 拍等待不适配 64 set 配置，已改成随 cache 参数计算的 `FLUSH_TIMEOUT`。

### [2026-05-26 10:45] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 接入完成。
- `depends_on`: `implement`
- `inputs`: 修改后的 `npc/single` 与 `npc/soc`。
- `action`: 运行静态和动态回归。
- `outputs`: 所有验证通过。
- `evidence`: `make -C npc/single lint` PASS；`timeout 30s make -C npc/single/testbench run TESTS='tb_icache tb_dcache' RESULT_DIR=/tmp/npc-sync-sram-cache-tests` PASS；`timeout 60s make -C npc/single/testbench pipe_test PIPE_RESULT_DIR=/tmp/npc-sync-sram-pipe-tests` PASS；`timeout 120s make -C npc/single/testbench run RESULT_DIR=/tmp/npc-sync-sram-module-tests` 27/27 PASS；`make -C npc/single -j4` PASS；`riscv32-npc` 的 `add/load-store/fence-i` GOOD TRAP；`make -C npc/soc lint` PASS；`timeout 120s make -C npc/soc/testbench run TESTS='tb_icache tb_dcache' RESULT_DIR=/tmp/npc-soc-sync-sram-cache-tests2` PASS；`timeout 60s make -C npc/soc/testbench pipe_test PIPE_RESULT_DIR=/tmp/npc-soc-sync-sram-pipe-tests` PASS；`make -C npc/soc soc-lint` PASS；`make -C npc/soc -j4` PASS；`make -C npc/soc soc` PASS；`make -C npc/soc soc-run RUN_ARGS='--max-cycles 10000'` GOOD TRAP；`git diff --check` PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory。
- `notes`: pipe 指标中同步 SRAM 后 `frontend_icache_hit_to_ifid_wait_cycles=3`、`mem_stage_dcache_load_hit_wait_cycles=2`、`mem_stage_dcache_store_hit_wait_cycles=2`，为预期延迟变化。

### [2026-05-26 10:53] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成。
- `depends_on`: `verify`
- `inputs`: 变更摘要与验证证据。
- `action`: 写入 task report、dispatch log、project status 和 NPC 模块笔记。
- `outputs`: 本目录记录与 memory 条目。
- `evidence`: `.github/task-runs/2026-05-26-npc-sync-sram-cache/`
- `handoff_to`: 无
- `next_step`: 无。
- `notes`: 无
