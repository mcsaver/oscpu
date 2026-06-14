# OoO branch fast-dispatch increment

## 背景

在 JAL 快速重定向、lane0 memory 免预 drain、受限 RAS return fast path 后，实验 OoO 路径运行默认 AM `cpu-tests add` 为 `cycles=2514/commits=839/CPI=2.996`。反汇编显示剩余热点包含 `check` 的 `c.beqz` 与主循环两个 `bne`；当前 lane0 branch 仍在进入 ROB/IQ 前等待后端全 drain，导致每个分支支付预 drain 成本。

## 四阶段记录

### 1. 需求

- 只优化 lane0 条件分支；lane1 branch 仍保持半包屏障。
- 分支仍真实进入后端/ROB，并由 ROB commit 计入 host 指令统计；不再使用 synthetic branch commit。
- 前端在 branch dispatch 后冻结，不取/派发更年轻指令；等后端执行出真实方向后恢复到 target/fallthrough。

### 2. 协议 / 状态机 / 不变量

- lane0 branch dispatch fire 当拍，清 fallthrough FIFO/outstanding，设置 `stop_pending_q + pending_branch_q + pending_branch_dispatched_q`。
- 后端 issue branch 时用 PRF 中真实 rs1/rs2 和 `CompareUnit` 产生 `branch_resolve_valid/next_pc/misaligned`。
- fetch core 收到 resolve 后清 pending，并把 `next_fetch_pc_q` 设置为真实下一 PC；若旧 outstanding response 尚未返回，沿用 discard response 状态先 drop stale response。
- 这是“非预测、执行后恢复”路径：不需要 checkpoint，因为 resolve 前没有更年轻指令进入；恢复后 younger target/fallthrough 指令可能早于 branch commit 入队，当前实验子集依赖 older ALU/JAL/memory 屏障无异常，完整 OoO 仍需 checkpoint/rollback。

### 3. 数据通路

- `OooAluDecodeBackend` 放行 branch uop。
- `OooIntBackend` 增加双 issue lane 的 branch compare/target 计算与 resolve 输出。
- `OooAluCoreSlice`/`OooAluFetchCore` 透传 resolve 端口。
- `OooAluFetchCore` 新增 `pending_branch_dispatched_q` 与 `direct_branch0_dispatch/fire`，lane1 branch 继续使用旧 drain synthetic 路径。

### 4. RTL 实施计划

- 修改 `npc/single/vsrc/ooo/OooIntBackend.v`、`OooAluDecodeBackend.v`、`OooAluCoreSlice.v`、`OooAluFetchCore.v`。
- 更新 testbench Makefile 的 OoO 后端源列表以包含 `CompareUnit`。
- 扩展 `tb_ooo_alu_fetch_core`，观测 lane0 branch fast dispatch/resolve。
- 回归 fetch-core、全量模块 testbench、实验构建与 AM add。

## 结果

- 已保留该增量。lane0 条件分支进入 OoO 后端执行并由 branch resolve 口驱动前端重定向，旧 synthetic branch commit 路径不再用于 lane0 fast path。
- 实验 OoO AM `cpu-tests/add` GOOD TRAP：`cycles=2498`，`commits=839`，`CPI=2.977`，日志 `/tmp/ysyx-ooo-branch-fast-add.log`。
- 限制：该阶段仍是不预测分支；前端等待后端 resolve 后再继续取目标/顺序路径。
