# RV64 V11B ProducerId holder 语义覆盖合同

## 本地 RTL 对象

本轮对象限定为当前 `NpcTop` product 配置下
`producer-holder-census.json` 的 44 个 ProducerId/owner-token 语义单元、
V11A 的 17 个 elaborated holder instance，以及
`OooMemOwnerTerminalCollector` 的 12 路 terminal ingress、2 路
tracker-free dequeue lane 和 2 路 registered output。

当前设计标识为：

`sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`

## 判定合同

1. census 字段清单、product instance graph 与语义闭环必须分开计数。
2. 每个语义单元按实际 product instance 展开；同 module 的两个实例不得合并。
3. 历史、RTL 漂移、TB 漂移和当前 source-bound 证据必须分别标注。
4. candidate evidence 不能自动晋级为 semantic PASS。
5. 只有同时绑定当前完整 RTL、正向 profile、可编译 RTL 反例、独立 oracle
   和精确 artifact hash 的单元才可局部 PASS。
6. terminal collector 的 transfer authority 只能来自 accepted terminal；
   raw ingress 不能直接获得 transfer 权限。
7. 同 token 的重复 terminal 必须由断言暴露；禁止增加去重逻辑掩盖重复事件。
8. 现有 duplicate、owner、hold、same-edge 与 conservation 断言不得削弱。

## 本轮允许闭合的最小范围

仅允许在证据成立时闭合：

- `terminal-output0-token`；
- `terminal-output1-token`；
- `terminal-pending-set`。

其余 41 个语义单元保持显式 GAP。不得据此声明 global no-live-reuse、
whole architecture GREEN、系统级 GREEN、200 MHz、Power 或 PPA promotion。

## 必需正向证据

- assert/release 两个 collector profile 均 PASS；
- 12 路 ingress 的 valid/kind/token/epoch 映射逐项精确；
- 2 路 tracker-free lane 映射逐项精确；
- output0/output1 非对称 turnover/hold 均被观测；
- accepted-only handoff 与 `duplicate_ingress_merged=false`；
- 146-file RTL pre/post source binding 相同；
- ledger 完整覆盖 44 单元、17 instance、50 条 unit×instance 绑定。

## 必需负向证据

- valid ingress 的 kind/token/epoch 含未知值时由 RTL assertion 拒绝；
- 删除 ingress-known assertion 的可编译 RTL 版本被拒绝；
- lane1 错用 lane0 grant 的可编译 RTL 版本被拒绝；
- 切除 pending/same-edge acceptance guard 的可编译 RTL 版本被拒绝；
- lane token 对调、accepted mask 缺失、raw ingress authority、free-lane
  对调和 assertion label 删除均由静态 lane checker 拒绝。

## 非目标

- 不改 release profile 的功能时序；
- 不重跑 A3 rootfs 全系统；
- 不关闭其余 41 个 holder 语义缺口；
- 不进行综合映射、STA、功耗或 Pareto 发布。
