# NPC (RTL CPU) 模块笔记

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-04-14: `npc/single` 现在在程序结束时会补一组接近 NEMU 的统计摘要：`npc: HIT GOOD/BAD TRAP`、`host time spent`、`total guest instructions`、`simulation frequency`；同时 `info s` 也已扩展出 `host-us` 和 `inst/s`，方便在 monitor 里查看累计统计。
- 2026-04-14: `npc/single` 现在已经带上长跑 progress 机制：默认配置项 `CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL` 控制 progress 间隔，运行时也支持 `--progress/--no-progress/--progress-interval`；在 batch 或 monitor 的 `c` 路径下，CPU 会按“已提交指令数”周期性打印 `[progress] ...`，帮助区分“CoreMark 还在跑”和“仿真真的卡死”。
- 2026-04-14: `npc/single` 的周期上限现在已经支持 `0 = unlimited`：`menuconfig` 里的 `NPC_DEFAULT_MAX_CYCLES` 不再只是“改一个更大的默认数”，而是可以直接设成 `0` 关闭超时；命令行 `--max-cycles 0` 也走同一条语义，welcome 会显示 `max cycles: unlimited`，适合 CoreMark 这类较大的测试。
- 2026-04-14: 已对 `npc/single` 默认 batch 行为做完真实回归：重新生成 `default_defconfig`、重编仿真器并重建 `hello-riscv32-npc.bin` 后，直接 `make -C npc/single run` 不传 `-b` 时 welcome 会明确显示 `batch: ON`，hello 也会自动跑完退出；另外通过预置 `help/q` 的 stdin 实测确认 `--no-batch` 仍能进入 `(npc)` monitor 并正常处理命令。
- 2026-04-14: `npc/single` 的默认配置现在已经把 batch 模式打开，直接跑测试镜像时默认等价于传 `-b`，不会再每次先停在 `(npc)` 等手动输入 `c`；如果只是临时想进 monitor，可以直接追加 `--no-batch`，不用回去改 Kconfig 再重编。
- 2026-04-14: `npc/single` 现在已经把 `Ctrl-C` 的交互语义理顺了：连续执行中的 `Ctrl-C` 仍然只会打断执行并回到 `(npc)`，而停在 `(npc)` 提示符上再按 `Ctrl-C` 会直接退出整个进程，不再出现屏幕上有 `^C` 但 NPC 还挂着、只能删终端收场的情况。
- 2026-04-14: `npc/single` 的 `itrace/mtrace/dtrace` 现在已经不是纯编译期宏功能，而是“编译期能力 + 运行时开关”的 trace 子系统：CLI 支持 `--itrace/--itrace-cond/--mtrace/--dtrace`，monitor 支持 `info t` 与 `trace ...`，且已用 `hello-riscv32-npc.bin` 实测通过 batch 和 monitor 两条路径。
- 2026-04-14: 当前 `mtrace` 已经显式排除了 IFU 取指，只记录真实数据 `load/store`；`dtrace` 则在 `device/map` 层统一记录 MMIO 访问，串口输出等设备行为可以直接从日志里看到。
- 2026-04-14: `npc/single` 现在已经带上一套接近 NEMU 的 monitor 外壳：有 `Kconfig/default_defconfig/menuconfig` 配置链，有蓝色 welcome/log，有 `(npc)` 交互提示符，也有 `help/c/q/si/info/x/p/w/d` 这组基础 SDB 命令；目前已用 `hello-riscv32-npc.bin` 实测通过 `help/info r/p/x/si/w/c/d/q` 与 `-b` batch 直跑两条路径。
- 2026-04-14: `npc/single/csrc/monitor/expr.cpp` 已支持十进制/十六进制常数、`$pc/$xN/$abi` 寄存器、括号、`+ - * / == != && || !` 和一元解引用，`watchpoint.cpp` 维护 32 项 watchpoint 池；因此当前的 `p EXPR`、`x N EXPR`、`w EXPR` 已经不是壳命令，而是接到了真实 RTL + PMEM/MMIO 可观察状态。
- 2026-04-14: `RegisterFile.v -> NpcCore.v -> NpcSimTop.sv` 已经把 32 个 GPR 扁平导出到 Verilator 顶层，host monitor 侧不再靠“软件影子寄存器”猜状态；`info r`、寄存器表达式求值和 watchpoint 都直接读取 RTL 导出的调试口。
- 2026-04-13: `npc/single/README.md` 已补齐当前 bring-up 环境的使用说明，覆盖目录结构、依赖、直接运行与 AM 侧运行入口、`RUN_ARGS/NPC_RUN_ARGS`、键盘两种模式、trace、退出/超时语义和当前限制；后续接手这个环境时，应该先读这份 README，再决定是改 RTL 还是改宿主平台。
- 2026-04-13: `npc/single/csrc` 已从最初的单文件 harness 重构成参考 NEMU 的分层仿真器：`main.cpp` 现在只做 bootstrap，`monitor/` 负责参数和初始化顺序，`memory/paddr.cpp` 负责 PMEM 装载与物理地址访问，`device/map.cpp + device.cpp` 负责 MMIO 注册和串口/RTC/键盘设备，`cpu/cpu-exec.cpp` 负责 Verilator 生命周期与执行循环，`dpi.cpp` 负责 DPI 总线桥。
- 2026-04-13: `npc/single` 的键盘设备已不再是空读占位；当前 `device.cpp` 同时支持 TTY 原始模式和非 TTY scripted stdin 模式，把宿主输入编码成 NEMU/AM 兼容的 `keydown/keycode` 事件流，经 `KBD_ADDR(0xa0000060)` 暴露给 AM 程序，`am-tests` 的 `readkey test` 已能在 `riscv32-npc` 上观测到 `A DOWN/UP`。
- 2026-04-13: `npc/single` 现已在 `NpcCore` 外层新增 `NpcSimTop.sv` + `csrc/main.cpp` 组成的最小 Verilator/DPI 平台：支持把 `.bin` 镜像装载到 `0x80000000` 起始的 `pmem`，并通过 DPI 总线提供 `SERIAL(0xa00003f8)`、`RTC(0xa0000048)` 和 `KBD_ADDR(0xa0000060, 初始版本为键盘空读占位)` 这组最小 MMIO；`make -C npc/single run IMG=...` 可以直接运行镜像。
- 2026-04-13: `NpcCore.v` 现已把 `ecall/ebreak` 从普通 trap 路径中拆出来，新增 `HALT` 状态和 `exit_valid`、`exit_is_ecall`、`exit_is_ebreak`、`exit_code` 输出；当前约定退出码来自 `a0(x10)`，便于 testbench 或后续 pmem harness 直接判断程序是否优雅结束。
- 2026-04-13: `npc/single/vsrc` 已新增一版 define 驱动的 RV32I 非流水线核心：顶层 `NpcCore.v` 采用单在途多周期状态机，外围补齐 `DecodeUnit.v`、`ImmGen.v`、`ALU.v`、`CompareUnit.v`、`LSU.v`、`WBU.v`，并把 `RegisterFile.v` 重写为双读单写、x0 硬屏蔽的寄存器堆；当前顶层已暴露 IFU/LSU 握手接口、commit 观测口和 trap 停机口。
- 2026-04-13: 当前这版核心已覆盖 RV32I 主干整数指令、分支跳转与基本 system trap 入口，但 trap 仍是 halt-only 语义，尚未接入最小 machine CSR、mtvec 重定向与 MRET 返回闭环。
- 2026-04-13: 已在 `.github/copilot-instructions.md`、`.github/instructions/memory-protocol.instructions.md`、`.github/instructions/npc-study.instructions.md`、`.github/agents/npc.agent.md`、`.github/agents/ysyx-coordinator.agent.md` 中固化 NPC 的“study-first”流程；后续处理 `npc/single/**` 任务时，应先读 `npc/single/design/study/README.md`，再按数据通路、functional-sim、hardware-architecture 三条线补读对应笔记后再编码。
- 2026-04-13: 本轮“硬件架构学习线”文档已经完成最终复检；当前确认无告警的文件包括 `npc/single/design/study/RISC-V-spec-hardware-architecture-notes.md`、`npc/single/design/study/RISC-V-spec-hardware-architecture-scope.md`、`npc/single/design/study/README.md`、`npc/single/design/study/tmp/README.md`、`.github/memory/project-status.md`、`.github/memory/modules/npc.md`，后续 agent 可以直接把这组文档作为 machine-level bring-up 的稳定入口。
- 2026-04-13: 已补出一条和 functional-sim 笔记并行的“硬件架构学习线”，当前相关结论已整理到 `npc/single/design/study/RISC-V-spec-hardware-architecture-scope.md` 与 `npc/single/design/study/RISC-V-spec-hardware-architecture-notes.md`；对 NPC 来说，这条线的核心结论是：先把 single hart、最小 machine CSR、trap controller、mtime/mtimecmp 预留与 pmem/mmio 边界建起来，再谈 supervisor、PMP 和更复杂平台扩展。
- 2026-04-13: 与 NPC bring-up 直接相关的规范学习文档已经完成最终收尾验证；`npc/single/design/study/RISC-V-spec-functional-sim-notes.md` 的章节标题现已唯一化，`RISC-V-spec-functional-sim-scope.md` 与 `tmp/README.md` 也已补齐结尾换行，当前这组 study 文档可作为后续 agent 继续补 PMEM、CSR、trap harness 的稳定基线。
- 2026-04-13: 已对 `npc/single/design/` 中新增的两本 RISC-V 规范做“按功能仿真目标筛选式学习”，当前已经把和 NPC bring-up 最相关的 EEI、内存访问、异常陷阱、Zicsr、M 模式 CSR、ECALL/EBREAK、MRET、WFI、复位等内容整理到 `npc/single/design/study/RISC-V-spec-functional-sim-scope.md` 与 `npc/single/design/study/RISC-V-spec-functional-sim-notes.md`，并在 `npc/single/design/study/tmp/` 保留了临时提取文本。
- 2026-04-13: 已通读 `npc/single/design/RV32I.pdf`，并把单周期 RV32I 的模块划分、立即数规则、控制包字段、WBU 提交原则整理到 `npc/single/design/study/README.md`、`npc/single/design/study/RV32I-ai-notes.md`、`npc/single/design/study/RV32I-implementation-checklist.md`，后续补 NPC 主通路前可先读这三份笔记对齐术语和边界。
- 2026-04-07: `alu.v` 已重建为面向 RV32I 单周期执行路径的组合 ALU，当前支持 `ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND/LUI(src2 直通)`，并额外输出 `zero`、`less_than`、`less_than_u` 供分支判断直接复用。
- 2026-04-07: `IFU/bh_bt.v` 已补成最小 BHT 闭环，当前支持 `pc_lookup` 组合查表输出 `pre_state`/`jump_if`，以及 `pc_wb_bt + state_wb_bh` 的同步写回；表项格式为 `{tag, 2-bit state}`，表深为 `2^BHT_ADDR_WIDTH`。
- 2026-03-22: 新增 alu.v 的基础实现，当前支持 10 种运算: add、sub、and、or、xor、sll、srl、sra、slt、sltu。

## 设计笔记
<!-- 模块设计思路、接口约定 -->
- 2026-04-14: progress 逻辑应该挂在 `cpu_exec()` 的提交循环里，而不是塞进 RTL 或 PMEM/MMIO 层；因为它关心的是“用户看到的连续执行是否还在前进”，本质上是宿主执行器的可观测性问题，不是硬件功能语义的一部分。
- 2026-04-14: 这轮 trace 体验增强的关键决定是把 `CONFIG_NPC_ITRACE/MTRACE/DTRACE` 限定为“是否把能力编进二进制”，真正是否输出日志交给运行时参数和 monitor 命令；这样默认运行路径保持安静，但需要时仍能像 NEMU 一样随开随看。
- 2026-04-14: `mtrace` 必须和 ifetch 分离，否则一旦 guest 程序开始顺序执行，日志立刻被取指流量淹没，根本看不到真实数据访存；因此当前 `BusAccessKind` 已显式区分 `kIfetch/kLoad/kStore`，并把 ifetch 拦在 MMIO 与 mtrace 之外。
- 2026-04-14: 这轮 monitor 的关键点不是“再写一个命令行解析器”，而是把 `cpu_exec()` 从一次性 run harness 改造成可重复进入的执行后端，再把 log/expr/watchpoint/sdb 这些用户态能力逐层挂上去；后续如果补 `itrace/mtrace/dtrace` 体验，优先继续沿 `monitor -> cpu-exec -> paddr/device` 这条链扩展。
- 2026-04-14: 当前 `si N` 的体验对齐是靠 host 侧在命中最后一次提交后额外推进一个不产生新提交的周期实现的，而不是把 RTL 的 `debug_pc_o` 改成“半拍 next_pc”；这样既保留了 commit 边界的精确性，也能让 monitor 返回时看到更像 NEMU 的“下一条待执行 PC”。
- 2026-04-13: 对这种“能直接运行并且带交互入口”的 bring-up 环境，README 不是可有可无的补充，而是工程边界的一部分；至少要把镜像生成路径、直接运行入口、AM 侧桥接入口、可透传参数、交互方式和已知限制写清，否则后续扩设备或换人接手时会重复踩环境坑。
- 2026-04-13: 当前 NPC 仿真器的软件侧显式借鉴 NEMU 的 `monitor -> cpu-exec -> paddr -> device/map` 分层；后续若要补 `mtime/mtimecmp`、VGA、串口状态、trace 或 difftest，应优先在对应层扩展，而不是让 `main.cpp` 重新长回“大一统平台实现”。
- 2026-04-13: 键盘桥目前统一以 NEMU/AM 的键码 ABI 对 guest 暴露事件，host 输入则分成“TTY 交互模式”和“管道脚本模式”两类源头；这样既能支撑后续真实交互，也能让回归测试直接用 `printf 'a' | ... --stdin-kbd` 自动喂事件。
- 2026-04-13: 当前平台层策略是“core 不内建 SoC，外面再包一层 DPI 平台”：`NpcCore` 继续只看 IFU/LSU 握手，`NpcSimTop.sv` 把请求拍扁成一拍请求、一拍返回的 C++ 总线调用；这样后续扩串口、RTC、VGA、键盘时，优先改平台层地址译码和宿主实现，而不是反复改核心内部接口。
- 2026-04-13: `NpcSimTop` 当前故意对齐 NEMU 的最小地址图：`pmem@0x80000000`、`serial@0xa00003f8`、`rtc@0xa0000048`、`kbd@0xa0000060`。这样 AM 程序只要遵循已有 NEMU/AM 约定，就能更平滑地迁到 NPC bring-up 环境里。
- 2026-04-13: 当前 EEI 约定是“普通异常走 `TRAP` 停机，`ecall/ebreak` 走 `HALT` 退出协议”。这是因为这版核心还没有完整 CSR/trap handler；先把程序主动退出和异常炸掉区分开，testbench 才能优雅收尾。
- 2026-04-13: 当前 `exit_code` 直接取寄存器堆里的 `a0(x10)`，更贴近常见 bare-metal / trap harness 约定；后续如果接系统调用语义或 AM 程序，可在此基础上继续扩展 `a7` 或 trap handler，而不用改退出观测接口。
- 2026-04-13: 这版 `NpcCore` 的控制面选择“单在途、多周期、统一提交”的非流水线骨架：`FETCH_REQ -> FETCH_WAIT -> DECODE -> EXEC -> MEM_REQ -> MEM_WAIT -> WB -> TRAP`，这样在不引入流水线冒险的前提下，也能把取指、访存、提交和异常边界收清。
- 2026-04-13: `npc/single/vsrc/define.v` 已从早期的“定宽二进制宽度宏”升级为“ISA 编码 + 控制枚举 + 状态编码 + packed ctrl bus 字段”统一入口；后续若补 CSR、trap controller 或 difftest，应优先复用这套宏，而不是再引入一套并行控制码。
- 2026-04-13: 当前 `DecodeUnit -> ImmGen -> ALU/CompareUnit/LSU -> WBU` 的边界已经稳定：译码只负责产出统一控制包，LSU 收口 lane 选择与 load/store 语义，WBU 负责唯一写回选择，顶层状态机只做阶段推进与精确 trap 裁决。
- 2026-04-13: 当前把 `FENCE` / `FENCE.I` 视为合法 no-op 的前提是 single hart、无 cache、统一 PMEM 的 bring-up 环境；后续如果引入 I-cache、自修改代码测试或更真实的 MMIO 一致性需求，不能继续维持这个简化。
- 2026-04-13: `npc/single/design/study/README.md` 现在应视为 NPC 开发的一号知识入口；`tmp/` 只做快速定位，不直接替代正式 study 笔记结论。
- 2026-04-13: 规范上的 PMA 和 PMP 必须分清。当前 NPC 的统一 pmem、illegal hole、可选 mmio 的地址译码，本质上是在先做简化 PMA；PMP 作为可编程权限覆盖，不是 single-hart、M-mode bring-up 的第一优先级。
- 2026-04-13: 结合前两轮规范学习，当前 NPC 最小硬件骨架应明确收敛为“pc + x0..x31 + machine CSR block + trap controller + 显式 pmem/mmio decoder”；不要把平台属性、异常重定向和执行结果提交分散到各局部模块里各自处理。
- 2026-04-13: 对当前 NPC，第二轮大规范学习的结论已经明确收敛为“先做最小 M 模式执行环境，再谈 supervisor 和虚拟内存”；也就是先实现单 hart、统一 pmem、Zicsr、mtvec/mepc/mcause/mtval/mscratch、ECALL/EBREAK、MRET 与 reset 语义，而不是一开始就被 S 模式、PMP、hypervisor 拖走。
- 2026-04-13: `RV32I.pdf` 对 NPC 当前阶段最有价值的结论是“先把译码压成统一控制包，再把 EXU、LSU、WBU 的边界切清楚”；尤其 WBU 被明确定位为提交点而不是计算点，这会直接影响后续顶层数据通路和异常屏蔽的组织方式。
- 2026-04-07: `alu.v` 当前改为纯组合实现，不再依赖时序寄存；这样更贴合 single 单周期数据通路，执行结果在同一拍内即可被写回、访存地址生成或分支判定复用。
- `alu.v` 的 `select_mod` 对 `OP/OP-IMM` 采用 `{funct7[5], funct3}` 编码：`0000 add`、`1000 sub`、`0001 sll`、`0010 slt`、`0011 sltu`、`0100 xor`、`0101 srl`、`1101 sra`、`0110 or`、`0111 and`；额外用 `1110` 表示 `LUI/src2 直通`，`1111` 预留为 `src1` 直通。
- `alu.v` 里 `zero`、`less_than`、`less_than_u` 统一由减法结果派生，后续 `BEQ/BNE/BLT/BGE/BLTU/BGEU` 可以直接复用，不必再单独复制一套比较器。
- 2026-04-07: `bh_bt.v` 当前按用户要求回到“直接用宏表达式定义位宽”的写法：`tag/index/entry` 的位宽和切片直接基于 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 展开，不再额外包一层 32 位 localparam。这样更贴近当前工程风格，但文件级检查会继续报定宽宏参与算术的位宽告警。
- `bh_bt.v` 当前把 PC 的低 2 位仅用于对齐检查，不参与索引；索引来自 `pc[2 + BHT_ADDR_WIDTH - 1:2]`，其余高位作为 tag，查表命中后用 2-bit 饱和计数器状态的高位作为 `jump_if`。
- `bh_bt.v` 中凡是拿 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 做减法、移位和 part-select 边界计算，都要先做 32 位零扩展；否则 `define.v` 里的 4 位/6 位定宽宏会触发位宽不匹配告警。
- `alu.v` 当前接口为 `rst` `en` `select_mod` `src1` `src2` `zero` `less_than` `less_than_u` `result`；移位类运算使用 `src2` 的低 5 位作为移位量。

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- 2026-04-14: 对 CoreMark 这类长时间 batch 跑分，如果执行器长时间完全静默，用户很容易把“正常推进但暂时没结束”误判成卡死；更稳的做法是在连续执行路径按提交数定期打印 progress，并且显式限制它不去干扰 `si` 这类短命令。
- 2026-04-14: 如果全局 `SIGINT` 处理只在 `cpu_exec()` 的运行循环里消费，而 monitor 提示符仍然直接阻塞在 `std::getline()` 上，那么 prompt 态 `Ctrl-C` 只会让终端回显 `^C`，却不会真正退出 NPC；更稳的做法是用不带 `SA_RESTART` 的 `sigaction(SIGINT, ...)` 打断阻塞读，再让 `sdb_mainloop()` 显式消费这次中断并退出。
- 2026-04-14: 默认 `CONFIG_NPC_ITRACE_COND="true"` 这类配置字符串不能直接假设表达式求值器认识；如果 expr 语法只支持数字、寄存器和运算符，就要在 trace 运行时层额外兼容 `true/false/0/1` 这类布尔字面量，否则即使 itrace 默认关闭，也会在启动时冒出误报警。
- 2026-04-14: 若不显式区分 IFU 与 LSU 访问类型，mtrace 很容易把 instruction fetch 和数据访存混成一锅，用户会误以为“访存量异常大”；对当前 NPC bring-up 环境，更稳的策略是让 ifetch 只服务取指正确性，而 mtrace 专注数据路径。
- 2026-04-14: 如果 core 的调试 `pc` 暴露的是“当前在途指令的 `pc_q`”，那么 host 在看到一次提交后立刻返回，会让 `si 1` 看起来像停在旧 PC；更稳的处理方式是在 host 单步收尾时再推进一个不产生新提交的周期，把可观察状态推进到下一条待执行指令。
- 2026-04-13: `npc/single/csrc` 的嵌套头如果只依赖 Makefile 传入的 include 根目录，VS Code 侧很容易在入口文件上出现“命名空间里找不到声明”的假红线；更稳的做法是让内部头写成自包含的相对 include，入口文件也尽量显式包含本地头路径。
- 2026-04-13: 若顶层把 packed ctrl bus 里的扩展位长期闲置，Verilator 很容易报 `UNUSEDSIGNAL`；更稳的做法不是随处 `lint_off`，而是尽量把 `valid/rs1_en/rs2_en/need_*` 这些位真正接入提交条件、操作数门控或 debug 派生逻辑。
- 初始版本只有运算模式参数，没有操作数输入和结果寄存器，无法形成可综合可用的 ALU。
