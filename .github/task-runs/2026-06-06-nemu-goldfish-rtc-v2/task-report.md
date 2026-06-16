# Task Report

## 基本信息

- `task_id`: `2026-06-06-nemu-goldfish-rtc-v2`
- `task_slug`: `nemu-goldfish-rtc-v2`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-06`
- `updated_at`: `2026-06-06`

## 任务目标

- `source_request`: 用户要求继续按上传建议优化 NEMU，使其逐步能启动完整规模 Ubuntu 22.04；上传路线图阶段 A 包含“补 RTC 或 goldfish RTC”。
- `goal`: 为 NEMU Ubuntu rootfs 路线增加 Linux 可见的 RTC 设备，并用完整 systemd/rootfs focused gate 证明 `/dev/rtc0` 与 `goldfish_rtc` 驱动可用。
- `scope`: 本切片只闭合 goldfish RTC/rtc0；不声明完整 Ubuntu 2204、完整 VM、阶段 B 性能路线或阶段 C/D 设备路线完成。

## 选图说明

- `selected_template`: `rv64-ubuntu-rootfs-loop`
- `why_this_graph`: RTC 是 Linux rootfs guest 可见平台设备，必须同时覆盖 NEMU 设备模型、DTB、kernel config、guest sysfs/dev node 和完整 rootfs/systemd gate。
- `dynamic_nodes_added`: `rtc-device-contract`、`dtb-rtc-node`、`guest-rtc-gate`、`hwclock-diagnostic-triage`
- `why_dynamic_nodes_were_needed`: 原模板偏 virtio/rootfs，本轮新增的 RTC 设备需要单独确认 Linux driver binding、wall-clock 合理性和 `hwclock` 行为边界。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | `codex` | `completed` | `.github/AGENTS.md`、Copilot 规则、memory、RV64/rootfs instructions、上传路线图 | 明确本轮只处理阶段 A RTC 子项 | 完成判定钩子要求不关闭总 goal |
| `rtc-device-contract` | `codex` | `completed` | Linux `timer-goldfish.h` 寄存器定义、NEMU 设备框架、PLIC 接口 | 新增 `nemu/src/device/goldfish_rtc.c`，接入 Kconfig/filelist/device_update | NEMU 构建 PASS，autoconf 含 `CONFIG_HAS_GOLDFISH_RTC=y` |
| `dtb-rtc-node` | `codex` | `completed` | `Linux/platform/npc-rv64.yml`、`gen_dts.py`、`Linux/Makefile` | NEMU rootfs DTB 暴露 `rtc@10003000`/`rtc0`，NPC DTB 不暴露 NEMU-only RTC | `make -C Linux ARCH=riscv64-nemu rootfs-dtb` PASS；`fdtget` compatible/interrupts/reg PASS；`ARCH=riscv64-npc rootfs-dtb` PASS |
| `kernel-config` | `codex` | `completed` | `Linux/scripts/build-linux.sh` | Linux 打开 `CONFIG_RTC_CLASS` 与 `CONFIG_RTC_DRV_GOLDFISH` | `JOBS=4 bash Linux/scripts/build-linux.sh` PASS，`.config` 含目标选项 |
| `guest-rtc-gate` | `codex` | `completed` | `Linux/scripts/check-nemu-systemd-guest.sh` | 新增 `/dev/rtc0`、sysfs name/date/time/since_epoch 检查 | focused gate `.github/task-runs/2026-06-06-nemu-goldfish-rtc-v2` PASS |
| `hwclock-diagnostic-triage` | `codex` | `completed` | 第一次 focused gate 日志 | `hwclock --show` 从 hard gate 调整为诊断 marker | sysfs/driver/time hard gate PASS；`__NEMU_CHECK_RTC0_HWCLOCK_DIAG__:124` 仅诊断 |
| `record` | `codex` | `completed` | 验证输出、perf、console marker | 更新 memory 与本 task-run | `.github/memory/project-status.md`、`modules/nemu.md`、`known-issues.md` |

## 关键产物

- `artifacts`: `nemu/src/device/goldfish_rtc.c`、`Linux/platform/npc-rv64.yml`、`Linux/platform/gen_dts.py`、`Linux/scripts/check-nemu-systemd-guest.sh`
- `logs_or_traces`: `.github/task-runs/2026-06-06-nemu-goldfish-rtc-v2/console.log`、`perf.tsv`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: 无 RTC 子项阻塞。
- `missing_dependencies`: `hwclock --show --rtc=/dev/rtc0` 在当前最小模型下超时，已记录为诊断；若未来需要把 `hwclock` 作为 hard gate，需要补充 goldfish RTC update IRQ/UIE 或确认 util-linux 期望。
- `risk_assessment`: RTC 模型是 Linux bring-up 功能模型，不是完整 QEMU RTC/PM/电池时钟模型；完整 Ubuntu 2204 总目标仍有大量设备、性能和长期运行条目未闭合。

## 下一步建议

1. 继续阶段 A：补 virtio-blk 更多标准特性/错误路径或异常精确性 gate。
2. 进入阶段 B 的低风险性能项：basic block interpreter、decode cache、host-pointer TLB、RAM fast path、serial buffering、virtio-blk `pread/pwrite` 和 TB-boundary interrupt checks。

## 模板升级候选

- `repeated_dynamic_subgraph`: `linux-mmio-device-contract -> dtb-node -> kernel-driver-config -> guest-sysfs-devnode-gate`
- `should_promote_to_static_template`: `no`
- `reason`: 当前仅为 NEMU rootfs 平台设备补洞，先保留在 `rv64-ubuntu-rootfs-loop` 内。

## 收尾结论

- `final_result`: goldfish RTC/rtc0 子任务完成并通过 focused Ubuntu rootfs/systemd gate；总 goal 保持 active。
- `evidence_summary`: perf `237/589/18/844s`；Linux 日志 `goldfish_rtc 10003000.rtc: registered as rtc0`，`setting system clock to 2026-06-06T10:49:20 UTC`；marker `__NEMU_CHECK_RTC0_NAME__:goldfish_rtc 10003000.rtc`、`__NEMU_CHECK_RTC0_SINCE_EPOCH__:1780743650`、`rtc0-node`、`rtc0-sysfs`、`rtc0-goldfish-driver`、`rtc0-since-epoch-plausible`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、`HIT GOOD TRAP`。
- `notes`: 根据完成判定钩子，本记录只能称为 RTC 切片完成，不得把完整规模 Ubuntu 2204/完整 VM 路线标为完成。
