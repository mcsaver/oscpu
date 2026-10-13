`resetall
`timescale 10ps/1ps
`celldefine

module ics55_ecos_sram_256x128_m4_ww (
`ifdef POWER_PIN
    VSS,
    VDD,
`endif
    MAR,
    D,
    Q,
    MARE,
    GWEB,
    A,
    CLK,
    CEB
  );


  input [7:0] A;
  input CEB;
  input CLK;
  input [127:0] D;
  input GWEB;
  input [3:0] MAR;
  input MARE;
  output [127:0] Q;
`ifdef POWER_PIN
  inout VSS;
  supply0 VSS;
  inout VDD;
  supply1 VDD;
`endif



endmodule
`endcelldefine



