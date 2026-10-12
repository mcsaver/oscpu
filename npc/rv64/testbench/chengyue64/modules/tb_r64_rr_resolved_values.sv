
`timescale 1ns/1ps
`include "R64Dispatch.vh"
module tb_r64_rr_resolved_values;
  localparam U=`R64_UOP_W;
  reg clk=0; always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] kill=0;
  reg [1:0] fire=0, out_ready=0, wb=0, alu_valid=0, alu_resident=0;
  reg [1:0] memory_valid=0;
  reg [11:0] memory_preg=0;
  reg [127:0] memory_data=0;
  wire [1:0] credit,valid,registered_valid,local_alu_valid;
  assign valid=registered_valid|local_alu_valid;
  reg [5:0] classes=0;
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
  R64RegRead #(.PAYLOAD_W(U),.LATE_OPERANDS(1),.LOAD_RESOLVED_VALUE(1),.Q_ONLY_TERMINAL(1),
    .SPLIT_VALUE_VALID(1),.ALU_TERMINAL_BYPASS(1)) dut (
    .resolved_value_valid_i(memory_valid), .resolved_value_preg_i(memory_preg), .resolved_value_data_i(memory_data),
    .out_local_alu_valid_o(local_alu_valid),
    .alu_bypass_resident_i(alu_resident),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(32'b0),.cancel_active_i(1'b0),
    .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.in_mem_slot_i(10'b0),
    .in_payload_i(payload),.in_class_i(classes),.in_gpr_dst_i(12'b0),
    .in_src_preg_i(source),.in_src_fp_i(6'b0),.in_src_used_i(used),
    .in_src_pending_i(pending),.in_fp_plan_i(52'b0),
    .wb_write_i(wb),.wb_fp_i(2'b0),.wb_preg_i(wb_preg),.wb_data_i(wb_data),
    .alu_bypass_valid_i(alu_valid),.alu_bypass_preg_i(alu_preg),.alu_bypass_data_i(alu_data),
    .fu_credit_i(6'b111111),
    .out_valid_o(registered_valid),.out_ready_i(out_ready),.out_tag_o(out_tag),
    .out_operand_o(operands),.out_shift_amount_o(shift),
    .out_mem_slot_o(unused_slot),.out_payload_o(unused_payload),.out_class_o(unused_class),
    .out_gpr_dst_o(unused_dst),.out_alu_control_o(unused_control),
    .out_add_source_o(unused_add),.out_branch_imm_o(unused_branch),
    .out_branch_control_o(unused_branch_ctrl)
  );
  reg [511:0] seen=0;
  reg [63:0] expected_a[0:511],expected_b[0:511];
  integer count=0, history_hold=0, history_transfer_refill=0;
  always @(posedge clk)
    if(!rst&&!flush) for(integer l=0;l<2;l=l+1) begin
      if(dut.read_select_w[l]&&|dut.ingress_history_hit_w[l]&&!dut.transfer_w[l])
        history_hold=history_hold+1;
      if(dut.transfer_w[l]&&fire[l]&&|dut.ingress_history_hit_w[l])
        history_transfer_refill=history_transfer_refill+1;
    end
  always @(posedge clk)
    if(!rst&&!flush) for(integer l=0;l<2;l=l+1)
      if(valid[l]&&out_ready[l]&&!kill[out_tag[l*9+:5]]) begin
        if(seen[out_tag[l*9+:9]]) $fatal(1,"duplicate RR owner");
        if(operands[l*192+:64]!==expected_a[out_tag[l*9+:9]] ||
           operands[l*192+64+:64]!==expected_b[out_tag[l*9+:9]] ||
           shift[l*6+:6]!==expected_b[out_tag[l*9+:9]][5:0])
          $fatal(1,"late value lost tag=%0d a=%h b=%h shift=%h expected=%h/%h",
             out_tag[l*9+:9],operands[l*192+:64],operands[l*192+64+:64],shift[l*6+:6],
             expected_a[out_tag[l*9+:9]],expected_b[out_tag[l*9+:9]]);
        seen[out_tag[l*9+:9]]=1;count=count+1;
      end
  task step; begin @(posedge clk);#1;@(negedge clk);end endtask
  task check; input yes;input [511:0] why;begin if(yes!==1'b1)$fatal(1,"%0s",why);end endtask
  task put;
    input integer lane,id,a,b,pbits;
    input [63:0] va,vb;
    begin
      expected_a[id]=va;expected_b[id]=vb;
      tag[lane*9+:9]=9'(id);source[lane*18+:18]={6'b0,6'(b),6'(a)};
      used[lane*3+:3]=3'b011;pending[lane*3+:3]=3'(pbits);
      fire=2'(1<<lane);#1;check(credit[lane],"RR ingress unavailable");
      step();fire=0;
    end
  endtask
  task put_pair;
    input integer id,a,b,pbits;
    input [63:0] va,vb;
    begin
      for(integer l=0;l<2;l=l+1) begin
        expected_a[id+l]=va;expected_b[id+l]=vb;
        tag[l*9+:9]=9'(id+l);source[l*18+:18]={6'b0,6'(b),6'(a)};
        used[l*3+:3]=3'b011;pending[l*3+:3]=3'(pbits);
      end
      fire=3;#1;check(credit==3,"dual RR ingress unavailable");step();fire=0;
    end
  endtask
  task write_one; input integer preg;input [63:0] value;begin
    wb=1;wb_preg={6'b0,6'(preg)};wb_data={64'b0,value};step();wb=0;
  end endtask
  task drain; input integer target;integer cycles;begin
    out_ready=3;cycles=0;
    while(count<target&&cycles<30)begin step();cycles=cycles+1;end
    check(count==target,"RR did not drain expected owners");out_ready=0;step();
  end endtask

  integer goal;
  initial begin
    for(integer n=0;n<512;n=n+1)begin expected_a[n]=0;expected_b[n]=0;end
    step();rst=0;
    if($test$plusargs("bad-memory-wb"))begin
      memory_valid=1;memory_preg=7;memory_data=1;
      wb=1;wb_preg=7;wb_data=2;step();
      $fatal(1,"conflicting WB/MEM value not rejected");
    end
    if($test$plusargs("bad-memory-alu"))begin
      memory_valid=1;memory_preg=7;memory_data=1;
      alu_valid=1;alu_preg=7;alu_data=2;step();
      $fatal(1,"conflicting ALU/MEM value not rejected");
    end
    if($test$plusargs("bad-memory-pair"))begin
      memory_valid=3;memory_preg={6'd7,6'd7};memory_data={64'd2,64'd1};step();
      $fatal(1,"conflicting paired MEM value not rejected");
    end
    // Both MEM sources are captured at admission; changed unqualified raw
    // buses one edge later cannot replace their history.
    memory_valid=3;memory_preg={6'd41,6'd40};memory_data={64'd202,64'd101};
    put_pair(1,40,41,3,101,202);memory_valid=0;memory_data=~128'b0;
    #1;check(dut.ingress_history_hit_w[0]==3&&dut.ingress_history_hit_w[1]==3,
             "MEM admission sample not certified");step();drain(2);
    // All six holders need A and B. A pulse fills only A; B may not become
    // current terminal fast readiness and must first cross its local register.
    write_one(42,64'hdead);write_one(43,64'hbeef);
    put_pair(10,42,43,3,303,404);step();put_pair(12,42,43,3,303,404);step();
    put_pair(14,42,43,3,303,404);step();
    check(dut.terminal_count_q[0]==2&&dut.terminal_count_q[1]==2&&
          dut.ingress_valid_q==3&&dut.operand_ready_q==3,"six-holder coverage");
    memory_valid=1;memory_preg=42;memory_data=303;step();memory_valid=0;
    repeat(4)begin step();check(valid==0,"one remaining operand escaped");end
    memory_valid=2;memory_preg={6'd43,6'b0};memory_data={64'd404,64'b0};#1;
    check(valid==0&&local_alu_valid==0,"MEM notice entered terminal combinational fast path");
    step();memory_valid=0;memory_data=0;repeat(3)step();drain(8);
    // Transfer+refill consumes the old sample while capturing the new sample.
    memory_valid=1;memory_preg=44;memory_data=505;put_pair(20,44,0,1,505,0);
    memory_valid=2;memory_preg={6'd45,6'b0};memory_data={64'd606,64'b0};
    check(dut.transfer_w==3,"old ingress transfer window");put_pair(22,45,0,1,606,0);
    memory_valid=0;memory_data=0;step();drain(12);
    // Admission with no valid pulse does not reuse an earlier memory history.
    memory_valid=1;memory_preg=46;memory_data=707;step();memory_valid=0;step();
    put_pair(24,46,0,1,808,0);step();repeat(3)begin step();check(valid==0,"old MEM event replayed");end
    write_one(46,808);drain(14);
    // First-read cancellation and flush scrub the numerical owner. New tags
    // reusing both slots and source preg must wait for a new qualified value.
    memory_valid=1;memory_preg=47;memory_data=909;put_pair(30,47,0,1,909,0);memory_valid=0;
    kill=32'hc0000000;step();step();kill=0;out_ready=3;repeat(3)step();out_ready=0;
    check(!seen[30]&&!seen[31]&&count==14,"cancelled MEM history escaped");
    put_pair(62,47,0,1,1001,0);step();check(valid==0,"reuse read old MEM history");
    memory_valid=1;memory_preg=47;memory_data=1001;step();memory_valid=0;drain(16);
    memory_valid=1;memory_preg=48;memory_data=1102;put_pair(64,48,0,1,1102,0);memory_valid=0;
    flush=1;step();flush=0;put_pair(96,48,0,1,1203,0);step();
    check(valid==0&&!seen[64]&&!seen[65],"flush exposed old MEM history");
    memory_valid=1;memory_preg=48;memory_data=1203;step();memory_valid=0;drain(18);
    // Duplicate authorized copies agree; WB still takes deterministic priority.
    memory_valid=3;memory_preg={6'd49,6'd49};memory_data={2{64'd1304}};
    wb=3;wb_preg={6'd49,6'd49};wb_data={2{64'd1304}};
    alu_valid=3;alu_resident=3;alu_preg={6'd49,6'd49};alu_data={2{64'd1304}};
    put_pair(100,49,0,1,1304,0);memory_valid=0;wb=0;alu_valid=0;alu_resident=0;
    step();drain(20);
    check(history_transfer_refill>=2,"transfer refill not covered");
    $display("[PASS] tb_r64_rr_resolved_values sources=6 holders=6 transfers=%0d history_refill=%0d",
             count,history_transfer_refill);$finish;
  end
endmodule
