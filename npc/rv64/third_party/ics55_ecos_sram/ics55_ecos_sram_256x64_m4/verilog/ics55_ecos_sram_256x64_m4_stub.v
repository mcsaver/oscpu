`resetall
`timescale 10ps/1ps
`celldefine

module ics55_ecos_sram_256x64_m4 (
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
    WEB,
    CLK,
    CEB
  );


  input [7:0] A;
  input CEB;
  input CLK;
  input [63:0] D;
  input GWEB;
  input [3:0] MAR;
  input MARE;
  input [63:0] WEB;
  output [63:0] Q;
`ifdef POWER_PIN
  inout VSS;
  supply0 VSS;
  inout VDD;
  supply1 VDD;
`endif



endmodule
`endcelldefine



