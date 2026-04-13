# Task Runs 目录说明

本目录用于保存**单次图任务**的结构化执行产物，与 `.github/memory/` 的长期记忆分层管理。

## 职责分工

- `.github/memory/`：记录稳定结论、长期经验、设计决策、项目阶段状态
- `.github/task-runs/`：记录某一次图任务的执行摘要、节点状态、证据链、派发历史、阶段性阻塞

## 推荐目录结构

```text
.github/task-runs/
├── README.md
├── templates/
│   ├── task-report.template.md
│   └── dispatch-log.template.md
└── YYYY-MM-DD-<task-slug>/
    ├── task-report.md
    └── dispatch-log.md
```

## 使用规则

- 对跨模块、多节点、需要证据链的图任务，优先创建独立目录保存本轮产物
- `task-report.md` 用于汇总任务目标、所用图模板、节点状态、关键产物、阻塞点、下一步和模板升级候选
- `dispatch-log.md` 用于追加记录节点派发、状态变化、证据、handoff 和失败恢复动作
- 任务完成后，把稳定结论再压缩写回 `.github/memory/`，不要反过来把整份日志塞进记忆文件

## 命名建议

- 目录名使用 `YYYY-MM-DD-<task-slug>`
- `<task-slug>` 采用小写短横线，例如 `rv32-reference-add-test`、`gpu-ioe-debug`

## 模板入口

- `.github/task-runs/templates/task-report.template.md`
- `.github/task-runs/templates/dispatch-log.template.md`

## 维护原则

- `task-report.md` 可以原地更新
- `dispatch-log.md` 采用追加写入，尽量保留时间顺序
- 保持中文、简洁、可复核，不写空泛总结
