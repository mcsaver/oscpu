# RV64 OoO 1M Cycle Window Counters

## 背景

用户希望知道 RV64 OoO core 每 100 万个 cycle 中，有多少 cycle 处于取指、访存、等待 AXI、处理 hazard、分支 flush、异常处理，并要求计数器放在 bypass/层次化访问路径上，尽量不影响 core 原生性能。

## 实现

- 在 `npc/rv64/vsrc/sim/NpcSimTop.sv` 扩展既有 `npc_ooo_cycle_event()`，继续只读层次化观察 `u_core.u_ooo_core`、`u_ooo_fetch_bridge`、`u_ooo_mem_bridge` 和顶层 IFU/LSU AXI 信号。
- 新增 6 个可重叠周期桶：
  - `fetch_busy`: fetch request/outstanding/fetch bridge 非 idle。
  - `mem_busy`: pending mem、mem bridge 非 idle 或 mem request fire。
  - `axi_wait`: IFU/LSU AXI 通道 valid-ready/ready-valid 等待。
  - `hazard_busy`: dispatch ready/unsupported、branch-spec dispatch block、commit1 synthetic-ret block。
  - `branch_flush`: direct frontend flush、branch/jump redirect/resolve 类 flush。
  - `exception_busy`: pending arch trap、trap valid/flush、ecall/irq/trap valid。
- 在 `npc/rv64/csrc/cpu/cpu-exec.cpp` 增加总计和窗口聚合。默认窗口为 `1,000,000` OoO cycle，输出 `[ooo_window] window ...`；`NPC_OOO_WINDOW=0` 可关闭，`NPC_OOO_WINDOW_CYCLES=N` 可调整窗口。最终统计也输出 `cycle buckets (overlap)`，最后不足一窗输出 `partial`。

## 验证

- `git diff --check -- npc/rv64/vsrc/sim/NpcSimTop.sv npc/rv64/csrc/cpu/cpu-exec.cpp` PASS。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j1` PASS。
- `make -C npc/rv64/testbench run TESTS="tb_ooo_fetch_trap_gate tb_ooo_priv_system"` PASS。
- `printf "\x73\x00\x10\x00" > /tmp/npc_ebreak.bin && NPC_OOO_WINDOW_CYCLES=2 ./npc/rv64/build/NpcSimTop -b -i /tmp/npc_ebreak.bin --max=200` 输出 3 个 `ooo_window window`，并在最终统计输出 `cycle buckets (overlap)`。

## 边界

这些桶不是互斥分摊，同一 cycle 可以同时计入访存与 AXI wait，或 flush 与异常。当前实现没有给 core 增加可综合状态寄存器或新 public ABI，属于仿真统计旁路；若后续要上硬件性能 CSR，需要另行设计采样寄存器、清零/读出协议和综合约束。
