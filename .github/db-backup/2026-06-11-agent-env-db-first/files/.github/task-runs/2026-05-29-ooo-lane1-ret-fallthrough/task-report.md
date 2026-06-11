# OoO Lane1 Return Fallthrough

## 目标

继续推进“乱序超标量处理器，目标 `CPI=0.5`”。本轮从当前最好 `cycles=835/commits=839/CPI=0.995` 出发，定位 AM `cpu-tests add` 的剩余控制流气泡，并保留能被 focused test 与 AM 共同证明的改动。

## Root Cause

VCD 采样显示，`add` 中有 72 次热点形态为 lane0 branch not-taken，真实 fallthrough 正好是同 packet lane1 的 RAS return。旧前端在 lane0 branch 当拍虽然能得到真实 next PC，但 next PC 是 lane1 `ret`，因此还要重新取/派发 return，再由 return fast path redirect 到 RAS target。这个路径对 AM `add` 形成重复控制流气泡。

对比基线：

- 回退无效实验后的基线：GOOD TRAP，`cycles=835/commits=839/CPI=0.995`。
- 基线 trace：`issue_bins {1:357, 2:241, 0:237}`，`fetch_rsp=530/fetch_req=529/mem_req=157/mem_rsp=157`。
- 优化后 trace：`issue_bins {1:357, 2:241, 0:93}`，`fetch_rsp=458/fetch_req=457/mem_req=157/mem_rsp=157`。

## RTL 推导

- 需求：lane0 branch 已在 dispatch 当拍解析，且解析结果是 fallthrough 到 lane1 return 时，不应再次请求/派发 return packet 才跳到返回地址。
- 协议规则：lane1 return 仍必须作为真实 uop 进入后端，保留 ROB/commit 可见性；RAS 只有在 return uop 被后端接收时 pop；若 flush/trap/exit 发生，pending return 状态必须清空。
- 状态机：前端保留 `pending_lane1_ret_q` 与对应 `pc/next_pc/inst`；该状态有效时阻止普通 FIFO dispatch，只从 pending return 产生 `core_dispatch0_valid_w`。
- 不变量：`pending_lane1_ret_q` 期间不能重复消费 FIFO head；return target 来自触发当拍的 `ras_top_w`；pending return fire 后清状态并 pop RAS；reset/flush 清状态。
- 数据通路约束：触发条件限定为 `direct_branch0_fire_w`、dispatch branch resolve PC 匹配、target 未 misalign、resolved next PC 等于 `head_pc1_w`、lane1 解码为 `jalr x0, x1/x5, 0` 且 RAS 非空。redirect fetch PC 在该路径下直接选 `ras_top_w`。
- RTL 落点：`OooAluFetchCore` 增加 `head1_return_candidate_w`、`direct_branch0_lane1_ret_w`、`pending_lane1_ret_*`，并把 pending return 接入 dispatch0 mux 与 RAS pop 条件。

## 修改内容

- `npc/single/vsrc/ooo/OooAluFetchCore.v`
  - lane0 branch resolved fallthrough 到 lane1 RAS return 时，直接 redirect fetch 到 RAS top。
  - 保存 lane1 return 为 pending dispatch0 单 uop，下一拍进入后端。
  - pending return fire 后 pop RAS；reset/flush/direct flush 清理 pending 状态。
- `npc/single/testbench/tests/tb_ooo_alu_fetch_core.sv`
  - `program_mode` 扩到 5 bit。
  - 新增 `MODE_BRANCH_LANE1_RET`：call 到 `0x80000014`，同包 `bne x0,x0` not-taken + `jalr x0,x1,0`。
  - 新增 `saw_lane1_ret_fallthrough` 观测，检查 fast path、直接 redirect、link、continuation 与 commit count。

## 已撤回实验

- ROB issue-to-commit fast bypass：局部 commit bins 改善，但 AM cycles 不下降，且 focused 采样边界不稳定。
- return target pairing：focused 可过，但 AM `CPI=0.824` 无进一步收益，复杂度没有保留价值。
- dispatch-time branch complete / IQ skip：形成 ready/operands 组合环，Verilator 报 `UNOPTFLAT`，已完全回退。

## 验证

- `make -B -C npc/single/testbench TESTS='tb_ooo_alu_fetch_core tb_ooo_int_backend' RESULT_DIR=/tmp/ysyx-ooo-lane1-ret-test-focused run`
  - 结果：`2/2` PASS。
- `make -B -C npc/single/testbench TESTS='tb_ooo_int_issue_queue tb_ooo_rob tb_ooo_dispatch_backend tb_ooo_int_backend tb_ooo_alu_fetch_core' RESULT_DIR=/tmp/ysyx-ooo-lane1-ret-full-focused run`
  - 结果：`5/5` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-lane1-ret-final-build NPC_OOO_ALU_EXPERIMENT=1 -j4`
  - 结果：PASS。
- `/tmp/npc-ooo-lane1-ret-final-build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000`
  - 结果：GOOD TRAP，`cycles=691/commits=839/CPI=0.824`。

## 结论

本轮把 AM `cpu-tests add` 从 `CPI=0.995` 推进到 `0.824`，收益来自消除 72 次 lane0 branch fallthrough 到 lane1 return 的重复取指/派发。完整 `CPI=0.5` 仍未完成；剩余 93 个 zero-issue 周期主要来自 fetch response 到 FIFO/dispatch 的一拍边界、单 memory port 与真实依赖链。下一步更值得做的是 fetch response 到 dispatch/FIFO bypass、RVC 64-bit response 多 packet 利用，或系统性缩短 load/ALU wakeup 与升级 LSU/LSQ。
