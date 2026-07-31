# V11K `OooMemInflightQueue` 实现结果

## 生产 RTL

`npc/rv64/vsrc/memory/OooMemInflightQueue.v` 的功能队列逻辑未改变。
新增内容全部位于 `OOO_ASSERT` 条件编译区：

- `[V11K-MIQ-PUSH-TUPLE-KNOWN]`：accepted push 的完整 owner tuple
  不得含 X/Z；
- `[V11K-MIQ-POP-TUPLE-KNOWN]`：有效 head 上的 response tuple 不得
  含 X/Z；
- `[V11K-MIQ-OWNER-TUPLE-KNOWN]`：每个 valid entry 的完整驻留 tuple
  必须为已知二值；
- `[V11K-MIQ-OWNER-TUPLE-STABLE]`：无队列或 recovery 事件的相邻周期，
  head tuple 必须保持。

生产源 SHA-256：
`02d2e8a23ba8b321723315e317a823844b4aac431e550cf208a379a1df9d7147`。

## Testbench 与证据 runner

- 新增
  `npc/rv64/testbench/tests/tb_ooo_dual_mem_inflight_queue_semantic.sv`；
  两个实例名与产品 lane 对一致，期望 tuple 仅由 stimulus schedule
  生成。
- 新增
  `npc/rv64/testbench/scripts/run_v11k_miq_holder_semantic.py` 与 5 个
  runner 定向单测。
- canonical attempt-3 矩阵为 34/34 PASS：
  - assertion/release 两个 production baseline；
  - 12 个编译成功的负向 RTL 变体，各在 assertion/release 中运行，
    共 24 次均被断言或独立 testbench oracle 拒绝；
  - accepted push 与 valid-head pop 的 X/Z 四个 interface probe，各在
    assertion/release 中运行，共 8 个 profile；
  - 3/3 普通回归 PASS：
    `tb_ooo_mem_inflight_queue`、
    `tb_ooo_dual_mem_inflight_queue_semantic`、
    `tb_ooo_int_backend`。

变体覆盖 kind/token/epoch 的 X/Z capture、idle head token drift、非精确
owner 消费、flush survivor/drop、occupancy live omission 与 ghost
addition。

## 产品 elaboration

V11J 与 V11K 的完整 Yosys JSON 在仅删除 `src` 位置属性后逐结构比较：

- module：130 对 130；
- cell：176087 对 176087；
- canonical logic SHA-256 均为
  `c49ad65d6aad707f525fe37fabaa2c7187ade0c1c5880ad22b05e5d164d15e5b`；
- `production_elaborated_logic_changed=false`。

因此本轮生产差异属于断言观测增强，不改变当前配置的两态产品逻辑。

## 证据生成中的纠偏

- 第一次 fresh instance-graph 生成被 stale census/product-config
  preflight 正确拒绝；更新当前绑定后 canonical graph PASS。该首次返回未
  单独保存 raw directory，不能把它描述为独立可重放证据。
- 一次 census 工具调用把 declaration 临时写成 audit payload；随后用
  `tools/rebuild_census_manifest.py` 从 HEAD declaration、V11J frozen
  audit 与当前 17-instance graph 交叉核验后恢复。恢复脚本只推进当前
  design-id、product config 与 graph evidence 绑定。
- `miq-holder-attempt-1` 原样保留；在 runner manifest 加入
  `define.v`/`filelist.mk` 后生成独立的 `miq-holder-attempt-2`。
  attempt-2 的终审 GAP 也原样保留；补齐 interface probe 与 regression
  source/vvp/post-hash 后生成 `miq-holder-attempt-3`，后者为
  canonical。
