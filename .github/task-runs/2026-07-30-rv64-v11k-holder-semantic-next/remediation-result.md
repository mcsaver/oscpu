# V11K 终审 GAP 修复结果

## Push/pop tuple 断言敏感性

attempt-3 新增四个 compile-success interface stimulus probe：

- `accepted-push-tuple-x`
- `accepted-push-tuple-z`
- `valid-head-pop-tuple-x`
- `valid-head-pop-tuple-z`

每个 probe 均在 assertion/release 两种配置中编译运行：

- assertion 配置分别精确命中
  `[V11K-MIQ-PUSH-TUPLE-KNOWN]` 或
  `[V11K-MIQ-POP-TUPLE-KNOWN]`；
- release 配置由独立固定状态 oracle 检查 invalid tuple 不得污染
  head/count/occupancy；当前 X/Z 注入均由
  `[V11K-MIQ-HOLDER-ORACLE][FAIL]` 拒绝；
- 8/8 interface profile 均符合预期，未出现
  `[V11K-MIQ-NEGATIVE-ESCAPED][FAIL]`。

原 12 个功能/holder 变体保持 24/24 simulation rejection；加上两个
production baseline 后，attempt-3 总计 34/34 profile PASS。

## 普通回归执行输入绑定

三个普通回归现在分别保存：

- `compile_source_manifest`
- `compile_source_post_manifest`
- `source_pre_post_match`
- `.vvp` artifact path/SHA-256/size
- log path/SHA-256/size

绑定结果：

- `tb_ooo_mem_inflight_queue`：7 个输入，pre/post MATCH；
- `tb_ooo_dual_mem_inflight_queue_semantic`：7 个输入，pre/post MATCH；
- `tb_ooo_int_backend`：43 个输入，pre/post MATCH；
- 3/3 `.vvp` 存在且哈希已写入 summary，3/3 日志 PASS。

## Fail-closed 集成

- semantic checker schema 升级为
  `npc-rv64-v11k-miq-holder-semantic-evidence-v2`。
- 新增 marker 缺失与 regression source binding 负向合同单测。
- 语义单测：37/37 PASS。
- 共享 testbench Makefile 变化使旧 V11J rebind 正确失效；新建
  `v11j-bridge-rebind-current-v2`，32/32 PASS，旧目录保留。
- unified gate：instance graph 17 tests、census 15 tests、
  replay/semantic 43 tests PASS。
- ledger 仍为 17/44 PASS、27/44 GAP；architecture RED、PPA
  UNPROMOTED。

生产 `OooMemInflightQueue.v` SHA-256 仍为
`02d2e8a23ba8b321723315e317a823844b4aac431e550cf208a379a1df9d7147`，
本次修复未改变功能 RTL 或两态产品 elaboration。
