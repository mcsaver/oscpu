// Variable-latency arithmetic owns an allocated slot until its exact
// completion arrives. Two producers may finish together; retirement through
// this local queue is one per cycle. Canceled slots become tombstones, but
// are never reused before the producing pipeline has finished that token.
module R64FpCompletion #(
 parameter SLOT_W=4,CAPACITY=14,DATA_W=69,TAG_W=9,ROB_W=5
)(
 input clk,rst,flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input in_valid_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
 output [SLOT_W-1:0] allocation_o,
 input [1:0] complete_valid_i,input [2*SLOT_W-1:0] complete_slot_i,
 input [2*DATA_W-1:0] complete_data_i,
 output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,
 output [DATA_W-1:0] out_data_o
);
 localparam GROUP_BITS=ROB_W>=3?8:(1<<ROB_W),GROUPS=(1<<ROB_W)/GROUP_BITS;
 reg [CAPACITY:0] reserved_q;
 reg [CAPACITY-1:0] allocated_q,done_q;
 reg empty_q,credit_q,credit_return_q;
 // Admission cancellation has its own one-bit register. Allocated slots
 // cannot complete in their birth cycle, so this correction reaches both
 // the resident owner and the front cache before any result becomes valid.
 reg birth_pending_q,birth_killed_q;
 reg [SLOT_W-1:0] birth_slot_q;
 reg [SLOT_W-1:0] head_q,tail_q,next_head_q;
 reg [1:0] front_select_q;
 reg [TAG_W-1:0] tag_q[0:CAPACITY-1];
 reg [DATA_W-1:0] data_q[0:CAPACITY-1];
 reg [(1<<ROB_W)-1:0] owner_q[0:CAPACITY-1];
 reg [GROUPS-1:0] dead_q[0:CAPACITY-1];
 reg [TAG_W-1:0] front_tag_q[0:1];
 reg [DATA_W-1:0] front_data_q[0:1];
 reg [GROUPS-1:0] front_dead_q[0:1];
 reg [1:0] front_done_q;
 wire head_done_w=|(front_select_q&front_done_q);
 wire head_dead_w=(front_select_q[0]&&(|front_dead_q[0]))||
  (front_select_q[1]&&(|front_dead_q[1]));
 wire pop_w=!empty_q&&head_done_w&&(head_dead_w||out_ready_i);
 wire accept_w=in_valid_i&&credit_q;
 wire [(1<<ROB_W)-1:0] incoming_owner_w={{((1<<ROB_W)-1){1'b0}},1'b1}<<in_tag_i[ROB_W-1:0];
 assign in_ready_o=credit_q;
 assign allocation_o=tail_q;
 assign out_valid_o=!empty_q&&head_done_w&&!head_dead_w;
 assign out_tag_o=({TAG_W{front_select_q[0]}}&front_tag_q[0])|({TAG_W{front_select_q[1]}}&front_tag_q[1]);
 assign out_data_o=({DATA_W{front_select_q[0]}}&front_data_q[0])|({DATA_W{front_select_q[1]}}&front_data_q[1]);
 always @(posedge clk)begin
  if(rst||flush_i)begin
   reserved_q<=1;allocated_q<=0;done_q<=0;empty_q<=1;credit_q<=1;credit_return_q<=0;
   head_q<=0;tail_q<=0;next_head_q<=1;front_select_q<=2'b01;birth_pending_q<=0;
  end else begin
   credit_return_q<=pop_w;
   birth_pending_q<=accept_w;
   if(accept_w)begin birth_slot_q<=tail_q;birth_killed_q<=kill_mask_i[in_tag_i[ROB_W-1:0]];end
   reserved_q<=credit_return_q?(accept_w?reserved_q:{1'b0,reserved_q[CAPACITY:1]}):
    (accept_w?{reserved_q[CAPACITY-1:0],1'b0}:reserved_q);
   credit_q<=credit_return_q?(accept_w?!reserved_q[CAPACITY]:1'b1):
    (accept_w?!reserved_q[CAPACITY-1]:!reserved_q[CAPACITY]);
   if(accept_w)begin
    allocated_q[tail_q]<=1;done_q[tail_q]<=0;
    tail_q<=tail_q==SLOT_W'(CAPACITY-1)?{SLOT_W{1'b0}}:tail_q+1'b1;
    empty_q<=0;
   end else if(pop_w)empty_q<=next_head_q==tail_q;
   if(pop_w)begin
    allocated_q[head_q]<=0;done_q[head_q]<=0;
    head_q<=next_head_q;
    next_head_q<=next_head_q==SLOT_W'(CAPACITY-1)?{SLOT_W{1'b0}}:next_head_q+1'b1;
    front_select_q<={front_select_q[0],front_select_q[1]};
   end
   if(complete_valid_i[0])done_q[complete_slot_i[0+:SLOT_W]]<=1;
   if(complete_valid_i[1])done_q[complete_slot_i[SLOT_W+:SLOT_W]]<=1;
  end
 end
 genvar entry,group;
 generate for(entry=0;entry<CAPACITY;entry=entry+1)begin:slot
  wire birth_w=accept_w&&tail_q==entry;
  wire complete0_w=complete_valid_i[0]&&complete_slot_i[0+:SLOT_W]==entry;
  wire complete1_w=complete_valid_i[1]&&complete_slot_i[SLOT_W+:SLOT_W]==entry;
  always @(posedge clk)begin
   if(birth_w)begin tag_q[entry]<=in_tag_i;owner_q[entry]<=incoming_owner_w;end
   if(complete0_w)data_q[entry]<=complete_data_i[0+:DATA_W];
   else if(complete1_w)data_q[entry]<=complete_data_i[DATA_W+:DATA_W];
  end
  for(group=0;group<GROUPS;group=group+1)begin:cancel
   always @(posedge clk)dead_q[entry][group]<=!birth_w&&(
    dead_q[entry][group]||(|(owner_q[entry][group*GROUP_BITS+:GROUP_BITS]&kill_mask_i[group*GROUP_BITS+:GROUP_BITS]))||
    (group==0&&birth_pending_q&&birth_slot_q==entry&&birth_killed_q));
  end
 end endgenerate
 genvar bank,part;
 generate for(bank=0;bank<2;bank=bank+1)begin:front
  wire [SLOT_W-1:0] index_w=head_q[0]==bank?head_q:next_head_q;
  wire birth_w=accept_w&&tail_q==index_w;
  wire complete0_w=complete_valid_i[0]&&complete_slot_i[0+:SLOT_W]==index_w;
  wire complete1_w=complete_valid_i[1]&&complete_slot_i[SLOT_W+:SLOT_W]==index_w;
  always @(posedge clk)begin
   front_tag_q[bank]<=birth_w?in_tag_i:tag_q[index_w];
   front_done_q[bank]<=!birth_w&&(done_q[index_w]||complete0_w||complete1_w);
   front_data_q[bank]<=complete0_w?complete_data_i[0+:DATA_W]:
    complete1_w?complete_data_i[DATA_W+:DATA_W]:data_q[index_w];
  end
  for(part=0;part<GROUPS;part=part+1)begin:cancel
   always @(posedge clk)front_dead_q[bank][part]<=!birth_w&&(
    dead_q[index_w][part]||(|(owner_q[index_w][part*GROUP_BITS+:GROUP_BITS]&kill_mask_i[part*GROUP_BITS+:GROUP_BITS]))||
    (part==0&&birth_pending_q&&birth_slot_q==index_w&&birth_killed_q));
  end
 end endgenerate
`ifdef R64_ASSERT
 integer live_count,reserved_count,k;
 always @(*)begin
  live_count=0;reserved_count=0;
  for(k=0;k<CAPACITY;k=k+1)live_count=live_count+{31'b0,allocated_q[k]};
  for(k=0;k<=CAPACITY;k=k+1)if(reserved_q[k])reserved_count=k;
 end
 always @(posedge clk)if(!rst&&!flush_i)begin
  if((CAPACITY%2)!=0||CAPACITY>(1<<SLOT_W))$fatal(1,"FP completion invalid ring capacity");
  if(!$onehot(reserved_q)||reserved_count!=live_count+{31'b0,credit_return_q})
   $fatal(1,"FP completion reservation conservation");
  if(accept_w&&allocated_q[tail_q])$fatal(1,"FP completion reuses unfinished producer slot");
  if(pop_w&&!allocated_q[head_q])$fatal(1,"FP completion pops anonymous owner");
  if(complete_valid_i==2'b11&&complete_slot_i[0+:SLOT_W]==complete_slot_i[SLOT_W+:SLOT_W])
   $fatal(1,"FP completion duplicate producer slot");
  for(k=0;k<2;k=k+1)if(complete_valid_i[k])begin
   if(!allocated_q[complete_slot_i[k*SLOT_W+:SLOT_W]]||done_q[complete_slot_i[k*SLOT_W+:SLOT_W]])
    $fatal(1,"FP completion missing or repeated producer owner");
  end
  if(out_valid_o&&(out_tag_o!==tag_q[head_q]||out_data_o!==data_q[head_q]))
   $fatal(1,"FP completion prefetched output differs from head");
 end
`endif
endmodule
