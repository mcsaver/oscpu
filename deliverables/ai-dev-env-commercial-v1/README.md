# YSYX AI Dev Environment Commercial v1

这是当前工作区 AI 开发环境的新版可交付面。它把开发环境固定成三层：

- Database：长期记忆、DB-backed stored documents、task-run/evidence 索引、runtime artifact 指针。
- Skill：可直接读取的标准化处理规则，入口是 `.github/skills/agent-env-maintenance/SKILL.md`。
- Agent：自动维护流程、profile 调度、review routing、branch health、state traceback 和 e2e 证据链。

## 交付定位

本包面向“把工程 AI 开发环境作为商业项目交付”的场景，交付的不是一次性聊天记录，而是一套可审计、可复刻、可运维的工程系统。

核心卖点：

- 用 DB-first memory 保存长期事实，避免上下文漂移。
- 用 Skill 固化可复用处理规则，避免规则散落在对话里。
- 用 Agent/e2e profile 把自动维护、验证、回归和证据包串成闭环。
- 用 C 调度器完成任务分类、显式路径日志、约 40% 非阻断占用观测和 compact/durable 结果归档。
- 用 runtime artifact boundary 把源码、证据索引和重型运行态 payload 分开。

## 快速验证

```bash
scripts/agent-maintain.sh --mode release
scripts/agent-e2e.sh --profile agent-system --task-slug commercial-delivery-smoke
```

## 打包

```bash
scripts/package-ai-dev-env.sh
```

生成目录：

```text
dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/
```

旧手工产物已经归档到 `.github/archive/legacy-ai-dev-env-2026-06-13/`，不再作为 active delivery surface。
