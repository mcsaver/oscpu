# Agent E2E Profiles

本目录描述显式端到端、跨栈集成、长时间系统/性能验证以及 release/publication profile。普通 review、
局部实现、bug 修复和 focused test 不因修改路径、文件数量或 profile 存在而自动进入 E2E；应先选择能直接
回答当前 acceptance criterion 的最小工程检查。

## 真源与入口

- canonical runner 是 [`scripts/agent-e2e.sh`](../../scripts/agent-e2e.sh)。
- profile 的节点、include 与 claim 绑定以 [`profiles/*.tsv`](./profiles/) 为准。
- 节点实现以 [`scripts/e2e/modules/*.sh`](../../scripts/e2e/modules/) 为准；本文和
  [`modules/*.md`](./modules/) 只说明稳定边界，不复制细粒度 oracle。
- `scripts/agent-e2e.sh --list-profiles` 查看现有入口；维护 runner/profile 时才使用
  `scripts/agent-e2e.sh --validate-profile --profile <name>` 或 `--validate-all-profiles`。validate 只检查
  include 展开、场景边界和函数绑定，不执行工程 workload，也不是普通任务的开工 gate。

常用入口：

```bash
scripts/agent-e2e.sh --profile nemu
scripts/agent-e2e.sh --profile nemu-dev
AGENT_E2E_NEMU_UBUNTU_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-gate
AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate
AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-soak
scripts/agent-e2e.sh --profile npc-dev
scripts/agent-e2e.sh --profile nemu-ubuntu-integrated
```

## Profile claim 与隔离

- `nemu`：NEMU reference 配置/ISA 绑定与最小 cpu-test；不声称 Linux、NPC 或 RTL 已验证。
- `nemu-dev`：NEMU Ubuntu static/slice contract；不启动真实 Ubuntu guest。
- `nemu-dev-gate`、`nemu-dev-full-gate`、`nemu-dev-full-soak`：分别增加 focused guest、full Ubuntu
  和 full soak。对应 opt-in 环境变量未设置时 required 节点会 SKIP，整个 profile 闭包不完整，不能 PASS。
- `npc-dev`：只覆盖 npc/sim、single、soc、rv64 合同；不注入 NEMU Ubuntu workload。
- `nemu-ubuntu-integrated`：显式组合 RV64 Linux 与 NEMU focused static/slice 节点；组合 PASS 仍只支持其
  展开的节点，不自动升级为 full Ubuntu、NPC DiffTest 或整机结论。
- `nemu-ubuntu*` 保留为 NEMU Ubuntu canonical/兼容入口；精确 include 关系始终看对应 TSV。
- `discovery`、`software-flow`、`contracts`、`agent-system` 是显式 AI/环境 profile，业务 profile 不自动
  继承它们。

NEMU-only 与 NPC-only profile 在展开后做 fail-closed closure 检查；跨入另一场景的 node、module、owner、
function 或 source profile 会直接失败。运行时只为真实共享可变资源串行，例如同一 build/scratch、current
artifact、端口、数据库、许可证或设备；互不冲突的读取、分析和独立 scratch 构建可以并行。

## PASS 的工程含义

每个 profile 只能支持其明示 claim。以下任一情况都不能记录为 PASS：non-zero exit、timeout、signal、
中断、required 节点 SKIP、缺失完整 terminal evidence，或 persistent/published 长跑未完成必要 cleanup。
guest/system profile 还必须通过其 checker 的正向终态与负向扫描；局部 marker、build 成功、日志存在或
publication 完整都不能替代真实 workload oracle。

DiffTest/compare 必须有两侧可比较产物；Linux/Ubuntu 结论按 firmware/OpenSBI、kernel、PID1、设备事务与
自然 poweroff 分层表达；PPA A/B 必须保持 RTL/filelist/parameter/define/tool/config/corner/workload
一致。固定输入、固定工具与确定 oracle 通常运行一次；只有随机、并发、flaky、测量噪声或机器异常才
按明确阈值重复。

## Compact 与 durable

默认 `persistence=compact`、`context=direct`：runner 从 live TSV 展开并执行节点，保存直接 report、
dispatch、node table 和原始日志；不要求 DB recall，不把 `task_slug` 当语义身份，也不生成 publication
manifest、evidence index、hash marker 或 DB 记录。普通工程 E2E 和本地长门优先使用此模式。

只有明确的 release、migration、security、forensic、publication 或跨会话 provenance criterion 才使用
`--publish`。它切换为 durable + recall，并增加索引、byte-identity 与 publication 闭包；这些产物只证明
持久化/发布完整性，不能把失败、SKIP 或不完整 workload 变成 PASS。仅需历史决定时可单独选择
`--with-context-recall`，它同样不是普通任务的默认前置。

strict guard 也只用于上述显式 durable 场景：
`scripts/agent-e2e.sh --guard --guard-mode strict --paths-file <paths.log>`。它消费调用方给定路径并核对已发布
证据，不扫描工作树替普通开发推导新 gate。
