# V11E `OooRob.slot_generation_q` 语义覆盖合同

## 本轮分类

- 初始分类：`verification`。
- 唯一技术目标：为 production `OooRob.slot_generation_q` 建立当前
  source-bound、可证伪且以沿前独立 slot-generation model 为参考答案的周期级语义证据。
- 重分类条件：若定向 testbench 在合法二态输入下给出 production RTL 反例，
  本轮立即改列 `production RTL fix`，先补根因与接口合同，再做最小修复。

## 当前绑定

- production RTL：`npc/rv64/vsrc/writeback/OooRob.v`
- production RTL SHA-256：
  `bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561`
- 复用 testbench：`npc/rv64/testbench/tests/tb_ooo_rob.sv`
- testbench 起始 SHA-256：
  `ecf96ab30a3de19c385a9c1ce5b3c4645812b3f1e3f629384f85c5e42ce92890`
- 当前 146-file design-id：
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`
- V11D semantic ledger 将 `rob-slot-generation` 保持为 GAP；V8L 已证明全局
  holder collision fence 的有限代际回绕路径，但没有直接变异
  `OooRob` 的 generation source、accepted-write 与 lifecycle 规则。

## 周期合同

令 `G[s]` 为某一时钟沿前 slot `s` 的 generation model，
`next(G) = G + 1 mod 2^PRODUCER_GEN_W`。

1. hard reset
   - `rst=1` 时 dispatch ready 必须为 0；
   - reset edge 后所有 `G[s]` 为全 1；
   - reset 释放后 tail slot 的候选 generation 为 0。
2. candidate
   - lane0 候选为 `{next(G[tail]), tail}`；
   - actual lane1 slot 为 `tail + dispatch0_fire`，候选从该 slot 的沿前
     `G` 独立导出；
   - pair lane1 候选恒为 `{next(G[tail+1]), tail+1}`，不与 lane1-only
     的 actual lane1 slot 混淆。
3. accepted write
   - 只有 `dispatchN_valid_i && dispatchN_ready_o` 的 accepted dispatch
     edge 才把对应候选写回对应 slot；
   - 双 accepted dispatch 必须写两个相邻且不同的 slot，各自使用自己的
     沿前 generation；
   - invalid、full、reset、ordinary flush、`kill_valid_i` 冻结和
     recovery walk 周期不得形成 generation write。
4. lifecycle
   - ordinary `flush_i` 清 ROB lifecycle，但保留所有 slot generation；
   - selective recovery 清更年轻项的 valid/done，但保留 survivor 与
     squashed slot generation；后续复用才递增；
   - commit 只终止当前 ROB incarnation，不推进 slot generation；
   - full ROB 即使同沿 commit，也不得借用本沿释放 slot 接受 dispatch。
5. carriers and queries
   - accepted entry 的 head/commit/walk ProducerId 使用其已登记
     `slot_generation_q`；
   - current/completion/resolve query 必须以完整 generation+index 精确匹配
     当前有效 incarnation，并遵守各自 valid/done/recovery 条件。

## 竞争假设

- H1（RTL 正确、证据缺口）：当前 RTL 精确实现上述 candidate、accepted-write、
  lifecycle、carrier 与 query 合同。
- H2（候选错误）：lane1 actual/pair source、模加一或 reset seed 至少一项错误。
- H3（推进错误）：valid-but-rejected、flush、recovery、commit 或错误 slot
  发生 generation write。
- H4（假绿）：testbench 从 DUT `slot_generation_q` 或 ProducerId 反喂
  expected，只观察最终 ID 不观察沿前 candidate/沿后写入，或负向变体只被
  `OOO_ASSERT` 检出。

## 结论边界

本轮最多晋级 census 单元 `rob-slot-generation`。`PRODUCER_GEN_W=1`
经过两个完整 incarnation 后 ProducerId 可有限回绕；是否允许新 birth 由
`OooDispatchBackend` 与全局 holder collision fence 决定，不属于
`OooRob` 单元 PASS。不得外推 whole architecture、系统事务、综合、STA、
功耗或 PPA。
