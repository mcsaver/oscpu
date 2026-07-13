# 规范：整数 MEM completion 只走 formal WB

> 模块：`OooIntBackend`、`OooIntIssueQueue`、`OooPhysRegFile`。
> 状态：**T3G 已实现并通过功能门禁；fresh STA 保留该切点但未闭合 5 ns（2026-07-13）**。
> 目标：切断 DCache response 到整数同拍 IQ select/PRF bypass 的真实长路径；
> 保留正式完成、精确异常和下一拍依赖唤醒。

## 1. Fresh STA 根因

T3F fresh 5 ns top40 全部仍由 DCache SRAM 启动，top1 是：

```text
DCache SRAM/tag/hit
 -> OooMemAxiBridge response
 -> MEM fast wake / IntIQ same-cycle select
 -> integer PRF bypass / ALU / branch resolve
 -> long-op kill / formal WB tag
 -> FetchPacketCache SRAM en_i
```

top1 arrival `15.996 ns`，WNS `-12.838 ns`。这不是 false path：load 返回拍的
真实依赖者会被旧 RTL 同拍选择并消费返回数据。T3G 在 producer/consumer 之间建立
一个明确的时序边界。

## 2. 冻结架构

- full WB 不变，仍包含 `EX > MEM > MulDiv > CLMUL > FPWB`，并继续驱动 ROB done、
  BusyTable、IQ sticky ready、整数 PRF 时序写和 commit bypass。
- fast broadcast 收紧为 **EX-only**。逐 lane 必须精确等于
  `{ex_valid && !ex_exception && ex_pdest != 0,
  ex_valid ? ex_pdest : 0, ex_valid ? ex_result : 0}`；invalid EX 的脏 payload
  不得泄漏到 fast 观察面。
- MEM response 即使无 fault 也不得进入 fast wake 或 PRF read0–3 bypass；N 拍只正式
  写回，N 沿写 PRF 并置 IQ sticky，N+1 依赖者才可 select，并从 `regs_q` 读新值。
- FP load 不走整数 pdest，继续由既有 `fpld_wb` 写 FPR/wake；失败 SC 的本地 EX
  结果继续是 fast，LR/AMO/成功 SC 的总线响应则与普通 MEM completion 一样 formal-only。
- SQ-forwarded integer load 复用本地 EX stage，继续是 fast，不属于 MEM response。
- 不改 `mem_rsp_to_wb0/1` 仲裁、不改 response ready、不增加缓存或 replay 状态。

本规范自 T3G 起收紧并覆盖 `ooo-longop-fast-broadcast.md` 中“EX/MEM fast”的旧合同；
T3B 的 full/fast 物理解耦结构仍保留。

## 3. 六类接口合同

### 3.1 握手

- MEM request/response ready-valid 和正式 WB lane 仲裁逐拍不变。
- fast 不是第二份完成，只是当前 lane EX formal winner 的精确 operand 投影。

### 3.2 stall / backpressure

- N 拍 MEM response 可以正式 WB/commit，但驻留依赖项不得因该 response 同拍 issue。
- N 沿写 `regs_q` 与 IQ ready；N+1 依赖项可 issue。独立 load throughput、response
  接受能力和 producer commit latency不变，仅 load-result consumer 增加一拍。
- EX producer 的 N 拍 wake/select/bypass 保持不变，双 lane EX 覆盖必须继续通过。

### 3.3 flush / kill / redirect

- 正式 MEM WB 与现有 ROB walk/flush owner 不变；被 squash 的年轻 consumer 不得复活。
- surviving IQ entry 继续在沿上吸收 full wake；fast 无状态、不可重放。

### 3.4 异常序

- fault response 仍只由 full WB 写 exception/cause/tval；它本来就不产生合法 operand。
- 正常 response 的 consumer 晚一拍发射不改变 ROB 年龄或提交全序。

### 3.5 访存序

- MIQ/SQ、MMIO、LR/SC、AMO、drain 与 response ownership 均不变。
- formal-only 只改变整数 MEM result 的消费时刻，不改变 request/response 顺序。

### 3.6 恢复 / 单一真源

- `regs_q` 是 MEM payload 的 consumer 真源，IQ `ready_q` 是可发射真源。
- full WB 是 completion 真源；禁止从 full WB mux 反解 fast，也禁止给 MEM 新建旁路。

## 4. 周期模型

| 周期 | MEM formal WB | fast broadcast | dependent issue | source data |
| --- | --- | --- | --- | --- |
| N 沿前 | valid/tag/data | invalid（若无 EX） | 不因 MEM response 发射 | 旧 `regs_q` |
| N 上升沿 | PRF/IQ sticky 落账 | — | — | 写入新值 |
| N+1 | response 可撤回 | 仅可能来自 EX | 可发射 | 新 `regs_q` |

若 N+2 同时存在既有 EX0 与另一条 MEM response，则 EX0 仍是 fast-WB0，MEM 正式落
WB1，但 fast-WB1 必须无效；这同时验证 lane1 formal ownership 未被破坏。

## 5. RED、断言与接受门禁

- focused RED 使用两条在飞 load 与一个依赖 add：旧 RTL 在首个 response 拍错误产生
  MEM fast-WB0 并同拍 issue；新合同要求 N 拍 fast=0/issue=0，N+1 stored-only issue。
- 第二个 response 与依赖 add 的 EX completion 同拍，要求 WB0 EX fast 保留、WB1 MEM
  formal-only，覆盖 mixed EX+MEM 仲裁。
- `[INT-FAST-WB-EX-ONLY]` 必须逐 lane精确比较 fast 与 EX 投影；no-EX + 真实 MEM
  response 后强制 fast payload 的负探针必须只命中该 marker。
- focused、94 个 module TB、lint/style/contract、177 个 core regression、AM 和 CoreMark
  均需通过；CoreMark 周期变化必须定量报告。
- fresh 5 ns 综合/STA 必须继续 `loops=0`，并证明 DCache/MEM response 不再能到达
  fast wake 或整数 PRF bypass。只有 WNS `>= 0` 才能声明 200 MHz。

## 6. 非声明

- 本刀不保证 FetchPacketCache `en_i`、FP load wake、纯 FP IQ→convert 等剩余路径闭合。
- 禁止以 false-path、multicycle 或宏 setup 豁免替代真实寄存边界。
- T3G 是父目标的下一次可回滚实验；功能门禁或 fresh STA 反例未解决时不得保留。

## 7. T3G 实测裁决

- focused RED 证明旧 RTL 在普通整数 load response 的 N 拍同时产生 MEM fast-WB 和
  dependent issue；GREEN 后 N 拍只保留 formal WB，N+1 从 IQ/PRF 寄存状态发射。
- `[INT-FAST-WB-EX-ONLY]` 负变异在自然 MEM formal-WB0 场景只命中目标 marker；
  focused、94/94 module、lint/style/contract、AM、177/177 ISA/privileged 与 CoreMark
  全部通过。
- CoreMark 为 `3,020,147 cycles / 3,218,532 commits / CPI 0.938 / 3.379/MHz`，
  CRC `0xfcaf`；相对 T3F 多 `82,238 cycles`（`+2.80%`），符合 load-use 增加一拍。
- fresh 综合为 `105/105` effective ABC、check `0`、area `1,573,356.12`；独立
  OpenSTA 仍为 `loops=0`、WNS `-12.979 ns`、TNS `-287092.31 ns`。top1 不再是
  integer MEM fast payload，而是
  `DCache -> FP-load fpld_wb/fp_wake1 -> IntIQ FP-store same-cycle issue -> ALU/control
  -> FetchPacketCache en_i`。定向报告仍见 DCache 到整数 ex0/ex1 stage 的
  `-4.900/-7.150 ns`，其来源是上述 FP-load-to-store 控制快路，不是被本规范禁止的
  integer MEM fast broadcast。
- 因而 T3G 的整数完成边界作为已验证、可回滚切点保留，但父目标仍为 active；下一刀
  必须同时隔离 FP-load 对 FP IQ resident consumer 与 IntIQ resident FP-store 的同拍唤醒，
  不能把残余路径错误归类为 T3G 失效或用约束掩盖。
