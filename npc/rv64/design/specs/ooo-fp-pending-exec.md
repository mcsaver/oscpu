# OooFpPendingExec Spec

## 阶段 1 - 需求

`OooFpPendingExec` 是 `npc/rv64` OoO 核的 FP pending 数据通路 helper。它接收父模块已经锁存的 pending FP 指令、GPR/FPR 操作数和控制位，输出 FP load/store 地址数据、普通 FP 组合结果、fflags，以及 FDIV/FSQRT 迭代单元的完成结果。

端口边界：

- 时钟/复位：`clk/rst`，`flush_i` 只清 div/sqrt 迭代子单元，不持有架构状态。
- 输入：`pending_valid_i`、`inst_i`、`load_i/store_i/double_i/gpr_write_i`、`int_rs1_value_i`、`frs1_value_i/frs2_value_i/frs3_value_i`、`long_start_i`。
- 输出：`long_op_o`、`compute_op_o`、`mem_addr_o/mem_aligned_addr_o/mem_wdata_o/mem_wstrb_o`、`compute_value_o/compute_fflags_o`、`long_done_o/long_done_result_o/long_done_fflags_o`、`div_busy_o/sqrt_busy_o`。

不在范围内：FPR 文件、pending 状态寄存器、memory request valid/ready、load response 写 FPR、commit、CSR fflags OR 入、trap/flush 仲裁。这些仍由父模块负责。

## 阶段 2a - 协议规则

- 组合数据通路：`mem_*`、`compute_*`、`long_op_o`、`compute_op_o` 对当前输入组合返回，父模块决定何时采样。
- 迭代协议：父模块在 `long_start_i` 单拍拉高时启动内部 FDIV/FSQRT，模块通过 `long_done_o` 单拍返回结果；同一条 pending 指令只能由父模块启动一次。
- flush 协议：`flush_i` 传给内部迭代单元，父模块同时清自己的 long pending/done 寄存器。
- backpressure：本模块无 ready；父模块通过 `long_op_o/compute_op_o/div_busy_o/sqrt_busy_o` 纳入现有 `drain_wait_w` 和 debug busy 逻辑。

## 阶段 2b - 状态机

模块本身不新增状态机；唯一时序状态在既有 `OooFpDivIter` 与 `OooFpSqrtIter` 内部。

| 状态来源 | 初始/清理 | 转换 | 输出 |
| --- | --- | --- | --- |
| FDIV iter | `rst/flush_i` 清 idle | `long_start_i && div_op` 进入 busy，完成后 done | quotient/remainder/done |
| FSQRT iter | `rst/flush_i` 清 idle | `long_start_i && sqrt_op` 进入 busy，完成后 done | root/remainder/done |

## 阶段 2c - 不变量

- `long_op_o` 只允许 FDIV/FSQRT 且目的为 FPR 的 OP-FP 指令置位。
- `compute_op_o` 只覆盖非 load/store、非 long-op 的 pending FP 指令。
- 单精度写 FPR 的结果必须 NaN-box 到高 32 位全 1；单精度 store 的 `mem_wstrb_o` 从 byte address lane 左移。
- `mem_aligned_addr_o` 只用于总线 8B window；`mem_addr_o` 保留 exact byte address 给父模块锁存和 load response lane 选择。
- 本模块不得直接写任何架构状态，所有输出必须由父模块在原有 pending/commit 时序点采样。

## 阶段 2d - 数据通路约束

- `inst_i[6:0]` 和 `inst_i[31:25]` 形成 op class mux，选择 class/compare/sgnj/addsub/mul/fma/minmax/convert/move 路径。
- `frs1/frs2/frs3` 直接进入 FP helper 函数；`int_rs1_value_i` 只用于 FP load/store 地址和 int-to-FPR/move-to-FPR。
- FDIV/FSQRT 先把操作数规整成迭代器输入，done 后再由 helper 函数组合成 IEEE 结果和 fflags。
- 父模块仍打一拍保存 `compute_value_o/compute_fflags_o`，切断 helper 到提交写回的组合锥。
