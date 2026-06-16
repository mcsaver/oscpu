# Task Report

## 基本信息

- `task_id`: `2026-05-19-nemu-bpu`
- `task_slug`: `nemu-bpu`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-19 18:30:00 +0800`
- `updated_at`: `2026-05-19 18:54:17 +0800`

## 任务目标

- `source_request`: `请你给我的nemu添加bpu，包括ras的，参数可定义化`
- `goal`: 为 NEMU RISC-V native 路径增加可配置 BPU/RAS 预测统计模型，并保持参考执行语义不变。
- `scope`: NEMU Kconfig、CPU 执行提交路径、BPU 模型、单元测试、统计输出和项目记忆。

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: BPU 接入 NEMU RISC-V 控制流提交路径，必须通过 AM cpu-tests 参考闭环验证没有 PC 语义回归。
- `dynamic_nodes_added`: `bpu-unit-red-green`、`bpu-stat-output`、`bpu-kconfig-rehome`
- `why_dynamic_nodes_were_needed`: 现有模板没有覆盖 BPU/RAS 模型本身的单元行为、新 counter 输出，以及后续将 BPU 参数迁出测试调试菜单的配置结构调整。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall-context` | Codex | completed | `.github/AGENTS.md`、memory、NEMU 当前实现 | 取指/执行/统计链路摘要 | 已确认 `exec_once -> isa_exec_once -> dnpc -> cpu.pc` 调用链 |
| `bpu-unit-red-green` | Codex | completed | BPU API 目标 | `nemu/tests/bpu_unit.c`、`bpu.h`、`bpu.c` | RED: 缺 `cpu/bpu.h`/`bpu.c`；GREEN: `/tmp/bpu_unit` 输出 `bpu_unit PASS` |
| `bpu-integration` | Codex | completed | `cpu-exec.c`、`monitor.c`、Kconfig | `CONFIG_BPU` 参数、初始化、提交与统计输出 | `make -C nemu -j4` 通过 |
| `bpu-kconfig-rehome` | Codex | completed | 用户要求 BPU 配置不要放在 `Testing and Debugging` | `nemu/src/cpu/Kconfig` 的 `CPU Performance Models` 独立菜单，主 `nemu/Kconfig` 顶层 source | 静态检查通过、`syncconfig` 通过、`make -C nemu -j4` 通过、`ALL=add` PASS |
| `rv32-reference-verify` | Codex | completed | AM cpu-tests | 功能回归结果 | `ALL=add` PASS 并输出 BPU counter；全量 35/35 PASS |
| `record-memory` | Codex | completed | 验证结果与改动范围 | memory 与 task-run 更新 | 更新 `project-status.md`、`modules/nemu.md`、`decisions.md` |

## 关键产物

- `artifacts`: `nemu/include/cpu/bpu.h`、`nemu/src/cpu/bpu.c`、`nemu/src/cpu/Kconfig`、`nemu/tests/bpu_unit.c`、`nemu/Kconfig`、`nemu/src/cpu/cpu-exec.c`、`nemu/src/monitor/monitor.c`
- `logs_or_traces`: 终端验证输出；`am-kernels/tests/cpu-tests/build/nemu-log.txt`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/decisions.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: BPU 当前是统计模型，不影响功能 PC；后续若要引入前端时序或错误恢复，需要单独建模，不能直接复用当前透明提交模型改写 PC。

## 下一步建议

1. 若要对比不同预测器参数，可通过 `menuconfig` 调整 BTB/BHT/RAS/GHR 参数后跑同一工作负载，对比 `bpu branch/target/btb/ras` counter。
2. 若后续要迁移到 NPC/RTL，先把这里的 counter 当作 workload profile，再设计 RTL 侧取指、预测、redirect 和 flush 协议。

## 模板升级候选

- `repeated_dynamic_subgraph`: 暂无
- `should_promote_to_static_template`: 否
- `reason`: 当前是一次 NEMU 性能模型扩展，不足以形成通用静态图。

## 收尾结论

- `final_result`: 已完成可配置 BPU/RAS 透明统计模型并接入 NEMU 结束统计；BPU 参数配置已迁移到独立 `CPU Performance Models` 顶层菜单。
- `evidence_summary`: `bpu_unit PASS`、`cache_unit PASS`、`make -C nemu -j4` 通过、`ALL=add` PASS 且输出 BPU counter、cpu-tests 35/35 PASS；配置迁移后静态检查、`syncconfig`、`make -C nemu -j4`、`bpu_unit PASS`、`ALL=add` PASS。
- `notes`: 当前工作区已有大量未提交历史改动，本任务只在其上追加 BPU 相关文件与记录，未回退既有改动。
