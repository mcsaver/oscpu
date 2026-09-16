// Native address admission -> physical read -> independently held operands.
// Four GPR and three FPR ports are explicit. Blocked read results remain local
// to ingress; they never keep claiming a port. Each MEM carries the LSQ slot
// allocated at dispatch; the LSQ alone owns memory age and capacity.
// Outputs are raw owners: Execute must reject current kill/flush before effects.
// Cancellation clears local state at the edge without an async READY chain.
module R64RegReadReference #(
  parameter PREPARED_CANCEL=0, parameter PREG_W=6, parameter PREG_N=(1<<PREG_W),
  parameter COMPACT_FP=0, parameter UNIQUE_SERIAL=0, parameter PREQUALIFIED_ISSUE=0,
  parameter Q_ONLY_TERMINAL=0,
  parameter ROB_W=5, parameter TAG_W=9, parameter PAYLOAD_W=128, parameter LSQ_W=5
) (
  input clk, input rst, input flush_i,
  input [(1<<ROB_W)-1:0] kill_mask_i,
  input [(1<<ROB_W)-1:0] cancel_candidates_i,input cancel_active_i,
  input [1:0] in_fire_i, output [1:0] in_ready_o,
  input [2*TAG_W-1:0] in_tag_i,
  input [2*LSQ_W-1:0] in_mem_slot_i,
  input [2*PAYLOAD_W-1:0] in_payload_i, input [5:0] in_class_i,
  input [2*PREG_W-1:0] in_gpr_dst_i,
  input [6*PREG_W-1:0] in_src_preg_i,
  input [5:0] in_src_fp_i, input [5:0] in_src_used_i,
  input [2*(3*PREG_W+8)-1:0] in_fp_plan_i,
  input [1:0] wb_write_i, input [1:0] wb_fp_i,
  input [2*PREG_W-1:0] wb_preg_i, input [127:0] wb_data_i,
  // Short ALU result holders bridge early wakeup to canonical WB/PRF.
  input [1:0] alu_bypass_valid_i,input [2*PREG_W-1:0] alu_bypass_preg_i,
  input [127:0] alu_bypass_data_i,
  output [1:0] out_valid_o, input [1:0] out_ready_i,
  output [2*TAG_W-1:0] out_tag_o,
  output [2*LSQ_W-1:0] out_mem_slot_o,
  output [2*PAYLOAD_W-1:0] out_payload_o, output [5:0] out_class_o,
  output [383:0] out_operand_o,
  output [2*PREG_W-1:0] out_gpr_dst_o,
  output [73:0] out_alu_control_o,output [9:0] out_add_source_o,output [11:0] out_shift_amount_o,
  output [41:0] out_branch_imm_o,output [9:0] out_branch_control_o
);
  // Select this registered owner's candidate bit before applying the late
  // redirect enable. The ordinary mask remains the default module contract.
  function cancel_selected;
    input [ROB_W-1:0] slot;
    input [(1<<ROB_W)-1:0] candidates,mask;
    input active;
    begin cancel_selected=PREPARED_CANCEL ?
        (active&&candidates[slot]):mask[slot];end
  endfunction

  reg [63:0] gpr_q[0:PREG_N-1], fpr_q[0:PREG_N-1];
  reg [PREG_N-1:0] ginit_q,finit_q;
  // Three owned slots per lane hide the credit return without a READY cone.
  // The physical read remains one edge after admission; no latency is added.
  reg [1:0] terminal_head_q,terminal_tail_q;
  reg [1:0] terminal_count_q[0:1];
  reg [3:0] terminal_dead_q;
  wire [1:0] terminal_pop_w;
  reg [TAG_W-1:0] tag_q[0:3];
  reg [PAYLOAD_W-1:0] payload_q[0:3];
  reg [2:0] class_q[0:3];
  reg [PREG_W-1:0] gpr_dst_q[0:3];
  reg [319:0] operand_q[0:3];
  reg [2:0] operand_fp_q[0:3],operand_used_q[0:3];
  reg [5:0] operand_rank_q[0:3];
  reg [36:0] alu_control_q[0:3];
  reg [4:0] add_source_q[0:3];wire [4:0] add_source_w[0:1];
  reg [5:0] shift_amount_q[0:3],ingress_shift_amount_q[0:1];
  wire [5:0] read_shift_amount_w[0:1];
  reg [20:0] branch_imm_q[0:3];reg [4:0] branch_control_q[0:3];
  wire [20:0] branch_imm_w[0:1];wire [4:0] branch_control_w[0:1];
  wire [36:0] alu_control_w[0:1];
  // A physical read snapshots storage and forward identities independently.
  // Late WB destination matching only reaches a small hit register; bank/
  // forward selection occurs from this owned snapshot after the read edge.
  reg [11:0] forward_hit_q[0:3],ingress_forward_hit_q[0:1];
  reg [255:0] forward_data_q[0:3],ingress_forward_data_q[0:1];
  // Address/owner admission precedes physical read. A read result can remain
  // in ingress if its output is held, without reserving a physical read port.
  reg [1:0] ingress_valid_q,operand_ready_q;
  reg [TAG_W-1:0] ingress_tag_q[0:1];
  reg [PAYLOAD_W-1:0] ingress_payload_q[0:1];
  reg [2:0] ingress_class_q[0:1],ingress_fp_q[0:1],ingress_used_q[0:1];
  reg [PREG_W-1:0] ingress_dst_q[0:1];
  reg [3*PREG_W-1:0] ingress_src_q[0:1];
  reg [319:0] ingress_operand_q[0:1];
  reg [2:0] ingress_operand_fp_q[0:1],ingress_operand_used_q[0:1];
  reg [5:0] ingress_operand_rank_q[0:1];
  wire [1:0] ingress_live_w,read_select_w,transfer_w,out_live_w,out_room_w;
  wire [6*PREG_W-1:0] read_src_w={ingress_src_q[1],ingress_src_q[0]};
  wire [5:0] read_fp_w={ingress_fp_q[1],ingress_fp_q[0]};
  wire [5:0] read_used_w={ingress_used_q[1],ingress_used_q[0]};
  wire [1:0] pending_read_w=ingress_valid_q&~operand_ready_q;
  // Every new ingress performs its physical read on the next edge even
  // when output is blocked, storing the result locally in that case.
  // Therefore pending reads are exactly a subset of the previous input
  // bundle: independent output stalls cannot merge different FP port budgets.
  assign read_select_w=pending_read_w;
  // This is the already allocated LSQ slot, not a second RR reservation.
  // It follows the same fulltag through ingress and terminal owners.
  reg [LSQ_W-1:0] mem_slot_q[0:3],ingress_mem_slot_q[0:1];
  wire [1:0] out_fire_w;
  wire [PREG_W-1:0] gaddr_w[0:3];
  wire [63:0] gdata_w[0:3];
  reg [PREG_W-1:0] faddr_w[0:2];
  wire [PREG_W-1:0] allocated_faddr_w[0:2];
  reg [11:0] allocated_rank_q;
  wire [11:0] allocated_rank_w;
  wire [5:0] allocate_fp_request_w=in_src_used_i&in_src_fp_i&
      {{3{in_fire_i[1]}},{3{in_fire_i[0]}}};
  wire [63:0] fdata_w[0:2];
  wire [1:0] frank_w[0:5];
  wire [5:0] frequest_w=read_used_w&read_fp_w&
      {{3{read_select_w[1]}},{3{read_select_w[0]}}};
  function [2:0] pop6;
    input [5:0] mask;
    reg [1:0] a,b,c;
    begin
      a={1'b0,mask[0]}+{1'b0,mask[1]};
      b={1'b0,mask[2]}+{1'b0,mask[3]};
      c={1'b0,mask[4]}+{1'b0,mask[5]};
      pop6={1'b0,a}+{1'b0,b}+{1'b0,c};
    end
  endfunction
  wire [2:0] fp_ports=pop6(frequest_w);
  genvar source,port,node;
  generate if(COMPACT_FP!=0)begin:g_compact_fp
    wire [3*PREG_W-1:0] address_w;
    R64FpReadJoin #(.PREG_W(PREG_W)) fp_join(
      .plan_i(in_fp_plan_i),.fire_i(in_fire_i),
      .address_o(address_w),.rank_o(allocated_rank_w));
    for(port=0;port<3;port=port+1)begin:g_port
      assign allocated_faddr_w[port]=address_w[port*PREG_W+:PREG_W];
    end
    for(source=0;source<6;source=source+1)begin:g_rank
      assign frank_w[source]=allocated_rank_w[source*2+:2];
    end
  end else begin:g_raw_fp
  for(source=0;source<6;source=source+1)begin:gen_fp_rank
    localparam [5:0] PREVIOUS=(6'b000001<<source)-1'b1;
    wire [2:0] rank_w=pop6(allocate_fp_request_w&PREVIOUS);
    assign frank_w[source]=rank_w[1:0];
    assign allocated_rank_w[source*2+:2]=rank_w[1:0];
  end
  for(port=0;port<3;port=port+1)begin:gen_fp_address
    for(node=1;node<16;node=node+1)begin:tree
      wire [PREG_W-1:0] addr_w;
      if(node>=8)begin:leaf
        if(node-8<6)begin:present
          assign addr_w=in_src_preg_i[(node-8)*PREG_W+:PREG_W]&
              {PREG_W{allocate_fp_request_w[node-8]&&frank_w[node-8]==port}};
        end else begin:pad
          assign addr_w=0;
        end
      end else begin:merge
        assign addr_w=tree[2*node].addr_w|tree[2*node+1].addr_w;
      end
    end
    assign allocated_faddr_w[port]=tree[1].addr_w;
  end
  end endgenerate
  function [63:0] compose_operand;
    input [63:0] stored;
    input [3:0] hit;
    input [255:0] values;
    reg [63:0] v0,v1,v2,v3;
    begin
      v0=values[0+:64]&{64{hit[0]}};v1=values[64+:64]&{64{hit[1]}};
      v2=values[128+:64]&{64{hit[2]}};v3=values[192+:64]&{64{hit[3]}};
      compose_operand=(v0|v1)|(v2|v3)|(stored&{64{!(|hit)}});
    end
  endfunction
  wire [3:0] gpr_forward_valid_w={wb_write_i&~wb_fp_i,alu_bypass_valid_i};
  wire [4*PREG_W-1:0] gpr_forward_preg_w={wb_preg_i,alu_bypass_preg_i};
  wire [255:0] gpr_forward_data_w={wb_data_i,alu_bypass_data_i};
  genvar p;
  generate for(p=0;p<4;p=p+1) begin:gen_gpr_port
    localparam SRC=(p/2)*3+(p%2);
    assign gaddr_w[p]=read_src_w[SRC*PREG_W+:PREG_W];
    assign gdata_w[p]=(gaddr_w[p]!=0&&ginit_q[gaddr_w[p]]) ? gpr_q[gaddr_w[p]]:64'b0;
  end
  for(p=0;p<3;p=p+1) begin:gen_fpr_port
    assign fdata_w[p]=finit_q[faddr_w[p]] ? fpr_q[faddr_w[p]]:64'b0;
  end endgenerate
  // Snapshot the physical read ports before mapping them back to logical
  // operands. FP source rank no longer traverses allocation -> PRF -> reverse
  // mapping in one cycle. Held packets retain all relevant physical values.
  wire [639:0] read_operand_w;
  wire [11:0] read_rank_w;
  wire [23:0] read_forward_hit_w;
  generate for(p=0;p<6;p=p+1) begin:gen_operand
    wire [PREG_W-1:0] source_w=read_src_w[p*PREG_W+:PREG_W];
    wire source_live_w=read_used_w[p]&&(read_fp_w[p]||source_w!=0);
    wire wb0_hit_w=source_live_w&&wb_write_i[0]&&wb_fp_i[0]==read_fp_w[p]&&wb_preg_i[0+:PREG_W]==source_w;
    wire wb1_hit_w=source_live_w&&wb_write_i[1]&&wb_fp_i[1]==read_fp_w[p]&&wb_preg_i[PREG_W+:PREG_W]==source_w;
    assign read_forward_hit_w[p*4+0]=source_live_w&&!read_fp_w[p]&&alu_bypass_valid_i[0]&&alu_bypass_preg_i[0+:PREG_W]==source_w;
    assign read_forward_hit_w[p*4+1]=source_live_w&&!read_fp_w[p]&&alu_bypass_valid_i[1]&&alu_bypass_preg_i[PREG_W+:PREG_W]==source_w;
    assign read_forward_hit_w[p*4+2]=wb0_hit_w&&!(read_fp_w[p]&&wb1_hit_w);
    assign read_forward_hit_w[p*4+3]=wb1_hit_w;
    assign read_rank_w[p*2+:2]=allocated_rank_q[p*2+:2];
  end endgenerate
  // Compose each resident packet before selecting a terminal head. The head
  // bit controls only the final operand mux, not physical-port rank and
  // forwarding selection cascaded behind a wide packet mux.
  wire [767:0] terminal_operand_w;
  generate for(p=0;p<12;p=p+1) begin:gen_terminal_operand
    wire [63:0] stored_gpr_w;
    if(p%3<2)assign stored_gpr_w=operand_q[p/3][(p%3)*64+:64];
    else assign stored_gpr_w=0;
    wire [1:0] rank_q=operand_rank_q[p/3][(p%3)*2+:2];
    wire [191:0] stored_fpr_w=operand_q[p/3][128+:192];
    wire [63:0] stored_operand_w=!operand_used_q[p/3][p%3] ? 64'b0:
        operand_fp_q[p/3][p%3] ? stored_fpr_w[rank_q*64+:64]:stored_gpr_w;
    assign terminal_operand_w[p*64+:64]=compose_operand(stored_operand_w,
        forward_hit_q[p/3][(p%3)*4+:4],forward_data_q[p/3]);
  end
  for(p=0;p<2;p=p+1) begin:gen_lane
    assign out_operand_o[p*192+:192]=terminal_head_q[p] ?
        terminal_operand_w[(p*2+1)*192+:192]:terminal_operand_w[p*2*192+:192];
    wire [63:0] read_bypass_b_w=compose_operand(gdata_w[p*2+1],
        read_forward_hit_w[(p*3+1)*4+:4],gpr_forward_data_w);
    assign read_operand_w[p*320+:320]={fdata_w[2],fdata_w[1],fdata_w[0],gdata_w[p*2+1],gdata_w[p*2]};
    if(PAYLOAD_W>=208)begin:alu_predecode
      assign read_shift_amount_w[p]=ingress_payload_q[p][207] ?
          ingress_payload_q[p][64+:6]:read_bypass_b_w[5:0];
      // Opcode control travels alongside the physical read, before any ALU
      // data calculation. Generic short test payloads do not contain an ALU.
      wire [7:0] function_w=ingress_class_q[p]==3'd1 ? 8'd0:ingress_payload_q[p][196+:8];
      R64AluControl decoder(.function_i(function_w),.control_o(alu_control_w[p]));
      wire [31:0] inst_w=ingress_payload_q[p][128+:32];
      wire conditional_w=inst_w[6:0]==7'h63,indirect_w=inst_w[6:0]==7'h67;
      wire [20:0] bi_w={{8{inst_w[31]}},inst_w[31],inst_w[7],inst_w[30:25],inst_w[11:8],1'b0};
      wire [20:0] ji_w={inst_w[31],inst_w[19:12],inst_w[20],inst_w[30:21],1'b0};
      wire [20:0] ii_w={{9{inst_w[31]}},inst_w[31:20]};
      assign branch_imm_w[p]=indirect_w ? ii_w:conditional_w ? bi_w:ji_w;
      assign branch_control_w[p]={inst_w[14:12],indirect_w,conditional_w};
      // {branch B, immediate B, register B, PC A, register A}.
      assign add_source_w[p]=ingress_class_q[p]==3'd1 ?
          {3'b100,!indirect_w,indirect_w}:
          {1'b0,ingress_payload_q[p][207],!ingress_payload_q[p][207],
           ingress_payload_q[p][205],!ingress_payload_q[p][205]&&!ingress_payload_q[p][206]};
    end else begin:no_alu_predecode
      assign alu_control_w[p]=37'd2;assign add_source_w[p]=5'b00101;
      assign read_shift_amount_w[p]=read_bypass_b_w[5:0];
      assign branch_imm_w[p]=0;assign branch_control_w[p]=0;
    end
    assign out_alu_control_o[p*37+:37]=alu_control_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_add_source_o[p*5+:5]=add_source_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_shift_amount_o[p*6+:6]=shift_amount_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_branch_imm_o[p*21+:21]=branch_imm_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_branch_control_o[p*5+:5]=branch_control_q[p*2+{31'b0,terminal_head_q[p]}];
    wire killed_w=cancel_selected(tag_q[p*2+{31'b0,terminal_head_q[p]}][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i);
    assign ingress_live_w[p]=ingress_valid_q[p]&&!rst&&!flush_i&&
        !cancel_selected(ingress_tag_q[p][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i);
    // Output is a raw registered owner. Execute checks the same current
    // kill/flush before any FU/LSU admission; local state cancels at this edge.
    assign out_live_w[p]=terminal_count_q[p]!=0&&!terminal_dead_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_valid_o[p]=out_live_w[p];
    assign out_fire_w[p]=out_valid_o[p]&&out_ready_i[p];
    assign terminal_pop_w[p]=terminal_count_q[p]!=0&&(out_fire_w[p]||
        terminal_dead_q[p*2+{31'b0,terminal_head_q[p]}]);
    // Q-only capacity prevents Execute READY/cancellation from re-entering
    // terminal admission. A full queue can pop now and accept ingress next edge.
    assign out_room_w[p]=terminal_count_q[p]<2||
        (Q_ONLY_TERMINAL==0&&terminal_pop_w[p]);
    assign transfer_w[p]=ingress_valid_q[p]&&out_room_w[p]&&
        (operand_ready_q[p]||read_select_w[p]);
    assign in_ready_o[p]=!(terminal_count_q[p][1]&&ingress_valid_q[p]);
    assign out_mem_slot_o[p*LSQ_W+:LSQ_W]=mem_slot_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_tag_o[p*TAG_W+:TAG_W]=tag_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_payload_o[p*PAYLOAD_W+:PAYLOAD_W]=payload_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_class_o[p*3+:3]=class_q[p*2+{31'b0,terminal_head_q[p]}];
    assign out_gpr_dst_o[p*PREG_W+:PREG_W]=gpr_dst_q[p*2+{31'b0,terminal_head_q[p]}];
  end endgenerate
  // Port allocation belongs to the address admission edge. Every pending
  // read is from exactly this previous bundle; completed blocked reads keep
  // their own physical values/rank and never consume these addresses again.
  integer address_port;
  always @(posedge clk)begin
    for(address_port=0;address_port<3;address_port=address_port+1)
      faddr_w[address_port]<=allocated_faddr_w[address_port];
    allocated_rank_q<=allocated_rank_w;
  end
  // Each physical register owns its two write enables. Lane one wins a
  // same-destination collision, matching forwarding and the original port order.
  genvar physical;
  generate for(physical=0;physical<PREG_N;physical=physical+1)begin:gen_physical_write
    localparam [PREG_W-1:0] PHYSICAL=physical;
    wire hit0=wb_write_i[0] && wb_preg_i[0+:PREG_W]==PHYSICAL;
    wire hit1=wb_write_i[1] && wb_preg_i[PREG_W+:PREG_W]==PHYSICAL;
    wire fg0=hit0 && wb_fp_i[0],fg1=hit1 && wb_fp_i[1];
    wire gg0=hit0 && !wb_fp_i[0] && physical!=0;
    wire gg1=hit1 && !wb_fp_i[1] && physical!=0;
    wire [63:0] fnext=({64{fg0&&!fg1}}&wb_data_i[0+:64])|({64{fg1}}&wb_data_i[64+:64]);
    wire [63:0] gnext=({64{gg0&&!gg1}}&wb_data_i[0+:64])|({64{gg1}}&wb_data_i[64+:64]);
    always @(posedge clk)begin
      if(rst)begin finit_q[physical]<=0;ginit_q[physical]<=0;end
      else begin
        if(fg0||fg1)begin fpr_q[physical]<=fnext;finit_q[physical]<=1;end
        if(gg0||gg1)begin gpr_q[physical]<=gnext;ginit_q[physical]<=1;end
      end
    end
  end endgenerate
  integer lane,terminal_slot;
  always @(posedge clk) begin
    if(rst) begin
      terminal_head_q<=0;terminal_tail_q<=0;terminal_dead_q<=0;
      terminal_count_q[0]<=0;terminal_count_q[1]<=0;
      ingress_valid_q<=0;operand_ready_q<=0;
    end else begin
      for(terminal_slot=0;terminal_slot<4;terminal_slot=terminal_slot+1)
        if(cancel_selected(tag_q[terminal_slot][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i))terminal_dead_q[terminal_slot]<=1;
      for(lane=0;lane<2;lane=lane+1) begin
        if(flush_i)begin
          terminal_head_q[lane]<=0;terminal_tail_q[lane]<=0;terminal_count_q[lane]<=0;
          terminal_dead_q[lane*2+:2]<=0;ingress_valid_q[lane]<=0;operand_ready_q[lane]<=0;end
        else begin
          terminal_count_q[lane]<=terminal_count_q[lane]+{1'b0,transfer_w[lane]}-{1'b0,terminal_pop_w[lane]};
          if(terminal_pop_w[lane])terminal_head_q[lane]<=~terminal_head_q[lane];
          if(transfer_w[lane])begin
            terminal_tail_q[lane]<=~terminal_tail_q[lane];
            terminal_dead_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=cancel_selected(ingress_tag_q[lane][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i);
            tag_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=ingress_tag_q[lane];payload_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=ingress_payload_q[lane];
            class_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=ingress_class_q[lane];gpr_dst_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=ingress_dst_q[lane];
            mem_slot_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=ingress_mem_slot_q[lane];
            alu_control_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=alu_control_w[lane];
            add_source_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=add_source_w[lane];
            shift_amount_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=operand_ready_q[lane] ?
                ingress_shift_amount_q[lane]:read_shift_amount_w[lane];
            branch_imm_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=branch_imm_w[lane];branch_control_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=branch_control_w[lane];
            operand_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=operand_ready_q[lane]?ingress_operand_q[lane]:
                read_operand_w[lane*320+:320];
            operand_fp_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=operand_ready_q[lane]?ingress_operand_fp_q[lane]:read_fp_w[lane*3+:3];
            operand_used_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=operand_ready_q[lane]?ingress_operand_used_q[lane]:read_used_w[lane*3+:3];
            operand_rank_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=operand_ready_q[lane]?ingress_operand_rank_q[lane]:read_rank_w[lane*6+:6];
            forward_hit_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=operand_ready_q[lane]?ingress_forward_hit_q[lane]:
                read_forward_hit_w[lane*12+:12];
            forward_data_q[lane*2+{31'b0,terminal_tail_q[lane]}]<=operand_ready_q[lane]?ingress_forward_data_q[lane]:gpr_forward_data_w;
          end
          if(!ingress_live_w[lane]||transfer_w[lane])begin
            ingress_valid_q[lane]<=0;operand_ready_q[lane]<=0;
          end else if(read_select_w[lane])begin
            ingress_shift_amount_q[lane]<=read_shift_amount_w[lane];
            operand_ready_q[lane]<=1;ingress_operand_q[lane]<=read_operand_w[lane*320+:320];
            ingress_operand_fp_q[lane]<=read_fp_w[lane*3+:3];
            ingress_operand_used_q[lane]<=read_used_w[lane*3+:3];
            ingress_operand_rank_q[lane]<=read_rank_w[lane*6+:6];
            ingress_forward_hit_q[lane]<=read_forward_hit_w[lane*12+:12];
            ingress_forward_data_q[lane]<=gpr_forward_data_w;
          end
          if(in_fire_i[lane])begin
            // Issue already qualifies a new owner; held owners retain cancellation.
            ingress_valid_q[lane]<=PREQUALIFIED_ISSUE!=0 ? 1'b1 : !cancel_selected(in_tag_i[lane*TAG_W+:ROB_W],cancel_candidates_i,kill_mask_i,cancel_active_i);
            operand_ready_q[lane]<=0;
            ingress_tag_q[lane]<=in_tag_i[lane*TAG_W+:TAG_W];
            ingress_payload_q[lane]<=in_payload_i[lane*PAYLOAD_W+:PAYLOAD_W];
            ingress_class_q[lane]<=in_class_i[lane*3+:3];
            ingress_mem_slot_q[lane]<=in_mem_slot_i[lane*LSQ_W+:LSQ_W];
            ingress_dst_q[lane]<=in_gpr_dst_i[lane*PREG_W+:PREG_W];
            ingress_src_q[lane]<=in_src_preg_i[lane*3*PREG_W+:3*PREG_W];
            ingress_fp_q[lane]<=in_src_fp_i[lane*3+:3];
            ingress_used_q[lane]<=in_src_used_i[lane*3+:3];
          end
        end
      end
    end
  end
`ifdef R64_ASSERT
  // Preserve the original admission predicate as an independent shadow.
  // An already-held owner's later cancellation remains unchanged.
  reg [1:0] ingress_valid_shadow_q;
  integer qualified_lane;
  always @(posedge clk)begin
    if(rst||flush_i)ingress_valid_shadow_q<=0;
    else for(integer q=0;q<2;q=q+1)begin
      if(!ingress_live_w[q]||transfer_w[q])ingress_valid_shadow_q[q]<=0;
      if(in_fire_i[q])ingress_valid_shadow_q[q]<=!kill_mask_i[in_tag_i[q*TAG_W+:ROB_W]];
    end
    if(PREQUALIFIED_ISSUE!=0)for(qualified_lane=0;qualified_lane<2;qualified_lane=qualified_lane+1)
      if(in_fire_i[qualified_lane]&&(rst||flush_i||
          kill_mask_i[in_tag_i[qualified_lane*TAG_W+:ROB_W]]))
        $fatal(1,"R64 RR prequalified Issue fire was cancelled");
  end
  always @(negedge clk)if(!rst&&PREQUALIFIED_ISSUE!=0)
    if(ingress_valid_q!==ingress_valid_shadow_q)
      $fatal(1,"R64 RR qualified admission differs from original predicate");

  integer serial_owner_count,serial_lane,serial_entry;
  // Occupancy is exact even when pop and replacement occur at the same edge:
  // both payload selection and this invariant refer to pre-edge terminal Q.
  always @(*)begin
    serial_owner_count=0;
    for(serial_lane=0;serial_lane<2;serial_lane=serial_lane+1)begin
      if(ingress_valid_q[serial_lane]&&ingress_class_q[serial_lane]==3'd5)
        serial_owner_count=serial_owner_count+1;
      for(serial_entry=0;serial_entry<2;serial_entry=serial_entry+1)
        if((terminal_count_q[serial_lane]==2||
            (terminal_count_q[serial_lane]==1&&terminal_head_q[serial_lane]==serial_entry[0]))&&
           !terminal_dead_q[serial_lane*2+serial_entry]&&class_q[serial_lane*2+serial_entry]==3'd5)
          serial_owner_count=serial_owner_count+1;
    end
  end
  always @(posedge clk)if(!rst&&UNIQUE_SERIAL!=0&&serial_owner_count>1)
    $fatal(1,"RR ingress and terminal Serial owners are not unique");

  // Verification shadow only: every live output keeps the slot that entered
  // with its fulltag. The actual reservation state resides solely in the LSQ.
  reg [TAG_W-1:0] observed_tag_q[0:(1<<ROB_W)-1];
  reg [LSQ_W-1:0] observed_slot_q[0:(1<<ROB_W)-1];
  integer slot_check;
  always @(posedge clk)if(!rst&&!flush_i)begin
    for(slot_check=0;slot_check<2;slot_check=slot_check+1)begin
      if(in_fire_i[slot_check]&&in_class_i[slot_check*3+:3]==3'd4)begin
        observed_tag_q[in_tag_i[slot_check*TAG_W+:ROB_W]]<=in_tag_i[slot_check*TAG_W+:TAG_W];
        observed_slot_q[in_tag_i[slot_check*TAG_W+:ROB_W]]<=in_mem_slot_i[slot_check*LSQ_W+:LSQ_W];
      end
      if(out_valid_o[slot_check]&&out_class_o[slot_check*3+:3]==3'd4&&
          !cancel_selected(out_tag_o[slot_check*TAG_W+:ROB_W],cancel_candidates_i,kill_mask_i,cancel_active_i)&&
          (observed_tag_q[out_tag_o[slot_check*TAG_W+:ROB_W]]!=out_tag_o[slot_check*TAG_W+:TAG_W]||
           observed_slot_q[out_tag_o[slot_check*TAG_W+:ROB_W]]!=out_mem_slot_o[slot_check*LSQ_W+:LSQ_W]))
        $fatal(1,"R64 RR LSQ slot separated from canonical fulltag");
    end
  end
  reg [1:0] prior_admit_q;
  always @(posedge clk)begin
    if(rst||flush_i)prior_admit_q<=0;else prior_admit_q<=in_fire_i;
    if(!rst&&!flush_i&&(read_select_w&~prior_admit_q)!=0)
      $fatal(1,"R64 physical read retried beyond its admission bundle");
  end
  integer mem_owner_check;
  always @(posedge clk)if(!rst&&!flush_i)begin
    for(mem_owner_check=0;mem_owner_check<2;mem_owner_check=mem_owner_check+1)begin
      if(in_fire_i[mem_owner_check]&&ingress_live_w[mem_owner_check]&&!transfer_w[mem_owner_check])
        $fatal(1,"R64 register read live ingress overwritten");
      if(terminal_count_q[mem_owner_check]>2)
        $fatal(1,"R64 register read terminal overflow");
    end
  end
  integer forward_a,forward_b;
  always @(posedge clk)if(!rst&&!flush_i)begin
    for(forward_a=0;forward_a<4;forward_a=forward_a+1)
      for(forward_b=forward_a+1;forward_b<4;forward_b=forward_b+1)
        if(gpr_forward_valid_w[forward_a]&&gpr_forward_valid_w[forward_b]&&
            gpr_forward_preg_w[forward_a*PREG_W+:PREG_W]!=0&&
            gpr_forward_preg_w[forward_a*PREG_W+:PREG_W]==gpr_forward_preg_w[forward_b*PREG_W+:PREG_W]&&
            gpr_forward_data_w[forward_a*64+:64]!=gpr_forward_data_w[forward_b*64+:64])
          $fatal(1,"R64 two forwarding stages disagree on a live physical value");
  end

  always @(posedge clk) if(!rst) begin
    if((in_fire_i&~in_ready_o)!=0) $fatal(1,"R64 register read overwritten while held");
    if(fp_ports>3) $fatal(1,"R64 FPR read budget exceeded");
    for(lane=0;lane<2;lane=lane+1)
      if(in_fire_i[lane]&&in_src_used_i[lane*3+2]&&!in_src_fp_i[lane*3+2])
        $fatal(1,"R64 third GPR read requested");
  end
`endif
`ifdef R64_ASSERT
  generate if(PREPARED_CANCEL)begin:gen_cancel_contract
    always @(posedge clk)if(!rst)
      if(kill_mask_i!==({(1<<ROB_W){cancel_active_i}}&cancel_candidates_i))
        $fatal(1,"prepared cancellation does not match canonical kill mask");
  end endgenerate
`endif
endmodule
