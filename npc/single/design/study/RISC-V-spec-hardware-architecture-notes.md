# 面向 NPC 硬件架构落地的规范摘要

## 元信息

- 学习来源：RISC-V 指令集手册第一卷与第二卷中文版
- 学习目标：支撑 npc/single 的最小硬件架构骨架，而不是完整 supervisor 或 hypervisor 平台
- 当前假设：single hart、RV32I、M 模式优先、无 cache、无页表、统一 PMEM、可选最小 MMIO

## 结论先行

- 上一轮 functional-sim 学的是“程序从外部看到什么”；这一轮 hardware-architecture 学的是“核和平台内部最少要准备什么”。
- 对当前 NPC，最关键的硬件骨架不是 S 模式，也不是 hypervisor，而是：single hart、基本架构状态、最小 machine CSR、trap controller、timer/MMIO 预留，以及清晰的 PMEM/PMA 边界。
- PMA 是平台固有属性，PMP 是可编程访问控制；当前统一 PMEM 模型本质上是在先做一层简化 PMA，而不是已经实现了 PMP。

## 一、RISC-V 硬件平台的层次先要摆正

### 硬件平台层次的规范结论

- 平台可以包含一个或多个 core、harts、加速器、物理内存结构、I/O 设备和互连。
- 只有包含独立取指单元的执行体才称为 core，而 hart 是软件视角下的执行资源。
- hart 是抽象执行资源，不等同于操作系统线程。
- 裸机平台、操作系统、虚拟机监视器和仿真器，都可以成为不同层次的执行环境。

### 硬件平台层次对当前 NPC 的直接含义

- npc/single 当前只需要实现 1 个 core、1 个 hart。
- 不需要一开始把多 hart、IPI、调度和抢占都带进来。
- 但最好从命名和文档上就明确这是“single hart RV32I core”，不要把平台对象和核内对象混在一起。

### 硬件平台层次的当前推荐理解

- core 内只保留架构执行所需状态和控制逻辑。
- PMEM、MMIO、timer、trap entry 地址等都应该看作平台层对象，通过接口接入 core。
- 后续如果补 mhartid，当前可以固定返回 0。

## 二、基础 ISA 本身就给硬件实现施加了很多形状约束

### 第一类约束：地址空间与访存视角

- hart 拥有按字节寻址的 XLEN 位循环地址空间。
- 每条已执行的指令至少包含一次隐式内存读取，也就是取指。
- load/store 是显式访存，执行环境决定哪些地址可读、可写、可取指。
- 指令取值和数据访问是否能推测、是否有副作用，和所在内存区域属性有关。

### 第二类约束：寄存器与程序员模型

- RV32I 的非特权架构状态核心就是 x0 到 x31 和 pc。
- x0 必须硬连为 0，不能被真正写入。
- x1/x5 通常承担返回地址语义，x2 通常承担栈指针语义，但这更多是 ABI 约定而不是硬件强制功能。

### 第三类约束：指令长度与对齐

- 基础 RV32I 默认 IALIGN=32，也就是只要求 32 位指令按 4 字节对齐。
- 如果不支持压缩扩展 C，那么当前 NPC 完全可以把取指对齐约束固定在 4 字节边界。
- 全 0 指令字在所有实现上都可视为非法指令，这对空白存储区调试很有价值。

### 第四类约束：译码硬件友好性

- rs1、rs2、rd 在不同格式中的位置被故意保持一致，以减小解码关键路径。
- 所有立即数的符号位都固定在 inst[31]，硬件可以并行做符号扩展。
- B/J 型立即数通过旋转比特编码，而不是靠硬件整体左移，目的是减少多路器和扇出成本。

### 这些基础 ISA 约束对当前 NPC 的直接含义

- IDU 应该固定切片提取 rs1/rs2/rd，再统一生成立即数。
- IFU 当前可以固定 32 位取指，不必过早考虑 IALIGN=16。
- x0 写屏蔽必须放在统一提交路径上，不能依赖上游“别写错”。
- 空白 PMEM 或未装载区域如果被取指，完全可以按非法指令或访问异常路径处理，但要在平台约定中明确。

## 三、最小机器态不是“多几个 CSR”这么简单，而是一套骨架

### 最小机器态的规范结论

- M 模式是唯一强制要求实现的特权模式。
- CSR 地址高位编码了寄存器访问属性和最低可访问特权级。
- misa 用来报告当前硬件线程支持的 ISA 基本宽度和扩展。
- mstatus 跟踪特权模式、中断开关、异常返回栈和部分内存特权语义。
- mtvec、mepc、mcause、mtval、mscratch 构成最小 trap 核心寄存器组。

### 最小机器态对当前 NPC 的直接含义

- 当前最小 machine CSR block 应该优先收敛到：misa、mhartid、mstatus、mtvec、mepc、mcause、mtval、mscratch。
- 如果当前不实现 S/U 模式，那么大量和 supervisor、delegation 相关的位可以只读 0 或相关寄存器不实现。
- CSR 的“未实现”“只读”“WARL/WLRL”都需要明确决策，不能让读取结果随机漂。

### 最小 machine CSR 的当前推荐实现策略

- misa 和 mhartid 当前做成只读常量即可。
- mtvec 第一阶段只支持 Direct 模式。
- mstatus 第一阶段聚焦 MIE、MPIE、MPP、MPRV；无 S/U 时，其它字段尽量读 0。
- CSR 合法性判定统一收口在一个 CSR decode/dispatch 层，不要散在 EXU 或 trap 逻辑里。

## 四、trap controller 才是 machine-level 核心控制面

### mstatus 的最关键含义

- xIE/xPIE/xPP 构成一层中断使能与特权模式栈。
- 陷阱进入时要保存当前中断使能与模式；xRET 返回时要恢复。
- MRET 不只是 pc <- mepc，还会恢复 MIE/MPIE/MPP，并在需要时清掉 MPRV。

### mtvec 的最关键含义

- mtvec 总是必须实现。
- Direct 模式下，所有 trap 都跳 BASE。
- Vectored 模式只对异步中断做 BASE + 4 × cause 的分发。

### mepc/mcause/mtval 的最关键含义

- mepc 保存出错或被中断指令的地址。
- mcause 最高位区分中断与异常，低位是原因码。
- mtval 至少适合承载地址类异常的 fault address；非法指令原始 bits 可以作为后续增强项。
- 多个同步异常并发时，规范要求有明确优先级，而不是谁晚到谁覆盖。

### trap 控制面对当前 NPC 的直接含义

- 需要一个单独的 trap controller，而不是把异常分散在 IFU/LSU/WBU 各自偷偷改 PC。
- trap controller 至少应承担：异常仲裁、写 mepc/mcause/mtval、更新 mstatus 栈位、pc 重定向到 mtvec。
- MRET 的语义要和 trap 进入语义成对实现，否则 ebreak/exception 虽能进 trap，但不能规范返回。

### trap 控制面的当前推荐实现策略

- 第一阶段只支持同步异常和 MRET，先不做真实异步中断。
- 地址异常优先把 mtval 写成 fault address。
- 非法指令时，mtval 先允许为 0，不把“保存非法指令原码”当作 bring-up 阶段硬门槛。
- trap 优先级在设计文档里单独列清楚，避免后续 IFU/LSU 冲突。

## 五、中断和计时器要和 trap 骨架分开看

### 中断与计时器的规范结论

- mip 表示挂起中断，mie 表示中断使能，位号和 cause 编码一致。
- 进入 M 模式中断的条件取决于当前模式、MIE、mip、mie 和 delegation 状态。
- mcycle/minstret 是性能计数器；mtime/mtimecmp 是内存映射的挂钟定时器。
- time CSR 只是 mtime 的影子，而不是另一个独立时钟源。
- WFI 允许被实现为 NOP。

### 中断与计时器对当前 NPC 的直接含义

- “时钟周期计数”和“定时器中断源”不是一回事，不要把 mcycle 和 mtime 设计成同一个对象。
- 如果当前没有 timer/MMIO 平台，就不要假装支持 MTIP，只需把相关位读 0。
- WFI 在当前 single-hart bring-up 阶段可以直接实现为 NOP。

### 中断与计时器的当前推荐实现策略

- 第一阶段：mip/mie 可以读 0 或只保留最小框架，不产生真实中断。
- 第二阶段：如果开始做 timer/MMIO，再引入 mtime/mtimecmp 和 MTIP。
- 如果后面要跑更完整软件栈，再把 mcycle/minstret 和 time shadow 区分补齐。

## 六、reset 语义决定 testbench 不能乱假设

### reset 语义的规范结论

- reset 后进入 M 模式。
- mstatus 中的 MIE 和 MPRV 复位为 0。
- pc 跳到实现定义的 reset vector。
- 其它大量状态未指定，不保证全 0。
- reset 后的 mcause 可以编码不同复位原因。

### reset 语义对当前 NPC 的直接含义

- testbench 不能默认所有通用寄存器和所有 CSR 上电清零。
- reset vector 必须被明确写进平台约定，而不是散落在 testbench 和 loader 里靠默契对齐。
- 程序装载基址、trap vector 基址和 boot 入口必须形成统一约定。

### reset 语义的当前推荐实现策略

- 当前直接固定一个 reset vector，并保证 loader、IFU 初始 PC 和 trap 入口文档一致。
- testbench 只检查规范明确承诺的复位状态。
- 如果暂时没有 NMI，就显式视为未实现，不复用普通中断语义去模拟它。

## 七、PMA、PMP 和当前 PMEM 模型的关系必须彻底分清

### PMA 的核心含义

- PMA 是平台固有属性，不随执行上下文变化。
- 它回答的是：某个物理地址区域到底是不是主存、是不是 I/O、支持什么访问宽度、是否支持原子、是否可缓存、是否幂等。
- PMA 违规应表现为 access fault，而不是 page fault。

### PMP 的核心含义

- PMP 是每个 hart 的可编程访问保护叠加层。
- 它主要用于限制 S/U 或受锁定约束的 M 模式访问权限。
- PMP 是权限机制，不是平台物理属性定义机制。

### PMA/PMP 对当前 NPC 的直接含义

- 当前统一 PMEM 实际上等价于“先定义一个最简 PMA”：一段可取指/可读/可写 RAM，加上若干非法空洞，再可选接少量 MMIO。
- MMIO 区域应被看作 I/O 区域，而不是普通 RAM 上套一层 if。
- 访问不存在或不支持的地址区间时，应明确是地址未对齐、访问故障还是非法区域，而不是一律沉默返回 0。
- PMP 不是当前 single-hart、M-mode only bring-up 的第一优先级。

### PMA/PMP 的当前推荐实现策略

- 先在 pmem/mmio decoder 层显式区分：RAM、MMIO、illegal hole。
- 对非幂等 MMIO，不要依赖重复读取或推测读取语义。
- 当前访问保护先由“简化 PMA/地址译码”承担，而不是 PMP。
- 等需要做 S/U 模式隔离、安全测试或更完整特权级时，再正式补 PMP。

## 八、结合前一轮经验后，当前 NPC 最自然的硬件实施顺序

1. 固定 single hart、RV32I、M-mode only、IALIGN=32、小端。
1. 建立统一 architectural state：pc、x0..x31 和最小 machine CSR block。
1. 实现 trap controller：异常仲裁、CSR 写回、mtvec 跳转、MRET 返回。
1. 在内存系统里显式建模 PMEM、MMIO 和 illegal hole，而不是默认“所有地址都像 RAM”。
1. 需要时再补 mtime/mtimecmp 和最小 mip/mie。
1. 最后再考虑 PMP、S 模式、delegation、多 hart。

## 九、当前可以明确延后的内容

- Supervisor 模式完整支持
- Hypervisor 与两阶段地址翻译
- Smstateen、Smcsrind 等高级平台扩展
- mvendorid、marchid、mimpid 的细编码
- PMA 的完整一致性/缓存层级建模
- PMP 增强、安全世界切换和调试模式

## 十、一句话结论

- 对当前 NPC，硬件架构部分最值得先学会的，不是“完整特权系统有多大”，而是“single hart RV32I core 最少要暴露哪些架构状态、哪些边界属于平台、哪些语义必须由 machine-level 硬件自己兜住”。
