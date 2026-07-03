# B-FP 实施方案(FP 从域B pending 旁路迁成正式乱序执行簇)

> **2026-07-02 方案升级为整体一次成型**(用户要求模块级整体实现, 不分 Phase 切片):
> rename+IQ+执行簇+ROB commit+拆 pending 全家一步到位, 详见 §7 整体实现定稿。
> 原分 Phase 计划(§3)保留作参考; §3.6 的地基(ROB is_fp_rd/fflags)已落, 整体实现直接用。

## 7. 整体实现定稿(2026-07-02, 全部盲点读码后)

**恢复模式(读码定案, FP 照抄整数)**: 本核整数 rename 的恢复=「RenameMap flush 重置
恒等映射(map[i]=i) + OooPhysRegFile.recover_i 单拍 bulk 拷入全 32 架构 GPR(低 32
preg=committed 承载区, 高 32 清 0) + FreeList/BusyTable 重置(free 集=[32,64))」;
mispredict 走 ROB-walk(walk emit old/new_pdest 还原 map/回收 preg)。FP 完全同构:
FP map 恒等 + FpPhysRegFile.recover 拷架构 FPR + FP walk 分流(ROB entry 的
is_fp_rd 已在, walk 输出加 is_fp 位)。

**新组件**: ① `OooFpPhysRegFile`(64 项 4R2W, 拷 OooPhysRegFile **去 x0 特判**——
f0 是真寄存器可读写可分配); ② FP RenameMap/FreeList/BusyTable=第二套参数化实例
(FreeList 初始 free=[32,64) 同构, f0 恒等 preg0 同为 committed 承载; alloc 的
x0-skip 本就在消费者侧, FP 侧不 skip); ③ `OooFpIssueQueue`(8 项单发 oldest-ready,
3 FP 源+1 GPR 源 ready, 无 int IQ 的 bypass/mem-order 脚手架); ④ OooFpArithGate
自流水化(数据通路已分级 FADD3/FMUL3/FMA5, 控制从"start 保持+单计数"改每级
valid_q+payload(rob_idx/pdest/fflags/double)随走, 背靠背吞吐)。

**uop 分域**: 纯 FP 算术/FMV·FCVT 跨域(GPR 源或 GPR 目的)→ **FP IQ**(加 1 GPR
读口+监听 int wakeup; GPR 目的结果走 int wb 口写 int PRF+唤醒); FP load/store →
**整数 IQ mem 通道**(保持 LSQ 语义: FP store 进 SQ/FP load 走 mem probe 通道;
load 目的挂 FP: mem pdest 加 is_fp 位, rsp 写 FP PRF+FP busy 唤醒+NaN-box(FLW);
store 数据 fs2 发射拍读 FP PRF, int IQ entry 加 fp_src ready 位监听 FP wakeup)。
rename: FPR 目的经 FP rename(f0 也 alloc), GPR 目的经整数 rename; ROB old/new_pdest
字段按 is_fp_rd 复用为 FP preg。

**commit**: is_fp_rd → 写架构 OooFpRegFile(角色=committed FPR)+释放 FP old_pdest
+fflags OR 入 FCSR(双 commit 两 FP 先 OR); GPR 目的走整数标准路径。

**拆除**: StopPending/DispatchArbiter/DrainResolveGate 的 FP 臂、
PendingFpSequencer、FpPendingExec 的 pending 壳(7 gate 本体保留由 FP IQ 驱动)、
FpCommitGate 整删(E2/E3 消灭)、ControlCommitSequencer.drain_fp_commit、
OperandReadGate FP 读口、RequestGate pending-FP mem 抢占口。

**known-limitation 继承**: FP load/store 的桥侧 fault 现状即被忽略(无精确路径),
本次进 mem 通道后自然获得与整数同款的精确 fault(probe/rsp exception)——顺带修复。
DiffContext 无 FPR(#107)不变。

> 状态:spec(2026-07-01,基于全核只读审计)。对应宪法 §4.2、§7.1(E2/E3 例外)、§8.3(OooPendingFpSequencer ELIMINATE)、§8.4(新 B-FP)。
> 目的:FP 走正式 rename(FPR 物理堆 + rename map/free list)+ FP IQ(乱序 wakeup/select)+ 复用现成 FP 流水 + FP 经 ROB commit 写 FPR/fflags,**消除 C6 的 E2/E3 副作用例外**。

## 1. 现状精确画像(file:line)
- 生命周期:decode `OooFpDecode.v`(15 子类 flag,fp_double 已按 opcode 门控修复)→ facts `OooFetchHeadPairGate.v:273-274`(`FP_ENABLED` 位)→ 域B捕获 `OooPendingDispatchArbiter.v:190-197`(单 entry pending owner + `stop_pending`)→ 串行 `OooPendingFpSequencer.v:96-207`(mem→long→compute)→ drain 屏障 `OooPendingDrainResolveGate.v:63-90`(整后端排空才解析)→ 访存复用**同一单-outstanding 桥** `OooMemoryRequestGate.v:44-68`(pending-FP 抢占 mem0)→ 操作数读 `OooFpRegFile.v:28-30`(架构 FP 号,未重命名,3R)→ 执行 7 gate(`OooFpPendingExec.v` 驱动)→ 提交 `OooFpCommitGate.v`。
- **E2/E3 精确绕过点**(消除目标):
  - E2 · FPR 写:`OooFpCommitGate.v:63-65`(load 写)/`:67-74`(结果写)→ `OooFpRegFile.v:38-42` 直写,**不经 ROB commit 口**。
  - E3 · fflags 累积:`OooFpCommitGate.v:56-58` → CSR OR 入 FCSR。
  - **注意**:FP→**GPR**(FMV.X/FCMP/FCLASS/FCVT.to_gpr)结果**不**属 E2——它经 `gpr_commit_o`(`:59-61`)→ `OooControlCommitSequencer` → `OooCommitOutputMux` 写架构 GPR,已是类 commit 语义。B-FP 要消的精确是 **FPR-目的结果写 + fflags** 两支。
- **FP 不占 ROB entry**(决定性):`OooFrontendBackendDispatchMux.v:84-92` 的 `core_dispatch0_valid_o` 取值项无 FP;FP head0 命中即转 pending owner + `stop_pending`,从不分配 ROB、结果从不经 ROB commit 口。ROB entry 无 FP-目的/fflags 字段(`OooRob.v:39-79`)。

## 2. 目标结构
- **独立 FP rename**(不与整数统一):FP 与 GPR 是两套架构空间(f0 非零)。
  - **物理 FPR 堆** `OooFpPhysRegFile`(仿 `OooPhysRegFile.v`,64 项,起步 1-wide 3R2W + 写-读旁路)。
  - **独立 FP rename map/free list/busy table**:参数化复用 `OooRenameMap/OooFreeList/OooBusyTable`(均已按 PHY_REG_COUNT 参数化);FP free list 无需排除 f0。checkpoint 端口已在,复用分支投机恢复。
  - **架构 FPR(RRAT)**:committed FP map;物理 FPR 永不回滚(投机靠 map 回滚)——**修掉 `OooFpRegFile.v:33-35` 的"flush 清全堆"隐患**(现 `flush_i` 恒接 `1'b0`,靠 drain;迁出 drain 后必须换 map-checkpoint 恢复)。
- **FP IQ**(仿 `OooIntIssueQueue`,起步 8 项 oldest-ready);**唤醒源三类**:FP 结果→FP、FP load→FP、整数结果→FP(int→fpr 的 mv/cvt);反向 FP→整数(mv/cvt 写 GPR)需 FP 结果广播给整数 busy table → **Int/FP IQ wakeup 交叉互听**。
- **复用 7 gate 的接口改造**:
  - `OooFpArithGate`(FADD/FMUL/FMA):**最大陷阱**——现 `done_o=start_i&&(latency_cnt==5)` 且 `!start_i` 归零(`:1372-1375`),**一次只能算一个 op、无法背靠背**。给 OoO IQ 复用会把吞吐锁到 1/5;Phase 2 须重构为**自流水 valid**(每级 `valid_q` + payload rob_idx/pdest/fflags/frm 随级打拍,start 单拍 launch,组合 datapath 保留)。
  - `OooFpLongOpGate`(div/sqrt 迭代器):已是 start-pulse+busy/done,**基本可直用**,IQ 加"迭代器忙则不 issue"背压。
  - Convert/Compare/Classify/Sgnj/MemAccess:纯组合,包一层 issue 级寄存(1 拍固定延迟)即可直接复用。
  - op-select(`OooFpPendingExec.v:128-194` 的 funct7 分类)平移到 rename 期算成 uop 字段(fp_op enum + double + rm 快照),免执行级重复译码。
- **FP 结果进 ROB + commit 写 FPR/fflags**:ROB 每 entry 加 `is_fp_rd` + `fflags[4:0]`;wb lane 加 `wb_fflags`;commit lane 加 `commit_is_fp_rd` + `commit_fflags`。commit 时 `is_fp_rd`→写架构 FPR、`fflags`→OR 入 FCSR。**E2/E3 消除**,`OooFpCommitGate.v` 整删。NaN-boxing/舍入照旧在执行 gate(fp_double/frm 随 uop);fflags 顺序化累积在 commit 口天然满足(2-wide commit 同拍两条 FP 需先 OR 再入 FCSR 单写口)。

## 3. 分阶段路线(每阶段 build+rv64uf/ud difftest 全绿)
- **Phase 0(最小可用:消 E2/E3,仍串行)**:让 FP 也分配 ROB entry(`OooFrontendBackendDispatchMux.v:84` 加 FP dispatch 项;ROB 加 `is_fp_rd`+`fflags`);执行仍在现 pending gate,但结果打成 result_event(带 fflags)→ ROB done → commit 口写 FPR/fflags;删 `OooFpCommitGate` 的 fpr_*_write/fp_fflags。**收益:C6 的 E2/E3 例外即刻消失**。风险:FP load 的 page-fault 进 ROB exception 序。验证:rv64uf/ud difftest bit-exact + fflags 对照 NEMU FCSR。
- **Phase 1(加 FP rename,单发顺序 issue)**:新增 `OooFpPhysRegFile` + 复用参数化 rename map/free list/busy(FP 专属)。FP 读物理 FPR、pdest 经 FP free list、RRAT commit 更新;FP 不再靠 drain 保护(靠 map)。风险:cross-domain mv/cvt 两侧 rename/busy 联动、分支投机 FP map checkpoint。
- **Phase 2(加 FP IQ,乱序,拆 pending)**:建 `OooFpIssueQueue`;arith gate 改自流水 valid、div/sqrt 加背压;删 `OooPendingFpSequencer`+`OooFpPendingExec` pending 语义,从 `OooPendingDispatchArbiter`/`OooPendingDrainResolveGate`/`OooStopPendingSequencer` 摘除 pending_fp_*(§8.3 ELIMINATE 完成)。风险:FP 越分支投机(依赖 F2)、arith 吞吐。

## 3.5 Phase 0 接线的硬结构点(2026-07-02 推演补充)

**rename 污染 gate**: Phase 0 让 FP 也分配 ROB entry 需要 FP 拍 core_dispatch0_valid=1,
但它会流经 OooDispatchBackend 的完整 rename——FP 的 rd 是 FPR 空间, 整数 rename 会为它
分配 GPR preg/写 RAT/占 free list = **整数架构态污染**。接线时必须对 is_fp uop 做 rename
bypass(rd_en=0/不 alloc preg/不写 map), ROB entry 以 is_fp_rd 标记, commit 时写 FPR 而非
GPR。双 commit 拍两条 FP 的 fflags 需先 OR 再入 FCSR 单写口(§5.3)。

## 3.6 Phase 0 接线方案定案 + 地基进度(2026-07-02)

**结构方案 = 照抄 pending-system 的"drain → dispatch 进 ROB → 执行 → 真 commit"模式**
(读码确认 system CSR 已是此模式先例: capture→stop_pending→drain→
`system_csr_dispatch_valid`→DispatchMux→ROB→执行→commit, 无死锁——**drain 在
dispatch 之前完成**, FP 占 ROB 不会阻塞自己的 drain 前提)。spec §3.5 之外的
第二个硬点(本轮推演发现): 若 FP 先 dispatch 再等 backend_drained 会死锁
(drained=ROB 空而 FP 自己在 ROB), system 模式天然规避。

**目标生命周期**: capture(payload 进 PendingFpSequencer, 照旧)→ drain →
`fp_dispatch_valid`(仿 system_csr_dispatch_valid: stop && pending_fp &&
!fp_dispatched && drained_q)→ DispatchMux 新 valid/pc/inst 项 → dispatch 进
ROB(序列器存 dispatch0_rob_idx, 置 dispatched; StopPendingSequencer 加 fp
dispatch fire hold 臂)→ pending 执行照旧(mem/long/compute, 推进条件从 drained
改 dispatched)→ 完成打 **fp_wb 事务**(rob_idx/pdest/data/exception/cause/tval/
fflags + ready 反压)进 IntBackend wb 仲裁(第五源, 最低优先)→ ROB done →
commit: is_fp_rd→写架构 FPR + fflags OR 入 FCSR; GPR 目的(FCMP/FCLASS/FMV.X/
FCVT.W)走**正常 rename+PRF+commit 写 GPR**(fp_gpr_write 已有 facts 信号)。

**dispatch 的 rename 分叉**(修正 §3.5 "一律 bypass"的不精确): FPR 目的/无目的
→ rename bypass(rd_en=0 不 alloc preg, ROB entry 以 is_fp_rd+arch_rd(复用为
FPR 号)标记); **GPR 目的 → 正常 rename**(消费者经 PRF 旁路/唤醒, 完全标准)。
FP uop **不进 IQ**(DispatchBackend 对 is_fp gate iq alloc——后端无 FP 单元,
done 由 fp_wb 置)。FP load fault → fp_wb exception(cause=LOAD_*)→ ROB 队头精确
trap(取代现 pending fault 旁路)。E2/E3/gpr_commit/ControlCommitSequencer 的
drain_fp_commit 伪提交全删。

**地基已落(本轮, 行为中性)**: OooRob entry +is_fp_rd+fflags[4:0](不进
checkpoint 影子——该机制已被 ROB-walk 取代)、dispatch 口 +is_fp_rd、wb 口
+fflags(含 commit 同拍 head 前递 mux 对称扩展)、commit 口 +is_fp_rd/+fflags;
OooDispatchBackend 全透传; OooIntBackend 本地接 0/收口(fp_wb 源与上层 plumb
属接线切片)。tb_ooo_rob/tb_ooo_dispatch_backend 对齐(顺带补齐 dispatch TB
自 SQ 切片起悬空的 sq_alloc0/1_ready——iverilog 宽松语义下靠非 store 指令
侥幸绿)。验证: lint 0 / module TB 99/99 / riscv 抽样(ui add·sd + uf/ud
fadd·fmadd·ldst)全绿。

## 4. 依赖
- **计算类 FP 不依赖 F2/LSQ**(宪法 §8.4:B-FP 可与 B-LSQ 并行,FP 独立簇)。**唯一耦合 = FP load/store**:现复用单-outstanding 桥(`OooMemoryRequestGate.v:44-68`);LSQ 建成后 FP load/store 应作为普通 load/store 进 LSQ(destination=FPR);LSQ 就绪前 Phase 0/1 可让 FP 访存仍走共享桥(过渡)。

## 5. 可综合性与陷阱
1. `OooFpArithGate` start-保持+计数器不能重叠(见 §2,Phase 2 自流水化)。
2. 3R2W FPR 对 1-wide 够;2-wide 需 6R4W(面积/时序,建议起步坚持 1-wide FP)。
3. fflags 累积迁 commit 口更干净(顺序性天然),但 2-wide 同拍两 FP 需先 OR 再单写 FCSR。
4. cross-domain wakeup 交叉总线(指令少,逻辑量小)。
5. 物理 FPR 恢复语义:废弃 `OooFpRegFile.v:33-35` 清全堆,改 FP rename map checkpoint(Phase 1 首要验证)。

## 关键文件索引
现状:`OooFpPendingExec.v`/`OooPendingFpSequencer.v`/`OooFpCommitGate.v`(E2/E3)/`OooFpRegFile.v`。捕获:`OooPendingDispatchArbiter.v:190-258`/`OooPendingDrainResolveGate.v:83-113`。转出 ROB 证据:`OooFrontendBackendDispatchMux.v:84-92`。复用件:`OooFpArithGate.v:1359-1375`/`OooFpLongOpGate.v`/`OooFpDivIter.v`/`OooFpSqrtIter.v`/各组合 gate。参数化基础:`OooRenameMap/OooFreeList/OooBusyTable.v`/`OooIntIssueQueue.v`/`OooRob.v`/`OooPhysRegFile.v`。FP 访存交点:`OooMemoryRequestGate.v:44-68`。宪法:§7.1(E2/E3)、§8.3(B-FP)、§8.4。

## 8. §7 整体一次成型落地实录(2026-07-02,uf/ud 23/23 全绿)

### 8.1 落地形态(与 §7 定案的差异点)
- FP 簇一体化于 `OooFpBackend.v`(~900 行):轻量 fp_map + OooFreeList 双口 +
  自建 fp_busy 数组(不占 BusyTable 口、无跨模块组合环)+ OooFpIssueQueue(8 项
  oldest-ready,双 alloc)+ 执行簇(arith 自流水/long 单在飞/组合类 exec1)+
  完成 FIFO(深 8,发射预算 count<=2)→ fpwb 单口回 IntBackend wb 第五源。
- **双 lane 化是被前端逼出来的**:dispatch_fire 双 ready 联锁不理 optional,
  lane1 FP 算术 ready=0 即死锁 → disp0/disp1、fpld0/1、fpst0/1 全双口。
- FP load/store 走整数 IQ mem 通道(mem_pdest_fp 标记随行);FP store 数据在
  发射拍读 FP PRF read3;SQ opcode 判定含 FP store(0100111 且 funct3∈{010,011})。
- CSR 指令与 FP 同窗口在飞成为新常态,pending CSR 注入模型补丁:PSS 在
  drain 完成拍(backend_drained 组合)刷新 csr_rdata 锁存,fire 拍消费寄存值
  (capture 拍锁存在"CSR 与产生 fflags 的 FP 指令同窗"时读到旧 fflags)。

### 8.2 十一个根因修复清单(全部有最小复现与探针证据)
1. **arith 对齐链早一拍**:addsub value_q 于 T+2 末写,捕获须用 meta[3](原 meta[2]
   读到 wrong-path 残值 NaN);输出读 a2(FADD3 与 FMUL3 同构)。
2. **SPS 的 dispatch0_fp 臂抢写 stop_pending=0**:barrier fire 拍 head0=FP 时
   把同拍 lane1 system capture 的 drain→注入链掐死。臂删除(FP=普通指令)。
3. **arbiter 的 dispatch0_fp gate 家族(11 处)**:lane1_barrier_base 的
   `!dispatch0_fp` 在"barrier fire 整包 pop"时挡死 lane1 capture → 与 FP 同包的
   CSR 指令静默丢弃成 NOP。capture 6 处+clear 5 处全删。
4. **ClassifyGate stop_raw 含 fp_raw**:head0=FP 时 head1 不 decode(facts 全 0),
   同包 lane1 CSR 以无害指令身份双发成 NOP。fp_raw 从 stop 类除名(FS=off 走
   arch_trap 仍 stop)。
5. **CSR 注入 rd 值用 capture 拍锁存**:fsflags 读 0(fflags 尚未累积)。改
   drain 完成拍刷新(见 8.1;直连实时 rdata 会成真组合环:commit inst→CSR 读→
   注入 imm→…→commit)。
6. **long op done 单拍脉冲无人接**:被仲裁抢占即丢;kill 后残留 done 错配新
   op(meta 收取臂原是 no-op)。加 hold 寄存(done→hold,收取清 hold+meta,
   新发射作废旧 hold)。
7. **LongOpGate 结果组装读活输入**:div/sqrt 的 value/fflags 块在 done 拍组合读
   frs*/rm/double,多拍迭代期间输入换人 → sqrt(π)=NaN。start 拍锁存
   op_frs1/frs2/rm/double,8 个组装块全改锁存(operand 准备块保持读输入)。
8. **lane0→lane1 同拍前视缺失**:lane1 源/old/store 查询直读 fp_map,同拍
   lane0 写 f0+lane1 读 f0 → 读旧 preg 且误 ready(fclass 读到 fmv 写前的值)。
   加意图版前视(valid 而非 fire,防 ready→fire→前视组合环):preg=alloc0、
   ready=0、old=alloc0(WAW)。
9. **FpIQ dispatch 写与同拍 wakeup 后写胜**:入队 entry 的 ready 写 0 覆盖同拍
   广播 → 错过唯一唤醒永睡(fcvt.d.w 的 GPR 源撞 li 的 wb 拍死锁)。八处 ready
   写全加同拍 wakeup 前视 mux。
10. **done FIFO 存量不 kill**:被 kill 的 FP 完成事务滞留 FIFO,pop 后把重放同号
    新 ROB entry 标 done(撞号假 commit)。FIFO 项加 killed 位:kill 拍 age squash
    +push 拍同拍判定,killed 项 pop 拍静默自弹。
11. **FP load 两处通路丢 FP 目的语义**:
    a) issue1 进 mem_buffer 装载块漏 `mem_buffer_pdest_fp_q`(fld 迁 pending 后
       按普通 load 写整数 PRF+整数唤醒);
    b) **SQ store→load 前递路(ex0 单拍完成)无 FP 分流**——fld 命中前递 → 整数
       wb,FP PRF/FP wakeup 双缺 → 依赖它的 FP 指令僵死(ud-recoding 死锁)。
       FP load 禁前递(`!issueX_fp_pdest_w` gate),命中重叠按序等 SQ drain。

### 8.3 验证与遗留
- rv64uf-p 全部 + rv64ud-p 全部:23/23 PASS(注意 rv64ud-p-move 的 tohost=
  0x80002000,与其他测试不同)。
- 遗留(下一批):拆 pending FP 残留(OooFpPendingExec/OooPendingFpSequencer/
  OooFpCommitGate/OooFpRegFile 实例与 glue 死线)、FP 相关 module TB 对齐、
  UNOPTFLAT 围栏族真伪甄别(新增 OooRenameMap 一处)、difftest(NEMU)/AM/
  CoreMark(10 iter)全量。

## 9. pending-FP 壳拆除实录(2026-07-02 第二批)

§7 拆除清单全部执行完毕,净删 ~800 行:
- **实例与文件**:OooFpPendingExec.v / OooPendingFpSequencer.v /
  OooFpCommitGate.v / OooFpMemAccessGate.v 四文件删除(OooFpPredicates.v 保留
  ——FpCompareGate 共用;OooFpRegFile.v 保留——FpBackend 内部架构 FPR 实例)。
- **ExecuteBackend**:两实例+13 输入/26 输出端口删;AluCoreSlice 串行写口封 0。
- **Writeback/ControlCommitSequencer**:FpCommitGate 实例、drain_fp_commit 臂、
  fp GPR 伪提交路径删除。
- **ControlPlane/DrainResolveGate/Arbiter/TrapExitEventMux/ObservableOutputGate**:
  pending_fp 状态输入、replay_wait fp 臂、fp capture/clear 输出全删。
- **glue/NpcCoreTop**:pending_fp wire 家族、旧 OooFpRegFile 实例(NpcCoreTop 层)
  删;**F8 fp_dirty 换源**——旧=fflags|FPR load 写|FPR 结果写(pending 通道),
  新=glue 组合 `fp_dirty_commit_w`(FPR 目的 commit | fflags commit),经新增
  commit0/1_is_fp_rd 六层 plumb(ROB 已有输出,IntBackend→ADB→ACS→EB→glue)。
- **mem 通路**:OooMemoryRequestGate 的 pending-FP 直写抢占 mux 全删(FP 访存
  走整数 LSU/SQ);OooMemoryAccess 透传口删。
- **frontend**:RunGate/SeedMux/OutstandingSequencer/BranchPrefetchClearGate 的
  pending_fp 臂删;Frontend 的 head*_fp 细分类 9 输出转内部 unused(facts 总线
  仍供 dispatch 消费)。
- **TB**:2 个死 TB 删除;8 个 TB 对齐(fp 场景组切除/死端口清/层级引用占位)。

验证:lint 0 / build 0 / module TB 97/97 / uf+ud 23/23 / CoreMark 10 iter
PASS(2.612/MHz) / riscv 官方全量(后台跑)。

## 10. difftest 基线修复(2026-07-02 第三批, 153/153 NEMU 对拍全绿)

遗留的"整数也 boot mismatch"实为**多因叠加**, 修复后全集 difftest 通过:
1. **dut 侧(NpcSimTop)**: ecall/ebreak 走 pending-trap 通道不产生 ROB/ctrl
   commit → ref 单步停在 ecall 等待, dut 直接报 handler 第一条 → 错位 abort
   (此前误判为"boot 头 mismatch"——实为测试尾 pass 例程的 ecall)。修=trap_ex
   注入拍(cause∈{3,8,9,11})合成一条 commit 事件(GPR 不变, next=trap 目标)。
2. **NEMU ref 侧(fp.c)五项**:
   - fflags 全面缺失(host 运算只手工置 NV)→ fenv 采集: 12 个运算函数包
     feclearexcept/fetestexcept→5 bit 映射(x86 UF 判定=after-rounding+inexact
     与 IEEE 对齐);
   - 运算结果 NaN 未 canonical(host 传播 operand 位形)→ from_host 收敛
     0x7fc00000/0x7ff8…;
   - 单精读口全面缺 NaN-box 检查 → f32_unbox×9 处(FSW/FMV.X.W 按 spec raw);
   - FCLASS.S/D 解码 bug(rs2==1 恒不中, fclass 被当 FMV 执行);
   - fcvt_to_int 重写: 按 rm 取整(rint/trunc/floor/ceil/RMM)→判界→NX 手工;
     负输入不再一刀切 NV(fcvt.wu.s(-0.9,rtz)=0+NX); NaN/饱和值按目标宽度 sext。
3. **NEMU ref 侧(bitmanip)**: Zbb 的 W 家族整体缺失——clzw/ctzw/cpopw/roriw
   (OP-IMM-32 无 zb 兜底, 6000971b 被 rv64i 当 slliw 误执行)+rolw/rorw
   (op_32 缺 case); decode.c 与 decode_cache.c 双路径都补兜底。

流程: 每次 so 重建备份/恢复 nemu/.config + 重建主 interpreter(memory 契约)。

## 11. F2 第五轮攻坚实录(2026-07-02/03, 撤退但侦查资产入册)

difftest 护栏就位后重试"预测正确免 redirect"。两个形态四小时内全部数据化:
- **哨兵版+去强制项**: riscv-tests 全绿; CoreMark boot ~2000 条 wrong-path 重复
  提交(0x2e54 双份)——not-taken 分支的 fall-through 双份历来靠恒-mispredict
  的 ROB-walk 砍第一份, 免 walk 后双活。
- **predict_taken gate 版**(taken 才 direct fire): jalr difftest 揪出三障碍:
  ①direct fire 的 flush 漏杀同拍 fetch-rsp(wrong-path 包 20c 入 FIFO, 旧靠
  后端恒 redirect 二次清洗); ②拍内解析(direct_branch_resolve_redirect)在
  fire 拍改写 next_fetch, 与 pred taken 项(direct_branch_pred_pc)不同源;
  ③mispredict-redirect 后 bypass 只 dispatch head0(204 蒸发)。
- **纯哨兵版**(direct fire 全关): taken 紧循环退化(matrix 内循环 9 拍/迭代)。

结论回到 known-issues #105 主线: per-packet threaded 取指决策的结构改造,
且须一并处理 flush 对 in-flight rsp 的 discard 语义与 bypass 双发。
**本轮保留资产**: pred_npc 哨兵化(count<2=64'h1); ecall/ebreak commit 合成
+MMIO-load skip 使 CoreMark difftest 条级可用(F2 专项的调试基建)。
基线恢复后 CoreMark 2.612/MHz 与改造前逐位一致。
