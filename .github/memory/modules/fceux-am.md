# FCEUX-AM 模块笔记

## 当前状态
- fceux-am 的 ROM 采用编译期内嵌方式：`nes/build-roms.py` 会把 `nes/rom/*.nes` 转成 `nes/gen/*.c` 和 `nes/gen/roms.h`，运行时通过 `mainargs` 在内置 ROM 表中选择游戏。
- `make ARCH=riscv32-nemu` 现在即使在 `nes/rom/` 目录没有任何 `.nes` 文件时也能完成构建；运行时会在 guest 中打印缺少 ROM 的明确提示，而不会再在编译期卡死在 `roms.h` 缺失。
- 对超级玛丽这类 ROM，源码侧不需要额外“移植逻辑”；只要把合法取得的 `mario.nes` 放入 `fceux-am/nes/rom/`，再执行 `make ARCH=riscv32-nemu run mainargs=mario` 即可走通现有入口。

## 踩坑记录
- 旧版 `fceux-am/Makefile` 用 `ls $(ROM_PATH)/rom/*.nes` 生成 `ROMS`，当目录为空时 `ROM_SRC` 为空，`rom` 规则不会触发，最终 `src/emufile.cpp` 在编译期因为找不到 `roms.h` 失败。
- 没有 ROM 时，当前 `make ... run` 末尾仍可能看到 LeakSanitizer 噪音；调用栈落在 NEMU 主机侧的 `src/device/vga.c:49` 和 SDL/GLX/Mesa 初始化链路，这不是 fceux-am 超级玛丽入口本身的阻塞点。
- 从 Windows 复制 ROM 到 WSL 时，目录里可能出现 `xxx.nes:Zone.Identifier` 这类附带文件；它们不是真正 ROM，可直接在 `fceux-am/nes/rom/` 下清理。