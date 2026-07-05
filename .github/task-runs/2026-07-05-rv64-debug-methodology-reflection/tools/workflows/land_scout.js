export const meta = {
  name: 'arch-first-landing-scout',
  description: '并行侦察三条落地线的精确方案：agent环境注入 / rv64ua-uf-ud入回归 / --assert立即断言探针',
  phases: [{ title: '侦察' }],
}

const RV = '/home/lyg/PA/ysyx-workbench/npc/rv64'
const GH = '/home/lyg/PA/ysyx-workbench/.github'

const CONTEXT = `【本次要落地的方法论结论（已沉淀 decisions [38]）】
rv64 采用 architecture-first = 接口/控制契约先行。六类该冻结的可判定跨模块契约：①握手(valid到fire不撤回/payload整拍冻结/禁组合环) ②反压stall(单向DAG/可停级vs不可停在飞级) ③flush「谁清谁保持」表+优先级全序(committed store不得清/不得kill已发AXI/CSR写commit拍即可见) ④异常序(精确异常只在ROB队头retire拍宣告) ⑤访存序(store只commit后drain/load前递判strb覆盖/store完成必更新失效dcache) ⑥投机恢复单一真源。
关键工具链约束(已复核)：全核 SVA 时序算子命中0、Verilator flags 无 --assert → 断言必须用立即断言 always @(posedge clk) if(违约) $error/$fatal(iverilog+Verilator通吃)，不能用 |->/$stable。`

phase('侦察')

const a_env = () => agent(`你要给出"把 architecture-first / 接口契约先行方法论**有机结合进 agent 环境**"的精确落地方案——用户明确说"不仅仅是加进记忆，要优化进整个 agent 环境有机结合"。不是再写一条孤立记忆，而是让 agent 未来做 rv64 RTL 工作时**默认按契约先行的工作流走**。

${CONTEXT}

只读侦察这些文件，摸清 agent 环境如何组织工作流与纪律：
- ${GH}/AGENTS.md（必读链、核心方法学节、RECALL/PLAN/RECORD 状态）
- ${GH}/agents/npc.agent.md、${GH}/agents/hardware-flow.agent.md、${GH}/agents/digital-logic.agent.md（看 rv64 RTL 由谁负责、工作流骨架）
- ${GH}/instructions/rtl-generation-workflow.instructions.md（RTL 生成工作流——最可能的注入点，看它现有阶段）
- ${GH}/instructions/npc-optimization-workflow.instructions.md
- ${RV}/design/arch/SPEC-TEMPLATE.md（36行契约骨架，从没被填过）
- ${RV}/design/arch/ooo-core-architecture.md 的 §7/C7（flush 结构缺陷自认）—— grep 采样即可

产出**精确落地方案**（不要泛泛而谈）：
1. 列出应该修改的**每一个文件 + 具体章节/插入点**，每处给出**要加的内容草稿**（真能粘贴的文字），让契约先行成为工作流的一个显式阶段/纪律，而非旁注。重点考虑：rtl-generation-workflow 里加"接口契约先行"前置阶段(先填 SPEC-TEMPLATE 边界表/stall/flush 语义→再写逻辑)；npc.agent.md 或 hardware-flow 的完成判定钩子里加"填不出契约=没理解上下游，禁止写 RTL"；SPEC-TEMPLATE 的地位如何被工作流强制引用。
2. 判断该"新增一份 instruction(如 interface-contract-first.instructions.md)"还是"改现有文件"——给理由与取舍。
3. 指出如何避免这次注入变成又一份没人填的空模板(呼应 SPEC-TEMPLATE 从没填过的教训)——即怎么让它真正被执行(如挂进完成判定钩子/必读链)。
中文，结构化，给可直接落地的文字草稿。`, { label: 'scout:agent-env', phase: '侦察', effort: 'high' })

const a_reg = () => agent(`给出"把 rv64ua/uf/ud 加进默认回归"的**精确可执行方案**。

只读侦察：
- ${RV}/eval/npc-eval.sh（默认回归入口，--all=--module --riscv --am；riscv-tests 段在行94-102，调用 lib 脚本 --riscv-privileged，RISCV_DIR=testsuites/core-tests/src/riscv-tests）
- ${RV}/eval/lib/ 下所有脚本（riscv-tests 到底怎么选测试集、跑哪些前缀、rv64ua/uf/ud 现在跑不跑）
- ${RV}/testsuites/scripts/ 与 testsuites/core-tests/（测试二进制清单、如何加载/运行）
- 用 ls/grep 确认 testsuites/core-tests/src/riscv-tests/isa/ 下 rv64ua-p-*/rv64uf-p-*/rv64ud-p-* 的完整清单

关键要回答：
1. **rv64ua/uf/ud 现在到底跑不跑？** 读 lib 脚本的测试选择逻辑（是按目录全跑？按白名单？按前缀过滤？）判断，给出证据(file:line)。如果已经在跑，任务就变成"确认+锁定不回退"；如果没跑，找出被排除的原因(白名单遗漏？还是 default 只跑 rv64ui/um/mi/si？)。
2. 给出**精确改动**：改哪个文件哪行、加什么，让 rv64ua/uf/ud 进默认回归。
3. 给出**验证命令**（我后续会实际跑），以及预期(这些测试二进制已存在，应能 PASS；注意 rv64ua-p-lrsc 历史上有活锁风险，rv64uf/ud 需要 FP difftest 或金标比对)。
4. 风险：加进去会不会有测试本就 FAIL(变成噪声)？如何区分"新拦截网抓到真问题"vs"测试环境不兼容"。
中文，精确到 file:line + 可粘贴改动 + 验证命令。`, { label: 'scout:regression', phase: '侦察', effort: 'high' })

const a_assert = () => agent(`给出"30分钟 --assert 立即断言探针"的**精确可执行方案**。目的不是铺契约，只回答一个致命问题：这个核的工具链(Verilator全核 + iverilog module-TB)能不能执行"契约转可执行检查"。

${CONTEXT}

只读侦察：
- ${RV}/Makefile（VERILATOR_FLAGS 在行94-122累积、build 规则行169-170、lint 行183；--assert 加在哪行最合适）
- 从六类契约里挑**一条最简单、最可能已成立、能表达成单点立即断言**的不变量做探针(不求覆盖，只求验证工具链)。候选：某对握手的 valid 在 !ready 时保持(payload/valid 不撤回)、或 one-hot redirect/flush 源互斥、或"stall 时某 pipeline reg 保持"。挑一个后，读对应 vsrc 模块找**精确信号名**。建议从这些目录选边界清晰的：${RV}/vsrc/scheduling/、${RV}/vsrc/control/、${RV}/vsrc/frontend/。先 ls + grep valid/ready/flush/redirect 定位一个干净的握手或 onehot。
- 确认 iverilog module-TB 也能跑立即断言(它已有 $error/$display? grep testbench)

产出**精确方案**：
1. Makefile 改动：--assert 加哪行(给出 diff)；注意可能与现有 -Wall/-Wno-* 的交互、以及 --assert 对 always@(posedge) if $error/$fatal 的语义(Verilator 需要 --assert 才会 elaborate immediate assertion? 还是 $error 本就生效？澄清 --assert 到底管 SVA 还是也管 immediate)。
2. 断言代码：给出**能直接粘贴**的一条 always @(posedge clk) if(违约条件) 断言，包含**真实存在的信号名**(file:line 佐证)，放哪个文件哪个位置。选一个当前应当恒成立的不变量。
3. **制造违约的验证方法**：怎么临时把断言写成必然违约(或临时破坏一个信号)确认它真的会响(build+跑一个最短测试看到 $error/$fatal 输出)，再恢复。给出具体命令与预期输出。
4. 判据：如果 Verilator 下 immediate assertion 不 fire / 编不过，fallback 是什么(纯 $display + testbench 断言？还是 iverilog-only？)。
中文，精确到 file:line + 可粘贴代码 + 验证命令。`, { label: 'scout:assert', phase: '侦察', effort: 'high' })

const [envPlan, regPlan, assertPlan] = await parallel([a_env, a_reg, a_assert])
return {
  agent_env: envPlan || '(未产出)',
  regression: regPlan || '(未产出)',
  assert_probe: assertPlan || '(未产出)',
}
