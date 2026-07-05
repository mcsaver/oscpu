export const meta = {
  name: 'flush-redirect-contract-freeze',
  description: '契约冻结：逆向 rv64 核所有 flush/redirect 源 → flush「谁清谁保持」表+优先级全序 → 单点仲裁器重写评估',
  phases: [
    { title: '逆向flush源' },
    { title: '综合建表' },
    { title: '重写评估' },
    { title: '对抗审查' },
    { title: '定稿契约' },
  ],
}

const RV = '/home/lyg/PA/ysyx-workbench/npc/rv64'
const CONST = `${RV}/design/arch/ooo-core-architecture.md`

const SRC_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    subsystem: { type: 'string' },
    sources: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          name: { type: 'string', description: 'flush/redirect/squash 源的名字或信号' },
          producer_file: { type: 'string', description: '产生它的模块 file:line' },
          trigger: { type: 'string', description: '触发条件' },
          scope: { type: 'string', description: 'fetch(冲前端) / backend(squash younger) / both / pc-only' },
          clears: { type: 'array', items: { type: 'string' }, description: '触发时清掉哪些队列/标志/在飞项（逐项，从 RTL 实读）' },
          keeps: { type: 'array', items: { type: 'string' }, description: '明确保持不清的（committed store / 已发 AXI / arch RF 等）' },
          priority_hint: { type: 'string', description: '相对其他源的优先级线索（谁盖过谁，从仲裁 RTL 读）' },
          evidence: { type: 'string', description: '关键 file:line 证据' },
          concerns: { type: 'array', items: { type: 'string' }, description: '现状是否违反/存疑三铁律或不变量（committed store 是否可能被清、是否可能 kill 已发 AXI、CSR 副作用是否可能被撤）' },
        },
        required: ['name', 'producer_file', 'trigger', 'scope', 'clears', 'keeps', 'priority_hint', 'evidence', 'concerns'],
      },
    },
    convergence_points: { type: 'array', items: { type: 'string' }, description: '汇合点（如 OooFetchRequestMux 优先级链）及其仲裁逻辑' },
    notes: { type: 'string' },
  },
  required: ['subsystem', 'sources', 'convergence_points', 'notes'],
}

function rev(subsystem, focus, files) {
  return `你在**逆向**一个 rv64 乱序超标量核的 flush/redirect 子系统，目的是把散在 RTL 里的 flush 语义**冻结成可判定契约**（宪法 §7/C7 自认"≥12 redirect/flush 源、≥5 汇合点、无统一优先级链"，这是要治的结构缺陷）。

你负责的子系统：**${subsystem}**。${focus}

只读逆向这些文件（用 Read/grep，从 RTL 实读真实行为，不要猜；每个结论给 file:line）：
${files.map(f => `  - ${RV}/${f}`).join('\n')}
参考宪法 flush/redirect 现状：${CONST} 的 §5.5(redirect_event 现状 10+ 源) 与 §7/C7 表。对应模块 spec 在 ${RV}/design/specs/ 下。

对你子系统内**每一个** flush/redirect/squash/清除 源，逆向出：触发条件、作用域(fetch/backend/both)、**触发时清掉哪些状态（队列/标志/在飞项/map，逐项）**、**明确保持哪些**、相对优先级线索、以及它是否可能违反三条铁律（committed store 不得清 / 不得 kill 已发 AXI / CSR 写 commit 拍即架构可见不得撤）。忠实 RTL，存疑处标"存疑+证据"。`
}

phase('逆向flush源')
const revThunks = [
  () => agent(rev('取指侧 redirect（PC 重定向 + 优先级链汇合）',
    '重点：OooFetchRequestMux 的优先级链（哪些源、谁盖过谁）、OooFetchPcOutstandingSequencer 的 next_fetch_pc 仲裁、untracked-over-flush 规则。这是"优先级全序"的取指侧真相来源。',
    ['vsrc/frontend/OooFetchRequestMux.v', 'vsrc/frontend/OooFetchPcOutstandingSequencer.v', 'vsrc/frontend/OooDirectControlFlowGate.v', 'vsrc/frontend/OooFrontendActionGate.v']),
    { label: 'rev:fetch-redirect', phase: '逆向flush源', schema: SRC_SCHEMA, effort: 'high' }),
  () => agent(rev('后端 flush/squash（trap/exit + branch mispredict ROB-walk）',
    '重点：trap/exit 清 ROB 全在飞/IQ/busytable/rename map→arch/freelist；branch mispredict 的 ROB-walk 恢复清 boundary 之后。逆向"清什么保持什么"的后端真相。',
    ['vsrc/control/OooControlPlane.v', 'vsrc/control/OooControlFlushSequencer.v', 'vsrc/frontend/OooBranchResolveRecoveryGate.v', 'vsrc/frontend/OooDirectBranchResolveGate.v']),
    { label: 'rev:backend-flush', phase: '逆向flush源', schema: SRC_SCHEMA, effort: 'high' }),
  () => agent(rev('访存/SQ flush + CSR/pending-trap 出口',
    '重点：SQ flush 时 committed store 必须保持继续 drain、不得 kill 已发 AXI；CSR/pending trap 出口（OooPendingTrapExitSequencer 的 clear_arch_squash、OooTrapExitEventMux 的 drain_trap_payload）的清除与残留规则。三铁律的访存/CSR 侧核对。',
    ['vsrc/control/OooPendingTrapExitSequencer.v', 'vsrc/control/OooTrapExitEventMux.v', 'vsrc/control/OooPendingDrainResolveGate.v', 'vsrc/memory/OooMemAxiBridge.v']),
    { label: 'rev:lsu-csr', phase: '逆向flush源', schema: SRC_SCHEMA, effort: 'high' }),
  () => agent(rev('stop_pending / dispatch-capture squash',
    '重点：OooStopPendingSequencer 的 stop_pending 保持/清除、OooPendingDispatchArbiter 的 capture squash 清除路径（clear_arch_squash 来源）、serialize 队头化不变量。逆向 dispatch-capture 侧的清除语义。',
    ['vsrc/control/OooStopPendingSequencer.v', 'vsrc/control/OooPendingDispatchArbiter.v', 'vsrc/control/OooCoreSliceControlGate.v']),
    { label: 'rev:pending-capture', phase: '逆向flush源', schema: SRC_SCHEMA, effort: 'high' }),
]
const revs = (await parallel(revThunks)).filter(Boolean)
const allSources = revs.flatMap(r => (r.sources || []).map(s => ({ ...s, subsystem: r.subsystem })))
log(`逆向完成：${revs.length} 子系统，共 ${allSources.length} 个 flush/redirect 源`)

phase('综合建表')
const synth = await agent(`把四个子系统逆向出的 flush/redirect 源，综合成一份**可判定的 flush 契约**。这是给一个新人"不看 RTL 就知道谁在什么条件 flush、清谁保持谁、谁盖过谁"的东西。

【四子系统逆向结果 JSON】
${JSON.stringify(revs)}

产出（中文 markdown，将落成 design/specs 里的 flush 契约 spec）：
1. **flush/redirect 源总表**：一张 markdown 表，列 = [源名 | 产生模块 | 触发 | 作用域 | 清什么 | 保持什么 | 证据file:line]，逐源填全（去重跨子系统重复项）。
2. **优先级全序**：把所有源排成一条全序（高→低），标注证据；与宪法目标序 trap/exit > CSR/xRET > branch mispredict > BPU/RAS > 顺序PC 对照，指出现状是否一致、哪里缺优先级链。
3. **三条铁律现状核对**：逐条给"成立/存疑/违反 + 证据"——① committed store 不得被清；② 不得 kill 已发 AXI（只能 drain 完）；③ CSR 写 commit 拍即架构可见、flush 不能撤。
4. **契约缺口清单**：哪些源之间的优先级未定义、哪些"清/保持"在 RTL 里不一致或靠巧合成立、哪些是宪法 §7 说的"补丁总线"症状。
忠实逆向证据，存疑标出。这份是契约冻结，不是重写——只描述现状 + 指出缺口。`, { label: 'synthesize-table', phase: '综合建表', effort: 'xhigh' })

phase('重写评估')
const rewrite = await agent(`基于下面冻结的 flush 契约现状，评估宪法 §5.5 的 **C-OBJ-REDIR 目标**（统一 redirect_request 对象 + 单一优先编码 control-flow arbiter，"同拍不得两源都赢"由构造保证）该不该做、怎么做、值不值。

【flush 契约现状】
${synth}

产出（中文）：
1. **可行性**：把 ≥12 源收敛进单点优先编码仲裁器，技术上要动哪些模块、改动面多大、哪些是纯搬迁哪些要改语义。
2. **设计草案**：redirect_request 统一对象字段（onehot 源 + target + scope flush_fetch/flush_backend + 优先级）、单一 arbiter 的优先编码逻辑、"同拍两源都赢由构造不可能"怎么保证。
3. **判据裁决**：按 architecture-first 的判据（非法状态随源数组合爆炸且无单一收敛点 → 重写；边界清晰状态小 → 立即断言够），flush 子系统到底该"局部重写单点仲裁器"还是"先加立即断言监视 + 逐步收敛"？给明确裁决 + 理由。
4. **成本与风险**：对单人 + 现有全绿 real workload，重写的成本(工时量级)、回归风险、以及"先加断言把现状钉住再重写"的渐进路径。
5. **最小第一步**：如果决定重写，第一个安全的小步是什么（如：先加"同拍至多一个 flush 源赢"的立即断言把当前隐式不变量钉成显式护栏，再逐源迁移）。
诚实，别为重写而重写；也别回避宪法已立的 C-OBJ-REDIR 目标。`, { label: 'rewrite-eval', phase: '重写评估', effort: 'xhigh' })

phase('对抗审查')
const crit = await agent(`对抗审查这份 flush 契约冻结 + 重写评估。挑战：
- 源清单**全不全**？宪法说 ≥12 源、≥5 汇合点——表里够数吗？漏了哪些（如 execute 侧的 FP/div flush、memory bridge 的 squash、fetch fault gate）？
- "清什么/保持什么"有没有把 RTL 读错或过度自信？哪些标了"成立"其实证据不足？
- 三铁律核对里，有没有把"当前恰好没触发"当成"契约成立"（幸存者偏差）？
- 重写裁决是否被"宪法立了目标所以要做"绑架？单人成本下渐进加断言是不是更该优先？
- 这份契约若落盘，会不会又变成"填了一次不更新"的死文档——怎么让它和 check-contract gate 挂钩活着？
【契约】${synth}
【重写评估】${rewrite}
中文，具体、锋利。`, { label: 'critique', phase: '对抗审查', effort: 'xhigh' })

phase('定稿契约')
const spec = await agent(`把 flush 契约 + 重写评估 + 对抗审查，融成一份可落盘的 **flush/redirect 契约 spec**（中文 markdown，将存到 design/specs/ooo-flush-redirect-contract.md）。

【契约现状】${synth}
【重写评估】${rewrite}
【对抗审查——把站得住的质疑纳入，标出未闭合项】${crit}

按 SPEC-TEMPLATE 结构组织，至少含：
- 顶部：类型(spec/契约)、依据(decisions [38]、宪法 §7 C7/§5.5 C-OBJ-REDIR)、"本表是 flush 触碰改动的前置契约"声明。
- §2 接口契约：**flush/redirect 源总表**（源×[清|保持]）+ **优先级全序** + 汇合点。
- §3 三条铁律 + 现状核对（成立/存疑/违反，逐条证据）。
- §4 不变量：能编码成立即断言的（如"同拍至多一个 flush 源赢"、"committed store 不在任何 flush 的 clears 里"），标注哪些可挂 check-contract gate。
- §重写评估：C-OBJ-REDIR 单点仲裁器裁决 + 渐进路径 + 最小第一步。
- §未闭合项：对抗审查指出的缺口/存疑，作为 backlog。
忠实证据，存疑不粉饰。这份会落盘并进 check-contract 的契约体系。`, { label: 'finalize-spec', phase: '定稿契约', effort: 'xhigh' })

return { spec, source_count: allSources.length, subsystems: revs.map(r => r.subsystem) }
