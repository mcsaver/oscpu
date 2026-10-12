`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_store_response_elastic;
  parameter ELASTIC = 1;
  parameter DEPTH = 6;
  parameter EARLY_STORE = 1;
  localparam IW = $clog2(DEPTH);
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0;
  reg [31:0] kill = 0;
  reg [ 2:0] trigger_enable = 0;
  reg [63:0] trigger_address = 0;
  reg trigger_test = 0, no_external = 0;
  reg [8:0] full_tag[0:31];
  reg head_valid = 1, effect_allow = 1, fp_enable = 1;
  reg [8:0] head_tag = 0;
  reg [1:0] commit_fire = 0;
  reg [17:0] commit_tag = 0;
  reg [1:0] in_fire = 0;
  wire [1:0] in_ready;
  reg [17:0] in_tag = 0;
  reg [2*`R64_UOP_W-1:0] in_uop = 0;
  reg [383:0] operand = 0;
  wire [1:0] out_valid;
  reg [1:0] out_ready = 3;
  wire [17:0] out_tag;
  wire [2*`R64_RESULT_W-1:0] out_result;
  wire [31:0] reuse;
  wire irreversible, idle;
  wire [1:0] tv, tr, tad, tresp, trespready;
  wire [2*IW-1:0] ttoken, trtoken;
  R64TranslationTokenEcho #(.TOKEN_W(IW)) translation_model_tokens (
    .clk_i(clk), .rst_i(rst), .req_fire_i(tv & tr), .req_token_i(ttoken),
    .rsp_fire_i(tresp & trespready), .rsp_token_o(trtoken)
  );
  wire [127:0] tva, tpa;
  wire [3:0] ta, tc;
  wire [1:0] tfault, tneeds;
  wire [9:0] tcause;
  wire [1:0] mv, mr, mcache, mresp, mrespready, merror;
  wire [2*IW-1:0] mtoken, mresptoken;
  wire [127:0] ma, md, mrd;
  wire [3:0] mop;
  wire [5:0] msize;
  wire [15:0] mstrb;
  wire [9:0] mamo;
  // TB-only front-end: previous stimuli reserve in program order, then
  // bind the captured payload one edge later to the real dispatch-owned LSU.
  reg [1:0] bind_fire_q = 0;
  reg [17:0] bind_tag_q = 0;
  reg [2*`R64_UOP_W-1:0] bind_uop_q = 0;
  reg [383:0] bind_operand_q = 0;
  reg [2*IW-1:0] bind_slot_q = 0;
  wire [2*IW-1:0] reserve_slot_w;
  always @(posedge clk) begin
    if (rst || flush) bind_fire_q <= 0;
    else bind_fire_q <= in_fire;
    if (|in_fire) begin
      bind_tag_q <= in_tag;
      bind_uop_q <= in_uop;
      bind_operand_q <= operand;
      bind_slot_q <= reserve_slot_w;
    end
  end
  wire sd_valid, sd_error, b_ready;
  wire [8:0] sd_tag;
  wire [63:0] sd_tval;
  wire [1:0] fast_store;
  reg sd_ready=1, b_valid=0, b_error=0;
  reg [IW-1:0] b_slot=0;
  R64Lsu #(
    .STORE_RESPONSE_ELASTIC(ELASTIC),
    .EARLY_STORE(EARLY_STORE),
    .ENTRIES(DEPTH),
    .INDEX_W(IW)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .flush_i(flush),
    .kill_mask_i(kill),
    .cancel_candidates_i(32'b0),.cancel_active_i(1'b0),
    .head_valid_i(head_valid),
    .head_tag_i(head_tag),
    .effect_allow_i(effect_allow),
    .trigger_enable_i(trigger_enable),
    .trigger_address_i(trigger_address),
    .fp_enable_i(fp_enable),
    .translate_active_i(1'b0),
    .store_done_valid_o(sd_valid),
    .store_done_ready_i(sd_ready),
    .store_done_tag_o(sd_tag),
    .store_done_error_o(sd_error),
    .store_done_tval_o(sd_tval),
    .mem_fast_store_o(fast_store),
    .mem_store_rsp_valid_i(b_valid),
    .mem_store_rsp_ready_o(b_ready),
    .mem_store_rsp_token_i(b_slot),
    .mem_store_rsp_error_i(b_error),
    .commit_fire_i(commit_fire),
    .commit_tag_i(commit_tag),
    .reserve_want_i(2'b11),
    .reserve_fire_i(in_fire),
    .reserve_ready_o(in_ready),
    .reserve_slot_o(reserve_slot_w),
    .reserve_tag_i(in_tag),
    .reserve_func_i({in_uop[`R64_UOP_W+196+:8], in_uop[196+:8]}),
    .reserve_amo_i({in_uop[`R64_UOP_W+155+:5], in_uop[155+:5]}),
    .in_fire_i(bind_fire_q),
    .in_ready_o(),
    .in_tag_i(bind_tag_q),
    .in_slot_i(bind_slot_q),
    .in_command_i({bind_uop_q[1*`R64_UOP_W+155+:5], bind_uop_q[1*`R64_UOP_W+196+:8], bind_operand_q[1*192+64+:64], bind_uop_q[1*`R64_UOP_W+64+:64], bind_operand_q[1*192+:64], bind_uop_q[0*`R64_UOP_W+155+:5], bind_uop_q[0*`R64_UOP_W+196+:8], bind_operand_q[0*192+64+:64], bind_uop_q[0*`R64_UOP_W+64+:64], bind_operand_q[0*192+:64]}),
    .out_valid_o(out_valid),
    .out_ready_i(out_ready),
    .out_tag_o(out_tag),
    .out_result_o(out_result),
    .reuse_block_o(reuse),
    .irrevocable_o(irreversible),
    .idle_o(idle),
    .tr_token_o(ttoken),
    .tr_rsp_token_i(trtoken),
    .tr_valid_o(tv),
    .tr_ready_i(tr),
    .tr_vaddr_o(tva),
    .tr_access_o(ta),
    .tr_ad_update_o(tad),
    .tr_rsp_valid_i(tresp),
    .tr_rsp_ready_o(trespready),
    .tr_paddr_i(tpa),
    .tr_class_i(tc),
    .tr_fault_i(tfault),
    .tr_needs_ad_i(tneeds),
    .tr_cause_i(tcause),
    .mem_valid_o(mv),
    .mem_ready_i(mr),
    .mem_token_o(mtoken),
    .mem_addr_o(ma),
    .mem_data_o(md),
    .mem_op_o(mop),
    .mem_cache_o(mcache),
    .mem_size_o(msize),
    .mem_strb_o(mstrb),
    .mem_amo_o(mamo),
    .mem_rsp_valid_i(mresp),
    .mem_rsp_ready_o(mrespready),
    .mem_rsp_token_i(mresptoken),
    .mem_rsp_data_i(mrd),
    .mem_rsp_error_i(merror),
    .mem_rsp_offset_i(6'b0)
  );

  reg [1:0] translation_pending=0;
  reg [127:0] translation_address=0;
  assign tr=~translation_pending;
  assign tresp=translation_pending;
  assign tpa=translation_address;
  assign tc=0;
  assign tfault=0;
  assign tneeds=0;
  assign tcause=0;
  assign mr=3;
  assign mresp=0;
  assign mresptoken=0;
  assign mrd=0;
  assign merror=0;
  integer cycles=0, physical_count=0, terminal_count=0, b_count=0;
  integer last_b=-1,last_terminal=-1;
  reg [IW-1:0] last_slot;
  always @(posedge clk) begin
    if(rst) translation_pending<=0;
    else begin
      cycles=cycles+1;
      for(integer i=0;i<2;i=i+1) begin
        if(tresp[i]&&trespready[i]) translation_pending[i]<=0;
        if(tv[i]&&tr[i]) begin
          translation_pending[i]<=1;
          translation_address[i*64+:64]<=tva[i*64+:64];
        end
        if(mv[i]&&mr[i]) begin
          if(!fast_store[i]||mop[i*2+:2]!=1)
            $fatal(1,"expected actual fast store request");
          last_slot=mtoken[i*IW+:IW];
          physical_count=physical_count+1;
        end
      end
      if(b_valid&&b_ready)begin b_count=b_count+1;last_b=cycles;end
      if(sd_valid&&sd_ready)begin
        terminal_count=terminal_count+1;last_terminal=cycles;
      end
      if(out_valid!=0)$fatal(1,"fast store duplicated through CQ");
    end
  end
  task tick;
    begin @(negedge clk);end
  endtask
  task reserve_store;
    input [8:0] tag;
    input [63:0] address;
    integer old_count,limit;
    begin
      tick;
      head_tag=tag;
      old_count=physical_count;
      in_fire=1;in_tag={9'b0,tag};in_uop=0;operand=0;
      in_uop[196+:8]=8'h23;operand[63:0]=address;operand[127:64]=64'h123456789abcdef0;
      if(!in_ready[0])$fatal(1,"reserve lacked credit");
      tick;in_fire=0;
      limit=0;
      while(physical_count==old_count&&limit<100)begin tick;limit=limit+1;end
      if(physical_count!=old_count+1)$fatal(1,"store did not reach physical accept");
      b_slot=last_slot;
      if(sd_valid)$fatal(1,"store completed before real B");
      repeat(3)begin tick;if(sd_valid)$fatal(1,"store completed during B delay");end
    end
  endtask
  task local_retire;
    input [8:0] tag;
    begin
      // Memory normally registers backend retire before LSQ sees it.
      tick;commit_fire=1;commit_tag={9'b0,tag};
      tick;commit_fire=0;
      repeat(3)tick;
      if(reuse[tag[4:0]]||!idle||irreversible)
        $fatal(1,"store owner did not drain after local retire");
    end
  endtask
  integer start_terminal;
  initial begin
    repeat(4)tick;rst=0;
    // Ready ROB: terminal and actual B at the same edge, no saved duplicate.
    reserve_store(9'd3,64'h80);
    b_valid=1;#1;
    if(!b_ready||sd_valid!==(ELASTIC!=0))
      $fatal(1,"empty direct acceptance qualification");
    if(ELASTIC!=0 && (sd_tag!==9'd3||sd_error||sd_tval!==64'h80))
      $fatal(1,"direct terminal identity");
    tick;b_valid=0;
    if(ELASTIC!=0 && dut.store_done_q)$fatal(1,"direct accept was saved twice");
    if(ELASTIC==0)tick;
    if(last_terminal-last_b!==(ELASTIC!=0?0:1))$fatal(1,"B-to-terminal latency mismatch");
    $display("STORE_RESPONSE_LATENCY elastic=%0d cycles=%0d",ELASTIC,last_terminal-last_b);
    local_retire(3);
    // Backpressure saves immutable terminal and blocks replacement B.
    reserve_store(9'd4,64'h88);sd_ready=0;start_terminal=terminal_count;
    b_valid=1;tick;b_valid=0;
    repeat(5)begin
      #1;
      if(!sd_valid||sd_tag!==4||sd_tval!==64'h88||sd_error||b_ready||
         !reuse[4]||terminal_count!=start_terminal)
        $fatal(1,"held B terminal corrupted or consumed");
      tick;
    end
    sd_ready=1;tick;
    if(terminal_count!=start_terminal+1||sd_valid)$fatal(1,"held terminal duplicated");
    local_retire(4);
    // Error carries precise VA and clears external effect ownership. ROB
    // exception handling may then flush; no successful retirement is modeled.
    reserve_store(9'd35,64'h90);sd_ready=0;b_error=1;b_valid=1;
    #1;if(ELASTIC!=0&&(!sd_valid||!sd_error||sd_tag!=35||sd_tval!=64'h90))
      $fatal(1,"direct error identity");
    tick;b_valid=0;b_error=0;
    #1;if(!sd_valid||!sd_error||sd_tag!=35||sd_tval!=64'h90||irreversible)
      $fatal(1,"error terminal failed to retain payload/drain effect");
    sd_ready=1;tick;
    flush=1;tick;flush=0;repeat(4)tick;
    if(!idle||reuse!=0)$fatal(1,"error flush leaked owner");
    // Same architectural row under a new generation must carry its new tag.
    reserve_store(9'd67,64'ha0);b_valid=1;tick;b_valid=0;
    if(ELASTIC==0)tick;
    local_retire(67);
    if(b_count!=4||terminal_count!=4||physical_count!=4)
      $fatal(1,"exactly-once count mismatch");
    $display("[PASS] tb_r64_store_response_elastic real_B ready/held/error generation precise_owner elastic=%0d",ELASTIC);
    $finish;
  end
  initial begin #100000;$fatal(1,"store elastic timeout");end
endmodule
