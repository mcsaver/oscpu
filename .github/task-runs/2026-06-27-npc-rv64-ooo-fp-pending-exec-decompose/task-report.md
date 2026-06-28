# 任务报告

## 任务

用户在子系统 wrapper 分层战线收口后要求"继续操作"。按既定多前沿计划进入战线 B：
拆分全核最大单文件 `execute/OooFpPendingExec.v`（~3778 行纯组合 FP 执行数据通路）巨石。
与 wrapper 分层不同，巨石拆分要外移带真实逻辑的 owner，沿用早期 RED→GREEN 专属
testbench + 全回归方法学，逐刀推进。

## 方法

按"函数/中间 wire 仅服务该子路径、不被 FP 算术主路径共享"为判据，挑选可干净外移的
组合 owner：把相关 helper 函数 + 输出形成搬到独立模块，父模块只把结果 mux 改读
owner 输出 wire。每刀先写专属 testbench（覆盖该 owner 全部分支），RED→GREEN 后跑
lint/build/module TB/official riscv-tests。

## 切片与结果（每刀 lint+build+module TB+official riscv-tests 全 PASS，0 FAIL）

| 刀 | owner | 职责 | 专属 TB | 结果 |
| --- | --- | --- | --- | --- |
| 1 | `execute/OooFpMemAccessGate.v` | FLW/FLD/FSW/FSD 有效地址、对齐地址、store wdata/wstrb（单精度按地址低位 lane 左移、wstrb 同步左移、双精度全宽） | `tb_ooo_fp_mem_access_gate`（13 check） | PASS |
| 2 | `execute/OooFpClassifyGate.v` | FCLASS.S/D 的 10 位 class mask（-inf..+inf、sNaN/qNaN、±0、±subnormal） | `tb_ooo_fp_classify_gate`（19 check） | PASS |
| 3 | `execute/OooFpSgnjGate.v` | FSGNJ/N/X（单/双精度 + NaN-box，未 box 单精度按 canonical qNaN） | `tb_ooo_fp_sgnj_gate`（10 check） | PASS |
| 4 | `execute/OooFpCompareGate.v` | FEQ/FLT/FLE、FMIN/FMAX 的 value + fflags（NaN/sNaN/±0 定序，FLT/FLE 遇 qNaN 置 NV、FEQ 仅 sNaN 置 NV） | `tb_ooo_fp_compare_gate`（18 check） | PASS |

共享头 `execute/OooFpPredicates.v`：集中 NaN/sNaN/NaN-box 谓词（`fp_is_nan_s/d_value`、
`fp_is_snan_s/d_value`、`fp_is_boxed_s_value`），compare gate `include` 复用，避免逐模块
复制；`-Ivsrc` 解析，入 `RTL_HEADER_SRCS`。

`OooFpPendingExec.v` 由 3778 行降到 3480 行。四刀均纯组合等价外移、RTL 行为不变。
两个 TB 笔误已定位并修正（均为 TB 期望 bug、RTL 正确）：slice 2 二进制分组、slice 4
误用 `\`FP_FLAG_NV` 宏（实为父模块 localparam，非 define.v），改用字面量后 GREEN。

## 验证

- `make -C npc/rv64 lint`（Verilator -Wall）PASS；`-j2` build PASS。
- module testbench 四刀后 107/107 PASS（新增 4 个 FP owner 专属 TB）。
- official riscv-tests 0 FAIL：前两刀跑全 177 项（含 privileged），run
  `…core-regress/20260627-221458-231802/`；后两刀以 rv64ui/uf/ud + privileged 共 101 项
  FP-focused 复跑（含 46 项 rv64uf/ud FP），最新 run
  `npc/rv64/perf/results/core-regress/20260627-222606-260737/`。

## FP 巨石收口（最终状态）

继续完成全部 7 个 FP owner + 3 个共享头，`OooFpPendingExec` 由 3778 行降到 **467 行薄壳**：

| 刀 | owner / 头 | 职责 |
| --- | --- | --- |
| 5 | `OooFpConvertGate.v` | FCVT int↔fp / fp↔fp value+fflags（18 check TB） |
| 6 | `OooFpArithGate.v` | FADD/FSUB/FMUL/FMADD 系列 value+fflags（~1000 行最重，14 check TB） |
| 7 | `OooFpLongOpGate.v` | FDIV/FSQRT 时序 owner（含 div/sqrt 迭代器，3 用例迭代 TB） |
| 共享头 | `OooFpDefs.v` / `OooFpPredicates.v` / `OooFpRound.v` | fflags 常量 / NaN-inf-zero 谓词 / lzc-norm-shift-round helper |

**关键工程坑**：Verilator 的 `define 跨文件全局，函数共享头**不能**用 `ifndef guard（否则
只有首个 include 的模块拿到声明），故头里只放 localparam/function、各模块按
Defs→Predicates→Round 顺序每个只 include 一次；`FP_FLAG_*` 是父模块 localparam（非
define.v），OooFpDefs.v 用 `lint_off UNUSEDPARAM`。arith TB 初版因 task 参数按值在调用时
捕获、漏了调用前 #1 settle 而误报（RTL 正确）。

## 整数后端 OooIntBackend（同战线延伸）

`execute/OooIntBackend.v` 2167→1845：抽出 `OooBitmanipGate.v`（Zbb/Zbc/Zbs 位操作，
两条 issue lane 各一实例）与 `OooAmoGate.v`（RV64A AMO 结果），各配专属 TB。剩余
select_op/rob 顺序/issue-writeback FSM 深度流水线耦合，判定停拆（负收益/风险）。详见
`design/specs/ooo-int-backend-decompose.md`。

## 验证（全程）

- 每刀 lint/build PASS；module testbench 由 103 增到 **112/112**（+9 个 owner TB）；
  official riscv-tests 177 项 0 FAIL（含 46 FP、38 AMO、70 bitmanip）。

## 边界

只做可分离组合/时序 owner 外移，不改数值语义/rounding/NaN/fflags、流水线 issue/bypass/
写回时序或 ROB 顺序。剩余壳/后端逻辑为合理的核心编排，继续拆为负收益。
