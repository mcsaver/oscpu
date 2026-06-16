# Task Report: RV64 Ubuntu Probe Guest Watch

## 背景

用户要求按上传文档配置后续 RV64 Linux/Ubuntu 22.04、Verilator-first、流片约束相关 agent 环境，并继续避免把不完整证据误判为“完整 Ubuntu”。本轮在已完成 agent 环境配置和 UART THRE 补强之后，继续把 NPC 侧 Ubuntu probe 验收做成可复验的 guest 输出 watch。

## 修改

- `npc/rv64/csrc/include/monitor/log.h`
  - 新增 `npc_guest_expect_matched()`、`npc_guest_expect_text()`、`npc_reset_guest_expect()`。
- `npc/rv64/csrc/monitor/log.c`
  - 新增 `NPC_GUEST_EXPECT` 环境变量。
  - guest UART 输出即使无日志文件也会进入 line buffer。
  - 对完整行和当前半行都执行 `strstr()` 匹配，避免无换行或半行输出导致 watch 永远不命中。
- `npc/rv64/csrc/cpu/cpu-exec.cpp`
  - 每轮仿真周期后检查 guest-watch 命中。
  - 命中后以 `NPC_END` 正常结束，并在报告中显示 `GUEST EXPECT MATCH` / `exit via guest-watch`，不伪装成 `HIT GOOD TRAP`。
- `npc/rv64/tools/Makefile`
  - 新增 `UBUNTU_PROBE_EXPECT ?= PRETTY_NAME="Ubuntu 22.04.5 LTS"`。
  - 新增 `smoke-ubuntu-probe-watch` 目标。
- `npc/rv64/platform/npc-rv64.yml`
  - 将 Ubuntu initramfs bootargs 修正为 `console=ttyS0,115200n8 earlycon=sbi loglevel=8 ignore_loglevel rdinit=/init nowatchdog softlockup_panic=0`。

## 验证

- `make -C npc/rv64 default`
  - PASS。
- `make -C npc/rv64/tools smoke-ubuntu-probe-watch UBUNTU_PROBE_EXPECT='OpenSBI v1.8' UBUNTU_INITRAMFS_MAX_CYCLES=5000000 LOG_DIR=../env/logs/codex-ubuntu-watch-smoke3`
  - PASS，命中 `OpenSBI v1.8`。
  - `cycles=1437817`、`commits=1425843`、`CPI=1.008`。
- `make -C npc/rv64 qemu-ubuntu-initramfs LOG_DIR=env/logs/codex-qemu-ubuntu-probe-check`
  - PASS，QEMU 同镜像完整打印 `[ysyx-init] Ubuntu 22.04 initramfs reached on NPC rv64imac core`、`PRETTY_NAME="Ubuntu 22.04.5 LTS"`、`VERSION_ID="22.04"`、`UBUNTU_CODENAME=jammy`。
- `make -C npc/rv64/tools ubuntu-initramfs-dtb`
  - PASS。
- `make -C npc/rv64 opensbi-ubuntu-initramfs`
  - PASS，确认 OpenSBI `fw_jump.bin` 内嵌新 bootargs。
- `make -C npc/rv64/tools smoke-ubuntu-probe-watch UBUNTU_PROBE_EXPECT='Kernel command line: console=ttyS0' UBUNTU_INITRAMFS_MAX_CYCLES=120000000 LOG_DIR=../env/logs/codex-ubuntu-watch-bootargs2`
  - PASS，NPC 侧 Linux 实际 command line 已使用 `console=ttyS0,115200n8 ... rdinit=/init ...`。
  - `cycles=46236723`、`commits=11100849`。
- `make -C npc/rv64/tools smoke-ubuntu-probe-watch LOG_DIR=../env/logs/codex-ubuntu-probe-watch-init-console UBUNTU_PROBE_EXPECT=[ysyx-init] UBUNTU_INITRAMFS_MAX_CYCLES=1300000000`
  - 未通过 watch，max-cycles 退出。
  - 已出现 `ttyS0` enabled、`Run /init as init process`、`with arguments`、`with environment`。
  - 未出现 `[ysyx-init]` 或 `PRETTY_NAME`。
  - 退出统计：`cycles=1300000000`、`commits=216551980`、`CPI=6.003`、约 `63463 inst/s`。
  - PC `0xffffffff80056b0a` 映射到 `hrtimer_update_next_event` 附近。

## 结论

当前 gate 仍停在 `/init` handoff 已发生、Linux console/bootargs 已确认，但 NPC 用户态最早 probe 输出不可见。不能声称 NPC 已完整显示 Ubuntu 22.04 `/etc/os-release`，更不能声称完整 Ubuntu shell/rootfs 已启动。

下一步应优先在 probe `/init` 中加入最早 `write(1, "[ysyx-init] early\n", ...)`，或在 NPC 侧加轻量 ecall/syscall trace，定位 first user syscall、`mkdir/mount(devtmpfs/proc/sysfs)`、console open/write 或调度/定时器路径。
