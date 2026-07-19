# RV64 v8b-prep producer kill-now 原子合同

## 目标与边界

本切片只关闭两个已识别 production producer 的同拍 kill 可见性缺口：

- `OooClmulUnit` 的 request/RUN/RESP producer reference；
- `OooFpArithGate` 自流水 meta stage5 的 completion reference。

它们是 full-identity/no-live-reuse 的 producer-side 前置，不是 Q1A live 化，也不是
generation-safe identity 或全局 stale-WB 完结。`OooMmuEpochOwner`/`CsrFile`
shared abort、ROB slot reuse、其他 producer/holder 仍保持 RED。

## 根因

旧 RTL 把 `kill_valid_i`/`kill_rob_idx_i`/`rob_head_idx_i` 作为 Verilog
function 的 ambient 自由变量，连续赋值只显式传入 producer index。在 Icarus
12.0 下，当 index/state 保持不变、仅 kill/head/cut 中一项变化时，该调用不重算：

- CLMUL matching kill 同拍仍可接受 request，RUN/RESP holder 不清；
- FP stage5 matching kill 同拍 `out_valid` 保持旧高值。

修复前动态现场分别为 10 个和 3 个 directed failure，且两者都 compile/elaborate
成功；因此这是仿真语义反例，不是编译器拒绝造成的假红。综合后硬件是否同样出错
本轮未证明，禁止宣称 silicon bug 或 PPA 收益。

## 冻结方程

对等宽 `ROB_INDEX_W` 值做模减：

```text
age(x)          = x - rob_head_idx
strict_younger  = age(x) > age(kill_boundary)
matching_kill   = kill_valid && strict_younger
```

- 必须使用严格 `>`；`x == kill_boundary` 的 recovery-causer 保留。
- `kill_valid`/producer idx/kill boundary/head 必须全部显式出现在组合依赖中。
- helper 若保留为 function，函数体只能读 formal，禁止读模块级 kill/head/cut。

CLMUL 优先级：

```text
reset/flush > matching inflight kill > request/iterate/response consume > hold
```

- matching request kill 同拍不得进入 RUN；
- RUN/RESP matching kill 同拍必须组合屏蔽 `resp_valid_o`；
- 同一时钟沿清 IDLE/held ROB idx/pdest/data，kill 撤销后不得重现旧 response；
- nonmatching/equal/older producer 必须正常完成。

FP arithmetic 优先级：

- launch 与每级 meta 推进都必须带 matching-kill gate；
- stage5 `out_valid_o` 必须额外消费当前拍 matching kill，不能只等寄存清除；
- stage5 的 `out_valid` 是 `OooFpBackend` 写 FP PRF/唤醒/入 done FIFO 前的最终
  arithmetic producer valid。

## production 调用链

```text
OooClmulUnit.resp_valid
  -> OooIntBackend.clmul_rsp_to_wb{0,1}
  -> wb{0,1}_valid / gpr_wb{0,1}_write_valid
  -> OooRob + BusyTable + IntIssueQueue + integer PRF

OooFpArithGate.out_valid
  -> OooFpBackend.fp_result_wb_valid
  -> FP PRF/wakeup + done FIFO
  -> fpwb_valid
  -> OooIntBackend shared WB
```

结构 checker 锁定该调用链不从 downstream 重建 producer valid；动态结论仍只覆盖
CLMUL/FP arithmetic producer-local kill。

## directed 与 mutation 硬门

Directed 必须覆盖：

1. CLMUL `16 x 16 x 16 = 4096` 组 strict circular age。
2. 只改 `kill_valid`/cut/head 的 delta-cycle 可见性。
3. CLMUL request-fire、RUN、backpressured RESP 三阶段。
4. wrap-younger、equal boundary、older survivor。
5. kill 后同 ROB idx 重发，只返回新 pdest/data。
6. FP stage5 cut-only、kill-valid-only、head-only wrap 反例及无延迟脉冲。
7. kill=0 的旧 CLMUL/FP arithmetic 功能回归。

Compile-success mutation 必须把以下语义错误打红：ambient function、漏 kill-valid、
inclusive boundary、raw index compare、漏 new-request kill、漏 response mask、漏 holder clear、漏 FP
stage propagation gate、漏 FP head 依赖。变异必须编译成功且由语义 oracle 失败；
compile fail/timeout/checker crash 不算通过。

## 可宣称矩阵

| 结论 | 预期状态 |
| --- | --- |
| CLMUL/FP arithmetic ambient kill dependency removed | GREEN |
| matching kill 同拍屏蔽并清除本地 holder | GREEN after gates |
| two identified production stale-producer holders reduced | GREEN after gates |
| all producer holders / downstream full identity | RED |
| ROB index reuse / generation / no-live-reuse | RED |
| live Q1 owner + mismatch kill-now + Q1/Csr shared abort | RED |
| global strict lint/default build | 继承状态，单独报告 |
| PPA/frequency/Linux | NOT MEASURED |
