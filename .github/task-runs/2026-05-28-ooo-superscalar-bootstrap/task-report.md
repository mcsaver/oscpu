# Task Report

## 基本信息

- `task_id`: `2026-05-28-ooo-superscalar-bootstrap`
- `task_slug`: `ooo-superscalar-bootstrap`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-28`
- `updated_at`: `2026-05-28`

## 任务目标

- `source_request`: `/goal 完成一个乱序超标量处理器，cpi=0.5`
- `goal`: 在现有 NPC 顺序流水线基础上推进 OoO/superscalar 架构改造，长期目标 CPI=0.5。
- `scope`: 本次只完成第一阶段 OoO 后端基础件 bootstrap，不接入当前 `NpcCore` 主路径。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 现有静态图更偏回归/bring-up，缺少 OoO 架构拆分节点；本任务需要先建立 rename/freelist/ROB 这些后续节点的硬依赖。
- `dynamic_nodes_added`: `recall`、`arch-cut`、`rtl-derive`、`rtl-implement`、`verify`、`record`
- `why_dynamic_nodes_were_needed`: 乱序超标量是跨前端、rename、issue、execute、LSQ、commit 的架构级任务，不能直接在顺序流水线上症状式修改。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | codex | completed | `.github/AGENTS.md`、Copilot 指令、project-status、known-issues、npc memory、study README/checklist | 当前 NPC 为单发顺序流水线，commit 口在 MEM/WB，CoreMark CPI 最新记录约 1.408 | 已读文件与命令输出 |
| `arch-cut` | codex | completed | `NpcCore.v`、`PipelineControl.v`、`RegisterFile.v`、`MemoryStage.v` | 第一阶段选择独立实现 rename map、freelist、ROB，不接入主路径 | 现有主路径仍为单发顺序提交 |
| `rtl-derive` | codex | completed | RTL 工作流约束 | 完成需求、协议、状态机、不变量、数据通路推导 | 对话记录与本文件“RTL 推导摘要” |
| `rtl-implement` | codex | completed | 推导结果 | 新增 `OooRenameMap`、`OooFreeList`、`OooRob` 与 3 个 testbench | 文件落盘 |
| `verify` | codex | completed | 新增 RTL 与 testbench | lint/build/smoke 通过 | 见“关键产物” |
| `record` | codex | completed | 验证结果 | 更新 project-status、npc memory、本 task-run | 本目录与 memory diff |

## RTL 推导摘要

### 需求

- `OooRenameMap`: 2-wide speculative rename map；x0 固定 p0；lane1 能看到 lane0 的同拍 RAW/WAW；flush 回初始映射。
- `OooFreeList`: 64 个物理寄存器，初始 p32..p63 空闲；支持 2 alloc/2 free；忽略 p0；释放项下一拍再可分配。
- `OooRob`: 16-entry ROB；支持 2 dispatch/2 writeback/2 commit；提交顺序从 head 开始；异常 head 阻断第二条提交。
- Out-of-scope: 本轮不实现双取/双译码、issue queue、wakeup/select、LSQ、物理寄存器堆、分支 checkpoint、ROB 接管 CSR/commit。

### 协议规则

- 所有模块单时钟同步复位；`flush_i` 清回初始状态。
- rename map 是组合查询、时钟沿更新。
- freelist 使用 valid/ready；alloc 只从当前队列取项，free 在下一拍可见。
- ROB 的 dispatch/writeback/commit 可同拍发生；dispatch 可使用同拍 commit 释放出来的 entry。
- ROB writeback 只标记 valid entry done；commit 只对 valid && done 的 head entry 生效。

### 状态机

- rename map: `RESET/FLUSH -> NORMAL`，正常态按 lane0 后 lane1 的程序序更新 map。
- freelist: `head/tail/count` 环形 FIFO，reset/flush 重新装入 p32..p63。
- ROB: `head/tail/count + entry valid/done` 环形窗口，reset/flush 清空全部 entry。

### 不变量

- x0 永远映射到 p0，freelist 永远不分配 p0。
- lane1 的 source 与 old-pdest 必须能看到 lane0 同拍新映射。
- ROB commit1 只有在 commit0 valid 且 commit0 无异常时才允许 valid。
- ROB 异常只在提交边界对外暴露，不允许 younger entry 越过异常提交。
- ROB flush 后 `count=0`，`empty=1`。

### 数据通路骨架

- rename map: `map_q[32]` + lane0 bypass function + lane0/lane1 顺序写入。
- freelist: `fifo_q[64]` + `head_q/tail_q/count_q` + 两路 alloc pop + 两路 free push。
- ROB: entry arrays 保存 pc/inst/rd/new/old/data/exception；head 输出 commit；tail 输出 dispatch index；writeback 按 ROB index 标记 done。

## 关键产物

- `artifacts`: `npc/single/vsrc/ooo/OooRenameMap.v`、`OooFreeList.v`、`OooRob.v`；`npc/single/testbench/tests/tb_ooo_*.sv`
- `logs_or_traces`:
  - 新增 3 个 OoO testbench PASS：`/tmp/npc-ooo-tb-results/logs/`
  - 全量模块 testbench PASS：30/30，`/tmp/npc-single-ooo-full-tb-results`
  - `make -C npc/single lint` PASS
  - `make -C npc/single -j4` PASS
  - `riscv32-npc add` GOOD TRAP，`cycles=1509/commits=838/CPI=1.801`
  - `git diff --check` PASS
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无本轮阻塞。
- `missing_dependencies`: 后续需要 issue queue、physical register file、LSQ、branch checkpoint、ROB commit 接管 CSR/RF/DiffTest。
- `risk_assessment`: 当前 OoO 模块尚未接入主路径，因此功能风险低；但距离 CPI=0.5 仍是架构级长链任务。

## 下一步建议

1. 增加 2-wide decode/rename bundle adapter，把 `DecodeStage` 输出打包到 rename/ROB dispatch 输入，同时保持旧单发路径可选。
2. 实现物理寄存器堆、busy table 与整数 issue queue，先覆盖 ALU-only 指令的乱序执行和顺序提交。
3. 再接 load/store queue 和 cache miss 非阻塞化，否则 CoreMark/MicroBench 很难接近 CPI=0.5。

## 模板升级候选

- `repeated_dynamic_subgraph`: `ooo-backend-bringup`
- `should_promote_to_static_template`: `yes-if-repeated`
- `reason`: OoO CPU 改造会反复执行“推导 -> 独立模块 -> testbench -> 主路径接入 -> DiffTest”的固定图。

## 收尾结论

- `final_result`: 第一阶段 OoO 后端基础件已落地并通过模块级/主入口验证。
- `evidence_summary`: 3 个新增 testbench PASS，NPC single lint/build PASS，全量模块 30/30 PASS，`cpu-tests add` GOOD TRAP。
- `notes`: 本轮不声称完成 OoO/superscalar CPU，也不声称 CPI 改善；它是后续主路径改造的基础切片。

