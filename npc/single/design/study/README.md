# RV32I 学习笔记索引

本目录保存对上层资料 RV32I.pdf 的阶段性学习结果，目标不是复写原文，而是把后续实现 NPC 单周期 RV32I CPU 时最需要复用的知识压缩成结构化 Markdown。

## 文件说明

- RV32I-ai-notes.md：面向后续 agent 和实现者的结构化知识库，重点整理模块职责、控制信号和边界条件。
- RV32I-implementation-checklist.md：按实现顺序整理的落地清单，适合边写边对照。

## 本轮学习结论

- 这份资料的核心不是完整 ISA 手册，而是单周期 RV32I CPU 的模块分层草图。
- 重点在 IFU、IDU、EXU、LSU、WBU 的职责边界，而不是流水线优化。
- 译码应尽量收敛为统一控制包，写回应集中在 WBU，避免执行和提交逻辑混杂。

## 使用建议

- 先读 RV32I-ai-notes.md 建立整体模型。
- 开始实现某个模块前，对照 RV32I-implementation-checklist.md 逐项勾选。
- 后续若继续阅读新资料，优先按“结论、原因、影响、待验证项”的格式追加。
