# v8t/F3 final-PA SQ ordering checkpoint 任务报告

## 基本信息

- `task_id`: `rv64-v8t-final-pa-sq-query`
- `task_slug`: `rv64-v8t-final-pa-sq-query`
- `graph_template`: `architecture-first + executable-counterexample + workspace-review`
- `graph_mode`: `static+dynamic+bounded-exhaustive`
- `status`: `completed`（仅指 F3 checkpoint）
- `owner`: `primary Codex agent`
- `updated_at`: `2026-07-20T13:53:51+00:00`

## 目标与声明边界

- `goal`: 在 canonical dual-memory 路径上，以 final physical byte address 对两路 ordinary load
  做 SQ allow/forward/replay；建立每 bank exact retry holder，闭合 capture/hold/reissue/cancel、
  same-bank older-store progress、bank-local identity、fault/late response 和 int/FP sink。
- `authorized_claim`: `final_pa_sq_ordering_checkpoint`
- `out_of_scope`: F4 sustained IPC、完整 load-violation recovery、Linux/full-system、CDC/reset/formal
  signoff、equal-capacity cache banking与正式 synthesis/STA/power/Pareto promotion。
- `architecture`: DI-5 RED、OOO-3 RED、overall RED。
- `ppa`: `UNQUALIFIED`; `promotion_eligible=false`。

## 实现与验证闭包

- `OooStoreQueue`: 两套 final-PA physical-byte CAM；逐 byte youngest-older 合并；unfilled/invalid/
  partial/IO fail-closed replay；ROB wrap 和 same-age/different-generation 语义。
- `OooMemAxiBridge`: bare/DTLB-hit/PTW-leaf/A-D 路径汇合 `S_SQ_QUERY`；forward capture、retry hold、
  pre-query fault 与 killed late response 不产生 SQ query side effect。
- `OooIntBackend`: bank0/bank1 retry holder 保存 full ProducerId、token/epoch、destination domain 与
  MIQ payload；cancel 优先；terminal lane10/11；older store 仲裁；holder/active/station load fence；
  int/FP response sink 保真。
- `directed profiles`: 10 个 release/assert profile + 1 个 X-metadata assertion-negative。
- `mutation`: 38/38 compile+elaborate+activated+static-target-rejected；37/37 要求动态拒绝，唯一
  `legacy_all_load_block` 按合同为 static-only `not_required`。
- `holder proof`: 每 bank 8192 个 Boolean control vectors、25 个双 bank action pairs、729 个
  depth-6 conditional-progress schedules，`counterexamples=[]`；proof binding 5/5、checker 23/23、
  mutator 2/2、checkpoint finalizer 7/7。
- `predecessors`: F0/F1/F2 fresh PASS；F2 checker 新增正式 F3 claim marker 与 unknown-state
  negative，15/15 单测 PASS。

## Fresh candidate 与不可变 checkpoint

- `candidate_run_id`: `v8t-f3-20260720T133351Z-1183319`
- `functional_source_closure_sha256`:
  `0be0d3ee3424ee816fe11d0176f2fc5e71849e24bedb764025f4e2dcc8212063`
- `candidate_result_sha256`:
  `030047748ddb9b75bb18e8be2cc164bbc576752d038682c8109c342ee40b8a0a`
- `mutation_summary_sha256`:
  `71c3b1812387bf8f8be68a572b9cb491177c00d66105d5ca02a8175466399af6`
- `immutable_candidate_snapshot`:
  `evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/`
- `review_result`: `implementation-review-result.json`, SHA-256
  `e5e80469184a5ba771dd487cb2eaa15d1bb88c81bd98d0fcda631c5a5c5a788e`
- `checkpoint_result`: `checkpoint-result.json`, SHA-256
  `9977ea25427c976462ed2e88e2f92ad60fd458f8958d410abad41770ecf3f484`
- canonical marker:
  `[V8T-F3-CHECKPOINT][PASS] ... checkpoint_eligible=true reviewer=PASS promotion_eligible=false`

## 实现者 / 审查者对抗

- `实现者`: 先关闭 v1-v3 contract 反例，再补双 bank directed、38 mutation 与 bounded holder
  proof；runner 始终 fail-closed 保持 candidate，直到独立 review overlay 完整。
- `审查者 v2`: 未发现 P0 RTL 反例，但发现 reviewer 合同把结果路径写错，无法绑定 fresh evidence。
- `审查者 v3`: 实际 evidence path 补齐后，对早期 closure PASS；随后 finalizer 成为新 functional
  source，该回执不被追认为最终授权。
- `审查者 v4`: 直接用正向单测复现 stale/wrong-run overlay fail-open，给出 P1 GAP。
- `实现者修复`: two-phase candidate/promotion；精确校验 run-id、closure、candidate result SHA、
  mutation summary SHA、contract SHA；promotion output 禁止覆盖 candidate。
- `审查者 v5`: `PASS`; `unresolved P0/P1 = none`; 只授权 F3 checkpoint。

## AI 开发环境实战纠偏

- 所有 v2-v5 子任务均由 `prepare-rtl-task-contract` 的 canonical
  `create -> validate -> render` 生成，正文只使用 RV64、RTL、流水线、事务、时序、验证与 PPA
  专业术语；真实 RTL 标识符原样保留。
- 措辞层没有降低 reviewer 能力：同一 reviewer 连续发现证据路径错误和 stale-run 授权问题，
  并可自由返回 GAP、P0/P1、替代设计与 scope extension。
- 权限仍由 JSON 合同独立控制：workspace review 只读、限定路径、无网络/账号/凭据/外部服务；
  wording profile 不改变工具、路径、写权限或推理自由。
- 一次 pre-dispatch validate/render 并发误用未进入正式派发；随后按 WSL single-flight 顺序重跑，
  并在 `dispatch-log.md` 保留过程纠偏。
- bounded startup brief 已分别以 `npc-dev`、`agent-system`、`github-index` 从 non-history
  retained memory 召回本轮 F3、RTL 合同与 checkpoint evidence；三个 task-specific profile
  均完成且 publication-valid。
- `snapshot-stored`、`audit-db-first`、本 task-run 的 558 项 raw evidence 索引以及最终
  `scripts/agent-e2e.sh --guard --guard-mode strict` 均 PASS；strict guard 根据 1258 个共享工作树
  changed paths 精确要求并命中上述三个 profile。

## 当前剩余项

- `F4`: 64-cycle IPC>=1.90、系统 workload、同 design-id aggregate、必要 DiffTest/Linux。
- `architecture`: 关闭 DI-5/OOO-3/overall 的其余 P0/P1 与全核 owner/recovery/system evidence。
- `PPA`: 先做等总容量 bank 和 arch-stable freeze；在此之前只能 diagnostic，不能 promotion。

## 收尾结论

- `final_result`: `final_pa_sq_ordering_checkpoint`
- `checkpoint_eligible`: `true`
- `unresolved_p0_p1`: `none`
- `promotion_eligible`: `false`
- `parent_goal`: `active`

F3 切片已经闭合；长期 OoO/PPA 目标未完成也未受阻，下一阶段进入 F4/系统证据与稳定基线准备。
