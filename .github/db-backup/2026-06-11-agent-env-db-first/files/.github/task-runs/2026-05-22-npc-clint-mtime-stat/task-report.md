# Task Report

## 基本信息

- `task_id`: `2026-05-22-npc-clint-mtime-stat`
- `task_slug`: `npc-clint-mtime-stat`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-22`
- `updated_at`: `2026-05-22`

## 任务目标

- `source_request`: 将 CLINT 中的 `mtime` 用层次化引用引出到仿真统计中，观察它是否和 DPIC/host 侧 `cycles` 相等。
- `goal`: 在 NPC 结束统计和 `info s` 中显示 CLINT `mtime`，并和 `npc_stats()->cycles` 做同值检查。
- `scope`: 仅改仿真观测链路与 host 统计；不改变 CLINT AXI-Lite 协议、`mtime` 递增/写入语义、core ABI 或 guest 可见行为。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 任务跨 `NpcSimTop.sv` 仿真壳、C++ 执行器和记忆记录，不需要完整 reference-loop，但需要实现与验证闭环。
- `dynamic_nodes_added`: `recall -> inspect -> implement -> verify -> record`
- `why_dynamic_nodes_were_needed`: 需要先确认 CLINT 实例层次、host cycles 统计位置和既有层次化统计风格，再落最小改动。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | `codex` | `completed` | `.github/AGENTS.md`、Copilot 规则、memory、NPC study | 关键约束：mtime 是平台 MMIO timer，不等同 mcycle | 已读相关规则与 NPC 记忆 |
| `inspect` | `codex` | `completed` | `AxiLiteClint.v`、`NpcSimTop.sv`、`cpu-exec.cpp`、`utils.h` | 确认 `u_clint_axi.mtime_q`、`npc_stats()->cycles`、统计输出位置 | `rg/sed` 静态检查 |
| `implement` | `codex` | `completed` | 现有仿真统计路径 | `debug_clint_mtime_o`、`NpcStats::clint_mtime`、统计匹配输出 | 代码改动已落盘 |
| `verify` | `codex` | `completed` | lint/build/测试镜像 | lint/build PASS，统计显示 match=yes | 见下方证据 |
| `record` | `codex` | `completed` | 改动与验证结论 | 更新 memory 与 task-run | 本文件与 `dispatch-log.md` |

## RTL 推导摘要

- 需求要点：新增只读仿真观测口 `debug_clint_mtime_o[63:0]`，反映 CLINT 内部 `mtime_q`；host 在每个完整周期后采样到 `NpcStats::clint_mtime`。
- 协议规则：该观测口不是 AXI/CPU 协议信号，不参与 valid/ready，不对 guest 可见；host 采样点在 `eval_half_cycle(1)` 之后，与 `cycles++` 同拍对齐。
- 状态机骨架：不新增状态机；CLINT 仍由既有 `mtime_q` 在 reset 清零、非 reset 按 `MTIME_INCREMENT` 递增，MMIO 写仍覆盖对应半字。
- 关键不变量：观测路径只读，不能反向驱动 CLINT；不改变 `mtime` reset/递增/写入优先级；`cycles` 与 `mtime` 的同值比较只表示本轮无 guest 写 `mtime` 时的仿真周期对齐关系。
- 数据通路骨架：`NpcSimTop.debug_clint_mtime_o = u_clint_axi.mtime_q`，C++ `step_cycle()` 在 posedge eval 后写入 `npc_stats()->clint_mtime`。

## 关键产物

- `artifacts`: `npc/single/vsrc/sim/NpcSimTop.sv`、`npc/single/csrc/include/utils.h`、`npc/single/csrc/cpu/cpu-exec.cpp`
- `logs_or_traces`: 终端验证输出
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 若 guest 后续通过 MMIO 写 `mtime`，统计中的 `match=no` 是预期现象，因为 `mtime` 已不再等于从 reset 后自然递增的周期数。

## 下一步建议

1. 若要做真正 timer interrupt，继续补 `mtimecmp -> MTIP -> trap`，并将 `match` 解释和 guest 写 `mtime` 的测试分开。
2. 若需要长跑统计采样，可在 host 侧增加“首次 mismatch cycle/mtime”记录，而不是每拍 DPI 打印。

## 模板升级候选

- `repeated_dynamic_subgraph`: RTL 内部性能/调试信号层次化暴露到 host statistics。
- `should_promote_to_static_template`: 暂不需要。
- `reason`: 目前仍是局部统计增强。

## 收尾结论

- `final_result`: 已将 CLINT `mtime` 引入 NPC 仿真统计，当前无 guest 写 `mtime` 的运行中与 host `cycles` 相等。
- `evidence_summary`: `make -C npc/single lint` PASS；`make -C npc/single -j14` PASS；`add-riscv32-npc.bin --no-diff --no-progress` 显示 `CLINT mtime = 1355 (mtime-cycles=+0, match=yes)`；`make -C npc/single/testbench RESULT_DIR=/tmp/npc-mtime-stat-tests run` 25/25 PASS；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 38/38 PASS。
- `notes`: 本地运行显示 Difftest OFF。
