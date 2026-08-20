RV64 RTL 结论｜对象=OooIntBackend/OooMemAxiBridge V9P C0→C1 handoff、OooLsuAxiLaneAdapter final-B、OooMemOwnerTerminalCollector 12-lane terminal path及L0-L3收据｜周期/配置=C0 barrier/C1 flush；design-id sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af；npc-rv64-ooo-current｜TB/EDA 观测=L0 114/114；V9R 2/2 + 3/3；adapter 1/1；ACT4 100/100；L1/L2/L3 PASS；未运行综合/STA｜范围=PASS

判定：历史 `HIST-V9P-TERMINAL-COLLECTOR-INGRESS-DUP` 已在当前 d3f3 生产 RTL 上达到 `VD4_REBOUND_CURRENT_DESIGN`。该 PASS 只覆盖 V9P current rebind 与同身份 L0–L3 功能收据；whole architecture 仍为 RED，PPA=UNMEASURED_UNPROMOTED。

1. 当前源码与身份绑定

- `OooIntBackend.v`：`bf07ac64ff59cf24bace41c17139704d2198406db194d5fcc42903e9a7f6a07e`
- `OooMemAxiBridge.v`：`86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348`
- `OooLsuAxiLaneAdapter.v`：`6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22`
- `OooMemOwnerTerminalCollector.v`：`d904f13af077b9abf72f9ba8eb2b37911b2e9a593b4933124818191d1487b185`

四个 live SHA-256 均与 `evidence/module/inputs.post.json` 一致；module pre/post 输入哈希相同。当前 module result SHA-256 为 `88c098ab…abc202`，并绑定 d3f3。

历史 immutable 失败属于 `sha256:9ac1…207a`；V15G 的 f7a 修复审查和 f72e ACT4 rebind 仅作为 predecessor。`v9p-act4-rebind-review-f72e-v2.json` 不得改写为 d3f3 current，本结论使用本轮 d3f3 V9R、module、layered、system 与 ACT4 收据重新绑定。

2. C0 retry handoff 与 C1 terminal

在 `OooIntBackend.v` 中，两 bank 的 `mem_sq_query_retry_ready_o`、`mem1_sq_query_retry_ready_o` 均显式包含 `!control_full_flush_barrier_w`；`mem_sq_retry0_capture_w`、`mem_sq_retry1_capture_w` 又依赖对应 ready。因此 C0 barrier 时既不返回 retry credit，也不把 MIQ owner 捕获进 bank-local retry holder。

在 `OooMemAxiBridge.v` 中，`sq_query_retry_fire_w` 包含 `!control_full_flush_barrier_i`；`S_SQ_QUERY` 在 barrier 分支保持原状态。到 C1 `flush_i` 时，`active_drop_terminal_r` 对 `S_SQ_QUERY` 产生一次 `drop0`，同一时钟边沿 FSM 转入 `S_IDLE`。由于 C0 未形成 retry holder，C1 不会再由 `mem_retry*_global_cancel_w` 为相同 tuple 产生第二 terminal。

V9R 正向 2/2：

- backend：`[V9R-SQ-RETRY-C0-HANDOFF-PASS] banks=2 forced=2 natural_trap=1 PASS`
- bridge：`[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] state=S_SQ_QUERY held=1 release=1 PASS`

三个编译成功负向 RTL 版本全部被定向测试检出：

- `backend-bank0-ready-open`：命中 `[V9R-SQ-RETRY-C0-HANDOFF]`，C0 credit/capture 检查失败，`[RESULT] FAIL status=1`
- `backend-bank1-ready-open`：同一 marker，`[RESULT] FAIL status=1`
- `bridge-retry-fire-open`：命中 `[V9R-MEM-SQ-RETRY-C0-HANDOFF]`，`[RESULT] FAIL status=1`

三者均先完成 Icarus 编译并进入仿真 fatal，`make_return_code=2` 是预期测试拒绝结果，不是编译失败；负向源码和日志 SHA 与 `v9r/summary.json` 一致。

3. Adapter final-B terminal 周期

当前 `OooLsuAxiLaneAdapter` 在 `S_W_RESP && d_axi_bvalid_i && !split_write_more_beats_w` 时令 `final_b_fallthrough_w=1`，同周期产生 `u_axi_bvalid_o`；若上游未 ready，则该边沿把响应保存在 `S_B_RESP`。当前绝对 owner-terminal 周期合同为 `2/4/7`。

`no-final-b-fallthrough` 编译成功负向版本同时禁用 fall-through 并恢复强制注册 `S_B_RESP`，观测周期变为 `3/5/8`，命中：

`[OWNER-TIMING-CAUSAL-PROBE][FAIL] adapter final-B fall-through absolute latency mismatch`

结果为 `COMPILE_SUCCESS=1`、`MUTATION_DETECTED=1`、`EXPECTED_TEST_FAILURE=1`、`MAKE_RC=2`，且 production SHA before/after 均为 `6d81…0e22`。当前 d3f3 L0 的 `tb_ooo_lsu_axi_lane_adapter` 同时为 PASS。故 adapter 1/1 负向版本闭合当前周期 oracle。

4. Collector fail-loud exactly-once

`OooIntBackend` 将两路 response、四路 bridge drop、两路 reservation terminal、buffer cancel、AMO interphase cancel 与两个 retry cancel，作为固定 12 路 raw ingress 直接送入 `OooMemOwnerTerminalCollector #(.INGRESS_N(12))`；lane assignment 不是优先选择。

Collector 对每一 ingress lane 与其余 11 路逐一比较 token。同 token 的两路都会置位 `ingress_duplicate_violation_r`，两路 `ingress_accept_o` 都为 0，不存在择一路、合并或去重后继续 PASS。只有 collector-accepted ingress 才进入 `mem_terminal_accept_mask_w` 并证明 holder handoff；raw duplicate 仍留在 unterminated-holder accounting 中。

在 `OOO_ASSERT` 配置下，重复 ingress 以 `[S2-G1-TCOLL-INGRESS-DUP]` 和 `$fatal` fail-loud；去掉断言的综合数据通路仍是 fail-closed 拒绝，而非静默释放 owner。pending collision、same-edge dequeue/re-enqueue、双输出同 token 与计数守恒也分别有 fatal 约束。

当前 collector TB 观测：

- `[V12A-TCOLL-LANE-PAIR-MATRIX] duplicate=66 distinct=66 PASS`，覆盖 12 路全部 `C(12,2)=66` lane pair
- 12 ingress capture/drain、两 dequeue lane turnover、same-edge reenqueue 均 PASS
- L0 编译启用 `-DOOO_ASSERT`，当前 d3f3 日志为 PASS

因此不存在选择一路、合并或去重后继续 PASS 的假绿。

5. L0–L3 与 ACT4

- L0：114/114，RTL assertion failures=0。
- L1：official 177/177、AM 61/61、DiffTest mismatch=0、证据 mutation 11/11；当前 guest 已 rerun。
- ACT4：`npc-rv64-ooo-current` 100/100，assertion failures=0，design-id=d3f3。101 个生成用例中唯一排除项为 policy 明示的互斥 `sv39_svnapot_not_supported_Smode`，并由四个必测 Svnapot 正向/保留编码用例替代；这不是 terminal ingress 的择一路或去重。
- L2：PASS，design-id=d3f3，sealed exact-current-input replay，RTL assertion failures=0。
- L3：PASS，design-id=d3f3，sealed exact-current-input replay，RTL assertion failures=0。
- L2/L3 的 guest 本轮未重跑，不能表述成 fresh guest execution；其 current identity 依赖 sealed inputs、source identity 和收据重算。
- `system-recertification-current.json` 中 layered pointer SHA 为 `3e9cf0e0…d6a06`，与当前 `layered-system-signoff-current.json` live SHA 一致。
- ACT4 receipt SHA 为 `5d57a531…3a56b`，policy SHA 为 `a823f467…3504`，彼此一致。
- Optional Ubuntu 22.04/systemd：NOT_RUN，不属于默认 L0–L3 conjunction。

6. 反例与边界

`counterexamples`：

- backend-bank0-ready-open was rejected by `[V9R-SQ-RETRY-C0-HANDOFF]`
- backend-bank1-ready-open was rejected by `[V9R-SQ-RETRY-C0-HANDOFF]`
- bridge-retry-fire-open was rejected by `[V9R-MEM-SQ-RETRY-C0-HANDOFF]`
- no-final-b-fallthrough was rejected by the absolute owner-terminal latency oracle

`unknowns`：

- immutable V9P instance bank is not retained
- immutable V9P kind/token/epoch owner tuple is not retained
- no fresh d3f3 collector fatal-removal RTL mutation was run
- current d3f3 mapped PPA has not yet been measured
- no L2/L3 guest、Ubuntu、synthesis 或 STA run was launched by this review

历史重放只证明 bank0 lane pair `[2,10]` 与 bank1 `[4,11]` 均可复现；不能据此声称 immutable 失败来自某一 bank。UNKNOWN bank/owner tuple 必须保留。

`alternative_hypotheses`：

- immutable duplicate 可能来自任一对称 bank
- registered-only final-B 在另一套 owner-terminal latency 合同下可能功能正确，但不满足当前 `2/4/7` 周期合同

`scope_extension_request=null`；`gaps=[]`。

`confidence_and_basis=HIGH_CURRENT_D3F3_SOURCE_HASHES_V9R_MUTATIONS_L0_ACT4_L3_AND_FAIL_LOUD_ASSERTIONS`

本节点合同仅授权 `rg`、`sed`、`sha256sum`，未执行 Python 定向单测，因此无非预期 schema 字段返回码可报告；已静态核对 `test_v9p_compile_success_mutation_survivor_is_rejected`、`test_v9p_current_rebind_review_cannot_claim_unmeasured_ppa` 与 `test_v9p_current_rebind_review_must_preserve_unknown_owner` 的 fail-closed 条件。

WSL single-flight ownership 已归还主节点。
