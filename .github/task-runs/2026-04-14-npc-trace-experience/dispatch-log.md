# Dispatch Log

## 基本信息

- `task_id`: `2026-04-14-npc-trace-experience`
- `task_slug`: `npc-trace-experience`
- `graph_template`: `regression-debug-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-04-14 00:10] `trace-path-survey` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `用户选择继续补 trace 体验，希望把 itrace/mtrace/dtrace 做成像 NEMU 一样可用的调试入口`
- `depends_on`: `已有 NPC monitor/Kconfig/SDB 壳`
- `inputs`: `npc/single/Kconfig`、`README.md`、`monitor.cpp`、`cpu-exec.cpp`、`paddr.cpp`、`map.cpp`、`dpi.cpp`、`NpcSimTop.sv`
- `action`: `回读现有 trace 钩子，区分编译期开关、日志落点和实际用户入口`
- `outputs`: `确认缺口在于运行时控制层缺失，且 mtrace 混入 ifetch`
- `evidence`: `源码检查显示三类 trace 已有零散 Log 点，但无 CLI/monitor 控制；paddr 路径未区分 ifetch 与 load/store`
- `handoff_to`: `runtime-trace-refactor`
- `next_step`: `新增 trace 运行时状态与 CLI/monitor 控制入口`
- `notes`: `这一阶段决定不重做 trace，而是在现有日志点上补“能力层”`

### [2026-04-14 00:40] `runtime-trace-refactor` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `trace 链路缺口已明确`
- `depends_on`: `trace-path-survey`
- `inputs`: `monitor/SDB 框架`、`paddr/map/dpi/NpcSimTop`、`Kconfig/default_defconfig`
- `action`: `新增 trace.cpp/trace.h，给 monitor.cpp 增加 --itrace/--itrace-cond/--mtrace/--dtrace，给 sdb.cpp 增加 info t/trace，给 paddr/map/dpi/NpcSimTop 增加访问类型区分`
- `outputs`: `编译期能力 + 运行时开关的 trace 子系统`
- `evidence`: `代码已接入 monitor、cpu-exec、paddr、map、dpi、NpcSimTop，且 default_defconfig 默认带 build 能力`
- `handoff_to`: `batch-regression`
- `next_step`: `重编并做 batch 回归`
- `notes`: `mtrace 被收敛为只看数据 load/store，ifetch 单独走 kIfetch`

### [2026-04-14 01:10] `batch-regression` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `运行时 trace 子系统已落盘`
- `depends_on`: `runtime-trace-refactor`
- `inputs`: `hello-riscv32-npc.bin`、`NpcSimTop`
- `action`: `执行 default_defconfig + 全量构建，再分别运行 batch itrace 和 batch mtrace+dtrace`
- `outputs`: `batch trace 回归结果与日志文件`
- `evidence`: `首条 itrace 命中 '$pc == 0x80000000' 条件；mtrace/dtrace 能看到数据 load/store 与 serial MMIO 日志；hello 正常退出`
- `handoff_to`: `monitor-regression`
- `next_step`: `验证 monitor 动态 trace 控制`
- `notes`: `第一次 mtrace+dtrace 回归暴露出默认 itrace cond="true" 的误报警`

### [2026-04-14 01:30] `monitor-regression` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `batch 路径通过，需要确认交互入口`
- `depends_on`: `batch-regression`
- `inputs`: `info t`、`trace itrace on`、`trace cond ...`、`si 2`
- `action`: `通过预置 stdin 驱动 (npc) monitor，检查 trace 状态展示与动态开关行为`
- `outputs`: `monitor 下可用的 trace 命令链`
- `evidence`: `info t` 能显示 build/runtime 状态；trace 命令能切换 itrace 条件并在 si 时输出日志`
- `handoff_to`: `literal-cond-fix`
- `next_step`: `修复默认 true 条件误报并重跑`
- `notes`: `交互验证沿用一次性 stdin 预置，避免把 monitor 操作留给用户手动输入`

### [2026-04-14 01:50] `literal-cond-fix` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `回归日志显示默认 CONFIG_NPC_ITRACE_COND="true" 会触发 bad condition warning`
- `depends_on`: `monitor-regression`
- `inputs`: `trace.cpp`、expr 解析能力、最新回归日志`
- `action`: `在 trace.cpp 中为 true/false/0/1 增加字面量兼容，再重编并重跑 monitor/mtrace 回归`
- `outputs`: `默认 true 条件与 trace cond true 的兼容修复`
- `evidence`: `修复后 monitor 输出不再出现 bad itrace condition warning，trace cond true 可直接生效`
- `handoff_to`: `record-docs`
- `next_step`: `更新 README、memory 和 task-run`
- `notes`: `问题根因不是 trace 开关本身，而是 expr 语法没有定义裸布尔字面量`

### [2026-04-14 02:10] `record-docs` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `代码、构建和回归均已完成，需要把可复用结论写回工作区`
- `depends_on`: `literal-cond-fix`
- `inputs`: `README`、回归命令、memory 协议、task-run 模板`
- `action`: `补 README 中的软件 trace 用法，更新 project-status/modules/decisions/known-issues，并新增 task-report/dispatch-log`
- `outputs`: `文档与长期记忆已对齐当前代码现状`
- `evidence`: `README、memory、task-run 文件均已写入 trace 体验增强、验证命令和改动文件清单`
- `handoff_to`: `none`
- `next_step`: `等待下一轮继续往反汇编视图或 difftest 钩子扩展`
- `notes`: `这一步明确记录了“mtrace 不含 ifetch”和“runtime toggle 优先”的长期约束`