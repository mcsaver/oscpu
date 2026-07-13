# 规范：整数 full-WB 与 EX fast broadcast 分离

> 模块：`OooIntBackend`、`OooDispatchBackend`、`OooIntIssueQueue`、`OooPhysRegFile`。
> 状态：**T3B 已实现并验证；T3G 已将 fast 从 EX/MEM 收紧为 EX-only（2026-07-13）**。
> 目标：结构切断 MulDiv/CLMUL response→full-WB→PRF/IQ→branch-kill 的108条组合反馈环，
> 不延迟 long-op 当拍 kill；EX producer→consumer 仍保持同拍快路。

## 1. 根因与范围

current A 的109个 OpenSTA combinational loops 中，108个共享 MulDiv/CLMUL response→WB 边：
38个经 PRF write-through，70个经 IQ same-cycle wakeup/select。ROB age/tag 使它们在合法动态状态
不可激活，但门级 STA 无法推导该相关性；禁止用 false-path 掩盖。

本刀只分离“正式完成”与“允许同拍消费”的广播类别：

- **full WB**：EX、MEM、MulDiv、CLMUL、FPWB 的唯一正式完成总线；ROB/BusyTable/IQ 状态/PRF
  时序写仍全部消费它。
- **fast broadcast**：物理独立的 EX-only `{valid,pdest,data}`；只给 IQ 当拍 select 和整数
  PRF read0–3 write-through 使用。T3B 最初允许 MEM，T3G 根据 fresh DCache 长路径反例将其
  收紧为 EX-only；不得从 `wb*_pdest/data` 通用 mux 反解。
- MEM、FPWB 与 MulDiv/CLMUL 都是 non-fast；其依赖者在正式 WB 后下一拍才可 select。
- T3B 实施时 PRF read8 曾保留 full-WB write-through，因为它不在当时的 108 环范围内；
  T3E fresh top40 证明该路径会继续进入 FP execute，故 T3F 契约已将 read8
  收紧为只读 `regs_q`，见 `ooo-int-to-fp-sticky-wakeup.md`。

## 2. 接口契约（六类）

### 2.1 握手

- 不新增 ready/valid handshake；full WB 的 valid、payload、仲裁优先级与 response ready 完全不变。
- fast broadcast 是一次性组合事件，必须是同 lane full WB 的子集：`fast_valid -> full_valid &&
  fast_pdest==full_pdest && fast_data==full_data`。
- fast source 只能是该 lane 已获正式 WB 仲裁的 EX；MEM/long-op/FPWB 不得进入 fast payload mux。

### 2.2 stall / backpressure

- EX/MEM/long-op/FPWB 的正式 WB 反压不变；MulDiv/CLMUL `resp_ready` 仍只由 full-WB 仲裁决定。
- IQ select 只看 fast wakeup；IQ compaction survivor、dispatch insertion、kill survivor 的 ready
  next-state 全部继续吸收 full wakeup，保证 non-fast pulse 不丢。
- 若 MEM/long-op/FPWB producer 在 N 拍正式 WB：N 拍依赖项不得因该 pulse 进入 select；N 上升沿 PRF
  写入且 IQ ready sticky；N+1 依赖项可 select 并从 `regs_q` 读到新值。
- EX fast producer保持 N 拍 wakeup→select→PRF bypass，不增加拍数。

### 2.3 flush / kill / redirect

- branch mispredict 对 MulDiv/CLMUL 的当拍 `kill_inflight` mask 与状态清除完全不动；禁止把 kill
  打拍或把 wrong-path response 先缓存再决定。
- IQ `kill_valid` 拍仍禁止 issue；存活前缀必须吸收同拍 full wakeup。年轻后缀按既有 ROB age 清除。
- fast broadcast 无状态；reset/flush 后不保留或重放事件。full WB 与 ROB-walk 的既有优先级不变。

### 2.4 异常序

- full WB 仍是 ROB done/exception/cause/tval/fflags 的唯一真源，本刀不改 commit 或精确异常点。
- fast 只携带 operand payload，不拥有 exception；异常 uop 的正式完成与 squash 语义维持现状。
- non-fast 结果晚一拍被依赖者选中，不改变 producer/consumer ROB 年龄与提交全序。

### 2.5 访存序

- accepted MEM response 只走 formal WB，不来自 request、MIQ peek 或 pending payload 的任何
  旁路；SQ/MIQ/order、MMIO、AMO/LRSC、bridge drain 均不变。
- load-use 在 response N 沿写 PRF/置 sticky，N+1 消费；load completion/commit 不增加拍数。

### 2.6 投机恢复 / 单一真源

- full WB 是完成/状态更新唯一真源；fast 只是 full WB 的受限投影，不产生第二份完成状态。
- fast payload 必须直接从 raw EX winner 构造；不能从通用 full-WB payload mux再加分类 bit。
- PRF 时序写仍只用 full write ports；read0–3 只用 fast bypass；read8 的 T3F 最终
  边界是不使用任何同拍 bypass，只读已落账 `regs_q`。

## 3. 周期与优先级模型

| producer class | N 拍 full WB | N 拍 IQ select | N 拍 PRF read0–3 | N+1 |
| --- | --- | --- | --- | --- |
| EX | valid | fast wakeup可选 | fast新值 | 已写值 |
| MEM | valid | 不因本次WB可选 | 旧值 | sticky ready + 已写新值，可选 |
| MulDiv/CLMUL | valid | 不因本次WB可选 | 旧值 | sticky ready + 已写新值，可选 |
| FPWB→GPR | valid | 不因本次WB可选 | 旧值 | sticky ready + 已写新值，可选 |

同 lane full source priority 仍为 `EX > MEM > MulDiv > CLMUL > FPWB`。fast 只复制其中
合法 EX winner；不存在把低优先 source 绕过已占 lane winner 单独广播的情形。

## 4. 可执行不变量与 RED

- `FAST-WB-SUBSET`：PRF bypass valid 必须逐 lane匹配 full write valid/addr/data；故意 mutation
  fast payload 必须只触发目标 marker。
- `FAST-WAKE-SUBSET`：IQ select wakeup 必须逐 lane匹配 full wakeup valid/pdest；故意 mutation
  必须只触发目标 marker。
- IQ RED：full-only WB0、WB1、两 lane、mixed fast+long、compaction+dispatch、kill survivor。
- PRF RED：T3B 原始证据要求 full-only 写回时 read0–3 沿前旧/沿后新、read8
  同拍见 full 新值；T3F 已用 fresh STA 反例修订 read8 合同为沿前旧/沿后新。
- IntBackend RED：真实 DIV/CLMUL→dependent branch/ALU 在 response 拍不 issue，下一拍以正确值 issue；
  覆盖 WB0/WB1 与 older/younger branch kill。
- STA：fresh 同参数 `check_setup` 目标从109降到1，且 top path/loop 中无
  MulDiv/CLMUL→IQ-select 或 PRF read0–3 arc；剩余 FP admission SCC 独立处理。

## 5. 非声明

T3B 不修唯一 FP admission credit 真环；T3G 的 MEM formal-only 细化合同与 RED/STA 门禁见
`ooo-mem-formal-only.md`。任一阶段都不单独构成 physical 200MHz signoff。
