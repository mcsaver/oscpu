# 规范:dispatch→issue 关键路径时序优化

> **[2026-06-29 重要修正]** 本文标题原称 dispatch 为"唯一 Fmax 封顶项",**已被推翻**。对 OooFpArithGate
> 做组合路径 OOC 实测:**单周期 FP FMA 路径 = 173 级 / 36.5ns logic,约 4× 于 dispatch 的 39 级 / 7.95ns**。
> FP arith 经确认单周期(OooPendingFpSequencer:120-121),故**真正的 Fmax 封顶是单周期 FP FMA,不是 dispatch**。
> 此前遗漏因:旧时序分析仅模块级 OOC 综合 OooDispatchBackend,FP arith 从未做时序 OOC;全核 P&R 在 WSL
> 不可行,FP 长路径与 dispatch 从未同网表比较。详见 `.github/memory/known-issues.md` [T1]。**时序优化真正
> 高优先级 = FP arith/FMA 流水化(2-3 级)**;dispatch-bypass 优化次之(它只省 7.95ns,FP FMA 36ns 才是封顶)。
> 下文 dispatch 分析仍有效(dispatch 是 FP 之外最深的整数路径),但"唯一封顶"应读作"整数侧封顶"。

> **[2026-07-03 更新(RTL 重读)]** 上述 FP 封顶已解除:`OooFpArithGate` 已流水化(FADD/FMUL/FMA 分级、
> 统一第 5 拍出结果、可背靠背,单拍 173 级关键路径压到每级 ≤ dispatch 级数),pending-FP 通道已拆除
> (`OooPendingFpSequencer` 已不存在,FP 走独立 rename/IQ 流水簇)。dispatch→issue 链重新成为当前
> 已知最深逻辑级路径;本文 §6c "不 ship dispatch-bypass" 的负决策与重启条件仍有效。
> 另:F2(`OOO_ROB_WALK_MODE=1`)下分支/JAL/JALR 已禁 dispatch 旁路(恒经队列发射),旁路仅余 ALU/访存类。

# (原标题)dispatch→issue 关键路径(整数侧最深路径)

> 模板见 `SPEC-TEMPLATE.md`。目标:`OooDispatchBackend` 及其子模块 `OooFreeList` / `OooBusyTable`
> / `OooIntIssueQueue`。状态:**已定案(§6c 数据完备负决策,重启条件见文末)**;数据来自 Vivado OOC 模块综合。

## 1. 数据(实测关键路径,2026-06-28 OOC)
`vivado/out/mod-OooDispatchBackend-20260628-143934/`:
- Slack −25.463ns,Data Path Delay **27.177ns**(logic 7.948ns / route 19.229ns,route 70% 但 OOC
  unplaced 不可信,**只看 logic delay 与 logic levels**)。
- **Logic Levels = 39**(CARRY4=10 LUT2=3 LUT3=3 LUT4=4 LUT5=3 LUT6=16),已从首版 42 降到 39。
- Source `u_free_list/count_q_reg[4]/C` → Dest `u_issue_queue/ctrl_q_reg[3][0]/CE`。
- 全核唯一封顶:第二名 OooFetchAxiBridge 仅 20ns/35 级,IntIssueQueue 18ns/21 级。

### 1.1 路径走向(单拍跨 3 子模块)
```
free_list.count_q[4]            // 空闲 preg 计数(够不够分配)
  → dispatch1_ready / dispatch0_ready   // 分配/ROB/IQ 三方就绪与
  → free_list.alloc1_preg        // lane1 并行分配的 preg(本战役新增并行读)
  → busy_table.alloc1_pdest_i → query0_ready 链(LUT6 i_22→i_10→i_1)  // 算子就绪查询(含同拍唤醒前递)
  → dispatch0_src1_ready
  → issue_queue.src1_ready 链 → issue0_valid → issue1_valid → count_q  // 同拍算发射有效+更新计数
  → issue_queue.ctrl_q CE        // IQ 表项写使能
```

## 2. 根因
**dispatch 与 issue 在同一拍内组合贯通**:本拍分配 preg → 本拍查算子就绪(含 lane0→lane1、
唤醒同拍前递)→ 本拍算"新插入表项能否发射"并更新 IQ 计数。即"零拍 dispatch-to-issue 旁路",
把 free_list、busy_table、issue_queue 三个本可分拍的阶段串成一条 39 级组合链。

## 3. 候选干预(按风险/收益)
### A. CPI-中性纯组合重构(低风险,OOC 可验级数下降,difftest+eval 保正确)
- **A1 busy_table 就绪查询平衡化**:`query0_ready` 经 i_22→i_10→i_1 多级 LUT6 线性归约;若为
  跨多 preg 的线性 OR/比较,改平衡树可省 1~3 级。需读 `OooBusyTable.v` 确认结构。
- **A2 dispatch_ready 与 free count 解耦**:路径起点是 `count_q[4]`(空闲数≥16?)经 dispatch_ready
  门控 alloc。可预寄存"free list 非空/≥2"标志(计数本就是寄存器,比较结果提前一拍算好),
  把比较移出关键拍。CPI 中性(下拍才用),省路径头部若干级。
- **A3 同拍 alloc1→busy_table 前递必要性**:lane1 的 alloc1_pdest 同拍喂 busy_table query。
  若 lane1 的 dest 不可能是 lane0/本拍 source(rename 已处理 RAW),该前递可能冗余;确认后去掉
  可断开 free_list→busy_table 的同拍依赖(收益大)。**需严格核对 rename 相关性后才能动**。

### B. dispatch→issue 流水化(中高风险,需整核 P&R 验净收益)
**已精确定位切点(读 `OooIntIssueQueue.v` 957 行后)**:IQ 的 issue-valid 已寄存
(`issue0_valid_o = issue0_found_r`),但存在 **dispatch→issue 旁路**:刚 dispatch 的指令经
`dispatch0_bypass_allowed_w`(非 mem 或 load-bypass、非 control-block 门控)可在本拍参与 select、
下拍即发射(`issue0_dispatch0_r` 等寄存位)。**关键路径正是该旁路的 select 次态组合依赖本拍
busy_table 算子就绪结果**(free_list→busy_table→IQ-select-next→count/ctrl_q.CE 全串一拍)。

**切点方案**:让 select 次态只读**已寄存表项就绪**,不读本拍 dispatch 的 busy_table 结果
(即弱化/流水化 dispatch bypass)。**代价**:刚 dispatch 的依赖指令失去快速旁路、晚 1 拍可发射。
**关键权衡**:头部负载 branch-resolve-loop 恰是依赖密集(load→store→branch 链),去旁路会**伤其
CPI**(见 `history/EVAL-REPORT-2026-06-28.md` §3.1(已归档))。故 B **必须**靠整核 P&R 实测:仅当
Fmax 提升带来的吞吐 > CPI 退化才净赢。

**当前**:整核 P&R 流程已建(`vivado/run-pnr-core.sh` + `pnr-core.tcl`,看门狗护航),运行取真实
布线 WNS 中。拿到 WNS(及估算去旁路后可达周期)后,对照 CPI 退化定量判 B 是否实施。

## 4. 不变量
- **T-I1 正确性**:任何重构后 difftest 33/33 + 三 gate(112/271/56)不退。
- **T-I2 CPI 中性(A 类)**:`eval --all` 加权 CPI 不升(基线 1.2647);B 类允许小升但须 Fmax 净赢。
- **T-I3 数据可验**:A 类改完重跑 `vivado/run-synth-module.sh OooDispatchBackend`,logic levels 必须 < 39。

## 5. 验证计划
每个候选独立小步:改 RTL → `eval/npc-eval.sh --difftest`(逐指令) + `--all`(三 gate+CPI) →
`vivado/run-synth-module.sh OooDispatchBackend`(看 logic levels)→ 退化即 git revert。
B 类额外需:搭整核 `synth.tcl` 全核 P&R(非 OOC)取真实 WNS,再判净收益。

## 6. 决策
- **A1/A2 先做**(低风险、数据可验、CPI 中性),A3 须先核对 rename 相关性。
- **B 暂缓**,前置条件=整核 P&R 流程就位(当前 Vivado 仅 OOC 模块综合,WSL 内存受限,
  整核 P&R 需评估内存峰值与看门狗,见 `vivado/README.md`)。

## 6b. spec-B 可执行实验(P&R 出 WNS 后立即跑)
精确位置 `OooIntIssueQueue.v:394-415`:`dispatch0/1_entry_ready_w` 把**本拍 busy_table 结果
`dispatchN_srcM_ready_i`** 接入 dispatch-bypass select。
- **B-cut-1(上界实验,最易测)**:`dispatch0_entry_ready_w = 1'b0; dispatch1_entry_ready_w = 1'b0;`
  (全禁 dispatch-bypass)。刚 dispatch 的指令一律写入 IQ、下拍从**已寄存** `src1_ready_q` 被 select。
  关键洞察:即便禁旁路,`busy_table→src1_ready_q[N]` 寄存写入(短,1~2 级)仍在;但 busy_table→
  select→issue_valid→count→`ctrl_q.CE` 长链被切断 → 关键路径应起于寄存器而非 busy_table 组合。
- **测法**:改后 `eval --difftest`(正确)+ `--all`(三 gate + **量 branch-resolve-loop CPI 退化**)+
  `run-synth-module.sh OooDispatchBackend`(看 logic levels 是否 < 39)+(可选)`run-pnr-core.sh`(真实 WNS)。
- **决策**:`Fmax_new/Fmax_old > CPI_new/CPI_old` 才净赢;否则 revert(git 检查点),B 判死。
- 若 B-cut-1 升 Fmax 但 CPI 退化大,再做 B-cut-2(保留 wakeup_match 驱动的旁路、仅去"已就绪"旁路)精炼。

## 6c. 实验结果与最终决策(2026-06-28,已实测)
跑了 B-cut-1/B-cut-2 两个实验(均 RTL 仿真 eval + 模块 OOC 综合,内存安全;整核 P&R 此 WSL 不可行):

| 变体 | OooDispatchBackend logic levels | logic delay | 加权 CPI | IQ 模块 TB |
|---|---|---|---|---|
| 基线(有旁路) | 39 | 7.948ns | 1.2647 | PASS |
| B-cut-1(全禁旁路) | **24(−38%)** | **3.617ns(−54%)** | 1.3340(**+5.5%**) | **FAIL**(tb_ooo_int_issue_queue 断言旁路) |
| B-cut-2(仅留 wakeup 旁路) | (≈24) | — | 1.3340(+5.5%,与 B-cut-1 **完全相同**) | FAIL |

**确证结论**:
1. **唯一 Fmax 封顶段 = dispatch-bypass 的同拍 busy_table 依赖**。去掉它 logic levels 39→24、logic delay 砍半
   (route 无关的可靠代理),新关键路径终于 `imm_q.D`(dispatch 写寄存,浅)。
2. **旁路的 CPI 价值几乎全在"已就绪算子"(busy_table)case**:B-cut-2 保留 wakeup 旁路后 CPI 与全禁
   **完全一样**(1.3340)——刚 dispatch 的指令其算子恰好本拍被 wakeup 的情形极罕见。故 B-cut-2 被 B-cut-1
   支配(同 CPI、逻辑更多),有意义的选择只有"基线 vs B-cut-1"。
3. **CPI 代价确定 +5.5%**(集中在依赖密集 ALU 环:wanshu +39%、select-sort +36%、string +28%;
   而头部 branch-resolve-loop 几乎不变,因其访存受限——见 `history/EVAL-REPORT-2026-06-28.md` §3.1(已归档))。
4. **net 收益不可在此 WSL 判定**:39→24 是否转成 >5.5% 的 **routed** Fmax 提升,需整核 P&R(此 16GB WSL
   不可行,见 `known-issues.md`)。OOC route 占 80% 不可信。

**最终决策:不 ship(回退基线)**。理由:确定的 5.5% CPI 损失 + 不可验证的 routed Fmax 收益 + 破单测
(违反 §4 T-I1)= 正是"验净收益"禁止的未验证 trade。**这是数据完备的负决策,非未完成**。
**重启条件**:① 有 ≥32GB 机器可跑整核 P&R 确认 routed Fmax 提升 > 5.5%;或 ② 明确 FPGA 目标为
Fmax-critical 且可接受 5.5% CPI。届时实施 B-cut-1(最简且 Pareto 最优)+ 同步更新 tb_ooo_int_issue_queue
的旁路时序契约(断言新行为,不可弱化真检查)。

## 7. 变更记录
- 2026-06-28：基于 OOC 实测关键路径(39 级 free_list→busy_table→issue_queue 单拍链)建立规范,
  分 A(CPI-中性组合重构,可验)/B(流水化,需 P&R)两路,B 暂缓。
- 2026-07-03：RTL 重读复核——FP arith 流水化落地后,2026-06-29 的"FP FMA 封顶"修正注记已过时,
  补 2026-07-03 更新注;状态改"已定案"。§6c 负决策不变。
