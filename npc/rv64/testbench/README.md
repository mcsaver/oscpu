# RV64 验证入口

当前默认验证目录是 [chengyue64/](chengyue64/README.md)，对应承岳64 的模块、整核、系统和
Tensor 验证。根 [Makefile](../Makefile) 的 `TEST_DIR` 指向该目录；本目录的
[Makefile](Makefile) 也只负责转发。

`testbench` 保存具体测试：输入激励、断言、oracle、测试程序和回归脚本。
通用的时钟驱动、镜像加载和设备模拟归 [sim/](../sim/README.md)，
参考模型适配和架构状态比较归 [difftest/](../difftest/README.md)。
可综合设计归 [vsrc/](../vsrc/)，NEMU 的参考接口实现归工作区 [nemu/](../../../nemu/)。

| 内容 | 入口 |
| --- | --- |
| 当前验证命令与文件职责 | [chengyue64/README.md](chengyue64/README.md) |
| NPC/NEMU DiffTest 调用链、CSR 字段与比较时机 | [difftest/README.md](../difftest/README.md) |
| L2/L3、Linux、UART、block 与 NPU 系统运行 | [sim/README.md](../sim/README.md) |
| 工程与架构总入口 | [RV64 README](../README.md)、[ARCHITECTURE.md](../ARCHITECTURE.md) |

从工作区根运行：

```sh
make -C npc/rv64 test
make -C npc/rv64 core-test
make -C npc/rv64 software-test
```

`rebuild/` 是 `chengyue64/` 的兼容链接。`tests/`、`cpp/`、`common/`、`scripts/` 与
[Makefile.legacy](Makefile.legacy) 保留旧验证资产，供历史入口及当前个别 oracle 复用；
它们不代表默认主线。旧核说明见 [README.legacy.md](../README.legacy.md)。

本文件此前误用了 `npc/single` 的模块测试说明；`npc/single` 的入口应查阅其
[testbench README](../../single/testbench/README.md)。
