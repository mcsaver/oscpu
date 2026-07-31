# AI Environment

本文件是仓库级 AI 开发环境入口索引。原则：Git 中只保留 source、contract、shim、template、manifest；生成物、运行物、历史大包、重型证据和 cache DB 不进入 tracked source。

## 日常开工（最短路径）

1. 从 `AGENTS.md` 和 `.github/instructions/agent-lightweight-workflow.instructions.md` 分类任务。
   `review/analysis` 直接读取相关代码/spec，不运行 guard。
2. 有落盘修改时运行 `scripts/agent-flow.sh begin --task <id> --class <class>`；每批修改用
   `record --path` 登记，不扫描 Git。
3. 只读取相关 `instructions/*.instructions.md`、module memory 和模块 README/spec。只有需要历史事实
   或跨模块 profile 上下文时才运行 bounded `brief`。
4. 业务开发选择 domain test/仿真/综合/STA 作为开发验证，并用 `agent-flow evidence` 登记结果；
   AI 环境 profile 不能代替业务 gate。
5. 派发本地 RV64 RTL 子 agent 时，用 `.github/skills/prepare-rtl-task-contract/` 的 canonical
    `create → validate → render` 生成并原样派发最小充分工程契约；validate 失败或手改边界的结果只记
   `candidate-only`，范围扩展另建 versioned JSON。主 agent 使用 `rv64-hardware-professional` 术语描述任务，
   `render` 追加 RV64 微架构/RTL/验证/PPA 语境、正向本地作用域声明和多义术语的对象/层级/作用域/
   工程目的限定，且不改变既有工具或推理能力；节点状态留在主 agent 的结构化记录中。用户可见进度与终审摘要也先写具体 module/signal/transaction、EDA 动作和证据，
   协调状态单独落 task-run，不反复复制到 RTL 技术正文；该分层不得削减负向 RTL 版本、断言或覆盖能力。
   创建该子 agent 时使用 `fork_turns="none"`，只把已校验的渲染结果作为初始提示；所需设计事实由
   `allowed_paths`、`required_context` 或 `supplied_material` 提供，不继承父任务完整对话历史。
   子 agent 最终回复首段按“RV64 RTL 对象或本地证据文件 → 周期或编译配置 → testbench/EDA 观测 →
   PASS/GAP 范围”组织；本地 JSON 证据校验出现意外接受或拒绝时，写明具体 schema 字段、工作区相对
   路径、定向单测和返回结果，并保留反例、未知项、原始日志 marker 和真实文件名。
   `render` 只保留上述硬件事实、合同绑定、输入/输出和工程命令；派发管线、父任务历史、协调状态与
   措辞策略不进入子 agent 技术提示。证据工具复核也必须以具体 CPU 债务项、RTL 证据文件、字段、
   测试名和返回码组织。长期 goal 只引用该措辞剖面，不重复展开协调场景。
6. 一轮目标达到确定性交付点后，需要独立审查的任务先运行
   `scripts/agent-flow.sh finish --task <id> --candidate`，审查无改动后再正式 `finish`；小型任务可
   直接正式收尾。C 调度器只调用路径对应的固定 gate pointer；流程占用约 40% 是非阻断复盘目标，
   不设置精确时间门禁。strict e2e guard 仅用于 release/迁移，且必须显式传入 paths-file/path。

task-run 按 `none/compact/durable` 留存：review/analysis 默认不建，落盘开发和环境修改保存 compact
结果，长仿真/综合/STA/系统回放及 release 保存 durable 结果。只归档修改目录、验证指针、结构化工程
决策轨迹、门禁结果和 bounded 日志，不复制完整上下文或重型 payload。

以下 bounded brief、publication、manifest 与 DB 精确集合说明只适用于真实
`agent-e2e.sh --profile ...` dispatch，不是普通任务的默认步骤。

`brief` 只有在 Markdown/JSON 明确给出 `recall_status=complete` 时才算召回成功；显式 profile、
canonical 规则或独立关键词 focus 缺失，以及任何必需 chunk 装不进 `max_tokens`，都会非零退出并
标记 `recall_status=failed`。CLI/API 与 e2e runner 的 bounded brief 默认预算统一为 2400 tokens，
runner 可用 `E2E_CONTEXT_BRIEF_MAX_TOKENS` 显式覆盖；调用方不得把预算失败降级为 WARN 后继续宣称 profile GREEN。

runner 从 `task_slug` 提取独立 focus 时会过滤生命周期噪声。版本/迭代身份必须写成受控相邻片段 `revtag-v<数字><可选字母>`，只有该显式片段会从 focus 删除；裸 `v8`、`v2ray`、内部 `v8a` 等继续参与召回，畸形或重复 `revtag` 直接失败。task slug 本身仍原样进入 report/manifest/DB，因此身份可审计、领域语义不靠启发式猜测，non-history fail-closed 边界不变。

收尾阶段若用本轮稳定结论作为 task-specific e2e 的独立 focus，先通过 `update-stored` 发布 project/module memory，再使用其中已经存在的领域词构造 slug。旧 task-run 仍不得自证，`no independent primary focus match` 的 blocked run 只保留为顺序反例，不能替代 completed evidence。

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
 -> 归类（导航、规则、机器合同、执行器、证据或长期事实）
 -> 在唯一真源修复
 -> 用反例、mutation 或失败样本证明门禁能抓到问题
 -> 跑真实 domain validation，并用 agent-flow evidence 登记
 -> 目标末尾运行路径对应 gate，生成 compact/durable 结果；memory 只沉淀稳定结论
```

“写了规则但未接入发现与 gate”不算闭环；“命令为 0 但设计点或证据不完整”也不算成功。

## 维护 Gate

日常轻量自检（不调用 Python/DB/profile）：

```bash
scripts/agent-maintain.sh --mode quick
```

AI 环境目标轮次结束：

```bash
scripts/agent-maintain.sh --mode final
```

CI/nightly/商业包：

```bash
scripts/agent-maintain.sh --mode release
```

生成包输出到 `dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/`，不写回 `deliverables/`。

## 新增规则

- 新增长时间仿真/综合/系统回放 runner：复用 `scripts/task-run-status.sh`，只有本轮 marker、内容哈希和
  cleanup 全部通过后调用 evidence-complete；`EXIT`、clean early-exit 或 `HUP/INT/TERM` 本身不能
  产生 `PASS`。运行 `scripts/tests/test-task-run-status.sh`，并由 `agent-system` profile 的
  `task-run-status-fail-closed` 节点检查 helper、反例和 runner 接线。
- 新增 skill：创建 `.github/skills/<name>/SKILL.md`，再运行 `python3 scripts/github_index_db.py skill-audit`。
- 本地 RTL 子任务派发：先运行 `rtl_task_contract.py create/validate/render`；`create` 自动声明输出
  JSON 自路径，并生成只含 `workspace_root/allowed_paths/write_paths/allowed_commands` 的 schema v2
  `scope`；schema v1 只保留历史 validate/render 兼容。`render` 自动绑定该 JSON 的路径与 SHA-256
  （不绑定设计 `contract.md`）。把这两项
  逐字写入当前 task-run 的 dispatch log。Windows/Codex→WSL 工程命令按 single-flight 调度，当前唯一
  shell ownership 可以交给一个契约授权节点。需要发现遗漏或核对源码时默认使用 `workspace-files`；
  只有限定材料复核才使用 `--self-contained-no-tools` 和 `--supplied-material`，使 JSON 原生声明
  `allowed_commands=[]`、无写路径，并只消费提示中冻结的 RTL 材料。所有模式都保留 unknowns、替代假设、反例、
  `scope_extension_request`、置信依据和 `inconclusive` 出口，不得强制 PASS 或设置固定发现数量上限。
  任务自然语言使用 `rv64-hardware-professional` 术语；子 agent 渲染提示不携带 `review_pending` 等协调
  状态，真实 RTL 标识符及 CPU 特权/保护/访问异常术语不改写。该措辞剖面不使用关键词黑名单，并与
  能力分档正交。`agent-system` profile 的 `rtl-task-contract` 节点负责 workspace-files、no-tools、硬件
  语境渲染和合同范围反例门禁。
- 新增 agent：创建或更新 `.github/agents/<name>.agent.md`，并同步 `.github/agents/AGENT_INDEX.md`。
- 新增长期工作流：先写 path-specific instruction，再接入相关 agent、profile/module contract 和反例 gate；单次 task-run 只能留证，不能成为规则依赖。
- 新增 e2e profile：添加 `.github/e2e/profiles/<name>.tsv`，必要时补 `.github/e2e/modules/<module>.md` 和 `scripts/e2e/modules/*.sh`，再运行 `scripts/agent-e2e.sh --validate-all-profiles`。
- 修改 live skill/instruction/profile 后，手工 `brief` 前对相关路径运行 `github_index_db.py refresh`；正式 `agent-e2e.sh` 会在生成 startup brief 前自动重建 active live 索引并留下 `context-live-index-refresh.log`，目录级排除 retained/history，且 missing 状态只更新实际扫描且未排除的路径，从流程上拒绝旧规则 chunk 假装成当前召回而不破坏 DB-first memory 状态。

## 禁放目录

- `.github/cache/`、`.github/runtime-artifacts/`：运行态 cache/payload。
- `.github/task-runs/**/evidence/`：原始证据 payload，只保留 `evidence-index.md` 和 `run-manifest.json` 指针。
- `.github/archive/`：只保留 `ARCHIVE_MANIFEST.md`、`CHECKSUMS.txt`、`POINTERS.md`。
- `.github/shujuku_aireview/`：一次性审计材料，不作为 active 配置目录。
- `deliverables/**/package/`、`dist/`、`build/`：生成物目录。
