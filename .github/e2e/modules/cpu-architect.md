# CPU Architect E2E Contract

- **范围**: `.codex/agents/cpu-architect.toml`、canonical agent、语义路由 instruction、机器 policy、
  classifier，以及 CapabilityGraph/ExperienceRecord/KnowledgeGap schema、grounded learning validator 与
  正反例测试；RV64 architecture registry 的 canonical catalog/schema/tool/test 与唯一人类入口。
- **启动门**: 只有 `scripts/cpu_architect_route.py classify` 输出 `ARCHITECT` 才允许启动 custom agent；
  `EXPLORER/WORKER/REVIEWER/CLARIFY/NON_ARCH` 必须 handoff。
- **分类语义**: 依据本地 RV64 domain、开放设计选择、因果根因、跨流水/架构状态深度、correctness+
  可测量 tradeoff、baseline/evidence 和授权；禁止关键词、文件数或“优化”字样触发。
- **验证预算**: 确定性命令默认一次；随机、并发、flaky、variable-PPA 或机器异常才按明确原因重复；
  high-risk/release 可以要求独立审查，但不自动重复确定性命令。
- **自我改进边界**: 允许基于外部仿真/RTL/EDA/cycle/silicon 证据更新能力、错误和策略记录；禁止自主
  权重更新，禁止把生成提案、human review 或 LLM opinion 当作训练真值。训练候选只允许隔离导出。
- **全核入口**: Architect 只在路由为 `ARCHITECT` 后消费 `npc/rv64/ARCHITECTURE.md` 或 registry 的
  capability/path query；registry 维护是 WORKER/NON_ARCH，且单一 catalog 派生树、图、网和五层可见性。
- **L0 gate**: `e2e_cpu_architect_contract` 校验 custom agent schema anchors、六路 taxonomy、policy self-test
  和 routing/learning/registry Python 正反例。
- **证据**: policy/schema/self-test PASS、自然语义正例/反例/对抗例、CLI JSON 输出。
- **边界**: 路由 PASS 只证明任务归类可执行，不证明任何 RTL 候选功能或 PPA 合格。
