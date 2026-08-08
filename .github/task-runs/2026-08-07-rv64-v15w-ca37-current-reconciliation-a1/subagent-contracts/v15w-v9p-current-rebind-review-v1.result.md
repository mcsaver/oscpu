RV64 RTL 结论｜对象=`OooIntBackend.mem*_sq_query_retry_ready_o`、`OooMemAxiBridge.sq_query_retry_fire_w/S_SQ_QUERY`、`OooMemOwnerTerminalCollector`、`OooLsuAxiLaneAdapter.final_b_fallthrough_w` 与 ca37 证据｜周期/配置=`C0 full-flush barrier → C1 flush`、`OOO_ASSERT`、5 ns mapped STA｜TB/EDA 观测=V9R 基线 2/2 PASS、编译成功负向 RTL 变体 3/3 被拒绝、L0 113/113、L1–L3 PASS、WNS=-13.694396973 ns/TNS=-398171.5625 ns｜范围=PASS（仅 V9P 机制到 ca37 的当前设计重绑定；STA=`FAIL_NOT_PROMOTABLE`）

### reviewed_inputs

- 合同 `.github/task-runs/2026-08-07-rv64-v15w-ca37-current-reconciliation-a1/subagent-contracts/v15w-v9p-current-rebind-review-v1.json` 的实际 SHA-256 为 `5d451d50c6b26b4a7b51587c7e5210ab2119a2d1a59d8f2a73c7428173a4e29d`，与派发绑定一致。
- 定向读取了四个生产 RTL、三个 TB，以及：
  - V9P root-cause summary/独立复核；
  - ca37 V9R summary、两份正向日志、三份负向 RTL 及其日志；
  - ca37 L0 module result、adapter/collector 日志；
  - 当前 layered signoff 与 system recertification；
  - final-B closure、负向 diff/result/log；
  - ca37 PPA delta 与独立复核。
- 全程只使用合同允许的 `rg`、`sed`、`sha256sum`，无写入、无仿真重跑。

### cycle-level contract

- `C0` full-flush barrier：
  - `OooIntBackend` 两个 bank 的 retry credit 都显式包含 `!control_full_flush_barrier_w`；因此 `mem_sq_query_retry_ready_o=0`、`mem1_sq_query_retry_ready_o=0`。
  - `mem_sq_retry{0,1}_capture_w` 依赖对应 retry-ready，故不会把 MIQ owner 捕获进 bank-local retry holder，也不会产生 retry-pop。
  - `OooMemAxiBridge.sq_query_retry_fire_w` 额外包含 `!control_full_flush_barrier_i`；`S_SQ_QUERY` 的 barrier 分支保持 `state_q==S_SQ_QUERY`，transport owner/payload 继续驻留 bridge，不释放给 backend retry holder。
- `C1` flush：
  - 因 `C0` 未创建 retry holder，`mem_retry{0,1}_cancel_w` 不会为该 owner 形成第二个终端入口。
  - bridge 中 `cpu_kill_w` 使 `S_SQ_QUERY` 的 active owner 经 `mem*_drop0_valid` 进入 collector；这条 raw terminal 保持原始 `{kind,token,epoch,fault_tval}`。
- `OooMemOwnerTerminalCollector`：
  - 12 条终端源逐 lane 输入，没有把相同 token 合并成一个“去重后”事件。
  - 同拍重复 token 会使所有相关 lane 的 `ingress_accept_o=0`，且 `OOO_ASSERT` 下触发 `[S2-G1-TCOLL-INGRESS-DUP]` 和 `$fatal`；pending 重复与同边 dequeue/re-enqueue 也分别 fail-loud。
  - 正常 exact ingress 被保留到双 dequeue 端口，conservation、stalled tuple hold 和双端口 token disjoint 均有断言。

### 当前源码绑定

- ca37 design-id：`sha256:ca37187e08a3ed489a20d8e05942a2fe8b33ae85904d2edb43e1df08332f9b6f`。
- `OooIntBackend.v` 当前 SHA-256 为 `bf07ac64...f6a07e`，`OooMemAxiBridge.v` 为 `86299fad...870348`；均逐字匹配 ca37 V9R summary 的 `production_sources`。
- `OooLsuAxiLaneAdapter.v` 当前 SHA-256 为 `6d81b143...3a0e22`，两个相关 TB 分别为 `b648ce4a...ddbfd`、`b13ef4cf...9bf988`；与 V15P final-B closure 的绑定完全一致。
- 当前 collector SHA-256 为 `d904f13a...7b185`；其 ca37 L0 日志携带相同 ca37 design-id。
- 当前 layered receipt SHA-256 为 `8c877416...178f3`，与 `system-recertification-current.json.layered_signoff_receipt` 一致。
- 历史 V9P summary 仍绑定旧的 f7a design-id 与旧 layered receipt；它只提供不可变历史 root cause，不能单独冒充 ca37 证据。ca37 重绑定来自当前 V9R、当前源码哈希及当前 L0–L3 收据。

### 定向基线与负向 RTL 变体

- V9R 正向基线：
  - backend：`[V9R-SQ-RETRY-C0-HANDOFF-PASS] banks=2 forced=2 natural_trap=1 PASS`；
  - bridge：`[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] state=S_SQ_QUERY held=1 release=1 PASS`；
  - 两份日志均带 ca37 design-id 和 `[RESULT] PASS`。
- 三个编译成功负向 RTL 版本均被定向断言/TB 拒绝：
  - `backend-bank0-ready-open`：C0 retry credit/capture 变为 1，触发 `[V9R-SQ-RETRY-C0-HANDOFF]`，`[RESULT] FAIL status=1`；
  - `backend-bank1-ready-open`：同类反例，bank1 被检出；
  - `bridge-retry-fire-open`：移除 barrier gate 后触发 `[V9R-MEM-SQ-RETRY-C0-HANDOFF]`，`[RESULT] FAIL status=1`。
- final-B：
  - 当前 `final_b_fallthrough_w = !rst && state_q==S_W_RESP && d_axi_bvalid_i && !split_write_more_beats_w`；ready owner 同拍消费，stalled owner 同边写入 `u_bresp_q` 后在 `S_B_RESP` 保持。
  - ca37 adapter L0 日志为 `[RESULT] PASS`。
  - 编译成功的 `no-final-b-fallthrough` 负向版本把 store terminal 周期从 `2/4/7` 推迟到 `3/5/8`、peer admission 从 `4/6/9` 推迟到 `5/7/10`，被 `adapter final-B fall-through absolute latency mismatch` 检出，外层 mutation receipt 为 PASS。

### L0–L3 与 STA 边界

- L0：`113/113`，`OOO_ASSERT` 开启、失败数 0；collector 日志包含 66 组重复 lane pair、66 组 distinct pair、12-ingress capture/drain 与 turnover PASS。
- L1：module `113/113`、official `177/177`、AM `61/61`、DiffTest mismatch 0、广义 evidence mutation `11/11`。
- L2：6,098,497 commits / 9,882,568 cycles，5 个终端 marker exactly-once，断言失败 0。
- L3：24,460,280 commits / 57,129,353 cycles，6 个终端 marker exactly-once，含 kernel power-down，断言失败 0。
- L2/L3 是 exact-current-input、无 live drift 的 sealed evidence reuse，不是本节点新跑 guest。
- ca37 5 ns STA：`target_200mhz_met=false`、WNS `-13.694396973 ns`、TNS `-398171.5625 ns`。PPA JSON 的 `status=PASS` 只表示证据收集/比较成功；工程状态必须保持 `5NS_TARGET_NOT_MET`、`UNPROMOTED`、`FAIL_NOT_PROMOTABLE`，不得提升为 timing PASS、Pareto champion 或 release。

### unknowns

- 不可变 V9P 日志只证明一次物理 `[S2-G1-TCOLL-INGRESS-DUP]` assertion event；实际 bank 和 owner tuple 均继续为 `UNKNOWN_NOT_RETAINED_IN_IMMUTABLE_LOG`。
- `[2,10]`（bank0）与 `[4,11]`（bank1）只是可重复 lane-pair family，不能回填为历史实例的真实 lane。
- Ubuntu 22.04/systemd 未运行，仍是明确 non-claim。
- collector 正向 TB 将故意重复的 raw ingress 放在非时钟边沿检查 `accept=0`；当前 fatal 合同由 RTL load-bearing assertion 和历史 assertion event 共同支撑，没有新的“删除 fatal 断言”编译成功 mutation。
- final-B 负向 mutation 没有在 ca37 aggregate 下重跑；其 adapter 与两个 TB 哈希不变、且 ca37 正向 L0 已重绑，因此足以作为文件级时序敏感性证据，但不是 ca37 全设计 timing signoff。

### counterexamples

- 三个 V9R gate-removal 版本分别重建 bank0、bank1 或 bridge 的 C0 split-ownership 窗口，均被检出；未发现能绕过现有 C0 gate 的合同内反例。
- 禁用 final-B fall-through 的版本仍可编译且保持基本协议功能，但增加一个终端周期并违反当前绝对延迟 oracle；这证明时序路径敏感，不证明 fall-through 是唯一功能正确实现。
- 若关闭 `OOO_ASSERT` 后上游仍产生重复终端，collector 会 fail-closed 地拒绝重复 lanes，而不是硬件修复或合并它们；当前 PASS 依赖上游 exactly-once 合同，不能表述为 collector 可容忍 duplicate ingress。

### alternative_hypotheses

- 历史 duplicate 可能来自任一对称 bank；不可变日志无法选择 bank0 或 bank1。
- 历史根因也可抽象为“C0 同时存在 bridge transport residency 与新 retry-holder authority，C1 两侧各自产生 terminal”；V9R 的三个独立 gate-removal 反例支持这一解释，未发现更符合当前证据的替代来源。
- final-B registered-only 实现可能在另一套性能合同下成立，但会改变当前 owner-terminal/peer-admission 周期，因此不能无条件替换现有 fall-through。

### scope_extension_request

`none`。当前合同材料足以给出 scoped ca37 重绑定 PASS。若未来要求 fresh ca37 final-B mutation replay、collector fatal-removal mutation 或 immutable V9P 精确 tuple 恢复，需要新 versioned 合同和额外执行/证据路径，不能在本节点扩展。

### confidence_and_basis

- 对 ca37 的 V9P C0/C1 机制重绑定：高置信度，依据当前源码哈希、2/2 正向、3/3 编译成功负向变体、113/113 L0 与同一 ca37 design-id 的 L1–L3。
- 对终端 fail-loud/no-dedup 合同：高置信度，依据 12-lane RTL、`[S2-G1-TCOLL-INGRESS-DUP]`、collector TB marker 与断言开启的分层收据。
- 对 immutable 历史 bank/tuple：保持 UNKNOWN，不作概率性回填。
- 对 5 ns promotion：确定为失败且不可提升。

只读工程批次已结束，无工程进程保留；WSL single-flight ownership 已归还。
