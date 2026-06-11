# RV64 SBI IPI Reset HSM Mini Boot

## 目标

继续补真实 Linux/OpenSBI 早期服务面，新增一个小型 SBI smoke，覆盖单 hart IPI、S software interrupt delivery、HSM hart status 和 system reset call ABI。

## 改动

- `am-kernels/tests/cpu-tests/tests/sbi-ipi-reset-hsm.c`
  - M-mode firmware handler 识别 SBI IPI (`EID=0x735049`) 的 `send_ipi`。
  - S-mode 传入 `hart_mask=1`、`hart_mask_base=0`，M handler 设置 `sip.SSIP`。
  - S-mode 打开 `sie.SSIE` 与 `sstatus.SIE`，在 `wfi` 处进入 S software interrupt handler。
  - S handler 检查并记录 `scause/sepc/sstatus`，清 `sip.SSIP` 后 `sret`。
  - 同测覆盖 HSM `hart_get_status(hart0)=STARTED`。
  - 同测覆盖 system reset `shutdown/no_reason` 的 SBI call 参数记录。

## 验证

- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=sbi-ipi-reset-hsm run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS
  - `cycles=979 / commits=279 / CPI=3.509`
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL="linux-handoff sbi-base-console counteren-time sbi-timer sbi-ipi-reset-hsm" run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS 5/5
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 run NPC_RUN_ARGS="--no-progress --max-cycles 5000000"`
  - PASS 48/48

## 限制

本轮仍是 AM 内 mini firmware，不是完整 OpenSBI。`system_reset` 在测试里作为可返回 ABI smoke 处理；真实 OpenSBI 的 reset 成功路径不应返回。当前也没有覆盖多 hart IPI/HSM 状态迁移、真实 OpenSBI extension 分发表、真实 DTB、virtio/blk 或完整 Linux 内核启动。
