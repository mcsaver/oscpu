# v8r/F1 双 memory bridge wrapper 派发记录

## 2026-07-20 合同审查

- 首个本地 RTL 限定材料 reviewer 节点被平台中断；该节点只记为 `review_pending/interrupted`，长期 RV64 OoO/PPA 父目标保持 `active`，没有改写技术语义重试。
- retry reviewer 返回 B1–B5 gap；B1–B4 已转成 DMA/MMU 同拍排序、逐 entry valid 合并、规范化 wstrb/跨线公式和 reset 边界，B5 保留 execution evidence gate。
- 合同复审 JSON：`.github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/subagent-contracts/v8r-dual-memory-bridge-contract-rereview.json`
- 合同复审 JSON SHA-256：`446bb02af4bcd5ebdc5f95e0fe19f676def4691b81eead25eee00c0d7d0cdaad`（只绑定该 JSON）。
- 结果：限定材料复审 `pass`；B1–B4 contractually sufficient，B5 execution-pending。

## 2026-07-20 本地实现与执行

- 主任务在本地单进程 WSL shell 中完成 RTL、TB、checker、10 族 mutation 和永久 runner；未向子 agent 授予 shell、文件写入或外部访问。
- fresh evidence：`run_id=v8r-f1-20260720T052716Z-935556`，`source_closure_sha256=05743bcd448bae5da16110a5a0a8644e74de87fde8bf6047b324c904eb1cfc18`。
- `make -C npc/rv64 check-dual-memory-bridge-wrapper`：PASS；只授权叶级 `dual_bridge_cache_hit_leaf_verified`，canonical core 未接入，DI-5/OOO-3/overall RED，PPA UNQUALIFIED。
- 执行中纠正两类假绿：全局 holder census 漏登记第二 memory reservation P/token；`swap_peer_addr` mutation 因 self payload 同值未被检出。两者均在门禁层修正并 fresh 重跑。

## 2026-07-20 实现复审派发

- 工程领域：本地 RV64 Verilog/SystemVerilog 数字电路实现与验证证据的限定材料复核。
- 合同 JSON：`.github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/subagent-contracts/v8r-dual-memory-bridge-implementation-review.json`
- 合同 JSON SHA-256：`3c20605c0a004b364b0e218271aa977e1f16ef07ff43e83c74f0a110bf757fe7`（只绑定该 JSON，不绑定设计 contract/spec/RTL/evidence）。
- 实际权限：`allowed_commands=[]`、`write_paths=[]`，无工具、无 shell、无文件访问、无网络、无账号、无凭据、无外部服务。
- 结果：`pass`，`remaining_blockers=[]`，置信度 `moderate_high`；reviewer 明确不声称完整仓库审计或哈希复算。
- 审查结论：fresh closure 与十项 mutation 足以授予唯一未集成叶级 claim；定向测试非形式穷尽、未来双 B、same-lane own-miss、canonical integration、IPC 与 PPA 均保留为边界。
- 父目标状态：`active`；复审结果只关闭当前 F1 实现复审节点。

## 2026-07-20 工作流 e2e 与 strict guard

- final `agent-system` completed：`.github/task-runs/2026-07-20-rtl-contract-mutation-evidence-revtag-v8r/`（在最终 memory 回写后 fresh 重跑）。
- `github-index` completed：`.github/task-runs/2026-07-20-stored-memory-evidence-index-revtag-v8r-github-index/`。
- 首两个 `npc-dev` 尝试分别为 `...rv64-dual-memory-bridge-cache-hit-revtag-v8r-npc-dev/` 与 `...peer-maintenance-revtag-v8r-npc-dev/`；五个执行节点均 PASS，但 startup brief 把重复的 `npc dev` 视为检索词，找不到 independent primary focus，因此 run 正确保持 `blocked`。
- 修正只作用于任务身份：profile 继续由 `--profile npc-dev` 绑定，slug 改为稳定业务词 `peer-maintenance-revtag-v8r`；受控 `revtag-v8r` 被 lifecycle 过滤后只留下 `peer maintenance`，startup recall complete，最终 run completed。
- strict guard 对当前工作树要求 `agent-system`、`npc-dev`、`github-index` 三项，最终全部 PASS。失败 run 原样保留；没有手改状态、降低 recall 门或让节点 PASS 覆盖召回失败。
