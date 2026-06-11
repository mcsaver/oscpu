# NEMU rootfs stage1/init 调度日志

## RECALL

- 已读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/nemu.md`。
- 已补读 `.github/agents/rv64-linux.agent.md`、`.github/agents/linux-device.agent.md`、`.github/instructions/virtio-rootfs.instructions.md`。

## PLAN

1. 复核当前 rootfs `/init` 与前一轮 NEMU 日志。
2. 把 stage1 marker 提前到第一条 shell 命令，避免早期 mount 阻挡可见性。
3. 重建 rootfs 并用 `debugfs` 验证镜像实物。
4. 运行 NEMU rootfs gate，定位是否能进入 stage1。
5. 增加 opt-in 静态 PID1 probe 做分层诊断。
6. 恢复默认 rootfs/DTB/OpenSBI，并记录证据与边界。

## DISPATCH / VERIFY

- 修改 `Linux/scripts/build-ubuntu-rootfs.sh`：
  - `/init` 第一条 shell 命令改为 `echo "[ysyx-rootfs] stage1 begin"`。
  - devtmpfs 改为在 proc mount 后通过 `/proc/mounts` 判断是否需要补挂。
  - 增加 proc/sysfs/run/devpts/devshm/cgroup2 的阶段 marker。
- 重建 rootfs：
  - 命令：`bash -n Linux/scripts/build-ubuntu-rootfs.sh && bash Linux/scripts/build-ubuntu-rootfs.sh`
  - 结果：PASS。
  - 证据：`debugfs -R "cat /init"` 可见第一条 marker；`debugfs -R "cat /etc/fstab"` 可见伪文件系统条目；`debugfs -R "stat /usr/lib/systemd/systemd"` 显示不存在。
- 默认 8B stage1 gate：
  - 命令：`make -C Linux ARCH=riscv64-nemu MAX_CYCLES=8000000000 LOG_DIR=.../riscv64-nemu-rootfs-stage1-mounts-v2 run`
  - 结果：到 `Run /init as init process`，无 stage1 marker，按预算停止。
  - PC：`0xffffffff803e5924`，`addr2line` 映射到 `do_irq`。
- 新增 opt-in 静态 probe：
  - `UBUNTU_ROOTFS_PROBE=1` 时编译 `Linux/tools/ysyx-ubuntu-init.c` 为 `/ysyx-rootfs-probe`。
  - 默认不安装；最终默认镜像验证 `/ysyx-rootfs-probe: File not found`。
- 修复 OpenSBI no-PMU：
  - 根因：直接 sed build 目录 `.config` 会被 OpenSBI make 按 defconfig 重新生成覆盖。
  - 修复：生成 `ysyx_nopmu_defconfig` 并通过 `PLATFORM_DEFCONFIG` 输入。
  - 验证：最终 `.config` 为 `# CONFIG_SBI_ECALL_PMU is not set`；OpenSBI banner 的 Standard SBI Extensions 不含 `pmu`。
- opt-in probe 诊断：
  - 命令：`BOOTARGS_EXTRA='init=/ysyx-rootfs-probe' MAX_CYCLES=9000000000/12000000000 ... run`
  - 结果：枚举到 `virtio_blk virtio0: [vda]`，但没有到 EXT4 mount；停止点映射到 `plic_handle_irq/irq_exit_rcu` 附近。
  - 处置：probe 改成默认不安装，避免污染普通 rootfs 布局。
- 默认恢复验证：
  - 命令：`make -B -C Linux ARCH=riscv64-nemu rootfs-dtb opensbi-rootfs`
  - 证据：bootargs 恢复为 `root=/dev/vda rw init=/init`；OpenSBI `.config` 保持 PMU unset。
  - 命令：`timeout 950s make -C Linux ARCH=riscv64-nemu MAX_CYCLES=8000000000 LOG_DIR=.../riscv64-nemu-rootfs-default-restored-8b run`
  - 结果：默认 rootfs 到 EXT4 mount 与 `Run /init`，8B 内无 stage1 marker。
- 后续静态 PID1 C breadcrumbs：
  - 修改 `Linux/tools/ysyx-rootfs-init.c`：新增 `static stage1 begin`、`mount proc`、`read cmdline`、`systemd gate checked`、`exec /bin/sh fallback` 等 marker。
  - shell fallback 跳过 sysfs，systemd gate 保留 sysfs/run/devpts/devshm/cgroup2。
  - `bash -n Linux/scripts/build-ubuntu-rootfs.sh && bash Linux/scripts/build-ubuntu-rootfs.sh` PASS。
- NEMU debug/performance 配置：
  - 新增 `nemu/configs/riscv64-linux_debug_defconfig`。
  - `Linux/Makefile` 新增 `NEMU_DEFCONFIG ?= riscv64-linux_defconfig`，debug run 可传 `NEMU_DEFCONFIG=riscv64-linux_debug_defconfig`。
  - debug 配置打开 syscall trace 与 PLIC IRQ trace，关闭 Etrace，避免 external interrupt 长跑生成 GB 级日志。
- syscall trace 定位 OP-FP 缺口：
  - `riscv64-nemu-rootfs-syscall-trace-12b`：到 `/bin/sh -c marker`，随后 `/bin/sleep` illegal `0xf2000453`，反汇编为 `fmv.d.x fs0,zero`。
  - 补 `fmv.{w,d}.x`、`fmv.x.{w,d}`、`fclass.{s,d}`。
  - `riscv64-nemu-rootfs-shell-skip-sysfs-fmvd-14b`：再次到 marker，下一条 illegal `0x228404d3`，反汇编为 `fmv.d fs1,fs0`，即 `fsgnj.d`。
  - 补 `fsgnj/fsgnjn/fsgnjx.{s,d}`。
- IRQ trace 复核：
  - `riscv64-nemu-rootfs-syscall-trace-fsgnj-12b` 关闭 IRQ trace 前曾因 Etrace 记录大量 cause=9 external interrupt，`nemu.log` 达 2.3G。
  - 改 debug defconfig 后跑 `riscv64-nemu-rootfs-irq-trace-fsgnj-12b`，日志降到几十 KB，PLIC IRQ1/IRQ2 claim/complete 后 `level=0`，未见典型不清线 storm；该轮因墙钟截断停在 `execve("/bin/sh")` 之后。
  - 默认 performance `riscv64-nemu-rootfs-shell-fsgnj-performance-20b` 到 `exec /bin/sh fallback`，但 700s/20B 内未重新到 shell marker。
- 构建验证：
  - `make -C nemu NEMU_HOME=... riscv64-linux_debug_defconfig && make -C nemu NEMU_HOME=... -j4` PASS。
  - `make -C nemu NEMU_HOME=... riscv64-linux_defconfig && make -C nemu NEMU_HOME=... -j4` PASS。
- 2026-06-05 继续推进：
  - 接受用户约束：旧 PA/AM `ebreak` 或退出条件若与 Linux 启动冲突，优先按 Linux 和官方 RISC-V ISA/privileged 语义处理。
  - 修正 `nemu/src/device/disk.c`：QueueNotify 无新 avail descriptor 时不再触发 used-buffer IRQ。
  - 在 `CONFIG_RISCV_SYSCALL_DEBUG_LOG` 下新增 execve 成功后的短预算 U-mode PC 采样；debug run `riscv64-nemu-rootfs-post-exec-utrace-12b` 显示 `/bin/sh` 已能 fork/exec `/bin/sleep`。
  - 解码并补齐用户态缺口：`0xa2f52753 = feq.d`，`0x02f47453 = fadd.d`，`0xc2251753 = fcvt.l.d`，随后补对应 RV64F/D compare、基础算术、min/max、FCVT 族。
  - `make -C nemu NEMU_HOME=... riscv64-linux_defconfig && make -C nemu NEMU_HOME=... -j4` PASS。
  - performance run `riscv64-nemu-rootfs-fcvt-performance-12b`：OpenSBI/Linux/ext4 rootfs/静态 PID1 均可达，到 `[ysyx-rootfs-sh] /bin/sh -c marker` 后 300s 内无 `Illegal instruction`、`unhandled signal`、`badaddr`；外层 `timeout` 终止的是 shell fallback 中正常等待的 `sleep 60`。
- 2026-06-05 systemd readiness / ebreak 语义继续收口：
  - 新增 `Linux/scripts/check-ubuntu-rootfs.sh`，并在 `Linux/Makefile` 暴露 `check-ubuntu-rootfs` 与 `check-ubuntu-rootfs-systemd`。
  - `build-ubuntu-rootfs.sh` 新增 `UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1`，在无法走 sudo+debootstrap+qemu-riscv64-static 时拒绝 shell-only fallback。
  - `riscv64/inst.c` 与 `riscv32/inst.c` 新增 `ebreak_should_raise_breakpoint_trap()`；非 AM system 配置的 `ebreak/c.ebreak` 走 `CAUSE_BREAKPOINT`，AM 目标继续保留 `NEMUTRAP`。
  - 验证：脚本 `bash -n` PASS；普通 rootfs check PASS 并报告 systemd 缺失；严格 systemd check 按预期失败；require-systemd 构建按预期失败；`make -C Linux ARCH=riscv64-nemu check` PASS；RV64 Linux NEMU defconfig/build PASS；裸 RV64 system `ebreak` 不再 HIT GOOD/BAD TRAP。
  - 额外尝试：RV32 AM 编译会被既有 32-bit system/AM 目标问题挡住，包括 PLIC/CLINT 32-bit shift、`sv39_fail` unused、`__int128` 在 AM 交叉目标不可用等；本轮不混入修复，最终 NEMU 配置已恢复到 `riscv64-linux_defconfig`。

## RECORD

- 已更新 `.github/memory/project-status.md`。
- 已更新 `.github/memory/modules/nemu.md`。
- 已新增 `.github/memory/known-issues.md` 条目 [49]。
- 已再次更新 `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`，记录 OP-FP/trace/动态 shell 前沿。
- 已在 2026-06-05 再次更新上述 memory 与本 task-run，记录动态 shell/sleep 已推进到稳定等待，以及 systemd/sysfs/TTY 的剩余边界。
- 已在 2026-06-05 再次更新 memory 与本 task-run，记录 rootfs systemd readiness 检查、require-systemd 硬门槛、以及 Linux/system `ebreak` 官方 trap 语义优先级。
