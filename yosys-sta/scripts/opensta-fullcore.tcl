read_liberty /home/lyg/PA/ysyx-workbench/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib
read_liberty /home/lyg/PA/ysyx-workbench/npc/rv64/syn/macro-lib/Sram4096x199.lib
read_liberty /home/lyg/PA/ysyx-workbench/npc/rv64/syn/macro-lib/Sram4096x113.lib
read_liberty /home/lyg/PA/ysyx-workbench/npc/rv64/syn/macro-lib/OooFpArithGate.lib
read_liberty /home/lyg/PA/ysyx-workbench/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib
read_verilog /home/lyg/PA/ysyx-workbench/npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v
link_design NpcTop
create_clock -name core_clock -period 10.0 [get_ports clk]
report_checks -path_delay max -group_count 10 -digits 3 > /home/lyg/PA/ysyx-workbench/npc/rv64/build/sta/NpcTop-100MHz/NpcTop.opensta.rpt
report_tns >> /home/lyg/PA/ysyx-workbench/npc/rv64/build/sta/NpcTop-100MHz/NpcTop.opensta.rpt
report_wns >> /home/lyg/PA/ysyx-workbench/npc/rv64/build/sta/NpcTop-100MHz/NpcTop.opensta.rpt
report_power > /home/lyg/PA/ysyx-workbench/npc/rv64/build/sta/NpcTop-100MHz/NpcTop.opensta.pwr
exit
