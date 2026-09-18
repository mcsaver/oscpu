# RV64 设计文档导航

当前主线为承岳64（ChengYue64）。从 [架构入口](../ARCHITECTURE.md) 了解系统组成与
当前源码，从 [模块拓扑](../vsrc/TOPOLOGY.md) 和
[模块说明](../vsrc/MODULES.md) 了解核内职责。

本目录按设计说明、模块规范、参考资料和历史记录分类。测试操作见
[testbench](../testbench/README.md)，仿真平台见 [sim](../sim/README.md)，差分接口与比较策略见
[difftest](../difftest/README.md)，综合与 STA 见 [syn](../syn/README.md)。

| 目录 | 内容与适用范围 |
| --- | --- |
| [arch/](arch/README.md) | 架构与系统替换记录、历史 OoO 架构材料，以及既有工具消费的策略和 registry 文件；各自适用版本见目录说明 |
| [specs/](specs/README.md) | 按模块划分的接口/行为规范；须区分旧 Ooo* 核规范与仍复用的总线、外设合同 |
| [literature/](literature/README.md) | 文献笔记；`design/` 根目录另保留 RISC-V 手册 PDF 作为 ISA 参考资料 |
| [history/](history/README.md) | 旧使用说明、旧 registry 快照、原生重写/暂停记录与早期学习笔记；同时索引 arch/history 和 specs/history |

设计行为以实际 RTL、filelist 和可执行测试为准。历史文档中的“当前”、测试计数、PPA 结果和
待办仅适用于其采样版本，不能直接作为承岳64 的验收结果。
