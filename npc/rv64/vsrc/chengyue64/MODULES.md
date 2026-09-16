# Rebuild 模块清单

按文件列出声明模块；这是一张覆盖检查表，不是 elaboration 实例证明。生产参数、owner 与连接见 [全核拓扑](TOPOLOGY.md) 及各域文档。目录外 AxiClint/AxiPlic/AxiResetSyscon/AxiToUart/Uart/AxiDefaultSlave 由平台显式连接，见 BUS 文档。

| 文件 | 声明模块 |
|---|---|
| [backend/R64Alu.v](backend/R64Alu.v) | R64Alu, R64AluControl, R64AluPipe, R64AluDatapath |
| [backend/R64Backend.v](backend/R64Backend.v) | R64Backend |
| [backend/R64CarryStages.v](backend/R64CarryStages.v) | R64CarryPrepare, R64CarryFinish |
| [backend/R64Clmul.v](backend/R64Clmul.v) | R64Clmul |
| [backend/R64Decode.v](backend/R64Decode.v) | R64Decode |
| [backend/R64DecodeControl.v](backend/R64DecodeControl.v) | R64DecodeControl |
| [backend/R64DecodeStage.v](backend/R64DecodeStage.v) | R64DecodeStage |
| [backend/R64Divide.v](backend/R64Divide.v) | R64Divide |
| [backend/R64Execute.v](backend/R64Execute.v) | R64Execute, R64AluLane |
| [backend/R64FpReadPlan.v](backend/R64FpReadPlan.v) | R64FpReadCompact, R64FpReadJoin |
| [backend/R64FreeSelect.v](backend/R64FreeSelect.v) | R64FreeSelect |
| [backend/R64Issue.v](backend/R64Issue.v) | R64Issue, R64AgeSelect |
| [backend/R64Multiply.v](backend/R64Multiply.v) | R64Multiply |
| [backend/R64NumericOwner.v](backend/R64NumericOwner.v) | R64NumericOwner |
| [backend/R64ProductTree.v](backend/R64ProductTree.v) | R64ProductTree, R64CsaReduce |
| [backend/R64RegRead.v](backend/R64RegRead.v) | R64RegRead |
| [backend/R64Rename.v](backend/R64Rename.v) | R64Rename |
| [backend/R64Rob.v](backend/R64Rob.v) | R64Rob |
| [backend/R64WideAdd.v](backend/R64WideAdd.v) | R64WideAdd |
| [backend/R64Writeback.v](backend/R64Writeback.v) | R64Writeback |
| [bus/R64AxiRead.v](bus/R64AxiRead.v) | R64AxiRead |
| [bus/R64AxiWrite.v](bus/R64AxiWrite.v) | R64AxiWrite |
| [control/R64Commit.v](control/R64Commit.v) | R64Commit |
| [control/R64Counter.v](control/R64Counter.v) | R64Counter |
| [control/R64CounterNear.v](control/R64CounterNear.v) | R64CounterNear |
| [control/R64Csr.v](control/R64Csr.v) | R64Csr |
| [control/R64CsrDecode.v](control/R64CsrDecode.v) | R64CsrDecode |
| [control/R64Serial.v](control/R64Serial.v) | R64Serial |
| [control/R64TrapVector.v](control/R64TrapVector.v) | R64TrapVector, R64TrapVectorStage |
| [control/R64Trigger.v](control/R64Trigger.v) | R64Trigger |
| [core/R64CoreTop.v](core/R64CoreTop.v) | R64CoreTop |
| [fp/R64FpCompletion.v](fp/R64FpCompletion.v) | R64FpCompletion |
| [fp/R64FpExecute.v](fp/R64FpExecute.v) | R64FpExecute |
| [fp/R64FpFast.v](fp/R64FpFast.v) | R64FpFast |
| [fp/R64FpFma.v](fp/R64FpFma.v) | R64FpFma |
| [fp/R64FpLong.v](fp/R64FpLong.v) | R64FpLong |
| [fp/R64FpOperand.v](fp/R64FpOperand.v) | R64FpDecompose, R64FpNormalize |
| [fp/R64FpProductPipe.v](fp/R64FpProductPipe.v) | R64FpProductPipe |
| [fp/R64FpRound.v](fp/R64FpRound.v) | R64FpRound |
| [fp/R64FpRoundStages.v](fp/R64FpRoundStages.v) | R64FpRoundRange, R64FpRoundShift, R64FpRoundDecision, R64FpRoundSelect, R64FpRoundIndexedDecision, R64FpRoundPack, R64FpRoundPipe |
| [fp/R64FpUnpack.v](fp/R64FpUnpack.v) | R64FpUnpack |
| [frontend/R64Align.v](frontend/R64Align.v) | R64Align |
| [frontend/R64FetchStream.v](frontend/R64FetchStream.v) | R64FetchStream |
| [frontend/R64Frontend.v](frontend/R64Frontend.v) | R64Frontend |
| [frontend/R64PacketParse.v](frontend/R64PacketParse.v) | R64PacketHeader, R64PacketParse, R64AlignPairView |
| [frontend/R64Predictor.v](frontend/R64Predictor.v) | R64Predictor, R64SumEqual, R64PredictionPrepare |
| [frontend/R64Rvc.v](frontend/R64Rvc.v) | R64Rvc |
| [lsu/R64Dcache.v](lsu/R64Dcache.v) | R64Dcache |
| [lsu/R64DcacheAmoParts.v](lsu/R64DcacheAmoParts.v) | R64DcacheAmoParts |
| [lsu/R64LoadStore.v](lsu/R64LoadStore.v) | R64LoadStore |
| [lsu/R64Lsu.v](lsu/R64Lsu.v) | R64Lsu |
| [lsu/R64LsuCompletion.v](lsu/R64LsuCompletion.v) | R64LsuCompletion |
| [lsu/R64LsuForwardByte.v](lsu/R64LsuForwardByte.v) | R64LsuForwardByte |
| [lsu/R64LsuMetaRead.v](lsu/R64LsuMetaRead.v) | R64LsuMetaRead |
| [lsu/R64LsuOrderSelect.v](lsu/R64LsuOrderSelect.v) | R64LsuOrderSelect |
| [lsu/R64LsuRequestQueue.v](lsu/R64LsuRequestQueue.v) | R64LsuRequestQueue |
| [lsu/R64LsuSelect.v](lsu/R64LsuSelect.v) | R64LsuSelect |
| [lsu/R64LsuYoungestByte.v](lsu/R64LsuYoungestByte.v) | R64LsuYoungestByte |
| [lsu/R64MemoryService.v](lsu/R64MemoryService.v) | R64MemoryService |
| [lsu/R64MemorySplit.v](lsu/R64MemorySplit.v) | R64MemorySplit |
| [memory/R64DataProtection.v](memory/R64DataProtection.v) | R64DataProtection |
| [memory/R64DataTranslation.v](memory/R64DataTranslation.v) | R64DataTranslation |
| [memory/R64FetchProtection.v](memory/R64FetchProtection.v) | R64FetchProtection, R64FetchProtectionPrepare, R64FetchProtectionFinish, R64FetchPma16 |
| [memory/R64FetchTranslation.v](memory/R64FetchTranslation.v) | R64FetchTranslation |
| [memory/R64ICache.v](memory/R64ICache.v) | R64ICache |
| [memory/R64Memory.v](memory/R64Memory.v) | R64Memory |
| [memory/R64PageWalk.v](memory/R64PageWalk.v) | R64PageWalk |
| [memory/R64Pma.v](memory/R64Pma.v) | R64Pma |
| [memory/R64PmaRange.v](memory/R64PmaRange.v) | R64PmaRange |
| [memory/R64PmpCheck.v](memory/R64PmpCheck.v) | R64PmpCheck |
| [memory/R64PmpDecode.v](memory/R64PmpDecode.v) | R64PmpDecode |
| [memory/R64PtePort.v](memory/R64PtePort.v) | R64PtePort |
| [memory/R64Tlb.v](memory/R64Tlb.v) | R64Tlb |
| [memory/R64Translation.v](memory/R64Translation.v) | R64Translation |
| [platform/R64AxiFabric.v](platform/R64AxiFabric.v) | R64AxiFabric |
| [platform/R64AxiPlatform.v](platform/R64AxiPlatform.v) | R64AxiPlatform |
| [platform/R64AxiReadService.v](platform/R64AxiReadService.v) | R64AxiReadService |
| [platform/R64AxiRegisterPort.v](platform/R64AxiRegisterPort.v) | R64AxiRegisterPort |
| [platform/R64AxiRtc.v](platform/R64AxiRtc.v) | R64AxiRtc |
| [platform/R64SystemTop.v](platform/R64SystemTop.v) | R64SystemTop |
| [platform/R64TensorLink.v](platform/R64TensorLink.v) | R64TensorLink |
| [platform/R64TensorMemory.v](platform/R64TensorMemory.v) | R64TensorMemory |
| [platform/R64TensorSystemTop.v](platform/R64TensorSystemTop.v) | R64TensorSystemTop |
