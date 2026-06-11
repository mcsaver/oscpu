# RV64 ECALL Exit

## 目标

在 `npc/rv64` 的 OoO core 中补齐非特权 `ECALL` 指令的仿真实验壳退出语义，避免它被归入 unsupported illegal trap。

## 改动

- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
  - 新增 `ECALL` raw 识别，并与既有 `EBREAK` 合并为 `dispatch0_exit_w/head*_exit_raw_w`。
  - 新增 `exit_is_ecall_q/exit_is_ebreak_q` 与 pending exit cause，drain 完成后按真实退出原因驱动 `exit_is_ecall_o/exit_is_ebreak_o`。
  - lane0 `ECALL/EBREAK` 不进入 OoO 后端；lane1 `ECALL/EBREAK` 继续作为半包屏障，先派发 lane0，再保存 lane1 退出原因并等待 ROB/IQ/retire drain。
- `npc/rv64/testbench/tests/tb_ooo_alu_fetch_core.sv`
  - 增加 `MODE_ECALL` 覆盖，保留 `MRET` 作为真正 unsupported SYSTEM 的非法路径样例。

## 验证

- `make -C npc/sim BACKEND=rv64 lint`：PASS。
- `make -C npc/sim BACKEND=rv64 -j4`：PASS。
- 手写最小镜像 `addi a0,zero,0; ecall`：
  - 命令：`npc/rv64/build/NpcSimTop --batch --no-diff --image=/tmp/rv64_ecall.bin --max=200 --no-progress`
  - 结果：`exit via ecall, code=0`，`HIT GOOD TRAP`。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`：40/40 PASS。

## 备注

`npc/rv64/testbench` 的 `tb_ooo_alu_fetch_core` 当前仍继承 RV32 focused 期望，直接用于 RV64 会在既有 JALR/访存断言上失败 9 项。对照实验用未改 ECALL 的 `npc/single/vsrc/ooo/OooAluFetchCore.v` 替换 rv64 fetch core 后，这 9 项同样失败，并额外出现 ECALL 断言失败；当前 rv64 core 下 ECALL 断言不失败。因此本轮使用 lint/build、最小 ECALL 镜像和 AM cpu-tests 全量作为验收证据。
