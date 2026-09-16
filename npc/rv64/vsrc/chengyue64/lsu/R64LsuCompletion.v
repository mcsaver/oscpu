`include "R64Uop.vh"
// Two independently held completion lanes, each with one skid entry. An LSU
// slot can be released when this queue captures its full ROB-tagged result.
// Backpressured heads never migrate between lanes; explicit kill removes only
// its own tagged completion. Ready depends on registered occupancy alone.
module R64LsuCompletion #(parameter TAG_W=9,parameter ROB_W=5)(
 input clk_i,input rst_i,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input [1:0] in_fire_i,output [1:0] in_ready_o,
 input [2*TAG_W-1:0] in_tag_i,input [2*`R64_RESULT_W-1:0] in_result_i,
 output [1:0] out_valid_o,output [1:0] out_request_o,input [1:0] out_ready_i,
 output [2*TAG_W-1:0] out_tag_o,output [2*`R64_RESULT_W-1:0] out_result_o,
 output reg [(1<<ROB_W)-1:0] reuse_block_o,output idle_o
);
 localparam R=`R64_RESULT_W;
 reg [1:0] front_q,back_q;
 reg [TAG_W-1:0] front_tag_q[0:1],back_tag_q[0:1];
 reg [R-1:0] front_result_q[0:1],back_result_q[0:1];
 reg turn_q;
 wire [1:0] free_w=~back_q;
 wire first_w=free_w[turn_q]?turn_q:!turn_q;
 assign in_ready_o={(&free_w),(|free_w)}&{2{!rst_i&&!flush_i}};
 assign idle_o=(front_q|back_q)==0;
 genvar g;
 generate for(g=0;g<2;g=g+1)begin:gen_out
   assign out_valid_o[g]=front_q[g]&&!flush_i&&!kill_mask_i[front_tag_q[g][ROB_W-1:0]]&&!rst_i;
   assign out_tag_o[g*TAG_W+:TAG_W]=front_tag_q[g];
   assign out_result_o[g*R+:R]=front_result_q[g];
 end endgenerate
 integer l;
 always @*begin
   reuse_block_o=0;
   for(l=0;l<2;l=l+1)begin
     if(front_q[l])reuse_block_o[front_tag_q[l][ROB_W-1:0]]=1;
     if(back_q[l])reuse_block_o[back_tag_q[l][ROB_W-1:0]]=1;
   end
 end
 generate for(g=0;g<2;g=g+1)begin:gen_write
   wire front_remove=front_q[g]&&(out_ready_i[g]||flush_i||kill_mask_i[front_tag_q[g][ROB_W-1:0]]);
   wire back_cancel=flush_i||kill_mask_i[back_tag_q[g][ROB_W-1:0]];
   wire first_take=in_fire_i[0]&&(first_w==g[0]);
   wire second_take=in_fire_i[1]&&(first_w!=g[0]);
   wire take=first_take||second_take;
   // Port demand may precede the result's registered VALID by one edge.
   // It is a hint only: a canceled/empty forecast can reserve a WB port but
   // cannot transfer a tag or value. Keep all result/cancel storage unchanged.
   assign out_request_o[g]=front_q[g]||back_q[g]||take;
   wire front_input=take&&(!front_q[g]||front_remove);
   wire back_input=take&&front_q[g]&&!front_remove;
   wire front_shift=front_remove&&back_q[g];
   // The physical lane assignment is a Q-state fact. Payload preparation
   // must not traverse the final event grant a second time.
   wire input_lane=first_w!=g[0];
   wire [TAG_W-1:0] input_tag=input_lane?in_tag_i[TAG_W+:TAG_W]:in_tag_i[0+:TAG_W];
   wire [R-1:0] input_result=input_lane?in_result_i[R+:R]:in_result_i[0+:R];
   // Empty payload storage has no owner. Prepare its next value while free;
   // only the unchanged fire/valid equations below create a completion.
   wire front_payload_write=!front_q[g]||front_remove;
   wire back_payload_write=!back_q[g]&&front_q[g]&&!front_remove;
   always @(posedge clk_i)begin
     if(rst_i)begin front_q[g]<=0;back_q[g]<=0;end
     else begin
       front_q[g]<=(front_q[g]&&!front_remove)||(front_remove&&back_q[g]&&!back_cancel)||front_input;
       back_q[g]<=(back_q[g]&&!front_remove&&!back_cancel)||back_input;
       // A populated skid excludes input credit for this physical lane.
       // Thus a removed front takes its skid; otherwise a free front can
       // prepare the incoming payload independently of whether it fires.
       if(front_payload_write)begin
         front_tag_q[g]<=back_q[g]?back_tag_q[g]:input_tag;
         front_result_q[g]<=back_q[g]?back_result_q[g]:input_result;
       end
       if(back_payload_write)begin back_tag_q[g]<=input_tag;back_result_q[g]<=input_result;end
     end
   end
`ifdef R64_ASSERT
   always @(posedge clk_i)if(!rst_i&&front_input&&front_shift)$fatal(1,"R64LsuCompletion incompatible writes");
`endif
 end endgenerate
 always @(posedge clk_i)begin
   if(rst_i)turn_q<=0;
   else if(in_fire_i[0])turn_q<=!first_w;
 end
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i)begin
   if((in_fire_i&~in_ready_o)!=0||in_fire_i==2)$fatal(1,"R64LsuCompletion credit/prefix violation");
   if((back_q&~front_q)!=0)$fatal(1,"R64LsuCompletion hole");
 end
`endif
endmodule
