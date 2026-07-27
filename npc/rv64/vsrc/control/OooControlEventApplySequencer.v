`include "define.v"

module OooControlEventApplySequencer (
  input clk,
  input rst,
  input flush_i,

  input request_valid_i,
  input [`REDIR_REASON_W-1:0] request_reason_i,
  input [`OOO_ROB_INDEX_W-1:0] request_kill_idx_i,

  output apply_valid_o,
  output [`REDIR_REASON_W-1:0] apply_reason_o,
  output [`OOO_ROB_INDEX_W-1:0] apply_kill_idx_o
);

  reg apply_valid_q;
  reg [`REDIR_REASON_W-1:0] apply_reason_q;
  reg [`OOO_ROB_INDEX_W-1:0] apply_kill_idx_q;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      apply_valid_q <= 1'b0;
      apply_reason_q <= `REDIR_REASON_NONE;
      apply_kill_idx_q <= {`OOO_ROB_INDEX_W{1'b0}};
    end else begin
      apply_valid_q <= request_valid_i;
      if (request_valid_i) begin
        apply_reason_q <= request_reason_i;
        apply_kill_idx_q <= request_kill_idx_i;
      end
    end
  end

  assign apply_valid_o = apply_valid_q;
  assign apply_reason_o = apply_reason_q;
  assign apply_kill_idx_o = apply_kill_idx_q;

`ifdef OOO_ASSERT
  wire request_reason_legal_w =
      (request_reason_i == `REDIR_REASON_TRAP) ||
      (request_reason_i == `REDIR_REASON_CSR_COMMIT);
  wire apply_reason_legal_w =
      (apply_reason_q == `REDIR_REASON_TRAP) ||
      (apply_reason_q == `REDIR_REASON_CSR_COMMIT);

  always @(posedge clk) begin
    if (!rst && request_valid_i && !request_reason_legal_w)
      $error("[CONTROL-EVENT] illegal full-flush request reason=%0d @%0t",
             request_reason_i, $time);
    if (!rst && apply_valid_q && !apply_reason_legal_w)
      $error("[CONTROL-EVENT] illegal full-flush apply reason=%0d @%0t",
             apply_reason_q, $time);
  end
`endif

endmodule
