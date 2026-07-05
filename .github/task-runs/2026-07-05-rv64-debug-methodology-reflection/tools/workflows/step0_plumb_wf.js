export const meta = {
  name: 'flush-contract-step0-plumbing',
  description: '为 INV-1..4 落实真实信号，产出能直接编译的 in-RTL 立即断言（Step 0：gate baseline 1→5）',
  phases: [{ title: '落实断言信号' }],
}

const RV = '/home/lyg/PA/ysyx-workbench/npc/rv64'
const SPEC = `${RV}/design/specs/ooo-flush-redirect-contract.md`

const SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    invs: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          inv_id: { type: 'string' },
          module_file: { type: 'string', description: '断言落点模块（相对 npc/rv64）' },
          feasible: { type: 'boolean', description: '能否用现有/最小引出信号编码成可编译立即断言' },
          real_signals: { type: 'array', items: { type: 'string' }, description: '落实到的真实信号名 + file:line（替换 spec 草案占位名）' },
          plumbing_needed: { type: 'array', items: { type: 'string' }, description: '若某比较点非现成，需引出的中间 wire：给出 wire 声明 + assign + 在模块哪行加（最小 plumbing）' },
          assertion_code: { type: 'string', description: '能直接粘贴进模块的完整 `ifdef OOO_ASSERT ... $error(...) `endif 块，用真实信号名，不用占位名' },
          insertion_anchor: { type: 'string', description: '插入位置的锚点（endmodule 前 / 某信号声明后），给可精确 Edit 的上下文' },
          violation_test: { type: 'string', description: '怎么临时改成必然违约以验证断言会响（具体到改哪个条件），以及用哪个 module-TB 跑' },
          coverage: { type: 'string', description: '活路径每拍走 / 仅 OOO_CSR_QUEUE_HEAD=1 exercise' },
          risk_notes: { type: 'string', description: '零行为风险确认 + 任何存疑' },
        },
        required: ['inv_id', 'module_file', 'feasible', 'real_signals', 'plumbing_needed', 'assertion_code', 'insertion_anchor', 'violation_test', 'coverage', 'risk_notes'],
      },
    },
  },
  required: ['invs'],
}

function task(invs, focus, files) {
  return `你在把已冻结的 flush 契约(${SPEC})的承重不变量落成**能直接编译的 in-RTL 立即断言**（Step 0，assert-then-converge 第一步，零行为风险）。

负责：**${invs}**。${focus}

先读 spec §4「不变量」的断言草案（${SPEC} 第 173-230 行）拿到契约意图；但**草案里的信号名（如 e1_win_w / mux_untracked_pc_w / seq263_override_pc_w / head0_csr_commit_w / younger_branch_mispredict_w / core_serial_flush_w / sq_empty_w）是"契约要求引出的比较点、非现成即取"** —— 你的任务是读真实 RTL 把它们落实成**真实存在的信号**，或设计**最小引出**（wire 声明 + assign）。

只读这些模块（Read + grep，逐信号 file:line 佐证）：
${files.map(f => `  - ${RV}/${f}`).join('\n')}

对每条 INV 产出：
1. **能直接粘贴、能编译**的 \`ifdef OOO_ASSERT ... $error(...) \`endif 断言块，**用真实信号名**（不是占位名）。断言必须是过程式 always @(posedge clk)（禁 SVA |->/$stable）；跨拍不变量用影子寄存器。
2. 若某比较点非现成：给出最小 plumbing（wire 声明 + assign + 加在模块哪行），优先复用现有信号，实在没有才引出。
3. 插入锚点（可精确 Edit 的上下文，如 endmodule 前）。
4. 制造违约验证法（临时改哪个条件让它必然 fire + 用哪个 module-TB 跑，参考 testbench/tests/ 下对应 TB）。
5. 覆盖（活路径每拍 / 仅 flag=1）+ 零行为风险确认。
关键：断言编码**独立于 RTL 的真理**（来自契约/ISA，不是照抄实现），且**非真空**（前件在活路径会为真）。忠实 RTL，信号不确定就标"存疑+证据"，宁可保守。`
}

phase('落实断言信号')
const thunks = [
  () => agent(task('INV-1（untracked 重定向两落点 PC 一致）+ INV-2（同拍至多一个 redirect 源赢，onehot0）',
    'INV-1：spec 说 OooFetchRequestMux 的择一 与 OooFetchPcOutstandingSequencer :263 override 两处人工同步「untracked>direct」，要 assert 两落点 PC 相同。INV-2：把各源"我赢了"谓词凑成 onehot0。读这两个模块找真实的 mux 结果、seq override、各源 win 谓词信号。',
    ['vsrc/frontend/OooFetchPcOutstandingSequencer.v', 'vsrc/frontend/OooFetchRequestMux.v']),
    { label: 'plumb:INV-1+2', phase: '落实断言信号', schema: SCHEMA, effort: 'high' }),
  () => agent(task('INV-3（CSR-commit ⊥ younger-branch-mispredict 同拍互斥，GAP-2）',
    '读 OooControlPlane 找 CSR-commit redirect 谓词 与 younger-branch mispredict 谓词。注意 spec 说这条只在 OOO_CSR_QUEUE_HEAD=1 被 exercise（默认 head0_csr_commit≡0），断言仍落但覆盖标 flag=1。',
    ['vsrc/control/OooControlPlane.v', 'vsrc/frontend/OooFetchPcOutstandingSequencer.v']),
    { label: 'plumb:INV-3', phase: '落实断言信号', schema: SCHEMA, effort: 'high' }),
  () => agent(task('INV-4-serial（serial_flush 恒在 SQ 空拍触发，铁律①构造不变量）',
    '读 OooRob/OooControlCommitSequencer 找 core_serial_flush 触发信号，OooStoreQueue 找 sq_empty。assert serial_flush 触发时 SQ 必空。spec 说仅 flag=1 exercise。',
    ['vsrc/writeback/OooControlCommitSequencer.v', 'vsrc/writeback/OooRob.v', 'vsrc/memory/OooStoreQueue.v']),
    { label: 'plumb:INV-4', phase: '落实断言信号', schema: SCHEMA, effort: 'high' }),
]
const results = (await parallel(thunks)).filter(Boolean)
const allInvs = results.flatMap(r => r.invs || [])
return { invs: allInvs, count: allInvs.length }
