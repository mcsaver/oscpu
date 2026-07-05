---
name: rv64-architecture-first-reflection
description: "rv64 方法论元反思——缺的是强制装置非文档;\"契约先行\"非\"datasheet先行\";flush该单点仲裁器重写;本周最小起步"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4ec33c7a-397d-4c3b-bd57-9ff028f7f9bb
---

用户对 rv64 乱序核做了两轮方法论元反思(从 21 会话/54 bug 归因)，结论已成两份 artifact 报告。核心校正与 actionable，帮他做 rv64 时默认据此思考：

**认知校正**
- 用户原以为"有 spec 就不该有 bug""写 RTL 只是翻译 datasheet"。校正：①"datasheet 先行"选错了层——datasheet(架构规格/ISA)不含微架构/接口规格，而**握手/stall/flush 语义/序/恢复这层接口契约**才是业界真正先行、真正防 bug 的层；②spec≠强制力，spec 只是意图声明；③业界不是纯瀑布，是"契约冻结 + 受控迭代"(很多接口语义要 consumer 建出来才结晶，如 serialize-at-retire §9 全是实现撞出来的)。

**诚实上限(别夸大)**
- bug 里"stall/flush/握手/序/一致性"确是最大一族，但**占不满一半**；近一半 bug 写再多契约也防不住(涌现交互 + 纯译码/数值/harness 噪声)。**用户缺的主要是强制装置(回归+可执行检查+加深金模型)，不是文档。** 拒绝"78%/52%"这类伪精确归类。

**"更顶层更抽象" = 六类可判定跨模块契约**(非框图、非模块说明书)：握手/反压stall(单向DAG)/flush「谁清谁保持」表+优先级全序/异常序/访存序/投机恢复单一真源。用户的 `design/arch/SPEC-TEMPLATE.md` §2/§3 已是正确骨架但 specs/ 从没填过一次。

**关键工程约束(已复核)**
- 全核 SVA 时序断言命中 **0**、Verilator flags 无 `--assert` → "断言先行"必须用**立即断言** `always @(posedge clk) if(违约) $error(...)`(iverilog+Verilator 通吃)，不能用 `|->`/`$stable`。断言两种烂法：真空通过、同盲区(照RTL写=重述RTL)。
- `design/arch/ooo-core-architecture.md` C7/§7 **自认**"≥12 redirect/flush 源、≥5 汇合、无统一优先级链" → flush 子系统是**结构缺陷**，该**局部重写成单点优先编码仲裁器**(true by construction)，不是"加表+挂断言"。判据：非法状态随源数组合爆炸且无单一收敛点→重写；边界清晰状态小→立即断言够。

**本周最小起步(给用户的建议)**：①rv64ua/uf/ud 加进默认回归(近一半涌现 bug 唯一拦截网,零成本)；②30分钟 `--assert` 探针验证工具链能否走"契约转可执行检查"。大表/flush 重写排其后。穷人版补基建：NEMU 吐微架构事件流做 difftest + 手搓交互 cover-point。天花板：缺覆盖率/形式化/独立评审，LLM-agent 替代不了独立评审(共享盲区+爱顺着；血债见 [[serialize-at-retire-flush-lsu-obstacle]] 的"对抗验证结论别自作主张加固")。

**落地状态(2026-07-05)**：最小起步已落地并全 gate 绿。①rv64ua/uf/ud 早已在默认回归(2026-07-01 commit d32b256be，非新加；复盘曾误判"不在回归"——又一次"别信没核实的断言")，本次加防回退护栏。②立即断言探针落地：`OooFetchPacketFifo.v` 加 count_q≤深度4 契约断言(`ifdef OOO_ASSERT`)，iverilog+Verilator 双链路实证会响(过程式 $error/$fatal 不依赖 --assert；--assert 只管 SV assert()关键字)。③**闭环 gate `make check-contract`** 建成(--assert/OOO_ASSERT 存在 + 断言计数不回退，删断言→rc≠0)=把探针升级为常驻 spec 符合性门禁。④architecture-first 焊进 agent 环境 8 文件(新建 interface-contract-first.instructions.md 规范 + rtl-generation-workflow 阶段0 + AGENTS 必读链/完成钩子 + npc/hardware-flow agent + SPEC-TEMPLATE)。Makefile `+define+OOO_ASSERT` 让断言常驻全核回归。证据见 task-run 2026-07-05-rv64-debug-methodology-reflection/landing-report.md。

相关：[[ooo-core-architecture-constitution]] [[rv64core-audit-baseline]] [[coremark-mode1-spec-wrongpath]] [[fp-cluster-eleven-root-causes]]。
