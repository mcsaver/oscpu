# OoO FP Register File

## 1. 需求

`OooFpRegFile` 是 `npc/rv64` OoO 核的**架构（committed）FPR** 状态 owner，
现为 `OooFpBackend` 内部实例 `u_arch_fpr`。历史上
`OooAluFetchCore` 直接持有 `fpr_q`，这会把 register read / bypass 与
front-end glue 混在一起；B-FP 簇落地（2026-07-02）拆除 pending FP 通道后，
本模块只剩两个活功能：commit 双口写入架构 FPR，以及 `fprs_o` 全量平铺导出
（trap flush 时作为 FP 物理寄存器堆的单拍恢复源）。

## 2. 边界

- 模块拥有 32 个 `XLEN` 宽 FPR。
- 仅 `rst` 时所有 FPR 清零；flush 清零端口/语义已删除（架构寄存器堆若被误接
  真实流水线 flush 会摧毁架构 FP 状态，原 `flush_i` 恒接 `1'b0` 属死代码）。
- 提供 3 个组合读端口：`read0/read1/read2`——在唯一实例中地址恒接 0、数据挂
  unused 线，属端口级死代码（操作数读取已改走 FP 物理寄存器堆）。
- 提供 2 个同步写端口（端口名沿用旧称，现语义为 commit 双写）：
  - `load_write_*` 接 commit lane0（`commit0_fp_*`）。
  - `result_write_*` 接 commit lane1（`commit1_fp_*`）。
- 同周期两个写端口写同一个 FPR 时，`result_write_*` 后写覆盖
  `load_write_*`——即 commit lane1（更年轻指令）胜出，符合程序序 WAW 语义。
- FPR 的 `f0` 是普通浮点寄存器，不像 GPR `x0` 一样硬连零，因此写端口不屏蔽
  地址 0。
- `fprs_o` 把 32 项 FPR 全量平铺导出，作为 trap flush 时 FP 物理寄存器堆
  （`OooFpPhysRegFile` recover 拷贝）的单拍 bulk 恢复源。

## 3. 不变量

- 模块不解码 FP 指令，不生成 fflags，不判断精确异常或提交合法性。
- 模块不修改 GPR、CSR、ROB、fetch PC、pending owner 或 memory request。
- 当前抽取只保持原行为，不新增写读同拍 combinational bypass。

## 4. RTL 映射

RTL 文件为 `npc/rv64/vsrc/regread_bypass/OooFpRegFile.v`。
单元测试为 `npc/rv64/testbench/tests/tb_ooo_fp_reg_file.sv`。
