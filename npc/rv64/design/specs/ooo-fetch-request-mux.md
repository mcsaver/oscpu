# OooFetchRequestMux

## 需求

`OooFetchRequestMux` 承接 `OooAluFetchCore` 中 fetch request PC 来源选择的纯组合逻辑：

- 计算顺序 fetch PC：若 outstanding response 本拍返回，则使用 response packet
  next PC；否则使用 `next_fetch_pc_q`。
- 计算 redirect fetch 是否能在本拍发起，并选择 redirect target。
- 在 redirect、branch prefetch 和顺序取指三类来源中选择最终 `fetch_req_pc_o`。

父模块仍保留所有时序状态，包括 `next_fetch_pc_q`、`outstanding_valid_q`、
`outstanding_pc_q`、`discard_fetch_rsp_q`、redirect/flush recovery 和 FIFO 状态。

## 协议

输入信号分为四类：

- 顺序 PC：`outstanding_valid_i`、`fetch_rsp_fire_i`、
  `fetch_rsp_packet_next_pc_i`、`next_fetch_pc_i`。
- redirect predicate：direct JAL/return、lane0 branch to lane1 return、
  pending JALR/no-link commit、direct branch resolve、normal branch resolve、
  branch speculation restore、untracked branch resolve、branch fallthrough
  outstanding suppression。
- redirect target：direct JAL target、direct return target、return continuation、
  RAS top、branch target cache next PC、fallthrough PC、direct branch resolve
  target、pending jump target、core branch resolve next PC。
- lower-priority source：branch prefetch request valid/PC。

输出信号：

- `direct_redirect_fetch_o` 是 direct fast redirect 类事件的 OR。
- `redirect_fetch_req_valid_o` 在任一 redirect 事件有效、未被 fallthrough outstanding
  suppression 阻止，且没有未返回 outstanding 或本拍 response 已 fire 时为真。
- `redirect_fetch_pc_o` 按旧优先级选择 redirect target。
- `fetch_req_pc_o` 优先使用 redirect PC，其次 branch prefetch PC，最后顺序 PC。

## 不变量

- Redirect request 优先级高于 branch prefetch，高于顺序取指。
- Outstanding 未返回且本拍 response 未 fire 时，redirect request valid 必须为假。
- Branch fallthrough 已有匹配 outstanding 时，redirect request valid 必须为假。
- Redirect target 优先级保持旧语义：
  direct JAL > direct return > lane0-branch lane1-return > branch target cache >
  branch fallthrough > direct branch resolve > pending jump > branch speculation
  restore/default core branch resolve。
- 新模块不产生 `fetch_req_valid_o`，不查看 `fetch_req_ready_i`，不更新任何状态。

## 非职责

- 不仲裁 fetch request ready-valid。
- 不维护 outstanding/discard 状态。
- 不写 FIFO，不处理 response ready/enqueue/drop。
- 不解释 instruction、branch compare、BTB/BHT/RAS 或 CSR trap cause。
