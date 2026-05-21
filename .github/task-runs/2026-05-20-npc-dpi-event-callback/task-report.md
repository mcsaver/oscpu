# 2026-05-20 NPC DPI 事件回调减少顶层 IO

## 目标

- 按用户要求，将 `NpcSimTop.sv` 的提交、trap、exit 观测从 Verilator 顶层端口轮询改成 DPI-C 事件回调。
- 先避免 difftest 关闭时仍读取 `debug_gprs_o` 宽总线。
- 用 host 侧影子 GPR 维护寄存器状态，去掉 `NpcSimTop` 的 `debug_gprs_o` 顶层输出。
- 保持 `NpcCore` 纯 RTL、可综合接口不引入 DPI-C。

## RTL 推导摘要

### 阶段 1：需求

- 功能目标：`NpcSimTop` 作为仿真壳，在提交、fatal trap、ebreak exit 发生的周期调用 DPI-C 事件函数，把事件 payload 推给 C++ 执行器。
- 端口边界：`NpcCore` 端口保持不变；`NpcSimTop` 对 host 只保留 `clk/rst/debug_pc/debug_state` 小宽度顶层端口，commit/trap/exit/debug_gprs 不再作为顶层 IO。
- 性能约束：减少 Verilator 顶层宽信号轮询，尤其是不在 difftest 关闭时读取 32 个 GPR；DPI 事件只在 commit/trap/exit 有效时调用。
- 上下游边界：SV 仿真壳负责从 `u_core` 层次信号形成事件；C++ host 负责保存事件、影子 GPR、difftest 和统计。
- 不在范围：不改 `NpcCore` 内部提交语义、流水线状态机、IFU/LSU DPI 总线协议、RTL cache 行为。

### 阶段 2a：协议规则

- commit event：当 `u_core.mem_wb_load_w` 为 1 且核心未 halt/fatal 时调用一次，payload 对齐即将装入 MEM/WB 的提交信息。
- exit event：当 `u_core.ebreak_fire_w` 为 1 时调用一次，payload 包含退出码、退出 PC 和退出类型。
- trap event：仅 fatal trap 调用；普通 `mtvec` trap 不通知 host 停机。
- host 每个仿真周期开始先清空 pending event，`eval()` 过程中由 DPI 回调置位；周期结束后 C++ 消费本周期事件。
- difftest 关闭时不读取 GPR；difftest 开启时使用 commit event 维护的影子 GPR 构造 DUT 上下文。

### 阶段 2b：状态机

- `NpcSimTop` 不新增硬件状态机，仅在现有 `posedge clk` 仿真进程内增加事件判断。
- Host 侧事件状态：
  - cycle start：`commit/trap/exit.valid = false`
  - DPI callback：对应 event.valid 置 1 并锁存 payload
  - cycle consume：执行统计、trace、difftest、退出处理
  - reset：清空 event 与影子 GPR

### 阶段 2c：不变量

- `NpcCore` 不 import DPI-C，仍是纯 RTL 模块。
- 每个仿真周期最多消费一个 commit event；store/branch/普通 ALU/load 均通过同一 commit event。
- fatal trap 与 ebreak exit 不应生成同一条 commit event。
- x0 在 host 影子 GPR 中始终为 0；rd 为 x0 或无写回时不得修改影子 GPR。
- difftest 的 DUT GPR 必须来自最近一次 commit 后的影子 GPR，与 `rd_en/rd_data` payload 一致。

### 阶段 2d：数据通路约束

- commit payload 从 `u_core.ex_mem_*` 与 `u_core.mem_wb_load_wb_data_w` 取数，对齐 MEM/WB load 时刻，避免读取下一拍顶层 `commit_*` IO。
- exit payload 从 `u_core.id_ex_pc_q` 与 `u_core.ex_a0_forward_w` 取数，对齐 ebreak fire 时刻。
- fatal trap payload 从 `mem_fault_w/ex_exception_fatal_w` 两条路径选择，对齐 `NpcCore` 写 fatal trap 寄存器的来源。
- host 影子 GPR 是唯一的 C++ 寄存器观测源；`debug_pc/debug_state` 保留为 monitor/progress 的小宽度即时状态。

## 实施结果

- `npc/single/vsrc/NpcSimTop.sv`
  - 新增 `npc_commit_event/npc_exit_event/npc_trap_event` DPI-C function import。
  - `NpcSimTop` 顶层端口移除 commit/trap/exit/halted/debug_gprs，仅保留 `debug_pc_o/debug_state_o` 供 monitor/progress 使用。
  - `NpcCore` 仍保持原端口和纯 RTL 属性，仿真壳对不再导出的观测端口使用空连接。
  - 事件触发全部来自 `u_core.*` 层次化引用：commit 对齐 `mem_wb_load_w`，exit 对齐 `ebreak_fire_w`，fatal trap 对齐 `mem_fault_w/ex_exception_fatal_w`。

- `npc/single/csrc/cpu/cpu-exec.cpp`
  - 新增本周期 `CommitEvent/ExitEvent/TrapEvent` 和 `g_shadow_gpr[32]`。
  - DPI callback 锁存事件 payload，并在 commit 写回时维护 shadow GPR，x0 强制保持 0。
  - 执行环路从顶层端口轮询改为消费 event；`npc_difftest_step()` 只在 `npc_difftest_enabled()` 为真时调用。
  - `npc_cpu_read_reg()` / `npc_cpu_reg_display()` 改为读取 shadow GPR，不再依赖 `debug_gprs_o` 顶层宽总线。

## 验证证据

- `make -C npc/single lint`：PASS。
- `make -C npc/single`：PASS。
- `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=add`：PASS，GOOD TRAP，838 commits。
- `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=load-store`：PASS，GOOD TRAP，370 commits。
- `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=add NPC_RUN_ARGS='--diff=default'`：PASS，difftest enabled，GOOD TRAP。
- `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=load-store NPC_RUN_ARGS='--diff=default'`：PASS，difftest enabled，GOOD TRAP。
- `make -C npc/single/testbench run`：PASS 21/21，结果保留在 `npc/single/perf/results/20260520-134000/module-testbench`。
- 生成后的 `VNpcSimTop.h` 只暴露 `debug_pc_o/debug_state_o`，不再暴露 `commit_* / trap_* / exit_* / debug_gprs_o` 顶层 IO。
