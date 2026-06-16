# Task Report

## 基本信息

- `task_id`: `2026-05-22-npc-define-params`
- `task_slug`: `npc-define-params`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-22`
- `updated_at`: `2026-05-22`

## 任务目标

- `source_request`: 用户要求把 core 中分散在模块定义里的可定制参数统一放到 `define.v` 管理，便于后续由另一套软件定义参数。
- `goal`: 建立 NPC RTL 结构参数的单一默认来源，并保持现有行为不变。
- `scope`: `npc/single/vsrc/include/define.v`、BPU/IF/pipe/cache 相关 RTL、`tb_branch_predictor`、NPC memory/decision 记录。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 任务是 RTL 参数治理，不是现有 reference/debug 模板。
- `dynamic_nodes_added`: `recall -> audit-params -> refactor-defines -> verify -> record`
- `why_dynamic_nodes_were_needed`: 需要先区分 core 级结构参数和通用 IP 泛型，再落 RTL 与测试更新。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | Codex | completed | `.github/AGENTS.md`、Copilot 指令、project/memory、NPC study | 约束摘要 | 已按要求读取相关文件 |
| `audit-params` | Codex | completed | `rg parameter/localparam`、相关 RTL | 参数边界清单 | 确认可集中项为 reset/cacheable/AXI 地址图、BPU、cache |
| `refactor-defines` | Codex | completed | 参数边界 | `define.v` 可配置宏区与 RTL 引用替换 | Verilator lint PASS |
| `verify` | Codex | completed | 改动后源码 | lint、testbench、build、cpu-tests | 见证据摘要 |
| `record` | Codex | completed | 改动与验证结果 | memory/decision/task-runs 更新 | 本文件与 dispatch log |

## RTL 推导摘要

- **需求要点**: 参数默认值集中到 `define.v`，外部软件可生成或覆盖；保持 NPC reset、BPU、cache、AXI 地址图行为等价。
- **协议规则**: 不修改 IFU/cache CPU 侧 valid/ready，不修改 cache miss/refill/writeback AXI-like 握手，不修改 BPU update/lookup 时序。
- **状态机骨架**: `ICache`、`DCache`、`BranchPredictor`、pipeline registers 状态机保持原状态与转移；只替换常量来源。
- **关键不变量**: `BPU_BHT_INDEX_W` 必须贯穿 BPU 输出、IF buffer、IF/ID、ID/EX 与 update 输入；I/D cache 的 `LINE_WORDS/LINE_COUNT/OFFSET_BITS/INDEX_BITS/WORD_BITS` 必须成组一致；cacheable 范围与 AXI PMEM 地址图由 `define.v` 同源维护。
- **数据通路骨架**: 未新增寄存器、mux、反馈路径；BPU arrays、cache SRAM 深度和地址切片仍由同一宽度驱动。

## 关键产物

- `artifacts`: `npc/single/vsrc/include/define.v` 新增可配置宏区；BPU/IF/pipe/cache 改为引用宏；`tb_branch_predictor` 改为宏驱动。
- `logs_or_traces`: `/tmp/npc-param-define-tests`、`/tmp/npc-param-define-pipe`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/decisions.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 本轮未跑综合/STA；只验证 Verilator lint/build 与功能回归。当前本地 cpu-tests 输出显示 Difftest OFF。

## 下一步建议

1. 若外部软件开始生成 `define.v`，增加一次非默认参数 smoke test，例如缩小 BPU BHT 或 cache line count 后跑 `tb_branch_predictor/tb_icache/tb_dcache`。
2. 后续新增 core 级结构旋钮时先写入 `define.v`，并同步避免 testbench 再写死旧位宽。

## 模板升级候选

- `repeated_dynamic_subgraph`: RTL 参数治理可复用为 `audit-params -> macro-default -> width-test -> regression`。
- `should_promote_to_static_template`: 否
- `reason`: 当前还不是高频重复任务。

## 收尾结论

- `final_result`: 已完成参数集中管理，保持现有默认行为。
- `evidence_summary`: `make -C npc/single lint` PASS；`make -C npc/single/testbench RESULT_DIR=/tmp/npc-param-define-tests run` 24/24 PASS；`make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-param-define-pipe pipe_test` PASS；`make -C npc/single -j14` PASS；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 38/38 PASS。
- `notes`: 通用 IP 参数如 SRAM 宽度和 crossbar master/slave 数量仍保留为模块泛型，不纳入 NPC core 全局参数区。
