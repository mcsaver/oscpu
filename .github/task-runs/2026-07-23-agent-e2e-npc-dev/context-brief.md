# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: npc dev
- `focus_scope`: non-history
- `token_estimate`: 2291 / 2400

## Profile Suggestions
- `npc-dev` score=14 matched=dev, npc, requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `linux-device` score=6 matched=dev command=`scripts/agent-e2e.sh --profile linux-device`
- `npc` score=6 matched=npc command=`scripts/agent-e2e.sh --profile npc`
- `agent-system` score=3 matched=dev, npc command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=3 matched=dev, npc command=`scripts/agent-e2e.sh --profile nemu`

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

### .github/memory/modules/software-flow.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-9
- `tokens`: 1464
- `heading`: 当前状态
- `summary`: - 2026-06-14：本轮 NEMU full Ubuntu 22.04 blocker 继续按 `hardware-aware-software-loop` 执行，而不是只做环境校验。scope-contract 明确普通 NEMU 开发入口为 `nemu-dev*`，NPC 开发入口为 `npc-dev`，跨栈集成入口为 `nemu-ubuntu-integrated`；实现阶段同时改 NEMU runtime diagnostic 开关、e2e static/slice/full focused c...

## 当前状态

- 2026-06-14：本轮 NEMU full Ubuntu 22.04 blocker 继续按 `hardware-aware-software-loop` 执行，而不是只做环境校验。scope-contract 明确普通 NEMU 开发入口为 `nemu-dev*`，NPC 开发入口为 `npc-dev`，跨栈集成入口为 `nemu-ubuntu-integrated`；实现阶段同时改 NEMU runtime diagnostic 开关、e2e static/slice/full focused contract、agent workflow 执行卫生和 DB stored memory。验证阶段没有只看外层退出码：先用 `bash -n`、`make -C Linux ARCH=riscv64-nemu sim`、默认/诊断 `nemu-machine-info` 和两个 NEMU-only static task-run 证明环境合同，再用真实 `nemu-dev-full-gate` 证明 `NEMU_INTERPRETER_BASIC_BLOCK=0` 后 Python int corruption 仍复现。当前 review-record 结论是：virtio-blk async、Sv39 TLB、decode cache、interpreter basic-block batching 已被排除为充分根因；wide-ifetch/host-fast path 仍待更短 reproducer。经验：遇到慢速 gate、上传、WSL/PowerShell quoting 问题时，修 e2e/agent 环境并固化 contract，不从备份或 NPC profile 绕开。
- 2026-06-13：按 `hardware-aware-software-loop` 修正本轮 NEMU/NPC 开发入口设计，形成“不损失旧集成功能”的双入口流程。scope-contract 重新界定为：`nemu-dev*`/`nemu-ubuntu-focused` 是 NEMU-only 默认开发入口，`npc-dev` 是 NPC-only 默认开发入口，旧 `nemu-ubuntu*` profile 继续作为跨 NEMU/NPC/RV64 Linux 集成 profile；实现阶段同步修改 stored profiles、NEMU/NPC agent 文档、agent-e2e workflow、e2e README、software-flow 模块说明和 e2e shell contracts；验证阶段用 profile resolve 证明 `nemu-dev` 只有 NEMU/software-flow 节点、`npc-dev` 只有 NPC/software-flow 节点、`nemu-ubuntu-full-gate` 仍保留 14 个集成节点，并用 `.github/task-runs/2026-06-13-software-flow-dev-isolation-contract/`、`2026-06-13-nemu-dev-no-loss-isolation-contract/`、`2026-06-13-npc-dev-no-loss-isolation-contract/` PASS 收口。经验：场景隔离不能靠删除旧集成节点实现；正确做法是新增隔离入口、保留集成入口，并把 agent、DB stored docs、e2e profile 和 memory 同时更新。
- 2026-06-11：`.github` 索引工具继续按软件产品化方向增强为可维护资料库操作层。新增 `ls/tree` 目录浏览、`search` alias、FTS5/LIKE 自动检索、`refresh` 单文件刷新、`add` 文件新增/替换和 `remove --delete-file --yes` 安全删除；维护命令遵守文件系统事实源原则，数据库只同步索引。验证：默认索引重建 PASS，`ls .github/e2e` 和 `tree .github/e2e --depth 2` PASS，`search github-index` 使用 `mode=fts` 命中；`.github/task-runs/2026-06-11-github-index-db-ops-e2e/` 与 `.github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/` PASS。意义：软件开发环境现在有可脚本化的 recall/query/maintenance 工具，但仍需由 `software-flow` 或对应模块 profile 证明业务软件改动质量。
- 2026-06-11：`software-flow` 方法论守门已被 NEMU Ubuntu 主 profile 显式消费。此前 `nemu-ubuntu.tsv` 已 include `software-flow`，但主要靠 profile 展开事实证明；本轮 `scripts/e2e/modules/nemu.sh` 的 `nemu-ubuntu-slice-contract` 直接检查 `@include|software-flow`、`software-flow-contract` 和 soft-flow agent 内的 dev/bugfix/hardware-aware 节点及反假完成约束。验证：`.github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/` PASS，`nemu-ubuntu-slice-contract.log` 含 `PASS nemu-ubuntu profile keeps software-flow include`、`PASS software-flow profile exposes software-flow-contract` 和 6 条 `PASS software-flow methodology available to nemu-ubuntu ...`；窄负向扫描无 `FAIL`/`__NEMU_CHECK_FAIL__`。意义：NEMU C/Python/Shell/Make/Kconfig 与 rootfs/guest-check 切片以后不仅会先跑 soft-flow contract，还会在 NEMU 自己的 slice contract 中防止软开方法论被摘除；边界是这仍是流程守门，不替代业务行为 gate。
- 2026-06-11：`software-flow-contract` 从“存在性/集成性检查”升级为“方法论守门”。`scripts/e2e/modules/module_contracts.sh` 现在在检查 `software-flow` agent/profile/memory 和 `hardware-aware-software-loop` 集成关系之外，还硬检查四类开发循环与关键节点产物是否保留：`software-dev-loop`、`software-bugfix-loop`、`software-refactor-loop`、`hardware-aware-software-loop`，以及 `scope-contract/design-plan/unit-or-contract-test/integration-smoke/regression-or-e2e/hardware-semantic-contract/system-or-hardware-gate/review-record`。同时检查反假完成约束：不把“构建通过”单独当成软件任务完成、不把脚本外层退出码当唯一证据、必须扫描 FAIL marker、完成后更新 software-flow memory；还检查 `.github/AGENTS.md` 的完成判定钩子仍要求重新展开用户原始请求。验证：`bash -n scripts/e2e/modules/module_contracts.sh scripts/agent-e2e.sh` PASS；`.github/task-runs/2026-06-11-software-flow-methodology-guard/` PASS，`evidence/software-flow-contract.log` 含 21 条新增 methodology PASS marker 与 `PASS global completion hook guards original request checklist`，负向扫描 `^FAIL `/`ERROR` 无命中。意义：软开环境现在不仅证明工具链和 profile 存在，也能低成本阻止开发思考流程被删弱；边界是这是方法论 contract，不替代具体业务模块的 focused test、系统 gate 或代码审阅。

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

### .github/memory/modules/software-flow.md#chunk-0006

- `kind`: memory-module
- `lines`: 26-31
- `tokens`: 291
- `heading`: 设计笔记
- `summary`: - `software-flow` 与 `hardware-flow` 对称：前者保证软件产物形成可验证闭环，后者保证 AM/NEMU/NPC/Verilator/difftest 的硬件开发闭环。两者可以协同，但不能互相越级声明对方 gate 完成。 / - 软件全流程默认静态图为 `software-dev-loop`，bug 修复用 `software-bugfix-loop`，重构用 `software-refactor-loop`；跨 3 个以上文件的软件任务应同步维护 task-run 证据。 /...

## 设计笔记

- `software-flow` 与 `hardware-flow` 对称：前者保证软件产物形成可验证闭环，后者保证 AM/NEMU/NPC/Verilator/difftest 的硬件开发闭环。两者可以协同，但不能互相越级声明对方 gate 完成。
- 软件全流程默认静态图为 `software-dev-loop`，bug 修复用 `software-bugfix-loop`，重构用 `software-refactor-loop`；跨 3 个以上文件的软件任务应同步维护 task-run 证据。
- NEMU 是“软件写成的硬件/系统模型”，不是普通应用软件，也不是纯硬件实现。开发 NEMU C 侧切片时，完成判定必须双层收口：软件层看调用链、接口、错误处理、focused test 和回归记录；硬件/系统层看 ISA/CSR/中断/设备/guest 可见行为、QEMU/NPC/NEMU reference 关系和对应 e2e profile 消费证据。
- 软件验证不能只看外层退出码，必须结合 PASS/FAIL marker、BAD TRAP、assert、guest marker、日志负向扫描或 e2e contract 证据。
