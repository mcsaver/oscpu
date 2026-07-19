# OooFetchRequestMux

> ✅ **状态(2026-07-09 P4 切消费点)**：redirect PC 真源已收敛 `OooRedirectArbiter`
> （年龄律，`OooFrontend.u_redirect_arbiter`，见 `ooo-flush-redirect-contract.md` §2.2）。
> 本模块的 **redirect target first-match 三元链已删除**——`redirect_fetch_pc_o =
> redirect_valid_i ? redirect_pc_i(arbiter 赢家) : core_branch_resolve_next_pc_i(兜底,
> E7/E9 保留臂拍与原链默认档同目标)`。原 11 档链的目标输入端口
> （direct_jal_target/direct_ret_target/return_cont/ras_top/branch_target_cache_next_pc/
> head_next_pc1/direct_branch_resolve_next_pc/pending_jump_resolved_target/
> direct_jump_spec_target）随之删除。**valid/流控职责原样保留**（direct_redirect_fetch_o
> OR、redirect_fetch_req_valid_o 三条件、fetch_req_pc_o 三段）——valid 成员集与 arbiter
> direct 口不同（e4 valid 含普通 branch0/1_fire 而本 valid 不含），改接 arbiter valid
> 会新增同拍取指请求=时序变化，为切消费点契约禁止项。
>
> ⚠️ 旧状态注(2026-07-03 RTL 重读)：pending-jump 两 fire 输入仍为 wave5b tie-0 死态
> （`OooRedirectMuxChecker` RDMUX-DEAD 哨兵在位）；其余判死臂描述随三元链删除而失效，
> 见 git 史。

## 需求

`OooFetchRequestMux` 承接 `OooFrontend`（原 `OooAluFetchCore`，已重构删除）中 fetch request PC 来源选择的纯组合逻辑：

- 计算顺序 fetch PC：若 registered outstanding owner 存在，则从 Bridge raw payload
  预装 response packet next PC；无 owner 才使用 `next_fetch_pc_q`。该数据选择不得依赖
  response valid/ready/fire；miss/fault/stall 时上游 flow control 禁止 request fire，
  所以预装值是 don’t-care，不形成架构 token。
- 计算 redirect fetch 是否能在本拍发起，并选择 redirect target。
- 在 redirect、branch prefetch 和顺序取指三类来源中选择最终 `fetch_req_pc_o`。

父模块仍保留所有时序状态，包括 `next_fetch_pc_q`、`outstanding_valid_q`、
`discard_fetch_rsp_q`、redirect/flush recovery 和 FIFO 状态；outstanding PC payload
由 Bridge active context 单独持有并透传。

## 协议

输入信号分为四类：

- 顺序 PC：`outstanding_valid_i`、`fetch_rsp_valid_i`、
  `fetch_rsp_packet_next_pc_i`、`next_fetch_pc_i`；其中 `fetch_rsp_valid_i` 只供
  协议可观察性，不得回流顺序 PC 数据 mux。
- redirect predicate：direct JAL/return、direct jump spec（B2 非返回 JALR 投机续取）、
  lane0 branch to lane1 return、pending JALR/no-link commit、direct branch resolve、
  normal branch resolve、branch speculation restore、untracked branch resolve、
  branch fallthrough outstanding suppression。
- redirect target：direct jump spec target、direct JAL target、direct return target、
  return continuation、RAS top、branch target cache next PC、fallthrough PC、
  direct branch resolve target、pending jump target、core branch resolve next PC。
- lower-priority source：branch prefetch request valid/PC。

输出信号：

- `direct_redirect_fetch_o` 是 direct fast redirect 类事件的 OR。
- `redirect_fetch_req_valid_o` 在任一 redirect 事件有效、未被 fallthrough outstanding
  suppression 阻止，且没有未返回 outstanding 或本拍 response 已 fire 时为真。
- `redirect_fetch_pc_o`（P4 后）= arbiter 赢家透传或默认兜底 core branch resolve next PC。
- `fetch_req_pc_o` 优先使用 redirect PC，其次 branch prefetch PC，最后顺序 PC。

## 不变量

- Redirect request 优先级高于 branch prefetch，高于顺序取指。
- outstanding token 有效时顺序 candidate 必须无条件预装 raw packet successor，
  包括 response valid 尚未成立的 H1 miss/fault 判决窗口；上游 request valid 仍被
  outstanding/flow control 关闭，candidate 是 don’t-care，不改变 active owner。
- PMP/ITLB response-valid 控制锥不得进入 packet-next-PC 数据选择。
- Branch fallthrough 已有匹配 outstanding 时，redirect request valid 必须为假。
- Redirect target（P4 单源）：`redirect_valid_i` 拍恒透传 `redirect_pc_i`（arbiter 年龄律
  赢家）；无赢家拍恒兜底 `core_branch_resolve_next_pc_i`。守卫=`OooRedirectMuxChecker`
  RDMUX-ARB-PC / RDMUX-DEFAULT-PC（重加链臂即 fire）。原 11 档 first-match 序由 arbiter
  年龄律 + commit pre-mux + e4 构造式取代（等价性=P4 shadow 期 SHADOW-EQ-PC + 刀 0
  mux-vs-succ 探针零 fire 证据链）。
- 新模块不产生 `fetch_req_valid_o`，不查看 `fetch_req_ready_i`，不更新任何状态。

## 非职责

- 不仲裁 fetch request ready-valid。
- 不维护 outstanding/discard 状态。
- 不写 FIFO，不处理 response ready/enqueue/drop。
- 不解释 instruction、branch compare、BTB/BHT/RAS 或 CSR trap cause。

## R2.3 raw successor 消费边界（2026-07-15）

`fetch_rsp_packet_next_pc_i` 在本模块边界上的物理含义收窄为
`OooFetchPacketDecode.packet_raw_next_pc_o`：它只驱动顺序 request candidate，
不得进入 FIFO、预测、异常或 architected PC 状态。registered `outstanding_valid_i`
只选择 payload；真正请求是否 fire 仍由独立 FlowControl/Bridge response token 决定。

因此必须同时满足：

- 成功 packet 上 raw successor 与 response-aware semantic successor 逐位相等；
- miss/fault/flush/invalidate/redirect 上即使 raw payload 任意变化，也不得产生 request fire；
- `fetch_rsp_valid_i`、PMP、ITLB permission 和 response provenance 不得回流本数据 mux；
- 删除 token gate 或把 raw 口接到语义消费者，均属于硬约束失败。
