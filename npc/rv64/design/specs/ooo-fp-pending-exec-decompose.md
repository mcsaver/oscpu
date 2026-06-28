# OooFpPendingExec 巨石拆分 Spec（已完成薄壳化）

## 1. 目标与结果

`execute/OooFpPendingExec.v` 曾是全核最大单文件（~3778 行，63 个 helper 函数 +
大结果 mux + div/sqrt 迭代器）。本战线按"一职责一 owner"把全部可分离逻辑抽出，
父模块收敛为 **467 行薄编排壳**（-88%），只保留 pending wire 别名、op 译码、结果/
fflags mux、1 个 4 行 trivial move 函数，以及 7 个 FP owner gate 实例：
`OooFpMemAccessGate`、`OooFpClassifyGate`、`OooFpSgnjGate`、`OooFpCompareGate`、
`OooFpConvertGate`、`OooFpArithGate`、`OooFpLongOpGate`。fflags 标志常量（`FP_FLAG_*`）
由 `include/define.v` 的宏统一管理；其余共享 helper 收敛到 2 个头
`OooFpPredicates.v`（NaN/inf/zero 谓词）、`OooFpRound.v`（lzc/norm/shift-jam/round）。
每刀 RED→GREEN 专属 testbench + 全回归。

## 2. 已抽出的 owner（纯组合，行为等价）

| owner | 文件 | 职责 | 专属 TB |
| --- | --- | --- | --- |
| FP 访存操作数 | `execute/OooFpMemAccessGate.v` | FLW/FLD/FSW/FSD 有效地址、对齐地址、store wdata/wstrb（单精度按 lane 左移） | `tb_ooo_fp_mem_access_gate`（13 check） |
| FP 分类 | `execute/OooFpClassifyGate.v` | FCLASS.S/D 的 10 位 class mask | `tb_ooo_fp_classify_gate`（19 check） |
| FP 符号注入 | `execute/OooFpSgnjGate.v` | FSGNJ/N/X（单/双精度 + NaN-box） | `tb_ooo_fp_sgnj_gate`（10 check） |
| FP 比较/最值 | `execute/OooFpCompareGate.v` | FEQ/FLT/FLE、FMIN/FMAX 的 value + fflags | `tb_ooo_fp_compare_gate`（18 check） |
| FP 转换 | `execute/OooFpConvertGate.v` | FCVT int↔fp / fp↔fp 的 value + fflags | `tb_ooo_fp_convert_gate`（18 check） |
| FP 加减/乘/乘加 | `execute/OooFpArithGate.v` | FADD/FSUB/FMUL/FMADD 系列 value + fflags（~1000 行最重组合） | `tb_ooo_fp_arith_gate`（14 check） |
| FP 长延迟运算 | `execute/OooFpLongOpGate.v` | FDIV/FSQRT 时序 owner（内含 div/sqrt 迭代器 + operand prep + result/fflags） | `tb_ooo_fp_long_op_gate`（3 用例迭代到 done） |

共享定义分布：fflags 标志常量 `FP_FLAG_NV/DZ/OF/UF/NX` 作为 `define 宏放在
`include/define.v`（由 define.v 统一管理，每个模块本就 `include "define.v"）；
NaN/sNaN/NaN-box/inf/zero 谓词在 `OooFpPredicates.v`、round_increment/u64/lzc/norm/
shift-jam/round_flags 在 `OooFpRound.v`。这两个函数库头各 owner 按 Predicates→Round
顺序 `include`，**不用 `ifndef guard**（Verilator 的 `define 跨文件全局，guard 会让
只有首个 include 的模块拿到函数声明）；每模块对每个头只 include 一次。函数无法做成
`define 宏（含 reg 局部量与过程逻辑），故不放进 define.v。

抽取判据：函数/中间 wire 仅服务该子路径、共享 helper 提到共享头；父模块保留同名 owner
输出 wire、结果 mux 只改读 owner 输出，迭代器随 long-op owner 一并下沉。

## 3. 完成状态

战线已收口：`OooFpPendingExec` 由 3778 行降到 467 行薄壳。FP move（FMV.X.W/D、FMV.W/D.X）
仅 4 行位操作，过于平凡，按 ROI 判定留在壳内不单独建模块。剩余壳内容（pending wire 别名、
op 译码、result/fflags mux、7 个 owner 实例）属于合理的编排职责，无进一步可正收益拆分。

## 4. 验证（每刀）

- 专属 TB RED→GREEN；`make -C npc/rv64 lint` / build PASS；module testbench 全 PASS
  （已从 103 增到 107，新增 4 个 FP owner 专属 TB）；official riscv-tests（含 rv64uf/ud
  共 46 项 FP）0 FAIL（前两刀跑全 177 项；后两刀以 rv64ui/uf/ud + privileged 共 101 项
  FP-focused 复跑，均 0 FAIL）。
- 已完成 4 刀后 `OooFpPendingExec` 由 3778 行降到约 3480 行。

## 5. 边界

本战线只做组合 owner 外移，不改变 FP 数值语义、rounding、NaN 处理或 fflags；
div/sqrt 迭代器时序、父模块 pending/commit 编排不在本战线范围。
