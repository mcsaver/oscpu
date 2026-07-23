# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: db first stored memory audit
- `focus_scope`: non-history
- `token_estimate`: 1998 / 2400

## Profile Suggestions
- `github-index` score=22 matched=audit, db, first, memory, requested-profile, stored command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=6 matched=audit, db, first, memory, stored command=`scripts/agent-e2e.sh --profile agent-system`
- `contracts` score=3 matched=db, first, memory command=`scripts/agent-e2e.sh --profile contracts`
- `nemu` score=3 matched=audit, db, memory command=`scripts/agent-e2e.sh --profile nemu`
- `software-flow` score=3 matched=db, memory command=`scripts/agent-e2e.sh --profile software-flow`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile github-index`

## Missing Paths
- `.github/agents/github-index.agent.md`
- `.github/memory/modules/github-index.md`

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

### .github/e2e/profiles/github-index.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 67
- `heading`: node_id|module|function|owner_agent|inputs|outputs
- `summary`: github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

# node_id|module|function|owner_agent|inputs|outputs
github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

### .github/memory/modules/agent-system.md#chunk-0020

- `kind`: memory-module
- `lines`: 106-110
- `tokens`: 1513
- `heading`: 当前状态
- `summary`: - 2026-06-16：DB doctor/audit 默认输出污染继续收紧到“不显示本轮无关历史项”。用户指出历史 manual log 缺失和旧 shim stale 即便是非阻塞，也不应继续出现在默认维护视图里；root cause 是前一版只隐藏路径或改名为 nonblocking，但默认仍暴露 `hidden_historical_drift`、`nonblocking_archived_stored_only`、`nonblocking_live_drift`、`hidden_nonblocki...

- 2026-06-16：DB doctor/audit 默认输出污染继续收紧到“不显示本轮无关历史项”。用户指出历史 manual log 缺失和旧 shim stale 即便是非阻塞，也不应继续出现在默认维护视图里；root cause 是前一版只隐藏路径或改名为 nonblocking，但默认仍暴露 `hidden_historical_drift`、`nonblocking_archived_stored_only`、`nonblocking_live_drift`、`hidden_nonblocking_db_first_drift` 这些会被 agent 误读成本轮状态的字段。现在 `scripts/dev_memory/maintenance.py` 默认输出只服务当前阻塞判断：`doctor --fail-on-drift` 只打印 `blocking_drift` 与普通索引计数，`audit-db-first` 只打印 PASS/FAIL 摘要、stored/materialized/shims/backup 信息；显式 `--show-nonblocking-drift` 才输出非阻塞计数与历史路径。`scripts/e2e/modules/github_index.sh` 的 mini repo 合同同步检查默认无 hidden/nonblocking 历史字段，verbose 可展开，strict `.github/memory/project-status.md` drift 仍 hard fail。验证：py_compile、bash -n、真实 `doctor --fail-on-drift` 和默认 `audit-db-first` 输出干净；`audit-db-first --show-nonblocking-drift` 可展开 91 个非阻塞历史项；`.github/task-runs/2026-06-16-db-doctor-audit-hide-historical-drift-default/` PASS 且 evidence 已登记。经验：默认维护命令只回答“现在能不能继续”，历史诊断必须由显式开关触发。
- 2026-06-16：NEMU PyLong focused gate 的证据链进一步接入 agent/e2e/DB。三组直接 run（默认、`NEMU_INTERPRETER_WIDE_IFETCH=0`、`NEMU_VADDR_HOST_FAST=0`）都 PASS 后，agent 发现 host 侧 runtime flags 和 boot/total 秒只在外层 make stdout，不在 evidence 文件里；这会让后续 DB evidence 查询缺少 A/B 关键字段。现在 `Linux/scripts/check-nemu-python-int-preflight.sh` 会写 `python-int-preflight-summary.tsv`，包含 runtime flags、loops、probe sha、done line、boot_seconds、total_seconds；`scripts/e2e/modules/nemu.sh` static contract 检查 summary hook 和关键字段。真实 `.github/task-runs/2026-06-16-nemu-python-int-summary-default-3loop/` PASS，`index-evidence` 将 summary TSV 作为 raw evidence asset 登记。经验：遇到“结果只在终端 stdout”的环境缺口要修工具，让后续 agent 可以从 task-run/DB 复用证据，而不是靠上一轮人类/模型记忆。
- 2026-06-16：继续按用户要求把“历史 manual log 缺失/旧 shim stale 与本轮无关”修成工具合同，而不是只口头解释。当前真实 `doctor --fail-on-drift` 已干净，但 `audit-db-first` 默认仍输出 `live_drift=90`，虽然 `ok=true`，语义上仍像当前 live 问题。root cause 是 audit 把非 strict task-run/report/evidence 的历史 stored-only 与 live evidence-index 漂移归入成功路径后，默认摘要没有明确标记 nonblocking。现在 `audit-db-first` 默认只输出 `nonblocking_archived_stored_only`、`nonblocking_live_drift` 与 `hidden_nonblocking_db_first_drift`，并隐藏路径；显式 `--show-nonblocking-drift` 才展开 `[nonblocking_archived_stored_only]`/`[nonblocking_live_drift]` 样例。github-index e2e mini repo 同步覆盖默认隐藏、verbose 展开、strict memory drift 仍 hard fail，usage 查询窗口也随新增 audit 步骤调大到 20，避免合同链变长后挤掉 runs 访问记录。验证：py_compile、bash -n、`.github/task-runs/2026-06-16-2026-06-16-db-audit-nonblocking-drift-labels-pass/` PASS；真实 `audit-db-first` 默认显示 `hidden_nonblocking_db_first_drift=91`，verbose 可展开历史路径，`doctor --fail-on-drift` 与 `audit-markdown-coverage --fail-on-live-evidence` PASS。
- 2026-06-16：本轮继续验证了“环境 bug 要修环境，而不是绕开”。开始阶段并发 WSL 读文件留下多个 `wsl.exe sed/pwd` 客户端，同时旧 NPC task-run `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-autocheck-real-marker.sh` 还有两个 stale `wsl.exe`，导致 NEMU-only 的 `wsl -d Ubuntu pwd` 都超时。agent 没有把这归因于 NEMU，也没有从备份读答案；先用 Windows 侧 live 文件读取继续 RECALL，随后确认 NPC run 已有 `autocheck-real-marker.rc=2` 且 log 5 秒不增长，只清理 stale 客户端，恢复 WSL single-flight。过程中再次踩到外层 PowerShell 会拆 `| head` 和 `&& sed` 的坑，后续命令改用 `rg -e` 或单个 `bash -lc`。工程结论：NEMU/NPC 可以同仓协同开发，但真实 WSL 工程命令仍要 single-flight；如果旧 NPC 长跑客户端卡住 NEMU 通道，应先判定是否 stale 再清理，并把证据写入 task-run/memory。
- 2026-06-16：agent/e2e/DB 与 NEMU full Ubuntu 继续协同推进 PyLong blocker。新增 NEMU-only `check-nemu-python-int-preflight` focused gate 后，第一次 5B 实跑证明 full rootfs/root prompt/probe SHA 都通但预算耗尽；第二次 20B 实跑拿到 guest `__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`，host 解析因串口 CR 误判失败，随后修复 host 侧 `tr -d '\r'`；最终 `.github/task-runs/2026-06-16-nemu-python-int-focused-gate/` PASS。e2e static contract 首轮因检查运行期展开 marker `INT_FROM_BYTES_MAP`/`VALUE_2_BIT_LENGTH` 而不是源码格式串失败，随后修为检查 `INT_FROM_BYTES_%s`/`VALUE_%s_BIT_LENGTH`，`.github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/` PASS。经验：focused gate 的失败也要按 root cause 修 host/e2e 工具链，不能把 guest 已 PASS 的结果硬写成失败，也不能把 e2e pattern 写成运行期过拟合。

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
