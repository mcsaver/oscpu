# RV64 V13W producer/holder current-design rebind

## 结果

- 本轮没有修改 production RTL。当前 design-id 为
  `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`。
- current holder instance graph：15 modules、17 instances、2 个 duplicated modules。
  census：20 direct full-P、5 packed、15 token-q、1 generation authority、3 token-set
  holders，共 44 semantic units；6 个 unit 跨双实例，因此为 50 个 unit-instance bindings。
- canonical semantic ledger 为 44/44 local PASS。顶层状态仍为 `GAP`，whole architecture
  保持 RED，PPA 保持 UNPROMOTED；本轮不声明 full-system、CPI、综合、STA、area 或 power
  promotion。

## 根因与修改

- graph/census/semantic policy 曾把历史 task-run 路径和 design-id currentness 固化在
  checker 中。现由 census/policy 的 hash-bound evidence 指针选择当前 bundle；graph bundle
  五个角色必须来自同一合法 task-run evidence 目录，跨 run 拼接会 fail closed。
- V11F/V11G/V11H 的等价 RTL 表示已使旧 mutation anchor 过期。切点更新到当前 packed
  dispatch/onehot/qualified-hit/release-ready 表示，仍要求唯一 anchor、非 no-op、编译成功和
  定向动态拒绝。
- V11H checker replay v3 只绑定 attempt-4 冻结的 `OooLoadQueue` 与两个 TB 哈希，保留原始
  FAIL 并显式 `current_rtl_binding_claimed=false`。当前 LQ 由本轮 current-design 的 4
  positive、1 raw-Q knownness probe、31 mutation × `g1/g4` 证明。
- 新增 compile-image retirement 轮子与稳定 artifact-retirement index；历史固定 graph/replay
  路径从相关聚合入口移除。聚合 Make target 只读 index/summary/checker 输出。

## 验证

- `make -C npc/rv64 check-producer-holder-semantic-coverage`：返回 0；graph 21、census 16、
  checker/replay/retirement/semantic 129 tests PASS；ledger 为 units=44、instances=17、
  bindings=50、semantic_pass=44。
- `make -C npc/rv64 check-contract`：返回 0；`--assert`、`OOO_ASSERT` 与 immediate
  `$error` 计数合同 PASS，当前 508 ≥ 基线 89。
- 删除 `.vvp` 后重新生成 canonical ledger 仍为 44/44；489/489 retirement manifest entry
  在 retained JSON 中有 exact path/SHA reference，size 由 manifest 精确绑定，无 missing 或
  mismatch。110 个额外 VVP reference 属于 V11T/U/V 独立 cleanup receipt。
- V11H 31 个 mutation 均具有 `g1/g4` 两个 run；62/62 compile rc=0、simulation rc 非零、
  assertions disabled、negative stimulus enabled，并由 `[V11H-LQ-PRODUCER-ORACLE][FAIL]`
  marker 约束。

## 选择性压缩

- 当前 task-run 中 489 个可重建 `.vvp` 先记录 path/SHA/size，再删除，共释放
  3,233,104,756 bytes。RTL/TB、mutation source、compile/simulation log、JSON、SHA
  binding、result marker 均保留；这些 image 可由相同 runner 重建，未进入回收站。
- 17 个内容相同的 Yosys full-graph 逻辑路径按 SHA hardlink 为 4 个只读 inode，释放
  350,646,181 bytes。所有历史路径和唯一内容保留，mode 为 `0444`，未来消费前仍须复核 SHA。
- 删除两份无引用且字节相同的 pre-cleanup semantic ledger 副本、300 个空 build 目录和三个
  `__pycache__`；保留最终 post-cleanup ledger、result、log、marker 与审查材料。

## 双角色复核

- 合同：`subagent-contracts/v13w-frozen-delivery-review.json`，SHA-256
  `36f306bc1431ff4c877065948431d547e9361a75738e0418eb54e313013e4429`。
- reviewer 结论：44 个合同内 unit 为条件性 PASS；whole architecture/system/PPA 为 GAP。
  其 41→44→50、31→62、逐镜像引用和 hardlink 写耦合四项反例均已在
  `evidence/reviewer-counterexample-closure.json` 落成静态/自动审计；未把 reviewer 文本直接
  当作 GREEN。

## 剩余边界

- global no-live-reuse、whole-architecture promotion、完整系统重跑、CPI/workload、综合、STA、
  area、power 与无界 temporal proof 均未由本轮覆盖。
- canonical ledger 顶层 `GAP` 是 promotion 边界，不表示 44 个 holder semantic unit 失败。

