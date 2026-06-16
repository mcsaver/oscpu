# RV64 SBI Base/Console Mini Boot

## 目标

继续推进 `npc/rv64` Linux boot 前置能力，在已有 S-mode trap、timer、counter CSR 基础上，补一个更接近 OpenSBI early probe 的 mini boot：S-mode 通过 SBI base extension 查询固件信息和扩展可用性，并通过 legacy console putchar 走真实 UART MMIO 输出。

## 改动

- `am-kernels/tests/cpu-tests/tests/sbi-base-console.c`
  - M-mode 安装 firmware trap handler 后 handoff 到 S-mode payload。
  - S-mode 使用 SBI base extension (`a7=0x10`) 验证 `get_spec_version/get_impl_id/get_impl_version/probe_extension/get_mvendorid/get_marchid`。
  - 验证 unknown EID 返回 `SBI_ERR_NOTSUPP`。
  - 使用 legacy console putchar (`a7=0x1`) 输出 `OK\n`。
  - M handler 记录 `mcause/mepc/eid/fid`、调用次数和 console chars，并写 UART THR `0x10000000`，让仿真终端能看到 guest `OK`。

## 验证

- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=sbi-base-console run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS
  - 终端出现 guest `OK`
  - `cycles=1524 / commits=582 / CPI=2.619`
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL="sbi-base-console counteren-time sbi-timer" run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS 3/3
- `make -C npc/sim BACKEND=rv64 lint`
  - PASS
- `make -C npc/sim BACKEND=rv64 -j4`
  - PASS
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=add run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`
  - PASS
  - `cycles=755 / commits=839 / CPI=0.900`

## 限制

本轮只新增 cpu-test 内的 mini firmware 测试，不等于真实 OpenSBI 或 Linux kernel 已启动。剩余缺口包括标准 OpenSBI extension 分发表、IPI、reset/HSM、hart state、DTB/hart 参数传入、virtio/blk、多源 PLIC 与真实 OpenSBI/kernel 镜像加载。
