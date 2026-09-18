# NPC SoC 综合与 STA

入口仍位于 [`../Makefile`](../Makefile)；生产源来自 [`../vsrc/filelist.mk`](../vsrc/filelist.mk)。

## 网表综合与 STA

如果你想对当前可综合核心 `NpcCore` 直接做标准单元网表综合和 STA，现在不用再切到 `yosys-sta/` 目录手动拼长命令；直接在 `npc/soc` 下运行下面两条入口即可：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/soc syn
make -C /home/lyg/PA/ysyx-workbench/npc/soc sta
```

其中：

- `make syn`：只跑 `yosys-sta` 的标准单元综合，生成 `NpcCore.netlist.v` 和综合统计
- `make sta`：在综合基础上继续跑 iEDA 的时序/功耗分析，生成 `.rpt/.pwr/.cap/.fanout/.trans`
- 这条流程默认只综合 `RTL_CORE_SRCS` 中的 `NpcCore` 及其纯 RTL 子模块，不会把带 `DPI-C` 的 `NpcSimTop.sv` 混进综合网表

默认结果目录位于：

```text
npc/soc/build/sta/NpcCore-500MHz/
```

常用覆写参数如下：

- `STA_CLK_FREQ_MHZ=<MHz>`：覆盖时钟频率，默认 `500`
- `STA_CLK_PORT_NAME=<port>`：覆盖时钟端口名，默认 `clk`
- `STA_SDC_FILE=<path>`：覆盖 SDC 约束文件，默认复用 `yosys-sta/scripts/default.sdc`
- `STA_RESULT_ROOT=<dir>`：覆盖综合/STA 结果根目录，默认 `npc/soc/build/sta`

例如，跑一次 `800MHz` 的 STA：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/soc sta STA_CLK_FREQ_MHZ=800
```

或者把结果输出到单独目录：

```bash
make -C /home/lyg/PA/ysyx-workbench/npc/soc sta \
  STA_CLK_FREQ_MHZ=800 \
  STA_RESULT_ROOT=/home/lyg/PA/ysyx-workbench/npc/soc/build/sta-800
```

这组入口默认依赖工作区里的：

- `oss-cad-suite/bin/yosys`
- `yosys-sta/bin/iEDA`
- `yosys-sta/pdk/icsprout55`

如果这些工具或资源缺失，`make syn` / `make sta` 会先在 NPC Makefile 的环境检查阶段直接报出缺失项，而不是等子流程跑到一半才失败。
