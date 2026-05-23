# YSYX 工作区 — 全局指导规范

## 项目概览
本工作区是 **"一生一芯" (YSYX)** 项目，目标是设计和验证一颗完整的 RV32 CPU。
工作区包含多个协同模块：RTL 设计与仿真入口 (`npc/sim`、`npc/single`、`npc/soc`)、SoC/Chisel 集成 (`ysyxSoC`)、软件仿真器 (`nemu`)、硬件抽象层 (`abstract-machine`)、测试程序 (`am-kernels`)、综合分析 (`yosys-sta`)、虚拟开发板 (`nvboard`)、数字逻辑实验 (`digital_logic_experiment`)、NES 模拟器 (`fceux-am`) 等。

## 语言与工具
- **RTL 设计**: Verilog / SystemVerilog, 使用 Verilator 仿真
- **SoC 生成**: Scala / Chisel / Mill / Firtool，生成 `ysyxSoC/build/ysyxSoCFull.v`
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
| NPC 统一仿真入口 | `cd npc/sim && make status && make run IMG=/path/to/image.bin` |
| NPC single 后端 | `cd npc/single && make lint && make` |
| NPC SoC 后端 | `cd npc/soc && make lint && make soc-lint && make soc` |
| ysyxSoC Verilog | `cd ysyxSoC && make verilog` |
| AM 程序 | `cd am-kernels/tests/cpu-tests && make ARCH=riscv32-nemu run` |
| AM on NPC | `cd am-kernels/tests/cpu-tests && make ARCH=riscv32-npc run NPC_RUN_ARGS="--diff=default --no-progress -m 0"` |
| 综合 | `cd yosys-sta && make syn` |
| STA | `cd yosys-sta && make sta` |
| NVBoard | 在对应实验目录下 `make run` |

## 模块间关系
```
npc/sim (NPC 平台无关仿真入口)
 ├── npc/single (普通 NPC 自仿真后端)
 └── npc/soc (ysyxSoC 接入后端)
      └── ysyxSoC (Chisel SoC + ysyxSoCFull.v + CPU ABI)

abstract-machine
 └── am-kernels (测试程序/基准测试)
      ├── riscv32-nemu -> NEMU reference
      └── riscv32-npc  -> npc/sim -> single/soc 后端

nemu (指令集模拟器, 用于对比验证)
 ├── abstract-machine (复用 AM 层)
 │    └── am-kernels (同一套测试)
 └── difftest (NPC single/soc vs NEMU reference)

digital_logic_experiment (数字逻辑实验, 使用 nvboard)
fceux-am (NES 模拟器, 运行在 AM 上)
```

## 关键约定
- 差分测试 (DiffTest): NPC 和 NEMU 逐指令对比，确保 RTL 实现正确
- AM 程序当前支持 `riscv32-nemu` 参考路径和 `riscv32-npc` 目标路径；`riscv32-npc` 默认通过 `npc/sim` 进入当前配置后端，可用 `NPC_SIM_BACKEND=soc` 临时切到 `npc/soc`
- NEMU `CONFIG_SOC_SIM` 是 NPC SoC/ysyxSoC 地址图的 reference 模式，构建 SoC difftest reference 时使用 `make -C npc/sim BACKEND=soc difftest-ref`
- ISA 目标: RISC-V 32 位 (RV32)

## AI 驱动硬件开发环境
- 工作区 agent 处理复杂任务时，先把任务建模为“图任务”，而不是只列线性 TODO。节点表示子任务，边表示执行依赖或知识依赖。
- 每个图节点至少写清：`node_id`、`owner_agent`、`depends_on`、`inputs`、`outputs`、`success_criteria`、`fallback`。
- 优先复用静态图模板：`rv32-reference-loop`、`rv32-bringup`、`npc-sim-regression`、`soc-difftest-loop`、`am-device-loop`、`ysyx-soc-integration`、`agent-env-refactor`。只有模板不足时才动态扩图。
- 选图顺序遵循“静态图优先，动态图补洞”：只要已有模板能覆盖任务类别、输入输出稳定且成功标准明确，就不要重新发明流程。
- 只有在以下情况才动态扩图：现有模板缺少定位节点、节点连续失败需要插入 `reproduce/collect-log/localize/fix/rerun` 链、出现新的跨模块边界、或当前产物缺少可验证证据。
- 图质量必须满足：没有 `evidence` 的节点不能作为下游硬依赖；没有两份可比较产物时不得创建 `compare/difftest` 节点；未来节点不能反向变成当前主闭环的硬前置。
- 若同类动态图在多轮任务中反复以相同输入输出和成功标准复用，应把它提升为新的静态图模板，而不是长期靠临时扩图维持。
- 对跨模块或多节点图任务，应在 `.github/task-runs/<日期-任务名>/` 下维护 `task-report.md` 与 `dispatch-log.md`；模板入口固定为 `.github/task-runs/templates/task-report.template.md` 与 `.github/task-runs/templates/dispatch-log.template.md`。
- `.github/memory/` 只沉淀稳定结论、长期经验和设计决策；单次图执行的节点明细、阶段状态、证据链和派发历史优先写入 `.github/task-runs/`，不要把长日志整段塞进记忆文件。
- 当前默认主闭环已经推进为 `am-kernels -> abstract-machine -> npc/sim -> NPC/Verilator(target) + NEMU(reference)`；纯参考调研、AM/NEMU 平台问题或 target 不相关任务仍可截断到 `NEMU(reference)`。
- 大任务允许并发调用多个只读子 agent 做 RECALL、资料审计和日志整理；涉及实现、验证、记录的节点仍按依赖顺序串行推进。
- 工作区级蓝图统一维护在 `.github/agentic-hardware-blueprint.md`；处理 agent 架构、工作流编排或 AI 驱动硬件开发环境任务时优先读取。

## Agent 本地学习资料约束
- 若相关模块目录存在已整理的本地学习资料（例如 `design/study/README.md`、规范摘要、实现清单），agent 在 RECALL / PLAN 阶段必须先读取索引文件，再按任务类型补读对应笔记，之后才能开始给方案、改代码或跑验证。
- 资料使用优先级：索引/范围说明 → 正式 Markdown 笔记 → 实现 checklist → `tmp/` 提取文本。`tmp/` 只用于快速定位，不直接作为最终依据。
- 当前已固化的稳定入口是 `npc/single/design/study/README.md` 和 `npc/soc/design/study/README.md`；若 `npc/soc` 笔记缺失或明显滞后，可回退读取 `npc/single` 对应正式笔记并记录原因。
- 处理 `npc/{single,soc}/` 下的数据通路、译码、ALU、控制、CPU wrapper 或骨架任务时，优先读取对应目录的 `RV32I-ai-notes.md` 与 `RV32I-implementation-checklist.md`。
- 处理 `npc/{single,soc}/` 下的功能仿真、异常、CSR、ECALL/EBREAK、MRET、WFI、PMEM 任务时，优先读取对应目录的 `RISC-V-spec-functional-sim-scope.md` 与 `RISC-V-spec-functional-sim-notes.md`。
- 处理 `npc/{single,soc}/` 下的 machine CSR、trap controller、mtime/mtimecmp、PMA/PMP、pmem/mmio 边界或 SoC 地址图任务时，优先读取对应目录的 `RISC-V-spec-hardware-architecture-scope.md` 与 `RISC-V-spec-hardware-architecture-notes.md`。

## Agent ysyxSoC / Chisel 约束
- 处理 `ysyxSoC/`、CPU 顶层 ABI、AXI4 端口命名、SoC 地址图或 `ysyxSoCFull.v` 生成任务时，优先读取 `.github/agents/ysyx-soc.agent.md`、`.github/memory/modules/ysyx-soc.md` 与 `ysyxSoC/spec/cpu-interface.md`。
- `ysyxSoC/build/ysyxSoCFull.v` 是生成物；除非任务明确要求临时补丁，否则优先修改 `ysyxSoC/src/` 后用 `make -C ysyxSoC verilog` 重新生成。
- 当前 Mill/Chisel 环境依赖用户级 JDK 21 与 `/home/lyg/.local/bin/mill` wrapper；不要用系统 OpenJDK 8 失败来判断源码错误。

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

## Agent RTL 生成约束
- 生成或修改任何 Verilog/SystemVerilog RTL（新模块、改接口、改时序、改状态机、改控制信号、改数据通路）前，**必须** 按 `需求 → 协议规则 + 状态机 + 不变量 + 数据通路约束 → RTL` 的四段式顺序推导，且每段都要在回复或落盘记录中显式给出，禁止跳过任何一段直接写代码。
- 详细执行规范见 `.github/instructions/rtl-generation-workflow.instructions.md`；该规则对所有 `*.v / *.sv / *.vh / *.svh` 自动生效，与 `.github/instructions/npc-study.instructions.md` 串联使用：先按 study 流程读资料，再按 RTL 工作流推导，最后才落 RTL。
- 落盘 RTL 改动需在 `.github/task-runs/<日期-任务名>/task-report.md` 追加“RTL 推导摘要”一节（需求要点、协议、状态机、不变量、数据通路骨架）；模块级稳定结论回写到 `.github/memory/modules/npc.md` 或对应模块笔记。
- 只读类问题（仅解释代码、做 RECALL）不强制走完整四段；但若结论会被用于后续 RTL 改动，那一步必须补齐。

## Agent 代码建议约束
- 默认不要直接修改用户工作区文件。用户询问“如何实现”“给出代码”“帮我分析/建议”这类请求时，优先在对话框中给出可审阅的代码片段、补丁建议或实现思路。
- 只有当用户明确要求“直接修改”“帮我改文件”“落盘实现”“应用补丁”或等价意图时，agent 才可以对工作区文件执行编辑。
- 若此前已自动修改过文件，而用户随后声明希望只接收对话框中的代码建议，则从该声明起按新约束执行。
- 处理 bug 修复时，禁止停留在“哪里坏了就在哪里继续缝一块补丁”的局部修补；agent 必须先从架构职责、模块边界以及控制流/数据流出发定位根因，再在正确抽象层落修复。只有在明确属于一次性兼容层或过渡方案时，才允许保留局部补丁，并且必须同时写清边界、退出条件和为什么不会继续累积技术债。
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
- `modules/*.md` — 各模块专属笔记（含 `agent-system.md`）

**所有 agent 在工作前必须读取相关记忆文件，完成后必须更新记忆。** 详见 `.github/instructions/memory-protocol.instructions.md`。

## 调度机制
复杂任务通过 `ysyx-coordinator` 总调度 agent 处理，它先选择静态图或动态图，再执行六步调度循环：
RECALL (加载记忆) → PLAN (分解任务) → DISPATCH (逐步派发) → VERIFY (验证结果) → ADAPT (失败恢复) → RECORD (写入记忆)
