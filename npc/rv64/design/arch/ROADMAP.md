# RV64 OoO 核 · 架构演进路线图（living document）

> **类型**：active plan / living backlog。
>
> **最近更新**：2026-07-27。
>
> **现状输入**：`rv64-200mhz-completion-design.md`、
> `../../eval/ppa/evidence/architecture-current.json`、
> `.github/task-runs/2026-07-21-rv64-v9a-width-continuity/`；2026-07-11 历史快照：
> `rtl-ground-truth-2026-07-11.md`；架构原则：
> `ooo-core-architecture.md`；逐模块合同：`../specs/README.md`。
>
> 本文件只保存当前优先级、依赖和验收标准。已完成方案、失败实验和逐轮性能明细应进入
> `history/`、task-run 或 Git 历史，不继续堆在 active backlog 中。

<!-- ARCH-DEBT-P0: FDG-G1,XRET-G1,MEM-ISSUE-G1,IFU-AXI-G1,IFU-FETCH-G2,IFU-ACCESS-G1,IFU-TVAL-G1,PTW-PMP-G1,INSTRET-G1 -->
<!-- ARCH-DEBT-P1: F0-G1,MIQ-FLUSH-G1,STORE-BRESP-G1,FENCE-G1,A-COHERENCE-G1,CONTROL-EVENT-G1,SERIALIZE-G1,WFI-G1,SFENCE-SINVAL-G1,VECTORED-TRAP-G1,DEBUG-TRIGGER-G1 -->

以上两行是 `architecture-debt-ledger.json` 的机器清单锚点。新增、删除或重分级 P0/P1
必须同时修改机器账本；冻结检查器要求两侧 exact-membership，并以本文件 SHA 使旧账本失效。

---

## 1. 当前状态

### 1.1 微架构

- 小窗口 RV64 OoO：双 dispatch/双 commit、ROB16、int/FP PRF64、int/FP IQ8、
  global completion 2。
- branch、FP、load/store/AMO 已进入正式 OoO 主路径；branch/jump/memory/FP pending
  owner 已物理删除。
- system/trap/IRQ/fault 默认仍走 pending + full drain；`OOO_CSR_QUEUE_HEAD` 默认 0。
- fetch redirect PC 已由年龄律 `OooRedirectArbiter` 单源化；kill/reason/flush_backend 与
  trap/pending 副作用仍未形成唯一 control event。
- IFU 单 outstanding；memory bridge 为 one active + one staged，真实 MLP 约等于 1。
- SQ4/MIQ4、Dcache 32KiB 但 line 仅 8B；无 LQ/replay/MSHR/L2/coherence。

### 1.2 验证状态

| gate | 2026-07-14 可采信结果 | 当前边界 |
| --- | --- | --- |
| official riscv-tests | 177/177 逐项 PASS | current-config sweep 非 Difftest；F0 另有 Difftest-ON AM gate |
| module testbench | 历史 100/100 真 PASS；当前 required inventory=112 | V9Z 已在当前 design_id 下由 `testbench/Makefile` 的 `TESTS` 动态推导并取得 112/112；该 module-only aggregate 不替代同源 official/AM/DiffTest aggregate |
| AM cpu-tests | 59/59 真 PASS | `fp-difftest-probe` 明确 Difftest ON |
| benchmark/DPI | CoreMark、Dhrystone-10000、sized DPI PASS | Dhrystone 默认500000在20min timeout，未宣称长跑 PASS |
| lint/build | Verilator build + lint 零告警 | 不替代功能和合同 gate |

F0 结果聚合已修正并重跑；后续切片必须复用真实 rc gate，仍不得只凭外层摘要扩写为
功能、Linux 或物理签核完成。

### 1.3 2026-07-27 full-core freeze 资格

- DI-1..DI-5、OOO-1..OOO-4 已在同一
  `design_id=sha256:bbb9c95199ada2e0e8160c235705a270f924240b28fde6e611bd9342398084c9`
  下 9/9 GREEN；这是必要条件，不替代全核债务、holder census 或功能 aggregate。
- 当前 full-core `ARCH_STABLE=GAP`：15 个 CLOSED 债务均已绑定当前设计；
  `CONTROL-EVENT-G1` 由 V9O 10/10 focused、3/3 queue-head 配置、11/11 负向 RTL
  版本与 V9R owner/holder 交接证据闭合，`VECTORED-TRAP-G1` 由 V9U 13 类
  CsrFile 用例、3 条全核路径与 7/7 负向 RTL 版本闭合。当前同源功能聚合为模块
  111/111、official 177/177、AM 59/59、DiffTest mismatch 0。full-core capability
  cohort 已由 `full-core-cohort-scope-v1.md` 冻结：`A-COHERENCE-G1`、
  `DEBUG-TRIGGER-G1`、`SFENCE-SINVAL-G1`、`WFI-G1` 以当前 design/cohort-bound
  合同解析为 `EXCLUDED_BY_COHORT`。V9Y 已闭合 pending-system exact
  memory-owner terminal consumer，V9Z 已闭合 pending architectural-trap 的同一组合
  consumer 边界；当前同源功能聚合为 module 112/112、official 177/177、AM 59/59、
  DiffTest mismatch 0。剩余显式 P1 债务只有 `SERIALIZE-G1=OPEN`：clocked
  fire-to-owner-clear、arch-trap 与 ECALL/IRQ/xRET/CSR/FENCE overlap、七类
  exactly-once、holder census 实例图/语义闭包与 exact freeze-input cohort inventory
  仍未完成。
- `architecture-debt-ledger.json` 是 active P0/P1 裁决的机器真源；
  `eval/ppa/tools/arch_stable_freeze.py` 负责 exact-input audit。资格闭合前只允许诊断性
  synthesis/STA，PPA 保持 `UNQUALIFIED`、`promotion_eligible=false`。

### 1.4 PPA / 性能

- CoreMark 当前回归：`6563047 cycles / 3218532 commits / CPI 2.039`；不能外推为所有
  workload 的加权 CPI。
- current frozen source target-driven fresh Yosys + exact-5ns OpenSTA：top40 40/40 MET，actual
  worst slack `+0.017907454ns`；网表 SHA256 `d7e5263f…e93eac`，source/netlist/setup-member
  binding 与 mutation-negative 均 PASS。T-PRE gate-level proxy 已达到200MHz。
- 仍有303 input missing delay、1873 output missing delay、1875 unconstrained endpoints；ideal
  clock、placeholder macro、无 SPEF/CTS/OCV/uncertainty。该结果不是 post-route/physical signoff，
  17.907ps 也不是可消费的物理裕量。

## 2. P0 — 先关闭正确性合同

| ID | 项目 | 当前证据 | 关闭标准 |
| --- | --- | --- | --- |
| FDG-G1 | **CLOSED；V9D 于 2026-07-21 重绑当前设计**：`arch_trap` head0 不得呈现 backend | current focused：4 类非法 FP 均分类为 `arch_trap` 且 backend 0 呈现，1 个合法 FADD.S 正控制到达 backend；全核程序精确捕获 1 次非法指令 trap，capture PC/tval 与 CSR `mepc/mtval` 各 1/1，known commit observer 1 hit、非法 FP 0 提交、handler/MRET 完成；6/6 current-source 可编译 RTL 验证变体及 1/1 commit-observer 探针被动态拒绝 | `make -C npc/rv64 check-fdg-arch-trap`；module 109/109，同一 `design_id=sha256:6236b1…f2f3dc`；未生成当前 official/AM/DiffTest 同源 aggregate，后续只防回退 |
| XRET-G1 | **CLOSED；V9E 于 2026-07-21 重绑当前设计**：MRET/SRET current-mode 合法性与精确异常 | current focused：7 点矩阵覆盖合法 MRET@M、SRET@S/M 和非法 MRET@S/U、SRET@U、SRET@S+TSR；全核合法 MRET/SRET 各 1 次 CSR 请求/提交/返回，非法 head0 MRET 与 lane1 SRET 各精确 capture 1 次、CSR 请求 0、提交 0、`mepc/mtval` 精确，lane1 更老 ADDI 正常退休；8/8 current-source 可编译 RTL 验证变体与 2/2 observer 探针被动态拒绝 | `make -C npc/rv64 check-xret-current-mode`；module 109/109，同一 `design_id=sha256:6236b1…f2f3dc`；未生成当前 official/AM/DiffTest 同源 aggregate，后续只防回退 |
| MEM-ISSUE-G1 | **CLOSED；V9F 于 2026-07-22 重绑当前设计**：单端口 terminal1 request-fire/consume/MIQ owner birth 同一事务 | 普通双 memory uop 原子捕获；terminal0 本地地址异常时 terminal1 保持，下拍 request fire/consume/birth 各 1；15 字段身份一致，两拍反压期间 fire/consume/birth 均 0；terminal0 竞争获得端口 fire 时 terminal1 保持且 MIQ 归属 terminal0；成功发射后 3 拍无重复；8/8 可编译 RTL 验证变体被动态拒绝 | `make -C npc/rv64 check-memory-issue-lifecycle`；module 109/109，同一 `design_id=sha256:6236b1…f2f3dc`；未生成当前 official/AM/DiffTest 同源 aggregate，PPA 仍不合格化 |
| IFU-AXI-G1 | **CLOSED；V9G 于 2026-07-22 重绑当前设计**：A-update AW/W/B 随 flush 完整排水 | current focused 3/3：AW-first/W-first、flush 同拍 first/last AW/W、AW+W+B 同拍、both-done+B-error、两拍冲刷保持、drop quiet；AxiXbar 两拍 BREADY 背压期间不提前释放 owner，后继 master 地址/数据/响应保持；18/18 current-source 可编译 RTL 验证变体被动态拒绝 | `make -C npc/rv64 check-ifu-axi-flush-drain`；module 109/109，同一 `design_id=sha256:6236b1…f2f3dc`；生产 RTL 未修改，未生成当前 official/AM/DiffTest 同源 aggregate，PPA 仍不合格化 |
| IFU-FETCH-G2 | **CLOSED；V9H 于 2026-07-22 重绑当前设计**：跨页 second-page page-fault byte provenance | current focused：13 行 page-end 矩阵含 9 条 F2/F4/F6 fault（5/3/1），每条两拍 response backpressure 锁定事务 owner、接受后两拍禁止年轻 AR/fill/SRAM write；成功 packet 后不复位再执行 F2 证明 tail 清零非 reset-vacuous；真实 invalid-PTE F0 与 decoder F0/poison 分别覆盖零前缀和 fault suffix 净化；16/16 current-source 可编译 RTL 验证变体被动态拒绝 | `make -C npc/rv64 check-ifu-fetch-provenance`；focused 2/2、module 109/109，同一 `design_id=sha256:6236b1…f2f3dc`；生产 RTL 未修改，PMP/RRESP、完整物理 footprint、lane1 capture、fault-`tval` lifecycle 与 PTW write PMP 保持独立，PPA 仍不合格化 |
| IFU-ACCESS-G1 | **CLOSED 2026-07-13**：精确2B footprint、PMP/RRESP 与 lane1 owner | 旧 RTL 34 RED；current F=0/2/4/6、M-fill→S、RRESP/owner/guard-page 全绿 | exact EXEC access + sized DPI + branch resolve owner 常驻回归 |
| IFU-TVAL-G1 | **CLOSED 2026-07-14**：faulting-portion `mtval/stval` | T4G 真实 page-end offset2/4/6 与 16-bit control | packet-level fault address 跨 FIFO/branch/pending owner 保持 |
| PTW-PMP-G1 | **CLOSED 2026-07-14**：I/D walker PTE WRITE 独立 PMP 判定 | R-only PTE deny、RW allow 与 flush/drop 正反例 | READ grant 不替代 WRITE grant；deny 无 AW/W |
| INSTRET-G1 | **CLOSED 2026-07-21**：唯一 ISA-retirement 计数源 | V9C 全核 Sv39 程序：异常 lane 2/2 零增量，MRET/SRET/SFENCE.VMA=1/6/1，控制提交 8/8 精确单增量，CsrFile 边沿检查 1052 次；3/3 current-source 可编译 RTL 验证变体被动态拒绝 | `make -C npc/rv64 check-instret-retirement`；同一 `design_id=sha256:6236b1…f2f3dc`，后续只防回退 |

原则：P0 未闭合前不扩大 ROB/IQ/MLP；扩并行会增加状态交叠并放大上述边界。

## 3. P1 — 状态一致性、平台语义与验证基础设施

### 3.1 验证结果聚合（`F0-G1`：历史完成，当前冻结证据待刷新）

- module runner 已同时裁决 compile/sim rc、TB 自身 PASS、FAIL/error 与失败型 `$finish`；
  三个陈旧 TB 已刷新 current contract。
- AM runner 已上传单项失败并拒绝缺项/重复/未知/损坏行；`fp-difftest-probe` 的 FP
  destination-domain 根因已修复。
- F0 历史 gate 为 module 86/86、AM 59/59（Difftest ON）、official 177/177；当前生产
  `TESTS` 清单已演进为 109 项。full-core freeze 必须重新生成同一 design_id 的
  109/109 + 177/177 + 59/59 + applicable DiffTest=0 aggregate，禁止把 86/89/100/102 等历史
  计数改写为当前覆盖。

### 3.2 memory / flush

- `MIQ-FLUSH-G1`：**CLOSED；V9F 于 2026-07-22 重绑当前设计**。环形队列的
  LOAD/PROBE/DRAIN 混合集合证明流水线冲刷只保留未消费 DRAIN，从 keep-set
  精确扣除同拍 fired head，并保持 owner identity 与 wrapped FIFO 顺序；2/2
  可编译 RTL 验证变体被动态拒绝；额外锁定 valid head 但 no-pop-fire 时不得误扣除，
  MIQ 共 3/3 变体被动态拒绝；`pop_fire` 还必须满足 exact-owner match，owner mismatch
  由 `OOO_ASSERT` 定义为非法接口激励。DRAIN 结论只到
  transport-irrevocable/nokill 物理写请求边界，不等同于已架构退休。
- `STORE-BRESP-G1`：retired/device late-B error 已由当前 OOO-3 的 request/B/retirement
  生命周期、精确 cause/tval 和编译成功 RTL 验证变异闭合；账本保存同源证据，后续只防回退。
- `FENCE-G1`：V9M 已把普通 FENCE 的 pending-system full-drain 合同绑定当前 design-id；
  store→FENCE→device-read 定向程序观测到完整 memory-idle 等待，CoreGlue→ControlPlane
  `mem_idle` 运行时连接检查通过，两份可编译负向 RTL 版本被对应 testbench 精确检出，当前模块
  aggregate 为 109/109。该单项现为 `CLOSED`，不外推 full-core ARCH_STABLE 或 PPA。
- Sv39 device mapping 与标准 lane/size 已由 T4I bridge+xbar+device/DPI 联测关闭；动态设备内部
  B `SLVERR` 的退休后精确 trap 仍需 ROB owner 或无副作用 write-probe，不能由静态 PMA 冒充。
- `A-COHERENCE-G1`：**EXCLUDED_BY_COHORT 2026-07-26**。full-core v1 只包含一个
  RV64 hart，且无可写 active LR/SC reservation granule 的 autonomous
  coherent/exclusive peer；本地 store/AMO/SC invalidation 保持现有 RTL 合同。任何新增
  coherent master、exclusive transport 或 peer invalidation 输入都会改变 cohort 并重开本项。

### 3.3 control plane

- `CONTROL-EVENT-G1` 已在当前设计关闭：ROB full pregrant 是唯一 C0 请求，
  `OooControlEventApplySequencer` 是唯一 C0→C1 state owner，V9R 继续约束
  SQ-query retry holder 在 full-flush barrier 下的交接。
- `SERIALIZE-G1`：serialize-at-retire 仍是高风险专项；必须在 P0 与验证聚合修复后，再评估
  `OOO_CSR_QUEUE_HEAD=1` 和 system/trap ROB 公民化。V9Y 已证明 pending-system
  drain 消费 exact memory-owner terminal，V9Z 已把同一条件接入 pending
  architectural-trap 的 gate→mux 组合边界；但 clocked next-edge owner clear、无新
  capture 时副作用不重复、arch-trap 与 ECALL/IRQ/xRET/CSR/FENCE overlap
  priority/unreachability 及七类联合 exactly-once 仍为 OPEN。
- `VECTORED-TRAP-G1` 已声明为 full-core cohort required：mtvec/stvec Direct/Vectored
  WARL、`BASE+4×cause` 中断入口、同步 BASE 入口、未委派 supervisor interrupt
  进入 M 以及 `mem > ex > irq` 单记录合同由 V9U 当前设计门覆盖；局部关闭不产生
  PPA 晋级。
- `WFI-G1`：**EXCLUDED_BY_COHORT 2026-07-26** 的仅是 true sleep/wakeup
  capability；现行 WFI 继续经过 pending-system drain、精确退休并 immediate-resume，TW
  非法路径不变。
- `SFENCE-SINVAL-G1`：**EXCLUDED_BY_COHORT 2026-07-26** 的仅是 address/ASID
  selective invalidation；所有 accepted SFENCE.VMA/Svinval-family encoding 继续形成
  保守 global `mmu_flush`。
- `DEBUG-TRIGGER-G1`：**EXCLUDED_BY_COHORT 2026-07-26**。simulation
  observability、`OOO_ASSERT` 与 semihost EBREAK 保留，但 full-core v1 不广告 Debug Module、
  debug mode、halt/resume transport 或 executable trigger。

## 4. P2 — 性能与 PPA 演进

### 4.1 前端

1. **PPA-R1（当前）**：按 `rv64-architecture-ppa-contract.md` 恢复 cache-hit frontend
   II=1；采用 elastic request/tag/response pipeline 与 selective squash，禁止恢复
   response→request 组合旁路或三拍单事务 FSM。
2. 增加普通 JALR 小型 target predictor；改善 RAS 可回滚/可用窗口。
3. 以 fetch block + byte queue 取代“8B packet 只展开两条”的字节浪费。
4. 在 memory hierarchy 可支撑后，再考虑多 IFU outstanding 与 speculative history。

### 4.2 后端

1. **PPA-R1（当前）**：恢复完整 pair capability；先让 registered memory reservation 作为
   虚拟 lane0 owner 时仍可 promotion 一个独立 uop 到 lane1，再以动态 steering 逐步移除
   simple-only lane1/静态 memory lane 限制。该过渡刀本身不代表 DI hard gate 已关闭。
2. int IQ 从全表 compact/oldest scan 演进为 valid+age、分 bank 或分层选择。
3. PRF 评估 bank/replica/同步读阶段，减少多口异步 FF 代价。
4. completion 从固定优先级演进为可保留/轮转仲裁，降低长尾抖动。
5. 先清除 ROB idx/preg 固定位宽切片，再评估 ROB32/更大 PRF；禁止只改参数扩容。

### 4.3 memory hierarchy

单 request/单 AGU 路线只允许作为内存顺序正确性的中间实验，必须标记
`architecture_infeasible`，不能进入最终 PPA 基线。完整双发射出口固定为：LQ、age compare、
violation replay、tagged outstanding、两路 AGU/翻译/LSQ 查询/cache-request admission、MSHR、
burst refill 与独立 PTW 资源；并须同刀设计 response identity、kill/drain 和 memory ordering，
不能只把 MIQ 深度改大，也不能把第二条 memory 仅移出 IQ 后串行排队。

## 5. 已完成里程碑（只保留摘要）

- B1：store probe / SQ / retire / committed drain 已落地。
- B-FP：独立 FP rename+IQ+execute+ROB commit cluster 已落地，旧 pending-FP 已删除。
- B2 主体：pred_npc、issue resolve、显式 mispredict、ROB-walk 已落地；fetch redirect PC
  arbiter 已进入生产路径。
- B4：pending branch/jump/memory、prefetch/BTC、synthetic lane1-ret 等可分离死模块已删除；
  剩余大文件拆分与 owner 归位仍是维护性 backlog。
- XRET-G1：classifier current-mode legality 已闭合并由 V9E 重绑当前设计；S-mode MRET 与
  U-mode lane1 SRET 均以 precise illegal-instruction 进入 CsrFile trap，`mepc/mtval`、
  no-xRET-request/commit、合法 MRET/SRET 正控制与 lane1 更老指令退休均有可执行证据。
- MEM-ISSUE-G1：当前两级 memory reservation terminal 路径已以接受握手
  `valid && ready` 定义 request fire；terminal consume 与 MIQ owner birth 与该 fire 同拍一致。
  edge-old terminal0 本地终结时 terminal1 不 look-through；下拍发射、反压保持、
  15 字段事务身份与禁止重复发射均为常驻定向回归。
- IFU-AXI-G1：A-update write owner 与 fetch semantic owner 已分离；flush 只 sticky-drop 旧语义，
  AW/W/B 完整排空后回 IDLE。V9G 已在当前 design_id 下锁定同拍/错拍 AW/W/B、BRESP
  优先级、两拍冲刷与 AxiXbar BREADY 背压 owner 释放；18/18 可编译 RTL 验证变体均被动态拒绝。
- IFU-FETCH-G2：bridge 已用 3-bit split 保存 first/second-page response provenance，decoder
  按真实 C/32 byte range 映射并净化 faulted inst；V9H 在当前 design_id 下锁定 13 行
  page-end 矩阵、真实 invalid-PTE F0、成功 packet 后无复位 stale-tail 反例、两拍 response
  backpressure 与接受后静默，并动态拒绝 16/16 个 current-source 可编译 RTL 验证变体。
  PMP/RRESP、完整物理 footprint、branch 后 lane1 page/access-fault capture、faulting-portion
  tval 与 PTW write PMP 明确仍由独立条目跟踪。
- IFU-ACCESS/TVAL/PTW-PMP：exact halfword access、lane1 owner、faulting-portion tval 与 I/D
  PTE WRITE authorization 已分别由 IFU-ACCESS-G1、T4G、T4F 关闭。
- T4I standard AXI lane：LSU adapter、AWSIZE、AW/W/B owner 与标准设备/DPI lane 已闭合；
  fresh T-PRE exact-5ns proxy 40/40 MET。物理 T-PHYS 与动态设备 late-B 精确 trap仍单列开放。
- fence.i：真实 pending-system commit + mmu_flush + refetch 已落地。
- Sv39 HW A/D：I/D 主路径已落地；实施计划已归档，PTE write PMP 仍作为 P0 开放项。

对应实施史见 `history/`、`../specs/history/` 与 Git 历史；active ROADMAP 不重复保存逐次
失败实验和过期 gate 数字。

## 6. 每轮执行与完成标准

1. **RECALL**：读本文件、current snapshot、相关 active spec 与 NPC memory。
2. **CONTRACT**：先冻结接口、stall、flush、异常序、访存序、恢复六类合同。
3. **IMPL**：一职责一改动；不把文档修订与无关 RTL 重构混刀。
4. **VERIFY**：先 focused 正反例，再 lint/build/module/official/AM；检查原始日志，不能只看 summary。
5. **PPA**：性能改动按全量与代表样本；STA 数字附模型边界。
6. **REVIEW**：实现者给证据，审查者主动找反例、真空检查和越级结论。
7. **RECORD**：更新 active spec、current snapshot、memory 和 task-run；完成的 plan 同刀归档。

任何项目只有满足表中“关闭标准”才可从 P0/P1 移入“已完成里程碑”；“summary PASS”本身
不再作为关闭条件。
