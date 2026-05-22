# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

## 活跃问题
<!-- 当前未解决的问题 -->

### [23] 本机缺少 `oss-cad-suite/bin/yosys`，RTL cache 接入后的综合/STA 尚未复跑

- **模块**: NPC / Yosys-STA / 环境
- **现象**: `make -C npc/single syn-check-env` 直接失败，提示缺少 `/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys`；因此本轮 ASIC 层级 I/D cache 接入后只完成了 Verilator lint/build 与 difftest/benchmark 功能验证，未产生新的综合网表、时序、面积、功耗报告。
- **根因**: 当前工作区期望的 oss-cad-suite 工具链路径不存在或未安装，`npc/single/Makefile` 的综合入口检查在进入 Yosys 前终止。
- **修复**: 暂未修复；恢复该路径下的 Yosys/OpenROAD 工具链，或调整 `YOSYS_STA_HOME`/相关工具路径后，再执行 `make -C npc/single syn` 与 `make -C npc/single sta`。
- **教训**: RTL 功能回归通过不等于 PPA 闭环完成；每次把 cache、BPU 这类大状态模块推进可综合层后，都要重新跑综合/STA 并更新面积/时序基线。

### [22] RTL cache 接管后 legacy host cache counter 会显示为 0

- **模块**: NPC / cache / 性能统计
- **现象**: 本轮 `IDCache.v` 接入后，`npc/single/csrc/dpi.c` 已改为 raw PMEM/MMIO 访问，host 侧 `memory/cache.c` 不再位于取指/访存路径上；因此程序结束时若仍打印 legacy `icache/dcache` counter，数值可能为 0 或不再代表真实 RTL cache 行为。
- **根因**: cache 微结构已经从 host bus 层下沉到 `NpcCore` 内部 RTL，原先的 C 侧 cache 统计自然失去数据源。继续让 host cache 和 RTL cache 同时工作会造成双重建模，反而破坏硬件语义。
- **修复**: 暂未修复；后续应在 RTL cache 内增加性能计数器，并通过仿真专用层次化读取或显式 debug/perf 端口暴露给 host。不要为了恢复旧 counter 而重新启用 host cache。
- **教训**: 性能统计的层次必须跟真实微结构层次一致；当 cache 从 simulator 优化变成硬件模块后，统计口也要迁移到 RTL，而不是继续复用 host 侧旧路径。

### [18] NPC 开启 stdin keyboard 后，终端输出会出现“越打越往右”的错位

- **模块**: NPC / 终端交互 / VGA 调试输出
- **现象**: 在 `riscv32-npc` 上运行 `make ARCH=riscv32-npc mainargs=v run` 一类会持续打印文本的程序时，即使 guest 代码只是普通 `printf("...\n")`，终端里的 `FPS = ...`、welcome 和 SDL 关闭日志也会逐行向右漂移，看起来像输出无法对齐；截图里 `[npc] stdin keyboard enabled` 同时出现时，几乎可以直接怀疑这条路径。
- **根因**: `npc/single/csrc/device/device.cpp` 的 `KeyboardDevice::Init()` 在把 TTY 切到“可轮询、无回显”的模式时额外执行了 `raw.c_oflag &= ~(OPOST)`。由于 stdin/stdout/stderr 共享同一个终端设备，这会关闭输出后处理，使 `\n` 不再被 TTY 转成回到列首的换行；而 guest 串口输出通过 `npc/single/csrc/monitor/log.cpp` 逐字符写 stdout，host `LogBoth()` 也直接 `printf("\n")`，于是列偏移会累积暴露出来。
- **修复**: 暂未修复；根治时应优先保留 `OPOST/ONLCR`，或者至少不要在只需要 raw input 的场景改动输出侧 termios。临时恢复宿主终端可用 `stty sane`。
- **教训**: 终端 raw mode 不是“只影响输入”的局部开关；凡是通过 `tcsetattr()` 修改同一个 TTY，输出行规程也会一起受影响。看到“文本错位”时先查 termios，再怀疑显示链路。

### [17] NPC 上直接跑 `am-tests mainargs=d` 时，当前主要卡在 `timer_test` 忙等与后续磁盘缺口，而不是 VGA

- **模块**: NPC / AM-Kernels / Abstract Machine
- **现象**: 在 `riscv32-npc` 上直接运行 `./npc/single/build/NpcSimTop ./am-kernels/tests/am-tests/build/amtest-riscv32-npc.bin --no-itrace --max-cycles 3000000` 时，输出只能到 `heap = ...` 和 `Input device test skipped.`，随后因周期上限在 `0x80000264` abort，看起来像 `devscan` 还没走通。
- **根因**: 这次停点位于 `devscan()` 里 `timer_test` 的 `for (volatile i = 0; i < 10000000; i++)` 忙等循环，本质上是当前多周期 NPC 对这种纯 CPU busy loop 太慢；而且即使越过这段，`storage_test()` 后面还会碰到 `riscv32-npc` 尚未实现的磁盘设备。高级 VGA ABI 本轮已经通过共享软件渲染层补齐，不再是这里的首要阻塞。
- **修复**: 暂未修复；若要让 `mainargs=d` 在 NPC 上更实用，可从“给 NPC 加快连续执行性能、为 `devscan` 增加 NPC 专用 smoke 入口、或补最小 disk config/blkio”几个方向继续推进。
- **教训**: 当一个跨设备测试在慢速 RTL 目标上跑不完时，不要直接把责任推回最近补的某个设备；先定位 PC 所在阶段，确认当前真正挡路的是功能缺口、性能预算，还是测试本身的前置 busy loop。

- 原 [3] 已在当前宿主环境中通过重装 SDL/Mesa 运行库暂时解除，见下方“已解决问题”。

### [15] NpcCore 在 500MHz STA 下时序满足，但时钟门控使能脚仍有最大电容违规

- **模块**: NPC / Yosys-STA
- **现象**: `npc/single/build/sta/NpcCore-500MHz/NpcCore.rpt` 显示 `core_clock` 的 `max/min TNS` 都为 `0.000`，最差 setup slack 约 `0.963ns`，但 `NpcCore.cap` 里 `mem_addr_raw_q_0__..._ICGX0P5H7L_E:ECK` 等时钟门控使能脚仍出现最大电容超限，最坏 `CapacitanceSlack` 约 `-0.074`。
- **根因**: 当前 `yosys-sta` 流程在综合阶段启用了 clockgate，`NpcCore` 又包含较宽的状态/调试寄存器扇出，导致部分 `ICGX0P5H7L` 的 `ECK` 使能脚负载偏大；这类问题不一定会立刻打穿逻辑级 WNS/TNS，但会先在电气约束报告里暴露出来。
- **修复**: 暂未修复；后续可从“收紧/调整 clockgate 策略、对高扇出的门控使能链补缓冲、降低调试扇出影响，或在更完整的物理实现阶段重新评估”几个方向处理。
- **教训**: 做综合验收时不能只看 `WNS/TNS`；对带 clock gating 的设计，还要同时检查 `cap/fanout/trans`，否则会把“时序过了但电气没过”的半成品误判成完全 clean。

## 已解决问题
<!--
### [编号] 问题标题
- **模块**: 出问题的模块
- **现象**: 具体表现
- **根因**: 根本原因分析
- **修复**: 如何修复的
- **教训**: 从中学到了什么
-->

### [26] NPC 配置切换不会稳定触发 Verilator 二进制重建，可能继续沿用旧产物

- **模块**: NPC / Makefile / Kconfig
- **现象**: `.config` 与 `include/generated/autoconf.h` 已更新配置，但直接 `make run` 仍可能运行旧 `npc/single/build/NpcSimTop`，例如关闭 `CONFIG_NPC_PROGRESS_BY_DEFAULT` 后仍打印 `[progress] ...`，或切回 VGA 后仍显示 `NPC VGA disabled`。
- **根因**: `include/generated/autoconf.h` 只通过 `-include` 传给 Verilator CFLAGS，之前没有作为 `$(BIN)` 的显式依赖；配置切换后如果 RTL/C 源文件没变，`make` 会认为二进制仍是最新。
- **修复**: 2026-05-22 已修复：`npc/single/Makefile` 新增 `CONFIG_OUTPUTS := include/generated/autoconf.h include/config/auto.conf`，并把它们加入 `$(BIN)` 依赖。验证：`make -C npc/single -W /home/lyg/PA/ysyx-workbench/npc/single/include/generated/autoconf.h -n default` 会展开 Verilator 重建命令；普通 `make -n default` 在二进制晚于配置头时保持 no-op。
- **教训**: Kconfig 选项影响 CFLAGS/条件编译时，配置生成物必须进入最终产物依赖链；否则用户看到的是“配置明明关了/开了却无效”，实际只是二进制陈旧。

### [27] RT-Thread AM on NPC 在线程入口返回后触发 `context.c:69`

- **模块**: Abstract Machine / RT-Thread BSP / NPC
- **现象**: `riscv32-npc` 上 RT-Thread 已打印 banner、utest 和 `Hello RISC-V!` 后，立即报 `Assertion fail at .../context.c:69`，NPC 侧显示 `HIT BAD TRAP at pc = 0x80043f9a`、`exit via ebreak, code=1`。
- **根因**: `pc=0x80043f9a` 是 `halt(1)` 内的 `ebreak`，不是第一现场。真正问题是 `rt_hw_stack_init()` 只按 `RT_ALIGN_SIZE=8` 计算新线程栈布局，而 RISC-V AM 的 `kcontext()` 会把 `kstack.end` 再按 16 字节向下对齐并清零 `Context`。当 RT-Thread heap 返回的线程栈顶是 8-byte-only 对齐时，`kcontext()` 实际放置的 `Context` 会比 BSP 预估位置低 8 字节，覆盖 `RtAmThreadStart.exit` 字段；trampoline 随后看到 `exit == NULL`，跳过 `texit` 并触发第 69 行 `assert(0)`。
- **修复**: 2026-05-22 已修复：`Templates/rt-thread-am/bsp/abstract-machine/src/context.c::rt_hw_stack_init()` 先把 `kstack.end` 按 16 字节对齐，再在该边界下方布局 `Context` 和 `RtAmThreadStart`，使 BSP 预留空间与 RISC-V `kcontext()` 内部行为一致。复验 `timeout 30s make ARCH=riscv32-npc run` 已进入 RT-Thread `msh` 并执行 shell 命令；native 回归和 `yield-os` on NPC 均正常。
- **教训**: OS/BSP 桥接栈布局时不能只看上层 RTOS 的最小对齐，还必须匹配底层架构 `kcontext()` 的真实对齐和清零范围。看到 trap PC 落在 `halt/ebreak` 时，要先沿断言/退出路径回溯，不要把 ebreak 地址当作原始异常点。

### [24] NPC 默认 Verilator 构建携带 `--prof-cfuncs/-pg`，普通运行不再是干净性能基线

- **模块**: NPC / Verilator / 性能
- **现象**: `npc/single/Makefile` 默认 `VERILATOR_FLAGS` 含 `--prof-cfuncs`；生成的 `npc/single/build/obj_dir/VNpcSimTop.mk` 中 `VM_PROFC=1`，Verilator 公共 `verilated.mk` 会据此给编译和链接都追加 `-pg`。因此默认二进制适合 gprof 归因，但不适合作为普通仿真速度基线。
- **根因**: `--prof-cfuncs` 被当作“便于 profile 且运行期零开销”的默认选项保留在普通构建中；但 Verilator 5.020 的生成 makefile 会把它转成 profile build，并会拆分生成函数/影响内联。
- **修复**: 2026-05-21 已修复：默认 `VERILATOR_FLAGS` 移除 `--prof-cfuncs`，新增 `VERILATOR_PROFILE/VERILATOR_PROF_EXEC/VERILATOR_THREADS*` 显式开关；`gprof-build` 才设置 `VERILATOR_PROFILE=1`，`prof-exec-build` 才设置 `VERILATOR_PROF_EXEC=1`。复验 `VM_PROFC=0`，MicroBench 单线程性能约 `2.68-2.81M inst/s`。
- **教训**: 仿真性能基线必须区分“profile 构建”和“release/perf 构建”；任何用于定位热点的插桩都不能长期留在默认路径，否则后续比较会把工具开销误判成 RTL 或 Verilator 本身慢。

### [25] NPC perf 配置关闭 VGA 后仍会被 C fallback 重新打开

- **模块**: NPC / Kconfig / VGA / 性能配置
- **现象**: 使用 `perf_defconfig` 跑 benchmark 时仍可能出现 SDL/VGA 窗口；`perf_defconfig` 中 `CONFIG_NPC_HAS_VGA=n`，但运行时 `CoreMark -> ioe_init -> __am_gpu_init` 仍认为 GPU present 并写 `SYNC_ADDR`，host 侧随后创建窗口。
- **根因**: Kconfig 的 `bool=n` 在 `include/generated/autoconf.h` 中表现为没有对应宏；`npc/single/csrc/include/utils.h` 的 fallback 却把未定义的 `CONFIG_NPC_HAS_VGA` 定义为 1。同类扫描确认 `CONFIG_NPC_SDB/EXPR/WATCHPOINT` 也曾有关闭后被 fallback 为 1 的风险。
- **修复**: 将 `CONFIG_NPC_HAS_VGA`、`CONFIG_NPC_SDB`、`CONFIG_NPC_EXPR`、`CONFIG_NPC_WATCHPOINT` 的 fallback 统一改为 0，并补注释说明 bool fallback 必须保守处理 Kconfig not-set 语义。
- **教训**: 对 Kconfig bool，未定义不是“配置缺失”，而是合法的关闭态。手写兼容默认值只能让整数/字符串补默认值，bool 应默认关闭，否则性能配置和最小配置会被悄悄污染。

### [21] NPC cache 曾停留在 Verilator host bus 透明模型，还不是可综合 RTL cache

- **模块**: NPC / cache / RTL-PPA
- **现象**: 早期 `riscv32-npc` 虽可通过 `fence-i` 自修改代码测试，并能输出 ICache/DCache counter，但真正的 cache tag/data/miss/fill/writeback 位于 `npc/single/csrc/memory/cache.c`；DPI 取指/访存经 host bus cache 后再访问 PMEM/MMIO，`NpcCore` 的 IFU/LSU ready/valid 接口没有真实多拍 cache miss/fill 时序。
- **根因**: 当时优先目标是按 NEMU 可选功能闭合功能与 difftest 回归，先做对 RTL 透明的 simulator cache，避免一次性扩大流水线控制面、外部 memory protocol 和 PPA 闭环。
- **修复**: 2026-05-19 新增 `npc/single/vsrc/IDCache.v`，在 `NpcCore.v` 内部接入可综合阻塞式 ICache/DCache，host `dpi.c` 改为 raw PMEM/MMIO 访问，`NpcSimTop.sv` 通过层次化引用观察 `u_core.cache_flush_valid_w`。复验 `make -C npc/single lint`、`make -C npc/single`、全量 `cpu-tests` 38/38 difftest 与 MicroBench `mainargs=test` difftest 均 PASS。
- **教训**: “参考模型/仿真器可观察到 cache 行为”不等于“CPU RTL 已经实现 cache 微结构”。记录性能数据时需要明确层次边界，避免把 host 侧透明优化误当作硬件 PPA 结果。

### [20] NPC 流水线化后 PC 跑飞：IF 返回丢失与 load 响应未前递

- **模块**: NPC / RTL 流水线 / IFU/LSU 冒险
- **现象**: 初版流水线在简单 `add` 可继续跑通，但更复杂的 AM 路径会出现 PC 跑飞；`am-tests mainargs=i` 曾在跳表附近把 PC 带到 `0x00007980`，触发 fetch out of bound。
- **根因**: 两层问题叠加：① IF fetch buffer 的容量判断只看旧的 `fetch_buf_valid_q`，没有把本拍 incoming response 和本拍 buffer 消费一起纳入，后级背压时可能静默丢取指返回；② load-use 只做了 ID 阶段一拍停顿，消费者进入 EX 时若 load 数据正好在 MEM 响应同拍返回，EX 仍只能从旧寄存器/MEM-WB 取值，跳表索引路径会读到旧地址。
- **修复**: IF 侧新增基于 `fetch_rsp_slot_w/fetch_issue_slot_w` 的容量计算，保证不会在没有槽位时继续接收/覆盖返回；EX 操作数转发新增 `mem_response_w && ex_mem_load_q` 的同拍 LSU 响应前递，同时保留 EX/MEM、MEM/WB 转发和 load-use stall。随后 `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 35/35 PASS，`am-tests mainargs=i` 能稳定进入交互菜单并运行到超时，`yield-os` 持续输出 `ABAB...`。
- **教训**: 流水线冒险不能只用“停一拍”口头覆盖；需要逐拍确认数据在哪一级产生、哪一级消费。带 ready/valid 的 IF/MEM 也要把“本拍进出队”合并计算容量，否则 bug 会表现为远端 PC 跑飞，根因却在更早的握手边界。

### [19] fceux-am 在 NPC 上 BAD TRAP：FUNC_IDX 溢出 + 音频设备 panic

- **模块**: FCEUX-AM / Abstract Machine / NPC
- **现象**: `make ARCH=riscv32-npc mainargs=mario3 run` 先因 `FUNC_IDX_MAX=16` 溢出 `halt(1)`，修复后又因 `io_read(AM_AUDIO_CONFIG)` 触发 `access nonexist register` panic。
- **根因**: 两层问题：① `fceux-am/src/config.h` 未识别 `__PLATFORM_NPC`，落入 `PERF_LOW` → `FUNC_IDX_MAX16`，MMC3 mapper 注册超 16 个唯一函数指针时 assert 失败；② 修成 `PERF_MIDDLE` 后 `SOUND_CONFIG` 变成 `SOUND_LQ`，`sdl-sound.cpp` 中 `io_read(AM_AUDIO_CONFIG)` 被编译进来，但 `riscv32-npc` 的 `ioe.c` 没有注册编号 14 的 `AM_AUDIO_CONFIG`。
- **修复**: ① 在 `config.h` 的 `#elif` 分支加上 `|| defined(__PLATFORM_NPC)` 使 NPC 获得 `PERF_MIDDLE`；② 在 `abstract-machine/am/src/riscv/npc/ioe.c` 新增 `__am_audio_config` 空桩（`present=false, bufsize=0`）并注册到 lut。修复后 mario3 在 NPC 上成功加载运行。
- **教训**: 跨平台的性能/功能配置层（如 `config.h`）在新增平台时必须显式接入，否则会静默退回最低档位带来意料之外的功能裁剪。IOE 设备查找表对所有 AM 定义的设备至少应提供 `present=false` 回应，避免任何程序碰未实现设备就直接 panic。后续实现 NPC 真实音频时，需把空桩替换为真实实现并同时注册 `AM_AUDIO_CTRL/STATUS/PLAY`。

### [8] am-tests 的 devscan 在 NEMU 上访问 GPU 高级接口时触发 BAD TRAP

- **模块**: AM-Kernels / Abstract Machine / NEMU
- **现象**: 早期执行 `make -C am-kernels/tests/am-tests ARCH=riscv32-nemu run mainargs=d NEMUFLAGS=-b` 时，日志会先打印 `Screen size: 400 x 300`，随后报 `AM Panic: access nonexist register`，NEMU 最终 `HIT BAD TRAP`。
- **根因**: `am-kernels/tests/am-tests/src/tests/devscan.c` 会调用 `io_write(AM_GPU_MEMCPY, ...)` 和 `io_write(AM_GPU_RENDER, ...)`；当时 `abstract-machine/am/src/platform/nemu/ioe/ioe.c` 只注册了 `AM_GPU_CONFIG`、`AM_GPU_FBDRAW`、`AM_GPU_STATUS`，没有注册 12/13 号 GPU 高级寄存器，因此访问时会落到 `fail()` 并 panic。
- **修复**: 2026-04-14 已通过共享软件渲染层 `abstract-machine/am/src/platform/gpu_soft.h` 补齐 NEMU/NPC 两条平台的 `AM_GPU_MEMCPY/AM_GPU_RENDER`，`platform/nemu/ioe/ioe.c` 现在已注册这两个寄存器，`platform/nemu/ioe/gpu.c` 会把 canvas/texture 数据写入 512KB 软显存并渲染到 framebuffer。历史验证显示 NEMU `am-tests mainargs=d` 已到达 `Test End!`。
- **教训**: 做回归归因时不要只看“最近改过什么”，还要先核对平台设备分发表和 AM 抽象 ABI 是否一致；这类 `access nonexist register` 更像平台能力缺口，不应直接归因到 `stdlib` 或其它最近改动上。

### [16] NPC 开启基础 VGA 后，AM 带 IOE 的程序一度在 `__am_gpu_init` 阶段提前超时

- **模块**: NPC / Abstract Machine
- **现象**: 给 `riscv32-npc` 平台补上 `VGACTL_ADDR/FB_ADDR` 和基础 GPU IOE 后，`am-tests mainargs=k/v` 在刚启动时就反复卡在 `0x80001624/0x8000162c`，也就是 `__am_gpu_init()` 的 `sw zero, 0(a5)` 清屏循环；即使用户真正想验证的是 keyboard 或 `AM_GPU_FBDRAW`，程序也会先在 GPU 初始化阶段把默认周期预算烧光。
- **根因**: `abstract-machine/am/src/riscv/npc/gpu.c` 起初沿用了 guest 侧逐像素清 400x300 framebuffer 的写法，这在 NEMU 上问题不大，但对当前多周期 NPC 来说会先消耗数十万次 `store` 提交；而宿主 `VgaDevice::Init()` 实际上已经把 framebuffer 后端清零了，这段 guest 清屏因此变成了纯冗余开销。
- **修复**: 把 `__am_gpu_init()` 收敛成“只做一次 sync”，把初始黑屏语义交给宿主 `VgaDevice::Init()` 负责；随后重新执行 `printf 'a' | ./npc/single/build/NpcSimTop ... mainargs=k --stdin-kbd --no-itrace --max-cycles 500000`，确认 `readkey test` 已输出 `A DOWN/UP`，并复验 `mainargs=v` 的停点已推进到 `__am_gpu_fbdraw` 的像素拷贝循环。
- **教训**: 对 RTL 目标上的平台初始化，不能机械照搬参考模型的 guest 侧大块清屏/搬运逻辑；只要宿主后端能在更低成本的抽象层提供同样的初始状态，就应该把这类 bulk 操作下沉到宿主，否则功能还没开始，性能预算就先被平台 glue 烧掉。

### [14] NPC 开启波形时启动阶段反复报 `previous dump`，日志文件也缺少可读的 guest 输出

- **模块**: NPC / cpu-exec / monitor / device
- **现象**: 打开默认波形后，程序刚启动就打印 `%Warning: previous dump at t=9, requesting t=0, dump call ignored` 一串 warning；即使 `npc-log.txt` 已经打开，文件里也主要只有 host 侧欢迎信息和收尾摘要，guest 串口文本不完整，离线排查体验很差。
- **根因**: `apply_reset()` 的 warmup 已经把 VCD 时间推进到 `t=9`，但后续 `clear_runtime_state()` 又经由 `reset_npc_state()` 把整份 `NpcStats` 连同 `sim_time` 一起清零，导致正式执行重新从 `t=0` dump；同时日志系统此前只镜像 `Log(...)`，guest 串口输出直接写 stdout，没有进入文件日志。
- **修复**: 把运行态清理收窄成“只清 `NpcState`，不重置 `NpcStats::sim_time`”，确保 VCD 时间轴持续单调；同时新增 `NPC_ITRACE_BY_DEFAULT`、`NPC_MTRACE_BY_DEFAULT`、`NPC_DTRACE_BY_DEFAULT` 默认运行态开关，并把 guest 串口输出整理成 `[guest] ...` 行写入日志文件。复验 `make -C am-kernels/kernels/hello ARCH=riscv32-npc run` 后，warning 已消失，`npc/single/build/npc-log.txt` 也能直接看到 `[guest] Hello, AbstractMachine!`。
- **教训**: “状态复位”和“trace 时间轴复位”不是一回事；只要 VCD 已经开始 dump，就不能再把时间戳回卷。另一方面，若希望日志文件承担 NEMU 风格的离线调试作用，就必须同时保留 host trace 和 guest 串口文本，不能只镜像其中一边。

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
