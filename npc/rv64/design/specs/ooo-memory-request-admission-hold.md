# 规范：OooIntBackend 双 bank memory request admission hold（V14R）

> 规范对象：`OooIntBackend` 到两份 `OooMemAxiBridge` 的 request `valid/ready` 边界。
> 状态：V14R production RTL、focused/mutation/link regression 与当前设计身份闭合；PPA 仍未晋级。
> 当前输入设计：`sha256:5a6895c8b2ec27cb45aec8bb935dcb2e415cc8935a1eff53686b03cdf981f9f4`。

## 1. 目的、范围与非目标

V14Q 冻结 CoreMark probe 在 cycles、retired、GOOD TRAP、v4 counter、84-owner inventory、
simulator 与 148-file production manifest 均不漂移时，仍得到 1,176 个 reason-conserved
`admission_identity_change`。源码根因是 bank0/bank1 request payload 由 live priority grant
直接组合选择；bridge `ready=0` 时后到高优先级 source 可在 `valid` 连续为 1 的相邻周期替换
kind/token/epoch/address/data。

本规范只负责：

- 让每个 bank 首次展示的 source selection 在 `valid&&!ready` 后锁到本 source fire；
- 保持完整 request payload、owner identity、MIQ birth 与 source consume 同源；
- 为显式 recovery/kill 规定先撤 VALID 的 cancellation bubble；
- 保留 SQ/AMO/buffer singleton、双 bank ordinary 并行、STORE B terminal 与既有内存序。

非目标：修改 `OooMemAxiBridge` FSM/cache/AXI、增加 request/MIQ 容量、改变优先级、绕过 B、
削弱 assertion、用 collector 去重、直接授权 CPI/PPA candidate，或重做双 bank 宏。

## 2. 六类接口契约

### 2.1 端口、握手与 payload

两个 bank 都使用单拍 `valid && ready` request fire。payload 合同固定为 217 bit 语义集合：

`write, addr[63:0], wdata[63:0], wstrb[7:0], probe, pretrans, nokill,
attr_valid, class[1:0], cacheable, owner_kind[1:0], owner_token[4:0],
mmu_epoch[1:0], fault_tval[63:0]`。

| bank | source inventory（高→低） | live 选择条件 |
| --- | --- | --- |
| bank0 | SQ drain, AMO write, buffer, retry0, issue0, issue1 | 只读 edge-old source Q、tracker/ROB/slot/ordering 与 recovery 条件；不读 `mem_req_ready_i` |
| bank1 | retry1, issue0, issue1 | 只读 edge-old source Q、bank route、tracker/slot/ordering 与 recovery 条件；不读 `mem1_req_ready_i` |

协议规则：

1. IDLE 中 live priority 只决定本次展示 owner；优先级本身不等于 fire。
2. 首次展示且 READY=1 时可以同拍 fire，不建立 holder。
3. 首次展示且 READY=0 时，上升沿保存 source one-hot 与 exact
   `{owner_kind,owner_token,mmu_epoch}`；下一周期起 holder selection 覆盖 live priority。
4. HELD 中 VALID、source selection 与全部 217-bit payload 保持到 exact fire。后到 SQ、AMO、retry、
   issue 或 buffer 不得抢占，也不得只换 owner 元数据而保持地址。
5. holder 不复制宽 payload；原 source Q 是 payload 唯一真源。source Q 在 HELD 中必须保持 resident、
   exact identity 与完整 payload。意外 source loss 使输出 fail closed 并由立即断言报告。
6. allowed cancellation 必须先令该 bank VALID=0，整拍不 fallback 到新 source；沿后清 holder，下一拍
   才重新仲裁。禁止连续 VALID 换 owner。
7. READY 只参与 fire 与上升沿 capture/clear，不进入 live/held VALID 的组合生成。

### 2.2 stall / ready DAG

合法方向：

```text
edge-old source Q / tracker / ordering
  -> live priority or registered hold selector
  -> request VALID + 217-bit payload
  -> bridge READY
  -> exact source fire + MIQ birth
  -> holder clear / source consume
```

禁止方向：

- READY -> live source valid / priority / owner identity；
- 新 contender -> HELD selector / payload；
- MIQ push/fire -> 同拍回改 request selection；
- bank0 response/ready -> bank1 holder，或反向依赖。

### 2.3 flush / kill / recovery 矩阵

| 事件 | HELD 行为 | 下一拍 |
| --- | --- | --- |
| synchronous reset | 两 bank VALID=0；清 holder/selector/identity | 冷启动仲裁 |
| global `flush_i` / checkpoint restore hold | 两 bank cancellation bubble；不得 fire/MIQ push | source 若仍合法则重新仲裁 |
| branch recovery | issue/retry 继承现有 recovery gate并产生 cancellation bubble；已经被 bank holder 接受的 older exact SQ/AMO 保持 VALID、payload 与 owner lease，不重新读取 first-launch gate | held SQ/AMO 可 exact-fire；尚未展示的新 source 等恢复结束后重新仲裁 |
| younger `mem_buffer_kill_w` | 仅 buffer holder cancellation bubble；不得进入 bridge | holder 清除 |
| issue/memory issue barrier | issue/retry holder cancellation bubble；SQ/AMO/buffer 仍按各自现有资格 | barrier 后重新仲裁 |
| source identity/valid 无授权丢失 | 输出 fail closed，禁止 fallback；`OOO_ASSERT` fatal/error | 只允许 reset 或另行根因修复 |

同拍优先级：

`reset > explicit cancellation/source-loss quarantine > held fire > held residency > new stalled capture > idle`。

### 2.4 异常、内存序与副作用

- effective selector 是 request payload、source fire、MIQ kind/ROB/pdest/size/unsigned 与 owner tuple 的
  共同真源；任一 fire 只能 consume 一个 exact source，并在同沿创建一个 bank-local MIQ owner。
- SQ/AMO/buffer effective selection 与 bank1 ordinary selection保持互斥。若 bank1 已 HELD，后到
  bank0 singleton 等待；若 bank0 singleton 已 HELD，bank1 live request 等待。
- bank0/bank1 ordinary request仍可在不同 bank 同拍 fire；不得因 holder 实现退化成全局串行器。
- SQ/AMO 首次进入 live priority 继续要求 exact tracker/PID/ROB-head `launch_open`；READY=0 捕获
  holder 后，物理请求改由 exact source residency、tracker/PID/ROB-head 与 `owner_open` 共同承重。
  younger selective recovery 只关闭新的 first launch，不撤销已经展示的 older write lease；global flush、
  checkpoint restore、source terminal/request-sent 或真实 owner/PID/ROB 漂移仍 fail closed。
- request fire 只表示 bridge admission。STORE/A-D write completion 仍唯一由 aggregate B terminal
  承重；本规范不提前完成、合并或去重任何 terminal。
- 单 bank 路径上，若 older MIQ probe 在本拍可成为 SQ physical head，younger plain-store probe 不得先
  展示为 request；reservation 仍可在 SQ fire 边沿按原合同缓冲。该 admission 规则避免 holder 把原先
  的非法 late-SQ 抢占固化成顺序倒置，不改变双 bank ordinary 并行。

### 2.5 owner / source-of-truth

| 事实 | 唯一真源 | 禁止替代 |
| --- | --- | --- |
| IDLE winner | live priority one-hot | READY、地址猜测、collector 状态 |
| HELD winner | bank-local hold selector Q | 当前 live priority |
| held identity | hold kind/token/epoch Q 与 source Q exact compare | ROB raw index、地址 bank bit |
| SQ/AMO 首次发起资格 | exact tracker/PID/ROB head + `launch_open` | holder 状态、READY |
| SQ/AMO 已持有 lease | exact source Q + tracker/PID/ROB head + `owner_open` | 瞬态 `launch_open`、collector 状态 |
| request payload | held selector选中的原 source Q | collector snapshot、另一 source payload |
| request acceptance | selected VALID && matching bank READY | grant-valid、自报 state |
| architectural completion | 既有 MIQ/tracker/ROB exact completion 与 B terminal | request fire、holder clear |

### 2.6 reset 与参数配置

holder Q 使用同步高有效 `rst`，复位全零。`ENABLE_DUAL_MEM=0` 时 bank1 holder恒空，bank0仍满足同一
hold合同；`ENABLE_DUAL_MEM=1` 时两 bank各自持有选择，singleton cross-bank exclusion仍有效。

## 3. 状态、优先级与 RTL 级拓扑

### 3.1 每 bank 两态模型

```text
IDLE
  -- live_valid && !ready --> HELD(selector, exact identity)
  -- live_valid &&  ready --> IDLE + exact fire

HELD
  -- allowed_cancel/source_loss --> IDLE + one-cycle invalid bubble
  -- source_exact && ready       --> IDLE + exact fire
  -- source_exact && !ready      --> HELD
```

其中 SQ/AMO 的 `source_exact` 使用 owner-residency 资格：选择性恢复导致的 `launch_open=0` 不是
source loss；若 exact source Q、tracker、ProducerId、ROB head 或 `owner_open` 任一失配，仍进入
source-loss quarantine 并触发 fail-loud assertion。

### 3.2 状态寄存器

| bank | state Q | 位宽 | reset | 更新 |
| --- | --- | ---: | --- | --- |
| bank0 | `mem_req_hold_valid_q` | 1 | 0 | stalled capture置位；fire/cancel清零 |
| bank0 | `mem_req_hold_sel_q` | 6 | 0 | 只在 stalled capture写 one-hot |
| bank0 | hold kind/token/epoch | 2+5+2 | 0 | 只在 stalled capture写 exact tuple |
| bank1 | `mem1_req_hold_valid_q` | 1 | 0 | stalled capture置位；fire/cancel清零 |
| bank1 | `mem1_req_hold_sel_q` | 3 | 0 | 只在 stalled capture写 one-hot |
| bank1 | hold kind/token/epoch | 2+5+2 | 0 | 只在 stalled capture写 exact tuple |

production 状态共 29 bit；不增加地址、数据、wstrb、fault-tval 或 MIQ metadata payload FF。

### 3.3 组合块与共享资源

1. `live_grant_bank0`：保持现有六源优先级；bank1 holder存在时阻止新 singleton。
2. `live_grant_bank1`：保持现有三源优先级；bank0 live/held singleton存在时关闭。
3. `hold_source_exact`：由 selector选择对应 source resident 与 kind/token/epoch compare；不读 READY。
   SQ/AMO 分支额外核对 tracker ProducerId、ROB head 与 `owner_open`，但不重读只用于首次展示的
   `launch_open`。
   `OooStoreQueue.req_source_resident_o` 是SQ本地Q、ROB exact identity和`owner_open`的组合事实；
   `req_held_lease_i`只在backend已捕获同一SQ selector且该事实仍成立时有效。StoreQueue以
   `req_valid_o || (req_held_lease_i && req_source_resident_o)`独立授权`req_fire_i`与request-sent更新。
4. `effective_grant`：holder valid时只输出 held selector；cancel/source-loss周期输出全零且不 fallback；
   无 holder时输出 live grant。
5. 既有 request/MIQ mux全部改读 effective grant；不复制宽 payload mux。
6. assertion-only shadow 在 `OOO_ASSERT` 下保存 217-bit stalled payload，下一周期逐位比较；不进入综合。

### 3.4 critical path 与自审

预计新增路径为 `hold selector Q + 小 tuple compare -> effective one-hot -> 既有 payload mux`。
READY 不进入该路径；live contender不再穿透已 HELD payload。29-bit 控制状态远小于两 bank复制
217-bit payload（434 FF）的替代方案。若 STA 显示 tuple compare成为 request-valid关键路径，可在保持
同一合同的前提下比较“capture full payload”或提前 exact-valid，但不得退回 live reselection。

拓扑自审结论：状态/复位/优先级有全序；两 bank ordinary 并行保留；singleton exclusion保留；
source consume与MIQ birth仍由同一 effective selector驱动；无 READY→VALID 组合回边。

## 4. 不变量与立即断言

- `V14R-H0-REQUEST-SELECT-ONEHOT`：live/effective grant和holder selector均为one-hot-or-zero。
- `V14R-H1-HOLDER-SELECT-NONZERO`：有效holder不得保存空selector。
- `V14R-H2-BANK0-PAYLOAD-HOLD` / `V14R-H3-BANK1-PAYLOAD-HOLD`：无cancel的HELD周期中
  VALID与217-bit payload逐位保持。
- `V14R-H4-BANK0-SOURCE-LOSS` / `V14R-H5-BANK1-SOURCE-LOSS`：HELD source必须resident且
  kind/token/epoch等于capture tuple；无授权丢失fail loud；同编号cancel-bubble marker禁止fallback。
- `V14R-H6-BANK0-OWNER-IDENTITY` / `V14R-H7-BANK1-OWNER-IDENTITY`：输出owner tuple必须等于held tuple。
- `V8G-SQ-LAUNCH-AUTH` / `V8G-AMO-LAUNCH-AUTH`：live fire 必须具备 first-launch authorization；
  held fire 必须具备 exact owner-residency lease。二者是同一 fire assertion 的互斥授权路径，不能因
  选择性恢复删除或放宽断言。
- fire/consume/MIQ原子性、singleton exclusion与READY DAG由focused TB、既有双bank回归、lint与
  `check-contract`共同承重，不用删除断言或放宽terminal语义替代。

上述可执行不变量使用 `always @(posedge clk)` immediate assertion；不得用 `$stable`/SVA。mutation
matrix 至少分别覆盖：holder bypass、cancel zero-arm fallback、consume/MIQ 改读 live grant、single-bank
probe-order谓词删除、SQ held residency退回live `sq_drain_valid_w`、AMO held fire退回live launch
authorization。每个负向版本都必须编译成功并由对应定向观测拒绝；release TB自身仍独立拒绝
连续 VALID owner swap，不能只依赖 assertion-only shadow。mutation聚合器必须逐variant匹配专属拒绝
marker与最终`[RESULT] FAIL`；领域PASS marker只允许在`tb_errors==0`时输出，禁止以任意失败冒充命中。

## 5. 验证、留存与晋级边界

最低成本顺序：

1. baseline release + `OOO_ASSERT` directed TB：bank0、bank1分别让低优先级 issue source在READY=0
   时展示，再引入高优先级source并保持到exact-fire；同时核对唯一source consume以及MIQ
   kind/ROB/pdest/size/unsigned/owner tuple与217-bit request payload同源。
2. cancel/capacity case：在request transport仍开放且live contender存在时注入branch recovery，确认整拍
   VALID=0、无fire/consume/MIQ；另以bank1-full/bank0-free及反向矩阵证明容量背压只作用本bank。
3. single-bank order：先让older store probe驻留MIQ，再让younger plain-store进入reservation；要求
   younger request保持VALID=0，删除`issue*_miq_probe_block_r`谓词的负向版本必须被拒绝。
4. SQ launch-lease case：用真实 store probe/fill 形成 backpressured SQ holder，再关闭 ROB
   first-launch gate模拟 younger selective recovery窗口；要求 live `sq_drain_valid_w=0`，但 holder
   VALID/payload/source exact保持并在READY恢复时精确fire，request-sent、drain-inflight与MIQ birth同拍。
5. AMO launch-lease case：用真实AMO read response形成backpressured write holder；关闭同一
   first-launch gate后要求write payload/owner保持并exact-fire，`mem_amo_write_sent_q`与LEGACY MIQ同拍。
6. compile-success mutation matrix：分别移除held override、允许cancel fallback、让consume/MIQ改读live
   grant、删除single-bank order谓词、把SQ held residency退回live valid、把AMO held fire退回live
   authorization；六个版本逐一编译并逐一触发
   目标oracle。
7. `check-rtl-style`、Verilator lint、Icarus module TB、`check-contract`；检查断言计数不回退及无新SCC。
8. focused层全过后只跑一次CoreMark invalid probe；要求`invalid_events=0`及全部reason=0。若production
   RTL已变化，旧baseline仅作冻结counter reference，结果必须标记current-design diagnostic、
   `observer_noninterference_qualified=false`与`PPA=UNQUALIFIED`。
9. probe闭合后先重建当前ARCH_STABLE/功能cohort，再恢复CoreMark/Dhrystone各三份同设计A/B与PPA；
   不能把跨设计diagnostic的周期差直接当作CPI promotion证据。

V14R focused PASS只证明request admission hold/cancel合同；不自动证明完整架构、CPI收益、综合/STA、
Power或PPA promotion。task-run保留result、marker、source/config/tool hash与bounded log；Icarus/VVP、
Verilator obj_dir、Yosys中间树和mutation副本在receipt后删除。

## 6. 风险与回退

- source Q若不能在stall期间保持payload，立即断言会暴露；不得用放宽checker处理。备选是full-payload
  skid，但必须重新比较434 FF与关键路径。
- issue/retry holder与selective recovery冲突时按§2.3先形成invalid bubble；已经展示的older exact
  SQ/AMO lease保持到fire。不得把瞬态launch gate关闭误报成source loss，也不得连续VALID换owner。
- holder若让bank0/bank1 ordinary无条件串行，属于性能回归；回退并修cross-bank exclusion，不删hold。
- 任何STORE B、exact owner、flush/recovery、SQ head授权或MIQ守恒回归均回退production RTL，保留FAIL。

## 7. 变更记录

- 2026-08-04：V14Q reason-conserved probe定位1,176次`admission_identity_change`；冻结V14R合同、29-bit
  selector/identity holder拓扑、cancel bubble、assertion/mutation与分层验证边界。
- 2026-08-04：实现双bank holder与single-bank older-probe admission规则；focused、compile-success
  holder-bypass mutation、V8S/default/V11L/V11M、style、lint、graph/census/contract均PASS。当前设计
  CoreMark冻结日志为5,380,028 cycles / 3,183,617 retired，GOOD TRAP，owner-timing invalid 0；原始
  receipt-build FAIL保留，current-design checker replay独立PASS。PPA与完整架构晋级仍为GAP。
- 2026-08-04：独立终审后补齐exact-fire consume/MIQ同源、非flush recovery cancel、双向bank-full
  隔离、single-bank older-probe顺序；compile-success mutation从1项扩为4项。固定wheel支持仅在显式
  task-run子目录保留result/log，build/VVP与mutation工作副本仍自动清理。
- 2026-08-04：终审反例进一步要求领域PASS marker受`tb_errors==0`门控，并把mutation判定从“任意
  FAIL”收紧为每个variant的专属marker加最终FAIL，消除孤立grep与错误失败原因造成的oracle假绿。
- 2026-08-04：V14W系统反例暴露SQ holder在younger selective recovery窗口把first-launch gate误当成
  source residency；冻结`launch_open`与`owner_open`分层合同，并要求真实SQ holder定向用例及第五项
  compile-success mutation承重。
