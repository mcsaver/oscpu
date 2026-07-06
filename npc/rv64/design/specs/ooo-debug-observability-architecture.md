# OoO 核 Debug / Observability 架构规格

> 状态: **方案已敲定, 未落地**(讨论产物, 2026-07-06)。本文是新会话接续本主题的单一入口。
> 关联: [[ooo-flush-redirect-contract.md]] · [[interface-contract-first.instructions.md]] · decisions [39]

## 0. 本文缘起(讨论链, 一句话版)

从"把 GAP-3/7 flush 契约断言内嵌进 `.v`"出发, 用户质疑"内嵌 `$error` 是否与'底层可综合核 / 顶层仿真核'分离理念冲突", 讨论逐层深入, 最终收敛出三块可复用结论:
1. **编码/状态机化 ≈ 面积中性**(EDA 自动处理), 于是"是否值得"从 PPA 问题降级为软件工程问题;
2. **debug 必须分两类**, 物理归属不同(仿真验证接口 vs OS 可见 debug IP);
3. **状态机显式编码的值得性判据**(真 FSM vs 无记忆组合仲裁是第一刀)。

---

## 1. 编码零面积论证(理论基础)

用户主张、经批判性核对成立的四条:

1. **纯组合仲裁的"编码" = 重命名, 严格零面积。** 5 个组合信号相或/与打包成 bundle 或换中间表示, 综合 `flatten` + 布尔优化把中间 wire 名与 encode-decode 对一起消掉, 门级网表逐门一致。这类"编码"是 RTL 可读性重构, 硬件无感。
2. **真 FSM 的编码 = 状态机模型, 不增寄存器**——前提两条边界:
   - **信息量守恒**: 显式状态位数 ≤ 隐式实现占用位数则寄存器数不变(`fsm_recode` 自动在 binary/one-hot 间权衡 FF 数 vs 译码深度)。
   - **⚠ Moore/Mealy 一致性(cycle 陷阱)**: "a2 阶段直接输出 a2 信号"是 Moore(`out=decode(state_q)`)。若原散信号是 Mealy/组合直通(满足进入条件的**当拍**即输出), Moore 化会**晚一拍** → cycle 行为变、difftest 抓到。状态机化必须保持原 Moore/Mealy 时序。
   - "网表一致"是理想化, 实际差几个门(综合启发式), 可忽略。**面积不构成反对理由。**
3. **悬空端口被 DCE → 可慷慨引出 debug 信号。** 未驱动 output / 空 fanout 被 DCE 零逻辑。模块可定义任意多 debug 端口, 例化不接 = 综合零面积, 仿真侧接 = 可观测。**引出零成本, 接入才有成本。**(caveat: 前提是该端口不被 `keep`/`dont_touch`、也非最终 top-level port; 对核内部模块 debug 端口成立。)
4. **张力: 零面积重命名 ⊥ true-by-construction 排除非法态。**
   - 纯重命名(严格等价) → 零面积, 但**没排除任何非法态**(只换名)。
   - 借显式化收紧非法态 → 严格说改了逻辑, 但收紧的是**可达性论证下本就不可达的态**, 砍掉不可达分支逻辑, 行为不变 + 面积**反降**几个门。
   - 两者能兼得但机制不同: 等价重排拿零面积, 不可达态收紧拿 bug-prevention。落地要分清哪块是哪种。

**结论**: 编码 ≈ 面积中性, 天平只剩 **一次性重构工作量 + 重写引 bug 风险 ⟷ 长期可读/可维护/可验证收益**。

---

## 2. Debug 两分类物理架构(本文核心, 任务敲定项)

debug 必须拆成两个物理归属不同的层, 禁混:

| | 分类 | 目录 / filelist 归属 | 综合 | 用途 |
|---|---|---|---|---|
| **(1)** | **符合 spec 的 FSM 转移验证接口** | `vsrc/debug/*.sv` → `SIM_TOP_SRCS` | **DCE, 零面积** | 开发期: 订阅模块 state / debug 端口, 断言转移落在 spec 合法转移表内 (`$error`/`$fatal`) |
| **(2)** | **开放给 OS 的 CPU 内部信号** | `vsrc/debug/*.v`(可综合) → `RTL_CORE_SRCS` | **必要且正当** | 运行期: RISC-V Debug Module(DM/DMI) / HPM 计数器 / 处理器 trace, OS·调试器读内部状态 |

### 2.1 (1) 验证接口层的落法

- **checker 是 `.sv`, 挂 `SIM_TOP_SRCS`**(filelist.mk:277 那组), 综合入口只吃 `RTL_CORE_SRCS`(Makefile:150), 故 checker 零面积。
- **被观测信号如何到达 checker**——两条既有范式二选一:
  - **XMR(跨层次引用)**: 现状已在用——`NpcSimTop.sv:445-543` 的 `debug_ooo_flags_o` 用 `u_top.u_core.u_ooo_core.<net>` 掏了 33 个核内部信号。**Verilator 支持且在用**(此点修正了讨论早期"XMR 支持有限"的误判)。零 plumbing, 但脆(死绑内部网名, 重构即断)。
  - **debug 端口引出**: 模块加 debug output(悬空即 DCE, 见 §1.3), checker 端口订阅。稳定 ABI, 上板友好, 但要逐层 plumb(OooCoreTopGlue→NpcCoreTop→NpcTop→NpcSimTop)。
  - 选择依据: 纯仿真守护用 XMR(省); 要形成上板可复用 ABI 的走端口。
- **checker 内容 = 状态合法域断言 + spec 转移表校验**。相比现状散落 RTL 的内联 `ifdef OOO_ASSERT` 断言(OooRob.v:512 / OooControlPlane.v / OooFrontend.v:1932 / ...), checker 迁走后可**删除内联断言, 核 `.v` 恢复绝对纯净**——这比内联 ifdef 更彻底(靠 filelist 分组隔离, 强于 ifdef)。

### 2.2 (2) OS 可见 debug IP 层的落法

- 可综合 `.v`, 进 `RTL_CORE_SRCS`, 面积是架构 feature 成本(debug spec 合规), 非可选观测开销。
- 范围: 只放 ISA/平台可见的(RISC-V Debug Module、HPM、trace encoder)。**不要**把开发期验证信号塞进这层。

### 2.3 端口引出约定(写进 interface-contract-first.instructions.md)

- 模块可慷慨定义 debug output(悬空 DCE 零面积), 但**每个 debug 端口后必须注释**其语义 + 归属((1)还是(2))。
- 控制状态优先走 `vsrc/common/` 编码库(仿 `OooSlotFacts.v`), **禁在数据通路中段拍一窝蜂组合信号** —— 但见 §3 的值得性判据, 此规则**仅适用于值得编码的真 FSM 热点**, 不是全核强制。

---

## 3. 状态机显式编码的值得性判据

**第一刀: 真 FSM vs 无记忆组合仲裁。**
- **无记忆组合仲裁**(每拍独立、无跨拍状态转移, 如前端 redirect winner): 强行"编状态机"拿不到 FSM 收益(无非法转移可防、无状态可门控), 只剩 observability 价值。→ **顶多做投影观测, 不做状态机化**。
- **真 FSM**(当前态决定下一态, 跨拍转移): 隐式实现(散 reg + 深 if-else)是非法态/漏转移 bug 温床。→ 显式编码 + 合法转移断言, 收益实打实。

| 维度 | 值得显式编码 | 不值得 |
|---|---|---|
| 有无记忆 | **真 FSM(跨拍转移)** | 无记忆组合仲裁 |
| 非法态危害 | **致命(死锁/数据损坏/控制分叉)** | 仅性能次优 |
| 状态结构 | **多 reg 交织的网状转移** | 3-4 态线性, 隐式已清晰 |
| 消费范围 | **跨模块共享语义(易多处镜像漂移, GAP-7 病)** | 单模块私有 |

**+ 最终诚实判据(因编码≈零面积, 决策维度是软件工程而非 PPA)**:
- 会**持续演进 / 反复出 bug** 的真 FSM 热点 → 值得重排式编码(未来每次改动都受益)。
- 已**冻结稳定**的 → 别动(重写风险 > 收益, 即便面积免费)。

**候选真 FSM 热点**(有跨拍转移、历史 bug 温床): `OooStopPendingSequencer`(SET→保持→drain→CLEAR, serialize-at-retire 死锁史) · `OooPendingTrapExitSequencer`(capture→drain→clear, GAP-6 出处) · `OooMemAxiBridge` 握手 · LSQ/SQ。**redirect 不在此列(非 FSM)。**

---

## 4. 探索记录: status encoding / redirect_status(已回滚)

- 讨论中曾建 `vsrc/common/OooRedirectStatus.v`(编码库) + `vsrc/frontend/OooRedirectStatusGate.v`(priority-encode 编码器), 想把前端 redirect 决策编码成 11 态枚举 + `is_architectural` 位, 承接 GAP-3/INV-1。
- **结论: 选错样板, 已删。** redirect winner 是**无记忆组合仲裁**(§3 第一刀), 非真 FSM——编码只有 observability 价值, 无状态机收益。其枚举设计(基于真实 mux 优先级三元链 `OooFetchRequestMux.v:66-82` + sequencer override 顺序 `OooFetchPcOutstandingSequencer.v:263/271`)记档备查: 若将来要一个"可打印的前端 redirect 观测面", 可作 (1) 类 observability 投影重建, 但**不作为 FSM 编码样板**。
- 真要立 FSM 编码样板, 应挑 §3 候选热点(stop_pending / trap-exit)。

### 4.1 redirect 真实互斥来源(observability 投影若重建时复用)

11 主态按真实优先级(高→低): `CSR_TRAP`(csr_trap_mem, Seq:271) > `TRAP_EXIT`(pending_arch_trap/ecall·irq·mret, Seq:219-232) > `CSR_COMMIT`(head0_csr_commit/pending_system_csr_commit, Seq:210-216) > `BR_MISPREDICT`(branch_resolve_untracked, Mux:70/Seq:263, 当前唯一活的 younger-branch 修正) > `PENDING_BRANCH`(Seq:151-177) > `BRANCH_SPEC`(legacy, Mux:60) > `DIRECT_JUMP_SPEC`(Mux:71) > `DIRECT_JAL`(Mux:72) > `DIRECT_RET`(Mux:73-75) > `DIRECT_BRANCH`(Mux:76-78) > `NONE`(Mux:84-87 兜底)。+ reserved 死态 `PENDING_JUMP`(D1 tie-0 @ OooFrontend.v:1317-1318; 复活即 GAP-3 违约暴露点)。`is_architectural = (态 ≤ PENDING_BRANCH)`。无 age 比较器: 仲裁靠 mux 优先级链(higher-tier-wins) + seq nonblocking 文本覆盖(later-wins) 手工对齐。

---

## 5. 当前代码状态 + Next-steps(给新会话)

### 已落地(本会话前半段, flush GAP 收口延续)
- **GAP-3 内嵌断言** @ `vsrc/frontend/OooFrontend.v`(INV-1 ifdef 块内, mux `direct_redirect_fetch_w && !direct_frontend_flush_w` → `$error`)。
- **INV-7(GAP-7) 内嵌断言** @ `vsrc/control/OooControlPlane.v`(INV-3 ifdef 块后, `pending_system_capture_head0_w && !inv7_seq_head0_system_set_w` → `$error;$fatal`; oracle 是 capture_head0 前件宽松超集, `capture_head0⟹oracle` 恒真, 故恒静默不假阳)。
- Verilator build(带 `+define+OOO_ASSERT`) 已通过。`$error` 计数 7→9。
- **⚠ 待完成**: 全回归验证恒静默 → baseline `eval/contract-assert-baseline.txt` 7→9 → commit。(本会话已后台起 `eval/npc-eval.sh --all`, 结果见收尾。)

### 已回滚
- `OooRedirectStatus.v` + `OooRedirectStatusGate.v` 已删(§4)。

### Next-steps(优先级序)
1. **收尾 GAP-3/7**: 回归绿 → baseline 7→9 → commit。(最小、独立、零风险)
2. **debug 两分类骨架**: 新建 `vsrc/debug/`, filelist 加 `RTL_DEBUG_DIR` 挂 `SIM_TOP_SRCS`(仅仿真侧先行, §2.1)。
3. **立第一个真 FSM 编码样板**: 挑 `OooStopPendingSequencer` 或 `OooPendingTrapExitSequencer`, 按 §3 判据 + §1 Moore/Mealy 陷阱 + 不可达态收紧, 做一次"值得性 + PPA 账"的具体推演再定是否重排。每步差分回归数字不变。
4. **规则固化**: §2.3 端口约定 + §3 判据写进 `interface-contract-first.instructions.md`(**只规范"值得的真 FSM 热点", 不定全核强制编码**)。

### 复用现有基础设施
- XMR 采集范式(`NpcSimTop.sv:445-543`) · 常开 commit/trap/exit ABI(OooCoreTopGlue→NpcSimTop) · filelist 分组(`RTL_CORE_SRCS` vs `SIM_TOP_SRCS`, 强于 ifdef 的综合隔离) · `vsrc/common/OooSlotFacts.v` 编码库范式。
