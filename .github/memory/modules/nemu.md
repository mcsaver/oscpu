# NEMU 模块笔记

## 当前状态
<!-- 已实现的指令、设备等 -->
- keyboard.c 中的 i8042 键盘设备只暴露一个 4 字节数据寄存器；非 CONFIG_TARGET_AM 构建下由 device.c 的 SDL_KEYDOWN/SDL_KEYUP 事件调用 send_key 入本地环形队列，CPU 读设备时在读回调里出队；CONFIG_TARGET_AM 构建下不经过 SDL，而是直接 io_read(AM_INPUT_KEYBRD) 取键盘事件。事件编码使用 `KEYDOWN_MASK=0x8000` 复用按下/松开状态与键码。
- 设备层通过 IOMap 统一抽象 PIO/MMIO；实际注册分别在 src/device/io/port-io.c 和 src/device/io/mmio.c 中维护独立映射表。
- map_read 在读前调用回调，map_write 在写后调用回调；这是设备寄存器准备读值与消费写值的关键时序。
- 设备地址命中映射时会调用 difftest_skip_ref；若未开启 CONFIG_DIFFTEST，该调用在头文件中退化为空内联函数。
- timer.c 中的 RTC 设备占 8 字节寄存器空间，offset 0/4 分别存放 get_time() 的低 32 位和高 32 位；当前实现只在读 offset 4 时整体刷新这两个槽位。非 CONFIG_TARGET_AM 构建下，timer_intr 会被注册到 alarm.c 的 SIGVTALRM 周期回调中，用于触发 dev_raise_intr()。
- DTRACE 已按 ITRACE 的模式接入 Kconfig/Makefile：`config DTRACE` 控制 MMIO 设备追踪开关，`config DTRACE_COND` 通过 Makefile 展开为 `-DDTRACE_COND=...`，当前日志挂在 src/device/io/mmio.c 的 `mmio_read/mmio_write`。

## 配置笔记
<!-- Kconfig 配置选项说明 -->
- 运行 AM 程序前需要使用 riscv32-am_defconfig 或等价配置，至少保证 CONFIG_TARGET_AM=y 且 CONFIG_DEVICE=y；否则 AM 侧访问 0xa0000000 起始的设备地址会因未注册 MMIO 而在 paddr.c 中触发 pmem 越界。
- 新增 Kconfig 项后，如果当前 `.config` 还是旧的，可以重新执行 `make menuconfig`、`make olddefconfig` 或直接 `make` 触发配置同步，再显式打开 `DTRACE`/调整 `DTRACE_COND`。

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- `nemu/.config` 若开启 `CONFIG_CC_ASAN=y` 且 `CONFIG_VGA_SHOW_SCREEN=y`，运行 AM/FCEUX 这类会打开窗口的程序时，退出后可能在 `src/device/vga.c` 的 SDL 创建路径上看到 LeakSanitizer 报告；这通常是 NEMU 宿主侧 SDL/Mesa 资源未显式销毁加上宿主图形库清理时机导致的噪音，不是 guest 程序本身的逻辑错误。
