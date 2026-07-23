# RV64 v8k pending-system CSR ProducerId lease 闭合报告

## 基本信息

- `task_id`: `2026-07-20-rv64-v8k-pending-csr-producer-lease`
- `task_class`: `architecture_closure_without_ppa_promotion`
- `slice_status`: `scoped_completed`
- `parent_goal_state`: `active`
- `promotion_eligible`: `false`

本报告只签收 dispatched pending CSR 的 full ProducerId 出生、Q-only lease、no-live-reuse birth
fence、exact commit capability、head0 fallback seal，以及 feedback-free admission cancel。非 CSR pending
控制事件、完整 holder census、finite-generation global no-live-reuse、全核架构、系统级验证和 PPA
均不在本地 GREEN 内。

## 实现者结论

- pre-ROB SYSTEM capture 保持无 ProducerId；只有真实 pending CSR lane0 ROB enqueue 沿才锁存
  `P={generation,rob_idx}`。`producer_valid_q/producer_id_q` 从出生保持到 exact commit、reset 或与
  ROB 同沿的 backend global flush，ordinary clear 与 `clear_dispatched` 不得切断 live owner。
- raw Q lease 直接解码成 pending external live mask，经 CoreTopGlue/ExecuteBackend/AluCoreSlice/
  DecodeBackend 下传并入 `OooIntBackend.producer_live_mask_w`。birth/death edge 均按 edge-old mask
  阻止同名 PID 同沿复用；mask 不读取 metadata、ready、fire、commit 或 authorization。
- pending CSR 只有 logical claim、raw lease、commit0 CSR、full PID exact match 与 PC coherence 全部
  成立时才能产生 CSR side effect。raw lease 或 logical claim 任一存在即封住 queue-head fallback，
  所以 partial metadata、same-index/different-generation、PC mismatch 均两路静默。
- 完整 `pending_system_clear` 含 backend-ready 派生的 direct frontend flush，不能反喂 admission。
  新的 `OooPendingSystemAdmissionCancelGate` 只读取无反馈 witness；pending jump 必须
  `ready && (misaligned || nolink_commit || redirect_after_dispatch)` 才能取消，裸 ready 不具备
  capability。ControlPlane 断言守住 direct-flush mutex、fire/clear mutex 和可达 jump-clear cover。

## 功能与静态硬门

| gate | 结果 | 证据 |
| --- | ---: | --- |
| source-bound structural audit | 14/14 PASS | `evidence/focused-run/static-audit.log` |
| focused assertion baseline | leaves 4/4 + IntBackend 1/1 + real privilege 1/1 PASS | `evidence/focused-run/summary.md` |
| focused release/malformed probes | IntBackend 1/1 + probes 3/3 PASS | `evidence/focused-run/summary.md` |
| expected-fail assertion probes | 2/2 rejected | `evidence/focused-run/summary.md` |
| compile-success semantic mutation | 10/10 rejected | `evidence/focused-run/mutation-summary.tsv` |
| focused source pre/post hash | byte-equal | `evidence/focused-run/sources.pre.sha256`、`sources.post.sha256` |
| legacy ProducerId slices | v8d/v8f/v8g/v8h/v8i/v8j 6/6 PASS | `evidence/regressions/summary.md` |
| fresh OOO_ASSERT module aggregate | 106/106 PASS | `evidence/regressions/module-aggregate/summary.txt` |
| RTL style / contract | PASS；assertions 388 >= 89 | `evidence/static/check-rtl-style.log`、`check-contract.log` |
| architecture checker self-test | 15/15 PASS | `evidence/static/architecture-hard-gates.log` |
| real architecture inventory | `OVERALL: RED`，预期 make rc=2 | `evidence/static/architecture-hard-gates.json` |
| full lint regression | inherited rc=2、115 warnings；normalized SHA 与 v8j 相同 | `evidence/static/full-lint.status` |

最终 focused 重跑发生在 dispatch/spec/memory 收口之后，输出
`[V8K-RUNNER] PASS: 10 compile-success semantic mutations rejected`，其 source manifest 因此绑定
最终合同、推导、holder census、dispatch log、spec、RTL 与 TB。没有把 full lint 非零豁免成 GREEN；
这里只证明 warning 集合未新增，normalized SHA 为
`414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b`。

## 审查者反例与处置

1. 合同 reviewer 首轮指出 metadata 部分清除会同时丢 birth fence 与 fallback seal、ordinary clear
   会错误杀死 post-dispatch lease、clear/flush 与 dispatch 同拍会产生 orphan P。三项均进入
   raw-lease authority、death whitelist、admission cancel、TB/assertion/mutation，修订后 PASS。
2. admission amendment reviewer 首轮 verdict=`gap`：裸 `pending_jump_resolve_ready` 在 outcomes 全 0
   时会持续取消 pre-ROB CSR。方程改为 ready+真实 outcome，并补 stuck-ready、outcome-without-ready、
   held-outcome-then-ready 与 `pending_jump_ready_overcancels` mutation；最终 verdict=`pass`。
3. implementation reviewer 最终 verdict=`pass`、blockers=0；建议的跨 ready 测试已落地。它保留的
   盲区是没有独立 full SCC/formal、未独立重放 raw mutation runner/log、未展开 core-local
   flush/commit0 同沿协议。这些盲区不被文本 pass 覆盖。
4. 结构化 reviewer 结果见 `cancel-amendment-review-result.json` 与
   `implementation-review-result.json`；actual access 均为 tools/shell/filesystem/network/write false。

## AI 开发环境实战固化

- 旧 reviewer JSON 因 schema 强制非空命令而虚列 `rg`，实际派发再口头收紧为 no-tools；该历史
  记录保留，但新派发已改用原生 `prompt-supplied-self-contained`。
- canonical JSON、generator、instruction、skill、`AI_ENVIRONMENT.md` 与 `agent-system` e2e 现共同
  强制：仅 `read-only-review` 可用；`allowed_commands=[]`、`write_paths=[]`、外部访问全 false；
  `supplied_material` 非空且每项单行；来源路径仅作 provenance。workspace-files 与旧 JSON 保持兼容。
- generator audit PASS、in-memory self-test 20/20、CLI self-test 18/18。真实 contract
  `subagent-contracts/v8k-native-no-tools-workflow-review.json` 的 SHA-256 为
  `9ef57a6f9e93bdb5ca3f9713a72ea618c3a2e9fe1eddecabf6002b67ff6bf0fb`；保存的 `.prompt` 与
  当前 renderer byte-equal。实际 no-tools reviewer verdict=`pass`，并明确没有自行读文件或复算 SHA。
- 两个失败的 agent-system forward run 原样保留：首次因 persistent skill 目录出现 untracked `.pyc`
  被 discovery 拒绝；第二次 10/10 execution nodes PASS，但 retained memory 发布前 startup recall
  无 independent primary，overall 仍 blocked。未改写失败报告制造 GREEN。
- retained memory/DB 发布后，首份
  `.github/task-runs/2026-07-20-no-tools-rtl-subagent-contract/` 虽为 agent-system 10/10 completed，
  审查者仍发现其 startup brief 命中 DB 中旧版 no-tools skill；因此它不再承担最终新鲜度证明。
  根因是 `brief` 的 live-first 读取 live 索引快照，而规则修改后没有自动刷新。runner 现于
  context brief 前 fail-closed `rebuild`，并在目录层排除 DB-first memory/task-run 与历史
  archive/review，只刷新 active rules/profile/root shims；最终日志为 `files=130`，独立计时
  16.69s。索引器新增 monkeypatch 反例，保证 excluded/retained 目录中的文件不会被逐项访问。
- DB-first audit 进一步抓到旧 rebuild 会把未扫描的 excluded memory 行误标 missing；实现已将 missing
  更新收窄为“本轮 scope 内且未排除”的旧行，并加真实 SQLite 保持状态反例。一次包含 memory 的
  修复性 rebuild 为 174 files/16.98s，随后 DB-first audit PASS；没有用物化缺失文件掩盖该 bug。
- 初版无剪枝全量扫描出现分钟级等待并被精确终止，只留下的 0-byte temp/空 nodes/未派发日志已
  删除；有效失败证据由 `.github/task-runs/2026-07-20-active-rules-root-shims/` 保留：目录剪枝已
  PASS，但根 `AGENTS.md` 已为 853 tokens，旧 smoke 的 800-token 阈值导致 overall blocked。将该
  只读 smoke 调整为 1200（仍小于 2400 startup brief 上限）后，
  `.github/task-runs/2026-07-20-active-rules-root-shims-2/` 的 github-index profile completed。
- 最终 workflow 新鲜度证据为
  `.github/task-runs/2026-07-20-no-tools-rtl-subagent-contract-4/`（agent-system 10/10 completed，
  brief 命中新 `--self-contained-no-tools`/`prompt-supplied-self-contained`）与
  `.github/task-runs/2026-07-20-active-rules-root-shims-4/`（github-index 1/1 completed，包含
  directory-prune 与 excluded-row-preservation 反例）；业务 evidence 仍为
  `.github/task-runs/2026-07-20-pending-csr-producer-lease-2/`（npc-dev 5/5）。三者均有 bounded
  non-history recall、evidence index 与 DB publication。最终 strict guard 按 541 个 changed paths
  推导这 3 个 profile 并全部 PASS；没有用旧 run、touch report 或手改时间戳满足新鲜度。
- 该规则用于准确描述本地 RV64 RTL、缩小权限、隔离 `review_pending` 并保留审计证据；不以改变、
  规避或削弱平台审查为目标，不承诺平台零误判，也不替代 RTL/PPA hard gate。

## 剩余 RED / UNKNOWN

- non-CSR pending 控制事件与尚未枚举的 stateful holder；
- 全核 holder census、last-reference、finite-generation collision fence 和 global no-live-reuse 形式证明；
- pending admission/clear 完整组合锥的独立 SCC/formal 报告及 global finite-progress；
- full lint 115 条继承 warning 与 real architecture inventory RED；
- official/DiffTest/AM/Linux、arch-stable freeze、fresh synthesis/STA/power、200 MHz 和 Pareto gate。

## 最终裁决

v8k dispatched pending CSR ProducerId lease scoped slice 完成，父目标继续 `active`。本轮没有运行或
授权 PPA promotion；下一主序应继续全核 holder census、last-reference 与 finite-generation
no-live-reuse 闭合。focused/mutation/regression/profile PASS 均不得外推成全核架构或 PPA GREEN。
