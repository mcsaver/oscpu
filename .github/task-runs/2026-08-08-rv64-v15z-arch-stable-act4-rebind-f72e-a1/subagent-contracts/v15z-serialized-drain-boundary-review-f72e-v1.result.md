RV64 RTL 结论｜对象=`OooIntBackend.mem_owner_terminalized_o`→`OooPendingDrainResolveGate.drain_complete_o`→`OooFrontend/OooFetchPcOutstandingSequencer`｜周期/配置=exact-current `NpcTop` 5ns mapped、design_id=`sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`｜TB/EDA 观测=两轮 Top40 bit-identical，但候选 owner 生命周期及证据工具绑定存在 blocker｜范围=GAP

## 已确认的 EDA 边界

- 两份 `opensta-top40.rpt` SHA-256 均为 `f10ad4a5f473316b6b3c6b678c0b411cec308051b5a0f7be24bde8382909006e`。
- 40/40 startpoint 均为 public-flat `csr_mtvec_q[63]` 别名；`traceability.txt` 为 `public_flat_startpoints=40`、`public_flat_endpoints=40`、opaque=0。
- endpoint 文本分类严格为 `jalr_prefetch_hit_available=34`、`redirect_valid=5`、`pending_branch_misaligned=1`。
- 40 条路径共享至少 200 个 raw-prefix cells，且 `mem_owner_terminalized_o`、`u_mem_owner_terminal_collector`、`pending_drain_resolve_gate_drain_complete`、`u_redirect_arbiter` 与 fetch-PC sink 均覆盖该路径族。
- public-flat 只证明映射后的 module/input alias；tie-off endpoint 名称不能解释为对应死信号的功能因果，也不能反推具体寄存器 bit。

## 阻断反例与缺口

1. `mem_owner_terminalized_o` 是逐拍守恒谓词，包含 `!v15r_mem_birth_any_w`、active-holder、collector-pending 与 tracker-live 对账。一位 readiness 在 C0 捕获后若保持为 1，而 C1 出现新的 memory birth/holder，旧 readiness 可能让 pending system、arch-trap 或 exit 提前 `drain_complete`。合同内 RTL 未证明该 birth 不可达。
2. 当前 `OooPendingDrainResolveGate` 没有 `clk`、`rst`、local/global flush 或 owner tag 输入，无法仅用现有接口精确定义 reset、owner completion/handoff 的优先清除，也无法防止 `stop_pending_q` 连续为 1 时跨 owner 复用 readiness。
3. 普通 FENCE 的当前拍 `mem_idle_i` 门可以阻挡部分 stale-readiness 反例；trap、exit 和 non-FENCE system 没有同等 current-owner guard。
4. collector-pending token 被 `mem_owner_terminalized_o` 有意允许；候选仍缺少跨拍 token/epoch 守恒断言，不能把 collector pending 当作 tracker-free completion。

## 证据工具缺口

- 输入 selector 仍绑定分析器旧 SHA；最终发布前必须用当前工具重放选择器并绑定新 SHA。
- 原定向测试仍绑定 ca37 的旧 CLI、状态和候选；必须改为 f72e GAP 正负向测试后才能形成 current receipt。

## 范围

- `serialized-mem-terminal-readiness-register-v1` 不获 RTL 实验授权。
- 下一步只能定向证明或否证 memory birth、owner handoff、flush、FENCE、精确异常与 collector token 的跨拍守恒；证明完成前不得改 production RTL。
- `scope_extension_request`：下一轮纳入 `OooPendingSystemSequencer.v`、`OooPendingTrapExitSequencer.v`、`OooStopPendingSequencer.v`、`OooPendingDispatchArbiter.v`、`OooTrapExitEventMux.v` 及对应 drain/collector TB。
- Top40 哈希、分类、映射边界及工具/测试漂移置信度为高；stale-readiness 实际可达性置信度为中等。

[V15Z-SERIALIZED-DRAIN-BOUNDARY-REVIEW][GAP_OWNER_LIFETIME_UNPROVEN] design_id=sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42 candidate-only production_rtl_change_authorized=false PPA=UNQUALIFIED promotion_eligible=false

全部只读工程命令已结束；WSL shell ownership 已归还主节点。
