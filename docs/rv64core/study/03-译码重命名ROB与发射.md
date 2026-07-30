# 第 3 章：译码、重命名、ROB 与发射

## 3.1 本章要解决的矛盾

顺序程序里寄存器名字只有 `x0..x31`，但乱序执行要求后面的独立指令先跑。考虑：

```asm
mul x5, x1, x2    # I0，长延迟，写 x5
add x6, x5, x3    # I1，真依赖 I0（RAW）
add x5, x4, x7    # I2，再次写 x5（WAW）
sub x8, x5, x9    # I3，应读取 I2 的 x5
```

必须同时做到：

- I1 不能越过 I0 使用旧 `x5`；
- I2 可以先分配自己的结果位置，不必等 I0 真正写完；
- I3 必须依赖 I2，而不是 I0；
- commit 时仍按 I0、I1、I2、I3 顺序更新架构状态。

这就是 RAT、PRF、busy table、IQ 和 ROB 共同解决的问题。

## 3.2 两层译码

### 前端译码：为了知道“能不能现在派发”

前端的 `DecodeStage`、`OooFpDecode` 和 classify gate 会提前识别：

- 指令是否合法；
- 是否 branch/jump/memory/system/FP；
- 是否必须在 head 处理；
- lane1 是否受 lane0 barrier 限制；
- PC、RVC 长度和预测 next-PC。

这层译码更关注**控制安全性**。

### 后端译码：为了生成可执行 uop

`OooAluDecodeBackend` 中的两个 `DecodeStage` 为两个 dispatch lane 生成：

- ALU operation；
- source/destination register；
- immediate；
- branch compare kind；
- load/store width 和 signedness；
- word/dword 语义；
- CSR/system/illegal 等事实。

它再把整理后的 uop 交给 `OooIntBackend`。前后两层必须语义一致，但职责不同：
前端决定是否允许进入，后端决定进入后怎样执行。

一个重要的当前实现事实是：后端 `DecodeStage`、rename 计算、资源 ready 计算和 dispatch
admission 处在同一个组合锥中。它们不是“Decode 一拍、Rename 一拍、Dispatch 一拍”。
真正保存新 uop 的边沿，是 RAT、FreeList、Busy、ROB 和 IQ 同时接受
`dispatch*_fire` 的那个上升沿。

## 3.3 重命名：把“名字依赖”变成“数据依赖”

假设起始时架构 `x5` 指向物理 `p5`。

### I0 dispatch

I0 要写 `x5`：

1. free list 分配 `p32`；
2. rename map 更新 `x5 -> p32`；
3. ROB 保存 `new=p32, old=p5`；
4. busy table 标记 `p32` 未完成。

### I1 dispatch

I1 读取 `x5`，RAT 返回 `p32`，因此 IQ 中保存 source tag `p32`。这是真正的 RAW，
只有 I0 completion 才能唤醒。

### I2 dispatch

I2 再写 `x5`，可立刻分配 `p33`，RAT 更新 `x5 -> p33`，ROB 保存
`new=p33, old=p32`。I0 和 I2 不再争同一个物理位置，所以 WAW 消失。

### I3 dispatch

I3 读取的是当前 RAT 映射 `p33`，所以它依赖 I2。

映射结果：

```text
I0: x5 -> p32，保留 old p5
I1: src x5 == p32
I2: x5 -> p33，保留 old p32
I3: src x5 == p33
```

物理寄存器的释放必须等覆盖它的新写者退休。例如 I2 退休后，`p32` 才能归还，
因为在那之前 branch recovery 仍可能恢复到 I0 提供的映射。

## 3.4 双派发同拍依赖

如果同一个 fetch packet 的 lane0 写 `x5`，lane1 读 `x5`：

```asm
add x5, x1, x2    # lane0
sub x6, x5, x3    # lane1
```

lane1 必须看到 lane0 同拍刚分配的新物理目的，而不是 edge-old RAT 的旧 `x5`。
这是一条同拍 rename bypass。

```wavedrom
{
  "signal": [
    {"name": "clk",               "wave": "p...."},
    {"name": "dispatch0_fire",    "wave": "010.."},
    {"name": "lane0 rd",          "wave": "x=x..", "data": ["x5"]},
    {"name": "lane0 new_prd",     "wave": "x=x..", "data": ["p32"]},
    {"name": "dispatch1_fire",    "wave": "010.."},
    {"name": "lane1 rs1",         "wave": "x=x..", "data": ["x5"]},
    {"name": "lane1 renamed rs1", "wave": "x=x..", "data": ["p32"]},
    {"name": "lane1 src_ready",   "wave": "0...."}
  ],
  "head": {"text": "同拍 lane0 写、lane1 读：lane1 使用新分配的 p32"}
}
```

如果 lane0 没有真正 fire，lane1 不能偷偷消费这次候选分配。这就是为什么两条 lane 的
`valid`、资源许可和 fire 必须整体计算。

## 3.5 `OooDispatchBackend` 的原子分配

`OooDispatchBackend` 装配：

- `OooFreeList`：物理寄存器分配/回收；
- `OooRenameMap`：架构寄存器到物理寄存器映射；
- `OooBusyTable`：物理目的是否已有完成值；
- `OooRob`：程序顺序、完成与退休资格；
- `OooIntIssueQueue`：等待源操作数与执行资源。

对每条 lane，dispatch 至少需要：

```text
frontend valid
&& ROB 有空 entry
&& IQ 有空 entry
&&（若写 GPR）free list 有可用 PRF
&& 不被 flush/stop/barrier 阻止
```

双 dispatch 还需考虑 lane0 占用一个资源后 lane1 是否仍有第二份资源。正确实现不能先对
某个子结构写状态，再发现另一个子结构不够而留下“半条指令”。

双 lane 使用前缀语义：lane1 不能脱离 lane0 fire。对 mandatory pair，只要第二份
ROB/IQ/PRF 资源不足，两条都应停；只有明确标成 optional 的 lane1，才允许 lane0
单独前进。这个区别不能用“资源只剩一个时总是先发 lane0”概括。

## 3.6 Free List

`OooFreeList` 的学习重点不是“找第一个 1”，而是：

- 单周期可能分配 0、1、2 个物理寄存器；
- 单周期也可能由双 commit 回收旧物理寄存器；
- lane1 不能与 lane0 拿到同一个 index；
- 分配与回收同拍时要规定 edge-old/edge-new 视图；
- flush/recovery 不能让仍被活 producer 引用的寄存器提前复用。

`x0` 永远不需要新物理目的；写 `x0` 的指令仍可能进入 ROB，但不应耗掉 free entry。
复位后整数 free ring 提供 `p32..p63`；commit/walk 在某个边沿归还的物理号，按当前
edge-old 视图要到下一周期才会重新参与分配。

## 3.7 Rename Map

`OooRenameMap` 保存 speculative RAT。它必须支持：

- 两 lane 同拍读多个源；
- 两 lane 同拍写 map；
- lane1 看到 lane0 的同拍覆盖；
- branch recovery/ROB walk 恢复被 younger 指令覆盖的映射；
- commit 与 speculative map 职责不混淆。

不要把 RAT 当成架构寄存器。RAT 只回答“当前在飞程序中，最新版本在哪里”。
当前 ROB 反向 walk 中，`walk0` 是更年轻项、`walk1` 是更老项；同拍恢复发生 WAW 时，
较老的 `walk1` 后写，最终留下“最老被撤销写者之前”的映射。

## 3.8 Busy Table 与 wakeup

目的 PRF 分配时变 busy；正式 writeback 时清 busy。IQ entry 对每个源保存：

```text
src_tag + src_ready
```

若 dispatch 时 busy table 已说明源 ready，entry 可直接标 ready；否则等待 wakeup
匹配 tag/ProducerId。两个 formal completion slot 允许一拍完成多个 producer。

需要警惕“同拍 completion + dispatch”：新 entry 应看到 completion 后的 ready 语义，
否则会平白多 stall 一拍；但旧 producer 的 completion 又不能误唤醒刚复用同 index 的新
producer，因此还需要完整身份合同。

还要区分 `early_wakeup`：它只把 IQ 中的 sticky-ready 置位，不写 BusyTable、PRF 或
ROB。紧邻的 dependent issue 所需数据来自已经寄存的 EX packet forwarding。因而
“IQ ready”不能直接翻译成“PRF 中已经有最终值”。

## 3.9 ROB：程序顺序的锚

ROB 是 16-entry 环形队列。每个 entry 至少概念上保存：

- PC、instruction；
- ProducerId / ROB position；
- destination 架构/物理寄存器与 old physical；
- 是否完成、是否有异常；
- branch/control/memory/FP/fflags 等退休所需事实；
- 用于 trace/DiffTest 的架构结果。

ROB 的两个方向：

- tail 端按程序顺序 allocate；
- head 端只在 entry 完成且允许时 commit，最多两条。

执行可以乱序，ROB 顺序不能乱。lane1 commit 的前提隐含 lane0 同拍可退休，不能跳过
有异常或未完成的 head0。

## 3.10 ProducerId：为什么 ROB index 不够

16-entry ROB 很快会 wrap。假设老事务使用 raw index 3，离开 IQ 后卡在 memory bridge；
ROB 误以为它已终止并再次把 index 3 分配给新事务。老 response 回来时只比较 index 3，
就会把数据写给新事务。

当前 ProducerId 把 generation 与 raw ROB index 组合。所有长寿命 holder 都应保存完整
ProducerId；释放前还要证明没有 live reference。generation 降低碰撞机会，但安全性来自
owner census/no-live-reuse，不来自“4 bit generation 应该够用”。

## 3.11 Integer IQ 与 oldest-ready

`OooIntIssueQueue` 有 8 个 entry。entry 只有在：

- valid；
- 所有需要的源 ready；
- 没被 kill；
- 对应执行资源可用；
- memory/long-op 等额外约束允许；

时才是 candidate。

`OooIntIssueSelect8` 负责平衡选择。两个 issue lane 是**物理终端**，不是静态的程序
lane0/lane1。Universal 终端承载 branch、MulDiv、CLMUL、复杂/访存操作；选择器可以把
较年轻的复杂操作放在 physical issue0，同时把较老的普通 ALU 动态交换到 issue1。
因此两个 issue lane 并不意味着任意两条都能一起走：

- 两条都需要唯一 MulDiv 时只能选一条；
- branch 只能由 physical issue0 解析；
- memory/FP-GPR 等类型受到 Universal 终端和下游资源约束；
- 第二个 winner 必须排除第一个 winner 的 entry 和资源。

“oldest-ready”保护年龄公平，但不是全局按序执行；一个更老但源未 ready 的 entry 不阻止
更年轻 ready entry。

## 3.12 PRF 读与旁路

`OooPhysRegFile` 保存整数物理结果，当前读口是 stored-only。执行源最终可能来自：

1. PRF 已写入值；
2. 已寄存 EX packet 提供的外部 forwarding；
3. 特殊架构读路径；
4. pending control 使用的架构 GPR 解包。

旁路的目的不仅是性能。`early_wakeup` 可能让 dependent 提前被选中，此时值必须由与该
wakeup 同源的 registered producer forwarding 提供；不能假设 PRF 自带 write-through。
正式 WB 之后，后续读取才依赖 stored PRF 值。

`OooPendingOperandReadGate` 是串行控制路径的操作数读取 gate，不是普通 issue 的通用
旁路网络。把它与 PRF wakeup 混为一谈会误读 control plane。

## 3.13 本章相关文件

| 文件 | 阅读重点 |
| --- | --- |
| [`DecodeUnit.v`](../../../npc/rv64/vsrc/decode/DecodeUnit.v) | opcode/funct 到基础控制事实 |
| [`ImmGen.v`](../../../npc/rv64/vsrc/decode/ImmGen.v) | I/S/B/U/J 立即数扩展 |
| [`DecodeStage.v`](../../../npc/rv64/vsrc/decode/DecodeStage.v) | DecodeUnit 与 ImmGen 的组合包装 |
| [`OooAluDecodeBackend.v`](../../../npc/rv64/vsrc/decode/OooAluDecodeBackend.v) | 双 lane uop 生成并接入整数后端 |
| [`OooDispatchBackend.v`](../../../npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v) | RAT/free/busy/ROB/IQ 的原子装配 |
| [`OooFreeList.v`](../../../npc/rv64/vsrc/rename_allocate/OooFreeList.v) | 双分配、双回收与可用计数 |
| [`OooRenameMap.v`](../../../npc/rv64/vsrc/rename_allocate/OooRenameMap.v) | speculative RAT 和同拍 bypass |
| [`OooBusyTable.v`](../../../npc/rv64/vsrc/rename_allocate/OooBusyTable.v) | PRF ready 状态与 completion 清除 |
| [`OooIntIssueQueue.v`](../../../npc/rv64/vsrc/scheduling/OooIntIssueQueue.v) | entry 生命周期、wakeup、双 issue |
| [`OooIntIssueSelect8.v`](../../../npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v) | 8-entry oldest-ready 组合选择 |
| [`OooPhysRegFile.v`](../../../npc/rv64/vsrc/regread_bypass/OooPhysRegFile.v) | 整数 PRF 多读写端口 |
| [`OooPendingOperandReadGate.v`](../../../npc/rv64/vsrc/regread_bypass/OooPendingOperandReadGate.v) | pending branch/jump 架构操作数读取 |
| [`OooRob.v`](../../../npc/rv64/vsrc/writeback/OooRob.v) | allocate、complete、walk、双 commit |

## 3.14 本章检查点

1. 用自己的例子画出 WAW 和 WAR 怎样被 PRF 消除；
2. 解释 lane0 写、lane1 读同一个架构寄存器时为何需要 rename bypass；
3. 说明 busy bit、IQ `src_ready` 与 PRF 数据分别表示什么；
4. 说明为什么 ROB raw index wrap 会威胁晚到 memory response；
5. 找出双 dispatch 必须共同满足的资源条件。
