# OoO 核 Debug / Observability 架构规格

> 状态: **三层观测模型定型(§5) + redirect 双仲裁器观测三件套(Mux/Seq/Merge)落地并验证 + 规则固化完成**(2026-07-06)。剩「真 FSM 编码样板(动 RTL)」待议。本文是新会话接续本主题的单一入口。
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

### 4.1 redirect 真实互斥来源(权威表, 2026-07-06 照两份 RTL 逐档改写)

> 本节原为「单一 11 主态优先级链」失真抽象(把组合 Mux + 时序 Seq 两个仲裁器压平、多处次序记反),
> 已于 2026-07-06 照 `OooFetchRequestMux.v`(组合)+ `OooFetchPcOutstandingSequencer.v`(时序)两份 RTL
> **逐档核实后改写为下表**(两仲裁器各列真实优先级 + 行号锚点, 可复核)。旧失真单链见 git 历史。

**redirect 由两个物理分离的仲裁器产生, 消费重叠条件集, 优先级机制不同(这是旧单链失真的根源):**

**(A) 组合 `OooFetchRequestMux`(:66-82) —— 取指 PC 组合选择, first-match(三元链自上而下), 纯 wire 当拍:**
`UNTRACKED`(:70, 后端 mispredict 真 target, 架构) > `DIRECT_JUMP_SPEC`(:71) > `DIRECT_JAL`(:72) > `DIRECT_RET`(:73, ret0/ret1) > `DIRECT_LANE1_RET`(:74) > `BRANCH_TARGET`(:76, 预测 taken 续取) > `BRANCH_FALLTHRU`(:77) > `DIRECT_BR_RESOLVE`(:78) > [`PENDING_JUMP` 死 :79-80] > `BRANCH_SPEC`(:81, legacy 最低有效档) > `NONE`(:82/84-87 兜底)。**已落地为 `common/OooRedirectMuxFacts.vh` + `OooRedirectMuxChecker`(§5.7)。**

**(B) 时序 `OooFetchPcOutstandingSequencer`(next_fetch_pc_q, :93-278) —— later-wins(文本后写覆盖先写), 打拍下一拍生效:**
`CSR_TRAP`(:271, 最后写=全局最高) > `UNTRACKED`-over-flush(:263, flush&untracked 高档) > [else-if 链 first-match: `PENDING_BRANCH`(:151/159) > `UNTRACKED`(:178) > [`PENDING_JUMP` 死 :188] > `CSR_COMMIT`(:210) > drain 臂(:217){`TRAP_EXIT`(arch_trap :219 / system ecall·irq·mret :223) > `PENDING_BRANCH`-late(:233) > [`PENDING_JUMP`-late :239] > `PENDING_MEM`(:250)}] > `BRANCH_SPEC`(:137) > `DIRECT` 组(:124, jal/ret/branch/jump_spec 四者 OR 进一个 if、无内部排序) > 顺序-base(:100)。此文本优先级由模块内 INV-2 断言(:280-294)守。**已落地为 `common/OooRedirectSeqFacts.vh`(粗粒度 tier)+ `OooRedirectSeqChecker`(INV-S1 死态 + INV-S2 CSR_TRAP 延迟比较, §6 item 3)。**

**两器关键差异(= 旧单链失真处, 逐条)**: ①`CSR_TRAP`/`PENDING_MEM` 是 Seq 独占态(不进 Mux); ②Seq else-if 链内次序是 `PENDING_BRANCH > UNTRACKED > CSR_COMMIT > TRAP_EXIT`——旧文档记成反向(但 `CSR_TRAP` 经 :271 override 仍全局最高, 与"链内 TRAP_EXIT 靠后"不矛盾); ③`UNTRACKED` 三处(Mux:70 最高 / Seq:178 链内 / Seq:263 flush 高档), 旧文档漏 :263 高档; ④`DIRECT_*` 组内排序**只在 Mux 可分辨**(Seq :124 一个 if 无序); ⑤`BRANCH_SPEC` 在 Mux 是最低有效档、在 Seq 居中(方向相反)。

**is_architectural**(后端解析/提交真值): {`CSR_TRAP`, `UNTRACKED`(含 :263 高档), `CSR_COMMIT`, `TRAP_EXIT`, `PENDING_BRANCH`, `PENDING_MEM`}; 投机(前端预测续取)={`DIRECT_*`, `BRANCH_TARGET`, `BRANCH_FALLTHRU`, `BRANCH_SPEC`}。(旧 `态 ≤ PENDING_BRANCH` 线性阈值在双仲裁器下不成立, 改列举。)

**reserved 死态 `PENDING_JUMP`**: 两路各自 tie-0——Mux 路 `pending_jump_nolink_commit`/`_redirect_after_dispatch` @ `OooFrontend.v:1317-1318`; Seq 路 `pending_jump_resolve_ready` @ `OooFrontend.v:1311`(均属 wave5b 死硅拆除块 :1298-1319)。复活 = GAP-3 违约暴露点(Mux 路已由 `OooRedirectMuxChecker` INV-1 断言)。

---

## 5. 外部抽象状态观测层：三层模型(2026-07-06 续讨论定型)

> 本节是 §2 (1) 类"面向 spec 的 FSM 转移验证接口"的**深化落地形态**。核心校正:
> 观测**不是收束 RTL 信号**, 而是**旁挂一个独立于电路真实编码的抽象状态层**。
> 早期讨论曾在「(a) 收束 RTL 散信号成 packed bus(动 RTL)」与「(b) 外部观测层(不动 RTL)」
> 间滑动, 本节钉死 **(b)**: 观测层零侵入电路。

### 5.1 encode / decode 对偶 + 自解释编码(取消独立映射表)

- **encode(收束/打包) 面向机器**: RTL 取某几位参与运算, **综合参与**(零面积, 但在数据通路上真实存在)。
- **decode(解读) 面向人**: 把位模式翻回抽象状态语义, 用途 debug / 优化分析, **综合不参与**。
- **自解释编码取消"独立映射表"**: **不**建"数值 N = 某态"的外部映射表(那必然两份、必漂移),
  而让**编码方式本身携带语义**——学 RISC-V 编码的精神: **编码结构 ↔ 语义结构 同构**
  (opcode 分大类、funct 细分, 读位域即读语义层次)。于是 **用(RTL 取位)/ 维护 / 查阅(人读)
  共享同一份真源**, 因为**编码即文档**。防漂移问题被**取消**(结构上只有一份), 而非被"管住"。
- **铁纪律**: 禁裸数值枚举(`4'b0101 = 某态` 一旦出现就需外部表来读它 → 两份复活)。
  编码必须结构化到"读位域即读语义"。
- **范式活证 = `OooSlotFacts.v`**: one-hot 位标志, `OOO_SLOT_FACT_BRANCH = 1` → **位名 = 语义
  = 位置三位一体**, 读 `bus[1]` 即知 is_branch, 无需任何外部表。FP 那组多位并存(`FP_ADDSUB`
  + `FP_DOUBLE` + `FP_GPR_WRITE` 同真)是"可并存属性簇"的活例。

### 5.2 三层模型(核心)

把"控制状态观测"彻底分三层, **③ 独立于 ①**:

| 层 | 是什么 | 面向 | 综合 |
|---|---|---|---|
| **① RTL 内部真实编码** | 电路物理表示: one-hot 位 / 散 wire / 稠密码, 按硬件最优(fanout/时序/译码深度) | 机器 | **参与** |
| **② 投影层** | 读 ① 真实信号 → 映射成抽象状态((1a) 人肉查表 / (1b) `.sv` function 打印) | 桥 | **不参与**(DCE) |
| **③ 外部抽象状态映射** | 抽象状态枚举 + 语义 + 合法转移表; 放 `common/`(或 spec) | 人(debug/优化) | **完全不碰** |

- **类比: ③ 之于 ① = ISA 之于微架构**。debug 时人读的是 **ISA 级抽象状态**("现在处于 DRAINING"),
  **不是微架构电路位**("drain_cnt=3 & stop=1 & inflight=0")。
- **one-hot / 稠密的选择是 ① 层的实现自由, ③ 层不管、不规定**。(早期把"互斥态铺 one-hot 还是稠密字段"
  当成 ③ 层议题是错的——那是 ① 层的事。)
- `OooSlotFacts.v` 那种 packed bus 是 **① 层的 RTL 内部收束**(动 RTL、零面积), 和 ③ 层旁挂观测**不是一回事**, 别混。
- **(1) 类的两个子形态**: (1a) 静态语义解码表(人查表, 纯文档零执行) / (1b) 可执行语义投影
  (`.sv` function 把值→字符串, waveform·log 自动显示)。(1b) 天然只能落 `.sv`(返回 string 是 SV,
  综合侧 `.v` 写不了)——**恰印证 §2 把 (1) 类物理归到 `SIM_TOP_SRCS`**。可先做 (1a)、无痛升 (1b)。

### 5.3 侵入归零

- 要的是"外部观测层(不动 RTL)", 纯旁挂"投影 + 断言", **不改数据通路一行**。
- one-hot 若出现是 ① 层实现自由, **不是我们这套要生产的 packed bus**。
- 正是 §3"无记忆组合仲裁 → **只做投影观测**、不做状态机化"的**字面落地**。
- 副产品: 全部落 `.sv` → `SIM_TOP_SRCS`(不进 `RTL_CORE_SRCS`), **不触发 interface-contract-first
  的"可综合 RTL"门槛**(那道门是给动综合 RTL 用的)。

### 5.4 漂移由断言守(不靠人工同步)

- 三层解耦后新漂移面 = **② 投影层**(① 改了、投影没跟 → 人读到错的抽象状态)。
- **但不靠人工同步**: 投影出的抽象状态**转移**必须落在 ③ 的**合法转移表**内, 否则 (1) 类 checker `$error`。
  漂移被**运行时**抓死。
- 所以"消漂移"目标在三层结构里从"用/维护/查阅同一份"**升级为"断言守护的投影"**:
  ③ 是真源, ② 的翻译被 ③ 的转移表当场校验。

### 5.5 契约先行(与 interface-contract-first 咬合)

- **③ 层天然是 architecture-first 产物**: 抽象状态 spec 是一份"抽象状态契约", 可**先于 RTL 冻结**
  (正是 `interface-contract-first.instructions.md` 里 §3 状态/时序模型该填的格子), 然后 ① 层 RTL
  用任意物理编码实现、② 层对齐。**③ 不是 RTL 的附属品, 是 RTL 要去满足的规格。**

### 5.6 物理落法(承 §2.1 / §2.3)

- **③ 抽象状态表**: `common/` 下 `.vh`, 自解释 one-hot 宏 + 行内语义注释(仿 `OooSlotFacts.v`);
  语义部分综合不参与。含**合法转移表 / 互斥约束**(供 ② 断言引用)。
- **② 投影 + 断言 checker**: `vsrc/debug/*.sv` → `SIM_TOP_SRCS`; XMR 订阅 ① 真实信号
  (复用 `NpcSimTop.sv` 现有 XMR 范式) → 投影成 ③ 抽象状态 → **时钟块立即断言**转移/互斥合法。
- **① 不动一行**。
- **断言纪律(承 interface-contract-first §"可执行形态")**: ① 非真空——每条断言故意制造一次违约确认它会响;
  ② 非同盲区——断言编码**独立于 RTL 的真理**(来自 ③ 抽象状态 spec 的合法转移 / ISA), 不是 RTL 逐句重述。

### 5.7 首个落地对象 = `redirect_status`(§4 废案翻案)

- **选它的理由**: ①无记忆组合仲裁, 正是 §3"只做投影观测"的对档首选; ②§4.1 已备真实互斥来源
  (2026-07-06 已照两份 RTL 改写为两仲裁器权威表: 组合 Mux 已落地、时序 Seq 待建); ③§4 回滚教训
  (错在想 **latch 成 FSM**)正好被这套"纯投影、不 latch"从根避开——把废案翻成现成输入。
- **落法**: ③ = `common/` 抽象态表(11 态 one-hot + `is_architectural` + reserved 死态 + 合法投影约束);
  ② = `vsrc/debug/` checker, XMR 订阅前端真实 redirect 仲裁信号 → 投影 → 断言(至多一态、
  `is_architectural` 与源态一致、reserved 死态永不出现)。① 前端 mux 优先级链**一行不动**。
- **纯组合不 latch → §1 Moore/Mealy 陷阱在此不适用**(那是真 FSM 样板才防的), 又一层零风险保证。

## 6. 当前代码状态 + Next-steps(给新会话)

### 已落地(本会话前半段, flush GAP 收口延续)
- **GAP-3 内嵌断言** @ `vsrc/frontend/OooFrontend.v`(INV-1 ifdef 块内, mux `direct_redirect_fetch_w && !direct_frontend_flush_w` → `$error`)。
- **INV-7(GAP-7) 内嵌断言** @ `vsrc/control/OooControlPlane.v`(INV-3 ifdef 块后, `pending_system_capture_head0_w && !inv7_seq_head0_system_set_w` → `$error;$fatal`; oracle 是 capture_head0 前件宽松超集, `capture_head0⟹oracle` 恒真, 故恒静默不假阳)。
- Verilator build(带 `+define+OOO_ASSERT`) 已通过。`$error` 计数 7→9。
- ✅ **已完成**: baseline `eval/contract-assert-baseline.txt`=9, commit `b94c57593`。(注: 该计数 gate 只数 `RTL_CORE_SRCS` 内联 `$error(`; §5 的 SIM_TOP checker 断言**不进此计数**, 靠回归恒静默验证。)

### 已回滚
- `OooRedirectStatus.v` + `OooRedirectStatusGate.v` 已删(§4)。

### Next-steps(优先级序, 2026-07-06 续更新)
1. ✅ **GAP-3/7 内嵌断言**: commit `b94c57593`, baseline=9。
2. ✅ **三层观测模型沉淀(§5) + 骨架 + `redirect_status`(组合 Mux)首个落地**:
   - `vsrc/debug/` + filelist `RTL_DEBUG_DIR`→`SIM_TOP_SRCS`(零综合面积, DCE);
   - ③ `common/OooRedirectMuxFacts.vh`(11 档 one-hot 自解释表, **忠实 RTL 真链、校正 §4.1 失真**);
   - ② `vsrc/debug/OooRedirectMuxChecker.sv`(XMR 投影 + 两条**独立真理**断言: INV-1 reserved 死态复活 /
     INV-2 untracked 优先级契约 `OooFrontend:1934` 依赖);
   - `NpcSimTop.sv` XMR 例化(`ifdef OOO_ASSERT` 门控)。
   - **验证**: 干净 build(0 warn) + riscv-tests 355/0 + AM 59/0 **恒静默** + 非真空已验
     (CoreMark untracked 前件可达 126250×, pc 不变量 126250/126250 成立)。**① 电路一行不动。**
3. ✅ **`redirect_status` 时序 Seq 仲裁器(第二观测对象)已落地**(§4.1 照 RTL 双仲裁器改写已完成 2026-07-06):
   - ③ `common/OooRedirectSeqFacts.vh`(粗粒度 tier: CSR_TRAP / UNTRACKED_OVER_FLUSH / OTHER, 细见 §4.1 B);
   - ② `vsrc/debug/OooRedirectSeqChecker.sv`(XMR `u_frontend.u_fetch_pc_outstanding.*` + INV-S1 reserved 死态
     `pending_jump_resolve_ready`(OooFrontend:1311 tie-0) + INV-S2 `CSR_TRAP` 全局最高延迟比较);
   - ★**时序件关键点**: Seq 是打拍(next_fetch_pc_q, later-wins), INV-S2 用【延迟一拍比较】正确处理 Moore/Mealy
     (seen_q 与 next_fetch_pc_q 同延迟对齐, 避免同拍读 reg 旧值)。这两条是核内自带 INV-2(:280-294, 只查 onehot0)未覆盖的独立真理。
   - **验证**: build 0 warn + riscv 355/0 + AM 59/0 **恒静默** + 非真空(csr_trap_mem 是 mem 阶段 trap,
     经 `sv39-xpage-misalign` 可达 1 次、延迟比较对齐、INV-S2 held; 该测试 HIT GOOD TRAP)。**① 电路一行不动。**
4. ✅ **合并两仲裁器统一视图(跨 Mux/Seq 一致性)已落地**: `vsrc/debug/OooRedirectMergeChecker.sv`(同时 XMR
   两个仲裁器 + INV-M1: 当 `flush && untracked_redirect && !csr_trap` 时组合 Mux 当拍 `redirect_fetch_pc` == 时序 Seq
   下一拍 `next_fetch_pc_q`, 延迟一拍比较对齐)。把 §4.1 Seq:262 注释声称的"两器一致"变成**运行时验证的事实**:
   CoreMark 前件可达 1417 次、1417/1417 全一致(静默)。验证: build 0 warn + riscv 355/0 + AM 59/0 恒静默。**① 电路一行不动。**
5. ✅ **规则固化已完成**: §5 三层模型 + §5.6 断言纪律 + 8 条工具链/方法学踩坑(XMR 五层 / `PINCONNECTEMPTY`
   去空端口 / `$display` 探针法[`--assert` 下 `$error` 中止、core-regress 不收 stdout 须直跑单 bin] / 时序件延迟比较 /
   mem-vs-exec trap 信号语义 / `$time` 恒 0 / baseline 不计 SIM checker 等)已写进 `interface-contract-first.instructions.md`
   新节「外部抽象状态观测层」+ frontmatter description。附已落地范例指路。
6. **(后续档, 动 RTL)真 FSM 编码样板**: `OooStopPendingSequencer`(honest FSM 散在 ≥3 模块, 高风险) /
   `OooPendingTrapExitSequencer`(自足, 有 GAP-6 oracle), 按 §3 判据 + §1 Moore/Mealy 做"值得性+PPA 账"。
   **排在观测层之后。**

### 复用现有基础设施
- XMR 采集范式(`NpcSimTop.sv:445-543`) · 常开 commit/trap/exit ABI(OooCoreTopGlue→NpcSimTop) · filelist 分组(`RTL_CORE_SRCS` vs `SIM_TOP_SRCS`, 强于 ifdef 的综合隔离) · `vsrc/common/OooSlotFacts.v` 编码库范式。
