---
description: "持久化记忆协议。当 agent 开始处理任何任务时加载，用于读取项目历史上下文、更新工作记录、记录设计决策和调试经验。所有模块 agent 都应遵循此协议。"
applyTo: "**"
---

# 持久化记忆协议

所有 agent 在工作时 **必须** 遵循以下记忆读写协议，确保项目知识跨会话持久化。

## 记忆文件位置

```
.github/memory/
├── project-status.md        — 项目进度总览
├── decisions.md             — 设计决策记录
├── known-issues.md          — 已知问题与调试历史
└── modules/                 — 各模块专属笔记
    ├── agent-system.md      — agent 架构与工作流环境
    ├── software-flow.md     — 软件开发全流程
    ├── npc.md
    ├── nemu.md
    ├── abstract-machine.md
    ├── am-kernels.md
    ├── difftest.md
    ├── ysyx-soc.md
    └── yosys-sta.md
```

> **存储形态（2026-07-08 起 DB-backed）**：上列文件多数已提升为 stored document
> （`.github/cache/github-index.sqlite`），工作区内只留 8 行兼容 shim（开头为
> `# DB-backed ...` 即是）。对 shim 文件：
>
> - **读原文**：`python3 scripts/github_index_db.py load --source stored --path <仓库相对路径>`；
>   批量召回优先 `brief <关键词> --profile <profile>`。
> - **更新（铁律，违反=数据灾难）**：`update-stored` 是**整体替换**语义——你喂给它
>   什么，stored 全文就变成什么。因此追加条目 **必须** 三步走：
>   ① `load --source stored` 导出全文到临时文件；② 在临时文件中追加/修改；
>   ③ `update-stored <路径> --from-file <临时文件> --refresh-shim`。
>   **绝对禁止**把"只含新条目的短文"直接喂给 `update-stored`——那会把整份
>   文档（可能数百 KB 的项目史）替换成几行新内容。2026-07-09 实锤事故：
>   某实施 agent 跳过 ① 直接写入单条目，project-status.md（613KB）与
>   modules/npc.md（575KB）被整体覆盖为 8.4KB/528B，靠会话残留导出才恢复。
> - **写回后必须自检**：`update-stored` 输出的 `bytes=` 必须 **≥ 改前全文字节数**
>   （追加场景只增不减）。发现缩水立即停止后续写操作并从
>   `.github/db-backup/files/` 恢复。度量坑：直接查 sqlite 时 `LENGTH(content)`
>   返回**字符数**非字节数（中文 UTF-8 两者差 ~30%），勿跨单位比较。
> - **委托写回的责任划分**：主会话把任务派给子 agent 时，若允许其更新 memory，
>   prompt 中 **必须** 原文附上本三步协议；否则子 agent 只交回"待追加条目文本"，
>   由主会话统一执行写回。
> - **一致性审计**：`python3 scripts/github_index_db.py audit-db-first`。
>
> 完整 DB 工作流（`promote`/`materialize`/`restore`/`snapshot-stored` 等）见
> `.github/AGENTS.md` §0；非 shim 的 materialized 全文文件仍可直接编辑，但受
> strict 审计约束（live 必须等于 stored，编辑后需 `update-stored` 同步）。

## 任务执行产物位置

```
.github/task-runs/
├── README.md                          — 任务级产物目录说明
└── templates/
    ├── task-report.template.md       — 图任务摘要模板
    └── dispatch-log.template.md      — 节点派发日志模板
```

- `memory/` 用于沉淀稳定结论、长期经验与设计决策
- `task-runs/` 用于保存单次图任务的执行产物、节点状态、证据链和派发历史
- 不要把长日志、逐节点状态变更、阶段性失败细节整段塞进 `memory/`；应优先写入 `task-runs/`

## 工作流程

### 1. 开始任务前 — 读取记忆与本地资料
- **必须** 先读取 `.github/memory/project-status.md` 了解当前项目状态（DB shim 用 `load` 读原文，见上）
- **必须** 读取自己模块对应的 `.github/memory/modules/<模块>.md`
- 如果任务涉及 `.github/agents/`、`.github/instructions/`、`copilot-instructions.md` 或 AI 驱动硬件开发环境本身，**必须** 读取 `.github/memory/modules/agent-system.md` 与 `.github/agentic-hardware-blueprint.md`
- 如果任务涉及 AI 开发环境 e2e、自检、规则发现漂移或“降低 AI 不确定性”，**必须** 读取 `.github/instructions/agent-e2e-workflow.instructions.md`，并用 `scripts/agent-e2e.sh` 生成或复用 task-run 证据包
- 如果对应模块目录下存在已整理的本地学习资料（如 `study/README.md`、规范摘要、实现 checklist、设计笔记），**必须** 先读取索引/README，再按当前任务补读相关资料后再开始规划或编码
- 对 `tmp/`、提取文本等中间资料，只能作为快速检索入口；最终结论应以正式 Markdown 笔记、源码或规范为准
- 如果任务涉及调试，读取 `.github/memory/known-issues.md` 查看是否有历史经验

### 2. 工作过程中 — 记录决策
- 做出重要设计决策时，追加到 `.github/memory/decisions.md`
- 遇到非显而易见的问题时，记录到 `.github/memory/known-issues.md`

### 3. 完成判定前 — 语义核对钩子
- **必须** 回看用户原始请求、已粘贴/上传文档、PLAN/task-run checklist 和本轮实际证据，区分“整体目标完成”与“子任务/阶段完成”
- 如果原始请求是路线图、长期目标、包含多阶段建议，或用户明确要求“继续推进”，不得因某一个子项闭合就记录为整体完成；只能写“本子项完成”，并列出剩余条目
- 只有当原始目标中的全部硬性要求都有客观证据，且没有未处理的用户明确要求时，才能在 project-status、task-report 或回复中使用“完成目标/整体完成”
- 若发现本轮目标被 agent 自行缩小，必须在 RECORD 中写清缩小范围、已完成切片和未完成范围；必要时把误判沉淀为 known-issues 或 agent-system 经验

### 4. 完成任务后 — 更新记忆
- **必须** 更新 `.github/memory/project-status.md` 的相关条目（DB shim 走 `update-stored`，见上；不得直接改 shim 本体）
- **必须** 更新自己模块的 `.github/memory/modules/<模块>.md`（同上）
- 如果修复了 bug，将问题从"活跃问题"移到"已解决问题"
- 若任务属于跨模块、图任务或长链调试，**应当** 同时更新 `.github/task-runs/<日期-任务名>/task-report.md` 与 `dispatch-log.md`

## 记录格式规范

### 项目状态条目
```markdown
- [YYYY-MM-DD] 完成/修改了什么，影响哪些模块
```

### 设计决策条目
```markdown
### [编号] 决策标题
- **日期**: YYYY-MM-DD
- **状态**: 已决定
- **上下文**: 为什么需要做这个决策
- **决策**: 选择了什么方案
- **理由**: 为什么
```

### 问题记录条目
```markdown
### [编号] 问题标题
- **模块**: 出问题的模块
- **现象**: 具体表现
- **根因**: 根本原因
- **修复**: 如何修复
- **教训**: 学到了什么
```

## 约束
- 记忆文件使用中文
- 保持简洁，只记录关键信息，不要长篇大论
- 不要删除历史记录，只追加新内容
- 更新时保持文件结构不变（对 DB-backed 文件，"结构"指 stored 原文的结构，不是 8 行 shim）
