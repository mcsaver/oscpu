# RV64 v8j branch-resolve ProducerId 授权闭合报告

## 基本信息

- `task_id`: `2026-07-19-rv64-v8j-branch-resolve-producer-authorization`
- `task_class`: `architecture_closure_without_ppa_promotion`
- `slice_status`: `scoped_completed`
- `parent_goal_state`: `active`
- `promotion_eligible`: `false`

本报告只签收 registered branch-resolve carrier 的 full ProducerId 持有、ROB exact-open 查询、
raw EX0 coherence 和 redirect/ROB walk/BPU/selective-kill 的 actual capability。pending-system/CSR、
完整 holder census、finite-generation global no-live-reuse、全核架构 hard gate、系统级验证和 PPA
均不在本地 GREEN 内。

## 实现者结论

- `OooIntBackend.u_branch_resolve_stage` 保存完整 `P={generation, rob_idx}`；对外 raw ROB boundary
  仅由 P 的低位投影。candidate 在 reset、flush、checkpoint restore 上 fail-closed。
- `OooDispatchBackend` 只代理专用 resolve query；`OooRob` 以 edge-old
  `valid && !done && exact full PID && !recover_q` 判定 open。该 query 不读取同拍
  `kill_valid_i`，也不进入 ready、issue、transport 或 credit。
- 生产态 coherence 只允许读取 raw registered `ex0_valid_q/ex0_producer_id_q`，禁止借用
  completion-open、killed-now、WB-valid 或其他 semantic valid。只有
  `candidate && resolve_open && raw_ex0_coherent` 能产生 resolve、mispredict、redirect、ROB walk、
  BPU update 和 selective kill；stale/raw-index alias 只能物理排空，不能取得控制副作用能力。
- current branch mispredict 的 self-kill 不反向关闭 boundary P；reset/flush/checkpoint、prior recovery、
  vacant、done、generation mismatch 和 raw EX0 mismatch 均静默拒绝。
- 实现期间定位到既有 `producer_target_killed_now` 的仿真敏感性根因：函数体隐式读取全局
  head/kill/recovery，并行调用还共享临时状态。函数现为 `automatic`，六项依赖均通过显式实参
  进入调用表达式；同一 PID 下 kill 置位再撤销的定向测试证明组合结果会重新打开。

## 功能与静态硬门

| gate | 结果 | 证据 |
|---|---:|---|
| source-bound structural audit | 16/16 PASS | `evidence/static/structural-audit.log` |
| focused release | 3/3 PASS | `evidence/focused-run/baseline-release/summary.txt` |
| focused `OOO_ASSERT` | 3/3 PASS | `evidence/focused-run/baseline-assert/summary.txt` |
| compile-success semantic mutation | 12/12 命中 | `evidence/focused-run/mutation-summary.tsv` |
| focused source pre/post hash | byte-equal | `evidence/focused-run/sources.pre.sha256`、`sources.post.sha256` |
| legacy focused regression | v8d/v8f/v8g/v8h/v8i release+assert，10/10 PASS | `evidence/regression/summary.md` |
| module aggregate | 105/105 PASS | `evidence/regression/module-aggregate/summary.txt` |
| regression source pre/post hash | byte-equal | `evidence/regression/sources.pre.sha256`、`sources.post.sha256` |
| RTL style / contract | PASS；assertions 366 >= 89 | `evidence/static/check-rtl-style.log`、`check-contract.log` |
| architecture checker self-test | 15/15 PASS | `evidence/static/architecture-hard-gates.log` |
| real architecture inventory | `OVERALL: RED`，预期 rc=2 | `evidence/static/architecture-hard-gates.json` |
| strict lint regression | inherited rc=2、115 warnings；normalized SHA 与 v8i byte-equal | `evidence/static/full-lint.status` |

12 个 mutation 覆盖 carrier generation 损坏、授权绕过 query/raw EX0、semantic-valid 反馈、
public candidate 泄漏、checkpoint fence 删除、raw projection 损坏、ROB query 绕过 generation/done/
recovery、query 读取 current kill，以及 killed-now 隐式依赖残留。lint 非零没有被豁免；这里只
证明继承 warning 集合没有新增。

## 审查者反例与处置

1. 合同 reviewer 首轮 verdict 为 `gap`：EX0 coherence 的信号类别未锁死，可能经 completion
   semantic valid 把 self-kill 反馈接回 capability。合同和 RTL 已冻结为 raw registered EX0-only，
   并增加 structural audit、semantic-valid mutation 与 live self-mispredict exactly-once 定向测试。
2. 实现 reviewer 最终 verdict=`pass`、blocker=0。它确认 scoped 合同内 stale generation、death
   edge、self-kill 和 production fail-closed 处置一致，但不替代本地主 agent 的验证。
3. reviewer 明确保留三项证据盲区：没有 elaborated-netlist SCC/formal loop 报告；未独立复跑
   原始日志、mutation patch 或波形；未来若新增独立同拍 older-kill，现有“忽略 current kill”
   前提必须重冻并重新审查。
4. 若 flush/checkpoint 未来成为 capability 的组合后代，或 `kill_valid_i` 不再唯一来自当前
   authorized mispredict，本轮无环结论自动失效，不能沿用本报告签收。

## AI 开发环境实战固化

- 两个 reviewer 节点均使用仓库内可发现的 RTL task-contract 工作流生成、校验并渲染 JSON。
  合同 reviewer JSON SHA-256 为
  `70355b973f0b4c11b770d281ea8b5f213e868413d49e93c9809fa857a2bb8e31`；实现 reviewer
  JSON SHA-256 为
  `a17c811e3c338a025a78d0f953515f343225deaf3586c67264164e46fbb35ea0`。每个 SHA 只绑定其
  对应 JSON，不冒充 RTL/spec/验证绑定。
- 派发正文先声明“本地 RV64 Verilog/SystemVerilog 数字电路设计与验证”，再给出指定路径、
  只读/可写边界、允许命令和成功条件；只读复核明确不改文件、不联网、不访问账号、凭据或
  外部服务。Windows→WSL 工程命令仍由主 agent single-flight 执行。
- reviewer 实际权限进一步收紧为 no tools/no shell，只消费自包含冻结摘要；单个 reviewer 若
  暂时受阻，只把当前 review 节点记为 `review_pending`，不自动停止或关闭长期 RTL/PPA 父目标。
- 反例必须进入 contract/spec/TB/assertion/mutation/audit；未闭合项进入 evidence blind spot 或
  remaining RED。该机制用于减少任务歧义和建立最小权限审计链，不以规避或削弱平台检查为
  目标，也不承诺平台零误判。
- retained project/NPC memory 先进入 DB，再以 `npc-dev`、`focus-scope=non-history` 运行 bounded
  brief；当前事实完整召回为 1959/2400 tokens。task-specific
  `.github/task-runs/2026-07-20-rv64-branch-resolve-producer-authorization/` 5/5 节点 completed、
  publication-valid，且没有 FAIL/blocked marker。DB-first audit、Markdown coverage 与 stored
  snapshot 均 PASS。
- 最终 strict guard 根据共享工作树 367 个 changed path 推导 `agent-system + npc-dev`：既有
  reviewer-contract run 覆盖 workflow 源，本轮 task-specific run 覆盖 NPC 路径，两项均 PASS。
  这些 profile 只证明协作/入口合同可发现、可执行、可审计，不替代本报告的 RTL 业务 gate。

## 剩余 RED / UNKNOWN

- pending-system/CSR 及其他尚未闭合的 ProducerId holder/actual-valid 控制锥；
- 全核 holder census、finite-generation collision fence 与 global no-live-reuse 形式证明；
- branch capability 的 elaborated-netlist SCC/formal loop 独立报告，以及未来多 kill-source 仲裁；
- redirect/BPU/ROB-walk 关键路径的 fresh synthesis/STA；
- real architecture inventory、strict lint 115 条继承 warning；
- official/DiffTest/AM/Linux、arch-stable freeze、fresh synthesis/STA/power、200 MHz 与 Pareto gate。

## 最终裁决

v8j branch-resolve ProducerId authorization scoped slice 完成，父目标继续 `active`。本轮没有运行
或授权 PPA promotion；下一主序应关闭 pending-system/CSR ProducerId ownership，再继续全核 holder
census 与 global last-reference/no-live-reuse。在这些架构硬门完成前，所有 PPA 声明保持
unqualified；focused/mutation/regression PASS 不能外推为全核正确性或架构 promotion。
