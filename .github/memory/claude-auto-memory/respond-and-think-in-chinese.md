---
name: respond-and-think-in-chinese
description: 用户要求 Claude 全程用中文——面向用户的回复 AND 内部思考链(thinking)都用中文
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d01eafd4-d1ad-4fdc-8c37-2ad193d4a19a
---

用户明确要求 Claude 的**所有输出全部使用中文**——不仅是面向用户的回复文本，**内部思考链(thinking blocks)也必须用中文**。

**Why:** 用户是中文母语者，本工程(ysyx-workbench)的代码注释、`.github/memory/*`、CLAUDE.md 规则1 全部用中文；用户希望能读懂 Claude 的完整推理过程，而不只是最终结论。

**How to apply:** 从对话第一轮起，thinking 就用中文书写（不要等到最终回复才切中文）。技术术语(如 UNOPTFLAT、difftest、ROB、pred_npc、CoreMark)可保留英文原词，但叙述与推理用中文。参见 [[rtl-coding-standard]] 同属该用户对本工程的工作方式约定。
