`include "define.v"

module OooRasStack #(
  parameter DEPTH = 32,
  parameter INDEX_W = 5,
  parameter COUNT_W = 6
) (
  input clk,
  input rst,

  input clear_i,
  input pop_i,
  input push_i,
  input [`XLEN-1:0] push_value_i,

  output empty_o,
  output full_o,
  output reliable_o,
  output [`XLEN-1:0] top_o
);

  localparam [COUNT_W-1:0] DEPTH_VALUE = DEPTH;
  localparam [INDEX_W-1:0] LAST_INDEX = {INDEX_W{1'b1}};

  reg [`XLEN-1:0] stack_q [0:DEPTH-1];
  reg [COUNT_W-1:0] count_q;
  reg reliable_q;

  wire empty_w = (count_q == {COUNT_W{1'b0}});
  wire full_w = (count_q == DEPTH_VALUE);
  wire [INDEX_W-1:0] push_idx_w =
      full_w ? LAST_INDEX : count_q[INDEX_W-1:0];
  wire [INDEX_W-1:0] top_idx_w =
      full_w ? LAST_INDEX :
               (count_q[INDEX_W-1:0] -
                {{(INDEX_W-1){1'b0}}, 1'b1});

  assign empty_o = empty_w;
  assign full_o = full_w;
  assign reliable_o = reliable_q;
  assign top_o = stack_q[top_idx_w];

  integer reset_idx;

  always @(posedge clk) begin
    if (rst) begin
      count_q <= {COUNT_W{1'b0}};
      reliable_q <= 1'b1;
      for (reset_idx = 0; reset_idx < DEPTH; reset_idx = reset_idx + 1) begin
        stack_q[reset_idx] <= {`XLEN{1'b0}};
      end
    end else if (clear_i) begin
      count_q <= {COUNT_W{1'b0}};
      reliable_q <= 1'b1;
    end else if (pop_i) begin
      count_q <= count_q - {{(COUNT_W-1){1'b0}}, 1'b1};
      if (count_q == {{(COUNT_W-1){1'b0}}, 1'b1}) begin
        reliable_q <= 1'b1;
      end
    end else if (push_i) begin
      stack_q[push_idx_w] <= push_value_i;
      if (!full_w) begin
        count_q <= count_q + {{(COUNT_W-1){1'b0}}, 1'b1};
      end else begin
        reliable_q <= 1'b0;
      end
    end
  end

endmodule
