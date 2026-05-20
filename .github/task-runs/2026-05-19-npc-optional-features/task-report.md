# NPC 对齐 NEMU 可选功能任务报告

## 目标

按顺序对照 NEMU 当前 RV32 可选能力，在 `riscv32-npc` 上补齐：

1. RV32M
2. Zba/Zbb/Zbc/Zbs bitmanip 子集
3. RV32C
4. cache 与 `fence.i`
5. BPU/RAS

随后先跑轻量级 cpu-test，再跑全量 cpu-tests difftest 和 benchmark。

## RTL 推导摘要

- 需求层：NPC 需要从原先 RV32I/Zicsr/trap 闭环扩展到 RV32IMC + Zba/Zbb/Zbc/Zbs，同时保持现有提交级 difftest 与单提交精确异常边界。
- 协议层：M/B 在 EX 组合计算，不改变流水握手；C 在 IF 解压并向后传 `inst_len`；BPU 只预测 fetch next PC，EX 仍计算真实 next PC 并负责 flush；cache 先收口在 Verilator DPI bus 层。
- 不变量层：每拍最多提交一条，x0 不写，`commit_next_pc_o` 表示架构提交后 PC，MMIO uncached 且继续 skip-ref，错误路径不得提交，`fence.i` 后不得取旧 ICache 行。
- 数据通路层：Decode 增加 M/B 控制位，EX 增加 `rv32m_result/rv32b_result`，IF 增加 C 解压与 BTB/BHT/RAS，pipeline regs 增加 `inst_len/pred_pc`，host bus 增加 ICache/DCache 与 flush DPI。

## 实现摘要

- `abstract-machine/scripts/riscv32-npc.mk`：`-march` 更新为 `rv32imc_zicsr_zifencei_zba_zbb_zbc_zbs`。
- `npc/single/vsrc`：
  - `define.v` 增加 M/B 控制位和编码宏。
  - `DecodeUnit.v` 识别 RV32M、Zba/Zbb/Zbc/Zbs 与 `fence.i`。
  - `NpcCore.v` 实现 RV32M、bitmanip 结果选择、`inst_len` PC 路径、`fence.i` flush、BPU update/correction。
  - `IfStage.v` 实现 RVC 解压、BTB/BHT/RAS 预测。
  - `PipelineRegs.v` 传递 `inst_len`、`pred_pc`。
  - `NpcSimTop.sv` 接入 `npc_cache_flush_all()`。
- `npc/single/csrc`：
  - 新增 `memory/cache.c` 与 `include/memory/cache.h`。
  - `dpi.c` 取指放宽到半字对齐，并接入 ICache/DCache。
  - `paddr.c` 初始化 cache。
  - `cpu-exec.cpp` 输出 cache 统计。
- `am-kernels/tests/cpu-tests/tests`：
  - 新增 `bitmanip.c`、`compressed.c`、`fence-i.c`。

## 验证结果

- `make -C npc/single lint`：PASS。
- 轻量级 cpu-test diff：
  - RV32M：`mul-longlong div` PASS。
  - B 扩展：`bit crc32 shift min3 bitmanip` PASS。
  - C 扩展：`dummy add if-else load-store bitmanip compressed` PASS。
  - cache/fence.i：`load-store compressed bitmanip crc32 fence-i` PASS。
  - BPU：`if-else recursion fib compressed crc32` PASS。
- 全量 cpu-tests diff：
  - 命令：`timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`
  - 结果：38/38 PASS。
- Benchmark：
  - CoreMark：默认 1000 iterations，`CoreMark PASS 3 Marks`，`commits=746654109`，`cycles=1632703802`，`CPI=2.187`。
  - Dhrystone：默认 500000 runs，`Dhrystone PASS 3 Marks`，`commits=230019046`，`cycles=469040116`，`CPI=2.039`。
  - MicroBench：`mainargs=test`，10/10 子项 PASS，`commits=522957`，`cycles=1112846`，`CPI=2.128`。

## 边界说明

- 当前 cache 是 Verilator host bus 层透明模型，不是可综合 RTL cache；已记录到 `known-issues.md`。
- RVC 的 `commit_inst_o` 当前输出解压后的内部 32-bit 指令；difftest 以提交后 PC/GPR 为准，功能正确。若后续需要原始指令 trace，应新增 raw inst/len 观测口。
- NEMU BPU 是统计模型，NPC BPU 是接入 IF/EX 的功能预测/校正路径；两者性能含义不能直接一一对照。
