# 2026-05-29 OoO lane1 return fast path

## 目标

- 在 CPU-test 全量正确性优先的约束下，继续降低 OoO/superscalar 实验核 CPI。
- 本轮不只看 `add`，从上一版全量结果 `/tmp/ysyx-ooo-full-cputests-final.tsv` 的全局画像出发，同时关注 high-excess 样本和三类代表样本。
- 维持一个 module 一个源文件；本轮未新增 module。

## 基线

- 上一版全量：`40/40 GOOD`，`cycles=68083/commits=78682/weighted CPI=0.865293`。
- 三类代表：`highest_cpi=dummy (52/12/CPI=4.333)`，`lowest_cpi=prime (2760/5158/CPI=0.535)`，`near_average_cpi=shift (472/323/CPI=1.461)`。
- 高权重瓶颈：`recursion` pending jump 仍高，`hello-str/pascal/bubble-sort/quick-sort` 主要是 branch/control wait，`matrix-mul/leap-year/add-longlong` 主要暴露 D-load miss。

## RTL 推导摘要

### 需求

- 对常见 epilogue 形态 `simple-alu; ret`，避免当前 lane1 `ret` 先让 lane0 入后端、再 drain、再单独重放 `ret` 的长路径。
- 保持精确异常与数据相关性：不能越过可能异常的 memory/system 指令，也不能越过会改写 `ret` 源寄存器的 lane0。
- 不改变后端 ROB 的提交顺序；lane0 和 lane1 `ret` 仍按同包顺序进入后端。

### 协议规则

- 仅当 `ras_reliable && !ras_empty` 且 lane1 为 `jalr x0, x1/x5, 0` 时允许 RAS 预测。
- lane0 必须是合法、不会异常的简单 ALU uop，且 `rd` 不等于 lane1 `rs1`；load/store/branch/jump/system/fence/muldiv/bitmanip 均不进入快路径。
- 命中快路径时，前端使用 `direct_ret1_fire` 同拍 redirect 到 RAS top，并弹出 RAS；后端仍接收 lane0+lane1，保持 ROB 顺序提交。
- 未命中快路径时仍走旧 `dispatch1_barrier -> stop_pending -> drain -> replay`。

### 状态机

- 不新增状态。复用已有 direct frontend flush 路径清 FIFO/outstanding，并复用普通 dispatch/fire 条件。
- `direct_ret1_fire` 与 `direct_ret0_fire` 一样参与 `direct_frontend_flush_w` 与 `direct_redirect_fetch_w`，避免 fallthrough fetch 逃逸。
- RAS push/pop 状态机只增加 `direct_ret1_fire` 作为 pop 事件。

### 不变量

- lane1 ret 快路径不会越过可能抛异常或产生内存副作用的 lane0。
- 若 lane0 写 `ra/t0` 且 lane1 ret 读取同一寄存器，必须回落到旧路径。
- redirect fetch 的目标必须与 `next_fetch_pc_q` 写入一致，否则会继续沿 fallthrough 取指。
- 任何 lane1 ret 仍需要通过后端 ROB 提交；前端只提前取指方向，不直接伪造 rd 写回。

### 数据通路骨架

- 新增组合条件 `head1_return_candidate_w`、`lane0_before_ret_safe_w`、`dispatch1_return_w`、`direct_ret1_fire_w`。
- `dispatch1_barrier_w`、`dispatch1_control_unsupported_w` 对 `dispatch1_return_w` 开白名单。
- `direct_frontend_flush_w`、`direct_redirect_fetch_w`、`redirect_fetch_pc_w` 和 RAS pop 条件包含 `direct_ret1_fire_w`。

## 实验与撤回

- 尝试 `RAS_DEPTH=128`：代表样本 `dummy/prime/shift/recursion/mersenne/hello-str/pascal/matrix-mul` CPI 与基线完全一致；该实验无收益，已撤回。
- 初版 lane1 ret 漏掉 `dispatch1_control_unsupported` 白名单，`recursion` 在合法 `ret` 处被当作 illegal trap，已修正。
- 第二版漏掉 `direct_redirect_fetch_w` 中的 `direct_ret1_fire`，`mersenne` 会沿函数尾 fallthrough 取到 0 填充并 trap，已修正。

## 验证

- 构建：`make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4` PASS。
- 代表/高权重样本：`dummy/prime/shift/recursion/mersenne/hello-str/pascal/matrix-mul/crc32` 均 GOOD。
- CPU-test 全量：`/tmp/ysyx-ooo-full-cputests-lane1-ret.tsv`，`40/40 GOOD`，`cycles=66269/commits=78682/weighted CPI=0.842238`。

## A/B 结果

- 加权 CPI：`0.865293 -> 0.842238`。
- 最高 CPI：`dummy 52/12/CPI=4.333 -> 46/12/CPI=3.833`。
- 最低 CPI：`prime 2760/5158/CPI=0.535 -> 2754/5158/CPI=0.534`。
- 接近平均：新全量为 `leap-year 1449/1692/CPI=0.856`。
- 主要收益：`mersenne 4068->3153`，`recursion 6372->5789`，`hello-str 3214->3120`。
- 未观察到单项 cycles 退化。

## 下一步

- `recursion` 仍有 `jump=2575` 的 pending jump wait，主要来自间接调用/函数指针/tail jump，不能靠 RAS 容量解决。
- `hello-str/pascal/bubble-sort/quick-sort` 的 excess 主要来自 branch wait；下一轮应从 branch speculation/恢复粒度或分支依赖旁路看。
- `matrix-mul/leap-year/add-longlong` 暴露 D-load miss；若继续做 cache/prefetch，必须先补响应所有权/队列或多 outstanding 不变量，避免重复 D-cache next-word prefetch 的 BAD TRAP。
