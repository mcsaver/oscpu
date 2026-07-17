# R4-S1-ID exact-owner-provenance RTL 推导

> 状态：`pre-RTL derivation frozen`。本文件在任何生产 RTL 改动之前建立。
> 基线 immutable bundle：
> `a80d45cb559652773c43fe6a765eff2bba7607e968b9565703b26c4a8a87adf1.tar`；
> 138-file RTL design id：
> `sha256:4a7d748a600096fa8010abbcef0245f6f524786fb0a2ab42857c7db6f81cf5fa`；
> source-set manifest：
> `6ed7ec7b570acdac84a02bb29ee4ae0e4ab4c4bb429e603828de249be07c9fd6`。

## 0. 接口/控制契约

### 0.1 握手

- owner allocation 是 `alloc_valid && alloc_ready`；token只在该 fire 拍创建。
- 两 allocation lane 独立，但 lane0优先只用于同拍候选选择；两个 fire必须得到不同 token。
- tagged free 是 `free_valid && free_ready`；`ready`只表示 live tuple exact match。
- bridge request/response在 backpressure期间保持
  `{kind,token,epoch,tval}` 与既有 operation/class/fault payload逐位稳定。
- MIQ response transport可在 identity mismatch时被 drain/pop，但所有 architecture side effect
  必须由 exact-match资格位门控；mismatch同时触发立即断言。

### 0.2 stall DAG

- owner allocator只在 32 token全部 live时反压 capture；candidate来自寄存 live bitmap。
- token/epoch equality只位于 response consumer，不进入 bridge request-ready、SRAM address或
  MIQ-head→bridge ready组合锥。
- epoch pending阻止新的 memory capture；它不改变已经 captured owner的 request/response ready。

### 0.3 flush/kill表

| owner位置 | 未形成 transport owner | 已进入 bridge station/FSM/AXI | STORE physical owner |
| --- | --- | --- | --- |
| reservation | LOAD/ATOMIC释放；STORE交给SQ squash释放 | 不适用 | 不适用 |
| MIQ/bridge | station cancel产生 tagged drop terminal | FSM按现有协议drain，最后产生 tagged drop terminal | nokill，不被普通flush清除 |
| SQ | 未 request_sent 的 killed entry清除并导出 token release mask | probe在飞时等 bridge drop terminal；SQ entry可清 | request_sent保留到B terminal和ROB release |

同拍优先级：`reset > terminal/drain accounting + effective kill > SQ/MIQ flush > normal bind/fill/alloc`。
response+kill 仍消费 transport、只禁 architectural completion。

### 0.4 异常序/访存序/恢复真源

- exact tuple命中后才可向原 ROB写 data/fault；ROB既有 head退休序不变。
- store probe success不 terminal；probe fault/local fault/B才 terminal；physical request仍需
  SQ physical head==ROB head，B前不release/cache success update。
- token唯一真源是 capture allocator。ROB tag用于年龄/关联，SQ index用于存储位置，MIQ head
  用于 in-order transport候选；三者均不能重建token。

## 1. 需求

### 1.1 功能目标

1. 新建一个32-token、双 alloc/双 tagged free、支持批量SQ cancel mask的 owner tracker。
2. 新建真实MMU epoch owner，比较有效 translation-context字段并用 quiet gate推进。
3. 当前单 memory capture采样 `{kind,token,epoch,tval}`，贯通 reservation/buffer/atomic state、
   MIQ、bridge station/active/response和SQ probe→drain→B。
4. mismatch/stale/kill/drop不能WB、SQ fill/terminal或产生新side effect；token仅在其真实生命周期
   终点释放。
5. 保持现有T4N store语义和单宽吞吐；不新增LQ/双memory datapath。

### 1.2 端口与位宽

- owner kind 2 bit：LOAD=`00`、STORE=`01`、ATOMIC=`10`、RESERVED=`11`。
- token 5 bit；epoch 2 bit；fault_tval XLEN。
- tracker：2组 `{alloc_valid,ready,kind,epoch,token}`、2组
  `{free_valid,ready,kind,token,epoch}`、`cancel_mask[31:0]`、live bitmap/count。
- epoch owner输入：`context_quiet`、SFENCE commit、priv、satp、mstatus相关位、PBMTE、PMP；
  输出 current epoch、capture block、advance pulse。
- MIQ/SQ/bridge和wrapper逐层传递完整tuple。

### 1.3 性能/时序

- allocator priority search只到 capture寄存器；不串到bridge/cache。
- epoch宽context compare只生成capture block/窄advance，不进入target data path。
- response exact compare位于寄存MIQ head与bridge response之间，不进入ready回路；mismatch仍ready。
- tuple只增加寄存payload，不改变cached-hit stage数量与II。

### 1.4 非目标

- LQ4、第二AGU、双xlate/SQ query/cache/WB；
- 删除MIQ FIFO或单bridge FSM；
- Linux、PPA、full regression、hash-bound合同更新。

## 2. 协议规则

### 2.1 tracker

- candidate从本拍开始时的 `live_q` 选择；free/cancel不反馈candidate，所以不发生same-edge reuse。
- alloc1在alloc0真实fire时排除token0；alloc0无效时alloc1可取第一个candidate。
- 双free同token时free0优先，free1不ready；wrong kind/epoch/nonlive均不ready并断言。
- cancel mask只允许清本拍开始时live且kind=STORE的token；与free端口重叠为契约错误。

### 2.2 epoch

- effective context = `{priv,satp,mstatus.MXR/SUM/MPRV/MPP,PBMTE,pmpcfg,pmpaddr}`。
- 初始化拍只采样，不推进epoch；之后vector改变或SFENCE形成pending。
- pending当拍阻止capture；只在quiet边沿更新snapshot并epoch+1。
- context vector在nonquiet时改变是契约错误；模块仍fail-closed保持block直到quiet。

### 2.3 tuple transport

- ordinary VA request attr仍invalid/RSVD；tuple与attr语义正交。
- bridge station capture request tuple，stage advance复制到active tuple；PTW/A-D/target phase不改tuple。
- response payload直接echo active tuple；fault_tval不按PA/CSR重算。
- SQ pretranslated request使用其保存tuple；bridge不得分配新token。

## 3. 状态机

### 3.1 tracker状态

无多态FSM，状态为 `{next_token_q,live_q,live_kind_q[32],live_epoch_q[32],live_count_q}`。

```text
RESET -> EMPTY
EMPTY/PARTIAL -- alloc fire --> PARTIAL/FULL
PARTIAL/FULL -- exact free or cancel --> PARTIAL/EMPTY
FULL -- no free feedback into candidate --> alloc_ready=0 for this cycle
```

### 3.2 epoch owner

| 状态 | 编码 | 行为 |
| --- | --- | --- |
| INIT | initialized=0 | block capture；首沿采样context，epoch=0 |
| CLEAN | initialized=1,pending=0,diff=0 | capture可用 |
| PENDING | pending或diff | block；quiet沿advance并回CLEAN |

SFENCE pulse若nonquiet则置pending；vector diff本身保持pending语义。

### 3.3 既有owner状态扩展

- reservation/buffer/atomic state不加新FSM状态，只在各自valid生命周期旁带tuple。
- MIQ FIFO entry增加tuple；kill位与tuple正交。
- SQ entry增加 `owner_valid + tuple`；alloc后未issue可owner_invalid，capture bind后直到
  squash/release不变。
- bridge station与active各增加tuple；active被kill时原FSM继续drain，到internal drop terminal
  才释放token。

## 4. 不变量

| ID | 表达式/后果 |
| --- | --- |
| ID-I01 | alloc0_fire && alloc1_fire -> token0 != token1；否则重复owner |
| ID-I02 | alloc token在old live bitmap中为0；否则ABA/collision |
| ID-I03 | live_count == popcount(live_bitmap)；否则守恒破坏 |
| ID-I04 | exact free必须匹配live kind+epoch；否则stale释放新owner |
| ID-I05 | request/response stall -> tuple stable；否则owner漂移 |
| ID-I06 | response side effect -> MIQ exact `{kind,token,epoch}`；否则错投 |
| ID-I07 | SQ fill/drain/terminal tuple == bound tuple；否则STORE phase重建 |
| ID-I08 | killed response -> no WB/SQ fill/cache fill；否则ghost |
| ID-I09 | request_sent STORE在B/ROB release前token live；否则ABA/丢副作用 |
| ID-I10 | epoch advance -> quiet && effective change；否则上下文交叉 |
| ID-I11 | context pending -> no new capture；否则新owner采旧epoch |
| ID-I12 | token equality不影响request ready；静态锥/定向hold检查 |

## 5. 数据通路与 RTL 级拓扑

```text
context regs --------------------------+
                                       v
core_mem_idle & mem_retire_quiet -> OooMmuEpochOwner
                                       | epoch, capture_block
                                       v
IQ memory capture -> OooMemOwnerTracker -> reservation tuple
                                             |\
                                             | +-> atomic state / buffer
                                             | +-> SQ owner_bind(STORE)
                                             v
                                    request mux tuple
                                             v
                                    MIQ entry tuple
                                             v
                                  bridge station tuple
                                             v
                                   bridge active tuple
                                       /           \
                           normal rsp exact     killed drain/drop terminal
                                  |                     |
                         MIQ exact consumer        tracker free
                           /       |      \
                       LOAD     PROBE    DRAIN
                        free     SQ fill   SQ terminal
                                   \       /
                                    SQ stored tuple
                                           |
                                  squash mask / ROB release
                                           v
                                        tracker
```

### 5.1 状态寄存器

- tracker：见§3.1；单一时序块，reset最高。
- epoch：epoch、snapshot、initialized、sfence_pending；单一时序块。
- backend：reservation/buffer/atomic tuple各一组；原valid块同沿更新。
- MIQ/SQ：每entry tuple arrays，与原entry state同块更新。
- bridge：station tuple在request fire更新；active tuple在stage advance更新；drop terminal pulse
  在internal owner实际结束沿更新。

### 5.2 组合块与资源共享

- tracker两个环形first-free选择器综合为分层优先选择网络；第二路排除真实grant0。
- MIQ/SQ exact compare为小等值比较；不封装状态/仲裁进function。
- SQ cancel mask由4 entry并行decode后OR到32 token bit；只清未request_sent survivor之外的entry。
- bridge仍共享单DTLB/PTW/cache/AXI；tuple不参与这些资源mux选择。

### 5.3 critical path与function边界

- 风险1：32-token first-free→capture ready；若focused lint/STA后需优化，允许层次化8×4编码，
  不能降低token数或猜测next必空。
- 风险2：full context compare→capture block；只到capture gate，不进入cache/AXI。
- 风险3：MIQ exact compare→side-effect enable；response ready保持与compare无关。
- function仅用于小型popcount/环形candidate helper（若工具允许）；allocator/epoch/SQ/MIQ状态更新、
  valid-ready、flush和仲裁必须显式 `always @(*)` / `always @(posedge clk)`。

## 6. 自审结论

- 无LQ或双memory越级接口；compatibility单宽边界明确。
- STORE token从capture绑定到既有SQ，probe/drain不重分配；T4N request/B/release顺序不变。
- fired owner与未fire SQ squash的释放边界分开，能表达flush drain后释放。
- epoch由有效context diff+SFENCE+quiet形成，不使用常0或mmu_flush替代。
- exact compare不进入ready，符合200MHz carrying constraint。

因此可进入 RED test 落盘；RED被 immutable S1 bundle证明后，才允许翻译为生产RTL。
