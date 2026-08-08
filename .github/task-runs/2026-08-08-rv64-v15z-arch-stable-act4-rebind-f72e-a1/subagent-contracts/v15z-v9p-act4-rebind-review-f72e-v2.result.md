RV64 RTL 结论｜对象=`OooIntBackend`/`OooMemAxiBridge` C0 retry handoff、`OooMemOwnerTerminalCollector`、`OooLsuAxiLaneAdapter`、ACT4/分层签核收据｜周期/配置=`f72e1fb4…`、C0 full-flush→C1 flush、`OOO_ASSERT=1`、默认 L0+L1+L2+L3｜TB/EDA 观测=V9R 2/2 基线、3/3 编译成功负向变体被检出、L0 113/113、ACT4 100/100、STA WNS=-13.38258934 ns｜范围=PASS（RTL/验证语义重绑定；旧 v1 机器收据需更新）

- 当前设计：相关生产 RTL 现场哈希与 f72e 证据完全一致：
  - `OooIntBackend.v` `bf07ac64…`
  - `OooMemAxiBridge.v` `86299fad…`
  - `OooLsuAxiLaneAdapter.v` `6d81b143…`
  - `OooMemOwnerTerminalCollector.v` `d904f13a…`
  当前 ACT4、layered、system-recertification 与 PPA 收据均声明 design-id `sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`。

- V9R/C0 修复：backend bank0/bank1 的 `mem*_sq_query_retry_ready_o` 均受 `!control_full_flush_barrier_w` 门控；bridge 的 `sq_query_retry_fire_w` 同样受 `!control_full_flush_barrier_i` 门控，C0 保留 bridge owner、禁止 retry holder 分裂。2/2 基线 PASS；`backend-bank0-ready-open`、`backend-bank1-ready-open`、`bridge-retry-fire-open` 三个编译成功负向 RTL 变体分别被 `[V9R-SQ-RETRY-C0-HANDOFF]`、`[V9R-MEM-SQ-RETRY-C0-HANDOFF]` 检出，`make_return_code=2`。

- exactly-once/fail-loud：collector 对同拍重复 token 两路均不接纳，并在 `OOO_ASSERT` 配置下以 `[S2-G1-TCOLL-INGRESS-DUP]` `$fatal`，不存在选择一路、合并或去重后继续 PASS 的路径；pending、同拍重入、双输出重复和守恒均有 fail-loud 断言。当前日志包含 `[V12A-TCOLL-LANE-PAIR-MATRIX] duplicate=66 distinct=66 PASS`、12-ingress capture/drain PASS。adapter 最终 B fallthrough 仍在，当前 TB PASS；`no-final-b-fallthrough` 编译成功变体被绝对 owner-terminal latency oracle 检出，生产哈希前后相同。

- ACT4/default signoff：`act4-current.json` 为 100/100 PASS、100 个唯一 terminal PASS、零 terminal fail/RTL assertion failure；其哈希 `5a6acd5b…` 已作为 `L1_FULL_CORE_DIFFTEST.required_subcohorts.act4_architectural_certification` 的强制收据。默认合取仍为 L0/L1/L2/L3。L2、L3 均为 `execution_reused=true`、`guest_rerun=false`，只重放 sealed 收据并核对 policy-only drift，没有冒充新 guest 执行。

- 边界：Ubuntu 22.04/systemd 为 `NOT_RUN` 且不阻塞默认签核；whole architecture 仍 `RED`，PPA `UNPROMOTED`。5 ns STA 未过：WNS `-13.38258934 ns`、TNS `-315554.09375 ns`、Top40 全违例，故不得晋级。

- 收据注意项：旧 `v9p-current-rebind-review-f72e-v1.json` 记录的 layered/system 哈希分别为 `1d97e9e…`、`aefbc9d…`，ACT4 纳入后的现场值为 `27bd975f…`、`bbf760cf…`。这是证据/策略收据更新，不是上述 RTL 语义漂移；但旧 v1 JSON 不能继续作为 exact-current 机器收据直接复用。静态检查可见 `historical_defect_current.py::validate_v9p_current_rebind_review()` 会核对现场哈希；本合同未授权 Python 执行，因此没有定向 Python 返回码可报告。

- unknowns：不可变 V9P 失败实例的实际 bank 与 `{kind,token,epoch}` 未保留；未新跑 f72e collector fatal-removal 变异；final-B 负向变异沿用哈希未漂移证据；未重跑 L2/L3、Ubuntu、综合或 STA。
- 反例：上述三个 V9R 缺门变体和 `no-final-b-fallthrough` 均已被对应 oracle 检出。
- 替代假设：历史重复可能来自任一对称 backend bank；若另行修改 owner-terminal 周期合同，纯寄存 final-B 也可能成立，但不符合当前绝对延迟合同。
- `scope_extension_request`：语义结论无需扩展；若要闭合机器可校验 current receipt，需新合同授权生成 v2 rebind JSON，并运行 `historical_defect_current.py` 定向 verify。
- `confidence_and_basis`：高；依据相关生产 RTL 现场哈希、V9R 2/2+3/3、L0 113/113、collector/adapter 原始 marker、ACT4 100/100、当前 layered/system 与 PPA/STA 收据。完整 146-file design-id 未在本只读合同中独立重算。

所有 WSL 工程命令均已退出，WSL single-flight ownership 已归还主节点。
