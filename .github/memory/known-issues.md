# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

## 活跃问题
<!-- 当前未解决的问题 -->

- 原 [3] 已在当前宿主环境中通过重装 SDL/Mesa 运行库暂时解除，见下方“已解决问题”。

### [8] am-tests 的 devscan 在 NEMU 上访问 GPU 高级接口时触发 BAD TRAP

- **模块**: AM-Kernels / Abstract Machine / NEMU
- **现象**: 执行 `make -C am-kernels/tests/am-tests ARCH=riscv32-nemu run mainargs=d NEMUFLAGS=-b` 时，日志会先打印 `Screen size: 400 x 300`，随后报 `AM Panic: access nonexist register`，NEMU 最终 `HIT BAD TRAP`。
- **根因**: `am-kernels/tests/am-tests/src/tests/devscan.c` 会调用 `io_write(AM_GPU_MEMCPY, ...)` 和 `io_write(AM_GPU_RENDER, ...)`；但 `abstract-machine/am/src/platform/nemu/ioe/ioe.c` 当前只注册了 `AM_GPU_CONFIG`、`AM_GPU_FBDRAW`、`AM_GPU_STATUS`，没有注册 12/13 号 GPU 高级寄存器，因此访问时会落到 `fail()` 并 panic。
- **修复**: 暂未修复；若要让 `devscan` 在 NEMU 上通过，需要在 `platform/nemu` 补齐 `AM_GPU_MEMCPY/AM_GPU_RENDER` 的处理，或让测试按平台能力降级，不再无条件访问这两个接口。
- **教训**: 做回归归因时不要只看“最近改过什么”，还要先核对平台设备分发表和 AM 抽象 ABI 是否一致；这类 `access nonexist register` 更像平台能力缺口，不应直接归因到 `stdlib` 或其它最近改动上。

## 已解决问题
<!--
### [编号] 问题标题
- **模块**: 出问题的模块
- **现象**: 具体表现
- **根因**: 根本原因分析
- **修复**: 如何修复的
- **教训**: 从中学到了什么
-->

### [13] NPC 长时间 batch 跑分时完全静默，容易被误判为卡死

- **模块**: NPC / cpu-exec / monitor
- **现象**: 跑 `coremark` 这类需要数分钟的 `riscv32-npc` 长测试时，终端长时间没有任何新输出；即使仿真实际上还在持续推进，使用者也很难区分“只是没跑完”和“真的卡住了”。
- **根因**: `npc/single` 的执行循环此前只有“开始 welcome”和“最终退出/异常/超时”这两类输出，中间没有任何连续执行期间的可观测反馈。
- **修复**: 新增 `CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL` 和 `--progress/--no-progress/--progress-interval`，并在 `cpu_exec()` 的连续运行路径按提交指令数周期性打印 `[progress] <commits> insts, pc=..., <inst/s> inst/s`；`si` 这类短命令默认不打印，避免刷屏。
- **教训**: 长时间仿真除了功能正确性，还要考虑“宿主层可观测性”；否则用户会在没有故障证据的情况下先怀疑卡死，调试效率会被交互体验拖慢。

### [12] klib 的 printf 缺少无符号/十六进制格式，导致 CoreMark 打印成 `0x%x`

- **模块**: Abstract Machine / klib / AM-Kernels
- **现象**: `coremark` 中的 `seedcrc/crclist/crcmatrix/crcstate/crcfinal` 会显示成 `0x%x`，`devscan` 之类使用 `%08x` 的路径也会把格式串近似原样吐出来。
- **根因**: `abstract-machine/klib/src/stdio.c` 的 `kvsnprintf()` 早先只覆盖 `%d/%s/%c/%%` 的窄子集，虽然解析了宽度和前导 `0`，但没有把这些能力真正接到 `%u/%x/%p` 等常用整数格式上。
- **修复**: 把整数格式统一收口到共享输出路径，补齐 `d/i/u/x/X/p`、`l/ll`、字段宽度和补零支持，并在 `am-kernels/tests/klib-tests/tests/klib_fmt.c` 中新增 `%u/%04x/%08x/%X/%p` 回归；随后在 `riscv32-nemu` 和 `riscv32-npc` 上复跑 `klib-tests`，并用 `coremark` 验证 CRC 已恢复真实十六进制输出。
- **教训**: 这类问题必须在公共格式化层根治，不能为单个 benchmark 临时改打印语句；同时一旦扩 `printf` 能力，就要补回归测试，否则下次仍会静默退化。

### [11] NPC 停在 `(npc)` 提示符时按 `Ctrl-C` 不能退出

- **模块**: NPC / monitor / cpu-exec
- **现象**: 进程停在 `Welcome to riscv32-NPC! ... (npc)` 提示符时，按 `Ctrl-C` 只会在终端上看到 `^C`，但 NPC 进程并不会退出，用户只能直接关掉整个终端标签页。
- **根因**: `SIGINT` 处理原先只把一个停止标志写到 `cpu-exec.cpp` 内部，而这个标志只会在 `cpu_exec()` 的运行循环中被消费；当 monitor 空闲停在 `std::getline()` 读命令时，没有任何代码去处理这次中断，而且 `signal()` 默认的重启语义会让阻塞读继续挂着。
- **修复**: 改为使用不带 `SA_RESTART` 的 `sigaction(SIGINT, ...)` 安装处理器，并把 `SIGINT` 标志通过 `consume_sigint_request()` 暴露给 `sdb_mainloop()`；现在连续执行中的 `Ctrl-C` 仍然只会中断回 prompt，而 prompt 态 `Ctrl-C` 会直接退出整个 NPC 进程。
- **教训**: 交互式仿真器不能只处理“运行态中断”，还要处理“提示符阻塞读”的中断路径；否则用户看到的会是典型的“终端已经收到了 Ctrl-C，但应用层没退”的假死体验。

### [10] NPC 默认 `itrace` 条件 `true` 一度被误判为非法表达式

- **模块**: NPC / monitor / trace
- **现象**: 即使没有显式打开 `itrace`，只要默认配置里保留 `CONFIG_NPC_ITRACE_COND="true"`，启动 batch `--mtrace --dtrace` 或 monitor `info t` 时也会先打印 `[npc] bad itrace condition 'true', fallback to true.`。
- **根因**: `trace.cpp` 会在初始化阶段预校验 `itrace` 条件，但当前表达式求值器只认识数字、寄存器和运算符，不认识裸布尔字面量 `true/false`，导致默认条件字符串被错误地视为非法表达式。
- **修复**: 在 `npc/single/csrc/monitor/trace.cpp` 里先对 `true/false/0/1` 做字面量兼容，再把其他情况交给 `expr()`；修复后默认配置和 `trace cond true` 都不再报错。
- **教训**: 配置层默认值如果打算直接喂给表达式求值器，就不能只验证“典型复杂表达式”，还要覆盖最常见的字面量语义，否则看似无害的默认配置也会在启动路径上制造误报警。

### [9] NPC 的 `si 1` 在 monitor 中一度停在旧 PC

- **模块**: NPC / monitor / cpu-exec
- **现象**: 对 hello 镜像执行 `si 1` 后，`info s` 会显示 `commits = 1`，但 `pc` 仍停在 `0x80000000`，看起来像没有前进到下一条待执行指令。
- **根因**: `cpu_exec()` 原先在命中最后一次提交后立刻返回，而 RTL 导出的 `debug_pc_o` 仍对应当前在途状态；host 正好在提交边界采样，导致 monitor 看到的是“刚完成提交的旧 PC”。
- **修复**: 在 `npc/single/csrc/cpu/cpu-exec.cpp` 中，当 `si`/定步命中最后一次提交后，额外推进一个不产生新提交的收尾周期，再返回 monitor；复验后 `si 1` 已能稳定看到 `pc = 0x80000004`。
- **教训**: 单步调试的用户观感不只取决于“提交是否发生”，还取决于 host 选择在哪个微状态对外暴露调试信号；如果直接在提交边界返回，monitor 很容易比用户预期落后半拍。

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
