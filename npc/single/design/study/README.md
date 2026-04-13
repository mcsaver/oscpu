# NPC 设计学习笔记索引

本目录保存对 design 目录资料的阶段性学习结果，目标不是复写原文，而是把后续实现 NPC 单周期 CPU 与功能仿真环境时最需要复用的知识压缩成结构化 Markdown。

## 文件说明

- RV32I-ai-notes.md：面向后续 agent 和实现者的结构化知识库，重点整理模块职责、控制信号和边界条件。
- RV32I-implementation-checklist.md：按实现顺序整理的落地清单，适合边写边对照。
- RISC-V-spec-functional-sim-scope.md：两本 RISC-V 大规范的选择性阅读范围，说明当前为什么只学这些章节。
- RISC-V-spec-functional-sim-notes.md：基于两本规范提炼出的“NPC 最小功能仿真必须理解的语义”。
- RISC-V-spec-hardware-architecture-scope.md：两本 RISC-V 大规范中与硬件平台、hart、机器级架构最相关的选读范围。
- RISC-V-spec-hardware-architecture-notes.md：基于两本规范提炼出的“NPC 最小硬件架构骨架必须理解的约束”。
- tmp/：临时提取文本与学习中间产物，供后续 agent 快速复用，不作为最终结论文件。

## 本轮学习结论

- 这份资料的核心不是完整 ISA 手册，而是单周期 RV32I CPU 的模块分层草图。
- 重点在 IFU、IDU、EXU、LSU、WBU 的职责边界，而不是流水线优化。
- 译码应尽量收敛为统一控制包，写回应集中在 WBU，避免执行和提交逻辑混杂。
- 新增两本 RISC-V 大规范后，本目录改为同时保留“实现结构笔记”和“规范选择性学习笔记”两条线。
- 对当前 NPC，规范学习重点不是 supervisor、虚拟内存和 hypervisor，而是 EEI、内存访问、异常陷阱、M 模式 CSR 与 trap return 语义。
- 在“功能仿真语义”之外，还需要单独掌握“硬件平台/机器态骨架”这条学习线；它更关注 hart、特权级、machine CSR、计时器、PMA/PMP 对 RTL 的约束。

## 使用建议

- 先读 RV32I-ai-notes.md 建立整体模型。
- 开始实现某个模块前，对照 RV32I-implementation-checklist.md 逐项勾选。
- 开始补功能仿真环境前，先读 RISC-V-spec-functional-sim-scope.md 和 RISC-V-spec-functional-sim-notes.md。
- 开始补 machine CSR、trap controller、mtime/mtimecmp 或 pmem/mmio 边界前，先读 RISC-V-spec-hardware-architecture-scope.md 和 RISC-V-spec-hardware-architecture-notes.md。
- 后续若继续阅读新资料，优先按“结论、原因、影响、待验证项”的格式追加。
