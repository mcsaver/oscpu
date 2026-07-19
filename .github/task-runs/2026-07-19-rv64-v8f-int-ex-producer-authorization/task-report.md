# RV64 v8f integer EX ProducerId formal-completion 任务报告

## 当前状态

`implementation_in_progress`。合同与 RTL 推导已在生产 RTL 前冻结；验证、证据闭包与独立复核尚未完成。

## 交付边界

见 `contract.md` 与 `rtl-derivation.md`。本轮只允许签收 integer IQ / memory-local EX0 /
EX1 formal-completion 的 scoped carrier + exact gate；完整 Domain-A identity 与 PPA promotion 保持 RED。

## 实现者证据

待 RTL 与 runner 完成后填写。

## 审查者反例

- 全 ID 回绕时旧/新 PID 仍可能相等；本刀没有 lease fence。
- shared WB 的其它四类 source 仍是 raw index。
- branch resolve、异步 memory request 与 FP result 可能早于 formal WB 产生副作用，未被本刀覆盖。
- query 比较加入 WB 控制锥，fresh physical evidence 未生成前不得声明 PPA 中性。

## 最终裁决

待 focused/full gates、compile-success mutations、独立复核和 strict guard 完成后填写。
