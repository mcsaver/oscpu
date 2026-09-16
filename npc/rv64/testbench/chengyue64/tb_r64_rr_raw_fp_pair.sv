`timescale 1ns/1ps
module tb_r64_rr_raw_fp_pair;
  parameter QMODE=1;
  localparam T=9,P=6,M=32;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] km=0;
  reg [4:0] head=0;
  reg [1:0] ev=0,wv=0,wfp=0,orr=3;
  reg [2*T-1:0] et=0;
  reg [2*M-1:0] ep=0;
  reg [5:0] ec=0,efp=0,eu=0,er=0,allow=0;
  reg serial_allow=0,barrier_valid=0;
  reg [31:0] serial_retire=0;
  reg [4:0] barrier_slot=0;
  reg [6*P-1:0] es=0;
  reg [2*P-1:0] wp=0;
  reg [127:0] wd=0;
  wire [1:0] eready,fire,ir,ov;
  wire [2*T-1:0] it,ot;
  wire [2*M-1:0] ip,op;
  wire [5:0] ic,ifp,iu,oc;
  wire [6*P-1:0] isp;
  wire [383:0] operands;wire [9:0] issue_slots,out_slots;
  wire [4:0] count;
  integer i,j,issued,retained,observed;
  wire [51:0] issue_plan;
  integer pair_checks=0,mask_case,kill_case,si,expected_fire;
  integer cycles=0;always @(posedge clk)cycles<=cycles+1;
  reg [31:0] held_payload;
  R64Issue #(.PAYLOAD_W(M)) issue(.enq_gpr_dst_i(12'b0),.issue_gpr_dst_o(),.early_valid_i(2'b0),.early_preg_i(12'b0),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),.rob_head_i(head),
    .barrier_valid_i(barrier_valid),.barrier_slot_i(barrier_slot),
    .serial_active_i(barrier_valid ? (32'b1<<barrier_slot):32'b0),.serial_release_i(serial_retire|~(barrier_valid ? (32'b1<<barrier_slot):32'b0)),.enq_valid_i(ev),.enq_ready_o(eready),.enq_tag_i(et),.enq_payload_i(ep),
    .enq_mem_slot_i({et[9+:5],et[0+:5]}),.issue_mem_slot_o(issue_slots),.enq_class_i(ec),.enq_src_preg_i(es),.enq_src_fp_i(efp),
    .enq_src_used_i(eu),.enq_src_ready_i(er),
    .wake_valid_i(wv),.wake_fp_i(wfp),.wake_preg_i(wp),
    .fu_allow_i(allow),.serial_allow_i(serial_allow),.issue_ready_i(ir),
    .issue_fire_o(fire),.issue_tag_o(it),.issue_payload_o(ip),.issue_class_o(ic),
    .issue_fp_plan_o(issue_plan),.issue_src_preg_o(isp),.issue_src_fp_o(ifp),.issue_src_used_o(iu),.count_o(count)
  );
  R64RegRead #(.RAW_FP_ALLOCATION(1),.COMPACT_FP(1),.Q_ONLY_TERMINAL(QMODE),.PREQUALIFIED_ISSUE(1),.PAYLOAD_W(M)) rr(.in_mem_slot_i(issue_slots),.out_mem_slot_o(out_slots),.in_gpr_dst_i(12'b0),.out_gpr_dst_o(),.alu_bypass_valid_i(2'b0),.alu_bypass_preg_i(12'b0),.alu_bypass_data_i(128'b0),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .in_fire_i(fire),.in_ready_o(ir),.in_tag_i(it),.in_payload_i(ip),.in_class_i(ic),
    .in_fp_plan_i(issue_plan),.in_src_preg_i(isp),.in_src_fp_i(ifp),.in_src_used_i(iu),
    .wb_write_i(wv),.wb_fp_i(wfp),.wb_preg_i(wp),.wb_data_i(wd),
    .out_valid_o(ov),.out_ready_i(orr),.out_tag_o(ot),.out_payload_o(op),
    .out_class_o(oc),.out_operand_o(operands)
  );
  wire [1:0] ref_ir,ref_ov;wire [17:0] ref_ot;wire [63:0] ref_op;
  wire [9:0] ref_slots;wire [5:0] ref_oc;wire [383:0] ref_operand;
  R64RegReadReference #(.COMPACT_FP(1),.Q_ONLY_TERMINAL(QMODE),.PREQUALIFIED_ISSUE(1),.PAYLOAD_W(M)) rr_reference(.in_mem_slot_i(issue_slots),.out_mem_slot_o(ref_slots),.in_gpr_dst_i(12'b0),.out_gpr_dst_o(),.alu_bypass_valid_i(2'b0),.alu_bypass_preg_i(12'b0),.alu_bypass_data_i(128'b0),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .in_fire_i(fire),.in_ready_o(ref_ir),.in_tag_i(it),.in_payload_i(ip),.in_class_i(ic),
    .in_fp_plan_i(issue_plan),.in_src_preg_i(isp),.in_src_fp_i(ifp),.in_src_used_i(iu),
    .wb_write_i(wv),.wb_fp_i(wfp),.wb_preg_i(wp),.wb_data_i(wd),
    .out_valid_o(ref_ov),.out_ready_i(orr),.out_tag_o(ref_ot),.out_payload_o(ref_op),
    .out_class_o(ref_oc),.out_operand_o(ref_operand)
  );

  always @(negedge clk)if(!rst)begin
    if({ir,ov}!=={ref_ir,ref_ov})$fatal(1,"raw FPR allocation changed ready/valid");
    if({rr.ingress_valid_q,rr.operand_ready_q,rr.terminal_head_q,rr.terminal_tail_q,
        rr.terminal_count_q[0],rr.terminal_count_q[1],rr.terminal_dead_q}!==
       {rr_reference.ingress_valid_q,rr_reference.operand_ready_q,rr_reference.terminal_head_q,rr_reference.terminal_tail_q,
        rr_reference.terminal_count_q[0],rr_reference.terminal_count_q[1],rr_reference.terminal_dead_q})
      $fatal(1,"raw FPR allocation changed owned state");
    for(integer l=0;l<2;l=l+1)if(ov[l])begin
      if({ot[l*T+:T],op[l*M+:M],oc[l*3+:3],out_slots[l*5+:5],operands[l*192+:192]}!==
         {ref_ot[l*T+:T],ref_op[l*M+:M],ref_oc[l*3+:3],ref_slots[l*5+:5],ref_operand[l*192+:192]})
        $fatal(1,"raw FPR allocation changed an owned output packet");
    end
  end
  task tick;begin @(posedge clk);#1;end endtask
  task check;input condition;input [511:0] message;
    begin if(condition!==1'b1)$fatal(1,"%0s",message);end
  endtask
  task clearpipe;
    begin ev=0;wv=0;allow=0;flush=1;tick();flush=0;km=0;orr=3;#1;end
  endtask
  task pair;
    input integer a,b;input [2:0] ca,cb;
    begin
      ev=3;et={T'(b),T'(a)};ep={32'(b),32'(a)};ec={cb,ca};
      #1;check(eready==3,"issue allocation credit");tick();ev=0;#1;
    end
  endtask
  integer lane1_namespace;
  initial begin
    tick();rst=0;#1;
    wv=3;wp={6'd6,6'd5};wd={64'd66,64'd55};tick();
    wfp=3;wd={64'd666,64'd555};tick();
    wv=1;wp[0+:P]=7;wd[63:0]=777;tick();wv=0;wfp=0;
    // A canonical lane1-only completion must wake a resident dependent,
    // including the FP namespace, before that dependent reads the PRF.
    for(lane1_namespace=0;lane1_namespace<2;lane1_namespace=lane1_namespace+1)begin
      eu=1;er=62;efp=lane1_namespace?1:0;es=9;ev=1;et=0;ec=0;ep=91;allow=0;
      tick();ev=0;wv=2;wfp=lane1_namespace?2:0;wp={6'd9,6'd0};
      wd={64'd1919,64'b0};tick();wv=0;wfp=0;allow=63;#1;
      check(fire==1,"lane1-only canonical wakeup");
      tick();tick();check(ov==1&&operands[63:0]==1919,"lane1-only canonical operand");
      clearpipe();
    end
    // GPR four-port read and write bypass preserve namespace and x0.
    eu=6'b011011;er=63;efp=0;es={6'd0,6'd6,6'd5,6'd0,6'd6,6'd5};
    pair(0,1,0,0);allow=63;#1;
    check(fire==3&&it=={T'(1),T'(0)},"dual ALU age selection");
    tick();allow=0;tick();#1;
    check(ov==3&&operands[0+:64]==55&&operands[64+:64]==66&&
          operands[192+:64]==55&&operands[256+:64]==66,"four GPR operands");
    tick();

    // A ready operand can be read on the same edge as canonical WB. Keep
    // addresses fixed while WB changes to test explicit bypass sensitivity.
    eu=1;er=63;efp=0;es=5;ev=1;et=3;ep=3;ec=0;tick();ev=0;allow=63;#1;
    tick(); // address admission precedes the physical read/WB edge
    wv=1;wfp=0;wp=5;wd=12345;#1;
    tick();wv=0;allow=0;#1;
    check(operands[63:0]==12345,"same-edge GPR WB bypass");
    clearpipe();
    wv=1;wp=5;wd=55;tick();wv=0;

    // Old blocked INT cannot hold the ready two-entry memory prefix.
    eu=1;er=62;es=9;pair(0,1,0,4);
    eu=0;er=63;ev=1;et=T'(2);ep=2;ec=4;tick();ev=0;
    allow=63;#1;check(fire==3&&it=={T'(2),T'(1)},"MEM pair blocked by older INT");
    tick();#1;check(count==1&&fire==0,"blocked integer disappeared");clearpipe();

    // Bind may bypass an unresolved older MEM; dispatch already reserved its LSQ owner.
    eu=1;er=62;es=9;pair(0,1,4,4);
    eu=0;er=63;ev=1;et=T'(2);ep=2;ec=0;tick();ev=0;
    allow=63;#1;check(fire==3&&it=={T'(2),T'(1)},"ready MEM bind was blocked by unknown older MEM");
    tick();#1;check(fire==0&&count==1,"unknown older MEM disappeared after independent binds");
    wv=1;wp=9;wd=999;tick();wv=0;#1;
    check(fire==1&&it[0+:T]==0,"older reserved MEM did not bind after wake");clearpipe();

    // Enqueue on the only producer WB edge must not lose the wakeup.
    eu=1;er=62;es=9;ev=1;et=3;ec=0;ep=3;wv=1;wp=9;wd=1009;
    tick();ev=0;wv=0;allow=63;#1;check(fire==1,"enqueue/WB lost wakeup");
    tick();tick();#1;check(ov[0]&&operands[63:0]==1009,"wakeup data not present");clearpipe();

    // A three-input FP instruction and an integer pair share 3 FP + 2 GPR.
    eu=6'b011111;er=63;efp=6'b000111;
    es={6'd0,6'd6,6'd5,6'd7,6'd6,6'd5};
    pair(0,1,3,0);allow=63;#1;check(fire==3,"FP3 plus INT failed dual issue");
    tick();allow=0;tick();#1;
    check(operands[0+:64]==555&&operands[64+:64]==666&&operands[128+:64]==777&&
          operands[192+:64]==55&&operands[256+:64]==66,"FP third operand routing");
    clearpipe();

    // A fourth FPR read is deferred without adding a fourth physical port.
    eu=6'b001111;efp=6'b001111;er=63;
    es={6'd0,6'd0,6'd5,6'd7,6'd6,6'd5};
    pair(0,1,3,4);allow=63;#1;check(fire==1,"FPR read budget overflow");
    tick();#1;check(fire==1&&it[0+:T]==1,"deferred FPR read lost progress");
    tick();tick();#1;check(ov[0]&&ot[0+:T]==1&&operands[63:0]==555,"compacted FPR load/store operand");clearpipe();

    // Independently held lanes: backpressure preserves every operand/payload.
    eu=6'b011011;efp=0;er=63;es={6'd0,6'd6,6'd5,6'd0,6'd6,6'd5};
    pair(0,1,4,0);allow=63;orr=2;tick();allow=0;tick();#1;
    check(ov==3,"held lane capture");held_payload=op[0+:M];
    // Fill lane0 second terminal and ingress; its computed value must hold
    // without consuming FPR/GPR ports while lane1 keeps making progress.
    ev=1;et=2;ep=2;ec=0;tick();ev=0;allow=63;#1;
    check(fire==1,"held output did not expose its free ingress credit");
    tick();allow=0;tick();#1;
    check(ir[0]&&op[0+:M]==held_payload,"lane0 second terminal changed held owner");
    ev=1;et=30;ep=30;ec=0;tick();ev=0;allow=63;#1;
    check(fire==1,"third owned slot was not available");
    tick();allow=0;tick();#1;
    check(!ir[0]&&op[0+:M]==held_payload,"full lane0 did not retain ingress owner");
    for(i=0;i<8;i=i+1) begin
      ev=1;et=T'(i+3);ep=32'(i+3);ec=0;tick();ev=0;allow=63;#1;
      check(fire==2,"held lane froze the independent register-read lane");
      tick();allow=0;tick();#1;
      check(ov==3&&op[0+:M]==held_payload&&operands[63:0]==55,"held packet mutated");
    end
    km=1;tick();check(!ov[0]&&!ir[0],"kill did not hide the owner before local drain");
    km=0;tick();check(ov[0]&&ot[0+:T]==2&&ir[0],"local tombstone drain lost the next owner");
    clearpipe();

    // Serial operations need the exact ROB head and external permission.
    eu=0;efp=0;er=63;head=0;ev=1;et=1;ep=1;ec=5;tick();ev=0;allow=63;
    serial_allow=1;#1;check(fire==0,"serial passed older ROB entry");
    head=1;#1;check(fire==1,"authorized serial made no progress");clearpipe();

    // The serial ROB owner remains a barrier after leaving the issue queue.
    head=0;barrier_valid=0;barrier_slot=1;
    pair(0,1,0,5);barrier_valid=1; // ROB serial becomes active at its birth edge.
    ev=1;et=2;ep=2;ec=0;tick();ev=0;allow=63;
    #1;check(fire==1&&it[0+:T]==0,"younger INT crossed serial barrier");
    tick();head=1;#1;check(fire==1&&it[0+:T]==1,"serial barrier head admission");
    tick();#1;check(fire==0&&count==1,"serial boundary vanished after issue");
    // ROB presents the actual retirement event before its active Q clears
    // at the edge. Preserve this real event/Q relationship in the fixture.
    serial_retire=32'b1<<barrier_slot;#1;
    check(fire==0,"retirement event released dependent before its edge");
    tick();barrier_valid=0;serial_retire=0;#1;
    check(fire==1&&it[0+:T]==2,"retired barrier did not release");
    clearpipe();

    // Both register-read outputs consume and replace every cycle after fill.
    eu=0;efp=0;er=63;allow=63;head=0;issued=0;observed=0;
    for(i=0;i<50;i=i+1) begin
      ev=3;et={T'(2*i+1),T'(2*i)};ep={32'(2*i+1),32'(2*i)};ec=0;
      head=(i==0)?0:5'(2*i-2);#1;
      check(eready==3,"steady IQ credit bubble");
      if(i>0)check(fire==3,"steady dual issue bubble");
      if(fire[0])issued=issued+1;if(fire[1])issued=issued+1;
      if(ov[0])begin check(op[0+:M]==observed,"pipeline output order0");observed=observed+1;end
      if(ov[1])begin check(op[M+:M]==observed,"pipeline output order1");observed=observed+1;end
      tick();
    end
    ev=0;head=5'(98);
    for(j=0;j<3;j=j+1)begin
      #1;
      if(fire[0])issued=issued+1;if(fire[1])issued=issued+1;
      if(ov[0])begin check(op[0+:M]==observed,"drain output order0");observed=observed+1;end
      if(ov[1])begin check(op[M+:M]==observed,"drain output order1");observed=observed+1;end
      tick();
    end
    check(issued==100&&observed==100&&count==0,"IQ/RR conservation");

    clearpipe();head=0;serial_allow=0;barrier_valid=0;wv=0;
    // Every raw <=3 source mask, all four independent same-cycle kill subsets.
    // Killing the older raw lane alone deliberately exceeds suffix assumptions:
    // lane1 must retain its raw port offset and still read the correct sources.
    for(mask_case=0;mask_case<64;mask_case=mask_case+1)if(((mask_case>>0)&1)+((mask_case>>1)&1)+((mask_case>>2)&1)+((mask_case>>3)&1)+((mask_case>>4)&1)+((mask_case>>5)&1)<=3)
      for(kill_case=0;kill_case<4;kill_case=kill_case+1)begin
        eu=6'(mask_case);efp=eu;er=63;
        es={6'd5,6'd7,6'd6,6'd7,6'd6,6'd5};
        pair(0,1,3,4);orr=0;allow=63;#1;
        check(fire==3,"raw three-port bundle selection");
        km=32'(kill_case);#1;expected_fire=3^kill_case;
        check(fire==2'(expected_fire),"independent selected-owner kill qualification");
        tick();allow=0;km=0;tick();#1;
        check(ov==2'(expected_fire),"accepted subset appeared at a different cycle");
        for(si=0;si<6;si=si+1)
          if(expected_fire&(1<<(si/3)))begin
            if(mask_case&(1<<si))begin
              case(es[si*P+:P])
                5:check(operands[si*64+:64]==555,"source five changed");
                6:check(operands[si*64+:64]==666,"source six changed");
                7:check(operands[si*64+:64]==777,"source seven changed");
              endcase
            end else check(operands[si*64+:64]==0,"unused source became visible");
          end
        repeat(4)tick();pair_checks=pair_checks+1;clearpipe();
      end
    // A full three-FPR raw bundle sustains two accepted instructions each
    // cycle after fill. All requests deliberately alias physical FPR5.
    head=0;eu=6'b001011;efp=eu;er=63;es={6'd0,6'd0,6'd5,6'd0,6'd5,6'd5};
    allow=63;orr=3;issued=0;observed=0;
    for(i=0;i<50;i=i+1)begin
      ev=3;et={T'(2*i+1),T'(2*i)};ep={32'(2*i+1),32'(2*i)};ec={3'd4,3'd3};
      head=(i==0)?0:5'(2*i-2);#1;
      check(eready==3,"FP3 hot IQ credit bubble");
      if(i>0)check(fire==3,"FP3 hot dual issue bubble");
      if(fire[0])issued=issued+1;if(fire[1])issued=issued+1;
      if(ov[0])begin check(op[0+:M]==observed,"FP3 pipeline output order0");observed=observed+1;end
      if(ov[1])begin check(op[M+:M]==observed,"FP3 pipeline output order1");observed=observed+1;end
      tick();
    end
    ev=0;head=5'(98);
    repeat(3)begin
      #1;
      if(fire[0])issued=issued+1;if(fire[1])issued=issued+1;
      if(ov[0])observed=observed+1;if(ov[1])observed=observed+1;
      tick();
    end
    check(issued==100&&observed==100&&count==0,"FP3 hot owner conservation");
    $display("[RAW-FP-HOT] issued=100 observed=100 steady_issue=2 same_fpr=5 physical_ports=3");
    clearpipe();head=0;
    // Same FPR at all three positions, lane1-only after older lane cancellation;
    // canonical WB at the physical-read edge must win over old PRF contents.
    eu=6'b001011;efp=eu;er=63;es={6'd0,6'd0,6'd5,6'd0,6'd5,6'd5};
    pair(0,1,3,4);allow=63;km=1;#1;check(fire==2,"shared source lane1-only admission");
    tick();allow=0;km=0;wv=1;wfp=1;wp=5;wd=909;tick();wv=0;
    check(ov==2&&operands[192+:64]==909,"shared FPR WB/read forwarding");
    clearpipe();
    // Fulltag generation reuse after pending physical-read cancellation.
    eu=1;efp=1;er=63;es=5;ev=1;et=9'd3;ep=33;ec=3;tick();ev=0;allow=63;
    tick();allow=0;km=8;tick();km=0;repeat(2)tick();
    check(ov==0,"killed pending read escaped");
    ev=1;et=9'd35;ep=35;ec=3;tick();ev=0;allow=63;orr=0;
    tick();allow=0;tick();check(ov==1&&ot[0+:T]==35&&operands[63:0]==909,"new generation inherited cancelled rank");
    repeat(5)tick();flush=1;tick();flush=0;check(ov==0,"fullflush retained owner");
    check(pair_checks==168,"raw FPR source/cancel matrix did not execute");
    $display("[RAW-FP-PAIR] masks=42 cancel_subsets=4 cases=%0d cycles=%0d same_accepted_cycle=1 state_equal=1",pair_checks,cycles);
    $display("[R64-ISSUE] MEM reservation/independent bind, FP3 port budget, enqueue WB, serial and held kill PASS");
    $display("[R64-ISSUE-THROUGHPUT] packets=100 observed=100 steady_issue=2 gpr_ports=4 fpr_ports=3");
    $display("[PASS] tb_r64_rr_raw_fp_pair");$finish;
  end
endmodule
