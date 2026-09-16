# 规范：整数 EX sticky wakeup / PRF 落账边界

> 模块：`OooIntBackend`、`OooDispatchBackend`、`OooIntIssueQueue`、
> `OooPhysRegFile`。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：T3M sticky-only 合同已落地；2026-07-19 v8d 进一步补齐整数 EX completion
> 在 selective-kill 同拍的授权截断。fresh 5 ns/PPA 仍须由独立 current-design 证据裁决。

## 1. 目的、根因与范围

T3L fresh 5 ns OpenSTA 的 top40 全部从 `ex0_valid_q` 起，经整数 EX 同拍
fast wake、IQ resident select、PRF fast bypass、ALU0、不可达的 lane0→lane1
结果前递、ALU1、正式 WB/ROB 与 CSR request，终止在 `CsrFile` 状态寄存器。
最差 arrival `13.340 ns`、WNS `-8.390 ns`。这不是 false path：EX producer 与
resident dependent consumer 的 same-cycle wake/read 是活跃架构合同；必须用真实流水边界
切断，禁止用 false/multicycle 约束掩盖。

T3M 将整数 EX 与此前已经 sticky-only 的 MEM、long-op、FP→integer completion 统一：

```text
cycle N：EX completion 只形成正式 WB event；resident dependent 不因该 event 同拍 select，
         PRF read0-3 仍见沿前 regs_q。
edge N ：正式 WB 同沿写 PRF regs_q、更新 IQ src-ready / BusyTable / ROB done。
cycle N+1：dependent 最早可 select，并从 regs_q 读到新值。
```

本切片物理删除 `select_wakeup0/1_*` 与 `bypass0/1_*` 接口以及 EX fast broadcast。
正式 `wb0/1`、PRF write、IQ sticky wake、BusyTable、ROB、commit/exception/fflags owner
保持不变。跨 lane `issue0_current_result` mux 与 `RAW-I1` 本轮不改：前两轮删除 A/B
曾恶化物理结果，T3M 只建立上游流水边界，fresh 后再独立裁决该 mux。

## 2. 接口契约

### 2.1 owner 与端口变化

| 边界 | T3M 合同 |
| --- | --- |
| `OooIntBackend -> OooDispatchBackend` | 只保留正式 `wb0/1` completion。删除四个 `select_wakeup*` 端口；不得以别名、tie-off 或新 fast 名称回流 IQ select。 |
| `OooDispatchBackend -> OooIntIssueQueue` | `wakeup0/1` 仍逐 lane 传正式 WB valid/tag，唯一用途是沿上更新 resident、dispatch insertion、compaction 与 kill-survivor 的 `src*_ready_q`。 |
| `OooIntBackend -> OooPhysRegFile` | `write0/1` 是唯一 payload 更新 event。删除六个 `bypass*` 端口；read0-3/read8 均只读已落账 `regs_q`。 |
| ROB / BusyTable / commit | 正式 WB valid/tag/data/exception/cause/tval/fflags 及其优先级不变；本切片不新增 completion queue 或重放 owner。 |

整数 preg0 仍是 x0：read 恒 0，write/wake 不产生有意义依赖。正式异常 completion 的
既有 speculative PRF/IQ 行为不在本切片改变；架构副作用仍由最老 trap commit 与随后 flush
裁决，年轻项不得越过既有 SQ/ROB 精确边界提交。

### 2.2 六类跨模块合同

| 类别 | 冻结合同 |
| --- | --- |
| 握手 | 不新增 ready/valid 通道。正式 WB 仍是单拍、无 consumer-ready 的 completion event；所有需要跨拍保持的就绪信息只由 IQ/BusyTable 寄存状态持有。 |
| stall/backpressure | resident dependent 在 N 拍即使下游 ready 也不得因 WB 同拍发射；N 沿 sticky 后可在 N+1 发射。若 N+1 仍反压，ready 必须保持直到唯一一次 fire。 |
| flush/redirect | `rst/flush` 在 IQ 清队与 PRF recover 中均高于 wake/write；branch kill 压 issue、清年轻后缀，同时存活前缀仍吸收同拍正式 WB。kill 拍 dispatch 继续由上游 freeze 禁止。 |
| 异常序 | ROB done/exception owner 和 commit 全序不变；屏障只延迟年轻 consumer 的 select。异常 producer 的年轻 speculative 工作最终仍由精确 trap flush 清除，不能成为架构提交。 |
| 访存序 | MIQ/SQ/AXI、committed store 与 nokill 事务均不改。load、AMO、MulDiv、CLMUL 本来已 formal-only；EX 现在与它们共享 N 沿落账/N+1 消费边界。 |
| 投机恢复/单一真源 | `OooPhysRegFile.regs_q` 是 operand payload 唯一真源，IQ `src1/2_ready_q` 是 resident 可选择资格唯一真源；wake 只是同沿 event，不得直接驱动 select/data。 |

## 3. 周期、碰撞与优先级

### 3.1 resident consumer

| 时刻 | formal WB | IQ ready | PRF read0-3 | consumer |
| --- | --- | --- | --- | --- |
| N 沿前 | valid/tag/data | 旧 sticky=0 | 旧 `regs_q` | 不可 select |
| N 上升沿 | 写 PRF/ROB/BusyTable | matching source 置 1 | — | — |
| N+1 | pulse 可撤回 | sticky=1 | 新 `regs_q` | 最早可 select/fire |

### 3.2 必须保真的同拍碰撞

1. **dispatch + WB**：新 consumer 的 `src*_ready_next` 必须 OR 匹配的正式 wake；N 拍不
   issue，N 沿同时入队/写 PRF/置 ready，N+1 可发射，唯一 pulse 不丢。
2. **compaction + WB**：未 fire survivor 搬移时必须在 next-state 合并 wake，不能只复制旧 ready。
3. **kill + WB**：严格年轻 raw EX completion 先在 WB/PRF/Busy/IQ/ROB 入口组合失去授权，
   不属于 formal WB；存活的 boundary/equal 与 older completion 才可被前缀吸收并 wake。
   kill 当拍 issue=0、dispatch=0，stage `kill_i` 负责沿上清状态，不能替代同沿副作用截断。
4. **双 WB / 双源**：src1/src2 可分别匹配 lane0/lane1，同沿后均 ready；同地址双写仍由
   PRF 既有 write1 后写覆盖给出确定值。
5. **flush + WB**：flush/recover 胜出；IQ 不保留项，PRF 从 committed GPR 恢复，旧 wake/write
   不得在 flush 后复活 speculative preg。
6. **backpressure**：N+1 未 fire 时 sticky 保持；解除 ready 后只 fire 一次。

全局优先级仍为 `rst > trap/exit > CSR/xRET > branch mispredict/ROB-walk > prediction >
sequential`。T3M 不移动 CSR/trap event，也不把 wake 注册成新的 redirect 源。

## 4. 不变量与可执行牙齿

1. **IQ-INT-WAKE-STICKY-ONLY**：任一 issued integer source（preg!=0）必须在沿前已有对应
   `src*_ready_q=1`；同拍 wake 不能替代该状态。
2. **PRF-INT-READ-STORED-ONLY**：read0-3/read8 必须精确等于 x0-zeroed `regs_q` view；
   正式 write 在 N 沿前不可见，N+1 才可见。
3. **无 fast ABI**：四个 production RTL 中不得出现 `select_wakeup`、PRF `bypass` 或
   `fast_wb` 数据/valid 接线；正式 WB→IQ state / PRF D / ROB state 路径必须仍存在。
4. **碰撞不丢 wake**：resident、dispatch insertion、compaction survivor、kill survivor 四个
   next-state 入口都必须 OR full wake match；删除任一入口的可编译 mutation 必须失败。
5. **RAW-I1 保持**：合法双 issue 的 lane1 enabled integer source 不得匹配 lane0 pdest；
   T3M 不以删除 PRF bypass 为由弱化既有断言或制造旧值消费窗口。

负探针必须精确命中 sticky-only / stored-only marker；source mutation 至少覆盖：重新把
full wake OR 进 resident select、删除 dispatch/WB collision 捕获、给 PRF read0 恢复同拍
write-through。mutation 必须编译成功并由行为/断言杀死，编译失败不算证据。

## 5. 验证与 200 MHz 裁决

| 层次 | 通过判据 |
| --- | --- |
| source/interface | 无 fast ABI；formal WB 的 IQ/PRF/BusyTable/ROB consumers 完整；lint/style/contract/elaboration 通过。 |
| focused dynamic | resident lane0/lane1、src1/src2、dual-source、dispatch collision、compaction、kill、flush、backpressure 均证明 N 不 issue、N+1 正确 issue/data。 |
| mutation/negative | 至少三个可编译 mutant 被预期断言或定向检查精确杀死；negative 日志只命中目标 marker。 |
| full functionality | module 全绿；official/privileged `177/177`；CoreMark 10 iter 为 GOOD TRAP/CRC `fcaf` 并记录 cycles/commits；OS smoke 无 panic/assert。 |
| focused STA | T3L 正对照能命中 `ex0_valid -> IQ select/PRF/execute`；T3M 原跨界路径为 0，同时 EX 正式 WB 到 IQ/PRF/ROB 的时序端点非空。 |
| global STA | current-source fresh、冻结 H7CL liberty 与 5.000 ns；`loops=0`，报告 WNS/TNS/top40。只有 `WNS>=0 && TNS>=0` 才宣称 200 MHz。 |

局部架构 PASS 不等于父目标完成。若旧路径退出但新路径仍负 slack，必须报告新起终点与共享
组合前缀后继续下一切片；不得把排名退出、投影、旧网表或 `NO_TIMING_PATH` 空查询冒充达标。

## 6. 风险与回退

- 连续整数 EX RAW 链每级增加一拍，CoreMark cycles 预计上升；这是显式的 Fmax/CPI 权衡，
  必须量化，不能伪称 cycle-exact。
- 若 full WB 与 PRF write/IQ ready 不是同一 event 或同一沿，会出现 stale operand 或永久睡眠；
  任何 focused 反例未闭合都必须回退。
- 保留的不可达 lane0→lane1 mux 可能成为下一条 IQ-Q→ALU0→ALU1 长路径；T3M fresh 后
  再作为独立结构 A/B，不与本屏障混改。
- 回退基线为 T3L canonical netlist/source 快照；本切片不修改时序约束。

## 7. 变更记录

- 2026-07-19（v8d）：补充 raw/effective completion、strict-younger kill 与 survivor-WB 合同；
  禁止用“ROB 后续 squash”解释 pre-ROB PRF/wakeup 副作用。
- 2026-07-13：T3M 接口冻结；定义 EX sticky-only、PRF stored-only、碰撞/flush/kill
  合同、可证伪门禁与 fresh 5 ns 裁决口径。
