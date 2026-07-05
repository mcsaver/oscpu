export const meta = {
  name: 'rv64-debug-postmortem',
  description: '从 21 个历史会话归因：为什么 RTL debug 慢、为什么有 spec 仍出 bug',
  phases: [
    { title: '解剖会话' },
    { title: '读沉淀文档' },
    { title: '定量画像' },
    { title: '综合归因' },
    { title: '对抗审查' },
    { title: '定稿报告' },
  ],
}

const DIG = '/home/lyg/.claude/jobs/4ec33c7a/tmp/digest'
const RC_CLASS = ['timing-handshake', 'state-machine-deadlock', 'invariant-corruption',
  'decode-isa-semantics', 'cross-module-contract', 'speculation-flush-recovery',
  'difftest-harness-alignment', 'reset-init', 'width-signedness', 'other']
const SPEC_REL = ['not-in-spec', 'spec-vague-underspecified', 'spec-correct-impl-diverged',
  'spec-wrong', 'spec-not-executable-no-assertion', 'emergent-cross-module-interaction',
  'na-not-correctness-bug']

const DISSECT = {
  type: 'object', additionalProperties: false,
  properties: {
    session_id: { type: 'string' },
    topic: { type: 'string' },
    debug_rhythm: { type: 'string', description: '这个会话 debug 推进的节奏叙事：compile->run->probe 往返形态、卡点、走了哪些弯路、有没有反复推翻假设' },
    bugs: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          symptom: { type: 'string', description: '外在表现：difftest 哪里分歧/哪个测试挂/死锁/波形异常' },
          root_cause: { type: 'string' },
          root_cause_class: { type: 'string', enum: RC_CLASS },
          localization_cost: { type: 'string', description: '定位这个 bug 花的代价：约几轮 compile/run/probe 往返、卡在哪、走了什么弯路、被什么误导' },
          why_slow: { type: 'array', items: { type: 'string' }, description: '这个 bug 定位慢的具体机制标签，如"不可观测-要靠波形反推"/"编译往返长"/"安全网掩盖真因"/"假设反复推翻"' },
          spec_relation: { type: 'string', enum: SPEC_REL },
          spec_relation_detail: { type: 'string', description: '为什么 spec 没能防住这个 bug 的具体解释' },
        },
        required: ['symptom', 'root_cause', 'root_cause_class', 'localization_cost', 'why_slow', 'spec_relation', 'spec_relation_detail'],
      },
    },
    session_slow_factors: { type: 'array', items: { type: 'string' }, description: '本会话观察到的、拖慢 debug 的结构性因素' },
    notable_quotes: { type: 'array', items: { type: 'string' }, description: '揭示困难本质的原话片段（中文，来自 [A]/[U] 行）' },
  },
  required: ['session_id', 'topic', 'debug_rhythm', 'bugs', 'session_slow_factors', 'notable_quotes'],
}

function dissectPrompt(files, big) {
  return `你在解剖一个/几个 RISC-V rv64 乱序超标量核 (RTL) 的历史 Claude Code debug 会话，目的是归因“为什么 RTL bug 定位慢”和“为什么有了 spec 仍不断出 bug”。

读取这些精简 timeline 文件（用 Read 工具；${big ? '注意其中有文件超过 2000 行，务必用 offset 参数分段读【完整】，不要只读前 2000 行' : '大多 <1000 行，一次可读完'}）：
${files.map(f => `  - ${DIG}/${f}.txt`).join('\n')}

timeline 行格式：
  [U] = 真实用户输入   [A] = 助手结论文本   [U:auto] = 定时自动轮
  [T:COMPILE] = 编译仿真器(verilator/iverilog/make)   [T:RUNTEST] = 跑 difftest/测试
  [T:PROBE] = 探查(grep/find/波形/日志)   [T:Edit]/[T:Write]/[T:Read] = 改/写/读文件
  [T:REVERT] = git 回退   [T:Agent]/[T:Workflow] = 子代理/工作流
文件头有该会话的统计 (COMPILE/RUNTEST/Edit/PROBE 次数、时长)。

对每个会话产出结构化结果。重点抓：
1. **每个真实的 RTL bug**（不是架构讨论、不是文档整理）：症状、根因、根因类别、**定位代价**（数 timeline 里为定位它反复出现的 COMPILE→RUNTEST→PROBE→Edit 往返段落、卡了多久、走了什么弯路、被什么误导过）。
2. **why_slow**：这个 bug 慢在哪的机制标签。典型机制：RTL 不可观测（只能从波形/日志反推内部状态）、编译-仿真往返长（每改一行要重编整个仿真器再跑几十万指令才到分歧点）、安全网/掩盖效应（如恒-mispredict 兜底掩盖真实 kill 窗口）、difftest 分歧点离真因很远、假设反复被推翻、跨模块交互难复现。
3. **spec_relation**：这个 bug 和 spec 的关系——spec 没覆盖？spec 写了但太模糊？spec 对但实现偏离？spec 本身错？spec 只是散文没有可执行断言所以违反没被自动抓到？还是多个各自正确的模块交互涌现（任何单点 spec 都防不住）？给出具体解释。
4. debug_rhythm：整体节奏叙事。notable_quotes：能体现困难本质的中文原话。

如果某会话主要是架构评估/文档/重构而非 bug 定位，bugs 可以少或空，但仍在 session_slow_factors 记录你观察到的规律。忠实于证据，不要编造往返次数——说“约”或引用文件头统计。`
}

// ---- 会话分组（已剔除 808a5bb7≡18feeedd 的重复，只留 808a5bb7）----
const GROUPS = [
  { label: 'dissect:0353a89c', files: ['0353a89c'], big: true },   // 王牌 C219 R280 E210
  { label: 'dissect:2308cc05', files: ['2308cc05'], big: true },   // C289 R115
  { label: 'dissect:bbdbcfbf', files: ['bbdbcfbf'], big: false },  // C185
  { label: 'dissect:d01+76369', files: ['d01eafd4', '76369d5c'], big: false },
  { label: 'dissect:1b1f+7634', files: ['1b1f8763', '7634f6a6'], big: false },
  { label: 'dissect:6fcdc+808a', files: ['6fcdc6d5', '808a5bb7'], big: false },
  { label: 'dissect:024c+c01b', files: ['024c1dc4', 'c01b40f4'], big: false },
  { label: 'dissect:06d8+0f46', files: ['06d8caae', '0f469065'], big: false },
  { label: 'dissect:small3', files: ['d675f1f5', '6df78c86', '887b766c'], big: false },
]

phase('解剖会话')
const dissectThunks = GROUPS.map(g => () =>
  agent(dissectPrompt(g.files, g.big), { label: g.label, phase: '解剖会话', schema: DISSECT, effort: 'high' }))

// ---- 文档 agent（已沉淀 bug 史 + 方法学）----
const docThunks = [
  () => agent(`读 /home/lyg/PA/ysyx-workbench/.github/memory/known-issues.md（很大，约 492KB/上万行）。这是 rv64core 已沉淀的“已知问题/bug 史”。
用 Bash (grep -n 提取标题/条目结构，如 '#'、'root'、'根因'、'#[0-9]'、'家族') 先摸清骨架，再 Read 采样关键段落。
产出：(1) 这个核历史上 bug 的**家族分类**（每类几句话+代表案例）；(2) 反复出现的**根因模式**（同一种错误反复犯的）；(3) 文档里已明说的“为什么难定位/难修”的线索。用中文，结构化叙事，控制在 ~1200 字，多引具体 bug 编号/名字。`,
    { label: 'doc:known-issues', phase: '读沉淀文档', effort: 'high' }),
  () => agent(`读 /home/lyg/PA/ysyx-workbench/.github/memory/project-status.md（很大，约 516KB）与 /home/lyg/PA/ysyx-workbench/.github/memory/decisions.md。
先 grep -n 找“方法学/教训/lesson/踩坑/root cause/失败/负结论/不变量/invariant/串行/对抗验证”等关键词定位，再 Read 采样。
产出：这个项目**已经自己总结过的方法学教训**——尤其关于 (a) 为什么某些 bug 难定位、(b) spec/文档 和实际 bug 之间的落差、(c) 有没有出现“同一坑反复踩”的记录。用中文，结构化，~1200 字，忠实引用已有措辞。`,
    { label: 'doc:project-status', phase: '读沉淀文档', effort: 'high' }),
  () => agent(`读定量指标表 /home/lyg/.claude/jobs/4ec33c7a/tmp/metrics.tsv（用 Bash cat/column 看，用 awk 做统计）。
列含义：dur=会话墙钟分钟(含自动轮等待,不等于活跃时长,谨慎解读)，COMPILE=编译仿真器次数，RUNTEST=跑测次数，Edit=改文件次数，PROBE=探查(grep/波形)次数。
已知汇总：21 会话，总 COMPILE=1353 RUNTEST=916 Edit=1428 PROBE=2181 真实用户输入=228。
用 awk 算出并解读：(1) Edit:COMPILE:RUNTEST 比例说明什么（每改一次代码是否就重编一次、跑测相对少）；(2) PROBE 相对 RUNTEST 的倍数说明定位成本；(3) 哪些会话是高强度 debug（高 COMPILE/RUNTEST），单个会话 COMPILE 上百意味着什么；(4) 把这些数字翻译成“时间都花在哪”的画像。用中文，~900 字，用具体数字支撑，明确指出 dur 列的解读陷阱。`,
    { label: 'quant:metrics', phase: '定量画像', effort: 'high' }),
]

const all = await parallel([...dissectThunks, ...docThunks])
const dissections = all.slice(0, GROUPS.length).filter(Boolean)
const docs = all.slice(GROUPS.length).filter(Boolean)
const allBugs = dissections.flatMap(d => (d.bugs || []).map(b => ({ ...b, session: d.session_id })))
log(`解剖完成：${dissections.length} 会话，提取 ${allBugs.length} 个 bug 案例；文档/定量 ${docs.length} 份`)

// ---- 综合归因 ----
const SYNTH = {
  type: 'object', additionalProperties: false,
  properties: {
    quantitative_picture: { type: 'string', description: '时间都花在哪的定量画像总结' },
    why_slow_causes: {
      type: 'array', description: '“为什么 debug 找 RTL bug 慢”的结构性原因，按重要性排序',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          cause: { type: 'string' },
          mechanism: { type: 'string', description: '作用机制' },
          evidence: { type: 'string', description: '来自会话/指标的证据' },
          prevalence: { type: 'string', description: '有多普遍（涉及多少会话/bug）' },
          remedy: { type: 'string', description: '可执行的改进方向' },
        }, required: ['cause', 'mechanism', 'evidence', 'prevalence', 'remedy'],
      },
    },
    why_bugs_despite_spec: {
      type: 'array', description: '“为什么有了 spec 仍不断出 bug”的原因，每条对应一种 spec-bug 落差',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          reason: { type: 'string' },
          spec_gap_class: { type: 'string', description: '对应哪种 spec 落差' },
          mechanism: { type: 'string' },
          examples: { type: 'string', description: '具体 bug 例子' },
          share: { type: 'string', description: '这类占比感觉' },
          remedy: { type: 'string' },
        }, required: ['reason', 'spec_gap_class', 'mechanism', 'examples', 'share', 'remedy'],
      },
    },
    spec_relation_distribution: { type: 'string', description: '所有 bug 的 spec_relation 分布统计与解读' },
    root_cause_distribution: { type: 'string', description: 'root_cause_class 分布统计与解读' },
    key_insight: { type: 'string', description: '一两句话的核心洞察：这个用户的期待错在哪、真相是什么' },
  },
  required: ['quantitative_picture', 'why_slow_causes', 'why_bugs_despite_spec', 'spec_relation_distribution', 'root_cause_distribution', 'key_insight'],
}

phase('综合归因')
const synthesis = await agent(`你在综合 21 个 rv64 乱序核历史 debug 会话的解剖结果，回答用户两个问题：
Q1: 为什么每次 debug 找 RTL bug 那么慢？
Q2: 我原以为有了 spec 就不会有 bug 了——为什么仍然不断出 bug？导致这个的原因是什么？

【所有会话解剖结果 JSON】
${JSON.stringify(dissections)}

【已沉淀文档 & 定量画像】
${docs.map((d, i) => `--- 文档${i + 1} ---\n${d}`).join('\n\n')}

【硬指标】21 会话 总 COMPILE=1353 RUNTEST=916 Edit=1428 PROBE=2181；单会话 COMPILE 最高 289、RUNTEST 最高 280。

要求：
- 先统计所有 bug 的 spec_relation 分布和 root_cause_class 分布（数出来），作为归因的证据底座。
- Q1(why_slow_causes)：给出结构性原因，按重要性排序。区分“RTL 这一媒介固有的慢”（编译-仿真往返长、内部状态不可观测只能靠波形反推、difftest 分歧点离真因远）和“方法/流程带来的慢”（安全网掩盖真因、假设反复推翻、乱序核状态空间组合爆炸、缺可观测性基建）。每条配证据+普遍性+补救。
- Q2(why_bugs_despite_spec)：这是重点。把“有 spec 仍出 bug”拆成几种本质不同的落差类型，每种解释机制并举例。核心论点应包括但不限于：spec 是自然语言散文而非可执行断言（违反不会被自动抓到）；spec 覆盖单模块行为但 bug 来自多模块交互涌现；spec 是“打算怎么做”而实现悄悄偏离（且没有护栏检测偏离）；乱序/投机引入的状态空间远超 spec 能穷举；spec 本身滞后于反复改动的 RTL。
- key_insight：一针见血指出用户“有 spec 就不该有 bug”这个预期的认知误区在哪，以及正确的心智模型是什么。
用中文。忠实证据，不夸大。`,
  { label: 'synthesize', phase: '综合归因', effort: 'xhigh' })

// ---- 对抗审查 ----
const CRITIQUE = {
  type: 'object', additionalProperties: false,
  properties: {
    weak_attributions: { type: 'array', items: { type: 'string' }, description: '归因链条不牢、把相关当因果的地方' },
    missing_evidence: { type: 'array', items: { type: 'string' }, description: '缺证据支撑的论断' },
    alternative_explanations: { type: 'array', items: { type: 'string' }, description: '被忽略的替代解释' },
    overlooked_patterns: { type: 'array', items: { type: 'string' }, description: '解剖里出现但综合漏掉的模式' },
    what_would_change_users_mind: { type: 'string', description: '要真正说服/帮到用户，还缺哪块论证' },
    verdict: { type: 'string', description: '综合结论整体可信度评价' },
  },
  required: ['weak_attributions', 'missing_evidence', 'alternative_explanations', 'overlooked_patterns', 'what_would_change_users_mind', 'verdict'],
}

phase('对抗审查')
const critique = await agent(`你是对抗性审查者。下面是对“为什么 rv64 RTL debug 慢 / 为什么有 spec 仍出 bug”的综合归因。请挑战它：哪些归因把相关当因果？哪些论断缺证据？有没有更简单的替代解释（例如：慢其实主要因为核太复杂/工程量本身大，而非方法问题）？解剖数据里有没有被综合忽略的模式？要真正帮到用户，还缺什么论证？

【综合结论 JSON】
${JSON.stringify(synthesis)}

【可回查的 bug 分布】共 ${allBugs.length} 个 bug 案例，spec_relation 取值来自：${SPEC_REL.join(', ')}；root_cause 取值来自：${RC_CLASS.join(', ')}。

严格、具体、可操作。用中文。`,
  { label: 'critique', phase: '对抗审查', effort: 'xhigh' })

// ---- 定稿：面向用户的中文报告 ----
phase('定稿报告')
const bugDistJson = JSON.stringify(allBugs.map(b => ({ s: b.session, rc: b.root_cause_class, sr: b.spec_relation })))
const report = await agent(`把下面的综合归因 + 对抗审查，融合成一份面向用户的**中文**复盘报告。用户是这个 rv64 乱序核的作者，技术很强、要求硬件结构化 RTL、讨厌症状级补丁、重视 root cause。他的原问题：
“为什么每次 debug 找 RTL bug 那么慢？我原以为有了 spec 以后就不会有 bug 了，导致这个的原因是什么？”

【综合归因】${JSON.stringify(synthesis)}
【对抗审查】${JSON.stringify(critique)}
【bug 分布原始数据(s=会话 rc=根因类 sr=与spec关系)】${bugDistJson}

报告要求（Markdown，中文，直接、诚实、有洞察，不要客套）：
1. 开篇一段直接回答两个问题的**核心结论**（把 key_insight 讲透：为什么“有 spec 就没 bug”是认知误区）。
2. 用**定量画像**开场支撑（编译/跑测/探查/改代码的往返数字，时间黑洞在哪）。
3. 「为什么慢」分点，区分“RTL 媒介固有的慢”vs“方法/流程的慢”，每点配证据，标注哪些是可改进的。
4. 「为什么有 spec 仍出 bug」分点，讲清 spec 与 bug 的几种本质落差（散文非断言、单模块 spec 挡不住跨模块涌现、实现偏离无护栏、乱序状态空间爆炸、spec 滞后）。给出 spec_relation 分布的实际统计。
5. 把对抗审查中站得住的质疑**诚实纳入**（例如“慢有多少其实是核本身复杂度的必然，而非方法问题”），不要粉饰。
6. 结尾「可落地的改进」：针对这个具体项目，给出能真正缩短 debug 循环、把 spec 变成护栏的具体手段（如：可执行断言/SVA、不变量在线检查、缩短编译-仿真往返、提升内部可观测性、把反复踩的坑做成回归护栏等），排优先级。
控制在 use 有信息密度，不灌水。这份报告会直接展示给用户。`,
  { label: 'report', phase: '定稿报告', effort: 'xhigh' })

return { report, synthesis, critique, n_bugs: allBugs.length, n_sessions: dissections.length }
