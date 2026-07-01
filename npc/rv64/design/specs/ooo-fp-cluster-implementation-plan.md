# B-FP 实施方案(FP 从域B pending 旁路迁成正式乱序执行簇)

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
