# RV64 Counteren/Time CSR Mini Boot

## 目标

继续推进 `npc/rv64` Linux boot 前置能力，补齐真实内核/SBI early path 常见的 counter CSR：`cycle/time/instret`、`mcounteren/scounteren`、`mcountinhibit.IR`，并用 S-mode mini boot 验证 `rdtime` 未授权 trap 与授权读取。

## 改动

- `npc/rv64/vsrc/include/define.v`
  - 新增 `CSR_TIME/INSTRET`、`CSR_MINSTRET`、`CSR_MCOUNTEREN/SCOUNTEREN`、`CSR_*H` 和 counter enable/inhibit bit。
- `npc/rv64/vsrc/core/CsrFile.v`
  - 新增 counter CSR known/writable 表。
  - S-mode 读 `cycle/time/instret` 受 `mcounteren.CY/TM/IR` 控制；U-mode 还受 `scounteren` 控制。
  - 新增 `minstret`，按 retire count 累加；`mcountinhibit.CY/IR` 分别抑制 `mcycle/minstret`。
  - `time` 由外部 `time_i` 输入提供。
- `npc/rv64/vsrc/{sim/NpcSimTop.sv,core/NpcCoreTop.v,ooo/OooAluFetchCore.v}`
  - 将 CLINT `mtime` 接入 CSRFile 的 `time_i`。
  - 将 OoO retire count 接入 CSRFile 的 `instret_inc_i`。
- `am-kernels/tests/cpu-tests/tests/counteren-time.c`
  - M-mode 清 `mcounteren` 并 handoff 到 S-mode。
  - S-mode 未授权 `rdtime` 触发 illegal instruction trap。
  - M handler 打开 `mcounteren.CY/TM/IR` 后返回。
  - S-mode 写/读 `scounteren`，并验证 `time/cycle/instret` 递增。

## 验证

- `make -C npc/sim BACKEND=rv64 lint`
  - PASS
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=counteren-time run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS
  - `cycles=416 / commits=82 / CPI=5.073`
- `make -C npc/rv64/testbench TESTS="tb_ooo_priv_system tb_ooo_sv39_boot tb_axi_lite_clint tb_ooo_mem_axi_bridge tb_ooo_int_backend" RESULT_DIR=/tmp/rv64-counteren-focused run`
  - PASS 5/5
- `make -C npc/sim BACKEND=rv64 -j4`
  - PASS
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=add run NPC_RUN_ARGS="--no-progress --max-cycles 2000000"`
  - PASS
  - `cycles=755 / commits=839 / CPI=0.900`
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL="counteren-time sbi-timer" run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS 2/2
- `git diff --check`
  - PASS

## 限制

本轮补齐的是 counter/time CSR 与权限门控，不等于完整 OpenSBI。后续仍需 SBI base/console/IPI/reset/HSM、DTB/hart 参数、virtio/blk、多源 PLIC 与真实 OpenSBI/kernel 镜像加载。
