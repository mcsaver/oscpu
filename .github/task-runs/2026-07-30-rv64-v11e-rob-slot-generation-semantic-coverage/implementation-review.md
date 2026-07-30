# V11E implementer review

## RTL 对象与结论

- production `OooRob.slot_generation_q` 未修改；当前 source SHA-256 为
  `bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561`。
- 合法二态、有效环形 ROB 状态下未观察到 candidate、accepted-write、
  flush/recovery/commit/reuse、carrier 或 exact-query 反例。
- 本轮实现仅进入 testbench、evidence tool/test、semantic ledger policy/tool/test
  与 task-run；分类保持 `verification`。

## 独立 oracle

- expected generation、valid、done、head、tail、count、recovery 均只由
  stimulus 与沿前 model 状态推导。
- 每个 posedge 后比较全部 16 个 slot；candidate/ready/fire 在沿前比较。
- head/commit/walk expected ProducerId 直接从 model 形成，不回用 DUT
  ProducerId。
- current0/1、completion0..7、resolve 对 `GEN_W=4` 的每个 generation bit
  分别施加 stale identity。

## 反例敏感性

- canonical attempt-3 为 4/4 baseline。
- 17 个源码形态唯一命中的 compile-success RTL variants 在
  `GEN_W=1/4` 各运行一次；34 个仿真均显式关闭 `OOO_ASSERT` 并被独立
  oracle 拒绝。
- attempt-1/2 的存活变体分别暴露“全零 carrier 不可判别”和
  “reset-to-ones 不改变全一状态”；最终 recovery pair 使用 generation
  0/1 混合状态同时关闭两洞。

## 范围

- bounded PASS 候选仅为 `rob-slot-generation`。
- `PRODUCER_GEN_W=1` 有限回绕不是 `OooRob` 局部缺陷；全局 holder
  collision fence 仍属 `OooDispatchBackend`/V8L。
- 其余 37 个 semantic unit、whole architecture、system、synthesis、STA、
  power 与 PPA 均保持 GAP。
- production/elaborated RTL、device model 与 simulator 语义未变化；A3
  原始 FAIL、checker replay PASS 和“不需完整重跑”分类保持不变。
