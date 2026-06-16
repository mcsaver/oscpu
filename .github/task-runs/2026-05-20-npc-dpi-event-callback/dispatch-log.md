# 2026-05-20 NPC DPI 事件回调 dispatch log

## 2026-05-20 13:36:23 +0800

- 用户要求“按照这个顺序来修改”：先避免 difftest 关闭时读取 GPR 宽总线，再引入 DPI-C 事件回调，最后用 `NpcSimTop` 层次化引用触发事件并保持 `NpcCore` 纯 RTL。
- 已复核 `.github/AGENTS.md`、Copilot 指令、项目状态、known issues、NPC 模块记忆与 RTL 四段式流程。
- 当前根因：`cpu-exec.cpp` 每条 commit 都通过 `debug_gprs_o` 读取 32 个 GPR，即使 difftest 关闭也会触碰 Verilator 顶层 1024-bit IO；同时 commit/trap/exit 也依赖顶层端口轮询。
- 修改策略：在 `NpcSimTop.sv` 内部用 `u_core.*` 层次化信号生成 `npc_commit_event/npc_exit_event/npc_trap_event` DPI-C 回调；C++ 侧保存本周期事件和 shadow GPR，执行环路只消费小结构体。

## 2026-05-20 13:40:58 +0800

- 已完成 `NpcSimTop.sv` 修改：顶层只保留 `debug_pc_o/debug_state_o`，`NpcCore` 的 commit/trap/exit/debug_gprs 输出保持空连接，仿真壳用层次化引用触发 DPI-C event。
- 已完成 `cpu-exec.cpp` 修改：新增 commit/exit/trap event 结构与 `g_shadow_gpr[32]`，执行环路改为消费 event；`npc_difftest_step()` 只在 `npc_difftest_enabled()` 为真时调用。
- 验证通过：
  - `make -C npc/single lint`
  - `make -C npc/single`
  - `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=add`
  - `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=load-store`
  - `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=add NPC_RUN_ARGS='--diff=default'`
  - `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=load-store NPC_RUN_ARGS='--diff=default'`
  - `make -C npc/single/testbench run`，结果目录 `npc/single/perf/results/20260520-134000/module-testbench`，21/21 PASS。
