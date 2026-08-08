RV64 RTL 结论｜对象=f72e `OooIntBackend.mem*_sq_query_retry_ready_o` / `OooMemAxiBridge.sq_query_retry_fire_w` / `OooMemOwnerTerminalCollector` / `OooLsuAxiLaneAdapter.final_b_fallthrough_w`｜周期/配置=C0 full-flush barrier→C1 flush，`OOO_ASSERT=1`，NpcTop mapped 5 ns｜TB/EDA 观测=V9R 2/2、编译成功负向变体 3/3 被检出、L0 113/113、L1-L3 PASS；WNS/TNS=-13.38258934/-315554.09375 ns｜范围=PASS（当前设计重绑定；STA=`FAIL_NOT_PROMOTABLE`）

**reviewed_inputs / 身份绑定**

- 合同 SHA-256 现场值为 `afc6f88c...e458b`，与声明一致。
- 当前生产 RTL SHA：
  - `OooIntBackend.v`：`bf07ac64...f6a07e`
  - `OooMemAxiBridge.v`：`86299fad...870348`
  - `OooLsuAxiLaneAdapter.v`：`6d81b143...a0e22`
  - `OooMemOwnerTerminalCollector.v`：`d904f13a...b185`
- 前两项逐字匹配 V9R `production_sources`；四项均匹配 f72e mapped `actual_synthesis_source_sha256`。adapter、adapter TB 与 causal-probe TB 也逐字匹配 V15P final-B closure 的 `6d81.../b648.../b13e...`。
- `layered-system-signoff-current.json` 现场 SHA `1d97e9e1...c48612`，与 `system-recertification-current.json.layered_signoff_receipt.sha256` 一致；L0 `result.json` 及两份指定日志哈希也与收据一致。

**cycle-level contract**

- C0：两 bank 的 `mem*_sq_query_retry_ready_o` 都含 `!control_full_flush_barrier_w`，因此 `mem_sq_retry{0,1}_capture_w=0`；bridge 的 `sq_query_retry_fire_w` 同样含 `!control_full_flush_barrier_i`，且 `S_SQ_QUERY` 在 barrier 下显式自保持。
- 因而 C0 不发生 MIQ→retry-holder 转移；bridge 保持唯一 transport holder，MIQ/tracker仅保留精确记账视图。
- C1 `flush_i`：仍处于 `S_SQ_QUERY` 的 active owner 经 `active_drop_terminal_r` 产生 `drop0` 并释放 bridge；同一 owner 不可能再从 retry lane 10/11 cancel。`[V9L-RETRY-OWNER-DISJOINT]` 另约束 active/station token 与既存 retry token 不重名。
- 这正切断不可变 V9P 序列：旧设计 C0 同时让 backend 捕获 retry holder、bridge 保留 owner，C1 再由 lane `[2,10]` 或 `[4,11]` 产生 drop/cancel 双终端。

**V9R 定向与负向 RTL**

- baseline 2/2：
  - backend：`[V9R-SQ-RETRY-C0-HANDOFF-PASS] banks=2 forced=2 natural_trap=1 PASS`
  - bridge：`[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] state=S_SQ_QUERY held=1 release=1 PASS`
- 三个编译成功负向版本均被预期拒绝：
  - bank0 移除 barrier gate：`[CHECK-FAIL] ... credit/capture`，`[V9R-SQ-RETRY-C0-HANDOFF] @18`
  - bank1 移除 barrier gate：同类 marker `@39`
  - bridge 移除 retry-fire barrier gate：`[V9R-MEM-SQ-RETRY-C0-HANDOFF] @24`
- 三者日志均为仿真期 `[RESULT] FAIL status=1`；summary 将其正确登记为 `REJECTED_COMPILE_SUCCESS_VARIANT`、`make_return_code=2`，变异 RTL/log 哈希全部现场匹配，故是有效 mutation kill，不是编译失败假绿。

**collector exactly-once**

- 当前 12 条入口保持独立 raw lane；V9P 可复现族仍映射为 bank0 `drop0/retry0 cancel=[2,10]`、bank1 `[4,11]`。
- collector 对同 token 多入口设置 `ingress_duplicate_violation_r`，两 lane 均不获 `ingress_accept_o`；在 `OOO_ASSERT` 时钟边沿触发 `[S2-G1-TCOLL-INGRESS-DUP]` 和 `$fatal`。这是 fail-loud 合同，不是挑一路、合并、去重或 waiver。
- 当前 TB 日志包含：
  - `[V12A-TCOLL-LANE-PAIR-MATRIX] duplicate=66 distinct=66 PASS`
  - `[V8P-TCOLL-12INGRESS-CAPTURE] pending=12 ... PASS`
  - `[V9Y-TCOLL-SAME-EDGE-REENQUEUE] accept=0 PASS`
  - `[V8P-TCOLL-12INGRESS-DRAIN] seen=12 ... PASS`
- 因此入口异常不会被“去重后继续”；合法 12-owner batch 则逐 token 保留并 exactly-once drain。

**adapter final-B**

- `final_b_fallthrough_w = !rst && state_q==S_W_RESP && d_axi_bvalid_i && !split_write_more_beats_w`；ready owner 同拍消费，stall owner同沿捕获 `u_bresp_q` 后由 `S_B_RESP` 保持。
- 当前 adapter TB 在 f72e L0 以 `-DOOO_ASSERT` PASS，源码覆盖 OKAY/SLVERR/DECERR、stall fallback、reset mask、non-final split suppression 和 `final B terminates exactly once`。
- 编译成功负向版本 `NO_FINAL_B_FALLTHROUGH`：
  - `COMPILE_SUCCESS=1`、`MUTATION_DETECTED=1`、`MAKE_RC=2`
  - production SHA before/after 均为 `6d81...a0e22`
  - store terminal 从 `2/4/7` 退为 `3/5/8`，peer admission 从 `4/6/9` 退为 `5/7/10`
  - oracle：`adapter final-B fall-through absolute latency mismatch`
- 该证据证明当前零 bubble 时序路径与 oracle 绑定，但不证明这是唯一可行微架构。

**L0-L3 / STA 边界**

- L0：f72e、`OOO_ASSERT=1`、113/113、assertion failure 0。
- L1：official 177/177、AM 61/61、DiffTest mismatch 0、证据变异 11/11 被检出。
- L2：6,098,497 commits / 9,882,568 cycles，终端 marker 各一次，assertion failure 0。
- L3：24,460,280 commits / 57,129,353 cycles，kernel power-down、good trap、syscon poweroff、system reset 各一次，assertion failure 0。
- L2/L3 是 sealed exact-current-input reuse，`guest_rerun=false`；不是本节点重新执行。
- 5 ns mapped receipt 虽 `status=PASS`，该字段仅表示候选证据采集成功：`target_200mhz_met=false`、`minimum_promotion_margin_0p1ns_met=false`、Top40 全违例，WNS/TNS 为 `-13.38258934/-315554.09375 ns`。系统收据明确 `ppa=UNPROMOTED`、`whole_architecture=RED`。不得写成 STA PASS 或 promotion。
- `adapter_tokens_in_top40=0`，不能据此把 final-B 认定为当前最差时序根因。

**unknowns / counterexamples / alternative_hypotheses**

- 不可变 V9P 仅确定物理 assertion event 为 1；console marker 重复两行。实际 bank、ingress lane 和 `{kind,token,epoch}` 仍为 `UNKNOWN_NOT_RETAINED_IN_IMMUTABLE_LOG`。`[2,10]/[4,11]` 是动态复现族，不是对冻结实例的反向猜测。
- 未执行形式化穷尽证明；Ubuntu 22.04/systemd 未运行。允许路径未包含顶层 glue，故 net continuity 未做独立源码级审计；当前 endpoint RTL、f72e 全设计身份及 L1-L3 集成收据彼此一致，未发现绑定漂移。
- 替代解释：冻结 V9P 可能来自任一对称 bank；final-B 也可由另一种保持相同同拍可见性的实现完成；当前 STA 失败更可能由其它 Top40 cone 或大量未约束 endpoint 主导，不能由本证据归因给 adapter。
- 未发现当前 f72e 反例；三个 V9R 缺门变体及 final-B 禁用变体均被定向 oracle 检出。

`scope_extension_request=none`。若未来要求顶层 net continuity 或形式化 exactly-once 证明，应另立合同加入实际 bridge/adapter glue 与 formal harness；不影响本次基于当前身份和既有集成收据的重绑定 PASS。

`confidence_and_basis=high`：生产源、TB、负向 RTL、日志及 L0/PPA 收据均有现场 SHA 交叉绑定；对冻结 V9P 的真实 bank/owner tuple 与形式化穷尽性保持低置信/UNKNOWN。未发生 Python/JSON schema 定向单测的意外返回。

所有只读 WSL 命令均已结束，无遗留工程进程；single-flight shell ownership 已归还主节点。
