# Task-run · RV64 OoO 核微架构宪法（normative architecture constitution）

- 日期：2026-06-29
- 类型：跨模块架构规范（全核只读审计 → 顶层 normative 文档）
- 触发：用户"第一点"——核已被整理干净，但缺一个更高层的微架构宪法来约束模块间关系（实现先长、架构后补）。
- 交付：`npc/rv64/design/arch/ooo-core-architecture.md`（v0.1 草案）。

## 方法（RECALL → PLAN → DISPATCH → VERIFY → RECORD）

1. RECALL：读 `.github/AGENTS.md`、`design/arch/ROADMAP.md`、`design/README.md`、`design/specs/README.md`、
   `vsrc/include/define.v`、`design/specs/ooo-fp-arith-pipeline.md`，确认仓库已有 `design/arch/` 约定与 B2/B3/B4 backlog。
2. PLAN+DISPATCH：用 Workflow 起 11 路只读 mapper（agentType=Explore），逐子系统在真实 RTL 上回填结构化地图
   （fetch_packet/uop 字段、执行事件、访存定序、控制面 redirect/flush/trap、commit、状态 owner、pending 普查），
   每条带 `file:line` 证据。10/11 成功（hierarchy mapper 触 StructuredOutput 重试上限失败）。
3. VERIFY：hierarchy 缺口由主 agent 直接 grep 顶层实例化补全（见下"拓扑实测"）。
4. RECORD：写宪法 + 更新 `design/README.md`、`design/arch/ROADMAP.md`、记忆。

> 审计原始结构化输出（849k subagent tokens / 360 tool uses）见会话 task 输出，未入 git；结论已固化进宪法文档。

## 用户断言裁决（evidence-backed）

| 断言 | 裁决 | 关键证据 |
| --- | --- | --- |
| Frontend 过载、拥有过多全局恢复语义 | confirmed | `OooFrontend.v` 55 子模块 >40% 涉恢复/重定向；`OooBranchResolveRecoveryGate.v`、三级分支恢复 |
| ControlPlane 是补丁总线、redirect 来源多无统一仲裁 | confirmed | redirect/flush ≥12 源、≥5 汇合点（FetchRequestMux/FrontendActionGate/CsrTrapRequestMux/TrapExitEventMux/ControlFlushSequencer） |
| 缺统一 uop（散线 + 复用 legacy CTRL_BUS） | confirmed | `define.v:556-603` 50-bit CTRL_BUS；`OooDispatchBackend.v:63-85`、`OooIntIssueQueue.v:97-137` 散线 |
| pending 是隐藏串行主干 | confirmed | `OooStopPendingSequencer.v:99-123` + `OooPendingDrainResolveGate.v:63-114`，6 类单 entry owner 全 `stop_pending && backend_drained` |
| Scheduler 只管 ready/select/issue | partially（基本达成） | `OooIntIssueQueue.v` 核心干净，附带快路径属脚手架 |
| Execute 只产 result/branch/mem event | partially | 事件散线非束；分支无显式 mispredict 位（靠 next_pc 比对）；FP 非簇 |
| Commit 唯一改架构态 | partially（+3 例外） | GPR 仅 commit 写（`OooArchRegFile.v:36-62`）；例外 E1 B1-store/E2 FPR/E3 fflags |
| pending_mem 应被 LSQ 替代 | partially | 仅 lane1 barrier；主串行在 `OooMemAxiBridge` 单 outstanding；LSQ 暂缓（`mem-lsq.md §5b`） |

## 拓扑实测（hierarchy 缺口补全，宪法 §3 的依据）

- 子系统 wrapper（Frontend/ExecuteBackend/ControlPlane/MemoryAccess/Writeback）自述"纯结构聚合，从
  `OooCoreTopGlue`(1415 行)抽出 N 实例"，互联策略仍留在 glue。
- 架构 GPR `OooArchRegFile` 在 `OooAluCoreSlice.v:218`（执行簇内）；ROB `OooRob` 在 `OooDispatchBackend.v:344`。
- `DecodeStage` 实例化 3 处（前端 6×、`OooAluDecodeBackend` 2×、legacy 1×）。
- 整数链深嵌：`OooExecuteBackend→OooAluCoreSlice→OooAluDecodeBackend→OooIntBackend→OooDispatchBackend→{FreeList,RenameMap,BusyTable,Rob,IntIssueQueue}`。

## 核心结论：两个执行域

- 域 A（真 OoO）：直线整数/乘除/load 走 rename→ROB→IQ→execute→commit，动态调度双发射。
- 域 B（串行 pending）：branch/jump/mem-barrier/fp/system/trap 捕获进单 entry，拉 `stop_pending`、
  全后端 drain、解析一条再恢复——近顺序。宪法不要求立即消灭域 B，而要求显式命名、定字段、定退出计划、单调收缩。

## 后续（下一刀候选，映射 ROADMAP）

- B2：单 control-flow arbiter + 统一 `redirect_request` + 显式 mispredict 位（先补定向 TB）。
- FP 正式簇：消解 §7.1 例外 E2/E3（FPR/fflags 改经 commit 口）。
- B4：`OooArchRegFile` 归位 commit 域、uop 收敛打包、glue 策略下沉、DecodeStage 收敛。
- 域 B 单调收缩：`stop_pending` 覆盖面只减不增。

## 改动清单

- 新增 `npc/rv64/design/arch/ooo-core-architecture.md`（宪法 v0.1）。
- 改 `npc/rv64/design/README.md`（nav 增宪法行）、`npc/rv64/design/arch/ROADMAP.md`（§3.2 增宪法条目）。
- 本 task-run。

## 后续 1：用户定调拆 B（真乱序多发射）

用户明确北极星=真正乱序多发射、拆掉域 B。据此把宪法 §1/§8 从"keep/shrink"改写为"拆除路线"：
branch/jump/mem/fp 四类是脚手架必须拆（ELIMINATE），system/trap 保留（ROB 队头串行，真 OoO 标准做法）。
拆除顺序 B2(分支投机+统一redirect) → B-LSQ → B-FP → serialize-at-retire(删 stop_pending)。

## 后续 2：spec 目录三角分类清理

8 批并行审计 78 份 spec：68 CURRENT / 5 OUTDATED / 0 ORPHAN / 5 SUPERSEDED（用户"大多过时"实为高估）。
归档 6 份真过时件入 `design/specs/history/`（5 SUPERSEDED 完成型计划/迁移文档 + `ooo-fp-fma-fused-topology` 描述单拍纯组合已被流水化取代）；
另 4 份活模块小漂移（branch-prefetch-request-gate + 3 份 FP 流水化端口漂移）标 ⚠ 待校正、不归档（避免活模块失 spec），FP 三份随 B-FP 重写。
`git mv` 保留历史，写 `history/README.md`，修 `specs/README.md` 唯一 live 索引引用。

## 后续 3：B2 设计 workflow 定案

3 方案设计 + 4 维评审（5 最好）：合计 **B=18 / C=15 / A=14**。B(ROB-walk) 赢时序/正确性/面积 3 维，
A(N 份 RAT 快照) 仅赢恢复延迟。**决策：B(ROB-walk)为 Phase-1 基线**（复用 ROB 已存 old_pdest/new_pdest 反向撤销 rename，
零 per-branch 快照，删 ~6.5Kb 影子阵列，最利 Fmax 与删 pending 干净度；恢复多拍但 ≤8、仅 mispredict 付，仍远优于今天全 drain）；
**C 的"最老分支 RAT 快照"作 Phase-2 可选快路径**（按 branch-resolve-loop 恢复延迟实测触发，避免前置双族 corner case）。
验证关键事实：`OooCoreTopGlue.v:554` `direct_branch_spec_start_w=1'b0`（投机生产线关闭）；全核无 mispredict 标识符（隐式 next_pc 比对）；
`OooIntBackend.v:859` 已有 `rob_idx_older_than()`（kill_younger_than 的 age 原语）。
共享地基（A/B/C 都需、先做）：显式 mispredict+rob_idx → 单一 redirect arbiter(§5.5) → kill-younger 机制。
spec 落 `npc/rv64/design/arch/b2-branch-spec-redirect.md`。

## 后续 4：B2 实施 slice-1（单一 redirect arbiter）✅

按"先补 arbiter 定向 TB"起第一刀（隔离、零核风险）：
- 新增 `vsrc/control/OooRedirectArbiter.v`——**纯组合 selector**，仲裁主判据=**年龄**（age=rob_idx−rob_head 环形，最老胜），
  同 age 平手按类 `trap>branch>direct`（trap 恒在 head 故自然最高）；透传胜者 `{pc,kill_idx,reason,flush_fetch,flush_backend}`。
  3 源（trap/branch/direct），无 function 隐藏仲裁，拓扑写在文件头。
- `define.v` 加 `REDIR_REASON_{NONE,BRANCH_MISS,JALR_MISS,TRAP,XRET,SFENCE,FENCEI,DIRECT}`（3-bit）。
- 新增 `testbench/tests/tb_ooo_redirect_arbiter.sv`——13 例（年龄优先级/类平手/环形 wrap/字段透传），用 `tb_finish` $fatal 真红；
  **负对照**（把 `<=` 改 `<` 破坏 trap 平手）→ case8 红、退出 1，证断言非空过。
- 接线：`filelist.mk` + `testbench/Makefile`（TESTS+TB_SRCS）。
- 验证：模块 TB 全套 **113/113 PASS**、`make check-rtl-style` PASS。
- **实现暴露 spec bug**：原 §3.2/§5.5 写"IMMEDIATE>DEFERRED>TRAP_COMMITTED 固定优先级"**不正确**（会让更年轻 direct 覆盖更老 trap/branch）；
  已改为年龄律（trap 因恒在 head 自然最高），spec 与宪法同步修正。
- 关键事实复核：`OooCoreTopGlue.v:554 direct_branch_spec_start_w=1'b0`、全核无 mispredict 标识符、`OooIntBackend.v:859 rob_idx_older_than()` 已存。
- **未接核**（纯增量新模块）。next：mispredict+rob_idx 导出 → kill-younger → 接核替换 OooFetchRequestMux 隐式链。

## 后续 5：B2 实施 slice-2（branch_resolve rob_idx 导出 + plumb）✅

- `OooIntBackend.v` 加输出 `branch_resolve_rob_idx_o = emit ? issue0_rob_idx_w : issue1_rob_idx_w`（与 branch_resolve_pc/next_pc 同源，纯增量旁路）。
- 随 `branch_resolve_*` 家族 plumb 4 级：`OooAluDecodeBackend`→`OooAluCoreSlice`→`OooExecuteBackend`→`OooCoreTopGlue.core_branch_resolve_rob_idx_w`（暂 driven-but-unused，待 redirect arbiter 接入；Verilator UNUSEDSIGNAL 已全局抑制）。
- **读码发现**：今天 **mispredict 在前端检测**，不在后端——`OooIntBackend.v:545 issue0_branch_next_pc_w = taken?target:issue0_next_pc_w`，`issue0_next_pc_w` 是 **fallthrough 非预测**；前端 `OooBranchResolveRecoveryGate` 用其跟踪的 `branch_spec_pred_pc` 比对得 mispredict（全核无 mispredict 标识符）。**决策**：后端算 per-branch mispredict 需把预测 next_pc 作新 uop 字段从前端 threaded 下来（多分支 B2 必需）——真实数据通路改动，列入整合切片、difftest 护航，**不在增量步做**。rob_idx 与该决策无关故先行。
- 验证：PINMISSING 在 `-Wall` 下致命 → 必须接线（故 plumb 而非留空）；最终 `make lint` exit 0、`check-rtl-style` PASS、模块 TB **113/113 PASS**（含 alu_decode_backend / alu_core_slice / int_backend / core_top_glue，证 plumb 行为中性）。
- 触及文件：`OooIntBackend.v`、`OooAluDecodeBackend.v`、`OooAluCoreSlice.v`、`OooExecuteBackend.v`、`OooCoreTopGlue.v`（全增量端口/连线，零行为改动）。

## 后续 6：B2 高风险大刀=点火休眠投机 → 验证负结论 → 回退绿核

用户授权"允许高风险大刀完成目标、勿总做最低风险决策"，遂取最大可用 cut：把 `OooCoreTopGlue.v` `direct_branch_spec_start_w`
1'b0→1'b1，点火现核**休眠的单级 checkpoint 投机**（spec tracker/checkpoint capture-restore/recovery gate 都已接线，只差此开关）。
- 快速 gate 过：lint exit 0、模块 TB 113/113。
- **功能 gate 大破**（`eval --build --riscv --am`，`results/20260629-210219-b2-spec-enable/`）：riscv **255/16**（FAIL=store sb/sd/sh/sw/ld_st/st_ld/ma_data + div/rem + clmul + ma_addr + dirty），AM **25/32**（分支程序 if-else/recursion/bubble-sort/quick-sort/prime 全活锁撞满 4M max-cycles、CPI 1e5+）。
- **根因**：weak 单 checkpoint 的 quiesce/capture 对多周期(div/clmul)/访存在飞指令系统性损坏架构态 + 基本分支恢复在纯 ALU+branch 程序即活锁——正是它当初被硬关 1'b0 的根因，印证审计"弱模型"。
- **决策**：不复活/不调试此**架构上被 ROB-walk 取代**的废弃路径（修它=补完已弃 WIP、投资将被替换的代码，ROI 差）。**精确回退 1'b0**。
- **回退验证绿**（`results/20260629-211754-b2-spec-revert-verify/`）：riscv **271/0 完全复原**、计算/分支 AM 全绿（`branch-resolve-loop`/bubble/quick/recursion/if-else 正常 CPI）、模块 113/113、lint、style 全绿 → 证 B2 增量(arbiter/rob_idx/define 宏)行为中性。
- **附带发现（非 B2）**：eval AM 现 45/12 vs 基线 57/0——差异 12 全是 Sv39/PMP/privileged/SBI/Linux/device/semihost 测试,系当前 `.config` `CONFIG_NPC_DIFFTEST=y`+`HAS_VGA/SDB/TEXT_TRACE=y`+改过的 `timer.c/paddr.c`(均会话前未提交工作,我本会话未触碰)导致对 NEMU 已知 diverge;riscv 271/0 与计算 AM 全绿证非代码回归。建议用户单独处理（关 DIFFTEST 或确认 device 配置）。
- 结论：B2 速胜路径（复活休眠投机）证伪;真 OoO 多分支只能走 ROB-walk 大建（整合切片,多会话级,difftest 护航）。已落地基础（arbiter+rob_idx）+ 此负结论 de-risk 后续。

## 后续 7：ROB-walk 恢复 FSM（决定的正道起步，slice）✅

回退后转向决定的正道（ROB-walk），先建其**核心件**（最难、最易出 bug、可隔离验证）：
- `OooRob.v` 加 `kill_valid_i`/`kill_rob_idx_i` + **多周期反向 walk FSM**（recover_q/walk_ptr_q/kill_idx_q）：从 tail-1 反向 squash 严格更年轻的 uop，每拍 2 条 emit `walk{0,1}_{arch_rd,old_pdest,new_pdest,rd_en}`（供 rename 还原 + free-list 回收），收尾 `tail<=kill+1`；`recover_active_o`/`recovering_w` 冻结 dispatch/commit。
- in-core(`OooDispatchBackend`)的 `kill_valid_i` 接 `1'b0`、walk 输出接死线 → **行为中性**（recovering_w≡0，新分支永不取，构造可证）。
- `tb_ooo_rob` 加定向 walk 测：奇数 younger(kill idx1→squash 3,走 last_one)+偶数 younger(kill idx2→squash 2,走 last_two)+存活按序提交完好+无-younger 边界。**负对照**：删 last_two 终止→walk2 检查 RED、退出 1（先前奇数-only 测有覆盖盲点，负对照暴露后补偶数例）。
- 验证：`tb_ooo_rob` 隔离 PASS + 负对照有效；`make lint` exit 0（OooRob 新口 + OooDispatchBackend tie-off 无 PINMISSING）；`check-rtl-style` PASS；模块 TB 全套 **113/113**。
- 触及：`OooRob.v`（FSM 主体）、`OooDispatchBackend.v`（tie-off 死线）、`tb_ooo_rob.sv`（walk 测）。
- 这是 ROB-walk 多分支恢复的核心组件，隔离 RED→GREEN 验证（含两条终止路径），de-risk 后续整合（接 kill 源/IQ squash/rename·free 恢复端口）。

## 后续 8：rename-map walk-restore 端口（恢复数据通路 ROB→rename 半边）✅

ROB-walk emit 的直接消费者：`OooRenameMap` 加 `restore_valid_i` + `restore{0,1}_{en,arch,pdest}_i`，
恢复拍 `map[arch]<=old_pdest`；lane1(程序序更老)同拍 WAW 源序在后→写胜→最老 squashed 写者的 old_pdest 留存=分支处精确映射。
in-core(`OooDispatchBackend`)接 0=行为中性。`tb_ooo_rename_map` 加恢复测（基本恢复/未触及寄存器/同拍 WAW 老者胜/en=0 门控），
负对照(交换 lane 源序)→RED 退出 1 证有效。`make lint` 0、`check-rtl-style` PASS、模块 **113/113**。
触及：`OooRenameMap.v`、`OooDispatchBackend.v`(tie-off)、`tb_ooo_rename_map.sv`。
现状：ROB-walk 恢复数据通路的 **ROB(emit)+rename(restore) 半边已建+验证**；余 free-list 回收端口 + IQ age squash + kill 源(mispredict) + 接核，属整合切片。

## 后续 9：B2 全整合（IQ squash + Step A 接线 + Step B 翻开关）—— 连续执行

用户升级目标=完成整个微架构（不止 B2）。遂连续执行 B2 全整合，逐件保绿：
- **IQ age-squash**（`OooIntIssueQueue`）：加 `kill_valid/kill_rob_idx/rob_head_idx/recover_active`，kill 拍清比 kill_rob_idx 更年轻(age 更大)的程序序后缀 entry、recover 期冻结发射。gating 经 TB 113/113 验证（squash 本体待整合 eval 验）。
- **free-list 回收=复用现有 free 口**（无需新模块逻辑）；busy-table=clear-on-realloc（无需改）。
- **Step A 端到端接线**（`OooDispatchBackend`）：ROB.walk{0,1}→rename.restore + free.free{0,1}(`recover?walk:commit` mux) + IQ.recover/kill，全 mux 在 recover=0 时选常规路径=行为中性（lint 0、113/113）。
- **Step B 翻开关**（`OOO_ROB_WALK_MODE` 定义，default 0）：mode 下 `direct_branch_spec_start=1`（前端投机越过分支）+ `rob_kill_valid=checkpoint_restore_i`(前端 branch_spec_restore=mispredict) + `kill_rob_idx=branch_resolve_rob_idx`(后端解析分支,OooIntBackend→OooDispatchBackend 1 级 plumb) + checkpoint capture/restore 全抑制(ROB-walk 取代)。单分支深度(复用前端单 spec tracker;多分支待 pred-next-pc threading)。mode=0 验证 113/113+lint 绿（行为中性）。
- eval mode=1 迭代调试：①UNOPTFLAT 组合环(mispredict→recovering→dispatch_ready→issue→branch_resolve→mispredict)→**kill 打一拍寄存**打破；②BLKSEQ(IQ kill 分支序逻辑里的 blocking)→**survivor count 改组合 @* 算**。两修后 build OK。
- **Step B mode=1 功能实测（决定性负结论）**：`b2-robwalk-spec-on3` riscv **251/20**（store sb/sd/sh/sw/ld_st/st_ld/ma_data + div/rem + clmul + ma_addr + dirty）、AM **14/43**（分支密集程序 string/if-else/recursion/add/bit/bubble-sort 全活锁撞满 4M cycles）。**与父会话 checkpoint 投机失败模式几乎一致**（255/16 vs 251/20）。
- **根因定性**：ROB-walk 恢复（已隔离验证正确）取代 checkpoint 后**失败模式不变**→ 问题**不在恢复机制**（checkpoint vs ROB-walk 同样破），而在**前端投机流本身**（fetch-past-branch + 单 spec tracker + redirect 这套休眠机器，启用即广泛破/活锁）。控制面已 fence 危险副作用（`core_mem_issue_block=branch_spec_active` 挡投机 store/load、`core_commit_ready` 在 spec-active 时关闭挡投机提交），故 store/commit 安全；但前端投机流的 redirect/recovery 收敛有根本缺陷。
- **决策**：恢复基础设施（ROB-walk FSM + rename-restore + free-reclaim + IQ-squash + arbiter + rob_idx）**已建成并隔离验证、Step A 端到端接线、mode-gated 行为中性**。**回退 `OOO_ROB_WALK_MODE`=0 保绿**（`b2-mode0-verify` 确认 riscv **271/0 复原**、计算/分支 AM 全绿、无活锁；AM 45/12 仍是 .config DIFFTEST artifact）。
- **精确根因（itrace `bit` 实测，mode=1）**：`control wait cycles: jump=1227/1500`，卡在 **JALR @pc=0x9c**；分支预测准确（branch 8/9、RAS 18/18、JAL 21/21）——**非误预测**。livelock = **branch-spec ↔ jump-pending 死锁**：mode 只开分支投机（`branch_spec_active`→commit 冻结），但 **jump(JALR) 仍走 pending+drain**，drain 要 ROB 排空、commit 却被 spec 冻结 → JALR 永不 resolve → `stop_pending` 不退 → 活锁。
- **下一步（精确、可执行，但多会话级）**：B2 的 **jump 半边**——后端加 JALR 解析（rs1+imm vs BTB/RAS 预测，产 mispredict+rob_idx，走同一 ROB-walk kill）+ 去 jump-pending（gate `OooStopPendingSequencer` jump 臂 + 禁 jump capture）+ 前端续取预测目标。再加 §3.1 pred-next-pc threading 才多分支正确。**教训固化**：B2 必须 branch+jump 一起投机，只做 branch 半边会与 jump-pending 死锁。
