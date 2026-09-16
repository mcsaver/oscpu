// One owner for a fixed-advance numerical pipe plus bounded terminal storage.
// Admission reserves capacity before work starts. Kill creates sticky tombstones;
// a consumer must reject same-cycle kill/flush before copying an output owner.
module R64NumericOwner #(
 parameter STAGES=11,SLOT_W=4,CAPACITY=(1<<SLOT_W),DATA_W=69,TAG_W=9,ROB_W=5
)(
 input clk,rst,flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input in_valid_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
 output [STAGES-1:0] stage_live_o,input [DATA_W-1:0] result_i,
 output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,
 output [DATA_W-1:0] out_data_o
);
 localparam SLOTS=CAPACITY;
 localparam CANCEL_BITS=ROB_W>=3?8:(1<<ROB_W),CANCEL_GROUPS=(1<<ROB_W)/CANCEL_BITS;
 reg [STAGES-1:0] token_q,dead_q;
 reg [TAG_W-1:0] tag_q[0:STAGES-1];
 reg [(1<<ROB_W)-1:0] final_owner_q;
 reg [SLOTS:0] reserved_hot_q;
 reg empty_q,credit_return_q;
 wire [SLOTS:0] reserved_add_w={reserved_hot_q[SLOTS-1:0],1'b0};
 wire [SLOTS:0] reserved_sub_w={1'b0,reserved_hot_q[SLOTS:1]};
 reg [SLOT_W-1:0] head_q,tail_q,next_head_q;
 reg [1:0] front_select_q;
 reg credit_q;
 reg [TAG_W-1:0] terminal_tag_q[0:SLOTS-1],front_tag_q[0:1];
 reg [DATA_W-1:0] terminal_data_q[0:SLOTS-1],front_data_q[0:1];
 reg [(1<<ROB_W)-1:0] terminal_owner_q[0:SLOTS-1],front_owner_q[0:1];
 wire [SLOTS-1:0] terminal_dead_q;
 wire front_dead_q[0:1];
 reg [CANCEL_GROUPS-1:0] terminal_dead_parts_q[0:SLOTS-1],front_dead_parts_q[0:1];
 wire head_dead_w=(front_select_q[0]&&front_dead_q[0])||(front_select_q[1]&&front_dead_q[1]);
 wire [SLOT_W-1:0] next_head_w=next_head_q;
 wire push_w=token_q[STAGES-1];
 wire pop_w=!empty_q&&(head_dead_w||out_ready_i);
 wire accept_w=in_valid_i&&credit_q;
 assign stage_live_o=token_q&~dead_q;
 assign in_ready_o=credit_q;
 assign out_valid_o=!empty_q&&!head_dead_w;
 assign out_tag_o=({TAG_W{front_select_q[0]}}&front_tag_q[0])|({TAG_W{front_select_q[1]}}&front_tag_q[1]);
 assign out_data_o=({DATA_W{front_select_q[0]}}&front_data_q[0])|({DATA_W{front_select_q[1]}}&front_data_q[1]);
 genvar entry;
 generate for(entry=0;entry<SLOTS;entry=entry+1)begin:dead_reduce
  assign terminal_dead_q[entry]=|terminal_dead_parts_q[entry];
 end
 for(entry=0;entry<2;entry=entry+1)begin:front_reduce
  assign front_dead_q[entry]=|front_dead_parts_q[entry];
 end endgenerate
 integer k;
 always @(posedge clk)begin
  if(rst||flush_i)begin
   token_q<=0;reserved_hot_q<=1;empty_q<=1;credit_return_q<=0;head_q<=0;tail_q<=0;next_head_q<=1;credit_q<=1;front_select_q<=2'b01;
  end else begin
   credit_q<=!reserved_hot_q[SLOTS];
   token_q<={token_q[STAGES-2:0],accept_w};
   final_owner_q<={{((1<<ROB_W)-1){1'b0}},1'b1}<<tag_q[STAGES-2][ROB_W-1:0];
   tag_q[0]<=in_tag_i;
   for(k=1;k<STAGES;k=k+1)tag_q[k]<=tag_q[k-1];
   // Terminal ownership moves immediately, while admission credits return
   // through a single register. Thus late READY never controls the wide
   // reservation bank. One extra reserved slot covers this return flight.
   credit_return_q<=pop_w;
   reserved_hot_q<=credit_return_q?(accept_w?reserved_hot_q:reserved_sub_w):
    (accept_w?reserved_add_w:reserved_hot_q);
   credit_q<=credit_return_q ? (accept_w?!reserved_hot_q[SLOTS]:1'b1):
    (accept_w?!reserved_hot_q[SLOTS-1]:!reserved_hot_q[SLOTS]);
   if(push_w)empty_q<=0;
   else if(pop_w)empty_q<=next_head_w==tail_q;
   if(push_w)begin
    terminal_tag_q[tail_q]<=tag_q[STAGES-1];terminal_data_q[tail_q]<=result_i;
    terminal_owner_q[tail_q]<=final_owner_q;
    tail_q<=tail_q==SLOT_W'(SLOTS-1)?{SLOT_W{1'b0}}:tail_q+1'b1;
   end
   if(pop_w)begin
    head_q<=next_head_q;
    next_head_q<=next_head_q==SLOT_W'(SLOTS-1)?{SLOT_W{1'b0}}:next_head_q+1'b1;
    front_select_q<={front_select_q[0],front_select_q[1]};
   end
  end
 end
 // Shadow cancellation is only meaningful under the corresponding owner.
 // Owner reset suffices; no global reset mux follows the late kill match.
 integer cancel_stage;
 always @(posedge clk)begin
  dead_q[0]<=kill_mask_i[in_tag_i[ROB_W-1:0]];
  for(cancel_stage=1;cancel_stage<STAGES;cancel_stage=cancel_stage+1)
   dead_q[cancel_stage]<=dead_q[cancel_stage-1]||kill_mask_i[tag_q[cancel_stage-1][ROB_W-1:0]];
 end
 // Resolve owner selection from Q, then accumulate independent eight-owner
 // sticky groups. Same-cycle kill is still rejected at the actual consumer.
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
 wire [TAG_W-1:0] next_tag_w=(!empty_q&&next_head_w!=tail_q)?terminal_tag_q[next_head_w]:tag_q[STAGES-1];
 wire [DATA_W-1:0] next_data_w=(!empty_q&&next_head_w!=tail_q)?terminal_data_q[next_head_w]:result_i;
 wire [(1<<ROB_W)-1:0] next_owner_w=(!empty_q&&next_head_w!=tail_q)?terminal_owner_q[next_head_w]:final_owner_q;
 integer bank;
 always @(posedge clk)begin
  for(bank=0;bank<2;bank=bank+1)begin
   if(head_q[0]!=bank[0])begin
    front_tag_q[bank]<=next_tag_w;front_data_q[bank]<=next_data_w;
    front_owner_q[bank]<=next_owner_w;
   end else if(empty_q&&push_w)begin
    front_tag_q[bank]<=tag_q[STAGES-1];front_data_q[bank]<=result_i;
    front_owner_q[bank]<=final_owner_q;
   end
  end
 end
 genvar front_bank,front_group;
 generate for(front_bank=0;front_bank<2;front_bank=front_bank+1)begin:front_cancel
  wire refill_w=head_q[0]!=front_bank;
  wire first_w=empty_q&&push_w;
  wire [(1<<ROB_W)-1:0] selected_owner_w=refill_w?next_owner_w:
   first_w?final_owner_q:front_owner_q[front_bank];
  for(front_group=0;front_group<CANCEL_GROUPS;front_group=front_group+1)begin:part
   wire next_old_w=(!empty_q&&next_head_w!=tail_q)?terminal_dead_parts_q[next_head_w][front_group]:dead_q[STAGES-1];
   wire old_dead_w=refill_w?next_old_w:first_w?dead_q[STAGES-1]:front_dead_parts_q[front_bank][front_group];
   always @(posedge clk)front_dead_parts_q[front_bank][front_group]<=old_dead_w||
    (|(kill_mask_i[front_group*CANCEL_BITS+:CANCEL_BITS]&selected_owner_w[front_group*CANCEL_BITS+:CANCEL_BITS]));
  end
 end endgenerate
`ifdef R64_ASSERT
 reg [SLOT_W:0] reserved_q,count_q;
 integer decode_count;
 always @(*)begin
  reserved_q=0;count_q=0;
  for(decode_count=0;decode_count<=SLOTS;decode_count=decode_count+1)begin
   if(reserved_hot_q[decode_count])reserved_q=decode_count[SLOT_W:0];
  end
  if(!empty_q)begin
   if(tail_q>head_q)count_q={1'b0,tail_q}-{1'b0,head_q};
   else count_q=(SLOT_W+1)'(SLOTS)+{1'b0,tail_q}-{1'b0,head_q};
  end
 end
 integer live_count,check_stage;
 always @(*)begin
  live_count=0;
  for(check_stage=0;check_stage<STAGES;check_stage=check_stage+1)live_count=live_count+{31'b0,token_q[check_stage]};
 end
 always @(posedge clk)if(!rst&&!flush_i)begin
  if(next_head_q!==(head_q==SLOT_W'(SLOTS-1)?{SLOT_W{1'b0}}:head_q+1'b1))
   $fatal(1,"Numeric owner predecoded next head lost ring position");
  if(!$onehot(reserved_hot_q))$fatal(1,"Numeric occupancy lost one-hot owner");
  if(STAGES<2||STAGES+3>SLOTS||SLOTS%2!=0||SLOTS>(1<<SLOT_W))$fatal(1,"Numeric owner capacity must cover pipe and terminal");
  if(!empty_q&&(out_tag_o!==terminal_tag_q[head_q]||out_data_o!==terminal_data_q[head_q]))
   $fatal(1,"Numeric owner front cache differs from terminal");
  if({{(31-SLOT_W){1'b0}},reserved_q}!={{(31-SLOT_W){1'b0}},count_q}+live_count+{31'b0,credit_return_q}||
   {{(31-SLOT_W){1'b0}},reserved_q}>SLOTS||count_q>reserved_q)
   $fatal(1,"Numeric owner token/terminal/credit conservation");
  if(push_w&&(!empty_q&&head_q==tail_q)&&!pop_w)$fatal(1,"Numeric owner terminal overflow");
 end
`endif
endmodule
