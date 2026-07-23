# v8h.1 合同修订：同拍 claim 与 dual-birth 结构证明

## 触发反例

ROB query 只读 edge-old `done_q`。若 EX、memory、MulDiv 或 CLMUL 在同一拍携带同一完整 PID，
它们可同时得到 exact-open；shared-WB transport priority不能约束独立的完成副作用。另一个反例是
同拍 mandatory/optional birth 若 PID 相同，registered live mask 在该拍对两者都仍为 0。

## 修订裁决

1. actual completion 使用 `EX0 > EX1 > memory > MulDiv > CLMUL` 的 full-PID claim 链。
2. claim 只门控 WB/PRF/Busy/IQ/ROB/public side effect；raw route、ready、holder FSM 与 lease mask
   完全不读取 claim 或 exact-open。
3. dual-birth 不由 mask仲裁；证明 ROB pair candidate 的低 index 位 `tail != tail+1`，并以 Q-only
   assertion、direct TB、compile-success mutation锁住该结构事实。
4. FP 尚无 full PID，因此不进入本次 claim 域；全局架构硬门继续 RED。

该修订覆盖原冻结合同中对“exact-open 足以唯一授权”的不完整表述；其它接口、状态、reset/flush/
kill 与 death-before-birth 规则不变。
