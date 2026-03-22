# YSYX 工作区 — 全局指导规范

## 项目概览
本工作区是 **"一生一芯" (YSYX)** 项目，目标是设计和验证一颗完整的 RV32 CPU。
工作区包含多个协同模块：RTL 设计 (npc)、软件仿真器 (nemu)、硬件抽象层 (abstract-machine)、测试程序 (am-kernels)、综合分析 (yosys-sta)、虚拟开发板 (nvboard)、数字逻辑实验 (digital_logic_experiment)、NES 模拟器 (fceux-am) 等。

## 语言与工具
- **RTL 设计**: Verilog / SystemVerilog, 使用 Verilator 仿真
- **软件仿真**: C 语言, 使用 GCC/Clang 编译
- **综合**: Yosys (开源综合器) + iEDA (STA/功耗分析)
- **虚拟开发板**: NVBoard (SDL + Verilator)
- **构建系统**: GNU Make, Kconfig

## 代码风格
- Verilog: 模块名大写开头 (如 `RegisterFile`), 信号名小写下划线 (如 `pc_out`)
- C 代码: 遵循项目已有风格，函数名小写下划线分隔
- 所有注释和文档使用中文

## 构建命令速查
| 模块 | 构建命令 |
|------|---------|
| NEMU | `cd nemu && make menuconfig && make` |
| NPC (仿真) | `cd npc/single && make` (Verilator) |
| AM 程序 | `cd am-kernels/tests/cpu-tests && make ARCH=riscv32-nemu run` |
| 综合 | `cd yosys-sta && make syn` |
| STA | `cd yosys-sta && make sta` |
| NVBoard | 在对应实验目录下 `make run` |

## 模块间关系
```
npc (RTL CPU 设计)
 ├── abstract-machine (提供 AM 硬件抽象层)
 │    └── am-kernels (测试程序/基准测试)
 ├── yosys-sta (综合 + 时序分析)
 └── nvboard (虚拟开发板仿真)

nemu (指令集模拟器, 用于对比验证)
 ├── abstract-machine (复用 AM 层)
 │    └── am-kernels (同一套测试)
 └── difftest (差分测试, npc vs nemu)

digital_logic_experiment (数字逻辑实验, 使用 nvboard)
fceux-am (NES 模拟器, 运行在 AM 上)
```

## 关键约定
- 差分测试 (DiffTest): NPC 和 NEMU 逐指令对比，确保 RTL 实现正确
- AM 程序可以同时运行在 NEMU 和 NPC 上，通过 ARCH 环境变量切换目标
- ISA 目标: RISC-V 32 位 (RV32)
