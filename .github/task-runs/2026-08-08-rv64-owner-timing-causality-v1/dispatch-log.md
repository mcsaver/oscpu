# RV64 serialized drain owner lifetime dispatch

- task: `serialized-drain-owner-lifetime-review-v1`
- contract: `.github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/subagent-contracts/serialized-drain-owner-lifetime-review-v1.json`
- contract_sha256: `789a2731fd51d13744080ad8f7ba40f6851306b73870fa3e6128184e09b55799`
- scope: 本地 RV64 OoO 串行 stop owner、`backend_drained_q_i`、`mem_owner_terminalized_i` 与 memory owner collector token 的跨周期只读反例复核。
- shell_ownership: 主节点在派发后交付唯一 WSL 工程命令执行权；子节点完成、GAP 或异常时归还。
- result: `GAP`；当前组合 `mem_owner_terminalized_i` 的当拍 exact holder/collector accounting 未发现缺陷，但裸一 bit readiness 缺少跨拍 owner identity、memory birth、flush/handoff 与 FENCE/trap/exit 证明。
- result_path: `.github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/subagent-contracts/serialized-drain-owner-lifetime-review-v1.result.md`
- shell_returned: 所有只读 WSL 命令结束后已归还；主节点随后扩展读取 RunGate、pending arbiter、trap/exit sequencer 与 tracker 连接。
