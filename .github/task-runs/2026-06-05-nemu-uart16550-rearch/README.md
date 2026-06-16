# NEMU 16550A UART 重新架构

## 2026-06-06 架构复核
- 用户再次要求“自行重新架构设计而不是在原来的基础上设计”后，复核当前实现：`nemu/src/device/uart16550.c` 是不引用 NEMU IOMap、PLIC、stdin 或 FIFO fd 的纯 16550A 状态机；`nemu/src/device/serial.c` 只是 `SerialPort` 平台前端；`nemu/src/memory/soc.c` 是 SoC adapter；`Uart16550BusProfile` 明确隔离 register stride/io-width。旧 `serial_base[8]` mini UART 和 SoC 私有 `soc_uart_regs[8]` 没有回流。
- 当前 smoke 覆盖 reset/LSR、DLAB divisor、THRI read-ack、RDI/CTI、FIFO burst、loopback、8-bit 与 32-bit stride/hole lane；Linux gate 另覆盖 ttyS0、console、FIFO 自动化输入、serial-getty、PTY/termios/job-control、UART RX burst 与 `/proc/interrupts` 中 ttyS0 PLIC IRQ 可见性。

## 2026-06-05 最终复验
- 本轮确认 UART 不是在旧 mini UART 上继续补丁：`uart16550.{c,h}` 维护纯 16550A 寄存器/FIFO/IRQ 状态，`serial.c` 只作为 `SerialPort` 前端接 NEMU IOMap、host stdin/`NEMU_SERIAL_FIFO`、TX 和 PLIC IRQ1，`soc.c` 也复用同一 core。
- `gcc -std=c11 -Wall -Wextra -Werror -I nemu/include nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c -o /tmp/uart16550-smoke && /tmp/uart16550-smoke`：PASS。
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`、`python3 -m py_compile Linux/platform/gen_dts.py`、相关 `git diff --check`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`、`make -C Linux ARCH=riscv64-nemu rootfs-dtb`、`make -C Linux ARCH=riscv64-nemu check-nemu-performance-config`：PASS。
- `timeout 1700s make -C Linux check-nemu-systemd-guest`：PASS，perf `boot_seconds=237`、`guest_check_seconds=197`、`poweroff_seconds=20`、`total_seconds=454`。关键 marker 覆盖 `ttyS0`/console/FIFO、systemd、syscall probe、vda hash、soak/interrupts 和最终 `systemctl poweroff -> syscon-reset -> HIT GOOD TRAP`。

## Bus Profile 合约
- 用户再次强调“自行重新架构设计而不是在原来的基础上设计”后，本轮把 UART 总线形态从 core 里抽成 `Uart16550BusProfile`。profile 只描述 register byte address 的 `reg_shift/reg_io_width`，core 仍独占 16550A 寄存器、FIFO、IRQ 和副作用语义。
- `uart16550_bus_read/write()` 现在必须接收 profile；`UART16550_BUS_PROFILE_8BIT` 对齐当前 Linux DTS 的 `ns16550a + reg-shift=<0>`，`UART16550_BUS_PROFILE_32BIT` 用于 32-bit stride/low-lane 有效模型。非低 lane 访问不触发寄存器副作用，避免以后把 bus lane 细节继续塞进 `serial.c` 或 SoC adapter。
- `serial.c` 的 `SerialPort` 增加 `bus_profile/bus_map_size`，PIO span 由 `uart16550_bus_profile_span()` 计算，MMIO aperture 仍保持 0x1000 以匹配 DTS `reg` window；`soc.c` 使用同一套 `soc_uart_bus_profile`，不再自己把 offset 当寄存器编号。
- `uart16550-smoke` 新增 32-bit profile 覆盖：检查 8-bit/32-bit span、DLAB 下 DLL/DLM 低 lane 读写、hole lane 读 0、hole lane 写不发 TX、32-bit THR 写只消费低字节。

## Bus Profile 验证
- `gcc -std=c11 -Wall -Wextra -Werror -I nemu/include nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c -o /tmp/uart16550-smoke && /tmp/uart16550-smoke`：PASS，输出 `[uart16550-smoke] PASS`。
- `git diff --check -- nemu/include/device/uart16550.h nemu/src/device/uart16550.c nemu/src/device/serial.c nemu/src/memory/soc.c nemu/tools/uart16550-smoke.c`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS，rv64 Linux 配置下重新链接 `riscv64-nemu-interpreter`。
- `riscv32-soc_defconfig` 下 `src/device/uart16550.c` 已参与编译，且 `/home/lyg/PA/ysyx-workbench/nemu/build/obj-riscv32-nemu-interpreter/src/memory/soc.o` 单目标 PASS；完整 rv32-soc 构建仍被既有 PLIC/CLINT 32-bit shift、`sv39_fail` unused 和 rv32 inst unused warning 阻塞，和本轮 UART profile 无关。
- `make -C Linux ARCH=riscv64-nemu check-nemu-performance-config`：PASS，输出 `__NEMU_PERFORMANCE_CONFIG__:ok`。
- `timeout 1400s make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=236`、`guest_check_seconds=190`、`total_seconds=426`。关键 marker：`serial-getty-ttyS0-active`、`ttyS0-write`、`console-write`、`fifo-ipc`、systemd transient service/timer 全 PASS、`__NEMU_CHECK_SYSTEMD_TRANSIENT_RESULT__:success`、`__NEMU_SYSCALL_PROBE_DONE__ rc=0`、soak uptime `604->639`、interrupts `156336->164965`、最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

## 公共 header 与 SoC adapter 收敛
- 用户再次明确“不在原来的基础上设计”后，本轮把 UART core 的公共 contract 从 `nemu/src/device/` 移到 `nemu/include/device/uart16550.h`，标准 NEMU `serial.c`、standalone smoke 和 `CONFIG_SOC_SIM` SoC adapter 共用同一套 16550A register/bit 定义。
- `nemu/src/memory/soc.c` 删除本地 `soc_uart_regs[8]` mini UART，改成懒初始化的 `Uart16550` 实例；SoC 前端只负责 `0x10000000` 窗口、TX 到 stderr 和 PLIC IRQ1 接线。
- `uart16550_reset()` 的 LCR 复位值收敛为官方硬件语义 `0x00`，由 AM/Linux 初始化为 8N1，不再在设备模型里预设 line format。
- `src/device/filelist.mk` 改为只要 `HAS_SERIAL` 或 `SOC_SIM` 任一启用就编译 `uart16550.c`，且只加入一次；`serial.c` 仍只在 `HAS_SERIAL` 下编译。

## 公共 header 与 SoC adapter 验证
- `gcc -std=c11 -Wall -Wextra -Werror -I nemu/include -o /tmp/uart16550-smoke nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c && /tmp/uart16550-smoke`：PASS，输出 `[uart16550-smoke] PASS`。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS，rv64 Linux 配置下重新编译 `serial.c`、`uart16550.c`、`soc.c` 并链接 `riscv64-nemu-interpreter`。
- `riscv32-soc_defconfig` 下手动单编 `src/memory/soc.c` 与 `src/device/uart16550.c` 到 `/tmp/nemu-soc.o`、`/tmp/nemu-uart16550-rv32.o`：PASS；完整 rv32-soc 构建仍被既有 rv32 PLIC/CLINT shift 与 unused warning 挡住，和本轮 UART 接线无关。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=225`、`guest_check_seconds=134`、`total_seconds=359`；TTY/console、udev/sysfs/virtio-blk、syscall probe、direct IO、rootfs stress、dmesg critical 和最终 rc=0 均 PASS。

## 公共寄存器合约与 ingress queue
- 用户再次明确“自行重新架构设计而不是在原来的基础上设计”后，本轮继续把架构边界从文件拆分推进到接口合约：`uart16550.h` 现在集中声明 16550A register offset 和 IER/IIR/FCR/LCR/MCR/LSR/MSR bit，`uart16550.c` 与 standalone smoke 共用同一套常量，不再各自复制私有寄存器表。
- core 内部把旧命名 `host_fifo/host_storage` 收敛为更中性的 `ingress_fifo/ingress_storage`，表达“进入 UART wire 的外部字节队列”，避免设备 core 语义继续带着宿主 fd/stdio 心智模型。
- `Uart16550` 结构体仍在头文件暴露大小用于静态分配，但已注明字段由 `uart16550.c` 独占维护；外层 `serial.c` 继续只通过 `uart16550_*` API 访问 core。

## 公共合约验证
- `gcc -std=c11 -Wall -Wextra -Werror -I nemu/src -I nemu/include nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c -o /tmp/uart16550-smoke && /tmp/uart16550-smoke`：PASS，输出 `[uart16550-smoke] PASS`。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS，重新编译 `serial.c` 与 `uart16550.c`。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=235`、`guest_check_seconds=125`、`total_seconds=360`。
- 关键 console marker：`ttyS0-write`、`console-write`、`fifo-ipc`、`ppoll-pipe`、`pty-controlling-tty`、`pty-foreground-pgrp`、`pty-sigwinch`、`pidfd-open`、`getrandom`、`syscall-probe`、并发 direct IO `4194304/4194304`、rootfs stress `4194304/4194304`、soak uptime `516->550`、interrupts `133230->141808`、`dmesg-no-critical` 和最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

## Bus Adapter 固化
- 用户再次要求“自行重新架构设计而不是在原来的基础上设计”后，本轮继续把 UART 从旧 `serial.c` mini 形态往三层结构收敛：`uart16550` core、NEMU bus adapter、host backend。
- `uart16550.{c,h}` 新增 `uart16550_bus_read/write()`，集中处理 1/2/4/8B little-endian register-window 访问；`uart16550_read/write()` 保持单寄存器设备语义。
- `serial.c` 不再 `assert(len == 1)`，而是把 IOMap backing store 中的 PIO/MMIO 访问取出后交给 core，再把 read 结果写回 backing store。这样总线访问宽度和 UART 寄存器副作用分开，后续补 `reg-shift`/`reg-io-width` 或多串口时不会把逻辑塞回设备 core。
- 新增 `nemu/tools/uart16550-smoke.c`，用 host 原生编译直接覆盖 reset/LSR、DLAB DLL/DLM、THRI IIR read-ack、RDI/CTI、32B host ingress burst、loopback 和 bus-window read/write。

## SerialPort Front-End
- 用户再次强调“自行重新架构设计而不是在原来的基础上设计”后，`serial.c` 不再保留散落的 `serial_space`、`serial_uart`、`serial_fifo_fd` 单例全局，而是整理为显式 `SerialPort` 前端适配层。
- `SerialPort` 统一承载 UART core 实例、PIO/MMIO backing store、host stdin/`NEMU_SERIAL_FIFO` 输入端点、TX 输出和 PLIC IRQ1 接线；`serial_register_bus()`、`serial_open_host_inputs()`、`serial_port_poll_host()` 分别对应总线注册、宿主端点和输入泵。
- `uart16550.{c,h}` 继续保持纯设备 core，不引用 NEMU IOMap、PLIC、stdin 或 FIFO fd。后续补 raw TTY、break、flow control、多串口时应扩 core 协议和前端实例配置，而不是把宿主逻辑塞回寄存器读写回调。

## Bus Adapter 验证
- `gcc -std=c11 -Wall -Wextra -Werror -I nemu/src/device nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c -o /tmp/uart16550-smoke && /tmp/uart16550-smoke`：PASS，输出 `[uart16550-smoke] PASS`。
- `git diff --check -- nemu/src/device/uart16550.c nemu/src/device/uart16550.h nemu/src/device/serial.c nemu/tools/uart16550-smoke.c`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS，重新编译 `serial.c` 和 `uart16550.c`。
- `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=231`、`guest_check_seconds=118`、`total_seconds=349`。
- 关键 console marker：`__NEMU_CHECK_PASS__:systemd-running`、`ttyS0-write`、`console-write`、`fifo-ipc`、syscall probe 全 PASS、`__NEMU_CHECK_SOAK_UPTIME__:504->539`、`__NEMU_CHECK_INTERRUPTS__:130113->138687`、`__NEMU_CHECK_PASS__:dmesg-no-critical`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

## 追加拆层
- 用户后续明确要求“自行重新架构设计，而不是在原来的基础上设计”。因此在已经重写为 16550A 功能模型后，又把单文件 `serial.c` 拆成 `uart16550.{c,h}` 设备核心与 `serial.c` 平台 glue。
- `uart16550.{c,h}` 现在只维护 16550A 寄存器/FIFO/中断语义，不引用 NEMU IOMap、PLIC、stdin 或 FIFO fd。
- `serial.c` 只负责 NEMU 侧 PIO/MMIO 注册、host stdin/`NEMU_SERIAL_FIFO` 轮询、TX 输出和 PLIC IRQ1 level 接线。
- `nemu/src/device/filelist.mk` 纳入 `uart16550.c`；`SERIAL_INPUT_FIFO` 加上 `depends on !TARGET_AM`，避免 AM 目标意外拉入宿主 fd 逻辑。
- 这个边界对齐 NPC `Uart` core + `AxiLiteToUart` adapter 的职责拆分。后续补 raw TTY、break、流控、多串口时，先扩 core 协议，再由 glue 接平台。

## 追加验证
- `git diff --check -- nemu/src/device/serial.c nemu/src/device/uart16550.c nemu/src/device/uart16550.h nemu/src/device/filelist.mk nemu/src/device/Kconfig`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS，用时 313s。
- `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-check/perf.tsv`：`boot_seconds=238`、`guest_check_seconds=75`、`total_seconds=313`、`soak_seconds=20`、`fs_stress_mib=4`、`process_loops=16`、`max_cycles=12000000000`。
- 关键 console marker：`__NEMU_CHECK_TTYS0_WRITE__`、`__NEMU_CHECK_CONSOLE_WRITE__`、`__NEMU_CHECK_PASS__:fifo-ipc`、`__NEMU_CHECK_PASS__:rootfs-stress-copy-cmp`、`__NEMU_CHECK_SOAK_UPTIME__:432->466`、`__NEMU_CHECK_INTERRUPTS__:110413->118823`、`__NEMU_CHECK_PASS__:dmesg-no-critical`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。
- 用户再次强调“自行重新架构设计而不是在原来的基础上设计”后复核当前职责边界：`serial.c` 仍只包含 IOMap/host FIFO/PLIC glue，`uart16550.c` 仍独占寄存器、FIFO 和 IRQ 状态，没有旧 `serial_base[8]` mini 模型回流。
- 最新复验：`bash -n Linux/scripts/check-nemu-systemd-guest.sh` PASS；`git diff --check -- nemu/src/device/serial.c nemu/src/device/uart16550.c nemu/src/device/uart16550.h nemu/src/device/filelist.mk nemu/src/device/Kconfig Linux/Makefile Linux/scripts/check-nemu-systemd-guest.sh` PASS；`NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)` PASS。
- 最新 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=243`、`guest_check_seconds=116`、`total_seconds=359`，串口 delay 仍为 0，console log 最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。
- 最新 `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=242`、`guest_check_seconds=191`、`total_seconds=433`，120s soak 后 `__NEMU_CHECK_SOAK_UPTIME__:515->713`、`__NEMU_CHECK_INTERRUPTS__:132771->182586`，最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。复跑中发现并修正了 `/proc/stat intr` 单次采样偶发读 0 导致的 false fail，当前脚本会重试采样。
- SerialPort front-end 重整后：`gcc -std=c11 -Wall -Wextra -Werror -I nemu/src/device nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c -o /tmp/uart16550-smoke && /tmp/uart16550-smoke` PASS；`NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)` PASS；相关 `git diff --check` PASS。
- SerialPort front-end 重整后的默认 `make -C Linux check-nemu-systemd-guest`：PASS，perf 为 `boot_seconds=236`、`guest_check_seconds=120`、`total_seconds=356`，`pty-controlling-tty/pty-foreground-pgrp/pty-sigwinch` 与 tty/console/FIFO/syscall/dmesg marker 全 PASS，soak uptime `505->539`，interrupts `130162->138724`，最终 rc=0。
- SerialPort front-end 重整后的 `make -C Linux check-nemu-systemd-guest-long`：PASS，perf 为 `boot_seconds=228`、`guest_check_seconds=188`、`total_seconds=416`，并发 direct IO `8388608/8388608`，16MiB rootfs stress `16777216/16777216`，soak uptime `522->720`，interrupts `134787->184595`，最终 rc=0。

## 目标
- 按用户要求，不在旧 mini UART 上继续贴补丁，而是把 NEMU 串口重新设计成 Linux/ns16550a 可长期使用的设备模型。
- 保持现有 `CONFIG_SERIAL_MMIO=0x10000000`、DTB `compatible = "ns16550a"`、PLIC IRQ1 和 `NEMU_SERIAL_FIFO` 自动化入口兼容。

## 实现
- `nemu/src/device/serial.c` 改为显式 `Uart16550` 状态，不再把硬件状态混放在 IO backing store 的 `serial_base[8]` 中。
- 新增 16B guest-visible RX FIFO，匹配 16550A FIFO 深度；新增 64KiB host ingress queue，用来吸收宿主 stdin/FIFO 的突发输入，再按硬件 FIFO 容量喂给 guest。
- 补齐 DLAB 下 DLL/DLM 别名、IER lower 4 bits、IIR 优先级、THRI read-ack latch、RDI/CTI/RLSI/MSI、FCR FIFO enable/clear/trigger、LSR error read-clear、MSR delta read-clear、MCR loopback 和 scratch register。
- MMIO aperture 从 8B 扩到 0x1000，和 Linux DTB 的 `reg = <... 0x1000>` 对齐；实际寄存器仍按 `reg-shift = 0` 的 8 个 byte register 解码。
- `Linux/scripts/check-nemu-systemd-guest.sh` 的默认 `NEMU_SYSTEMD_INPUT_DELAY` 改为 0；delay=0 时直接 `cat` 整段 guest 命令进入串口 FIFO，用来证明 UART 自身能承受自动化突发输入。

## 验证
- `git diff --check -- nemu/src/device/serial.c`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS。
- 默认无输入延迟的 `make -C Linux check-nemu-systemd-guest`：PASS，用时约 295s。

关键日志：
- `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-check/console.log`
- 其中可见 `__NEMU_CHECK_SOAK_UPTIME__:431->465`、`__NEMU_CHECK_INTERRUPTS__:110097->118487`、`__NEMU_CHECK_PASS__:interrupts-stat-monotonic`、`__NEMU_CHECK_PASS__:dmesg-no-critical`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

## 边界
- 这是面向单 hart Linux bring-up 的 16550A 功能模型，不是周期精确 UART，也不模拟真实 baud-rate 发送时间。
- 还未声明 QEMU 级设备完整性；后续仍需要更长交互 session、恶意/异常 FIFO 压力、多设备并发和 virtio 错误路径验证。
