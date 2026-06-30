# RV64 NPC 统计/trace 细粒度 Kconfig 开关 + 性能模式

## 目标(用户要求)
- 给每个统计类别独立 Kconfig 开关,关掉的不编译进去(运行/编译零开销)。
- 新增「性能模式」:开启后所有 trace + 统计全部关闭。
- 范围:用户明确选「C 侧 + RTL 探针一步到位」。

## 关键发现(先摸清再动手)
- **trace 已编译期门控**(`NPC_TEXT_TRACE` 罩 itrace/mtrace/dtrace、`NPC_TRACE_BY_DEFAULT` 罩 wave)。
- **统计完全没门控**:`g_sim_perf.*` 逐拍累加、`report_branch/cache/ooo_stats` 无条件打印。
- **RTL 侧 ``ifdef`` 基础设施其实还在**(`NpcSimTop.sv` 的 `CONFIG_NPC_{SIM,BRANCH,CACHE,OOO}_STATS`、`DEBUG_PORTS`),但 **Kconfig 选项 + Makefile 接线(`RTL_VERILATOR_DEFINES :=` 空)已被删** → 这些 ifdef 是死代码 → 探针从不编进 → **CoreMark 里 `icache=0/BTB hit 0/RAS hit 0/branch accuracy 0/0` 全是零**(半还原状态,memory 2026-06-25 那条已 stale)。
- 采集入口都是干净 `extern "C"` DPI:`npc_control_flow_event`(C 侧从 commit 流,经 `record_ooo_control_flow_commit`@847)、`npc_bpu_lookup/resolve_event`、`npc_i/dcache_event`、`npc_ooo_cycle_event`。`SIM_STATS`(NpcSimTop 654-779)是共享探针 wire 网络,BRANCH/CACHE/OOO 调用点都依赖它。`pct_u64` 仅 OOO 用。
- 去风险:`make lint RTL_VERILATOR_DEFINES="+define+...4个"` → exit 0,证明重构后探针信号仍可编译 → 默认开安全。
- 机制:`Makefile:151 -include autoconf.h`(C 宏)、`Makefile:111/176 $(RTL_VERILATOR_DEFINES)`(Verilator/lint),`-include auto.conf` 给 Makefile 拿到 `CONFIG_*=y`。加 Kconfig 选项即自动流通,无需额外 Makefile 改。

## 设计(三级层次)
```
NPC_PERF_MODE (默认 n) 主控:on → 编译掉所有 trace + 统计(含 RTL 探针)
  NPC_TEXT_TRACE / NPC_TRACE_BY_DEFAULT 加 depends on !NPC_PERF_MODE
  NPC_SUMMARY_STATS (默认 y, !PERF_MODE)  C-only:cycles/CPI/mtime/host-time
  NPC_SIM_STATS     (默认 y, !PERF_MODE)  RTL 探针网络总开关
    if NPC_SIM_STATS: NPC_BRANCH_STATS / NPC_CACHE_STATS / NPC_OOO_STATS (默认 y)
  NPC_DEBUG_PORTS   (默认 n, !PERF_MODE)  调试观测口(与统计正交)
```
`HIT GOOD/BAD TRAP` 结果行(cycles/commits)始终打印(是运行结果非统计)。

## 改动(5 类文件)
1. `npc/rv64/Kconfig`:新增 "Statistics and Profiling" 菜单(上述选项);trace 两项加 `depends on !NPC_PERF_MODE`。
2. `npc/rv64/Makefile`:`RTL_VERILATOR_DEFINES` 从 `CONFIG_NPC_{SIM,BRANCH,CACHE,OOO}_STATS`/`DEBUG_PORTS` 派生 `+define+`。
3. `npc/rv64/csrc/cpu/cpu-exec.cpp`:**10 处 `#ifdef`**——branch 函数块(1028-1157)+ 调用(847)、cache 块(1159-1185)、ooo 块(1187-1393,含 pct_u64/window/cycle_event)、report_branch/cache/ooo_stats 各自函数、report_statistics 的 SUMMARY 块 + 三个 report 调用各按类门控。计数器存储保留(无 -Werror,极少 unused 警告非致命)。
4. `configs/perf_defconfig` + `configs/rv64_perf_defconfig`:加 `CONFIG_NPC_PERF_MODE=y`。
5. (无需改 scripts/config.mk;`%defconfig` 规则已能加载+syncconfig。)

## 验证(三种组合,全量重建 + CoreMark ITERATIONS=10)
| 配置 | 结果 |
| --- | --- |
| **全开**(default_defconfig) | 编译 0 错;统计**现在有真实数据**(branch acc 565689/591119=95.7%、BTB hit 20009、RAS hit 2239、icache acc 1877990、dcache acc 697615、OoO retire hist 非0);GOOD TRAP code=0、CPI 1.024、CoreMark/MHz 3.079 |
| **perf 模式**(perf_defconfig) | 编译 0 错;Verilator 无 `+define stats`;**统计行计数=0**(无 Branch/Cache/OoO/CPI/mtime);GOOD TRAP 在;CoreMark guest 输出(PASS/Marks/CoreMark-MHz)保留 |
| **只 CACHE**(临时 defconfig,已删) | 编译 0 错;Verilator 仅 `+define CACHE_STATS+SIM_STATS`;**Cache 行=3、Branch/OoO/CPI 行=0**;GOOD TRAP 在 → 证明独立门控 |

## 附带修复
重新接线后,此前「半还原死探针 → 统计全 0」的 bug 自动修复:cache/BPU/RAS/OoO 统计默认开时显示真实微架构数据。

## 残留 / 风险
- perf/部分关配置下,被门控掉的统计全局量可能触发 `-Wunused-variable/function`(无 -Werror 故非致命);如需零警告可后续把全局存储也按类门控。
- 全开配置默认编进 RTL 探针网络 → 默认仿真比纯 perf 慢;需要极速基线用 `perf_defconfig`(已 `--max-cycles 0`)。
- 全量 AM/difftest/riscv-tests 回归未在「全开」配置重跑(探针是只读观测、不改架构行为,difftest 设备读已 skip_ref;CoreMark + lint 已绿)。提交前建议补跑。
- 结束态:`.config` 恢复为 default_defconfig + max_cycles=100M(用户原值)+ 统计默认全开;perf 用 `make perf_defconfig`。
