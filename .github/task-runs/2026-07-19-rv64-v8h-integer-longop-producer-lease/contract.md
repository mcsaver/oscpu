# v8h integer long-op ProducerId lease 冻结合同

- `task_class`: `architecture_closure_without_ppa_promotion`
- `parent_goal_state`: `active`
- `scope`: MulDiv + CLMUL full ProducerId holder、ROB exact-open、shared-WB transport/authority
  分权、Q-only dispatch collision lease。
- `out_of_scope`: FP、branch resolve、pending-system/CSR、global no-live-reuse、DI/OOO 全门、
  Linux、正式 synthesis/STA/Power/Pareto。

## 接口冻结

1. 两个 unit request/response identity 均为 `ProducerId={generation,rob_idx}`；unit 内只保留一个
   `producer_id_q` owner，raw idx 全部从低位投影。
2. `owner_valid_o/owner_producer_id_o` 只读 unit Q，不读 kill、ready、query 或 next-state。
3. `OooIntBackend` 形成 `memory | muldiv | clmul` lease union；`OooDispatchBackend` 的端口升级为
   语义准确的 `producer_live_mask_i`，只做 candidate-indexed lookup。
4. ROB completion query 3/4 与既有 query 0/1/2 同义：valid、exact generation、`!done`、
   kill/recovery survivor；只授权 side effect，不进入 response ready。
5. shared-WB priority保持 `EX > MEM > MulDiv > CLMUL > FP`；raw route/ready消费 stale response，
   actual WB/GPR/Busy/IQ/ROB/public pulse另与对应 exact-open 相与。
6. edge-old ROB query 之外，actual completion 使用 full-PID claim 全序
   `EX0 > EX1 > memory > MulDiv > CLMUL`；claim 只门控 side effect，不门控 raw transport。
7. dual-dispatch candidate PID 的低 index 位分别为 `tail`/`tail+1`，在 `ROB_ENTRIES>=2` 下必须
   结构性不同；用 Q-only 断言与测试证明，不能依赖 registered live mask 补救同拍 birth。

## 状态/事件冻结

- MulDiv FSM：`IDLE→REQ_BUF→MUL_RUN|DIV_RUN→RESP→IDLE`；CLMUL：
  `IDLE→RUN→RESP→IDLE`。
- PID 在 request fire capture，non-IDLE 全生命周期保持；reset/flush、matching kill 或 response
  transport terminal 沿清零。
- 优先级：`reset/global flush > matching selective kill > normal FSM`。
- reset/flush/任意 kill-valid 拍 request ready=0。
- kill/response terminal 同沿的 dispatch collision 仍看 edge-old lease，下一拍才释放。
- 同 PID 多源同拍只允许固定全序中的首个 actual claim；后续 raw response可等待或静默核销。

## 完成条件

- spec、RTL、TB 与 static audit 对上述接口/状态/事件逐项绑定；
- focused release/assert 正例、compile-success semantic mutation、module aggregate、style/contract；
- strict lint 不新增 signature；global architecture inventory 保持真实 RED；
- 实现者/审查者冲突逐项由 TB/mutation/static evidence 关闭，未关闭项列剩余风险；
- 不生成 PPA promotion 声明。
