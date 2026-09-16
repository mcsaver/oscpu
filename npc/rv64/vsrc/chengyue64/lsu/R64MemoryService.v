// Shared coherent ingress for LSU and auxiliary physical clients (three page
// walkers and Tensor by default). Auxiliary clients own at most one request;
// CPU tokens identify independent LSQ entries. All effects reach one Dcache.
module R64MemoryService #(
 parameter TOKEN_W=5,parameter AUX=4,parameter SRC_W=3,parameter CPU_REQUEST_HINTS=0
)(
 input clk_i,input rst_i,
 input [1:0] cpu_fast_store_i,output [1:0] cache_fast_store_o,
 input [1:0] cpu_valid_i,input [1:0] cpu_request_i,output reg [1:0] cpu_ready_o,
 input [2*TOKEN_W-1:0] cpu_token_i,input [127:0] cpu_addr_i,cpu_data_i,
 input [3:0] cpu_op_i,input [1:0] cpu_cache_i,input [5:0] cpu_size_i,
 input [15:0] cpu_strb_i,input [9:0] cpu_amo_i,
 output [1:0] cpu_rsp_valid_o,input [1:0] cpu_rsp_ready_i,
 output [2*TOKEN_W-1:0] cpu_rsp_token_o,output [127:0] cpu_rsp_data_o,
 output [1:0] cpu_rsp_error_o,
 input [AUX-1:0] aux_valid_i,output reg [AUX-1:0] aux_ready_o,
 input [AUX*64-1:0] aux_addr_i,aux_data_i,aux_expected_i,
 input [AUX*2-1:0] aux_op_i,input [AUX-1:0] aux_cache_i,
 input [AUX*3-1:0] aux_size_i,input [AUX*8-1:0] aux_strb_i,
 output [AUX-1:0] aux_rsp_valid_o,input [AUX-1:0] aux_rsp_ready_i,
 output [AUX*64-1:0] aux_rsp_data_o,output [AUX-1:0] aux_rsp_error_o,aux_rsp_compare_o,
 output [1:0] cache_valid_o,input [1:0] cache_ready_i,
 output [2*(TOKEN_W+SRC_W)-1:0] cache_token_o,
 output [127:0] cache_addr_o,cache_data_o,cache_expected_o,
 output [3:0] cache_op_o,output [1:0] cache_cache_o,
 output [5:0] cache_size_o,output [15:0] cache_strb_o,output [9:0] cache_amo_o,
 input [1:0] cache_rsp_valid_i,output reg [1:0] cache_rsp_ready_o,
 input [2*(TOKEN_W+SRC_W)-1:0] cache_rsp_token_i,input [127:0] cache_rsp_data_i,
 input [1:0] cache_rsp_error_i,cache_rsp_compare_i,
 output idle_o
);
 localparam CT=TOKEN_W+SRC_W;
 // Each physical lane owns two fixed request slots. Admission observes
 // only Q occupancy; cache completion never grants same-cycle CPU capacity.
 localparam PAYLOAD_W=212+CT;
 reg [1:0] valid_q[0:1],valid_d[0:1];
 reg [1:0] head_q,head_d;
 reg [PAYLOAD_W-1:0] payload_q[0:1][0:1];
 wire [1:0] write_slot_w,available_w,enqueue_w,cache_take_w;
 wire [PAYLOAD_W-1:0] incoming_w[0:1],cpu_payload_w[0:1];
 wire [PAYLOAD_W-1:0] aux_payload_w;
 reg [AUX-1:0] busy_q,out_valid_q,out_error_q,out_compare_q;
 reg [63:0] out_data_q[0:AUX-1];
 reg [SRC_W-1:0] turn_q;

 // CPU is an always-eligible stable round-robin slot. For each auxiliary
 // client, all earlier eligible clients in this turn are tested in parallel.
 // start is a Q-state function; no arriving VALID enters modulo arithmetic.
 wire [SRC_W:0] start_ext_w={1'b0,turn_q} % (AUX+1);
 wire [SRC_W-1:0] start_w=start_ext_w[SRC_W-1:0];
 wire [AUX-1:0] eligible_aux_w,selected_aux_w,pair_aux_w;
 wire selected_cpu_w=!(|selected_aux_w);
 genvar candidate,earlier;
 generate for(candidate=0;candidate<AUX;candidate=candidate+1)begin:gen_choice
  wire [AUX-1:0] preceding_w;
  assign eligible_aux_w[candidate]=aux_valid_i[candidate]&&!busy_q[candidate];
  for(earlier=0;earlier<AUX;earlier=earlier+1)begin:gen_preceding
   if(earlier<candidate)begin:g_before
    assign preceding_w[earlier]=eligible_aux_w[earlier]&&
      start_w!=0&&start_w<=earlier+1;
   end else begin:g_after
    assign preceding_w[earlier]=1'b0;
   end
  end
  wire within_turn_w;
  if(candidate+1 >= (1<<SRC_W)-1)begin:g_full_range
   assign within_turn_w=1'b1;
  end else begin:g_bounded_range
   assign within_turn_w=start_w<=candidate+1;
  end
  assign selected_aux_w[candidate]=eligible_aux_w[candidate]&&start_w!=0&&
    within_turn_w&&!(|preceding_w);
  assign pair_aux_w[candidate]=selected_aux_w[candidate]&&aux_op_i[candidate*2+:2]==0;
 end endgenerate
 // Pair an auxiliary read with a useful CPU load before either request is
 // captured. A retained cache offer is never retargeted. Passing CPU0 is
 // allowed only between ordinary cached reads; special/NC owners keep order.
 wire [AUX-1:0] better_bank_w;
 generate for(genvar ab=0;ab<AUX;ab=ab+1)begin:gen_aux_pair
   // Candidate bank comparisons precede arbitration. Common operation
   // qualification remains outside that reduction, especially on CPU1 ready.
   assign better_bank_w[ab]=aux_cache_i[ab]&&
     cpu_addr_i[3]==aux_addr_i[ab*64+3]&&cpu_addr_i[67]!=aux_addr_i[ab*64+3];
 end endgenerate
 // Hints match both real VALIDs whenever either CPU lane can transfer.
 // When both are blocked, only empty-slot preparation/unused READY may vary;
 // actual enqueue, auxiliary selection and retained owners still use VALID.
 wire [1:0] ready_request_w=CPU_REQUEST_HINTS!=0?cpu_request_i:cpu_valid_i;
 wire pair_cpu1_choice_w=ready_request_w[1]&&
   ((!ready_request_w[0]&&(|pair_aux_w))||
    (cpu_op_i[1:0]==0&&(&cpu_cache_i)&&(|(pair_aux_w&better_bank_w))));
 wire pair_cpu1_w=pair_cpu1_choice_w&&cpu_op_i[3:2]==0;
 integer choice_w,i;
 reg found_w;
 always @*begin
   choice_w=0;found_w=1;
   for(i=0;i<AUX;i=i+1)
     choice_w=choice_w|({32{selected_aux_w[i]}}&(i+1));
   cpu_ready_o=0;aux_ready_o=0;
   if(!rst_i)begin
     aux_ready_o=selected_aux_w&{AUX{available_w[0]}};
     cpu_ready_o[0]=(selected_cpu_w&&available_w[0])||
       ((|pair_aux_w)&&!pair_cpu1_w&&cpu_op_i[1:0]==0&&available_w[1]);
     cpu_ready_o[1]=cpu_op_i[3:2]==0&&(selected_cpu_w||pair_cpu1_choice_w)&&available_w[1];
   end
 end

`ifdef R64_ASSERT
 wire original_pair_choice_w=cpu_valid_i[1]&&
   ((!cpu_valid_i[0]&&(|pair_aux_w))||
    (cpu_op_i[1:0]==0&&(&cpu_cache_i)&&(|(pair_aux_w&better_bank_w))));
 wire original_pair_w=original_pair_choice_w&&cpu_op_i[3:2]==0;
 wire [1:0] original_cpu_ready_w={
   cpu_op_i[3:2]==0&&(selected_cpu_w||original_pair_choice_w)&&available_w[1],
   (selected_cpu_w&&available_w[0])||
     ((|pair_aux_w)&&!original_pair_w&&cpu_op_i[1:0]==0&&available_w[1])}&{2{!rst_i}};
 always @(posedge clk_i)if(!rst_i)begin
   if(CPU_REQUEST_HINTS!=0&&(|cpu_valid_i)&&cpu_request_i!==cpu_valid_i)
     $fatal(1,"R64MemoryService request hint differs with live CPU input");
   if((cpu_valid_i&cpu_ready_o)!==(cpu_valid_i&original_cpu_ready_w))
     $fatal(1,"R64MemoryService request hint changed CPU acceptance");
   if(enqueue_w[1]&&incoming_w[1]!==((aux_select_w&&!original_pair_w)?cpu_payload_w[0]:cpu_payload_w[1]))
     $fatal(1,"R64MemoryService request hint changed accepted payload");
 end
`endif
 wire [1:0] cpu_take_w=cpu_valid_i&cpu_ready_o;
 wire [AUX-1:0] aux_take_w=aux_valid_i&aux_ready_o;
 wire aux_select_w=found_w&&choice_w!=0;


 assign aux_rsp_valid_o=out_valid_q&{AUX{!rst_i}};
 assign aux_rsp_error_o=out_error_q;assign aux_rsp_compare_o=out_compare_q;
 assign idle_o=valid_q[0]==0&&valid_q[1]==0&&busy_q==0&&out_valid_q==0;
 genvar g;
 generate for(g=0;g<2;g=g+1)begin:gen_lane
   wire [SRC_W-1:0] source_w=cache_rsp_token_i[g*CT+TOKEN_W+:SRC_W];
   assign available_w[g]=!(&valid_q[g]);
   assign write_slot_w[g]=valid_q[g][0];
   assign cache_valid_o[g]=valid_q[g][head_q[g]]&&!rst_i;
   assign cache_take_w[g]=cache_valid_o[g]&&cache_ready_i[g];
   assign {cache_token_o[g*CT+:CT],cache_addr_o[g*64+:64],
     cache_data_o[g*64+:64],cache_expected_o[g*64+:64],
     cache_op_o[g*2+:2],cache_cache_o[g],cache_size_o[g*3+:3],
     cache_strb_o[g*8+:8],cache_amo_o[g*5+:5],cache_fast_store_o[g]}
       =payload_q[g][head_q[g]];
   assign cpu_payload_w[g]={{SRC_W{1'b0}},cpu_token_i[g*TOKEN_W+:TOKEN_W],
     cpu_addr_i[g*64+:64],cpu_data_i[g*64+:64],64'b0,cpu_op_i[g*2+:2],
     cpu_cache_i[g],cpu_size_i[g*3+:3],cpu_strb_i[g*8+:8],
     cpu_amo_i[g*5+:5],cpu_fast_store_i[g]};
   assign cpu_rsp_valid_o[g]=cache_rsp_valid_i[g]&&source_w==0;
   assign cpu_rsp_token_o[g*TOKEN_W+:TOKEN_W]=cache_rsp_token_i[g*CT+:TOKEN_W];
   assign cpu_rsp_data_o[g*64+:64]=cache_rsp_data_i[g*64+:64];
 end
 for(g=0;g<AUX;g=g+1)begin:gen_aux
   assign aux_rsp_data_o[g*64+:64]=out_data_q[g];
 end endgenerate
 assign cpu_rsp_error_o=cache_rsp_error_i;
 integer b,s;
 always @*begin
   cache_rsp_ready_o=0;
   for(b=0;b<2;b=b+1)begin
     s={{(32-SRC_W){1'b0}},cache_rsp_token_i[b*CT+TOKEN_W+:SRC_W]};
     if(s==0)cache_rsp_ready_o[b]=cpu_rsp_ready_i[b];
     else if(s<=AUX)cache_rsp_ready_o[b]=!out_valid_q[s-1]||aux_rsp_ready_i[s-1];
   end
 end
 integer l,a;
 wire [1:0] destination_w={1'b1,aux_select_w};
 function [CT-1:0] aux_token;
 input [SRC_W-1:0] number;
 begin aux_token={number[SRC_W-1:0],{TOKEN_W{1'b0}}};end
 endfunction
 assign aux_payload_w={aux_token(choice_w[SRC_W-1:0]),
   aux_addr_i[(choice_w-1)*64+:64],aux_data_i[(choice_w-1)*64+:64],
   aux_expected_i[(choice_w-1)*64+:64],aux_op_i[(choice_w-1)*2+:2],
   aux_cache_i[choice_w-1],aux_size_i[(choice_w-1)*3+:3],
   aux_strb_i[(choice_w-1)*8+:8],5'b0,1'b0};
 assign incoming_w[0]=aux_select_w?aux_payload_w:cpu_payload_w[0];
 assign incoming_w[1]=(aux_select_w&&!pair_cpu1_w)?cpu_payload_w[0]:cpu_payload_w[1];
 assign enqueue_w[0]=(|aux_take_w)||(cpu_take_w[0]&&!aux_select_w);
 assign enqueue_w[1]=cpu_take_w[1]||(cpu_take_w[0]&&aux_select_w);
 integer lane;
 always @*begin
  head_d=head_q;
  for(lane=0;lane<2;lane=lane+1)begin
   valid_d[lane]=valid_q[lane];
   if(cache_take_w[lane])valid_d[lane][head_q[lane]]=0;
   if(enqueue_w[lane])valid_d[lane][write_slot_w[lane]]=1;
   if(valid_q[lane]==0)head_d[lane]=0;
   else if(cache_take_w[lane])head_d[lane]=!head_q[lane];
  end
 end
 genvar storage_lane,storage_slot;
 generate for(storage_lane=0;storage_lane<2;storage_lane=storage_lane+1)begin:gen_payload_lane
  for(storage_slot=0;storage_slot<2;storage_slot=storage_slot+1)begin:gen_payload_slot
   // Inactive-slot prewrite cannot mutate a retained or accepted owner.
   always @(posedge clk_i)if(!rst_i&&!valid_q[storage_lane][storage_slot]&&
       write_slot_w[storage_lane]==storage_slot)
     payload_q[storage_lane][storage_slot]<=incoming_w[storage_lane];
  end
 end endgenerate
 always @(posedge clk_i)begin
   if(rst_i)begin valid_q[0]<=0;valid_q[1]<=0;head_q<=0;busy_q<=0;out_valid_q<=0;out_error_q<=0;out_compare_q<=0;turn_q<=0;end
   else begin
     valid_q[0]<=valid_d[0];valid_q[1]<=valid_d[1];head_q<=head_d;
     for(a=0;a<AUX;a=a+1)begin
       if(out_valid_q[a]&&aux_rsp_ready_i[a])begin out_valid_q[a]<=0;busy_q[a]<=0;end
       if(aux_take_w[a])busy_q[a]<=1;
       for(l=0;l<2;l=l+1)if(cache_rsp_valid_i[l]&&cache_rsp_ready_o[l]&&
         {{(32-SRC_W){1'b0}},cache_rsp_token_i[l*CT+TOKEN_W+:SRC_W]}==a+1)begin
         out_valid_q[a]<=1;out_data_q[a]<=cache_rsp_data_i[l*64+:64];
         out_error_q[a]<=cache_rsp_error_i[l];out_compare_q[a]<=cache_rsp_compare_i[l];
       end
     end
     if((|aux_take_w)||(|cpu_take_w))turn_q<=choice_w==AUX?{SRC_W{1'b0}}:choice_w[SRC_W-1:0]+1'b1;
     else if(!aux_select_w&&!cpu_valid_i[0])turn_q<={{(SRC_W-1){1'b0}},1'b1};
   end
 end
`ifdef R64_ASSERT
 integer cq;
 always @(posedge clk_i)if(!rst_i)begin
  if((enqueue_w&~available_w)!=0)$fatal(1,"Service request overbooked Q credit");
  for(cq=0;cq<2;cq=cq+1)begin
   if((|valid_q[cq])&&!valid_q[cq][head_q[cq]])
     $fatal(1,"Service head lost oldest request owner");
   if(enqueue_w[cq]&&valid_q[cq][write_slot_w[cq]])
     $fatal(1,"Service request replaced an occupied payload");
  end
 end

 generate if(AUX < (1<<SRC_W)-1)begin:g_owner_range
 integer v;
 always @(posedge clk_i)if(!rst_i)begin
   for(v=0;v<2;v=v+1)if(cache_rsp_valid_i[v]&&cache_rsp_ready_o[v]&&
     cache_rsp_token_i[v*CT+TOKEN_W+:SRC_W]>AUX)$fatal(1,"R64MemoryService invalid response owner");
 end
 end endgenerate
`endif
endmodule
