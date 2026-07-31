# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工先按 `.github/instructions/agent-lightweight-workflow.instructions.md` 分类；只读 review/analysis 只读直接相关源码和规范，不强制 DB brief、memory、task-run 或 guard。开发/长跑/环境任务再按作用域读取相关 module/instruction；只有需要历史召回或跨模块上下文时才运行 bounded brief。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. memory 只更新稳定、跨会话复用的结论；task-run 按 `none/compact/durable` 留存确定性结果、修改目录、验证指针、工程决策轨迹和少量日志，不保存默认全量过程。
6. AI 环境任务读取 `AI_ENVIRONMENT.md`、轻量工作流与相关 layer/e2e 文件，用 `scripts/agent-flow.sh` 登记路径和门禁指针；只在一轮目标结束时运行选中门禁，不在每次编辑后生成 profile/task-run。
7. Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，工程命令统一交给 Ubuntu：`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'`；若 agent/CLI 已在 WSL/Linux 原生 shell 内运行，则直接使用原生命令，不再套 `wsl.exe`。Windows/Codex→WSL 工程命令默认 single-flight：主 agent 可以把当前唯一 shell ownership 交给一个契约授权的子 agent，但该节点执行期间其它 agent 不得并发运行工程命令；无 shell 推理或自包含材料复核仍可并行。复杂控制流、管道和 Bash 变量放入仓库脚本，避免被 PowerShell 预先解释。
8. 历史 task-run/evidence 回查使用 `python3 scripts/github_index_db.py runs --profile <profile>` 和 `python3 scripts/github_index_db.py evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
9. 有落盘实现、跨模块结论或高风险交付时先用 `finish --candidate` 形成候选，再执行一次实现者/审查者复核，最后正式 `finish`；纯代码 review 不再追加同构的二次流程审查。
10. 日常收尾运行 `scripts/agent-flow.sh finish --task <task-id>`；流程占用约 40% 只是非阻断复盘目标，靠分类、固定指针和低频触发控制。旧 strict guard 只用于 release/迁移且必须显式提供 paths-file/path，不得扫描整个 Git 工作树。
11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确 RTL/spec/TB/evidence 输入、输出路径、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务只消费合同列出的本地工程材料并使用不落盘命令，其它资料另建研究节点。
12. 本地 RV64 RTL 子 agent 使用 `fork_turns="none"`，初始提示只采用已校验的合同 `render` 输出；所需设计事实写入合同路径或随附材料，不继承父任务完整对话历史。该上下文隔离不降低模型、源码探索、实现、验证或 PPA 能力。
13. 主/子 agent 的任务描述、用户进度和终审摘要使用 `rv64-hardware-professional` 措辞：首句明确本地 RV64 module/signal/transaction、仿真/综合/STA 动作与证据产物；协调状态单独记录，不反复混入 RTL 技术正文。子 agent 最终回复按“RTL 对象或本地证据文件 → 周期或编译配置 → testbench/EDA 观测 → PASS/GAP 范围”组织，并保留反例、未知项、日志 marker 和真实文件名。长期 goal 只引用该措辞剖面，不复制场景清单。该规则不得减少工具、上下文、源码探索、负向 RTL 版本、断言、覆盖或 PPA 能力。
14. 合同 `render` 保持精简，只承载 RV64 RTL/证据对象、周期/配置、TB/EDA 观测、合同绑定和工程动作；派发管线、父任务历史与协调状态留在 JSON/dispatch log。Python/JSON 证据工具复核也以具体 CPU 债务项、RTL 证据路径、字段、定向单测和返回码作主语，不用泛化软件保证叙述替代硬件事实。
15. 长时间仿真、综合或系统回放的 task-run 状态必须 fail-closed：只有证据 marker、哈希复核和清理动作全部完成后才能显式授权 `PASS`；`EXIT` trap 不得仅凭 `$?=0` 写 `PASS`，`HUP/INT/TERM` 必须留下 `FAIL`、stage 与 signal。复用 `scripts/task-run-status.sh` 并运行 `scripts/tests/test-task-run-status.sh`。

请直接打开 [`.github/AGENTS.md`](./.github/AGENTS.md)。
