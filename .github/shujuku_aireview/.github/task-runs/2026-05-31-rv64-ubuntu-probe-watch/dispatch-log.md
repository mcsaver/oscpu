# Dispatch Log: RV64 Ubuntu Probe Guest Watch

## 2026-05-31

- 读取项目规则、agent/instructions、NPC memory、用户上传文档。
- 确认用户目标：
  - 完整 Linux/Ubuntu 22.04 是长期目标。
  - 近期先不以 Vivado/FPGA 作为前置。
  - 使用 Verilator 做尽量真实的系统/性能仿真。
  - core/SoC 修改仍要保持后续流片水准边界。
- 在 `npc/rv64` 增加 `NPC_GUEST_EXPECT` guest 输出 watch。
- 增加 `smoke-ubuntu-probe-watch` target。
- 短跑 `OpenSBI v1.8` watch PASS，确认 watch 机制有效。
- QEMU 同镜像 probe PASS，确认 initramfs 内容和 `/init` 本身可用。
- 发现 NPC Linux 实际 command line 仍是旧 `earlycon=sbi rdinit=/init`。
- 定位 root cause：OpenSBI 使用 `FW_FDT_PATH`，DTB 被嵌入 `fw_jump.bin`，只重建外部 DTB 不会改变 Linux 实际 bootargs。
- 修正 `platform/npc-rv64.yml` 的 Ubuntu initramfs bootargs，并重建 `opensbi-ubuntu-initramfs`。
- `Kernel command line: console=ttyS0` watch PASS，确认新 bootargs 已进入 Linux。
- 运行 1.3B cycles `[ysyx-init]` watch：
  - 达到 `Run /init as init process`。
  - 打印 arguments/environment。
  - `ttyS0` 已 enabled。
  - 未出现 `[ysyx-init]`。
  - 未出现 `PRETTY_NAME`。
  - max-cycles 退出。
- 更新 memory：
  - `.github/memory/project-status.md`
  - `.github/memory/modules/npc.md`
  - `.github/memory/known-issues.md`
  - `.github/memory/decisions.md`

## 下一步建议

- 给 `npc/rv64/tools/ysyx-ubuntu-init.c` 加最早入口输出，放在 `mkdir_p()`/`mount_fs()` 之前。
- 或在进入 `/init` 后临时打开 syscall/ecall trace，至少记录 syscall number、a0-a2、返回值和 `sepc`。
- 先判断卡在“没有进入用户态第一条 syscall”还是“进入用户态后卡在 early mkdir/mount/open/write”。
- 在 `[ysyx-init]` 和 `PRETTY_NAME` 两个 guest-watch 都通过前，不升级为 `ubuntu-probe-visible`。
