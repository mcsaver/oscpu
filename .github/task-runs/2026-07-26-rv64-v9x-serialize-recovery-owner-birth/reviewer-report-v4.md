# V9X final independent RTL review

RV64 RTL 结论｜对象=V9X accepted owner birth/live/lease 与 queue-head CSR
real-fire、trap-exit C1 reset｜周期/配置=`OOO_ASSERT +
OOO_CSR_QUEUE_HEAD=1 + V9O_CSR_QH_FOCUSED`｜TB/EDA
观测=定向 PASS、2/2 mutation 定点失败、功能 111/111、架构
9/9｜范围=PASS（仅 owner-birth 子范围）

合同 JSON：
`reviewer-contract-v4.json`

合同 SHA-256：
`0c24142ece0c242655ac6f1b757a741dcb99071deebf33fd9c1c404746688708`

## Independent result

未发现新的 V9X accepted owner-birth/live/lease 阻断项，owner-birth
子范围可独立判定为 PASS：

- `OooStopPendingSequencer` 只消费 accepted birth；reset/C1、exact
  commit、CSR lease 与其余状态转换使用显式优先级。普通 recovery
  不会清除存活 lease，exact producer death/commit 才能终止。
- queue-head CSR birth 使用 `OooFrontend` 产生并经
  `OooCoreTopGlue` 传给 `OooControlPlane` 的 canonical
  `head0_csr_dispatch_fire_w`，不从 merged dispatch fire 重建；
  not-ready、merged-only、older branch/JALR kill 均不会误生 owner。
- trap/exit holder 与 stop 都由 C1 `core_local_flush_w` 同步 reset。
- 两个 compile-success mutation 分别删除 trap/exit C1 reset、改回
  merged-fire CSR birth，均运行到最终 V9P marker 后由对应定向
  oracle 唯一拒绝，return code 2。
- 当前受审 RTL SHA 全部命中 architecture hard-gate source map；
  design id 为
  `sha256:a2ccc0c2a61be3d8922245f7d145eadc186b701fca1f38ef534aafdd983e994b`。

## Confidence boundary

反例复核没有推翻上述结论，但保留两个证据强度边界：

1. V4 合同没有重新打开 `OooPendingDispatchArbiter` 与 C1 gate 的内部
   生成逻辑；其输入事实沿用已经过 V1–V3 与最终回归验证的边界。
2. mutation summary 直接绑定 production `OooControlPlane.v` 的
   before/after SHA，而不是完整 mutant cohort 与 TB 的统一 aggregate
   hash；保存的 mutant source/log hash、临时 vsrc 编译路径、最终 V9P
   marker 与 return code 均已逐项核对。

结合最终 RTL source-map identity、focused marker、mutation rejection
和分层回归，这两项不构成 V9X owner-birth 子范围 blocker。

## Remaining GAP

本轮 PASS 不覆盖：

- `OooMemOwnerTerminalCollector` 的非 FENCE memory-owner terminal；
- 七类 serialized transaction 的 exactly-once 完成/退休；
- 完整 Linux flag-on；
- architecture-stable freeze；
- 综合、STA、功耗与 PPA；当前仍为 `ppa=UNQUALIFIED`；
- `SERIALIZE-G1` 总体继续 OPEN。

终审全程只读，未修改文件、未遗留后台进程；WSL shell ownership
已归还主节点。
