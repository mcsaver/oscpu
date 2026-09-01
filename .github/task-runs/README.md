# Task Runs

本目录只用于需要跨会话恢复或正式留存的单次运行记录。它不是普通开发任务的前置条件、完成许可或
工程正确性来源。

## 何时使用

适合创建 task-run 的场景：

- 显式 persistent/published 的长时间仿真、综合、STA 或系统回放；
- release、migration、security、forensic 或对外 publication；
- 多个会话/协作者确实需要一个稳定的 handoff 记录；
- 用户明确要求保留结构化运行记录。

普通 inspect、实现、修 bug、构建、定向测试和一次性分析不需要创建本目录中的新记录。跨模块、文件多、
使用子 agent 或任务耗时较长本身都不是触发条件。

## 最小内容

需要留存时，优先只保存：

- 人类可读的 objective 与 acceptance criteria；
- 实际修改范围和重要行为变化；
- 直接相关的命令、配置、结果与必要 artifact 指针；
- 会影响后续判断的工程决策、blocker 和剩余风险。

不要默认保存完整对话、每一步内部状态、逐节点 marker、Git/SHA genealogy 或 verifier 的重复自证。只有
byte identity、release provenance、security、cache integrity 或明确 reproducibility criterion 才记录 hash。

## 建议结构

```text
.github/task-runs/
├── README.md
├── templates/
│   ├── task-report.template.md
│   └── dispatch-log.template.md
└── YYYY-MM-DD-<semantic-task-name>/
    ├── task-report.md
    └── dispatch-log.md        # 仅在真实 handoff/长跑恢复需要时
```

`task-report.md` 汇总目标、变更、验证和风险。`dispatch-log.md` 只记录会影响恢复或 ownership 的重要事件，
不要求每次 inspect、命令或状态变化都追加条目。

历史 task-run 是当时运行的 evidence，不自动成为当前任务的 gate。上下文恢复时仍以当前 objective、用户
acceptance criteria、实际 worktree、hard constraints 和最新 build/test 结果为准。

## 命名与维护

- 目录名使用简短、语义化的任务名，例如 `2026-08-23-agent-contract-refactor`；不要用 commit SHA、内容
  hash 或临时 artifact ID 作为人类任务身份。
- 报告可以就地更新；需要顺序恢复时，dispatch log 采用追加写入。
- 稳定、跨会话可复用的事实才进一步压缩到 `.github/memory/`，不要把整份运行日志复制进 memory。
- 生成物、波形和大日志放在既定 runtime/cache 位置，只在报告中保留必要指针。
