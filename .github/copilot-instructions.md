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
- ISA 目标: 默认历史主线是 RISC-V 32 位 (RV32)；`npc/rv64` 是 RV64 Linux/Ubuntu 22.04 bring-up 主线，必须单独按 RV64/OpenSBI/Linux/Ubuntu gate 判断。

## AI 驱动硬件开发环境
- 工作区 agent 处理复杂任务时，先把任务建模为“图任务”，而不是只列线性 TODO。节点表示子任务，边表示执行依赖或知识依赖。
- 每个图节点至少写清：`node_id`、`owner_agent`、`depends_on`、`inputs`、`outputs`、`success_criteria`、`fallback`。
- 优先复用静态图模板：`rv32-reference-loop`、`rv32-bringup`、`npc-sim-regression`、`soc-difftest-loop`、`am-device-loop`、`ysyx-soc-integration`、`software-dev-loop`、`software-bugfix-loop`、`software-refactor-loop`、`hardware-aware-software-loop`、`rv64-ubuntu-probe-loop`、`rv64-ubuntu-rootfs-loop`、`linux-display-loop`、`rv64gc-userland-loop`、`verilator-tapeout-readiness-loop`、`modular-agent-e2e`（兼容名 `agent-e2e-loop`）、`agent-env-refactor`。只有模板不足时才动态扩图。
- NEMU、Linux tools、guest check、host C++ harness、QMP/GDB 和设备模型属于“软件实现硬件/系统语义”的任务，默认走 `hardware-aware-software-loop`：先由 `software-flow` 收敛软件需求、契约、实现和测试，再叠加 `nemu-ubuntu`、`hardware-flow`、`rv64-linux`、`difftest` 或 target gate。
- 选图顺序遵循“静态图优先，动态图补洞”：只要已有模板能覆盖任务类别、输入输出稳定且成功标准明确，就不要重新发明流程。
- 只有在以下情况才动态扩图：现有模板缺少定位节点、节点连续失败需要插入 `reproduce/collect-log/localize/fix/rerun` 链、出现新的跨模块边界、或当前产物缺少可验证证据。
- 图质量必须满足：没有 `evidence` 的节点不能作为下游硬依赖；没有两份可比较产物时不得创建 `compare/difftest` 节点；未来节点不能反向变成当前主闭环的硬前置。
- 若同类动态图在多轮任务中反复以相同输入输出和成功标准复用，应把它提升为新的静态图模板，而不是长期靠临时扩图维持。
- 对跨模块或多节点图任务，应在 `.github/task-runs/<日期-任务名>/` 下维护 `task-report.md` 与 `dispatch-log.md`；模板入口固定为 `.github/task-runs/templates/task-report.template.md` 与 `.github/task-runs/templates/dispatch-log.template.md`。`agent-e2e.sh` 生成的 task-run Markdown 会在报告层收口时归档/同步进开发记忆数据库，但工作区保留可直接读取的原文件；原始 `.log/.cmd/.tsv/.txt` evidence 保留在文件系统，但会登记到 `evidence_assets` 并生成/归档 `evidence-index.md`；读取报告内容优先用 `load --source auto --path <task-report.md>`，查询原始 evidence 摘要用 `evidence --run-id <run_id>`。
- `.github/memory/` 只沉淀稳定结论、长期经验和设计决策；单次图执行的节点明细、阶段状态、证据链和派发历史优先写入 `.github/task-runs/`，不要把长日志整段塞进记忆文件；长日志只做路径/hash/marker/摘要登记。
- 当任务是“搭建/验证 AI 开发环境 e2e”“降低 AI 不确定性”或检查规则发现漂移时，先读取 `.github/instructions/agent-e2e-workflow.instructions.md` 与 `.github/e2e/README.md`，用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 生成 bounded 上下文包，再用 `scripts/agent-e2e.sh --list-profiles` 和 `--validate-all-profiles` 选择模块 profile；全模块入口用 `--profile contracts`，软件流程入口用 `--profile software-flow`，`.github` 检索索引入口用 `--profile github-index`，最小 smoke 用 `--profile quick`，结果不能越级证明 target、Linux/Ubuntu 或 PPA 正确。
- 当前默认主闭环已经推进为 `am-kernels -> abstract-machine -> npc/sim -> NPC/Verilator(target) + NEMU(reference)`；纯参考调研、AM/NEMU 平台问题或 target 不相关任务仍可截断到 `NEMU(reference)`。
- 大任务允许并发调用多个只读子 agent 做 RECALL、资料审计和日志整理；涉及实现、验证、记录的节点仍按依赖顺序串行推进。派发本地 RV64 RTL 子任务前必须读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 生成并校验路径/权限/结构化 `command/mode/purpose`/最小上下文/产物/成功条件契约；只读任务禁止写型命令、文件写入和外部访问。
- `AI_ENVIRONMENT.md` 是 AI 开发环境的一页导航，工作区级图任务蓝图统一维护在 `.github/agentic-hardware-blueprint.md`；处理 agent 架构、工作流编排或 AI 驱动硬件开发环境任务时依次读取两者。

## Agent 本地学习资料约束
- 若相关模块目录存在已整理的本地学习资料（例如 `design/study/README.md`、规范摘要、实现清单），agent 在 RECALL / PLAN 阶段必须先读取索引文件，再按任务类型补读对应笔记，之后才能开始给方案、改代码或跑验证。
- 资料使用优先级：索引/范围说明 → 正式 Markdown 笔记 → 实现 checklist → `tmp/` 提取文本。`tmp/` 只用于快速定位，不直接作为最终依据。
- 当前已固化的稳定入口是 `npc/single/design/study/README.md` 和 `npc/soc/design/study/README.md`；若 `npc/soc` 笔记缺失或明显滞后，可回退读取 `npc/single` 对应正式笔记并记录原因。
- `npc/rv64` 的 core 稳定入口是 `npc/rv64/README.md` 与 `npc/rv64/design/study/README.md`；Linux/Ubuntu 启动套件稳定入口是 `Linux/README.md`、`Linux/env/README.md`、`Linux/tools/Makefile` 与 `.github/instructions/rv64-linux-bringup.instructions.md`，按需叠加 `virtio-rootfs`、`linux-framebuffer-vga`、`rv64gc-userland`、`verilator-tapeout-realism`。
- 处理 `npc/{single,soc}/` 下的数据通路、译码、ALU、控制、CPU wrapper 或骨架任务时，优先读取对应目录的 `RV32I-ai-notes.md` 与 `RV32I-implementation-checklist.md`。
- 处理 `npc/{single,soc}/` 下的功能仿真、异常、CSR、ECALL/EBREAK、MRET、WFI、PMEM 任务时，优先读取对应目录的 `RISC-V-spec-functional-sim-scope.md` 与 `RISC-V-spec-functional-sim-notes.md`。
- 处理 `npc/{single,soc}/` 下的 machine CSR、trap controller、mtime/mtimecmp、PMA/PMP、pmem/mmio 边界或 SoC 地址图任务时，优先读取对应目录的 `RISC-V-spec-hardware-architecture-scope.md` 与 `RISC-V-spec-hardware-architecture-notes.md`。

## Agent ysyxSoC / Chisel 约束
- 处理 `ysyxSoC/`、CPU 顶层 ABI、AXI4 端口命名、SoC 地址图或 `ysyxSoCFull.v` 生成任务时，优先读取 `.github/agents/ysyx-soc.agent.md`、`.github/memory/modules/ysyx-soc.md` 与 `ysyxSoC/spec/cpu-interface.md`。
- `ysyxSoC/build/ysyxSoCFull.v` 是生成物；除非任务明确要求临时补丁，否则优先修改 `ysyxSoC/src/` 后用 `make -C ysyxSoC verilog` 重新生成。
- 当前 Mill/Chisel 环境依赖用户级 JDK 21 与用户本地 `mill` wrapper；不要用系统 OpenJDK 8 失败来判断源码错误。

## Agent RV64 Linux / Ubuntu 约束
- 处理 `npc/rv64`、OpenSBI、Linux kernel、DTB、initramfs/rootfs、Ubuntu Base、QEMU reference 或 NPC/Verilator Linux 启动任务时，优先读取 `.github/agents/rv64-linux.agent.md` 与 `.github/instructions/rv64-linux-bringup.instructions.md`。
- 结论必须按层级表述：环境构建、QEMU reference、OpenSBI handoff、Linux kernel 推进、`/init` 执行、Ubuntu probe 完整可见、Ubuntu Base shell、Ubuntu rootfs；禁止越级声称“完整 Ubuntu 已启动”。
- 官方 Ubuntu riscv64 用户态是 `rv64gc/lp64d` 路线；rv64imac/lp64 syscall-only probe 只能证明 kernel 到用户态的最小链路，不能替代 `/bin/sh`、动态链接器或 rootfs 证据。
- 近期不把 Vivado/FPGA 作为功能 bring-up 前置；Verilator 是主验证平台，但不能借 Verilator 便利在 core 内引入不可综合后门。

## Agent Linux 设备 / 显示约束
- rootfs 任务必须读取 `.github/agents/linux-device.agent.md` 与 `.github/instructions/virtio-rootfs.instructions.md`；没有 virtio-mmio、vring、host block backend、多源 PLIC 和 Linux probe 日志，就不能声称 `/dev/vda` rootfs 路线已闭合。
- 显示任务必须读取 `.github/agents/display-vga.agent.md` 与 `.github/instructions/linux-framebuffer-vga.instructions.md`；AM legacy VGA、`CONFIG_NPC_HAS_VGA` 或 SoC 预留 VGA window 都不能直接当作 Linux framebuffer/fbcon 已接通。
- Linux 屏幕近期目标是 simple-framebuffer/simpledrm/fbcon + SDL scanout 文本显示，不是完整 Ubuntu 图形桌面。

## Agent 终端约束
- Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，不负责工程命令、路径展开、管道或文件操作；统一使用 `wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'` 把命令交给 Ubuntu。若当前 agent/CLI 已经在 WSL/Linux 原生 shell 内运行，则直接使用原生 `bash`/`make`/`rg`/`git` 等命令，不再套 `wsl.exe`。
- 从 Windows 侧启动 WSL 工程命令默认 single-flight；不要并发打开多个 `wsl.exe` client 做读写、构建或检索。复杂控制流、管道和 Bash 变量应留在 Linux 侧 `bash -lc` 或仓库脚本中，避免被 PowerShell 预先解释。
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

## Agent NPC 性能优化约束
- 处理 NPC CPI、cache、BPU、LSQ、OoO/superscalar、issue/commit、取指/访存等性能优化时，必须叠加读取 `.github/instructions/npc-optimization-workflow.instructions.md`。
- 处理 `npc/rv64` 完整双发射、真 OoO、PPA、综合/STA 或功耗取舍时，还必须读取 `.github/instructions/rv64-ppa-optimization-workflow.instructions.md`；中间切片不得作 PPA 淘汰，完整同源 design-id 先过功能/DI/OOO/timing hard gates，再做 Pareto/promotion。
- 性能优化以 CPU-test 全量正确性为门槛；每次 RTL 性能改动后必须跑全量并收集每个测试的 `cycles/commits/CPI`，不能只用 `add` 作为有效性依据。
- 每轮分析必须从同一次全量结果中同时选取 `highest_cpi`、`lowest_cpi`、`near_average_cpi` 三类代表样本，并报告它们与全量加权 CPI 的变化。
- Verilog/SystemVerilog 源码默认一个 module 一个源文件；新增 module 必须放入同名源文件并更新 `vsrc/filelist.mk`。

## Agent Verilator / 流片约束
- 处理 `npc/rv64` 长跑、性能仿真、设备模型真实性或后续流片水准任务时，读取 `.github/agents/verilator-tapeout.agent.md` 与 `.github/instructions/verilator-tapeout-realism.instructions.md`。
- DPI/host C++/SDL/文件 IO 只能作为仿真平台层；长期 core/SoC RTL 必须保留可综合边界、状态机、不变量和验证证据。
- 性能仿真必须报告 guest cycles、commits、CPI、host time 与关键等待来源；不能只用 `add` 或单个 smoke 作为性能优化依据。

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
- 开发记忆系统实现目录为 `scripts/dev_memory/`，其中 `core.py` 负责 schema/index/chunk 基础能力，`queries.py` 负责 query/summary/load，`api.py` 负责外部 AI JSON/JSONL 只读协议，`maintenance.py` 负责 promote/migrate/backup/restore/audit，`cli.py` 负责命令行装配，`__main__.py` 提供 `PYTHONPATH=scripts python3 -m dev_memory ...` 包入口；`scripts/github_index_db.py` 只是兼容 wrapper。
- 可用 `scripts/github_index_db.py rebuild/stat/ls/tree/query/search/summary/compact/load/show/brief/profiles/resolve-profile/runs/evidence/usage/api/refresh/add/remove/promote/update-stored/backup/migrate/archive-markdown/index-evidence/snapshot-stored/rehydrate/materialize/restore/audit-db-first/audit-markdown-coverage/doctor` 为 `.github/**` 和根目录/多 AI 入口 shim 建本地 SQLite 检索索引和目录式资料库；默认数据库在 `.github/cache/github-index.sqlite`，默认额外索引 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`CONVENTIONS.md`、`.windsurfrules`、`.cursor/rules/agents.mdc`，保存索引、元数据、哈希、状态、查询文本、派生 chunk/summary、CLI/API access_log、raw evidence asset 摘要，以及 retained memory/log stored documents。agent、instruction、e2e profile/module、contract 和说明文档直接保留在原文件，数据库只作为索引读取它们。`brief <terms> --profile <profile>` 会组合核心规则、项目状态、known issues、live/indexed e2e profile/module 和关键词命中 chunk，为外部 agent 生成 bounded startup context；`profiles <terms>` 会从 live/indexed e2e profiles 解析 include、节点数、模块、owner 和运行命令，作为 profile 选择目录；`resolve-profile <profile>` 会按 TSV 行顺序递归展开 `@include`，输出 include 边、profile_order、展开节点、source_profile、模块和 owner，贴近 `agent-e2e.sh` 的真实调度视图；`runs --profile <profile>` 会从 retained task-report 汇总历史 run 状态、时间、final_result，并链接 report/dispatch/context brief/profile resolve/evidence index 及 evidence asset 数量；`index-evidence <task-run>` 只登记原始 evidence 文件的路径、大小、sha256、mtime、行数、marker 和 bounded 摘要，不把完整 log 放进 DB；`evidence --run-id <run_id>` 查询这些摘要；`usage` 会从 `access_log` 汇总最近一次数据库使用时间、CLI/API 来源、op、target 和 result_count；`api` 提供外部 AI 可调用的只读 JSON/JSONL 协议，支持 `stat/search/summary/load/show/brief/profiles/resolve-profile/runs/evidence/usage/schema`。普通文档读取用 `load --source auto` 或直接读文件；修改 memory/log retained documents 用 `update-stored --from-file/--content/--stdin` 写回数据库并同步 live 文件；`archive-markdown` 只用于 memory/log Markdown；`.github/cache` 可被清理，所以重要 DB 更新后用 `snapshot-stored --backup-dir .github/db-backup/stored-snapshot --yes` 生成当前 retained 快照，缓存 DB 丢失时用 `rehydrate --backup-dir .github/db-backup/stored-snapshot --yes` 从 manifest 重建 memory/log stored documents；`materialize --prune-non-retained` 可把 stored 内容写回原文件并移除非 memory/log DB ownership；`audit-db-first` 实时读取 live 文件，严格要求 `memory`/`memory-module` 与 stored 一致，并把历史 task-run/report/evidence stored-only 或 live drift 作为非阻塞归档分类；`audit-markdown-coverage --fail-on-live-evidence` 用来证明 Markdown ownership 边界；删除真实文件必须显式 `remove --delete-file --yes`。
- 非平凡任务开工优先用 `scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 获取 live/indexed context；未确定 e2e profile 时只省略 `--profile`，仍保留 non-history focus，输出会包含 `Profile Suggestions`，根据 live/indexed profile/module 文档给出候选 profile、匹配词和推荐 `scripts/agent-e2e.sh --profile <profile>` 命令。历史 task-run/evidence 回查使用 `runs --profile <profile>` 与 `evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
- `project-status.md` — 项目进度总览
- `decisions.md` — 设计决策记录
- `known-issues.md` — 已知问题与调试历史
- `modules/*.md` — 各模块专属笔记（含 `agent-system.md`）

**所有 agent 在工作前必须读取相关记忆文件，完成后必须更新记忆。** 详见 `.github/instructions/memory-protocol.instructions.md`。

## 调度机制
复杂任务通过 `ysyx-coordinator` 总调度 agent 处理，它先选择静态图或动态图，再执行六步调度循环：
RECALL (加载记忆) → PLAN (分解任务) → DISPATCH (逐步派发) → VERIFY (验证结果) → ADAPT (失败恢复) → RECORD (写入记忆)

## Agent 完成判定钩子
- 在声明“完成”、关闭 goal 或写入“已完成”记录前，必须回看用户原始请求和已读文档的完整 checklist/路线图，逐项核对实际证据。
- 收尾时必须显式执行“实现者人格 / 审查者人格”内部对抗：实现者说明交付证据和边界，审查者优先攻击反例、覆盖洞、假绿、未跑 profile、未读上下文和越级结论；最终答复必须写清冲突后结论，冲突未解决时只能交付子任务状态和剩余风险。
- 在收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`。该 guard 会按本轮工作树触碰路径推导推荐 profile，并检查 `.github/task-runs/` evidence 是否包含对应 completed report、`context-brief.md`、`profile-resolve.md` 与 `evidence-index.md`；若缺证据或 DB 召回产物，先补跑建议 profile，或在回复和 memory/task-run 中写明豁免理由与风险。
- 若只完成路线图中的一个子项，只能表述为“本子项/本切片完成”，并列出未完成项；不得把长期目标、多阶段任务或完整 Ubuntu/完整 VM 路线越级标为整体完成。
- 对 RV64 Linux/Ubuntu、图任务、长链调试和 agent 工作流任务，最终答复必须同时写清已闭合 gate、未闭合 gate 和下一步候选。
