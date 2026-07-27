# RV64 V9P SERIALIZE-G1 current-design contract

## 工作对象

本轮只处理本地 RV64 双发射 OoO 核的 system/CSR 串行提交架构，重点是
`OooFrontend`、`OooRob`、`OooControlEventApplySequencer`、`OooCoreTopGlue`
和 `NpcCoreTop` 之间的 head0 非 FP CSR 路径。

## 架构目标

- 以 queue-head CSR 作为产品架构方向，不把已实现的队头提交路径退回 pending full-drain。
- 在改变默认配置前，闭合合法 head0 CSR 的 dispatch、ROB owner、memory quiet、C0 full barrier、
  C1 typed apply、`CsrFile` 写入、年轻指令取消与重取。
- 保留 FP CSR、ECALL/xRET、FENCE/FENCE.I/SFENCE.VMA/SINVAL 等现有 pending-system 路径的
  独立类型和 owner，不把 Phase1 结论外推到尚未队头化的 system uop。
- 本轮首先是架构闭合；所有综合/STA/PPA 结果仍为诊断或未资格化，直到 full-core arch-stable。

## 允许改动范围

- queue-head CSR 默认配置及其一致的 NPC/Linux 构建入口；
- 直接承载上述路径的 RTL/spec/testbench；
- SERIALIZE-G1 current-design evidence、账本绑定和本 task-run；
- 必要的 AI 合同渲染规则与对应 e2e 证据。

## 禁止越级

- 不把局部 queue-head CSR 证据称为完整 system-uop 队头化；
- 不用 focused TB 代替 full functional/DiffTest/Linux gate；
- 不把当前切片称为 full-core ARCH_STABLE 或正式 PPA promotion。

