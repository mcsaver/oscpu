RV64 RTL 结论｜对象=`OooIntBackend` SQ retry、`OooMemAxiBridge` `S_SQ_QUERY/drop0`、`OooMemOwnerTerminalCollector` terminal ingress、`OooLsuAxiLaneAdapter.final_b_fallthrough_w`｜周期/配置=C0 full-flush barrier→C1 flush，337de8bf，Icarus `-g2012 -DOOO_ASSERT`，mapped 5 ns proxy｜TB/EDA 观测=V9R 2/2 baseline PASS、3/3 compile-success mutation 拒绝，adapter 正负向闭合，L0-L3 PASS，5 ns hard gate FAIL｜范围=PASS

结论：现有证据足以把 f7a 的 V9P VD4 结论续接到当前 `sha256:337de8bf9bb72a57ab50570313521cd282c49f88df9cb88417c47673af4a6968`。该 PASS 仅表示历史缺陷的当前设计 VD4 rebind；不表示 5 ns timing、PPA、`ARCH_STABLE` 或 complete-design promotion 合格。

1. 不可变 9ac1 事件

- 冻结设计为 `sha256:9ac1ae14...26207a`，原始 runner 状态保持 `FAIL rc=2`，marker 为 `[S2-G1-TCOLL-INGRESS-DUP]`。
- 两条 marker 来自 live console 与 bounded console-tail 对同一 commit/PC/fatal 序列的重放，只对应一个物理 DUT assertion event，不能解释成两个事件。
- 冻结实例属于哪个 bank/lane pair，以及其 `{kind,token,epoch}` tuple，均未保存在原始日志中，必须保持 UNKNOWN。
- `[2,10]` 与 `[4,11]` 只是后来分别对 bank0 `mem_drop0 + mem_retry0_cancel`、bank1 `mem1_drop0 + mem_retry1_cancel` 的可复现实例，不得回填为冻结实例事实。

2. C0/C1 根因与当前 RTL

- 旧 V9P 在 C0 同时发生：Backend 暴露 retry credit、捕获 MIQ owner 并 pop；Bridge 因 barrier 保持同一 `S_SQ_QUERY` owner。C1 flush 时 Bridge 产生 `drop0`，Backend retry holder 产生 cancel，collector 两条 ingress 携带同一 token，从而 fail-loud。
- 当前 `OooIntBackend.v` 的两个 retry-ready 均含 `!control_full_flush_barrier_w`，而 capture 依赖 retry-ready；当前 `OooMemAxiBridge.v` 的 `sq_query_retry_fire_w` 含 `!control_full_flush_barrier_i`，且 barrier 优先保持 `S_SQ_QUERY`。
- 因此 C0 owner 只保留在 Bridge；C1 flush 由 `active_drop_terminal_r` 产生唯一 `mem0_drop0_valid_o`。Backend 不再持有同 owner 的新 retry 副本。
- `OooMemOwnerTerminalCollector` 未增加去重或合并：同 token 多 ingress 会同时拒绝并触发 `[S2-G1-TCOLL-INGRESS-DUP]`；当前 12-ingress TB 的 66 组重复 lane pair 全部保持 fail-loud 语义。

3. 当前源字节绑定

- `OooIntBackend.v`：`8b95b9ad899de4bbe461fcde3d68df8e2d379fa39d532beadfc89889cad74d0e`
- `OooMemAxiBridge.v`：`86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348`
- 两者与 f7a 修复证据中的精确 SHA 完全一致；337de8bf 与 f7a 的整体 design-id 差异来自其它 RTL 字节，不改变该修复锥。
- Adapter 当前 SHA 为 `6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22`，也与 f7a adapter closure 一致。

4. 当前 V9R

- 两个 baseline：`tb_ooo_int_backend_v9r_sq_retry_c0`、`tb_ooo_mem_axi_bridge_v9r_sq_retry_c0` 均 PASS。
- 三个编译成功负向 RTL 版本均被原断言拒绝，`make_return_code=2`：

  - bank0 ready-open：`[V9R-SQ-RETRY-C0-HANDOFF]`，`@18`
  - bank1 ready-open：`[V9R-SQ-RETRY-C0-HANDOFF]`，`@39`
  - bridge retry-fire-open：`[V9R-MEM-SQ-RETRY-C0-HANDOFF]`，`@24`

- 三份日志均保留 `FATAL`、`[RESULT] FAIL status=1` 与 337de8bf design-id；编译镜像清理后保留数为 0。没有 assertion waiver、terminal dedup 或断言弱化。

5. Adapter final-B 时序

- `d_axi_bready_o` 仅由 `state_q == S_W_RESP` 决定。
- 最终 beat 的 `d_axi_bvalid_i` 在同周期经 `final_b_fallthrough_w` 呈现 `u_axi_bvalid_o/u_axi_bresp_o`；上游反压时同一边沿捕获 `u_bresp_q`，随后由 `S_B_RESP` 稳定保持。非最终 split B 不得泄漏到上游。
- 正向 causal probe：store terminal 周期 `2/4/7`，peer admission `4/6/9`。
- `no-final-b-fallthrough` 编译成功负向版本把周期移到 `3/5/8` 和 `5/7/10`，被 `adapter final-B fall-through absolute latency mismatch` 拒绝，`MAKE_RC=2`；生产 Adapter SHA 前后不变。
- mapped 5 ns proxy 的 candidate WNS 为 `-18.121620178 ns`、TNS 为 `-495447.71875 ns`，40 条路径违例。因此必须保持 `FAIL_NOT_PROMOTABLE`。

6. 当前分层回执

- L0：113/113 module TB PASS，RTL assertion failures=0；包含 collector 与 adapter TB。
- L1：AM 61/61、official 177/177、DiffTest mismatch=0，11/11 evidence mutation 被拒绝。
- L2：PASS，6,098,497 commits / 9,879,662 cycles。
- L3 lightweight Linux：PASS，24,459,262 commits / 57,112,863 cycles，包含 kernel power-down 与 syscon poweroff。
- L2/L3 是 exact-current-input sealed identity 回执而非本节点新跑 guest；均绑定 337de8bf 且无 live drift。
- Ubuntu 22.04/systemd 全量运行仍为 `NOT_RUN_EXPLICIT_REQUEST_ONLY`。

反例与边界：

- 存活的阻断反例：无。
- 历史 split-owner 反例和四个 compile-success mutation 都被当前门禁检出。
- 替代微架构可以选择“C0 原子转移给 Backend、Bridge 同拍释放”，但这不是当前 RTL；需要全新的唯一 owner invariant 与 TB。
- JSON 兼容的 `alternative_hypotheses` 应保留为：未来 Backend、Bridge 或 lane-adapter 任一源字节变化，必须重新进行 current-design directed rebind。
- `scope_extension_request=None`；`gaps=[]`。
- `confidence_and_basis=HIGH`：基于直接 RTL 检查、实际 SHA、保留日志 marker、负向版本和同 design-id L0-L3 receipts。未越权执行 Python；没有字段级“非预期返回码”。

[V15Q-V9P-CURRENT-REBIND] PASS
FROZEN_INSTANCE_LANE_PAIR=UNKNOWN
FROZEN_INSTANCE_OWNER_TUPLE=UNKNOWN
CURRENT_V9R=PASS_2_BASELINES_3_MUTATIONS
ADAPTER_TIMING_HARD_GATE=FAIL_NOT_PROMOTABLE
ASSERTION_POLICY=PRESERVED_FAIL_LOUD_NO_DEDUP
GAPS=NONE

所有合同内 WSL 只读命令均已退出，未残留工程进程，shell ownership 已归还主节点。
