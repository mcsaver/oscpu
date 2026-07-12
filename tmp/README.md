# 临时证据归档

此目录保存系统 `/tmp` 中与当前 RV64 架构优化目标相关、但尚未进入正式
`.github/task-runs/` 的日志、仿真二进制与综合中间产物。

- `2026-07-13-goal-tmp-snapshot.tar.zst`：按 allowlist 收集的历史/当前目标临时产物。
  最终归档覆盖 134 个 `/tmp` 顶层来源、712 个 archive members，源内容共
  846,552,126 bytes，压缩后 17,555,742 bytes；SHA-256 为
  `0cc175cfb0049621d986a7019789d2b5eae28b078d47ecb3b1ab3fd394d3c9bb`。
  `zstd --test` 与 `tar --list` 均已通过。
- `2026-07-13-rv64-ifu-access-g1/NpcTop-200MHz-fresh.tar.zst`：本切片 fresh 5ns
  synthesis 的完整稳定产物（netlist、Yosys log、synth check/stat、provenance），大小
  22,294,373 bytes，SHA-256
  `9a483b3f1b67e9c575076f0a04ce2cdaf636c5a54670592b411cb417a0e28e38`；
  `zstd --test` 与 `tar --list` 均已通过。
- `2026-07-13-goal-tmp-snapshot.source-list.txt`、`.inventory.tsv` 和 `.contents.txt`：
  分别记录顶层 allowlist、原始大小/类型/时间戳，以及压缩包成员。
- `2026-07-13-goal-tmp-exclusions.md`：逐类说明未归档的系统/IPC、随机 scratch、
  可再生工具 cache 和重复 worktree。
- `SHA256SUMS`：压缩包、清单和重复 worktree 元数据的校验值。

完整临时 Git worktree（例如 `/tmp/ysyx-bpu-static-a`）若 clean 且内容已存在主工作区，
只记录元数据而不重复打包整个仓库；这是去重，不是丢弃唯一证据。

系统 `/tmp` 执行脚本为 `archive-related-system-tmp.sh`，fresh STA 执行脚本为
`archive-fresh-sta.sh`。两者均不会删除源内容。
