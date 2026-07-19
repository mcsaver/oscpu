# AI Environment

本文件是仓库级 AI 开发环境入口索引。原则：Git 中只保留 source、contract、shim、template、manifest；生成物、运行物、历史大包、重型证据和 cache DB 不进入 tracked source。

## 日常开工（最短路径）

1. 从 `AGENTS.md` 进入通用规则；本文件只导航，不复制完整规则。
2. 运行 `python3 scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 获取 bounded 上下文。
3. 读取相关 `instructions/*.instructions.md`、module memory 和模块 README/spec。
4. 按目标选择 domain profile；AI 环境改动用 `agent-system`，RV64 PPA 同时考虑 `npc`、
   `verilator-tapeout`、`yosys-sta`，不能用环境 profile 代替业务 gate。
5. 派发本地 RV64 RTL 子 agent 时，先用 `.github/skills/prepare-rtl-task-contract/` 生成并校验
   最小权限契约；平台 review 只隔离当前子任务，不自动关闭长期父目标。
6. 实施、验证、记录后运行 `scripts/agent-e2e.sh --guard --guard-mode strict`。

`brief` 只有在 Markdown/JSON 明确给出 `recall_status=complete` 时才算召回成功；显式 profile、
canonical 规则或独立关键词 focus 缺失，以及任何必需 chunk 装不进 `max_tokens`，都会非零退出并
标记 `recall_status=failed`。CLI/API 与 e2e runner 的 bounded brief 默认预算统一为 2400 tokens，
runner 可用 `E2E_CONTEXT_BRIEF_MAX_TOKENS` 显式覆盖；调用方不得把预算失败降级为 WARN 后继续宣称 profile GREEN。

e2e runner 只接受原子落盘且顶层头字段唯一的召回产物：`context-brief.md` 必须以
`# Agent Brief` 开头并绑定 `ok=true`、`recall_status=complete`、请求 profile、硬 token budget，且
`Chunks` 顺序包含 canonical 规则、请求 profile 与独立 focus，每个 chunk 都必须带完整 metadata 和
非空正文；`profile-resolve.md` 必须以
`# E2E Resolved Profile` 开头，绑定 `ok=True` 与同一 profile，并让 node count 与 `Nodes`/run manifest
闭包一致，节点序号必须连续且 ID 唯一。completed run 必须全节点 PASS，并把 run/report/manifest/index/
dispatch 的 task/trace/slug、report/manifest 语义时间，以及 resolve/manifest/report/dispatch/`nodes.tsv`
中的 `node_id/source_profile/module/owner/function/status/inputs/outputs/evidence` 全元组逐项绑定；validator 还会现场递归解析当前 `.github/e2e/profiles/<profile>.tsv` include closure，把前八项逐节点回绑 live profile，不能靠一致改写多份产物伪造节点。dispatch 必须严格按 startup 两个 PASS、随后每个节点 `in-progress -> PASS` 的全局顺序出现，11 个 payload 字段全部匹配；每个节点的首要 evidence 必须是该节点 canonical `evidence/<node_id>.log`，可选辅助指针也必须落到 actual indexed ordinary evidence。`evidence-index.md` 会重算每个普通 evidence 文件的路径、尺寸和 SHA-256。
召回、profile resolve、报告渲染、sanitizer、evidence index 或 DB 归档任一阶段失败都必须传播为
非零/blocked，不能由后续成功覆盖。completed 发布采用两阶段契约：先用 `archive-markdown --sync-task-run` 精确同步 staged Markdown；该通用同步既不能创建，也不能撤销已经提交的 publication。随后原子准备绑定 report、manifest、recall、resolve、index、dispatch 与 `nodes.tsv` 哈希的 `complete.marker` 和严格 EOF 的 `completion-publication.md`，最后由专用 `publish-task-run` 在单个 SQLite 事务内复核 marker/artifact/staged DB 快照并提交完成记录。普通归档、promotion、migration、backup 与 rehydrate 都不得创建 completion publication；`runs` 只承认 canonical report header 中的 `db-marker-v1` 和有效 publication。任一 pre-commit 失败都会撤销本次 live marker/publication 并重渲染 blocked；既有已提交 publication 不会被通用同步误删，且 blocked report 不会被 `runs --status completed` 接受。strict guard 同时复核 marker、publication 与 DB/live 精确集合。

RV64 完整双发射/OoO/PPA 的稳定入口是
`.github/instructions/rv64-ppa-optimization-workflow.instructions.md`；架构能力和 promotion 阈值
仍以 `npc/rv64/design/arch/rv64-architecture-ppa-contract.md` 为规范真源。

## 入口文件

- 通用入口：`AGENTS.md`、`.github/AGENTS.md`、`.github/copilot-instructions.md`。
- AI 环境说明：`.github/ai-env/README.md`。
- canonical contract：`.github/ai-env/contracts/agent-env-*.json`。
- live skill：`.github/skills/*/SKILL.md`。
- RTL 子任务契约：`.github/instructions/rtl-agent-task-contract.instructions.md`、
  `.github/skills/prepare-rtl-task-contract/` 与
  `.github/ai-env/contracts/agent-env-rtl-task-contract.json`。
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

数据库只保留固定格式的长期记忆和 task-run 日志：`.github/memory/**`、`.github/task-runs/**/{task-report.md,dispatch-log.md,context-brief.md,profile-resolve.md,evidence-index.md,completion-publication.md}` 等；其中 `completion-publication.md` 只能由 `publish-task-run` 提交，不能从普通 archive/backup/snapshot/rehydrate 恢复。agent、instruction、e2e profile/module、contract 和说明文档直接保留为原文件；读取普通文档优先使用文件系统或 `load --source auto`：

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
- 本地 RTL 子任务派发：先运行 `rtl_task_contract.py create/validate/render`，把 JSON 路径和 SHA-256
  写入当前 task-run 的 dispatch log；`agent-system` profile 的 `rtl-task-contract` 节点负责正例和
  mutation 反例门禁。
- 新增 agent：创建或更新 `.github/agents/<name>.agent.md`，并同步 `.github/agents/AGENT_INDEX.md`。
- 新增长期工作流：先写 path-specific instruction，再接入相关 agent、profile/module contract 和反例 gate；单次 task-run 只能留证，不能成为规则依赖。
- 新增 e2e profile：添加 `.github/e2e/profiles/<name>.tsv`，必要时补 `.github/e2e/modules/<module>.md` 和 `scripts/e2e/modules/*.sh`，再运行 `scripts/agent-e2e.sh --validate-all-profiles`。

## 禁放目录

- `.github/cache/`、`.github/runtime-artifacts/`：运行态 cache/payload。
- `.github/task-runs/**/evidence/`：原始证据 payload，只保留 `evidence-index.md` 和 `run-manifest.json` 指针。
- `.github/archive/`：只保留 `ARCHIVE_MANIFEST.md`、`CHECKSUMS.txt`、`POINTERS.md`。
- `.github/shujuku_aireview/`：一次性审计材料，不作为 active 配置目录。
- `deliverables/**/package/`、`dist/`、`build/`：生成物目录。
