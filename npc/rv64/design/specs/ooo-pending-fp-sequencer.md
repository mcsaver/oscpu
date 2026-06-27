# OoO Pending FP Sequencer Spec

## 1. 需求

- `OooPendingFpSequencer` 承接 `OooAluFetchCore` 中 pending FP 单 entry
  的注册状态，包括 valid、memory 进度、long-op 进度、compute 结果、FP
  指令属性和 memory request payload。
- 输入只包含父模块已经仲裁好的 capture/clear 事件、FP memory request/response
  事件、long-op start/done 事件和 compute start/result 事件；输出仍由父模块消费，
  用于 `OooFpPendingExec`、memory request gate、control commit mux、CSR fflags
  commit 和 fetch redirect。
- 时钟域为 `clk`，同步高有效 reset；父模块把 `rst || flush_i` 接入本模块
  `rst`，保持旧全局 reset/flush 清空所有 payload 的语义。
- 本模块不负责 FPR 文件、不计算 FP 算术结果、不发起 LSU/MMU 仲裁、不提交
  fflags，也不决定 precise trap/redirect；这些仍属于父模块和现有 helper。

## 2a. 协议规则

- 本模块是固定时序寄存器 bank，不提供 ready/valid backpressure。
- `capture_head0_i` 表示 lane0 FP 在 head 处成为精确 drain 边界；下一拍
  `valid_o=1`，memory/long/compute 进度被重新初始化。
- `capture_lane1_i` 表示 lane1 半包 barrier 被父模块命中；`capture_lane1_valid_i`
  决定是否真的保留 FP entry。即使 valid 为 0，payload 仍会更新，以匹配旧父模块
  lane1 barrier 分支对 pending FP payload 的写入语义。
- `mem_req_fire_i` 锁存本次 FP memory 请求的 exact address、aligned request
  payload 和 strobe，并置 `mem_pending_o=1`。
- `mem_rsp_fire_i` 清 `mem_pending_o`、置 `mem_done_o`。FPR load 写入仍在父模块
  完成，本模块只负责 pending 进度位。
- `long_start_i` 置 long pending 并清旧 long result/fflags；`long_done_i` 清
  long pending、置 long done 并锁存 result/fflags。
- `compute_start_i` 对非 long-op 组合结果打一拍，置 `compute_done_o` 并锁存
  result/fflags，切断 helper 到 commit 的同拍组合锥。
- 普通 `clear_i` 对齐旧 drain-complete clear：清 valid、memory/long/compute
  进度、`load/store/gpr_write`，但不清 `double/pc/inst/next_pc/addr/wdata/wstrb/rd`
  payload。
- `late_clear_i` 对齐 CSR trap late clear：优先级高于 capture 和进度事件，清
  valid、memory/long/compute 进度和 `next_pc`，但不重写旧 payload。

## 2b. 状态机

| 状态 | 条件 | 下一状态 | 输出语义 |
| --- | --- | --- | --- |
| `IDLE` | `capture_head0_i` | `HELD` | valid=1，payload 来自 lane0 |
| `IDLE` | `capture_lane1_i && capture_lane1_valid_i` | `HELD` | valid=1，payload 来自 lane1 |
| `IDLE` | `capture_lane1_i && !capture_lane1_valid_i` | `IDLE` | payload 可更新，valid=0 |
| `HELD` | `mem_req_fire_i` | `MEM_WAIT` | memory request 已发出 |
| `MEM_WAIT` | `mem_rsp_fire_i` | `HELD` | memory 阶段完成 |
| `HELD` | `long_start_i` | `LONG_WAIT` | long-op 迭代启动 |
| `LONG_WAIT` | `long_done_i` | `HELD` | long-op result/fflags 有效 |
| `HELD` | `compute_start_i` | `HELD` | compute result/fflags 有效 |
| 任意 | `clear_i || late_clear_i` | `IDLE` | pending entry 失效 |
| 任意 | `rst` | `IDLE` | 全 state/payload 清零 |

实现优先级为：

`rst > progress events > clear_i > capture_lane1_i > capture_head0_i > late_clear_i`

因为 RTL 使用同一时序块里的后写覆盖，实际可观察优先级是：

`late_clear > capture_head0 > capture_lane1 > clear > progress events`。

这复制旧 `OooAluFetchCore` 中进度先写、普通 clear/capture 后写、CSR trap late clear
最后重写的非阻塞赋值顺序。

## 2c. 不变量

- I1：reset 后 `valid/mem_pending/mem_done/long_pending/long_done/compute_done` 均为
  0，所有 payload/result/fflags 清 0。
- I2：`capture_head0_i` 总是创建 valid entry；`capture_lane1_i` 只在
  `capture_lane1_valid_i=1` 时创建 valid entry。
- I3：任意 capture 都重新初始化 memory/long/compute 进度，并清 memory request
  payload，避免旧 FP entry 的 response/result 污染新 entry。
- I4：`mem_req_fire_i` 不能单独完成 memory 阶段；只有 `mem_rsp_fire_i` 才能置
  `mem_done_o=1`。
- I5：`long_start_i` 后到 `long_done_i` 前，`long_pending_o=1` 且旧 long result
  不可被 commit 观察为 done。
- I6：`late_clear_i` 覆盖 capture，防止 CSR trap commit 同拍 stale user FP
  pending entry 穿过 privilege boundary。
- I7：普通 `clear_i` 不重写 payload，失效 entry 的 payload 只作为 don't-care
  保留，和旧父模块行为一致。

## 2d. 数据通路约束

- 数据通路只有一个 pending FP register bank：status bits、instruction payload、
  memory request payload、long result/fflags、compute result/fflags。
- `pending_fp_result_value` 和 `pending_fp_commit_fflags` 的 long/compute mux 仍留在
  父模块，因为它依赖 `OooFpPendingExec` 的组合分类输出。
- FPR 文件仍留在父模块：FP load response 写 FPR 与 FP arithmetic commit 写 FPR
  有不同触发点，本切片只迁移 pending owner，避免把 register file 端口和 precise
  commit 边界混在同一改动里。
- 本模块不反向驱动 dispatch ready、memory ready 或 CSR ready，避免引入新的组合环。

## 3. RTL 映射

- `OooPendingFpSequencer.v` 使用单个时序块按 2b 的后写覆盖顺序编码。
- `OooAluFetchCore` 继续生成 capture/clear/progress 事件，继续持有 FPR 文件、
  fflags commit、GPR serial write 和全局 pending owner 仲裁。
