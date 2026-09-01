---
name: agent-env-maintenance
description: 定向维护 YSYX 工作区的 AI 规则、Skill、Agent、memory、contract、profile 或执行器；根据明确 acceptance criteria 修改唯一真源并做最小充分验证。
---

# Agent Environment Maintenance

使用本 skill 时，先读取 AI_ENVIRONMENT.md、agent-env-layer-contract.instructions.md 和被修改对象的直接
引用。此 skill 负责定向维护，不启动默认全环境认证。

## Ownership

- Database/memory：稳定跨会话事实和显式留存结果。
- Skill/instruction：短小、可复用的处理方法。
- Agent/script/profile：自动执行、专家角色和显式专项编排。
- Contract：release/security/schema/runner 等机器可判定的特定接口。

下游层不能扩大用户授权；路径和层级只能帮助定位真源，不能自动创造 gate。

## Procedure

1. 写清本次 primary objective、可观察 acceptance criteria 和不在范围内的对象。
2. 搜索直接引用与消费者，确认语义属于哪一层；只在真实接口变化时同步必要消费者。
3. 修改最少的一组现有文件，不新增 policy framework、hash manifest、审批层或 meta-test。
4. 对每项候选验证回答：
   - 它对应哪个 acceptance criterion？
   - 它能发现现有检查遗漏的哪种实际 false PASS？
   - 不运行是否真会导致错误结论？
5. 执行最小定向检查并报告累计行为变化、验证结果和剩余 machine-enforced 冲突。

版本控制内已有自身测试的 verifier、runner、classifier、parser 和 harness 默认可信。只有本次修改了它，
或运行中出现异常接受/拒绝、矛盾、缺失或 fallback 可疑时，才运行其自测或 audit。

## Optional specialized modes

- 历史召回或跨会话事实：bounded brief / memory。
- 显式可恢复交接：agent-flow / compact task-run。
- persistent/published 长跑：durable task-run + task-run-status；中断或 cleanup 未完成不是 PASS。
- profile 开发、release、migration、security、forensic、commercial delivery 或 publication：
  选择直接相关的 agent-maintain/e2e/strict guard、manifest/hash 和 reviewer。

普通文档、规则和入口修改不默认生成 task-run，不运行 final/release/full，不更新 rebuild matrix、
review routing、branch dashboard 或所有 contracts。只有本轮 acceptance criteria 直接覆盖这些对象时才
进入相应模式。

## Boundaries

- 不把 DB snapshot 当作 active rule，不把完整 raw log 写进 memory。
- 不把 Skill 写成全局百科；领域正确性留在 domain spec/test/EDA contract。
- 不用 SHA/hash 作为普通 task identity 或主要汇报内容。
- 不继承 compaction 前 agent 自创的临时 gate、sequencing、marker 或禁止事项。
- 不以环境自检替代 RTL correctness、DiffTest、综合、STA、PPA、release 或 security 验证。
