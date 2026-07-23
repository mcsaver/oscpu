# v8l ProducerId holder census derivation (superseded by manifest)

此表是实现前冻结输入，现保留作推导记录；权威机器账本已迁移到
`npc/rv64/design/arch/producer-holder-census.json`，并由
`npc/rv64/eval/ppa/tools/producer_holder_census.py` fail closed 校验。`direct-mask` 表示该 Q字段自身
解码进 dispatch fence；`indirect-tracker` 表示 resident只保存 memory token，full P由 tracker table
承重；`overlap-proof` 表示字段保存 full P，但生命周期必须由相邻 direct lease无空窗覆盖。

终态扫描结果为 direct full-P Q 15、ProducerId packed stage 5、token Q 12、generation authority 1；
本表不再作为自动门禁输入，也不得用于独立授予 GREEN。

| id | production path / field | kind | current coverage | v8l action |
| --- | --- | --- | --- | --- |
| rob-generation | `OooRob.slot_generation_q[]` + slot valid | authority | slot occupancy | 保持；作为 candidate真源 |
| int-iq-pid | `OooIntIssueQueue.valid_q[]/producer_id_q[]` | direct full P | 缺失 | 新增 direct-mask |
| int-ex0-pid | `u_ex0_stage.valid/payload generation+index` | packed full P | ROB/kill隐式 | 新增 transient direct-mask |
| int-ex1-pid | `u_ex1_stage.valid/payload generation+index` | packed full P | ROB/kill隐式 | 新增 transient direct-mask |
| branch-resolve-pid | `u_branch_resolve_stage.valid/payload full P` | packed full P | EX0 coherence隐式 | 新增 transient direct-mask |
| mem-res-pid | `mem_issue_res_valid_q/producer_id_q` | direct full P+token | tracker同沿 | 新增 transient direct-mask |
| mem-pending-pid | `mem_pending_q/mem_producer_id_q/token` | direct full P+token | tracker | overlap-proof + exact assertion |
| mem-buffer-token | `mem_buffer_valid_q/owner_token_q` | token indirect | tracker | indirect-tracker assertion |
| miq-token | MIQ valid owner token | token indirect | tracker | indirect-tracker assertion |
| store-queue-pid | SQ `valid_q[]/producer_id_q[]/token` | full P+token | IntIQ→tracker handoff | overlap-proof逐entry assertion |
| memory-bridge-token | external bridge residency token mask | token indirect | tracker | indirect-tracker assertion |
| mem-tracker-pid | tracker `live_q[]/producer_id_q[]/producer_live_q` | direct full P | direct mask | 保持 |
| muldiv-pid | `owner_valid_o/producer_id_q` | direct full P | direct mask | 保持 |
| clmul-pid | `owner_valid_o/producer_id_q` | direct full P | direct mask | 保持 |
| fp-iq-pid | FP IQ valid/PID array | direct full P | FP aggregate | 保持 |
| fp-issue-pid | FP issue stage packed full P | packed full P | FP aggregate | 保持 |
| fp-arith-pid | arith meta stage1..5 full P | direct full P | FP aggregate | 保持 |
| fp-exec1-pid | exec1 packed full P | packed full P | FP aggregate | 保持 |
| fp-long-pid | long meta full P | direct full P | FP aggregate | 保持 |
| fp-done-pid | done FIFO valid/PID array | direct full P | FP aggregate | 保持 |
| pending-csr-pid | sequencer raw producer valid/PID | direct full P | direct mask | 保持 |
| assert-shadows | `*_prev_q`, request check snapshots | assertion-only | EXEMPT | checker显式排除 |
| pre-rob-events | control/trap pending payload without P | pre-birth | EXEMPT | 保持无P |

实现前结论：旧 v8c `field_level_complete=false` 仍然有效；本草案本身不提升状态。只有 permanent
checker、focused handoff/wrap evidence与 mutations全部通过后，才允许生成 v8l final manifest。
