# B-LSQ 实施方案(Load-Store Queue 打破单 outstanding 访存封顶)

> 状态:spec(2026-07-01,基于全核只读审计)。对应宪法 §5(C5)、§8.3/8.4(B-LSQ),ROADMAP B-LSQ。
> 目的:把当前"单 outstanding 访存"这个访存 ILP 封顶用 LQ/SQ + store→load 前递 + 歧义消解 + load replay + MSHR 多 outstanding 替换。

## 0. 一句话结论
访存 ILP 封顶**不在** `OooPendingMemorySequencer`(默认 ROB-walk 模式下它对普通 load/store 已近死路,是可删残留脚手架),而在:
- **(A)** `OooMemAxiBridge` 单 `state_q` FSM(桥级一次一笔);
- **(B)** `OooIntBackend` 的 `mem_pending_q` + 单 `mem_buffer_q`(后端至多 1 在飞 + 1 暂存);
- **(C)** store 只在 ROB 队头发射 + load 对任意更老在飞 store **地址无关**阻塞;
- **(D)** dcache 每次 store **全失效**(核弹式,代替 store→load 前递)。
LSQ 目标 = 同时替换 A/B/C/D。

## 1. 现状精确画像(file:line)
- 数据通路:`OooIntBackend`(mem_req `:1243-1262`,mem_rsp `:49-59`)→ `OooMemoryRequestGate`(纯组合 2:1 mux,FP/core 二选一,`:54-68`)→ `OooMemAxiBridge`(`NpcCoreTop.v:199`)→ lsu_axi_* → `AxiLiteXbar`。
- **桥级单 outstanding**:`req_slot_ready_w = !cpu_kill && (S_IDLE || (S_RESP && rsp_ready))`(`OooMemAxiBridge.v:258-260`)——非 IDLE/RESP 不收新请求;单 `state_q`/`write_q`/`paging_q`。唯一重叠 = B1 cacheable-store 写回解耦(`bpend_q`,`:80,315-322,442-443,677-688`)。
- **后端级**:`mem_pending_q`(`OooIntBackend.v:699`)、`mem_request_slot_open_w=!mem_pending_q||mem_rsp_final_fire`(`:805`)、单 `mem_buffer_q`(`:717-726`,1 深发射前置队列,不在总线重叠)。双发第二访存口 mem1 已删(本会话)。
- **store 顺序**:store/AMO 只有 `rob_idx==rob_head`(队头)才 mem-order-ready(`:841-850`);load 对任意更老在飞 store **地址无关**阻塞(`issue*_load_waits_for_inflight_store_w :829-840`)。store→load 可见性靠 dcache 每 store `store_invalidate_all_i(1'b1)` 全失效(`OooMemAxiBridge.v:402` + `OooDataWordCache.v:100-116`)。
- **LR/SC**:单地址 reservation(`OooIntBackend.v:679-697,1352-1409`);失败 SC 活锁刚修(`issue*_sc_premature_w`,本会话)。
- **lane1 mem barrier 死路**:ROB-walk 下 `pending_mem` 对纯 load/store 近死路(`OooPendingLane1CaptureGate.v:50` + `OooFrontendDispatchGate.v:81-89` 证据),即访存已"半 OoO"。
- 容量:ROB16/IQ8/PRF64/FIFO4(`define.v:21-43`);**无独立 LQ/SQ**。
- 总线:`AxiDpiSlave.sv:62-63`(每 master 单笔 `arready=!rvalid`)、`AxiLiteXbar.v`(single-beat,无 AXI ID)。

## 2. 目标结构
- **SQ 深度 8 / LQ 深度 8**(起步可 SQ4/LQ4);entry 在 **dispatch 时按程序序分配**(与 ROB 同拍拿 lq_idx/sq_idx,环形指针天然编码年龄,替代 `rob_idx_older_than`)。
- **SQ**:dispatch alloc → AGU(现 `LSU` `mem_addr_o`,`:653-677`)写 addr → data 就绪写 data/strb → **ROB 队头退休才发 AXI 写(落存)**,B 回释放。
- **LQ**:dispatch alloc → AGU 写 addr → load 可**投机发射**(不必等所有更老 store)→ 数据回写 ROB done → commit 释放。
- **store→load 前递(取代 dcache 全失效)**:load 对所有更老 SQ entry 做 CAM:line 地址 `[63:3]` 匹配 + 字节掩码 `load.strb & sq.strb`:全覆盖→前递该 store data(不访存);部分覆盖→stall 到该 store 退休(一期保守);无重叠→忽略。多命中取最年轻的更老(优先编码)。前递路径替换 `store_invalidate_all_i(1'b1)`,dcache 恢复按地址失效/更新。
- **歧义(未知地址)**:一期保守(有更老 store 地址未知则 load 等);二期投机越过未知地址 store + order-violation replay。
- **load replay**:触发=更老 store 后算地址命中已投机 load;恢复=一期 squash-from-load(复用 flush/redirect),二期精确 replay(保留 ROB entry 清 done 重发)。
- **MSHR 多 outstanding**:档1(不改 sim slave)桥内拆 AR/R 双轨 + 2~4 MSHR(桥内 PTW/读/写解耦);档2(改 `AxiDpiSlave.sv`/`AxiLiteXbar` 加 AXI ID + pipelined AR)真多 outstanding。响应改带 tag(lq_idx)路由。
- **store 退休落存 = B1 推广**:`bpend_q` 升级为多-B 计数跟踪器(解 known-issues 隐患A);MMIO store 仍等 B(E1 边界)。

## 3. 分阶段路线(每阶段 build+difftest+177/177 全绿才进)
- **Phase 0**:补 `tb_ooo_mem_axi_bridge` 的 2-outstanding/flush-drain/B 归因/tag 路由 RED 用例(0 功能改动,降风险)。
- **Phase 1(最小可用)✅ 完成(2026-07-02, SQ 切换步+store→load 前递全绿, 见 §3.6/§3.7)**:新增 `vsrc/memory/OooStoreQueue.v`(SQ4)。load-wait(`:829-840`)从地址无关改为"查 SQ:全覆盖前递/部分重叠或地址未知才 stall";store 从队头发射(`:841-850`)改为进 SQ、退休落存;去 dcache 全失效(`OooMemAxiBridge.v:402`)。仍单 outstanding load。验证:`ooo-mem-order`/rv64ui ld/st/ma_data/rv64ua/difftest。
- **Phase 2**:新增 `OooLoadQueue.v`(LQ4)。load 只要更老 store 地址已知且不重叠即可发(不等落存)。尚不投机越未知地址 store。
- **Phase 3**:MSHR + 桥双轨 + 升级 sim slave/xbar(pipelined AR + ID)+ 响应 tag 路由(取代单 `mem_rob_idx_q :700`)+ 多-B 跟踪器。真多 outstanding(mem-bound CPI 真杠杆)。
- **Phase 4(依赖 F2)**:load 投机越过预测分支 + order-violation replay;删 `OooPendingMemorySequencer` + `OooMemoryRequestGate` pending-mem 分支 + `mem_buffer_q`(§8.3 B-LSQ 标完成)。

## 3.4 接线进度(2026-07-02)
- **影子层已落地**: OooStoreQueue 以影子模式挂进 OooIntBackend 真实 store 生命周期
  (dispatch 双发 alloc / 发射拍 rob_idx CAM 单拍回填 / commit0/1 退休标记 /
  flush_i 全清 + mispredict boundary 清 / drain 即时释放), 行为零变化,
  [SQSHADOW-FAIL] 断言对拍记账一致性(riscv-tests + module TB 全程静默)。
  §3.5 硬点2 已按首选方案(rob_idx CAM, uop 不带 sq_idx)实装并验证; 双发/双退休
  同拍口、branch-kill 只清投机段(boundary flush)等真时序坑均已在影子层暴露并解决。
  切换步(store 发射决策改"进 SQ、退休 drain 落存"+ 前递)只需替换 mux + 解决硬点1。
- **切换步已落地(§3.6 方案, OOO_SQ_STORE_PATH=1 上线)**: plain store 全生命周期
  切换为 probe(issue 拍翻译+PMP 精确异常)→ SQ(PA)→ 退休 → drain 落存
  (pretrans+nokill)。验证: lint 0 / module TB 99/99(tb_ooo_mem_axi_bridge 补
  probe 短路+nokill 写必达两用例)/ riscv-tests 177/177(含 rv64si-p-dirty store
  page fault 精确性、mi misaligned store、rv64ua 全 AMO/LR-SC)/ AM cpu-tests
  全绿 / spike difftest 逐指令 507(与基线一致)/ CoreMark 10 iter GOOD TRAP
  CPI 1.227(与切换前 domain-A 基线持平; 收益待 F2 叠加变现)。
  **实测修掉的三个"队头=序安全"不变量腐蚀坑**(SQ 使 store 退休≠落存, 旧不变量
  全面失效, 同族问题后续 LSQ 阶段仍需警惕):
  1. mem_order_ready 的 ROB 队头豁免支放行了与 SQ committed entry 重叠的 load
     (store commit 拍 load 升队头 → 读旧值); 修=队头豁免对 load AND !sq_block。
  2. load 等待判定整体被 rob_head_valid gate——dispatch-bypass 发射的 load 在
     发射拍自身 ROB 记账不可见(hv=0), 判定被短路; 修=sq_block 移出 hv gate
     (committed entry 拦截不依赖 head 有效性)。
  3. AMO 的 SQ 静默 gate 只加在 can_fire、不在请求 mux valid——AMO 占 mux 饿死
     更低优先级 drain, drain 不排空 AMO 永等(amoadd_d 死锁); 修=mux valid 同步
     gate。教训: 发射条件与 mux 占用条件必须同步收紧, 否则"永不 fire 的 valid"
     饿死低优先级源。
- **剩余(后续切片)**: Sv39 下 load-vs-SQ 精确判定(现 blind, 需 load probe 拿
  PA)、Phase 3 MSHR 多 outstanding、known-limitation=未映射地址 store 的精确
  access fault 降级为 [SQ-DRAIN-ERROR] 退休后警告(PMA 前置留后续)。

## 3.7 store→load 前递方案(2026-07-02 切换步续篇)

**字节语义前提(读码定案)**: LSU 的 wstrb=从 bit0 起连续 size 个 1(与地址无关)、
wdata 不 shift、内存(AxiDpiSlave→npc_paddr_write)按"addr 起顺序字节"写——即
SQ entry 语义=覆盖字节区间 [addr, addr+size)、数据低位对齐。故前递判定用**区间
包含**(非 8B lane 掩码比对), 天然支持 misaligned(区间连续, 无对齐限制); 数据=
entry.data 右移 (laddr-eaddr) 字节后经 LSUDataPath 抽取(size/unsigned 扩展)。

**判定**(issue 拍组合, issue0/issue1 各自独立 always 块防 UNOPTFLAT 假环):
按 head→tail 程序序遍历 SQ, 取"更老(committed 恒老/否则 rob_idx age)且区间重叠"
的最年轻 entry Y: Y 全覆盖 load(eaddr<=laddr && laddr+lsize<=eaddr+esize) 且
Y∈PMEM → 前递 Y 数据; 否则回落现有 sq_block 等待。**禁前递**(回落等待):
Sv39 翻译开启(VA 别名)/load 或 entry 为 MMIO(设备读语义)/存在更老 addr_valid=0
entry(probe 未完成, 防御)。lsize/esize 由 strb popcount(连续 1)。

**数据通路**: 前递 load 不发桥请求(request/buffer fire 与 mux valid 均 gate
!sq_fwd), 复用 ex0/ex1 单拍完成通道(fire 拍锁存抽取结果进 ex*_result_q,
下拍 wb+唤醒), 无新 wb 源。SQ snoop 面补 data/strb/head 平铺导出。

**落地(2026-07-02, 同日续切片)**: 已实装并全绿。lint 0(fwd 块局部变量块首
全初始化防 latch 推断)/ module TB 99/99(SQ 单测补三新端口)/ 冒烟 11/11 /
spike difftest add 507(=基线)+sd 663+st_ld 762 逐指令全对 / CoreMark 10 iter
GOOD TRAP **CPI 1.227→1.208**(-1.5%, store-load 紧邻不再等 drain; CoreMark
该场景占比低, 收益主场在栈/结构体密集代码)。

## 3.5 SQ 接线步的两个硬结构点(2026-07-02 推演补充, 接线会话先解决再动手)

1. **store 精确异常必须前置到 issue**: SQ 语义下 store 在 ROB done/退休后才经 drain 落存,
   但 Sv39 page fault/PMP access fault 的检查现在全在桥的请求路径(退休后才发现 fault =
   无法精确异常, rv64si-p-dirty/ACT4 PMP store 用例会破)。接线前必须把 store 的翻译+PMP
   检查提前到 issue 拍(复用/前置桥的 DTLB+PmpChecker 逻辑, 或 issue 时经桥做"探测请求"),
   fault 随 uop 进 ROB exception 字段, 只有无 fault 的 store 才进 SQ committed 流。
2. **SQ 字段回填的 idx 传递**: uop 不带 sq_idx(IQ payload 不扩)时, addr/data 回填改用
   rob_idx CAM 匹配 SQ entry(4 项 CAM 可综合); 或 IQ payload 扩 sq_idx(threading)。
   前者改 SQ 接口(addr/data write 带 rob_idx), 后者改 OooIntIssueQueue——推荐前者。
   另: ROB 双 commit 拍两个 store 时 SQ 单 commit 口标不全——ROB 侧需约束 commit1
   为 store 且 commit0 也 store 时 block(或 SQ 加第二 commit 口)。

## 3.6 SQ 切换步方案定案(2026-07-02, 接线会话)

**硬点1 定案 = probe(翻译探测)复用现请求通道**: 桥的翻译(DTLB 组合查询/PTW FSM)+PMP 检查
本就在请求路径前端完成(`accept_request` 组合判定 + `S_WALK_*`), store 精确异常前置不需要复制
TLB/PMP——给 mem0 请求口加 `probe` 位: write+probe 走完翻译+PMP 后**不进 S_WRITE_REQ**, 短路
S_RESP 把 **PA 经 rsp_rdata 回传**(fault 路径完全复用现 error/page_fault, 后端 cause 生成
`mem_rsp_wb_cause_w` 已按 mem_store_q 区分 STORE_*, 零改动)。两个短路点: `accept_request` 的
`req_write_w` 分支(TLB hit/无翻译)与 `S_WALK_R` leaf-OK 的 `write_q` 分支(PTW 完成)。

**store 新生命周期**(`OOO_SQ_STORE_PATH` 开关 gate, 默认 1):
```
dispatch(SQ alloc, 程序序, 满则反压 dispatch_ready)
  → issue(不再等 ROB 队头; IQ 内 older_store_seen 约束保留)
  → probe 请求(占 mem_pending, mem_probe_q=1; wdata/wstrb 寄存 mem_store_{wdata,wstrb}_q)
  → probe rsp: fault → wb exception(cause=STORE_*, 精确) | OK → wb done + SQ fill(PA+data+strb)
  → ROB 退休(SQ mark committed; exception commit 不 mark!)
  → SQ 队头 drain: pretrans+nokill 写请求(优先级最低: amo_write>buffer>issue>drain)
  → drain rsp(不占 wb 槽) → SQ 释放
```
- **MMIO store 也进 SQ**(不做等队头旁路): PMP fault 已在 probe 精确; 退休后 drain 写等 B
  (非 PMEM 不解耦), B error 理论仅剩"未映射地址/SLVERR"→ 打 `[SQ-DRAIN-ERROR]` 警告计数,
  **known-limitation: 未映射地址 store 的精确 access fault 降级为退休后警告**(现实测试集不触及;
  PMA 前置留后续)。设备写序: SQ 程序序 drain + load 对 MMIO entry blind 等待。
- **AMO/LR/SC 不变**(队头+真事务), 发射加 `sq_no_committed && !drain_inflight`(更老 store 已落存)。
- **probe 无副作用**可投机: wrong-path probe 的 TLB 填充无害, fault 随 squash 消失;
  probe fire 清 reservation(与现 store fire 清等价保守)。

**load 等待判定三层**: IQ 内 older_store_seen(未发射, 保留) + pending/buffer VA 重叠(probe 中,
保留) + **SQ snoop(新)**: 对 addr_valid entry, `translate_active`(Sv39 开) 或 MMIO entry → blind
等待; 否则 line_overlap_1(PA vs load VA, M-mode VA=PA 精确)。age: committed entry 恒视为更老
(rob_idx 已回收不可比), 未 committed 用 rob_idx_older_than。**Sv39 blind 的理由 = VA 别名**
(不同 VA 同 PA 时 VA 比对漏判); 前递与 Sv39 精确判留 Phase2 后半(load 也 probe 拿 PA)。

**不变量守护**:
- 翻译上下文时效: satp 写/sfence/trap/xret 均走域 B drain, `mem_idle_o += sq_empty && !drain_inflight
  && !mmio_残留`——SQ 非空即不 drained, 上下文改变点前 SQ 必排空(probe 的 PA 永不过期)。
- drain 写不可丢: 桥 `nokill` 位使 flush/drop 对该事务失效(已退休 store 写必达); drain_inflight_q
  不随 flush 清除。
- fault store 不落存: mark 口 gate `!commit*_exception`(exception commit 的 store 不标 committed,
  随 trap flush_all 清除)。
- rsp 归属: 单 outstanding 下 drain_inflight 与 mem_pending 互斥(桥 slot 语义天然保证 + drain 挂
  请求 mux 最低优先级); drain rsp 拍 `mem_rsp_ready` 恒 1(不占 wb)。

**plumb**: 桥 3 新输入(probe/pretrans/nokill)+1 新输出(translate_active), RequestGate 透传(FP 侧
恒 0), glue→ExecuteBackend→AluCoreSlice→AluDecodeBackend→IntBackend 四层机械穿线。

## 4. 依赖
- Phase 1-3 **不依赖 F2**(store→load 前递/SQ 落存/歧义/独立 load 多 outstanding 都在"不会被 squash 的窗口"内成立)。**Phase 4(投机越分支 load)才强依赖 F2** 的多级分支投机——今天每分支强制 redirect,ROB 里不积累跨分支投机 load,LSQ 投机无处可投。

## 5. 风险与陷阱
- SQ 前递 CAM 可综合性(N≤8 标准比较器阵列+优先编码,用 `always @(*)`+for 展开,禁 `always_comb` const-select,遵 MEMORY.md)。
- 前递路径深组合链可能成新 Fmax 封顶(一期做成发射后一拍的时序级;line 地址与字节掩码分级)。
- 与单 outstanding FSM 共存:Phase 1-2 桥接口不动,只改后端发射决策+dcache 失效策略,把桥重写隔离到 Phase 3(每阶段可 revert)。
- Phase 3 response ownership/组合环(ready/valid 不成回边)、flush drain per-MSHR-entry drop、known-issues 隐患A(多 outstanding 写前桥内自保 B 计数)。

## 关键文件索引
桥:`OooMemAxiBridge.v`(封顶 `:258-260`、FSM `:489-718`、B1 `:80,315-322,442-443`、dcache 全失效 `:402`)。后端:`OooIntBackend.v`(mem_pending `:699`、buffer `:717-726`、slot-open `:805`、store 队头 `:841-850`、load 阻塞 `:829-840`、reservation `:679-697,1352-1409`、请求 `:1210-1262`、响应 `:1565-1641`)。残留脚手架:`OooMemoryRequestGate.v`/`OooPendingMemorySequencer.v`。dcache:`OooDataWordCache.v:100-116`。总线:`AxiDpiSlave.sv:62-63`/`AxiLiteXbar.v`。规范:`design/arch/mem-lsq.md`、`mem-store-decouple.md`、`design/specs/ooo-mem-axi-bridge-fsm.md`、宪法 §5/§8.3-8.4。

## 4. Phase 2+3 定稿方案(2026-07-03, "访存并行度"模块整体一刀)

### 4.1 核心洞察(改变原计划形态)
- **桥的 back-to-back 已在**: `req_slot_ready = S_IDLE || (S_RESP && rsp_ready)`
  ——dcache-hit 流桥吞吐已是 1 req/拍。**真封顶是后端单 `mem_pending_q`**
  (发→等 rsp→再发, 每 load 串行 2-3 拍)。
- **响应恒按请求序**(单桥 FSM; 后续 slave/xbar 流水化亦保持 in-order)——
  **无需 AXI ID/乱序 tag 路由**: in-flight 用顺序 FIFO, rsp 恒配 FIFO 头。
  这同时结构性消灭"迟到 rsp 撞号"族(F2/FP 轮的教训: 单例寄存器+rob 匹配
  才会撞, FIFO 序配对天然免疫)。

### 4.2 第一刀: 后端 mem 通道 FIFO 化(桥/总线零接口改动)
- 新 `OooMemInflightQueue`(深 4, 顺序 FIFO), entry = 现 mem_*_q 单例状态的
  数组化: {kind(load/store/amo/probe/drain), rob_idx, pdest, pdest_fp, load,
  store, amo 族(lr/sc/write_phase/inst/src2/old/wdata/wstrb), eff_addr, size,
  unsigned, probe, killed}。
- **发射规则**(替换 mem_request_slot_open 单笔判):
  - plain load / probe-store / drain: FIFO 有空 + 桥 req_ready 即发(背靠背);
  - AMO/LR/SC: 保守串行——FIFO 空才发, 且其在飞期间不发新(与现语义等价);
  - mem_buffer_q(1 深发射前置暂存)保留, 其迁移目标改为 FIFO。
- **rsp 消费** = FIFO 头: load→wb/fpld_wb(按 pdest_fp), probe→SQ fill,
  amo_read→amo 状态机, drain→SQ pop。与现单例逻辑同形, 状态源换 FIFO 头。
- **kill(ROB-walk)**: kill 拍对 FIFO 存量按 rob age 标 killed; killed entry
  的 rsp 到达即静默弃(不 wb 不唤醒; dcache fill 无害——数据是真实内存值)。
  drain(nokill)不可 kill。flush: 非 drain entry 全清(桥侧 cpu_kill 配套)。
- LQ/SQ 歧义判定不变(Phase1 的 SQ CAM 已给出 load 越过"地址已知不重叠
  store"的能力, 原 Phase2 的 LQ 独立文件并入本 FIFO——一物两用)。

### 4.3 第二刀: miss 并发(桥读通道 MSHR + slave/xbar 流水)
- 桥: S_READ_ADDR/S_READ_DATA 从 FSM 独立成读通道小队列(2 MSHR):
  AR 可在前一 R 未回时发出(paddr/wstrb 数组化); PTW(S_WALK_*)与写通道
  仍独占(保守窗口)。rsp 仍按序。
- AxiDpiSlave: arready 流水化(2-4 深响应队列, 按序回)。
- AxiLiteXbar: rd_master_busy 从单笔锁改 in-flight 计数(同 master 按序,
  跨 master 仲裁保持)。
- 验证顺序: 第一刀全绿(全套回归+difftest)后才叠第二刀。

### 4.4 验证与退出
- 每刀: lint/build + riscv 全集 difftest(153) + uf/ud 23 + module TB +
  AM cpu-tests + CoreMark 10 iter(观察 mem/axi_wait 桶与 CoreMark/MHz)。
- 隐患对照: known-issues 隐患A(多-B 计数)在第二刀写通道不动故不触发;
  SQ"队头=序安全"不变量(memory: lsq-sq-switch-landed)——FIFO 化不改变
  store 生命周期, drain 仍单笔。

## 5. Phase 2+3 落地实录(2026-07-03)

### 5.1 第一刀·MIQ(OooMemInflightQueue, 已落地)
- 新模块 4 深顺序 FIFO; kind=LOAD/PROBE/DRAIN/LEGACY; rsp 恒配队头(响应
  按请求序, 无需 AXI ID——顺带结构性消灭"迟到 rsp 撞号"族)。
- IntBackend: mem_pending_q 收窄为 LEGACY(AMO/LR/SC/MMIO-load 独占族)专用;
  plain LOAD/PROBE/DRAIN 走 MIQ 背靠背; 消费(wb/fpld/SQ fill/drain)全部
  换 MIQ head 字段单源; ROB-walk kill 对 MIQ 存量按 age 标 killed(rsp 到弃);
  flush 压缩保留 DRAIN(nokill 写必达)。
- 落地踩坑二则: ①PROBE 成功也必须 wb 一次(标 ROB done)——只 fault 才 wb
  会让 plain store 永不 commit, SQ 满死锁; ②PROBE 在飞=store 地址未知窗口,
  更老 PROBE 必须拦住更年轻 load(带 line 重叠精判, 翻译开启 blind)——
  旧版该拦截隐含在"probe 占 mem_pending"里, 拆出后必须显式重建。

### 5.2 真瓶颈改判与 dcache line 化(性能主收益)
- CoreMark 画像: dcache load miss 47.6%(274k/576k), 且容量 8KB→32KB 零变化
  ——miss 全是旧 byte-window 模型的「访问起始地址精确匹配」互踢(同一 8B 的
  不同偏移是不同 entry), 非容量。
- OooDataWordCache 重写为对齐 8B line 语义: index/tag 按 line; 命中给窗口
  视图(line>>off*8); 跨线窗口走"uncached 窗口读不 fill"; store 不跨线
  write-update 精确合并(no-allocate), 跨线双线失效; 桥配套(对齐 AR+strb
  全 1+fill 对齐地址+rsp 窗口视图+read_cross_q 锁存)。
- 效果: **miss 274347→5833(-98%)**, CoreMark **2.612→2.869/MHz(+10%)**。
- 裁决: 原第二刀(桥 MSHR/slave/xbar 流水)在 miss 稀少后 ROI 消失, 降级
  不做(留档); MIQ 保留为 LSQ 正式 in-flight 基建(Phase4 投机 load/replay
  的地基)。TB 对齐三处(dcache 语义断言/桥 AR 断言参数化/场景地址隔离)。
