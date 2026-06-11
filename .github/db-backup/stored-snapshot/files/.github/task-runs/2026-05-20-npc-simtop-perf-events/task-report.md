# Task Report

## 基本信息

- `task_id`: `2026-05-20-npc-simtop-perf-events`
- `task_slug`: `npc-simtop-perf-events`
- `graph_template`: `regression-debug-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-20`
- `updated_at`: `2026-05-20`

## 任务目标

- `source_request`: 用户指出结束统计中 ICache/DCache/writeback 为 0，并要求把仿真统计放到 DPI-C 仿真顶层，通过层次化引用拉出，与 core 分离；branch/JAL/JALR 统计同理。
- `goal`: `NpcSimTop.sv` 负责采样 RTL 内部性能事件，host 只累加 DPI 事件并打印。
- `scope`: `NpcSimTop.sv`、`cpu-exec.cpp`、memory/task-runs。

## 选图说明

- `selected_template`: `regression-debug-loop`
- `why_this_graph`: 这是仿真观测链调整，必须验证 lint/build/功能回归和统计输出。
- `dynamic_nodes_added`: 无。
- `why_dynamic_nodes_were_needed`: 不需要扩图。

## RTL 推导摘要

- `需求要点`: 不改 `NpcCore` 端口；用 DPI-C 顶层层次化引用采样 control/cache 事件；删除 host 侧 commit opcode 分支统计和 legacy host cache 统计输出。
- `协议`: `NpcSimTop` 在 posedge 中调用 `npc_control_flow_event/npc_icache_event/npc_dcache_event`；host 侧函数只做计数，不反向影响 RTL。
- `状态机`: ICache/DCache access 只在 CPU-side `valid && ready` 且 cacheable 时计数；hit/miss 来自对应 lookup hit wire；控制流事件使用 `bpu_update_valid_w` 作为 EX 有效控制流事件边界。
- `不变量`: `NpcCore` 纯 RTL 端口 ABI 不变；`RTL_CORE_SRCS/STA_RTL_FILES` 不含 `NpcSimTop.sv`；DCache 当前无 dirty eviction，所以 writeback 统计保持 0。
- `数据通路骨架`: RTL 内部事件 -> `NpcSimTop` 层次采样 -> DPI event -> `cpu-exec.cpp` 计数 -> 结束统计打印。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | `cache.c`、`paddr.c`、`NpcSimTop.sv`、RTL cache/core | 确认旧 cache 统计不在主路径 | 源码阅读 |
| implement | codex | completed | `NpcSimTop.sv`、`cpu-exec.cpp` | DPI 性能事件采样与 host 计数 | 文件 diff |
| verify | codex | completed | 新构建 | lint/build/cpu-test 通过，统计非零 | 终端输出 |
| record | codex | completed | 验证结果 | memory/task-runs 更新 | 本文件与 memory 条目 |

## 关键产物

- `artifacts`: `npc_control_flow_event`、`npc_icache_event`、`npc_dcache_event`；`report_cache_stats()`。
- `logs_or_traces`: `cpu-tests add` 输出 ICache/DCache 非零统计。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 无。
- `risk_assessment`: 统计层次引用依赖 `ICache/DCache` 内部 wire 命名；若后续重命名内部信号，需要同步 `NpcSimTop.sv` 的仿真采样逻辑。

## 下一步建议

1. 长跑 CoreMark/MicroBench 时用新统计观察 RTL I/D cache 命中率和 write-through store 次数。
2. 若后续改 DCache 为 write-back，需要把 dirty eviction event 同步填到 `npc_dcache_event(... writeback ...)`。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无。
- `should_promote_to_static_template`: 否。
- `reason`: 单次仿真观测链调整。

## 收尾结论

- `final_result`: 性能统计已迁到 DPI-C 仿真顶层，`NpcCore` 接口不变。
- `evidence_summary`: `make -C npc/single lint` PASS；`make -C npc/single -B -j4` PASS；`cpu-tests add` PASS 且 I/D cache 统计非零。
- `notes`: DCache 当前 writeback 为 0 是设计属性，不是统计未接入；新增 `write-through store` 更能反映当前 store 行为。
