`timescale 1ns/1ps
module tb_r64_fetch;
  reg clk=0; always #5 clk=~clk;
  reg rst=1, run=0, redirect=0;
  reg [63:0] target=64'h80000000;
  wire req_valid, req_ready, rsp_ready;
  wire [63:0] req_pc;
  reg rsp_valid=0, req_allow=0;
  reg [127:0] rsp_data=0;
  reg rsp_fault=0;
  reg [4:0] rsp_cause=0;
  assign req_ready=req_allow;
  wire pv,pr,pf;
  wire [63:0] pp;
  wire [127:0] pd;
  wire [4:0] cause;wire [7:0] access_mask;
  R64FetchStream fs(.clk_i(clk),.rst_i(rst),.run_i(run),.redirect_i(redirect),
    .redirect_block_i(target[63:4]),.redirect_offset_i(3'b0),.invalidate_i(1'b0),
    .learn_i(1'b0),.learn_pc_i(64'b0),.learn_length_i(4'b0),.learn_target_i(64'b0),
    .resolve_i(1'b0),.resolve_pc_i(64'b0),.resolve_taken_i(1'b0),.resolve_target_i(64'b0),
    .repair_i(1'b0),.repair_block_i(64'b0),.req_valid_o(req_valid),.req_ready_i(req_ready),.req_pc_o(req_pc),
    .rsp_valid_i(rsp_valid),.rsp_ready_o(rsp_ready),.rsp_data_i(rsp_data),.rsp_fault_i(rsp_fault),
    .rsp_cause_i(rsp_cause),.rsp_access_mask_i(8'b0),.packet_valid_o(pv),.packet_ready_i(pr),
    .packet_pc_o(pp),.packet_data_o(pd),.packet_fault_o(pf),.packet_cause_o(cause),.packet_access_mask_o(access_mask),
    .packet_plan_valid_o(),.packet_plan_offset_o(),.packet_plan_word_o(),.packet_plan_target_o());
  wire [1:0] valid;
  reg [1:0] consume=0;
  wire [63:0] pc0,pc1,i0,i1,tv0,tv1;
  wire [3:0] l0,l1;
  wire f0,f1;
  wire [4:0] c0,c1;
  R64Align al(.clk_i(clk),.rst_i(rst),.redirect_i(redirect),.redirect_pc_i(target),
    .packet_valid_i(pv),.packet_ready_o(pr),.packet_pc_i(pp),.packet_data_i(pd),
    .packet_fault_i(pf),.packet_cause_i(cause),.packet_access_mask_i(access_mask),
    .packet_plan_valid_i(1'b0),.packet_plan_offset_i(3'b0),.packet_plan_word_i(1'b0),
    .packet_plan_target_i(63'b0),.jump_i(1'b0),.jump_pc_i(64'b0),
    .plan_at_o(),.plan_bad_o(),.plan_target_o(),.plan_source_o(),
    .valid_o(valid),.consume_i(consume),.pc0_o(pc0),.pc1_o(pc1),.inst0_o(i0),.inst1_o(i1),
    .length0_o(l0),.length1_o(l1),.fault0_o(f0),.fault1_o(f1),.cause0_o(c0),.cause1_o(c1),.tval0_o(tv0),.tval1_o(tv1));
  reg [7:0] mem [0:16383];
  integer lengths[0:16383];
  reg [63:0] words[0:16383];
  integer addresses[0:4095];
  reg [63:0] qpc[0:32767];
  integer due[0:32767];
  integer qh=0,qt=0,cycle=0,expected=0,ninst=0;
  integer accepted=0,returned=0,retired=0,dual=0,blocked=0,redirs=0;
  integer pos,k,j,n,len,idx;
  reg [63:0] word;
  reg [31:0] random_q=32'h502510ab;
  reg held=0; reg [63:0] held_pc;
  reg [63:0] held_i0,held_pc0; reg held_output=0;
  integer inject_block=-1, faults=0;

  function [31:0] rng(input [31:0] x);
    rng={x[30:0],x[31]^x[21]^x[1]^x[0]};
  endfunction

  task check_one(input [63:0] pc,input [63:0] bits,input [3:0] size,
                 input fault,input [4:0] why,input [63:0] tval);
    integer a;
    begin
      a=pc-64'h80000000;
      if(a!=expected) $fatal(1,"PC %h expected %h",pc,64'h80000000+expected);
      if(fault) begin
        if(why!=12 || tval!=(64'h80000000+inject_block*16))
          $fatal(1,"fault provenance pc=%h cause=%d tval=%h",pc,why,tval);
        faults=faults+1;
      end else if(size!=lengths[a] || bits!==words[a])
        $fatal(1,"decode pc=%h got %h/%d expected %h/%d",pc,bits,size,words[a],lengths[a]);
      expected=expected+size;
      retired=retired+1;
    end
  endtask

  always @(posedge clk) begin
    if(!rst) begin
      if(held && (!req_valid || req_pc!==held_pc))
        $fatal(1,"request changed while backpressured");
      held=req_valid&&!req_ready; held_pc=req_pc;
      if(held) blocked=blocked+1;
      if(held_output && !redirect && (i0!==held_i0 || pc0!==held_pc0))
        $fatal(1,"instruction changed while backpressured");
      held_output=valid[0]&&consume==0&&!redirect;
      held_i0=i0; held_pc0=pc0;
      if(redirect) begin
        expected=target-64'h80000000;
        redirs=redirs+1;
        held_output=0;
      end else begin
        if(consume>=1) check_one(pc0,i0,l0,f0,c0,tv0);
        if(consume==2) begin check_one(pc1,i1,l1,f1,c1,tv1);dual=dual+1;end
      end
      if(req_valid&&req_ready) begin
        qpc[qt]=req_pc; due[qt]=cycle+2+random_q[5:3];
        qt=qt+1;accepted=accepted+1;
      end
      if(rsp_valid&&rsp_ready) begin qh=qh+1;returned=returned+1;end
    end
  end

  initial begin
    for(k=0;k<16384;k=k+1) begin mem[k]=0;lengths[k]=0;words[k]=0;end
    pos=0;
    for(k=0;k<2048;k=k+1) begin
      case(k%8)
        0,5: begin len=2;word=64'h0001+((k&31)<<7);end
        4: begin len=8;word={32'h0a00305b,32'h0200305b};end
        default: begin len=4;word=32'h00100413+((k&511)<<20);end
      endcase
      addresses[ninst]=pos;ninst=ninst+1;
      lengths[pos]=len; words[pos]=word;
      for(j=0;j<len;j=j+1) mem[pos+j]=word>>(j*8);
      pos=pos+len;
    end
    repeat(3) @(negedge clk);
    rst=0;run=1;
    for(cycle=0;cycle<3500;cycle=cycle+1) begin
      random_q=rng(random_q);
      req_allow=random_q[0]||random_q[3];
      redirect=0; consume=0;
      // Multiple redirects during outstanding/backpressured requests, without
      // epoch wrap assumptions. A target always names an instruction boundary.
      if(cycle%61==20 || (cycle>=300&&cycle<309)) begin
        redirect=1;target=64'h80000000+addresses[random_q[15:6]%1200];
      end
      if(!redirect&&valid[0]&&random_q[1]) begin
        consume=(valid[1]&&random_q[2])?2:1;
      end
      rsp_valid=(qh<qt && due[qh]<=cycle);
      if(rsp_valid) begin
        idx=(qpc[qh]-64'h80000000)%16384;
        for(j=0;j<16;j=j+1) rsp_data[j*8+:8]=mem[(idx+j)%16384];
      end
      @(negedge clk);
    end
    // Deterministic full-bandwidth region: every consumed bundle must have
    // two instructions once both alignment blocks have been filled.
    redirect=1;target=64'h80000000;consume=0;
    @(negedge clk);redirect=0;
    for(cycle=3500;cycle<3900;cycle=cycle+1) begin
      req_allow=1;consume=valid[1]?2:0;
      rsp_valid=qh<qt;
      if(rsp_valid) begin
        idx=(qpc[qh]-64'h80000000)%16384;
        for(j=0;j<16;j=j+1) rsp_data[j*8+:8]=mem[(idx+j)%16384];
      end
      if(cycle>=3550&&!valid[1]) $fatal(1,"steady frontend bubble");
      @(negedge clk);
    end
    // Tensor low word at byte 14 straddles blocks; a second-page fault must
    // identify byte 16 while retaining instruction PC=14.
    redirect=1;target=64'h8000000e;consume=0;inject_block=1;
    @(negedge clk);redirect=0;
    for(cycle=3900;cycle<3950&&faults==0;cycle=cycle+1) begin
      req_allow=1;consume=valid[0]?1:0;rsp_valid=qh<qt;
      if(rsp_valid) begin
        idx=(qpc[qh]-64'h80000000)%16384;
        for(j=0;j<16;j=j+1) rsp_data[j*8+:8]=mem[(idx+j)%16384];
        rsp_fault=(idx==16);rsp_cause=12;
      end
      @(negedge clk);
    end
    if(faults!=1||dual<300||blocked<100||redirs<50||accepted-returned>4)
      $fatal(1,"coverage dual=%d blocked=%d redirects=%d fault=%d",dual,blocked,redirs,faults);
    $display("[PASS] tb_r64_fetch");
    $display("COVERAGE accepted=%0d returned=%0d retired=%0d dual=%0d blocked=%0d redirects=%0d faults=%0d",
      accepted,returned,retired,dual,blocked,redirs,faults);
    $finish;
  end
endmodule
