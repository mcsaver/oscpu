# v8l dispatch log

## 2026-07-20 local census and contract freeze

- 工作范围仅为本地 RV64 RTL、testbench、静态 checker、task-run/memory/e2e 证据；无网络、账号、
  凭据、外部服务或外部状态变更。
- bounded brief：`producer holder census last reference generation reuse` / `npc-dev` /
  `non-history`，recall complete。
- v8c checker只证明 file/module lexical census，明确
  `field_level_complete=false, instance_graph_complete=false, semantic_complete=false`；不得沿用其
  PASS作为当前字段级完整性。
- live RTL根因：`OooIntBackend.producer_live_mask_w` 尚未包含 integer IQ；EX0/EX1、memory
  reservation和branch resolve packed/direct Q holder没有统一显式 contributor。
- 在任何 RTL修改前已冻结 `contract.md`、`rtl-derivation.md` 与 `holder-census-draft.md`；下一步只派发
  自包含 no-tools只读反例审查。

## 2026-07-20 no-tools contract review dispatch

- contract JSON：`.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/subagent-contracts/v8l-global-producer-contract-review.json`
- contract JSON SHA-256：`59e014f7700d073d01bb9d1575a262181e38464181fedc6ce5289f630c1486c1`
- SHA-256只绑定上述 JSON，不绑定设计合同、RTL、测试或 reviewer 输出。
- 实际派发严格使用 canonical `self-contained-no-tools`：tools=false、shell=false、filesystem=false、
  network=false、writes=false；来源路径只作 provenance，reviewer只消费渲染提示内随附事实。

## 2026-07-20 first contract review closeout

- verdict=`gap`；原始结构化输出已保存为 `contract-review-result.json`。
- reviewer 的 IntIQ `srcP` 反例不适用于当前 RTL：本核 source dependency 只保存
  physical-register tag 与 sticky-ready，IntIQ 唯一 full-P 字段是 owner `producer_id_q`；已把该事实
  写入合同，未来新增 full-P source tag 会触发 static discovered-set 变化。
- 接受并修订其余 blocker：tracker allocation/hand-off 原子性、indirect mapping 稳定与 token
  no-reuse、WB/replay/redirect packed 发现、ROB guard-P 与 actual birth-P 同源、独立 raw-holder
  reference monitor，以及 manifest/checker/config/source SHA 绑定。
- 当前仍停在合同审查点，没有修改 RTL；将生成 amended no-tools 契约复核。

## 2026-07-20 amended contract review dispatch

- amended contract JSON：`.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/subagent-contracts/v8l-global-producer-contract-amended-review.json`
- contract JSON SHA-256：`2c4e54e9b85759baa2a8e57a7ace7eece4972ca0d48b5d31bc8df0797a4d1708`
- 实际派发继续为 self-contained no-tools，只包含修订后的字段、handoff、allocation 与证据事实。

## 2026-07-20 amended contract review closeout

- verdict=`pass`、blockers=`[]`；结构化结果保存为 `contract-amended-review-result.json`。
- reviewer确认：IntIQ唯一owner P边界、tracker原子handoff、transient拓扑、同源alloc-P、独立raw
  reference monitor以及`GEN_W=1`组合证据在合同层自洽。
- pass只解除实现前合同门，不代表RTL已实现或global no-live-reuse已GREEN；若拓扑事实变化，static
  checker必须先RED。architecture其余gate与PPA继续未提升。

## 2026-07-20 implementation and evidence closeout

- 永久 manifest/checker 完成字段级精确扫描：direct=15、packed=5、token Q=12、generation=1；
  checker unit 9/9，`make check-producer-holder-census` 与 `make check-contract` PASS。
- focused assert/release 8/8、compile-success runtime mutation 9/9、legacy v8d..v8l 8/8、fresh module
  aggregate 106/106。source pre/post SHA 清单一致。
- 第一次删 EX1 union mutation 意外 survived；root cause 是 Icarus variable release保留 force值且相邻
  probe复用同P。改成互异 P、每段 release后 reset/清零检查后，四类 transient deletion均被击杀。
- architecture checker self-test 15/15，但真实 inventory保持 `OVERALL: RED`；full lint签名仍为
  rc=2/115 warnings。没有将局部 correctness证据外推为architecture或PPA晋级。

## 2026-07-20 no-tools implementation review dispatch and schema gate

- review JSON：`.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/subagent-contracts/v8l-global-producer-implementation-review.json`
- JSON SHA-256：`67b3f82fb7dfec776ab34d32160e1c1ae31ff7ef74f52eef64c5b7b61110cc99`；只绑定该权限/输出合同。
- 实际权限：tools/shell/filesystem/network/writes均none；reviewer只消费提示内自包含的本地RV64 RTL
  实现和证据摘要，未读取文件、未复算SHA、未重放测试。
- 首份输出虽 verdict=pass，但沿用旧键名并把 `claim_boundary` 输出为 array，不符合本轮 schema；原文
  保存为 `implementation-review-result-schema-mismatch.json`，节点保持 `review_pending`。
- 父 agent只请求“不新增事实的机械重排”；第二份严格 schema结果保存为
  `implementation-review-result.json`，verdict=pass、blockers=[]。此 pass只允许当前绑定证据下的
  `v8l/global_no_live_reuse` scoped GREEN；architecture继续RED，PPA unpromoted，父目标active。
