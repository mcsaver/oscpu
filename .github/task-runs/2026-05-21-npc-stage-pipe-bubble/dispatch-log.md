# Dispatch Log

## 基本信息

- `task_id`: `2026-05-21-npc-stage-pipe-bubble`
- `task_slug`: `npc-stage-pipe-bubble`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-21 16:30] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求按五级流水阶段仿真并减少无用 stall
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study
- `action`: 读取项目规范、NPC 记忆、RTL 工作流和现有 testbench
- `outputs`: 明确需要中文、RTL 四段式、验证和 memory/task-runs 记录
- `evidence`: 已读取并据此制定计划
- `handoff_to`: `localize-frontend-bubble`
- `next_step`: 运行现有 pipe_test 和审计前端链路
- `notes`: 工作区已有大量本地改动，本轮只在相关文件上叠加修改，不回退其它改动

### [2026-05-21 16:45] `localize-frontend-bubble` - `completed`

- `owner_agent`: Codex
- `trigger`: 需要找出仍可消除的流水线气泡
- `depends_on`: `recall`
- `inputs`: `pipe_test`、`IfStage.v`、`ICache.v`、`IfIdPipeReg.v`
- `action`: 运行 `PIPE_RESULT_DIR=/tmp/npc-stage-baseline pipe_test`，审计 fetch response 到 IF/ID 的数据流
- `outputs`: MEM/DCache hit 等待已为 0；前端 response 仍先写 fetch buffer 后下拍装 IF/ID
- `evidence`: 基线 `mem_stage_dcache_load_hit_wait_cycles=0`、`mem_stage_store_write_through_wait_cycles=0`
- `handoff_to`: `rtl-fix`
- `next_step`: 给 `IfStage` 增加空 buffer response bypass
- `notes`: load-use 的 1 拍仍保留为真实相关气泡

### [2026-05-21 17:00] `rtl-fix` - `completed`

- `owner_agent`: Codex
- `trigger`: 前端 hit response 多打一拍
- `depends_on`: `localize-frontend-bubble`
- `inputs`: RTL 四段式推导
- `action`: `IfStage` 新增 `fetch_direct_to_pipe_w/fetch_store_rsp_w/pipe_load_w`；修正 direct response 也必须推进 `fetch_pc_q`
- `outputs`: 空 buffer 且 IF/ID ready 时 response 直接进入 pipe 输出，非直通 response 才写 buffer
- `evidence`: `tb_if_stage` 直通检查后续通过
- `handoff_to`: `stage-testbench`
- `next_step`: 新增阶段级仿真顶层
- `notes`: 第一次模块回归捕获到 direct path 未推进 PC，已修复

### [2026-05-21 17:10] `stage-testbench` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求按流水线级别写专门顶层仿真
- `depends_on`: `rtl-fix`
- `inputs`: 现有 `pipe_test` 和 testbench Makefile
- `action`: 新增 `stage_pipe_test.sv`，扩展 `make ... pipe_test` 同时跑 MEM 指标和 Stage 指标
- `outputs`: `stage_bubble_report.txt` 记录前端 hit 到 IF/ID、重复 buffer、MEM hit、load-use 指标
- `evidence`: `/tmp/npc-stage-pipe-test` PASS
- `handoff_to`: `verify`
- `next_step`: 完整回归
- `notes`: README 同步说明 `stage_pipe_test` 覆盖范围

### [2026-05-21 17:25] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL/testbench 改动完成
- `depends_on`: `stage-testbench`
- `inputs`: 修改后的 RTL、testbench、Makefile
- `action`: 跑模块级、阶段级、lint/build、代表性 cpu-tests
- `outputs`: 验证通过
- `evidence`: `make -C npc/single/testbench RESULT_DIR=/tmp/npc-stage-module-tests run` 21/21 PASS；`make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-stage-pipe-test pipe_test` PASS；`make -C npc/single lint` PASS；`make -C npc/single -j4` PASS；`cpu-tests add/load-store/if-else/switch/fence-i` PASS
- `handoff_to`: `record`
- `next_step`: 更新 memory
- `notes`: 当前构建未启用 difftest，cpu-tests 为裸跑

### [2026-05-21 17:35] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成
- `depends_on`: `verify`
- `inputs`: 改动摘要与验证结果
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`，创建本 task-run 记录
- `outputs`: 长期记忆和单次任务记录
- `evidence`: 本文件与 `task-report.md`
- `handoff_to`: none
- `next_step`: 交付给用户
- `notes`: 无

### [2026-05-21 18:05] `localize-load-use` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求“以类似的方法很层次，对其他模块压 stall”
- `depends_on`: `record`
- `inputs`: `PipelineControl.v`、`NpcCore.v`、`pipe_test.sv`、`stage_pipe_test.sv`
- `action`: 复核 ID/EX、EX/MEM、MEM/WB 的 load-use 数据流和背压链
- `outputs`: 确认固定 ID 插泡不是必须；load hit 可用 MEM response -> EX 前递，load miss 可由 EX/MEM 未响应背压 `ex_fire`
- `evidence`: `NpcCore` 已有 `mem_response && ex_mem_load` 前递优先级；`PipelineControl` 已有 `ex_mem_can_accept_w` 阻止消费者越过未完成 load
- `handoff_to`: `rtl-fix-load-use`
- `next_step`: 去掉 ID 阶段 load-use 固定门控，并补 miss 背压测试
- `notes`: 本轮保持精确异常/flush/halt 优先级不变

### [2026-05-21 18:20] `rtl-fix-load-use` - `completed`

- `owner_agent`: Codex
- `trigger`: load-use 可改为 EX 等待模型
- `depends_on`: `localize-load-use`
- `inputs`: RTL 四段式推导
- `action`: `PipelineControl` 取消 `id_accept_o` 的 `load_use_hazard_w` 门控；更新 `tb_pipeline_control`、`pipe_test`、`stage_pipe_test` 的 load-use 预期
- `outputs`: dependent 指令可立即进入 ID/EX；hit 通过同拍前递消除 bubble；miss 在 EX 阶段等待
- `evidence`: 阶段级微基准后续显示 `id_stage_load_use_bubbles=0`
- `handoff_to`: `verify-load-use`
- `next_step`: 跑模块级、阶段级、lint/build、全量 cpu-tests
- `notes`: 原 hazard 关系保留为可审计信号，语义从“ID 插泡”转为“EX 等待边界由 MEM 响应控制”

### [2026-05-21 18:45] `verify-load-use` - `completed`

- `owner_agent`: Codex
- `trigger`: 第二阶段 RTL/testbench 改动完成
- `depends_on`: `rtl-fix-load-use`
- `inputs`: 修改后的 `PipelineControl` 与 testbench
- `action`: 跑模块级、阶段级、lint/build 和全量 cpu-tests
- `outputs`: 验证通过
- `evidence`: `make -C npc/single/testbench RESULT_DIR=/tmp/npc-loaduse-module-tests run` 21/21 PASS；`make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-loaduse-stage-pipe pipe_test` PASS，`id_stage_load_use_bubbles=0`；`make -C npc/single lint` PASS；`make -C npc/single -j4` PASS；全量 `cpu-tests` 38/38 PASS
- `handoff_to`: `record-update`
- `next_step`: 更新 memory 与 task-run
- `notes`: 当前构建未启用 difftest，cpu-tests 为裸跑

### [2026-05-21 19:00] `record-update` - `completed`

- `owner_agent`: Codex
- `trigger`: 第二阶段验证完成
- `depends_on`: `verify-load-use`
- `inputs`: load-use 改动摘要与验证结果
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`，补充本 task-run
- `outputs`: 长期记忆和单次任务记录已覆盖前端直通与 load-use 压 stall 两阶段
- `evidence`: 本文件与 `task-report.md`
- `handoff_to`: none
- `next_step`: 交付给用户
- `notes`: 无
