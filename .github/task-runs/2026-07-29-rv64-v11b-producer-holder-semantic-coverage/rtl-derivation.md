# V11B terminal collector RTL 推导

## Root cause

V11A 已证明 holder module 的 product instance multiplicity，但实例存在性不能证明
terminal tuple 在 ingress、pending set、grant 和 registered output 间保持同一
token/kind/epoch。旧 V9Y 证据的 production RTL 仍可用于历史定位，但 TB 已漂移，
且当前 collector 缺少 valid-input identity-known 的直接断言与双 lane 非对称
turnover 观测，不能把 candidate evidence 追认为当前语义闭环。

## 最小 RTL 改动

`npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v` 只在
`OOO_TERMINAL_HOLDER_ASSERT` 范围新增：

- pending mask 二态性；
- valid ingress kind/token/epoch 二态性；
- tracker live/kind/epoch truth 二态性；
- output0/output1 kind/epoch 二态性。

既有 duplicate、same-edge、owner、hold 与 conservation 断言全部保留。
release profile 的组合选择、pending next-state、grant、output register 和 dequeue
握手逻辑未改。

## TB 判别

`tb_ooo_mem_owner_terminal_collector.sv` 新增：

- lane1 turnover、lane0 hold；
- lane0 turnover、lane1 hold；
- valid ingress unknown-value negative profile；
- raw dequeue fire 直接计数。

计数不使用 seen/reported 去重，因此重复 terminal 不能被 testbench oracle 掩盖。

## 语义晋级条件

静态 12+2 lane 合同、assert/release 正例、unknown negative 和三个
compile-success RTL 反例共同成立时，只晋级 collector 对应的三个语义单元。
44 单元总账仍以 3 PASS / 41 GAP 发布。

## 全系统重跑边界

本轮 production release 语义与当前 product elaboration 功能锥未改变；改变的是
assertion-only RTL 与定向 TB/oracle。因此不满足 A3 完整重跑条件。若后续修改
production core RTL 语义、当前配置实际 elaborated 功能逻辑、device model 或
simulator 执行语义，才重新进入 rootfs 全系统验证。
