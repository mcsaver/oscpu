# Task Report

## 基本信息

- `task_id`: `2026-05-21-npc-difftest-default-on`
- `task_slug`: `npc-difftest-default-on`
- `graph_template`: `regression-debug-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-21 19:31 CST`
- `updated_at`: `2026-05-21 19:31 CST`

## 任务目标

- `source_request`: 用户指出“开启 difftest 时就是要和 NEMU 逐条对比”，要求修改当前默认行为。
- `goal`: `CONFIG_NPC_DIFFTEST=y` 的验证构建启动即默认启用 NEMU reference 逐提交对比；裸跑必须显式关闭。
- `scope`: `npc/single` monitor 参数、welcome 状态显示、默认配置初始化、Kconfig help、README，以及长期记忆。

## 选图说明

- `selected_template`: `regression-debug-loop`
- `why_this_graph`: 该任务是默认验证语义与回归路径修正，需要定位当前开关链路、修改行为并用真实运行证据确认。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | `.github/memory/modules/difftest.md`、`npc/single/csrc/*` | 确认旧行为是编译期有能力但运行时默认不启用 | 源码与记忆文件审计 |
| implement | Codex | completed | `utils.c`、`monitor.c`、`Kconfig`、`README.md` | 默认 `difftest=true`，新增 `--no-diff`，welcome 显示 `Difftest: ON/OFF`，文档更新 | 工作区补丁 |
| verify | Codex | completed | 重建后的 `NpcSimTop` 和 `add-riscv32-npc.bin` | 默认加载 reference 且显示 `Difftest: ON`；`--no-diff` 不加载 reference 且显示 `Difftest: OFF`；两者均 GOOD TRAP | `make -C npc/single -j4` PASS；直接运行验证 PASS |
| record | Codex | completed | 验证结果 | 更新 project status、npc/difftest 模块记忆、task-run | 本目录与 `.github/memory/**` |

## 关键产物

- `artifacts`: `npc/single/csrc/utils.c`、`npc/single/csrc/monitor/monitor.c`、`npc/single/Kconfig`、`npc/single/README.md`
- `logs_or_traces`: 终端验证输出
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/difftest.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 当前仅改变运行默认值；性能跑分应显式使用 `--no-diff` 或 `perf_defconfig`。

## 下一步建议

1. 后续跑性能脚本时确认是否传入 `--no-diff` 或切到 `perf_defconfig`。
2. 若需要更强 difftest 覆盖，可继续扩展 CSR 或内存一致性比较范围。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无
- `should_promote_to_static_template`: 否
- `reason`: 本轮是一次性语义修正。

## 收尾结论

- `final_result`: `CONFIG_NPC_DIFFTEST=y` 现在默认逐条和 NEMU reference 对比；`--no-diff` 可单次关闭；welcome 会显示 `Difftest: ON/OFF`。
- `evidence_summary`: `make -C npc/single -j4` PASS；`NpcSimTop --help` 显示 `--no-diff`；默认运行 `add` 打印 `[npc-diff] reference enabled...`、`Difftest: ON` 并 GOOD TRAP；`--no-diff` 运行不加载 reference、显示 `Difftest: OFF` 且 GOOD TRAP。
- `notes`: 旧的 `--diff=default|path` 仍保留，用于显式选择 reference。
