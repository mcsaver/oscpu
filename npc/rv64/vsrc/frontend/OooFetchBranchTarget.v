`include "define.v"

// T3L: RV64 B-type target without an XLEN-wide sign-extended immediate ABI.
// The low 12-bit sum determines the 4 KiB carry; the page number changes by
// carry-sign. Both arithmetic operations are modulo their natural widths.
module OooFetchBranchTarget (
  input clk,
  input rst,
  input valid_i,
  input [`XLEN-1:0] pc_i,
  input [12:0] bimm_i,
  output wire [`XLEN-1:0] target_o
);

  wire [12:0] low_sum_w =
      {1'b0, pc_i[11:0]} + {1'b0, bimm_i[11:0]};
  wire [`XLEN-13:0] high_sum_w =
      pc_i[`XLEN-1:12] +
      {{(`XLEN-13){1'b0}}, low_sum_w[12]} -
      {{(`XLEN-13){1'b0}}, bimm_i[12]};

  assign target_o = {high_sum_w, low_sum_w[11:0]};

`ifdef OOO_ASSERT
  wire [`XLEN-1:0] reference_target_w =
      pc_i + {{(`XLEN-13){bimm_i[12]}}, bimm_i};
  always @(posedge clk) begin
    if (!rst && valid_i && (target_o !== reference_target_w)) begin
      $error("[FETCH-BRANCH-TARGET-EQUIV] split target differs from RV64 reference");
    end
  end
`endif

endmodule
