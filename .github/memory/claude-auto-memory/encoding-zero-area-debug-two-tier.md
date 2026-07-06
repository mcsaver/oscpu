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

**值得性判据**:第一刀=真 FSM(跨拍转移) vs 无记忆组合仲裁(后者只配 observability 投影,如前端 redirect winner)。值得编码=真 FSM+非法态致命+多 reg 交织+跨模块共享(GAP-7 病)+持续演进/反复出 bug。冻结稳定的别动(重写风险>收益即便面积免费)。候选真 FSM 热点:OooStopPendingSequencer / OooPendingTrapExitSequencer。

**XMR 可用(修正早期误判)**:NpcSimTop.sv:445-543 已用跨层次引用掏 33 核内部信号,Verilator 支持。故 .sv checker 可 XMR 直读内部信号零 plumbing(脆,死绑网名),或走 debug 端口(稳定 ABI、上板友好、逐层 plumb)。filelist 分组(RTL_CORE_SRCS vs SIM_TOP_SRCS)是强于 ifdef 的综合隔离。

**本轮已落地**(flush GAP 收口延续,非上述讨论):GAP-3(OooFrontend)+INV-7/GAP-7(OooControlPlane)内嵌 ifdef 断言,回归 module82/riscv355/AM59/断言误报0,baseline 7→9。`redirect_status`(OooRedirectStatus.v+Gate)探索已删(redirect 非 FSM)。

关联 [[rv64-architecture-first-reflection]] [[rv64core-audit-baseline]] [[workspace-artifacts-not-tool-dir]]。
