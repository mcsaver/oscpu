# RV64 OoO 核 · 架构演进路线图（living document）

> **类型**：active plan / living backlog。
>
> **最近更新**：2026-07-15。
>
> **现状输入**：`rv64-200mhz-completion-design.md`、
> `.github/task-runs/2026-07-14-rv64-t4i-standard-axi-lanes/`；2026-07-11 历史快照：
> `rtl-ground-truth-2026-07-11.md`；架构原则：
> `ooo-core-architecture.md`；逐模块合同：`../specs/README.md`。
>
> 本文件只保存当前优先级、依赖和验收标准。已完成方案、失败实验和逐轮性能明细应进入
> `history/`、task-run 或 Git 历史，不继续堆在 active backlog 中。

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
| module testbench | 100/100 真 PASS | 当前生产清单；100 份 raw log 由 task-run SHA manifest 锁定 |
| AM cpu-tests | 59/59 真 PASS | `fp-difftest-probe` 明确 Difftest ON |
| benchmark/DPI | CoreMark、Dhrystone-10000、sized DPI PASS | Dhrystone 默认500000在20min timeout，未宣称长跑 PASS |
| lint/build | Verilator build + lint 零告警 | 不替代功能和合同 gate |

F0 结果聚合已修正并重跑；后续切片必须复用真实 rc gate，仍不得只凭外层摘要扩写为
功能、Linux 或物理签核完成。

### 1.3 PPA / 性能

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
| FDG-G1 | **CLOSED 2026-07-12**：`arch_trap` head0 不得呈现 backend | 旧 RTL 四类非法 FP 精确 RED；断言负探针非真空；focused 4/4 | module 87/87、AM Difftest ON 59/59、official 177/177；后续只防回退 |
| XRET-G1 | **CLOSED 2026-07-12**：MRET/SRET current-mode 合法性 | 旧 RTL MRET-from-S/U、SRET-from-U 精确 RED；真实编码 integration 覆盖 head0/lane1 | classifier + CsrFile 边界合同已冻结；module 87/87、AM 59/59、official 177/177；后续只防回退 |
| MEM-ISSUE-G1 | **CLOSED 2026-07-12**：lane1 memory dequeue/request/MIQ owner 同源 | 旧 RTL `fire=1/request=0` 丢事务；reviewer 负探针再锁 `request=1/fire=0` 幽灵 MIQ | eligible/available 单一事实 + MEM-I1/I2；module 87/87、AM Difftest ON 59/59、official 177/177 |
| IFU-AXI-G1 | **CLOSED 2026-07-12**：A-update AW/W/B 随 flush 完整排水 | 旧 RTL bridge 22 RED、bridge+xbar owner deadlock 3 RED | sticky drop + 独立 shadow；focused 2/2、module 88/88、AM 59/59、official p-mode 153/153 |
| IFU-FETCH-G2 | **CLOSED 2026-07-12**：跨页 second-page page-fault byte provenance | 旧 RTL 真实 Sv39 12 行矩阵精确 4 RED；当前 12/12 + poison + reviewer 8/8 | bridge segment split + decoder 单一长度 owner；module 89/89、lint/style/contract/build |
| IFU-ACCESS-G1 | **CLOSED 2026-07-13**：精确2B footprint、PMP/RRESP 与 lane1 owner | 旧 RTL 34 RED；current F=0/2/4/6、M-fill→S、RRESP/owner/guard-page 全绿 | exact EXEC access + sized DPI + branch resolve owner 常驻回归 |
| IFU-TVAL-G1 | **CLOSED 2026-07-14**：faulting-portion `mtval/stval` | T4G 真实 page-end offset2/4/6 与 16-bit control | packet-level fault address 跨 FIFO/branch/pending owner 保持 |
| PTW-PMP-G1 | **CLOSED 2026-07-14**：I/D walker PTE WRITE 独立 PMP 判定 | R-only PTE deny、RW allow 与 flush/drop 正反例 | READ grant 不替代 WRITE grant；deny 无 AW/W |
| INSTRET-G1 | 唯一 ISA-retirement 计数源 | **T4J RTL/focused 已实现**：core/final count 均滤 exception，CsrFile 接 final lanes；等待程序级证据 | exception 不计、control retire 各计一次的程序回归 |

原则：P0 未闭合前不扩大 ROB/IQ/MLP；扩并行会增加状态交叠并放大上述边界。

## 3. P1 — 状态一致性、平台语义与验证基础设施

### 3.1 验证结果聚合（F0 已完成，2026-07-11）

- module runner 已同时裁决 compile/sim rc、TB 自身 PASS、FAIL/error 与失败型 `$finish`；
  三个陈旧 TB 已刷新 current contract。
- AM runner 已上传单项失败并拒绝缺项/重复/未知/损坏行；`fp-difftest-probe` 的 FP
  destination-domain 根因已修复。
- F0 当时 gate 为 module 86/86、AM 59/59（Difftest ON）、official 177/177；后续切片已把
  current module gate 推进到 89/89。结果传播只需防回退，可补 child-command 注入失败 fixture
  锁定 core-regress 的 `OVERALL_RC` 合同。

### 3.2 memory / flush

- MIQ flush + DRAIN pop 同拍：局部动态已复现；补完整 NpcCoreTop 波形或常驻 checker。
- retired store late B error：明确 PMEM 永不报错的平台合同，或选择可承载精确错误的退休策略。
- 普通 FENCE：当前 legal no-op；用 RVWMO/多 observer litmus 决定实现范围。
- Sv39 device mapping 与标准 lane/size 已由 T4I bridge+xbar+device/DPI 联测关闭；动态设备内部
  B `SLVERR` 的退休后精确 trap 仍需 ROB owner 或无副作用 write-probe，不能由静态 PMA 冒充。
- A 扩展能力声明限定为 single-hart local model；多主平台需要 reservation invalidation 与
  coherent/exclusive transport。

### 3.3 control plane

- B2 后续：在已完成 fetch-PC 单源化基础上，统一 kill/reason/flush_backend 的消费合同。
- B7 serialize-at-retire：仍是高风险专项；必须在 P0 与验证聚合修复后，再评估
  `OOO_CSR_QUEUE_HEAD=1` 和 system/trap ROB 公民化。
- true WFI、selective SFENCE/SINVAL、vectored trap、完整 debug/trigger 作为独立能力项，
  不与当前合同修复混刀。

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
- XRET-G1：classifier current-mode legality 已闭合；S-mode MRET 与 U-mode lane1 SRET 均以
  precise illegal-instruction 进入 CsrFile trap，`mepc/mtval` 与 no-xRET-commit 常驻回归通过。
- MEM-ISSUE-G1：lane0 exception 与 lane1 normal memory 的端口资格、IQ fire、request mux 与
  MIQ owner 已收敛到不依赖 ready 的 eligible/available 单一事实；正向 co-fire 与 head-blocked
  反例均为常驻回归，`MEM-I1/I2` 立即断言基线已提升到 37。
- IFU-AXI-G1：A-update write owner 与 fetch semantic owner 已分离；flush 只 sticky-drop 旧语义，
  AW/W/B 完整排空后回 IDLE。bridge 22 RED、bridge+xbar 3 RED 与 12 条非真空断言均已闭合。
- IFU-FETCH-G2：bridge 已用 3-bit split 保存 first/second-page response provenance，decoder
  按真实 C/32 byte range 映射并净化 faulted inst；真实 Sv39 B=2/4/6 矩阵与 semihost poison
  常驻。PMP/RRESP/物理读宽、branch 后 lane1 page/access-fault capture、faulting-portion tval
  明确仍在开放项。
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
