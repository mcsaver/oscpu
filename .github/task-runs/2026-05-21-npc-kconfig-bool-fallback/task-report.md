# Task Report

## 基本信息

- `task_id`: `2026-05-21-npc-kconfig-bool-fallback`
- `task_slug`: `npc-kconfig-bool-fallback`
- `graph_template`: `regression-debug-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-21 20:21 CST`
- `updated_at`: `2026-05-21 20:21 CST`

## 任务目标

- `source_request`: 修复 benchmark 时弹 VGA 窗口的问题，并检查类似 bug。
- `goal`: 让 `perf_defconfig` 关闭的 NPC bool 配置在 C 侧保持关闭，尤其是 `CONFIG_NPC_HAS_VGA=n` 不再触发 SDL 窗口。
- `scope`: `npc/single/csrc/include/utils.h`、NPC host 配置路径、AM benchmark 启动链路。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | memory、NPC study 索引、源码搜索 | 确认链路 `CoreMark -> ioe_init -> __am_gpu_init -> SYNC_ADDR -> vga_present` | 源码定位 |
| localize | Codex | completed | `perf_defconfig`、`autoconf.h`、`utils.h` | 根因是 Kconfig `bool=n` 未定义被 fallback 成 1 | 预处理修复前可推出 `CONFIG_NPC_HAS_VGA=1` |
| fix | Codex | completed | `utils.h` | bool fallback 改为 0，覆盖 VGA/SDB/EXPR/WATCHPOINT | 代码 diff |
| verify | Codex | completed | 当前 perf 配置 | 宏值、构建、benchmark 启动、cpu-test 正常 | 见下方验证 |

## 验证

- 预处理确认当前 perf 配置下 `CONFIG_NPC_HAS_VGA/SDB/EXPR/WATCHPOINT/DIFFTEST/ITRACE/MTRACE/DTRACE` 均为 0。
- `make -C npc/single -B -j4` 通过。
- `./npc/single/build/NpcSimTop ./am-kernels/benchmarks/coremark/build/coremark-riscv32-npc.bin --max-cycles 50000 --no-progress` 输出 `NPC VGA disabled; GPU_CONFIG will report present=false.`，随后继续执行到预期周期上限。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--no-progress'` PASS。

## 结论

同类问题已扫描：本次修复覆盖 `utils.h` 中所有曾把关闭态 fallback 为 1 的 NPC bool；全仓库未发现其它手写 fallback 把 `CONFIG_*` 关闭态重新定义为 1 的同类风险，剩余命中为生成配置或测试固定配置。
