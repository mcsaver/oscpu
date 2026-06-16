# RV64 SBI Timer Mini Boot

## 目标

继续推进 `npc/rv64` Linux boot 前置能力，补齐 OpenSBI/Linux early timer 依赖的 CLINT `mtime/mtimecmp` RV64 aligned lane 访问，并新增一个小型 SBI timer 启动测试覆盖复杂控制链路。

## 改动

- `npc/rv64/vsrc/bus/AxiLiteClint.v`
  - `mtimecmp@0x4000` 与 `mtime@0xbff8` 在 `DATA_W=64` 时按完整 64-bit aligned word 读写。
  - 支持 CPU `sw/lw mtimecmp+4` 经 LSU 对齐后以 `WSTRB[7:4]`/`WDATA[63:32]` 表达的高半访问。
  - 保留 32-bit 外设视角的精确 `+4` 地址读写兼容。
- `npc/rv64/testbench/tests/tb_axi_lite_clint.sv`
  - 新增 64-bit CLINT 实例，覆盖 aligned full write、高 lane only write、高半 read、`MTIP` compare set/clear。
- `am-kernels/tests/cpu-tests/tests/sbi-timer.c`
  - M-mode handoff 到 S-mode。
  - S-mode 用 SBI TIME extension 风格 `ecall` 进入 M-mode handler。
  - M handler 写 CLINT `mtimecmp+4/+0` 设置 timer pending 后 `mret`。
  - S-mode 在 `wfi` 处接收 delegated `STIP`，handler 清 timer 并 `sret`。

## 验证

- `make -C npc/rv64/testbench TESTS="tb_axi_lite_clint" RESULT_DIR=/tmp/rv64-clint-lane run`
  - PASS 1/1
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=sbi-timer run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS
  - `cycles=645 / commits=162 / CPI=3.981`
- `make -C npc/rv64/testbench TESTS="tb_axi_lite_clint tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_mem_axi_bridge tb_ooo_int_backend tb_axi_lite_plic tb_uart tb_axi_lite_to_uart" RESULT_DIR=/tmp/rv64-sbi-timer-focused run`
  - PASS 8/8
- `make -C npc/sim BACKEND=rv64 lint`
  - PASS
- `make -C npc/sim BACKEND=rv64 -j4`
  - PASS
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=add run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`
  - PASS
  - `cycles=755 / commits=839 / CPI=0.900`

## 限制

本轮是 CLINT/SBI timer mini boot，不等于真实 Linux 已启动。后续仍需 OpenSBI/kernel 镜像加载、DTB/hart 参数、SBI console/IPI/reset/HSM、virtio/blk、多源 PLIC 与真实平台设备栈。
