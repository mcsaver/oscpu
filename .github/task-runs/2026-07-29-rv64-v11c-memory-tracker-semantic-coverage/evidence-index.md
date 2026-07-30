# V11C evidence index

| 产物 | SHA-256 | 结论 |
|---|---|---|
| `evidence/memory-tracker-attempt-2/summary.json` | `2d138562cdf2ebfba6f55dcfdbbe46f4edeb56a14e01cbc2221037d3342ef67c` | 2/2 baseline、4/4 X-known、9/9 mutation PASS |
| `evidence/semantic-coverage-ledger.json` | `238ec62af0e82cde012c2c8ba403297886bde261bc21de0864ec34bd5719ce98` | 5 PASS / 39 GAP / 44，整体 GAP |
| `subagent-contracts/v11c-memory-tracker-semantic-pre-review.json` | `388882c1daf6b3ade38b1762f9c874be8b212f321c404ef36406a0d1891c5637` | 只读预审合同 |
| `subagent-contracts/v11c-memory-tracker-semantic-final-review.json` | `8ed5f78978c53d2c39cbcbb778c56b3319ac0f26795bce7dfcaf23e479ed2729` | 独立终审合同 |
| `../2026-07-29-memory-tracker-semantic-revtag-v11c/task-report.md` | `741152df196f2298181bc7307f37673bd2be38d856cbd67bb547c20e232d04d4` | `npc-dev` 5/5 completed、DB-published |

attempt-2 共 76 个文件、3,209,458 bytes；包含 full RTL pre/post、
focused source pre/post、2 个 baseline、4 个 unknown-negative、
9 个 mutant source/receipt/vvp/log/return-code 与 evidence tool unit log。

`evidence/memory-tracker-attempt-1/` 保留首次 PASS，但因后续 focused
Makefile/policy 漂移不再 current，policy 不引用它。

全工作树 strict guard 的 `agent-system`、`rv64-systemd-contract`、
`npc-dev` 为 PASS；共享 `Linux/scripts/check-ubuntu-rootfs.sh` 缺
`rv64-linux` evidence，保持范围外 GAP。显式绑定上述 e2e evidence 后，
V11C 12-path scoped strict guard PASS。

本技术 task-run 的 `evidence/` 共 165 个可索引资产；已由
`github_index_db.py index-evidence` 写入 `evidence_assets`，raw payload
未进入 `db_documents`。8 份 Markdown 已通过 `archive-markdown
--sync-task-run` 同步，随后 `snapshot-stored`、DB-first audit 和全局
runtime-artifact audit 均 PASS。
