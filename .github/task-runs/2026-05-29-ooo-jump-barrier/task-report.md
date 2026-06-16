# OoO lane0 JAL/JALR 精确屏障

## 目标

在 ALU-only OoO 实验核中补齐 lane0 `JAL/JALR` 的最小正确执行路径，使跳转指令本身经过 rename/PRF/ROB 提交，链接寄存器写回 `pc+4`，前端在提交后精确重定向。

## RTL 四阶段记录

### 1. 需求

- `JAL/JALR` 位于 fetch packet lane0 时可执行；lane1 暂不作为控制流指令执行。
- `rd` 写回必须进入 OoO 后端的 rename map、物理寄存器和 ROB，不允许只在前端合成架构态写回。
- `JALR rd==rs1` 必须使用跳转提交前的源寄存器值计算 target，不能被 link 写回覆盖。
- target 非 4B 对齐时产生精确 `EXC_INST_ADDR_MISALIGN`，并且跳转不写回 link。

### 2. 协议/状态机/不变量

- lane0 branch 仍走现有 synthetic commit 屏障；lane0 `JAL/JALR` 新增 two-phase jump barrier。
- phase A：发现 lane0 jump 后停止取指/派发，等待更老 ROB、issue queue 和 retire 输出全部排空。
- phase B：在 jump 尚未进入后端前，用已提交架构 GPR 计算并锁存 target；若 misaligned，直接精确 trap。
- phase C：将 jump 作为单 lane0 uop 派发到 OoO 后端，lane1 不派发；等待该 uop 提交并排空。
- phase D：清空 fetch FIFO/outstanding response，`next_fetch_pc` 切到锁存 target，恢复运行。
- 不变量：跳转提交前不重定向；重定向前 link 已由后端提交；lane1 控制流仍作为 unsupported 边界。

### 3. 数据通路

- `OooIntBackend` 不再直接把 ALU result 当作 writeback data，而是复用 `WBU`，按 `CTRL_WB_SEL` 选择 `ALU/IMM/PC+4`。
- `OooAluDecodeBackend` 放行 `CTRL_JAL_BIT/CTRL_JALR_BIT`，但 frontend 只允许 lane0 通过 jump barrier 进入后端。
- `OooAluFetchCore` 增加 lane0/lane1 DecodeStage 观测、pending jump 元数据、JALR target 计算、target latch 和单 lane dispatch mux。

### 4. RTL 修改计划

- 修改 `OooIntBackend.v` 的执行级 writeback 数据生成。
- 修改 `OooAluDecodeBackend.v` 的 ALU-only supported 子集边界。
- 修改 `OooAluFetchCore.v` 的 pending stop 协议，加入 `JAL/JALR` two-phase barrier。
- 更新 `tb_ooo_alu_decode_backend.sv` 与 `tb_ooo_alu_fetch_core.sv`，覆盖 `JAL` link 写回、target redirect 和 `JALR rd==rs1`。
- 更新 Icarus testbench source list，确保新增 `WBU` 依赖在 OoO 专项 testbench 下可见。

## 验证记录

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-ooo-jump-ooo-tb LOG_DIR=/tmp/npc-ooo-jump-ooo-tb/logs TESTS="tb_ooo_rename_map tb_ooo_free_list tb_ooo_rob tb_ooo_phys_reg_file tb_ooo_busy_table tb_ooo_int_issue_queue tb_ooo_dispatch_backend tb_ooo_int_backend tb_ooo_alu_decode_backend tb_ooo_alu_core_slice tb_ooo_alu_fetch_core" run`：11/11 PASS。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 lint`：PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-jump-sim-build NPC_OOO_ALU_EXPERIMENT=1 -j4`：PASS。
- raw `JALR rd==rs1` smoke：GOOD TRAP，`cycles=20`、`commits=5`、`CPI=4.000`。
- raw 4096 独立 ALU smoke：GOOD TRAP，`cycles=2055`、`commits=4096`、`CPI=0.502`。
- `make -C npc/single lint`：PASS。
- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-ooo-jump-full-tb LOG_DIR=/tmp/npc-ooo-jump-full-tb/logs run`：38/38 PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-jump-default-build -j4`：PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run`：PASS，默认 `cycles=1509/commits=838/CPI=1.801`。
- `git diff --check`（本轮 touched paths）：PASS。

## 调试结论

- 根因避免项：不能在组合函数里隐式读取 `core_debug_gprs_w` 这类外部总线而只把寄存器号作为显式参数；Icarus 可能不随外部总线变化重算，导致 `JALR` target 锁到旧值。本轮把 flattened GPR 总线作为 `arch_gpr()` 的显式参数后，`JALR rd==rs1` 通过。
