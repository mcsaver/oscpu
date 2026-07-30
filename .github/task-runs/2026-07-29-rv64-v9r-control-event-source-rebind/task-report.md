# RV64 CONTROL-EVENT-G1 current-source rebind report

## 状态

`BOUNDED_COMPLETE`。

本轮只闭合当前 design-id 上的 V9R SQ-query retry C0 验证源重绑、
CONTROL-EVENT-G1 evidence publication/currentness 与 postflight receipt。
production RTL 没有修改。

当前 design-id：

`sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`

## RTL transaction 证据

- `OooIntBackend.v` 与 `OooMemAxiBridge.v` 的 pre/post SHA-256 未变。
- C0 edge-old full-flush barrier 阻断两路 SQ-query retry-ready/capture/fire，
  owner 在 barrier 周期保持；撤销后才完成 handoff。
- V9R baseline 为 2/2 PASS。
- bank0、bank1、bridge 三个 compile-success RTL 负向版本分别由
  `@18`、`@39`、`@24` 的 raw assertion marker 拒绝，3/3 PASS。
- V9O evidence-index 为 167/167 PASS，verification-id 为
  `sha256:5e8107e641f459131fc86220a84ef206870ebc773cc6931ecc65921d8b1c4a92`。

## 证据发布器 root cause 与修复

v1 独立审查发现三个不同的假绿入口：

1. publisher 只运行 SERIALIZE canonical verifier，没有逐项校验 ledger
   `entry.evidence` 的 candidate/contract/review tuple；
2. currentness auditor 对该 tuple 采用广义非 JSON 例外，却没有先验证
   tuple identity；
3. postflight 只读取 V9R/currentness JSON，未消费 48 项与 task-local
   unittest 的返回码和 terminal marker。

修复后：

- canonical verifier 导出唯一、按顺序、带固定 SHA-256 的三元组；
- publisher 与 auditor 在重写任何 hash 前先做 exact tuple 比较；
- missing、extra、remapped 三类 fixture 均 fail closed；
- postflight 在校验开始时先撤销旧 PASS，只在 48/48、4/4、20/20、
  V9O index 与 SERIALIZE verifier 的 `.rc=0` 和精确 marker 全部通过后
  发布 PASS；
- stale runner 不再包含第二份绕过 receipt 的 inline postflight。

## Bounded replay

attempt 20 从 `control-event-gap-boundary` 开始，没有重跑 rootfs：

- V10C stage-order negative contract：3/3 rejected；
- GAP boundary、V9O index build/verify、ledger publisher、closed evidence
  currentness：全部 PASS；
- closed debt currentness：
  `16 entries / 38 artifacts / 32 canonical semantic checks / 0 failures`；
- `test_arch_stable_freeze`：48/48 PASS；
- `test_historical_defect_backfill`：4/4 PASS；
- task-local publisher/auditor/postflight fixtures：20/20 PASS；
- SERIALIZE verifier：
  `raw_c0_c1_c2=PASS c2_negative=2/2 system=3/3+14/14 replay=26/26`。

attempt 19 因外层 5 秒命令超时在 publisher 开始处被中断，未遗留工程
进程；其 RUNNING status 与 partial driver 保留，不被 attempt 20 覆盖。

## A3 系统事务边界

- A3 原始 published state 保持 `FAIL rc=1`，没有篡改历史。
- execution、DUT terminal、binding、raw input 与 RTL assertion 分别为
  `COMPLETE / COMPLETE / NO_DRIFT / VALID / CLEAN`。
- 唯一旧 oracle 失败是把 `printk: debug:` 误判为 critical；冻结 dmesg/
  console 重放与正负向单测证明新 checker 接受该行并拒绝真正的 `BUG:`。
- 本轮没有 production core RTL 语义变化、当前配置的 actual elaborated
  RTL 变化、device model/simulator execution semantics 变化，也不缺 A3
  原始输入、terminal chain 或 post-hash，因此不要求完整系统重跑。

## 独立审查

- v1：`GAP`，准确发现 exact tuple、receipt 与 bridge TB 合同缺口。
- v2：`APPROVED_FOR_CURRENT_SCOPE`，确认 production RTL 不变、V9R
  2/2+3/3、V9O 167、currentness 16/38/32/0、SERIALIZE exact tuple、
  48/4/20 receipt 与 A3 原始边界均有效。

## 当前硬门

- historical backfill 当前为 `VD0=0 / VD1=0 / selected=NONE`；
- 全局 architecture freeze 仍有 33 个 blocker，状态为 `GAP`；
- PPA 为 `UNQUALIFIED`；
- `promotion_eligible=false`。

因此本轮 PASS 只表示 current-source/evidence-workflow 子范围闭合，不表示
完整 OoO 核已 `ARCH_STABLE`，也不授权综合、STA 或 PPA 晋级。

## AI workflow 证据

- 三份稳定记忆通过 DB-owned `load/update-stored/materialize` 发布，并由
  `snapshot-stored` 生成可重灌快照。
- `npc-dev` bounded brief 以
  `RV64 SQ-query retry current-source contract` 命中独立 NPC memory；
  e2e task-run
  `2026-07-29-rv64-sq-query-retry-current-source-contract-v9r-final` 为 completed，
  5/5 节点 PASS。
- `agent-system` 首次 brief 因规则只存在于该 profile 自己的 module
  memory 而诚实返回 `no independent primary focus match`。随后把通用
  schema-aware publisher/receipt contract 写入
  `.github/agentic-hardware-blueprint.md`；同词 non-history brief 完整命中，
  e2e task-run
  `2026-07-29-schema-aware-rtl-evidence-publication-receipt-closure-final` 为
  completed，11/11 节点 PASS。没有放宽 recall gate，也没有把首次失败
  追认为完成。
- strict guard 显式绑定上述两份 completed publication 后通过：
  `agent-system` 覆盖 blueprint/agent memory，`npc-dev` 覆盖 RV64 debt
  ledger、historical ledger 与 arch-stable tests。
- DB-first audit 在刷新本轮三个 memory snapshot 后只保留 8 个既有历史
  task-run `missing_backup`；本轮 `agent-system.md`/`npc.md` 不再有
  `backup_hash_mismatch`。因此记录为全局归档 GAP，不改写成 PASS，也不
  影响本轮 RTL current-source 子范围的验证结论。

## Git 边界

工作树包含大规模 mixed-origin 既有改动。本轮只记录 scoped diff，不执行
reset、restore、clean、stash、amend、commit 或 push；是否形成原子 commit
需在独立工作树边界审计后再决定。
