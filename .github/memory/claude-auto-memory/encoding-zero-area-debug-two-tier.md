---
name: encoding-zero-area-debug-two-tier
description: "编码/状态机化≈面积中性(EDA自动处理)→\"是否值得\"是软件工程非PPA问题;debug两分类物理归属;真FSM vs组合仲裁值得性判据"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 4ec33c7a-397d-4c3b-bd57-9ff028f7f9bb
---

rv64 核 debug/observability 与状态机编码方法论(2026-07-06 长讨论沉淀)。**权威文档=`npc/rv64/design/specs/ooo-debug-observability-architecture.md`**(新会话接续入口)。

**编码≈面积中性(核心论证)**:①纯组合仲裁编码=重命名,综合 flatten+布尔优化消掉中间 wire/encode-decode 对,门级网表逐门一致(EDA 自动解决);②真 FSM 状态编码不增寄存器(前提:显式状态位数≤隐式占用位数;fsm_recode 自动权衡 binary/one-hot);③悬空 debug 端口被 DCE→可慷慨引出零成本,例化不接=综合零面积、仿真侧接=可观测;④⚠张力:纯重命名零面积但不排除非法态,收紧非法态改逻辑(但收紧的是不可达态,行为不变+面积反降)。→"是否值得"从 PPA 降为"重构工作量+重写风险⟷可维护收益"软件工程问题。

**⚠Moore/Mealy 陷阱**:状态机化把 Mealy(组合直通,当拍即输出)误做成 Moore(decode(state_q),晚一拍)会改 cycle 行为→difftest 抓。等价重命名必须保持原 Moore/Mealy 时序。

**debug 两分类(物理归属禁混)**:(1)符合 spec 的 FSM 转移验证接口→.sv checker→SIM_TOP_SRCS(DCE 零面积,断言转移落合法表);(2)开放给 OS 的内部信号→可综合 debug IP(RISC-V Debug Module/HPM/trace)→RTL_CORE_SRCS(面积必要,架构 feature)。

**三层观测模型(2026-07-06 续讨论深化 (1) 类)**:观测≠收束 RTL 信号,而是旁挂**独立于电路真实编码的抽象状态层**。① RTL 真实编码(one-hot/散 wire,综合参与,爱怎么实现怎么实现)/ ② 投影层(读①真实信号→映射抽象态,.sv/DCE,不综合)/ ③ 外部抽象状态映射(枚举+语义+合法转移,common .vh,不综合)。**③ 独立于 ①**(类比 ISA vs 微架构:debug 读抽象态"DRAINING"非电路位"drain_cnt=3");one-hot 是①实现自由非③议题;packed bus(OooSlotFacts)是①层 RTL 收束、与③旁挂不同别混。**自解释编码取消独立映射表**:学 RISC-V 字段化(编码结构↔语义结构同构),用/维护/查阅同一份,禁裸数值枚举(否则外部表复活漂移)。漂移由②投影出的转移落③合法表校验、否则(1)类断言 $error(运行时抓死,"断言守护的投影")。③可 architecture-first 先冻结(interface-contract-first §3 该填的格子)。纯组合投影不 latch→§1 Moore/Mealy 陷阱不适用(那是真 FSM 样板才防)。

**值得性判据**:第一刀=真 FSM(跨拍转移) vs 无记忆组合仲裁(后者只配 observability 投影,如前端 redirect winner)。值得编码=真 FSM+非法态致命+多 reg 交织+跨模块共享(GAP-7 病)+持续演进/反复出 bug。冻结稳定的别动(重写风险>收益即便面积免费)。候选真 FSM 热点:OooStopPendingSequencer / OooPendingTrapExitSequencer。

**XMR 可用(修正早期误判)**:NpcSimTop.sv:445-543 已用跨层次引用掏 33 核内部信号,Verilator 支持。故 .sv checker 可 XMR 直读内部信号零 plumbing(脆,死绑网名),或走 debug 端口(稳定 ABI、上板友好、逐层 plumb)。filelist 分组(RTL_CORE_SRCS vs SIM_TOP_SRCS)是强于 ifdef 的综合隔离。

**已落地并验证(2026-07-06)**:①GAP-3/7 内嵌断言 commit b94c57593,baseline=9。②**三层模型首个落地=前端 redirect 组合仲裁器 OooFetchRequestMux**:③ `vsrc/common/OooRedirectMuxFacts.vh`(11 档 one-hot 自解释表,忠实 RTL 真链)+② `vsrc/debug/OooRedirectMuxChecker.sv`(XMR `u_top.u_core.u_ooo_core.u_frontend.u_fetch_request_mux.*` 五层订阅→投影→INV-1 reserved 死态复活 / INV-2 untracked 优先级 pc 契约[`OooFrontend:1934` 依赖])+NpcSimTop XMR 例化+filelist 挂 SIM_TOP_SRCS。**验证**:干净 build(★PINCONNECTEMPTY 修法=**去空 output 端口改内部 wire+`_unused` sink**;--assert 下 `$error` 会中止如 $fatal,非真空探针须用 `$display`+`===1'b1` 排 @0 的 X)+riscv355/0+AM59/0 恒静默+非真空已验(CoreMark untracked 可达 126250×、pc 不变量 126250/126250;`$time` 恒 0 是 harness 伪影)。**★关键发现**:认真建 ③ 表逼出 §4.1 散文档失真——redirect 实为**组合 Mux(:66-82)+时序 Seq(OooFetchPcOutstandingSequencer,later-wins)两个物理分离仲裁器**、优先级多处相反(信号名/行号准但次序压平记反)=**观测层价值活标本**(人脑文档 vs RTL 真相漂移被逼出)。旧 `redirect_status`(OooRedirectStatus.v+Gate)探索已删=那是想 **latch 成 FSM**(错档);本次是**纯组合投影不 latch**(对档)。**§4.1 已照 RTL 双仲裁器正式改写**(组合 Mux first-match + 时序 Seq later-wins, 两器各列真实优先级+行号, Seq 优先级由其自带 INV-2 断言 :280-294 交叉印证)。**第二观测对象=时序 Seq checker 已落地**(`OooRedirectSeqChecker.sv`+`OooRedirectSeqFacts.vh`: XMR `u_frontend.u_fetch_pc_outstanding.*`; INV-S1 reserved 死态 `pending_jump_resolve_ready`[OooFrontend:1311 tie-0] + INV-S2 CSR_TRAP 全局最高**延迟一拍比较**——★时序件 later-wins 打拍, seen_q 与 next_fetch_pc_q 同延迟对齐处理 Moore/Mealy; 均核内自带 INV-2 只查 onehot0 未覆盖的独立真理; 非真空:csr_trap_mem=mem 阶段 trap[≠exec 的 csr_trap_ex], 经 `sv39-xpage-misalign` 可达、held; build 0warn+riscv355/0+AM59/0 恒静默)。★方法学坑:core-regress runner 不收 sim stdout→$display 探针须直跑单 bin 捕获; csr_trap_mem 罕见(仅 page/access fault)非常开。**第三观测=合并视图 checker 已落地**(`OooRedirectMergeChecker.sv`: 同时 XMR 两仲裁器; INV-M1 跨仲裁器一致性——`flush && untracked_redirect && !csr_trap` 时组合 Mux 当拍 redirect_fetch_pc == 时序 Seq 下拍 next_fetch_pc_q, 延迟一拍比较对齐; 把 §4.1 Seq:262 注释"两器一致"变运行时验证事实, CoreMark 前件 1417 次全一致)。**至此 redirect 三件套齐(Mux/Seq/Merge), riscv355/0+AM59/0 全静默、CPI 零影响、① 零改动。****规则固化已完成**:§5 三层模型+§5.6 断言纪律+8 条踩坑(XMR 五层/PINCONNECTEMPTY 去空端口/$display 探针法[--assert 下 $error 中止、core-regress 不收 stdout 须直跑单 bin]/时序件延迟比较/mem-vs-exec trap 语义/$time 恒 0/baseline 不计 SIM checker)写进 `interface-contract-first.instructions.md` 新节「外部抽象状态观测层」+ frontmatter。**至此 Debug/Observability 三层观测架构本轮闭环**(讨论→§5 沉淀→redirect 三件套落地验证→§4.1 双仲裁器校正→规则固化)。**剩**:真 FSM 编码样板(stop_pending/trap-exit,动 RTL,§3 判据+PPA 账)待议,属另一档。

关联 [[rv64-architecture-first-reflection]] [[rv64core-audit-baseline]] [[workspace-artifacts-not-tool-dir]]。
