# 承岳64架构入口

当前主线为 **ChengYue64（承岳64）v1.0.0**，版本真源是
[core-version.mk](core-version.mk)。主线 RTL 直接列在 [vsrc/filelist.mk](vsrc/filelist.mk)，
按功能保存在 `vsrc/` 的各子目录；模块连接和参数以源码为准。

## 系统边界

| 层次 | 实现 | 职责 |
| --- | --- | --- |
| CPU | [R64CoreTop](vsrc/core/R64CoreTop.v) | 取指、双发射乱序后端、整数/浮点执行、提交/CSR、LSU/MMU/Cache、AXI |
| 系统 | [R64SystemTop](vsrc/platform/R64SystemTop.v) | CPU、AXI fabric、CLINT、PLIC、UART、RTC 和 syscon |
| 可选协处理器系统 | [R64TensorSystemTop](vsrc/platform/R64TensorSystemTop.v) | 真实 Tensor/NPU 接口、DMA 和缓存一致性配合 |
| 仿真宿主与观察 | [sim/](sim/README.md) | RTL 仿真封装输出观察状态；C++ 宿主驱动时钟、镜像和设备，不参与硬件综合 |
| 架构状态差分 | [difftest/](difftest/README.md) | NEMU 接口、退休/trap 对齐、PC/GPR/FPR 和选定 CSR 比较 |
| 定向测试与回归 | [testbench/chengyue64](testbench/chengyue64/README.md) | 模块激励、程序、oracle、测试生成器和回归调度 |

主线能力包括 RV64IMAFDC、Zicsr/Zifencei、Zba/Zbb/Zbc/Zbs、M/S/U、Sv39、
16 项 PMP、原子操作与 Sdtrig 地址触发器。扩展能力及系统接入取舍见
[系统替换记录](design/arch/rv64-replacement.md)；具体行为由 RTL、参考配置和定向测试共同约束。

## 详细设计

- [全核拓扑](vsrc/TOPOLOGY.md)：请求、完成、信用、恢复和不可取消事务的连接。
- [模块清单](vsrc/MODULES.md)：源码中声明的模块与文件位置；它不是实例化证明。
- [前端](vsrc/frontend/TOPOLOGY.md)、[后端](vsrc/backend/TOPOLOGY.md)、
  [浮点](vsrc/fp/TOPOLOGY.md)、[提交控制](vsrc/control/TOPOLOGY.md)、
  [翻译与保护](vsrc/memory/TOPOLOGY.md)、[LSU/Cache](vsrc/lsu/TOPOLOGY.md)、
  [总线与平台](vsrc/bus/TOPOLOGY.md)：各模块域的详细连接与设计取舍。
- [设计资料分类](design/README.md)：主线说明、共享 IP 规范、文献和旧核资料的适用范围。

源码旁的拓扑文档也包含标有日期的优化测量；这些测量只描述对应版本。
最新正式版本的 CPI/STA 和验证范围在[发布说明](releases/chengyue64-v1.0.0/README.md)中维护。

## 验证和实现证据

[DiffTest 文档](difftest/README.md)说明逐条提交的 PC/GPR/FPR 检查，
以及当拍提交和 trap 处理后的 CSR 比较；[系统仿真](sim/README.md)
说明 Linux、设备与 NPU 的运行边界。[综合与 STA](syn/README.md)说明真实网表、约束和时序判定。
理想吞吐目标为 CPI 0.5，当前 1 ns / 1 GHz 时序尚未闭合；局部测试、短程序和布局前报告
不能代替完整系统验证或物理签核。

## 历史资料

冻结 timing28–33、早期 CPU-only 暂停范围及旧 Ooo* 核的架构快照已归入
[历史文档](design/history/README.md)。其任务状态和测量不描述当前主线。
旧核完整源码、配置与文档见[封存包](../pack/rv64core-legacy-20260916/README.md)。
旧 Ooo* 主核不在 `vsrc/` 中；个别测试复用的旧实现位于测试 oracle 目录，保持其验证用途。
