`timescale 1ns/1ps
module tb_r64_packet_map;
reg  clk_i=0;
reg  rst_i=0;

reg  redirect_i=0;
reg [63:0] redirect_pc_i=0;
reg  packet_valid_i=0;
wire  a_packet_ready_o,b_packet_ready_o;
reg [63:0] packet_pc_i=0;
reg [127:0] packet_data_i=0;
reg  packet_fault_i=0;
reg [4:0] packet_cause_i=0;
reg [7:0] packet_access_mask_i=0;
reg  packet_plan_valid_i=0;
reg [2:0] packet_plan_offset_i=0;
reg  packet_plan_word_i=0;
reg [62:0] packet_plan_target_i=0;
reg  jump_i=0;
reg [63:0] jump_pc_i=0;
wire [1:0] a_plan_at_o,b_plan_at_o;
wire [1:0] a_plan_bad_o,b_plan_bad_o;
wire [63:0] a_plan_target_o,b_plan_target_o;
wire [63:0] a_plan_source_o,b_plan_source_o;
wire [1:0] a_valid_o,b_valid_o;
reg [1:0] consume_i=0;
wire [63:0] a_pc0_o,b_pc0_o;
wire [63:0] a_pc1_o,b_pc1_o;
wire [63:0] a_inst0_o,b_inst0_o;
wire [63:0] a_inst1_o,b_inst1_o;
wire [3:0] a_length0_o,b_length0_o;
wire [3:0] a_length1_o,b_length1_o;
wire  a_fault0_o,b_fault0_o;
wire  a_fault1_o,b_fault1_o;
wire [4:0] a_cause0_o,b_cause0_o;
wire [4:0] a_cause1_o,b_cause1_o;
wire [63:0] a_tval0_o,b_tval0_o;
wire [63:0] a_tval1_o,b_tval1_o;
always #5 clk_i=~clk_i;
R64Align #(.EARLY_PREDICT(1)) dut(.clk_i(clk_i),.rst_i(rst_i),.redirect_i(redirect_i),.redirect_pc_i(redirect_pc_i),.packet_valid_i(packet_valid_i),.packet_ready_o(a_packet_ready_o),.packet_pc_i(packet_pc_i),.packet_data_i(packet_data_i),.packet_fault_i(packet_fault_i),.packet_cause_i(packet_cause_i),.packet_access_mask_i(packet_access_mask_i),.packet_plan_valid_i(packet_plan_valid_i),.packet_plan_offset_i(packet_plan_offset_i),.packet_plan_word_i(packet_plan_word_i),.packet_plan_target_i(packet_plan_target_i),.jump_i(jump_i),.jump_pc_i(jump_pc_i),.plan_at_o(a_plan_at_o),.plan_bad_o(a_plan_bad_o),.plan_target_o(a_plan_target_o),.plan_source_o(a_plan_source_o),.valid_o(a_valid_o),.consume_i(consume_i),.pc0_o(a_pc0_o),.pc1_o(a_pc1_o),.inst0_o(a_inst0_o),.inst1_o(a_inst1_o),.length0_o(a_length0_o),.length1_o(a_length1_o),.fault0_o(a_fault0_o),.fault1_o(a_fault1_o),.cause0_o(a_cause0_o),.cause1_o(a_cause1_o),.tval0_o(a_tval0_o),.tval1_o(a_tval1_o));
R64AlignBaseline #(.EARLY_PREDICT(1)) refdut(.clk_i(clk_i),.rst_i(rst_i),.redirect_i(redirect_i),.redirect_pc_i(redirect_pc_i),.packet_valid_i(dut.parse_w),.packet_ready_o(b_packet_ready_o),.packet_pc_i(dut.source_pc_w),.packet_data_i(dut.source_data_w),.packet_fault_i(dut.source_cause_w==12),.packet_cause_i(dut.source_cause_w),.packet_access_mask_i(dut.source_mask_w),.packet_plan_valid_i(dut.source_planned_w),.packet_plan_offset_i(dut.source_plan_w[66:64]),.packet_plan_word_i(dut.source_plan_w[63]),.packet_plan_target_i(dut.source_plan_w[62:0]),.jump_i(jump_i),.jump_pc_i(jump_pc_i),.plan_at_o(b_plan_at_o),.plan_bad_o(b_plan_bad_o),.plan_target_o(b_plan_target_o),.plan_source_o(b_plan_source_o),.valid_o(b_valid_o),.consume_i(consume_i),.pc0_o(b_pc0_o),.pc1_o(b_pc1_o),.inst0_o(b_inst0_o),.inst1_o(b_inst1_o),.length0_o(b_length0_o),.length1_o(b_length1_o),.fault0_o(b_fault0_o),.fault1_o(b_fault1_o),.cause0_o(b_cause0_o),.cause1_o(b_cause1_o),.tval0_o(b_tval0_o),.tval1_o(b_tval1_o));


integer held_lane_checks=0,late_completion=0,missing_next_wait=0;
reg [1:0] held_valid,held_at,held_bad;
reg [201:0] held0,held1;
reg [127:0] held_plan;
always @(posedge clk_i)begin
 if(!rst_i&&!redirect_i&&consume_i==0)begin
  held_valid=a_valid_o;held_at=a_plan_at_o;held_bad=a_plan_bad_o;
  held0={a_pc0_o,a_inst0_o,a_length0_o,a_fault0_o,a_cause0_o,a_tval0_o};
  held1={a_pc1_o,a_inst1_o,a_length1_o,a_fault1_o,a_cause1_o,a_tval1_o};
  held_plan={a_plan_target_o,a_plan_source_o};
  if(dut.count_q!=0&&!a_valid_o[0])missing_next_wait=missing_next_wait+1;
  #1;
  if(held_valid[0])begin
   if(!a_valid_o[0]||{a_pc0_o,a_inst0_o,a_length0_o,a_fault0_o,a_cause0_o,a_tval0_o}!==held0)
    $fatal(1,"held map lane0 changed on producer completion cycle=%0d held=%h new=%h",cycle,held0,{a_pc0_o,a_inst0_o,a_length0_o,a_fault0_o,a_cause0_o,a_tval0_o});
   held_lane_checks=held_lane_checks+1;
  end
  if(held_valid[1])begin
   if(!a_valid_o[1]||{a_pc1_o,a_inst1_o,a_length1_o,a_fault1_o,a_cause1_o,a_tval1_o}!==held1)
    $fatal(1,"held map lane1 changed on producer completion");
   held_lane_checks=held_lane_checks+1;
  end
  if(held_at!=0||held_bad!=0)begin
   if(held_at!==a_plan_at_o||held_bad!==a_plan_bad_o||held_plan!=={a_plan_target_o,a_plan_source_o})
    $fatal(1,"held actionable plan changed on producer completion");
  end
  if(held_valid[0]&&!held_valid[1]&&a_valid_o[1])late_completion=late_completion+1;
 end
end

integer cycle,k,idx,packets=0,partial=0,pairs=0,cuts1=0,cuts2=0,overlap=0,faults=0,redirects=0,held=0;
integer cross2=0,cross4=0,cross8=0,metadata_checks=0;
reg [31:0] rng=32'h395cb271;
reg packet_held=0;reg [273:0] held_packet;
integer input_hold_checks=0;
task random_next;begin rng=(rng<<13)^rng;rng=(rng>>17)^rng;rng=(rng<<5)^rng;end endtask
task check;
begin
 if(a_valid_o!==b_valid_o||a_pc0_o!==b_pc0_o)
   $fatal(1,"window owner cycle=%0d",cycle);
 if(a_plan_at_o!==b_plan_at_o||a_plan_bad_o!==b_plan_bad_o)
   $fatal(1,"window plan cycle=%0d count=%0d at=%b/%b bad=%b/%b pc=%h data=%h next=%h plan=%h len=%0d/%0d valid=%b/%b",cycle,dut.count_q,a_plan_at_o,b_plan_at_o,a_plan_bad_o,b_plan_bad_o,a_pc0_o,dut.data_q[dut.head_q],refdut.data_q[refdut.next_head_w],dut.own_plan_q[dut.head_q],a_length0_o,b_length0_o,a_valid_o,b_valid_o);
 if(((|a_plan_at_o)||(|a_plan_bad_o)) && ({a_plan_target_o,a_plan_source_o}!=={b_plan_target_o,b_plan_source_o}))
   $fatal(1,"window plan target ownership");
 if(a_valid_o[0])begin
  if({a_inst0_o,a_length0_o,a_fault0_o,a_tval0_o}!=={b_inst0_o,b_length0_o,b_fault0_o,b_tval0_o})
    $fatal(1,"window lane0 cycle=%0d",cycle);
  if(a_fault0_o&&a_cause0_o!==b_cause0_o)$fatal(1,"window fault0 cause");
 end
 if(a_valid_o[1])begin
  if({a_pc1_o,a_inst1_o,a_length1_o,a_fault1_o,a_tval1_o}!=={b_pc1_o,b_inst1_o,b_length1_o,b_fault1_o,b_tval1_o})
    $fatal(1,"window lane1 cycle=%0d",cycle);
  if(a_fault1_o&&a_cause1_o!==b_cause1_o)$fatal(1,"window fault1 cause");
 end
 if(dut.count_q!==refdut.count_q||dut.head_q!==refdut.head_q)
   $fatal(1,"parse map fixed owner mismatch");
 metadata_checks=metadata_checks+1;
end endtask
initial begin
 rst_i=1;
 repeat(3)@(negedge clk_i);
 rst_i=0;
 for(cycle=0;cycle<160000;cycle=cycle+1)begin
  check;
  random_next;
  redirect_i=(rng[7:0]==0)||b_plan_bad_o[0];
  redirect_pc_i=64'h80000000+{47'b0,rng[15:0],1'b0};
  consume_i=0;jump_i=0;
  if(!redirect_i&&b_valid_o[0]&&rng[3:0]!=0)begin
   consume_i=b_valid_o[1]&&!b_plan_at_o[0]&&!b_plan_bad_o[1]&&rng[5:4]!=0?2:1;
   jump_i=consume_i==2?b_plan_at_o[1]:b_plan_at_o[0];
  end
  jump_pc_i=b_plan_target_o;
  if(!packet_held||redirect_i)begin
  packet_valid_i=rng[10:8]!=0;
  packet_pc_i=dut.fill_pc_q;
  for(k=0;k<8;k=k+1)begin
   random_next;
   case(rng[3:0])
    0,1,2,3:packet_data_i[k*16+:16]=16'h0001;
    4,5:packet_data_i[k*16+:16]=16'h305b;
    6,7:packet_data_i[k*16+:16]=16'h0200;
    default:packet_data_i[k*16+:16]=rng[15:0];
   endcase
  end
  packet_fault_i=rng[9:4]==0;
  packet_access_mask_i=rng[12:10]==0?rng[23:16]:0;
  packet_cause_i=12;
  packet_plan_valid_i=rng[13:10]==0;
  packet_plan_offset_i=rng[16:14];
  packet_plan_word_i=rng[17]&&(packet_plan_offset_i!=7);
  packet_plan_target_i=(64'h90000000+{47'b0,rng[31:16],1'b0})>>1;
  end
  #1;check;
  if(packet_held&&!redirect_i)begin
   if(!packet_valid_i||{packet_pc_i,packet_data_i,packet_fault_i,packet_cause_i,packet_access_mask_i,
      packet_plan_valid_i,packet_plan_offset_i,packet_plan_word_i,packet_plan_target_i}!==held_packet)
     $fatal(1,"test producer changed a held packet");
   input_hold_checks=input_hold_checks+1;
  end
  @(posedge clk_i);
  packet_held=packet_valid_i&&!a_packet_ready_o&&!redirect_i;
  held_packet={packet_pc_i,packet_data_i,packet_fault_i,packet_cause_i,packet_access_mask_i,
      packet_plan_valid_i,packet_plan_offset_i,packet_plan_word_i,packet_plan_target_i};
  if(redirect_i)redirects=redirects+1;
  else begin
   if(packet_valid_i&&a_packet_ready_o)packets=packets+1;
   if(consume_i==1)partial=partial+1;
   if(consume_i==2)pairs=pairs+1;
   if(jump_i&&dut.pop_count_w==1)cuts1=cuts1+1;
   if(jump_i&&dut.pop_count_w==2)cuts2=cuts2+1;
   if(dut.parse_w&&(dut.pop_count_w!=0))overlap=overlap+1;
   if(consume_i!=0&&a_fault0_o)faults=faults+1;
   if(consume_i==2&&a_fault1_o)faults=faults+1;
   if(consume_i==0&&a_valid_o[0])held=held+1;
   if(consume_i!=0&&{1'b0,a_pc0_o[3:0]}+{1'b0,a_length0_o}>16)begin
    if(a_length0_o==2)cross2=cross2+1;
    if(a_length0_o==4)cross4=cross4+1;
    if(a_length0_o==8)cross8=cross8+1;
   end
  end
  @(negedge clk_i);
 end
 check;
 if(packets<5000||partial<1000||pairs<5000||cuts1<1||cuts2<1||overlap<1000||faults<500||cross4<500||cross8<10||input_hold_checks<10000)
  $fatal(1,"window coverage gap packets=%0d partial=%0d pairs=%0d cuts=%0d/%0d overlap=%0d faults=%0d cross4=%0d cross8=%0d",packets,partial,pairs,cuts1,cuts2,overlap,faults,cross4,cross8);
 $display("[PASS] tb_r64_packet_map cycles=%0d packets=%0d partial=%0d pairs=%0d cuts=%0d/%0d overlap=%0d faults=%0d redirects=%0d held=%0d cross4=%0d cross8=%0d metadata=%0d input_hold=%0d",cycle,packets,partial,pairs,cuts1,cuts2,overlap,faults,redirects,held,cross4,cross8,metadata_checks,input_hold_checks);
 $display("MAP_HOLD valid_lane_checks=%0d late_second_completion=%0d missing_successor_wait=%0d",held_lane_checks,late_completion,missing_next_wait);
 $finish;
end
endmodule
