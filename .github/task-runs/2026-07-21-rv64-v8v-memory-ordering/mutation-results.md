# OOO-3 LQ compile-success mutation results

- source SHA-256: `4287aa7c746391d522bebcfceb481c01127d35f248da3cc025b5efdef15cf427`
- mutations: `9/9` rejected by dynamic hardware oracles
- all passed: `true`

| Mutation | Compile | Dynamic reject | Exact oracle | Result |
| --- | --- | --- | --- | --- |
| pid_index_only | PASS | PASS | `same ROB index with stale generation is issue-closed` | PASS |
| issue_killed_bypass | PASS | PASS | `launched younger load remains issue-closed tombstone` | PASS |
| query_metadata_bypass | PASS | PASS | `retry with changed final PA fails closed` | PASS |
| response_order_bypass | PASS | PASS | `allow opens response while replay stays ordered-closed` | PASS |
| terminal_releases_normal | PASS | PASS | `normal transport terminal retains retire-resident entries` | PASS |
| flush_drops_launched | PASS | PASS | `selective recovery clears unlaunched younger load only` | PASS |
| release_before_completion | PASS | PASS | `retirement before formal completion is backpressured` | PASS |
| dual_alloc_same_slot | PASS | PASS | `dual dispatch must create two LQ residents` | PASS |
| dual_query_same_pid_bypass | PASS | PASS | `same-PID dual query fails closed on both ports` | PASS |
