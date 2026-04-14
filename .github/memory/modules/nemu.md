# NEMU 模块笔记

## 当前状态
<!-- 已实现的指令、设备等 -->
- 在当前工作区的分层里，NEMU 应优先被当作“参考模型/参考平台”而不是最终目标实现：它先承载 AM 和 am-kernels 跑通参考闭环，定义程序、指令和基础设备在功能上的正确行为，后续 RTL 仿真再拿这份行为做对照。
- 对 CPU 敏捷开发来说，NEMU、RTL 仿真和综合的职责不能混淆：NEMU 负责参考正确性与快速回归，RTL 仿真负责验证你的目标 CPU 实现是否与参考一致，RTL 综合/STA 则负责检查这份 RTL 是否可实现以及面积、频率、时序是否可接受；综合结果不能替代参考模型，NEMU 也不直接回答 PPA 问题。
- `WATCHPOINT` 现在已与 AM 目标对齐：`nemu/Kconfig` 用 `depends on !TARGET_AM` 从配置入口禁止 AM 打开监视点；`nemu/src/cpu/cpu-exec.c` 则进一步把监视点头文件和执行分支都收紧为“非 AM 且开启 WATCHPOINT”才参与编译。这样改完后，即使 future 配置切换或旧对象文件混入，AM 目标也不会再链接到被 `src/filelist.mk` 排除掉的 `watchpoint.c` 符号。
- 已确认一次 AM 目标特有的链接失配：`make ARCH=riscv32-nemu` 构建的不是普通 native NEMU，而是 `CONFIG_TARGET_AM=y` 的目标；该目标会在 `src/filelist.mk` 中把 `src/monitor/sdb` 整个黑名单排除，所以 `watchpoint.c` 不会进入 `build/riscv32-nemu`。如果 `cpu-exec.c` 仍因 `CONFIG_WATCHPOINT` 或旧对象文件而保留 `watchpoint_enabled` / `compare_assert` 引用，就会在最终链接 `riscv32-nemu-interpreter-riscv32-nemu.elf` 时出现 undefined reference。
- 当前这次 SDL/Mesa 泄漏问题已由用户在宿主机侧重装运行库后消失：`sudo apt install --reinstall -y libsdl2-2.0-0 libglx-mesa0 libgl1-mesa-dri libegl-mesa0 mesa-vulkan-drivers` 之后，用户反馈“没问题了”。因此本次案例里，虽然上游 NEMU 的 VGA/SDL 生命周期设计本身仍有缺口，但真正让错误在当前机器上显性化的触发条件，至少部分来自宿主图形运行库/后端状态。
- 已追加一次显示后端对照实验：即便显式设置 `SDL_VIDEODRIVER=x11`，`ASAN_OPTIONS=detect_leaks=1 make -C am-kernels/tests/am-tests ARCH=riscv32-nemu c mainargs=v` 仍旧在 `libGLX_mesa.so`、`libSDL2.so` 与 `src/device/vga.c:56` 报相同泄漏规模。这说明当前问题不能简单归因为“只是在 Wayland 下才会泄漏”，更像 SDL 默认 renderer/GLX 路径与缺失 SDL 退出清理共同作用。
- 当前终端没有 `sudo` 免密权限；涉及 `apt install --reinstall` 这类系统包修复时，agent 可以给出精确命令，但无法替用户无交互完成。
- 已核对当前宿主图形环境：本机 `sdl2-config --version` 为 `2.30.0`，APT 中 `libsdl2-2.0-0` 为 `2.30.0+dfsg-1ubuntu3.1`；`libglx-mesa0`、`libgl1-mesa-dri`、`libegl-mesa0`、`mesa-vulkan-drivers` 当前为 `25.0.7-0ubuntu0.24.04.2`，会话环境同时存在 `WAYLAND_DISPLAY=wayland-0` 和 `DISPLAY=:0`。这说明当前系统库并未缺失到“程序无法运行”的程度，更像是 Wayland/X11/GLX/Mesa 后端选择与 ASAN 泄漏检查交互，导致某些工作区会把 SDL/Mesa 退出噪音放大成错误。
- 检索上游 `NJU-ProjectN/nemu` 后确认，官方 `src/device/vga.c` 也同样只做 `SDL_CreateWindowAndRenderer()` 与 `SDL_CreateTexture()` 初始化，未提供统一 `SDL_DestroyTexture`、`SDL_DestroyRenderer`、`SDL_DestroyWindow`、`SDL_Quit()` 收尾路径；因此“别人工作区不报错”不能据此推出 guest 程序无条件没问题，更可能是宿主环境、renderer 后端或 sanitizer 设置差异把同一份上游代码表现成了不同结果。
- 本工作区现要求：凡是 agent 直接落盘修改 NEMU 代码，都应在改动附近补充简短中文注释，说明“为什么这样改”和“改完带来的效果”；本次会话中已对 `inst.c`、`cpu-exec.c`、`device.c`、`watchpoint.*`、`vga.c` 等修改点补齐这类说明。
- `nemu/src/cpu/cpu-exec.c` 里的 `need_itrace_logbuf()` 与监视点快路径现在已重新对齐条件编译边界：`g_print_step` 被前移到 ITRACE 辅助函数之前，`watchpoint_enabled` 通过 `CONFIG_WATCHPOINT` 条件包含的 `watchpoint.h` 获得正式声明。这样在打开 `TRACE/DIFFTEST/WATCHPOINT` 时仍能保留之前的懒构造 logbuf 和零监视点快路径，不会再因为声明顺序或缺头文件而编译失败。
- `nemu/src/isa/riscv32/inst.c` 现已进一步把分层译码主体改成“X-macro 表项 + switch”形式：顶层仍按 `opcode` 做快速分流，但类内不再堆叠 if-else，而是把 `OP-IMM/LOAD/STORE/BRANCH` 写成 `funct3` 表项，把 `OP` 写成 `funct3/funct7` 组合 key 表项。这样后续查看或新增指令时，可以直接按表项横向比对，不需要在多层条件分支里来回跳。
- `nemu/src/isa/riscv32/inst.c` 现已去掉基于 `INSTPAT` 的线性穷举匹配，改为先按 `opcode` 做一级分流，再在各指令大类内按 `funct3/funct7` 细分；常见的 `OP-IMM/LOAD/STORE/OP/BRANCH` 被放在顶层快速路径，`JALR/JAL/LUI/AUIPC/SYSTEM` 放在后续分支。该改动保留了原有 `ftrace` 与 `INV/NEMUTRAP` 语义。
- 当前一组已验证的性能基线：在关闭 TRACE/DIFFTEST、保留 `CONFIG_CC_ASAN=y` 与 `CONFIG_RT_CHECK=y` 的情况下，`add-riscv32-nemu.bin` 经过分层译码重构后以 batch 模式运行得到约 `6.56 MIPS`（840 instructions / 128 us）；在重构前、同样配置下的先前基线约为 `2.35 MIPS`。
- 当前一组已验证的性能基线：在关闭 TRACE/DIFFTEST、保留 `CONFIG_CC_ASAN=y` 与 `CONFIG_RT_CHECK=y` 的情况下，`add-riscv32-nemu.bin` 以 batch 模式运行得到约 `2.35 MIPS`（840 instructions / 357 us）；后续若继续调优，可用这一点作为粗略对照。
- `nemu/src/cpu/cpu-exec.c` 的 ITRACE 路径已从“每条指令总是预取+反汇编”改成“仅在单步打印或当前确实会输出 trace 时才构建 logbuf”；这样在保留 ITRACE 编译开关的前提下，普通长跑阶段不再为无效日志准备付出每条指令的双重取指与反汇编成本。
- `nemu/src/device/device.c` 里的 `device_update()` 现在先按固定指令间隔做批量门控，再决定是否调用 `get_time()`；这避免了设备开启时每执行一条 guest 指令都向宿主查询一次时间，通常能明显降低系统调用或 vDSO 时间查询开销。
- `nemu/src/monitor/sdb/watchpoint.c` 维护 `watchpoint_enabled` 全局标志，`cpu-exec.c` 在零监视点场景下直接跳过 `compare_assert()`；虽然收益不如 ITRACE 和 device_update 大，但能去掉每条指令上的一层无效监视点检查。
- `nemu/src/isa/riscv32/inst.c` 的 RV32 译码热路径已做一次源代码级瘦身：把原先每条命中指令都要走的 `decode_operand()` + `switch(type)` 取值层改成 `INSTPAT_MATCH` 内按 `I/U/S/J/B/R/N` 直接展开字段提取，这样 J/U/N 等类型不再白白读取无关寄存器；同时在非 `CONFIG_RVE` 配置下，`R(i)` 直接访问 `cpu.gpr[i]`，绕过热路径里的 `check_reg_idx()` 断言开销。
- 排查 NEMU “运行很慢”时，优先先看 `.config` 是否同时开启 `CONFIG_CC_ASAN`、`CONFIG_ITRACE`、`CONFIG_DTRACE`、`CONFIG_FTRACE`、`CONFIG_DIFFTEST`、`CONFIG_RT_CHECK`；这些选项叠加时，性能损失通常明显大于单个 `inst.c` 里的取值开销。若目标是跑分或体感速度，应先关闭其中不需要的调试开关，再评估代码级优化效果。
- 在 `nemu/src/device/vga.c` 中，`vgactl_port_base` 是 VGA 控制寄存器块在 host 侧的后端内存指针。由于该块通过 `new_space(8)` 分配了 8 字节并按 `uint32_t *` 访问，所以 `vgactl_port_base[0]` 表示偏移 0 的宽高寄存器，`vgactl_port_base[1]` 表示偏移 4 的 sync 寄存器，也就是 guest 看到的 `VGACTL_ADDR + 4`。
- `nemu/src/device/vga.c` 中的 `vga_update_screen()` 已补全 sync 提交流程：当 `vgactl_port_base[1]` 非零时调用 `update_screen()`，随后将该 sync 寄存器清零；这样 guest 通过 `VGACTL_ADDR + 4` 发出的刷新请求现在能被 NEMU 主循环消费。该修改已通过 `make -C nemu -j4` 构建验证。
- VGA 设备由两部分组成：`vgactl` 控制寄存器区和 `vmem` 帧缓冲区。`vgactl[0]` 打包保存宽高，`vgactl[1]` 充当 sync 标志；guest 往 `CONFIG_FB_ADDR` 对应的 `vmem` 写像素后，再向 `VGACTL_ADDR + 4` 写非零触发刷新请求。NEMU 主循环中的 `device_update()` 会周期调用 `vga_update_screen()`，检测到 sync 后才执行真正的 `update_screen()` 并清零 sync，这样把“写显存”和“提交一帧”分离开来。
- 处理 NEMU/SDB 调试任务时，应默认优先使用 `--batch`、日志、trace、watchpoint、表达式求值、专用测试程序和必要的临时代码插桩等非交互路径；当前工具无法可靠向已启动的前台 readline monitor 持续注入 stdin，不应把这类交互默认转嫁给用户手动完成。
- 已验证 NEMU monitor 可在启动时通过 stdin 预置命令自动执行 `c`；因此对“从 `(nemu)` 继续运行”这类场景，agent 应自行用预置 stdin、`-b` 或 make 的 `c` 目标推进，而不是等待用户键入。
- 在当前工作区，用户允许 agent 在确有必要时直接承担 shell/monitor 交互测试；因此不要把所有 NEMU 任务都硬改成纯 batch，只要当前工具支持，就应结合终端输出直接执行必要的交互步骤。
- 需要区分宿主终端交互与 guest 设备输入：NEMU 的 SDL/设备键盘路径服务于模拟机内部 i8042/AM INPUT_KEYBRD 语义，不能用“已经能在 shell 里输入字符”替代，因为 shell/stdin 不提供统一的按键事件语义。
- keyboard.c 与 am/include/amdev.h 的协同点在于 ABI 对齐而非头文件直接包含：非 CONFIG_TARGET_AM 路径中本地定义的 NEMU_KEYS 列表顺序与 AM_KEYS 保持一致，因此生成的 NEMU_KEY_* 数值可直接作为 AM 风格键码返回给 guest；CONFIG_TARGET_AM 路径则直接使用 AM_INPUT_KEYBRD_T 与 io_read(AM_INPUT_KEYBRD)。
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
- 这类“配置层排除了某模块，但源码层仍引用其符号”的问题，最好双保险处理：一层放在 Kconfig 里禁止不合法组合出现，另一层放在使用点的 `#if` 条件里保证即使配置文件或对象文件残留异常，也不会把错误符号带进最终链接。
- `ARCH=riscv32-nemu` 的 AM 目标和普通 native 目标不是同一组源文件：前者会在 `src/filelist.mk` 里排除 `src/monitor/sdb`，所以分析 `watchpoint_enabled` / `compare_assert` 这类链接错误时，不能只看 `.config` 是否关闭了 `CONFIG_WATCHPOINT`，还要检查 `build/riscv32-nemu/src/cpu/cpu-exec.o` 是否残留了旧的监视点引用，以及对应实现是否根本未参与该目标的链接。
- 若 ITRACE 的 logbuf 构建逻辑写在 `exec_once()` 且无条件执行，即使最终没有输出任何 trace，也会为每条指令额外做一次原始取指和一次反汇编；这类“为了调试兜底而默认常开”的路径很容易成为解释器热点。
- 设备刷新若在每条指令后都先调用 `get_time()` 再判断是否到达 60Hz，会把宿主时间查询本身变成性能瓶颈；先按若干条 guest 指令分批检查，再进入时间门控，通常更划算。
- 当前 `.config` 若同时打开 `ASAN + ITRACE + DTRACE + FTRACE + DIFFTEST + RT_CHECK`，NEMU 即使功能正确也会明显变慢；此时若只盯着 `inst.c` 微优化，很容易误判瓶颈位置。
- NEMU 的 SDL 键盘事件以“窗口焦点”为前提：即便窗口内容还是黑的，只要 SDL 窗口存在，就必须先把鼠标点到该窗口或让其获得焦点，宿主按键才会进入 `SDL_PollEvent` 路径；否则字符只会进入终端 stdin。
- 若 `readkey test` 已打印 `Try to press any key...` 但按键后没有 `Got (kbd)` 输出，先检查输入焦点是否在 NEMU 的 SDL 窗口上。若按下字母后字符直接回显在终端，说明按键进入的是 monitor/pty 的 stdin，而不是 SDL 事件队列；此时应优先判断焦点问题，而不是先怀疑 AM 平台层拆包代码。
- `am-kernels/tests/am-tests` 的 `readkey test` 需要同时满足两点才会表现正确：一是通过 `mainargs=k` 进入 keyboard_test，二是避免把普通 `run` 停在 NEMU monitor；若想直接启动程序应用层，应优先使用带 `-b` 的 `c` 目标。即便如此，keyboard_test 仍会无限轮询等待键盘事件，不会自行退出。
- 当前宿主环境未发现 `xdotool`、`ydotool`、`wtype`、`xte` 等桌面输入自动化工具；因此 agent 目前可以自动处理 monitor 命令，但不能直接向 SDL 窗口注入宿主键盘事件，遇到真实键盘测试时应优先选择代码侧/设备侧的可回退合成输入方案。
- 若任务需要 SDB monitor 或 SDL 键盘窗口交互，先检查是否能用 `--batch`、watchpoint、trace、日志或测试程序替代；当前 agent 工具不支持对已运行的前台 NEMU monitor 持续喂 stdin，直接启动交互式调试后往往无法在不中断会话的情况下继续自动操作。
- `nemu/.config` 若开启 `CONFIG_CC_ASAN=y` 且 `CONFIG_VGA_SHOW_SCREEN=y`，运行 AM/FCEUX 这类会打开窗口的程序时，退出后可能在 `src/device/vga.c` 的 SDL 创建路径上看到 LeakSanitizer 报告；这通常是 NEMU 宿主侧 SDL/Mesa 资源未显式销毁加上宿主图形库清理时机导致的噪音，不是 guest 程序本身的逻辑错误。
