# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: serialized system
- `focus_scope`: non-history
- `token_estimate`: 2272 / 2400

## Profile Suggestions
- `npc-dev` score=8 matched=requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `agent-system` score=6 matched=system command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=2 matched=system command=`scripts/agent-e2e.sh --profile github-index`
- `rv64-linux` score=2 matched=system command=`scripts/agent-e2e.sh --profile rv64-linux`
- `contracts` score=1 matched=system command=`scripts/agent-e2e.sh --profile contracts`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile npc-dev`

## Missing Paths
- `.github/e2e/modules/npc-dev.md`
- `.github/agents/npc-dev.agent.md`
- `.github/memory/modules/npc-dev.md`

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

### .github/e2e/profiles/npc-dev.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-5
- `tokens`: 148
- `heading`: npc-dev.tsv
- `summary`: @include|software-flow|||| / npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backend manifests|NPC 开发环境入口只检查 NPC 仿真后端合同 / npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在 / npc-soc-contrac...

@include|software-flow||||
npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backend manifests|NPC 开发环境入口只检查 NPC 仿真后端合同
npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在
npc-soc-contract|npc|e2e_npc_soc_contract|npc|npc/soc + ysyxSoC CPU ABI|NPC SoC 后端合约入口存在
npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|NPC RV64 Linux 入口合约存在但不跑 NEMU Ubuntu gate

### .github/memory/modules/npc.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-4
- `tokens`: 11
- `heading`: RV64 serialized SYSTEM post-fire V10B
- `summary`: RV64 serialized SYSTEM post-fire V10B

## RV64 serialized SYSTEM post-fire V10B

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-18
- `tokens`: 972
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
9. 交付前必须显式执行“实现者 / 审查者”双角色复核：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；分歧未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。
11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确 RTL/spec/TB/evidence 输入、输出路径、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务只消费合同列出的本地工程材料并使用不落盘命令，其它资料另建研究节点。
12. 本地 RV64 RTL 子 agent 使用 `fork_turns="none"`，初始提示只采用已校验的合同 `render` 输出；所需设计事实写入合同路径或随附材料，不继承父任务完整对话历史。该上下文隔离不降低模型、源码探索、实现、验证或 PPA 能力。

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

### .github/memory/modules/npc.md#chunk-0018

- `kind`: memory-module
- `lines`: 119-124
- `tokens`: 197
- `heading`: 稳定微架构合同
- `summary`: - `OooPendingSystemSequencer.kind_q` 是 serialized SYSTEM/CSR/IRQ 类型的唯一注册真源；`valid_o` 当且仅当 kind 非 NONE，valid holder 的八个公开类型 exact-one。非空 holder 不接受 recapture，kind/payload 保持到授权 clear/death。 / - 普通 FENCE 由 holder 输出 `fence_o`，`OooControlPlane` 不得再从 raw instru...

### 稳定微架构合同

- `OooPendingSystemSequencer.kind_q` 是 serialized SYSTEM/CSR/IRQ 类型的唯一注册真源；`valid_o` 当且仅当 kind 非 NONE，valid holder 的八个公开类型 exact-one。非空 holder 不接受 recapture，kind/payload 保持到授权 clear/death。
- 普通 FENCE 由 holder 输出 `fence_o`，`OooControlPlane` 不得再从 raw instruction 建立第二类型真源。SFENCE.VMA/SINVAL family 与 FENCE.I 的 redirect reason 必须消费 exact holder-derived commit pulse。
- CSR ProducerId lease 只在 CSR dispatch birth，必须由 matching PID+PC commit death 或 backend-global reset 终止；非 CSR serialized transaction 不制造 ProducerId。

### .github/memory/modules/npc.md#chunk-0009

- `kind`: memory-module
- `lines`: 68-73
- `tokens`: 229
- `heading`: 稳定微架构合同
- `summary`: - `OooPendingDrainResolveGate` 对 pending SYSTEM 与 pending architectural trap 共用同一 exact memory-owner terminal 边界：`!(pending_system_i || pending_arch_trap_i) || mem_owner_terminalized_i`。旧 memory holder active 且没有 exact accepted terminal transfer 时，`drain_co...

### 稳定微架构合同

- `OooPendingDrainResolveGate` 对 pending SYSTEM 与 pending architectural trap 共用同一 exact memory-owner terminal 边界：`!(pending_system_i || pending_arch_trap_i) || mem_owner_terminalized_i`。旧 memory holder active 且没有 exact accepted terminal transfer 时，`drain_complete_o`、`pending_arch_trap_fire_o`、trap request 与 predictor boundary 必须保持 0。
- exact same-edge accepted transfer、collector-pending-only 与 full-idle phase 继续由 production `mem_owner_terminalized_i` 标量表达；没有 serialized owner 的无关 control cycle 不受该标量约束。ordinary FENCE 仍额外等待 full `mem_idle_i`。
- 该修复只增加组合 consumer term，不增加寄存器、terminal 去重或 collector filter；`OooMemOwnerTerminalCollector` 与 owner/tracker fail-loud 合同保持不变。

### .github/memory/modules/npc.md#chunk-0021

- `kind`: memory-module
- `lines`: 135-142
- `tokens`: 327
- `heading`: 稳定微架构合同
- `summary`: - `full-core-single-hart-rv64-dual-issue-ooo-v1` 是当前 full-core candidate 的规范 capability cohort，并严格绑定 design-id `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。cohort exclusion 不是因缺测试自动产生；必须有明确 rationale、当前 design/cohort、规范合同路径/hash...

### 稳定微架构合同

- `full-core-single-hart-rv64-dual-issue-ooo-v1` 是当前 full-core candidate 的规范 capability cohort，并严格绑定 design-id `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。cohort exclusion 不是因缺测试自动产生；必须有明确 rationale、当前 design/cohort、规范合同路径/hash 和 candidate/ledger 完全对称集合。
- A-extension 只承诺单 hart local reservation：successful LR 建立，SC consumption 与 hart-issued store/AMO write 清除；autonomous coherent/exclusive peer invalidation 不属于当前产品 cohort。
- WFI 是经过 pending-system drain 的 legal immediate-resume hint，`mstatus.TW` below M 的非法路径保留；不承诺 clock/power sleep、interrupt-only wakeup 或 wake latency。
- accepted `SFENCE.VMA` / Svinval-family encoding 统一进入 serialized pending-system，并形成 global `mmu_flush`；不承诺 address/ASID selective invalidation。reserved encoding 与 TVM legality 不变。
- simulation observability、`OOO_ASSERT` 与 semihost EBREAK 不是 architectural Debug。当前 cohort 不广告 Debug Module、debug mode、halt/resume transport 或 executable trigger action。
