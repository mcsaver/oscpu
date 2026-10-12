// Execution-owned physical readiness. Mapping/free-list state lives in Rename.
// Priority: reset/flush > birth > reclaim > authorized WB. Queries observe Q;
// Issue owns deferred initialization and same-cycle WB/ALU wake handling.
module R64Scoreboard #(
  parameter PREG_W = 6,
  parameter PREG_N = (1 << PREG_W),
  parameter QUERIES = 6,
  parameter BATCH_SUFFIX_ROLLBACK = 0
) (
  input clk, rst, flush_i,
  input [1:0] birth_write_i, birth_fp_i,
  input [2*PREG_W-1:0] birth_preg_i,
  input [1:0] wb_write_i, wb_fp_i,
  input [2*PREG_W-1:0] wb_preg_i,
  input [1:0] reclaim_write_i, reclaim_fp_i,
  input [2*PREG_W-1:0] reclaim_preg_i,
  input [QUERIES*PREG_W-1:0] query_preg_i,
  input [QUERIES-1:0] query_fp_i,
  output [QUERIES-1:0] query_ready_o,
  input batch_apply_i,
  input [PREG_N-1:0] batch_greclaim_i,batch_freclaim_i
);
  reg [PREG_N-1:0] gbusy_q, fbusy_q;
  genvar q;
  generate
    for (q = 0; q < QUERIES; q = q + 1) begin : gen_query
      wire [PREG_W-1:0] preg_w = query_preg_i[q*PREG_W+:PREG_W];
      assign query_ready_o[q] = query_fp_i[q] ? !fbusy_q[preg_w] : !gbusy_q[preg_w];
    end
  endgenerate
  integer lane;
  reg [PREG_W-1:0] preg;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      gbusy_q <= 0;
      fbusy_q <= 0;
    end else begin
      for (lane = 0; lane < 2; lane = lane + 1) begin
        preg = wb_preg_i[lane*PREG_W+:PREG_W];
        if (wb_write_i[lane]) begin
          if (wb_fp_i[lane]) fbusy_q[preg] <= 1'b0;
          else if (preg != 0) gbusy_q[preg] <= 1'b0;
        end
      end
      for (lane = 0; lane < 2; lane = lane + 1) begin
        preg = reclaim_preg_i[lane*PREG_W+:PREG_W];
        if (reclaim_write_i[lane]) begin
          if (reclaim_fp_i[lane]) fbusy_q[preg] <= 1'b0;
          else if (preg != 0) gbusy_q[preg] <= 1'b0;
        end
      end
      if((BATCH_SUFFIX_ROLLBACK != 0)&&batch_apply_i)
        for(integer p=0;p<PREG_N;p=p+1)begin
          if(p!=0&&batch_greclaim_i[p])gbusy_q[p]<=0;
          if(batch_freclaim_i[p])fbusy_q[p]<=0;
        end
      for (lane = 0; lane < 2; lane = lane + 1) begin
        preg = birth_preg_i[lane*PREG_W+:PREG_W];
        if (birth_write_i[lane]) begin
          if (birth_fp_i[lane]) fbusy_q[preg] <= 1'b1;
          else if (preg != 0) gbusy_q[preg] <= 1'b1;
        end
      end
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk)
    if (!rst) begin
      if (gbusy_q[0]) $fatal(1, "R64 execution scoreboard marked integer zero busy");
      if ((birth_write_i[0] && !birth_fp_i[0] && birth_preg_i[0+:PREG_W] == 0) ||
          (birth_write_i[1] && !birth_fp_i[1] && birth_preg_i[PREG_W+:PREG_W] == 0))
        $fatal(1, "R64 execution birth assigned integer zero");
    end
`endif
endmodule
