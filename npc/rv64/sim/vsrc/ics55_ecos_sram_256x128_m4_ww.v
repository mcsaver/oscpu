// Cycle-level functional view of the ECOS 256 x 128 single-port SRAM.
// The official *_core.v is the oracle; its #1 output delay is omitted here
// for the untimed Verilator CPU harness. CEB/GWEB are active low:
// writes update memory and Q; reads register Q; disabled cycles hold Q.
// No reset/initialization. MAR/MARE are ignored by the official core view.
// Synthesis retains the macro name and must load its real vendor Liberty.
// The simulation array is never a synthesizable SRAM replacement.
`ifdef SYNTHESIS
(* blackbox *)
`endif
module ics55_ecos_sram_256x128_m4_ww (
`ifdef POWER_PIN
  inout VSS,
  inout VDD,
`endif
  input [3:0] MAR,
  input [127:0] D,
  output [127:0] Q,
  input MARE,
  input GWEB,
  input [7:0] A,
  input CLK,
  input CEB
);
`ifndef SYNTHESIS
  reg [127:0] memory_q [0:255];
  reg [127:0] data_q;
  wire mem_read = ~CEB & GWEB;
  wire mem_write = ~CEB & ~GWEB;
  wire unused_test_controls = ^{MAR, MARE};
`ifdef POWER_PIN
  wire unused_power_pins = VSS ^ VDD;
`endif
  always @(posedge CLK) begin
    if (mem_write) begin
      memory_q[A] <= D;
      data_q <= D;
    end else if (mem_read) begin
      data_q <= memory_q[A];
    end
  end
  assign Q = data_q;
`endif
endmodule
