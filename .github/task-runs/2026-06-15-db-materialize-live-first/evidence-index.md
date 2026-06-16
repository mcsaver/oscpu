# Evidence Index: DB Materialize Live First

| Evidence | Result |
| --- | --- |
| `materialize --prune-non-retained` | PASS: documents=2349, pruned_non_retained=102 |
| stored kind count | PASS: dispatch-log=758, memory=3, memory-module=10, task-report=802, task-run=674 |
| `audit-db-first` | PASS: candidates=2247, stored=2247, materialized=2247, shims=0 |
| `audit-markdown-coverage --fail-on-live-evidence` | PASS: active_md=2311, db_owned=2247, shims=0, live_evidence=0 |
| `schema-audit` | PASS |
| `policy-audit` | PASS: live indexed agents=18 |
| `report-audit` | PASS |
| `artifact-audit` | PASS |
| `delivery-audit` | PASS |
| `branch-health-audit` | PASS |
| `trace-audit` | PASS |
| `skill-audit` | PASS |
| `profiles agent-system` | PASS: source=live-or-stored |
| `resolve-profile agent-system` | PASS: source=live-or-stored, expanded_node_count=9 |
| `brief agent-system --profile agent-system` | PASS: source=live-or-stored |
| full `rebuild` | BLOCKED BY SCALE: timed out twice; residual process stopped and targeted refresh used |
