# RV64 历史文档索引

这里保存已被后续实现取代的说明、方案和阶段结果。正文保留当时的源码路径、命令、
验证范围与 PPA 数据；“当前”“默认”“暂停”均指记录时点。
现行主线从 [承岳64 架构入口](../../ARCHITECTURE.md) 和 [项目使用说明](../../README.md) 进入。

| 类别 | 历史入口 | 范围与迁移说明 |
| --- | --- | --- |
| 旧核使用说明 | [README.legacy.md](README.legacy.md) | 旧 Ooo* 核的构建、回归和使用说明；2026-09-18 从项目根目录迁入 |
| 旧核生成快照 | [ARCHITECTURE.legacy.md](ARCHITECTURE.legacy.md) | 旧架构 registry 生成报告及原有 qualification/PPA 缺口；2026-09-18 从项目根目录迁入，未重新生成旧快照 |
| 局部重构方案 | [rv64-refactor.md](rv64-refactor.md) | 2026-09-05 起的局部重构记录，随后由原生重写取代 |
| 原生 RTL 重写 | [rv64-rebuild.md](rv64-rebuild.md) | timing28–33 等冻结版本的 CPU、微架构与 PPA 记录 |
| 重写收尾与暂停 | [rv64-rebuild-pause.md](rv64-rebuild-pause.md) | 该轮已经完成的验证、单点取舍和当时未启动的工作；CPU-only/暂停范围不约束后来的系统替换 |
| 架构过程归档 | [arch/history](../arch/history/README.md) | 旧分支投机、store 解耦、评估报告及 2026-07-03 快照 |
| 模块规范归档 | [specs/history](../specs/history/README.md) | 旧模块规范及已完成的一次性实施方案 |
| 早期学习笔记 | [study/](study/README.md) | 2026-07-03 归档的 RV32I 学习笔记副本；原始学习目录为 [npc/single/design/study](../../../single/design/study/README.md) |

重写记录于 2026-09-18 从 `design/arch/` 迁入；旧路径及项目根目录的 legacy 文件均保留薄入口。
[2026-09-15 系统替换记录](../arch/rv64-replacement.md) 仍在 `arch/`，记录恢复 Linux/NPU 后的
集成范围。旧 ROADMAP、Ooo* 规范和工具策略还保留原路径，适用范围分别见
[arch 索引](../arch/README.md) 与 [specs 索引](../specs/README.md)。

历史报告引用的 `tmp/` 等本地结果可能已不在当前工作区；链接缺失不改变原记录的结果，
也不构成当前验证已经完成的证据。
