#!/usr/bin/env python3
"""生成 NpcTop 四个黑盒宏的 non-signoff 占位 Liberty(.lib)。

目的:让 iEDA STA 图闭合(消除 "liberty cell X is not exist"、data propagation
不收敛),数字不做签核。宏合同 v1 既定形态,见
npc/rv64/design/specs/yosys-macro-boundary-contracts.md。

抽象:全部按「寄存器边界宏」——所有 input 对 clk 上升沿 setup 0.5ns/hold 0.1ns,
所有 output 从 clk 上升沿出 cell_rise/cell_fall 1.0ns 固定值;pin cap 0.01pf。
纯组合口(BPU lookup 等)也挂 clk 时序弧——占位模型允许,与宏合同 latency 冻结
语义一致。

单位/操作条件对齐 icsprout55 标准单元库
(ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib):time 1ns / cap 1pf / 1.2V / 25C /
slew_derate 0.5 / 30-70 slew threshold。操作条件名刻意不与标准库重名,
避免跨库同名定义冲突,数值(process/temp/voltage)一致。

再生成:端口表以综合网表实例连接为真源(位宽逐条从
build/sta/NpcTop-*/NpcTop.netlist.v 与 RTL module 声明核对);RTL 端口变更后
更新下方 CELLS 表并重跑 `python3 gen_macro_libs.py`(在本目录)。
"""

import os
from datetime import date

# 默认占位弧(BPU/FpArithGate 仍 non-signoff)
SETUP_NS = "0.500"
HOLD_NS = "0.100"
CLK2Q_NS = "1.000"
# 【时序战役 S0(2026-07-10)】SRAM 两颗宏换 CACTI 65nm 实测弧(bsg_fakeram +
# 修改版 CACTI, cfg=~/tools/bsg_fakeram/npc_sram.cfg, 65nm 保守近似 55nm):
#   Sram4096x199: clk-to-q 1.543ns / setup 1.842ns (占位曾 1.0/0.5, setup 差 3.7x!)
#   Sram4096x113: clk-to-q 1.285ns / setup 0.763ns
# BPU/OooFpArithGate 保持占位——它们不是 SRAM, 真实化需 OOC 综合提取(留后续)。
CELL_TIMING = {
    "Sram4096x199": ("1.842", "0.100", "1.543"),
    "Sram4096x113": ("0.763", "0.100", "1.285"),
}
OUT_TRANS_NS = "0.100"
PIN_CAP_PF = "0.010"
MAX_CAP_PF = "0.500"

# 每个 cell: (名字, clock 引脚, [(端口名, 位宽, 方向)])。
# 位宽真源 = NpcTop.netlist.v 实例连接(与 RTL module 声明一致):
#   Sram*: vsrc/sram/Sram4096x{199,113}.v
#   OooFpArithGate: vsrc/execute/OooFpArithGate.v (XLEN=64, ROB_IDX=4,
#     PHY_REG_ADDR=6, fflags=5, rm=3, kind=2)
#   OooBranchDirectionPredictor: vsrc/frontend/OooBranchDirectionPredictor.v
#     (BPU_BHT_INDEX_W=12)
CELLS = [
    ("Sram4096x199", "clk", [
        ("en_i", 1, "input"),
        ("we_i", 1, "input"),
        ("addr_i", 12, "input"),
        ("wdata_i", 199, "input"),
        ("rdata_o", 199, "output"),
    ]),
    # bit-write-mask 变体(2026-07-09 store RMW write-update): wmask_i 与 wdata_i
    # 同宽同 setup 弧——真实 SRAM 宏的 per-bit write mask 端口形态。
    ("Sram4096x113", "clk", [
        ("en_i", 1, "input"),
        ("we_i", 1, "input"),
        ("addr_i", 12, "input"),
        ("wdata_i", 113, "input"),
        ("wmask_i", 113, "input"),
        ("rdata_o", 113, "output"),
    ]),
    ("OooFpArithGate", "clk", [
        ("rst", 1, "input"),
        ("flush_i", 1, "input"),
        ("start_i", 1, "input"),
        ("frs1_value_i", 64, "input"),
        ("frs2_value_i", 64, "input"),
        ("frs3_value_i", 64, "input"),
        ("double_i", 1, "input"),
        ("sub_op_i", 1, "input"),
        ("negate_product_i", 1, "input"),
        ("subtract_addend_i", 1, "input"),
        ("rm_i", 3, "input"),
        ("launch_valid_i", 1, "input"),
        ("launch_rob_idx_i", 4, "input"),
        ("launch_pdest_i", 6, "input"),
        ("launch_kind_i", 2, "input"),
        ("kill_valid_i", 1, "input"),
        ("kill_rob_idx_i", 4, "input"),
        ("rob_head_idx_i", 4, "input"),
        ("addsub_value_o", 64, "output"),
        ("addsub_fflags_o", 5, "output"),
        ("mul_value_o", 64, "output"),
        ("mul_fflags_o", 5, "output"),
        ("fma_value_o", 64, "output"),
        ("fma_fflags_o", 5, "output"),
        ("done_o", 1, "output"),
        ("out_valid_o", 1, "output"),
        ("out_rob_idx_o", 4, "output"),
        ("out_pdest_o", 6, "output"),
        ("out_value_o", 64, "output"),
        ("out_fflags_o", 5, "output"),
    ]),
    ("OooBranchDirectionPredictor", "clk", [
        ("rst", 1, "input"),
        ("clear_i", 1, "input"),
        ("lookup0_pc_i", 64, "input"),
        ("lookup0_imm_i", 64, "input"),
        ("lookup1_pc_i", 64, "input"),
        ("lookup1_imm_i", 64, "input"),
        ("update_valid_i", 1, "input"),
        ("update_pc_i", 64, "input"),
        ("update_bht_idx_i", 12, "input"),
        ("update_taken_i", 1, "input"),
        ("lookup0_bht_idx_o", 12, "output"),
        ("lookup0_bht_valid_o", 1, "output"),
        ("lookup0_pred_taken_o", 1, "output"),
        ("lookup0_predict_strong_o", 1, "output"),
        ("lookup1_bht_idx_o", 12, "output"),
        ("lookup1_bht_valid_o", 1, "output"),
        ("lookup1_pred_taken_o", 1, "output"),
        ("lookup1_predict_strong_o", 1, "output"),
    ]),
]


def bus_type_name(width):
    return "bus_%d" % width


def emit_lib(cell_name, clk_pin, ports):
    setup_ns, hold_ns, clk2q_ns = CELL_TIMING.get(
        cell_name, (SETUP_NS, HOLD_NS, CLK2Q_NS))
    widths = sorted({w for _, w, _ in ports if w > 1})
    L = []
    L.append("/* %s.lib — non-signoff placeholder liberty" % cell_name)
    L.append(" * 占位模型:数字无物理意义,仅用于 iEDA STA 图闭合(宏合同 v1)。")
    L.append(" * 全端口按寄存器边界宏抽象:input setup %sns/hold %sns 对 clk;"
             % (setup_ns, hold_ns))
    L.append(" * output 从 clk 上升沿 %sns 固定 delay;pin cap %spf。"
             % (clk2q_ns, PIN_CAP_PF))
    L.append(" * 单位/操作条件数值对齐 icsprout55 (1ns/1pf/1.2V/25C)。")
    L.append(" * 由 gen_macro_libs.py 生成(%s),勿手改——改端口表后重跑生成器。"
             % date.today().isoformat())
    L.append(" */")
    L.append("library (%s) {" % cell_name)
    L.append("  technology (cmos);")
    L.append("  delay_model : table_lookup;")
    L.append("  time_unit : \"1ns\";")
    L.append("  voltage_unit : \"1V\";")
    L.append("  current_unit : \"1mA\";")
    L.append("  leakage_power_unit : \"1nW\";")
    L.append("  pulling_resistance_unit : \"1kohm\";")
    L.append("  capacitive_load_unit (1,pf);")
    L.append("  nom_process : 1;")
    L.append("  nom_temperature : 25;")
    L.append("  nom_voltage : 1.2;")
    L.append("  input_threshold_pct_fall : 50;")
    L.append("  input_threshold_pct_rise : 50;")
    L.append("  output_threshold_pct_fall : 50;")
    L.append("  output_threshold_pct_rise : 50;")
    L.append("  slew_derate_from_library : 0.5;")
    L.append("  slew_lower_threshold_pct_fall : 30;")
    L.append("  slew_lower_threshold_pct_rise : 30;")
    L.append("  slew_upper_threshold_pct_fall : 70;")
    L.append("  slew_upper_threshold_pct_rise : 70;")
    L.append("  default_cell_leakage_power : 0;")
    L.append("  default_fanout_load : 1;")
    L.append("  default_output_pin_cap : 0;")
    L.append("  default_max_transition : 0.795659;")
    # 操作条件数值与 icsprout55 一致,名字独立避免跨库同名冲突。
    L.append("  operating_conditions (macro_placeholder_tt_1p2_25) {")
    L.append("    process : 1;")
    L.append("    temperature : 25;")
    L.append("    voltage : 1.2;")
    L.append("  }")
    L.append("  default_operating_conditions : macro_placeholder_tt_1p2_25;")
    for w in widths:
        L.append("  type (%s) {" % bus_type_name(w))
        L.append("    base_type : array;")
        L.append("    data_type : bit;")
        L.append("    bit_width : %d;" % w)
        L.append("    bit_from : %d;" % (w - 1))
        L.append("    bit_to : 0;")
        L.append("    downto : true;")
        L.append("  }")
    L.append("  cell (%s) {" % cell_name)
    L.append("    area : 0;")
    L.append("    interface_timing : true;")
    L.append("    pin (%s) {" % clk_pin)
    L.append("      direction : input;")
    L.append("      clock : true;")
    L.append("      capacitance : %s;" % PIN_CAP_PF)
    L.append("    }")
    for name, width, direction in ports:
        kw = "bus" if width > 1 else "pin"
        L.append("    %s (%s) {" % (kw, name))
        if width > 1:
            L.append("      bus_type : %s;" % bus_type_name(width))
        L.append("      direction : %s;" % direction)
        if direction == "input":
            L.append("      capacitance : %s;" % PIN_CAP_PF)
            for ttype, val in (("setup_rising", setup_ns),
                               ("hold_rising", hold_ns)):
                L.append("      timing () {")
                L.append("        related_pin : \"%s\";" % clk_pin)
                L.append("        timing_type : %s;" % ttype)
                L.append("        rise_constraint (scalar) {")
                L.append("          values (\"%s\");" % val)
                L.append("        }")
                L.append("        fall_constraint (scalar) {")
                L.append("          values (\"%s\");" % val)
                L.append("        }")
                L.append("      }")
        else:
            L.append("      max_capacitance : %s;" % MAX_CAP_PF)
            L.append("      timing () {")
            L.append("        related_pin : \"%s\";" % clk_pin)
            L.append("        timing_type : rising_edge;")
            L.append("        timing_sense : non_unate;")
            L.append("        cell_rise (scalar) {")
            L.append("          values (\"%s\");" % clk2q_ns)
            L.append("        }")
            L.append("        cell_fall (scalar) {")
            L.append("          values (\"%s\");" % clk2q_ns)
            L.append("        }")
            L.append("        rise_transition (scalar) {")
            L.append("          values (\"%s\");" % OUT_TRANS_NS)
            L.append("        }")
            L.append("        fall_transition (scalar) {")
            L.append("          values (\"%s\");" % OUT_TRANS_NS)
            L.append("        }")
            L.append("      }")
        L.append("    }")
    L.append("  }")
    L.append("}")
    L.append("")
    return "\n".join(L)


def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    for cell_name, clk_pin, ports in CELLS:
        path = os.path.join(out_dir, cell_name + ".lib")
        with open(path, "w") as f:
            f.write(emit_lib(cell_name, clk_pin, ports))
        print("generated", path)


if __name__ == "__main__":
    main()
