# V9A holder / owner census delta

## 生产 RTL

无新增、删除或迁移生产 holder；`npc/rv64/vsrc/**` 初始写范围为空。现有 owner 仍为：

- fetch packet：`OooFetchPacketFifo`；
- speculative map/free/busy：`OooRenameMap` / `OooFreeList` / `OooBusyTable`；
- in-flight program order：`OooRob`；
- ready scheduling entries：`OooIntIssueQueue`；
- integer execution completion：`PipeStageReg u_ex0_stage/u_ex1_stage`；
- formal completion / retirement：WB ports / `OooRob` commit ports。

## Testbench-only ledger

V9A focused mode新增仿真局部 PC/payload ledger、allocation-instance sequence、active full ProducerId lifecycle table，以及 EX0/EX1 previous-cycle capture ledger。后者保存 full ProducerId 与完整 stage payload，并在下一拍与 `PipeStageReg` down-side逐字段比较。PID 只在旧 lifecycle 已 `retired` 并清除 active entry 后允许复用。这些 ledger 不驱动 DUT、不被综合、不成为设计 owner。停止 fetch admission 后必须以自然 drain 证明 pending response、outstanding、FIFO、ROB、IQ、EX stage 和 active ledger 全空，不用 reset/flush 掩盖残留事务。

## 裁决

若生产 RTL SHA 前后不同或出现新 holder，本 census 必须先修订并在 `producer-holder-census.json` 登记；否则 DI-2 evidence builder fail closed。
