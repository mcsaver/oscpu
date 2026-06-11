# 设计决策记录

> 本文件记录项目中的重要设计决策及其理由，供后续参考。

## 决策格式

<!--
### [编号] 决策标题

- **日期**: YYYY-MM-DD
- **状态**: 已决定 / 待讨论 / 已废弃
- **上下文**: 为什么需要做这个决策
- **决策**: 最终选择了什么方案
- **理由**: 为什么选择这个方案
- **影响**: 对其他模块的影响
-->

## 架构决策

### [37] 软件开发全流程采用独立 `software-flow` agent

- **日期**: 2026-06-09
- **状态**: 已决定
- **上下文**: 工作区已经有硬件落地前的 `hardware-flow`、`npc`、`ysyx-soc`、`rv64-linux` 等 agent，但软件侧需求、脚本/工具链、NEMU/AM/am-kernels/Linux guest check 和 host side 软件开发仍缺一个对称的全流程入口，容易在实现、测试、回归和记录之间靠临时口头串联。
- **决策**: 新增 `software-flow` 作为 L1 软件开发流程 agent，负责 `scope-contract -> design-plan -> implement -> unit-or-contract-test -> integration-smoke -> regression-or-e2e -> review-record` 的完整闭环，并补充 `software-bugfix-loop` 与 `software-refactor-loop`。它可以调度 `nemu`、`abstract-machine`、`am-kernels`、`fceux-am`、`rv64-linux`、`linux-device`、`agent-system` 等软件相关模块；当任务需要 RTL/Chisel/SoC/STA/PPA 或 target/difftest 证据时，必须交接给 `hardware-flow` 或对应硬件模块 agent。
- **理由**: 这样软件任务在落地前也有清晰 owner、静态图、节点产物和 e2e contract，不再把软件开发流程混进硬件 bring-up 或 agent-system 维护任务里。
- **影响**: 后续新增软件功能、软件 bug 修复、脚本工具链重构或软件测试补齐时，应优先判断是否命中 `software-dev-loop`、`software-bugfix-loop` 或 `software-refactor-loop`；新增/调整该 agent 时必须同步更新 `.github/e2e/modules/software-flow.md`、`.github/e2e/profiles/software-flow.tsv`、`contracts` profile、脚本 gate 和 `.github/memory/modules/software-flow.md`。
- **2026-06-09 追加**: 对 NEMU/RV64/Linux 这类“用软件建硬件/系统模型”的任务，不能把 `software-flow` 只当环境校验；新增 `hardware-aware-software-loop` 作为组合图，先用 `software-flow` 收敛软件工程闭环，再叠加 `nemu-ubuntu`、`hardware-flow`、`rv64-linux`、`difftest` 或 target gate 做硬件/系统语义完成判定。

### [36] RV64 外部中断对 Linux S 态按 SEI delegation 建模

- **日期**: 2026-06-01
- **状态**: 已决定
- **上下文**: Ubuntu probe 已证明 `/init` 多次 `write()` 返回成功，但 UART THR 没有写入。新增 UART access/IRQ trace 后发现 UART IER 写入会让 `uart_irq` 与 PLIC 输出抬高，说明源和 PLIC 输出可达；问题在 S 态 Linux 是否按 supervisor external interrupt 服务该事件。
- **决策**: 当前单外部中断线模型中，`CsrFile` 将 PLIC external IRQ 映射为 S 态 `MIP_SEIP` 时使用 `mideleg[IRQ_CAUSE_SEI]`，并在 lower privilege 下按同一 `SEI` delegation 位屏蔽对应 `MIP_MEIP`，不再使用 `MEI` 位伪装 S external interrupt。测试中 S external IRQ 也必须显式设置 `mideleg` bit 9。
- **理由**: Linux/OpenSBI 对 S 态外部中断使用 cause 9 (`SEI`)；旧模型看 `MEI(cause=11)` 会导致 PLIC 输出已高但 S 态 8250 handler 不被触发，表现为 `write()` 返回后 TTY 队列不写 THR。
- **影响**: 后续 PLIC 从单线模型升级为更真实多 context 时，应优先拆出 M/S context 独立 IRQ 输出；在拆分前，所有 Ubuntu/Linux 报告都必须把 `SEIP` delegation 与 PLIC claim/complete 作为同一条证据链说明，不能把 `plic_irq=1` 直接等同于 Linux handler 已执行。

### [35] RV64 Ubuntu 输出路径采用 post-window 与 UART TX trace 切分

- **日期**: 2026-06-01
- **状态**: 已决定
- **上下文**: commitwatch 已证明 Ubuntu probe `/init` 用户态入口和多次 `write()` 返回成功，但 guest-watch 仍看不到 `[ysyx-init]`。若在 `write()` 返回点立即退出，可能误把 UART/TTY 异步 drain 的延迟当成输出丢失。
- **决策**: 对“syscall 已返回但 guest 输出不可见”的 Linux bring-up 诊断，使用 host-only `NPC_COMMITWATCH_POST_CYCLES` 在命中 stop 条件后继续运行固定 cycles；同时用 `NPC_UART_TX_TRACE`、`NPC_UART_TX_TRACE_MIN_COMMIT`、`NPC_UART_TX_TRACE_LIMIT` 记录 DPI 层真实 UART TX 字节。报告中必须同时列出 post window 长度、commit/cycle 退出点、UART TX trace 计数和 guest-watch 结果。
- **理由**: post-window 可以排除“退出太早”这一类误判；UART TX trace 能把 Linux/TTY/8250 队列和仿真 host capture 分开。短跑先用 OpenSBI 验证 trace 链路有效，长跑再对 `/init` 输出做负证据，结论才可复验。
- **影响**: `NPC_COMMITWATCH_POST_CYCLES` 与 `NPC_UART_TX_TRACE` 只属于 Verilator/DPI 诊断能力，不进入可综合 RTL，也不能替代完整 Ubuntu gate。若 post-window 内 `write()` 返回成功但 `uart-trace tx=0`，下一步应查 Linux console/TTY/8250/THR MMIO；若有 TX 字节但 guest-watch 未命中，才回查 `npc_log_putchar`/guest buffer/匹配器。

### [34] RV64 Ubuntu 用户态入口采用 commitwatch-stop 做执行证据

- **日期**: 2026-06-01
- **状态**: 已决定
- **上下文**: Ubuntu probe 在 NPC 上已到 `Run /init as init process`，但 guest UART 没有出现 `[ysyx-init] early-entry`。仅靠 guest 输出无法区分“没有进入用户态”“用户态第一条 write/syscall 未生效”和“串口/console 输出未可见”。
- **决策**: 对这类 Linux 用户态入口切分，允许使用 host-only `NPC_COMMITWATCH_START/END` 加 `NPC_COMMITWATCH_STOP=1` 观察提交 PC 是否落入目标 ELF 地址范围；需要连续观察多个返回点时使用 `NPC_COMMITWATCH_STOP_AFTER=N`，并在 commitwatch 记录中保留 `a0..a7` 等 syscall 参数/返回证据。命中时以 `COMMIT WATCH MATCH` 正常退出，并在报告中同时给出目标 ELF 符号/反汇编和 QEMU 同镜像证据。commitwatch 是诊断证据，不替代 guest-watch 或架构 PASS。
- **理由**: 提交级 PC 证据能把 execve/user-entry 与 first syscall/output 路径分开，避免把“未见串口字符串”误判为“未进入用户态”。stop-on-match 还能显著缩短后续长跑定位时间。
- **影响**: 后续 Ubuntu/Linux 报告必须明确区分 `COMMIT WATCH MATCH`、`GUEST EXPECT MATCH`、GOOD TRAP 和完整 shell/rootfs gate。`NPC_COMMITWATCH_STOP`/`NPC_COMMITWATCH_STOP_AFTER` 属于 Verilator harness 诊断开关，不得进入可综合 RTL，也不能作为完整 Ubuntu 可见性的验收条件；若 syscall 返回成功但 guest-watch 不可见，下一步应转向 Linux console/TTY/8250、UART MMIO/DPI TX 或 host capture 层。

### [33] RV64 Ubuntu probe 证据采用 guest-watch 与 embedded-FDT 重建纪律

- **日期**: 2026-05-31
- **状态**: 已决定
- **上下文**: RV64 Ubuntu bring-up 同时存在 QEMU reference、NPC/Verilator target、OpenSBI embedded DTB、Linux printk、用户 `/init` 输出和后续 shell/rootfs 多层证据。若只看某段日志或只重建外部 DTB，容易把旧 bootargs、QEMU PASS 或部分 guest 输出误判成 NPC 已完整 Ubuntu。
- **决策**: NPC 侧 Ubuntu probe 使用 `NPC_GUEST_EXPECT`/`smoke-ubuntu-probe-watch` 分层验收：先证实 OpenSBI 输出，再证实 Linux 实际 command line，再证实 `[ysyx-init]`，最后证实 `PRETTY_NAME="Ubuntu 22.04.5 LTS"`。修改平台 DTB/bootargs 后，若 OpenSBI 通过 `FW_FDT_PATH` 嵌入 DTB，必须重建对应 `fw_jump.bin`，不能只重建外部 `.dtb`。
- **理由**: guest-watch 能把“看到了某个 guest 可见字符串”做成可复验退出条件，embedded-FDT 重建纪律能防止 Linux 实际读取旧 DTB。二者结合可以把证据边界写清，避免未来开发误把 `/init` handoff、半行输出或 QEMU reference 当成完整 NPC Ubuntu。
- **影响**: 后续 Ubuntu/Linux 任务必须在报告中标明命中的具体 gate、镜像/firmware 是否重建、以及 NPC 和 QEMU 证据的关系。`GUEST EXPECT MATCH` 是仿真 harness gate，不是架构 GOOD TRAP，也不代表官方 Ubuntu shell 或 rootfs 已闭合。

### [32] RV64 Ubuntu 主线采用 Verilator-first 且按流片边界约束

- **日期**: 2026-05-31
- **状态**: 已决定
- **上下文**: 用户要求后续目标是启动完整 Linux/Ubuntu 22.04，近期先不考虑 Vivado，而是用 Verilator 做尽量真实的性能/系统仿真，同时要求 core 后期能达到流片水准。旧 agent 体系主要围绕 RV32/NPC/AM/NEMU，容易把 QEMU PASS、toy payload、AM VGA 或 probe init 误判成完整 Ubuntu。
- **决策**: 新增 RV64 Linux/Ubuntu 专用 agent 和 instructions，把 `rv64-ubuntu-probe-loop`、`rv64-ubuntu-rootfs-loop`、`linux-display-loop`、`rv64gc-userland-loop`、`verilator-tapeout-readiness-loop` 接入总调度。近期不把 Vivado/FPGA 作为功能 bring-up 前置；Verilator 是主验证平台，但必须保留 core/SoC 可综合边界，DPI/host C++/SDL 只能作为仿真平台层。
- **理由**: 这样可以让完整 Ubuntu 的证据按 QEMU reference、NPC/Verilator target、`/init`、完整 `/etc/os-release`、官方 `/bin/sh`、rootfs mount 分层推进，避免未来开发因旧图任务或旧 agent 口径造成错判。
- **影响**: 后续 `npc/rv64` 任务必须优先读取新的 RV64/Linux/Verilator instructions；涉及 RTL 或性能优化时仍叠加 RTL 四段式和 NPC 性能优化流程。Vivado/FPGA 只作为后续硬件原型/PPA 节点，不替代当前 Verilator Linux/Ubuntu 功能闭环。

## 实现决策

### [31] ysyxSoC AM 运行时以 MROM 作为复位入口、SRAM 作为栈堆

- **日期**: 2026-05-23
- **状态**: 已决定
- **上下文**: ysyxSoC 的 NPC 复位后从 MROM 地址空间取指，MROM 只有读能力；若 AM 镜像继续链接到 PSRAM `0x80000000`，TRM 第一条指令和复位 PC 不一致，且栈/全局写可能落在只读区域。
- **决策**: `riscv32-ysyxsoc` 使用专用链接脚本：`.text/.rodata` 从 `0x20000000` 开始放入 4KB MROM，`_stack_pointer=0x0f001000`、`_heap_start=0x0f001000`、`PMEM_END=0x0f002000` 放在 8KB SRAM；NPC SoC `RESET_PC` 同步为 `0x20000000`，仿真内存模型显式提供 read-only MROM 和 writable SRAM。
- **理由**: 这样 `_start` 的第一条机器指令就是复位后 CPU 实际取到的第一条指令，栈和堆也满足可写性要求；MROM 写入在仿真侧立即报错，能尽早暴露不符合 ysyxSoC 约束的全局写。
- **影响**: ysyxSoC AM 程序应避免运行期写全局变量；IOE 查表、timer init 等运行时代码需要保持只读或改用栈/调用者缓冲。镜像大小也受 MROM 4KB 限制，超出时链接脚本会报 overflow。

### [30] NPC 可调结构参数以 `define.v` 宏区作为唯一默认来源

- **日期**: 2026-05-22
- **状态**: 已决定
- **上下文**: NPC core 中 reset PC、BPU 表规模、RAS 深度、I/D cache 容量和地址范围等参数此前分散在模块参数或局部常量中，后续若用外部软件生成配置，容易出现 `NpcCore`、前端、流水寄存器、cache 和 testbench 位宽不一致。
- **决策**: 把这类全局结构参数统一收口到 `npc/single/vsrc/include/define.v` 的可配置宏区，并用 `ifndef` 允许外部软件或 Verilator/仿真命令行覆盖默认值。模块内部只保留从宏派生出的别名或状态编码；通用 IP 的接口泛型如 SRAM 宽度、crossbar master/slave 数量继续保留为模块参数。
- **理由**: 全局可调参数需要单一事实来源，才能保证 BPU index 宽度、cache SRAM 深度、AXI 地址图和测试期望同步变化；而通用 IP 参数是实例化时的复用边界，不应强行全局化。
- **影响**: 后续新增 NPC core 级结构旋钮时优先加入 `define.v`，并同步修改相关 testbench 使用同一宏。外部软件生成配置时必须成组维护相关字段，例如 cache 的 line/count/index/offset/word bits 与 RAS entries/index/size/depth。

### [29] NEMU BPU 作为透明预测统计模型接入提交路径

- **日期**: 2026-05-19
- **状态**: 已决定
- **上下文**: 用户要求给 NEMU 增加可配置 BPU，并包含 RAS。NEMU 当前是功能参考模型，执行路径已经在 `inst.c` 中直接算出真实 `dnpc`；如果让预测结果参与取指或改写 PC，会把参考模型语义和性能模型耦合，增加 difftest/AM 回归风险。
- **决策**: BPU 只作为透明统计模型接入 `cpu-exec.c::exec_once()`：在 `isa_exec_once()` 完成并得到真实 `snpc/dnpc` 后，用当前 BTB/BHT/RAS 状态做一次预测、和真实结果对比、更新 counter，不改变 `cpu.pc = s->dnpc` 的功能提交语义。参数通过 Kconfig 暴露，默认启用 BTB/BHT/RAS 和 2-bit 饱和计数器。
- **理由**: 这样能观察分支方向、目标、BTB 与 RAS 命中率，同时保持 NEMU 作为参考模型的架构状态完全由真实执行语义决定；预测模型出错只影响统计，不会影响程序正确性。
- **影响**: 后续若要把 BPU 用于 NPC/RTL 设计，应把这里的统计结果作为参考指标或工作负载画像，而不是把 NEMU 的预测结果当成功能依赖。若未来引入更真实的前端时序模型，也应单独建模取指队列/错误恢复，不要直接让当前 BPU 改写解释器 PC。

### [28] NPC 设备层采用 NEMU 的 IO/设备分层模式

- **日期**: 2026-04-16
- **状态**: 已决定
- **上下文**: `npc/single/csrc/device/device.c` 把串口、RTC、键盘、VGA 四个设备的全部行为和 ~460 行代码都挤在一个文件里，增删设备或修改设备行为时必须在大文件中翻找。NEMU 则把 IO 注册/分发（`io/map.c + io/mmio.c`）和具体设备（`serial.c/timer.c/keyboard.c/vga.c`）分开两层。
- **决策**: 按 NEMU 模式拆分——每个设备有自己的 `.c` 文件，内部管理 static 状态，在 `init` 中通过 `npc_add_mmio_map()` 自行注册到 MMIO 总线；`device.c` 精简成只调用各设备 init/update/fini 的编排入口。VGA 的 SDL 键盘事件通过公共接口 `npc_kbd_push_event()` 跨设备路由。
- **理由**: 与真实 SoC 的总线-外设分层对应；增删设备只改一个文件和 device.c 的一行 init 调用；IO 基础设施（地址译码、边界检查、trace）与设备行为（回调逻辑）彻底解耦。
- **影响**: 新增设备时只需新建 `csrc/device/<name>.c`，实现回调并在 init 中调用 `npc_add_mmio_map()`，再在 `device.c` 加一行 init 调用即可，不需要修改 IO 框架。

### [27] 高级 GPU ABI 采用共享 AM 软件渲染层，而不是继续堆进宿主 VGA 设备

- **日期**: 2026-04-14
- **状态**: 已决定
- **上下文**: `am-tests` 的 `devscan` 并不满足于基础 `AM_GPU_FBDRAW`，它还会调用 `AM_GPU_MEMCPY` 和 `AM_GPU_RENDER`，把一棵 `gpu_canvas`/texture 树交给平台渲染。此前 NEMU 和 NPC 都只实现了基础 framebuffer 语义，导致 `mainargs=v` 能工作，但 `mainargs=d` 会在 GPU 高级寄存器处直接 `access nonexist register`。
- **决策**: 新增共享软件渲染层 `abstract-machine/am/src/platform/gpu_soft.h`，统一维护 512KB GPU 软显存、scratch buffer、`gpu_canvas` 递归渲染与缩放逻辑；`platform/nemu/ioe/gpu.c` 与 `riscv/npc/gpu.c` 只各自负责读取屏幕宽高、把最终像素写到 `FB_ADDR` 并做一次 sync。
- **理由**: 这样能把“高级 GPU ABI 语义”和“宿主显示设备实现”分层：前者只写一份，NEMU 和 NPC 共用；后者仍保持为简单的 `vgactl + framebuffer + sync` 平台边界，不需要让宿主设备层背上 `gpu_canvas` 树解释逻辑。
- **影响**: 后续若继续扩 `gpu_canvas` 类型或渲染策略，应优先改共享软件渲染层；平台文件只处理屏幕几何和 framebuffer 落点。对 NPC 来说，这也意味着之后若 `devscan` 仍跑不完，应先看 `timer_test`/disk/性能，而不是再回头怀疑 VGA 高级 ABI 缺口。

### [26] NPC 的基础黑屏初始化由宿主预清屏，guest 侧 GPU init 只做 sync

- **日期**: 2026-04-14
- **状态**: 已决定
- **上下文**: 在 `riscv32-npc` 平台补齐基础 VGA 后，`am-tests` 这类带 IOE 的程序一启动就会进入 `__am_gpu_init()`；若沿用 NEMU 平台那种 guest 侧 `for (i < w * h) fb[i] = 0` 整屏清零，对当前多周期 NPC 会先白白耗掉数十万次 `store`，导致程序还没进入真正测试主体就因为默认周期上限而超时。
- **决策**: 让 `npc/single/csrc/device/device.cpp` 里的宿主 `VgaDevice::Init()` 负责把 framebuffer 后端清零；`abstract-machine/am/src/riscv/npc/gpu.c` 里的 `__am_gpu_init()` 只保留一次 `sync` 提交，不再让 guest 侧逐像素扫满 400x300 的初始黑屏。
- **理由**: 初始显示语义并没有改变，窗口第一次提交时仍然是黑屏；但清零动作从“慢速 guest store 循环”转移到“宿主一次性内存初始化”后，AM 带 IOE 的程序就能在合理周期预算内进入真正逻辑，而不是被平台初始化本身拖死。
- **影响**: 后续若在同一仿真进程内引入热复位、程序重载或多次运行，同样要继续由宿主设备重置 framebuffer 后端，再让 guest 侧用一次 `sync` 观察到干净初始帧；不要再把大块清屏搬回 guest 路径。

### [25] NPC trace 采用“编译期能力 + 运行时开关”，并让 mtrace 排除 ifetch

- **日期**: 2026-04-14
- **状态**: 已决定
- **上下文**: `npc/single` 在接入 monitor/Kconfig/SDB 后，用户继续要求补齐 `itrace/mtrace/dtrace` 的完整使用体验。现有实现虽然已经有零散日志点，但完全依赖 `CONFIG_NPC_ITRACE/MTRACE/DTRACE` 这类编译期开关，且 `mtrace` 把 IFU 取指和数据访存混在一起，实际用起来既不灵活也噪音很大。
- **决策**: 保留 `CONFIG_NPC_ITRACE/MTRACE/DTRACE` 作为“二进制是否编进这项能力”的 build-time 选项；真正是否输出日志，统一交给 CLI 参数和 monitor 的 `trace ...` 命令在运行时控制。与此同时，把总线访问类型显式拆成 `ifetch/load/store`，其中 `mtrace` 只记录真实数据 `load/store`，`dtrace` 在 `device/map` 层统一记录 MMIO，IFU 取指不再混入 `mtrace`。
- **理由**: 这样既保留了 Kconfig 对最终二进制大小和能力面的控制，也让日常运行默认保持安静，需要时再临时开 trace；而把 ifetch 从 mtrace 中拆出去，能显著提升访存日志的可读性，避免用户在排查 load/store 问题时被顺序取指噪音淹没。
- **影响**: 后续若继续补反汇编、difftest 或更细粒度的设备 trace，应继续沿“build-time capability + runtime toggle”的边界扩展；同时默认把 `mtrace` 理解为数据路径观测，而不是泛化成“所有内存访问日志”。

### [24] NPC 单步停点通过 host 收尾周期对齐下一条待执行 PC

- **日期**: 2026-04-14
- **状态**: 已决定
- **上下文**: `npc/single` 已接入 NEMU 风格 monitor 后，`si 1` 虽然能正确提交 1 条指令，但 monitor 立即读取 `debug_pc_o` 时仍显示刚提交那条指令的 PC，观感上像“停在旧 PC”，与 NEMU 的单步体验不一致。
- **决策**: 保持 RTL 导出的 `debug_pc_o` 继续表示核心当前在途状态，不在 `NpcCore` 内部为 monitor 额外改写 PC 语义；改由 `cpu_exec()` 在定步命中最后一次提交后，再额外推进一个不产生新提交的收尾周期，让 monitor 返回时看到下一条待执行指令的 PC。
- **理由**: 这样可以把修正范围限制在 host monitor 语义层，不会污染 RTL 的状态定义、提交边界和 trap/exit 观测接口，也不会破坏 batch 连续运行路径。
- **影响**: 后续若继续扩 SDB/trace，应默认把“单步返回时可观察 PC”理解为 host 收尾后的下一条待执行地址，而不是重新修改 `NpcCore` 的 `debug_pc_o` 语义。

### [23] klib 的 stdlib 采用“native 复用宿主 libc，非 native 自管可回收堆”

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 当前工程中的 `am-kernels`、`abstract-machine` 和部分应用已经真实依赖 `malloc/free/rand/atoi` 等 `stdlib` 能力，但原有 `klib/src/stdlib.c` 只有线性 bump allocator 和极简 `atoi`，既不支持释放复用，也不足以覆盖工程里常见的字符串转数值场景。
- **决策**: `abstract-machine/klib` 在非 native 目标上实现基于 `heap` 区间的可回收分配器，并补齐 `calloc/realloc/labs/atol/strtol/strtoul`；而在 native 目标上不导出自定义 `malloc/free`，继续复用宿主 libc 的分配器路径。
- **理由**: 非 native 目标需要 freestanding 运行库提供完整的堆管理与数值转换；但 native 可执行文件若强行接管 `malloc/free`，容易截获宿主启动期或外部库内部的分配行为，把问题扩散到 SDL、工具链和宿主运行时边界。按目标类型分开处理，既能补齐工程能力，又能降低宿主侧副作用。
- **影响**: 后续若继续补 `stdlib`，应优先围绕工程真实使用面扩展，并保持“native 复用宿主 libc、非 native 自管 freestanding 能力”的边界，不要把宿主进程运行时强行拉进 klib 的自定义分配器。

### [22] NPC 仿真器 C++ 侧采用 NEMU 风格分层，而不是继续扩单个 main.cpp

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 最小 DPI bring-up 已经能跑通 `hello`，但用户明确要求不要把仿真器长期维持为“一个 `main.cpp` 做完所有平台逻辑”的教学式结构，希望后续输入、设备、trace、difftest 和更多平台能力都建立在更商业化、可维护的边界之上。
- **决策**: `npc/single/csrc` 采用参考 NEMU 的 `monitor`、`memory/paddr`、`device/map`、`device`、`cpu/cpu-exec`、`dpi`、`utils` 分层，`main.cpp` 只保留 bootstrap；同时延续 NEMU 兼容地址图和 NEMU/AM 兼容键盘 ABI，让 AM/NEMU 现有软件假设尽量不变地迁到 NPC。
- **理由**: 这样能把“参数与初始化”“物理地址空间”“设备注册与 host bridge”“执行循环”“DPI 边界”拆成稳定职责面，后续补设备或调试设施时不会再次陷回大文件耦合；同时继续复用 NEMU/AM 的地址与输入约定，可以显著降低平台迁移成本。
- **影响**: 后续若补 `mtime/mtimecmp`、VGA、串口状态、trace、difftest 或更真实总线，应优先沿现有分层各自扩展；`main.cpp` 不再承担平台功能实现，AM 侧也继续沿 NEMU 兼容 ABI 接输入和 MMIO。

### [21] NPC bring-up 先采用“core 外 DPI 平台层 + NEMU 兼容地址图”

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 用户当前已经完成了一版 RV32I 核心，但还没有外设和 SoC 外壳；下一步目标是用 Verilator 把 AM 编出来的程序镜像直接装进 NPC 的 `pmem`，至少先跑通取指、最小 MMIO、串口输出和程序正常退出，而不是一开始就上复杂总线或完整平台。
- **决策**: 在 `npc/single` 中新增 `NpcSimTop.sv` 和 `csrc/main.cpp` 组成的最小 DPI 平台层，保持 `NpcCore` 只暴露 IFU/LSU 握手接口；平台层对齐 NEMU 现有地址图，先提供 `pmem@0x80000000`、`serial@0xa00003f8`、`rtc@0xa0000048` 与 `kbd@0xa0000060`。同时把 `abstract-machine` 的 `npc` 平台改成同一套串口/RTC/ebreak 约定，并新增 `riscv32-npc` 架构脚本。
- **理由**: 这样能在最小改动核心的前提下快速形成“AM 镜像 -> NPC 平台 -> RV32I 核心”的可运行闭环，复用已有 NEMU/AM 软件约定，也为后续继续扩展 MMIO、trap handler、difftest 和更真实总线留出稳定平台边界。
- **影响**: 后续若补 UART、mtime/mtimecmp、VGA、键盘等功能，应优先继续扩展 `NpcSimTop` 的 DPI 地址译码和 C++ 宿主实现；除非核心总线协议本身要升级，否则不要把平台语义重新塞回 `NpcCore` 内部。

### [20] 在无 CSR/trap handler 阶段，把 ecall/ebreak 收口为 EEI 退出协议

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 当前 `npc/single/vsrc/NpcCore.v` 已能译码 `ecall/ebreak`，但此前只是把它们和普通异常一样送进 `TRAP` 状态卡死；对“CPU 跑程序并优雅退出”这个目标来说，外部 testbench 无法区分这是程序主动结束还是核心异常炸掉。
- **决策**: 顶层新增 `CORE_STATE_HALT`，并导出 `exit_valid`、`exit_is_ecall`、`exit_is_ebreak`、`exit_code` 四个退出观测口；其中 `exit_code` 来自寄存器堆中的 `a0(x10)`。普通异常仍保留在 `TRAP` 路径，`ecall/ebreak` 单独进入 `HALT`。
- **理由**: 当前还没有最小 CSR / mtvec / mepc / mcause / mtval 闭环，与其让 `ecall/ebreak` 伪装成普通 trap，不如先把它们定义为 EEI 结束协议，方便仿真环境、测试程序和后续 pmem harness 稳定收尾。
- **影响**: 后续接 testbench、程序加载器或 difftest 时，应优先消费 `exit_*` 信号来结束仿真；未来即使补上最小 trap handler，也应保留这组观测口作为功能仿真阶段的稳定退出接口。

### [19] NPC 首版 RV32I 核采用“单在途多周期 + 统一控制包”骨架

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 用户要求在 `npc/single/vsrc` 中直接落一版“近似商业级别”的 RV32I 非流水线核心，而当前工程只有 `define.v` 和 `RegisterFile.v` 的占位骨架；若继续按教学式超长组合单周期硬拼，很难同时把访存语义、提交边界和异常边界收清。
- **决策**: 顶层 `NpcCore` 采用 `FETCH_REQ / FETCH_WAIT / DECODE / EXEC / MEM_REQ / MEM_WAIT / WB / TRAP` 的单在途多周期状态机；译码产出 packed ctrl bus，`ALU` / `CompareUnit` / `LSU` / `WBU` 各自负责纯组合语义，寄存器写回统一收口在 WBU，顶层只负责阶段推进、重定向和 trap 裁决。
- **理由**: 这种方案仍属于非流水线实现，但比“所有逻辑一拍组合到底”的教学写法更接近可维护工程：模块边界清楚、访存和提交容易插入观测点，后续升级到 CSR / trap controller / difftest 时不用推翻主数据通路。
- **影响**: 后续若补最小 machine CSR、mtvec/mepc/mcause/mtval 或 NEMU 对拍，应优先沿这条统一控制包和统一提交边界继续演进；当前 trap 仍是 halt-only，需要在下一轮升级成可恢复 trap 流。

### [13] 单周期 NPC ALU 采用“指令字段直编码 + 共享比较通路”

- **日期**: 2026-04-07
- **状态**: 已决定
- **上下文**: `npc/single` 当前还在搭建单周期数据通路，用户要求新增一版覆盖 RV32I 的 ALU，并尽量借鉴成熟开源核的结构，让后续译码和分支接入更直接。
- **决策**: `npc/single/vsrc/alu.v` 保持纯组合单周期实现；对 `OP/OP-IMM` 指令直接使用 `{funct7[5], funct3}` 作为 4 位 `select_mod`，并额外保留 `1110` 作为 `LUI/src2` 直通、`1111` 作为 `src1` 直通；比较输出 `zero/less_than/less_than_u` 统一由减法结果派生。
- **理由**: 这种控制编码能显著简化单周期控制器译码；而共享减法/比较通路可以把 `SUB/SLT/SLTU/BEQ/BNE/BLT/BGE/BLTU/BGEU` 收到同一套比较基础上，减少重复逻辑并保持执行语义一致。
- **影响**: 后续若补 `decoder`、`branch unit` 或 `EXU top`，应优先按这套控制码和比较输出接口接入，而不是重新定义另一套 ALU 编码。

## 工具与流程决策

### [1] 交互式仿真程序禁止外层截断输出

- **日期**: 2026-03-30
- **状态**: 已决定
- **上下文**: agent 为了缩短终端输出，曾用管道把 NEMU 运行结果交给 tail 处理，导致 NEMU 界面与交互行为异常。
- **决策**: 对 NEMU、NVBoard、menuconfig、SDL 类交互程序，一律直接运行原命令，不在外层追加 tail、head、sed、grep 或类似截断/消费输出的管道。
- **理由**: 这类程序依赖完整终端或图形界面输出链路，额外管道会破坏界面刷新、标准输入输出行为和交互体验。
- **影响**: 后续 agent 需要通过程序自身日志开关控制输出量，而不是通过 shell 管道截断交互程序输出。

### [2] 代码建议默认不直接落盘

- **日期**: 2026-03-30
- **状态**: 已决定
- **上下文**: 用户要求所有代码建议先在对话框中给出，保留人工审核权，不希望 agent 在未明确授权时直接修改工作区文件。
- **决策**: 后续默认以对话框代码片段、补丁建议或实现说明的形式回复；只有当用户明确要求直接修改文件时，agent 才执行编辑。
- **理由**: 这样更符合用户的审阅流程，也能降低误改工作区文件的风险。
- **影响**: 后续回答实现类问题时，agent 优先提供可复制的代码和修改说明，而不是直接应用补丁。

### [3] NEMU 调试默认采用非交互优先流程

- **日期**: 2026-04-01
- **状态**: 已决定
- **上下文**: agent 在处理 NEMU/SDB 相关任务时，若直接启动交互式 monitor 或 SDL 输入测试，当前工具无法稳定向运行中的前台进程持续注入 stdin，也不应把交互测试默认转嫁给用户手动在 shell 中代打。
- **决策**: 后续处理 NEMU 调试任务时，默认优先选择 `--batch`、日志、trace、watchpoint、表达式求值、专用测试程序、配置切换或临时代码插桩等可脚本化路径；仅在确认没有替代方案时，才向用户说明剩余的最小人工步骤。
- **理由**: 该流程与当前工具能力匹配，也能减少交互式仿真把测试责任转移给用户的问题。
- **影响**: agent 在 NEMU 相关任务中需要先判断是否存在等价的非交互调试手段，再决定是否启动交互式 monitor 或 SDL 程序。

### [4] NEMU monitor 启动命令默认由 agent 自行预置

- **日期**: 2026-04-01
- **状态**: 已决定
- **上下文**: 已验证在当前环境中，NEMU monitor 可通过启动时喂入 stdin 的方式自动执行 `c`，不必等待用户在 `(nemu)` 提示符下人工输入。
- **决策**: 对仅需执行少量 monitor 启动命令的任务，agent 默认采用启动时预置 stdin 或直接使用 `-b`/等价目标的方式自行推进执行。
- **理由**: 这能消除最常见的“卡在 monitor 等用户敲 c”问题，且不依赖运行中向前台 readline 进程二次注入输入。
- **影响**: 后续 agent 在运行 AM on NEMU 或普通镜像时，若只需从 monitor 进入执行态，应优先用 `printf 'c\n' | ...`、make 的 `c` 目标或 `--batch` 方案。

### [5] 必要交互测试由 agent 先自行承担

- **日期**: 2026-04-01
- **状态**: 已决定
- **上下文**: 用户明确要求在当前工作区中，agent 不应把所有测试都强行自动化成非交互流程；对于确实需要 shell 或 monitor 交互的测试，若工具支持，应由 agent 直接执行必要键入和终端交互，而不是要求用户代打。
- **决策**: 后续在本工作区处理 NEMU/AM/NVBoard 等任务时，agent 应阅读终端输出并在工具支持范围内直接完成必要的 shell/monitor 输入；仅当宿主输入注入或前台进程交互超出当前工具能力时，才说明限制并给出替代验证路径。
- **理由**: 这更符合用户的工作流，也避免把本可由 agent 自己完成的交互步骤转嫁给用户。
- **影响**: agent 需要区分“能自行完成的交互”和“当前工具确实无法完成的交互”，不能简单以“优先自动化”为由回避所有交互测试。

### [6] 短代码建议必须直接展示正文

- **日期**: 2026-04-02
- **状态**: 已决定
- **上下文**: 用户多次要求对几行补全或局部修正直接给出可复制代码，但此前回复中曾出现只描述位置、未完整展示代码正文的情况，导致用户在新聊天中需要重复强调同一偏好。
- **决策**: 在本工作区中，只要用户明确要求“直接给代码”“小提示可以显示代码”或等价意图，agent 就必须直接展示完整的最小代码片段；不得用空白、占位、隐藏或仅文字描述替代代码本体。
- **理由**: 这符合用户的审阅方式，也能避免因展示不完整而反复沟通同一细节。
- **影响**: 后续对未落盘的实现建议，agent 应把“文件位置说明”和“代码正文”分开表达，并优先保证代码正文完整可复制。

### [7] 短代码建议优先使用缩进代码块展示

- **日期**: 2026-04-02
- **状态**: 已决定
- **上下文**: 虽然已要求 agent 直接展示短代码正文，但当前聊天界面对部分围栏代码块显示不稳定，曾出现解释文本保留而代码正文被吞掉的现象。
- **决策**: 在本工作区中，对几行补全、局部修正和实现方法说明，agent 优先使用缩进代码块或直接缩进的多行代码展示，不依赖围栏代码块；若上一条代码未正常显示，下一条必须完整重发代码正文。
- **理由**: 这能降低界面吞掉代码正文的概率，确保用户在新旧聊天中都能直接看到可复制代码。
- **影响**: 后续短代码建议的展示形式将从“是否写代码”进一步细化为“如何稳定显示代码”，以保证实际可见性。

### [8] 除整文件大改外默认直接展示代码正文

- **日期**: 2026-04-02
- **状态**: 已决定
- **上下文**: 用户进一步明确，希望除了整文件级的大段源码修改外，其余代码说明都直接展示代码，不要把“直接给代码”的适用范围限制在几行补全或特别短的小提示上。
- **决策**: 在本工作区中，只要是未落盘的代码建议且规模不属于整文件级大改，agent 默认直接展示完整代码正文；整文件级大改可优先给关键片段、补丁思路和修改位置，但若规模可读，仍优先展示关键代码。
- **理由**: 这更符合用户的阅读和审阅方式，也能减少来回追问“代码到底在哪”的沟通成本。
- **影响**: 后续回答实现问题时，agent 将把“直接展示代码”作为默认表现形式，而不是仅在极短片段场景下启用。

### [9] 避免块级代码格式以绕开聊天界面空白灰块

- **日期**: 2026-04-02
- **状态**: 已决定
- **上下文**: 实际对话中已观察到，无论是围栏代码块还是缩进代码块，当前聊天界面对部分代码段都会渲染成空白灰块，导致解释文字存在而代码正文不可见；此前“优先用缩进代码块”的修正并没有解决这个显示层问题。
- **决策**: 在本工作区中，对非整文件级代码建议默认避免使用任何块级代码格式，改用普通正文逐行展示代码，必要时把每一行代码单独成行或使用逐行内联代码；若上一条代码未显示，下一条必须按这种非块级方式完整重发。
- **理由**: 问题根因在于聊天界面对块级代码格式的渲染异常，而不是代码内容本身；只有避开块级代码容器，才能稳定显示代码正文。
- **影响**: 后续展示代码时，agent 需要把“给代码”和“代码怎么在界面稳定显示”一起考虑，默认不再用传统 markdown 代码块承载短中等规模代码。

### [10] 未落盘代码建议恢复默认代码块展示

- **日期**: 2026-04-02
- **状态**: 已决定
- **上下文**: 之前为绕开聊天界面偶发的空白灰块，工作区先后引入“缩进代码块”“非块级正文逐行展示”等多层回退规则，导致约束重复且相互冲突；用户现明确要求恢复默认代码框输出。
- **决策**: 后续对未落盘的代码建议默认使用标准 Markdown 代码块展示；只有当用户明确要求其它展示形式，或实际确认代码块显示异常时，才降级为普通正文逐行展示。
- **理由**: 默认代码块更符合常规阅读与复制习惯，也能显著简化工作区指令；显示异常应作为特例处理，而不是常态规则。
- **影响**: 先前关于“默认避免块级代码格式”的临时性展示 workaround 不再作为默认策略，后续仅保留为兼容性回退方案。

### [11] 直接落盘修改必须附带设计意图注释

- **日期**: 2026-04-02
- **状态**: 已决定
- **上下文**: 用户要求 agent 在直接修改工作区代码时，不要只留下机械实现，而要在修改点附近明确说明“为什么这么改”和“改完能带来什么效果”；同时希望这条规则在后续会话中持续生效。
- **决策**: 后续只要 agent 直接修改代码文件，就在修改块前后补充简短中文注释；若是一组连续改动，可用 1 到 2 条块前注释统一说明目的与收益，避免重复噪音。
- **理由**: 这样用户回看代码时能直接看到设计意图与收益，减少重复追问“这段改动是干什么的”。
- **影响**: 后续直接落盘实现时，agent 需要同时交付“代码本身”和“修改意图说明”，并在不影响可读性的前提下控制注释粒度。

### [12] RV32 分层译码优先使用宏表项表达

- **日期**: 2026-04-02
- **状态**: 已废弃（2026-05-19 由分区 `static inline` 执行块替代）
- **上下文**: `nemu/src/isa/riscv32/inst.c` 已从线性 `INSTPAT` 重构为按 `opcode/funct` 分层分发，但继续用大段 if-else 表达时，查看同类指令和补充新指令仍然不够直观。
- **决策**: 保留现有 `opcode -> funct3/funct7` 的热路径结构，但将类内实现改成 X-macro 表项配合 switch；其中 `OP-IMM/LOAD/STORE/BRANCH` 按 `funct3` 列表展开，`OP` 按 `funct3/funct7` 组合 key 展开。
- **理由**: 这样不会退回线性穷举，同时能把一类指令稳定排成“编码 -> 行为”的表状结构，便于阅读、比对和后续维护。
- **影响**: 该决策是历史阶段选择。2026-05-19 后 `inst.c` 已改为“基础设施集中、RV32I 热路径直达、M/B/C 扩展各自独立执行块”的结构，后续扩展 RV32 指令应优先沿当前分区和直接 `switch` 组织维护，不再新增 X-macro 表生成层。

### [14] NPC 开发前先读取本地学习资料

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: `npc/single/design/study/` 已沉淀出 RV32I、功能仿真语义、硬件架构三条稳定学习线，但原有 agent 流程只强制读取记忆文件，没有把这些资料纳入正式执行流，导致后续开发容易脱离现有知识基线重复摸索。
- **决策**: 将“索引 README → 专题正式笔记 → tmp 原始摘录”的本地学习资料读取顺序固化到 `.github/copilot-instructions.md`、`.github/instructions/memory-protocol.instructions.md`、`.github/instructions/npc-study.instructions.md`、`.github/agents/npc.agent.md` 和 `.github/agents/ysyx-coordinator.agent.md` 中；后续处理 `npc/single/**` 任务时必须先读 `npc/single/design/study/README.md`，再按任务类型进入 RV32I / functional-sim / hardware-architecture 对应资料。
- **理由**: 这样能把已经整理好的学习成果变成可复用输入，统一术语和边界，减少反复翻规范、重复试错和实现方向漂移。
- **影响**: 后续 NPC 相关任务在规划或实现前都应先说明参考了哪些 study 文件；未来若其他模块也沉淀出本地学习资料，可沿用同样的“索引优先、正式笔记优先、tmp 兜底”流程。

### [15] 工作区 agent 系统采用“图任务 + 工作流 agent + 模块专家”三层结构

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 当前工作区已经沉淀出模块专家 agent、记忆系统和 NPC 学习资料，但复杂任务仍主要依赖人工口头串联，缺少类似 NVIDIA Marco 的图任务求解、子任务 agent 配置和工具/知识绑定机制。用户希望把工作区升级成真正可调用的 AI 驱动硬件开发环境，同时仍以现有可运行的 NEMU、AM、am-kernels、NPC/Verilator 协同链路为主。
- **决策**: 在现有模块专家之上新增两层：由 `ysyx-coordinator` 先按静态图或动态图切分任务节点，再引入 `hardware-flow` 负责 `NEMU + AM + NPC/Verilator` 闭环，`agent-system` 负责 `.github/` 下的 agent / instructions / memory / blueprint 演进；同时用 `.github/agentic-hardware-blueprint.md` 统一沉淀节点契约、静态图模板和阶段路线图。
- **理由**: 这样既吸收了 Marco 的核心方法，也不会脱离当前工作区真实可执行的工程后端；复杂任务能被稳定拆成有输入、输出、验证标准和回退策略的节点，而不是退化成松散的多轮提示词交互。
- **影响**: 后续大型任务应优先判断是否命中 `rv32-bringup`、`am-device-loop`、`agent-env-refactor` 等静态图；未来接入 difftest、Yosys/STA 或更多 EDA 节点时，也应继续沿用这套图任务协议扩展，而不是另起一套调度逻辑。

### [16] 当前默认闭环先收敛到 NEMU 参考路径

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 在第一阶段骨架落盘后，用户明确说明 `npc` 尚未实现，因此当前如果继续把 `NPC/Verilator` 放在默认主闭环里，会让调度层错误地把未来目标当成现成依赖，造成伪闭环。
- **决策**: 当前默认工作流改为 `am-kernels -> abstract-machine -> NEMU(reference)`，并新增 `rv32-reference-loop` 作为默认静态图；`rv32-bringup`、`rtl-sim`、`compare-or-difftest` 只在 NPC/Verilator 目标实现后启用。
- **理由**: 先围绕真实可执行的参考后端收敛工作流，能让 AI 驱动环境从一开始就建立在可验证链路上，而不是依赖尚未落地的 target 节点。
- **影响**: 近期工作重点从“补 NPC 运行链路”调整为“稳定 NEMU 参考闭环与结构化记录”；待 NPC 实现后，再把 target 路径和对比诊断按既有图任务协议接入。

### [17] 图任务采用“静态图优先、动态图补洞、稳定后模板化”策略

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 仅有静态图会让系统在异常、回归和跨模块边界问题上不够灵活；仅靠动态图又会让流程长期停留在临时编排状态，难以积累成稳定方法。NVIDIA Marco 的强项正是在“图模板 + 动态扩图 + 专用工具/知识绑定”之间取得平衡。
- **决策**: 工作区图任务默认先命中静态图模板；当模板缺少证据链、定位链或边界澄清步骤时，再做最小动态扩图；如果某类动态图反复稳定出现，就把它升级成新的静态图模板，例如新增 `regression-debug-loop`。
- **理由**: 这样既能保持流程可复用、可审计，也能在真实硬件调试场景里保留足够的探索与恢复能力，避免体系退化成僵硬模板或纯临时拼装。
- **影响**: 后续 coordinator、hardware-flow 和 agent-system 在处理失败恢复、日志收集、边界澄清时都应优先考虑“是否需要插入诊断节点”，同时注意把成熟的动态子图沉淀回蓝图。

### [18] 单次图任务产物与长期记忆分层保存

- **日期**: 2026-04-13
- **状态**: 已决定
- **上下文**: 当前 `memory/` 已承担项目状态、设计决策和长期经验的沉淀职责，但随着图任务逐渐复杂，仅靠记忆文件无法干净表达单次任务的节点状态、证据链、派发历史和阶段性阻塞，容易让长期记忆被运行细节污染。
- **决策**: 新增 `.github/task-runs/` 作为单次图任务的结构化产物目录，并提供 `task-report.template.md` 与 `dispatch-log.template.md` 两个模板；`memory/` 继续只保存稳定结论和长期经验，节点级执行细节优先写入 `task-runs/`。
- **理由**: 这样既保留了 Marco 风格的证据链和任务执行可审计性，又能维持长期记忆的简洁度与可复用性。
- **影响**: 后续重要图任务在完成时，除了更新 `project-status.md`、`decisions.md`、模块记忆外，还应在 `.github/task-runs/<日期-任务名>/` 下维护对应的 `task-report.md` 与 `dispatch-log.md`。

### [19] Bug 修复默认按“架构/数据流根因”而不是“补丁叠补丁”推进

- **日期**: 2026-04-14
- **状态**: 已决定
- **上下文**: 随着 `npc`、`nemu`、`abstract-machine` 和工作区 agent 系统逐步工程化，单点报错往往只是更深层职责错位、状态机边界不清或数据流断裂的表象；如果每次都只围绕症状补一层特判，短期虽然能过当前 case，但会不断累积不可见耦合，最终演化成难以定位和清理的技术债。
- **决策**: 后续 agent 处理 bug 时，必须先从架构职责、模块边界、控制流和数据流定位根因，再在正确抽象层修复；默认禁止“哪里坏了就在哪里缝一块”的补丁式修法。只有在明确属于兼容层、过渡期或外部约束导致无法立即做根修时，才允许保留局部补丁，并且必须显式说明边界、退出条件和债务控制方式。
- **理由**: 这样能把修复动作和系统结构对齐，避免局部症状消失但全局复杂度持续上升，也更符合当前工作区希望沉淀长期可维护架构而不是堆临时 workaround 的方向。
- **影响**: 后续无论是代码实现、review 还是 task-run 记录，遇到 bug 修复都应优先解释“根因在什么层、修复为什么放在这一层、数据流如何恢复正确”，而不是只记录表面补丁点。

### [20] NPC RTL 源码采用功能目录 + 统一 filelist 管理

- **日期**: 2026-05-22
- **状态**: 已决定
- **上下文**: `npc/single/vsrc` 的 RTL 模块数量已经增长到 30+，继续把所有 `.v/.sv` 平铺在同一目录会让新增模块、综合边界、仿真壳和 testbench 路径维护变得混乱。
- **决策**: `vsrc` 按功能域划分为 `include/core/frontend/decode/execute/memory/cache/bus/common/pipeline/writeback/sim`，并新增 `vsrc/filelist.mk` 集中维护各模块路径变量、`RTL_CORE_SRCS`、`SIM_TOP_SRCS` 和 `VSRCS`；主 Makefile、模块 testbench 与 STA 入口共享这份清单。
- **理由**: 这是商业 RTL 工程中常见的组织方式：目录表达架构职责，filelist 表达工具入口，避免每个构建脚本各自散落一份路径清单，也能继续明确区分可综合核心和 DPI 仿真壳。
- **影响**: 后续新增或移动 RTL 文件时，应先选择对应功能目录，再更新 `vsrc/filelist.mk`；不要重新在 `Makefile` 或 testbench 中直接写平铺文件路径。
