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

## Agent 终端约束
- 对 NEMU、NVBoard、menuconfig、SDL 窗口等交互式程序，禁止使用 `tail`、`head`、`sed -n`、管道截断或其他会消费/劫持标准输入输出的包装方式运行；这会破坏界面显示或导致交互异常。
- 需要查看结果时，应直接在终端原样运行程序，再由 agent 在回复中总结关键输出；不要为了缩短输出而改写命令的数据流。
- 若必须减少日志量，优先调整程序自身日志开关或构建参数，不要在命令外层追加会截断交互输出的管道。

## Agent 代码建议约束
- 默认不要直接修改用户工作区文件。用户询问“如何实现”“给出代码”“帮我分析/建议”这类请求时，优先在对话框中给出可审阅的代码片段、补丁建议或实现思路。
- 只有当用户明确要求“直接修改”“帮我改文件”“落盘实现”“应用补丁”或等价意图时，agent 才可以对工作区文件执行编辑。
- 若此前已自动修改过文件，而用户随后声明希望只接收对话框中的代码建议，则从该声明起按新约束执行。

## 持久化记忆系统
本项目使用 `.github/memory/` 目录存储跨会话的项目状态和知识：
- `project-status.md` — 项目进度总览
- `decisions.md` — 设计决策记录
- `known-issues.md` — 已知问题与调试历史
- `modules/*.md` — 各模块专属笔记

**所有 agent 在工作前必须读取相关记忆文件，完成后必须更新记忆。** 详见 `.github/instructions/memory-protocol.instructions.md`。

## 调度机制
复杂任务通过 `ysyx-coordinator` 总调度 agent 处理，它使用六步调度循环：
RECALL (加载记忆) → PLAN (分解任务) → DISPATCH (逐步派发) → VERIFY (验证结果) → ADAPT (失败恢复) → RECORD (写入记忆)
