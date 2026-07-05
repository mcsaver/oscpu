---
description: "rv64 核接口/控制契约先行强制规则。动 npc/rv64 可综合 RTL（新模块/改接口/改时序/改控制信号/改数据通路）前，必须先冻结六类可判定跨模块契约并填入对应 spec 的 §2/§3；填不出即视为未理解上下游，禁止写 RTL。契约优先转成立即断言可执行检查，而非停留在散文。"
applyTo: "npc/rv64/**/*.{v,sv,vh,svh}"
---

# rv64 接口/控制契约先行（architecture-first 的可执行形态）

> 依据 `.github/memory/decisions.md` [38]。本文件是六类契约的**规范单一真源**；
> 决策记录见 [38]，证据/推导见 `.github/task-runs/2026-07-05-rv64-debug-methodology-reflection/architecture-first.md`。
> 本规则与 `rtl-generation-workflow.instructions.md` 叠加执行：本规则是其**阶段 0（前置）**，
> 先冻结跨模块契约，再进入块内 需求→FSM→拓扑→RTL 推导。

## 何时强制（可判定触发器）

改动**同时命中**"可综合 RTL"且以下任一时，本规则强制生效，**先契约后逻辑**：
- 触碰握手 / 反压 stall / flush·redirect·trap / 异常序 / 访存序 / 投机恢复 任一路径；
- 跨模块（改动影响 ≥2 个 module 的边界信号，或改一个信号但其 producer/consumer 在别的文件）；
- 新增 module、改端口、改时序（哪拍有效/组合还是打拍）、改控制信号语义。

纯块内、纯组合、纯数值、纯译码且不触碰上述六类边界的改动，可只走 rtl-generation-workflow，不强制本规则。

## 硬门槛：填不出契约 = 没理解上下游 = 禁止写 RTL

动手前必须把受影响模块的 **SPEC-TEMPLATE §2 接口契约 + §3 状态/时序模型**（尤其其中的
flush「谁清谁保持」表、stall 语义、同拍优先级表）填满到"两端能并行开工"的程度。
**填不出的格子，就是你还没理解的上下游业务——此时写 RTL 就是在赌，禁止落 RTL。**
（反面教材：`design/specs/ooo-fetch-flow-control.md` 给了握手方程却声明"不持有任何状态、
PC/outstanding 全甩给 parent"——契约必须包含"决定握手的状态在谁那里"。）

契约不是"一次定死"：定义到能让两端并行开工即可；RTL 撞出的语义**先回填契约（小、被评审）再落 RTL**，绝不让 RTL 悄悄分叉。

## 六类必须冻结的可判定契约

每类给出"当 X 必须 Y"的判据，且**能编码的部分优先转成立即断言**（见下节）。

**① 握手协议**：valid 拉高到 fire 前不撤回；payload 整拍冻结；ready 可组合依赖 valid，
valid 禁组合依赖同级 ready（禁组合环）；双发通道"同拍两 lane 齐 fire 才前进"，同包多 uop 必须**整体**冻结。

**② 反压 / stall（单向 DAG）**：stall 唯一产生源枚举（freelist 空 / ROB 满 / IQ 满 / SQ 满）；
传播链是无环 DAG（retire→ROB→dispatch→rename→decode→fetch 逐级 ready 回吹）；
显式区分可停级 vs 不可停在飞级（已进多周期 FU、已发 AXI 不可回退）；stall = 冻结 = pipeline reg 与架构可见状态保持。

**③ flush/redirect「谁清谁保持」表 + 优先级全序**（最该先做的一张，填进 §3）：
- 逐 flush 源列「清什么 / 保持什么」（trap/exit、branch mispredict(ROB-walk)、SQ flush …）；
- 优先级全序（高→低）：`trap/exit > CSR/xRET > branch mispredict > BPU/RAS 预测重定向 > 顺序 PC`；
- 三条铁律：`committed store 不得被清`、`不得 kill 已发 AXI（只能 drain 完）`、`CSR 写在 commit 拍即架构可见、flush 不能撤`。
- 判据：若一个 flush 汇合子系统**非法状态随源数组合爆炸且无单一收敛点**（宪法 §7 自认 ≥12 源/≥5 汇合/无优先级链正是此形态）→ 应**局部重写成单点优先编码仲裁器（true by construction）**，而非"加表+挂断言监视爆炸空间"。边界清晰、状态小 → 立即断言即够。

**④ 异常序**：精确异常点 = 只在 ROB 队头 retire 拍宣告、年轻全 squash；retire 全序（commit0 先于 commit1）；
serialize 指令必须成 ROB 唯一在飞项才执行。

**⑤ 访存序**：store 只在 commit 后 drain；load 前递须对 older 未 drain store 判 addr_valid + strb 覆盖，
addr 未 valid 必须阻塞或 replay；**任何 store 完成必更新/失效 dcache**（跨模块副作用，须进不变量清单）。

**⑥ 投机恢复 / 单一真源**：每个"域/成员关系/预测 npc"必须有单一真源，禁多处各存一份过期副本。

## 契约的可执行形态（关键工具链约束，别照 SVA 写）

**已复核：全核 SVA 时序算子命中 0；module-TB 走 iverilog（对 `always_comb` 常量位选静默错）；
全核 Verilator 且 `VERILATOR_FLAGS` 无 `--assert`。因此禁止用 `|->`/`|=>`/`$stable` 写并发断言。**

契约转检查只能用**时钟块里的立即断言**（iverilog + Verilator 通吃，同一套代码两仿真器复用）：

    always @(posedge clk) if (违约条件) $error("契约X违约: ...");   // 严重的用 $fatal

- 全核 build 需加 `--assert`（见 gate 一节）；接进已有 cycle-exact 差分 fuzz 护栏，违约即回退。
- **两种烂法必须防**：① 真空通过——refactor 后前件永不为真、断言静默 PASS，写完每条断言**必须故意制造一次违约确认它会响**；② 同盲区——断言只照 RTL 重述则永远抓不到 RTL 本身错，断言必须编码**独立于 RTL 的真理**（来自 ISA / 金模型），不是来自实现。

## 留痕与回写

- 契约推导与本次冻结的表，写进 `.github/task-runs/<日期-任务名>/task-report.md` 的「接口契约冻结」一节。
- 模块级稳定契约回写对应 `design/specs/<模块>.md` §2/§3 与 `.github/memory/modules/npc.md`，避免下次重推。

## 禁止行为

- 禁止跳过契约冻结直接写触碰六类边界的 RTL。
- 禁止用"回复里口头说一下上下游"替代填 §2/§3 表。
- 禁止把契约停在散文而不转成能编译的立即断言（能编码的部分）。
- 禁止用"符合 spec"为错误契约背书——spec 只停在意图+不变量高度，微架构细节归 RTL。
