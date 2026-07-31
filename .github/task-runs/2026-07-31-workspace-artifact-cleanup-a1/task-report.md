# 任务报告

## 基本信息

- `task_id`: 2026-07-31-workspace-artifact-cleanup-a1
- `trace_id`: e2e:2026-07-31-workspace-artifact-cleanup-a1
- `task_slug`: workspace-artifact-cleanup-a1
- `graph_template`: modular-agent-e2e
- `profile`: workspace-artifact-retention
- `graph_mode`: static
- `publication_contract`: db-marker-v1
- `status`: completed
- `started_at`: 2026-07-31 11:40:00 +0800
- `updated_at`: 2026-07-31 12:30:00 +0800

## 状态回溯

- `state_sequence`: recall_context -> classify_layer -> plan_graph -> implement -> verify -> inspect -> persist
- `current_state`: persist
- `failure_state`: 无
- `rollback_target`: 无
- `failure_reason`: 无
- `reviewer`: ysyx-coordinator
- `inspector`: agent-system
- `evidence_policy`: task-report + dispatch-log + review + run-manifest + evidence-index

## Result

Status: **PASS**

本轮只清理本地 RV64 Verilog/SystemVerilog 工程中可再生的 EDA
编译/展开产物；未修改 production RTL、testbench、断言、综合网表、STA/PPA
结果、Linux 当前 platform 产物、Git 对象或既有 task-run evidence。

- 冻结计划 SHA-256：
  `44c796ccad0f2082d2546ab31f131b4e1cd3c0266bdb609268f1d544c00f7884`
- 清理对象：7,094
  - `tmp/**/*.vvp`：7,077 个，4,223,938,560 B allocated upper bound
  - `tmp/**/obj_dir`：16 个，3,021,541,376 B allocated upper bound
  - `fpga/.Xil`：1 个，345,079,808 B allocated upper bound
- 计划 allocated upper bound：7,590,559,744 B
- 文件系统可用空间实增：7,585,472,512 B
- 计划目标残留：0
- quarantine 残留：0

## Retention boundary

以下对象明确保留：

- 三个含未提交 RTL/TB 的 Git 工作树：
  `tmp/r3p2-early-wake-sandbox`、
  `tmp/r3p2-functional-regress/r2p5-worktree`、
  `tmp/r4-dual-hit-sandbox`
- `.github/task-runs/**` 的报告、日志和 evidence
- `.github/runtime-artifacts`、`.github/db-backup` 与 Git object store
- `Linux/env/build` 和当前 Linux platform build
- `npc/rv64/build`、`npc/rv64/testbench/build` 及所有命名 NPC build
- `.github/cache/github-index.sqlite` 与被 retained 文档引用的
  `.github/cache/rv64-functional-v9l`
- 综合 console、Yosys/STA 日志、网表和 PPA 结果

保护闭包包含 43,129 条 Git tracked path、66,504 条 DB evidence asset
path，以及 task-run 根层 11,281 个 retained source 导出的合计 125,256 条
规范化引用。2,016 个 evidence-reference 目标和 6 个 tracked 目标被拒绝，
未进入删除计划。

## Execution contract

执行器先写 `RUNNING`，持有排他 cleanup lock，并对每个目标执行：

1. cached Git/evidence/protected-root 判定与 Git index identity 复核；
2. 从 repository root 逐级以 dirfd + `O_NOFOLLOW` 打开父目录；
3. 核验 device/inode/type/mtime/size；
4. 原子 rename 到同文件系统 quarantine；
5. 对目录再次拒绝嵌套 `.git`；
6. 全部目标隔离完成后，再复核 Git/evidence/EDA/protected-root；
7. 仅在复核通过后清除 quarantine。

异常或 HUP/INT/TERM 在隔离阶段会回滚；purge 阶段保留精确 journal cursor。
`scripts/task-run-status.sh` 负责 `RUNNING/FAIL/PASS`，PASS 还同时绑定 plan
digest 和 `execution-result.json`。

## Independent review

初审为 BLOCK，指出全量验证与字符串路径删除之间的 TOCTOU、缺 manifest
run 的引用闭包、当前 NPC/Linux build 判定依据、signal 状态和脏工作树
内容摘要不足。修正后独立二审为 **APPROVE**，未发现 local single-flight
契约内会造成 RTL 或 evidence 丢失的 blocker。

Residual risk：不遵守 workspace lock 的外部并发可在 purge 窗口新增引用；
这不属于当前 single-flight 模型。allocated upper bound 也不等于保证回收量，
实际值可能受 hardlink/reflink/shared extent 影响。

## Postflight

- task-run status：`PASS`
- journal：7,094 `intent`、7,094 `staged`、7,094 `purged`
- artifact audit：PASS
- task-run-status HUP/INT/TERM 单测：PASS
- strict guard：RC=1
  - `npc-dev`：PASS，命中当前 V11S evidence
  - `nemu-dev`：缺 evidence，触发路径为任务外既存
    `nemu/src/isa/riscv64/inst/amo.c`

strict guard 的 `nemu-dev` 缺口作为范围豁免保留；本次没有修改 NEMU，也不以
清理任务运行或伪造 NEMU profile。该豁免不影响本轮 7,094 个未跟踪 EDA
产物的删除事实，但不能外推为全工作树 strict PASS。

## Scope

本轮不证明 RV64 RTL 功能、架构稳定性、完整系统行为或 PPA 晋级；这些结论
继续由各自的仿真、综合、STA 与系统 evidence 管线给出。
