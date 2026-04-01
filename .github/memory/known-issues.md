# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

## 活跃问题
<!-- 当前未解决的问题 -->

### [3] NEMU 开启 ASan 且显示 VGA 窗口时，退出后被 LSan 判定 SDL/Mesa 泄漏
- **模块**: NEMU / FCEUX-AM
- **现象**: 执行 `make ARCH=riscv32-nemu run` 结束后，LeakSanitizer 报告调用栈落在 `libGLX_mesa.so`、`libSDL2.so` 和 `nemu/src/device/vga.c:49` 的 direct/indirect leak，`make run` 以 Error 1 结束。
- **根因**: 当前 `nemu/.config` 开启了 `CONFIG_CC_ASAN=y`，同时 `CONFIG_VGA_SHOW_SCREEN=y` 会让 `init_screen()` 调用 `SDL_CreateWindowAndRenderer()` 和 `SDL_CreateTexture()`。NEMU 现有代码只创建 SDL 资源，没有在退出路径中显式执行 `SDL_DestroyTexture`、`SDL_DestroyRenderer`、`SDL_DestroyWindow` 和 `SDL_Quit`；LSan 会继续把宿主图形栈中的分配记为泄漏，其中一部分也可能来自 Mesa/GLX 自身的退出清理时机。
- **修复**: 若只想运行程序，可关闭 `CONFIG_CC_ASAN` 或用 `ASAN_OPTIONS=detect_leaks=0` 运行；若想彻底消除报告，需要给 NEMU 增加 SDL 资源销毁路径，并验证 Mesa/GLX 侧是否仍有宿主库噪音。
- **教训**: 这类泄漏报告首先要区分 guest 程序与宿主模拟器；调用栈停在 `nemu/src/device/vga.c` 及 SDL/GLX/Mesa 时，优先检查 NEMU 主机侧窗口资源和 sanitizer 配置，而不是先怀疑 NES ROM 或 AM 应用逻辑。

## 已解决问题
<!--
### [编号] 问题标题
- **模块**: 出问题的模块
- **现象**: 具体表现
- **根因**: 根本原因分析
- **修复**: 如何修复的
- **教训**: 从中学到了什么
-->

### [1] AM hello 访问串口地址触发 pmem 越界
- **模块**: NEMU / Abstract Machine
- **现象**: 运行 hello 时在 pc = 0x80000090 访问 0xa00003f8，报 address out of bound of pmem [0x80000000, 0x87ffffff]
- **根因**: AM 的 putch 会向 SERIAL_PORT 写字符；该地址位于 DEVICE_BASE = 0xa0000000 的设备区。若 nemu/.config 中 CONFIG_DEVICE 未开启，且未使用 AM 目标配置，paddr_read/paddr_write 不会转到 mmio_read/mmio_write，而是直接按普通物理内存越界处理。
- **修复**: 切回 riscv32-am_defconfig 或在 menuconfig 中重新开启 CONFIG_TARGET_AM 和 CONFIG_DEVICE 后重编 NEMU。
- **教训**: 跑 AM 程序前不要直接沿用普通 system 模式配置；先确认 NEMU 目标配置与镜像类型匹配。

### [2] fceux-am 在无 ROM 时编译失败并误以为“游戏未移植”
- **模块**: FCEUX-AM
- **现象**: 执行 `make ARCH=riscv32-nemu run mainargs=mario` 时，早期版本会在 `src/emufile.cpp` 报 `roms.h: No such file or directory`；修复后可构建运行，但会明确提示 `No embedded ROM found. Put a .nes file under nes/rom/ and rebuild.`。
- **根因**: `fceux-am/Makefile` 用 `ls` 枚举 `nes/rom/*.nes`；当目录为空时，`ROM_SRC` 为空导致 `rom` 规则不触发，`nes/gen/roms.h` 根本不会生成。与此同时，运行逻辑默认假设至少有一个 ROM 可供选择，容易把“缺 ROM 文件”误判成“超级玛丽没有移植好”。
- **修复**: 改为用 `wildcard`/`patsubst` 生成 ROM 列表，并让 FCEUX 源文件总依赖 `rom` 规则；`build-roms.py` 在零 ROM 时也生成占位 `roms.h`，`emufile.cpp` 在 `nroms <= 0` 时给出明确提示。
- **教训**: 对编译期资源生成链，不能把“输入为空”直接退化成“生成规则不执行”；否则错误会以缺头文件的形式在下游爆出来，定位成本很高。

## 调试技巧备忘
<!-- 在调试过程中发现的有用技巧 -->
