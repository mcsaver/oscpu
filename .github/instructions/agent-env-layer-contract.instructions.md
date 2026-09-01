# Agent Environment Layer Contract

本文件只定义 Database、Skill 和 Agent 工具的职责边界。它不规定普通任务的实现顺序，也不授予下游
文件新增 permission gate 的权力。

## Layer ownership

### Database / memory

- 保存稳定、跨会话复用的 project/module memory，以及显式选择留存的 task-run 报告与 evidence 索引。
- live agent、instruction、skill、profile、contract 和说明文档仍以工作区原文件为真源。
- scripts/dev_memory 与 scripts/github_index_db.py 提供检索、同步和专项审计；普通任务不要求先运行
  brief、rebuild、refresh、snapshot、rehydrate 或 DB audit。
- raw log、波形、镜像和可再生成 payload 放在 runtime/cache/object store；只有在明确持久化边界中
  记录必要指针或 identity。

### Skill

- .github/skills/*/SKILL.md 保存短小、可复用、面向具体任务的方法。
- Skill 可建议读取哪些输入和运行哪些定向验证，但不能扩大用户授权、把建议变成全局 gate，或要求
  普通业务任务重验版本化 verifier。
- 长期事实写 memory，复杂执行逻辑写 script，机器可判定专项接口写对应 contract；不要全部复制进 Skill。

### Agent / execution

- .github/agents、.github/e2e 和 scripts/agent-* 提供专家角色、可选编排、维护、长跑和发布执行器。
- Agent 根据 objective 和 acceptance criteria 选择最小充分动作；路径、文件数和任务时长只能提示风险，
  不能自动创建 authorization phase。
- e2e/profile/task-run/candidate/strict guard 默认 opt-in，只服务于显式跨会话交接、persistent/published
  长跑、profile 开发、release、migration、security、forensic、publication 或用户明确要求。
- 显式 persistent/published runner 继续 fail closed：工作负载、必要证据和 cleanup 未全部完成，或发生
  HUP/INT/TERM，均不能记录 PASS。

## Cross-layer rules

1. 先根据语义选择唯一真源：稳定事实进 Database/memory；可复用方法进 Skill/instruction；自动执行进
   Agent/script/profile；专项机器接口进已有 contract。
2. 修改一个层不自动要求同步所有其它层。只有实际接口或被引用语义变化时才更新直接消费者。
3. 不为普通改动自动更新 rebuild matrix、review routing、branch dashboard、trace manifest、publication
   或商业交付包；这些对象仅在本次 acceptance criteria 直接涉及它们时维护。
4. 已进入版本控制并有自身测试的 DB/verifier/runner 默认可信。只有出现 schema mismatch、异常接受/
   拒绝、矛盾输出、缺失结果或真实故障时才运行相应 audit 或自测。
5. gate registry、path mapping 和 profile 可以推荐定向检查，但下游不得把推荐升级为新的权限要求。
6. hash/SHA 仅用于 release/security/persistence/cache/reproducibility/forensic 等 identity 本身承重的
   边界，不作为普通任务身份或人工汇报主线。

## Targeted maintenance

AI 环境修改遵循 inspect → edit → targeted validation → report：

- 先读 AI_ENVIRONMENT.md、本文件和被修改对象的直接引用；
- 只修改拥有该语义的真源及必要消费者；
- 用最小检查确认链接、格式、解析或行为符合本轮 acceptance criteria；
- verifier 自身未改且未出现异常时，不重跑其完整自测；
- 报告累计行为变化、验证结果和仍存在的 machine-enforced 冲突。

scripts/agent-maintain.sh、agent-flow、agent-e2e 和 github_index_db.py 的 audit 子命令仍可用于明确专项，
但普通环境文档编辑不因路径自动运行 quick/final/release/full 或完整 agent-system profile。

## Compatibility

现有 schema、observability、runtime-artifact、delivery、state-traceability、review-routing 和
branch-health contract 可以继续服务旧发布物或显式专项。它们不构成工作区日常 operating contract；
若旧脚本仍强制七状态、全矩阵、publication/hash 或 reviewer/inspector，视为机器实现层兼容债务，在
对应脚本被授权修改时再定向收敛，不把该限制扩写回文档。
