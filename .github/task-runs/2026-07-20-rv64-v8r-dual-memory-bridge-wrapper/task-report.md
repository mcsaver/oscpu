# v8r/F1 双 memory bridge/cache-hit wrapper 任务报告

## 基本信息

- `task_id`: `rv64-v8r-dual-memory-bridge-wrapper`
- `task_slug`: `rv64-dual-memory-bridge-cache-hit-leaf-revtag-v8r`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`（仅指本 F1 叶级切片）
- `owner`: `primary Codex agent`
- `started_at`: `2026-07-20T04:27:26+00:00`
- `updated_at`: `2026-07-20T05:43:20+00:00`

## 任务目标

- `source_request`: 在既定硬门约束下持续推进 RV64 双发射完整 OoO/PPA，并把有效架构、验证、证据和安全协作规则有机固化到工作区流程。
- `goal`: 在不接 canonical core 的前提下，建立两份完整 `OooMemAxiBridge`、私有 D-cache hot-hit 路径、cross-lane peer maintenance 与已验证 F0 AXI miss fabric 的可综合 F1 wrapper，并用可执行反例关闭合同缺口。
- `scope`: `OooDualMemBridgeWrapper`、`OooMemAxiBridge` peer boundary、`OooDataWordCache` peer invalidate、directed TB、checker、mutation、永久 Make 入口；不含第二 MIQ/final-PA SQ query/canonical integration/IPC/PPA。

## 选图说明

- `selected_template`: architecture-first RTL leaf + contract-review + focused evidence + independent review。
- `why_this_graph`: F1 跨 bridge/cache/F0，且触碰 handshake、flush、访存完成与同拍可见性，必须先冻结接口合同，再由 directed/mutation 门收口。
- `dynamic_nodes_added`: DMA/MMU 同拍排序、逐 entry valid merge、规范化 mask/cross-line、sampled reset、holder census 漏项修复、mutation 同值假绿修复。
- `why_dynamic_nodes_were_needed`: 首轮 reviewer 与真实 runner 分别发现合同缺口和两个可执行假绿，不能用原计划直接宣称通过。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall` | primary | completed | DB brief、AGENTS、RV64/agent workflow rules | bounded 约束与 F1 计划 | `contract.md`、`rtl-derivation.md` |
| `contract-review` | no-tools reviewer | completed | 冻结合同事实 | B1–B5 gap、修订、复审 pass | `contract-review-result.json`、`contract-review-resolution.md`、`contract-rereview-result.json` |
| `rtl-implement` | primary | completed | 修订合同、F0 leaf | wrapper/bridge/cache/checker/TB/filelist/Make target | `npc/rv64/vsrc/**`、`npc/rv64/testbench/**` |
| `focused-verify` | primary | completed | 同一 source closure | release/assert/negative、10 mutation、F0 regression、架构 RED | `evidence/focused/result.json` |
| `implementation-review` | no-tools reviewer | completed | 同摘要冻结证据 | pass、blockers=0、边界与剩余风险 | `implementation-review-result.json` |
| `record-workflow` | primary | completed | 真实失败与复审结果 | 永久入口、dispatch/task-run/memory/e2e 记录 | 本报告与 `dispatch-log.md` |

## RTL 推导摘要

- `需求`: 两个 lane 都保留自己的翻译/cache-hit/response 路径，只把 miss AXI 汇入 F0；任一授权 store terminal 必须同拍使 peer 的陈旧 line 不可见。
- `协议与状态机`: wrapper 无功能状态；每个 bridge 维持原 FSM，F0 维持 registered owner；maintenance 只由 `dcache_store_commit_w` 授权，MMU flush 只在双 idle 合法。
- `不变量`: cross wire 原样且无 ready/寄存；READY/response lane-local；peer 不占 SRAM owner；DMA > 逐 entry local merge > peer clear；exact peer lookup 同拍屏蔽；normalized wstrb 唯一决定两 line 集合。
- `数据通路`: `laneN request -> bridgeN TLB/D-cache -> hot response`，miss 才进入 `u_miss_arbiter`；`bridge0 maintenance -> cache1`，`bridge1 maintenance -> cache0`。

## 关键产物

- `artifacts`: `OooDualMemBridgeWrapper.v`、bridge/cache peer 边界、两个 directed TB、F1/F0 fail-closed checker、10 族 mutator、`check-dual-memory-bridge-wrapper` 永久入口。
- `logs_or_traces`: fresh run `v8r-f1-20260720T052716Z-935556`；closure `05743bcd448bae5da16110a5a0a8644e74de87fde8bf6047b324c904eb1cfc18`；wrapper/bridge/cache SHA 分别 `a92661bf…d0111364`、`e78cbdf5…2f7fd51`、`50ee1121…653c57d`。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/agent-system.md`（通过 DB retained-document 流程更新）。
- `subagent_contracts`: 合同复审 `446bb02af4bcd5ebdc5f95e0fe19f676def4691b81eead25eee00c0d7d0cdaad`；实现复审 `3c20605c0a004b364b0e218271aa977e1f16ef07ff43e83c74f0a110bf757fe7`。两者只绑定各自 JSON，均为 self-contained no-tools、无写入/网络/账号/凭据/外部服务。
- `workflow_e2e`: final `agent-system` run `.github/task-runs/2026-07-20-rtl-contract-mutation-evidence-revtag-v8r/`、`github-index` 与 `npc-dev` run `.github/task-runs/2026-07-20-peer-maintenance-revtag-v8r/` 均 completed；strict guard 三项全 PASS。两个把重复 profile 词写入 slug 的 recall-blocked run 原样保留，不改报告造绿。

## 验证结果

- F1/F0 checker unit：10/10 与 12/12 PASS；style、全局 interface contract、Verilator release/assert PASS。
- wrapper、D-cache、legacy bridge：release/assert 共 6 profile PASS。
- assertion-negative：非法 peer mask 与非 idle MMU flush 均非零、命中目标语义且未到 escape marker。
- mutation：10/10 compile-success、elaborated、activated、target-rejected；每项只有一个 V8R target marker 与一个 fatal，无 assertion 抢先。
- `make -C npc/rv64 check-dual-memory-fabric-foundation`：PASS；F0 checker只放行固定 F1 leaf instance。
- architecture checker：预期非零，DI-5/OOO-3/overall 均 RED；PPA UNQUALIFIED；architecture manifest 未改写。
- DB-first：四份 retained memory 回写/召回、`audit-db-first`、`audit-markdown-coverage --fail-on-live-evidence` PASS；本 task-run evidence index 已生成并归档。
- e2e/guard：`agent-system`、`github-index` 与最终 `npc-dev` 均 completed，`scripts/agent-e2e.sh --guard --guard-mode strict` 对当前 1074 个 changed paths 推导三 profile 并全部接受。

## 实现者 / 审查者对抗

- `实现者陈述`: 同一 closure 已覆盖双 hot response、双向 peer-miss 下 hot hit、B/lookup overlap、B error、cross-line、DMA、双 DTLB flush、sampled reset、default-off legacy 和十个定向 mutation，满足唯一叶级 claim。
- `审查者质疑`: directed/mutation 非形式穷尽；no-tools review 未复算哈希或查看原始日志；同值 payload 曾使 `swap_peer_addr` 假绿；census 曾漏登记第二 reservation；双 B、same-lane own-miss、canonical integration 与 PPA 均未证明。
- `冲突结论`: 同值假绿和 census 漏项均已转成可执行门并 fresh 重跑关闭；e2e 又以两个节点全 PASS 但 startup recall blocked 的失败包证明 profile 名不能重复污染 slug。形式完备性、未集成能力和 PPA 质疑未被本切片关闭，因此只授予 `dual_bridge_cache_hit_leaf_verified`，不升级父目标或架构状态。

## 当前阻塞点

- `blockers`: 本 F1 叶级无剩余 blocker；长期父目标仍有未实现节点。
- `missing_dependencies`: 第二 MIQ/并行 downstream owner 路径、final-PA SQ query、formal WB credit/canonical integration、完整功能/DI/OOO hard gate 和同源 PPA。
- `risk_assessment`: directed + mutation 不能替代形式证明；wrapper 当前未实例化，不产生性能收益，不能进入 Pareto/promotion。

## 下一步建议

1. 进入 F2：冻结并实现双 memory downstream admission/completion 与 final-PA SQ query，继续保持 full ProducerId/token owner 语义。
2. 在 canonical integration 前补双 B/双 completion 冲突合同、形式 WB credit 与 same-lane outstanding policy，再 fresh 重跑 DI-5/OOO-3。
3. 仅在完整同源 design-id 通过功能/DI/OOO/timing hard gates 后采集 synthesis/STA/power 并进入全局 Pareto。

## 模板升级候选

- `repeated_dynamic_subgraph`: contract gap → executable counterexample → compile-success mutation → same-closure aggregate → minimum-permission reviewer。
- `should_promote_to_static_template`: `yes`，现已由永久 Make target、contract skill、task-run/evidence 和 strict guard 入口共同固化。
- `reason`: F0/F1 连续实战证明该子图能发现同拍边界、陈旧证据、同值 mutation 假绿与审查状态误传播。

## 收尾结论

- `final_result`: `dual_bridge_cache_hit_leaf_verified`（仅未接 canonical core 的 F1 leaf）。
- `evidence_summary`: fresh focused run PASS；10/10 mutation；F0 regression PASS；独立限定材料 implementation review pass/blockers=0。
- `notes`: DI-5、OOO-3、overall 继续 RED，PPA UNQUALIFIED；长期 `/goal` 保持 active。
