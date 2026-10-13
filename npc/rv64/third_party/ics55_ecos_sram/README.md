# ECOS ICS55 Cache SRAM

本目录保留 [ECOS SRAM 发布库](https://github.com/openecos-projects/ics55_ecos_sram)
的原始 IP 文件；生成入口是 [ECOS IP Factory](https://factory.openecos.com/ip/sram)。
下载来源、原始归档校验和与编译器输入见 ICache 的 [source.json](source.json)
及 DCache 的 [source-256x64.json](source-256x64.json)。
宏子目录中的文件原样保留，使用须遵循供应方适用的 ICS55 / IP 条款；本项目不为其另行授予许可。

当前接入两个 ECOS 官方配置，均为 mux 4、VT 0、无 redundancy、ringless：

| 用途 | 真实宏 | 写接口 | 数量 / 有效数据容量 |
| --- | --- | --- | --- |
| ICache data | `ics55_ecos_sram_256x128_m4_ww` | 整字写 | 2 / 8 KiB |
| DCache data | `ics55_ecos_sram_256x64_m4` | 64-bit 低有效逐 bit WEB | 4 / 8 KiB |

DCache 配置由官方 IP Factory 使用 `wordWrite=0` 生成，原始包与 Liberty 已完整保留，
不是在整字宏外虚构写掩码。tag、valid、LRU 与物理寄存器堆仍由标准单元实现。
Cache 的其他测试几何使用明确的通用数组分支；生产参数实例化上述真实宏。

## 接口与仿真

`CLK` 上升沿采样；`CEB=0` 使能；`GWEB=1` 读、`GWEB=0` 写。
两种宏的地址均为 8 bit，数据分别为 128 bit / 64 bit，禁能时 Q 保持。
写操作同时更新 Q；掩码宏只有被选中的 bit 更新 Q，其余 bit 保持前一次 Q，
不能把写后的 Q 当作目标行的完整新数据。
`MARE=0`、`MAR=0000` 使用默认表征条件。宏无数据复位。
ICache 的 LOOKUP 和 FILL 访问互斥，每 way 的单端口宏保持原同步读边界。
DCache 每 bank 使用两项写合并 FIFO、byte 转发、lookup 结果保持和公平排空仲裁；
每个 byte enable 展开到 8 个 WEB bit，不需要读改写。
这些适配在 RTL 注释中明确标注为 ECOS 工艺库设计。

原始 `verilog/` 中 full、core、stub 三个文件定义同名模块，只能选择一种。
日常周期仿真采用单独维护的无延时 view；其行为与供应方 core model 通过
直接测试对照。该 view 不能用于估算物理延迟、功耗或 ASIC 面积。
综合保留真实宏 leaf，并加载匹配工艺的 Liberty。

## 物理模型与结论边界

默认布局前分析使用 `tt1p2v25cctyp` Liberty，与 ICSprout55 TT、1.2 V、25°C 对齐。
ICache 每宏的 Liberty 面积为 33226.22205 µm²，两宏共 66452.44410 µm²；
DCache 每宏为 17492.01405 µm²，四宏共 69968.05620 µm²。
生产配置的六宏面积之和为 136420.50030 µm²，实际实例数须由综合结果确认；
总核面积还必须包含实际映射后的标准单元。宏的最小周期、脉宽、setup/hold 和
clock-to-Q 均须参与 STA，不能把存储宏当零延迟黑盒。

归档还包含 LEF、另外七个 corner、Verilog 与 CPF，但没有 GDS。
布局前面积与 STA 不等于完成物理签核；没有工作负载活动率及完整物理分析，
也不能由面积变化直接推断功耗降幅。

Vivado 的 FPGA 实现应另选保持相同访问契约的 BRAM / LUTRAM 适配；
此宏名、Liberty 与 LEF 描述的是 ICS55 ASIC SRAM，不会变成 FPGA 上的同一硬宏。

## 直接验证入口

从工作区根目录运行：

```sh
python3 npc/rv64/testbench/chengyue64/scripts/test_ecos_sram_cycle.py
python3 npc/rv64/testbench/chengyue64/scripts/test_ecos_sram_256x64_cycle.py
# DCache FIFO/转发和集成测试入口见 ../../vsrc/lsu/TOPOLOGY.md
make -C npc/rv64/testbench/chengyue64 run TESTS="tb_r64_icache tb_r64_icache_hit_flow"
make -C npc/rv64/sim core-lint system-lint
make -C npc/rv64/testbench/chengyue64 system-run system-throughput
python3 npc/rv64/syn/test_check_opensta.py
make -C npc/rv64 sta
```

两个模型对照入口验证 cycle view 与供应方模型一致；Cache 定向验证访问、fill、
错误、invalidate、背压与命中吞吐。全核短程序通过真实 DiffTest，不能替代
完整软件回归、CoreMark/Dhrystone 重测或系统发布验证。最后一项使用默认 2 ns / 500 MHz，
应如实报告时序违例；命令非零退出不代表宏面积被漏计。

## 当前 ICache + DCache 的 2026-10-12 TT 500 MHz 实测

本轮实际网表含 2 颗 ICache 256×128 与 4 颗 DCache 256×64 宏。
包含所有标准单元和宏的面积由 2906950.524099 µm² 降至 2406410.460301 µm²，
减少 **17.2187%**；触发器从 198598 减至 132509，ICG 从 10780 减至 2610。
完整 CoreMark 10 / Dhrystone 10000 的严格本轮前后 A/B 周期和提交数完全相同；
两个程序均通过真实 NEMU DiffTest 与 RTL assertions。

同为 2 ns 的 TT STA，setup WNS 从 -3.147320986 ns 恶化到 **-5.034887791 ns**，
hold WNS 仍为 -0.313464463 ns，最小周期裕量 +0.408300072 ns，
全局最小脉宽裕量 -20.870256424 ns，最终仍为 **FAIL**。
新增最差控制链贯穿 lookup、FIFO 信用、store terminal 直通、退休与 IQ 依赖释放，
不经过 SRAM 数据输出 Q。本轮证明宏化与面积收益，不能称 500 MHz 已收敛或完整 PPA 优化成功。
完整结果及比较口径见[本轮结果](../../../../build/ecos-dcache-20261012/RESULT.md)。

## 历史 ICache 单独接入的 2026-10-12 focused 实测

同一 R64CoreTop、TT 1.2 V / 25°C、1 ns、ABC 600 ps、fanout 8 下，
最终网表保留 **2 个真实 SRAM 宏**，宏面积合计 **66452.44410 µm²**。
含标准单元的总面积由第二十批 **3406233.03999 µm²** 变为
**2906950.52410 µm²**，变化 **-14.6579%**。
实际 SDC 与第二十批完全一致；setup WNS **-4.147320747 ns**、
hold WNS **-0.313464463 ns**、最小周期裕量 **-0.591699898 ns**、
全局最小脉宽裕量 **-21.370258331 ns**，
最终 STA 为 **FAIL**，面积变化不替代时序收敛。
最小周期端点在 SRAM CLK；全局最差脉宽端点是标准触发器 DFFQX1H7L 的
_1253616_/CK (low)，不是 SRAM 宏引脚。第二十批未采集周期/脉宽报告，
不能以缺失结果判为 PASS，或把该项直接归为本次引入的退化。

最终模型的 2308 次供应方对照、6 个 ICache 配置、相关 lint/frontend 域、
10 个系统 DiffTest、7 个 CPI=0.5 热窗口和 9 个 STA checker 测试通过。
本轮未重测完整软件、CoreMark/Dhrystone、L2/L3 或功耗/P&R，保持 focused 未发布结论；
历史第二十批证据不改写。

详见[实测结果](../../build/ecos-sram-20261012/RESULT.md)、
[机器比较](../../build/ecos-sram-20261012/ppa-comparison.json)和
[最终模型功能摘要](../../build/ecos-sram-20261012/validation/summary.json)。
