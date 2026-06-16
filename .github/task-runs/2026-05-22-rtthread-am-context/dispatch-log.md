# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-rtthread-am-context`
- `task_slug`: `rtthread-am-context`
- `graph_template`: `am-device-loop`
- `log_policy`: `append-only`

---

### [2026-05-22 15:20] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求完成 RT-Thread 上下文创建与切换。
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、RT-Thread AM BSP 源码。
- `action`: 读取项目规则与 AM 模块状态，确认需要从 AM CTE 与 RT-Thread BSP ABI 两端收敛。
- `outputs`: 明确 `context.c` 和 `interrupt.c` 是本轮核心修改点。
- `evidence`: 当前 `context.c` 的 switch/stack init 仍为 assert 占位，`interrupt.c` 签名不匹配 RT-Thread 预期。

### [2026-05-22 15:35] `rtthread-abi-derive` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `recall`
- `inputs`: RT-Thread `rt_hw_stack_init`、`rt_hw_context_switch*` 约定，AM `kcontext/yield/cte_init`。
- `action`: 将 RT-Thread 线程对象中的 `sp` 映射为 AM `Context *`；普通切换用 `yield()` 进入 CTE，中断切换延后到事件处理尾部。
- `outputs`: 上下文桥接方案。
- `evidence`: `rt_am_request_switch()`、`rt_am_dispatch_context()` 实现。

### [2026-05-22 15:50] `implement-context` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `rtthread-abi-derive`
- `inputs`: `bsp/abstract-machine/src/context.c`
- `action`: 实现线程启动描述符、trampoline、`rt_hw_stack_init()`、普通/中断上下文切换和 AM event handler 中的 tick 驱动。
- `outputs`: `context.c` 修改。
- `evidence`: 文件 diff；中文注释说明 RT-Thread `sp` 与 AM `Context *` 的桥接。

### [2026-05-22 15:58] `implement-interrupt` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `rtthread-abi-derive`
- `inputs`: `bsp/abstract-machine/src/interrupt.c`
- `action`: 修正 `rt_hw_interrupt_disable/enable` 签名，使用 AM `ienabled()/iset()` 保存和恢复中断开关。
- `outputs`: `interrupt.c` 修改。
- `evidence`: 文件 diff。

### [2026-05-22 16:05] `verify-build` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `implement-context`、`implement-interrupt`
- `inputs`: RT-Thread AM BSP。
- `action`: 执行 native 构建。
- `outputs`: `build/rtthread-native.elf`。
- `evidence`: `make ARCH=native` PASS。

### [2026-05-22 16:10] `shell-runtime-verify` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `verify-build`
- `inputs`: native RT-Thread 镜像。
- `action`: 使用 `timeout 3s make ARCH=native run` 运行驻留 shell。
- `outputs`: RT-Thread banner、shell 命令输出和线程状态。
- `evidence`: `ps` 显示 `tshell` running、`sys workq/tidle0` ready、`timer` suspend、`main` close；timeout 124 为主动结束。

### [2026-05-22 16:20] `record` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `shell-runtime-verify`
- `inputs`: 实现内容与验证证据。
- `action`: 更新 project status、AM module memory 和本 task-run。
- `outputs`: 记录落盘。
- `evidence`: `.github/memory/project-status.md`、`.github/memory/modules/abstract-machine.md`、本目录。

### [2026-05-22 16:45] `npc-stack-align-debug` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `shell-runtime-verify`
- `trigger`: 用户在 `riscv32-npc` 上运行 RT-Thread 时命中 `context.c:69` 断言，并要求修复。
- `inputs`: NPC 失败日志、`Templates/rt-thread-am/bsp/abstract-machine/src/context.c`、RISC-V AM `kcontext()` 行为与反汇编。
- `action`: 复现 `timeout 30s make ARCH=riscv32-npc run`，对比 `rt_hw_stack_init()` 的 8B 栈布局与 `kcontext()` 内部 16B 对齐/清零范围。
- `outputs`: 根因定位为 `RtAmThreadStart.exit` 被 `Context` 清零覆盖，trampoline 跳过 `texit` 后触发第 69 行断言。
- `evidence`: `rt_am_thread_trampoline` 在 `exit == NULL` 时直接断言；`kcontext` 会把 `kstack.end` 向下对齐到 16B 后放置并清零 `Context`。

### [2026-05-22 17:05] `fix-riscv-stack-layout` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `npc-stack-align-debug`
- `inputs`: `context.c`
- `action`: 修改 `rt_hw_stack_init()`，新增 16B AM context stack 对齐常量，使 BSP 先按 RISC-V `kcontext()` 的栈顶对齐规则计算 `kstack.end`，再布局 `Context` 与启动描述符。
- `outputs`: `Templates/rt-thread-am/bsp/abstract-machine/src/context.c` 修改。
- `evidence`: `rt_am_align_down(addr, align)`；`stack_end` 使用 `RT_AM_CONTEXT_STACK_ALIGN=16U`。

### [2026-05-22 17:20] `verify-npc-native` - `completed`

- `owner_agent`: `codex`
- `depends_on`: `fix-riscv-stack-layout`
- `inputs`: 修复后的 RT-Thread AM BSP。
- `action`: 复跑 NPC RT-Thread、native RT-Thread 和 NPC `yield-os`。
- `outputs`: NPC 与 native 均进入 shell，`yield-os` 持续交替输出。
- `evidence`: `timeout 30s make ARCH=riscv32-npc run` 执行 `help/date/version/free/ps/memtrace/utest_list` 后由 timeout 结束；`timeout 3s make ARCH=native run` 正常进入 shell；`timeout 5s make -C am-kernels/kernels/yield-os ARCH=riscv32-npc run NPC_RUN_ARGS='--no-progress -m 0'` 输出 `ABAB...`。
