# 承岳64（ChengYue64）架构入口

当前正式版本为 **承岳64（ChengYue64）v1.0.0**，版本真源是 [core-version.mk](core-version.mk)。
默认源码和测试分别位于 `vsrc/chengyue64`、`testbench/chengyue64`。
版本范围、最新 CPI/STA 与验证说明见 [v1.0.0 版本说明](releases/chengyue64-v1.0.0/README.md)。
旧 rv64core 的源代码、构建配置和历史文档归档到 [独立源码包](../pack/rv64core-legacy-20260916/README.md)。

> 2026-09-15：用户已恢复完整替换范围（包含 Linux 与 NPU）。当前任务与缺口见[完整替换记录](design/arch/rv64-replacement.md)。下文此前的暂停/CPU-only 范围属于历史记录。

## 此前系统替换记录

2026-09-16 起，正式主线命名为承岳64 v1.0.0，以 `vsrc/chengyue64/` 的原生双发射乱序实现为主线。
原来自动生成的旧核 registry 快照保存在 [ARCHITECTURE.legacy.md](ARCHITECTURE.legacy.md)；
它的 BPU/FP sweep、优化任务和 qualification 状态不适用于本次重写。

实际架构、接口、验收结果与开放问题见 [rv64-rebuild.md](design/arch/rv64-rebuild.md)。
当前默认 [Makefile](Makefile) 和 [RTL filelist](vsrc/filelist.mk) 已指向新实现。
## 早期冻结版本与暂停记录

以下记录描述各自快照，不代表 09-08 之后默认源码的身份或当前任务范围。
冻结 timing28 的85源CPU回归全部通过，112项模块、352软件、8项系统定向、双基准和7个CPI0.5理想热区通过；严格默认lint与同源filelist核对通过。同源1ns原始映射setup为−3.472463846ns、实际单元面积3,151,497.72µm²；真实单元及hold修复已完成：setup−1.543375254ns、hold+.005088600ns、面积3,615,844.96µm²，1GHz仍未闭合；相对27的PPA退步已保留，冻结30联合结构已通过134模块及矩阵、352软件、8系统定向、7个CPI0.5窗口及双基准，CM／Dhry周期较29增加0.706%／0.666%；同源1ns raw及真实单元／hold修复均完成：最终setup−1.893222690ns、hold+.005088600ns、面积3,607,802.52µm²，1GHz FAIL。

该轮后续联合候选都位于独立快照，当时默认仍为28：
- 31：136模块及矩阵、352软件、8整机、7个CPI0.5窗口及双基准通过，双基准六项计数与30相同。整核raw及真实单元/hold修复完成，最终setup −1.882808447ns、hold +.005088600ns、面积3,605,016.80µm²，1GHz仍失败。
- 32原始回归保留PLIC旧断言失败。32a仅修正暂停退休时的检查条件，可综合硬件相同，139模块与矩阵、全部352软件、8整机、7个CPI0.5窗口和双基准已通过；同源整核raw完成，setup−3.473068953ns、hold−.036660694ns、面积3,144,771.56µm²。后续物理修复按用户暂停指示未运行。
- 33：将单沿解析归属证书、普通投机load排空、CQ写回预约和cached store直接进入WRITE合并；相对32a新增普通流水沿和逻辑状态均为0。严格lint、146模块与矩阵、352软件、8整机、7个理想窗口和双基准全部通过。CM9,813,100拍／CPI3.048944，Dhry15,703,314拍／CPI3.685644；相对32a周期下降3.2768%／5.9410%。按用户要求已停在整核综合之前。

单点的CPI或raw时序改进不能相加为整核结果，当前仍未达到1GHz。
该轮已启动的小任务与结果收集当时均已结束，并按用户要求暂停；详见
[暂停记录与单点取舍](design/arch/rv64-rebuild-pause.md)。

## 当前系统组成

- CPU：R64CoreTop，原生 Frontend、Backend、FP、Commit/CSR、LSU/MMU/Cache、AXI。
- 系统：R64SystemTop，连接真实 AXI fabric、CLINT、PLIC、UART、RTC、syscon。
- 可选协处理器系统：R64TensorSystemTop，实际 TensorNpuCoprocessor 和 DMA/cache coherency。
- 仿真观察：SV TestTop + C++ 全状态参考桥；观察寄存器不进入综合。
- 当前范围：使新核完整取代旧核，包含 Linux 分层系统与完整 Tensor/NPU 接入和验证。
- 优化目标：理想 CPI 0.5，优先实际程序 CPI 与时序；面积仅记录。目前 1 ns / 1 GHz 时序尚未闭合。

历史源码和用户已有改动保留，默认新核不实例化旧 Ooo* 核，也没有双核选择 mux。


## 2026-09-08 全核拓扑迭代

用户已授权继续逐模块优化并整合全核，优先时序与 CPI，面积仅记录。当前入口为 [全核拓扑](vsrc/chengyue64/TOPOLOGY.md)、[模块清单](vsrc/chengyue64/MODULES.md) 与 [本轮执行记录](../../tmp/rv64-whole-topology-20260908/PLAN.md)。前文历史暂停/旧版本记录不代表本轮状态；最终接受配置与实测结论由本轮结果记录。
