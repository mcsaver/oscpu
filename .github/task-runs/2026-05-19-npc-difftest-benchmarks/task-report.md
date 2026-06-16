# NPC difftest 与 benchmark 回归

## 任务
- 为 `riscv32-npc` 接入 difftest，并用 difftest 跑通 cpu-tests 与 benchmark。
- 保持已有 NPC 流水线和 AM/NPC 运行入口不被破坏。

## RTL 推导记录

### 需求
- difftest 需要比较每条已提交指令后的架构状态。
- 当前参考端 `nemu/tools/spike-diff` 暴露的 RV32 context 为 32 个 GPR 加 PC，因此 NPC 至少要提供提交后 PC 与提交后 GPR。

### 协议
- `commit_valid_o` 是唯一提交握手，异常、`ecall`、`ebreak` 和 fatal trap 不提交。
- `commit_pc_o/commit_inst_o/commit_next_pc_o/commit_rd_*` 只在 `commit_valid_o` 同周期有意义。
- `debug_gprs_o` 作为寄存器堆快照，host 侧必须用 `commit_rd_*` 对当前提交写回做一次覆盖，形成提交后状态。

### 状态机
- IF/ID、ID/EX、EX/MEM、MEM/WB 仍按既有 valid/pending 推进。
- EX 阶段生成提交后 PC，EX/MEM 和 MEM/WB 只携带该字段，不改变 stall/flush 行为。

### 不变量
- 单拍最多提交一条指令。
- `commit_next_pc_o` 对普通指令为 `pc+4`，对 taken branch/JAL/JALR 为跳转目标，对 `mret` 为 `mepc`。
- load/store 在等待 LSU 响应期间保持 EX 计算出的 `next_pc` 不变。
- MMIO 指令不让 Spike 真实访问设备地址，而是 skip reference 并同步 DUT 状态。

### 数据通路
- 新增 `ex_next_pc_w`、`ex_mem_next_pc_q`、`mem_wb_next_pc_q`。
- `NpcSimTop.sv` 透传 `commit_next_pc_o` 给 Verilator 顶层，`cpu-exec.cpp` 在提交点传给 `npc_difftest_step()`。

## 改动摘要
- `npc/single/vsrc/NpcCore.v`、`NpcSimTop.sv`：新增提交后 PC 观测口。
- `npc/single/csrc/cpu/difftest.cpp`、`include/cpu/difftest.h`：动态加载 Spike REF，初始化内存/寄存器，逐条执行并比较 GPR/PC。
- `npc/single/csrc/memory/paddr.c`：记录已加载镜像大小；成功 MMIO load/store 后标记 reference skip。
- `npc/single/csrc/monitor/monitor.c`、`utils.c`、`utils.h`：新增 `--diff`、`--diff-port` 配置。
- `npc/single/Makefile`：注入默认 Spike REF 路径，链接 `-ldl`，新增 `difftest-ref` 目标。

## 验证
- `make -C nemu/tools/spike-diff GUEST_ISA=riscv32 SHARE=1 ENGINE=interpreter`: PASS。
- `make -C npc/single lint`: PASS。
- `make -C npc/single`: PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--diff=default -m 0'`: PASS。
- `timeout 240s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`: 35/35 PASS。
- `timeout 240s make -C am-kernels/benchmarks/dhrystone ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`Dhrystone PASS 4 Marks`，`commits=230018912`。
- `timeout 900s make -C am-kernels/benchmarks/coremark ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`: PASS，`CoreMark PASS 4 Marks`，`commits=746654025`。
- `timeout 240s make -C am-kernels/benchmarks/microbench ARCH=riscv32-npc run mainargs=test CROSS_COMPILE=/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf- NPC_RUN_ARGS='--diff=default -m 0'`: PASS，10/10 microbench 子项通过。
- `git diff --check -- <本轮相关文件>`: PASS。

## 注意事项
- 目前 NPC difftest 只比较 GPR/PC，不比较 CSR；CSR/trap 可见状态需要后续扩展 reference context 或新增专门事件。
- MicroBench 默认 `ref` 负载会很长；本轮用于回归的是 `mainargs=test`。
- 当前系统缺 `riscv64-linux-gnu-g++`，MicroBench 需要覆盖到 `riscv64-unknown-elf-` 工具链。
