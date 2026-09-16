// Six fixed-advance numerical stages. Admission reserves one of eight
// terminal slots, so WB backpressure never crosses the numerical pipeline.
// Canceled tokens retain their slot until a tombstone reaches the terminal.
module R64Multiply #(parameter TAG_W=9,parameter ROB_W=5,parameter PREQUALIFIED_INPUT=0)(
 input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input in_valid_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
 input [63:0] a_i,b_i,input [2:0] function_i,input word_i,
 output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,output [63:0] out_data_o
);
 localparam STAGES=6,SLOTS=8;
 localparam CANCEL_BITS=ROB_W>=3?8:(1<<ROB_W),CANCEL_GROUPS=(1<<ROB_W)/CANCEL_BITS;
 reg [STAGES-1:0] token_q,dead_q,high_q,word_q;
 reg [(1<<ROB_W)-1:0] final_owner_q;
 reg [TAG_W-1:0] tag_q[0:STAGES-1];
 reg [SLOTS:0] reserved_hot_q,count_hot_q;
 wire [SLOTS:0] reserved_add_w={reserved_hot_q[SLOTS-1:0],1'b0};
 wire [SLOTS:0] reserved_sub_w={1'b0,reserved_hot_q[SLOTS:1]};
 wire [SLOTS:0] count_add_w={count_hot_q[SLOTS-1:0],1'b0};
 wire [SLOTS:0] count_sub_w={1'b0,count_hot_q[SLOTS:1]};
 reg [2:0] head_q,tail_q;
 reg credit_q;
 reg [1:0] front_select_q;
 wire front_dead_bank_q[0:1];
 reg [CANCEL_GROUPS-1:0] front_dead_parts_q[0:1];
 reg [TAG_W-1:0] front_tag_bank_q[0:1];
 reg [63:0] front_data_bank_q[0:1];
 reg [(1<<ROB_W)-1:0] front_owner_bank_q[0:1],terminal_owner_q[0:SLOTS-1];
 wire front_dead_q=(front_select_q[0]&&front_dead_bank_q[0])||(front_select_q[1]&&front_dead_bank_q[1]);
 wire [TAG_W-1:0] front_tag_q=({TAG_W{front_select_q[0]}}&front_tag_bank_q[0])|({TAG_W{front_select_q[1]}}&front_tag_bank_q[1]);
 wire [63:0] front_data_q=({64{front_select_q[0]}}&front_data_bank_q[0])|({64{front_select_q[1]}}&front_data_bank_q[1]);
 wire [2:0] next_head_w=head_q+1'b1;
 reg [TAG_W-1:0] terminal_tag_q[0:SLOTS-1];
 reg [63:0] terminal_data_q[0:SLOTS-1];
 wire [SLOTS-1:0] terminal_dead_q;
 reg [CANCEL_GROUPS-1:0] terminal_dead_parts_q[0:SLOTS-1];
 genvar reduce_owner;
 generate for(reduce_owner=0;reduce_owner<SLOTS;reduce_owner=reduce_owner+1)begin:dead_reduce
  assign terminal_dead_q[reduce_owner]=|terminal_dead_parts_q[reduce_owner];
 end
 for(reduce_owner=0;reduce_owner<2;reduce_owner=reduce_owner+1)begin:front_dead_reduce
  assign front_dead_bank_q[reduce_owner]=|front_dead_parts_q[reduce_owner];
 end endgenerate
 // A same-cycle kill is rejected by the WB consumer before capture. Here
 // cancellation is recorded at the edge; it never combinationally advances
 // the result queue or returns admission capacity.
 wire head_dead_w=front_dead_q;
 wire pop_w=!count_hot_q[0]&&(head_dead_w||out_ready_i);
 wire push_w=token_q[STAGES-1];
 wire accept_w=in_valid_i&&in_ready_o;
 assign in_ready_o=credit_q;
 assign out_valid_o=!count_hot_q[0]&&!head_dead_w;
 assign out_tag_o=front_tag_q;
 assign out_data_o=front_data_q;
 // Radix-4 Booth recoding is registered with input capture. Thirty-two
 // signed digits cover B[63:0]; unsigned-B's top correction shares one row
 // with all +1 negation bits. A's sign extension handles MULH/MULHSU directly.
 reg [65:0] a0_q;
 reg [31:0] one0_q,two0_q,negative0_q;
 reg unsigned_top0_q;
 reg [127:0] correction1_q;
 wire [64:0] booth_input_w={b_i,1'b0};
 wire [63:0] correction_low_w;
 wire [127:0] initial_rows_w[0:33];
 genvar tile,s,j;
 generate for(tile=0;tile<32;tile=tile+1)begin:booth
  wire [2:0] code_w=booth_input_w[2*tile+:3];
  wire [65:0] magnitude_w=({66{one0_q[tile]}}&a0_q)|
   ({66{two0_q[tile]}}&{a0_q[64:0],1'b0});
  reg [65:0] row_q;
  always @(posedge clk)begin
   one0_q[tile]<=code_w[0]^code_w[1];
   two0_q[tile]<=(code_w==3'b011)||(code_w==3'b100);
   negative0_q[tile]<=code_w[2];
   row_q<=magnitude_w^{66{negative0_q[tile]}};
  end
  // Guard encoding equals signed(row) + 2^66. A single constant
  // correction cancels these offsets without broadcasting each row sign.
  assign initial_rows_w[tile]={61'b0,~row_q[65],row_q}<<(2*tile);
  assign correction_low_w[2*tile]=negative0_q[tile];
  assign correction_low_w[2*tile+1]=1'b0;
 end endgenerate
 assign initial_rows_w[32]=correction1_q;
 localparam [127:0] SIGN_OFFSETS=128'h5555555555555555<<66;
 assign initial_rows_w[33]=~SIGN_OFFSETS+128'd1;
 function integer rows_after;
  input integer n,levels;integer k;
  begin for(k=0;k<levels;k=k+1)n=2*(n/3)+(n%3);rows_after=n;end
 endfunction
 generate for(s=0;s<=4;s=s+1)begin:first_compress
  localparam N=rows_after(34,s);
  wire [127:0] row_w[0:N-1];
  if(s==0)begin
   for(j=0;j<N;j=j+1)begin:source assign row_w[j]=initial_rows_w[j];end
  end else begin
   localparam PREV=rows_after(34,s-1),GROUPS=PREV/3;
   for(j=0;j<GROUPS;j=j+1)begin:triple
    wire [127:0] a=first_compress[s-1].row_w[3*j];
    wire [127:0] b=first_compress[s-1].row_w[3*j+1];
    wire [127:0] c=first_compress[s-1].row_w[3*j+2];
    assign row_w[2*j]=a^b^c;
    assign row_w[2*j+1]=((a&b)|(a&c)|(b&c))<<1;
   end
   for(j=0;j<PREV%3;j=j+1)begin:remainder_rows
    assign row_w[2*GROUPS+j]=first_compress[s-1].row_w[3*GROUPS+j];
   end
  end
 end endgenerate
 reg [127:0] middle2_q[0:7];
 generate for(j=0;j<8;j=j+1)begin:middle
  always @(posedge clk)middle2_q[j]<=first_compress[4].row_w[j];
 end endgenerate
 generate for(s=0;s<=4;s=s+1)begin:second_compress
  localparam N=rows_after(8,s);
  wire [127:0] row_w[0:N-1];
  if(s==0)begin
   for(j=0;j<N;j=j+1)begin:source assign row_w[j]=middle2_q[j];end
  end else begin
   localparam PREV=rows_after(8,s-1),GROUPS=PREV/3;
   for(j=0;j<GROUPS;j=j+1)begin:triple
    wire [127:0] a=second_compress[s-1].row_w[3*j];
    wire [127:0] b=second_compress[s-1].row_w[3*j+1];
    wire [127:0] c=second_compress[s-1].row_w[3*j+2];
    assign row_w[2*j]=a^b^c;
    assign row_w[2*j+1]=((a&b)|(a&c)|(b&c))<<1;
   end
   for(j=0;j<PREV%3;j=j+1)begin:remainder_rows
    assign row_w[2*GROUPS+j]=second_compress[s-1].row_w[3*GROUPS+j];
   end
  end
 end endgenerate
 reg [127:0] sum3_q,carry3_q,base4_q;
 reg [31:0] propagate4_q,generate4_q;
 wire [127:0] base_w,product_w;
 wire [31:0] propagate_w,generate_w;
 reg [63:0] result5_q;
 R64CarryPrepare #(.BLOCK(4)) prepare(.a_i(sum3_q),.b_i(carry3_q),.base_o(base_w),
  .propagate_o(propagate_w),.generate_o(generate_w));
 R64CarryFinish #(.BLOCK(4)) finish(.base_i(base4_q),.propagate_i(propagate4_q),
  .generate_i(generate4_q),.carry_i(1'b0),.sum_o(product_w),.carry_o());
 wire [63:0] packed_w=word_q[STAGES-1] ? {{32{result5_q[31]}},result5_q[31:0]}:result5_q;
 wire [63:0] selected_w=high_q[4] ? product_w[127:64]:product_w[63:0];
 always @(posedge clk)begin
  a0_q<={{2{(function_i==1||function_i==2)&&a_i[63]}},a_i};
  unsigned_top0_q<=function_i!=1&&b_i[63];
  correction1_q<={unsigned_top0_q?a0_q[63:0]:64'b0,correction_low_w};
  sum3_q<=second_compress[4].row_w[0];carry3_q<=second_compress[4].row_w[1];
  base4_q<=base_w;propagate4_q<=propagate_w;generate4_q<=generate_w;
  result5_q<=selected_w;
 end
 integer k;
 always @(posedge clk)begin
  if(rst||flush_i)begin
   token_q<=0;reserved_hot_q<=1;count_hot_q<=1;head_q<=0;tail_q<=0;credit_q<=0;front_select_q<=2'b01;
  end else begin
   credit_q<=!reserved_hot_q[SLOTS];
   token_q<={token_q[STAGES-2:0],accept_w};
   final_owner_q<={{((1<<ROB_W)-1){1'b0}},1'b1}<<tag_q[STAGES-2][ROB_W-1:0];

   tag_q[0]<=in_tag_i;high_q[0]<=function_i!=0;word_q[0]<=word_i;
   for(k=1;k<STAGES;k=k+1)begin
    tag_q[k]<=tag_q[k-1];high_q[k]<=high_q[k-1];word_q[k]<=word_q[k-1];

   end

   // Occupancy is one-hot: late downstream READY selects already shifted
   // Q states and never traverses an increment/decrement carry chain.
   reserved_hot_q<=pop_w?(accept_w?reserved_hot_q:reserved_sub_w):
    (accept_w?reserved_add_w:reserved_hot_q);
   count_hot_q<=pop_w?(push_w?count_hot_q:count_sub_w):
    (push_w?count_add_w:count_hot_q);
   credit_q<=pop_w ? (accept_w?!reserved_hot_q[SLOTS]:1'b1):
    (accept_w?!reserved_hot_q[SLOTS-1]:!reserved_hot_q[SLOTS]);
   if(push_w)begin
    terminal_tag_q[tail_q]<=tag_q[STAGES-1];terminal_data_q[tail_q]<=packed_w;

    tail_q<=tail_q+1'b1;
    terminal_owner_q[tail_q]<=final_owner_q;
   end

   if(pop_w)begin head_q<=next_head_w;front_select_q<={front_select_q[0],front_select_q[1]};end
  end
 end

 // Cancel metadata is meaningful only beneath a live token/terminal entry.
 // Clearing the owner on reset/flush is sufficient; resetting these shadow
 // bits would put a global reset mux after every timing-critical kill match.
 integer cancel_stage;
 always @(posedge clk)begin
  dead_q[0]<=PREQUALIFIED_INPUT ? 1'b0 : kill_mask_i[in_tag_i[ROB_W-1:0]];
  for(cancel_stage=1;cancel_stage<STAGES;cancel_stage=cancel_stage+1)
   dead_q[cancel_stage]<=dead_q[cancel_stage-1]||kill_mask_i[tag_q[cancel_stage-1][ROB_W-1:0]];
 end

 // Partition cancellation into independent sticky groups. The late kill
 // input sees only eight owners; the OR of registered groups remains on
 // the earlier Q-owned pop path. Observable cancellation timing is unchanged.
 genvar cancel_entry,cancel_group;
 generate for(cancel_entry=0;cancel_entry<SLOTS;cancel_entry=cancel_entry+1)begin:entry_dead
  wire replace_w=push_w&&tail_q==cancel_entry;
  wire [(1<<ROB_W)-1:0] selected_owner_w=replace_w?final_owner_q:terminal_owner_q[cancel_entry];
  for(cancel_group=0;cancel_group<CANCEL_GROUPS;cancel_group=cancel_group+1)begin:part
   wire old_dead_w=replace_w?dead_q[STAGES-1]:terminal_dead_parts_q[cancel_entry][cancel_group];
   always @(posedge clk)terminal_dead_parts_q[cancel_entry][cancel_group]<=old_dead_w||
    (|(kill_mask_i[cancel_group*CANCEL_BITS+:CANCEL_BITS]&selected_owner_w[cancel_group*CANCEL_BITS+:CANCEL_BITS]));
  end
 end endgenerate

 // The unused front bank prefetches the next head independently of READY.
 // Pop changes ownership through the pointer bit, never a wide data-select.
 wire [TAG_W-1:0] next_tag_w=!(count_hot_q[0]||count_hot_q[1])?terminal_tag_q[next_head_w]:tag_q[STAGES-1];
 wire [63:0] next_data_w=!(count_hot_q[0]||count_hot_q[1])?terminal_data_q[next_head_w]:packed_w;
 wire [(1<<ROB_W)-1:0] next_owner_w=!(count_hot_q[0]||count_hot_q[1])?terminal_owner_q[next_head_w]:final_owner_q;
 integer bank;
 always @(posedge clk)begin
  for(bank=0;bank<2;bank=bank+1)begin
   if(head_q[0]!=bank[0])begin
    front_tag_bank_q[bank]<=next_tag_w;front_data_bank_q[bank]<=next_data_w;
    front_owner_bank_q[bank]<=next_owner_w;
   end else if(count_hot_q[0]&&push_w)begin
    front_tag_bank_q[bank]<=tag_q[STAGES-1];front_data_bank_q[bank]<=packed_w;
    front_owner_bank_q[bank]<=final_owner_q;
   end
  end
 end
 genvar front_bank,front_group;
 generate for(front_bank=0;front_bank<2;front_bank=front_bank+1)begin:front_cancel
  wire refill_w=head_q[0]!=front_bank;
  wire first_w=count_hot_q[0]&&push_w;
  wire [(1<<ROB_W)-1:0] selected_owner_w=refill_w?next_owner_w:
   first_w?final_owner_q:front_owner_bank_q[front_bank];
  for(front_group=0;front_group<CANCEL_GROUPS;front_group=front_group+1)begin:part
   wire next_old_w=!(count_hot_q[0]||count_hot_q[1])?terminal_dead_parts_q[next_head_w][front_group]:dead_q[STAGES-1];
   wire old_dead_w=refill_w?next_old_w:first_w?dead_q[STAGES-1]:front_dead_parts_q[front_bank][front_group];
   always @(posedge clk)front_dead_parts_q[front_bank][front_group]<=old_dead_w||
    (|(kill_mask_i[front_group*CANCEL_BITS+:CANCEL_BITS]&selected_owner_w[front_group*CANCEL_BITS+:CANCEL_BITS]));
  end
 end endgenerate
`ifdef R64_ASSERT
 // This mode is a boundary contract, not permission to ignore cancellation.
 // The upstream producer must have rejected current kill/reset/flush before
 // emitting the actual admission pulse. Later owner kills remain local.
 always @(posedge clk)begin
  if(PREQUALIFIED_INPUT&&in_valid_i&&in_ready_o&&
     (rst||flush_i||kill_mask_i[in_tag_i[ROB_W-1:0]]))
   $fatal(1,"numeric prequalified input accepted cancelled owner");
 end

 reg [3:0] reserved_q,count_q;
 integer decode_count;
 always @(*)begin
  reserved_q=0;count_q=0;
  for(decode_count=0;decode_count<=SLOTS;decode_count=decode_count+1)begin
   if(reserved_hot_q[decode_count])reserved_q=decode_count[3:0];
   if(count_hot_q[decode_count])count_q=decode_count[3:0];
  end
 end
 always @(posedge clk)if(!rst&&!flush_i)begin
  if(!count_hot_q[0]&&(front_tag_q!==terminal_tag_q[head_q]||front_data_q!==terminal_data_q[head_q]))
   $fatal(1,"R64 MUL head cache differs from terminal owner");
  if({28'b0,reserved_q}!={28'b0,count_q}+{31'b0,token_q[0]}+{31'b0,token_q[1]}+
   {31'b0,token_q[2]}+{31'b0,token_q[3]}+{31'b0,token_q[4]}+{31'b0,token_q[5]})
   $fatal(1,"R64 MUL in-flight plus terminal credit conservation");
  if(!$onehot(reserved_hot_q)||!$onehot(count_hot_q))$fatal(1,"R64 MUL occupancy lost one-hot owner");
  if(reserved_q>SLOTS||count_q>reserved_q)$fatal(1,"R64 MUL reservation conservation");
  if(push_w&&count_hot_q[SLOTS]&&!pop_w)$fatal(1,"R64 MUL terminal overflow");
  if(out_valid_o&&head_dead_w)$fatal(1,"R64 MUL canceled terminal escaped");
 end
`endif
endmodule
