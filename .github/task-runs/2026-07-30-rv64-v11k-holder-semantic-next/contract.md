# V11K `OooMemInflightQueue` holder 语义闭环合同

> 状态：已实现，分层验证 PASS，终审 attempt 1 GAP 已修复，独立复审 PASS
>
> 主分类：verification
>
> 次分类：architecture documentation、tooling/workflow
>
> 生产 RTL 授权范围：仅 `OOO_ASSERT` 观测与断言

## RV64 对象与实例

- 生产模块：`npc/rv64/vsrc/memory/OooMemInflightQueue.v`。
- 语义单元：`miq-owner-tokens`。
- 两个产品实例：
  - `NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_mem_inflight_queue`
  - `NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_mem1_inflight_queue`
- 当前设计 ID：
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- 当前生产源 SHA-256：
  `02d2e8a23ba8b321723315e317a823844b4aac431e550cf208a379a1df9d7147`。

## 待验证合同

1. 接受 push 时完整
   `{owner_kind, owner_token, mmu_epoch}` 必须为已知二值。
2. 有效 entry 驻留期间完整 owner tuple 必须保持已知；无
   push/pop/flush/kill 的 head tuple 不得漂移。
3. response 仅在完整 owner tuple 与 FIFO head 精确相等时消费；
   相同 ROB、不同 owner 以及两个 MIQ 之间交换 tuple 均不得误消费。
4. selective flush、global flush、ROB-walk kill 与 exact consume 后，
   `occupancy_token_mask_o` 必须精确等于所有有效 entry 的 32-bit token
   集合，既不遗漏 live token，也不产生 ghost token。
5. 两个产品实例必须由 stimulus-owned 固定期望表分别观测，期望 owner
   tuple 不得取自 DUT 内部状态。

## 实现范围

- 在 `OOO_ASSERT` 配置中增加 push/pop/驻留 owner tuple knownness 与
  head tuple idle-stability 断言；不得改变 release 配置下的队列更新方程、
  datapath、flush/kill/pop 语义或产品 elaboration。
- 新增双实例定向 testbench，覆盖 capture、三拍 hold、cross reject、
  flush/kill、exact consume 与 occupancy 集合。
- 证据 runner 同时编译 assertion/release 基线及编译成功的负向 RTL
  变体，并保存命令、源文件哈希、返回码和 marker。
- 历史证据不可改写；`miq-holder-attempt-1` 与
  `miq-holder-attempt-2` 均保留。补齐 push/pop interface probe 及普通
  回归执行输入绑定后的 `miq-holder-attempt-3` 为 canonical。

## 判定边界

- 本合同只能把 `miq-owner-tokens` 在两个列出的产品实例上提升为局部
  PASS。
- `global_no_live_reuse` 不由本合同证明；完整架构保持 RED，PPA 保持
  UNPROMOTED。
- 生产差异若经完整两态 Yosys elaboration 证明逻辑恒等，则不触发系统
  重跑。若产品 RTL 语义、当前配置下实际 elaborated RTL、设备模型或
  simulator 执行语义改变，或者缺少原始输入/终端链/post-hash，必须重新
  评估完整系统运行。
- 不得用事件去重掩盖重复 terminal transaction，也不得削弱任何既有
  断言。
