# Dispatch Log

## 基本信息

- `task_id`: `2026-05-29-npc-rv64-backend`
- `task_slug`: `npc-rv64-backend`
- `graph_template`: `npc-sim-regression`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-29 21:05] `copy-backend` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求从 `single` 派生 `rv64`
- `depends_on`: repo instruction read
- `inputs`: `npc/single`
- `action`: 复制 `npc/single` 到 `npc/rv64`，排除 build/testbench/perf 产物
- `outputs`: 独立 `npc/rv64` 工作目录
- `evidence`: `npc/rv64/` 生成
- `handoff_to`: `sim-backend`
- `next_step`: 接入 `npc/sim`
- `notes`: 保留 `single` 原目录不动

### [2026-05-29 21:12] `sim-backend` - `completed`

- `owner_agent`: Codex
- `trigger`: AM 和外部入口需要稳定选择 RV64 后端
- `depends_on`: `copy-backend`
- `inputs`: `npc/sim/Makefile`, `npc/sim/Kconfig`
- `action`: 新增 `rv64` backend descriptor、Kconfig 选项和 `rv64_defconfig`
- `outputs`: `BACKEND=rv64` 与 `make -C npc/sim rv64_defconfig`
- `evidence`: defconfig PASS
- `handoff_to`: `rtl-width`
- `next_step`: 迁移 RTL/host 位宽
- `notes`: 继续复用 `npc/sim` 作为 AM 稳定入口

### [2026-05-29 21:24] `rtl-width` - `completed`

- `owner_agent`: Codex
- `trigger`: RV64 core 需要 64-bit PC/GPR/LSU/ALU
- `depends_on`: `sim-backend`
- `inputs`: `npc/rv64/vsrc`
- `action`: 扩展 `define.v`、译码、立即数、LSU、core、mul/div、AXI/CLINT/DPI top 等
- `outputs`: RV64 基础 RTL
- `evidence`: `make -C npc/sim BACKEND=rv64 lint` PASS
- `handoff_to`: `host-width`
- `next_step`: 构建 Verilator host
- `notes`: RV64 cacheable 范围暂时保守关闭

### [2026-05-29 21:30] `host-width` - `completed`

- `owner_agent`: Codex
- `trigger`: Verilator C++/DPI 需要承载 64-bit payload
- `depends_on`: `rtl-width`
- `inputs`: `npc/rv64/csrc`
- `action`: 引入 `npc_word_t/npc_paddr_t`，调整 PMEM/DPI/commit/trace/disasm/log 为 64-bit
- `outputs`: 可链接 `NpcSimTop`
- `evidence`: `make -C npc/sim BACKEND=rv64 -j4` PASS
- `handoff_to`: `am-backend`
- `next_step`: 打通 `ARCH=riscv64-npc`
- `notes`: welcome/VGA title 已改为 `riscv64`

### [2026-05-29 21:33] `am-backend` - `completed`

- `owner_agent`: Codex
- `trigger`: CPU-test 需要 RV64 AM 构建入口
- `depends_on`: `host-width`
- `inputs`: `abstract-machine/scripts`, `abstract-machine/klib`
- `action`: 新增 `riscv64-npc.mk`，使用 freestanding `rv64im_zicsr_zifencei/lp64`，新增 `klib/include/limits.h`
- `outputs`: RV64 AM 镜像可编译并进入 `npc/sim BACKEND=rv64`
- `evidence`: `ARCH=riscv64-npc ALL=add run` PASS
- `handoff_to`: `regression`
- `next_step`: 跑 cpu-tests 全量
- `notes`: 避开当前宿主 sysroot 缺 `stubs-lp64.h`

### [2026-05-29 21:34] `difftest-policy` - `completed`

- `owner_agent`: Codex
- `trigger`: `difftest-ref` 试构建失败
- `depends_on`: `host-width`
- `inputs`: NEMU `Kconfig`, `src/isa/filelist.mk`, `src/isa/riscv32/inst.c`
- `action`: 确认当前 NEMU RV64 reference 不完整，关闭 `npc/rv64` 默认 difftest 并记录 known issue
- `outputs`: `CONFIG_NPC_DIFFTEST=n`, `difftest-ref` 显式提示不可用
- `evidence`: known issue [31]
- `handoff_to`: `regression`
- `next_step`: 以 cpu-tests 自检闭合
- `notes`: 后续 RV64 difftest 需独立补 reference

### [2026-05-29 21:37] `regression` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户验收标准为 cpu-test 全量
- `depends_on`: `am-backend`, `difftest-policy`
- `inputs`: `am-kernels/tests/cpu-tests`
- `action`: 对 `ARCH=riscv64-npc` 跑基础全量，RV64 下排除 RV32 专属 `bitmanip/compressed`
- `outputs`: 38 项全部 PASS
- `evidence`: `test list [38 item(s)]` 且结果表全 PASS
- `handoff_to`: `memory-update`
- `next_step`: 更新 memory/task-run
- `notes`: 使用 `NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`

### [2026-05-29 21:38] `memory-update` - `completed`

- `owner_agent`: Codex
- `trigger`: repo AGENTS 要求完成后更新 memory 与 task-runs
- `depends_on`: `regression`
- `inputs`: validation evidence
- `action`: 更新 project-status、npc/abstract-machine/am-kernels 模块笔记、known-issues，并创建本 task-run
- `outputs`: memory/task-run 记录
- `evidence`: 本目录 `task-report.md` 与 `dispatch-log.md`
- `handoff_to`: none
- `next_step`: final response
- `notes`: 未触碰用户既有 OoO 工作目录内容
