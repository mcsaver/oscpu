# Dispatch Log

## 基本信息

- `task_id`: `2026-05-20-npc-simtop-perf-events`
- `task_slug`: `npc-simtop-perf-events`
- `graph_template`: `regression-debug-loop`
- `log_policy`: `append-only`

---

### [2026-05-20 14:54] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求把 cache/branch 统计移到 DPI-C 仿真顶层。
- `depends_on`: 无。
- `inputs`: `cache.c`、`paddr.c`、`NpcSimTop.sv`、`ICache.v`、`DCache.v`、`NpcCore.v`。
- `action`: 查明旧 `cache.c` 统计不在主执行路径；梳理可层次引用的 RTL 信号。
- `outputs`: 选择 `NpcSimTop -> DPI event -> host counter` 方案。
- `evidence`: `paddr.c` PMEM 直接读写，未调用 `npc_icache_read/npc_dcache_read/npc_dcache_write`。
- `handoff_to`: `implement`
- `next_step`: 修改仿真顶层和 host 统计。
- `notes`: 不新增 `NpcCore` 端口。

### [2026-05-20 14:57] `implement` - `completed`

- `owner_agent`: `codex`
- `trigger`: 方案确认。
- `depends_on`: `recall`
- `inputs`: `NpcSimTop.sv`、`cpu-exec.cpp`。
- `action`: 新增 DPI event import/实现；在 `NpcSimTop.sv` 层次采样 control/cache 事件；删除 host commit opcode 分支推断；改打印为仿真事件统计。
- `outputs`: 代码补丁。
- `evidence`: 文件 diff。
- `handoff_to`: `verify`
- `next_step`: lint/build/run。
- `notes`: DCache write-through store 作为新统计项输出。

### [2026-05-20 14:59] `verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: 实现完成。
- `depends_on`: `implement`
- `inputs`: 新构建。
- `action`: 运行 lint、强制构建、`cpu-tests add`。
- `outputs`: 验证通过。
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/single -B -j4` PASS；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='-m 0'` PASS，统计显示 ICache `1009/1003/6`、DCache `157/139/18`、write-through store `11`。
- `handoff_to`: `record`
- `next_step`: 更新记忆。
- `notes`: 无。

### [2026-05-20 15:00] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 验证完成。
- `depends_on`: `verify`
- `inputs`: 验证证据。
- `action`: 更新 project-status、NPC module memory 和本任务记录。
- `outputs`: 记录完成。
- `evidence`: 本目录文件与 memory diff。
- `handoff_to`: 无。
- `next_step`: 回复用户。
- `notes`: 无。
