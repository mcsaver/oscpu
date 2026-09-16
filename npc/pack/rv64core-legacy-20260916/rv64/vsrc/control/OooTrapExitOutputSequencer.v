`include "include/define.v"

module OooTrapExitOutputSequencer (
  input wire clk,
  input wire rst,

  input wire trap_i,
  input wire [`TRAP_CAUSE_W-1:0] trap_cause_i,
  input wire [`XLEN-1:0] trap_pc_i,
  input wire [`XLEN-1:0] trap_tval_i,

  input wire exit_i,
  input wire exit_is_ecall_i,
  input wire exit_is_ebreak_i,

  output reg trap_valid_o,
  output reg [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output reg [`XLEN-1:0] trap_pc_o,
  output reg [`XLEN-1:0] trap_tval_o,
  output reg exit_valid_o,
  output reg exit_is_ecall_o,
  output reg exit_is_ebreak_o,
  output reg halted_o
);

  always @(posedge clk) begin
    if (rst) begin
      trap_valid_o <= 1'b0;
      trap_cause_o <= {`TRAP_CAUSE_W{1'b0}};
      trap_pc_o <= {`XLEN{1'b0}};
      trap_tval_o <= {`XLEN{1'b0}};
      exit_valid_o <= 1'b0;
      exit_is_ecall_o <= 1'b0;
      exit_is_ebreak_o <= 1'b0;
      halted_o <= 1'b0;
    end else begin
      if (trap_i) begin
        halted_o <= 1'b1;
        trap_valid_o <= 1'b1;
        trap_cause_o <= trap_cause_i;
        trap_pc_o <= trap_pc_i;
        trap_tval_o <= trap_tval_i;
      end

      // trap_i and exit_i are required to be one-hot at the event mux.  Keep
      // trap priority explicit at this final sticky boundary as well, so an
      // invalid overlap cannot create dual terminal status.
      if (!trap_i && exit_i) begin
        halted_o <= 1'b1;
        exit_valid_o <= 1'b1;
        exit_is_ecall_o <= exit_is_ecall_i;
        exit_is_ebreak_o <= exit_is_ebreak_i;
      end
    end
  end

endmodule
