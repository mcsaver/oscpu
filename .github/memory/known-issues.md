# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

## 活跃问题
<!-- 当前未解决的问题 -->

- 原 [3] 已在当前宿主环境中通过重装 SDL/Mesa 运行库暂时解除，见下方“已解决问题”。

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

### [4] cpu-exec 优化后在 TRACE/DIFFTEST/WATCHPOINT 全开时编译失败
- **模块**: NEMU / CPU Exec
- **现象**: 打开 `CONFIG_ITRACE`、`CONFIG_DIFFTEST`、`CONFIG_WATCHPOINT` 后，`cpu-exec.c` 编译报 `g_print_step undeclared`、`watchpoint_enabled undeclared`，并连带触发 `need_itrace_logbuf()` 的 `return-type` 警告。
- **根因**: 优化时新增的 `need_itrace_logbuf()` 放在 `g_print_step` 定义之前，C 编译器不会为后面的文件作用域变量做提前声明；同时 `cpu-exec.c` 直接使用了 `watchpoint_enabled` 快路径，却没有在该编译单元中包含声明它的 `watchpoint.h`。
- **修复**: 将 `g_print_step` 前移到 ITRACE 辅助函数之前，并在 `CONFIG_WATCHPOINT` 下显式包含 `src/monitor/sdb/watchpoint.h`；这样既保留懒构造 logbuf 和监视点快路径，又恢复所有调试开关组合下的可编译性。
- **教训**: 对热路径做局部优化时，不能只在“当前配置能过”下验证；凡是新引入的 helper、全局状态和快路径标志，都要重新检查它们在不同 `#ifdef` 组合中的声明顺序和可见性。

### [5] 当前宿主环境中的 SDL/Mesa 泄漏报错经重装运行库后消失
- **模块**: NEMU / 宿主 SDL-Mesa 环境
- **现象**: 此前 `make ARCH=riscv32-nemu run mainargs=v` 与类似 VGA 路径会在退出时触发 `LeakSanitizer: detected memory leaks`，调用栈落在 `libGLX_mesa.so`、`libSDL2.so` 和 `src/device/vga.c:init_screen()`。
- **根因**: 代码层面存在上游 NEMU 也具备的 SDL 生命周期缺口；但在本机这次案例中，宿主 SDL/Mesa 运行库或其后端状态也是触发“由噪音升级为报错”的关键因素，因为单改运行库状态后问题即消失。
- **修复**: 用户在宿主机执行 `sudo apt install --reinstall -y libsdl2-2.0-0 libglx-mesa0 libgl1-mesa-dri libegl-mesa0 mesa-vulkan-drivers` 后反馈“没问题了”。
- **教训**: 当 SDL/GLX/Mesa 调用栈只在某一台机器稳定复现时，不要只盯 guest 程序或上游代码；先核对宿主图形运行库、显示后端和 sanitizer 配置，低风险重装运行库往往能快速区分“代码问题”和“环境问题”。

### [6] AM 目标下监视点符号在链接阶段未定义
- **模块**: NEMU / CPU Exec / AM Target
- **现象**: 执行 `make ARCH=riscv32-nemu` 时，链接 `riscv32-nemu-interpreter-riscv32-nemu.elf` 报 `undefined reference to 'watchpoint_enabled'` 和 `undefined reference to 'compare_assert'`。
- **根因**: `ARCH=riscv32-nemu` 对应 `CONFIG_TARGET_AM=y`，而 `src/filelist.mk` 会在该目标下把 `src/monitor/sdb` 整个排除出构建，所以 `watchpoint.c` 不会参与链接；但 `src/cpu/cpu-exec.c` 里的监视点路径仍可能因为当时的 AM 配置开启了 `CONFIG_WATCHPOINT`，或复用了旧的 `build/riscv32-nemu/src/cpu/cpu-exec.o`，从而继续引用这两个符号。
- **修复**: 已在 `nemu/Kconfig` 中为 `WATCHPOINT` 增加 `depends on !TARGET_AM`，并在 `nemu/src/cpu/cpu-exec.c` 中把监视点相关包含与执行分支都改成“`CONFIG_WATCHPOINT` 且非 `CONFIG_TARGET_AM`”才编译；随后复现 `make -C am-kernels/kernels/nemu ARCH=riscv32-nemu mainargs=/home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello/build/hello-riscv32-nemu.bin`，确认链接恢复正常并成功运行到 `HIT GOOD TRAP`。
- **教训**: 分析链接错误时不能只看当前根目录 `.config`；还要同时核对目标类型对应的源码黑名单和该目标目录中的对象文件是否为旧配置残留。对这类不合法配置组合，优先在 Kconfig 和源码使用点两层同时收口，比只在 Makefile 或生成宏文件里做单点修补更稳。

### [7] 定宽宽度宏直接参与位宽算术时触发告警
- **模块**: NPC / IFU / BHT
- **现象**: 在 `npc/single/vsrc/IFU/bh_bt.v` 中把 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 直接拿来做 localparam 减法、移位和位选边界计算时，文件级检查报 `expects 32 bits ... generates 4 bits/6 bits` 一类位宽不匹配错误。
- **根因**: `npc/single/vsrc/IFU/define.v` 把宽度宏定义成了 `6'b100000`、`4'b1000` 这样的定宽常量；它们直接参与参数算术时会保留原始位宽，检查器不会自动提升到 32 位。
- **修复**: 在 `bh_bt.v` 中先把 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 零扩展成 32 位 localparam，再参与 BHT 表深、tag 宽度和 part-select 边界计算；修改后文件级检查恢复无报错。
- **教训**: 宽度类宏如果写成定宽二进制常量，拿来做参数算术前要先显式扩展；更稳的长期方案是把这类宏改成无位宽十进制常量或 `localparam`。

## 调试技巧备忘
<!-- 在调试过程中发现的有用技巧 -->
- 像 ITRACE 这类调试功能不能只看“是否输出日志”，还要看“是否为了日志提前做了额外工作”；若 logbuf、反汇编、预取指在每条指令上无条件执行，即使最后没打印，也已经把开销付掉了。
- 宿主时间查询也是 NEMU 的常见隐藏热点：如果设备更新逻辑在每条 guest 指令后都调用 `get_time()`，即便大多数时候只是立即返回，也会形成稳定开销；可先按指令数做粗粒度节流，再用真实时间做精细门控。
- NEMU 性能排查不要只盯着 `inst.c`：若 `.config` 同时开了 `CONFIG_CC_ASAN`、`CONFIG_ITRACE`、`CONFIG_DTRACE`、`CONFIG_FTRACE`、`CONFIG_DIFFTEST`、`CONFIG_RT_CHECK`，这些调试/检测功能叠加后的开销通常远大于单条指令取值代码本身，先关掉不需要的开关再看热点更有效。
- NEMU/SDB 调试优先用可脚本化路径：`--batch`、日志、trace、watchpoint、表达式求值和专用测试程序；当前 agent 工具不能可靠向已运行的前台 readline monitor 连续发送输入，因此不要默认依赖“启动后再人工键入命令”的流程。
