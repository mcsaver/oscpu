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

默认综合顶层为 `R64CoreTop`，PDK 为 `icsprout55`，目标频率为 500 MHz（2 ns 周期）。
本轮采用实验验证口径：标准单元和 SRAM 均以 **TT、1.2 V、25°C** 做综合/STA 和可比 PPA
分析；SS、多工况及布局后签核不作为本轮实验验收要求。ISA、双发射乱序、精确异常、
恢复、访存序和总线协议等功能/架构要求保持原标准，实际 TT 时序结果仍如实报告。
默认 ICache data 使用两个真实 ECOS55 256×128 整字写 SRAM 宏，DCache data
使用四个真实 ECOS55 256×64 逐 bit 掩码写 SRAM 宏，分别提供 8 KiB 数据容量。
宏以带真实 Liberty 的 leaf 进入综合、面积统计及 STA，不使用占位模型。
算术逻辑、cache tag/valid/LRU、物理寄存器堆和其余未适配数组仍进入标准单元映射。
加载宏 Liberty 不等于自动将其他数组映射为 SRAM。
来源及接口见 [ECOS SRAM](../third_party/ics55_ecos_sram/README.md)。
测试顶层和 C++ DiffTest 不进入综合。

DCache 针对 ECOS 单口 1RW 工艺宏使用两个独立 bank，每 bank 两个 way 宏，
并配两项写合并 FIFO、逐 byte 转发、查询结果保持和有限等待的读/排空仲裁。
byte mask 展开到宏的低有效 64-bit WEB；不使用整字读改写，也不借用 ICache 宏的一半容量。
tag 仍保持原 2R1W 契约。完整的 refill、失效、B 响应与事务可见性合同见
[DCache 存储合同](../vsrc/lsu/TOPOLOGY.md)和
[ECOS 适配架构](../design/arch/ecos-memory-adaptation-20261012.md)。

| 参数 | 默认值 / 含义 |
| --- | --- |
| `STA_DESIGN` | `R64CoreTop`；必须与实际网表顶层一致 |
| `STA_CLK_FREQ_MHZ` | `500`，对应 2 ns 时钟 |
| `STA_SDC_FILE` | [chengyue64.sdc](chengyue64.sdc) |
| `SYNTH_MAX_FANOUT` | `8`，ABC 真实缓冲树的扇出目标 |
| `SYNTH_MAP_DELAY_PS` | `600`，ABC 映射目标；并不改变 2 ns 时钟约束 |
| `STA_RESULT_ROOT` | 默认 `build/chengyue64/sta/`，相对于 RV64 工程 |
| `OPENSTA` | 默认工作区 `tool/opensta/bin/sta` |
| `STA_ECOS_SRAM` | `1`，启用当前 ICS55 宏及 TT Liberty；生产核不可关闭 |
| `STA_EXTRA_LIB_FILES` | 默认同时加载 ICache 256×128 与 DCache 256×64 的 TT 1.2 V / 25°C Liberty，参与 link、stat 与 STA |
| `STA_BLACKBOX_MODULES` | 默认上述两个真实 ECOS cell 名；不能用来跳过实际实现成本 |

SDC 包含 50 ps 时钟不确定度、最大 400 ps I/O 延迟、最小 0 ps I/O 延迟，
以及 20 fF 输出负载。实际端口由 [prepare_sdc.py](prepare_sdc.py) 从映射后的顶层枚举。
修改映射参数需要重新综合，不能复用旧参数下的映射结论。

## STA 引擎和结果

`make sta` 转到 `sta-opensta`，使用 [opensta.tcl](opensta.tcl) 和
[check_opensta.py](check_opensta.py)。默认结果目录为
`build/chengyue64/sta/R64CoreTop-500MHz/`；更换顶层或频率后目录名相应变化。

- `*.netlist.v`：综合映射结果。
- `*.sta.v`：供 STA 使用的展开网表。
- `opensta.sdc`、`opensta.rpt`、`opensta.json`、`opensta.log`：实际约束、路径和运行日志。
- `opensta-min-period.rpt`、`opensta-min-pulse-width.rpt`：Liberty 时钟最小周期和脉宽检查。
- `timing-summary.json`：setup、hold、最小周期或脉宽任何一项负裕量均失败。
- `sta_area.txt`：实际参与 STA 的标准单元与 SRAM 宏总面积。

宏 Liberty 只用于 link、面积和时序，ABC、clockgate 与 dfflibmap 仍只使用标准单元库。
默认 SRAM 对应 `icsprout55`；其他 PDK 需要匹配的物理存储实现，不允许混用。
`STA_ECOS_SRAM=0` 仅用于不含该宏的诊断顶层。更改宏或库会触发重新综合。

供应方 TT Liberty 对 ICache 256×128 宏给出的最小周期约为 1.57–1.70 ns（随输入 slew 变化）；
读 clock-to-Q 表内范围为 1.2311–1.5454 ns（clock slew 0.008–0.4 ns、Q load 0.005–0.3 pF）。
按表内最大值，2 ns 还剩 0.4546 ns 覆盖后级逻辑、连线、接收 setup 和 uncertainty，
因此这些宏参数允许继续做 TT 500 MHz 实验，但不单独证明整条返回路径满足 2 ns。
本轮先按 TT 核实 500 MHz 的实际路径，不因历史 SS 1.08 V / 125°C 的
3.47–3.66 ns 读最小周期而预设宏必须降到 250 MHz。
DCache 256×64 掩码宏的 TT 读最小周期为 1.4396–1.5883 ns，写最小周期为
1.4189–1.5879 ns；读 clock-to-Q 表内范围为 1.0842–1.3983 ns。
按表内最大值，2 ns 扣除宏读延迟与 50 ps uncertainty 后剩 0.5517 ns，
还需覆盖接收 setup、转发/选择逻辑和连线。最终判断必须来自实际连接后的 STA。

500 MHz 是设计约束，实验时序是否通过以 TT 下的真实检查结果为准。

`make sta-ieda` 保留为诊断入口。当前本地 iEDA 对 ICG path group 漏扣 uncertainty，
不能用它判定含 ICG 设计时序通过。SDC 中仍显式设置 setup/hold 与 rise/fall 的四种
uncertainty 组合；历史省略这些设置的报告不能作为同约束测量。

这些是布局前约束和报告。没有 P&R、寄生提取及相应 corner 的证据时，不声称物理签核
或合格功耗。已发布版本的 **1 ns / 1 GHz 时序仍为 FAIL**；早期 500 MHz 和冻结候选
的结果只属于[历史记录](../design/history/README.md)，不能作为当前 500 MHz 默认目标已通过的证据。


## 当前 ECOS I/D Cache 实验结果

2026-10-12 的真实 TT 500 MHz 测量包含 2 颗 ICache 宏与 4 颗 DCache 宏：
整核映射面积 **2.406410 mm²**，较本轮前 **2.906951 mm²** 减少 **17.2187%**。
完整 CoreMark 10 / Dhrystone 10000 的本轮前后 A/B 周期和采集性能计数相同。

500 MHz setup WNS 为 **-5.034887791 ns**（基线 -3.147320986 ns），存在新增控制链退化；
hold WNS -0.313464463 ns，最小周期裕量 +0.408300072 ns，
全局最小脉宽裕量 -20.870256424 ns，整体 **STA FAIL**。
宏化/面积收益与时序收敛分开报告；保持原 2 ns 约束，不删除失败检查。
详见[本轮结果](../../../build/ecos-dcache-20261012/RESULT.md)与
[架构合同及后续边界](../design/arch/ecos-memory-adaptation-20261012.md)。


## 每批结束后的空间回收

每轮综合、STA 与必要路径分析结束后，只长期保留结果与必要复现信息。
保留实际 SDC、工具/命令配置、综合检查和 stat、最终面积、原始 STA report/log/JSON、
摘要、功能结果和错误诊断；源码快照、补丁、oracle 与 guest 镜像也保留。
**mapped / STA 网表及其 gzip 副本不再长期保留。需要重查网表或重新做网表分析时，必须重新综合。**

使用 [finish_round.py](finish_round.py) 显式收尾，传入这一轮已经存在的最终 STA 目录。
此目标没有构建依赖，也不会自动挂在 `make sta` 后；应在综合、STA 和必要分析进程全部退出后调用。
它不会遍历或清理其他轮次，也不会修改原有 PASS / FAIL / INCONCLUSIVE 判定。

```sh
# 在工作区根目录运行；先看清单时可附加 --dry-run（不写文件、不删除）。
python3 npc/rv64/syn/finish_round.py \
  --round-dir build/ecos-dcache-20261012/sta/R64CoreTop-500MHz --dry-run

# 正式收尾：通过绝对路径明确这一次的最终 STA 目录。
make -C npc/rv64 sta-finish-round \
  STA_FINISH_ROUND_DIR="$PWD/build/ecos-dcache-20261012/sta/R64CoreTop-500MHz"
```

仅接受工作区 `build/` 或 `npc/rv64/build/` 下至少两级的具体目录；
根目录、build 根、一级批次根、源码目录、越界路径和符号链接路径会被拒绝。
Linux 下还会只读检查是否有综合/STA 等工具仍引用该目录；这不代替调用方等待本轮工作结束。

清理只匹配指定顶层实际生成的 `TOP.netlist.v`、`TOP.netlist.v.sim`、
`TOP.netlist.v.json`、`TOP.netlist.v.il`、`TOP.sta.v` 及这些文件的 `.gz` 副本。
ABC 临时目录须匹配 Yosys 命名且同时有引用 `input.blif` 的 `abc.script` 和实际输入；
其中只删除已知可再生文件，日志和未知文件仍保留，目录为空才删除。
不按 `*.json`、`*.v` 泛删，不递归清理其他子目录；独立仿真构建使用下述专用入口。

删除前流式读取实际 `TOP.sta.v` 或 `.gz`，把 ECOS 宏实例及 DCache/ICache 归属
写入 `ecos-macro-instances.json`。已有清单保留；同目录重综合时另存带时间的清单。
缺网表、损坏或识别不完整时记录 `unavailable` / `incomplete`，不会补造 PASS 或预期宏数量。
每次收尾另存 `finish-round-*.json`，记录删除清单、字节数、清理错误与原始返回码；
字节数按被删除文件的长度累计，不代表文件系统配额的精确差值。

原 runner/STA 返回码可用 `--upstream-exit-code "$rc"` 传入并原样返回；
原非零码优先于清理返回码，报告同时保存清理错误。未提供该参数时，
工具返回值只表示清理是否完成，不能据此判断综合、STA 或功能通过。
例如已完成全部必要分析后：

```sh
# rc 应是先前保存的真实 runner/STA 返回码。
python3 npc/rv64/syn/finish_round.py \
  --round-dir "$round_dir" --upstream-exit-code "$rc"
# Make 包装亦支持 STA_FINISH_ROUND_ARGS="--dry-run" 或 "--upstream-exit-code 2"。
```

### 仿真结束后的同轮清理

[finish_simulation.py](finish_simulation.py) 在本轮已完成仿真、计数采集和必要诊断后显式调用。
它与综合清理一样只接受具体轮次目录，支持 `build/ecos-opt-20261012/round1-credit`
及其更深目录；没有自动提前执行的构建钩子。路径参数相对于 `--round-dir`，
各选择参数可以重复，不能指向其他轮次或任何符号链接。

```sh
python3 npc/rv64/syn/finish_simulation.py \
  --round-dir "$PWD/build/ecos-opt-20261012/round1-credit" \
  --obj-dir system/obj \
  --vvp-dir directed \
  --command-file system/command.json \
  --upstream-exit-code "$sim_rc"
```

`--obj-dir` 必须含可识别的 Verilator `V*__verFiles.dat`。工具先保存其中的编译命令、
source/target 元信息、`__ver.d` 和生成的 make 配置，再删除该目录第一层已登记生成的
C++/header/make 文件、对象文件/静态库/预编译头，以及与模型前缀同名的 ELF 仿真器。
source 记录明确列出的输入文件、未知文件、日志、报告、guest、oracle 和嵌套目录保留；
不直接递归删除整个 obj。自定义名称的仿真器若不能从模型前缀识别，会作为未知文件保留。

`--vvp` 选择单个 Icarus 产物，`--vvp-dir` 只选择目录第一层的 `*.vvp`；
必须匹配 VVP 文件头，不遍历下层目录。使用 `--command-file` 引用本轮已经保存的
运行/构建参数；该文件保留原样。调用方仍需保存 Icarus 构建命令、仿真参数及真实结果日志，
工具不会从一次 cleanup 反推丢失的运行参数或宣布测试通过。

工具会检查是否有进程仍使用所选对象/仿真器，并记录 `finish-simulation-*.json`，
其中包括删除清单、回收字节数、保留元信息及原 runner 返回码；原非零码优先返回。
`--dry-run` 只打印清单、不写文件、不删除，原 PASS/FAIL 和错误诊断始终保持原样。

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

### 显式时钟负载修复候选

`make -C npc/rv64 sta-clock STA_RESULT_ROOT=/绝对路径/sta` 复用该父轮的
`R64CoreTop.sta.v` 和原 `opensta.sdc`，在独立 `clock-repaired/` 目录生成同名
STA 网表、`cell-changes.json`、真实三库 mapped check/area 与完整 OpenSTA 结果。
普通 `sta` 的 raw 基线保持原行为；候选使用原 setup/hold、ICG-enable、minimum
period/pulse 检查及原时钟传播语义，不因插 buffer 改写约束。

`STA_CLOCK_ARGS` 直接传给 `repair_clock_fanout.py`。默认使用实际 BUFX4H7L，
每级预算取库 max-cap/table 边界的 25% 与 0.02 pF 的较小值，fanout 上限 32；
例如 `STA_CLOCK_ARGS="--max-load-pf 0.015"` 可作为另一独立负载实验。
用 `STA_CLOCK_DIR=/绝对路径/候选目录` 保存另一参数结果。插入单元计入真实面积，
原 ICG 和控制脚保持不变，宏与全部原 pin 在正相 buffer 收缩后保持一致。

完成结果取证后，显式执行 `make -C npc/rv64 sta-clock-finish`，传入同一
`STA_RESULT_ROOT`/`STA_CLOCK_DIR`；失败轮也可使用
`STA_FINISH_ROUND_ARGS="--upstream-exit-code 1"` 保留失败返回码并清理产品。
清理器保留结果与 ECOS inventory，不保留可再生网表。不存在默认复制巨网表备份。

该目标只做 pre-layout pin-capacitance 负载修复，没有布线寄生或物理 CTS。
脉宽或电容改善不能替代 full-core setup/hold，也不构成 500MHz/postroute 签核。

## ECOS SRAM 输入 hold 的有界网表实验

[repair_ecos_macro_hold.py](repair_ecos_macro_hold.py) 是独立、显式启用的 mapped 网表工具，
用于本轮 ECOS 工艺库 SRAM 的所选非时钟输入 hold 修复。它不改变旧
[repair_input_hold.py](repair_input_hold.py) 的独立输入路径合同，也不改变 RTL、SDC 或时钟树。
输入必须是待评估当前网表对应的完整负 hold 报告；可通过已有
`STA_HOLD_PATHS=/absolute/path/negative-hold.json` 接口从 OpenSTA 导出。

```sh
python3 npc/rv64/syn/repair_ecos_macro_hold.py \
  --netlist /absolute/path/clock-parent/R64CoreTop.sta.v \
  --checks /absolute/path/clock-parent/negative-hold.json \
  --liberty /absolute/path/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib \
  --liberty /absolute/path/ics55_ecos_sram_256x128_m4_ww_tt1p2v25cctyp.lib \
  --liberty /absolute/path/ics55_ecos_sram_256x64_m4_tt1p2v25cctyp.lib \
  --macro-cell ics55_ecos_sram_256x128_m4_ww \
  --buffer DLY4X2H7L --stages 3 \
  --output /absolute/path/new-hold-round/R64CoreTop.sta.v \
  --manifest /absolute/path/new-hold-round/cell-changes.json
```

默认首试为每个所选负 hold D 位的 sink branch 插入 3 级实际 H7CL `DLY4X2H7L`，
每条链新增面积 8.4 µm²；这只是实验候选，不预先宣称满足 hold。
`--macro-cell` 必须显式指定，可重复。`--macro-pin` 可重复，未指定时只选择 D；
显式参数给出本轮完整选择，例如
`--macro-pin D --macro-pin A --macro-pin WEB --macro-pin GWEB --macro-pin CEB`。
仅允许这五种非时钟输入；拒绝 CLK、输出和未知名称。
`--stages` 默认为 3，适用于未单独覆盖的 pin。可重复 `--pin-stages PIN=N`
为已选 pin 指定 1..8 级，例如保留 D=3、控制和地址/掩码使用 1 级：
`--stages 3 --pin-stages A=1 --pin-stages WEB=1 --pin-stages GWEB=1 --pin-stages CEB=1`。
拒绝未知或未选择 pin、越界级数及同一 pin 的冲突重复；同值重复幂等。
已选合法 pin 没有负 hold endpoint 时保持 no-op。manifest 记录默认值、覆盖值、
有效 per-pin 配置，以及每个实际 endpoint 的级数与链长。
D 仍必须是 `memory_write` 且 `clocked_on: CLK` 的输入 bus；全部目标 pin/bit
必须具有实际 Liberty 中关联 CLK 的 hold timing。A、D、WEB 展开实际 bus 位序，
GWEB、CEB 按标量处理。256×128 整字写宏没有 WEB 端口，256×64 bit-write 宏有
WEB[63:0]；混合选择允许这种差异，但每个请求 pin 至少存在于一个所选宏，
报告若声称缺少该端口的宏有该 endpoint 则拒绝。
工具展开 Liberty bus type 与网表 concat、位选择、部分选择，校验当前报告的 cell/pin/net 与
FF 或顶层 input launch，以及整个数据路径连接和各路径 net 的单 driver；
拒绝过期端点、宽度错误、不支持表达式和 source net 不匹配。
同一端点的重复 rise/fall 报告只插一条链；未选择的其他负 hold 端点保留在 manifest 中。
不会因一个端点改善而隐藏全局剩余违例。

插入后对**每个原 cell 的每个 pin bit**收缩仅本工具添加的非反相 delay 链并比较，
同时要求只有所选 sink 接入新链、其余源文本完全一致。manifest 保留选择参数、所选端点、
逐级连接、实际库面积及输入/输出身份。
该连接证明不等于时序收敛。必须用原三份 Liberty、原 SDC 和原 clock semantics 重跑
mapped check/stat、全局 setup/hold、最小脉宽/周期及适用的电气检查；保留失败诊断。
工具拒绝覆盖父网表或重复使用已插链的父网表。本批 `hold-tool/run-hold-round.py`
同样接受可重复 `--macro-pin`（默认 D）与 `--pin-stages`，透传并核对级数配置；
必须从同一已完成 clock parent 选择 fresh child；
原 round 输出及其冻结 source hashes 保持不变。
本地测试：`python3 -m unittest discover -s npc/rv64/syn -p 'test_repair_*hold.py' -v`。
