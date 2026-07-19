# RV64 v8c producer identity P0 合同

本阶段不实现或激活 full producer identity。它只要求两件事可自动发现、可重跑、可审计：

1. production source-tree 中 lexical 可见的 ROB-index carrier 与 bounded derived owner 必须进入
   file/module census，且 global no-live-reuse/full-ID/WB/Q1 状态保持 RED；
2. current `OooRob` 的 raw-index slot ABA 必须由真实 branch recovery/walk、slot wrap/reuse 与
   正常 new-WB 对照动态复现。

机器入口：

```bash
.github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/census/run-holder-census.sh
bash .github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/rob-reuse-red/run-rob-reuse-red.sh
```

`CENSUS_RESULT=PASS` 只证明 bounded file/module 账本一致；expected-RED runner 的 PASS 只证明当前
缺口存在且正控有效。两者都不允许解释成设计 GREEN。

