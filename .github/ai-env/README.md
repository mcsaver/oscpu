# AI Environment Layout

仓库级导航从 AI_ENVIRONMENT.md 进入。本目录只保存特定 AI 环境机器合同；旧
.github/agent-env-*.json 是兼容入口。

## Layout

- contracts/：release、security、schema、runner、delivery 等专项机器接口。
- ../skills/：live、短小的定向处理方法。
- ../agents/：专家角色与入口。
- ../e2e/：显式专项 profile 和模块说明。
- ../memory/：稳定跨会话事实。
- ../task-runs/：仅在明确留存、长跑或发布场景使用的运行记录。

这些路径用于定位所有权，不自动派生 gate。普通任务直接遵循 .github/AGENTS.md 的
inspect → act → targeted validation → report；不要求运行 profile、DB audit、agent-maintain 或 strict
guard。

## Specialized use

- 修改某个 contract 或 verifier 时，运行与其 acceptance criteria 直接相关的定向检查。
- profile/e2e 本身开发、release、migration、security、forensic、publication 或用户明确要求时，才使用
  agent-maintain、agent-e2e、manifest/hash 和完整 task-run。
- 已版本化 verifier 在未修改且没有真实异常时视为可信，不在每次环境编辑后重验。

生成包写入 dist；cache、runtime artifact、重型 evidence 和一次性审计展开目录不作为 active source。
不要为防止流程膨胀再创建新 framework、manifest 或 meta-test。
