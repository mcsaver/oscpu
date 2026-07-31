# V11S evidence map

| 声明 | 主证据 | 绑定 |
|---|---|---|
| production RTL 无本轮变化 | `final-static-gates-attempt-1.stdout.log` | `OooIntBackend.v=49ec3d7e…`、`OooMulDivUnit.v=c28ad0cf…`、`define.v=1ce15fae…` |
| request/hold/completion/release/flush baseline | `evidence/focused-attempt-4/summary.json` | 4/4 baseline，generation width 1/4，assert/release |
| semantic sensitivity | 同上 `profiles/` 与 `variants/` | 9 类 compile-success variant × 2 width，18/18 exact-stage rejection |
| ordinary regression | 同上 `regressions/` | 4/4，source pre/post match |
| runner 自检 | `evidence/self-test-attempt-6/` 与 final static log | 10/10 |
| current holder topology | `evidence/current-instance-graph-rebind-attempt-1/holder-instance-graph.json` | 15 modules、17 instances、2 duplicates、194 reachable |
| frozen graph audit | `evidence/current-instance-graph-rebind-attempt-1/instance-graph-frozen-audit.json` | PASS，design/source/Yosys artifact binding |
| semantic ledger | `evidence/ledger-attempt-9/producer-holder-semantic-coverage.json` | 44 units、50 bindings、35 PASS / 9 GAP |
| live ledger materialization | `evidence/materialize-ledger-attempt-3/` | byte-exact SHA `80d50ba8…944` |
| graph/census/replay/semantic aggregate | `evidence/combined-semantic-gate-attempt-3/` | graph 19/19、census 15/15、replay+semantic 91/91、rc=0 |
| V11H replacement checker binding | `evidence/v11h-checker-replay-after-graph-attempt-9-receipt.json` | SHA `3a405dd3…833` |
| independent review | `final-review-result.md`、review contract | bounded PASS、blocker=0 |
| A3 immutable original result | A3 source task-run | FAIL rc=1、strict 16/17，未改写 |
| A3 versioned replay | `../2026-07-28-rv64-v10f-a3-checker-replay-v2/checker-replay-v2-evidence.json` | SHA `5274b0d6…af8`，debug fixture accept / real BUG fixture reject |
| memory recall | `brief-post-memory.json` | complete，8 chunks，token estimate 1,523 |
| environment e2e | `../2026-07-31-OooMulDivUnit-producer-lifecycle-revtag-v11s/` | `npc-dev` completed 5/5，publication valid |
| scoped strict guard | `scoped-strict-guard-attempt-1.stdout.log` | 16 paths，PASS |
| full-worktree strict guard | `full-worktree-strict-guard-attempt-1.stdout.log` | FAIL only for out-of-scope `amo.c → nemu-dev` |
| final static identity gate | `final-static-gates-attempt-1.stdout.log` | PASS rc=0 |
| task document publication | `task-doc-publish-attempt-1.status` | stored document materialize/cmp PASS |
| DB-first audit | `audit-db-first-attempt-1.log` | candidates 8,117、stored 8,159、shims 116，PASS |
| Markdown coverage | `audit-markdown-coverage-attempt-1.log` | `live_evidence=0`，PASS |
| runtime artifact audit | `artifact-audit-global-attempt-1.log` | tracked heavy files 0，PASS |

大型 `.vvp`、Yosys full JSON gzip 与仿真日志按 raw evidence
`INDEX_ONLY` 处理；长期 Markdown、JSON receipt 与 memory 使用 DB-backed
stored document 协议。
