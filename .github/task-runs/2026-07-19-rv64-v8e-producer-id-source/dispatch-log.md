# Dispatch log

| phase | status | evidence |
|---|---|---|
| bounded recall | PASS | `brief rv64 producer identity generation --profile npc-dev --focus-scope non-history` |
| contract freeze | PASS | `contract.md` |
| ROB source mapping | PASS | canonical allocation/head/tail/recovery call chain inspected |
| carrier mapping | PASS | future 64P-bit conservative holder footprint and AUTH remainder bounded |
| implementation | PASS | 4+4 per-slot source、7 ROB carrier、parent/leaf reset-flush ready fail-closed；`tb_ooo_rob` 与 `tb_ooo_dispatch_backend` 非真空覆盖 |
| independent counterexample review | PASS after correction | 首轮发现 reset/flush 伪接受、real-walk/runner 证据洞；修复后 15→0 walk reuse、依赖 SHA、raw witness copy、13/13 mutation 闭合；复核裁决 scoped blocker=0 |
| broader verification | PASS/known RED split | focused 6/6、module 104/104、style/contract/diff PASS；strict lint 115 条历史签名继续 RED |
| DB recall | FAIL then PASS | slug `rv64-v8e-producer-id-source-e2e` 无 independent primary focus，fail-closed 保留；retained memory update 后 `brief rv64 producer identity generation` complete 2001/2400 |
| profile | PASS | `npc-dev/rv64-producer-identity-generation` 5/5 nodes completed；首轮 blocked run 未删除 |
| record | PASS | 185 个本轮普通 evidence asset 已索引，顶层 marker 作为闭包元数据单列；stored snapshot、doctor、DB-first、Markdown coverage 均 PASS；strict guard 首次按时间边界要求新证据，最终 retained-memory 同步后补跑 `agent-system/agent-rtl-3` 与 `npc-dev/rv64-producer-identity-generation-3`，连同 `github-index/slug-recall-3` 三 profile PASS |
