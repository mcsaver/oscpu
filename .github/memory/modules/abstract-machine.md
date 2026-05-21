# Abstract Machine 模块笔记

## 当前状态
<!-- 已实现的 API (TRM/IOE/CTE/VME/MPE) -->
- 2026-05-20: `riscv32-npc` benchmark 镜像可能因为历史构建缓存继续保留旧 ISA attribute；本轮 CoreMark 就出现过 `abstract-machine/scripts/riscv32-npc.mk` 已经是 `rv32imc_zicsr_zifencei_zba_zbb_zbc_zbs`，但 `am-kernels/benchmarks/coremark/build/riscv32-npc/src/core_matrix.o` 仍是旧 `rv32i_zicsr`，导致矩阵乘法调用 `__mulsi3` 软件乘法。处理这类性能异常时，优先执行 `make -C am-kernels/benchmarks/coremark ARCH=riscv32-npc -B image` 或清理对应 build 目录，再用 `readelf -A`/`objdump` 确认实际 ELF 与预期 ISA 一致。
- 2026-05-19: `riscv32-npc` 的 guest 编译参数已从 `rv32i_zicsr` 扩展为 `rv32imc_zicsr_zifencei_zba_zbb_zbc_zbs`，用于驱动 NPC 本轮新增的 RV32M、RV32C、bitmanip 与 `fence.i` 路径。新增 cpu-tests `bitmanip/compressed/fence-i` 已随 AM 构建并在 NPC/NEMU difftest 下通过；全量 `cpu-tests` 38/38 PASS。后续若临时关闭 NPC 某个扩展，必须同步调整 `abstract-machine/scripts/riscv32-npc.mk`，否则 guest 可能生成目标核尚不支持的指令。
- 2026-05-19: `riscv32-npc` 的 AM CTE 已对齐 NEMU 平台的最小语义：`cte_init()` 写 `mtvec=__am_asm_trap`；`__am_irq_handle()` 将 M-mode ecall 映射为 `EVENT_YIELD/EVENT_SYSCALL` 并推进 `mepc += 4`，识别 timer/external interrupt cause；`kcontext()` 在任务栈顶构造初始 `Context`，设置 `mepc=entry`、`a0=arg`、M-mode `mstatus` 与返回即 panic 的 `ra`；`ienabled()/iset()` 读写 `mstatus.MIE`。`trap.S` 在 handler 返回后切换到返回的 `Context *` 再恢复寄存器，因此 `yield-os` 已能在 NPC 上持续输出 `ABAB...`。
- 2026-05-19: `riscv32-nemu` / `riscv32e-nemu` 的 guest 编译参数已接入 NEMU Kconfig：新增 `scripts/isa/riscv-nemu-ext.mk` 读取 `$(NEMU_HOME)/include/config/auto.conf`，按 `RISCV_EXT_M/C/B` 拼接 `-march=rv32{e,i}{m}{c}_zicsr[_zba_zbb_zbc_zbs]` 与对应 `-mabi`；`auto.conf` 被加入 AM 编译规则的 `EXTRA_DEPS`，所以 menuconfig 改扩展后会触发 guest 对象重编。NEMU 平台还复用了现有 `riscv/npc/libgcc` 乘除法例程，使关闭 M 后的 `rv32i_zicsr` 程序仍可链接并运行。
- 2026-05-19: `riscv32-nemu` 的 AM CTE 已补齐最小内核上下文切换能力：`kcontext()` 在 16 字节对齐后的任务栈顶构造 `Context`，通过 `mepc` 让第一次 `mret` 直接进入 `entry(arg)`，并设置 `ra` 为返回即 panic 的兜底；`trap.S` 的 `CONTEXT_SIZE` 已包含 `Context.pdir` 槽位，且会使用 `__am_irq_handle()` 返回的 `Context *` 作为新的 `sp` 再恢复现场。`yield-os` 在 NEMU 上已能输出交替 `ABAB...`，说明两个 PCB 的协作式切换生效。
- 2026-05-19: 清理本模块记忆中的过时 GPU/klib 叙述：当前 `platform/nemu` 已注册并实现 `AM_GPU_MEMCPY/AM_GPU_RENDER`，`GPU_CONFIG` 会报告 `has_accel=true` 与 512KB 软显存；`klib` 的 `kvsnprintf()` 也已支持常用整数格式、宽度和补零。后续排查同类问题时应以这些当前状态为基准，不再引用早期“只支持 sync/缺高级 GPU/printf 只支持窄子集”的旧描述。
- 2026-04-23: `abstract-machine/am/src/riscv/riscv.h` 已补 `MSTATUS_MIE` 位定义，匹配 `riscv/nemu/cte.c::ienabled()/iset()` 中对机器态全局中断开关的读写；此前 AM CTE 编译会因 `MSTATUS_MIE` 未定义失败。配合 NEMU `SYSTEM` 指令补全后，`timeout 3s make -C am-kernels/tests/am-tests ARCH=riscv32-nemu c mainargs=i` 已能进入 `Hello, AM World` 并连续输出 `y`，说明 `yield()` 的 `ecall -> trap.S -> __am_irq_handle -> mret` 闭环可用。
- 2026-04-16: `riscv32-npc` 的 `ioe.c` 新增 `AM_AUDIO_CONFIG` 空桩（`present=false, bufsize=0`），避免上层程序（如 fceux-am 在 `PERF_MIDDLE/SOUND_LQ` 下）查询音频设备时触发 `access nonexist register` panic。后续若在 NPC 上实现真正的音频设备，需要把这个空桩替换为真实实现，并同时注册 `AM_AUDIO_CTRL`、`AM_AUDIO_STATUS`、`AM_AUDIO_PLAY`。改动文件：`abstract-machine/am/src/riscv/npc/ioe.c`。
- 2026-04-14: `platform/nemu` 与 `riscv32-npc` 现在都已经补齐高级 GPU ABI：`AM_GPU_MEMCPY` 会先把 canvas/texture 数据拷进一块 512KB 的 GPU 软显存，`AM_GPU_RENDER` 再按根节点把树形画布渲染到最终 framebuffer。实测 NEMU 上的 `am-tests mainargs=d` 已经可以完整跑到 `Test End!`，不再在 VGA 阶段报 `access nonexist register`。
- 2026-04-14: 这轮高级 GPU 补全采用共享软件渲染层 `am/src/platform/gpu_soft.h`，而不是在 NEMU/NPC 两个平台里各自复制一套 canvas/tree 解释逻辑；这样 `GPU_MEMCPY/GPU_RENDER` 的语义只维护一份，平台文件只保留“如何把最终像素写到各自 framebuffer”这层差异。
- 2026-04-14: `riscv32-npc` 现已补齐基础 GPU IOE：新增 `am/src/riscv/npc/gpu.c`，在 `ioe.c` 中注册 `AM_GPU_CONFIG/AM_GPU_STATUS/AM_GPU_FBDRAW`，并在 `npc.h` 中补上 `VGACTL_ADDR/FB_ADDR`。当前 `am-tests mainargs=v` 已能推进到 `__am_gpu_fbdraw` 的矩形拷贝循环，`mainargs=k` 也已继续通过 NPC 键盘设备看到 `A DOWN/UP`。
- 2026-04-14: `riscv32-npc` 的 `__am_gpu_init()` 现在不再在 guest 侧逐像素清 400x300 全屏，而是复用 NPC 宿主 `VgaDevice::Init()` 已预清零的 framebuffer，只做一次 sync；这样 AM 带 IOE 的程序不会再在 GPU 初始化阶段先耗掉几十万次 store。
- 2026-04-14: `abstract-machine/klib/src/stdio.c` 现已补齐常用整数格式化能力，支持 `d/i/u/x/X/p`、`l/ll` 长度修饰、字段宽度和前导 `0`；CoreMark 的 CRC、`devscan` 的 `%08x` 以及 AM 侧指针打印不再退化成把 `%x/%p` 原样输出。
- 2026-04-13: `abstract-machine/klib` 的 `stdlib` 已补齐当前工程最常用的一组能力：非 native 平台上的 `malloc/free/calloc/realloc` 改为基于 `heap` 区间的可回收空闲链表分配器，`atoi/atol/strtol/strtoul/labs` 现已支持前导空白、符号、自动进制识别、`0x` 前缀和溢出饱和；已通过 `klib-tests` 的 `klib_stdlib/klib_ro/klib_fmt/klib_rw` 批处理回归。
- 2026-04-13: `abstract-machine` 的 `riscv32-npc` 输入与运行桥接已补齐到可回归状态：`am/src/riscv/npc/input.c` 现在会直接读取 `KBD_ADDR` 并按 bit15/低位拆出 `keydown/keycode`，`scripts/platform/npc.mk` 新增 `NPC_RUN_ARGS` 透传，因此 AM 侧可以不改程序就直接给 NPC 打开 `--trace`、`--trace-file`、`--max-cycles`、`--stdin-kbd` 等运行参数。
- 2026-04-13: `abstract-machine` 现已补出一条可直接对接 `npc/single` 的最小 NPC 路径：新增 `scripts/riscv32-npc.mk`，`scripts/platform/npc.mk` 的 `run` 入口会直接调用 `npc/single` 的仿真器；同时 `am/src/riscv/npc/trm.c` 已改为向 `SERIAL_PORT(0xa00003f8)` 输出字符、通过 `ebreak + a0` 结束程序，`timer.c` 则改为从 `RTC_ADDR(0xa0000048)` 读取 uptime/rtc。
- 在当前工作区的 CPU 敏捷开发闭环里，AM 更适合被理解为“软件/测试与底层平台之间的抽象契约”：上层 am-kernels 和应用只依赖 AM API，不直接依赖 NEMU 或 RTL 细节；同一套程序可以先跑在 NEMU 参考平台上确认语义，再迁移到未来的 NPC/RTL 目标平台上复用，减少测试环境切换成本。
- AM 不负责给出“CPU 是否实现正确”的参考答案，它负责统一程序入口、设备语义和平台接口；真正的参考正确性通常由 NEMU 这类参考模型提供，而 RTL 仿真负责验证目标实现是否符合这份参考，综合/STA 则继续验证 RTL 是否能落成硬件与满足时序。
- AM on NEMU 的 keyboard 映射不是 ASCII，而是“同名物理键枚举”映射：`abstract-machine/am/include/amdev.h` 用 `AM_KEYS` 生成 `AM_KEY_*` 顺序枚举，platform/nemu 的 `__am_input_keybrd` 只把 `KBD_ADDR` 中的 bit15 拆成 `keydown`、把低位原样作为 `keycode` 返回；NEMU 宿主侧 `src/device/keyboard.c` 用 `keymap[SDL_SCANCODE_x] = NEMU_KEY_x` 做一一对应，并依赖 `NEMU_KEYS` 与 `AM_KEYS` 顺序一致，使 `SDL_SCANCODE_A -> AM_KEY_A`、`SDL_SCANCODE_RETURN -> AM_KEY_RETURN`、方向键对应 `AM_KEY_UP/DOWN/LEFT/RIGHT`。判断按键时应优先比较 `AM_KEY_*` 宏，不要写死数字，也不要把 `keycode` 当 ASCII 字符处理。
- `riscv32-npc` 现阶段也应沿用同一套 NEMU/AM 键盘 ABI，而不是单独发明一套 ASCII 或 host-only 输入语义；这样 `am-tests`、后续小游戏和更复杂应用可以在 `riscv32-nemu` 与 `riscv32-npc` 之间尽量复用输入处理逻辑。
- 在 `__am_gpu_fbdraw` 中，目标 framebuffer 索引与源像素索引的“每行步长”不同：目标端用 `screen_w`（屏幕总宽）计算 `fb[(y + row) * screen_w + (x + col)]`，源端用 `w_reg`（图块宽度）计算 `data[row * w_reg + col]`。若把目标端也写成 `w_reg`，只有在整屏绘制时才偶然正确，普通子矩形绘制会写错行偏移。
- 对 platform/nemu 的 GPU 绘制路径，可把 `ctl->pixels` 理解为“源图块”，把 `FB_ADDR` 理解为“目标屏幕显存基址”。前者由调用 `io_write(AM_GPU_FBDRAW, x, y, pixels, w, h, sync)` 时传入，后者是平台固定映射的 framebuffer 地址；实现时本质是在做一次从源缓冲区到目标显存的矩形拷贝。
- `abstract-machine/am/src/platform/nemu/ioe/gpu.c` 中 `__am_gpu_fbdraw` 已落盘实现基础 framebuffer copy：当 `ctl->pixels` 非空且 `w/h > 0` 时，会把源像素块按 `(x, y)` 偏移写入 `FB_ADDR` 指向的 framebuffer；`sync` 仍通过向 `VGACTL_ADDR + 4` 写 1 请求 NEMU 提交一帧。该修改已通过 `am-kernels/tests/am-tests` 的 `ARCH=riscv32-nemu` 构建验证。
- `AM_GPU_FBDRAW_T` 中的 `pixels` 是源像素块首地址，也就是调用 `io_write(AM_GPU_FBDRAW, x, y, pixels, w, h, sync)` 时传入的那块内存起始指针；通常可按 `uint32_t *` 解释为按行连续的 `w x h` 像素数组。它不是目标 framebuffer 基址，目标 framebuffer 在 platform/nemu 下由 `FB_ADDR` 表示。
- `FB_ADDR` 是 framebuffer 像素区起始地址，不承载 `x/y/w/h` 这类控制参数；在 platform/nemu 中，`x/y/w/h` 只用于计算显存偏移与拷贝范围。若直接 `outl(FB_ADDR, ctl->x)`、`outl(FB_ADDR + 4, ctl->y)`，效果只是把 `x` 和 `y` 写成前两个像素值。
- 需要区分 AM 抽象寄存器编号和平台底层 MMIO 地址：`AM_GPU_FBDRAW` 在 `am/include/amdev.h` 中只是寄存器 ID 11，供 `io_write(AM_GPU_FBDRAW, ...)` 通过 `ioe_write()` 分发到 `__am_gpu_fbdraw`；它不对应 `VGACTL_ADDR + 8`。在 platform/nemu 下，GPU 相关的底层地址是 `VGACTL_ADDR`、`VGACTL_ADDR + 4` 和 `FB_ADDR`。
- `AM_GPU_FBDRAW_T` 中 `x/y` 表示把像素块画到目标 framebuffer 的左上角坐标，`w/h` 表示待绘制矩形的宽高，单位都是像素；`pixels` 则是源像素块首地址，通常按行连续存放。可把它理解成“把一个 `w x h` 的小图拷贝到屏幕上从 `(x, y)` 开始的位置”。
- `abstract-machine/am/src/platform/nemu/ioe/gpu.c` 里的 `__am_gpu_fbdraw` 早期只实现过 sync 通知，这个旧状态已在后续补齐：当前它会把 `ctl->pixels/x/y/w/h` 对应的源像素块写入 `FB_ADDR`，再按 `sync` 请求提交；树形 canvas 渲染则由 `AM_GPU_MEMCPY/AM_GPU_RENDER` 走共享软件渲染层。
- `AM_GPU_CONFIG_T` 的 `present`、`has_accel`、`vmemsz` 字段定义在 `am/include/amdev.h` 的 `AM_DEVREG(9, GPU_CONFIG, ...)` 展开结果中；当前 platform/nemu 的 `__am_gpu_config` 会在 VGA 存在时返回 `present=true`、`has_accel=true`、`vmemsz=AM_GPU_SOFT_VMEM_SIZE`。可把它理解为“GPU 是否存在、是否支持高级 canvas/render ABI、是否显式报告软显存容量”。
- `abstract-machine/am/src/platform/nemu/ioe/gpu.c` 中的 `__am_gpu_config` 已落盘实现 `VGACTL_ADDR` 宽高寄存器解析，`__am_gpu_fbdraw` 已负责 framebuffer 像素复制，NEMU 侧 `vga_update_screen()` 也已能消费 sync 提交；当前 NEMU devscan 的高级 GPU ABI 缺口已关闭。
- `VGACTL_ADDR` 的第一个 32 位寄存器按“高 16 位宽度、低 16 位高度”编码；AM 侧实现 `GPU_CONFIG` 时应先 `uint32_t reg = inl(VGACTL_ADDR)`，再用 `reg >> 16` 和 `reg & 0xffff` 拆出 width/height。
- 完成 IOE(3) 的 NEMU GPU 路径时要把三个层次分开：`GPU_CONFIG` 负责从 `VGACTL_ADDR` 读回真实宽高，`GPU_FBDRAW` 负责把像素块写到 `FB_ADDR` 对应的帧缓冲区域，而 `sync` 只负责通知 NEMU 提交这一帧。若只写 sync 而不复制像素，窗口会刷新但内容仍是旧帧/黑屏。
- 在 AM/NEMU 输入模型里，`io_read(AM_INPUT_KEYBRD)` 是“事件流”接口而不是“当前全键盘状态”接口：一次读取最多得到 1 个按下/松开事件。若应用需要检测多个键同时按下，必须在应用层循环 drain 事件，并维护 `key_state[keycode] = keydown` 这类状态表，再按帧检查多个键是否同时为真；`am-kernels/kernels/litenes/src/psg.c` 已按此模式实现，`snake` 中只取首个 keydown 的 `read_key()` 则只适合单键控制。
- am-tests 的 keyboard_test 不是一次性通过/失败测试，而是交互式轮询程序：进入后会一直执行 `while (1) drain_keys();`，只有读到键盘事件才打印结果，因此在无按键输入时表现为持续运行而非自行结束。
- C 里需要明确区分 `&` 和 `&&`：前者按位与、后者逻辑与；处理键盘事件寄存器这类整数编码时应使用按位与，不能用逻辑与代替。
- 位运算拆分键盘事件时要区分两种掩码用法：`ev & KEYDOWN_MASK` 检查 bit15 是否置位，`ev & ~KEYDOWN_MASK` 清除 bit15 后留下 keycode；把后者赋给 bool 会把“只要 keycode 非零”误当成按下。
- 实现 __am_input_keybrd 时，读取 KBD_ADDR 后应在本地临时变量上用位运算拆分 keydown/keycode；不要把 `uint32_t` 当数组下标访问，也不要在一次函数调用里多次读取同一键盘寄存器。
- 对于 platform/nemu 输入层，获取真实键盘事件的正确方式是读取 nemu.h 中的 KBD_ADDR，而不是直接依赖宿主 shell；推荐在 __am_input_keybrd 中使用 inl(KBD_ADDR)，再把 bit15 解释为 keydown、低位解释为 keycode。
- AM_INPUT_KEYBRD_T 中的 keycode 仅表示“是哪一个键”，其值来自 am/include/amdev.h 里的 AM_KEY_* 枚举；按下/松开语义由独立的 keydown 字段承载，两者不要混淆。
- 在 riscv32-nemu 场景中，__am_input_keybrd 运行于 guest AM 程序内部；宿主键盘事件不会直接调用它，而是先进入 NEMU 宿主侧 keyboard.c 队列，待 guest 侧执行 io_read(AM_INPUT_KEYBRD) 时再同步读出。
- am/include/amdev.h 的 AM_KEYS + AM_KEY_NAMES 组合采用 X-macro 生成 AM_KEY_* 连续枚举，AM_KEY_NONE 固定为 0，后续键码按列表顺序自增，便于跨平台保持一致的 keycode 编号。
- platform/nemu/ioe/input.c 中的 __am_input_keybrd 由上层执行 io_read(AM_INPUT_KEYBRD) 时经 ioe_read 分发表同步调用，属于轮询式设备读取，不会因宿主键盘事件自动异步触发。
- AM 的 INPUT_KEYBRD 语义是目标机内部键盘设备，而不是宿主 shell/stdin 的别名；前者提供 keydown/keycode 事件，后者通常只是字符流，适用场景不同。
- am/include/amdev.h 中 AM_DEVREG(8, INPUT_KEYBRD, RD, bool keydown; int keycode) 为键盘事件定义了稳定的数据布局，AM_KEYS 列表定义了跨平台统一键码编号；NEMU 的 keyboard.c 依赖这套约定，把宿主键盘事件转换成与 AM 兼容的键值流。
- klib-macros.h 提供地址对齐、数组长度、区间构造、字符串化、拼接、IO 设备读写、静态断言与 panic 封装，广泛依赖 GNU statement expression 扩展。
- io_read/io_write 通过 am/include/amdev.h 中 AM_DEVREG 生成的 `AM_xxx_T` 类型包装 `ioe_read/ioe_write`。
- panic_on 最终走 putstr/putch 输出错误，再调用 halt(1) 终止；不同平台的 putch/halt 在各自 trm.c 中实现。
- hello 等 AM 程序的 mainargs 在不同平台采用不同传递方式：nemu/npc 在 trm.c 中放置 MAINARGS_PLACEHOLDER 静态字符串，链接后由 tools/insert-arg.py 直接回写到镜像；native 则在 constructor 中通过 getenv("mainargs") 读取宿主环境变量，再手动调用用户 main。

## klib 实现进度
<!-- 已实现的标准库函数 -->
- 2026-04-13: `stdlib` 现已提供 `rand/srand/abs/labs/atoi/atol/strtol/strtoul/malloc/free/calloc/realloc`。其中 native 目标继续复用宿主 libc 的分配器，避免在宿主可执行文件里导出自定义 `malloc/free` 干扰启动路径；非 native 目标再接入 klib 自己的可回收堆管理。

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- 2026-05-19: AM CTE 的 `__am_irq_handle()` 返回值不是装饰性接口；调度器可以返回另一个 `Context *`。trap.S 若调用 handler 后继续用旧 `sp` 恢复现场，`kcontext()` 即使构造正确也不会真正切任务。NEMU/NPC 的 RISC-V trap.S 都应在恢复 GPR/CSR 前执行 `mv sp, a0`。
- 2026-04-14: 之前那条“`kvsnprintf()` 只实现 `%d/%s/%c/%%`”的限制已经修复；后续若还要扩 `printf`，优先在统一整数输出路径上加能力，并同步补 `klib_fmt` 回归，不要再针对某一个 benchmark 单独修打印语句。
- `klib` 自己实现分配器时，不能把“堆是否初始化完成”和“当前空闲链表是否非空”混为一谈；否则堆已初始化但所有块都暂时被占用时，后续 `free/realloc` 会误判成“堆尚未初始化”。
- `klib/src/stdio.c` 当前的 `kvsnprintf()` 已支持 `d/i/u/x/X/p`、`l/ll`、字段宽度和前导 `0`；若后续再遇到格式串原样输出，优先检查是否使用了尚未实现的新格式，而不是沿用早期“只支持 `%d/%s/%c/%%`”的旧判断。
