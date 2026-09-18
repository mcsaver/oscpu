// Shared slow path for ordinary RAM accesses that are not naturally aligned.
// Aligned requests/responses bypass without an added register. A split first
// drains accepted CPU traffic, then owns one byte request at a time. The token
// remains live through the final aggregated response, even after caller kill.
module R64MemorySplit #(parameter TOKEN_W=5)(
 input clk_i,input rst_i,input physical_idle_i,output idle_o,
 input [1:0] in_fast_store_i,output [1:0] out_fast_store_o,
 input [1:0] in_valid_i,output [1:0] in_ready_o,
 input [2*TOKEN_W-1:0] in_token_i,input [127:0] in_addr_i,in_data_i,
 input [3:0] in_op_i,input [1:0] in_cache_i,input [5:0] in_size_i,
 input [15:0] in_strb_i,input [9:0] in_amo_i,
 output [1:0] rsp_valid_o,input [1:0] rsp_ready_i,
 output [2*TOKEN_W-1:0] rsp_token_o,output [127:0] rsp_data_o,
 output [1:0] rsp_error_o,output [5:0] rsp_offset_o,
 output [1:0] out_valid_o,output [1:0] out_request_o,input [1:0] out_ready_i,
 output [2*TOKEN_W-1:0] out_token_o,output [127:0] out_addr_o,out_data_o,
 output [3:0] out_op_o,output [1:0] out_cache_o,output [5:0] out_size_o,
 output [15:0] out_strb_o,output [9:0] out_amo_o,
 input [1:0] mem_rsp_valid_i,output [1:0] mem_rsp_ready_o,
 input [2*TOKEN_W-1:0] mem_rsp_token_i,input [127:0] mem_rsp_data_i,
 input [1:0] mem_rsp_error_i
);
 localparam IDLE=0,SEND=1,WAIT=2,DONE=3;
 reg [1:0] state_q;
 reg [TOKEN_W-1:0] token_q;
 reg [63:0] address_q,store_q,gather_q;
 reg write_q,cache_q,error_q;
 reg [2:0] step_q,last_q;
 wire [1:0] misaligned_w;
 genvar g;
 generate for(g=0;g<2;g=g+1)begin:gen_alignment
  assign misaligned_w[g]=|(in_addr_i[g*64+:3]&((3'b001<<in_size_i[g*3+:3])-1'b1));
 end endgenerate
 wire pending_w=|(misaligned_w&in_valid_i);
 wire selected_w=!(misaligned_w[0]&&in_valid_i[0]);
 wire acquire_w=state_q==IDLE&&pending_w&&physical_idle_i&&!rst_i;
 wire response_lane_w=!mem_rsp_valid_i[0];
 wire response_fire_w=state_q==WAIT&&(|mem_rsp_valid_i);
 assign idle_o=state_q==IDLE;

 // Q state selects the payload owner. Current input VALID determines only
 // whether that owner may transfer or must enter the split slow path. In
 // particular, a pending split must not select stale slow-path op bits and
 // return through the physical service's speculative CPU READY calculation.
 wire input_owner_w=state_q==IDLE;
 wire bypass_w=input_owner_w&&!pending_w;
 assign in_ready_o=rst_i?2'b0:(state_q==IDLE?(pending_w?
   (selected_w?{physical_idle_i,1'b0}:{1'b0,physical_idle_i}):out_ready_i):2'b0);
 assign out_fast_store_o=input_owner_w?in_fast_store_i:2'b0;
 assign out_valid_o=rst_i?2'b0:(bypass_w?in_valid_i:(state_q==SEND?2'b01:2'b0));
 // Readiness/payload preparation can precede the pending-split barrier.
 // If any output can really transfer, this is exactly out_valid_o. During
 // pending split both actual VALIDs are zero and in_ready selects only the
 // slow-path acquisition, so speculative service readiness cannot transfer.
 assign out_request_o=rst_i?2'b0:(input_owner_w?in_valid_i:(state_q==SEND?2'b01:2'b0));

 assign out_token_o=input_owner_w?in_token_i:{{TOKEN_W{1'b0}},token_q};
 assign out_addr_o=input_owner_w?in_addr_i:{64'b0,address_q};
 assign out_data_o=input_owner_w?in_data_i:{64'b0,store_q};
 assign out_op_o=input_owner_w?in_op_i:{2'b0,write_q?2'd1:2'd0};
 assign out_cache_o=input_owner_w?in_cache_i:{1'b0,cache_q};
 assign out_size_o=input_owner_w?in_size_i:6'b0;
 assign out_strb_o=input_owner_w?in_strb_i:{8'b0,(8'b1<<address_q[2:0])};
 assign out_amo_o=input_owner_w?in_amo_i:10'b0;
 assign rsp_valid_o=rst_i?2'b0:(state_q==IDLE?mem_rsp_valid_i:(state_q==DONE?2'b01:2'b0));
 assign rsp_token_o=state_q==IDLE?mem_rsp_token_i:{{TOKEN_W{1'b0}},token_q};
 assign rsp_data_o=state_q==IDLE?mem_rsp_data_i:{64'b0,gather_q};
 assign rsp_error_o=state_q==IDLE?mem_rsp_error_i:{1'b0,error_q};
 assign rsp_offset_o=state_q==IDLE?6'b0:{3'b0,step_q};
 assign mem_rsp_ready_o=rst_i?2'b0:(state_q==IDLE?rsp_ready_i:(state_q==WAIT?2'b11:2'b0));
 always @(posedge clk_i)begin
  if(rst_i)begin
   state_q<=IDLE;token_q<=0;address_q<=0;store_q<=0;gather_q<=0;
   write_q<=0;cache_q<=0;error_q<=0;step_q<=0;last_q<=0;
  end else begin
   if(acquire_w)begin
    token_q<=in_token_i[selected_w*TOKEN_W+:TOKEN_W];
    address_q<=in_addr_i[selected_w*64+:64];store_q<=in_data_i[selected_w*64+:64];
    write_q<=in_op_i[selected_w*2+:2]==1;cache_q<=in_cache_i[selected_w];
    gather_q<=0;error_q<=0;step_q<=0;last_q<=(3'b1<<in_size_i[selected_w*3+:3])-1'b1;state_q<=SEND;
   end
   if(state_q==SEND&&out_ready_i[0])state_q<=WAIT;
   if(response_fire_w)begin
    gather_q[step_q*8+:8]<=mem_rsp_data_i[response_lane_w*64+address_q[2:0]*8+:8];
    if(mem_rsp_error_i[response_lane_w]||step_q==last_q)begin
     error_q<=mem_rsp_error_i[response_lane_w];state_q<=DONE;
    end else begin step_q<=step_q+1'b1;address_q<=address_q+1'b1;state_q<=SEND;end
   end
   if(state_q==DONE&&rsp_ready_i[0])state_q<=IDLE;
  end
 end
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i)begin
  if((|out_valid_o)&&out_request_o!==out_valid_o)$fatal(1,"R64MemorySplit request hint differs on live transfer");
  if(acquire_w&&in_op_i[selected_w*2+:2]>1)$fatal(1,"R64MemorySplit cannot split atomics");
  if(response_fire_w&&(mem_rsp_valid_i==3||mem_rsp_token_i[response_lane_w*TOKEN_W+:TOKEN_W]!=token_q))
   $fatal(1,"R64MemorySplit response owner mismatch");
 end
`endif
endmodule
