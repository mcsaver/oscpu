# 第 7 章：完成、退休、CSR 与精确异常

## 7.1 最容易混淆的三个词

### Execute done

某个功能单元算出了结果。例如 ALU 已得到 sum，D-cache 已返回 load data。

### Completion

结果获得全局 completion slot，完整 ProducerId 被确认，PRF/wakeup/ROB done 等状态
得到更新。功能单元有结果但 slot 被反压时，还不能重复或丢失 transaction。

### Commit/Retire

ROB head 按程序顺序把结果变成架构可见状态。只有这一步才允许更新架构 GPR/FPR、
`instret`、CSR side effect 和外部 commit trace。

“写回”在不同教材里可能指 execute→PRF，也可能指 commit→arch state。本项目中
`OooWriteback.v` 的名字偏向后者：它主要装配 control pseudo-commit 和最终 commit
输出，不是所有执行结果的集中数据寄存器。

## 7.2 两个全局 completion slot

可能产生 completion 的 owner 包括：

- EX0/EX1 普通整数；
- branch 的 control/recovery resolve（其 ROB completion 仍由对应 EX0 formal WB 完成）；
- MulDiv/CLMUL；
- memory bank0/bank1 response；
- SQ/AMO/LRSC 相关 terminal；
- FP short/long/simple result；
- FP→GPR 或 load-to-FPR 等跨域结果。

它们竞争 WB0/WB1。仲裁必须保证：

- 同一个 producer 一拍最多被接受一次；
- 两个 slot 不选择同一个 producer；
- 被 kill 的 producer 没有资格；
- payload 的 ProducerId、destination、value、exception、fflags 同源；
- 未获 slot 的结果 owner 保持；
- 同一拍 wakeup 和 busy clear 对 dependent issue 可见。

并不是每种 owner 都把 value 写同一个物理端口。FP PRF 写口物理上在 `OooFpBackend`，
但 completion 资格仍要与全局 ROB done/ProducerId 语义一致。

FP 还多一层：authorized raw result 可先写 FP PRF并 wake，随后住进 done FIFO；只有
done FIFO head 获得 formal FPWB 时才写 ROB done。因而“依赖者已醒”和“ROB 已完成”
可以出现在不同周期。

## 7.3 ROB entry 何时算完成

普通 ALU/FP/load：获得对应 completion 后 done。

store：地址/data 形成只表示 SQ entry 已可参与 ordering；当前必须等它成为 SQ head 且
匹配 ROB head，获得 launch-open 后才发物理请求，B terminal 后才释放 ROB/SQ owner。

branch：比较和 actual next-PC 已确定，且 completion 被接受。

exception：entry 可以携带异常事实到 ROB head。它不需要产生正常 register value，但必须
保存 cause/tval/PC。

serialized SYSTEM：可能由 pending owner 和 control pseudo-commit 表达，不等同于普通
execution completion。

## 7.4 双退休

每拍最多退休两条：

```text
commit0 = head0 valid &&（normal done 或精确异常可消费）&& 无更高优先级控制
commit1 = commit0 && head1 valid && done && lane-pair allowed
```

这只是概念式。实际还会加入：

- head0/head1 instruction kind；
- store/CSR/FP side effect；
- trap/exit；
- serial owner；
- external halt/debug；
- branch recovery 和 flush 优先级。

关键不变量是 lane1 不能越过 lane0。即使 head1 已完成、head0 未完成，head1 也必须等待。
head0 或 head1 带 exception 时都禁止 commit1。位于 head0 的异常 entry 可以作为精确
事件从 ROB dequeue，但它不是普通 ISA retire：不写架构寄存器，也不计 `instret`。

另一个刚性边界是 ROB 没有 WB→commit 同拍旁路。formal WB 在一个上升沿写
`done_q/data_q`，commit 最早在下一周期从 edge-old ROB 状态生成。

```wavedrom
{
  "signal": [
    {"name": "clk",          "wave": "p......."},
    {"name": "head0 done",   "wave": "0..1...."},
    {"name": "head1 done",   "wave": "01......"},
    {"name": "commit0",      "wave": "0..10..."},
    {"name": "commit1",      "wave": "0..10..."},
    {"name": "head advance", "wave": "0..10..."}
  ],
  "head": {"text": "head1 早完成也不能越过 head0；head0 ready 后可双退休"}
}
```

## 7.5 退休时发生什么

### GPR instruction

- `OooArchRegFile` 写架构 `rd`；
- old physical register 归还 free list；
- 对外 commit value/PC/instruction 有效。

### FPR instruction

- `OooFpRegFile` 写架构 FPR；
- old FP physical 归还；
- entry 的 `fflags` 按程序顺序累积。

### Store

- SQ head 与 ROB head 相遇后，`rob_head_launch_open` 授权物理写；
- AW/W 可分开握手，B response 是 terminal；
- terminal 后 ROB/SQ exact owner 才能释放并形成最终退休；
- 因此当前实现不是“先 commit、以后后台等待 B”的 store buffer 模型。

### Branch

- 正确解析后按普通 entry retire；
- predictor update 可能早于 commit，但必须绑定活 producer，不能让被 kill branch 更新。

### CSR/system

- 通过 pending/control event 在精确边界更新 `CsrFile`；
- 产生必要 redirect、MMU flush 或 trap/xRET state change。

## 7.6 `OooWriteback` 的真实职责

`OooWriteback` 例化：

- `OooControlCommitSequencer`；
- `OooCommitOutputMux`。

`OooControlCommitSequencer` 保存控制类伪提交和 serial flush pulse；`OooCommitOutputMux`
在 control pseudo-commit、branch append 和 ROB commit0/1 之间选择外部可见 commit。

control commit 的优先级最高，并会压掉 lane1；synthetic append 也可能覆盖最终 lane1。
所以 raw ROB `commit0/1` 与最终 DiffTest/trace commit 不是同一层接口，`retire_count`
必须按最终无异常事件计算。

这样仿真器/DiffTest 可以看到统一 commit ABI，但不应误认为所有 control event 都是一个
普通 ROB ALU entry。

## 7.7 架构状态分散在三个位置

| 状态 | 物理 owner | 何时更新 |
| --- | --- | --- |
| GPR x0..x31 | `OooArchRegFile` | GPR producer commit |
| FPR f0..f31 | `OooFpRegFile` | FP producer commit |
| CSR/priv/PMP/counter | `CsrFile` | 精确 CSR/trap/xRET/retire event |

`CsrFile` 在 `NpcCoreTop` 直接例化。`OooCoreTopGlue` 输出 CSR access/trap/fflags/retire
事件，并消费 `priv/satp/mstatus/PMP/interrupt target` 等状态。

## 7.8 CSR access 与 legality probe

当前 CSR 接口分为：

### Main access

真正的 commit/pending CSR transaction，可能产生读值、写副作用和 redirect。

### Head-only probe

前端只想知道当前 head CSR 在当前 privilege 下是否合法。probe 复用 legality predicate，
但不更新 CSR。

如果把 probe 接到 main access，单纯“看一下是否合法”就可能改 `mstatus/satp/PMP`，
制造幽灵 side effect。

`OooCsrAccessRequestMux` 选择 commit0 CSR、pending SYSTEM CSR、lane1/head probe 等来源；
`OooCsrIllegalProbeGate` 把 probe 结果投影成 precise illegal facts。

## 7.9 产品默认 CSR 双路径：head0 queue-head 与 pending full-drain

当前产品配置不是“所有 CSR 都先进入 pending、等全核排空”。配置真源
[`product-rtl-defaults.mk`](../../../npc/rv64/configs/product-rtl-defaults.mk) 令
`OOO_CSR_QUEUE_HEAD=1`，[`define.v`](../../../npc/rv64/vsrc/include/define.v)
fallback 同步为 `1'b1`。CSR 因位置和种类分成两条互斥路径：

| CSR 情形 | admission / owner | 精确执行边界 |
| --- | --- | --- |
| 合法、非 FP、位于 head0 | 单发进入正常 rename/ROB/IQ；`head0_csr_inflight` + `stop_pending` 阻止 younger | ROB head 且 `mem_idle=1` 后 C0 单独提交，C1 serial/full-flush apply |
| 位于 lane1 | pending SYSTEM holder | 等 backend/full memory owner drain 后走原 pending CSR commit |
| `fflags` / `frm` / `fcsr` | 即使在 head0 也保留 pending 路 | 避免每次 CSR flush 把在飞多周期 FP 清掉，造成 RAW 错误或活锁 |
| 非法 CSR | legality probe 只读检查后转精确 trap | 不产生普通 CSR/GPR side effect |
| ECALL、xRET、WFI、SFENCE、FENCE.I、FENCE 等 | 非 CSR SYSTEM，继续 pending/full-drain | 由各自 typed control terminal 决定 |

### 从 birth 到 C2 的逐拍生命周期

1. **Birth / dispatch**：registered head 确认 CSR 合法且不是 FP CSR；lane0 单发，
   dispatch edge 原子写 RAT、FreeList、Busy、ROB、IQ，并锁存
   `head0_csr_inflight`。CSR 已离开 FIFO，所以后续必须由 inflight owner 继续保持
   `stop_pending`，不能再依赖“它还在 head”。
2. **Execute / formal WB**：CSR 复用普通后端执行与 formal completion 让 ROB entry
   变 done。dispatch-time CSR data 对 queue-head 路只是 placeholder；真正的“旧 CSR
   值”必须到队头时从架构 `CsrFile` 组合读出。
3. **Head wait**：CSR 已成为 done 的 ROB head 后，只等待 `mem_idle`。这里刻意**不**
   等 `mem_retire_quiet` 或 SQ empty：若 SQ 中有 CSR 之后的 younger Store，它未退休就
   不能 drain，而 CSR 又等它离开 SQ，二者会形成循环死锁。younger Store 的 probe
   完成后已满足 `mem_idle`，随后可由 serial flush 安全清除。
4. **C0**：ROB 形成 queue-head full-flush pregrant 和 `commit0_fire`，禁止同拍
   `commit1`。`OooCsrAccessRequestMux` 用 commit0 instruction 与架构 GPR rs1 形成
   `CsrFile` request；旧 CSR 组合值覆写 commit0 `rd` data，同一架构边沿提交 CSR 写。
5. **C1**：`OooControlCommitSequencer`/control-event apply 输出 serial/full flush，
   kill younger、恢复 rename/phys state、清旧 fetch packet/outstanding 可见性，并从
   commit next-PC 重取。`head0_csr_inflight` 与 stop owner 在这个边界释放。
6. **C2**：request/apply 必须回到 0；重复 CSR 写、重复 flush 或重复 redirect 都是
   exactly-once 违例。

```wavedrom
{
  "signal": [
    {"name": "clk",                    "wave": "p........."},
    {"name": "CSR dispatch / birth",   "wave": "010......."},
    {"name": "head0_csr_inflight",     "wave": "0.1...0..."},
    {"name": "stop_pending",           "wave": "0.1...0..."},
    {"name": "formal WB",              "wave": "0..10....."},
    {"name": "ROB head + done",        "wave": "0...1....."},
    {"name": "mem_idle",               "wave": "0...1....."},
    {"name": "C0 commit / barrier",    "wave": "0....10..."},
    {"name": "C0 CsrFile request",     "wave": "0....10..."},
    {"name": "C1 serial / apply",      "wave": "0.....10.."},
    {"name": "C2 new-path fetch",      "wave": "0......10."},
    {"name": "C2 repeated apply",      "wave": "0........."}
  ],
  "head": {"text": "产品默认 head0 CSR：inflight 持有 stop，只等 mem_idle；C0 提交，C1 apply，C2 静默"}
}
```

这张图是由当前 RTL 静态边沿关系整理出的教学模型，不是本轮重新采集的仿真波形。
尤其不要把 `mem_idle` 拉高的位置理解成固定 latency；它取决于更老的 MIQ、bridge、
cache/PTW 和已 handoff transaction。

### `satp` 为什么也走这条路

`satp` 是普通 CSR 编码，所以合法 head0 `csrw satp` 走 queue-head C0/C1。C0 写入新
地址空间状态，C1 flush/refetch；旧已发 fetch response 仍被物理消费但只能 discard，
新路径重新以新 `satp` context 查询。lane1 `satp` 仍走 pending/full-drain，因此不能把
“head0 SATP 的 pending MMU pulse 为 0”误解成所有 SATP 都没有串行化。

## 7.10 `CsrFile` 包含哪些状态

主要类别：

- machine/supervisor trap state：`mstatus/sstatus`、`mtvec/stvec`、
  `mepc/sepc`、`mcause/scause`、`mtval/stval`；
- delegation 与 interrupt enable/pending；
- `satp`、Sv39 相关控制；
- `misa` WARL；
- `fflags/frm/fcsr`；
- `cycle/time/instret` 与 counter enable；
- `pmpcfg0/2`、`pmpaddr0..15`；
- debug trigger no-op CSR；
- `mstatus.TVM/TW/TSR/SUM/MXR/FS` 等权限/状态位。

当前 WARL/legality 边界还包括几处容易从“CSR 地址存在”误读的细节：

- `mstatus.MPP=2` 是保留编码，写入时由 `sanitize_mstatus_write` 规范化为 U；SXL/UXL
  固定为 RV64。`sstatus` 只暴露属于它的 UXL，而不会把 machine-only SXL 一并泄漏；
- `medeleg` 写入只保留当前实现的 `0x0000_0000_0000_b3ff` cause mask，`mideleg`
  只保留 SSIP/STIP/SEIP。`sie/sip` 又是 `mideleg` 选中位的受限视图，不是对 `mie/mip`
  全部 supervisor 位的无条件别名；
- supervisor 经 `sip` 只能写已 delegated 的 SSIP，STIP/SEIP 仍由 machine/hardware
  路径控制；
- 当 `mstatus.FS=Off` 时，访问 `fflags/frm/fcsr` 本身就是 illegal。合法写这些 FP CSR
  会把 FS 置 Dirty，与提交 FPR/fflags 的 `fp_dirty_i` 路径形成同一架构状态合同。

具体实现是教学/bring-up 所需子集，不能仅凭 CSR 地址存在就外推完整 privileged spec
覆盖。

## 7.11 精确异常

精确异常要求软件看到：

- 异常指令之前的所有指令已经生效；
- 异常指令自己没有正常 side effect；
- 之后的所有指令都没有生效；
- xEPC 指向正确 PC；
- xCAUSE/xTVAL 与选中的异常同源；
- trap target 与 delegation/privilege 状态一致。

乱序执行允许 younger 指令已完成甚至写入 PRF，但它们尚未 commit，因此 trap 时可丢弃。
异常 entry 在 ROB 头可以被 dequeue 以推进结构状态，但该动作只触发 precise trap，
不等于 normal commit，也不得更新架构目标或 `instret`。

```wavedrom
{
  "signal": [
    {"name": "clk",                "wave": "p........."},
    {"name": "older I0 complete",  "wave": "010......."},
    {"name": "fault I1 known",     "wave": "0.10......"},
    {"name": "younger I2 complete","wave": "0.10......"},
    {"name": "I0 commit",          "wave": "0..10....."},
    {"name": "I1 normal commit",   "wave": "0........."},
    {"name": "trap apply",         "wave": "0....10..."},
    {"name": "kill I2",            "wave": "0....10..."},
    {"name": "trap redirect",      "wave": "0.....10.."}
  ],
  "head": {"text": "精确异常：老 I0 退休，fault I1 不正常退休，年轻 I2 即使完成也被取消"}
}
```

## 7.12 异常优先级和 owner 同源

同一周期可能看到：

- ROB-head exception；
- pending architectural trap；
- memory access/page fault；
- interrupt；
- simulation exit。

`OooCsrTrapRequestMux` 和 `OooTrapExitEventMux` 选择唯一有效 owner。cause、tval、PC、
target 和 flush 必须来自同一个 winner，不能 valid 来自 memory fault、payload 却来自 IRQ。

interrupt 只应在精确边界被接受。它是异步事实，但 trap transaction 必须序列化到某个
instruction boundary。

## 7.13 `instret`、counter 和 fflags

`cycle` 通常按运行周期增加；`instret` 必须按真实 retire 数量增加 0/1/2，而不是按
dispatch 或 completion。被 flush、异常、pseudo event 均不能错误计入。

FP `fflags` 随 ROB entry 到 commit 才 OR；被 kill FP producer 的 flags 不可见。

这些状态是检查“执行”和“退休”是否混淆的好探针。

## 7.14 本章相关文件

| 文件 | 职责 |
| --- | --- |
| [`OooRob.v`](../../../npc/rv64/vsrc/writeback/OooRob.v) | entry allocate/complete/walk/双 commit |
| [`OooWriteback.v`](../../../npc/rv64/vsrc/writeback/OooWriteback.v) | control/ROB commit 输出装配 |
| [`OooControlCommitSequencer.v`](../../../npc/rv64/vsrc/writeback/OooControlCommitSequencer.v) | control pseudo-commit 和 serial flush |
| [`OooCommitOutputMux.v`](../../../npc/rv64/vsrc/writeback/OooCommitOutputMux.v) | 外部双 commit/retire mux |
| [`OooArchRegFile.v`](../../../npc/rv64/vsrc/writeback/OooArchRegFile.v) | 架构 GPR |
| [`CsrFile.v`](../../../npc/rv64/vsrc/core/CsrFile.v) | CSR/priv/trap/PMP/counter 状态，以及 delegation/FS/WARL 规范化 |
| [`OooCsrAccessRequestMux.v`](../../../npc/rv64/vsrc/control/OooCsrAccessRequestMux.v) | CSR main access 与 probe source 选择 |
| [`OooCsrIllegalProbeGate.v`](../../../npc/rv64/vsrc/control/OooCsrIllegalProbeGate.v) | 无副作用 legality probe 结果 |
| [`OooCsrTrapRequestMux.v`](../../../npc/rv64/vsrc/control/OooCsrTrapRequestMux.v) | commit/pending/IRQ/xRET trap request 选择 |
| [`OooStopPendingSequencer.v`](../../../npc/rv64/vsrc/control/OooStopPendingSequencer.v) | queue-head inflight 与 pending holder 的 stop owner |
| [`OooControlEventApplySequencer.v`](../../../npc/rv64/vsrc/control/OooControlEventApplySequencer.v) | C0 typed request 到 C1 apply |

## 7.15 本章检查点

1. execute done、completion、commit 分别改变哪些状态？
2. 为什么 head1 done 不能先于 head0 retire？
3. `OooWriteback` 为什么不是所有结果的集中写回模块？
4. CSR legality probe 若有副作用会发生什么？
5. younger 指令已经写 PRF，为什么仍能实现精确异常？
6. 为什么 head0 CSR 只等 `mem_idle`，而不能再把 `mem_retire_quiet`/SQ empty 并入退休门？
