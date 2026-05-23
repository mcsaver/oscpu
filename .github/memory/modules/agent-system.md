# Agent System 模块笔记

## 当前状态

- 2026-05-23：工作区 agent 配置已按当前 NPC/SoC 真实形态刷新。全局 `.github/AGENTS.md`、`.github/copilot-instructions.md` 与 `.github/agentic-hardware-blueprint.md` 已把默认闭环从纯 `NEMU reference` 更新为 `am-kernels -> abstract-machine -> npc/sim -> NPC/Verilator + NEMU reference`；新增静态图 `npc-sim-regression`、`soc-difftest-loop`、`ysyx-soc-integration`。`ysyx-coordinator`、`hardware-flow`、`npc`、`nemu`、`abstract-machine`、`am-kernels`、`difftest`、`yosys-sta` 等 agent 已识别 `npc/sim` 统一入口、`npc/single` 普通后端、`npc/soc` SoC 后端、NEMU `CONFIG_SOC_SIM` reference 和 ysyxSoC CPU ABI。
- 2026-05-23：新增 `.github/agents/ysyx-soc.agent.md` 与 `.github/memory/modules/ysyx-soc.md`。后续涉及 `ysyxSoC/`、`ysyxSoCFull.v`、CPU AXI4 顶层规范、Chisel/Mill/Firtool 生成链路或 SoC 地址图的任务，应优先交给 `ysyx-soc`，并与 `npc`、`nemu`、`difftest` agent 协同。
- 2026-05-23：用户级 Java 默认版本已切到 Zulu JDK 21.0.10。`/home/lyg/.local/bin/{java,javac,jar,jshell}` 指向该 JDK，且 `/home/lyg/.bashrc` 末尾设置了 `JAVA_HOME` 与 `PATH`，新终端默认使用 JDK 21；系统 alternatives 未改，OpenJDK 8 仍保留在 `/usr/bin/java`。已验证 `java -version`、`javac -version` 和 `cd ysyxSoC && mill -i --version`。
- 2026-05-23：`mill` 命令已安装到 `/home/lyg/.local/bin/mill` 并进入 PATH。该文件是 wrapper，只对 Mill 进程临时设置自动缓存的 Zulu JDK 21，再执行仓库根 `mill` bootstrap；系统默认 `java` 仍是 OpenJDK 8。根目录脚本默认 Mill 1.1.6，可用 `mill --no-daemon --version` 验证；`ysyxSoC/.mill-version` 指定 Mill 0.12.4，已下载到本机缓存。OpenJDK 8 会触发 `java.io.InputStream.readAllBytes()` 缺失，当前 wrapper 下 `cd ysyxSoC && mill -i --version` 已验证通过。后续 ysyxSoC/Chisel 任务应使用 `mill -i` 或 `--no-daemon` 避免 daemon 干扰。
- 2026-04-21：继续按“先补 shim、后做真实消费端验证”的路线推进，已为 `CLAUDE.md`、`GEMINI.md`、`CONVENTIONS.md`、`.windsurfrules`、`.cursor/rules/agents.mdc` 补齐最小兼容入口，并在 `.github/AGENTS.md` 中显式写清“工程规则走 AGENTS / instructions / memory，Codex 通用能力走 skills，plugin 只在 UI / MCP / marketplace 场景下引入”的分层边界。
- 2026-04-21：根据一次人工验收意见，继续收紧 agent 环境文档：修正 `.github/agents/npc.agent.md` 中已经漂移的 NPC 入口与命令示例，把根目录 `AGENTS.md` 的最小契约补强到不弱于 `memory-protocol.instructions.md`，并把 task-run 结论从“多 agent 兼容已完成”收敛为“AGENTS 基线已补齐、仍待非 Copilot smoke 验证”。
- 2026-04-21：补齐跨 agent 发现入口，新增仓库根 `AGENTS.md` 兼容 shim 与 `.github/AGENTS.md` 通用基线。前者为只读取根入口的 agent 提供最小契约，后者把当前工作区的 `.github/copilot-instructions.md`、`memory/`、`task-runs/`、蓝图和 study 入口统一成跨工具可复用的工作流规范，避免规则只对 Copilot 可见。
- 2026-04-14：工作区级 agent 规则已新增一条 bug 修复方法论约束：默认禁止“补丁上再套补丁”的症状式修法，必须先从架构职责、模块边界和控制流/数据流定位根因，再在正确抽象层落修复；若不得不保留兼容性补丁，必须显式写清边界与退出条件。
- 2026-04-13：根据用户确认，当前默认主闭环收敛为 `am-kernels -> abstract-machine -> NEMU(reference)`；`NPC/Verilator` 改为未来接入节点，不再作为当前调度前置。
- 2026-04-13：继续吸收 NVIDIA Marco 的图任务思想后，工作区新增“静态图优先、动态图补洞、稳定后模板化”的规则，并补上 `regression-debug-loop`、动态图扩图规则和图质量门槛。
- 2026-04-13：新增 `.github/task-runs/` 作为任务级结构化产物目录，把单次图任务的 `task-report` 和 `dispatch-log` 与长期记忆分层保存。
- 2026-04-13：工作区 agent 体系已从“模块专家集合”推进到“图任务调度 + 工作流 agent + 模块专家执行”的第一阶段骨架；新增 `agent-system` 与 `hardware-flow` 两个工作流层 agent，并新增 `.github/agentic-hardware-blueprint.md` 作为稳定入口。
- 当前默认主闭环已推进为 `am-kernels -> abstract-machine -> npc/sim -> NPC/Verilator(target) + NEMU(reference)`；纯参考、快速定位或 AM/NEMU 平台问题仍可截断为 `am-kernels -> abstract-machine -> NEMU(reference)`，真实 EDA 工具仍作为后续下游节点接入。
- `ysyx-coordinator` 现在应优先选择静态图 `rv32-reference-loop`、`rv32-bringup`、`npc-sim-regression`、`soc-difftest-loop`、`am-device-loop`、`ysyx-soc-integration`、`agent-env-refactor`、`regression-debug-loop`，只有模板不足时才动态扩图；涉及 target 行为时不要继续只走 `rv32-reference-loop`，除非任务明确是纯参考或 AM/NEMU 平台问题。

## 设计笔记

- 修改 bug 时，优先问“当前症状是哪个职责层的数据流/控制流断掉了”，再决定在哪一层修；不要直接围着报错点缝局部特判，否则很容易把暂时能跑的补丁累积成后续无法收敛的技术债。
- 图任务节点至少写清 `node_id`、`owner_agent`、`depends_on`、`inputs`、`outputs`、`success_criteria`、`fallback`。
- `hardware-flow` 负责跨 `am-kernels + abstract-machine + nemu + npc` 的闭环，模块专家继续负责本模块内部实现与调试。
- `ysyx-soc` 负责 `ysyxSoC/`、CPU ABI、Chisel 生成链路和 SoC 地址图；`npc` 负责 `npc/soc` 里的 CPU wrapper/bridge；`nemu` 负责 `CONFIG_SOC_SIM` reference；`difftest` 负责把三者放到可比较的提交级证据链里。
- `.github/agentic-hardware-blueprint.md` 是当前 agent 环境的稳定入口；处理 `.github/agents/`、`.github/instructions/`、`.github/copilot-instructions.md` 相关任务时先读它。
- 当前工程里真正可执行的 target 入口是 `npc/sim`；遇到外部脚本直接硬编码 `npc/single`、绕过 `npc/sim` 或忽略 `NPC_SIM_BACKEND` 时，应识别为入口漂移或基础设施问题。
- 当前默认调度应按任务性质选择：纯参考用 `rv32-reference-loop`，普通 target 用 `rv32-bringup` 或 `npc-sim-regression`，SoC/difftest 用 `soc-difftest-loop`，ysyxSoC 生成/ABI 用 `ysyx-soc-integration`。
- 动态图的职责是给失败节点补证据、补定位、补边界澄清；如果同类动态子图频繁复现，就应把它沉淀成新的静态图模板。
- `memory/` 与 `task-runs/` 已分层：前者沉淀长期知识，后者保存单次图执行过程，避免记忆文件被日志污染。

## 踩坑记录

- 只堆模块专家不等于可编排环境；如果没有静态图模板和节点交付契约，多 agent 很容易退化成散乱的多轮问答。
- `applyTo: "**"` 会持续吞上下文，除非确实是全局规则，否则优先放到 coordinator、专用 agent 或蓝图文档中。
