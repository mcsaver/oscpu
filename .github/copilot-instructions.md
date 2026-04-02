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

## Agent NEMU 调试约束
- 处理 NEMU、SDB、AM on NEMU 调试任务时，agent 在“等价可完成”的前提下优先使用可脚本化或批处理路径，例如 `--batch`、日志文件、trace、watchpoint、表达式求值、配置开关、专用测试程序或临时代码插桩；但不要为了回避交互而机械地改写每一个测试流程。
- 若测试本身就需要 shell 或 monitor 交互，而且当前工具能在启动或会话边界上完成这些输入，agent 应自己完成交互并继续根据终端输出推进，不要把本可代劳的键入动作转交给用户。
- 当前工具不能可靠地向已经启动的前台 NEMU readline monitor 持续注入标准输入；因此若需要 monitor 交互，agent 应优先使用启动时预置 stdin、`-b`、make 的 `c` 目标或其它一次性命令序列。只有在确认不存在可行交互入口时，才向用户说明限制和剩余的最小人工步骤。
- 对 SDL 键盘、窗口或设备输入测试，agent 应先判断宿主是否具备可脚本化桌面输入工具；若具备，应自行完成必要的宿主按键注入；若不具备，再优先采用 NEMU/AM 侧可回退的合成输入、专用测试程序、日志或临时插桩完成验证，而不是默认要求用户在宿主机上现场按键配合。
- 若任务只是在 monitor 中执行 `c`、`q`、`si` 或其它少量启动命令，agent 应优先在启动 NEMU 时通过 stdin 预置命令或直接使用等价的批处理目标自行完成，并读取终端输出确认效果。

## Agent 代码建议约束
- 默认不要直接修改用户工作区文件。用户询问“如何实现”“给出代码”“帮我分析/建议”这类请求时，优先在对话框中给出可审阅的代码片段、补丁建议或实现思路。
- 只有当用户明确要求“直接修改”“帮我改文件”“落盘实现”“应用补丁”或等价意图时，agent 才可以对工作区文件执行编辑。
- 若此前已自动修改过文件，而用户随后声明希望只接收对话框中的代码建议，则从该声明起按新约束执行。
- 当用户要求 agent 直接修改代码时，agent 应在修改点附近补充简短中文注释，明确说明“为什么这么改”和“改完能带来什么效果”；若是一组连续改动，可在代码块前用 1 到 2 条注释统一说明目的与收益，避免只留下机械实现而没有设计意图。
- 当用户要求“直接给代码”“这种小提示直接显示代码”“给出几行补全”“告诉我怎么写”或等价意图时，agent 必须直接展示完整、可复制的最小代码片段；不要只给口头描述，也不要用空白、占位、隐藏、折叠或省略替代代码正文。
- 对未落盘的代码建议，默认使用标准 Markdown 代码块展示，并尽量同时说明插入位置或替换位置；展示代码片段本身不算“直接修改文件”。
- 对整文件级的大段源码修改，可以优先给关键片段、补丁思路和修改位置；若变更规模仍适合阅读，仍应优先展示关键代码，而不是只给抽象描述。
- 只有当用户明确要求其它展示形式，或实际确认聊天界面对代码块显示异常时，才退回普通正文逐行展示代码；若发生这种异常，下一条应直接重发完整代码并说明插入位置。

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
