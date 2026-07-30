# V11B evidence index

## Canonical bounded evidence

| 路径 | SHA-256 | 结论 |
| --- | --- | --- |
| `evidence/semantic-coverage-ledger.json` | `85e176b99816e4126b7e4a269af37a63eca82e3e58e345b4e4431b980405acf6` | 44 units / 17 instances / 50 bindings；3 PASS / 41 GAP |
| `evidence/terminal-collector-lane-contract.json` | `1353ac2d876260dbb30ecdc69dcf812b65d6977082f87f4ef6bd77d1bc495f00` | 12 ingress / 2 tracker-free / accepted-only PASS |
| `evidence/terminal-collector-attempt-3/summary.json` | `b41598a5ee849033080c1d870c4f3cac3dba83d171a6c4384758b3bf234b57e5` | 2/2 profiles、unknown negative、3/3 mutations PASS |
| `subagent-contracts/v11b-holder-semantic-coverage-final-review.json` | `49177c45a363d2953e59387018e8d82675543ab3415cba89b1e5f90368a18f80` | read-only independent review contract |
| `final-reviewer-report.md` | `938ea351c45856c8a2e00b34838c7f6ba2c5f031615cda8e8721621859062aeb` | collector bounded PASS；41/44 GAP retained |

## 保留的反例与失败

- `evidence/terminal-collector-attempt-1/`：mutator anchor 不成立；
- `evidence/terminal-collector-attempt-2/`：same-edge 变异未切断 pending guard，
  不具判别力；
- `evidence/currentness-rebind-attempt-21/`：10 个 canonical closed debt 的
  `semantic_evidence:GAP`，原始 FAIL 保留。

## 证据消费边界

canonical ledger 只闭合 collector 的三个语义单元。attempt-1/2 和
currentness attempt-21 不参与 PASS 聚合，但必须保留用于审计反例和防止历史改写。
