# AI Environment

本文件是仓库级 AI 开发环境入口索引。原则：Git 中只保留 source、contract、shim、template、manifest；生成物、运行物、历史大包、重型证据和 cache DB 不进入 tracked source。

## 日常开工（最短路径）

1. 从 `AGENTS.md` 进入通用规则；本文件只导航，不复制完整规则。
2. 运行 `python3 scripts/github_index_db.py brief <关键词> --profile <profile>` 获取 bounded 上下文。
3. 读取相关 `instructions/*.instructions.md`、module memory 和模块 README/spec。
4. 按目标选择 domain profile；AI 环境改动用 `agent-system`，RV64 PPA 同时考虑 `npc`、
   `verilator-tapeout`、`yosys-sta`，不能用环境 profile 代替业务 gate。
5. 实施、验证、记录后运行 `scripts/agent-e2e.sh --guard --guard-mode strict`。

RV64 完整双发射/OoO/PPA 的稳定入口是
`.github/instructions/rv64-ppa-optimization-workflow.instructions.md`；架构能力和 promotion 阈值
仍以 `npc/rv64/design/arch/rv64-architecture-ppa-contract.md` 为规范真源。

## 入口文件

- 通用入口：`AGENTS.md`、`.github/AGENTS.md`、`.github/copilot-instructions.md`。
- AI 环境说明：`.github/ai-env/README.md`。
- canonical contract：`.github/ai-env/contracts/agent-env-*.json`。
- live skill：`.github/skills/*/SKILL.md`。
- agent 索引：`.github/agents/AGENT_INDEX.md`，具体 agent 文件直接保留在 `.github/agents/*.agent.md`。
- e2e profile：`.github/e2e/profiles/*.tsv`，模块说明在 `.github/e2e/modules/*.md`。
- 维护脚本入口：`scripts/agent-maintain.sh`、`scripts/agent-e2e.sh`、`scripts/package-ai-dev-env.sh`、`scripts/github_index_db.py`。

## 单一真源与内容去向

| 内容 | 单一真源/去向 | 不应放在 |
| --- | --- | --- |
| 全局行为约束 | `.github/AGENTS.md` 与 path-specific instructions | 每个 agent 重复复制 |
| AI 环境日常导航 | 本文件 | 蓝图、contract JSON |
| 图任务/角色分层 | `.github/agentic-hardware-blueprint.md`、`.github/agents/` | memory 或单次 task-run |
| 可复用流程规则 | `.github/instructions/`；短小通用能力放 `.github/skills/` | DB snapshot、最终回复 |
| 可判定机器合同 | `.github/ai-env/contracts/`、domain checker/policy/schema | 兼容 shim、散文自报布尔值 |
| 自动执行与发现 | `.github/e2e/profiles/`、`scripts/e2e/` | 手工命令清单 |
| 当前稳定事实 | `.github/memory/` retained documents | instructions |
| 单次过程/证据 | `.github/task-runs/` + evidence index | memory 长篇日志 |
| cache/重型运行物 | `.github/cache/`、`.github/runtime-artifacts/` 或外部 object store | tracked source |

旧 `.github/agent-env-*.json` 只作兼容 shim；所有真实修改必须落到
`.github/ai-env/contracts/agent-env-*.json`。

## Database Scope

数据库只保留固定格式的长期记忆和 task-run 日志：`.github/memory/**`、`.github/task-runs/**/{task-report.md,dispatch-log.md,context-brief.md,profile-resolve.md,evidence-index.md}` 等。agent、instruction、e2e profile/module、contract 和说明文档直接保留为原文件；读取普通文档优先使用文件系统或 `load --source auto`：

```bash
python3 scripts/github_index_db.py load --source auto --path <path>
```

若 `.github/cache/github-index.sqlite` 丢失，可从备份重建：

```bash
python3 scripts/github_index_db.py rehydrate --backup-dir .github/db-backup/stored-snapshot --yes
python3 scripts/github_index_db.py rehydrate --backup-dir .github/db-backup/task-runs --yes
```

## 使用中迭代

AI 环境不是一次性整理项目，而是业务开发中的反馈控制面。每次发现入口冲突、假绿、证据断链或重复规则，都应在当前业务任务内完成最小纠偏：

```text
发现摩擦 / 假绿 / 入口冲突
 -> classify（导航、规则、机器合同、执行器、证据或长期事实）
 -> 在唯一真源修复
 -> 用反例、mutation 或失败样本证明门禁能抓到问题
 -> 跑 domain profile，并补跑 agent-system / strict guard
 -> 在 task-run 留证，在 memory 只沉淀稳定结论
```

“写了规则但未接入发现与 gate”不算闭环；“命令为 0 但设计点或证据不完整”也不算成功。

## 维护 Gate

常规自检：

```bash
scripts/agent-maintain.sh --mode check
```

profile 校验：

```bash
scripts/agent-e2e.sh --validate-all-profiles
```

商业包生成：

```bash
scripts/package-ai-dev-env.sh
python3 scripts/github_index_db.py delivery-audit
```

生成包输出到 `dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/`，不写回 `deliverables/`。

## 新增规则

- 新增 skill：创建 `.github/skills/<name>/SKILL.md`，再运行 `python3 scripts/github_index_db.py skill-audit`。
- 新增 agent：创建或更新 `.github/agents/<name>.agent.md`，并同步 `.github/agents/AGENT_INDEX.md`。
- 新增长期工作流：先写 path-specific instruction，再接入相关 agent、profile/module contract 和反例 gate；单次 task-run 只能留证，不能成为规则依赖。
- 新增 e2e profile：添加 `.github/e2e/profiles/<name>.tsv`，必要时补 `.github/e2e/modules/<module>.md` 和 `scripts/e2e/modules/*.sh`，再运行 `scripts/agent-e2e.sh --validate-all-profiles`。

## 禁放目录

- `.github/cache/`、`.github/runtime-artifacts/`：运行态 cache/payload。
- `.github/task-runs/**/evidence/`：原始证据 payload，只保留 `evidence-index.md` 和 `run-manifest.json` 指针。
- `.github/archive/`：只保留 `ARCHIVE_MANIFEST.md`、`CHECKSUMS.txt`、`POINTERS.md`。
- `.github/shujuku_aireview/`：一次性审计材料，不作为 active 配置目录。
- `deliverables/**/package/`、`dist/`、`build/`：生成物目录。
