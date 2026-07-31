# RV64 Core 源码学习讲义

> 文档类型：常驻学习索引（ACTIVE）  
> RTL 基线：当前工作区 `npc/rv64/vsrc/`，2026-07-30 产品配置与 elaboration 静态复核
> 教学目标：像“一生一芯”讲义一样，从问题、事务和周期出发理解一颗真实 RV64
> 双发射乱序核，而不是背模块名。

## 先从交互式 Datasheet 开始

打开 **[RV64 Core 交互式 Datasheet](index.html)**。它把当前 RTL 同时组织成两种视图：

- **实例层次树**：显示 `instance_name : ModuleType`，点击任一实例即可进入该模块的数据页，
  再沿父实例、子实例继续下钻；
- **事务拓扑图**：按取指、整数完成、浮点完成、load、store、分支恢复、CSR 队头提交和精确异常等路径，
  观察数据与控制在模块间怎样流动。

页面是可直接双击打开的单文件离线 HTML，不依赖 CDN。它还提供 150 个 `vsrc` 文件的
可搜索源码图册、模块/信号反向索引、38 幅 WaveDrom 时序图、深链接、键盘导航、移动端
侧栏和打印版式。195 个实例页各有 5 道可展开参考答案；9 条 transaction（新增产品默认
head0 CSR queue-head 路）采用自上而下的 58 阶段主数据流和 1 条独立 owner-lifetime
分支、1 条并行 serial-flush 分支，共明确 240 个
Data In / State / Data Out / Guard 字段。正文仍是
事实依据更完整的学习讲义；交互页负责建立全局空间感并快速跳转到证据。

页面默认使用“大”字号。页面右上角的“字号”按钮可以在“标准 → 大 → 特大”之间循环，
选择会保存在本机；事务卡片、表格、Self-check 和 WaveDrom 标签会一起缩放，不需要分别
调整。浏览器本身的 `Ctrl +` / `Ctrl -` 仍可作为额外缩放手段。

## 先给结论：这是一颗什么样的 Core

当前 Core 是 RV64IMAFDC + Zba/Zbb/Zbc/Zbs、M/S/U 三特权级、Sv39、PMP×16
的小窗口乱序处理器。主数据宽度为 64 bit，核心吞吐边界是：

- 每周期最多取出并观察两个指令槽；
- 每周期最多 dispatch 两条；
- 整数 IQ 最多 issue 两条，FP IQ 最多 issue 一条；
- 全局最多接收两个 completion；
- ROB 最多按程序顺序退休两条；
- 数据侧有两个 memory bank，但 cache miss、PTW 和写事务最终共享一条 LSU AXI
  出口。

当前产品配置 `OOO_CSR_QUEUE_HEAD=1`：合法非 FP head0 CSR 走 ROB queue-head，
`head0_csr_inflight` 保持 stop，只等 `mem_idle` 后 C0 commit、C1 apply；lane1/FP CSR
与非 CSR SYSTEM/trap 仍走 pending/full-drain。产品配置真源是
[`npc/rv64/configs/product-rtl-defaults.mk`](../../../npc/rv64/configs/product-rtl-defaults.mk)，
`define.v` fallback 为 `1'b1`。

这里最重要的认识不是“它有几级流水”，而是：

> 这颗 Core 由 fetch packet FIFO、rename 状态、IQ、ROB、MIQ、LQ、SQ、执行级寄存器
> 和 pending control owner 解耦。指令会在不同队列中停留不同周期，因此不存在一个
> 能解释所有指令的固定五级或八级流水模板。

## 学习路线

| 顺序 | 讲义 | 你应该回答的问题 |
| --- | --- | --- |
| 0 | [学习方法与源码导航](00-学习方法与源码导航.md) | 如何从 Verilog 中找状态 owner、握手和事务边界？ |
| 1 | [全局拓扑与指令一生](01-全局拓扑与指令一生.md) | 一条指令从 PC 到 commit 经过哪些队列和身份转换？ |
| 2 | [前端：取指、预测与双槽派发](02-前端取指预测与双槽派发.md) | 8B fetch packet 怎样变成最多两条指令？redirect 怎样取消旧响应？ |
| 3 | [译码、重命名、ROB 与发射](03-译码重命名ROB与发射.md) | WAW/WAR 如何消失？为什么 ROB 和物理寄存器缺一不可？ |
| 4 | [整数执行与分支恢复](04-整数执行与分支恢复.md) | 两个 issue lane 如何共享执行资源？分支错预测怎样杀 younger？ |
| 5 | [浮点乱序执行簇](05-浮点执行簇.md) | FP 为什么有独立 RAT/PRF/IQ？短流水和长迭代如何汇合？ |
| 6 | [访存顺序、MMU、Cache 与 AXI](06-访存顺序MMU缓存AXI.md) | LQ/SQ/MIQ 各管什么？双 bank 并行的边界在哪里？ |
| 7 | [完成、退休、CSR 与精确异常](07-完成退休CSR与精确异常.md) | “执行完成”和“体系结构可见”为什么是两件事？ |
| 8 | [控制域、pending/drain 与全局冲刷](08-控制域与全局冲刷.md) | branch recovery 与 SYSTEM/trap 为什么走两套控制域？ |
| 9 | [SoC 总线、仿真与调试观测](09-SoC总线仿真与调试.md) | Core 如何连接 CLINT/PLIC/UART/PMEM？checker 为什么不进综合？ |
| 10 | [时序、反压与 WaveDrom 图册](10-时序反压与WaveDrom.md) | valid/ready、stall、kill、replay、exactly-once 怎样逐拍判断？ |
| 11 | [150 个文件逐文件源码地图](11-逐文件源码地图.md) | 每个 `vsrc` 文件属于哪里、谁例化它、应该先看什么？ |
| 12 | [动手实验与思考题](12-动手实验与思考题.md) | 如何自己用 trace、波形和小实验验证理解？ |

建议第一次按顺序读 0→10；遇到模块名时再查第 11 章。不要从
`OooIntBackend.v` 第一行硬啃到最后一行，那会很快失去“这根信号为什么存在”的上下文。

## 本讲义的事实等级

讲义使用三种标签，避免把“读到代码”误当成“已经验证”：

- **【RTL 事实】**：能直接绑定当前 module、signal、always block 或实例端口。
- **【结构推导】**：由多个 RTL 事实组合出的拓扑或周期结论，会给出推导前提。
- **【验证边界】**：说明还需要 testbench、DiffTest、综合或 STA 才能证明什么。

本轮只修改学习文档与审计工具，没有修改 `npc/rv64/vsrc/`。除非某一节明确引用测试
证据，否则所有时序图都是当前 RTL 的教学模型，不冒充动态波形。

## 当前源码与旧文档的一个重要差异

[`npc/rv64/vsrc/README.md`](../../../npc/rv64/vsrc/README.md) 和
[`npc/rv64/vsrc/filelist.mk`](../../../npc/rv64/vsrc/filelist.mk) 中仍保留部分演进注释，
例如曾把双 memory bridge 写成“原型、未实例化”。当前
[`NpcCoreTop.v`](../../../npc/rv64/vsrc/core/NpcCoreTop.v) 已真实例化
`OooDualMemBridgeWrapper`，内部有两个 `OooMemAxiBridge`、两个 DTLB、两个 D-cache，
再由 `OooDualMemAxiArbiter` 合并外部 miss 流量。

因此本讲义的裁决顺序是：

1. 当前 RTL 实例和端口连接；
2. 当前参数、宏与 always block；
3. 当前规范文档；
4. 历史演进注释。

出现冲突时，历史注释只帮助理解“为什么代码长成这样”，不再描述现状。

## 机械覆盖门

[`tools/audit_vsrc_coverage.py`](tools/audit_vsrc_coverage.py) 会检查：

- `npc/rv64/vsrc/` 的 150 个文件是否全部在讲义中出现；
- 所有本地 Markdown 链接是否存在；
- 每个 `wavedrom` 代码块是否为合法 JSON；
- 时序信号是否错误地用重复 `0`/`1` 画保持电平，进而产生伪尖峰；
- 9 条 transaction 的每个阶段是否都具备输入、状态变化、输出和准入条件；
- Self-check 是否包含可展开答案及状态线索，而不是只留下问题；
- Features 长文本和 transaction 是否使用可换行的纵向/响应式布局；
- 讲义是否至少包含一张 WaveDrom 时序图。

运行：

```bash
python3 docs/rv64core/study/tools/normalize_wavedrom_levels.py
python3 docs/rv64core/study/tools/audit_vsrc_coverage.py
python3 docs/rv64core/study/tools/audit_interactive_datasheet.py
```

若第一条命令报告需要规范化，可执行
`python3 docs/rv64core/study/tools/normalize_wavedrom_levels.py --write`。它只改
`wavedrom` 代码块里的 `"wave"` 字段，把相邻重复的显式 `0`/`1` 改成 WaveDrom
规定的保持符号 `.`，不会改动信号语义。

若当前 RTL、filelist 或产品默认配置已改变，先重新生成当前产品的 NpcTop/NpcSimTop
XML，再生成交互页。生成器会比较 XML 与 RTL/config 的 mtime，拒绝沿用旧层次：

```bash
docs/rv64core/study/tools/generate_elaboration_xml.sh
python3 docs/rv64core/study/tools/build_interactive_datasheet.py
```

[`tools/extract_vsrc_inventory.py`](tools/extract_vsrc_inventory.py) 可结合 Verilator XML
区分 `NpcTop` 可达模块、仿真专用模块、focused checker、header 和 catalog-only 模块。
它是源码清册工具，不代替人工理解。

当前 elaboration 清册为：

| 身份 | 文件数 | 应怎样理解 |
| --- | ---: | --- |
| `NpcTop` 生产实例树可达 | 124 | 当前 Core/SoC 主路径 |
| `NpcSimTop` 仿真专用 | 6 | 仿真壳、DPI/virtio 与常驻 checker |
| focused checker | 3 | 需要定向 TB 显式实例化 |
| catalog-only | 3 | 源码存在，但当前两个顶层均未实例化 |
| header/include | 9 | 宏、helper 与 packed facts ABI |
| document/build | 5 | README 与 filelist |

这张表是“当前实例可达性”，不是功能覆盖率。生产可达也可能被参数/常量门死，checker
存在也不等于它已在本轮运行。

## 贯穿全书的五个问题

看到任何模块或信号，都先问：

1. **谁拥有状态？** 是寄存器、FIFO entry、ROB entry，还是纯组合 gate？
2. **事务什么时候出生？** `valid && ready`、dispatch fire、issue fire、request fire
   还是 commit fire？
3. **身份如何保存？** PC、ROB index、ProducerId、epoch、bank、load/store kind 在哪里打拍？
4. **谁能取消它？** branch recovery、`core_local_flush`、MMU flush、drop token，还是根本
   不允许取消？
5. **什么时候对架构可见？** completion 只表示结果回来了；commit 才表示按程序顺序生效。

只要能沿着这五个问题追完一条指令，你就真正理解了这颗 Core 的拓扑。
