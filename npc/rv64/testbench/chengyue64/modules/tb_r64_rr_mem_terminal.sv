
`timescale 1ns/1ps
`include "R64Dispatch.vh"
module tb_r64_rr_mem_terminal #(parameter MEM_TERMINAL_CURRENT=1, PREPARED_CANCEL=1);
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
  R64RegRead #(.PAYLOAD_W(U),.LATE_OPERANDS(1),.LOAD_RESOLVED_VALUE(1),.ALU_TOKEN_BYPASS(1),.Q_ONLY_TERMINAL(1),
    .SPLIT_VALUE_VALID(1),.ALU_TERMINAL_BYPASS(1),
    .MEM_TERMINAL_CURRENT(MEM_TERMINAL_CURRENT),.PREPARED_CANCEL(PREPARED_CANCEL)) dut (
    .alu_token_valid_i(token_valid), .alu_token_resident_i(token_resident),
    .alu_token_preg_i(token_preg), .alu_token_data_i(token_data),
    .resolved_value_valid_i(memory_valid), .resolved_value_preg_i(memory_preg), .resolved_value_data_i(memory_data),
    .out_local_alu_valid_o(local_alu_valid),
    .alu_bypass_resident_i(alu_resident),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(|kill),
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
  integer checks=0;
  task check; input yes;input [511:0] why;begin checks=checks+1;if(yes!==1'b1)$fatal(1,"%0s",why);end endtask
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


  integer target,kind;
  initial begin
    for(integer n=0;n<512;n=n+1)begin expected_a[n]=0;expected_b[n]=0;end
    step();rst=0;classes={`R64_C_MEM,`R64_C_MEM};
    // Address+data require independent certificates. One current token cannot
    // discharge the second pending source, even when memory/WB presents it.
    put_pair(1,10,11,3,101,202);step();
    token_valid=1;token_resident=1;token_preg=10;token_data=101;#1;
    check(valid==0,"one ready operand released two-source MEM");
    memory_valid=1;memory_preg=11;memory_data=202;#1;
    check(valid==0,"memory notice reached current MEM readiness");
    step();memory_valid=0;token_valid=0;token_resident=0;drain(2);
    put_pair(3,12,13,3,303,404);step();
    token_valid=1;token_resident=1;token_preg=12;token_data=303;
    wb=1;wb_preg=13;wb_data=404;#1;
    check(valid==0,"canonical WB bypassed the pending register");
    step();token_valid=0;token_resident=0;wb=0;drain(4);
    // Both current sources from different lanes of token/head complete all
    // operands. MEM alone gets this valid; off remains original Q capture.
    put(0,5,14,15,3,505,606);step();put(1,6,16,17,3,707,808);step();
    alu_valid=3;alu_resident=3;alu_preg={6'd17,6'd14};alu_data={64'd808,64'd505};
    token_valid=3;token_resident=3;token_preg={6'd16,6'd15};token_data={64'd707,64'd606};
    #1;check(valid==(MEM_TERMINAL_CURRENT?3:0)&&local_alu_valid==0,
             "MEM current readiness or class boundary incorrect");
    out_ready=3;step();
    check(count==(MEM_TERMINAL_CURRENT?6:4),"current MEM real consumption edge");
    alu_valid=0;alu_resident=0;token_valid=0;token_resident=0;
    drain(6);
    // An uncertified raw head keeps the fixed wide priority over a certified
    // same-preg token. Local capture may resolve next cycle, never re-route now.
    put_pair(7,18,0,1,909,0);step();
    alu_resident=1;alu_valid=0;alu_preg=18;alu_data=64'hbad;
    token_resident=1;token_valid=1;token_preg=18;token_data=909;#1;
    check(valid==0,"stale raw head re-routed via current authorization");
    step();alu_resident=0;token_resident=0;token_valid=0;drain(8);
    // Current valid with downstream stall captures the pulse. Changed raw
    // payloads cannot replace the held owner value after the capture edge.
    put_pair(9,19,20,3,1001,1102);step();
    token_resident=3;token_valid=3;token_preg={6'd20,6'd19};token_data={64'd1102,64'd1001};#1;
    check(valid==(MEM_TERMINAL_CURRENT?3:0),"dual pending token certificate");
    step();token_resident=0;token_valid=0;token_data=~128'b0;
    repeat(5)begin step();check(valid==3&&operands[0+:128]=={64'd1102,64'd1001},
             "backpressure lost captured current value");end
    drain(10);
    // Kill/flush do not make an accepted effect: RR cancels local holders,
    // while Execute is responsible for suppressing same-cycle raw offers.
    put_pair(11,21,0,1,1203,0);step();
    kill=32'h1800;token_resident=1;token_valid=1;token_preg=21;token_data=1203;
    step();step();kill=0;token_resident=0;token_valid=0;
    out_ready=3;repeat(4)step();out_ready=0;
    check(count==10&&!seen[11]&&!seen[12],"killed MEM reappeared");
    put_pair(43,21,0,1,1304,0);step();check(valid==0,"reused tag/preg saw old result");
    token_resident=1;token_valid=1;token_preg=21;token_data=1304;step();
    token_resident=0;token_valid=0;drain(12);
    put_pair(45,22,0,1,1405,0);step();flush=1;step();flush=0;
    token_resident=1;token_valid=1;token_preg=22;token_data=1405;step();
    token_resident=0;token_valid=0;out_ready=3;repeat(4)step();out_ready=0;
    check(count==12&&!seen[45]&&!seen[46],"flushed MEM reappeared");
    // A MEM at lane head keeps the FIFO boundary. No independent ALU may
    // cross it; once resolved both owners drain through distinct handshakes.
    put_pair(47,23,0,1,1506,0);step();classes=0;
    put_pair(49,0,0,0,0,0);step();out_ready=3;
    repeat(3)begin step();check(valid==0&&out_tag=={9'd48,9'd47},
      "following ALU crossed unresolved MEM");end
    token_resident=1;token_valid=1;token_preg=23;token_data=1506;step();
    token_resident=0;token_valid=0;drain(16);
    // MDU, FP and serial retain their original Q-only numeric readiness.
    for(kind=2;kind<=5;kind=kind+1)if(kind!=4)begin
      classes={3'(kind),3'(kind)};
      put_pair(60+2*kind,24,0,1,1607,0);step();
      token_resident=1;token_valid=1;token_preg=24;token_data=1607;
      #1;check(valid==0,"MEM option widened other shared-resource class");
      step();token_resident=0;token_valid=0;drain(count+2);
    end
    $display("[PASS] tb_r64_rr_mem_terminal enabled=%0d prepared_cancel=%0d checks=%0d transfers=%0d mixed_WB_MEM_Qonly=1 fixed_raw_selection=1 stall_cancel_reuse=1",
      MEM_TERMINAL_CURRENT,PREPARED_CANCEL,checks,count);$finish;
  end
endmodule
