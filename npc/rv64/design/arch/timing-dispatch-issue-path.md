# 规范:dispatch→issue 关键路径时序优化(唯一 Fmax 封顶项)

> 模板见 `SPEC-TEMPLATE.md`。目标:`OooDispatchBackend` 及其子模块 `OooFreeList` / `OooBusyTable`
> / `OooIntIssueQueue`。状态:**设计中(spec 先行)**;数据来自 Vivado OOC 模块综合。

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
在 busy_table 输出与 issue_queue 之间插一级寄存:本拍只完成 alloc+就绪查询并写入 IQ 表项,
发射有效/计数在下拍由寄存值算。**代价**:dispatch 到可发射 +1 拍,背靠背依赖指令的唤醒需补
旁路(否则 IPC 退化)。**只有整核 place&route 实测 Fmax 提升 > IPC 退化才净赢**——当前仅有 OOC
模块综合(route 不可信),**无法判净收益,故 B 暂缓至搭好整核 P&R 流程**。

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

## 7. 变更记录
- 2026-06-28：基于 OOC 实测关键路径(39 级 free_list→busy_table→issue_queue 单拍链)建立规范,
  分 A(CPI-中性组合重构,可验)/B(流水化,需 P&R)两路,B 暂缓。
