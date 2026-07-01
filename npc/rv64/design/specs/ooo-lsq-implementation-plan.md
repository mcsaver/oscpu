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
- **Phase 1(最小可用)**:新增 `vsrc/memory/OooStoreQueue.v`(SQ4)。load-wait(`:829-840`)从地址无关改为"查 SQ:全覆盖前递/部分重叠或地址未知才 stall";store 从队头发射(`:841-850`)改为进 SQ、退休落存;去 dcache 全失效(`OooMemAxiBridge.v:402`)。仍单 outstanding load。验证:`ooo-mem-order`/rv64ui ld/st/ma_data/rv64ua/difftest。
- **Phase 2**:新增 `OooLoadQueue.v`(LQ4)。load 只要更老 store 地址已知且不重叠即可发(不等落存)。尚不投机越未知地址 store。
- **Phase 3**:MSHR + 桥双轨 + 升级 sim slave/xbar(pipelined AR + ID)+ 响应 tag 路由(取代单 `mem_rob_idx_q :700`)+ 多-B 跟踪器。真多 outstanding(mem-bound CPI 真杠杆)。
- **Phase 4(依赖 F2)**:load 投机越过预测分支 + order-violation replay;删 `OooPendingMemorySequencer` + `OooMemoryRequestGate` pending-mem 分支 + `mem_buffer_q`(§8.3 B-LSQ 标完成)。

## 4. 依赖
- Phase 1-3 **不依赖 F2**(store→load 前递/SQ 落存/歧义/独立 load 多 outstanding 都在"不会被 squash 的窗口"内成立)。**Phase 4(投机越分支 load)才强依赖 F2** 的多级分支投机——今天每分支强制 redirect,ROB 里不积累跨分支投机 load,LSQ 投机无处可投。

## 5. 风险与陷阱
- SQ 前递 CAM 可综合性(N≤8 标准比较器阵列+优先编码,用 `always @(*)`+for 展开,禁 `always_comb` const-select,遵 MEMORY.md)。
- 前递路径深组合链可能成新 Fmax 封顶(一期做成发射后一拍的时序级;line 地址与字节掩码分级)。
- 与单 outstanding FSM 共存:Phase 1-2 桥接口不动,只改后端发射决策+dcache 失效策略,把桥重写隔离到 Phase 3(每阶段可 revert)。
- Phase 3 response ownership/组合环(ready/valid 不成回边)、flush drain per-MSHR-entry drop、known-issues 隐患A(多 outstanding 写前桥内自保 B 计数)。

## 关键文件索引
桥:`OooMemAxiBridge.v`(封顶 `:258-260`、FSM `:489-718`、B1 `:80,315-322,442-443`、dcache 全失效 `:402`)。后端:`OooIntBackend.v`(mem_pending `:699`、buffer `:717-726`、slot-open `:805`、store 队头 `:841-850`、load 阻塞 `:829-840`、reservation `:679-697,1352-1409`、请求 `:1210-1262`、响应 `:1565-1641`)。残留脚手架:`OooMemoryRequestGate.v`/`OooPendingMemorySequencer.v`。dcache:`OooDataWordCache.v:100-116`。总线:`AxiDpiSlave.sv:62-63`/`AxiLiteXbar.v`。规范:`design/arch/mem-lsq.md`、`mem-store-decouple.md`、`design/specs/ooo-mem-axi-bridge-fsm.md`、宪法 §5/§8.3-8.4。
