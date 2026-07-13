# 规范：FP wake 全消费域 sticky barrier

> 模块：`OooFpIssueQueue`、`OooIntIssueQueue`、`OooFpPhysRegFile`、`OooFpBackend`。
> 状态：**T3H RTL/全功能与定向时序合同已 GREEN；fresh 5 ns WNS 仍为负（2026-07-13）**。
> 目标：切断 FP execution/load completion 到 FP 算术和 FP-store 两类 resident
> consumer 的同拍 select/data bypass；保留完成、写回和下一拍依赖唤醒。

## 1. Fresh STA 根因

T3G 已把 integer MEM completion 从 fast-WB 移除，但 fresh 5 ns top1 仍为：

```text
DCache SRAM/tag/hit
 -> fpld_wb_valid / fp_wake1
 -> IntIQ resident FP-store source same-cycle ready
 -> integer PRF / ALU / memory-control / ROB-control
 -> FetchPacketCache payload SRAM en_i
```

top1 arrival `16.137 ns`、WNS `-12.979 ns`。定向报告同时给出
DCache→integer ex0/ex1 `-4.900/-7.150 ns`、DCache→FP exec1 `-8.149 ns`，以及
FpIQ Q→FP exec1 `-3.484 ns`。网表 cell `_69386_` 的输出是
`fpld_wb_valid_w`，证明 DCache→integer stage 残余不是 T3G integer MEM fast 回归，
而是 FP-load-to-store 快唤醒。

只切 FpIQ 会留下已证实的 IntIQ FP-store 首路径；只切 tag ready 而保留 FP PRF
write-through 会留下 payload 长弧或让 consumer 在数据尚未落账时发射。因此 tag 与 data
边界必须原子修改。

## 2. 冻结架构

- `fp_wake0`（FP execution completion）与 `fp_wake1`（FP load WB）继续作为单拍正式
  写回事件，继续清 `fp_busy_q`、写 FP PRF、更新 resident/dispatch collision sticky；
  producer completion/ROB/fflags/commit latency 不变。
- FpIQ resident entry 的 fs1/fs2/fs3 ready 组合视图只读
  `fs1_ready_q/fs2_ready_q/fs3_ready_q`。任一匹配 wake 在 N 沿置 sticky，N+1 才可
  oldest-select。GPR source 继续沿用 T3F sticky-only。
- IntIQ resident FP-store source 的 ready 组合视图只读 `fp_st_ready_q`；wake0 和 wake1
  都只在 compaction/kill-survivor next-state 落账，N+1 才可发射。
- dispatch 本身不进入任何 IQ same-cycle select。dispatch 与 wake 同拍时，入队写臂仍
  OR 对应 wake，防止唯一脉冲丢失；下一拍从已写 PRF 读取。
- `OooFpPhysRegFile` R0/R1/R2（FP issue 三源）与 R3（FP-store data）全部只读
  `regs_q[addr]`，不再消费 write0/write1 同拍旁路。f0/preg0 是真实 FPR，禁止整数 x0
  特判；write1 与 write0 同地址时，时序写仍保持 write1 后写覆盖。
- `fp_src_ready` 的 dispatch 查询可继续前视本拍 completion，因为其结果只写入新 entry
  sticky，且 dispatch→issue 已有寄存边界；不新增 wake FIFO、replay 或第二份 busy 真源。

## 3. 六类接口合同

### 3.1 握手

- 不新增或注册 producer ready/valid；FP arithmetic、long-op、load WB 与 done FIFO owner
  不变。
- IQ dispatch/issue ready-valid 端口和队列容量不变；只改变 resident source 成为 ready 的
  可见周期。

### 3.2 stall / backpressure

- N 拍匹配 wake 不得让 waiting resident consumer issue；N 沿写 PRF/ready；N+1 可 issue。
- downstream blocked 时已 sticky 的 entry 保持 ready；独立 ready entry 与无关 wake 不得被
  阻塞。稳态独立 FP 吞吐不变，producer-dependent latency增加一拍。

### 3.3 flush / kill / redirect

- flush 全清 IQ/恢复 FP rename/PRF 的现有 owner 不变，flush+dispatch+wake 不得复活 entry。
- kill 拍冻结 issue；存活前缀必须吸收 wake0/1，年轻后缀必须 squash；recover 多拍后存活项
  仍可从 sticky state 发射。

### 3.4 异常序

- FP exception/fflags/ROB done 与 precise commit 顺序不变；consumer 晚一拍不改变 ROB age。
- GPR-destination FP completion 继续由 `fp_result_wb_valid && fp_result_wb_frd` 排除在 FPR
  wake/write 域之外。

### 3.5 访存序

- FP load request/response 与 FP store 的 MIQ/SQ/probe/drain owner 不变；仅 load-result
  consumer 和 FP producer→store data dependency 增加一拍。
- FP-store R3 读取发生在 sticky ready 后，故数据已经在上个上升沿写入 `regs_q`。

### 3.6 恢复 / 单一真源

- `*_ready_q` 是 resident 可发射唯一真源，`regs_q` 是 operand data 唯一真源，full FP
  completion 是写回唯一真源。
- 禁止用 false-path、multicycle、宏 setup 豁免或另建旁路恢复同拍消费。

## 4. 周期模型

| 周期 | FP completion/write | resident select | FP PRF read | state |
| --- | --- | --- | --- | --- |
| N 沿前 | wake0 或 wake1 valid | 不因该 wake 发射 | 旧 `regs_q` | sticky 仍低 |
| N 上升沿 | `regs_q` 写入 | — | — | matching sticky 置高 |
| N+1 | pulse 可撤回 | 可发射 | 新 `regs_q` | sticky 保持 |

dispatch+wake collision 在 N 沿直接写入 sticky，entry 最早仍从 N+1 发射。

## 5. RED、断言与门禁

- IntIQ：resident FP-store 只等 preg24，wake1 N 拍旧 RTL 会 issue；新合同要求 N 不
  issue、N沿 sticky、N+1 issue。dispatch0/1 × wake0/1 四象限由 IQ 自身捕获，且至少
  两象限使用真实 f0/preg0，禁止复用整数 x0 matcher。
- FpIQ：分别用 resident fs1/fs2/fs3 与 wake0/wake1；N 不 issue、N+1 issue，并覆盖
  dual-source/dual-wake、dispatch collision、FP wake 的 kill/recover/flush 和 preg0。
- FP PRF：预写 OLD；write0 命中时 N 拍 R0–R3 全 OLD、N+1 全 NEW；write1 同理。
  同地址双写 N+1 仍见 write1，recover 与 preg0 不退化。
- `[FP-IQ-FP-STICKY-ONLY]`：任何 issued enabled fsN 必须已有对应 `fsN_ready_q`。
- `[IQ-FP-WAKE-STICKY-ONLY]`：任何 issued FP-store source 必须已有 `fp_st_ready_q`，
  断言必须同时覆盖 wake0/1 与 issue0/1，而不是只在 wake0 命中时检查。
- `[FP-PRF-STORED-ONLY]`：R0–R3 输出必须等于相应 `regs_q`；natural write hit + force
  read-output negative 必须精准命中该 marker。
- 已验证 focused、全 module `95/95`、lint/style/contract `85/85`、full build、AM、
  177 official/privileged 与 FP ISA；CoreMark 10 iter 为 `3,020,147 cycles`、
  `3,218,532 commits`、CPI `0.938`、CRC `fcaf`，与 T3G cycle-exact。
- fresh 5 ns 必须 `loops=0`。DCache→integer ex0/ex1 与 DCache→FP exec1 的旧长弧
  必须消失；允许保留不经过 wake/select/data-bypass 的短资源控制弧，但三个 directed
  report 必须集合非空且全部 `MET`。wake/write-through 到 execute/read-data 的 20 组
  forbidden report 必须精确为 `NO_TIMING_PATH`，fanout 只能终止于各自状态 owner。
  只有全局 WNS `>= 0` 才可声明 200 MHz。

## 6. 非声明

- T3H 不保证纯 FpIQ state→oldest-select→FP PRF→FpConvert 的 `-3.484 ns` 本域路径闭合；
  若它成为新首路径，下一刀应评估 elastic FP issue/preg stage。
- 本刀不注册 FP completion、不改变 FP arith 5-cycle macro合同，也不改变 fetch SRAM setup。

## 7. Fresh 5 ns 裁决

- Yosys 两轮均为 `110 candidates - 5 empty = 105 effective`，三次 check 为零问题，
  网表 `110 module / 110 endmodule`；综合输入 pre/post hash 完全一致。
- 已知标准单元面积 `1,572,550.00`，相对 T3G 减少 `806.12`（`0.051236%`）；四个
  placeholder macro 面积未知。
- 独立 OpenSTA：`loops=0`、WNS `-10.10 ns`、TNS `-201564.20 ns`、功耗代理
  `0.120 W`。相对 T3G 的 `-12.979/-287092.31` 明显改善，但未达到 200 MHz。
- 三个 DCache 短控制 residual 分别为 `+1.468/+1.373/+0.155 ns`；20 个
  wake/write-through forbidden path 全部切断，六类 fanout 均只落本模块状态。
- FpIQ Q→FP exec1 仍为 `-3.516 ns`，但全局新 top 已转为 integer EX fast
  wake/select/PRF bypass→ALU/ROB/redirect→Fetch SRAM `en_i`，最差 `-10.097 ns`。
  下一轮必须优先切 integer EX 同拍快广播长链，再按 fresh residual 决定是否加入
  FP issue/preg elastic stage；不得用 false path 掩盖。
