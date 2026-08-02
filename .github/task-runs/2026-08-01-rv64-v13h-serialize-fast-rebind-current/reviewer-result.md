# V13H SERIALIZE-G1 当前设计独立审查

RV64 RTL 结论｜对象=`OooRob` queue-head CSR 与 `OooPendingSystemSequencer`
pending-SYSTEM｜周期/配置=C0/C1/C2、`OOO_CSR_QUEUE_HEAD=1`、design-id
`sha256:364b1e601773c22ab0594950170674ea6b228bf6b4c9b2c26b0bdcc9a4374d44`｜
TB/EDA 观测=queue-head 2/2 正向加 3/3 负向、SYSTEM 3/3 正向加 15/15 负向、
功能 113/113 加 177/177 加 61/61、DiffTest mismatch=0；综合/STA 未运行｜范围=PASS

裁决：`APPROVED_NOT_PROMOTION_ELIGIBLE`。

- 当前设计绑定包含近期 `OooStoreQueue`、`OooLoadQueue`、`OooIntIssueQueue`、`OooRob`
  与 `OooPendingSystemSequencer` 修改；实际源码哈希与冻结输入一致，pre/post 输入及
  design-id 无漂移。
- queue-head CSR 的 C0 只在内存静默、上下文和 fence permit 满足后提交并产生 typed
  serialize barrier；pending CSR 用完整 ProducerId 排除重复 queue-head owner。C1 仅出现一次
  control/CSR apply，C2 无重复 request、apply 或 MMU action。
- pending-SYSTEM holder 保持 typed kind 与完整 ProducerId lease；普通 clear/recapture 不释放
  CSR lease，仅 producer death 可释放。相关 `OOO_ASSERT` 保留，未发现断言削弱。
- StoreQueue 的已接受 physical-write owner、LoadQueue 的已发射异常路径 tombstone 与
  IntIssueQueue 的 resident select/ProducerId live mask/kill-issue 互斥未破坏上述 C0/C1/C2 边界。
- queue-head summary SHA-256=`4cf76dc4e40ee5cd8a32c76968d3ea1209608cc5c7b238ac453c9c77b11e0317`。
  两个正向配置均观察到 C0 commit/barrier、`CsrFile` request、C1 apply 与 C2 quiet；三个
  可编译负向版本均被动态拒绝。精确分类为两个 production RTL mutation 加一个
  verification-only `CsrFile` TB-wiring mutation，不能称为三个 production RTL mutation。
- pending-SYSTEM summary SHA-256=`9b3192be50d64de5a50294fe0a7809cc5f7bb0784724190b669359b77b2447b4`。
  3/3 baseline PASS，15/15 production RTL mutation 编译成功后被预期 marker 动态拒绝。
- 功能直接执行证据为 module 113/113、official 177/177、AM 61/61、DiffTest mismatch=0；
  CoreMark 与 Dhrystone 各出现一次 GOOD TRAP。冻结 checker 正负向单测 PASS。本只读节点
  没有重新执行 Python。
- A3 checker replay 仍绑定旧 design-id `sha256:c1b531...`；它只修正旧 oracle 的误判，
  不能作为当前 `364b1e...` 的完整系统事务。
- 必须保持 `fast_gates=PASS`、full-system=`RECERT_REQUIRED`、
  `SERIALIZE-G1=STALE_EVIDENCE`、`current_design_bound=false`、architecture freeze=`GAP`、
  PPA=`UNPROMOTED`。

未知项与边界：本节点没有运行综合、STA、Power 或完整系统事务。旧架构文档仍有历史
`SERIALIZE-G1=CLOSED` 文字，`OooRob.v` 接口附近也有旧 `mem_quiet` 注释；当前裁决以 ledger、
currentness decision 和现行 `mem_idle` 接线为准。关闭 `SERIALIZE-G1` 必须补当前 design-id 的
完整系统事务；正式 PPA 还需同身份 mapped synthesis、STA 与 Power 证据。

置信度：当前设计快速门 PASS 为高；完整系统重认证与 PPA 未晋级为高。无需
`scope_extension_request`。
