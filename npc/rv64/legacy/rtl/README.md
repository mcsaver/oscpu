# 旧 NpcTop / Ooo* RTL 入口

[`filelist.mk`](filelist.mk) 是旧核心的兼容构建清单；[`vsrc/`](vsrc/) 显式链接到
[`2026-09-16 封存 RTL`](../../../pack/rv64core-legacy-20260916/rv64/vsrc/)，不保存另一份逻辑副本。
当前主线生产 RTL 只位于 [`../../vsrc/`](../../vsrc/README.md)，旧工具不得从那里读取 `NpcCoreTop` 或 `Ooo*` 模块。

旧宿主由 [`../sim/`](../sim/) 提供，仿真包装源仍在 `../../sim/vsrc/`。
可从工作区根目录调用：

```sh
make -C npc/rv64 -f Makefile.legacy lint
make -C npc/rv64 -f Makefile.legacy
make -C npc/rv64/testbench -f Makefile.legacy run
```

封存源码是历史真源；mutation 测试应先复制到独立输出目录，禁止原地修改链接指向的文件。
旧评估和测试工具读取这里的归档路径，输出只说明旧核心；历史结果、source hash 与资格记录
保留原始身份，不会因路径整理自动成为当前主线证据。

仅归档 source catalog 与显式 `Makefile.legacy` 入口属于这里的路径兼容保证。
旧的完整架构/PPA/系统资格工作流还依赖当时的 JSON、配置、工具、AM 路由与 task-run 文件；
需要复现整套历史流程时使用封存包自身的工作区布局。通用系统采集器仍保留当前主线默认入口，
不能把它们的新输出与旧核资格记录混合。目录迁移不重新签发任何历史 qualification。
