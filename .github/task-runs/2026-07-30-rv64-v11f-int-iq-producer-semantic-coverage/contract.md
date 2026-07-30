# V11F `OooIntIssueQueue.producer_id_q` 语义覆盖合同

## 本轮分类

- 分类：`verification`。
- 唯一技术目标：为 production `OooIntIssueQueue.producer_id_q` 建立当前
  source-bound、可证伪且由 testbench 独立八槽 full-ProducerId model
  给出参考答案的周期级语义证据。
- production RTL 仅在合法 IQ-I6 输入合同内发现可达反例时才允许重分类为
  `production RTL fix`；当前独立预审未发现该类反例。

## 当前绑定

- production RTL：`npc/rv64/vsrc/scheduling/OooIntIssueQueue.v`
- production RTL SHA-256：
  `d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b`
- issue selector：
  `npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v`
- testbench：`npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv`
- canonical testbench SHA-256：
  `cb8e875f772157de0651c0582184c78b4820627ab8b1a2dce56cc604c77e9d2c`
- 当前 146-file design-id：
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`
- V11E semantic ledger 将 `integer-iq-producers` 保持为 GAP；V8L 只直接
  变异了 IQ fire death-edge，尚未闭合 full-P birth、hold、compaction、
  issue/pair carrier、raw identity knownness 与完整 lifecycle。

## 周期合同

令 `Qold` 为时钟沿前的八槽 `{valid, producer_id}` 有序队列。

1. birth
   - 仅 `dispatchN_valid_i && dispatchN_ready_o` 的 accepted edge 形成 birth；
   - 双 accepted dispatch 按 lane0、lane1 顺序把两个完整 ProducerId
     追加到 survivor 尾部；
   - 本沿组合 live mask 仍扫描 `Qold`，新 birth 从下一周期开始成为 holder。
2. hold
   - issue READY-low、memory pair READY-low 与 recover hold 期间，全部 valid
     槽的 full ProducerId、相对顺序和对应 issue/pair payload 保持稳定；
   - generation 位不得截断，raw ProducerId 必须二态已知。
3. handoff/death and compaction
   - regular single/dual fire 精确删除被选择的 edge-old entry；
   - memory pair 仅在原子 pair fire 时同时删除 edge-old entry0/1；
   - survivor 按原顺序压缩，ProducerId 从被压缩的源槽携带；
   - 同沿 accepted append 位于全部 survivor 之后；
   - fire 当拍 live mask 仍包含 edge-old holder，死亡从下一周期生效。
4. selective recovery
   - `kill_valid_i` 按 raw ROB 环形年龄删除严格年轻于 boundary 的 entry；
   - boundary 自身与 older survivor 的完整 ProducerId 不被重写；
   - `head=14`、boundary=15 和跨回绕 0/1 必须可判别。
5. flush/reset
   - nonempty flush 与 reset edge 后八槽全部 invalid；
   - edge 前仍按 `Qold` 观测 holder，不用组合去重掩盖死亡沿；
   - IQ-I6 禁止 kill/flush/reset 与新 dispatch acceptance 同拍。本轮不把
     违反该上游 transaction barrier 的无约束端口组合外推为 IQ 局部缺陷。

## 竞争假设

- H1：当前 production RTL 在合法 IQ-I6 合同内正确，缺口位于验证闭包。
- H2：production RTL 在 birth、hold、compaction、issue/pair death、kill、
  flush/reset 或 raw identity knownness 中存在可达缺陷。
- H3：现有 V8L 证据已充分覆盖 `integer-iq-producers`。
- H4：新 testbench 从 `producer_live_mask_o`、DUT `valid_q` 或
  `producer_id_q` 反喂 expected，或变体仅被 `OOO_ASSERT` 拒绝。

## 结论边界

本轮最多晋级 semantic unit `integer-iq-producers`。上游
kill/flush transaction barrier、全局 finite-generation collision fence、
其它 36 个 semantic unit、whole architecture、系统事务、综合、STA、功耗
与 PPA 均不得由本轮外推为完成。
