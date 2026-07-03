export const meta = {
  name: 'doc-lifecycle-audit',
  description: '文档生命周期全量审计:动态盘点→分组对照代码真源→判定并就地校正,归档建议交主控执行',
  whenToUse: '大规模代码改动后文档可信度存疑、用户要求"重读/释放/归档文档"、或按 doc-lifecycle 协议 §4 触发全量重审时',
  phases: [
    { title: '盘点', detail: '动态发现文档清单并按子系统分组' },
    { title: '审计', detail: '并行逐份判定 CURRENT/DRIFT_FIXED/ARCHIVE 并修正漂移' },
  ],
}

// args:
//   roots:     要审计的文档根(目录或 .md 文件路径数组)。缺省 = npc/rv64 设计文档集。
//   truth:     可选,现成的真相参照(审计报告 JSON/真相基线 md 路径数组)。不传则 agent 直接读代码验证。
//   groupSize: 每组最多文档数,缺省 10。
const REPO = '/home/lyg/PA/ysyx-workbench'
const PROTOCOL = REPO + '/.github/instructions/doc-lifecycle.instructions.md'
const roots = (args && args.roots && args.roots.length) ? args.roots : [
  REPO + '/npc/rv64/design',
  REPO + '/npc/rv64/README.md',
  REPO + '/npc/rv64/vsrc/README.md',
  REPO + '/npc/rv64/vsrc/control/README.md',
]
const truth = (args && args.truth) ? args.truth : []
const groupSize = (args && args.groupSize) ? args.groupSize : 10

// ---------- Phase 1: 盘点(workflow 脚本无文件系统访问,由 agent 动态发现) ----------
phase('盘点')
const INVENTORY = {
  type: 'object', required: ['groups'],
  properties: {
    groups: { type: 'array', items: { type: 'object', required: ['key', 'files', 'code_hint'], properties: {
      key: { type: 'string', description: '组名(子系统/主题),kebab-case' },
      files: { type: 'array', items: { type: 'string' }, description: '本组文档的绝对路径' },
      code_hint: { type: 'string', description: '本组文档对应的代码真源目录/文件提示' } } } },
  },
}
const inv = await agent(
  `你是文档盘点员。任务:列出以下根下的全部 .md 文档并按主题分组,供后续并行审计。\n` +
  `根:\n${roots.join('\n')}\n` +
  `规则:1) 用 find/ls 枚举全部 .md,**严格限定在上述根路径之内,一份都不得越界纳入**(调用方已按需圈定范围;` +
  `若你发现根外明显相关的文档,只在最后备注建议,不进 groups);2) **排除**任何 history/ 归档目录下的文件;` +
  `3) 按子系统/主题分组,每组最多 ${groupSize} 份(同目录同主题的放一组,巨型 README 可单独成组);` +
  `4) 为每组给出对应的代码真源提示(读文件头几行判断主题,指出该主题的 RTL/源码目录);5) 输出绝对路径。全程中文。`,
  { label: '盘点', phase: '盘点', schema: INVENTORY })
if (!inv || !inv.groups || !inv.groups.length) return { error: '盘点失败或无文档', groups: [] }
log('盘点完成:' + inv.groups.length + ' 组,共 ' + inv.groups.reduce((n, g) => n + g.files.length, 0) + ' 份')

// ---------- Phase 2: 并行审计 ----------
phase('审计')
const AUDIT = {
  type: 'object', required: ['group', 'results'],
  properties: {
    group: { type: 'string' },
    results: { type: 'array', items: { type: 'object', required: ['file', 'verdict', 'summary'], properties: {
      file: { type: 'string' },
      verdict: { type: 'string', enum: ['CURRENT', 'DRIFT_FIXED', 'SUPERSEDED_ARCHIVE', 'ORPHAN_ARCHIVE'] },
      summary: { type: 'string', description: '判定依据;DRIFT_FIXED 逐条列修改;ARCHIVE 给原因' },
      current_ref: { type: 'string', description: '仅归档件:现状参考(留给 history README 登记表)' } } } },
  },
}
const truthNote = truth.length
  ? `【真相参照(先读)】${truth.join(' , ')}\n存疑处仍须亲自读代码核实。`
  : `【无现成真相参照】所有判定必须亲自读代码验证,证据具体到 文件:行号。`
const COMMON =
  `你是文档生命周期审计员。先读协议(判定类别/死硅注记格式/纪律的唯一真源):${PROTOCOL}\n` +
  truthNote + `\n` +
  `【动作】对分到的每份文档:判定 CURRENT(一致,不动)/ DRIFT_FIXED(对应实体仍活,就地用 Edit 修正事实错误——` +
  `最小 diff、不重写结构、保持原文风格;若实体是"活文件中的死通道"则按协议 §2 格式加 ⚠️ 死硅注记)/ ` +
  `SUPERSEDED_ARCHIVE(一次性计划/快照使命已完成)/ ORPHAN_ARCHIVE(描述的实体已不存在)。\n` +
  `【禁止】归档件不改不移动(git 操作由主控统一执行);不要臆断,每个判定要有代码证据。全程中文。\n`
const results = (await parallel(inv.groups.map(g => () =>
  agent(COMMON + `\n【你的分组】${g.key}\n【代码真源提示】${g.code_hint}\n【文档清单】\n` + g.files.join('\n'),
    { label: 'audit:' + g.key, phase: '审计', schema: AUDIT })
))).filter(Boolean)
log('审计完成:' + results.length + '/' + inv.groups.length + ' 组')

// ---------- 汇总:归档建议交主控按协议 §3 执行(git mv + history 登记 + 悬空引用清零 + 索引同步) ----------
const archives = []
for (const r of results) for (const it of r.results) if (it.verdict.indexOf('ARCHIVE') >= 0) archives.push(it)
return { groups: results, archive_queue: archives,
  next_steps: '主控按 doc-lifecycle 协议 §3 执行归档手续(git mv→history 登记表→悬空引用 grep 清零→索引同步),并更新协议 §6 登记状态与 task-run。' }
