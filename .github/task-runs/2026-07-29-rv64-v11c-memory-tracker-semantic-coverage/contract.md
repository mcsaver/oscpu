# V11C memory tracker 语义闭合合同

## 对象

- production RTL：`npc/rv64/vsrc/memory/OooMemOwnerTracker.v`
- 语义单元：`memory-tracker-producer-map`、
  `memory-tracker-live-set`
- 明确排除：`tracker-next-token-cursor`、其它 holder/instance、
  whole architecture、系统重放、综合/STA/power/PPA

## 周期合同

1. allocation encoder 只读 edge-old `live_q` 与 `producer_live_q`。
2. exact free / STORE bulk release 命名 old-live death；birth 命名
   old-free token，birth/death 不相交。
3. dying token 与 dying ProducerId 本沿不可复用，下一周期方可复用。
4. 每个 live token 的 kind/epoch/ProducerId 保持，且对应
   `producer_live_mask_o` 中唯一 membership。
5. valid transaction tuple、release mask、live set 与 live map 在
   四态仿真中必须为已知值；该合同由 verification-only checker 承担，
   不改变生产 RTL。

## 成功条件

- assert/release baseline 均由独立 scoreboard PASS；
- X-known 负向必须编译成功并命中精确 checker marker；
- compile-success RTL variant 必须先生成 vvp，再在关闭 checker 与
  `OOO_ASSERT` 后由 TB 拒绝；
- full RTL 与 focused sources pre/post/current 哈希一致；
- policy 只能闭合精确两个单实例单元，cursor 与整体 ledger 保持 GAP。
