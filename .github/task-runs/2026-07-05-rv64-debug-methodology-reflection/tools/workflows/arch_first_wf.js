export const meta = {
  name: 'architecture-first-thinking',
  description: '回答：为什么 RTL-first 是根、怎么像 IC 公司那样 architecture-first、契约该冻结什么',
  phases: [
    { title: '业界流程' },
    { title: '项目证据' },
    { title: '契约清单' },
    { title: '诚实反面' },
    { title: '综合回答' },
    { title: '对抗审查' },
    { title: '定稿' },
  ],
}

const JOURNAL = '/home/lyg/.claude/projects/-home-lyg-PA-ysyx-workbench/4ec33c7a-397d-4c3b-bd57-9ff028f7f9bb/subagents/workflows/wf_76e0b4f6-008/journal.jsonl'
const DIG = '/home/lyg/.claude/jobs/4ec33c7a/tmp/digest'
const DESIGN = '/home/lyg/PA/ysyx-workbench/npc/rv64/design'
const VSRC = '/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc'

phase('业界流程')
const a_industry = () => agent(`你是资深 CPU IC 架构师。用户在做一个 rv64 乱序超标量核，他反思："业界是 spec 先行——先有 datasheet/架构，写 RTL 只是翻译过程；而我是为了实现功能先写 RTL，没理解模块承接的上下游接口业务，本末倒置了。"

请把**真实 IC 公司（做 CPU 的，如 Arm/SiFive/Intel 量级）从概念到 RTL 的分层流程**讲清楚、讲准。重点：
1. 分层：产品需求 → 架构规格(architecture spec, 指 ISA/可见行为) → **微架构规格(microarchitecture spec)** → **接口/控制规格(interface & control spec)** → RTL → 验证计划(verification plan)。每层**谁写、冻结什么、什么时候冻结、下游凭什么开工**。
2. 精确澄清用户"写 RTL 不过是翻译"这句话**哪里对、哪里危险**：微架构探索、时序收敛、验证反馈其实会回改架构，业界并非纯瀑布；但"接口契约在写 RTL 前必须冻结"这一点是对的。区分"架构规格"（做什么）和"微架构/接口规格"（怎么做、模块间怎么握手）——用户混用了 datasheet 一词。
3. 关键洞察：业界真正先行、真正防住 bug 的，**不是笼统的 datasheet，而是模块间的接口时序契约**（valid/ready 握手、stall 反压、flush/redirect 的优先级与作用域、异常序、访存序）。这些是"更顶层更抽象"的正确所指。
可用 WebSearch 佐证权威定义（architecture vs microarchitecture spec、verification plan 的地位），但主要靠你对真实流程的理解，别被搜索噪声带偏。中文，结构化，~1400 字，具体、不空泛。`, { label: 'industry-flow', phase: '业界流程' })

phase('项目证据')
const a_evidence = () => agent(`证实或证伪用户的怀疑："我 debug 慢、反复出 bug 的根，是一开始没写明什么时候 stall、什么时候 flush 这类控制契约。"

数据源：上一轮解剖的 54 个 bug 存在 ${JOURNAL}（每行一个 JSON；type=="result" 的行里，.result.bugs 是数组，每个 bug 有字段 symptom / root_cause / root_cause_class / localization_cost / why_slow / spec_relation / spec_relation_detail）。用 python 或 jq 把所有 bug 提取出来。补充上下文可读 ${DIG}/ 下的会话 timeline。

任务：
1. 用 python 统计 root_cause_class 和 spec_relation 的完整分布（把数字列全）。
2. **筛出根因属于"上下游接口/控制契约未定义"的 bug**——即 timing-handshake、cross-module-contract、state-machine-deadlock、speculation-flush-recovery、invariant-corruption 这几类，以及 spec_relation 为 emergent-cross-module-interaction / spec-correct-impl-diverged 的。数出它们占比。
3. 对其中最有代表性的 6-10 个，逐条给：bug 是什么、它精确地缺了哪一条 stall/flush/握手/序 的契约、如果开工前这条契约被写明并冻结、这个 bug 会不会根本不发生。
4. 结论：用户的怀疑成立到什么程度？给一个诚实的比例判断（多少 bug 确实可归因于"接口契约缺失"，多少其实是别的原因如纯译码/工具链/难以事前预见的涌现）。
中文，用具体 bug 名字/编号，~1400 字。忠实数据，不夸大。`, { label: 'bug-evidence', phase: '项目证据' })

const a_specaudit = () => agent(`诊断用户现有架构文档的**粒度**，验证他的自评："我没写明什么时候 stall、什么时候 flush；我的 spec 只是说明这个模块干什么，不够顶层抽象。"

读 ${DESIGN}/ 下的 arch/ 与 specs/ 目录（先 ls -R 和 wc -l 摸清有哪些文档、多大，再 Read 采样有代表性的几份）。也看一眼 ${VSRC}/ 的模块目录划分（control/execute/scheduling/memory/frontend/writeback/rename_allocate 等）对照文档覆盖。

判断并给证据：
1. 现有文档主要是哪种？(a) 模块功能说明"这个模块干什么"，(b) 实现记录/bug 史/task log，(c) 真正的**跨模块接口时序契约**（明确规定 valid/ready 握手、stall 何时拉高与如何反压传播、flush/redirect 的优先级与作用域、异常/中断序、访存序）。给出各类占比的体感和例证（引具体文件名+一两句内容）。
2. **有没有一份文档，能让一个新人不看 RTL 就知道"模块 A 在什么条件下 stall、flush 时谁清谁不清、握手时序是什么"？** 如果没有，明确说没有，这就证实了用户的诊断。
3. 现有 specs 里写得最接近"控制契约"的是哪几份（如 serialize spec）？它们为什么仍不够（是散文而非可判定的时序规则？只覆盖单模块？）。
中文，~1200 字，多引具体文件名，结论明确。`, { label: 'existing-spec-audit', phase: '项目证据' })

phase('契约清单')
const a_checklist = () => agent(`为这个具体的 rv64 乱序超标量核，产出一份**"开工前该冻结的接口/控制契约清单"**——回答用户"架构应该是更顶层更抽象的内容，具体指什么"。

背景：核按 frontend/decode/rename_allocate/scheduling(IQ)/execute/memory(LSQ,SQ)/writeback/control 分层（见 ${VSRC}/）；历史踩过的坑包括 flush 与异步 LSU 冲突、serialize coexistence 五机制涌现死锁、redirect 优先级、pending 标志被误用、SQ drain、投机恢复 walk。可读 ${VSRC}/ 结构与 ${DIG}/ 里的 timeline 了解真实模块边界。

清单要求：把"更顶层更抽象的架构"落成**具体的契约类目**，每一类给出"这条契约必须规定什么"的模板 + "这个核现在缺它导致过什么 bug"的反例。至少覆盖：
- **握手契约**：每对生产者→消费者的 valid/ready 语义、谁能等谁、组合环禁令。
- **反压/stall 契约**：stall 从哪产生、如何逐级传播、哪些级可被 stall、stall 时状态冻结的精确定义。
- **flush/redirect 契约**：redirect 的来源与优先级排序、每种 flush 的作用域（清哪些队列/标志/在飞项）、flush 与在途访存/CSR 副作用的交互——**必须是一张"谁清谁、谁保持"的表**。
- **异常/中断/序契约**：精确异常点、retire 序、trap 时机、serialize 指令的队头化不变量。
- **访存序契约**：load/store/LSQ/SQ 的排序与前递规则、与 PTW/cache 一致性的契约。
- **投机/恢复契约**：预测点、恢复点、walk/rollback 要还原的精确状态集。
关键：每条要写成**可判定、可转成断言**的形式（"当 X 时必须 Y"），而不是散文"这个模块负责 Z"。中文，结构化清单，~1600 字，具体到这个核。`, { label: 'contract-checklist', phase: '契约清单' })

phase('诚实反面')
const a_counter = () => agent(`唱反调，防止给用户一个理想化、他一个人做不到的答案。用户想"像真正的 IC 公司一样做 architecture-first"。请诚实指出：

1. **architecture-first 不是纯瀑布、也不是银弹**：真实 IC 公司也大量迭代——微架构探索、时序收敛、验证暴露的问题会回改架构；很多接口契约是在实现和验证中才浮现的。把"spec 先行"理解成"先写完美文档再一行不改地翻译"是另一种误区。业界是"契约冻结 + 受控迭代"，不是"想清楚一切再动手"。
2. **IC 公司防住 bug 靠的不只是 spec，而是一整套用户目前不具备的基建**：专职验证团队(设计:验证≈1:2)、UVM/形式化、覆盖率驱动、接口 assertion/SVA、code review、回归农场。单人 + LLM-agent 复制不了全部。
3. **在"单人 + LLM-agent + 教学项目"的现实约束下**，怎么近似 IC 公司的纪律而不被文档负担压垮？哪些环节 ROI 最高、哪些是奢侈品？给出"穷人版 architecture-first"的取舍。
4. 反问：用户"写 RTL 是翻译"的心智，如果推到极端会带来什么新问题（过度设计、文档与实现漂移、冻结了错误的契约）？如何避免。
中文，~1200 字，锋利、具体、可操作。目的不是泼冷水，是让最终建议落地。`, { label: 'honest-counterpoint', phase: '诚实反面' })

const parts = await parallel([a_industry, a_evidence, a_specaudit, a_checklist, a_counter])
const [industry, evidence, specaudit, checklist, counter] = parts.map(p => p || '(该部分未产出)')
log('五路材料就绪，进入综合')

phase('综合回答')
const synth = await agent(`把下面五份材料综合成对用户三个问题的深度回答。用户是一个技术很强的 rv64 乱序核作者，正在做方法论反思。他的原话与三问：

原话："我怀疑根因是一开始没写明 spec——没写明什么时候 stall、什么时候 flush。业界是 spec 先行，先有 datasheet/架构再实现，写 RTL 不过是翻译；而我为了实现功能先写 RTL，没理解模块承接的上下游接口业务，本末倒置。架构过程应该优先，不是简单说明模块干什么，应该是更顶层更抽象的内容。"
三问：(Q1) 这种本末倒置的情况要怎么处理？(Q2) 怎么做到像真正的 IC 工程师一样思考问题？(Q3) 怎么做到像真正的 IC 公司一样解决问题？

【业界流程】${industry}

【项目证据：接口契约缺失是否是根】${evidence}

【现有 spec 粒度诊断】${specaudit}

【该冻结的契约清单】${checklist}

【诚实反面：局限与现实约束】${counter}

综合要求：
- 先**用项目自己的证据确认/校准用户的诊断**（他对在哪、需要精确化在哪：他说的"datasheet 先行"真正该指的是"接口/控制契约先行"）。
- Q1：给"从现在这个已长歪的核出发"的可操作路径——不是推倒重来，而是**补契约、把散文契约转断言、按契约反向审计现有模块边界**。区分"该补的契约"和"该接受的现实"。
- Q2「像 IC 工程师思考」：具体是什么思维习惯——先定义接口再写逻辑、先问"这个模块在什么条件下 stall/flush"、把每个信号当契约的一方、拒绝"先让它跑起来"。给可练习的动作。
- Q3「像 IC 公司解决」：流程/基建层面，结合诚实反面给"穷人版"——哪些必做(接口契约文档+SVA+回归)、哪些是单人做不到要放弃或用 LLM-agent 替代。
- 把"更顶层更抽象"这句话**落成具体物**：不是模块说明书，而是可判定的跨模块时序契约（一张 flush"谁清谁保持"表、一套握手/反压规则、一份异常序）。
- 诚实纳入反面：architecture-first 也迭代、不是银弹、单人有天花板。
中文，结构清晰，有思想密度不灌水。`, { label: 'synthesize', phase: '综合回答', effort: 'xhigh' })

phase('对抗审查')
const crit = await agent(`对抗审查下面这份"如何做到 architecture-first / 像 IC 公司思考"的回答。挑战：
- 有没有把用户哄开心而给了他做不到的理想化建议？哪些建议单人+LLM-agent 其实落不了地？
- "接口契约缺失是根"这个结论，会不会高估了？（对照：也许很多 bug 是纯译码/工具链/难以事前预见的真涌现，写再多契约也防不住）
- 有没有把"写更多文档"当成万能药，而忽视了文档会与实现漂移、冻结错误契约的风险？
- 对"怎么处理已经长歪的核"给的路径够不够具体、够不够可执行？有没有回避"是否要重写"这个真问题？
- 缺了什么能真正帮到他的东西？
【回答】${synth}
中文，具体、锋利、可操作。`, { label: 'critique', phase: '对抗审查', effort: 'xhigh' })

phase('定稿')
const report = await agent(`把综合回答 + 对抗审查融成一份面向用户的**中文**回答。用户是 rv64 乱序核作者，技术强、讨厌症状级补丁与空泛套话、要 root cause 与可落地方法。他刚提出：根因也许是一开始 RTL-first 没写接口契约(stall/flush)，想知道怎么处理、怎么像 IC 工程师/IC 公司那样思考和解决，并认为"架构应更顶层抽象"。

【综合回答】${synth}
【对抗审查——把站得住的质疑诚实纳入，不要粉饰】${crit}

要求（Markdown，中文，直接有洞察，不客套）：
1. 开篇直接回应他的诊断：**他对了，但要把"datasheet 先行"精确成"接口/控制契约先行"**——并用他自己项目的证据（多少 bug 确实源于契约缺失）确认，同时诚实说明这个归因的上限。
2. 讲清业界真实分层（架构规格 vs 微架构/接口规格 vs RTL），澄清"写 RTL 是翻译"哪里对哪里是危险的误区（业界也迭代，不是纯瀑布）。
3. 把"更顶层更抽象"**落成具体物**：给出该冻结的契约类目（握手/反压/flush谁清谁保持表/异常序/访存序/投机恢复），每类点出这个核现在缺它踩过的坑。这是回答的骨干，要具体到他的核。
4. 分别回答三问：Q1 已长歪的核怎么办(补契约+转断言+反向审计边界，而非推倒重来；诚实讨论"要不要重写")、Q2 像 IC 工程师怎么思考(先定接口再写逻辑等可练动作)、Q3 像 IC 公司怎么解决(穷人版：必做 vs 单人天花板)。
5. 诚实一节：architecture-first 的局限、文档漂移风险、单人+LLM-agent 的现实约束、以及"写契约"不能防住的那类 bug。
6. 收尾给一个**最小起步动作**——不要让他被宏大流程压垮，给一个这周就能做、ROI 最高的第一步。
有信息密度。这份会直接展示给用户。`, { label: 'report', phase: '定稿', effort: 'xhigh' })

return { report, evidence_excerpt: evidence.slice(0, 600), checklist_excerpt: checklist.slice(0, 400) }
