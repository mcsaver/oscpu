---
description: "rv64 核接口/控制契约先行强制规则。动 npc/rv64 可综合 RTL（新模块/改接口/改时序/改控制信号/改数据通路）前，必须先冻结六类可判定跨模块契约并填入对应 spec 的 §2/§3；填不出即视为未理解上下游，禁止写 RTL。契约优先转成立即断言可执行检查，而非停留在散文。另含「外部抽象状态观测层」三层模型（.sv checker 旁挂 SIM_TOP、零侵入验证既有 RTL）的落地范式与工具链踩坑。"
applyTo: "npc/rv64/**/*.{v,sv,vh,svh}"
---

# rv64 接口/控制契约先行（architecture-first 的可执行形态）

> 依据 `.github/memory/decisions.md` [38]。本文件是六类契约的**规范单一真源**；
> 决策记录见 [38]（本规则已自包含，不依赖任何会归档的 task-run/spec 佐证）。
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
（反面教材：某 spec 曾给出握手方程却声明"不持有任何状态、
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

## 外部抽象状态观测层（三层模型：契约的旁挂可执行形态）

> 本节是**自包含**的可操作规则 + 踩坑清单（规则不依赖任何会归档的 spec/task-run，独立成立）。
> **适用**：跨模块控制契约 / 想要"抽象状态"debug 视图 / 零侵入验证既有 RTL。**非每次动 RTL 都强制**——
> 单模块、边界清晰的局部不变量走上节内联 `ifdef OOO_ASSERT` 断言即够，不必起外部 checker。

**三层分层（物理归属禁混）**：
- **① RTL 真实编码**（one-hot / 散 wire / 稠密，综合参与）——观测层**一行不碰**。
- **② 投影 + 断言**：`vsrc/debug/*.sv` → filelist `SIM_TOP_SRCS`（**不进 `RTL_CORE_SRCS`** → DCE 零面积）。XMR 读 ① 真实信号 → 投影 ③ 抽象态 + 立即断言。
- **③ 外部抽象状态映射**：`vsrc/common/*.vh`，自解释 one-hot 宏——`` `define OOO_XXX_YYY N ``，**位号=语义=位置三位一体**（packed bus + 宏切片，读位即读语义）+ 行内语义注释。**③ 独立于 ①**（ISA vs 微架构：debug 读抽象态"DRAINING"、非电路位）；one-hot/稠密是 ① 实现自由、③ 不规定。**禁裸数值枚举**（否则需外部映射表→漂移）。

**判据（何时用）**：**无记忆组合仲裁**（每拍独立、无跨拍态，如前端 redirect winner）→ 只做 ② 投影观测 + 独立真理断言，**不状态机化**。**真 FSM**（跨拍转移）→ 另属"值得性+PPA 账"档，排观测层之后且动 RTL。

**落地范式（照做）**：
1. ③ 表 `vsrc/common/XxxFacts.vh`：`` `define OOO_XXX_YYY N `` + 行内注释归属。
2. ② checker `vsrc/debug/XxxChecker.sv`：`` `include "define.v" `` + ③ 头；module 只接 `clk/rst` + 被观测端口；投影=observability、断言=独立真理。
3. filelist 三处 **additive**：`RTL_DEBUG_DIR := $(VSRCDIR)/debug`（目录变量区）+ 文件变量 + 追加 `SIM_TOP_SRCS`（**绝不进 `RTL_CORE_SRCS`**）。
4. `NpcSimTop.sv` 例化 checker + XMR 连端口：`u_top.u_core.u_ooo_core.<层层实例>.<net>`（用局部 `` `define XMR_PREFIX ... `` 宏简化 + 用完 `` `undef ``）；`` `ifdef OOO_ASSERT `` 门控例化。

**断言纪律（承上节，观测层强化）**：断言编码**独立于 ① 的真理**（ISA / spec 合法转移 / 结构不变量 / 死硅 tie-0），**非重述 RTL/三元链**（同盲区）；投影 facts 是 observability、**不作断言依据**。每条必须验**非真空**（故意制造违约确认会响 + 确认前件在真实 workload 可达、计数 > 0）。**漂移由断言守**：② 投影的转移落 ③ 合法表、否则 `$error`。

**⚠ 工具链 / 方法学踩坑（血泪，照避）**：
1. **XMR**：Verilator 支持任意深度 downward 引用（读子模块 port net）；从 `NpcSimTop` 例化 checker、XMR 连端口最稳（已验五层深）。
2. **`PINCONNECTEMPTY` = 错误**（本 build 视告警为错误）：checker 的 observability 投影**别引出成 output 端口再空连接**（`.facts_o()` 空连接即报错中止）；改**内部 wire + 命名 `` wire _unused_ = |facts_w `` sink**（波形仍可观测）。
3. **`$error` 在 `--assert` 下会中止**（等同 `$fatal`）；**非真空探针改用 `$display`**（不中止、可计数）+ **`=== 1'b1`**（排除时刻 0 的 X 假触发）。
4. **core-regress runner 不收 sim stdout** → `$display` 探针别指望 `npc-eval` 日志；**直跑单 bin** 捕获：`objcopy -O binary <elf> <bin>` + tohost=`` `nm|grep tohost` `` + `build/NpcSimTop -b --no-diff --tohost=<addr> <bin>`（AM bin 直跑、syscon halt 无需 tohost）。
5. **时序件（reg 输出 / later-wins 打拍）断言须【延迟一拍比较】**：当拍仲裁条件决定**下一拍** reg 值，同拍读 reg 是旧值（Moore/Mealy 陷阱）；把条件+期望值各寄一拍、与目标 reg **同延迟对齐**后比。
6. **信号语义先勘察别假设**：如 `csr_trap_mem_valid`（mem 阶段 trap = page/access fault）≠ `csr_trap_ex_valid`（exec 阶段 = ecall/illegal）；键错信号 → 断言真空（该类测试根本不触发）。断言前勘察信号驱动链确认它何时脉冲。
7. **`$time` 恒 0**：本 harness 不推进 Verilator 时间，`@%0t` 恒 0 是打印伪影、不影响断言逻辑（要精确时刻用周期计数器）。
8. **验证方式**：SIM_TOP checker 的 `$error` **不进 `contract-assert-baseline` 计数**（那只数 `RTL_CORE_SRCS` 内联 `$error(`）；观测层验证 = **回归恒静默 + 每条非真空各过一遍**。

**三种典型仲裁形态及对应手法**（自包含分类，覆盖迄今遇到的全部形态）：
- **组合仲裁**（first-match 三元链，纯 wire 当拍）→ 当拍直接投影 + 断言（无 Moore/Mealy 问题）；
- **时序仲裁**（later-wins 打拍 reg，下一拍生效）→ **延迟一拍比较**（条件+期望值各寄一拍，与目标 reg 同延迟对齐）；
- **跨仲裁器一致性**（两器消费重叠条件、须结果一致）→ 同时 XMR 两器、延迟对齐比对二者输出。
现有实现落在 `vsrc/debug/`（② checker）与 `vsrc/common/`（③ 表）下，可作起步参考（工作区常驻，非归档件）。

## 留痕与回写

- 契约推导与本次冻结的表，写进 `.github/task-runs/<日期-任务名>/task-report.md` 的「接口契约冻结」一节。
- 模块级稳定契约回写对应 `design/specs/<模块>.md` §2/§3 与 `.github/memory/modules/npc.md`，避免下次重推。

## 禁止行为

- 禁止跳过契约冻结直接写触碰六类边界的 RTL。
- 禁止用"回复里口头说一下上下游"替代填 §2/§3 表。
- 禁止把契约停在散文而不转成能编译的立即断言（能编码的部分）。
- 禁止用"符合 spec"为错误契约背书——spec 只停在意图+不变量高度，微架构细节归 RTL。
