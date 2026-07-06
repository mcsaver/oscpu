---
name: doc-dependency-direction-law
description: "文档依赖方向铁律:常驻层(instructions/宪法/index/memory)禁止依赖任务层(spec/plan/task-run),后者会归档→前者悬空;常驻层必须自包含"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b32703f1-8f29-4fd8-b3c4-6fea520cb3a3
---

写**常驻层**文档(instructions / normative 宪法 / index 索引 / memory)时, **绝不引用会归档的任务层文档**(spec `design/specs/*`、plan、task-run)的具体章节/证据(如"详见 spec §5 / 对应 §4.1 / 见 task-run 推导")。

**Why**: 文档分两层生命周期——常驻层伴随工作区**一直进化**; 任务层(spec/plan/task-run)任务完成后**释放归档进 history**。依赖方向只能「任务层 → 常驻层」; 反向 = 长命依赖短命, 被依赖件一归档、常驻层就留**悬空引用**(自相矛盾: 一边固化规则一边从源头制造悬空)。用户 2026-07-06 当场指正:"spec 里的东西是有生命周期的、完成后归 history, 而 interface-contract 这类 instructions 要一直伴随工作区进化"。

**How to apply**:
- 常驻层文档**自包含**: 把 spec 里值得长期保留的知识**提炼内联**进 instructions/memory, 而非挂"详见 spec"指针——这本就是任务收尾时"知识从任务层沉淀到常驻层"的应有动作(而非只在 spec 里留着等归档)。
- 区分**依赖 vs 动作指令**: 常驻规则里写"回写 `design/specs/<模块>.md` / 记录到 `task-runs/<pattern>`"是指向**目录约定的动作指令**(要你去维护它们), 合法; 依赖某份归档件的**内容**才违规。
- **反例连教训一并自包含**: 反面教材别点会归档的文件名, 只描述反模式本身(点常驻层文件名 OK)。
- 已固化进 `doc-lifecycle.instructions.md` §1.5(铁律)+ §4(完成判定钩子)。**给常驻层文档加内容后必核对此项**。

关联 [[doc-lifecycle-protocol]] · [[encoding-zero-area-debug-two-tier]] · [[workspace-artifacts-not-tool-dir]]。
