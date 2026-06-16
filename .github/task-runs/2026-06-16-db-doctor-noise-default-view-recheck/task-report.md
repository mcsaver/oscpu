# DB Doctor Noise Default View Recheck

## 任务

用户要求修复 `DB doctor` 默认只显示历史 manual log 缺失、旧 shim/evidence stale 这类与本轮无关噪声的问题。目标是让默认维护入口只回答当前是否存在阻塞 drift；历史追溯必须通过显式诊断开关打开。

## 根因

`doctor`/`audit-db-first` 早期虽然把历史 task-run/manual log、旧 shim/evidence stale 归为非阻塞，但默认输出仍暴露 hidden/nonblocking 计数、标签或路径，容易被 agent 误读成本轮状态。

当前修复点在 `scripts/dev_memory/maintenance.py`：先把 raw drift 映射为 strict blocking drift 与 archived/live-index 非阻断 drift；默认只打印 blocking/摘要信息，`--show-nonblocking-drift` 才展开历史诊断。`scripts/dev_memory/cli.py` 提供显式开关，`scripts/e2e/modules/github_index.sh` 和 `.github/e2e/modules/github-index.md` 固化合同。

## 本轮复核

- `doctor --fail-on-drift`：PASS，输出 `blocking_drift=0`，默认无历史 manual log、旧 shim/evidence stale、hidden/nonblocking 字段或路径。
- `doctor --fail-on-drift --show-nonblocking-drift`：刷新三份 live-first 规则文档索引后 PASS，输出 `nonblocking_drift=0`。
- `audit-db-first`：PASS，默认只输出 strict DB-first 摘要。
- `audit-markdown-coverage --fail-on-live-evidence`：PASS，`live_evidence=0`。
- `scripts/agent-e2e.sh --validate-profile --profile github-index`：PASS，确认本任务入口属于 `github-index` profile。
- `py_compile`、`bash -n`、相关文件 `git diff --check`：PASS。

## 边界

这是 agent-system/DB 维护视图 bug 修复，不代表 NEMU full Ubuntu 22.04 PyLong blocker 或完整 Ubuntu 总目标关闭。NEMU 主线下一步仍应继续 `systemctl-lite` 的 wide-ifetch-off/host-fast-off A/B。
