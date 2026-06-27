# OoO FP Register File

## 1. 需求

`OooFpRegFile` 是 `npc/rv64` OoO 核的 FPR 状态 owner。历史上
`OooAluFetchCore` 直接持有 `fpr_q`，这会把 register read / bypass 与
front-end glue 混在一起。该模块把 FPR 存储、pending FP 操作数读取、
FP load 写回和 FP compute/long 写回收束到一个可单测边界。

## 2. 边界

- 模块拥有 32 个 `XLEN` 宽 FPR。
- `rst_i || flush_i` 时所有 FPR 清零，保持父模块原有 reset/flush 语义。
- 提供 3 个组合读端口：`read0/read1/read2`。
- 提供 2 个同步写端口：
  - `load_write_*` 对应 pending FP load 数据写回。
  - `result_write_*` 对应 pending FP compute/long 结果写回。
- 同周期两个写端口写同一个 FPR 时，`result_write_*` 后写覆盖
  `load_write_*`，匹配原父模块同一 always 块内非阻塞赋值顺序。
- FPR 的 `f0` 是普通浮点寄存器，不像 GPR `x0` 一样硬连零，因此写端口不屏蔽
  地址 0。

## 3. 不变量

- 模块不解码 FP 指令，不生成 fflags，不判断精确异常或提交合法性。
- 模块不修改 GPR、CSR、ROB、fetch PC、pending owner 或 memory request。
- 当前抽取只保持原行为，不新增写读同拍 combinational bypass。

## 4. RTL 映射

RTL 文件为 `npc/rv64/vsrc/regread_bypass/OooFpRegFile.v`。
单元测试为 `npc/rv64/testbench/tests/tb_ooo_fp_reg_file.sv`。
