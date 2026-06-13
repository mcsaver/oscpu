# Dispatch Log

## 2026-06-01

- `node_id`: `baseline-1t`
- `owner_agent`: `verilator-tapeout`
- `status`: completed
- `inputs`: 当前单线程 `npc/rv64/build/NpcSimTop`、Ubuntu shell initramfs、Linux Image、OpenSBI shell firmware
- `outputs`: Ubuntu shell 120M cycles 单线程性能基准
- `evidence`: `npc/rv64/env/logs/codex-verilator-threads-baseline-1t-120m/npc-ubuntu-shell-watch.log`；`host time spent = 362499028 us`；`simulation frequency = 67634 inst/s`

- `node_id`: `build-8t`
- `owner_agent`: `npc`
- `status`: completed
- `inputs`: `VERILATOR_THREADS=8`
- `outputs`: 8 线程 Verilator model
- `evidence`: `npc/rv64/build/obj_dir/VNpcSimTop.cpp` 中 `unsigned VNpcSimTop::threads() const { return 8; }`

- `node_id`: `bench-8t`
- `owner_agent`: `verilator-tapeout`
- `status`: completed
- `inputs`: 8 线程 `NpcSimTop`、同一 Ubuntu shell 120M cycles 窗口
- `outputs`: 8 线程未加速，反而变慢
- `evidence`: `npc/rv64/env/logs/codex-verilator-threads-8t-120m/npc-ubuntu-shell-watch.log`；`host time spent = 731380226 us`；`simulation frequency = 33522 inst/s`

- `node_id`: `rollback`
- `owner_agent`: `npc`
- `status`: completed
- `inputs`: 8 线程 A/B 失败结论
- `outputs`: 当前活动 `NpcSimTop` 回退到单线程
- `evidence`: 重建默认目标后 `unsigned VNpcSimTop::threads() const { return 1; }`

- `node_id`: `record`
- `owner_agent`: `verilator-tapeout`
- `status`: completed
- `outputs`: 更新长期记忆和本 task-run
- `evidence`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md`
