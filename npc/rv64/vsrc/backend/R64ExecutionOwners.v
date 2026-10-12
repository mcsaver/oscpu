// Execution-local value leases. These authorize speculative fast values only;
// architectural WB and side effects still require the lifecycle certificate.
// Recovery has already crossed the registered execution-domain ingress.
module R64ExecutionOwners #(
  parameter TAG_W=9, ROB_W=5, PREG_W=6, QUERIES=4, LOAD_QUERIES=2,
  parameter N=(1<<ROB_W)
) (
  input clk, rst, flush_i,
  input [N-1:0] kill_mask_i,
  input [1:0] birth_i, birth_write_i, birth_fp_i, birth_load_i,
  input [2*TAG_W-1:0] birth_tag_i,
  input [2*PREG_W-1:0] birth_preg_i,
  input [1:0] wb_accept_i,
  input [2*TAG_W-1:0] wb_tag_i,
  input [QUERIES-1:0] query_valid_i,
  input [QUERIES*TAG_W-1:0] query_tag_i,
  input [QUERIES*PREG_W-1:0] query_preg_i,
  output [QUERIES-1:0] query_accept_o,
  input [LOAD_QUERIES-1:0] load_capture_i,
  input [LOAD_QUERIES*TAG_W-1:0] load_tag_i,
  output [LOAD_QUERIES-1:0] load_promise_o,
  output [LOAD_QUERIES*PREG_W-1:0] load_preg_o
);
  reg [N-1:0] live_q, write_q, fp_q, load_q;
  reg [TAG_W-1:0] tag_q[0:N-1];
  reg [PREG_W-1:0] preg_q[0:N-1];
  genvar q;
  generate
    for (q=0;q<QUERIES;q=q+1) begin : gen_query
      wire [TAG_W-1:0] tag_w=query_tag_i[q*TAG_W+:TAG_W];
      wire [ROB_W-1:0] slot_w=tag_w[ROB_W-1:0];
      assign query_accept_o[q]=query_valid_i[q] && !rst && !flush_i &&
          !kill_mask_i[slot_w] && live_q[slot_w] && write_q[slot_w] &&
          !fp_q[slot_w] && tag_q[slot_w]==tag_w &&
          preg_q[slot_w]==query_preg_i[q*PREG_W+:PREG_W] &&
          query_preg_i[q*PREG_W+:PREG_W]!=0;
    end
    for (q=0;q<LOAD_QUERIES;q=q+1) begin : gen_load_capture
      wire [TAG_W-1:0] tag_w=load_tag_i[q*TAG_W+:TAG_W];
      wire [ROB_W-1:0] slot_w=tag_w[ROB_W-1:0];
      // Fixed-source tag selects the resident destination. This lookup only
      // certifies scheduling/value identity; numerical transport remains on
      // the independent held-result observation or canonical WB channels.
      assign load_preg_o[q*PREG_W+:PREG_W]=preg_q[slot_w];
      assign load_promise_o[q]=load_capture_i[q] && !rst && !flush_i &&
          !kill_mask_i[slot_w] && live_q[slot_w] && write_q[slot_w] &&
          load_q[slot_w] && !fp_q[slot_w] && tag_q[slot_w]==tag_w && preg_q[slot_w]!=0;
    end
  endgenerate
  integer lane;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      live_q<=0;
      write_q<=0;
      fp_q<=0;
      load_q<=0;
      for (integer s=0;s<N;s=s+1) begin tag_q[s]<=0;preg_q[s]<=0;end
    end else begin
      live_q<=live_q & ~kill_mask_i;
      for (lane=0;lane<2;lane=lane+1)
        if (wb_accept_i[lane] &&
            tag_q[wb_tag_i[lane*TAG_W+:ROB_W]]==wb_tag_i[lane*TAG_W+:TAG_W])
          live_q[wb_tag_i[lane*TAG_W+:ROB_W]]<=0;
      for (lane=0;lane<2;lane=lane+1)
        if (birth_i[lane]) begin
          // Non-writers need no value lease: ordinary stores use a dedicated
          // precise terminal and do not necessarily generate canonical WB.
          live_q[birth_tag_i[lane*TAG_W+:ROB_W]]<=birth_write_i[lane];
          write_q[birth_tag_i[lane*TAG_W+:ROB_W]]<=birth_write_i[lane];
          fp_q[birth_tag_i[lane*TAG_W+:ROB_W]]<=birth_fp_i[lane];
          load_q[birth_tag_i[lane*TAG_W+:ROB_W]]<=birth_load_i[lane];
          tag_q[birth_tag_i[lane*TAG_W+:ROB_W]]<=birth_tag_i[lane*TAG_W+:TAG_W];
          preg_q[birth_tag_i[lane*TAG_W+:ROB_W]]<=birth_preg_i[lane*PREG_W+:PREG_W];
        end
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk)
    if (!rst) begin
      if (flush_i && birth_i!=0)
        $fatal(1,"Execution birth crossed local recovery fence");
      for (integer l=0;l<2;l=l+1)
        if (birth_i[l] &&
            (kill_mask_i[birth_tag_i[l*TAG_W+:ROB_W]] ||
             live_q[birth_tag_i[l*TAG_W+:ROB_W]]))
          $fatal(1,"Execution birth reused a live or cancelled value lease");
      if (birth_i==3 && birth_tag_i[0+:ROB_W]==birth_tag_i[TAG_W+:ROB_W])
        $fatal(1,"Execution dual birth shares a lease slot");
    end
`endif
endmodule
