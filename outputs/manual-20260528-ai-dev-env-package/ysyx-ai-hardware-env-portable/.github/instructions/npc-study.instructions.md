---
description: "NPC 开发的本地学习资料流程。处理 npc/single 或 npc/soc 下的 RTL、仿真、设计或 bring-up 任务时，先读取对应 study 索引和专题笔记，再开始规划、实现和验证。"
applyTo: "npc/{single,soc}/**"
---

# NPC 本地学习资料流程

处理 `npc/single/` 或 `npc/soc/` 下的任务时，先把本地学习资料当作正式输入，而不是只在卡住时回头翻。`npc/soc` 是从 SoC 接入版拆出的目录，若对应 study 文件与 `npc/single` 同步存在，应按当前后端目录读取；若缺失，再回退读取 `npc/single/design/study/` 的正式笔记并在记录里说明。

## 固定入口

- **必须** 先读取当前后端目录下的 `design/study/README.md`，例如 `npc/single/design/study/README.md` 或 `npc/soc/design/study/README.md`
- 只有在索引无法覆盖问题时，才继续进入同一目录下的 `design/study${TMPDIR}/README.md` 和 `design/study${TMPDIR}/*.txt` 查找原始摘录

## 按任务选读

- 做数据通路、译码、ALU、控制器、单周期骨架或模块边界梳理时，优先读取 `npc/single/design/study/RV32I-ai-notes.md` 与 `npc/single/design/study/RV32I-implementation-checklist.md`
- 做功能仿真、异常、trap、CSR、ECALL/EBREAK、MRET、WFI、PMEM 行为时，优先读取 `npc/single/design/study/RISC-V-spec-functional-sim-scope.md` 与 `npc/single/design/study/RISC-V-spec-functional-sim-notes.md`
- 做 machine CSR、trap controller、mtime/mtimecmp、PMA/PMP、hart/platform、pmem/mmio 边界时，优先读取 `npc/single/design/study/RISC-V-spec-hardware-architecture-scope.md` 与 `npc/single/design/study/RISC-V-spec-hardware-architecture-notes.md`

## 使用要求

- 在开始实现前，先把要采用的关键约束从学习资料里提炼成 2 到 4 条明确结论，再据此规划或编码
- `tmp/` 下的临时提取文本只用于快速定位原始上下文，不直接替代正式笔记结论
- 若任务与现有笔记冲突，优先回到源码、规范或正式笔记核对，再决定是否更新 study 文档
