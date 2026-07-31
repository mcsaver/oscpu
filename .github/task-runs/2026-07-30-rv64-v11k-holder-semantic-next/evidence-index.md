# V11K evidence index

## Canonical 局部证据

- MIQ holder summary：
  `evidence/miq-holder-attempt-3/summary.json`
  (`7270bb30bab149970a938951cfee58a2d3f8ee5c47e0be5e7b90cec5f06cbbf4`)
- 完整两态 elaboration 恒等：
  `evidence/elaborated-logic-identity.json`
  (`886c9e72ef3561968da0d0d23a8075dfc56be69bb378aadaf96cb134207a5cf0`)
- 当前 instance graph：
  `evidence/current-instance-graph/holder-instance-graph.json`
- 当前 census audit：
  `evidence/current-census/producer-holder-census.json`
- 当前 semantic ledger：
  `evidence/semantic-ledger-current/producer-holder-semantic-coverage.json`
  (`282fbc80d5883e041b0c02b2e8fcf72c5025c1bd85531bfd9c0653266122b881`)
- 当前 V11H frozen-input checker replay：
  `evidence/v11h-attempt4-checker-replay-current/receipt.json`
  (`11313e99c0eba4d3e3edaedb859dd35c277ae0cda07c22db8dbb7e1cb0451d2a`)
- 当前 V11J bridge rebind：
  `evidence/v11j-bridge-rebind-current-v2/summary.json`
  (`4d8fe5fc4aad31cf9613fd31974bef3fa5bad1dfe22aea4927bbf5955d1a794f`)

## 历史与辅助证据

- `evidence/miq-holder-attempt-1/`：首个 PASS 矩阵；保留原始结果，不作为
  canonical source-manifest 绑定。
- `evidence/miq-holder-attempt-2/`：26-profile PASS 矩阵；终审发现
  push/pop marker 与普通回归绑定缺口，保留为 GAP 输入。
- `tools/compare_elaborated_logic.py`：比较 V11J/V11K 完整 Yosys JSON，
  只忽略 `src` 位置属性。
- `tools/rebuild_census_manifest.py`：按 frozen declaration/current graph
  恢复 census declaration 的可审计脚本。

## 当前结论

- `miq-owner-tokens`：两个产品实例局部 PASS。
- 独立复审：
  `final-review-result.md`，合同 JSON SHA-256
  `d0f7816e66e3de3826e0aafd06bf421deab048f55088b1da996feeeca1d526cb`。
- 固定 reviewer 枚举：
  `final-review-enum-followup.md`，
  `APPROVED_FOR_CURRENT_SCOPE`。
- ledger：17/44 PASS、27/44 GAP。
- architecture：RED。
- PPA：UNPROMOTED。
- V11K system rerun：未触发；理由为当前配置下两态产品 elaboration
  逻辑恒等。

## 工作流证据

- 结构化轮次状态：`round-state.json`，包含 classification、分层 identity、
  evidence state、semantic delta、成本、固定 reviewer 枚举与下一动作。
- NPC profile：
  `.github/task-runs/2026-07-30-OooMemInflightQueue/`
  （completed，5/5 节点，7 个 indexed assets）。
- AI 环境 profile：
  `.github/task-runs/2026-07-30-rtl-task-contract/`
  （completed，11/11 节点，14 个 indexed assets）。
- 本 task-run raw evidence DB index：1571 个 assets；DB 只保存索引与摘要，
  canonical 局部结论仍由上方 attempt-3、ledger、instance graph 与
  elaboration identity 文件承载。
