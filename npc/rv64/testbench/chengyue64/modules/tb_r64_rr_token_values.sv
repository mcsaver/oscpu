
`timescale 1ns/1ps
`include "R64Dispatch.vh"
module tb_r64_rr_token_values;
  localparam U=`R64_UOP_W;
  reg clk=0; always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] kill=0;
  reg [1:0] fire=0, out_ready=0, wb=0, token_valid=0, token_resident=0;
  reg [1:0] head_valid=0,head_resident=0;
  reg [11:0] head_preg=0;
  reg [127:0] head_data=0;
  wire [1:0] credit,valid,registered_valid,local_alu_valid;
  assign valid=registered_valid|local_alu_valid;
  reg [5:0] classes=0;
  reg [17:0] tag=0;
  reg [2*U-1:0] payload=0;
  reg [35:0] source=0;
  reg [5:0] used=0,pending=0;
  reg [11:0] wb_preg=0,token_preg=0;
  reg [127:0] wb_data=0,token_data=0;
  wire [17:0] out_tag;
  wire [383:0] operands;
  wire [11:0] shift;
  wire [9:0] unused_slot,unused_add,unused_branch_ctrl;
  wire [2*U-1:0] unused_payload;
  wire [5:0] unused_class;
  wire [11:0] unused_dst;
  wire [73:0] unused_control;
  wire [41:0] unused_branch;
  R64RegRead #(.PAYLOAD_W(U),.LATE_OPERANDS(1),.ALU_TOKEN_BYPASS(1),.Q_ONLY_TERMINAL(1),
    .SPLIT_VALUE_VALID(1),.ALU_TERMINAL_BYPASS(1)) dut (
    .out_local_alu_valid_o(local_alu_valid),
    .alu_bypass_resident_i(head_resident),
    .resolved_value_valid_i(2'b0),.resolved_value_preg_i(12'b0),.resolved_value_data_i(128'b0),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(32'b0),.cancel_active_i(1'b0),
    .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.in_mem_slot_i(10'b0),
    .in_payload_i(payload),.in_class_i(classes),.in_gpr_dst_i(12'b0),
    .in_src_preg_i(source),.in_src_fp_i(6'b0),.in_src_used_i(used),
    .in_src_pending_i(pending),.in_fp_plan_i(52'b0),
    .wb_write_i(wb),.wb_fp_i(2'b0),.wb_preg_i(wb_preg),.wb_data_i(wb_data),
    .alu_bypass_valid_i(head_valid),.alu_bypass_preg_i(head_preg),.alu_bypass_data_i(head_data),
    .alu_token_resident_i(token_resident),.alu_token_valid_i(token_valid),
    .alu_token_preg_i(token_preg),.alu_token_data_i(token_data),
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
  integer target_count, kind, mode, base_id;
  initial begin
    for(integer n=0;n<512;n=n+1)begin expected_a[n]=0;expected_b[n]=0;end
    step();rst=0;
    if($test$plusargs("bad-token-head"))begin
      head_valid=1;head_resident=1;head_preg=7;head_data=1;
      token_valid=1;token_resident=1;token_preg=7;token_data=2;
      step();$fatal(1,"conflicting head/token certificates were not rejected");
    end
    if($test$plusargs("bad-token-wb"))begin
      wb=1;wb_preg=7;wb_data=1;
      token_valid=2;token_resident=2;token_preg={6'd7,6'b0};token_data={64'd2,64'b0};
      step();$fatal(1,"conflicting WB/token certificates were not rejected");
    end
    if($test$plusargs("bad-history-collision"))begin
      wb=3;wb_preg={6'd7,6'd7};wb_data={64'd2,64'd1};step();
      $fatal(1,"conflicting certified arrivals were not rejected");
    end
    // WB completed before admission: Issue exports no pending source.
    write_one(10,101);
    put(0,1,10,0,0,101,0);step();drain(1);
    // Same admission edge one-cycle WB: pending must capture at the doorway.
    wb=1;wb_preg=11;wb_data=202;
    put(0,2,11,0,1,202,0);wb=0;step();drain(2);
    // One-cycle WB at physical-read/terminal-transfer edge.
    put(1,3,12,0,1,303,0);
    write_one(12,303);drain(3);

    // All four terminal positions and both ingress positions are resident.
    // Pending values arrive one source at a time, after stale PRF snapshots.
    write_one(20,64'hdead);write_one(21,64'hbeef);
    put_pair(10,20,21,3,404,505);step();
    put_pair(12,20,21,3,404,505);step();
    put_pair(14,20,21,3,404,505);step();
    check(dut.terminal_count_q[0]==2&&dut.terminal_count_q[1]==2&&
          dut.ingress_valid_q==3&&dut.operand_ready_q==3,
          "all six RR late operand holders not occupied");
    check(valid==0,"stale PRF snapshot discharged a promise");
    write_one(20,404);
    repeat(5)begin step();check(valid==0,"one of two pending sources fired early");end
    // Use the authorized registered ALU bus for B, exercise terminal late select.
    token_valid=2;token_resident=2;token_preg={6'd21,6'b0};token_data={64'd505,64'b0};#1;
    check(valid==3&&operands[63:0]==404&&operands[127:64]==505&&shift[5:0]==6'(505),
          "registered ALU late select or shift amount failed");
    step();token_valid=0;token_resident=0;
    repeat(5)begin step();check(valid==3&&operands[63:0]==404&&operands[127:64]==505,
          "one-cycle late values were lost under backpressure");end
    drain(9);
    check(seen[10]&&seen[11]&&seen[12]&&seen[13]&&seen[14]&&seen[15],
          "terminal or held ingress lost resolved data");

    // WB arrives while held ingress transfers into the now-free terminal.
    put_pair(20,0,0,0,0,0);step();
    put_pair(22,0,0,0,0,0);step();
    put_pair(24,30,0,1,606,0);step();
    out_ready=3;step();out_ready=0;
    wb=1;wb_preg=30;wb_data=606;step();wb=0;
    drain(15);

    // A killed pending owner must not keep queue capacity or resurrect on late WB.
    put_pair(30,31,0,1,707,0);step();
    kill=32'hc0000000;step();step();kill=0;
    write_one(31,707);out_ready=3;repeat(5)step();out_ready=0;
    check(!seen[30]&&!seen[31]&&count==15,"killed pending owner resurrected");
    put_pair(62,31,0,1,808,0);step();
    flush=1;step();flush=0;write_one(31,808);
    out_ready=3;repeat(5)step();out_ready=0;
    check(!seen[62]&&!seen[63]&&count==15,"flushed pending owner resurrected");
    // New owner reuses prior physical source, but old ginit is insufficient.
    put_pair(94,31,0,1,909,0);step();check(valid==0,"preg reuse read stale ginit");
    write_one(31,909);drain(17);
    // Fixed resident choice must not re-route wide data through current
    // cancellation. Lane0 is an obsolete same-preg result, lane1 is certified.
    put_pair(96,40,0,1,1001,0);step();
    token_resident=3;token_valid=2;token_preg={6'd40,6'd40};
    token_data={64'd1001,64'hdeaddead};#1;
    check(valid==0,"authorization re-routed a stale same-preg ALU candidate");
    wb=1;wb_preg=40;wb_data=1001;#1;
    check(valid==0,"canonical WB bypassed the local RR register");
    step();wb=0;
    check(valid==3&&operands[63:0]==1001,"WB did not replace a stale resident choice");
    drain(19);token_resident=0;token_valid=0;
    // Admission samples all four raw buses once while both terminal queues
    // are full. The first held edge overwrites shared history with unrelated
    // pregs/data; each source must already copy its certified sample locally.
    put_pair(100,0,0,0,0,0);step();
    put_pair(102,0,0,0,0,0);step();
    wb=3;wb_preg={6'd41,6'd43};wb_data={64'd1101,64'd1303};
    token_valid=3;token_resident=3;token_preg={6'd44,6'd42};token_data={64'd1404,64'd1202};
    expected_a[104]=1101;expected_b[104]=1202;
    expected_a[105]=1303;expected_b[105]=1404;
    tag={9'd105,9'd104};source={6'b0,6'd44,6'd43,6'b0,6'd42,6'd41};
    used=6'b011011;pending=6'b011011;fire=3;
    #1;check(credit==3,"history admission lacks ingress credit");step();fire=0;
    check(dut.ingress_late_pending_q[0]==3&&dut.ingress_late_pending_q[1]==3&&
          dut.ingress_late_resolved_q[0]==0&&dut.ingress_late_resolved_q[1]==0&&
          dut.ingress_history_hit_w[0]==3&&dut.ingress_history_hit_w[1]==3&&
          dut.g_arrival_history.arrival_valid_q==60&&
          dut.g_late_ingress[0].g_source[0].history_hits_w==6'b001000&&
          dut.g_late_ingress[0].g_source[1].history_hits_w==6'b010000&&
          dut.g_late_ingress[1].g_source[0].history_hits_w==6'b000100&&
          dut.g_late_ingress[1].g_source[1].history_hits_w==6'b100000,
          "admission history did not retain the four certified source identities");
    wb_preg={6'd50,6'd51};wb_data={64'hbad1,64'hbad2};
    token_preg={6'd52,6'd53};token_data={64'hbad3,64'hbad4};
    step();
    check(dut.read_select_w==0&&dut.ingress_history_hit_w[0]==0&&dut.ingress_history_hit_w[1]==0&&
          dut.ingress_late_data_q[0]=={64'd1202,64'd1101}&&
          dut.ingress_late_data_q[1]=={64'd1404,64'd1303}&&
          dut.g_arrival_history.arrival_data_q=={token_data,wb_data,head_data},
          "first-held edge lost old admission data as shared history advanced");
    repeat(3)begin wb_data=wb_data+1;token_data=token_data+1;step();end
    wb=0;token_valid=0;token_resident=0;drain(25);
    check(seen[104]&&seen[105]&&history_hold>=2,"admission pulse was not retained under hold");

    // Old ingress transfer and new admission share an edge. Old WB history
    // must reach terminal while a distinct ALU pulse installs the next owner.
    wb=1;wb_preg=45;wb_data=2101;
    put_pair(110,45,0,1,2101,0);wb=0;
    token_valid=2;token_resident=2;token_preg={6'd46,6'b0};token_data={64'd2202,64'b0};
    #1;check(dut.transfer_w==3,"transfer/refill did not overlap old ingress transfer");
    put_pair(112,46,0,1,2202,0);token_valid=0;token_resident=0;
    wb_preg={6'd55,6'd54};wb_data={64'hbad5,64'hbad6};
    token_preg={6'd57,6'd56};token_data={64'hbad7,64'hbad8};
    step();drain(29);
    check(seen[110]&&seen[111]&&seen[112]&&seen[113]&&history_transfer_refill>=2,
          "transfer/refill crossed old and new admission values");

    // MEM must wait one capture edge even when the ALU head is already
    // certified. Both lanes use their own held value after the head changes.
    classes={`R64_C_MEM,`R64_C_MEM};
    put_pair(120,58,0,1,3301,0);step();
    out_ready=3;token_resident=1;token_valid=1;token_preg=58;token_data=3301;#1;
    check(registered_valid==0&&local_alu_valid==0&&dut.out_fire_w==0,
          "MEM escaped through current ALU certification");
    step();token_preg=59;token_data=64'hbad9;#1;
    check(count==29&&registered_valid==3&&local_alu_valid==0&&
          operands[63:0]==3301&&operands[192+:64]==3301,
          "MEM capture edge or saved value changed");
    step();out_ready=0;token_valid=0;token_resident=0;
    check(count==31&&seen[120]&&seen[121],"dual MEM did not fire exactly one edge later");
    put_pair(122,59,0,1,3302,0);step();
    token_resident=2;token_valid=2;token_preg={6'd59,6'b0};token_data={64'd3302,64'b0};
    step();token_preg={6'd57,6'b0};token_data={64'hbada,64'b0};
    repeat(4)begin step();check(registered_valid==3&&local_alu_valid==0&&
        operands[63:0]==3302&&operands[192+:64]==3302,
        "MEM lost captured ALU value under downstream backpressure");end
    token_valid=0;token_resident=0;drain(33);
    // A cancelled unresolved MEM may not reappear when the result arrives.
    put_pair(124,60,0,1,3303,0);step();
    kill=32'h30000000;token_valid=1;token_resident=1;token_preg=60;token_data=3303;
    step();step();kill=0;token_valid=0;token_resident=0;
    out_ready=3;repeat(3)step();out_ready=0;
    check(count==33&&!seen[124]&&!seen[125],"cancelled MEM reappeared");
    // MEM remains a FIFO boundary even if an independent ALU is behind it.
    put_pair(126,60,0,1,3304,0);step();
    classes=0;put_pair(128,0,0,0,0,0);step();
    out_ready=3;repeat(3)begin step();
      check(valid==0&&out_tag=={9'd127,9'd126},"ALU crossed a waiting MEM boundary");
    end
    token_resident=1;token_valid=1;token_preg=60;token_data=3304;
    step();token_valid=0;token_resident=0;drain(37);
    $display("RR_SPLIT_MEM lanes=2 capture_edges=1 held=4 cancel=2 fifo_boundary=2");

    // Only MDU/FP numeric-Q waits may select the following ALU. Test both
    // already-ready and current-certified ALUs, with the FU credit asserted.
    target_count=37;
    for(kind=2;kind<=3;kind=kind+1)for(mode=0;mode<=1;mode=mode+1)begin
      base_id=140+(kind-2)*8+mode*4;
      classes={3'(kind),3'(kind)};
      put_pair(base_id,61,0,1,64'd4100+64'(base_id),0);step();
      classes=0;
      put_pair(base_id+2,mode==0?0:62,0,mode,mode==0?64'b0:64'd4200+64'(base_id),0);step();
      check(out_tag=={9'(base_id+3),9'(base_id+2)}&&
            dut.terminal_count_q[0]==2&&dut.terminal_count_q[1]==2,
            "pending MDU/FP did not select the following ALU owner");
      if(mode!=0)begin
        token_resident=2;token_valid=2;token_preg={6'd62,6'b0};
        token_data={64'd4200+64'(base_id),64'b0};
      end
      #1;check(local_alu_valid==3&&registered_valid==(mode==0?2'b11:2'b00),
               "escaped ALU validity was derived from the wrong terminal");
      out_ready=3;step();token_valid=0;token_resident=0;
      check(count==target_count+2&&seen[base_id+2]&&seen[base_id+3]&&
            !seen[base_id]&&!seen[base_id+1]&&valid==0,
            "escaped ALU popped or duplicated the pending head");
      token_resident=1;token_valid=1;token_preg=61;token_data=64'd4100+64'(base_id);#1;
      check(valid==0&&dut.out_fire_w==0,"MDU/FP used current certification for shared admission");
      step();token_valid=0;token_resident=0;token_data=64'hbadb;#1;
      check(registered_valid==3&&local_alu_valid==0&&count==target_count+2&&
            out_tag=={9'(base_id+1),9'(base_id)},
            "held MDU/FP head was not restored from its captured value");
      step();out_ready=0;target_count=target_count+4;
      check(count==target_count&&seen[base_id]&&seen[base_id+1],
            "captured MDU/FP head did not drain exactly once");
    end
    classes=0;
    $display("RR_SPLIT_ESCAPE classes=2 lanes=2 cases=4 current_fast=2");

    // A raw resident without its certificate must not become history. The
    // missed admission sample is followed by a one-shot canonical WB at read.
    token_resident=1;token_valid=0;token_preg=63;token_data=64'hbadc;
    put_pair(160,63,0,1,6001,0);token_resident=0;
    #1;check(dut.ingress_history_hit_w[0]==0&&dut.ingress_history_hit_w[1]==0&&
             dut.ingress_effective_pending_w[0]==1&&dut.ingress_effective_pending_w[1]==1,
             "uncertified raw resident discharged admission history");
    wb=1;wb_preg=63;wb_data=6001;step();wb=0;drain(55);

    // Even a changed following sample of the same preg cannot replace the
    // certified admission event. Exercise both direct transfer and held read.
    wb=1;wb_preg=61;wb_data=6101;put_pair(162,61,0,1,6101,0);wb=0;
    token_resident=2;token_valid=2;token_preg={6'd61,6'b0};token_data={64'd6102,64'b0};
    #1;check(dut.ingress_history_hit_w[0]==1&&dut.ingress_effective_pending_w[0]==0&&
             dut.ingress_late_hit_w[0]==1,"history/current priority window not reached");
    step();token_valid=0;token_resident=0;drain(57);
    put_pair(164,0,0,0,0,0);step();put_pair(166,0,0,0,0,0);step();
    wb=2;wb_preg={6'd60,6'b0};wb_data={64'd6201,64'b0};
    put_pair(168,60,0,1,6201,0);wb=0;
    token_resident=1;token_valid=1;token_preg=60;token_data=6202;
    #1;check(dut.transfer_w==0&&dut.read_select_w==3&&
             dut.ingress_history_hit_w[0]==1&&dut.ingress_effective_pending_w[0]==0,
             "blocked read missed admission history");
    step();token_valid=0;token_resident=0;
    repeat(3)begin step();check(dut.read_select_w==0&&
        dut.ingress_history_hit_w[0]==0&&dut.ingress_history_hit_w[1]==0&&
        dut.ingress_late_data_q[0][63:0]==6201&&dut.ingress_late_data_q[1][63:0]==6201,
        "held ingress replayed history or lost earlier certified event");end
    drain(63);

    // Cancellation at the first-read boundary kills the history's consumer;
    // the next generation reusing slot and preg cannot see that prior event.
    wb=1;wb_preg=59;wb_data=6301;put_pair(170,59,0,1,6301,0);wb=0;
    kill=32'h00000c00;step();step();kill=0;
    out_ready=3;repeat(3)step();out_ready=0;
    check(count==63&&!seen[170]&&!seen[171],"cancelled admission history resurrected");
    put_pair(202,59,0,1,6401,0);step();
    check(valid==0,"new generation used stale cancelled history");
    write_one(59,6401);drain(65);
    wb=1;wb_preg=58;wb_data=6501;put_pair(204,58,0,1,6501,0);wb=0;
    flush=1;step();flush=0;
    put_pair(236,58,0,1,6601,0);step();
    check(valid==0&&!seen[204]&&!seen[205],"flush exposed prior history to a new owner");
    write_one(58,6601);drain(67);

    // Different preg heads and tokens must both remain independently visible.
    // Each consumer needs one of each on opposite physical lanes.
    put(0,240,10,11,3,7101,7102);step();
    put(1,241,12,13,3,7103,7104);step();
    head_valid=3;head_resident=3;head_preg={6'd13,6'd10};head_data={64'd7104,64'd7101};
    token_valid=3;token_resident=3;token_preg={6'd12,6'd11};token_data={64'd7103,64'd7102};
    #1;check(valid==3 && operands[0+:128]=={64'd7102,64'd7101} &&
             operands[192+:128]=={64'd7104,64'd7103},
             "token globally hid an unrelated resident head");
    step();head_valid=0;head_resident=0;token_valid=0;token_resident=0;
    drain(69);
    // Obsolete raw head may not redirect through certification to a new token.
    // The new token is still captured locally, then supplies the next edge.
    put_pair(242,14,0,1,7201,0);step();
    head_resident=1;head_valid=0;head_preg=14;head_data=64'hbad;
    token_resident=1;token_valid=1;token_preg=14;token_data=7201;
    #1;check(valid==0,"current certification re-routed stale head to new token");
    step();head_resident=0;token_resident=0;token_valid=0;
    check(valid==3 && operands[63:0]==7201,"new token local capture did not replace obsolete head");
    drain(71);
    $display("RR_HISTORY_METADATA sources=6 qualified_only=1 miss_then_current=1 priority_transfer=1 priority_hold=1 one_shot=1 cancel_reuse=1 flush_reuse=1");
    $display("RR_ARRIVAL_HISTORY held_copy=%0d transfer_refill=%0d sources=6",history_hold,history_transfer_refill);
    $display("[PASS] tb_r64_rr_token_values windows=4 holders=6 dual-lane two-source shift kill flush reuse Q-route transfers=%0d",count);
    $finish;
  end
endmodule
