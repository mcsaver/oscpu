# F2 整体实施方案:pred_npc 单源化 + not-taken 免 flush + BPU resolve-update(#105 正解落地)

> 状态:实施中(2026-07-03)。前置:domain-A 已落地(dbranch 普通 dispatch 进 ROB,总闸已拆),
> mode=1(`OOO_ROB_WALK_MODE`)恒 mispredict + ROB-walk 是当前交付态。
> 本刀把「恒 mispredict」换成「真 mispredict」,一次成型,不做单点补丁(8 轮失败史见 known-issues #105/#110)。

## 1. 现状机器的三个关键事实(2026-07-03 侦查定死)

1. **每条 direct branch dispatch 拍恒 flush 全前端**(`OooFrontendActionGate.direct_frontend_flush` 含
   `direct_branch0/1_fire`,fire 无预测方向条件)→ FIFO 清 + 按 `direct_branch_pred_pc`(taken?target:fallthrough)重取;
   同拍 head1 作为「影子」被普通双发进 ROB(`frontend_dispatch_to_backend_valid` 对 dbranch 拍=1 且驱动 d1),
   恒靠后端 mispredict 的 ROB-walk 砍掉,fall-through 从 head1.pc 完整重取。
2. **拍内快解析已死**:`dispatch_branch_fast_candidate_w = ... && !OOO_DBRANCH_DOMAIN_A` 恒 0
   → `direct_branch_resolve_valid` 恒 0 → **BPU update 四臂全死,BHT 从不学习**;
   方向预测=BHT 未命中的 static BTFN(`imm[63]`,回跳 taken)。
3. **bypass 已禁**(`fetch_rsp_dispatch_bypass = ... && !OOO_ROB_WALK_MODE`),head 恒经 FIFO;
   branch/jalr prefetch、branch_target/fallthrough append、pending_branch capture 在 mode=1 全为死路
   (`BRANCH_APPEND_DISPATCH_ENABLE=0`、`BRANCH_PREFETCH_DISPATCH_ENABLE=0`、capture 含 `!rob_walk_mode`)。

即当前每条分支的代价 = 1 次 flush 重取(static 方向) + 1 次后端恒 redirect + ROB-walk;
jal/ret/jalr 同吃恒 redirect。CoreMark branch_flush 34.7% 由此而来。

## 2. 方案核心:三件事,一个真源

### 2.1 pred_npc 单一真源(障碍②的结构解)
新组合信号 `direct_fire_succ_w`(OooFrontend)= 本拍 direct fire(jal/ret/branch/jump_spec)后前端
**实际重取目标**,mux 臂与 `OooFetchPcOutstandingSequencer` 的 direct 分支臂**逐项同一**;
OutstandingSequencer 删内部重复 mux 改收 `direct_fire_succ_i`——**两个消费者共享同一 wire,机械同源**。
dispatch 侧 pred_npc:

```
core_dispatch0_pred_npc = d0_ctrlflow_fired ? direct_fire_succ :
                          d1_present         ? core_dispatch1_pc :   // 双发:d0 后继=d1
                                                head_pred_succ;       // count>=2?下包pc0:64'h1 哨兵
core_dispatch1_pred_npc = d1_ctrlflow_fired ? direct_fire_succ : head_pred_succ;
d1_present = core_dispatch1_valid && dispatch1_ready   // pair 原子性下 ⟺ d1 实际 fire
```

### 2.2 not-taken 分支免 flush(双发直通)
- `dbranch_dual_go = dispatch0_branch && !head0_branch_pred_taken(纯 BHT 寄存输出,无 ready,不成环)
   && !head1_barrier_raw(fault1/exit1/system1/arch_trap1) && !dispatch1_unsupported && !dispatch0_unsupported`
- dual_go 拍:`direct_branch0_fire=0`(不 flush 不重取),lane1_base 放行(`!dispatch0_branch` →
  `(!dispatch0_branch || dbranch_dual_go)`)→ 分支按普通指令与 head1 **原子双发**(dispatch_fire),
  顺序流继续;pred_npc(d0)=d1.pc。解析 not-taken → 免 redirect 免 walk(零代价);taken → redirect+walk(错预测价)。
- 非 dual_go 拍(taken 预测,或 head1 是 barrier/unsupported 类):保持现状 fire+flush+重取,
  但 pred_npc=direct_fire_succ(同源)→ 解析与重取流一致时免第二次 redirect。
- **fire(solo)拍 d1 必须 squash**(`core_dispatch1_valid` gate),否则免 walk 后影子 fall-through 提交
  (#110 边界 2);非返回 JALR(depend_jump)拍同理 squash(jump_spec fire 恒 flush)。
- `dispatch1_optional` 恒 0(direct 模型选发槽遗产;dual 双发必须 pair 原子,否则 dbranch pop 后 head1 蒸发)。

### 2.3 BPU update 重建(resolve-update)
- bht_idx(12b)+pred_taken(1b)随 dispatch 载荷 thread 进 IQ(与 pred_npc 同路:DispatchMux→
  DispatchBackend→IQ→issue export)。
- 后端 branch_resolve 总线新增 export:`is_branch/taken/pred_taken/bht_idx`(pick1 同源 mux)。
- BpuUpdateGate 新臂:`resolve_update = core_branch_resolve_valid && is_branch`;update_taken/idx/pc 取 resolve 侧。
  wrong-path 分支天然不 update(walk kill 后不 issue);乱序 resolve 的 ghr 近似污染可接受。

### 2.4 后端判定
- `issue*_is_ctrlflow_w = is_branch || is_jal || is_jalr`(恒判,不再挂 mode 条件);
- `issue*_mispredict_w` 去 `mode_walk_w ||` 强制项——**jal 前后端同算 target 恒免;ret/jalr-BTB/分支预测对时免**;
- ROB-walk/redirect(RecoveryGate untracked=显式 mispredict)机制原样保留,只是从「恒走」变「错时走」。

## 3. 四形态全景(正确性论证)

| 形态 | fire/flush | d1 | pred_npc(分支) | 解析对 | 解析错 |
|---|---|---|---|---|---|
| not-taken + head1 平凡 | 否 | 双发算数 | d1.pc | 免(零代价) | redirect+walk 杀 d1+流 |
| not-taken + head1 barrier/unsupp | 是(重取 fallthrough) | squash | fallthrough(同源) | 免(吃一次 flush) | redirect+walk 杀重取流 |
| taken 预测 | 是(重取 target) | squash | target(同源) | 免(吃一次 flush) | redirect+walk |
| jal/ret/jalr-spec | 是(现状) | 本就不双发 | target(同源) | jal 恒免;ret/jalr 命中免 | redirect+walk |

哨兵兜底:count<2 且无 fire → pred=64'h1 恒 mispredict(安全,资产保留)。

## 4. 改动文件清单

前端:OooFrontendDispatchGate(dual 资格+fire gate+squash)/OooDirectControlFlowGate(branch0 fire gate)/
OooFrontendBackendDispatchMux(d1 squash+pred_npc mux+bht/pred_taken 出线)/OooFrontend(direct_fire_succ 构造+接线)/
OooFetchPcOutstandingSequencer(收 direct_fire_succ_i)/OooBranchBpuUpdateGate(resolve 臂)/
OooBranchAppendDispatchGate(optional 恒 0)。
后端:OooIntBackend(去强制项+ctrlflow 恒判+resolve export+载荷)/OooDispatchBackend/OooIntIssueQueue(载荷 +13b)/
OooExecuteBackend/OooCoreTopGlue(透传)。

## 5. 验证矩阵

build+lint(UNOPTFLAT 零容忍)→ module TB 全量 → riscv 153 全集 NEMU difftest → CoreMark 10 iter difftest
+ 性能 bucket 对比(branch_flush 34.7% 基线)→ 官方全量 regress。

## 6. 落地实录(2026-07-03,一次成型)

### 6.1 结果

- **CoreMark/MHz 2.869 → 3.395(+18.3%)**;branch_flush 34.7% → **19.4%**;IPC≈1.077;
  branch accuracy 92.7%(498782/538166,BHT resolve-update 学习恢复,此前恒 0 训练)。
- 验证全绿:riscv **153/153 全集 NEMU difftest**、CoreMark 10 iter **difftest 全程零 mismatch
  HIT GOOD TRAP**、module TB **97/97**、lint 0(UNOPTFLAT 0)。
- `issue*_mispredict_w` 强制项拆除,`is_ctrlflow=branch||jal||jalr` 恒判;mode=1 的 ROB-walk
  机制保留为错预测恢复路径(从「恒走」变「错时走」)。

### 6.2 主体落地与 §2 一致

pred_npc 单源(`direct_fire_succ_w` 同 wire 喂 OutstandingSequencer 与 dispatch pred_npc;
OutstandingSequencer 删内部重复 mux 改收 `direct_fire_succ_i`)、dual_go(裸事实谓词,无 ready)、
solo/jalr 拍 d1 squash、`dispatch1_optional` 恒 0、bht_idx(12b)+pred_taken(1b)thread 进 IQ
(镜像 pred_npc 的 dispatch/compact/checkpoint/issue 全套)、resolve 总线 export
`is_branch/taken/pred_taken/bht_idx`、BpuUpdateGate 加 resolve 臂。
UNOPTFLAT 实战一例:dual_go 起初用含 valid 的 `dispatch1_unsupported`(valid←core_dispatch1_valid
←dual_go 成环),解法=AluDecodeBackend export **无 valid 项的裸支持性** `dispatch*_unsupported_raw`。

### 6.3 三个新根因(全部是被「恒 mispredict 节奏」掩盖的预存漏洞,免 redirect 后显形)

1. **flush 拍顺序取指臂泄漏(#105 障碍①真身)**:direct fire 拍 `can_issue_request` 仍放行顺序
   请求,用的是旧 `next_fetch_pc_q`(重取目标下拍才可见),wrong-path 请求发出且被 OutstandingSeq
   flush 臂登记为合法 outstanding → wrong-path 包入 FIFO 提交(add difftest 0x174 案)。旧机器靠
   恒 redirect 二次清洗掩盖。修:`OooFetchFlowControl.can_issue_request` 加 `!direct_frontend_flush`
   (jal/ret 走 redirect 臂不受影响,分支 spec 重取多 1 拍)。
2. **MIQ kill 拍同拍 push 漏标**:mispredict 当拍 IQ squash 未生效(kill_valid 寄存一拍),
   wrong-path load 仍可 issue+push MIQ;kill 扫描只看 `valid_q` 旧值 → 该 entry 漏标 killed,
   迟到 rsp 写「已被 walk 回收并重分配」的 preg(CoreMark p42 案:right-path `ld t4` 的前递正确值
   进 ROB/commit,GPR 对拍全过,IQ 里的分支却读到被污染的 preg → 方向错)。修:MIQ push 块同拍
   按 age 判 killed。
3. **MMIO load 可投机发射(架构级预存漏洞)**:`mem_order_ready` 的 plain-load 臂不排 MMIO,
   wrong-path MMIO load 发射=不可撤销设备读副作用 + LEGACY 在飞事务不受 MIQ killed/walk 保护
   (mem_pending 只 flush 清)。修:MMIO load 归入 ROB 队头独占臂(与 AMO 同,恒非投机)。

### 6.4 difftest 基建:MMIO skip 搬到 commit 拍(既往 3.2M 条预存墙的真身)

旧机制=桥 rsp 拍/uart 总线拍置全局 skip 旗,与 commit 粗配对。两个时序洞:
(a)SQ 切换后 store 的总线访问在 **commit 之后**,UART store 自己吃不到 skip,ref(NEMU so 无
设备)真执行 MMIO store → fault → ref.pc=0(F2 前 CoreMark difftest 3,204,741 条的「预存墙」
即此;F2 改变节奏后提前到 ~1700 条显形);(b)wrong-path MMIO 访问/rsp→commit 距离拉大都会错位,
skip 旗毒到无辜 commit(其 ROB next_pc 是预测值,ret 的该字段=RAS top,ref.pc 被设 0 跑飞)。
修(csrc/cpu/difftest.cpp):**commit 拍按 inst 解码 EA**(load/store/AMO,EA=gpr[rs1]+imm),
EA<0x8000_0000 即 MMIO → ref 不步进、拷 dut GPR 进 ref、ref.pc=pc+4;dpi.c 旧
`npc_mmio_load_event/uart_event` 的 skip 调用退役。限制:RVC 压缩 mem 指令未解码(当前设备访问
均为 32b 指令,遇 RVC 设备访问需补)。

### 6.5 TB 对齐

11 个受影响 TB:OutstandingSequencer(TB 侧重建 direct_fire_succ mux)、DispatchGate/DispatchMux
(新输入 tie/驱动)、AppendDispatchGate(optional 期望 0)、int_backend(场景 EA 入 pmem——旧场景
「串行等待」断言靠 0x270 落 MMIO 区占 mem_pending 的巧合,按 MIQ 背靠背语义重写)、
core_top_glue(fire 观测期望翻转:not-taken 预测 dual 双发不 fire)。

### 6.6 裁决与遗留

- taken fire 的 flush+重取延迟(fetch 84% bucket 的一部分)是下一刀空间:分支 spec 重取走
  redirect 臂(省 1 拍)、BTB/loop-buffer 免 flush 形态、fetch-time BPU。
- BPU update 只训条件分支(is_branch gate);jal/jalr 由 pred_npc 通路免 redirect,BTB/RAS
  的学习通路沿旧机制。ghr 在乱序 resolve 下的近似污染可接受。
- RVC 设备访问的 difftest skip 缺口(6.4)入 known-issues 备忘。
