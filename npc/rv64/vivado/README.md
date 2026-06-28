# Vivado 综合 / 时序分析（vivado/）

用 Vivado 对**可综合核**(`NpcTop` + `RTL_CORE_SRCS`，排除 sim/DPI)做 OOC 综合，
产出时序/关键路径/资源报告，作为**数据驱动时序(Fmax)优化**的依据。

## 用法
```bash
cd npc/rv64
vivado/run-synth.sh [PERIOD_ns] [PART]
#   PERIOD 默认 2.0ns(激进,逼出负 slack 以暴露关键路径)
#   PART   默认 xc7a100tcsg324-1(ysyx Nexys A7 常用件)
#   4 核(synth.tcl: general.maxThreads 4；WSL 下 8 核内存压力过大会崩溃)
#   CPU 亲和: 绑核 8-11 + nice -n 15(给系统/Claude/vscode/wsl 留核,防整机阻塞)
#   可用 CPUSET=.. NICE=.. 覆盖
```
- 文件清单与 include 目录从 Makefile 的 `RTL_CORE_SRCS`/`RTL_INCLUDE_DIR` 自动导出(单一真源)。
- include 搜索路径含 `vsrc/` 与 `vsrc/include/`(对齐 Verilator 的 `-I`)。

## 产物（vivado/out/<时间戳>/，不入 git）
- `timing_summary.rpt`：WNS/TNS、时钟、违例概览。
- `timing_paths.rpt`：最差 30 条路径(全展开)，用于定位关键路径的**起点/终点/经过的模块与信号**。
- `utilization.rpt`：LUT/FF/DSP/BRAM 资源。
- `vivado.log`：完整日志。`out/latest` 软链指向最近一次。

## 时序优化工作流（数据驱动，配合 design/arch/ROADMAP.md）
1. 跑 OOC 综合(激进周期)→ 读 `timing_paths.rpt` 找最差路径。
2. 定位该路径所属模块/逻辑(常见嫌疑：PMP 16-entry 比较、issue queue oldest-select、
   除法器 radix-4 商位选择、宽 mux/优先级链)。
3. 在 `design/specs|arch/` 更新该模块 spec(状态机/流水切分方案)→ 改 RTL。
4. `eval/npc-eval.sh --all` 守 CPI/正确性(三 gate 全绿) + 重综合确认 WNS 改善。
5. 记录 A/B(WNS 前后 + CPI 前后) 到 task-run；负优化撤回。

## 约定
- 综合只读核 RTL，**不含** `vsrc/sim/*.sv`(DPI/$display 等不可综合)；核 RTL 已验证 0 个 initial/DPI。
- OOC 模式：不做物理引脚约束与布局布线，给出综合级时序估计；足以定位关键路径与相对优化。
  如需更准的 Fmax，可后续加 `opt_design/place_design/route_design` 与真实 XDC。

## WSL 崩溃根因与规避（经验）
**现象**：用 Vivado 综合整核(`NpcTop`,34k 行)且 `-flatten_hierarchy rebuilt` 时 WSL 多次整机崩溃，
即便已降到 4 核 + 绑核(taskset 8-11) + nice。
**根因=内存压力，非 CPU**：整核**全展平**综合 + 34k 行设计的时序图，内存峰值远超 synthesize
阶段日志可见的 ~3.5GB；在 WSL(总 15GB,默认上限更低)下击穿内存→OOM/整机崩溃。CPU 亲和/nice
只能防 CPU 阻塞，挡不住内存峰值。
**规避(已验证)**：
1. **首选按模块 OOC 综合**(`run-synth-module.sh <Module>`)：只综合单模块子树,内存仅 ~1.6GB、
   ~40s 完成、可用内存稳在 11GB+,零崩溃;且直接给出该模块关键路径(定向时序优化所需)。
   关键路径几乎总在某嫌疑模块内(issue 选择/除法器/PMP/宽 mux),逐个综合比较即可定位。
2. 整核综合(`run-synth.sh`)如需,应改 `-flatten_hierarchy none`、降 maxThreads(2),
   并考虑在 `~/.wslconfig` 设 `[wsl2] memory=12GB` 给 WSL 明确上限(由用户配置)。
3. 综合一律 nice+taskset 绑到部分核(8-11),给 Claude/vscode/wsl 留核。
