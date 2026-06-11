# 完成判定钩子固化

## 背景

用户指出：上一轮 NEMU Ubuntu 路线图任务中，agent 把“完成 `virtio-rng/hwrng` 子项”误标为“整个目标完成”。这说明现有 RECORD 流程缺少收口前的语义核对钩子，容易把可验证增量误报为长期目标完成。

## 改动

- `.github/AGENTS.md`：新增“完成判定钩子”，要求声明完成、关闭 goal 或写入已完成记录前，重新展开用户原始请求和已读文档中的 checklist/路线图。
- `.github/instructions/memory-protocol.instructions.md`：在“完成任务后更新记忆”前新增“完成判定前语义核对钩子”，把整体目标、阶段目标和子任务区分作为 RECORD 前置条件。
- `.github/copilot-instructions.md`：补充同义的 Copilot 专属提醒，避免不同入口规则漂移。
- `.github/memory/modules/agent-system.md`：沉淀这次误判的长期经验。
- `.github/memory/known-issues.md`：把该问题归档为已解决问题 [50]。
- `.github/memory/project-status.md`：记录本轮工作流规则更新。

## 新完成标准

后续 agent 在收口前必须回答以下问题：

1. 用户原始目标是单点任务、阶段任务，还是路线图/长期目标？
2. 已读文档里有哪些 checklist、阶段或硬性要求？
3. 本轮证据覆盖了哪些条目？
4. 哪些条目仍未覆盖？
5. 当前是否只能声明“子任务/本切片完成”？
6. 是否真的满足关闭 goal 或写“整体完成”的条件？

只有全部硬性条目都有客观证据，且不存在未处理的用户明确要求时，才能使用“整体完成”或关闭 goal。

## 验证

- 相关 Markdown `git diff --check` PASS。

## 边界

该钩子能约束 agent 的完成判定和交付表述，但不能替代具体工程任务自己的构建、测试、仿真或日志证据。
