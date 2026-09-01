---
description: "NPC 本地学习资料的按需入口。任务依赖既有设计分析、规范摘录或历史约束时读取相关 study；不把固定开工阅读或摘要当作普通任务门禁。"
applyTo: "npc/{single,soc}/**"
---

# NPC 本地学习资料流程

`design/study/` 是已有设计分析和规范摘录的检索入口，不是每个 `npc/single/` 或 `npc/soc/` 任务的固定
开工阶段。当前源码、接口 spec 与直接相关 README 已足以回答问题时，无需额外读取或复述 study；当任务
依赖既有设计取舍、规范边界或历史分析时，再按问题有界读取。`npc/soc` 的对应资料缺失时，可回退到
`npc/single/design/study/` 中仍适用的正式笔记，并核对与当前后端是否一致。

## 按需入口

- 不清楚已有资料覆盖范围时，先查当前后端的 `design/study/README.md`，例如
  `npc/single/design/study/README.md` 或 `npc/soc/design/study/README.md`。
- 已知具体专题时可直接读取对应正式笔记；只有正式笔记不足以核对原始上下文时，才进入
  `design/study/tmp/README.md` 或 `design/study/tmp/*.txt`。

## 按任务选读

- 做数据通路、译码、ALU、控制器、单周期骨架或模块边界梳理时，优先读取 `npc/single/design/study/RV32I-ai-notes.md` 与 `npc/single/design/study/RV32I-implementation-checklist.md`
- 做功能仿真、异常、trap、CSR、ECALL/EBREAK、MRET、WFI、PMEM 行为时，优先读取 `npc/single/design/study/RISC-V-spec-functional-sim-scope.md` 与 `npc/single/design/study/RISC-V-spec-functional-sim-notes.md`
- 做 machine CSR、trap controller、mtime/mtimecmp、PMA/PMP、hart/platform、pmem/mmio 边界时，优先读取 `npc/single/design/study/RISC-V-spec-hardware-architecture-scope.md` 与 `npc/single/design/study/RISC-V-spec-hardware-architecture-notes.md`

## 使用边界

- 只提炼会改变本轮 acceptance、接口或实现选择的约束；不要求固定的开工摘要、阅读清单或条目数量。
- `tmp/` 下的临时提取文本只用于快速定位原始上下文，不直接替代正式笔记结论
- 若当前源码、权威规范与旧笔记冲突，以核实后的当前工程事实为准；只有笔记本身仍属于任务范围时才
  同步更新，不把一次普通实现自动扩大成全量文档维护。
