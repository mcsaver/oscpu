# V9R current-source rebind independent review v2

RV64 RTL 结论｜对象=`OooIntBackend`/`OooMemAxiBridge` SQ-query retry C0 与
CONTROL-EVENT-G1 本地证据链｜周期/配置=C0 edge-old barrier；
`OOO_ASSERT+V9R_SQ_RETRY_C0_FOCUSED`｜TB/EDA 观测=V9R 2/2 PASS、3/3
变异拒绝；V9O=167；currentness=16/38/32/0；48/4/20 PASS｜范围=PASS

本次只读终审未发现 blocker，判定 scoped source-rebind 可以交付：

- 合同 SHA-256 精确匹配
  `cf8cd0fec3b700dbc680a0e3caad208533c6a492c4db66eb3ef568e03ba3c8db`。
- production RTL 未变：
  - `OooIntBackend.v`：
    `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`；
  - `OooMemAxiBridge.v`：
    `2d6f33182e02e516e03864849e6d7299db44163a847b814f88ba8ea8d821a062`。
- C0 语义成立：full-flush barrier 同周期阻断 retry-ready、capture 和
  fire，MIQ/SQ-query owner 保留；barrier 撤销后才允许精确 handoff。
- 原始 TB 日志包含：
  - `[V9R-SQ-RETRY-NATURAL-TRAP] ... PASS`；
  - `[V9R-SQ-RETRY-C0-HANDOFF-PASS] ... PASS`；
  - `[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] ... PASS`。
- bank0、bank1、bridge 三个 compile-success RTL 版本分别由 `@18`、
  `@39`、`@24` 的定向断言拒绝。
- V9O evidence-index 实时校验为 167 artifacts；closed-currentness 为
  `closed=16 artifacts=38 semantic_checks=32 failures=0`。
- SERIALIZE candidate/contract/review 三元组的路径、顺序与 SHA-256
  精确匹配；A3 保留原始 `FAIL`，frozen-input checker replay 为 `PASS`，
  没有改写历史状态。
- receipt 精确为 48/48、4/4、20/20，均为 `OK`、返回码 0。

边界：

- 全局 architecture freeze 仍为 `GAP`，保留 33 个 blocker；
  PPA 为 `UNQUALIFIED`。本结论不授权 `ARCH_STABLE` 或 PPA 晋级。
- reviewer 没有新跑仿真、综合或 STA；结论来自实时源码/哈希、原始仿真
  日志及独立 auditor/verifier 逻辑交叉复核。
- `scope_extension_request：无`。reviewer 未修改文件、未遗留工程进程。

裁决：`APPROVED_FOR_CURRENT_SCOPE`。
