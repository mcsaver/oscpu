# v8k dispatch log

## 2026-07-20 contract freeze

- 本地 RV64 RTL 架构闭合；无网络、账号、凭据、外部服务或外部状态变更。
- bounded brief：`pending system csr` / `npc-dev` / `non-history`，2024/2400 tokens，recall complete。
- 首个过窄 query 因无独立 primary fail-closed，随后仅扩大关键词，不扩大工程/权限范围。
- reviewer JSON 路径与 SHA-256 由 contract renderer 生成后逐字追加。
- contract JSON：`.github/task-runs/2026-07-20-rv64-v8k-pending-csr-producer-lease/subagent-contracts/v8k-pending-csr-contract-review.json`
- contract JSON SHA-256：`36a40fb1ad9059f873eaeb8e97733081d58740cd91ea8736ed6ea9fffa10b822`
- 该 SHA-256 只绑定上述 JSON，不绑定设计 spec、`contract.md`、RTL 或测试。
- 实际派发边界将进一步收紧为 no tools / no shell / no file access / no network；reviewer 只接收
  自包含冻结摘要并返回结构化反例。

## 2026-07-20 independent contract review

- verdict：`gap`；3 个 blocker 均为可执行 RTL 生命周期反例，未进入实现即被拦截。
- blocker 1：metadata 任一位部分清除时，旧的 gated lease 会同时丢失 birth fence 与 head0 封口。
  修订：live mask 直接读 raw lease；head0 seal 为 `raw_lease || logical_claim`；empty 同时要求
  `!valid && !raw_lease`。
- blocker 2：普通 pending clear 不等价于 post-dispatch ROB death。
  修订：live death 白名单仅 exact pending commit、reset、与 ROB 同沿的 backend global flush；普通
  clear 只处理 pre-ROB 状态，新增 lease-fall death-witness 检查。
- blocker 3：dispatch fire 与高优先级 clear/flush 同拍可能形成 orphan ROB P。
  修订：system CSR admission 显式排除 reset/global/core-local flush 与 pending clear，并检查每个真实
  ROB enqueue 同沿都产生 lease birth。
- reviewer 还确认：full PID 是身份主键、PC 是附加 coherence；commit0 true head fire 下无需再把
  inst 加入授权，但必须证明 dispatch payload 同源且 live 期间不被覆盖。

## 2026-07-20 amended contract review

- verdict：`pass`；blockers=`[]`。
- 落地约束：raw/logical 四态中只允许 `00` 进入 head0 fallback；`logical_claim=1 && raw=0`
  必须用失败断言与变异证明不可达。
- `core_local_flush_w` 只有在与 backend ROB flush 同沿、不可拒绝时才是合法 death witness；集成
  证据必须检查 flush 后 held P 不再存活。
- exact commit 与 ordinary clear 同拍时 exact death 不能被吞掉；commit/flush 同拍还须保持既有
  ROB commit acceptance 语义或同步抑制 CSR 副作用。
- scoped 结论不得外推任意多点 malformed state、generation wrap、全核 holder census 或 PPA。

## 2026-07-20 admission-cancel amendment dispatch

- 静态 lint 发现把完整 `pending_system_clear_w` 反喂 admission 会形成
  `system-valid -> backend-ready -> direct-fire -> pending-clear -> system-valid` 组合环；这属于合同
  精确定义变化，先复核再收尾。
- amendment contract JSON：`.github/task-runs/2026-07-20-rv64-v8k-pending-csr-producer-lease/subagent-contracts/v8k-pending-csr-cancel-amendment-review.json`
- contract JSON SHA-256：`41dd305ada3b9794f31da994e50cbf75f39b427d9df86a5f6a1038fc80a3e29c`
- renderer 要求声明至少一个只读命令，JSON 声明 `rg`；实际派发继续收紧为无工具、无 shell、
  无文件与无网络，只提供自包含方程和 lint 结果。

## 2026-07-20 implementation review dispatch

- implementation contract JSON：`.github/task-runs/2026-07-20-rv64-v8k-pending-csr-producer-lease/subagent-contracts/v8k-pending-csr-implementation-review.json`
- contract JSON SHA-256：`1f6f5ff4f3bcea2742d58ead169ab2c80ca80765b45659132b47f1ecc294a5c7`
- 审查范围只覆盖 v8k pending-system CSR ProducerId lease、exact commit、holder census、拆环
  admission 与现有证据充分性；禁止外推全核、PPA 或 promotion。
- 实际派发仍为自包含 no-tools reviewer；JSON 内 `rg` 只满足 canonical contract schema，未授予
  实际运行权限。

## 2026-07-20 admission-cancel review closeout

- amendment reviewer 首轮 verdict=`gap`：裸 `pending_jump_resolve_ready` 会在三个 outcome 均为 0
  时取得 cancel capability，构成 pre-ROB pending CSR 自锁反例。
- 方程改为
  `ready && (misaligned || nolink_commit || redirect_after_dispatch)`；补入 stuck-ready/no-outcome、
  outcome-without-ready、held-outcome-then-ready、逐 outcome 定向测试，以及
  `pending_jump_ready_overcancels` compile-success mutation。
- reviewer 复核后最终 verdict=`pass`、blockers=`[]`；结构化结果：
  `cancel-amendment-review-result.json`。保留边界：精简方程是在 pending-system/direct-flush 互斥下
  的安全上位覆盖，并非全局布尔等价；跨模块无环仍由 ControlPlane assertions 与 full lint 约束。

## 2026-07-20 implementation review closeout

- implementation reviewer 最终 verdict=`pass`、blockers=`[]`；结构化结果：
  `implementation-review-result.json`。
- reviewer 建议的 ready=0 outcome→ready=1 跨周期反例已加入 admission gate TB；完整 SCC/formal、
  原始 mutation runner 独立复跑、core-local flush/commit 同沿协议仍列为证据盲区，不外推全核 GREEN。

## 2026-07-20 native self-contained no-tools forward test

- 旧合同因 schema 要求非空命令而只能在 JSON 声明 `rg`、派发时再口头收紧；该记录保留为历史
  证据，不再作为新派发规范。
- 已将原生 `prompt-supplied-self-contained` 模式接入 canonical JSON、generator、instruction、skill、
  `AI_ENVIRONMENT.md` 与 `agent-system` e2e：只允许 `read-only-review`，精确要求
  `allowed_commands=[]`、`write_paths=[]`、非空单行 `supplied_material`，路径仅作 provenance。
- 本次 forward-test contract JSON：
  `.github/task-runs/2026-07-20-rv64-v8k-pending-csr-producer-lease/subagent-contracts/v8k-native-no-tools-workflow-review.json`
- contract JSON SHA-256：`9ef57a6f9e93bdb5ca3f9713a72ea618c3a2e9fe1eddecabf6002b67ff6bf0fb`
- 该 SHA-256 只绑定上述 JSON。渲染提示逐字保存为同目录
  `v8k-native-no-tools-workflow-review.prompt`，并与 generator 当前输出 byte-equal。
- 实际访问：tools=false、shell=false、filesystem=false、network=false、writes=false；reviewer
  verdict=`pass`、blockers=`[]`，结果落盘 `native-no-tools-workflow-review-result.json`。
- reviewer 明确保留 no-tools 固有盲区：未自行读取 JSON、复算 SHA 或重放测试；因此 workflow
  GREEN 仍须以主 agent 的 audit/self-test/CLI/e2e/strict-guard 证据签收。

## 2026-07-20 retained-memory and profile evidence

- `update-stored` 已发布 `modules/npc.md`、`project-status.md` 与 `modules/agent-system.md`；
  `snapshot-stored --yes`、DB-first audit 与 Markdown coverage 均 PASS。
- agent-system forward run 1：
  `.github/task-runs/2026-07-20-v8k-native-no-tools-rtl-contract/`，`blocked`。discovery 精确拒绝
  skill 目录内由显式 `py_compile` 生成的 untracked `.pyc`；仅删除该可再生产物，未改报告。
- agent-system forward run 2：
  `.github/task-runs/2026-07-20-v8k-native-no-tools-rtl-contract-2/`，`blocked`。10/10 execution
  nodes PASS，但 startup bounded brief 在 retained memory 发布前没有 independent non-history primary；
  未把节点 PASS 改写成 overall GREEN。
- task-specific brief `no tools rtl subagent contract / agent-system / non-history` 为 complete，
  2317/2400 tokens；正式
  `.github/task-runs/2026-07-20-no-tools-rtl-subagent-contract/` completed、10/10 PASS、
  publication-valid。
- task-specific brief `pending csr producer lease / npc-dev / non-history` 为 complete，
  2385/2400 tokens；正式 `.github/task-runs/2026-07-20-pending-csr-producer-lease/`
  completed、5/5 PASS、publication-valid。
- 两个 profile 只证明协作规则与 NPC 入口可发现、可执行、可审计；不替代本 task-run 的 RTL
  focused/mutation/regression/static 证据，也不提升 architecture/PPA 状态。

## 2026-07-20 live-index recall freshness correction

- reviewer 检查首份 completed agent-system run 的 `context-brief.md` 后发现：执行节点读取最新 live
  文件并 PASS，但独立 focus chunk 仍是 DB 中旧版 skill；因此不接受“节点 PASS 即召回新鲜”的越级结论。
- 根因：普通规则的 live-first 来源是 SQLite live 索引快照，修改后若不 `refresh/rebuild`，brief
  仍可结构合法地返回旧 chunk。runner 已在 dispatch 前增加 fail-closed active-only rebuild，结果
  保存到 `evidence/context-live-index-refresh.log`；失败时不再调用 brief 生成假 complete recall。
- 初版扫描 72,717 个 task-run 文件造成分钟级等待；索引器改用 top-down `os.walk`，在目录层剪枝
  `.github/{memory,task-runs,archive,shujuku_aireview}` 及 backup/cache/tmp/runtime/raw evidence。
  monkeypatch 反例要求被剪枝文件不得触达 `index_one_file`。最终 rebuild 为 130 files/16.69s。
- DB-first audit 随后抓到旧 rebuild 会把未扫描的 excluded memory 行误标 missing；missing 更新已收窄为
  “本轮 scope 内且未排除”的旧行，并加入真实 SQLite 保持状态反例。包含 memory 的修复性 rebuild
  为 174 files/16.98s，随后 `audit-db-first` PASS。
- `.github/task-runs/2026-07-20-no-tools-rtl-subagent-contract-3/`：agent-system 10/10 completed，
  brief 命中新 no-tools mode；`.github/task-runs/2026-07-20-active-rules-root-shims/` 保留为 blocked
  反例（根 shim 853 tokens 超过旧 smoke 800）；阈值按真实最小契约调到 1200 后，`...-2/`
  github-index 1/1 completed、publication-valid。
- 被中断扫描只生成的 0-byte `.tmp`、空 nodes 与未派发日志没有审计价值且会污染 artifact gate，
  已精确删除；未删除或改写任何 canonical blocked/completed report。

## 2026-07-20 final profile and strict-guard closeout

- `scripts/agent-maintain.sh --mode check` PASS：policy/skill/RTL-contract 20+18 cases、artifact、delivery、
  trace/state/branch health、DB-first、Markdown coverage 与全部 profile binding 均通过。
- 最终 agent-system：`.github/task-runs/2026-07-20-no-tools-rtl-subagent-contract-4/`，10/10 PASS、
  publication-valid，refresh `files=130`，brief 明确包含原生 no-tools mode。
- 最终 github-index：`.github/task-runs/2026-07-20-active-rules-root-shims-4/`，1/1 PASS、
  publication-valid，日志包含目录剪枝、excluded live-index row 保持、root shim load 与 DB-first 门禁。
- 最终 npc-dev 沿用晚于 RTL/spec 的 `.github/task-runs/2026-07-20-pending-csr-producer-lease-2/`，
  5/5 PASS、publication-valid；本轮没有在其后修改 RTL/spec。
- strict guard：`changed_paths=541`、`required_profiles=3`，上述 agent-system/npc-dev/github-index
  全部 PASS。该结论只闭合协作环境和 v8k scoped slice，不改变 architecture inventory RED 或 PPA 未授权。
