# NPC Single

## 这是什么

`npc/single` 按以下职责组织：

- 一版 RV32 五级流水核心 RTL，位于 `vsrc/`
- 一套参考 NEMU 分层方式组织的 Verilator + DPI 宿主仿真环境，位于 `sim/`

当前目标不是完整 SoC，而是先提供一条稳定的 bring-up 闭环：

1. 用 `abstract-machine` 和 `am-kernels` 生成 `riscv32-npc` 裸机镜像
2. 把 `.bin` 镜像装进 `pmem@0x80000000`
3. 通过 DPI 模拟最小 MMIO 设备并运行程序
4. 用 `ebreak + a0` 退出程序，或输出 trap/timeout 信息


## 按职责阅读

| 目录 | 内容 |
| --- | --- |
| [`vsrc/`](vsrc/filelist.mk) | 可综合 CPU、总线与存储 RTL |
| [`sim/`](sim/README.md) | 程序仿真宿主、设备、monitor、DPI 与仿真顶层；构建和运行说明 |
| [`difftest/`](difftest/README.md) | NEMU 参考模型适配、状态同步和比较 |
| [`testbench/`](testbench/README.md) | 具体模块与流水线自检用例、公共激励和断言辅助 |
| [`syn/`](syn/README.md) | 综合与 STA 使用说明 |
| [`perf/`](perf/README.md) | 性能分析脚本、配置与历史结果 |
| [`design/`](design/README.md) | 设计学习资料与历史记录 |
| `configs/`、`Kconfig`、`scripts/config.mk` | 构建配置与配置生成；`include/` 保存生成配置 |

`make -C npc/single`、`lint`、`run`、`syn` 和 `sta` 入口保持不变。
生产 RTL 和仿真清单分别维护在 `vsrc/filelist.mk` 与 `sim/filelist.mk`，
DiffTest 通过 `difftest/filelist.mk` 独立接入。`build/` 保存可再生构建产物。
