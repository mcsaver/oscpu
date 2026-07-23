# V9I IFU-ACCESS-G1 RTL 数据流推导

## 当前实现链

1. `OooFetchAxiBridge` 以寄存的 halfword frontier 驱动 translation→EXEC PMP→instruction AR→RRESP
   循环；`OooFetchPacketDecode` 只消费 packet response ABI，不拥有物理访问范围。
2. AR address/size/prot 经 `NpcCoreTop`、`NpcTop`、`NpcAxiBus` 到 `AxiXbar`；xbar 在读事务寄存器
   中保存 owner/address/size/prot，并用 `SLAVE_EXEC_MASK` 在设备看到请求前选择 default error slave。
3. `NpcSimTop` 将 size/prot 传给 `AxiDpiSlave`；instruction data 采用标准地址 lane，PTW/LSU 控制
   保持各自已冻结的数据布局。
4. lane1 fetch fault 由 PairGate 保留、DispatchGate 建立 older-head barrier、
   `OooPendingLane1CaptureGate` 锁存 transaction facts，再由 pending arbiter/stop/trap request 链在
   branch resolve 后选择保留或 squash。

## 当前待证明而非预设的事实

- 生产 RTL design-id 是否仍与 V9H 相同；若不同，所有历史结果只能作反例目录。
- 现有 permanent TB marker 是否足以精确重建矩阵 membership、非真空正控制与周期级 owner；
  缺口必须先补 TB/evidence parser，不能直接关闭 ledger。
- 历史 2026-07-12 的 module 93/93、AM/official 与 reviewer 结论不自动迁移到当前 109-module
  inventory；V9I 至少重新绑定 focused、109 aggregate、compile-success variants 与独立复核。
- 本轮若生产 RTL 不变，则 PPA 仍为 `UNQUALIFIED`；诊断性历史 STA 数字不得作为当前 promotion。

