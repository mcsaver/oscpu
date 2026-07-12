# `/tmp` 归档排除说明

本次归档采用项目产物 allowlist。以下内容不进入压缩包：

- `/tmp/ysyx-bpu-static-a`：完整 Git 工作树副本，内容已存在主工作区；其 HEAD、
  分支、状态和大小单独记录在 `2026-07-13-goal-tmp-worktree-metadata.txt`。
- `/tmp/systemd-private-*`、`/tmp/.X11-unix`：操作系统私有目录或 IPC。
- `/tmp/{cc-daemon-1000,claude-1000,codex-ipc,vscode-typescript1000,python-languageserver-cancellation}`：
  编辑器/agent IPC 与缓存，不是工程证据。
- `/tmp/{ivrl*,yosys-abc-*}`：Icarus/Yosys 单次随机 scratch；稳定的测试二进制、
  日志、netlist 和报告另行归档。
- `/tmp/yosys-liberty-scl-cache`：可再生工具缓存，不是唯一工程产物。
- `/tmp/tmp.*`：匿名临时文件；当前发现的该类文件为空。

归档不会删除或改写系统 `/tmp` 中的源内容。可重建的 build 目录和 `.vvp` 仍被保留，
因为用户要求把相关内容全部放入工作区；这里只排除非工程内容、随机 scratch、工具缓存
以及已有主工作区等价内容的完整重复仓库。
