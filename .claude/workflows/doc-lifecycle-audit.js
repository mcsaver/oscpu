export const meta = {
  name: 'doc-lifecycle-audit',
  description: '对调用者给定范围做一次有界文档核对，修正事实漂移并返回归档建议',
  whenToUse: '仅在用户明确要求全量文档审计，或正式 release/migration/publication、跨会话文档重组确实需要时使用；普通代码或文档修改不触发',
  phases: [
    { title: '盘点', detail: '按调用者给定 roots 枚举并分组' },
    { title: '核对', detail: '对照直接相关代码真源，修正事实错误并提出归档建议' },
  ],
}

// args:
//   roots:     必填；要核对的文档目录或 Markdown 文件绝对路径数组。
//   truth:     可选；调用者已经确认的代码/规范真源路径数组。
//   groupSize: 可选；每组最多文档数，缺省 10。
const REPO = '/home/lyg/PA/ysyx-workbench'
const PROTOCOL = REPO + '/.github/instructions/doc-lifecycle.instructions.md'
const roots = (args && Array.isArray(args.roots)) ? args.roots.filter(Boolean) : []
const truth = (args && Array.isArray(args.truth)) ? args.truth.filter(Boolean) : []
const groupSize = (args && args.groupSize) ? args.groupSize : 10

if (!roots.length) {
  return {
    error: 'doc-lifecycle-audit 需要显式 roots；不会默认扩展到整个 workspace 或固定 NPC 文档集',
    groups: [],
  }
}

phase('盘点')
const INVENTORY = {
  type: 'object', required: ['groups'],
  properties: {
    groups: { type: 'array', items: { type: 'object', required: ['key', 'files', 'code_hint'], properties: {
      key: { type: 'string', description: '组名，kebab-case' },
      files: { type: 'array', items: { type: 'string' }, description: '本组文档的绝对路径' },
      code_hint: { type: 'string', description: '直接相关的代码或规范真源提示' },
    } } },
  },
}

const inventory = await agent(
  `你是文档盘点员。只枚举调用者明确给出的 roots 内的 Markdown，不得扩展范围。\n` +
  `roots:\n${roots.join('\n')}\n` +
  `排除 history/archive、task-run、cache、backup 和生成包，除非调用者把其中某个具体路径显式列为 root。` +
  `按主题分组，每组最多 ${groupSize} 份，并为每组指出直接相关的代码/spec/test 真源。输出绝对路径。全程中文。`,
  { label: '盘点', phase: '盘点', schema: INVENTORY })

if (!inventory || !inventory.groups || !inventory.groups.length) {
  return { error: '给定范围内没有可核对文档，或盘点失败', groups: [] }
}

log('盘点完成:' + inventory.groups.length + ' 组,共 ' +
  inventory.groups.reduce((count, group) => count + group.files.length, 0) + ' 份')

phase('核对')
const AUDIT = {
  type: 'object', required: ['group', 'results'],
  properties: {
    group: { type: 'string' },
    results: { type: 'array', items: { type: 'object', required: ['file', 'verdict', 'summary'], properties: {
      file: { type: 'string' },
      verdict: { type: 'string', enum: ['CURRENT', 'DRIFT_FIXED', 'ARCHIVE_SUGGESTED'] },
      summary: { type: 'string', description: '直接证据、实际修正或归档理由' },
      current_ref: { type: 'string', description: '归档建议对应的当前真源，可选' },
    } } },
  },
}

const truthNote = truth.length
  ? `调用者提供的真源:\n${truth.join('\n')}\n仍只核对当前问题直接相关的内容。`
  : '没有预先给定真源；按每组 code_hint 读取最小必要代码/spec/test，不做全仓审计。'
const common =
  `先读当前文档生命周期原则:${PROTOCOL}\n${truthNote}\n` +
  `逐份判断 CURRENT、DRIFT_FIXED 或 ARCHIVE_SUGGESTED。事实仍有效但描述错误时做最小就地修正；` +
  `只有当前入口已被替代或实体不存在时提出归档建议。不要移动或删除文件，不刷新全局索引，不创建 ` +
  `task-run/memory/hash/marker，也不要运行与文档结论无关的 RTL、系统或 PPA 回归。每个结论给出直接证据。全程中文。\n`

const results = (await parallel(inventory.groups.map(group => () =>
  agent(common + `\n分组:${group.key}\n代码真源提示:${group.code_hint}\n文档:\n` + group.files.join('\n'),
    { label: 'doc-check:' + group.key, phase: '核对', schema: AUDIT })
))).filter(Boolean)

const archiveSuggestions = []
for (const result of results) {
  for (const item of result.results) {
    if (item.verdict === 'ARCHIVE_SUGGESTED') archiveSuggestions.push(item)
  }
}

return {
  groups: results,
  archive_suggestions: archiveSuggestions,
  next_steps: '仅在调用者决定归档且准确目标、引用方和未提交修改已核对后，再执行可恢复的移动；不自动创建 task-run、memory 更新或全局索引刷新。',
}
