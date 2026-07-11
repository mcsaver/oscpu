---
name: ooo-core-architecture-constitution
description: RV64 OoO 核的微架构宪法文档及其两执行域框架（域A真OoO / 域B串行pending）
metadata: 
  node_type: memory
  type: project
  originSessionId: f1fe0282-f035-4090-8cb2-559e132112ac
---

**〔2026-07-03 更新〕宪法已升 v0.2**(随全 RTL 重读同步【现状】层, 见 [[rv64core-audit-baseline]]):
两执行域图景已过时——域 B 只剩 system/trap 类, branch/jump/fp/mem 已迁域 A(F2/FP 簇/SQ),
E2/E3 副作用例外已消除, branch_event 已有显式 mispredict。下文 v0.1 框架与 B2 失败史仍是
有效历史记录(负结论防重蹈), 但**现状以 `rtl-ground-truth-2026-07-11.md` 为准**；
07-03 snapshot 已归档。
文档归档: b2-branch-spec-redirect.md 等已移 `design/arch/history/`。

RV64 乱序核新立**微架构宪法**：`npc/rv64/design/arch/ooo-core-architecture.md`（v0.1，2026-06-29→v0.2，2026-07-03）。
它是 normative 顶层，规定指令生命周期、标准 uop/fetch_packet/event 字段、状态 owner 表、
副作用·flush·redirect 宪法、pending 退出计划；是 ROADMAP B2/B3/B4/B-LSQ 的父规范。

经全核 11 路只读审计（Workflow + Explore mapper，带 file:line）确认的核心框架——**两个执行域**：
- 域 A（真 OoO）：直线整数/乘除/load 走 rename→ROB→IQ→execute→commit，动态双发射。
- 域 B（串行 pending）：branch/jump/mem-barrier/fp/system/trap 捕获进单 entry owner，拉
  `OooStopPendingSequencer` 的 `stop_pending`、全后端 drain（`OooPendingDrainResolveGate`）、解析一条再恢复——近顺序。

关键拓扑错配（"干净的杂糅感"根因）：架构 GPR `OooArchRegFile` 在 `OooAluCoreSlice` 内、
ROB 在 `OooDispatchBackend` 内、子系统 wrapper 是从 1415 行 `OooCoreTopGlue` 抽出的聚合（策略仍留 glue）、
uop 是散线且复用 50-bit legacy CTRL_BUS。commit 唯一改架构态基本成立，+3 受规约例外：B1 store、FPR、fflags
（后两者随 FP 迁出 pending 应消除）。

**用户定调（2026-06-29）：north star = 真正的乱序多发射核，目标是拆掉域 B，不是约束它。**
域 B 分两半：(1) 频繁四类 branch/jump/mem/fp = 占位脚手架、ILP 杀手，**必须拆除迁回域 A**；
(2) 稀少两类 system/trap = ISA 必需串行、真 OoO 标准做法（队头执行+刷 younger），**保留**。
拆除顺序：**B2（多级分支投机+统一 redirect，一切投机深度前置）→ B-LSQ（LQ/SQ+前递+歧义消解+MSHR）
→ B-FP（FP 重命名+IQ+簇，消除 FPR/fflags 副作用例外）→ serialize-at-retire 清理删 stop_pending**。
每拆一类删掉对应 pending owner（§8.3 标注），域 B 四类目标清零、不准只加不减。
**B2 设计已定案（2026-06-29，spec `npc/rv64/design/arch/b2-branch-spec-redirect.md`）**：3 方案 4 维评审，
合计 B=18/C=15/A=14。**决策：B(ROB-walk) 为 Phase-1 基线**——复用 ROB 已存 old_pdest/new_pdest 反向撤销 rename、
零 per-branch 快照、删 ~6.5Kb 影子阵列、最利 Fmax 与删 pending；恢复多拍(≤8,仅 mispredict 付)但远优于今天全 drain。
**C 的"最老分支 RAT 快照"作 Phase-2 可选快路径**（按 branch-resolve-loop 恢复延迟实测触发）。A(N 份 RAT 快照)仅赢恢复延迟，作 fallback。
关键现状：`OooCoreTopGlue.v:554 direct_branch_spec_start_w=1'b0`（投机生产线关）；全核无 mispredict 标识符（隐式 next_pc 比对）；
`OooIntBackend.v:859 rob_idx_older_than()` 已是 kill_younger_than 的 age 原语。共享地基(先做)：显式 mispredict+rob_idx→单一 redirect arbiter→kill-younger。
**B2 实施 slice-1 ✅(2026-06-29)**：`vsrc/control/OooRedirectArbiter.v`(纯组合 selector,仲裁=年龄最老胜+trap 类平手)+`tb_ooo_redirect_arbiter`(13 例 RED→GREEN,负对照验过)+`define.v REDIR_REASON_*`;模块 TB 113/113 绿、check-rtl-style 绿、**未接核**。
**实现暴露 spec bug**:原"IMMEDIATE>DEFERRED>TRAP 固定优先级"错(更年轻 direct 会覆盖更老 trap)→改年龄律(trap 恒在 head 自然最高),spec+宪法已修。next=mispredict+rob_idx 导出→kill-younger→接核替换 OooFetchRequestMux。
新模块加 TB 流程:`filelist.mk` 加 RTL_ 变量 + `testbench/Makefile` 加 TESTS 行与 `TB_SRCS_<name>`;TB 用 `tb_common.svh`(`tb_finish` $fatal 才真红;trap_exit 那种 `$finish`-on-fail 是latent gate bug)。

**B2 高风险大刀验证负结论(2026-06-29)**:点火休眠单级 checkpoint 投机(`OooCoreTopGlue.v direct_branch_spec_start_w` 1'b0→1'b1)**功能 gate 大破**——riscv 255/16(store/div/clmul FAIL)+AM 分支程序活锁(撞满 max-cycles)。根因:weak 单 checkpoint 的 quiesce/capture 对多周期/访存在飞指令系统性损坏态,基本分支恢复也活锁——这是它被硬关的根因。**已精确回退 1'b0,riscv 271/0 复原**。结论:**不复活此废弃路径(被 ROB-walk 取代),真 OoO 多分支只能走 ROB-walk 大建(多会话级整合,difftest 护航)**。
eval 验证坑:跑 `--am` 前看 `.config`——`CONFIG_NPC_DIFFTEST=y` 会让 Sv39/PMP/privileged/SBI/device/Linux 测试对 NEMU 已知 diverge → AM 出 ~12 FAIL(45/12),非代码回归;riscv-tests 271/0 是更可靠的核行为 gate。
Lint 关键:Verilator `make lint` 用 `-Wall`,**PINMISSING(未接输出端口)是致命**(exit 2);新输出必须接线或随同族信号 plumb 到顶(driven-but-unused 走 UNUSEDSIGNAL,已 `-Wno` 抑制)。新增模块端口后,**in-core 实例化点必须 tie-off**(输入接常量、输出接死线),否则 lint 致命。

**B2 正道起步:ROB-walk 恢复 FSM ✅(2026-06-29)**:`OooRob` 加 `kill_valid_i`/`kill_rob_idx_i`+多周期反向 walk(recover_q/walk_ptr_q/kill_idx_q),从 tail-1 反向 squash 严格更年轻 uop、2/拍 emit `walk{0,1}_{arch_rd,old_pdest,new_pdest,rd_en}` 供 rename 还原/free 回收、收尾回退 tail、`recover_active_o` 冻结 dispatch/commit。in-core kill 接 1'b0=行为中性(构造可证+113/113)。`tb_ooo_rob` 定向 walk 测**两条终止路径**(奇 younger→last_one、偶 younger→last_two)。**经验:负对照暴露覆盖盲点**——首版只测奇数(last_one),删 last_two 仍 PASS;补偶数例后负对照才有效。**rename-map walk-restore 端口 ✅**:`OooRenameMap` 加 `restore_valid/restore{0,1}_{en,arch,pdest}`,恢复 `map[arch]<=old_pdest`,lane1(更老)同拍 WAW 源序后写胜(=最老 squashed 写者留存=分支处精确映射)。in-core 接 0=行为中性。tb 加恢复测+负对照(换 lane 序)。
→ **ROB-walk 恢复数据通路的 ROB(emit)+rename(restore) 半边已建+隔离验证**(113/113+lint+style 全绿)。

**B2 全整合 + Step B 投机 flip 实测（决定性负结论，2026-06-29）**：续建 IQ age-squash + Step A 端到端接线(walk→rename/free/IQ,行为中性)+ Step B `OOO_ROB_WALK_MODE` 开关(direct_branch_spec_start=1 + mispredict→ROB-walk kill + checkpoint 抑制)。eval 调试修了 UNOPTFLAT 组合环(kill 打一拍寄存破环)+ BLKSEQ(survivor count 改组合)。**mode=1 功能实测 riscv 251/20、AM 14/43(分支程序全活锁)，与父会话 checkpoint 投机失败模式几乎一致**。
**关键定性：ROB-walk(已验证正确)取代 checkpoint 后失败不变 → 问题不在恢复机制，而在前端投机流本身**(fetch-past-branch + 单 spec tracker + redirect 这套休眠机器,启用即广泛破/活锁)。控制面已 fence 副作用(core_mem_issue_block=branch_spec_active 挡投机 store/load、core_commit_ready 在 spec-active 关闭挡投机提交)。**真正使分支投机=重建前端投机流(多会话级)**,非恢复修复。
**已回退 `OOO_ROB_WALK_MODE`=0 保绿**;ROB-walk 恢复基础设施(FSM+rename-restore+free-reclaim+IQ-squash+arbiter+rob_idx)全保留、mode-gated、隔离验证,待接入。
**精确根因(itrace `bit` 实测)**:`control wait cycles: jump=1227/1500`,卡在 JALR @pc=0x9c;分支预测准确(8/9、RAS 18/18、JAL 21/21)——**不是误预测**。livelock = **branch-spec ↔ jump-pending 死锁**:mode 只开了分支投机(branch_spec_active→commit 冻结),但 **jump(JALR)仍走 pending+drain**,drain 要 ROB 排空、而 commit 被 spec 冻结→JALR 永不 resolve→stop_pending 不退→活锁。**修法=jump 也投机(后端加 JALR 解析+去 jump-pending+JALR mispredict 走同一 ROB-walk kill)——即 B2 的 jump 半边**(本会话只做了 branch 半边)。这是多会话级前端+后端工作。教训:**B2 必须 branch+jump 一起投机,只做 branch 会与 jump-pending 死锁;且要先做 pred-next-pc threading 才多分支正确**。

**B2 mode=1 大刀 bring-up（2026-06-30，branch+jump 一起投机；未完成但根因唯一）**：实现 4 片（mode-gated，
mode=0 逐位中性 271/0）：片1 pred_npc threading（前端实际预测后继 PC 平行 next_pc 穿到 IntBackend）、
片3 de-pend branch+jump（stop_pending/pending capture 门控 0 + 前端非返回 JALR dispatch 期 BTB/RAS 投机续取
`direct_jump_spec_fire`）、片2 后端 BRANCH/JAL/JALR 统一 issue 级 mispredict 解析、片4 kill 源改后端显式 mispredict +
**critique#1 commit-freeze/mem-block/checkpoint_quiesce 全在 mode 下去掉破死锁** + redirect 复用 untracked 通路
（mode 下 untracked-raw 收紧为仅 mispredict，兼解 critique#4 latch/#5 churn）。**mode=1 调试修了 4 个真 bug**：
(a) `OooRob` 写回→done 只在 normal 分支、recovery 窗口丢更老指令写回→head 卡死（修：recover/kill 分支也吸收 wb）；
(b) `recovering_w` 与 IQ kill 不一致→僵尸 ROB 项（修：`recovering_w=recover_q||kill_valid_i`）；
(c) **核心**：`OooDispatchBackend.dispatch0_ready_o` 不含 ROB recover/kill 冻结→多指令共用同一 rob_idx（实测
390/394/398 都 rob=12）→wakeup 错配卡死（修：`dispatch_freeze_w=rob_recover_active_w||kill_valid_q` gate ready）；
(d) pred_npc 必须=前端实际取指后继：`next_fetch_pc_q` 是滞后一个 packet 的全局前沿→伪误预测，改 `count>=2 →
下一条 FIFO entry pc0`(`OooFetchPacketFifo` 加 `head1_pc0_o` peek)。**唯一未决**：`count==0 bypass` 时后继未入队、
`next_fetch_pc_q` 当拍未更新→pred 滞后指向本 packet 自身→bypass-taken 分支 wrong-path 提交。组合前端预测后继会与
backend mispredict 成 UNOPTFLAT 环（含 branch_target/fallthrough_dispatch 依赖后端 redirect）。**修复计划**：
寄存 redirect 打一拍 / 禁分支 dispatch-bypass issue / **per-packet 预测后继随 FIFO+bypass threaded（首选）**。
**调试坑**：difftest 在 csrwi 0x744(e4) 对 NEMU 已知 diverge（mode=0 也 diverge 但 tohost PASS）→调 mode=1 必须
`--no-diff` 按 tohost 判。task-run：`.github/task-runs/2026-06-30-rv64-ooo-b2-rob-walk-mode1-bringup/`。
现 `OOO_ROB_WALK_MODE=0` 保绿，全改动 mode-gated 保留待续。
**续2（同会话再延伸，2026-06-30）**：(e) **IQ 结构破环**（已落地保留）：mode 下禁 branch/JAL/JALR `dispatch-bypass
issue` + `issue_pred_npc_o` 恒取寄存 `pred_npc_q[idx]`（不旁路）→ 结构性断开 pred_npc→mispredict→redirect→前端预测
→pred_npc 组合环，使 count<2 可用组合前端预测后继而不 UNOPTFLAT。**关键定性**：`next_fetch_pc_q` 滞后(指向 head
自身)**反而最鲁棒(232 条)**——每分支伪 mispredict 但 redirect 恒指向架构后继=功能正确(慢)；任何更精确但与前端实际
取指不完全一致的源(fallthrough/fetch_req_pc/逐字镜像 sequencer 的 frontend_head_succ)一旦匹配错误预测→wrong-path
提交→trap@0x140。**232 根因(FETCHDBG 实测)**：operand/分支解析全对，但 not-taken bne 提交后前端未取架构后继却取到
非法 PC(0x140) instruction-access-fault——即前端投机/flush/bypass/outstanding 时序与 ROB-walk 单拍 kill 系统性不匹配
(单拍 kill 管不到 redirect 后陆续到达的 outstanding 经 bypass 的 wrong-path；mode 下 untracked redirect 未触发完整
`direct_frontend_flush` 暂停语义)。**多会话级正解**：① per-packet 预测后继随 FIFO+bypass threaded(取指当拍寄存前端
实际下一取指 PC，dispatch 取之，对所有 count loop-free 正确)；② 完整 flush-in-progress 状态(redirect 冻结 dispatch+丢
所有在途 wrong-path 直到正确路径首条到达)。两者须一起。调试块(8 个 `ifdef ROB_WALK_DEBUG`)已清，续调重置该 define。

**spec 目录清理（2026-06-29）**：78 份审计 = 68 CURRENT/5 OUTDATED/0 ORPHAN/5 SUPERSEDED（"大多过时"是高估）。
6 份真过时件已移 `design/specs/history/`；4 份活模块小漂移（FP 流水化端口 + branch-prefetch 握手）标 ⚠ 待校正、未归档（FP 三份随 B-FP 重写）。

工作约束：动 RTL 触碰指令形态/对象字段/状态 owner/flush·redirect/pending 时，先更新宪法（spec 先行）。
相关：[[rtl-coding-standard]] [[fp-arith-multicycle-pipeline]]。
task-run：`.github/task-runs/2026-06-29-rv64-ooo-core-architecture-constitution/`。
