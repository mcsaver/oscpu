# npc E2E Contract

本文件只描述显式选择的 NPC/NPC RV64 profile。局部 RTL、仿真或工具任务直接按 acceptance criteria 运行
focused build/test；不因路径自动进入 full CPU-test、Linux、strict guard、systemd 或 PPA profile。

- **范围**: `npc/sim`、`npc/single`、`npc/soc`、`npc/rv64`。
- **上游**: am-kernels 镜像、NEMU reference、ysyxSoC CPU ABI。
- **下游**: DiffTest、SoC、STA/PPA、RV64 Linux。
- **L0 gate**: `npc-sim-contract` 和 `npc-sim-status`。
- **L1 gate**: `npc-cpu-tests-full` 通过 `riscv32-npc` 全量 `am-kernels/tests/cpu-tests` 验证 target 路径；后端跟随 `npc/sim` 当前配置，不在 e2e 中偷偷切换。
- **RV64 Linux gate**: `rv64-linux` profile 中的 NPC rootfs gate 至少覆盖 ttyS0 console、virtio-blk、EXT4/VFS root mount、`/lib/systemd/systemd` handoff，以及 systemd PID1/Ubuntu 22.04 banner；`npc-rv64-systemd-guest-check-contract` 节点静态守住 `make check-npc-systemd-guest`、`NPC_UART_RX_FILE`、`NPC_UART_RX_WAIT`、`NPC_GUEST_EXPECT`、绝对路径归一化、`NPC_SYSTEMD_PROGRESS` 透传，以及 `NPC_USER_PROGRESS_INTERVAL`/`NPC_USER_ECALL_TRACE`/`NPC_USER_ECALL_TRACE_PRIV`/`NPC_USER_ECALL_MIN_COMMIT`、trap-layer `trap_hit=` 观测开关。完整 NEMU 等价 gate 仍需继续让真实 NPC 长跑到 root prompt、释放 guest 检查脚本并命中完整 Ubuntu runtime marker。
- **Checker-only guard routing**: strict guard 对 systemd guest checker、strict
  dmesg oracle、transaction parser、对应三份单测和冻结 incomplete-console
  fixture 精确要求 `rv64-systemd-contract`；其它 Linux/kernel/rootfs/boot
  输入仍要求 `rv64-linux`。该分流不改变 checker sensitivity 或 terminal
  exactly-once 规则，也不把静态/定向合同外推为完整 rootfs PASS。
- **证据**: backend status、全量 cpu-tests PASS 汇总、NPC log、cycles/commits/CPI；若当前后端启用 DiffTest，则同时记录 DiffTest 结果。
- **升级路线**: 分别升级 `npc-single`、`npc-soc`、`npc-rv64` 的 smoke/regression profile。
