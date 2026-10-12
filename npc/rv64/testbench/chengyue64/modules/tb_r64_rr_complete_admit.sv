
`timescale 1ns/1ps
`include "R64Dispatch.vh"
module tb_r64_rr_complete_admit #(parameter RR_COMPLETE_ADMIT=1, PREPARED_CANCEL=1);
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
  R64RegRead #(.PAYLOAD_W(U),.LATE_OPERANDS(1),.LOAD_RESOLVED_VALUE(1),.ALU_TOKEN_BYPASS(1),.Q_ONLY_TERMINAL(1),
    .SPLIT_VALUE_VALID(1),.ALU_TERMINAL_BYPASS(1),.MEM_TERMINAL_CURRENT(1),
    .RR_COMPLETE_ADMIT(RR_COMPLETE_ADMIT),.PREPARED_CANCEL(PREPARED_CANCEL),
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
    .out_valid_o(registered_valid),.out_ready_i(out_ready),.out_tag_o(out_tag),
    .out_operand_o(operands),.out_shift_amount_o(shift),
    .out_mem_slot_o(unused_slot),.out_payload_o(unused_payload),.out_class_o(unused_class),
    .out_gpr_dst_o(unused_dst),.out_alu_control_o(unused_control),
    .out_add_source_o(unused_add),.out_branch_imm_o(unused_branch),
    .out_branch_control_o(unused_branch_ctrl)
  );
  reg [511:0] seen=0;
  reg [63:0] expected_a[0:511],expected_b[0:511],expected_c[0:511];
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
           shift[l*6+:6]!==expected_b[out_tag[l*9+:9]][5:0] ||
           operands[l*192+128+:64]!==expected_c[out_tag[l*9+:9]])
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


  integer eligible=0,actual=0,fallback=0,pop_direct=0,full_pop_fallback=0,old_transfer_fallback=0;
  always @(posedge clk)if(!rst&&!flush)for(integer l=0;l<2;l=l+1)if(fire[l])begin
    if(dut.direct_eligible_w[l])eligible=eligible+1;
    if(dut.direct_admit_w[l])actual=actual+1;else fallback=fallback+1;
    if(dut.direct_admit_w[l]&&dut.terminal_pop_w[l])pop_direct=pop_direct+1;
    if(!dut.direct_admit_w[l]&&dut.terminal_pop_w[l]&&dut.terminal_count_q[l]==2)
      full_pop_fallback=full_pop_fallback+1;
    if(!dut.direct_admit_w[l]&&dut.transfer_w[l])old_transfer_fallback=old_transfer_fallback+1;
  end
  task fpwrite(input integer preg,input [63:0] value);
    begin wb_fp=1;write_one(preg,value);wb_fp=0;end
  endtask
  task clear_sources;
    begin wb=0;alu_valid=0;alu_resident=0;token_valid=0;token_resident=0;memory_valid=0;end
  endtask
  integer target;
  initial begin
    for(integer n=0;n<512;n=n+1)begin expected_a[n]=0;expected_b[n]=0;expected_c[n]=0;end
    step();rst=0;
    if($test$plusargs("bad-direct-conflict"))begin
      wb=1;wb_preg=10;wb_data=1;memory_valid=1;memory_preg=10;memory_data=2;
      put_pair(1,10,0,1,1,0);$fatal(1,"conflicting values escaped numerical assertion");
    end
    // Both lanes capture two real values at the same accepted edge, and no
    // direct owner performs a redundant physical read on the next edge.
    memory_valid=3;memory_preg={6'd11,6'd10};memory_data={64'd202,64'd101};
    put_pair(1,10,11,3,101,202);clear_sources();memory_data=~128'b0;
    check(dut.ingress_valid_q==(RR_COMPLETE_ADMIT?0:3)&&
          dut.read_select_w==(RR_COMPLETE_ADMIT?0:3),"direct owner destination/PRF skip");
    step();drain(2);
    // Mixed head/token/WB sources; WB is the deterministic highest selector.
    // Observe priority before the edge, then restore consistency for capture.
    wb=3;wb_preg={6'd12,6'd12};wb_data={64'd304,64'd303};
    token_valid=1;token_resident=1;token_preg=12;token_data=302;
    source={6'b0,6'b0,6'd12,6'b0,6'b0,6'd12};used=6'b001001;
    #1;check(dut.direct_value_w[0][63:0]==304,"WB1 did not retain highest capture priority");
    wb_data={2{64'd303}};token_data=303;
    alu_valid=1;alu_resident=1;alu_preg=13;alu_data=404;
    classes={`R64_C_MEM,`R64_C_ALU};
    put_pair(3,12,13,3,303,404);clear_sources();step();drain(4);
    // Missing one broadcast never reads PRF-ready as a current numerical value.
    write_one(14,505);memory_valid=1;memory_preg=15;memory_data=606;
    put_pair(5,14,15,2,505,606);
    check(dut.ingress_valid_q==3,"one missing real source did not fall back");
    clear_sources();step();drain(6);
    // No valid certificate on a resident raw head: only PRF fallback is legal.
    write_one(16,707);alu_resident=1;alu_valid=0;alu_preg=16;alu_data=64'hbad;
    put_pair(7,16,0,0,707,0);check(dut.ingress_valid_q==3,"raw candidate became certified input");
    alu_resident=0;step();drain(8);
    // Old ingress uses terminal write ports first, including transfer/refill.
    classes=0;write_one(17,808);put(0,9,17,0,0,808,0);
    wb=1;wb_preg=18;wb_data=909;
    put(0,10,18,0,1,909,0);clear_sources();
    check(dut.ingress_valid_q[0]&&dut.ingress_tag_q[0]==10,"old ingress was displaced by direct refill");
    step();drain(10);
    // One terminal owner pops while the newly accepted complete packet enters
    // its Q-empty tail. Both tags drain exactly once, preserving head order.
    wb=1;wb_preg=19;wb_data=1001;put(0,11,19,0,1,1001,0);clear_sources();step();
    out_ready=1;wb=1;wb_preg=20;wb_data=1102;
    put(0,12,20,0,1,1102,0);clear_sources();out_ready=0;
    check(seen[11]&&!seen[12],"pop/direct owner order");
    step();drain(12);
    // Full terminal cannot borrow the same-edge pop. A complete incoming
    // packet takes the unchanged ingress fallback, then transfers next edge.
    wb=1;wb_preg=21;wb_data=1203;put(0,13,21,0,1,1203,0);step();clear_sources();
    wb=1;wb_preg=22;wb_data=1304;put(0,14,22,0,1,1304,0);step();clear_sources();
    check(dut.terminal_count_q[0]==2&&!dut.ingress_valid_q[0],"terminal-full window absent");
    out_ready=1;wb=1;wb_preg=23;wb_data=1405;put(0,15,23,0,1,1405,0);
    clear_sources();out_ready=0;
    check(dut.ingress_valid_q[0]&&dut.ingress_tag_q[0]==15,"full queue borrowed pop capacity");
    step();drain(15);
    // Other lane is reading three FP operands while lane0 direct-captures and
    // lane1 refills with a different three-port FP bundle. Old rank stays local.
    fpwrite(30,30);fpwrite(31,31);fpwrite(32,32);
    fpwrite(33,33);fpwrite(34,34);fpwrite(35,35);
    classes={`R64_C_FP,`R64_C_ALU};source_fp=6'b111000;
    tag={9'd16,9'b0};source={6'd32,6'd31,6'd30,18'b0};used=6'b111000;pending=0;
    expected_a[16]=30;expected_b[16]=31;expected_c[16]=32;fire=2;step();fire=0;
    wb=1;wb_preg=24;wb_data=1506;
    tag={9'd18,9'd17};source={6'd35,6'd34,6'd33,6'b0,6'b0,6'd24};
    used=6'b111001;pending=1;
    expected_a[17]=1506;expected_a[18]=33;expected_b[18]=34;expected_c[18]=35;
    fire=3;#1;check(credit==3&&dut.transfer_w[1],"FP read/direct/refill window missing");step();
    fire=0;clear_sources();source_fp=0;classes=0;step();drain(18);
    // A branch keeps the original ingress boundary even with complete values.
    classes={`R64_C_BRANCH,`R64_C_BRANCH};
    wb=1;wb_preg=25;wb_data=1607;put_pair(19,25,0,1,1607,0);
    check(dut.ingress_valid_q==3,"branch incorrectly direct admitted");clear_sources();step();drain(20);
    // x0/unused sources are complete zeros; nonzero raw buses cannot leak.
    classes={`R64_C_MEM,`R64_C_ALU};token_resident=1;token_valid=1;token_preg=0;token_data=64'hbad;
    put_pair(21,0,0,0,0,0);clear_sources();step();drain(22);
    // A cancelled incoming packet cannot enter direct terminal ownership.
    kill=32'h01800000;wb=1;wb_preg=26;wb_data=1708;
    put_pair(23,26,0,1,1708,0);clear_sources();step();kill=0;
    out_ready=3;repeat(3)step();out_ready=0;
    check(count==22&&!seen[23]&&!seen[24],"input kill created a direct owner");
    // A captured packet remains cancelable. Fulltag/preg reuse cannot replay it.
    wb=1;wb_preg=27;wb_data=1809;put_pair(25,27,0,1,1809,0);clear_sources();step();
    kill=32'h06000000;step();step();kill=0;
    out_ready=3;repeat(3)step();out_ready=0;check(count==22,"held kill escaped");
    wb=1;wb_preg=27;wb_data=1901;put_pair(57,27,0,1,1901,0);clear_sources();step();drain(24);
    wb=1;wb_preg=28;wb_data=2002;put_pair(59,28,0,1,2002,0);clear_sources();
    flush=1;step();flush=0;out_ready=3;repeat(3)step();out_ready=0;
    check(count==24&&!seen[59]&&!seen[60],"flush left direct owner visible");
    // MEM with an FPR store-data source is not an integer complete packet,
    // even if both same-numbered integer destinations happen to be broadcast.
    fpwrite(29,2103);classes={`R64_C_MEM,`R64_C_MEM};source_fp=6'b010010;
    wb=3;wb_preg={6'd29,6'd30};wb_data={64'hbad,64'd2204};
    put_pair(61,30,29,1,2204,2103);
    check(dut.ingress_valid_q==3,"MEM FPR data incorrectly used integer direct values");
    clear_sources();source_fp=0;step();drain(26);
    check(full_pop_fallback>0&&old_transfer_fallback>0&&eligible>0&&fallback>0,"capacity coverage vacuous");
    if(RR_COMPLETE_ADMIT)check(actual>0&&pop_direct>0,"actual direct/pop coverage absent");
    else check(actual==0,"disabled direct admission changed behavior");
    $display("[PASS] tb_r64_rr_complete_admit enabled=%0d prepared=%0d checks=%0d transfers=%0d eligible=%0d actual=%0d fallback=%0d pop_direct=%0d full_pop_fallback=%0d old_transfer_fallback=%0d",
      RR_COMPLETE_ADMIT,PREPARED_CANCEL,checks,count,eligible,actual,fallback,pop_direct,full_pop_fallback,old_transfer_fallback);$finish;
  end
endmodule
