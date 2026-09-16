`include "R64Uop.vh"
// Two static decoders followed by four instruction slots. Q-only credit cuts
// execution-resource readiness out of the fetch/align feedback path. A partial
// two-lane dispatch simply advances the ring by one; the following instruction
// can pair with the next packet without inserting a packet-boundary bubble.
// Dynamic privilege, FS and rounding checks remain with the serial/FP owners.
module R64DecodeStage #(parameter PREDECODED=0,parameter PREPARED_NPC=0,parameter PRECONTROLLED=0)(
  input clk,input rst,input clear_i,input stop_i,
  input [1:0] in_valid_i,output [1:0] in_ready_o,
  input [65:0] canonical_i,input [69:0] control_i,
  input [127:0] pc_i,raw_i,pred_npc_i,sequential_npc_i,
  input [7:0] length_i,input [1:0] exception_i,
  input [11:0] cause_i,input [127:0] tval_i,
  output [1:0] out_valid_o,output [1:0] query_valid_o,input [1:0] out_take_i,
  output [2*`R64_UOP_W-1:0] uop_o,
  output [2*`R64_META_W-1:0] meta_o,
  output [5:0] class_o,src_fp_o,src_used_o,
  output [1:0] rd_write_o,rd_fp_o,serial_o,
  output [9:0] rd_arch_o,output [29:0] src_arch_o
);
  localparam U=`R64_UOP_W,M=`R64_META_W,W=U+M+33;
  wire [W-1:0] decoded_w[0:1];
  reg [W-1:0] payload_q[0:3];
  wire [W-1:0] formatted_w[0:3];
  reg [1:0] head_q,tail_q;
  reg [2:0] count_q;
  reg [1:0] room_q;
  wire room0_w=room_q[0],room1_w=room_q[1];
  // Derived credit is registered beside count at its existing update edge.
  // Current reset/clear/stop still suppress external acceptance immediately.
  assign in_ready_o[0]=!(rst||clear_i||stop_i||!room0_w);
  assign in_ready_o[1]=!(rst||clear_i||stop_i||!room1_w);
  // Q occupancy drives resource queries; cancelled packets cannot birth.
  assign query_valid_o={count_q>=2,count_q!=0};
  assign out_valid_o=query_valid_o&{2{!rst&&!clear_i}};
  wire [1:0] in_fire_w=in_valid_i&in_ready_o;
  wire [1:0] added_w={1'b0,in_fire_w[0]}+{1'b0,in_fire_w[1]};
  wire [1:0] removed_w={1'b0,out_take_i[0]}+{1'b0,out_take_i[1]};
  wire [2:0] next_count_w=count_q+{1'b0,added_w}-{1'b0,removed_w};
  wire [1:0] tail1_w=tail_q+2'd1;
  genvar lane,slot;
  generate for(lane=0;lane<2;lane=lane+1)begin:gen_decode
    wire [U-1:0] uop_w;wire [M-1:0] meta_w;
    wire [2:0] class_w,src_fp_w,src_used_w;
    wire rd_write_w,rd_fp_w,serial_w;
    wire [4:0] rd_arch_w;wire [14:0] src_arch_w;
    R64Decode #(.PREDECODED(PREDECODED),.DEFER_ILLEGAL_TVAL(1),.PREPARED_NPC(PREPARED_NPC),.PRECONTROLLED(PRECONTROLLED)) decode(
      .canonical_i(canonical_i[lane*33+:33]),.control_i(control_i[lane*35+:35]),.sequential_npc_i(sequential_npc_i[lane*64+:64]),
      .pc_i(pc_i[lane*64+:64]),.raw_i(raw_i[lane*64+:64]),
      .length_i(length_i[lane*4+:4]),.pred_npc_i(pred_npc_i[lane*64+:64]),
      .fetch_exception_i(exception_i[lane]),.fetch_cause_i(cause_i[lane*6+:6]),
      .fetch_tval_i(tval_i[lane*64+:64]),.uop_o(uop_w),.meta_o(meta_w),
      .class_o(class_w),.rd_write_o(rd_write_w),.rd_fp_o(rd_fp_w),
      .rd_arch_o(rd_arch_w),.src_arch_o(src_arch_w),.src_fp_o(src_fp_w),
      .src_used_o(src_used_w),.serial_o(serial_w),.illegal_o());
    assign decoded_w[lane]={exception_i[lane],uop_w,meta_w,class_w,rd_write_w,rd_fp_w,
      rd_arch_w,src_arch_w,src_fp_w,src_used_w,serial_w};
    wire [1:0] read_slot_w=head_q+2'(lane);
    wire unused_fetch_fault_w;
    assign {unused_fetch_fault_w,uop_o[lane*U+:U],meta_o[lane*M+:M],class_o[lane*3+:3],
      rd_write_o[lane],rd_fp_o[lane],rd_arch_o[lane*5+:5],
      src_arch_o[lane*15+:15],src_fp_o[lane*3+:3],
      src_used_o[lane*3+:3],serial_o[lane]}=formatted_w[read_slot_w];
  end
  for(slot=0;slot<4;slot=slot+1)begin:gen_slot
    localparam B=M+32;
    wire [U-1:0] stored_uop_w=payload_q[slot][B+:U];
    wire illegal_w=stored_uop_w[`R64_U_EXCEPTION]&&!payload_q[slot][W-1];
    wire [63:0] instruction_tval_w=stored_uop_w[`R64_U_LEN]==2 ?
      {48'b0,payload_q[slot][96+:16]}:{32'b0,payload_q[slot][96+:32]};
    // Each fixed owner prepares its own exception value before the output
    // slot selector. No selected head flag fans back out across both lanes.
    assign formatted_w[slot]={payload_q[slot][W-1:B+128],
      illegal_w?instruction_tval_w:stored_uop_w[127:64],payload_q[slot][B+63:0]};
    // Speculative data writes are allowed only into Q-state free slots.
    // Validity, order and lifetime change exclusively on real handshakes.
    // Thus late STOP/redirect/admission does not drive the wide data enables.
    always @(posedge clk)begin
      if(room0_w&&tail_q==2'(slot))payload_q[slot]<=decoded_w[0];
      else if(room1_w&&tail1_w==2'(slot))payload_q[slot]<=decoded_w[1];
    end
  end endgenerate
  always @(posedge clk)begin
    if(rst||clear_i)begin head_q<=0;tail_q<=0;count_q<=0;room_q<=3;end
    else begin
      head_q<=head_q+removed_w;
      tail_q<=tail_q+added_w;
      count_q<=next_count_w;
      room_q<={next_count_w<=2,next_count_w<4};
    end
  end
`ifdef R64_ASSERT
  genvar npc_lane;
  generate if(PREPARED_NPC)begin:gen_prepared_npc_check
    for(npc_lane=0;npc_lane<2;npc_lane=npc_lane+1)begin:gen_lane
      always @(posedge clk)if(!rst&&!clear_i)begin
        if(in_fire_w[npc_lane]&&sequential_npc_i[npc_lane*64+:64]!==pc_i[npc_lane*64+:64]+{60'b0,length_i[npc_lane*4+:4]})
          $fatal(1,"decode accepted a mismatched prepared sequential NPC");
        if(out_take_i[npc_lane]&&meta_o[npc_lane*M+128+:64]!==meta_o[npc_lane*M+:64]+{60'b0,meta_o[npc_lane*M+192+:4]})
          $fatal(1,"dispatch sequential NPC separated from canonical instruction");
      end
    end
  end endgenerate

  always @(posedge clk)if(!rst&&!clear_i)begin
    if(in_valid_i[1]&&!in_valid_i[0])$fatal(1,"decode ingress must be dense");
    if(out_take_i[1]&&!out_take_i[0])$fatal(1,"decode dispatch must be a prefix");
    if((out_take_i&~out_valid_o)!=0)$fatal(1,"dispatch without decoded owner");
    if(room_q!=={count_q<=2,count_q<4})
      $fatal(1,"decode Q credit disagrees with owned instruction count");
    if(count_q>4||head_q+2'(count_q)!=tail_q)
      $fatal(1,"decode ring lost instruction ownership");
    if(stop_i&&out_take_i!=0)$fatal(1,"decode dispatch while stopped");
  end
`endif
endmodule
