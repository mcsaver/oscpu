# Task Report

## 基本信息

- `task_id`: `2026-05-20-npc-bubble-audit`
- `task_slug`: `npc-bubble-audit`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-20`
- `updated_at`: `2026-05-20`

## 任务目标

- `source_request`: 逐模块分析 NPC 流水线，减少不必要的空泡。
- `goal`: 在不直接修改 RTL 的前提下，定位当前最可能制造额外 bubble 的模块边界，并给出优先级。
- `scope`: `npc/single/vsrc` 的 BPU/IF/控制/LSU/DCache/比较与顶层前递链路；短用例 difftest 只做基线证据。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | `.github/memory/**`, `npc/single/design/study/**` | 读取项目阶段、NPC 约束、RTL 工作流 | 已确认当前处于流水线 + RTL I/D cache + BPU 阶段 |
| static-audit | codex | completed | `BranchPredictor.v`, `IfStage.v`, `PipelineControl.v`, `MemoryStageControl.v`, `LSU*.v`, `DCache.v`, `CompareUnit.v`, `NpcCore.v` | 空泡来源排序 | 主要机会点是 DCache hit/MemoryStage 同拍响应/store buffer/计数器 |
| verify-sample | codex | completed | `cpu-tests` 短用例 | 当前 CPI 小样本 | `lint` PASS；`add/load-store/if-else/switch` difftest PASS |

## 关键结论

- ICache/IfStage 已有同拍 hit 响应与同拍 request/response 接收，当前前端顺序 hit 不再是主要 bubble 来源。
- DCache 仍采用锁存请求后下一拍 lookup、再下一拍 response 的阻塞 hit 路径；MemoryStageControl 也只认 `mem_pending_q && rsp_valid`，因此无法消费未来可能出现的 req/rsp 同拍命中响应。
- EX/MEM 被 MEM 响应严格阻塞，cacheable store 当前必须等 write-through 外部响应，尚无 store buffer。
- BranchPredictor 能覆盖 JAL/条件分支常规预测，但 RAS 只在 EX update，不做预测期投机 push/pop；短函数 call/return 仍可能多付 redirect bubble。
- 当前 host 侧 legacy cache counter 已失效，缺 RTL cache/BPU 性能计数，后续优化前应补最小计数器，避免只靠总 CPI 归因。

## 验证证据

- `make -C npc/single lint`: PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`cycles=1790`、`commits=838`、`CPI=2.136`。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=load-store run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`cycles=1040`、`commits=370`、`CPI=2.811`。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=if-else run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`cycles=718`、`commits=274`、`CPI=2.620`。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=switch run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`cycles=686`、`commits=242`、`CPI=2.835`。

## 下一步建议

1. 先补 RTL ICache/DCache/BPU 计数器，至少区分访问、hit、miss、fill、store wait、branch redirect。
2. 优先把 DCache load hit 改成组合响应，并同步改 MemoryStageControl 支持 req/rsp 同拍完成。
3. 再评估 cacheable store buffer 或 store hit early-ack，明确 fault 精确性边界后再落 RTL。

## 收尾结论

- `final_result`: 完成逐模块空泡审计，未修改 RTL。
- `evidence_summary`: lint 与 4 个短 difftest 样本通过。
- `notes`: 真正落 RTL 时需按 `.github/instructions/rtl-generation-workflow.instructions.md` 补齐四段式推导。
