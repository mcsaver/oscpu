# 承岳64综合与静态时序分析

本目录保存默认 RV64 主线的 ASIC 综合、STA 约束和网表处理工具。
工程目标在 [../Makefile](../Makefile) 定义，输入来自
[RTL filelist](../vsrc/filelist.mk)，版本和测量结果见
[v1.0.0 发布说明](../releases/chengyue64-v1.0.0/README.md)。

## 构建入口与约束

从工作区根目录运行：

```sh
make -C npc/rv64 syn
make -C npc/rv64 sta
# 使用其他本地 OpenSTA 安装：
make -C npc/rv64 sta OPENSTA=/absolute/path/to/sta
```

默认综合顶层为 `R64CoreTop`，PDK 为 `icsprout55`，目标频率为 1000 MHz。
CPU 算术单元和存储数组进入真实映射，不使用占位黑盒；测试顶层和 C++ DiffTest 不进入综合。

| 参数 | 默认值 / 含义 |
| --- | --- |
| `STA_DESIGN` | `R64CoreTop`；必须与实际网表顶层一致 |
| `STA_CLK_FREQ_MHZ` | `1000`，对应 1 ns 时钟 |
| `STA_SDC_FILE` | [chengyue64.sdc](chengyue64.sdc) |
| `SYNTH_MAX_FANOUT` | `8`，ABC 真实缓冲树的扇出目标 |
| `SYNTH_MAP_DELAY_PS` | `600`，ABC 映射目标；并不改变 1 ns 时钟约束 |
| `STA_RESULT_ROOT` | 默认 `build/chengyue64/sta/`，相对于 RV64 工程 |
| `OPENSTA` | 默认工作区 `tmp/rv64-opensta/build/sta` |

SDC 包含 50 ps 时钟不确定度、最大 400 ps I/O 延迟、最小 0 ps I/O 延迟，
以及 20 fF 输出负载。实际端口由 [prepare_sdc.py](prepare_sdc.py) 从映射后的顶层枚举。
修改映射参数需要重新综合，不能复用旧参数下的映射结论。

## STA 引擎和结果

`make sta` 转到 `sta-opensta`，使用 [opensta.tcl](opensta.tcl) 和
[check_opensta.py](check_opensta.py)。默认结果目录为
`build/chengyue64/sta/R64CoreTop-1000MHz/`；更换顶层或频率后目录名相应变化。

- `*.netlist.v`：综合映射结果。
- `*.sta.v`：供 STA 使用的展开网表。
- `opensta.sdc`、`opensta.rpt`、`opensta.json`、`opensta.log`：实际约束、路径和运行日志。
- `timing-summary.json`：检查器输出的判定；setup 或 hold 有负值均失败。
- `sta_area.txt`：实际参与 STA 的网表面积。

`make sta-ieda` 保留为诊断入口。当前本地 iEDA 对 ICG path group 漏扣 uncertainty，
不能用它判定含 ICG 设计时序通过。SDC 中仍显式设置 setup/hold 与 rise/fall 的四种
uncertainty 组合；历史省略这些设置的报告不能作为同约束测量。

这些是布局前约束和报告。没有 P&R、寄生提取及相应 corner 的证据时，不声称物理签核
或合格功耗。当前发布版本的 **1 ns / 1 GHz 时序仍为 FAIL**；500 MHz 和早期冻结候选
的结果只属于[历史记录](../design/history/README.md)。

## 输入路径 hold 修复

[repair_input_hold.py](repair_input_hold.py) 在独立网表中插入真实 Liberty 正向缓冲单元，
核对原有单元类型及收缩缓冲后的连接图，并记录新增面积。工程入口为：

```sh
make -C npc/rv64 sta-hold STA_HOLD_ARGS=--through-logic
make -C npc/rv64 sta-hold STA_HOLD_ARGS="--source-branches --clock-enable"
```

| 参数 | 作用 |
| --- | --- |
| 无附加参数 | 修复直接输入到寄存器 D 端的负 hold 路径 |
| `--through-logic` | 也处理输入经过组合逻辑到 D 端的路径 |
| `--clock-enable` | 允许处理 Liberty 标记的 ICG enable 数据端；始终排除时钟引脚 |
| `--source-branches` | 在输入的首个负载前共享缓冲，避免在最终 D 端拖慢汇合的其他路径 |
| `--source-fanout` | 每条缓冲链最多共享的首级负载数，默认 8 |
| `--output-branches` | 配合 `--source-branches`，处理输入到顶层数据输出的路径 |
| `--output-stages 1` | 为只到数据输出的分支指定较短缓冲链；与寄存器共用时取两者较大值 |

直接调用脚本时可以重复 `--checks` 合并同一网表的 min 路径报告。
一次修复后可能暴露同一 endpoint 的其他短路径，插入缓冲本身不代表时序通过。
该入口不改变 RTL 拍数或放宽时钟、I/O、load、uncertainty，修复后按同一 SDC
重新检查 setup 和 hold。输出在结果目录的 `hold-repaired/`，包含修复网表、
`cell-changes.json` 和重新运行的 STA 报告。

面积应取实际参与 STA 的 `sta_area.txt` 或 `cell-changes.json`；
`synth_stat.txt` 是层次映射统计，可能还包含展开和清理前的冗余单元。

## 其他工具的适用范围

[macro-lib/](macro-lib/README.md) 和 [../vivado/](../vivado/README.md)
保留旧核宏边界或 FPGA OOC 相关工具。它们的历史拓扑、占位宏及测量不能用于证明
当前默认主线的综合和时序。当前流程以本页所指 Makefile、filelist 和真实网表为准。
