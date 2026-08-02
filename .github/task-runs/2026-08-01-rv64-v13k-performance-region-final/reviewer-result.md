# V13K 交付前 reviewer 结果

## 裁决

`DELIVERY_REVIEW_PASS / INDEPENDENT_REVIEW_RECEIPT_GAP / PERFORMANCE_BASELINE_GAP`。

对象为 `cpu-exec.cpp` 的 committed-PC start/end 与 termination-time `FINAL`、v4 checker、policy
合同绑定和三份本地仿真日志。production RTL 未改变；配置为当前 RV64 双发射 OoO 仿真配置。

## 通过项

- `report_region_probe_final()` 只从 `finish_exec(..., report_summary=true)` 调用；
  `final_emitted` 防止重复权威记录，非报告型交互返回不伪造终止证据。
- `FINAL` 同时携带 schema/scope、complete、termination rc、最终 hit 总数和边界算术；正常
  CoreMark、超时 CoreMark 与同周期双 lane 日志覆盖三条互补路径。
- v4 checker 的负向版本覆盖缺失/重复 FINAL、early RESULT、post-end hit、incomplete、非零
  termination、零周期和合同 path/ID/digest/eligibility 变异；定向 suite 为 49/49 PASS。
- policy 中合同 SHA-256 与当前 JSON 一致；`performance_baseline_eligible=false` 仍机器阻断 strict
  baseline 消费，没有因实现基础 parser 而越级晋级。

## 审查发现与处理

机器合同 `counter_qualification.consumer_fail_closed_enforcement` 已写成 IMPLEMENTED，但
`known_limitations` 仍残留“没有 consumer”的 V13J 旧句。该自相矛盾已改为说明 v4 绑定已经实现、
当前 false eligibility 会阻断 strict acceptance；policy digest 随之重绑，49 项测试再次 PASS。

## 未闭合范围

- 独立只读子节点合同 SHA-256 为
  `516ce0eb46f52098f1d90b0dac6b5031dfa55ebb8753296f95e0720bc9ab4f39`，但节点未在时间边界内
  返回 findings；主节点在其状态变为 `interrupted` 后才恢复 WSL shell ownership。
- 新鲜证据只有 CoreMark 一次，不满足两 workload × 三次 bit-exact baseline 合同。
- typed identities、守恒 CPI stack、retire/issue lost-slot、occupancy/overflow 与观测非干扰仍为 GAP。
- 全 PPA discovery 的跨轮次旧 binding 失败尚未整理，不能把 49 项局部 PASS 扩大为全套 PPA PASS。
- changed-path strict guard 推荐的 `npc-dev` profile 五个合同节点全部 PASS，但前置
  `context-brief` WARN 使 wrapper fail-closed 为 `blocked`；guard 仍为 GAP，未篡改历史状态。

