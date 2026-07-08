# 规范：流水线级间边界显式化（宪法级架构治理）—— 边界清单 + 六类契约 + 分阶段实施

> 状态：**spec 先行（2026-07-08 冻结，基于四路只读侦查的 RTL 实测基线；PipeStageReg 原语
> 与 focused TB 已落地，边界提取未动 RTL）**。
> 定位：把乱序核的级间边界**显式化、归一化**——弹性边界（队列解耦）保留并确认契约，
> 隐藏在功能模块内部的刚性边界（一拍寄存簇）提取为 `vsrc/pipeline/PipeStageReg` 实例；
> flush 单点化搭车；综合侧用 `keep_hierarchy` 兑现 ABC 沿寄存器切 cone 的收益。
> 方法论：spec 先行 + 接口契约先行（`interface-contract-first.instructions.md` 六类契约）
> + 强制装置（立即断言进 `check-contract` 计数），参照 `serialize-at-retire.md` 分阶段模式。
> 验证策略：cycle-exact 全程不适用（拍数必变）；护栏 = focused TB + checker + 全量 module TB
> + 大节点 tohost 回归；全状态 difftest 按既定策略留到重构整体收口。

## 1. 目标形态：两类边界，显式化而非直线化

- **弹性边界**（队列解耦，保留）：Fetch→Decode（`OooFetchPacketFifo`）、Dispatch→Issue
  （`OooIntIssueQueue`/`OooFpIssueQueue`）、Execute→Commit（`OooRob`）。
- **刚性边界**（一拍寄存，提取对象）：藏在功能模块内部的 stage 寄存簇。

## 2. 现实基线（2026-07-08 全 RTL 侦查实测——治理前必读的校正）

**关键事实：四条候选刚性边界里只有一条真的存在打拍。**

| 候选边界 | 实测现状 | 治理动作分类 |
| --- | --- | --- |
| EX→WB | **唯一真实 stage 寄存簇**：`OooIntBackend.v` `ex0/ex1_*_q`（valid1+rob4+pdest6+result64+exception1+cause5+tval64 = 145b/lane ×2）。无条件每拍写、无 stall 保持（下游 ROB wb 口恒收）、flush 单臂清、kill 不清（晚到 wb 由 ROB squash 吞）——语义就是 down_ready≡1 的退化 PipeStageReg | **提取**（第一刀，最机械） |
| Decode→Rename | **零寄存融合拍**：`OooAluDecodeBackend`/`DecodeStage` 全组合（0 个 posedge 块），上游最近寄存是 PacketFifo | **重新流水化**（插寄存=新增流水级，改 IPC，须单独决策） |
| Rename→Dispatch | **零寄存融合拍**：rename map 读/freelist/busytable 全组合同拍写入 IQ/ROB 阵列；`OooDispatchBackend` 仅 kill_valid_q/kill_idx_q 一对破环寄存 | 同上 |
| Issue→RegRead→EX | **零寄存融合拍**：IQ 出队组合直通 PRF 读→ALU→ex_q，且存在 dispatch→issue 同拍 bypass；全核最深组合锥 | 同上（且触碰唤醒时序，风险最高） |

**推论**：①"提取"类动作语义中性可先行；②"重新流水化"类动作是微架构变更（改变 IPC、
唤醒/前递时序、kill 窗口位置），每条必须走独立 spec + 用户决策，本 spec 只冻结其边界
定义与契约模板，不排期。

**弹性边界现状要点**（契约核对底稿）：
- `OooFetchPacketFifo`：4 packet 裸存储原语，**无内生 valid/ready**——enq/pop/clear/seed
  全由 `OooFetchFlowControl`（纯组合策略）+`OooFetchPacketSeedMux` 外部决策；FIFO 空时有
  0 拍 bypass 直通臂；clear 只复位指针不清 payload。
- IQ：**压缩式队列**（每拍全阵列 `*_next_r` 组合重算+整体重写）+ wakeup CAM +
  dispatch→issue 同拍 bypass + kill 按 ROB 环形 age 清 younger 后缀（kill 拍存活前缀仍
  吸收当拍 wakeup——死锁教训已注释实锤）。**这是调度器不是 PipeStageReg，不做提取。**
- ROB：2 条/拍反向 walk 恢复 + recover 窗口吸收 in-flight wb + 不借当拍 commit 槽。
- 纯组合胶水模块（0 posedge，可自由 keep_hierarchy 不动寄存器）：`OooAluDecodeBackend`、
  `OooAluCoreSlice`、`OooExecuteBackend`、`OooCoreTopGlue`、`OooFetchHeadPairGate`、
  `OooDispatchBackend`（除 kill 一对）。

## 3. PipeStageReg 原语契约（已落地：`vsrc/pipeline/PipeStageReg.v` + `tb_pipe_stage_reg`）

六类契约映射：
- **①握手**：`up_ready_o = !valid_q || down_ready_i`（ready 组合依赖 valid/下游 ready 合法，
  不依赖 up_valid_i——结构上无 valid↔ready 组合环）；payload 整拍冻结随 fire 装载。
- **②stall**：`down_ready_i=0` 时 valid/payload 整拍冻结（PSR-HOLD 立即断言）。
- **③flush**：`flush_i`（nuke 族）与 `kill_i`（投机 squash 命中）分端口清 valid、payload
  留脏（全核 valid-only 惯例）；flush 同拍压过装载；后一拍必空（PSR-FLUSH-EMPTY 断言）。
- **④⑤**：原语不承载异常序/访存序——它们是使用方（ROB/SQ）契约。
- **⑥单一真源**：原语不解析 payload；**rob_idx 年龄比较必须留在使用方**，kill_i 只接受
  已判定的单 bit 结论（F2 kill 窗口逃逸家族：移动打拍点=移动 kill 窗口，每条边界改造前
  核对 kill 覆盖是使用方义务）。
- 参数化 WIDTH 合法（iEDA 只对参数化 blackbox 报错，本模块不是黑盒）；自带
  `(* keep_hierarchy *)`（实测 iverilog14/verilator5 零告警容忍，穿透 `$paramod` 派生）。
- skid-buffer 变体（切断 ready 组合链）按需另立模块。

## 4. 分阶段实施

| 阶段 | 内容 | 判定 |
| --- | --- | --- |
| P0（本轮已完成） | 本 spec 冻结 + PipeStageReg 原语 + focused TB + yosys `KEEP_HIERARCHY_MODULES` 机制接入 | TB PASS；机制 PoC 全通过 |
| P1（**2026-07-08 已完成**） | **EX→WB 提取第一刀**：`OooIntBackend` 的 ex0/ex1 簇替换为两个 `PipeStageReg #(.WIDTH(144))` 实例（valid 由原语持有，payload 144b/lane）。原 always 各赋值臂等价改写为组合 up_valid/up_payload 生成（"功能模块退化为纯组合+写入下一级寄存器"目标形态）；mem_pending/AMO FSM 共用 always 块原地不动。down_ready 接常 1（ROB wb 口恒收的现状语义），kill_i 接常 0（现状：kill 不清 ex_q），flush_i 接 `flush_i\|\|checkpoint_restore_i`（原 flush 臂等价）。原"未命中臂写全 0 payload"语义不保留（valid=0 拍 payload 留脏，已核对无 valid=0 读 payload 消费点）。原语自带 PSR-HOLD/PSR-FLUSH-EMPTY 断言随 CORE_SRCS 进 check-contract 计数（+2） | focused TB（tb_ooo_int_backend）PASS + 全量 module TB 85/85 + lint + check-contract（tohost 回归留给重构整体收口） |
| P2（**2026-07-08 已完成**） | **FP exec1 簇提取**：`OooFpBackend` exec1_*_q（valid1+payload 81b，带 IQ 反压占用语义）替换为 `PipeStageReg #(.WIDTH(81)) u_exec1_stage`。payload 布局 `{rob[80:77], pdest[76:71], dst_gpr[70], dst_en[69], value[68:5], fflags[4:0]}`。端口契约：flush_i=`flush_i`（recover/checkpoint 不清 exec1——与 IntBackend 不同的现状语义）、kill_i=`exec1_kill_w`（年龄比较留使用方，rob 取 down_payload 位段）、up_valid_i=`issue_fire_w && issue_is_comb_w`、down_ready_i=`!arith_out_valid_w`（唯一阻塞源=arith 完成仲裁优先）、**up_ready_o 悬空**——issue_ready_w 保留 `!exec1_valid_q` 项（现行反压比原语 up_ready 更严，语义中性提取不做省 1 拍微优化）。消费点经 `exec1_*_q` 位段别名 wire 零文本改动；原 flush 清零 payload 变留脏安全（全消费点经 exec1_take_w/exec1_valid_q 门控）。done FIFO（同 always 块但 next-state 零交叉）与 long meta/hold 簇（两相写违反单装载契约）、`OooFpArithGate` 多级 meta 链（kill 前视耦合）**不提取**——exec1 是本模块唯一可提取纯流水簇 | tb_ooo_int_backend PASS + 全量 module TB 85/85 + lint + check-contract（计数 17 不变：PSR 断言按文件计，P1 已计入） |
| P3（**2026-07-08 机制完成+首批数据**） | keep_hierarchy 全核对照实验：7 大模块 keep 下 ABC **分模块独立 mapping 实锤**——`OooMemAxiBridge` 66034 gates/area 131k/delay 45、`OooFetchAxiBridge` 93412 gates/area 175k/delay 50（两 cache 控制逻辑 stdcell 成本首次量化）。**发现并修复哈希 paramod 漏保**：参数值长时 yosys 用 `$paramod$<hash>\Mod` 形态（模块名在末尾），原 glob 尾部强制 `\*` 匹配不上致 7 keep 5 漏——yosys.tcl setattr 补 `=*\$module` 后缀 pattern（小例 PoC 验证）。**修复版全核综合 4670s 跑通**(此前 flatten 全核 6000s×2 timeout)：ABC 分 10 块独立 mapping——IntBackend 95250 gates/197k area/delay 89、FetchAxiBridge 93412/175k/50、MemAxiBridge 66269/132k/47、FpBackend 50545/107k/**90**、IntIssueQueue 30656/55k/27、Rob 15230/46k/14、Frontend 14497/27k/37、NpcTop 剩余 59395/113k/61、PipeStageReg×2 各 5 gates；总 stdcell 面积 ~855k(不含 4 黑盒宏)。关键路径大户=IntBackend(89)/FpBackend(90)——与"Issue→RegRead→EX 全核最深组合锥"侦查结论互证。宏合同 checker 新网表全 PASS+iEDA 兼容 PASS。`OooFpArithGate` 内部子模块化仍单独立项 | **全核综合首次闭合** |
| P4（**2026-07-09 切消费点完成**） | **flush 单点化——fetch 侧 redirect PC 单真源落地**（见 §5）：shadow 全绿（86 TB+riscv 177+AM+CoreMark 全程 OOO_ASSERT 零 fire）后一次切齐——`OooRedirectArbiter` 转正（生产实例迁 `OooFrontend`，trap 口=E1>E5>E6 pre-mux age0 / branch 口=E3 真 rob_idx / direct 口=E4 head−1 哨兵）；`OooFetchRequestMux` 三元链删除（赢家透传+core_branch_resolve 兜底，valid 成员集不动）；`OooFetchPcOutstandingSequencer` E1/E3/E4/E5/E6 六处 PC 写删除（记账全保留，含 :263 系 override 臂记账），换文本最后唯一 arb 终写；E7/E8/E9 排除集臂原样保留（新增 INV-3c 钉互斥）。GAP-2 甲门删除=唯一行为变化面（全 flag=0 负载不可达，INV-3b 0 fire 实证，升格哨兵）；GAP-1 双落点由构造消灭。glue shadow 段删除（NUKE-SRC-EQ 保留钉 nuke 源）；断言基线 21→20。刀 0 前置探针（mux E4 链 vs direct_fire_succ 两平行编码，shadow 未覆盖点）module TB 86+CoreMark 零 fire 后才动刀。后端 kill/nuke 通道零触碰（arbiter kill_idx/reason/flush_backend unused-sink） | ✅ fetch 侧完成。验证=focused TB 重写 PASS+module TB 86/86+lint 双变体+check-contract 20≥20+负测试（错接 arbiter branch 口 pc 源 INV-1 623 fire→复原 0 fire）+切换后 CoreMark 0xfcaf/0.966 持平零 fire；大节点回归（riscv/AM/linux-mini）主控统一跑。**GAP-4 后端扁平 OR 收敛（消费 kill_idx/reason/flush_backend）另立刀**；E2/E5-head0 支 flag=0 零 exercise 照旧 |
| P5+ | "重新流水化"类边界（Decode→Rename 等）按独立 spec 逐条决策 | 每条独立 spec+用户拍板 |

## 5. flush 单点化路线（搭车项，输入已由侦查冻结）

权威契约已存在：`design/specs/ooo-flush-redirect-contract.md`（13 事件族/7 汇合点，
2026-07-05 冻结仍在维护）。本治理的增量：

- **输入清单** = 契约 13 事件族（活 8/休 2/半死 2/死 2）；**输出挂接点** = 现成两级 OR 漏斗
  `OooCoreSliceControlGate`（core_local_flush）与 `OooMemoryRequestGate`（mem_flush）。
- **仲裁语义 = 年龄律**（`age = rob_idx − rob_head` 环形 argmin 单赢家）——宪法裁定，
  静态优先编码初稿已被 history/b2 §3.2 否决。
- **可复活资产（2026-07-08 已复活）**：`OooRedirectArbiter.v`（13 例年龄律 TB 全绿，因未
  接线于 2026-07-03 删档）现已原样回填 `vsrc/control/`，连同 `REDIR_REASON_*` 宏（define.v）、
  `RTL_OOO_REDIRECT_ARBITER`（filelist.mk，经 FRONTEND_HELPERS 进 RTL_CORE_SRCS）与
  `tb_ooo_redirect_arbiter`（testbench）。
- **切换路径 = assert-then-converge + shadow-equivalence**（big-bang 判死史：控制面一把
  点火曾致全活锁）：复活 arbiter 并行计算赢家 → 每拍断言与现行散落逻辑等价 → 全绿后
  才切消费点。**✅ 2026-07-09 fetch 侧切换完成**：arbiter 生产实例在 `OooFrontend`
  （放 glue 会造 frontend→glue→frontend 跨层组合往返，撞 UNOPTFLAT 家族）；commit
  家族（E1/E5/E6 同 age0）家族内序 pre-mux，arbiter 只仲裁家族间。
- **三条铁律不进 arbiter**：committed store 不可清（SQ survive_r 自治，INV-4 已断言）、
  已发 AXI 只能 drain（nokill 事务层旁路与控制流仲裁保持两层分离）、CSR commit 拍即
  架构可见不可撤。E11 mmu_flush 与控制流正交、E10 是掩码非清除，均不并入。
- ~~最大 plumbing 缺口：取指侧无 age 字段~~ ✅ 已由 direct 口 head−1 哨兵构造式消解
  （direct 恒最年轻的语义忠实编码，age=2^W−1 是保守表示；age15 平手拍不可达——分支占
  head+15 ⟹ ROB 满 ⟹ 无 dispatch ⟹ 无 direct fire）。
- ~~已知序缺陷 GAP-2~~ ✅ 已由年龄律修复（甲门删除；flag=0 负载不可达实证 INV-3b 0 fire，
  flag=1 哨兵在位）。**剩余=GAP-4 后端扁平 OR 收敛**（arbiter kill_idx/reason/
  flush_backend 输出现为 unused-sink，消费它们 = 下一刀）。

## 6. 综合侧兑现（已实测的机制）

- 主机制：RTL `(* keep_hierarchy *)`（PipeStageReg 已自带）；
- 辅机制：`KEEP_HIERARCHY_MODULES` 环境变量（yosys.tcl，与 SYNTH_BLACKBOX_MODULES 并列；
  **必须先 `hierarchy -check -top` 再 setattr**——read_verilog 后直接 setattr 落在 AST
  占位上会被 paramod 重派生丢弃，实测负结果）；
- 端到端已验证：层次活到最终网表，ABC 对 keep 模块**分别抽取映射**（cone 切割机制成立），
  iEDA STA 读层次化网表兼容（link 时自动展平）。
- 代价：边界阻断跨界常量传播（这正是目的），未用位不被跨界剪除，面积可能微涨；
  同参数多实例共享单一综合实现（需 per-instance 优化时后接 uniquify）。

## 7. 雷区（本工程特有，来自 memory 的失败史）

1. **kill 窗口逃逸家族**（F2 八轮失败史）：移动级间打拍点=移动 kill 窗口，涉投机边界
   改造前必须核对 kill 覆盖；
2. **"队头=序安全"不变量腐蚀家族**（LSQ 教训）：Issue/Mem 侧边界重排必读；
3. **cycle-exact 不适用**：拍数必变，禁以周期数为回归判据；
4. IQ 压缩队列/ROB walk/PacketFifo bypass 臂是**调度器语义**不是流水寄存，禁套原语；
5. PacketFifo clear 不清 payload、IQ kill 拍存活前缀吸收 wakeup、ROB recover 窗口吸收
   in-flight wb——三条"看似可简化实为承重"的现状，动前先读对应注释与 TB。

## 8. 变更记录

- 2026-07-09（P4 切消费点完成）：`OooRedirectArbiter` 转正为 fetch 侧 redirect PC 单真源。
  刀 0（探针）：OooFrontend 加 mux-vs-succ 探针断言（mux E4 链与 direct_fire_succ 两平行
  编码、shadow 未覆盖点），module TB 86/86 零 fire（前件非真空自证 1 hit）+ CoreMark 10
  迭代零 fire（0xfcaf）。刀 1（一次切齐，mux/seq 同批禁分切）：arbiter 生产实例迁
  OooFrontend（commit 家族 E1>E5>E6 pre-mux + branch 口 untracked_redirect/真 rob_idx +
  direct 口 e4 构造式/head−1 哨兵；kill/reason/flush_* unused-sink 留 GAP-4）；
  RequestMux 三元链删除（赢家透传+默认兜底，valid 成员集不动=禁止项①）；Sequencer 六处
  PC 写删除（E1/E3/E4/E5/E6，记账全保留=禁止项②，:263 系臂记账尤然）+ 文本最后唯一
  arb 终写 + INV-2 重写 + INV-3c 新增；GAP-2 甲门删除（唯一行为变化面，INV-3b 全负载
  0 fire 实证不可达，INV-3/INV-3b 升格哨兵）；glue shadow 段删除（SHADOW-EQ-NUKE 保留
  改名 NUKE-SRC-EQ）；INV-1 改口径（arbiter branch 口守卫）；断言基线 21→20。
  Sim 观测层：MuxChecker 重写（单源透传守卫）+ MuxFacts 缩 2 档、MergeChecker 退役
  （INV-M1 由单源构造给出）、SeqChecker INV-S1/S2 保留（csr_trap_target XMR 迁
  u_frontend 作用域）。TB：tb_ooo_fetch_request_mux/tb_ooo_fetch_pc_outstanding_sequencer
  按「记账臂+arb 终写」口径重写，tb_ooo_redirect_arbiter 13 例不动。
  验证：focused TB PASS、module TB 86/86、lint 双变体零告警、check-contract 20≥20、
  负测试（错接 branch 口 pc 源→INV-1 623 fire→复原 0 fire）、切换后 CoreMark
  0xfcaf/0.966 持平全断言零 fire。大节点回归主控统一跑。
- 2026-07-08（P2/P3/P4）：P2 FP exec1 簇提取落地（WIDTH=81，kill 年龄判定留使用方，issue_ready 保留 !exec1_valid_q 项零拍数变化）；P3 keep_hierarchy 全核首批数据 + 哈希 paramod glob 修复；P4 shadow RedirectArbiter 复活接线（S1-S4①），SHADOW-EQ-PC/KILL/NUKE + INV-3b 断言基线 12→21，负测试 15 fire→复原 0 fire，riscv-tests 177/CoreMark 全程 OOO_ASSERT 零 fire=等价证据。切消费点（拆 Sequencer/RequestMux 双机制）为 shadow 全绿后的独立后续。

- 2026-07-08：spec 冻结（四路侦查基线）；PipeStageReg 原语 + tb_pipe_stage_reg 落地；
  yosys KEEP_HIERARCHY_MODULES 机制接入。P1（EX→WB 第一刀）待开工。
- 2026-07-08（P1 落地）：`OooIntBackend` ex0/ex1 EX→WB 簇提取为 `u_ex0_stage`/`u_ex1_stage`
  两个 `PipeStageReg #(.WIDTH(144))` 实例。payload 位段布局（两 lane 一致，
  rob4+pdest6+result64+exc1+cause5+tval64）：
  `{rob_idx[143:140], pdest[139:134], result[133:70], exception[69], cause[68:64], tval[63:0]}`。
  端口契约：flush_i=`flush_i||checkpoint_restore_i`、kill_i=1'b0、down_ready_i=1'b1。
  原 always 装载臂等价改写为组合 `exN_up_valid_w`/`exN_up_payload_w`；下游 wb mux 经
  `exN_*_q` wire 别名（PipeStageReg 输出位段）零文本改动。既有 lane 不对称原样保留：
  ex1 的 exception=issue1_mem_exception_w 不被 sq_fwd 压 0（ex0 的 sq_fwd 臂 exception 恒 0）。
  `RTL_PIPE_STAGE_REG` 进 `RTL_CORE_SRCS` 与 `TB_OOO_INT_BACKEND_SRCS`；check-contract
  断言计数 12 基线→当前 17（本刀 +2 = PSR-HOLD/PSR-FLUSH-EMPTY ×1 文件计）。
  验证：tb_ooo_int_backend PASS、全量 module TB 85/85、`make lint` 零告警、check-contract PASS。
- 2026-07-08（P2 落地）：`OooFpBackend` exec1 簇（组合类 FP op 的 1 拍 stage 寄存，
  valid1+81b payload）提取为 `PipeStageReg #(.WIDTH(81)) u_exec1_stage`。
  payload 位段：`{rob[80:77], pdest[76:71], dst_gpr[70], dst_en[69], value[68:5], fflags[4:0]}`。
  端口契约：flush_i=`flush_i`（无 recover 项）、kill_i=`exec1_kill_w`（环形 age 比较留使用方）、
  up_valid_i=`issue_fire_w && issue_is_comb_w`、down_ready_i=`!arith_out_valid_w`、
  up_ready_o 悬空（issue_ready_w 保留 `!exec1_valid_q` 现行反压——比原语更严，语义中性）。
  kill/装载互斥双重保证：IQ issue_valid 被 kill/flush 拍压制 + 装载需 !valid 而 kill 需 valid。
  原 `:853` 共用 always 块只剩 done FIFO（双方 next-state 互不引用新值，干净分离）。
  Makefile/filelist 零改动（PipeStageReg 已在 RTL_CORE_SRCS 与 TB_OOO_INT_BACKEND_SRCS）；
  断言计数 17 不变（按文件计）。
  验证：tb_ooo_int_backend PASS、全量 module TB 85/85、`make lint` 零告警、check-contract PASS。
- 2026-07-08（P4 shadow 阶段落地）：flush 单点化 assert-then-converge 第一步。
  S1 复活：`OooRedirectArbiter.v`/`tb_ooo_redirect_arbiter.sv` 逐字节等同删档前版本回填，
  `REDIR_REASON_*` 9 宏回 define.v 占位处，filelist（经 `RTL_OOO_FRONTEND_HELPERS` 进
  RTL_CORE_SRCS 与全部 glue 系 TB）+ testbench Makefile 接线，13 例 TB 原样全绿。
  S2 plumbing（纯增量端口）：`rob_head_idx_o` 经 OooIntBackend→OooAluDecodeBackend→
  OooAluCoreSlice→OooExecuteBackend 四层透传至 glue（侦查报告预估 2 文件，实际层次多两层——
  AluDecodeBackend/AluCoreSlice 为不可绕过的中间 wrapper）；OooFrontend 新增
  `e4_redirect_{valid,pc}_o`（照抄 Sequencer :124-129 装载臂的组合构造式）。
  S3 shadow：glue 文末 `ifdef OOO_ASSERT` 段=commit 家族 pre-mux（E1>E5>E6 照 Sequencer
  文本序；E6-jump 臂目标忠实镜像前端死硅 tie-0）+ GAP-2 甲门（`!branch_resolve_untracked_w`
  raw 版镜像 :178 arm-taken 抢占）+ shadow arbiter 实例（trap 口喂 rob_head/age0、direct 口
  喂 head-1 哨兵/age 最大）+ 赢家寄存（复位域镜像 seq 的 rst||flush_i）+ 三断言
  （SHADOW-EQ-PC 主证据/SHADOW-EQ-KILL 同拍 E3/SHADOW-EQ-NUKE 晚 1 拍 nuke 镜像，
  E7/E8/E9 臂排除谓词）；INV-3b（GAP-2 乙，监测型）落 OooControlPlane INV-3 旁。
  断言计数 17→21（+3 glue +1 ControlPlane），基线文件同步升 21。
  S4①负测试：临时错接 branch 口 pc 源（core_branch_resolve_pc_w）→ tb_ooo_sv39_boot
  15 次 SHADOW-EQ-PC fire（恢复后 0 fire）；证据存
  `.github/task-runs/2026-07-08-stage-boundary-p4-shadow-arbiter/s4-negative-test-evidence.log`。
  验证：tb_ooo_redirect_arbiter 13 例 PASS、全量 module TB 86/86、`make lint` 零告警
  （含 +define+OOO_ASSERT 变体）、check-contract PASS（21≥21）。
  S4② 大节点回归（riscv-tests 177/AM/CoreMark 10 迭代/sv39/linux-mini tohost，全程
  OOO_ASSERT）由主控统一执行，是切消费点的前置门槛；E2/E5-head0 支零 exercise 的
  幸存者偏差照契约 §0 如实标注。
