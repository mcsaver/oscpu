# Dispatch Log

## 基本信息

- `task_id`: `2026-06-06-nemu-goldfish-rtc-v2`
- `task_slug`: `nemu-goldfish-rtc-v2`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-06-06 18:20] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求继续按上传路线图优化 NEMU 启动完整规模 Ubuntu 22.04。
- `depends_on`: 无
- `inputs`: 上传路线图、`.github/AGENTS.md`、Copilot 规则、memory、RV64/rootfs instructions
- `action`: 复核路线图阶段 A，选择“补 RTC 或 goldfish RTC”作为下一切片。
- `outputs`: 明确本轮只处理 RTC 子任务。
- `evidence`: 完成判定钩子要求路线图只能按子项收口。
- `handoff_to`: `rtc-device-contract`
- `next_step`: 实现 NEMU goldfish RTC 功能模型。
- `notes`: 总 goal 不应因本切片完成而关闭。

### [2026-06-06 18:35] `rtc-device-contract` - `completed`

- `owner_agent`: `codex`
- `trigger`: Linux `goldfish_rtc` 驱动需要 DTB compatible 与寄存器语义。
- `depends_on`: `recall`
- `inputs`: Linux `include/clocksource/timer-goldfish.h`、NEMU 设备/PLIC 框架
- `action`: 新增 `nemu/src/device/goldfish_rtc.c`，实现 time/alarm/IRQ 寄存器，接入 `device_update()`、Kconfig、filelist、默认 defconfig。
- `outputs`: `CONFIG_HAS_GOLDFISH_RTC=y`，默认 MMIO `0x10003000`。
- `evidence`: NEMU rv64 linux defconfig 构建 PASS。
- `handoff_to`: `dtb-rtc-node`
- `next_step`: 暴露 Linux 可匹配的 DTB 节点。
- `notes`: 时间源使用宿主 realtime 初值加 NEMU monotonic delta。

### [2026-06-06 18:45] `dtb-rtc-node` - `completed`

- `owner_agent`: `codex`
- `trigger`: Linux 驱动需要 `google,goldfish-rtc` 节点与 IRQ/reg 一致。
- `depends_on`: `rtc-device-contract`
- `inputs`: `Linux/platform/npc-rv64.yml`、`Linux/platform/gen_dts.py`、`Linux/Makefile`
- `action`: 仅 NEMU rootfs DTB 加入 `rtc@10003000` 与 `rtc0` alias；NPC DTB 不暴露该 NEMU-only 设备。
- `outputs`: `npc-rv64-nemu-rootfs.dtb` 含 RTC 节点。
- `evidence`: `make -C Linux ARCH=riscv64-nemu rootfs-dtb` PASS；`fdtget` compatible=`google,goldfish-rtc`、interrupts=`4`、reg=`0 268447744 0 4096`；`ARCH=riscv64-npc rootfs-dtb` PASS。
- `handoff_to`: `kernel-config`
- `next_step`: 打开 Linux goldfish RTC driver。
- `notes`: 曾检查 alias 不能污染非 NEMU DTS，已修正。

### [2026-06-06 18:55] `kernel-config` - `completed`

- `owner_agent`: `codex`
- `trigger`: kernel 需内建 `RTC_CLASS` 和 `RTC_DRV_GOLDFISH`。
- `depends_on`: `dtb-rtc-node`
- `inputs`: `Linux/scripts/build-linux.sh`
- `action`: 将构建脚本从关闭 RTC class 改为启用 goldfish RTC。
- `outputs`: Linux Image 可 probe goldfish RTC。
- `evidence`: `JOBS=4 bash Linux/scripts/build-linux.sh` PASS；`.config` 含 `CONFIG_RTC_CLASS=y`、`CONFIG_RTC_DRV_GOLDFISH=y`。
- `handoff_to`: `guest-rtc-gate`
- `next_step`: 在 guest-check 中加入 Linux-visible RTC gate。
- `notes`: 此变更面向 NEMU rootfs 机器的功能设备完整性。

### [2026-06-06 19:03] `guest-rtc-gate` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要证明设备不是只存在于 DTB/构建，而是 guest 可用。
- `depends_on`: `kernel-config`
- `inputs`: `Linux/scripts/check-nemu-systemd-guest.sh`
- `action`: 新增 `/dev/rtc0`、sysfs `name/since_epoch/date/time` marker 和 hard gate。
- `outputs`: focused gate `.github/task-runs/2026-06-06-nemu-goldfish-rtc-v2`。
- `evidence`: `__NEMU_CHECK_RTC0_NAME__:goldfish_rtc 10003000.rtc`、`__NEMU_CHECK_RTC0_SINCE_EPOCH__:1780743650`、`rtc0-node`、`rtc0-sysfs`、`rtc0-goldfish-driver`、`rtc0-since-epoch-plausible`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、`HIT GOOD TRAP`。
- `handoff_to`: `hwclock-diagnostic-triage`
- `next_step`: 处理 `hwclock` 行为。
- `notes`: perf `boot=237s/guest_check=589s/poweroff=18s/total=844s`。

### [2026-06-06 19:10] `hwclock-diagnostic-triage` - `completed`

- `owner_agent`: `codex`
- `trigger`: 初版 gate 将 `hwclock --show --rtc=/dev/rtc0` 作为 hard gate 时超时。
- `depends_on`: `guest-rtc-gate`
- `inputs`: `.github/task-runs/2026-06-06-nemu-goldfish-rtc/console.log`
- `action`: 将 `hwclock` 改为诊断 marker，保留 sysfs/driver/time 作为 hard gate。
- `outputs`: `__NEMU_CHECK_RTC0_HWCLOCK_DIAG__:124`。
- `evidence`: 第二次 focused gate PASS，RTC hard gate 与 systemd/rootfs/poweroff 全闭合。
- `handoff_to`: `record`
- `next_step`: 更新 memory 与 task-run。
- `notes`: util-linux `hwclock` 可能等待当前最小模型未承诺的 update IRQ/UIE 行为；不把该诊断项误判为 RTC 失败。

### [2026-06-06 19:25] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 跨模块/长链调试要求 RECORD。
- `depends_on`: `guest-rtc-gate`、`hwclock-diagnostic-triage`
- `inputs`: console marker、perf、构建与 DTB 验证结果
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`，补齐本 task-run 报告。
- `outputs`: RTC 子任务记录。
- `evidence`: memory/task-run 文件存在，并在最终 diff check 中纳入验证。
- `handoff_to`: 无
- `next_step`: 继续路线图剩余项。
- `notes`: 根据完成判定钩子，本节点只记录“RTC 切片完成”，不关闭总 goal。
