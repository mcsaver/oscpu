# Dispatch Log

## RECALL

- 已读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`。
- 已读取 RTL 生成工作流与 NPC study 流程，补读 `npc/single/design/study/README.md`、`RV32I-ai-notes.md`、`RV32I-implementation-checklist.md`。
- 当前事实：OoO 后端和 `OooAluFetchCore` 已能通过模块 testbench，但默认 `NpcSimTop` 仍只实例化 `NpcCore`，host commit 路径只能可靠消费单提交。

## PLAN

1. 复核 `NpcSimTop`、`cpu-exec.cpp`、`OooAluFetchCore` 接口。
2. 补 host 双提交队列和实验顶层编译开关。
3. 让 `OooAluFetchCore` 支持 lane0 `ebreak` 作为 raw smoke 的正常退出。
4. 修复 OoO 后端纳入 Verilator 顶层后暴露的 lint/可编译性问题。
5. 跑实验顶层、OoO 套件、默认主线回归。
6. 写 memory/task-run，保留 CPI 未完成状态。

## DISPATCH

- `cpu-exec.cpp`：把 `g_commit_event` 改为 `g_commit_events[2]`，每条事件保存 GPR snapshot。
- `Makefile`：新增 `NPC_OOO_ALU_EXPERIMENT=1`，lint 和 build 统一传 `-DNPC_OOO_ALU_EXPERIMENT`。
- `NpcSimTop.sv`：默认 `NpcCore` 分支保持原层次化统计；实验分支实例化 `OooAluFetchCore`，tie-off LSU，禁用 cache/BPU 统计。
- `OooAluFetchCore.v`：lane0 `ebreak` 在 dispatch 状态进入 exit/halt。
- `OooIntIssueQueue.v`：从时序块里边 compact 边写数组，改为组合 next-state 后统一时序落库，解决 Verilator `BLKLOOPINIT`。

## ADAPT

- 第一次实验 lint 失败：`OooIntIssueQueue` 在 for-loop 中对数组做非阻塞赋值，作为真正顶层实例时触发 Verilator unsupported error。改为 next-state 结构后通过。
- 第二次实验 lint 只剩 warnings 且 Verilator 将 warnings fatal。已修正 `OooRob/OooFreeList/OooRenameMap` 位宽扩展/截断问题，并对实验分支 unused 观测进行显式消费或局部 lint 说明。

## VERIFY

- 实验 lint：PASS。
- 实验 build：PASS。
- 实验 raw ALU+ebreak smoke：GOOD TRAP，`cycles=29/commits=6/CPI=4.833`。
- OoO 11 项定向 testbench：PASS。
- 默认 lint：PASS。
- 全量模块 testbench：38/38 PASS。
- 默认 build：PASS。
- 默认 `cpu-tests add`：GOOD TRAP，`cycles=1509/commits=838/CPI=1.801`。

## RECORD

- 更新 `.github/memory/project-status.md`。
- 更新 `.github/memory/modules/npc.md`。
- 新增本目录 `task-report.md` 与 `dispatch-log.md`。
