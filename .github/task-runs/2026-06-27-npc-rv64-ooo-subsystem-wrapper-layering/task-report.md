# 任务报告

## 任务

把 `core/OooCoreTopGlue.v` 从"扁平例化 ~80 个 owner 的装配壳"按"目录即架构边界"
重构为子系统 wrapper 分层：让顶层只例化少数几个目录对齐的子系统 wrapper。用户要求
按工业化标准重构，沿用既有 RED→lint→build→103 module TB→official riscv-tests→
task-run+memory 方法学，连续多刀直到该战线收口。

## 方法

纯结构变换 + 编译 oracle：写连通性分析器（`glue_conn.py`）解析所有子模块端口方向
与 glue 实例连接，对任意 instance cluster 自动导出 wrapper 端口集合/方向；写生成器
（`gen_wrapper.py`）自动产出 wrapper 模块 + glue 替换实例 + 打补丁后的 glue，再用
Verilator lint + iverilog module TB 做编译/功能 oracle。每刀全回归后落盘。

分析器迭代中暴露并修复了 3 类边界 bug（均由 oracle 兜底捕获）：
1. glue 级 `wire X = <expr>;` 连续赋值（unused 聚合）的 RHS 引用未计入"外部消费"，
   导致被外部聚合引用的 cluster 产出信号被误判 internal → 补 `glue_assign_rhs_signals`。
2. glue 级 `wire X = <expr>;` 的 LHS（如 `dispatch0_facts_w` packing）被 cluster 消费时
   应为 wrapper 输入，却被误判 internal → 补 `glue_assign_lhs_names`。
3. 连续赋值 wire 的位宽未被 width 查询覆盖，导致 41 位 `dispatch0_facts_w` 端口被声明成
   1 位、信号被截断 → 补 `glue_all_wire_widths`。
另外修复：wrapper 实例插到 `endmodule` 前（满足 iverilog 先声明后使用）、wrapper 只
声明实际使用的 param/localparam（避免 Verilator UNUSEDPARAM）、testbench/`NpcSimTop`
全部 glue 顶层探针信号加入 keep 集强制保留为边界端口。

## 切片与结果（每刀 lint+build+103 module TB+177 official riscv-tests 全 PASS，0 FAIL）

| 刀 | wrapper | 聚合 | 实例数 | 端口 |
| --- | --- | --- | --- | --- |
| 1 | `memory/OooMemoryAccess.v` | memory/ | 2 | 60 |
| 2 | `writeback/OooWriteback.v` | writeback/ | 5 | 113 |
| 3 | `execute/OooExecuteBackend.v` | execute/ | 4 | 149 |
| 4 | `control/OooControlPlane.v` | control/ | 13 | 222 |
| 5 | `frontend/OooFrontend.v` | frontend/ + 6×DecodeStage | 55 | 270 |

最终 `OooCoreTopGlue.v`：6 个实例（5 子系统 wrapper + `OooPendingOperandReadGate`
单叶子）、约 1.4k 行（原约 3.5k）、0 个 `always`、1 个 `assign`。

## 验证

- `make -C npc/rv64 lint`（Verilator -Wall，warning 即 error）PASS。
- `make -C npc/rv64 -j2` build PASS。
- 默认 module testbench 103/103 PASS（含探针深入 glue 内部的 `tb_ooo_core_top_glue`、
  `tb_ooo_fetch_trap_gate`（探针路径加 `u_frontend.` 前缀）、`tb_ooo_priv_system`、
  `tb_ooo_sv39_boot`）。
- official riscv-tests（rv64ui/um/ua/uc/uzb{a,b,c,s}/uf/ud + privileged mi/si，177 项）
  0 FAIL，最终 run `npc/rv64/perf/results/core-regress/20260627-213809-168946/`。
  全 5 wrapper 同时在位下 177 项全过，端到端证明无任何 wrapper 宽度截断或误连。

## 边界

只完成子系统 wrapper 结构分层，不改变任何 owner 的状态机/时序/语义。
`OooFpPendingExec`/`OooIntBackend` 巨石内部拆分、common packed bus 全面化、
单叶子 `OooPendingOperandReadGate` 并入 regread 子系统、formal/PPA/timing/CDC/物理
sign-off 仍是后续独立战线。
