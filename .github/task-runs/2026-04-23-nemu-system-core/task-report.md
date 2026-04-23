# Task Report

## 基本信息

- `task_id`: `2026-04-23-nemu-system-core`
- `task_slug`: `nemu-system-core`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-04-23 17:48 +0800`
- `updated_at`: `2026-04-23 17:48 +0800`

## 任务目标

- `source_request`: 用户已实现异常处理部分顶层模块，希望补全 `inst` 中核心逻辑。
- `goal`: 补齐 NEMU RISC-V `SYSTEM` 指令核心，使 AM CTE 的 `ecall/csrr/csrw/mret` 闭环可执行。
- `scope`: `nemu/src/isa/riscv32/inst.c`、CSR 状态定义、trap 入口状态维护，以及 AM 侧缺失的 `MSTATUS_MIE` 位定义。

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: 本任务以 NEMU 参考路径为主，验证对象是 `am-kernels -> abstract-machine -> NEMU`。
- `dynamic_nodes_added`: `am-cte-build-fix`
- `why_dynamic_nodes_were_needed`: 验证时发现 AM `cte.c` 已引用 `MSTATUS_MIE`，但公共头未定义，需先补齐才能构建 CTE 测试。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | AGENTS、memory、NEMU/AM/CSR study | 确认最小目标为 Zicsr + ECALL + MRET | 已读相关说明与源码 |
| implement-system | Codex | completed | `inst.c`、`isa-def.h`、`intr.c` | SYSTEM 指令与 CSR 分发补齐 | `make -C nemu -j4` 通过 |
| am-cte-build-fix | Codex | completed | `cte.c` 编译错误 | `riscv.h` 补 `MSTATUS_MIE` | AM CTE 构建通过 |
| verify | Codex | completed | NEMU 与 AM 镜像 | add PASS；yield 连续输出 `y` | `cpu-tests ALL=add` PASS；`am-tests mainargs=i` timeout 前输出 `yyyy` |
| record | Codex | completed | 代码与验证结果 | memory 和 task-run 更新 | 本文件与 dispatch log |

## 关键产物

- `artifacts`: 修改后的 NEMU RISC-V SYSTEM 指令实现与 AM MSTATUS 位定义。
- `logs_or_traces`: 终端验证输出。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/modules/abstract-machine.md`

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 外部中断投递仍未实现，`isa_query_intr()` 与 `dev_raise_intr()` 仍为空桩。
- `risk_assessment`: 当前覆盖同步 trap/CSR/MRET；定时器或外部中断后续还需要单独验证。

## 下一步建议

1. 若继续做中断，先补 `dev_raise_intr()` 与 `isa_query_intr()` 的 MTIP/MEIP 投递链路。
2. 若继续做 NPC RTL，对照本次 NEMU 语义实现 CSR block 和 trap controller。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无。
- `should_promote_to_static_template`: 否。
- `reason`: 这是一次具体功能补全，不是新的稳定调度模板。

## 收尾结论

- `final_result`: NEMU RISC-V 同步 trap 与 AM CTE yield 闭环已打通。
- `evidence_summary`: `make -C nemu -j4` 通过；`cpu-tests ALL=add` PASS；`am-tests mainargs=i` 在 timeout 前输出连续 `y`。
- `notes`: NEMU 构建期间 `.git/index` 写入因沙箱只读报错，但 Makefile 标记为 ignored，最终链接与测试均继续完成。
