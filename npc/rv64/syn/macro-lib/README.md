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

- 全部按「寄存器边界宏」抽象：所有 input 对 clk 上升沿 setup 0.5ns / hold 0.1ns；
  所有 output 从 clk 上升沿出 1.0ns 固定 delay（cell_rise/cell_fall scalar）。
- BPU lookup 等纯组合路径同样挂 clk 弧——占位模型允许，与宏合同 latency
  冻结语义一致；真实组合弧留给未来 OOC 特征化。
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
