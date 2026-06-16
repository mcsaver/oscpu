# Task Report

## 基本信息

- `task_id`: `2026-05-22-rtthread-am-context`
- `task_slug`: `rtthread-am-context`
- `graph_template`: `am-device-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-22`
- `updated_at`: `2026-05-22`

## 任务目标

- `source_request`: 用户先要求“结合 AM 的环境，完成 RT-Thread 的上下文的创建和切换功能”，后续在 `riscv32-npc` 运行时报 `context.c:69` 断言并要求修复。
- `goal`: 在 `Templates/rt-thread-am/bsp/abstract-machine` 中补齐 RT-Thread 线程栈初始化、线程切换和中断切换，并修复 RISC-V/NPC 路径的新线程栈对齐问题。
- `scope`: `bsp/abstract-machine/src/context.c`、`bsp/abstract-machine/src/interrupt.c`、项目记忆。

## 选图说明

- `selected_template`: `am-device-loop`
- `why_this_graph`: 任务本质是把 RT-Thread BSP 接到 AM CTE/中断环境，依赖 AM 事件、上下文和时钟 tick 的闭环验证。
- `dynamic_nodes_added`: `rtthread-abi-derive`、`shell-runtime-verify`、`npc-stack-align-debug`、`fix-riscv-stack-layout`、`verify-npc-native`
- `why_dynamic_nodes_were_needed`: RT-Thread 的 `sp` 保存约定与 AM `Context *` 返回约定需要额外推导；运行验证必须观察 shell、多线程和 tick 驱动调度；后续 NPC 断言需要把 RT-Thread BSP 栈布局与 RISC-V `kcontext()` 的实际 16B 对齐行为重新对齐。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | AGENTS、memory、AM/RT-Thread BSP 源码 | 当前 AM CTE 与 BSP 缺口 | 已读取必读规则和模块记忆 |
| rtthread-abi-derive | codex | completed | RT-Thread `rt_hw_stack_init/context_switch` 调用约定、AM `kcontext/yield/cte_init` | `thread->sp == Context *` 的桥接方案 | `context.c` 实现 |
| implement-context | codex | completed | `context.c` | 线程 trampoline、上下文创建、普通/中断切换、timer tick 事件处理 | 文件修改 |
| implement-interrupt | codex | completed | `interrupt.c`、RT-Thread 中断 API | `rt_base_t` 级别的 disable/enable 保存恢复 | 文件修改 |
| verify-build | codex | completed | RT-Thread AM BSP | native 镜像构建通过 | `make ARCH=native` PASS |
| shell-runtime-verify | codex | completed | `build/rtthread-native.elf` | RT-Thread shell 运行，多线程状态可见 | `timeout 3s make ARCH=native run` 输出 banner/shell/ps |
| npc-stack-align-debug | codex | completed | NPC 失败日志、`context.c`、RISC-V `kcontext()` 反汇编 | 根因定位为 8B BSP 布局与 16B `kcontext()` 对齐不一致，`RtAmThreadStart.exit` 被覆盖 | `rt_hw_stack_init` 与 `kcontext` 对齐/清零范围对比 |
| fix-riscv-stack-layout | codex | completed | `bsp/abstract-machine/src/context.c` | `kstack.end` 先按 16B 对齐，再布局 `Context` 和启动描述符 | 文件修改 |
| verify-npc-native | codex | completed | 修复后的 RT-Thread AM BSP | NPC shell、native shell 与 NPC yield-os 均正常 | 三条 `timeout ... run` 验证 |
| record | codex | completed | 本轮实现与验证 | memory 与 task-run 更新 | 本目录与 `.github/memory/*` |

## 关键产物

- `artifacts`: `Templates/rt-thread-am/bsp/abstract-machine/src/context.c`、`Templates/rt-thread-am/bsp/abstract-machine/src/interrupt.c`
- `logs_or_traces`: `make ARCH=native`；`timeout 3s make ARCH=native run`；`timeout 30s make ARCH=riscv32-npc run`；`timeout 5s make -C am-kernels/kernels/yield-os ARCH=riscv32-npc run NPC_RUN_ARGS='--no-progress -m 0'`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/abstract-machine.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md`

## 验证证据

- `make ARCH=native`: PASS，生成 `build/rtthread-native.elf`。
- `timeout 3s make ARCH=native run`: 进入 RT-Thread 5.0.1，打印 utest 初始化成功和 `Hello RISC-V!`，shell 自动执行 `help/date/version/free/ps`。
- `ps` 输出显示 `tshell` running、`sys workq` ready、`tidle0` ready、`timer` suspend、`main` close，说明首次切换、线程间切换和 tick 驱动调度均已工作。
- 运行命令以 124 退出是 `timeout` 主动结束驻留 shell，属于预期行为。
- `timeout 30s make ARCH=riscv32-npc run`: PASS 到驻留 shell；原先的 `context.c:69` 断言消失，`msh` 自动执行 `help/date/version/free/ps/pwd/ls/memtrace/memcheck/utest_list`，最终因 shell 常驻被 `timeout` 结束。
- `timeout 5s make -C am-kernels/kernels/yield-os ARCH=riscv32-npc run NPC_RUN_ARGS='--no-progress -m 0'`: 持续输出 `ABAB...`，以 `timeout` 结束，说明 NPC 基础 AM CTE/yield 切换仍可用。

## 当前阻塞点

- `blockers`: none
- `missing_dependencies`: none
- `risk_assessment`: native 与 `riscv32-npc` 的协作式 shell/yield 路径已覆盖；NPC 真正的异步 timer interrupt/`mtimecmp -> MTIP` 仍未补齐，后续若依赖抢占式 tick 需要继续实现和验证。

## 下一步建议

1. 后续若要让 RT-Thread 在 NPC 上获得真实抢占式 tick，需要补 `mtime/mtimecmp -> MTIP` 中断源、核心异步中断仲裁和对应回归。
2. 若启用 SMP 或更复杂外设中断，补充对应 RT-Thread BSP API 的签名与回归样例。

## 模板升级候选

- `repeated_dynamic_subgraph`: BSP runtime bridge: ABI 推导 -> CTE 接入 -> resident shell 运行验证。
- `should_promote_to_static_template`: false
- `reason`: 当前 RT-Thread AM BSP 是一次性适配，后续若反复处理 OS-on-AM 才需要升级模板。

## 收尾结论

- `final_result`: RT-Thread AM BSP 的上下文创建、普通切换和中断切换已落盘；后续 NPC 栈对齐断言已修复。
- `evidence_summary`: native 与 `riscv32-npc` 均能进入 RT-Thread shell，`ps` 可见多线程状态；`yield-os` on NPC 仍持续交替输出。
- `notes`: 驻留 shell 和无限 yield 样例需要用 `timeout` 结束验证命令，不能把超时退出误判为 RT-Thread 崩溃。
