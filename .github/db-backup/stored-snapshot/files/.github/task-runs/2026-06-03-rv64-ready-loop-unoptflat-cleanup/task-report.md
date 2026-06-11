# 2026-06-03 RV64 ready/resolve UNOPTFLAT 清理

## 任务目标

- 清理 `OooAluDecodeBackend` dispatch valid/ready 附近的 `UNOPTFLAT` waiver。
- 沿 `OooAluFetchCore -> OooAluDecodeBackend -> OooIntBackend/OooDispatchBackend` 追踪组合环 root cause，而不是恢复局部 waiver。
- 保持现有端口、ISA 行为、unsupported trap、flush/checkpoint/commit 协议不变。

## RECALL 摘要

- 已读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`、`.github/instructions/rtl-generation-workflow.instructions.md`、`.github/instructions/npc-study.instructions.md`、`npc/rv64/README.md`、`npc/rv64/design/study/README.md`。
- RTL 修改按 `需求 -> 协议规则 + 状态机 + 不变量 + 数据通路约束 -> RTL` 留痕。
- core/长期 RTL 不引入 DPI/backdoor；Verilator lint/build 与 focused/smoke 作为本轮验证证据。

## RTL 推导摘要

### 需求

- dispatch wrapper 的 `ready` 应表示后端可接受能力，不应通过当前拍 front-end fire、branch resolve、synthetic lane1 payload 再反向影响自己。
- `OooAluDecodeBackend` 仍只做 decode 支持性过滤，unsupported 指令不上送 `OooIntBackend`。
- `OooDispatchBackend` 仍是 rename/free-list/ROB/IQ 的 2-wide dispatch owner。
- 不在本轮范围内：恢复被关闭的同拍 lane1 append/return-cont fast path、扩大 branch predictor、改 ROB/IQ 深度或做 CPI 优化。

### 协议规则

- lane0 是 dispatch 顺序前导；lane1 fire 必须蕴含 lane0 fire。
- 非 optional lane1 必须在 ROB/IQ/free-list 都有 pair 容量时才允许 lane0 接受；optional lane1 不阻塞 lane0。
- 子模块 ROB/IQ/free-list 只接收最终 `dispatch*_fire_w` 更新状态；parent ready 不再读取子模块基于 parent fire 反算出的 ready。
- branch/return fast path 不能在同一组合锥内同时生成 current dispatch payload 又用该 payload 反推 current branch resolve。

### 状态机

- 本轮不新增时序状态机。
- 状态仍由既有 ROB/IQ/free-list/frontend pending/stop 寄存器管理。
- 禁用的 return-cont/branch append 同拍派发会退回既有 redirect/fetch/issue resolve 路径。

### 不变量

- `dispatch1_fire_w -> dispatch0_fire_w`。
- 每拍最多写入两个 ROB/IQ 项，且不借用同拍 commit/issue 释放槽位。
- 需要新物理寄存器的 lane 数不能超过当前 free-list `free_count_w`。
- unsupported 指令不进入 `OooIntBackend`。
- branch target cache 的 dispatch0 append lookup 目标必须来自 head0 `pc + imm`，不能复用会随 lane1 fire 摆动的 `direct_branch_target_w`。
- 未启用的 branch prefetch dispatch、return-cont 同拍 lane1、branch target/fallthrough 同拍 append 不得参与 ready/resolve 组合锥。

### 数据通路骨架

- `OooDispatchBackend` 增加 `rob_slot0_ready_w/iq_slot0_ready_w/rob_pair_ready_w/iq_pair_ready_w`，直接由 `rob_count_w/iq_count_w` 推导 parent ready。
- `OooAluDecodeBackend` 删除 `backend_dispatch*_valid/ready` 附近 `UNOPTFLAT` waiver。
- `OooIntBackend` 保留 lane0 dispatch-time branch fast resolve；lane1 branch 仍正常进入 IQ 后 resolve。
- `OooAluFetchCore` 显式门掉未打拍的 branch prefetch dispatch、return-cont 同拍 lane1 派发、branch target/fallthrough 同拍 append，并把 branch target cache lookup target 固定为 head0 branch target。

## 改动摘要

- `npc/rv64/vsrc/ooo/backend/OooDispatchBackend.v`
  - parent dispatch ready 改由本模块容量计数直接生成。
  - ROB/IQ 子模块 ready 输出不再反喂 parent ready，只纳入 unused observe。
- `npc/rv64/vsrc/ooo/backend/OooAluDecodeBackend.v`
  - 删除 dispatch ready/valid 附近 `UNOPTFLAT` waiver。
- `npc/rv64/vsrc/ooo/backend/OooIntBackend.v`
  - lane1 dispatch fast branch resolve 显式关闭；lane1 branch 通过 IQ 正常 resolve。
- `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`
  - 显式关闭未启用/未打拍的 branch prefetch dispatch 和同拍 lane1 append fast path。
  - branch target cache lookup 改用 head0 branch target。
  - 删除剩余 `UNOPTFLAT` waiver。

## 验证证据

- `make -C npc/rv64/testbench TESTS="tb_ooo_alu_decode_backend tb_ooo_int_backend tb_ooo_alu_fetch_core" RESULT_TIMESTAMP=20260603-rv64-alu-decode-ready-loop-final run`：3/3 PASS。
- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_trap_gate tb_branch_predictor tb_ooo_fetch_axi_bridge" RESULT_TIMESTAMP=20260603-rv64-ready-loop-frontend-neighbor run`：3/3 PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-ras-trap-boundary smoke-muldiv smoke-sret-user-sv39-halfword smoke-fp-loadstore`：全部 GOOD TRAP。
- `rg -n "UNOPTFLAT|UNUSEDSIGNAL|BLKSEQ|lint_off|lint_on" npc/rv64/vsrc | rg -v "[\\/]legacy[\\/]"`：无命中。
- `git diff --check`：PASS。

## 风险与后续

- 本轮关闭了几个没有寄存器边界的同拍前端性能 fast path，短 smoke 的 cycles 有小幅变化；这是有意用可综合/可 lint 的单向组合边界换掉隐式组合环。
- 若后续要恢复 return-continuation 或 branch target/fallthrough append，应做成带寄存器、队列或明确 replay owner 的结构，不能重新让 current ready/resolve/payload 在同一组合锥互相驱动。
