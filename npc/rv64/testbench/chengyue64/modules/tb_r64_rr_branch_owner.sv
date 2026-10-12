
`timescale 1ns/1ps
`include "R64Dispatch.vh"
module tb_r64_rr_branch_owner #(parameter BRANCH_ADMIT=1, PREPARED_CANCEL=1, MASTER_ADMIT=1);
  localparam RR_COMPLETE_ADMIT=MASTER_ADMIT;
  localparam U=`R64_UOP_W;
  reg clk=0; always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] kill=0;
  reg [1:0] fire=0, out_ready=0, wb=0, alu_valid=0, alu_resident=0;
  reg [1:0] memory_valid=0, token_valid=0, token_resident=0;
  reg [11:0] token_preg=0;
  reg [127:0] token_data=0;
  reg [11:0] memory_preg=0;
  reg [127:0] memory_data=0;
  wire [1:0] credit,valid,registered_valid,local_alu_valid;
  assign valid=registered_valid|local_alu_valid;
  reg [5:0] classes=0,source_fp=0;
  reg [1:0] wb_fp=0;
  wire [51:0] fp_plan;
  for(genvar l=0;l<2;l=l+1)begin: plans
    R64FpReadCompact plan(.preg_i(source[l*18+:18]),.used_i(used[l*3+:3]),
      .fp_i(source_fp[l*3+:3]),.plan_o(fp_plan[l*26+:26]));
  end
  reg [17:0] tag=0;
  reg [2*U-1:0] payload=0;
  reg [35:0] source=0;
  reg [5:0] used=0,pending=0;
  reg [11:0] wb_preg=0,alu_preg=0;
  reg [127:0] wb_data=0,alu_data=0;
  wire [17:0] out_tag;
  wire [383:0] operands;
  wire [11:0] shift;
  wire [9:0] unused_slot,unused_add,unused_branch_ctrl;
  wire [2*U-1:0] unused_payload;
  wire [5:0] unused_class;
  wire [11:0] unused_dst;
  wire [73:0] unused_control;
  wire [41:0] unused_branch;
  wire [1:0] execute_ready;
  R64RegRead #(.PAYLOAD_W(U),.LATE_OPERANDS(1),.LOAD_RESOLVED_VALUE(1),.ALU_TOKEN_BYPASS(1),.Q_ONLY_TERMINAL(1),
    .SPLIT_VALUE_VALID(1),.ALU_TERMINAL_BYPASS(1),.MEM_TERMINAL_CURRENT(1),
    .RR_COMPLETE_ADMIT(RR_COMPLETE_ADMIT),.RR_COMPLETE_BRANCH_ADMIT(BRANCH_ADMIT),
    .RR_ADMIT_GPR_READ(1),.PREPARED_CANCEL(PREPARED_CANCEL),
    .COMPACT_FP(1),.RAW_FP_ALLOCATION(1)) dut (
    .alu_token_valid_i(token_valid), .alu_token_resident_i(token_resident),
    .alu_token_preg_i(token_preg), .alu_token_data_i(token_data),
    .resolved_value_valid_i(memory_valid), .resolved_value_preg_i(memory_preg), .resolved_value_data_i(memory_data),
    .out_local_alu_valid_o(local_alu_valid),
    .alu_bypass_resident_i(alu_resident),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(|kill),
    .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.in_mem_slot_i(10'b0),
    .in_payload_i(payload),.in_class_i(classes),.in_gpr_dst_i(12'b0),
    .in_src_preg_i(source),.in_src_fp_i(source_fp),.in_src_used_i(used),
    .in_src_pending_i(pending),.in_fp_plan_i(fp_plan),
    .wb_write_i(wb),.wb_fp_i(wb_fp),.wb_preg_i(wb_preg),.wb_data_i(wb_data),
    .alu_bypass_valid_i(alu_valid),.alu_bypass_preg_i(alu_preg),.alu_bypass_data_i(alu_data),
    .fu_credit_i(6'b111111),
    .out_valid_o(registered_valid),.out_ready_i(execute_ready),.out_tag_o(out_tag),
    .out_operand_o(operands),.out_shift_amount_o(shift),
    .out_mem_slot_o(unused_slot),.out_payload_o(unused_payload),.out_class_o(unused_class),
    .out_gpr_dst_o(unused_dst),.out_alu_control_o(unused_control),
    .out_add_source_o(unused_add),.out_branch_imm_o(unused_branch),
    .out_branch_control_o(unused_branch_ctrl)
  );

  wire resolve_valid,redirect_valid;
  wire [8:0] resolve_tag;
  wire [63:0] resolve_npc,resolve_pc;
  wire [4:0] result_valid;
  wire [44:0] result_tag;
  wire [5*`R64_RESULT_W-1:0] result_data;
  wire [1:0] mem_fire;
  wire [17:0] mem_tag;
  // Endpoint availability is held low to exercise RR payload retention. RR
  // pops only the exact accepted event from the real Execute instance.
  R64Execute #(.PREPARED_CANCEL(PREPARED_CANCEL),.SPLIT_VALUE_VALID(1),.DIRECT_MEM_BIND(1)) execute(
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(|kill),.rob_head_i(5'd0),
    .in_valid_i(registered_valid & out_ready),.in_local_alu_valid_i(local_alu_valid & out_ready),
    .in_ready_o(execute_ready),.in_tag_i(out_tag),.in_mem_slot_i(unused_slot),
    .in_uop_i(unused_payload),.in_class_i(unused_class),.in_operand_i(operands),
    .in_gpr_dst_i(unused_dst),.in_alu_control_i(unused_control),.in_add_source_i(unused_add),
    .in_shift_amount_i(shift),.in_branch_imm_i(unused_branch),.in_branch_control_i(unused_branch_ctrl),
    .result_valid_o(result_valid),.result_ready_i(5'b11111),.result_tag_o(result_tag),.result_o(result_data),
    .resolve_valid_o(resolve_valid),.resolve_tag_o(resolve_tag),.resolve_npc_o(resolve_npc),
    .resolve_pc_o(resolve_pc),.redirect_valid_o(redirect_valid),
    .lsu_ready_i(2'b11),.lsu_fire_o(mem_fire),.lsu_tag_o(mem_tag),
    .fp_ready_i(1'b1),.serial_ready_i(1'b1));
  integer cycle=0,checks=0,actual=0,fallback=0,full_fallback=0,hold_cycles=0;
  integer executed[0:511],resolved[0:511],exec_lane[0:511],result_count[0:511];
  reg [63:0] expected_npc[0:511],expected_link[0:511];
  reg [U-1:0] expected_uop[0:511];
  reg [63:0] expected_a[0:511],expected_b[0:511];
  reg [511:0] expected_valid=0;
  always @(posedge clk)begin
    cycle+=1;
    if(!rst&&!flush)begin
      for(integer l=0;l<2;l+=1)begin
        if(fire[l])begin
          if(dut.direct_admit_w[l])actual+=1;else fallback+=1;
          if(dut.terminal_count_q[l]==2&&dut.terminal_pop_w[l])begin
            if(dut.direct_admit_w[l])$fatal(1,"branch borrowed same-edge pop credit");
            full_fallback+=1;
          end
        end
        if(valid[l]&&!execute_ready[l])hold_cycles+=1;
        if(execute_ready[l])begin
          if(!expected_valid[out_tag[l*9+:9]])$fatal(1,"unexpected RR branch owner");
          if(executed[out_tag[l*9+:9]]>=0)$fatal(1,"duplicate Execute");
          executed[out_tag[l*9+:9]]=cycle;exec_lane[out_tag[l*9+:9]]=l;
          if(unused_payload[l*U+:U]!==expected_uop[out_tag[l*9+:9]] ||
             operands[l*192+:64]!==expected_a[out_tag[l*9+:9]] ||
             operands[l*192+64+:64]!==expected_b[out_tag[l*9+:9]])
             $fatal(1,"branch operand/control owner changed under stall");
        end
      end
      if(resolve_valid)begin
        if(resolved[resolve_tag]>=0)$fatal(1,"duplicate resolve");
        resolved[resolve_tag]=cycle;
        if(resolve_npc!==expected_npc[resolve_tag])$fatal(1,"wrong branch target tag=%0d npc=%h expected=%h",
          resolve_tag,resolve_npc,expected_npc[resolve_tag]);
      end
      for(integer l=0;l<5;l+=1)if(result_valid[l])begin
        result_count[result_tag[l*9+:9]]+=1;
        if(result_data[l*`R64_RESULT_W+:64]!==expected_link[result_tag[l*9+:9]])
          $fatal(1,"branch result lost original PC/length link");
      end
    end
  end
  task tick;begin @(posedge clk);#1;@(negedge clk);end endtask
  task check(input yes,input[511:0] why);begin checks+=1;if(yes!==1'b1)$fatal(1,"%0s",why);end endtask
  task clean;
    begin
      rst=1;flush=0;kill=0;fire=0;out_ready=0;wb=0;memory_valid=0;token_valid=0;token_resident=0;
      alu_valid=0;alu_resident=0;source_fp=0;expected_valid=0;tick();rst=0;tick();
      for(integer i=0;i<512;i+=1)begin executed[i]=-1;resolved[i]=-1;exec_lane[i]=-1;result_count[i]=0;end
    end
  endtask
  task prepare(input integer lane,id,input [63:0] pc,input integer off,len,
               input [63:0] va,vb,input [2:0] pending_bits);
    reg [31:0] inst;reg [U-1:0] u;
    begin
      inst={12'(off),5'd1,3'b0,5'd0,7'h67};u=0;u[`R64_U_PC]=pc;u[`R64_U_ARG]=pc+64'(len);
      u[`R64_U_CMD]={32'hbed01234,inst};u[`R64_U_LEN]=4'(len);
      u[`R64_U_FUNC]=`R64_F_SRA;u[`R64_U_FLAGS]=8'h0f;
      tag[lane*9+:9]=9'(id);payload[lane*U+:U]=u;classes[lane*3+:3]=`R64_C_BRANCH;
      source[lane*18+:18]={6'b0,6'd33,6'd32};used[lane*3+:3]=3'b001;
      pending[lane*3+:3]=pending_bits;expected_valid[id]=1;expected_uop[id]=u;
      expected_a[id]=va;expected_b[id]=0;
      expected_npc[id]=(va+64'(off))&~64'd1;expected_link[id]=pc+64'(len);
    end
  endtask
  task accept(input [1:0] mask);
    begin fire=mask;#1;check((credit&mask)==mask,"branch RR credit");tick();fire=0;end
  endtask
  task drain(input integer id);
    integer n;
    begin out_ready=3;n=0;while(resolved[id]<0&&n<30)begin tick();n+=1;end
      check(resolved[id]>=0,"branch failed to drain to real Execute");repeat(2)tick();end
  endtask
  integer before_actual,before_fallback,id,mode;
  initial begin
    // Both complete branch packets are held, then their actual Execute
    // arbitration observes reverse physical-lane age.
    clean();memory_valid=1;memory_preg=32;memory_data=64'h90001001;
    prepare(0,8,64'h80001000,6,4,64'h90001001,0,1);
    prepare(1,3,64'h80002000,-6,2,64'h90001001,0,1);accept(3);
    memory_valid=0;payload=0;tag=0;source=0;repeat(4)tick();
    check(executed[3]<0&&executed[8]<0,"held branches executed without endpoint acceptance");
    drain(8);check(executed[3]<executed[8]&&exec_lane[3]==1&&exec_lane[8]==0,"reversed branch ages ignored");

    // Full Q cannot borrow the same edge's pop for direct allocation.
    clean();memory_valid=1;memory_preg=32;memory_data=64'h80003001;
    prepare(0,1,64'h80001000,2,4,64'h80003001,0,1);accept(1);repeat(2)tick();
    prepare(0,2,64'h80001004,4,2,64'h80003001,0,1);accept(1);repeat(2)tick();
    check(dut.terminal_count_q[0]==2,"fixture failed to fill branch terminal Q");
    prepare(0,3,64'h80001006,-2,4,64'h80003001,0,1);out_ready=3;accept(1);
    memory_valid=0;drain(3);
    check(executed[1]<executed[2]&&executed[2]<executed[3],"full Q fallback reordered branches");

    // Missing a genuinely pending source forces original ingress even with an
    // initialized stale PRF value. The actual WB arrival then repairs it.
    clean();wb=3;wb_preg={6'd33,6'd32};wb_data={64'd99,64'd55};tick();wb=0;
    prepare(0,4,64'h80001000,8,4,64'h80004001,0,1);
    before_actual=actual;accept(1);check(actual==before_actual,"pending source guessed from initialized PRF");
    repeat(3)tick();check(!valid[0],"pending branch became ready without a value");
    wb=1;wb_preg=32;wb_data=64'h80004001;tick();wb=0;drain(4);


    // One current memory value plus one pending source is incomplete; the
    // ready-PRF option cannot infer that second source from initialized data.
    clean();wb=1;wb_preg=33;wb_data=99;tick();wb=0;
    prepare(0,9,64'h80003000,8,4,10,10,3);
    payload[`R64_U_CMD]={32'hcafef00d,32'h00208463};used[2:0]=3;expected_uop[9]=payload[0+:U];
    expected_b[9]=10;expected_npc[9]=64'h80003008;
    memory_valid=1;memory_preg=32;memory_data=10;
    before_actual=actual;accept(1);memory_valid=0;check(actual==before_actual,"partial branch packet bypassed ingress");
    repeat(3)tick();check(!valid[0],"second pending branch source was guessed");
    wb=1;wb_preg=33;wb_data=10;tick();wb=0;drain(9);

    // Complete mixed current-notice and canonically ready PRF values.
    clean();wb=1;wb_preg=33;wb_data=10;tick();wb=0;
    prepare(0,10,64'h80004000,8,2,10,10,1);
    payload[`R64_U_CMD]={32'hcafef00d,32'h00208463};used[2:0]=3;expected_uop[10]=payload[0+:U];
    expected_b[10]=10;expected_npc[10]=64'h80004008;
    memory_valid=1;memory_preg=32;memory_data=10;
    before_actual=actual;accept(1);memory_valid=0;
    check(actual-before_actual==((BRANCH_ADMIT&&MASTER_ADMIT)?1:0),"mixed complete PRF/current branch admission");
    drain(10);

    // Current real WB overrides old PRF on complete input admission.
    clean();wb=1;wb_preg=32;wb_data=64'h1111;tick();wb=0;
    prepare(0,5,64'h80002000,-2,2,64'h80005003,0,0);
    wb=1;wb_preg=32;wb_data=64'h80005003;accept(1);wb=0;drain(5);

    // Kill and flush held complete packets, then reuse the exact ROB slot
    // under a new full tag and different source value.
    for(mode=0;mode<2;mode+=1)begin
      clean();memory_valid=1;memory_preg=32;memory_data=64'h80006001;
      prepare(0,6,64'h80002000,4,4,64'h80006001,0,1);accept(1);memory_valid=0;
      repeat(3)tick();if(mode==0)kill=32'h40;else flush=1;
      out_ready=3;tick();kill=0;flush=0;repeat(3)tick();
      check(executed[6]<0&&resolved[6]<0&&result_count[6]==0,"cancelled branch published an effect");
      out_ready=0;memory_valid=1;memory_data=64'h80007001;
      prepare(0,38,64'h80003000,-4,2,64'h80007001,0,1);accept(1);memory_valid=0;drain(38);
    end
    check(full_fallback>0&&hold_cycles>0,"branch Q/stall coverage gap");
    if(BRANCH_ADMIT&&MASTER_ADMIT)check(actual>0,"branch direct coverage absent");
    else check(actual==0,"branch independent/master OFF admitted directly");
    $display("[PASS] tb_r64_rr_branch_owner branch=%0d master=%0d prepared_cancel=%0d checks=%0d direct=%0d fallback=%0d full_fallback=%0d hold=%0d",
      BRANCH_ADMIT,MASTER_ADMIT,PREPARED_CANCEL,checks,actual,fallback,full_fallback,hold_cycles);
    $finish;
  end
endmodule
