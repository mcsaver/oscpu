# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: rv64-linux
- `terms`: rv64 linux contract
- `focus_scope`: non-history
- `token_estimate`: 3908 / 4000

## Profile Suggestions
- `rv64-linux` score=30 matched=contract, linux, requested-profile, rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `linux-device` score=10 matched=contract, linux, rv64 command=`scripts/agent-e2e.sh --profile linux-device`
- `display-vga` score=6 matched=contract, linux, rv64 command=`scripts/agent-e2e.sh --profile display-vga`
- `verilator-tapeout` score=6 matched=contract, linux, rv64 command=`scripts/agent-e2e.sh --profile verilator-tapeout`
- `contracts` score=5 matched=contract, linux, rv64 command=`scripts/agent-e2e.sh --profile contracts`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile rv64-linux`

## Missing Paths
- `.github/memory/modules/rv64-linux.md`

## Chunks

### .github/AGENTS.md#chunk-0001

- `kind`: agent-rule
- `lines`: 1-15
- `tokens`: 328
- `heading`: AGENTS.md — YSYX 工作区 Agent 通用工作流规范
- `summary`: > 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent / > （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等） / > 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。 / > / > 与本文件协作的入口文件分两类： / > 根...

# AGENTS.md — YSYX 工作区 Agent 通用工作流规范

> 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent
> （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等）
> 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。
>
> 与本文件协作的入口文件分两类：
> 根目录 `AGENTS.md` / 其他兼容入口文件是兼容 shim，保留最小可执行契约并回链本文件；
> `.github/copilot-instructions.md` 不是薄指针，而是 GitHub Copilot 专属工程级补充规则。
> 多份文件出现重叠时，以本文件作为跨 agent 通用基线；Copilot 的额外构建、调试与记录细则再叠加读取 `copilot-instructions.md`。
>
> 当前阶段的目标是“工程规则自动发现与会话恢复”，不是“插件式 UI 扩展”。因此本仓库优先补齐兼容 shim，不主动引入 `.codex-plugin/` 或 `.agents/plugins/marketplace.json`。

---

### .github/e2e/profiles/rv64-linux.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-8
- `tokens`: 414
- `heading`: rv64-linux.tsv
- `summary`: @include|discovery|||| / npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|RV64 core/Linux 入口合约存在 / npc-rv64-sv39-sret-u-mode|npc|e2e_npc_rv64_sv39_sret_u_mode|npc|npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB|NPC RV64 SRET 到 U-...

@include|discovery||||
npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|RV64 core/Linux 入口合约存在
npc-rv64-sv39-sret-u-mode|npc|e2e_npc_rv64_sv39_sret_u_mode|npc|npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB|NPC RV64 SRET 到 U-mode、U 页取指、U ecall、U load page fault 回 S 并 sret 回 U 的回归 PASS
npc-rv64-linux-focused-smokes|npc|e2e_npc_rv64_linux_focused_smokes|npc|Linux/tools SRET/Sv39/pagefault/virtio focused smokes on NPC|NPC RV64 Linux focused smokes 覆盖 SRET/Sv39、ret_from_exception、U pagefault 与 virtio-blk
npc-rv64-uart-rx-smoke|npc|e2e_npc_rv64_uart_rx_smoke|npc|NPC 16550 UART RX register + gated DPI injection smoke|NPC RV64 UART RX 支持 RBR/LSR/IIR/IER[0]，并支持 NPC_UART_RX_WAIT 按 guest 输出 marker 释放宿主输入
npc-rv64-linux-rootfs-mount-smoke|npc|e2e_npc_rv64_linux_rootfs_mount_smoke|npc|Ubuntu rootfs mount + systemd banner smoke on NPC|NPC RV64 Ubuntu rootfs 至少完成 ttyS0 console、virtio-blk、EXT4/VFS root mount，并进入 systemd PID1 打印 Ubuntu 22.04 banner
npc-rv64-systemd-guest-check-contract|npc|e2e_npc_rv64_systemd_guest_check_contract|npc|NPC systemd guest prompt/script gate contract|NPC RV64 具备等待 root 串口 prompt 后用 NPC_UART_RX_FILE 注入 guest-side 检查脚本并等待 NPC_GUEST_EXPECT marker 的 gate 入口
rv64-linux-contract|rv64-linux|e2e_rv64_linux_contract|rv64-linux|Linux Makefile/env/platform/instructions|RV64 Linux/Ubuntu 合约入口存在

### .github/memory/decisions.md#chunk-0007

- `kind`: memory
- `lines`: 40-49
- `tokens`: 556
- `heading`: [37] 软件开发全流程采用独立 `software-flow` agent
- `summary`: - **日期**: 2026-06-09 / - **状态**: 已决定 / - **上下文**: 工作区已经有硬件落地前的 `hardware-flow`、`npc`、`ysyx-soc`、`rv64-linux` 等 agent，但软件侧需求、脚本/工具链、NEMU/AM/am-kernels/Linux guest check 和 host side 软件开发仍缺一个对称的全流程入口，容易在实现、测试、回归和记录之间靠临时口头串联。 / - **决策**: 新增 `software-flow` 作为 L...

### [37] 软件开发全流程采用独立 `software-flow` agent

- **日期**: 2026-06-09
- **状态**: 已决定
- **上下文**: 工作区已经有硬件落地前的 `hardware-flow`、`npc`、`ysyx-soc`、`rv64-linux` 等 agent，但软件侧需求、脚本/工具链、NEMU/AM/am-kernels/Linux guest check 和 host side 软件开发仍缺一个对称的全流程入口，容易在实现、测试、回归和记录之间靠临时口头串联。
- **决策**: 新增 `software-flow` 作为 L1 软件开发流程 agent，负责 `scope-contract -> design-plan -> implement -> unit-or-contract-test -> integration-smoke -> regression-or-e2e -> review-record` 的完整闭环，并补充 `software-bugfix-loop` 与 `software-refactor-loop`。它可以调度 `nemu`、`abstract-machine`、`am-kernels`、`fceux-am`、`rv64-linux`、`linux-device`、`agent-system` 等软件相关模块；当任务需要 RTL/Chisel/SoC/STA/PPA 或 target/difftest 证据时，必须交接给 `hardware-flow` 或对应硬件模块 agent。
- **理由**: 这样软件任务在落地前也有清晰 owner、静态图、节点产物和 e2e contract，不再把软件开发流程混进硬件 bring-up 或 agent-system 维护任务里。
- **影响**: 后续新增软件功能、软件 bug 修复、脚本工具链重构或软件测试补齐时，应优先判断是否命中 `software-dev-loop`、`software-bugfix-loop` 或 `software-refactor-loop`；新增/调整该 agent 时必须同步更新 `.github/e2e/modules/software-flow.md`、`.github/e2e/profiles/software-flow.tsv`、`contracts` profile、脚本 gate 和 `.github/memory/modules/software-flow.md`。
- **2026-06-09 追加**: 对 NEMU/RV64/Linux 这类“用软件建硬件/系统模型”的任务，不能把 `software-flow` 只当环境校验；新增 `hardware-aware-software-loop` 作为组合图，先用 `software-flow` 收敛软件工程闭环，再叠加 `nemu-ubuntu`、`hardware-flow`、`rv64-linux`、`difftest` 或 target gate 做硬件/系统语义完成判定。

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-22
- `tokens`: 1288
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`；AI 环境入口见 `AI_ENVIRONMENT.md`；非平凡任务优先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 生成 bounded 上下文包。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境整理、e2e、自检或降低不确定性，先读取 `AI_ENVIRONMENT.md`、`.github/instructions/agent-env-layer-contract.instructions.md`、`.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，再用 `scripts/agent-e2e.sh --list-profiles` 选 profile 并生成 task-run 证据包。
7. Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，工程命令统一交给 Ubuntu：`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'`；若 agent/CLI 已在 WSL/Linux 原生 shell 内运行，则直接使用原生命令，不再套 `wsl.exe`。Windows/Codex→WSL 工程命令默认 single-flight：主 agent 可以把当前唯一 shell ownership 交给一个契约授权的子 agent，但该节点执行期间其它 agent 不得并发运行工程命令；无 shell 推理或自包含材料复核仍可并行。复杂控制流、管道和 Bash 变量放入仓库脚本，避免被 PowerShell 预先解释。
8. 历史 task-run/evidence 回查使用 `python3 scripts/github_index_db.py runs --profile <profile>` 和 `python3 scripts/github_index_db.py evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
9. 交付前必须显式切换“实现者人格”和“审查者人格”：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；冲突未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。
11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确 RTL/spec/TB/evidence 输入、输出路径、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务只消费合同列出的本地工程材料并使用不落盘命令，其它资料另建研究节点。
12. 本地 RV64 RTL 子 agent 使用 `fork_turns="none"`，初始提示只采用已校验的合同 `render` 输出；所需设计事实写入合同路径或随附材料，不继承父任务完整对话历史。该上下文隔离不降低模型、源码探索、实现、验证或 PPA 能力。
13. 主/子 agent 的任务描述、用户进度和终审摘要使用 `rv64-hardware-professional` 措辞：首句明确本地 RV64 module/signal/transaction、仿真/综合/STA 动作与证据产物；协调状态单独记录，不反复混入 RTL 技术正文。子 agent 最终回复按“RTL 对象或本地证据文件 → 周期或编译配置 → testbench/EDA 观测 → PASS/GAP 范围”组织，并保留反例、未知项、日志 marker 和真实文件名。长期 goal 只引用该措辞剖面，不复制场景清单。该规则不得减少工具、上下文、源码探索、负向 RTL 版本、断言、覆盖或 PPA 能力。
14. 合同 `render` 保持精简，只承载 RV64 RTL/证据对象、周期/配置、TB/EDA 观测、合同绑定和工程动作；派发管线、父任务历史与协调状态留在 JSON/dispatch log。Python/JSON 证据工具复核也以具体 CPU 债务项、RTL 证据路径、字段、定向单测和返回码作主语，不用泛化软件保证叙述替代硬件事实。

请直接打开 [`.github/AGENTS.md`](./.github/AGENTS.md)。

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-2
- `tokens`: 8
- `heading`: YSYX 项目状态总览
- `summary`: YSYX 项目状态总览

# YSYX 项目状态总览

### .github/memory/known-issues.md#chunk-0001

- `kind`: memory
- `lines`: 1-4
- `tokens`: 35
- `heading`: 已知问题与调试历史
- `summary`: > 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

### .github/e2e/README.md#chunk-0001

- `kind`: markdown
- `lines`: 1-2
- `tokens`: 6
- `heading`: Agent E2E Profiles
- `summary`: Agent E2E Profiles

# Agent E2E Profiles

### .github/e2e/modules/rv64-linux.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-9
- `tokens`: 157
- `heading`: rv64-linux E2E Contract
- `summary`: - **范围**: `Linux/`、OpenSBI、Linux kernel、Ubuntu initramfs/rootfs、QEMU/NPC gate。 / - **上游**: npc/rv64 core、Linux env、device contracts。 / - **下游**: linux-device、display-vga、verilator-tapeout。 / - **L0 gate**: `rv64-linux-contract` 检查 Linux 入口、platform yaml 和 i...

# rv64-linux E2E Contract

- **范围**: `Linux/`、OpenSBI、Linux kernel、Ubuntu initramfs/rootfs、QEMU/NPC gate。
- **上游**: npc/rv64 core、Linux env、device contracts。
- **下游**: linux-device、display-vga、verilator-tapeout。
- **L0 gate**: `rv64-linux-contract` 检查 Linux 入口、platform yaml 和 instructions。
- **L1 gate**: 后续按 `rv64-ubuntu-probe-loop` 跑 QEMU/NPC probe。
- **证据**: `/init`、`/etc/os-release`、`/bin/sh`、rootfs mount、poweroff。
- **升级路线**: 按 gate 分层生成机器可读 boot status。

### .github/agents/rv64-linux.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 172
- `heading`: rv64-linux.agent.md
- `summary`: --- / description: "RV64 Linux/Ubuntu 22.04 bring-up 专家。当任务涉及 npc/rv64、OpenSBI、Linux kernel、DTB、initramfs/rootfs、Ubuntu Base、QEMU reference 或 Verilator 上的完整 Linux 启动证据时使用。" / tools: [read, edit, search, execute, agent, todo] / --- / 你是 **RV64 Linux / Ubuntu...

---
description: "RV64 Linux/Ubuntu 22.04 bring-up 专家。当任务涉及 npc/rv64、OpenSBI、Linux kernel、DTB、initramfs/rootfs、Ubuntu Base、QEMU reference 或 Verilator 上的完整 Linux 启动证据时使用。"
tools: [read, edit, search, execute, agent, todo]
---

你是 **RV64 Linux / Ubuntu bring-up 专家**。你的职责是把 `Linux/` 中的真实 OpenSBI、Linux kernel、DTB、initramfs/rootfs、QEMU reference 与 `npc/rv64` Verilator target 组织成可验证闭环，避免把“构建了镜像”“进入 kernel high-half”“进入 `/init`”“完整 Ubuntu shell/rootfs”混为一谈。

### .github/memory/modules/software-flow.md#chunk-0005

- `kind`: memory-module
- `lines`: 21-25
- `tokens`: 933
- `heading`: 当前状态
- `summary`: - 2026-06-09：通过 `nemu-ubuntu` 已 include `software-flow` 的链路，当前 interpreter TB max-inst 配置切片先执行 `software-flow-contract`，再执行 NEMU static/slice gate。验证：`scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-tb-max-inst-config-e2e` PASS，`.github/task-run...

- 2026-06-09：通过 `nemu-ubuntu` 已 include `software-flow` 的链路，当前 interpreter TB max-inst 配置切片先执行 `software-flow-contract`，再执行 NEMU static/slice gate。验证：`scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-tb-max-inst-config-e2e` PASS，`.github/task-runs/2026-06-09-nemu-tb-max-inst-config-e2e/nodes.tsv` 与 `task-report.md` 均显示 `software-flow-contract` PASS，后续 `nemu-ubuntu-static`/`nemu-ubuntu-slice-contract` 也 PASS。意义：NEMU C/Kconfig/Make/Shell 侧性能配置工作现在被软开流程前置消费，不再是单独跑过 `software-flow` 后靠主观记忆应用。
- 2026-06-09：`software-flow` 已被 `nemu-ubuntu` profile 显式 include，真正进入 NEMU C 侧/Ubuntu 切片生产链路。此前它能单独 PASS，但 NEMU 切片只是“按原则应叠加”；现在 `.github/e2e/profiles/nemu-ubuntu.tsv` 通过 `@include|software-flow` 把 `software-flow-contract` 放在 `nemu-ubuntu-static` 与 `nemu-ubuntu-slice-contract` 之前，`nemu-ubuntu-gate` 也继承该前置节点。验证：`scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu` 显示 8 nodes 且包含 `software-flow-contract`；`scripts/agent-e2e.sh --validate-all-profiles` PASS；`.github/task-runs/2026-06-09-nemu-ubuntu-software-flow-include-e2e/` PASS，task-report 节点表、dispatch-log 和 `evidence/software-flow-contract.log` 均证明该节点被真实执行。边界：这是把软件流程纳入 NEMU Ubuntu 生产守门，不替代 NEMU static/slice gate、真实 guest gate、DiffTest、target gate 或完整软件回归矩阵。
- 2026-06-09：新增 `software-flow` 作为 L1 软件开发流程 agent，用于覆盖需求/契约、设计、实现、单测/契约测试、集成 smoke、回归/e2e、审阅和记录的完整软件开发闭环。职责边界是软件模块、脚本、工具链、NEMU/AM/am-kernels/Linux guest check、host side C/C++/Python/Shell/Make/Kconfig；一旦任务进入 RTL/Chisel/SoC/STA/PPA 或 target/difftest 依赖，必须把产物交给 `hardware-flow` 或对应硬件模块 agent。验证：`software-flow` profile PASS，证据 `.github/task-runs/2026-06-09-software-flow-agent-e2e/`；`contracts` profile 中 `software-flow-contract` PASS，证据 `.github/task-runs/2026-06-09-software-flow-contracts-e2e/`；`quick` profile 无 hard fail，`nemu-add-smoke` 因当前 NEMU 配置边界 SKIP。
- 2026-06-09：根据用户指出“之前只是环境校验，没有作为主开发流程使用”，已把 `software-flow` 从可发现 agent 升级为生产组合流程。新增稳定口径 `hardware-aware-software-loop`：NEMU、Linux tools、guest check、host C++ harness、QMP/GDB、virtio/device model 等任务既是软件开发，又承载硬件/系统语义；必须先由 `software-flow` 做需求/契约、设计、实现、软件 focused test 和记录，再叠加 `nemu-ubuntu`、`hardware-flow`、`rv64-linux`、`difftest` 或 target gate 证明系统语义。e2e `software-flow-contract` 已升级为检查 software-flow、hardware-flow、nemu、coordinator、蓝图与 agent-e2e workflow 的组合钩子，避免退回“只验证存在”。验证：`scripts/agent-e2e.sh --validate-all-profiles` PASS；`scripts/agent-e2e.sh --profile software-flow --task-slug software-flow-integrated-e2e` PASS，日志含 `PASS hardware-flow consumes software-flow for software artifacts` 与 `PASS nemu agent requires software-flow for C-side model work`；`scripts/agent-e2e.sh --profile contracts --task-slug software-flow-integrated-contracts-e2e` PASS。
