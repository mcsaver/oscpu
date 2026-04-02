# Abstract Machine 模块笔记

## 当前状态
<!-- 已实现的 API (TRM/IOE/CTE/VME/MPE) -->
- AM on NEMU 的 keyboard 映射不是 ASCII，而是“同名物理键枚举”映射：`abstract-machine/am/include/amdev.h` 用 `AM_KEYS` 生成 `AM_KEY_*` 顺序枚举，platform/nemu 的 `__am_input_keybrd` 只把 `KBD_ADDR` 中的 bit15 拆成 `keydown`、把低位原样作为 `keycode` 返回；NEMU 宿主侧 `src/device/keyboard.c` 用 `keymap[SDL_SCANCODE_x] = NEMU_KEY_x` 做一一对应，并依赖 `NEMU_KEYS` 与 `AM_KEYS` 顺序一致，使 `SDL_SCANCODE_A -> AM_KEY_A`、`SDL_SCANCODE_RETURN -> AM_KEY_RETURN`、方向键对应 `AM_KEY_UP/DOWN/LEFT/RIGHT`。判断按键时应优先比较 `AM_KEY_*` 宏，不要写死数字，也不要把 `keycode` 当 ASCII 字符处理。
- 在 `__am_gpu_fbdraw` 中，目标 framebuffer 索引与源像素索引的“每行步长”不同：目标端用 `screen_w`（屏幕总宽）计算 `fb[(y + row) * screen_w + (x + col)]`，源端用 `w_reg`（图块宽度）计算 `data[row * w_reg + col]`。若把目标端也写成 `w_reg`，只有在整屏绘制时才偶然正确，普通子矩形绘制会写错行偏移。
- 对 platform/nemu 的 GPU 绘制路径，可把 `ctl->pixels` 理解为“源图块”，把 `FB_ADDR` 理解为“目标屏幕显存基址”。前者由调用 `io_write(AM_GPU_FBDRAW, x, y, pixels, w, h, sync)` 时传入，后者是平台固定映射的 framebuffer 地址；实现时本质是在做一次从源缓冲区到目标显存的矩形拷贝。
- `abstract-machine/am/src/platform/nemu/ioe/gpu.c` 中 `__am_gpu_fbdraw` 已落盘实现基础 framebuffer copy：当 `ctl->pixels` 非空且 `w/h > 0` 时，会把源像素块按 `(x, y)` 偏移写入 `FB_ADDR` 指向的 framebuffer；`sync` 仍通过向 `VGACTL_ADDR + 4` 写 1 请求 NEMU 提交一帧。该修改已通过 `am-kernels/tests/am-tests` 的 `ARCH=riscv32-nemu` 构建验证。
- `AM_GPU_FBDRAW_T` 中的 `pixels` 是源像素块首地址，也就是调用 `io_write(AM_GPU_FBDRAW, x, y, pixels, w, h, sync)` 时传入的那块内存起始指针；通常可按 `uint32_t *` 解释为按行连续的 `w x h` 像素数组。它不是目标 framebuffer 基址，目标 framebuffer 在 platform/nemu 下由 `FB_ADDR` 表示。
- `FB_ADDR` 是 framebuffer 像素区起始地址，不承载 `x/y/w/h` 这类控制参数；在 platform/nemu 中，`x/y/w/h` 只用于计算显存偏移与拷贝范围。若直接 `outl(FB_ADDR, ctl->x)`、`outl(FB_ADDR + 4, ctl->y)`，效果只是把 `x` 和 `y` 写成前两个像素值。
- 需要区分 AM 抽象寄存器编号和平台底层 MMIO 地址：`AM_GPU_FBDRAW` 在 `am/include/amdev.h` 中只是寄存器 ID 11，供 `io_write(AM_GPU_FBDRAW, ...)` 通过 `ioe_write()` 分发到 `__am_gpu_fbdraw`；它不对应 `VGACTL_ADDR + 8`。在 platform/nemu 下，GPU 相关的底层地址是 `VGACTL_ADDR`、`VGACTL_ADDR + 4` 和 `FB_ADDR`。
- `AM_GPU_FBDRAW_T` 中 `x/y` 表示把像素块画到目标 framebuffer 的左上角坐标，`w/h` 表示待绘制矩形的宽高，单位都是像素；`pixels` 则是源像素块首地址，通常按行连续存放。可把它理解成“把一个 `w x h` 的小图拷贝到屏幕上从 `(x, y)` 开始的位置”。
- `abstract-machine/am/src/platform/nemu/ioe/gpu.c` 里的 `__am_gpu_fbdraw` 目前只是“部分实现”：它已支持 `ctl->sync` 时向 `VGACTL_ADDR + 4` 写 1 触发提交请求，但还没有利用 `ctl->pixels/x/y/w/h` 把像素块写入 `FB_ADDR`。因此它实现了 sync 通知语义，还没有实现完整的 framebuffer draw 语义。
- `AM_GPU_CONFIG_T` 的 `present`、`has_accel`、`vmemsz` 字段定义在 `am/include/amdev.h` 的 `AM_DEVREG(9, GPU_CONFIG, ...)` 展开结果中；当前 platform/nemu 的 `__am_gpu_config` 返回 `present=true`、`has_accel=false`、`vmemsz=0`。可把它理解为“GPU 是否存在、是否支持加速特性、是否显式报告显存容量”。
- `abstract-machine/am/src/platform/nemu/ioe/gpu.c` 中的 `__am_gpu_config` 已落盘实现 `VGACTL_ADDR` 宽高寄存器解析，不再返回 0x0 的占位分辨率；当前仍待补的是 `__am_gpu_fbdraw` 的 framebuffer 像素复制与 NEMU 侧 `vga_update_screen()` 的 sync 提交逻辑。
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

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- klib/src/stdio.c 当前的 kvsnprintf 只实现了 `%d`、`%s`、`%c`、`%%` 四类格式；遇到 `%02d` 这类带宽度/补零标志的格式会走未知格式分支，导致格式串被近似原样输出。
