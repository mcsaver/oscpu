`include "R64Uop.vh"
// Unified native FP transaction owner. The architectural RAT, PRF, readiness,
// destination and fflags accumulation remain solely in Rename/ROB/commit.
// Ingress stores only the operation, operands and owner; three arithmetic
// paths keep their own elastic completions until fair one-port arbitration.
module R64FpExecute #(parameter TAG_W=9,parameter ROB_W=5,parameter Q_CREDIT_INGRESS=0,parameter RAW_FAST_DISPATCH=0,parameter RAW_FMA_DISPATCH=0)(
 input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input in_fire_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
 input [`R64_UOP_W-1:0] in_uop_i,input [191:0] in_operand_i,
 input fp_enabled_i,input [2:0] frm_i,
 output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,
 output [`R64_RESULT_W-1:0] out_result_o
);
 wire [31:0] command=in_uop_i[159:128];
 wire fused=command[6:0]!=7'h53;
 wire [6:0] function_code=command[31:25];
 wire arithmetic=fused||function_code<=7'h0d||function_code==7'h2c||function_code==7'h2d;
 wire uses_rounding=arithmetic||function_code==7'h20||function_code==7'h21||
   function_code==7'h60||function_code==7'h61||function_code==7'h68||function_code==7'h69;
 wire [2:0] resolved_rounding=command[14:12]==7 ? frm_i:command[14:12];
 wire illegal=!fp_enabled_i||(uses_rounding&&resolved_rounding>4);
 wire ingress_valid_q;
 wire [TAG_W-1:0] tag_q;
 wire [31:0] command_q;
 wire fast_source_double_q;
 wire [191:0] operand_q;
 wire [2:0] rounding_q;
 wire [1:0] path_q;
 wire [1:0] input_path=illegal ? 2'd3:(!fused&&(function_code==7'h0c||function_code==7'h0d||
   function_code==7'h2c||function_code==7'h2d)) ? 2'd1:arithmetic ? 2'd0:2'd2;
 wire input_source_double=command[25]^(command[31:26]==6'h10);
 wire ingress_live=ingress_valid_q&&!kill_mask_i[tag_q[ROB_W-1:0]];
 wire [3:0] path_ready,path_valid;
 wire [4*TAG_W-1:0] path_tag;
 wire [255:0] path_value;
 wire [19:0] path_flags;
 wire dispatch=ingress_live&&path_ready[path_q]&&!rst&&!flush_i;

 wire [3:0] fire={4{dispatch}}&(4'b0001<<path_q);
 // Fast's existing completion owner records a killed birth before either
 // numerical producer can complete. The actual mode may therefore offer
 // a resident raw head on its cancellation edge. Reset/fullflush are
 // consumed locally by both Fast's token pipe and completion owner.
 // Canonical dispatch still governs this ingress and all other paths.
 wire fast_offer_w=RAW_FAST_DISPATCH ?
   (ingress_valid_q&&path_q==2'd2&&path_ready[2]):fire[2];
 // FMA's fixed-advance token owns a reservation even when arithmetic
 // stage_live is suppressed. Its existing birth dead bit is sampled on
 // the accepting edge and stays with that token through terminal drain.
 wire fma_offer_w=RAW_FMA_DISPATCH ?
   (ingress_valid_q&&path_q==2'd0&&path_ready[0]):fire[0];
 wire [3:0] result_ready;
 wire fused_q=command_q[6:0]!=7'h53;
 wire [6:0] f7_q=command_q[31:25];
 wire double_q=fused_q ? command_q[25]:f7_q[0];
 wire [1:0] fma_kind=fused_q ? 2'd2:f7_q[3] ? 2'd1:2'd0;
 wire negate_product=fused_q&&command_q[3];
 wire negate_addend=fused_q ? command_q[2]:f7_q[2];
 R64FpFma #(.TAG_W(TAG_W),.ROB_W(ROB_W)) fma(
 .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
 .in_fire_i(fma_offer_w),.in_ready_o(path_ready[0]),.in_tag_i(tag_q),
 .a_i(operand_q[63:0]),.b_i(operand_q[127:64]),.c_i(operand_q[191:128]),
 .double_i(double_q),.rounding_i(rounding_q),.kind_i(fma_kind),
 .negate_product_i(negate_product),.negate_addend_i(negate_addend),
 .out_valid_o(path_valid[0]),.out_ready_i(result_ready[0]),.out_tag_o(path_tag[0+:TAG_W]),
 .out_value_o(path_value[0+:64]),.out_flags_o(path_flags[0+:5]));
 R64FpLong #(.TAG_W(TAG_W),.ROB_W(ROB_W)) longop(
 .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
 .in_fire_i(fire[1]),.in_ready_o(path_ready[1]),.in_tag_i(tag_q),
 .a_i(operand_q[63:0]),.b_i(operand_q[127:64]),.double_i(double_q),
 .rounding_i(rounding_q),.sqrt_i(f7_q[5]),
 .out_valid_o(path_valid[1]),.out_ready_i(result_ready[1]),.out_tag_o(path_tag[TAG_W+:TAG_W]),
 .out_value_o(path_value[64+:64]),.out_flags_o(path_flags[5+:5]));
 R64FpFast #(.TAG_W(TAG_W),.ROB_W(ROB_W)) fast(
 .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
 .in_fire_i(fast_offer_w),.in_ready_o(path_ready[2]),.in_tag_i(tag_q),
 .inst_i(command_q),.source_double_i(fast_source_double_q),.a_i(operand_q[63:0]),.b_i(operand_q[127:64]),.rounding_i(rounding_q),
 .out_valid_o(path_valid[2]),.out_ready_i(result_ready[2]),.out_tag_o(path_tag[2*TAG_W+:TAG_W]),
 .out_value_o(path_value[128+:64]),.out_flags_o(path_flags[10+:5]));
 reg fault_valid_q;
 reg [TAG_W-1:0] fault_tag_q;
 reg [31:0] fault_command_q;
 assign path_valid[3]=fault_valid_q&&!kill_mask_i[fault_tag_q[ROB_W-1:0]];
 assign path_ready[3]=!path_valid[3]||result_ready[3];
 assign path_tag[3*TAG_W+:TAG_W]=fault_tag_q;
 assign path_value[192+:64]=0;
 assign path_flags[15+:5]=0;
 reg output_valid_q;
 reg [TAG_W-1:0] output_tag_q;
 reg [`R64_RESULT_W-1:0] output_result_q;
 wire output_live=output_valid_q&&!kill_mask_i[output_tag_q[ROB_W-1:0]];
 wire output_credit=!output_live||out_ready_i;
 reg [1:0] next_q,selected;
 wire [3:0] selected_mask_w;
 wire found=|selected_mask_w;
 wire [4*(TAG_W+`R64_RESULT_W)-1:0] source_tuple_w;
 wire [3:0] upper_segment_w={1'b1,next_q!=2'd3,!next_q[1],next_q==0};
 genvar candidate,other;
 generate for(candidate=0;candidate<4;candidate=candidate+1)begin:g_return_rank
   wire [3:0] older_request_w;
   for(other=0;other<4;other=other+1)begin:g_other
     wire same_segment_w=upper_segment_w[candidate]==upper_segment_w[other];
     assign older_request_w[other]=path_valid[other]&&
         (same_segment_w?(other<candidate):upper_segment_w[other]);
   end
   assign selected_mask_w[candidate]=path_valid[candidate]&&!(|older_request_w);
   wire [`R64_RESULT_W-1:0] result_w;
   if(candidate==3)assign result_w={5'b0,32'b0,fault_command_q,6'd2,1'b1,64'b0};
   else assign result_w={path_flags[candidate*5+:5],64'b0,6'b0,1'b0,path_value[candidate*64+:64]};
   assign source_tuple_w[candidate*(TAG_W+`R64_RESULT_W)+:(TAG_W+`R64_RESULT_W)]=
       {(TAG_W+`R64_RESULT_W){selected_mask_w[candidate]}}&
       {path_tag[candidate*TAG_W+:TAG_W],result_w};
 end endgenerate
 wire [TAG_W+`R64_RESULT_W-1:0] selected_tuple_w=
     (source_tuple_w[0*(TAG_W+`R64_RESULT_W)+:(TAG_W+`R64_RESULT_W)]|
      source_tuple_w[1*(TAG_W+`R64_RESULT_W)+:(TAG_W+`R64_RESULT_W)])|
     (source_tuple_w[2*(TAG_W+`R64_RESULT_W)+:(TAG_W+`R64_RESULT_W)]|
      source_tuple_w[3*(TAG_W+`R64_RESULT_W)+:(TAG_W+`R64_RESULT_W)]);
 integer n;
 always @*begin
   selected=0;
   for(n=0;n<4;n=n+1)selected=selected|({2{selected_mask_w[n]}}&n[1:0]);
 end
 assign result_ready={4{output_credit&&!rst&&!flush_i}}&selected_mask_w;
 // Result payload is selected once by the one-hot rank. Current cancellation
 // affects its valid owner, without adding another wide data mux/enable.
 always @(posedge clk)if(output_credit)
   {output_tag_q,output_result_q}<=selected_tuple_w;
 assign out_valid_o=!rst&&!flush_i&&output_live;
 assign out_tag_o=output_tag_q;
 assign out_result_o=output_result_q;
 // Two fixed owners advertise only physical Q vacancy. A full queue does
 // not spend a same-edge kill/pop credit. Payload and dynamic FP legality
 // are captured together at actual admission; no new empty-path stage.
 generate if(Q_CREDIT_INGRESS)begin:g_ingress_queue
   localparam PAYLOAD_W=TAG_W+230;
   reg [1:0] valid_q;
   reg head_q;
   reg [PAYLOAD_W-1:0] payload_q[0:1];
   wire birth_slot=valid_q[0];
   wire [PAYLOAD_W-1:0] input_payload={in_tag_i,command,input_source_double,
     in_operand_i,resolved_rounding,input_path};
   wire [TAG_W-1:0] tag0=payload_q[0][PAYLOAD_W-1-:TAG_W];
   wire [TAG_W-1:0] tag1=payload_q[1][PAYLOAD_W-1-:TAG_W];
   wire [1:0] live=valid_q&~{kill_mask_i[tag1[ROB_W-1:0]],kill_mask_i[tag0[ROB_W-1:0]]};
   reg [1:0] survivors,valid_next;
   reg head_next;
   assign in_ready_o=!(valid_q[0]&&valid_q[1]);
   assign ingress_valid_q=valid_q[head_q];
   assign {tag_q,command_q,fast_source_double_q,operand_q,rounding_q,path_q}=payload_q[head_q];
   always @(*)begin
     survivors=live;
     if(dispatch)survivors[head_q]=0;
     valid_next=survivors;
     if(in_fire_i)valid_next[birth_slot]=!kill_mask_i[in_tag_i[ROB_W-1:0]];
     head_next=head_q;
     if(!survivors[head_q])begin
       if(survivors[!head_q])head_next=!head_q;
       else if(in_fire_i)head_next=birth_slot;
       else head_next=0;
     end
   end
   always @(posedge clk)if(!(valid_q[0]&&valid_q[1]))
     payload_q[birth_slot]<=input_payload;
   always @(posedge clk)begin
     if(rst||flush_i)begin valid_q<=0;head_q<=0;end
     else begin
       valid_q<=valid_next;head_q<=head_next;

     end
   end
`ifdef R64_ASSERT
   always @(posedge clk)if(!rst&&!flush_i)begin
     if((|valid_q)&&!valid_q[head_q])$fatal(1,"R64 FP ingress queue lost oldest owner");
     if(in_fire_i&&valid_q[birth_slot])$fatal(1,"R64 FP ingress queue overwrote occupied slot");
   end
`endif
 end else begin:g_ingress_legacy
   reg valid_q;
   reg [TAG_W+229:0] payload_q;
   assign in_ready_o=!rst&&!flush_i&&(!ingress_live||dispatch);
   assign ingress_valid_q=valid_q;
   assign {tag_q,command_q,fast_source_double_q,operand_q,rounding_q,path_q}=payload_q;
   always @(posedge clk)begin
     if(rst||flush_i)valid_q<=0;
     else begin
       if(!ingress_live||dispatch)valid_q<=0;
       if(in_fire_i)begin
         valid_q<=!kill_mask_i[in_tag_i[ROB_W-1:0]];
         payload_q<={in_tag_i,command,input_source_double,in_operand_i,resolved_rounding,input_path};
       end
     end
   end
 end endgenerate
 always @(posedge clk)begin
   if(rst||flush_i)begin fault_valid_q<=0;output_valid_q<=0;next_q<=0;end
   else begin
     if(path_ready[3])begin
       fault_valid_q<=fire[3];
       if(fire[3])begin fault_tag_q<=tag_q;fault_command_q<=command_q;end
     end
     if(output_credit)begin
       // Numerical sources may report registered raw VALID on a kill edge.
       // Never create a fresh output holder for such a canceled owner.
       output_valid_q<=found&&!kill_mask_i[path_tag[selected*TAG_W+:ROB_W]];
       if(found)begin
         next_q<=selected+1'b1;
       end
     end
   end
 end
`ifdef R64_ASSERT
 always @(posedge clk)if(RAW_FMA_DISPATCH&&!rst&&!flush_i)begin
   if(fire[0]&&!fma_offer_w)$fatal(1,"FP raw FMA offer lost canonical dispatch");
   if(fma_offer_w&&!fire[0]&&!kill_mask_i[tag_q[ROB_W-1:0]])
     $fatal(1,"FP extra FMA offer has no cancellation owner");
 end
 always @(posedge clk)if(RAW_FAST_DISPATCH&&!rst&&!flush_i)begin
   if(fire[2]&&!fast_offer_w)$fatal(1,"FP raw Fast offer lost canonical dispatch");
   if(fast_offer_w&&!fire[2]&&!kill_mask_i[tag_q[ROB_W-1:0]])
     $fatal(1,"FP extra Fast offer has no cancellation owner");
 end
 always @(posedge clk)if(!rst&&!flush_i&&in_fire_i&&!in_ready_o)
   $fatal(1,"R64 FP ingress admitted without credit");
`endif
endmodule
