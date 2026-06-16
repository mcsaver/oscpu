# Task Report

## 基本信息

- `task_id`: `2026-05-19-nemu-cache`
- `task_slug`: `nemu-cache`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-19 17:34 +0800`
- `updated_at`: `2026-05-19 17:34 +0800`

## 任务目标

- `source_request`: `请你给我的 nemu 中实现 cache，icache 和 dcache 并作性能计数器`
- `goal`: 在 NEMU 中加入 ICache/DCache 和可观察的 cache 性能计数器。
- `scope`: NEMU native system 的 PMEM 访问；MMIO 保持直通，不改变设备语义。

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: 任务修改 NEMU 参考路径的取指、数据访存和统计输出，需要用 AM cpu-tests 验证 ISA 行为未回归。
- `dynamic_nodes_added`: `cache-unit-red-green`、`cache-counter-smoke`
- `why_dynamic_nodes_were_needed`: 原仓库没有 cache 单元测试入口，需要新增最小 standalone 测试覆盖 cache 替换/写回/跨行行为。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | AGENTS、Copilot instructions、memory、NEMU 源码 | 取指/访存调用链 | `vaddr_ifetch -> paddr_read`、`vaddr_read/write -> paddr_read/write` |
| design | Codex | completed | 用户确认的默认 cache 规格 | 设计文档 | `docs/superpowers/specs/2026-05-19-nemu-cache-design.md` |
| plan | Codex | completed | 设计文档 | 实施计划 | `docs/superpowers/plans/2026-05-19-nemu-cache.md` |
| cache-unit-red-green | Codex | completed | 计划中的 cache API | cache 单元测试与实现 | RED: 缺少 `memory/cache.h`/`cache.c`；GREEN: `/tmp/cache_unit` 输出 `cache_unit PASS` |
| build | Codex | completed | cache 接线后源码 | NEMU 可执行文件 | `make -C nemu -j4` 退出 0 |
| smoke | Codex | completed | `add` AM 程序 | cache counter 输出 | `ALL=add` PASS，输出 icache/dcache access/hit/miss/hit-rate/writeback |
| regression | Codex | completed | 全量 cpu-tests | 回归结果 | `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run` 35/35 PASS |
| record | Codex | completed | 验证结果 | memory 与 task-run 更新 | `.github/memory/project-status.md`、`.github/memory/modules/nemu.md` |

## 关键产物

- `artifacts`: `nemu/include/memory/cache.h`、`nemu/src/memory/cache.c`、`nemu/tests/{cache_unit.c,generated/autoconf.h}`、`nemu/src/memory/{Kconfig,paddr.c,vaddr.c}`、`nemu/src/cpu/cpu-exec.c`、`nemu/src/isa/riscv32/inst.c`
- `logs_or_traces`: 终端输出包含 unit PASS、NEMU build PASS、`ALL=add` PASS、cpu-tests 35/35 PASS
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: DCache write-back 会让 SDB 直接 `paddr_read` 观察 PMEM 时看不到尚未写回的脏行；当前在程序结束和 `fence.i` 时 flush，后续若需要运行中 monitor 观察一致性，可为 SDB 增加 cache-aware 读或显式 flush 命令。

## 下一步建议

1. 如需更像硬件，可继续把 cache 参数扩展成组相联、替换策略和 miss penalty 统计。
2. 如需调试体验，可在 SDB 增加 `cache` 命令查看/flush cache 状态。

## 模板升级候选

- `repeated_dynamic_subgraph`: `cache-unit-red-green`
- `should_promote_to_static_template`: `false`
- `reason`: 目前只用于本次 NEMU cache 功能，尚未形成重复跨任务图。

## 收尾结论

- `final_result`: NEMU 已接入 ICache/DCache 和性能计数器，默认 Kconfig 参数为 4KB/64B line。
- `evidence_summary`: 单元测试 PASS、NEMU 构建 PASS、`ALL=add` PASS 且输出 cache counter、cpu-tests 35/35 PASS。
- `notes`: 本次未回退工作区中既有未提交变更，只追加本任务相关文件和记录。
