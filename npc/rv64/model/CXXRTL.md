# RTL 派生执行后端实验

此后端使用 Yosys + yosys-slang 将当前 SystemTestTop 生成 C++，用于探索保留真实
RTL 状态转换的执行方式。**它目前不是已经验收的快速性能模型。**
手写 trace 模型与该后端是两种独立实现；不能将前者的速度和后者的时序精度组合为同一个结论。

## 已测量范围

2026-09-17，在相同镜像、原有 NEMU DiffTest、RTL 断言和 SystemTestTop 驱动时序下：

| 完整程序 | 退休指令 | Verilator 结束周期 | CXXRTL 结束周期 | 逐条绝对退休周期偏差 |
| --- | ---: | ---: | ---: | ---: |
| compressed 微基准 | 195 | 302 | 302 | 0 |
| load_banks 微基准 | 259 | 610 | 610 | 0 |
| divide 微基准 | 68 | 784 | 784 | 0 |

功能记录中的 PC、指令、操作数与地址也一致。该结果只覆盖这三个短程序，
不代表 CoreMark、Dhrystone、特权态、异常或全部微架构配置已经零误差。

保留的部分优化构建（LSU 使用 O1，DCache 仍为 O0）运行 compressed 用例耗时 16.99 秒，
原有 Verilator 记录为 0.164 秒。较早构建为 28.88 秒，已被替代并清理。
二者不是同一时刻的严格性能基准，但数量级差异已足以说明当前实现不适合作为加速工具。
independent 微基准在 120 秒主机超时前未完成，没有作为通过的结果。

全优化构建没有完成：DCache 的 O1 编译运行 1,070.97 秒后被停止；
两个有时限的替代参数实验触及编译器内存上限。
因此没有测得完整优化构建的运行速度，也不将调试构建的耗时推广为 CXXRTL 的普遍性能结论。

本次保留的可执行文件位于
tmp/rv64-perf-model-20260917/cxxrtl-hierarchy/quick-check/r64-cxxrtl-partial-opt。
该实验目录中的可重建生成代码、对象文件和旧可执行文件已经清理；
重新构建需要重新生成，不可对这个已清理目录使用 --reuse-generated。

## 构建与对照

在工作区根目录执行：

    make -C npc/rv64/model test-cxxrtl
    python3 npc/rv64/model/build_cxxrtl.py --build tmp/r64-cxxrtl --jobs 2

需要工作区内的 oss-cad-suite、yosys-slang 和 clang++。
默认编译优化为 O1。编译大模块仍可能耗时较长；生成成功不等于时序验收通过。
--optimization 0 可以降低部分编译优化开销，但会显著降低运行速度。
--reuse-generated 只用于重编译该目录中已生成的 RTL 快照；
RTL 或配置有变化时必须重新生成。

同一镜像先后由真实 Verilator 与独立 CXXRTL 可执行文件运行，分别采集后对照：

    python3 npc/rv64/model/collect_rtl.py \
      --sim tmp/r64-cxxrtl/r64-cxxrtl \
      --image PATH/TO/program.bin --out tmp/r64-cxxrtl-run \
      --max-cycles 5000 --host-timeout 600

    python3 npc/rv64/model/compare_runs.py \
      PATH/TO/VERILATOR_RUN tmp/r64-cxxrtl-run

compare_runs.py 对自然结束、全部功能记录、每条绝对退休周期和最终终止周期分别检查。
未通过时返回非零，不以平均 CPI 或误差阈值代替零误差。

## 适配边界

- 生产 RTL、正式 Verilator testbench 和 NEMU 不改动，适配发生在构建目录的副本。
- Slang 不支持的 $fatal 转换为同一条件、同一时钟下的立即断言；
  原始消息与位置保存在 assertions.json。R64_ASSERT 保持启用。
- 原有跨层 CSR 观察和 ROB/LSU/RegRead 检查通过附加观察输出连接。
  这些输出不进入被测设计的数据输入，也不修改断言条件。
- 去除 testbench 可选的文本调试及占用统计打印；退休记录和功能检查来自原有
  sim/src/r64_sim_main.cpp 与 difftest/src/r64_difftest.cpp。NEMU 的 GPR/FPR/CSR、UART 和设备检查继续执行。
- CXXRTL 每个寄存器提交后继续计算组合逻辑直至稳定，避免主机在上升沿后读到旧 CSR。
- 驱动入口不提供自定义 performer 回调。生成代码显式拒绝非空回调，并将对应不可达分支
  专门化；原始 RTL 检查和 CXXRTL_ASSERT 全部保留。
- 默认仅在本地运行库副本中取消强制内联属性。类型、运算、状态更新和断言不变。
  --forced-inline 可恢复该属性，但大模块可能使编译器耗尽内存。
- 当前观察端口宽度针对本次生产核配置。改变 ROB/tag/物理寄存器等结构后，需要同步这些
  观察接口并重新验证；该后端尚未实现通用的运行时微架构参数扫描。

生成的 C++ 按完整模块方法分成多个编译单元。构建退出时删除本次生成的临时编译单元
和目标文件，保留可执行文件（若成功）、生成快照及诊断日志。
生成快照用于重编译；确认不再使用后可以删除整个专属构建目录。

开源实现与接口说明见 [Yosys CXXRTL](https://yosyshq.readthedocs.io/projects/yosys/en/v0.53/cmd/write_cxxrtl.html)
和 [yosys-slang](https://github.com/povik/yosys-slang)。
