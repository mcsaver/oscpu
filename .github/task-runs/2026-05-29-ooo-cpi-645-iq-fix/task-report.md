# OoO CPI 0.645 IQ 修复记录

## 目标

- 继续推进“乱序超标量处理器，CPI=0.5”目标。
- 当前验证基线：AM `cpu-tests add` GOOD TRAP，`cycles=541/commits=839/CPI=0.645`。
- 本轮未达到完整 `CPI=0.5`，但修复了一个会污染后续 memory/issue 实验的 issue queue 正确性 bug。

## Root Cause

- `OooIntIssueQueue` 支持 dispatch-bypass：新来的 ready uop 可以不进入 IQ，直接从 dispatch path 发射。
- 旧 compact 逻辑只看 `issue0_fire_w/issue1_fire_w`，默认 `issue0_idx_r=0`。
- 当 issue0 来自 dispatch0/dispatch1 bypass 而不是 IQ entry 时，compact 仍把 slot0 当成“已发射 entry”删除。
- 在双 memory 实验 trace 中，这会误删 `0x80000060 sub`，导致 `0x80000062 seqz` 和 `0x8000000e beqz` 永远等待 producer，前端停在 `stop_pending`。

## 保留修改

- `npc/single/vsrc/ooo/OooIntIssueQueue.v`
  - 新增 `issue0_queue_fire_w/issue1_queue_fire_w`。
  - compact 删除 entry 时只接受真实 IQ entry 发射，不接受 dispatch-bypass fire。
- `npc/single/testbench/tests/tb_ooo_int_issue_queue.sv`
  - 新增 unready slot0 + dispatch-bypass 回归：slot0 等待 preg20，lane0 dispatch-bypass 发射后 slot0 必须仍保留，并能在 wakeup 后正常发射。

## 已撤回实验

- 双 memory issue/buffer 放宽：
  - IQ bug 修复前会挂死。
  - IQ bug 修复后 AM `add` 可 GOOD TRAP，但退化为 `cycles=558/commits=839/CPI=0.665`。
  - 已回退到稳定单 memory request 策略。
- lane0 branch + lane1 ret 同拍派发：
  - focused test 可通过。
  - Verilator build 报 `UNOPTFLAT`，组合环穿过 dispatch ready、branch resolve 与 dispatch1 valid。
  - 已回退。

## 验证

- Focused tests PASS：
  - `/tmp/ysyx-ooo-current-final-focused/logs/tb_ooo_int_issue_queue.log`
  - `/tmp/ysyx-ooo-current-final-focused/logs/tb_ooo_alu_fetch_core.log`
  - `/tmp/ysyx-ooo-current-final-focused/logs/tb_ooo_dispatch_backend.log`
  - `/tmp/ysyx-ooo-current-final-focused/logs/tb_ooo_int_backend.log`
- Verilator build：`/tmp/npc-ooo-current-final-build/NpcSimTop`
- AM `cpu-tests add`：
  - 命令：`/tmp/npc-ooo-current-final-build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000`
  - 结果：GOOD TRAP，`cycles=541/commits=839/CPI=0.645`

## 剩余瓶颈

- 839 条提交的理想 2-wide 下界约为 420 cycles，当前 541 cycles 仍多约 121 cycles。
- trace 单提交热点：
  - `0x80000010 ret`
  - `0x80000058 lw a0,0(s0)`
  - `0x8000000e beqz`
- 下一步需要优先评估：
  - 真正多端口或多 outstanding LSU/response queue/LSQ，缓解两个 load 同包与 ROB head 顺序提交。
  - 不引入 dispatch ready 组合环的 branch/ret 控制投机或 ROB-age selective squash。
  - 更短的 ALU wakeup/branch compare 关键路径。
