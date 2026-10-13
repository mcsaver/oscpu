`timescale 1ns/1ps
`include "R64Dispatch.vh"
// Real ExecutionDomain/Q/Owners; only interface births and certified WB driven.
module tb_r64_load_notice_q_identity #(parameter NOTICE_Q=1);
  localparam U=`R64_UOP_W,R=`R64_RESULT_W,T=9;
  reg clk=0;always #5 clk=~clk;
  reg rst=1;
  reg [`R64_RECOVERY_W(32)-1:0] recovery=0;
  reg [1:0] birth=0,birth_write=0;
  reg [17:0] birth_tag=0;
  reg [2*U-1:0] birth_uop=0;
  reg [5:0] birth_class=0,birth_used=0;
  reg [11:0] birth_preg=0;
  reg [35:0] birth_src=0;
  wire [1:0] credit;
  reg [1:0] nv=0,wb=0;
  reg [17:0] nt=0,wt=0;
  reg [127:0] nd=0,wd=0;
  reg [11:0] wp=0;
  wire [4:0] result_valid;
  wire [44:0] result_tag;
  wire [5*R-1:0] result_data;
  wire [1:0] mem_fire;
  wire [17:0] mem_tag;
  R64ExecutionDomain #(
    .LOAD_VALUE_NOTICE_Q(NOTICE_Q),.LOAD_RESOLVED_VALUE(1),.LOAD_COMPLETION_PROMISE(0),
    .INIT_CURRENT_READY(1),.RR_COMPLETE_ADMIT(1),.RR_ADMIT_GPR_READ(1),
    .ALU_TOKEN_BYPASS(1),.DIRECT_MEM_BIND(1)
  ) dut (
    .clk(clk),.rst(rst),.recovery_i(recovery),
    .serial_allow_i(1'b1),.head_slot_i(5'b0),.head_tag_i(9'b0),
    .barrier_slot_i(5'b0),.barrier_valid_i(1'b0),
    .serial_active_i(32'b0),.serial_release_i(32'b0),
    .birth_i(birth),.birth_rd_write_i(birth_write),.birth_rd_fp_i(2'b0),
    .birth_ready_o(credit),.birth_tag_i(birth_tag),.birth_mem_slot_i(10'b0),
    .birth_uop_i(birth_uop),.birth_class_i(birth_class),.birth_preg_i(birth_preg),
    .birth_src_preg_i(birth_src),.birth_src_fp_i(6'b0),.birth_src_used_i(birth_used),
    .resolved_value_valid_i(nv),.resolved_value_tag_i(nt),.resolved_value_data_i(nd),
    .load_capture_i(2'b0),.load_capture_tag_i(18'b0),
    .wb_accept_i(wb),.wb_write_i(wb),.wb_fp_i(2'b0),
    .wb_tag_i(wt),.wb_preg_i(wp),.wb_data_i(wd),
    .reclaim_write_i(2'b0),.reclaim_fp_i(2'b0),.reclaim_preg_i(12'b0),
    .result_valid_o(result_valid),.result_ready_i(5'b11111),
    .result_tag_o(result_tag),.result_o(result_data),
    .lsu_ready_i(2'b11),.lsu_fire_o(mem_fire),.lsu_tag_o(mem_tag),
    .fp_ready_i(1'b1),.serial_ready_i(1'b1),
    .batch_apply_i(1'b0),.batch_greclaim_i(64'b0),.batch_freclaim_i(64'b0)
  );

  integer checks=0,cycle=0,samples=0,holds=0,dual=0;
  integer wb_reject=0,kill_reject=0,flush_reject=0,stale_reject=0,mixed=0;
  integer fallbacks=0,reuse_results=0;
  integer results[0:511],issued[0:511],memory[0:511];
  reg [63:0] got[0:511];
  // Independent accepted-event ledger, never copied from DUT owner arrays.
  reg [`R64_RECOVERY_W(32)-1:0] ref_recovery=0;
  reg [31:0] live=0,is_load=0;
  reg [8:0] tags[0:31];
  reg [5:0] pregs[0:31];
  reg [1:0] sample_v,qualified,sample_wb;
  reg [17:0] sample_t,sample_wt;
  reg [127:0] sample_d;
  reg [31:0] applied_kill;
  reg [U-1:0] u;
  reg [7:0] func;
  integer slot,id;
  task check(input yes,input [639:0] why);
    begin checks=checks+1;if(yes!==1'b1)$fatal(1,"%0s cycle=%0d",why,cycle);end
  endtask
  task packet_check;
    begin
      check(dut.load_notice_valid_w===sample_v,"notice valid changed outside capture edge");
      check(dut.load_notice_tag_w===sample_t,"notice tag changed outside capture edge");
      check(dut.load_notice_data_w===sample_d,"notice data changed outside capture edge");
      check(dut.registers.resolved_value_data_i===sample_d,"RR data bypassed whole notice Q");
    end
  endtask
  always @(posedge clk)begin
    cycle=cycle+1;
    sample_v=(rst||ref_recovery[33])?0:nv;sample_t=nt;sample_d=nd;
    sample_wb=wb;sample_wt=wt;
    applied_kill=ref_recovery[31:0]&{32{ref_recovery[32]}};
    if(rst)begin
      live=0;is_load=0;ref_recovery=0;
      for(integer s=0;s<32;s=s+1)begin tags[s]=0;pregs[s]=0;end
      for(integer t=0;t<512;t=t+1)begin results[t]=0;issued[t]=0;memory[t]=0;got[t]=0;end
    end else begin
      for(integer l=0;l<2;l=l+1)begin
        if(mem_fire[l])begin id=mem_tag[l*T+:T];memory[id]=memory[id]+1;
          check(memory[id]==1,"duplicate actual memory command");end
        if(dut.issue_fire_w[l])begin id=dut.issue_tag_w[l*T+:T];issued[id]=issued[id]+1;
          check(issued[id]==1,"duplicate actual IQ issue");end
      end
      for(integer l=0;l<5;l=l+1)if(result_valid[l])begin
        id=result_tag[l*T+:T];results[id]=results[id]+1;got[id]=result_data[l*R+:64];
        check(results[id]==1&&!result_data[l*R+`R64_R_EXCEPTION],"duplicate/faulted actual result");
      end
      live=ref_recovery[33]?0:live&~applied_kill;
      for(integer l=0;l<2;l=l+1)if(wb[l])begin
        slot=wt[l*T+:5];
        check(live[slot]&&tags[slot]==wt[l*T+:T]&&pregs[slot]==wp[l*6+:6],
              "mock WB lacked accepted matching owner");
        live[slot]=0;
      end
      for(integer l=0;l<2;l=l+1)if(birth[l])begin
        slot=birth_tag[l*T+:5];u=birth_uop[l*U+:U];func=u[`R64_U_FUNC];
        check(credit[l]&&!live[slot]&&!ref_recovery[33]&&!applied_kill[slot],
              "fixture birth lacked credit or reused live/cancelled owner");
        live[slot]=birth_write[l];tags[slot]=birth_tag[l*T+:T];pregs[slot]=birth_preg[l*6+:6];
        is_load[slot]=birth_class[l*3+:3]==`R64_C_MEM&&birth_write[l]&&
          pregs[slot]!=0&&!u[`R64_U_EXCEPTION]&&!func[5]&&!func[6]&&!func[7];
      end
      ref_recovery=recovery;
    end
    #1;packet_check();samples=samples+1;qualified=0;
    for(integer l=0;l<2;l=l+1)begin
      slot=sample_t[l*T+:5];
      if(sample_v[l]&&!rst&&!ref_recovery[33]&&
         !(ref_recovery[32]&&ref_recovery[slot])&&live[slot]&&is_load[slot]&&
         tags[slot]==sample_t[l*T+:T]&&pregs[slot]!=0)qualified[l]=1;
      if(sample_v[l]&&!qualified[l])begin
        if(ref_recovery[33])flush_reject=flush_reject+1;
        else if(ref_recovery[32]&&ref_recovery[slot])kill_reject=kill_reject+1;
        else if(live[slot]&&tags[slot]!=sample_t[l*T+:T])stale_reject=stale_reject+1;
        for(integer w=0;w<2;w=w+1)
          if(sample_wb[w]&&sample_wt[w*T+:T]==sample_t[l*T+:T])wb_reject=wb_reject+1;
      end
      if(qualified[l])check(dut.resolved_preg_w[l*6+:6]==pregs[slot],"qualified preg differs from birth ledger");
    end
    check(dut.resolved_valid_w===qualified,"qualification differs from independent fulltag ledger");
    if(sample_v==3&&qualified==3)dual=dual+1;
    if(sample_v==3&&(qualified==1||qualified==2))mixed=mixed+1;
  end

  task tick;begin @(posedge clk);#2;@(negedge clk);end endtask
  task reset_case;begin rst=1;birth=0;wb=0;recovery=0;nv=0;tick();rst=0;tick();end endtask
  task load_input(input integer l,input [8:0] tag,input [5:0] preg);
    reg [U-1:0] payload;
    begin
      payload=0;payload[`R64_U_FUNC]=8'h03;
      birth_tag[l*T+:T]=tag;birth_preg[l*6+:6]=preg;birth_class[l*3+:3]=`R64_C_MEM;
      birth_uop[l*U+:U]=payload;birth_src[l*18+:18]=0;birth_used[l*3+:3]=0;
    end
  endtask
  task loads(input [8:0] t0,input [5:0] p0,input [8:0] t1,input [5:0] p1);
    begin load_input(0,t0,p0);load_input(1,t1,p1);birth=3;birth_write=3;tick();birth=0;end
  endtask
  task consumer_input(input [8:0] tag,input [5:0] dst,input [5:0] src);
    reg [U-1:0] payload;
    begin
      payload=0;payload[`R64_U_FUNC]=`R64_F_ADD;
      payload[`R64_U_OP2_ARG]=1;payload[`R64_U_ARG]=1;
      birth_tag={9'b0,tag};birth_preg={6'b0,dst};birth_src={30'b0,src};
      birth_class={3'b0,`R64_C_ALU};birth_uop={{U{1'b0}},payload};
      birth_used=1;birth_write=1;birth=1;
    end
  endtask
  task notice(input [8:0] t0,input [63:0] d0,input [8:0] t1,input [63:0] d1);
    begin nv=3;nt={t1,t0};nd={d1,d0};end
  endtask
  task hold_check;
    begin #1;packet_check();check(dut.resolved_valid_w===qualified,"raw notice changed certification before edge");holds=holds+1;end
  endtask
  task await_memory(input [8:0] t0,input [8:0] t1);
    integer n;
    begin n=0;while((memory[t0]!=1||memory[t1]!=1)&&n<40)begin tick();n=n+1;end
      check(memory[t0]==1&&memory[t1]==1,"born loads failed actual memory acceptance");end
  endtask
  task await_result(input [8:0] tag,input [63:0] value);
    integer n;
    begin n=0;while(results[tag]==0&&n<40)begin tick();n=n+1;end
      check(results[tag]==1&&got[tag]==value,"dependent failed actual numerical execution");
      repeat(3)tick();check(results[tag]==1,"dependent repeated after completion");end
  endtask

  initial begin
    reset_case();loads(1,32,2,33);loads(3,34,4,35);await_memory(1,2);await_memory(3,4);
    // Every edge accepts both packets; no credit/WB event is required.
    notice(1,100,2,200);hold_check();tick();
    notice(3,300,4,400);hold_check();tick();
    notice(2,200,1,100);hold_check();tick();
    repeat(3)begin notice(3,300,4,400);hold_check();tick();end
    nv=0;nt={9'd2,9'd1};nd=128'hbad0bad1;hold_check();tick();
    check(dut.resolved_valid_w==0,"invalid packet gained authority");
    nt={9'd4,9'd3};nd=~128'b0;hold_check();tick();
    notice(1,100,2,200);hold_check();
    check(dut.resolved_valid_w==0,"raw valid bypassed invalid Q");tick();

    // WB destroys lane0 lease at the same edge that installs its raw notice
    // in Q and births a real dependent. Lane1 remains a certified load value.
    reset_case();loads(1,32,2,33);await_memory(1,2);
    notice(1,101,2,202);wb=1;wt=1;wp=32;wd=101;
    consumer_input(3,34,32);tick();birth=0;wb=0;
    check(dut.load_notice_valid_w==3&&dut.resolved_valid_w==2,"WB-crossing mixed Q rejection absent");
    nv=0;await_result(3,102);fallbacks=fallbacks+1;

    // Source kill delivery and local consume differ by an edge. Old packets
    // keep arriving across reuse of the killed slot and physical destination.
    reset_case();loads(1,32,2,33);await_memory(1,2);
    notice(1,111,2,222);recovery=0;recovery[32]=1;recovery[1]=1;tick();
    check(dut.load_notice_valid_w==3&&dut.resolved_valid_w==2,"selective kill did not isolate lane");
    recovery=0;tick();check(dut.resolved_valid_w==2,"killed lease reappeared");
    load_input(0,33,32);birth=1;birth_write=1;tick();birth=0;
    consumer_input(35,34,32);tick();birth=0;repeat(6)tick();
    check(dut.load_notice_valid_w==3&&dut.resolved_valid_w==2&&issued[35]==0&&results[35]==0,
          "old Q woke same-preg new fulltag");
    check(memory[33]==1,"reused load had not reached memory");
    notice(33,333,2,222);tick();nv=0;await_result(35,334);reuse_results=reuse_results+1;

    // Fullflush immediately revokes both Q certificates on local delivery,
    // then clears Q valid at consume even with raw valid continuously high.
    reset_case();loads(1,32,2,33);await_memory(1,2);
    notice(1,121,2,242);recovery=0;recovery[33]=1;recovery[32]=1;
    recovery[31:0]=32'hffffffff;tick();
    check(dut.load_notice_valid_w==3&&dut.resolved_valid_w==0,"flush delivery failed to suppress Q");
    recovery=0;tick();
    check(dut.load_notice_valid_w==0&&dut.resolved_valid_w==0,"flush consume did not clear Q");
    loads(33,32,34,33);await_memory(33,34);
    check(dut.load_notice_valid_w==3&&dut.resolved_valid_w==0,"pre-flush tags certified after reuse");
    notice(33,363,34,484);tick();check(dut.resolved_valid_w==3,"new fulltags failed certification");
    rst=1;tick();check(dut.load_notice_valid_w==0,"reset failed Q invalidation");
    rst=0;nv=0;tick();
    check(samples>=40&&holds>=9&&dual>=7&&wb_reject>=1&&kill_reject>=1&&flush_reject>=2&&
          stale_reject>=4&&mixed>=4&&fallbacks==1&&reuse_results==1,"required coverage vacuous");
    $display("NOTICE_Q_IDENTITY samples=%0d holds=%0d dual=%0d wb_reject=%0d kill_reject=%0d flush_reject=%0d stale_reject=%0d mixed=%0d fallback=%0d reuse_result=%0d",
      samples,holds,dual,wb_reject,kill_reject,flush_reject,stale_reject,mixed,fallbacks,reuse_results);
    $display("[PASS] tb_r64_load_notice_q_identity checks=%0d actual_WB_birth_consumer=1",checks);$finish;
  end
  initial begin #100000;$fatal(1,"notice Q identity timeout");end
endmodule
