// Physical ownership transfers only on in_valid && in_ready. Three fixed
// slots per lane retain capture and departure at full bandwidth. Owner/live
// disposition is captured with the payload; later cancellation only changes live.
// Cancellation changes narrow live state; payload never moves or depends on kill.
module R64LsuResponseIngress #(
  parameter DATA_W=152, TAG_W=9, ROB_W=5
) (
  input clk_i, rst_i, flush_i,
  input [(1<<ROB_W)-1:0] kill_mask_i,
  input [1:0] in_valid_i,
  output [1:0] in_ready_o,
  input [1:0] in_live_i,
  input [2*TAG_W-1:0] in_tag_i,
  input [2*DATA_W-1:0] in_data_i,
  output [1:0] out_occupied_o, out_valid_o,
  input [1:0] out_ready_i,
  output [2*TAG_W-1:0] out_tag_o,
  output [2*DATA_W-1:0] out_data_o,
  output reg [(1<<ROB_W)-1:0] reuse_block_o,
  output idle_o
);
  reg [2:0] valid_q[0:1], live_q[0:1];
  reg [1:0] head_q[0:1], tail_q[0:1];
  reg [TAG_W-1:0] tag_q[0:1][0:2];
  reg [DATA_W-1:0] data_q[0:1][0:2];
  wire [1:0] capture_w, pop_w;
  wire [2:0] cancel_w[0:1];
  genvar l,s;
  generate for(l=0;l<2;l=l+1) begin:g_lane
    assign in_ready_o[l]=!rst_i && !valid_q[l][tail_q[l]];
    assign capture_w[l]=in_valid_i[l] && in_ready_o[l];
    assign out_occupied_o[l]=valid_q[l][head_q[l]];
    assign out_valid_o[l]=out_occupied_o[l] && live_q[l][head_q[l]] &&
        !cancel_w[l][head_q[l]] && !rst_i;
    assign out_tag_o[l*TAG_W+:TAG_W]=tag_q[l][head_q[l]];
    assign out_data_o[l*DATA_W+:DATA_W]=data_q[l][head_q[l]];
    assign pop_w[l]=out_occupied_o[l] &&
        (!live_q[l][head_q[l]] || cancel_w[l][head_q[l]] || out_ready_i[l]);
    always @(posedge clk_i) begin
      if(rst_i) begin head_q[l]<=0; tail_q[l]<=0; end
      else begin
        if(capture_w[l]) tail_q[l]<=tail_q[l]==2 ? 0 : tail_q[l]+1'b1;
        if(pop_w[l]) head_q[l]<=head_q[l]==2 ? 0 : head_q[l]+1'b1;
      end
    end
    for(s=0;s<3;s=s+1) begin:g_slot
      assign cancel_w[l][s]=flush_i || kill_mask_i[tag_q[l][s][ROB_W-1:0]];
      wire target_w=tail_q[l]==s;
      always @(posedge clk_i)
        if(!rst_i && !valid_q[l][s] && target_w) begin
          tag_q[l][s]<=in_tag_i[l*TAG_W+:TAG_W];
          data_q[l][s]<=in_data_i[l*DATA_W+:DATA_W];
        end
      always @(posedge clk_i) begin
        if(rst_i) begin
          valid_q[l][s]<=0; live_q[l][s]<=0;
        end else begin
          if(valid_q[l][s]) begin
            if(cancel_w[l][s]) live_q[l][s]<=0;
          end
          if(pop_w[l] && head_q[l]==s) begin
            valid_q[l][s]<=0; live_q[l][s]<=0;
          end
          if(capture_w[l] && target_w) begin
            valid_q[l][s]<=1;
            live_q[l][s]<=in_live_i[l] && !flush_i &&
                !kill_mask_i[in_tag_i[l*TAG_W+:ROB_W]];
          end
        end
      end
    end
  end endgenerate
  assign idle_o=!(|valid_q[0]) && !(|valid_q[1]);
  integer lane,slot;
  always @* begin
    reuse_block_o=0;
    for(lane=0;lane<2;lane=lane+1)
      for(slot=0;slot<3;slot=slot+1)
        if(valid_q[lane][slot]) reuse_block_o[tag_q[lane][slot][ROB_W-1:0]]=1;
  end
`ifdef R64_ASSERT
  always @(posedge clk_i) if(!rst_i) begin
    if((out_valid_o & ~out_occupied_o)!=0)
      $fatal(1,"response ingress published absent resident owner");
    if(head_q[0]>2 || head_q[1]>2 || tail_q[0]>2 || tail_q[1]>2)
      $fatal(1,"response ingress pointer out of range");
  end
`endif
endmodule
