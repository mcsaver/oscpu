# macro-lib — NpcTop 黑盒宏的 non-signoff 占位 Liberty

## 是什么 / 不是什么

本目录 4 个 `.lib` 是 NpcTop 综合网表中黑盒 cell 的**占位时序模型**，
唯一目的是让 iEDA STA 的时序图闭合（消除 `liberty cell X is not exist`、
data propagation 不收敛），从而产出 rpt/pwr：

| cell | RTL 真源 | 角色 |
| --- | --- | --- |
| `Sram4096x199` | `npc/rv64/vsrc/sram/Sram4096x199.v` | 取指包 cache payload SRAM (1RW) |
| `Sram4096x113` | `npc/rv64/vsrc/sram/Sram4096x113.v` | dcache 数据 SRAM (1RW) |
| `OooFpArithGate` | `npc/rv64/vsrc/execute/OooFpArithGate.v` | FP 加/乘/FMA 多拍流水宏 |
| `OooBranchDirectionPredictor` | `npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v` | BPU 方向预测宏 |

**数字无物理意义，不做签核**（宏合同 v1 既定形态，见
`npc/rv64/design/specs/yosys-macro-boundary-contracts.md`）。占位口径：

- 全部按「寄存器边界宏」形式抽象：所有 input 对 clk 上升沿有 setup/hold，所有 output
  有 clk→Q 固定 delay；每颗宏当前数值以 `gen_macro_libs.py::CELL_TIMING` 为准，并非统一
  0.5/0.1/1.0ns。
- BPU 的真实 lookup 是 0-cycle 组合 view；当前占位模型只给 input→clk setup 与
  clk→output 分离弧，**不表达真实 input→output 组合延迟**，真实弧留给 OOC 特征化。
- BPU static fallback ABI 每 lane 只有 1-bit `lookup*_static_taken_i`。完整 B-imm 不属于
  predictor 边界；若重新出现 64-bit imm port，`check_bpu_macro_contract.py` 必须失败。
- pin cap 0.01pf；单位/操作条件数值对齐 icsprout55 标准单元库
  （1ns / 1pf / 1.2V / 25C / slew_derate 0.5），操作条件名独立
  （`macro_placeholder_tt_1p2_25`）避免跨库同名冲突。

## 再生成路径

`.lib` 由本目录 `gen_macro_libs.py` 生成，**勿手改**。RTL 端口变更后：

1. 从新综合网表（`npc/rv64/build/sta/NpcTop-*/NpcTop.netlist.v` 实例连接）
   或 RTL module 声明核对端口名/位宽；
2. 更新 `gen_macro_libs.py` 里的 `CELLS` 表；
3. `python3 gen_macro_libs.py` 重新生成。

端口名/位宽必须与网表实例连接完全一致，否则 iEDA link 阶段挂脚失败。

## 接入方式

- `yosys-sta/scripts/common.tcl` 读环境变量 `EXTRA_LIB_FILES`（默认空，
  与 `KEEP_HIERARCHY_MODULES` 同哲学）；`sta.tcl` 的 `read_liberty` 追加之。
- `npc/rv64/Makefile` 的 `STA_EXTRA_LIB_FILES ?=` 默认指向本目录 4 个 lib，
  经 `STA_MAKE_ARGS` 传给 `yosys-sta`。`make -C npc/rv64 sta` 即自动生效。

## 替换（签核化）路径

以后有真实宏时序时按同名 cell 直接替换本目录文件即可：SRAM 走 memory
compiler / fakeram 特征化，两个逻辑宏走时序 OOC 特征化（write_timing_model
类流程）。届时删除本 README 的占位声明。
