# 承岳64 验证平台

本目录维护当前承岳64 的具体测试用例与回归脚本。
命令由 RV64 根 [Makefile](../../Makefile) 转发到本目录的 [Makefile](Makefile)。

## 文件职责

| 目录 | 内容 |
| --- | --- |
| [modules/](modules/) | `tb_*.sv`：模块/组合子系统激励、协议断言和定向测试 |
| [oracles/](oracles/) | 独立的预期行为与对照实现 |
| [programs/](programs/) | `r64_core_*.S`：整核、特权、设备、吞吐与 Tensor 测试程序 |
| [scripts/](scripts/) | AM、官方 ISA、ACT4、系统回归的构建、运行及结果检查 |
| [generators/](generators/) | SoftFloat 浮点测试向量生成器 |
| [host/](host/) | 宿主镜像加载器的 C++ 单元测试 |

通用仿真运行设施见 [sim/](../../sim/README.md)，独立的参考模型及 CSR 比较实现见
[difftest/](../../difftest/README.md)。测试 Makefile 引用 [sim/build.mk](../../sim/build.mk)
构建 core/system/tensor 仿真器；NEMU 参考配置和构建脚本由 `difftest/` 管理。

## 常用命令

以下命令均从工作区根运行：

```sh
make -C npc/rv64 all difftest-ref
make -C npc/rv64 lint
make -C npc/rv64 test
make -C npc/rv64 core-test
make -C npc/rv64 device-test
make -C npc/rv64 tensor-test
make -C npc/rv64 software-test
make -C npc/rv64 regression
```

| 目标 | 实际范围 |
| --- | --- |
| `all` / `difftest-ref` | 构建系统仿真可执行文件 / NEMU 参考共享库 |
| `lint` | 整核与系统 lint |
| `test` | 当前模块测试、负向断言与选定配置矩阵，准确集合以根 Makefile 为准 |
| `core-test` | 整核、系统定向、系统 I/O 与理想吞吐测试 |
| `device-test` | block 设备读写、错误和 IRQ 定向测试 |
| `tensor-test` | Tensor 单元和原生 Tensor 系统定向对拍 |
| `software-test` | AM、官方 ISA、ACT4 非 OS 软件回归 |
| `regression` | `lint + test + core-test + software-test + device-test` |

`regression` 不包含 `tensor-test`、L2/L3 或完整 NPU 主工作流；这些入口分别见
[系统运行](../../sim/README.md)。模块测试结果不能替代整核或系统结论。
`core-test` 的理想吞吐检查在 I-cache 自然预热后，要求 7 个稳态窗口各退休 768 条 / 384 拍，
同时保留 NEMU 检查。该特定窗口的 CPI=0.5 不表示所有负载均达到此吞吐。

默认构建输出位于 `npc/rv64/build/chengyue64/`：模块回归用 `regress/`，
整核、系统、Tensor 系统分别用 `core/`、`system/`、`tensor-system/`。
参考库默认位于 `nemu/build/rv64-rebuild-reference/`，通过 `CORE_REF` 选择。
`CORE_JOBS` 控制编译并行度，`CORE_THREADS` 控制 Verilator 宿主线程数；
后者不改变 RTL 时钟和流水拍数。

## 运行单个程序

```sh
make -C npc/rv64 run IMG=/absolute/guest.bin \
  RUN_ARGS="--maxcycles=20000000 --progress"
```

`run` 默认使用系统仿真封装。普通测试通过 `EBREAK` 且 `a0=0`，或 ELF 提供的 `tohost=1`
结束；也可用 `--tohost=0x...` 指定地址。系统模式使用真实 syscon 关机，参数及终态要求见
[sim/README.md](../../sim/README.md)。`--stalls` 可加入总线停顿，`--verbose` 打印提交与 trap 事件。
