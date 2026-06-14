# Task Report

## 基本信息

- `task_id`: 2026-06-12-rv64-npc-clint-mtime-divisor
- `task_slug`: rv64-npc-clint-mtime-divisor
- `scope`: NPC RV64 CLINT mtime divider、Ubuntu rootfs/systemd smoke contract、rv64-linux e2e
- `status`: partial-progress
- `updated_at`: 2026-06-12

## 任务目标

- 继续推进 `npc/rv64` RTL，使 NPC 向 NEMU 的 Ubuntu 22.04 systemd/rootfs 能力收敛。
- 本轮聚焦 3.0B systemd pathtrace 暴露出的 `/dev/ttyS0`/getty/sysusers deadline 问题，避免继续盲目加 cycles。
- 把 RTL 修复、e2e contract 和 DB-backed memory 合到一条可复核证据链。

## 关键结论

- 旧配置下 `AxiLiteClint` 的 `mtime` 每 core cycle 增 1，而 Linux DTB/OpenSBI 声明 `timebase-frequency = 10000000`。在当前 RTL CPI>2 时，这等价于把 core 建模为 10MHz，systemd/udev/getty 的 guest wall-clock deadline 相对 NEMU 过早流逝。
- 3.0B pathtrace 旧长跑 `Linux/env/logs/codex-npc-systemd-guest-pathtrace-3000m` 已经出现 `Timed out waiting for device /dev/ttyS0`、`Dependency failed for Serial Getty on ttyS0`、`Failed to start Create System Users`。这说明继续加 cycles 已不能得到干净 Ubuntu gate，必须修正时间模型或服务等待路径。
- 本轮新增 CLINT `MTIME_DIVISOR`，并在 `NpcTop` 中设置 `CLINT_MTIME_DIVISOR = 32'd10`。Linux 仍看到 10MHz CLINT timebase，但 RTL 以 100MHz core / 10MHz CLINT 的关系推进 guest 时间。

## 修改内容

- `npc/rv64/vsrc/bus/AxiLiteClint.v`
  - 新增参数 `MTIME_DIVISOR` 和安全化 `MTIME_DIVISOR_SAFE`。
  - 新增 `mtime_div_q`，只有分频 tick 到达时才累加 `mtime_q`。
  - 保持既有 `mtime` MMIO 写入优先级，写寄存器仍能覆盖自增路径。
- `npc/rv64/vsrc/core/NpcTop.v`
  - 新增 `CLINT_MTIME_DIVISOR = 32'd10`，并传给 RV64 CLINT。
- `npc/rv64/testbench/tests/tb_axi_lite_clint.sv`
  - 新增 `MTIME_DIVISOR(4)` 的 `div_dut`，覆盖 reset 后保持、分频前保持、分频 tick 后递增。
- `Linux/scripts/check-npc-systemd-guest.sh`
  - 将 `/dev/ttyS0` device timeout、serial-getty dependency failure、Create System Users failure 纳入 console hard fail。
- `scripts/e2e/modules/npc.sh`
  - systemd contract 静态守住 `AxiLiteClint.v`、`NpcTop.v`、`MTIME_DIVISOR` 和 `CLINT_MTIME_DIVISOR = 32'd10`。
  - rootfs mount smoke 的边界收紧为 kernel cmdline、ttyS0、virtio-blk、EXT4/VFS root、systemd 249、Ubuntu 22.04 banner 和 hostname；不再把更深的 `Initializing machine ID from random generator` 当作该 smoke 的硬 marker。
- `scripts/e2e/modules/toolchain.sh`
  - `JAVA_HOME java` 检查支持 PATH 上的 symlink wrapper，解析真实路径后确认其位于 `$JAVA_HOME/bin`。

## 验证证据

- `bash -n Linux/scripts/check-npc-systemd-guest.sh scripts/e2e/modules/npc.sh scripts/e2e/modules/toolchain.sh`: PASS。
- `make -C npc/rv64/testbench TESTS=tb_axi_lite_clint run`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- Sv39 pathtrace smoke:
  - 命令含 `NPC_USER_ECALL_TRACE=1 NPC_USER_ECALL_PATH_TRACE=1 NPC_USER_ECALL_TRACE_LIMIT=8 make -C Linux ARCH=riscv64-npc smoke-sret-user-sv39`。
  - 结果 `HIT GOOD TRAP`，并显示 `cycles=299`、`CLINT mtime = 29`、`match=no`，证明 10:1 divider 生效。
- `scripts/agent-e2e.sh --validate-profile --profile rv64-linux`: PASS，10 个节点绑定完整。
- `scripts/agent-e2e.sh --profile rv64-linux --task-slug agent-e2e-rv64-linux-mtime-div-contract`: PASS。
  - 自动报告：`.github/task-runs/2026-06-12-agent-e2e-rv64-linux-mtime-div-contract/task-report.md`。
  - rootfs smoke 证据：`.github/task-runs/2026-06-12-agent-e2e-rv64-linux-mtime-div-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/`。
  - console marker 包含 ttyS0、virtio-blk、EXT4/VFS root、`Run /lib/systemd/systemd`、systemd 249、Ubuntu 22.04.5 和 hostname。
  - `npc.log` 显示 `cycles=340000000`、`commits=164215587`、`CLINT mtime = 34000000 (mtime-cycles=-306000000, match=no)`。

## 边界与下一步

- 本轮不是完整 Ubuntu/NEMU 等价完成；尚未看到真实 `root@ysyx-ubuntu2204:~#` 或 `__NPC_SYSTEMD_CHECK_DONE__ rc=0`。
- 新 divider 下应重新跑 `Linux/scripts/check-npc-systemd-guest.sh` 长门，建议从 1B/3B cycles 分层推进，并把 `NPC_USER_ECALL_MIN_COMMIT` 或 path trace window 放在 systemd banner 后，避免被早期 syscall 扫描耗尽。
- 若 divider 后仍不能进入 prompt，应优先切分 udev coldplug、`serial-getty@ttyS0` 和 `systemd-sysusers` 的具体等待源，而不是只增加仿真预算。
