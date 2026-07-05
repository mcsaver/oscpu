# 分析工具与产物（2026-07-05 方法论复盘 + architecture-first）

本次 task-run 的可复用工具、量化数据与网页报告，从 Claude Code 会话临时目录迁入工作区——**跨平台 / 换工具 / 换机器可用，不随会话目录删除而丢失**。

## workflows/ — 多 agent 分析工作流脚本（Claude Code `Workflow` 工具的 JS）

| 脚本 | 干什么 |
|---|---|
| `reflect_wf.js` | 复盘：9 会话解剖 + 文档/定量 → 综合 → 对抗审查 → 定稿"为什么 debug 慢 / 为什么有 spec 仍出 bug" |
| `arch_first_wf.js` | architecture-first：业界流程 ‖ 54-bug 证据 ‖ spec 粒度 ‖ 契约清单 ‖ 诚实反面 → 综合 → 审查 |
| `land_scout.js` | 落地侦察：agent 环境注入 / 回归 / assert 探针 三线 |
| `flush_contract_wf.js` | flush 契约冻结：4 子系统逆向 → 建表 → 重写评估 → 对抗审查 → 定稿 spec |
| `step0_plumb_wf.js` | Step 0 断言：为 INV-1..4 落实真实信号，产出可编译立即断言 |

复用：Claude Code 里 `Workflow({scriptPath: "<绝对路径>"})`。

## 根目录

- `digest.py` — 会话 jsonl → 精简 timeline + 量化指标 的预处理器（剥离波形/编译输出，保留对话 + 每次编译/跑测/探查/改代码动作）。
- `metrics.tsv` — 21 会话量化数据（时长 / COMPILE / RUNTEST / Edit / PROBE 计数），是复盘"时间黑洞"（Edit/COMPILE≈1.06 等）的硬证据来源。

## reports-html/ — 网页版报告（自包含 HTML，可离线打开）

- `rv64-postmortem.html` — 为什么 debug 慢 / 为什么有 spec 仍出 bug
- `arch-first.html` — 怎么像 IC 公司一样 architecture-first

（曾在线发布为 claude.ai artifact，此为工作区留存版；内容与同目录上级的 `postmortem-why-slow.md` / `architecture-first.md` 一致。）
