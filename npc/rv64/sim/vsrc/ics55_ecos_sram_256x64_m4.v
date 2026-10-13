// ECOS55 SRAM adaptation: cycle view of the vendor 256x64 bit-write macro.
// CEB/GWEB/WEB are active low. A written bit updates memory and Q; masked
// bits retain their previous Q (not the selected row). Disabled cycles hold Q.
// The vendor core is the oracle; only its output delay is omitted here.
// Synthesis retains the real macro and uses its matching vendor Liberty.
`ifdef SYNTHESIS
(* blackbox *)
`endif
module ics55_ecos_sram_256x64_m4 (
`ifdef POWER_PIN
  inout VSS,
  inout VDD,
`endif
  input [3:0] MAR,
  input [63:0] D,
  output [63:0] Q,
  input MARE,
  input GWEB,
  input [7:0] A,
  input [63:0] WEB,
  input CLK,
  input CEB
);
`ifndef SYNTHESIS
  reg [63:0] memory_q [0:255];
  reg [63:0] data_q;
  wire unused_test_controls = ^{MAR, MARE};
`ifdef POWER_PIN
  wire unused_power_pins = VSS ^ VDD;
`endif
  integer bit_index;
  always @(posedge CLK) begin
    if (!CEB) begin
      if (GWEB) data_q <= memory_q[A];
      else
        for (bit_index = 0; bit_index < 64; bit_index = bit_index + 1)
          if (!WEB[bit_index]) begin
            memory_q[A][bit_index] <= D[bit_index];
            data_q[bit_index] <= D[bit_index];
          end
    end
  end
  assign Q = data_q;
`endif
endmodule
