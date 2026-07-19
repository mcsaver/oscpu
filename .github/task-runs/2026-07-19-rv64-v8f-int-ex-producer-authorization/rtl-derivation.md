# v8f RTL derivation（RTL 前冻结）

## 四阶段推导

1. **行为**：当前 generation 的 integer EX formal completion 正常生效；非当前 generation 的
   raw stage 仍被消费，但不得产生任何 formal-completion 副作用。fixed early wake 同样 exact。
2. **状态**：把 IQ、memory reservation、EX stage 的 raw-index holder 替换成 full-ID holder；
   raw index 由低位派生。净状态增量仅 generation：IQ `8x4=32b`、reservation `4b`、
   EX0/EX1 `2x4=8b`，合计 44b；ROB query 无新状态。
3. **数据通路**：ROB 组合比较只读 `valid_q/done_q/slot_generation_q`；比较结果在 shared WB
   仲裁前与 v8d kill-cut 相与。early query 只门控 sticky D，不进入 resident select。
4. **控制**：不改 dispatch/issue/transport ready；mismatch drop 不反压 raw producer。reset/flush
   fail closed；selective recovery 仍由 v8d strict age 决定即时 kill。

## 拓扑九项

1. **source owner**：`OooRob.slot_generation_q` 与 allocation slot。
2. **stateful holders**：`OooIntIssueQueue.producer_id_q[8]`、
   `OooIntBackend.mem_issue_res_producer_id_q`、两个 EX `PipeStageReg` payload。
3. **legacy projection**：所有 raw `rob_idx` 由 full ID 低位派生，仅作地址/年龄。
4. **authorization owner**：`OooRob` 的 issue-current 与 completion-open exact query。
5. **kill overlay**：`exN_pre_auth_valid = raw_valid && !exN_kill_now`；exact match 在其后。
6. **side-effect fanout**：effective EX valid → WB arbiter → ROB/Busy/IntIQ，同时直达 PRF、FP IQ
   integer wake、registered forward 与 public completion。
7. **backpressure topology**：query 不进入 dispatch/issue/WB ready；mismatch 释放当拍 WB source slot。
8. **priority**：`rst/flush > selective kill > exact current/open > shared source arbitration`；
   alternate MEM/long/FP source可占用被 stale EX 释放的槽。
9. **remaining cut**：async memory、MulDiv、CLMUL、FP 与 branch resolve 仍未携带/消费 full ID；
   全局 lease/collision fence 亦未建立，状态显式 RED。

## 预期关键路径与 PPA 风险

- 新弧为 `ROB valid/done/generation Q -> PID compare -> EX source valid -> shared WB valid`。
- PID 不进入 IQ eligibility/onehot/PRF read，不扩大既有 select critical cone；IQ payload mux新增 8-bit。
- 44b 净状态是合同值，不等于综合面积结论。只有 fresh same-design netlist/STA/power 才能评价 PPA。
