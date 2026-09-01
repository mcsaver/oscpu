# CPU Architect E2E Contract

- **范围**: 这是显式维护 CPU Architect 路由、可选 formal-research learning 工具和 architecture registry 时
  使用的环境 E2E；普通架构任务不运行本 profile，也不先自测 classifier/learning validator。
- **角色选择**: 由任务语义与父任务 ownership 选择 custom agent。`scripts/cpu_architect_route.py classify`
  只是歧义任务或路由回归的 advisory 工具，其输出不授权、阻止或撤销安全本地工作。
- **分类语义**: 依据本地 RV64 domain、开放设计选择、因果根因、跨流水/架构状态深度、correctness+
  可测量 tradeoff、baseline/evidence 和授权；禁止关键词、文件数或“优化”字样触发。
- **验证预算**: 确定性命令默认一次；随机、并发、flaky、variable-PPA 或机器异常才按明确原因重复；
  high-risk/release 可以要求独立审查，但不自动重复确定性命令。
- **formal-research 边界**: 只有用户或 acceptance criteria 显式 opt-in 时，才使用 CapabilityGraph、
  ExperienceRecord、KnowledgeGap、grounded learning validator 或训练候选；禁止自主权重更新，禁止把生成
  提案、human review 或 LLM opinion 当作训练真值。
- **全核入口**: 真正的全局架构任务按需消费 `npc/rv64/ARCHITECTURE.md` 或 registry 有界 query；registry
  维护本身是 WORKER/NON_ARCH。局部 RTL/bug 不因目录或关键词被迫加载全核 catalog。
- **显式维护检查**: `e2e_cpu_architect_contract` 仅在本 profile 被选择时校验 custom agent、六路 taxonomy
  及 routing/learning/registry 的版本化正反例；该检查不是 Architect 启动或普通实验的许可门。
- **证据**: policy/schema/self-test PASS、自然语义正例/反例/对抗例、CLI JSON 输出。
- **边界**: 工具自测 PASS 只证明路由/可选研究基础设施自洽，不证明任何 RTL 候选功能或 PPA 合格。
