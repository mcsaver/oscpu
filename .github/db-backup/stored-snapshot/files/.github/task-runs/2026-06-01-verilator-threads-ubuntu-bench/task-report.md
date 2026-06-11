# Verilator Threads Ubuntu Bench

- `date`: 2026-06-01
- `graph_template`: `verilator-tapeout-readiness-loop`
- `source_request`: 用户允许在 14-core 主机上调用 8 core，要求启用 Verilator 多核仿真加快 Ubuntu；若没有提升则回退，以跑 Ubuntu 为准，不用轻量测试判断。
- `goal`: 用 Ubuntu shell initramfs 长跑窗口对比 Verilator 单线程与 8 线程，决定是否保留 8 线程为当前默认。

## 节点状态

| node_id | owner_agent | status | outputs | evidence |
| --- | --- | --- | --- | --- |
| `baseline-1t` | `verilator-tapeout` | completed | 单线程 Ubuntu shell 120M cycles 基准 | `threads()=1`，`cycles=120000000/commits=24517449`，host time `362499028 us`，`67634 inst/s` |
| `build-8t` | `npc` | completed | 显式 `VERILATOR_THREADS=8` 生成 Verilator 多线程模型 | `VNpcSimTop::threads() const { return 8; }`，生成物含 thread pool/mtask；构建约 `12.50s` |
| `bench-8t` | `verilator-tapeout` | completed | 8 线程 Ubuntu shell 120M cycles 对比 | guest 进度与 commits 完全一致，host time `731380226 us`，`33522 inst/s` |
| `rollback` | `npc` | completed | 回退当前活动产物为单线程默认 | 重建后确认 `VNpcSimTop::threads() const { return 1; }` |
| `record` | `verilator-tapeout` | completed | 更新 memory 与 known issue | `project-status`、`modules/npc`、`known-issues` |

## 结论

- 8 线程没有加速，反而约慢 2.0 倍：`33522 / 67634 = 0.50x`。
- 本轮使用的是 Ubuntu shell initramfs 同一 120M cycles 窗口，日志均进入 Linux 并到 `clocksource: Switched to clocksource riscv_clocksource`，不是轻量 smoke。
- Verilator 5.020 对当前 RTL 报 `UNOPTTHREADS`，说明当前 mtask 切分不足；线程同步和调度开销超过收益。
- 当前默认必须回退/保持单线程。显式多线程入口保留为实验开关，不作为 Ubuntu bring-up 默认路径。

## 修改文件

- `npc/rv64/Makefile`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/memory/known-issues.md`
- `.github/task-runs/2026-06-01-verilator-threads-ubuntu-bench/task-report.md`
- `.github/task-runs/2026-06-01-verilator-threads-ubuntu-bench/dispatch-log.md`

## 关键命令

```bash
make -C npc/rv64/tools smoke-ubuntu-shell-watch \
  LOG_DIR=../env/logs/codex-verilator-threads-baseline-1t-120m \
  UBUNTU_INITRAMFS_MAX_CYCLES=120000000

make -C npc/rv64 clean
make -C npc/rv64 default VERILATOR_THREADS=8

make -C npc/rv64/tools smoke-ubuntu-shell-watch \
  LOG_DIR=../env/logs/codex-verilator-threads-8t-120m \
  UBUNTU_INITRAMFS_MAX_CYCLES=120000000

make -C npc/rv64 clean
make -C npc/rv64 default
```

## 后续建议

- 若继续追仿真速度，优先用 `--prof-exec`/mtask profile 查 Verilator 热点和 mtask 切分，而不是直接调大 `--threads`。
- 更可能有效的方向是减少每拍 host 热路径：简化 sim top 地址译码/默认 slave、压缩统计输出、定位 cache/mem/control wait、或把 Ubuntu gate 拆成可 checkpoint 的阶段。
