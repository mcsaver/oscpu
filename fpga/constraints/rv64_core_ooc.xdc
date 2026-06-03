# Core 级 out-of-context 综合只约束 RV64 core 的主时钟。
# 板级引脚、IO standard 和真实外设约束需要等 FPGA wrapper 明确后再补。
create_clock -name core_clk -period 10.000 [get_ports clk]
