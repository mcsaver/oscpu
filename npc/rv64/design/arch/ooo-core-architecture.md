# RV64 OoO 核 · 微架构宪法（normative architecture constitution）

> **定位**：本文件是 RV64 乱序核的**规范性（normative）顶层架构文档**——即"微架构宪法"。
> 它不描述"现在代码里有哪些模块"（那是 `vsrc/README.md` 与 `design/specs/*.md` 的职责），
> 而是**规定**：指令生命周期、标准数据对象（uop / fetch_packet / 各类 event）的字段与生命周期、
> 状态 owner 表、谁允许产生副作用、哪些路径允许 flush、redirect/trap 的仲裁语义，
> 以及 pending 机制的长期地位与退出计划。
>
> **为什么需要它**：本核是"实现先长出来、架构后补"。功能上已是 OoO / 双发射 / rename / ROB / IQ /
> PRF / CSR / FP / Sv39；代码上也已拆出干净的 frontend/decode/rename/execute/memory/control/writeback
> 目录与 owner。但这些 owner 之间的关系主要是**历史演化**出来的，而不是先有一张架构图、再让代码服从它。
> 本文件就是那张图。下一步重构应**反过来用本文件约束实现**。
>
> **版本**：v0.2（2026-07-03，随全 RTL 从零重读同步【现状】层；v0.1 为 2026-06-29 草案）。
> 证据来源：2026-07-03 的 9 路无文档依赖 RTL 重读 + 矛盾裁定 + 追问验证
> （`.github/task-runs/2026-07-03-rv64-rtl-reread-audit/`），现状快照见
> **`rtl-ground-truth-2026-07-03.md`（与本文件冲突时以其证据为准）**；v0.1 证据见
> `.github/task-runs/2026-06-29-rv64-ooo-core-architecture-constitution/`。
> **配套**：流程/优先级 backlog 见 `ROADMAP.md`；逐模块规范见 `../specs/`；模板见 `SPEC-TEMPLATE.md`。
> 本文件是 `ROADMAP` 中 B2（redirect FSM）/ B3（spec 体系）/ B4（文件组织）/ B-LSQ 的**共同父规范**。

---

## 0. 本文件的地位与读法

1. **规范优先级**：涉及"一条指令应经过哪些形态、哪个模块拥有哪块状态、谁能改架构状态、谁能 flush"
   这类**架构级问题**时，以本文件为准；与某个局部 spec 冲突时，先改本文件或先改该 spec 使之一致，
   不允许"代码这么写所以架构就这样"。
2. **as-is / target 标注约定**：本核现状与目标尚有差距，故每条都显式标注：
   - 【现状】= 今天 RTL 的真实行为（带 `file:line` 证据，可被审计）。
   - 【宪法】= normative 规则（**必须**遵守；新代码与重构必须向它收敛）。
   - 【目标】= 尚未达成、但所有改动应朝它走的形态。
   - 【迁移】= 从现状到目标的可执行路径，映射到 `ROADMAP` backlog。
3. **本文件不替代** spec：数据对象的**字段语义**在这里规定一次（single source of truth），
   各模块 spec 只描述自己如何生产/消费这些字段，不得各自重新定义同名对象。

---

## 1. 核心论点：实现先长出来，架构后补 —— 两个执行域

审计确认：本核**同时存在两种执行域**，这是当前架构最关键、却未被显式命名的事实。

- **域 A（真乱序 / true-OoO）**：直线整数算术/乘除/load 等"常规" uop，走
  `decode → rename → ROB 分配 → IQ 入队 → wakeup/select/issue → execute → writeback → commit`，
  动态调度、双发射、分支投机配 ROB-walk 恢复。这是核真正的乱序数据通路。
- **域 B（串行 pending / serialized）**：**system / trap** 类"ISA 要求串行"的指令，被前端/控制面
  捕获进**单 entry pending owner**，核拉高 `stop_pending`，
  **把后端完全 drain 干净（ROB/IQ 清空）**，解析这唯一一条 pending op，再恢复取指。
  这本质上是**顺序执行**。

> 【现状（2026-07-03 重读更新）】域 B 的总开关仍是 `OooStopPendingSequencer`（全局 `stop_pending`）
> + `OooPendingDrainResolveGate`（`backend_drained` 同步屏障），但覆盖面已从 v0.1 的六类收缩到
> **仅 system/trap 类**：CSR 指令、ecall/ebreak、mret/sret、wfi、sfence.vma/Svinval、取指 fault、
> 非法指令类 arch-trap、中断注入、lane1 barrier。
> **branch/jump（F2 真预测 + issue 解析 + ROB-walk）、fp（独立 rename/IQ/流水簇 + 经 ROB 提交）、
> load/store/AMO（SQ probe/drain + MIQ）已全部迁回域 A**；
> `pending_branch / pending_jump / pending_mem` 三通道已被形式化证死（capture 恒 0，
> 见 `rtl-ground-truth-2026-07-03.md` §4），pending-FP 壳已物理删除。
> 即：v0.1 的"对所有控制流/访存/FP/系统指令退化为近顺序"**已不再成立**，
> 残余串行仅限稀少的 system/trap 类（这正是 §8.2 裁定 KEEP 的那一半）。

**本核的 north star 是真正的乱序多发射（true OoO superscalar）——目标是把域 B 拆掉，不是把它"约束好"。**
但域 B 混了**两类性质完全不同**的串行，必须分开处理：

- **频繁四类 `branch / jump / mem / fp`**：性能关键，真 OoO **必须投机穿过**它们。它们落进域 B
  纯属"投机分支恢复 / LSQ / FP 簇还没建"时的占位脚手架——对真 OoO **毫无价值，必须拆除、迁回域 A**（§8）。
  **〔2026-07-03 状态〕四类的功能迁移已全部完成**（branch/jump=F2、fp=FP 簇、mem=SQ/LSQ Phase2+3；
  pending_mem 通道经证明本就不可达）；残余工作是**死壳物理删除**（B4 清理）与
  **B-LSQ 剩余件**（LQ/依赖预测/MSHR 多 outstanding——这是性能项，不再是"串行化"问题）。
- **稀少两类 `system / trap`**：CSR 副作用 / 特权切换 / 精确异常，ISA 要求串行。对它们
  "drain + 在 ROB 队头执行 + 刷新更年轻指令"是**真 OoO 的标准做法**（BOOM 等核同样把 serializing 指令做成
  drain），因稀少而性能可忽略——**保留**（机制可从全局 `stop_pending` 改为更干净的 ROB-队头串行）。

故本文件的目标不是"让 B 好好待着"，而是：**定义真乱序多发射的目标结构（§8.4），给出把 branch/jump/mem/fp
四类逐个迁回域 A 的拆除路线，最终删掉 `stop_pending` 与全部 branch/jump/mem/fp 的 pending owner**；
只留 system/trap 经 ROB 队头串行。（迁移已完成；删壳未完成——见 §8.3 各行状态。）

---

## 2. 七条总原则（the layering constitution）

以下七条是本核的**根本约束**。每条给出 normative 规则与当前偏离。

| # | 宪法原则 | 【现状】偏离 |
| --- | --- | --- |
| **C1** | **Frontend 只生产"预测路径上的 fetch packet + 预测信息"**，不拥有数据通路语义与全局恢复语义。 | 偏离重。前端 55 子模块中 >40% 与恢复/重定向相关，承载三级分支恢复、RAS、pending branch/jump 串行（已证死待删）、dispatch gating（`vsrc/frontend/OooFrontend.v`、`OooBranchResolveRecoveryGate.v`）。 |
| **C2** | **Decode/Rename 把 fetch packet 变成带物理寄存器的 uop**，且 uop 有**统一字段契约**。 | 偏离中。uop 是**散线**，无打包结构；复用 50-bit legacy `CTRL_BUS`（`define.v:598-643`）。decode 在 2 处被实例化。 |
| **C3** | **Scheduler 只负责 ready / select / issue**。 | 基本达成。`OooIntIssueQueue` 核心是干净的 oldest-ready 选择；附带 dispatch-bypass/mem-order/load-branch 快路径属"调度脚手架"非语义掺杂（`vsrc/scheduling/OooIntIssueQueue.v`）。 |
| **C4** | **Execute cluster 只产生 `result_event` / `branch_event` / `mem_event`**。 | 部分达成（域 A）。事件存在但为散线非统一束（`vsrc/execute/OooIntBackend.v`）；FP 已是独立执行簇 `OooFpBackend`（2026-07-02，pending 旁路已删）。 |
| **C5** | **Memory ordering 只负责 load/store 顺序与副作用提交**。 | 部分。SQ(4)+probe/drain+store→load 前递已落地（LSQ Phase2/3）；桥仍单 outstanding 串行 FSM（`OooMemAxiBridge`）；`OooPendingMemorySequencer` 已证死（capture 恒 0）。 |
| **C6** | **Commit 是唯一允许改变架构状态的地方**（受规约的例外须显式登记）。 | 基本达成 + 一个**受规约例外**：E1 SQ 退休后 drain 落存（E2 FPR / E3 fflags 已随 FP 簇消除）。详见 §7.1。 |
| **C7** | **ControlPlane 只仲裁 redirect / trap / flush，不直接拥有数据通路语义**；且 redirect/flush 应有**单一仲裁语义**。 | 偏离重。控制面是"补丁总线"：≥12 类 redirect/flush 源、≥5 处汇合点、无统一事件类型与优先级链（`vsrc/control/*`）。 |

一句话宪法：

> **Frontend 生产 fetch packet；Decode/Rename 造 uop；Scheduler 只 ready/select/issue；
> Execute 只产 event；Memory ordering 只管顺序与副作用；Commit 是唯一改架构状态的点；
> ControlPlane 只仲裁 redirect/trap/flush。**

---

## 3. 真实模块层级与子系统边界

### 3.1 【现状】实例化树（2026-07-03 重读实测，非愿景）

```text
NpcSimTop (仿真壳: 3×AxiDpiSlave + AxiLiteVirtioBlk + DPI 事件泵)
└── NpcTop (可综合 SoC: NpcAxiBus→AxiLiteXbar 2M×16S + UART/CLINT/PLIC + 9 stub 窗)
    └── NpcCoreTop (u_core)
        ├── OooFetchAxiBridge   取指桥：ITLB+硬件 PTW+取指包 cache(4096)+PMP×5   core/NpcCoreTop.v:163
        ├── OooMemAxiBridge     数据桥：DTLB+硬件 PTW+dcache(32KB)+PMP×3+单-outstanding FSM  :192
        ├── CsrFile             特权/架构 CSR 状态（M/S/U、trap、satp、PMP、计数器）        :359
        └── OooCoreTopGlue (1315 行) —— 核内主互联；存储/流控/重定向"策略"仍集中在此    :238
            ├── OooFrontend        子系统 wrapper（取指/FIFO/分类/预测/派发 mux，~44 子模块）
            │   ├── OooFetchPacketDecode → OooRvcDecompressor ×2 / OooFetchPacketFifo(4)
            │   ├── OooBranchDirectionPredictor / OooRasStack(32) / OooJalrBtb(死:恒空)
            │   ├── OooBranchResolveRecoveryGate / OooDirectControlFlowGate / OooFetchRequestMux …
            │   └── OooPendingBranch/JumpSequencer + prefetch 家族 + BTC（全部死路,待 B4 删）
            ├── OooExecuteBackend  子系统 wrapper
            │   └── OooAluCoreSlice
            │       ├── OooArchRegFile  ★ 架构 GPR（committed）仍在"ALU core slice"内
            │       └── OooAluDecodeBackend（DecodeStage ×2 + supported 白名单 + FP 旁路合成）
            │           └── OooIntBackend (2929 行)
            │               ├── OooDispatchBackend
            │               │   ├── OooFreeList / OooRenameMap / OooBusyTable
            │               │   ├── OooRob(16)   ★ ROB 仍在"dispatch backend"内
            │               │   └── OooIntIssueQueue(8)
            │               ├── OooPhysRegFile(64,10R2W) / ALU×2 / MulDiv / Clmul / Bitmanip×2 / AmoGate
            │               ├── OooStoreQueue(4) / OooMemInflightQueue(4) / LSU helper ×4
            │               └── OooFpBackend  ★ FP 簇（2026-07-02 落地,pending 壳已删）
            │                   ├── FP rename(map32+FreeList 复用+busy) / OooFpIssueQueue(8)
            │                   ├── OooFpPhysRegFile(64,4R2W) / OooFpRegFile(架构 FPR,commit 写)
            │                   └── OooFpArithGate(FADD3/FMUL3/FMA5) / Convert / LongOp(Div/Sqrt 57拍)
            │                     / Compare / Classify / Sgnj gate
            ├── OooMemoryAccess    子系统 wrapper（OooPendingMemorySequencer=证死 / RequestGate=纯透传）
            ├── OooControlPlane    子系统 wrapper（13 实例：CSR mux×2 / PendingDispatchArbiter
            │                      / Flush / PendingSystem / PendingTrapExit / StopPending / TrapExit mux…）
            ├── OooWriteback       子系统 wrapper（ControlCommitSequencer / CommitOutputMux
            │                      / SyntheticLane1Ret{Seq,Gate}=设计路径死）
            └── OooPendingOperandReadGate（域 B 架构操作数读）
```

〔v0.1→v0.2 树差异：`OooFpPendingExec`/`OooPendingFpSequencer`/`OooFpCommitGate` 已物理删除，
FP 改为 `OooIntBackend` 内的 `OooFpBackend` 真乱序簇；`OooFpRegFile` 移入 FP 簇（架构 FPR，commit 双写）；
新增 SQ/MIQ/dcache/DTLB 访存件；前端 DecodeStage 已收敛（分类走 `OooFetchHeadClassifyGate` 的 ctrl 总线）。〕

### 3.2 【现状】拓扑与流水语义的四处错配（本核"干净的杂糅感"根因）

1. **子系统 wrapper 是"从 glue 抽出的聚合"，不是有窄契约的架构边界。** 五个 wrapper 的文件头都写明
   "纯结构聚合，从 OooCoreTopGlue 抽出 N 个实例"，且 "Storage and flow-control decisions stay in
   OooCoreTopGlue"。即目录干净，但**真正的互联策略仍在那个 1315 行的 glue 里**，wrapper 只是把实例
   分组搬了出去。这正是"干净 owner，但关系是历史演化"的字面证据。
2. **`DecodeStage` 被实例化 2 处共 8 份**（前端 6×、`OooAluDecodeBackend` 2×）。译码没有单一 owner 阶段，
   前端为分类/预取做一份、后端为真正 dispatch 再做一份。
3. **架构 GPR（committed `OooArchRegFile`）在 `OooAluCoreSlice` 内**（执行簇），而 **ROB 在 `OooDispatchBackend`
   内**，commit 决策逻辑却在 `OooWriteback`。即"产生 commit 决定（ROB@dispatch）→ 经 writeback mux →
   写 arch GPR（@execute）"跨了三个子系统，最重要的架构状态离它的提交决策点很远。
4. **"execute backend" 名不副实**：`OooExecuteBackend → OooAluCoreSlice → OooAluDecodeBackend →
   OooIntBackend → OooDispatchBackend` 这条链里塞进了**译码 + rename + 分配 + ROB + IQ + PRF + arch-RF**。
   命名（"执行后端"、"ALU core slice"）严重低估了其内容。

### 3.3 【目标】逻辑分层 = 物理容器

> 【宪法 C-TOPO】**逻辑流水阶段应与模块容器一一对应**：frontend / decode / rename+dispatch /
> schedule / execute / memory-order / writeback-commit / control 各为一个有窄契约的顶层子系统，
> 互联契约写在子系统端口上，而非集中在一个 glue 巨文件里。

> 【迁移】对应 `ROADMAP` B4（文件组织）。**不要求大重写**，但每次触碰这些边界时，应：
> (a) 把"策略"从 `OooCoreTopGlue` 下沉到对应子系统；(b) 把 `OooArchRegFile` 归位到 writeback/commit 域；
> (c) 评估前端 6 份 `DecodeStage` 的预译码能否收敛到"预解码（轻）+ 后端译码（全）"两类。
> 这些是低风险结构变换，build/gate 不变即可逐步收口。

---

## 4. 指令生命周期（canonical lifecycle）

> 【宪法 C-LIFE】一条指令从 fetch 到 commit，**只允许**经过下列标准形态之一。任何新增路径必须先在本节登记。

### 4.1 域 A 主线（直线整数/乘除/load）

```text
   fetch_packet ── decode/rename ── uop ── ROB分配+IQ入队 ── wakeup/select/issue
        │              │             │            │                  │
   OooFrontend    OooAluDecode   (带 preg)   OooRob/OooIntIQ      OooIntIssueQueue
        │                                                            │
        └────────────────────────────────────────────── execute ──→ result_event / branch_event / mem_event
                                                            │                       │
                                                       OooIntBackend          写 PRF + 唤醒广播 + (分支)前端重定向
                                                            │
                                                         ROB done ──→ commit ──→ commit_event ──→ 写 arch GPR / 释放旧 preg / 更新 RRAT
                                                                         │
                                                                    OooRob/OooCommitOutputMux/OooArchRegFile
```

每形态的 owner 与"形态变换"：

| 阶段 | owner（现状） | 输入形态 → 输出形态 |
| --- | --- | --- |
| Fetch | OooFrontend（取指/预测） | PC → `fetch_packet`（双槽 pc/inst/resp + 预测） |
| Decode/Rename | OooAluDecodeBackend + OooRenameMap/FreeList | `fetch_packet` → `uop`（+ 物理寄存器 prs/prd/old_prd + ctrl） |
| Dispatch | OooDispatchBackend（含 OooRob/OooBusyTable） | `uop` → ROB entry + IQ entry（+ rob_idx + src ready） |
| Schedule | OooIntIssueQueue | IQ entry → `issued_uop`（oldest-ready，2-wide） |
| Reg-read | OooPhysRegFile（10R2W，其中 5 读口死硅 + 写-读旁路） | `issued_uop` → 带操作数值的 uop |
| Execute | OooIntBackend（ALU/MulDiv/CLMUL/Bitmanip/AMO/Compare） | uop → `result_event` / `branch_event` |
| Writeback | wb0/wb1 通道 → ROB + PRF + busy-table 唤醒 | `result_event` → ROB done + PRF 写 + 唤醒广播 |
| Commit | OooRob → OooCommitOutputMux → OooArchRegFile | ROB head → `commit_event` → 写 arch GPR / free old_preg / 更新 RRAT |

### 4.2 域 B 旁路（branch/jump/mem-barrier/fp/system/trap）

```text
   fetch_packet ── 分类(facts) ── OooPendingDispatchArbiter 仲裁 ── capture 进单 entry pending owner
                                          │                                    │
                                  置 stop_pending（OooStopPendingSequencer）   保存该指令全部 payload
                                          │
                                  backend 完全 drain（ROB/IQ 清空，OooPendingDrainResolveGate）
                                          │
                          resolve（分支比较 / JALR 目标 / 访存 / FP 计算 / CSR 副作用 / trap 进入）
                                          │
                          commit / redirect / trap ── 清 stop_pending ── 恢复取指
```

> 【宪法 C-LIFE-B】域 B 的每一种 pending 轨迹**必须**在 §8 的普查表中登记其 `classifies_as`、
> `serializes`、`trigger`、`on_main_path`、`long_term_replacement`。未登记的新 pending 不允许引入。

---

## 5. 标准数据对象（normative 字段定义）

> 【宪法 C-OBJ】下列对象的**字段集合在本节定义一次**。模块 spec 只说明自己生产/消费哪些字段，
> 不得另起同名对象。Verilog 里今天即便仍是散线，也**必须**按本节字段名与生命周期对应。
> 【目标】逐步把高频对象（uop / commit_event / redirect_event）收敛为**打包总线/结构**。

### 5.1 `fetch_packet`

【现状】由 `OooFetchPacketDecode` 产出，存入 `OooFetchPacketFifo`（深度 4），双指令槽。
散线，无打包；证据 `vsrc/frontend/OooFetchPacketDecode.v:53-75`、`OooFetchPacketFifo.v:62-70`。

| 字段 | 宽 | 含义 |
| --- | --- | --- |
| `pc0` / `pc1` | 64 | 两槽指令 PC |
| `inst0` / `inst1` | 32 | RVC 解压后指令 |
| `next_pc0` / `next_pc1` | 64 | 各槽 fallthrough（pc+len） |
| `packet_next_pc` | 64 | 整包下一取指 PC |
| `resp0` / `resp1` | 2 | 取指访问响应（异常/缺页检测） |
| `pred_*` | — | 预测信息（taken/target/BHT/RAS 提示） |

### 5.2 `uop`（核心对象）

【现状】**散线，无 `uop_t` 结构**；跨模块靠"端口名约定"对齐。控制位复用 50-bit legacy `CTRL_BUS`
（`vsrc/include/define.v:598-643`，原服务 legacy `NpcCore`，OoO 直接沿用未改造）。
证据：`vsrc/rename_allocate/OooDispatchBackend.v:63-85`、`vsrc/scheduling/OooIntIssueQueue.v:97-137`、
`vsrc/writeback/OooRob.v:88-122`。最近的 `OooSlotFacts`（41-bit）只覆盖 fetch/decode 分类，不是完整 uop。

| 字段 | 宽 | producer | 生命周期 |
| --- | --- | --- | --- |
| `pc` / `next_pc` | 64 | decode / 前端预测 | decode→commit |
| `inst` | 32 | fetch | fetch→ROB |
| `ctrl`（CTRL_BUS） | 50 | DecodeUnit | decode→issue→execute |
| `rs1_arch` / `rs2_arch` / `rd_arch` | 5 | DecodeStage | decode→rename |
| `imm` | 64 | ImmGen | decode→execute |
| `src1_preg` / `src2_preg` | 6 | OooRenameMap | rename→execute |
| `pdest` | 6 | OooFreeList | rename→writeback |
| `old_pdest` | 6 | OooRenameMap | rename→commit（释放） |
| `src1_ready` / `src2_ready` | 1 | OooBusyTable | dispatch→issue |
| `rob_idx` | 4 | OooRob | dispatch→commit |
| `data` | 64 | execute | execute→commit |
| `exception` / `cause` / `tval` | 1/5/64 | execute/memory | execute→commit（精确异常） |

> 【宪法 C-OBJ-UOP】(1) **uop 字段以本表为唯一定义**；新增字段先改本表。(2) **`CTRL_BUS` 应与 OoO 解耦**：
> 现状把 in-order 控制总线塞进 OoO uop 是债务，新增控制位优先走 OoO 专属字段而非继续扩 legacy 位图。
> 【迁移】把 uop 收敛为打包 bus（先 dispatch→issue→execute 段），对应 `ROADMAP` B4；属低风险、可被 gate 守住。

### 5.3 执行簇事件：`result_event` / `branch_event` / `mem_event`

【现状】事件存在但为**散线非统一束**（`is_unified_bundle=false`）。

`result_event`（`vsrc/execute/OooIntBackend.v:166-180,2427-2494`）：
`{valid, rob_idx, prd, value, exception, cause, tval}`，双通道 wb0/wb1 → ROB + PRF 写 + 唤醒广播。

`branch_event`（2026-07-03 更新）：resolve 总线
`{valid, pc, next_pc, mispredict, taken, pred_taken, bht_idx, is_branch, misaligned}`——
**已有显式 `mispredict` 位**（issue 级统一解析，`mispredict = 架构 next_pc != pred_npc`，
`OooIntBackend.v:1661-1684`），并携带 BPU 回训载荷（bht_idx/pred_taken 为 dispatch 拍快照随 uop thread）。
dispatch 级快路径源已被 `OOO_DBRANCH_DOMAIN_A=1` 证死（恒 0），实际单源=issue resolve。
v0.1 记录的"无显式 mispredict、靠隐式比对"已随 F2 落地而解决。

`mem_event`（`vsrc/memory/OooMemAxiBridge.v`）：现状不是统一束，而是
`mem_req_valid/mem_rsp_valid/mem_rsp_rdata/mem_rsp_error/mem_rsp_page_fault` 等独立接口。

> 【宪法 C-EVT】执行簇对后级**只**经这三类 event 通信。【目标】把每类收敛为带 `valid` 的统一束，
> 并给 `branch_event` 增加**显式 `mispredict` 位**（消除"靠 next_pc 比对隐式判定"的脆弱性），对应 `ROADMAP` B2。

### 5.4 `commit_event`

【现状】**已是统一束**（域 A 唯一干净的事件，`is_unified_bundle=true`）。
`vsrc/writeback/OooRob.v:280-335` + `OooCommitOutputMux.v:95-198`，双通道 commit0/commit1。

字段：`{valid, pc, next_pc, inst, rd_en, arch_rd, old_pdest, new_pdest, data, exception, cause, tval}`。
精确异常：异常项阻止 commit1（`OooRob.v:282-285`，ROB-I2）；commit0 必为 head、commit1 必为 head+1。
合成 lane1 ret（`OooSyntheticLane1Ret*`）：双发射分支取消时的虚拟退休项，**不写架构状态**（仅计退休数）。

> 【宪法 C-OBJ-COMMIT】`commit_event` 是架构可见的程序序退休点，字段以本表为准。其它对象不得复制其语义。

### 5.5 `redirect_event`（取指重定向，**目标统一格式**）

【现状】**无统一 redirect_event**。取指 PC 重定向有 10+ 源，由前端 `OooFetchRequestMux` 按优先级链择一
（direct jal/ret/branch、pending jump、branch-resolve、branch-spec restore、untracked…见 §7.3）。

> 【目标 C-OBJ-REDIR】统一为单一对象，由**单一 control-flow arbiter** 仲裁：
> ```text
> redirect_request {
>   valid
>   pc                  // 目标 PC
>   reason              // branch_miss / xret / trap / sfence / fence_i / debug / jalr / …
>   priority            // 三档：IMMEDIATE > DEFERRED > TRAP_COMMITTED
>   kill_younger_than   // rob_idx 或 spec tag
>   flush_fetch         // 冲前端
>   flush_backend       // 冲后端（squash younger）
> }
> ```
> 所有 branch miss / trap / xret / sfence / fence.i / debug-exit 都成为该仲裁器的**输入**。
> 对应 `ROADMAP` B2（redirect/PC sequencer 改显式状态机，先补定向 TB）。

### 5.6 `trap_event` / `exit_event`

【现状】分散在 `OooCsrTrapRequestMux`（commit 异常 / pending arch-trap / ECALL / IRQ / xret-priv-boundary）
与 `OooTrapExitEventMux`（pending 分支/跳转 misalign / drain 终态 / ebreak-exit）。多 mux、payload 不统一。

> 【宪法 C-OBJ-TRAP】`trap_event { valid, epc, cause, tval, deleg(M/S), is_interrupt }`；
> `exit_event { valid, kind(ecall/ebreak/sim-exit) }`。【目标】并入 §5.5 的统一 arbiter，作为 `reason=trap` 的一支。

---

## 6. 状态 owner 表（normative）

> 【宪法 C-STATE】每块架构/微架构状态**有且只有一个 owner 模块**；写者与写阶段以本表为准。
> 跨模块写同一状态必须在本表登记并说明仲裁。下表为审计实测（带 `file:line`）。

| 状态 | owner | 写者 | 写阶段 |
| --- | --- | --- | --- |
| 架构 GPR（committed, x0-x31） | `OooArchRegFile`（★在 OooAluCoreSlice 内） | commit0/commit1（`rd_en && !exc && rd!=x0`）；serial_write 口已封 0 | **commit** |
| 整数 PRF（投机结果，64×） | `OooPhysRegFile` | execute wb0/wb1 | execute writeback（同拍旁路可见） |
| 架构 FPR（committed, f0-f31） | `OooFpRegFile`（在 OooFpBackend 内） | commit 双写口；trap flush 时作为物理堆恢复源 | **commit**（E2 已消除） |
| FP 物理堆（投机，64×） | `OooFpPhysRegFile`（4R2W） | FP 算术完成 / FP load 写回 | execute writeback |
| 投机 rename map（RAT, 32×int + 32×fp） | `OooRenameMap` + OooFpBackend 内 fp_map | lane0/lane1 rename（同拍 WAW lane1 胜）；ROB-walk 逐项还原 | rename / walk |
| free list（int + fp 各一） | `OooFreeList` ×2 实例 | alloc（rename）/ free（commit）/ walk 回收 | rename + commit + walk |
| busy table（int + fp） | `OooBusyTable` + fp_busy 数组 | alloc 置忙 / wakeup 置就绪（同拍 alloc 胜） | rename + writeback |
| ROB(16) | `OooRob`（★在 OooDispatchBackend 内） | dispatch 入队 / wb 置 done / commit 出队 / ROB-walk 反向 squash | dispatch+writeback+commit+walk |
| 架构 PC / 取指 PC | `OooFetchPcOutstandingSequencer` | 多源 redirect mux | fetch/redirect |
| ~~投机恢复检查点（map/free/busy/IQ/ROB 五套影子）~~ | 各自模块 checkpoint_*_q | **死硅**：`cp_*` 在 mode=1 下恒 gate 0，已被 ROB-walk 取代（待 B4 删除） | — |
| Store Queue（4 项） | `OooStoreQueue`（在 OooIntBackend 内） | 发射拍 probe 回填 PA+data / commit 置 committed / 队头 drain 落存 | issue + commit + drain |
| CSR（mstatus/mtvec/mepc/mcause/medeleg/mie/mip/…） | `CsrFile` | CSR 写指令（commit）/ trap 自动更新 | **commit** + trap |
| satp（虚存模式） | `CsrFile` | CSR 写（受 mstatus.TVM 约束；WARL 仅 Bare/Sv39） | commit |
| PMP（pmpcfg×2 / pmpaddr×16） | `CsrFile` | CSR 写（WARL + lock） | commit |
| fflags / frm（FCSR） | `CsrFile` | fflags 随 ROB 进 commit 拍 OR 累积（`OooFpCommitGate` 已删）；CSR 写 | **commit**（E3 已消除） |
| Sv39 TLB（I/D 各 64 项） | `OooSv39Tlb` ×2 实例（两桥内） | page-walk 完成填充；mmu_flush 全清 | memory/fetch |
| pending owner entry（system/trap；branch/jump/mem 已死） | 见 §8 普查表 | capture/clear/resolve | 域 B |

【现状·缺口更新（2026-07-03）】v0.1 的"无独立 store buffer"已解决：SQ(4) + probe/drain +
store→load 前递已落地（LSQ Phase2/3）。**剩余缺口 = 无 LQ/依赖预测/replay、无 MSHR、
两桥单 outstanding（真实 MLP≈1）**——B-LSQ 的性能残件。

> 【宪法 C-STATE-OWN】**架构 GPR 应归属 commit/writeback 域**（现状在 execute 内是历史错配，见 §3.2-③）。
> 迁移时只搬归属、不改时序语义；属 B4 范畴。

---

## 7. 副作用 / flush / redirect 宪法

### 7.1 谁允许改架构状态（C6 细则）

> 【宪法 C6】**仅 commit 改架构状态**。当前有且仅有**三个受规约例外**，每个都必须满足其约束、且登记在此：

| 例外 | 何时写 | 受规约约束（为何安全） | 证据 |
| --- | --- | --- | --- |
| **E1 · SQ drain / 解耦 store** | store 数据在 commit 后由 SQ 队头 nokill drain 落存（PMEM 解耦：AW&W fire 即完成，B 后台吸收） | 仅已退休 store 才 drain（发射拍只 probe 不落写）；MMIO/可错 store 仍等 B 保精确总线异常；drain 对 flush 免疫（写必达） | `OooStoreQueue.v`、`OooMemAxiBridge.v:479-481,738-748` |
| ~~**E2 · FPR 写**~~ | **已消除（2026-07-02，FP 簇落地）**：FPR 改为架构堆 commit 双写 | — | `OooFpBackend.v`（`OooFpCommitGate` 已删除） |
| ~~**E3 · fflags 累积**~~ | **已消除（同上）**：fflags 随完成事务进 ROB，commit 拍非异常才 OR 入 fcsr（架构序精确） | — | `OooFpBackend.v` / `CsrFile.v` |

> 【宪法 C6-限制】**不得新增新例外**。E2/E3 已随 FP 迁出 pending 而按计划消失（v0.1 的预言兑现）。
> E1 从"B1 提交前落存"演进为"SQ 严格 commit 后 drain"——**已不再是提交前写内存**，
> 仅剩"drain 落存遇总线错误无法精确 trap（打印计数警告）"这一已知边界；须维持 probe 拍前置翻译/PMP 的前提。

### 7.2 哪些路径允许 flush

> 【宪法 C-FLUSH】允许产生 flush/squash 的**仅**两类来源：
> (a) **分支/控制流误预测**（kill younger-than 该指令）；(b) **精确 trap/xret**（kill 该指令及其后全部）。
> 任何模块不得自行 flush 全核；flush 必须经 §7.3 的仲裁汇合点表达为 `redirect_request`/`trap_event`。

【现状】flush 由多处产生：前端 `direct_frontend_flush`（`OooFrontendActionGate`）、
`core_trap_flush` + `trap_redirect_squash`（`OooControlFlushSequencer.v:25-29`）、
RAS 清空（权限边界 / spec restore，`OooRasUpdateGate.v:25-29`）、各 pending owner 的 clear。
分散且无统一"kill 范围"语义。

### 7.3 redirect/flush/trap 单一仲裁（C7 细则）

【现状】审计实测：**redirect/flush 源 ≥12 类，汇合点 ≥5 处，无统一优先级链**：

| 汇合点 | 负责的源 |
| --- | --- |
| `OooFetchRequestMux`（前端） | 取指 PC 重定向优先级链：direct jal/ret/branch、pending jump、branch-resolve、branch-spec restore、untracked-resolve（10+ 源） |
| `OooFrontendActionGate` | direct 前端 flush（direct branch/jal/ret fire） |
| `OooCsrTrapRequestMux` | commit 异常、pending arch-trap、pending ECALL、IRQ、xret 特权边界 |
| `OooTrapExitEventMux` | pending 分支/跳转 misalign、drain 终态 trap/exit（ebreak） |
| `OooControlFlushSequencer` | `core_trap_flush` 脉冲、`trap_redirect_squash` sticky、checkpoint 恢复 flush |

> 【目标 C7】收敛为**单一 control-flow arbiter**，输入全部 redirect/flush/trap 源，输出 §5.5 的
> `redirect_request`。**仲裁主判据＝年龄**：同拍多源取 age 最老（`rob_idx − rob_head`，环形）者胜——
> 更老的重定向会 squash 更年轻的源本身；同 age 平手按类 `trap > branch > direct`（trap/xret 恒在 commit/head=最老，
> 年龄律已天然给它最高）。`IMMEDIATE`(dispatch 直算)/`DEFERRED`(后端误预测)/`TRAP_COMMITTED`(commit) 三类只**描述典型 age 位置、非固定覆盖序**。
> 〔2026-07-03 更新：曾有"已实现地基"`vsrc/control/OooRedirectArbiter.v` + `tb_ooo_redirect_arbiter.sv`
> （13 例 RED→GREEN，年龄律 selector），但该模块**从未进编译清单/从未实例化**，属已验证但未接线的死文件；
> 经决策**删档减负**（模块+TB+filelist 变量+`REDIR_REASON_*` 宏全删，2026-07-03）。
> C7 统一仲裁**仍是目标**，但不再保留未接线的独立地基文件——待真正做 redirect 收口时从 git 历史复活或重导出。
> 当前 redirect 仲裁仍由 `OooFetchRequestMux` 隐式优先级链与多汇合点分散承担。〕
> 对应 `ROADMAP` B2。〔修正：本节初稿的"IMMEDIATE>DEFERRED>TRAP_COMMITTED 固定优先级"不正确，实现时改为年龄律，详见 `history/b2-branch-spec-redirect.md` §3.2（已归档）。〕

---

## 8. 拆除域 B：通往真正的乱序多发射

### 8.1 【现状】stop_pending + backend-drain 大锤——覆盖面已收缩到 system/trap

v0.1 审计确认的「pending 隐藏主干」（6 类指令各一个单 entry owner、每条难指令全后端 drain）
**在 2026-07-03 重读中已确认收缩**：`stop_pending` 的置位源只剩 system/trap/IRQ/fault/lane1-barrier 类
（`OooStopPendingSequencer.v:111-139`；分支臂被 `OOO_DBRANCH_DOMAIN_A` 关闭、FP 臂端口保留但 unused）。
branch/jump/mem/fp 四个 pending owner 的 capture 已全部恒 0 或物理删除（证据见
`rtl-ground-truth-2026-07-03.md` §4）。对仍走域 B 的 CSR/系统指令，每条数十拍的全排空成本不变——
这是 KEEP 项的固有代价，可在 serialize-at-retire 清理时再收窄。

### 8.2 域 B 的两半：必须拆 vs 可保留

> 把"难指令"全塞进 drain 模型，混淆了两类**性质完全不同**的串行：

- **频繁四类 `branch` / `jump` / `mem` / `fp`**：性能关键，真 OoO **必须投机穿过**它们。它们落进域 B
  纯属"投机分支恢复 / LSQ / FP 簇还没建"时的占位脚手架——对真 OoO **毫无价值**，是 ILP 杀手，
  **必须拆除、迁回域 A**。
- **稀少两类 `system` / `trap`**：CSR 副作用 / 特权切换 / fence / 精确异常，ISA 要求串行。
  对它们"drain + 队头执行 + 刷新更年轻指令"是**真 OoO 的标准做法**（BOOM 等核同样把 serializing 指令做成
  drain），因稀少而性能代价可忽略——**保留**（机制可从全局 `stop_pending` 改为更干净的 ROB-队头串行）。

> 【宪法 C-PEND】每个 pending owner 登记下表一行，裁决三选一：
> **ELIMINATE**（拆除，迁回域 A 由正式 OoO 结构承接）/ **KEEP**（ISA 必需的稀少串行，保留）/
> **DELETE**（四类拆完后机制本身删除）。

### 8.3 拆除计划表

| owner | 类 | 现状机制 | 裁决 | 目标：被谁取代 | ROADMAP |
| --- | --- | --- | --- | --- | --- |
| `OooPendingBranchSequencer` | branch | ~~单 entry + 全 drain~~ | **✅ 功能 ELIMINATED（2026-07-03）** | 已由「后端 issue 解析 + 显式 mispredict + ROB-walk 恢复 + **F2 真预测（pred_npc 单源, 预测正确免 redirect）**」取代（`../specs/history/ooo-f2-per-packet-pred-implementation-plan.md`，已归档）；pending 壳在 mode=1 为死路（capture 门控恒 0），文件删除待 B4 清理 | B2 ✅（tag/多 checkpoint 未做, ROB-walk 版够用） |
| `OooPendingJumpSequencer` | jump | ~~单 entry + 全 drain~~ | **✅ 功能 ELIMINATED（2026-07-03）** | JAL 前端直算（pc+imm, F2 后恒免 redirect）；JALR 走 RAS/BTB 投机续取 + 后端解析 mispredict（同分支机制）；pending 壳同上为死路 | B2 ✅ |
| `OooPendingMemorySequencer` + 单-outstanding 桥 | mem | ~~lane1 barrier~~ | **✅ 功能 ELIMINATED（2026-07-03 证实）** | 重读形式化证明 pending_mem capture 恒 0（lane1 barrier 条件与 FACT_MEM 严格互斥）——**该通道从未可达**，可整链删除；SQ(4)+probe/drain+store→load 前递+MIQ(4) 已落地（LSQ Phase2/3）。**剩余 = 性能残件**：LQ/依赖预测/replay、MSHR、多 outstanding 桥 | B-LSQ（残件） |
| `OooPendingFpSequencer` + `OooFpPendingExec` | fp | ~~单 entry，mem→long→compute 串行~~ | **✅ ELIMINATED（2026-07-02）** | 已由 `OooFpBackend`（FP rename + FpIQ + 执行簇 + 经 ROB 真 commit）取代；pending-FP 壳四文件删除、E2/E3 消除、fflags/FS-dirty 走 commit（`../specs/history/ooo-fp-cluster-implementation-plan.md` §8/§9，已归档） | 新 B-FP ✅ |
| `OooPendingSystemSequencer` | system | drain + 执行 | **KEEP** | 改"ROB 队头执行 + 退休刷 younger"标志位（语义不变，去掉全局 `stop_pending` 依赖） | 清理 |
| `OooPendingTrapExitSequencer` | trap | drain + 执行 | **KEEP / 瘦身** | 精确异常本就由 ROB 队头承接（exception 字段 + commit1 阻塞已在）；瘦掉冗余脚手架 | 清理 |
| `OooStopPendingSequencer` / `OooPendingDrainResolveGate` / `OooPendingDispatchArbiter` / 各 …Gate | 机制 | 全局门控/屏障/仲裁 | **DELETE（最终）** | 四类拆完后只剩 system/trap 的队头串行，全局 `stop_pending` + drain 机制整体删除 | **仍 KEEP（在用）**——见下 §8.4 注 |

> **【2026-07-04 serialize-at-retire 只读调查更正】**：本行 DELETE 与 §8.4 step 4 对 serialize-at-retire 的
> "改标志位、语义不变、复用队头精确异常"框定**经 RTL 只读调查证实为严重低估**。真相：**除 CSR 外的系统指令
> （ecall/mret/sret/wfi/sfence/IRQ/arch-trap）今天根本不进 ROB**，副作用由 pending 控制面在 drain-complete 拍
> 合成；CSR 也只在 drain 后作孤儿再注入。要"队头执行"须先把它们改造成真 ROB 公民、把 CSR 读点/副作用下沉到
> 队头/commit = **新建系统指令数据通路（~15-20 RTL + ~15 TB），非删机制**。判定=高风险大重写、增量分步差
> （中间态两套队头独占易死锁）、difftest 不比 CSR 故需 Linux boot smoke 护栏。**完整可行性评估 + 6 阶段实施
> 路线 + 风险登记见 `design/arch/serialize-at-retire.md`（专项 spec，本步作为独立专项推进，非快速改动）。**
> 在该专项阶段 5 完成前，本行机制保持 KEEP（在用），B4 死硅删除不触碰它们。

### 8.4 【目标】真正的乱序多发射结构（north star）

```text
Fetch(≥2-wide, BPU + BTB + RAS)
   └─ fetch_packet（只预测，无恢复语义）
Decode / Rename（GPR + FPR 统一重命名；分配 ROB entry + branch tag）
   └─ uop（统一打包，见 §5.2）
Dispatch ──► { Int IQ │ Mem IQ(AGU) │ FP IQ }   ← 分布式发射队列，乱序 wakeup/select
                 │            │            │
            Int ALU×n     AGU + LSQ     FP 管线（FADD/FMUL/FMA 流水 + Div/Sqrt 迭代）
            Mul/Div       LQ/SQ：前递 / 歧义消解 / replay / MSHR 多 outstanding
            Branch-unit（cond + JALR 解析 → 显式 mispredict + kill-tag）
                 │
            Writeback：广播 wakeup + 写 PRF + ROB 置 done
                 │
            Commit（≥2-wide 顺序退休）：唯一改架构态；精确异常 + serializing@队头；
                                       释放旧 preg；FPR/fflags 也在此写
Recovery：branch tag + 多级 checkpoint / ROB-walk；单一 redirect arbiter（§5.5）
```

**四个使能件（拆 B 的全部前置）**：

1. **多级分支投机 + 统一 redirect**（B2+B6）：**✅ 主体完成（2026-07-03, F2 整体落地）**——
   多条投机分支在飞、后端解析 cond+JAL+JALR 产出显式 mispredict + kill-younger-than（ROB-walk）、
   真方向/目标预测（BHT resolve-update + RAS/BTB）、预测正确免 redirect（pred_npc 单源）。
   branch tag/多 checkpoint 未做（单 ROB-walk 恢复够用, 需求出现再升级）。`branch`+`jump` 功能已拆。
2. **LSQ**（B-LSQ）：**◐ 部分完成（2026-07-03 状态）**——SQ(4)+发射拍 probe+退休 drain、
   store→load 前递、load 乱序投机发射+三层歧义保护、ROB-walk 年龄 squash 均已落地（Phase2/3）；
   **未做**：LQ/依赖预测/load replay、MSHR、多 outstanding 桥（真实 MLP≈1 的封顶仍在），
   且 Sv39 开启时前递/精判整体退化 blind（VA 别名）。
3. **FP 执行簇**（新 B-FP）：**✅ 完成（2026-07-02）**——FP 重命名 + FP IQ + FP 管线 + FP 经 ROB 提交
   已落地（rv64uf/ud 23/23 + 全集 difftest 全绿），`fp` 类清零、E2/E3 已消除。
4. **serialize-at-retire**（清理）：`system`/`trap` 改 ROB-队头执行 + 退休刷 younger，删 `stop_pending`。

**推荐拆除顺序**（依赖驱动，非随意）：

1. **先 B2（分支投机 + 统一 redirect）** —— 它是**一切投机深度的前置**：没有多级 spec 恢复，
   连 LSQ 的投机 load 都无法越过分支。先补 redirect 优先级定向 TB，再改 FSM。
   **规范已立**：`history/b2-branch-spec-redirect.md`（已归档；评审定 **B=ROB-walk** 为基线、C 最老分支快照作 Phase-2 快路径）。
2. **再 B-LSQ** —— 性能最大杠杆；依赖 #1 才能让 load 投机越过分支；difftest 已就绪护航。
3. **B-FP 可与 #2 并行** —— **✅ 已完成**（先于 B-LSQ Phase2+，实证独立簇不阻塞访存改造）。
4. **最后 serialize-at-retire 清理** —— 与 #1 的 redirect 改造同源，#1 落定后顺手收口，删 `stop_pending`。

> 【宪法 C-PEND-DIR】**域 B 的 branch/jump/mem/fp 四类是过渡脚手架，目标清零**；只允许 system/trap
> 经 ROB 队头串行存在。任何新指令默认走域 A；**严禁**再用新的 `stop_pending`/drain 旁路"绕过建正式 OoO 结构"。
> 每拆除一类，必须删掉对应 pending owner 并在 §8.3 标注完成，不允许只加不减。

---

## 9. 现状 ↔ 目标 差距表（gap analysis）

审计对用户点名的断言逐条裁决（证据见 §3–§8 及 task-run）：

| 断言 | 裁决 | 现状性质 | 迁移优先级 → ROADMAP |
| --- | --- | --- | --- |
| Frontend 拥有过多全局恢复语义 | **confirmed** | aspirational（待收口） | 中 → B2 + B4 |
| 缺统一 uop 格式（散线 + 复用 legacy CTRL_BUS） | **confirmed** | aspirational | 中 → B4 |
| Scheduler 已只管 ready/select/issue | **partially（基本达成）** | already-true（核心） | 低（维持） |
| Execute 只产 result/branch/mem event | **partially**（散线非束；FP 非簇） | 部分达成 | 中 → B2（事件束 + 显式 mispredict） |
| Commit 是唯一改架构状态点 | **partially**（+3 受规约例外；2026-07-03：仅余 E1） | already-true（GPR/精确异常）| E2/E3 已由 FP 迁移消解 |
| ControlPlane 是补丁总线、redirect 来源多 | **confirmed** | aspirational | 高 → B2（单 arbiter） |
| pending 是隐藏串行主干 | **confirmed→已拆除**（2026-07-03：四类 capture 恒 0/已删，仅 system/trap 在用） | 死壳物理删除待 B4 | 低 → B4 清理 |
| pending_mem 应被 LSQ 替代 | **superseded**（重读证明 pending_mem 从未可达；SQ/前递已落地） | 剩余=LQ/MSHR/多 outstanding 性能残件 | 中 → B-LSQ 残件 |

> **读法**：`already-true` = 宪法已基本满足，维持即可；`aspirational` = 宪法是目标、现状偏离，
> 重构应朝它走但**不要求一次到位**。本表是后续每轮迭代"选下一刀"的依据。

---

## 10. 维护约定

1. **改 RTL 前**：若改动触碰指令形态 / 数据对象字段 / 状态 owner / flush·redirect·trap 路径 / pending，
   **先更新本文件**（spec 先行，`ROADMAP §5`），再改对应 `design/specs/*.md`，最后动 RTL。
2. **新增路径需登记**：新的指令生命周期轨迹（§4）、新数据对象字段（§5）、新状态写者（§6）、
   新 redirect/flush 源（§7.3）、新 pending owner（§8.2）——一律先在本文件登记，否则视为违宪。
3. **域 B 单调收缩**：任何改动不得扩大 `stop_pending` 的覆盖范围；新指令默认走域 A。
4. **与其它文档关系**：本文件=宪法（normative 顶层）；`ROADMAP.md`=流程/优先级/时序 track；
   `specs/*.md`=逐模块实现规范；三者冲突时，架构问题以本文件为准、流程问题以 ROADMAP 为准。
5. **证据纪律**：本文件每条【现状】都应可被 `file:line` 审计；行号随重构漂移时，
   在对应迭代的 task-run 里更新，不让宪法与代码静默脱节。

---

### 附：v0.1 的已知未尽项（历史记录，v0.2 现状见 §8.3/§9）

- 顶层互联仍集中在 `OooCoreTopGlue`（v0.1 时 1415 行，现 1315 行）；本文件先**规定**子系统窄契约，下沉是 B4 的逐步工作。
- §5 的对象多数仍是散线；本文件先**定字段契约**，打包结构化是后续迭代。
- 多级分支 spec checkpoint（B6）、正式 FP 簇、LSQ 均为更大改动，本文件给方向与退出计划，不在本版落地。
