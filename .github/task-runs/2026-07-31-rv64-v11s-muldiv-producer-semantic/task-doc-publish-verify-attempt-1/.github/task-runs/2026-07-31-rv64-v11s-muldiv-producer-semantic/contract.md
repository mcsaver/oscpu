# V11S MulDiv producer lifecycle contract

本地 RV64 `OooIntBackend.u_muldiv_unit` 必须让
`OooMulDivUnit.producer_id_q` 从 request acceptance 到 iterative hold、
authorized response、writeback/retirement 与 terminal release 全程保持完整
`{generation, rob_idx}`，并在 flush/death 边界保持 edge-old lease。

## 本轮唯一机制

- 机制：`muldiv-producer-lifecycle`
- RTL 对象：`OooMulDivUnit`、`OooIntBackend`
- product instance：
  `NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_muldiv_unit`
- semantic unit：`muldiv-producer`
- production RTL 不修改；本轮只增加 focused testbench fragment、runner、
  semantic policy/evaluator、instance-graph 绑定纠偏与 task-run 证据。

## 周期合同

1. TB 用已接受的 retirement 推进独立 allocation schedule，并让 request
   使用 stimulus-owned `P={generation=1,index=2}`；expected identity 不从
   DUT holder 或 writeback 输出反推。
2. request fire 必须把完整 ProducerId 捕获到 `producer_id_q`；REQ_BUF、
   MUL/DIV iterative state 与 RESP state 的 owner/live mask 必须保持同一 P。
3. 相同 index、错误 generation 的 completion query、authorization、claim
   与 writeback side effect 必须全部为零。
4. 正确 terminal 只能产生一次携带完整 ProducerId 的 WB/PRF/Busy/IQ/ROB
   公共副作用，并最终有序退休。
5. response ready、matching kill 或 flush 的 death edge 仍暴露 edge-old
   owner/live lease；下一周期 holder、PID 与 live mask 清空。
6. MUL 与 DIVU product-path 场景各复用一次 V8N 八条 younger dual-issue
   pressure，证明 variable-latency holder 不受后继流量改写。

## 验证矩阵

- production baseline：`PRODUCER_GEN_W=1/4` × `OOO_ASSERT on/off`，
  共 4 个 profile。
- compile-success release RTL 版本：9 类 × 两个 generation width，
  共 18 个 mutation profile。
- mutation 覆盖 request birth、generation/index capture、iterative live
  mask、completion query、exact-open authorization、response release、
  terminal WB identity 与 flush death。
- ordinary regression：
  `tb_ooo_muldiv_unit`、`tb_ooo_int_backend`、
  `tb_ooo_int_backend_v11r_int_lane1_packet`、
  `tb_ooo_int_backend_v11i_terminal_lifecycle`。
- focused TB 由 V11R base TB 与 V11S fragment 经 3 个唯一锚点生成 overlay；
  base TB 与共享 testbench Makefile 必须保持原 SHA。

## 证据与停止条件

- 4/4 baseline、18/18 mutation profile、4/4 ordinary regression 通过。
- source pre/post manifest 一致；production RTL SHA 与 design-id 无漂移。
- ledger 只能把 `muldiv-producer` 从 GAP 晋为 PASS。
- current instance graph、census、V11H replay 与 semantic ledger 必须重绑，
  但不得覆盖 V11R 历史证据。
- A3 原始 `FAIL rc=1` 与 strict 16/17 保持不可变；本轮不运行完整系统。
- whole architecture 保持 `RED`，PPA 保持 `UNPROMOTED`。

