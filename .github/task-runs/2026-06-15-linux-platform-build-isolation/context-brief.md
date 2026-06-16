# Agent Brief

- `source`: live-or-stored
- `profile`: contracts
- `terms`: contracts linux-platform-build-isolation
- `token_estimate`: 1542 / 1800

## Profile Suggestions
- `contracts` score=11 matched=contracts, requested-profile command=`scripts/agent-e2e.sh --profile contracts`
- `agent-system` score=1 matched=contracts command=`scripts/agent-e2e.sh --profile agent-system`
- `rv64-linux` score=1 matched=contracts command=`scripts/agent-e2e.sh --profile rv64-linux`
- `toolchain` score=1 matched=contracts command=`scripts/agent-e2e.sh --profile toolchain`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile contracts`

## Missing Paths
- `.github/e2e/modules/contracts.md`
- `.github/agents/contracts.agent.md`
- `.github/memory/modules/contracts.md`

## Chunks

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-14
- `tokens`: 321
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境 e2e、自检或降低不确定性，读取 `.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，先用 `scripts/agent-e2e.sh --list-profiles` 选 profile，再生成 task-run 证据包。

请直接打开 [`.github/AGENTS.md`](./.github/AGENTS.md)。

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

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-3
- `tokens`: 38
- `heading`: YSYX 项目状态总览
- `summary`: > 本文件由 agent 自动维护，记录项目当前进度。每次完成重要任务后更新。

# YSYX 项目状态总览

> 本文件由 agent 自动维护，记录项目当前进度。每次完成重要任务后更新。

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

### .github/e2e/profiles/contracts.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-24
- `tokens`: 803
- `heading`: node_id|module|function|owner_agent|inputs|outputs
- `summary`: @include|discovery|||| / profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile / ysyx-coordinator-contract|ysyx-coordinator|e2e_ysyx_coordinator_contract|ysyx-coordinator|coordinator agent + blueprint +...

# node_id|module|function|owner_agent|inputs|outputs
@include|discovery||||
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile
ysyx-coordinator-contract|ysyx-coordinator|e2e_ysyx_coordinator_contract|ysyx-coordinator|coordinator agent + blueprint + profile root|总调度 e2e 合约入口存在
hardware-flow-contract|hardware-flow|e2e_hardware_flow_contract|hardware-flow|hardware-flow agent + scripts/am-regression.sh + e2e profiles|硬件流程合约入口存在
software-flow-contract|software-flow|e2e_software_flow_contract|software-flow|software-flow agent + profile + memory|软件开发全流程 agent 合约入口存在
github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|.github SQLite 索引数据库入口可构建、查询和巡检
abstract-machine-contract|abstract-machine|e2e_abstract_machine_contract|abstract-machine|AM Makefile/scripts/include/memory|AM 平台合约入口存在
am-kernels-contract|am-kernels|e2e_am_kernels_contract|am-kernels|cpu-tests/am-tests/klib-tests/benchmarks|测试与 benchmark 合约入口存在
nemu-config-probe|nemu|e2e_nemu_config_probe|nemu|nemu Kconfig/configs/device filelist|NEMU 当前配置和参考入口可见
npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backends|NPC 统一仿真入口合约存在
npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在
npc-soc-contract|npc|e2e_npc_soc_contract|npc|npc/soc + ysyxSoC CPU ABI|NPC SoC 后端合约入口存在
npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|RV64 core/Linux 入口合约存在
ysyx-soc-contract|ysyx-soc|e2e_ysyx_soc_contract|ysyx-soc|ysyxSoC Makefile/spec/agent/memory|ysyxSoC 合约入口存在
difftest-contract|difftest|e2e_difftest_contract|difftest|NEMU spike-diff + npc/sim difftest-ref|DiffTest 合约入口存在
yosys-sta-contract|yosys-sta|e2e_yosys_sta_contract|yosys-sta|yosys-sta Makefile/tools/memory|综合/STA 合约入口和工具状态可见
rv64-linux-contract|rv64-linux|e2e_rv64_linux_contract|rv64-linux|Linux Makefile/env/platform/instructions|RV64 Linux/Ubuntu 合约入口存在
linux-device-contract|linux-device|e2e_linux_device_contract|linux-device|virtio-rootfs instruction + Linux scripts|Linux 设备合约入口存在
display-vga-contract|display-vga|e2e_display_vga_contract|display-vga|linux-framebuffer-vga instruction + Linux README|显示/fbcon 合约入口存在
verilator-tapeout-contract|verilator-tapeout|e2e_verilator_tapeout_contract|verilator-tapeout|verilator realism instruction + npc/rv64|Verilator-first 流片边界合约入口存在
fceux-am-contract|fceux-am|e2e_fceux_am_contract|fceux-am|fceux-am Makefile/agent/memory|FCEUX-AM 合约入口存在
nvboard-contract|nvboard|e2e_nvboard_contract|nvboard|nvboard README/scripts/example/agent|NVBoard 合约入口存在
digital-logic-contract|digital-logic|e2e_digital_logic_contract|digital-logic|digital_logic_experiment + agent|数字逻辑实验合约入口存在

