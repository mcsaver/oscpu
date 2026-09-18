# NPC SoC

## 这是什么

`npc/soc` 是从 `npc/single` 复制出来的 ysyxSoC 接入版本，用来和老的 single 自仿真版本分开维护。它按以下职责组织：

- 一版 RV32 五级流水核心 RTL，位于 `vsrc/`
- 一套参考 NEMU 分层方式组织的 Verilator + DPI 宿主仿真环境，位于 `sim/`
- 一套 ysyxSoC 接入包装：`ysyx_26010035` 顶层、`NpcSoCAxiBridge` AXI4 bridge、`make soc` / `make soc-lint` 构建入口

普通 `make` 使用 `NpcSimTop` 自仿真入口，当前复位地址已经按 SoC 调整：

1. 用 `abstract-machine` 和 `am-kernels` 生成 `riscv32-ysyxsoc` 裸机镜像
2. 把匹配复位地址的 `.bin` 镜像装进 `mrom@0x20000000`（4 KiB）
3. 通过 DPI 模拟最小 MMIO 设备并运行程序
4. 用 `ebreak + a0` 退出程序，或输出 trap/timeout 信息

严格 ysyxSoCFull 接入验证使用：

- `make -C npc/soc soc-lint`
- `make -C npc/soc soc`
- `make -C npc/soc soc-run IMG=/path/to/image.bin RUN_ARGS='--max-cycles 10000000'`

`IMG` 为空时，`soc-run` 会在 MROM 中放入内建 smoke 程序；传入 `riscv32-ysyxsoc` 的 AM `.bin` 后，ysyxSoCFull 会从 `0x20000000` 取指并通过 DPI 报告 GOOD/BAD TRAP。


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

`make -C npc/soc`、`lint`、`run`、`syn` 和 `sta` 入口保持不变。
生产 RTL 和仿真清单分别维护在 `vsrc/filelist.mk` 与 `sim/filelist.mk`，
DiffTest 通过 `difftest/filelist.mk` 独立接入。`build/` 保存可再生构建产物。
