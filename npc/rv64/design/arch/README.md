# 架构文档与实施记录

当前架构从 [承岳64 架构入口](../../ARCHITECTURE.md) 进入；核内结构见
[TOPOLOGY](../../vsrc/TOPOLOGY.md) 和
[MODULES](../../vsrc/MODULES.md)。本目录保留不同阶段的架构材料，
文件位于 `arch/` 并不表示它描述当前主线。

| 类别 | 入口 | 适用范围 |
| --- | --- | --- |
| 系统替换实施记录 | [rv64-replacement.md](rv64-replacement.md) | 2026-09-15 起原生核替换旧核、恢复 Linux/NPU 范围的集成记录；运行结果属于记录中的源码与配置 |
| 早期原生重写与暂停记录 | [历史索引](../history/README.md) | `rv64-rebuild`、`rv64-rebuild-pause`、`rv64-refactor` 正文已归入 history；原路径保留迁移入口 |
| 旧 Ooo* 架构与路线 | [ooo-core-architecture.md](ooo-core-architecture.md)、[ROADMAP.md](ROADMAP.md)、[rtl-ground-truth-2026-07-11.md](rtl-ground-truth-2026-07-11.md) | 旧 OoO 实现的职责、路线和阶段快照；其中的 current、pending 与待办不适用于承岳64 |
| 旧时序与 PPA 记录 | [rv64-200mhz-completion-design.md](rv64-200mhz-completion-design.md)、[timing-dispatch-issue-path.md](timing-dispatch-issue-path.md) | 旧核的 5 ns/200 MHz 等配置与阶段结果，不能代替当前核的 1 ns 测量 |
| 工具策略与 registry | 本目录的 JSON/TSV、[performance-counter-schema.md](performance-counter-schema.md)、[performance-measurement-contract.md](performance-measurement-contract.md) | 由既有评估工具按路径消费；适用产品、版本和配置以各文件及调用工具为准，不因文档整理迁移或重写 |
| 规范模板 | [SPEC-TEMPLATE.md](SPEC-TEMPLATE.md) | 编写模块行为、状态与接口说明时参考 |
| 已归档架构过程 | [history/](history/README.md) | 更早的方案、快照和评估报告 |

未在上表逐项列出的方案也须按其标题、日期和目标模块判断范围。当前运行与验证导航见
[项目使用说明](../../README.md)，不要直接套用历史路线图中的命令或结论。
