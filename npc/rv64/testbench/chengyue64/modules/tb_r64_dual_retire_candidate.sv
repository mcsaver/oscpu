`timescale 1ns/1ps
`include "R64Protocol.vh"
module tb_r64_dual_retire_candidate;
  parameter N3=1;
  parameter M=204;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0,kill=0,preview=0;
  reg [8:0] boundary=0;
  reg [1:0] alloc=0,writes=0,serial=0,fp=0,wb=0,wx=0,ready=0;
  reg [2*M-1:0] metadata=0;
  reg [17:0] wt=0;
  wire [1:0] ar,wa,cv;
  wire [17:0] at,ct;
  wire [5:0] count;
  wire [4:0] head;
  wire [31:0] kills;
  wire candidate,recover;
  wire [8:0] tag;
  reg [17:0] first;
  reg [8:0] third,old_third;
  integer checks=0,cases=0;
  localparam EXPECT=(N3!=0&&M>=204);
  R64Rob #(.DUAL_RETIRE_STORE_LEASE(N3),.META_W(M)) dut(
    .serial_retire_candidate_o(),
    .batch_apply_o(),.batch_mask_o(),.batch_head_o(),.batch_desc_o(),

    .clk(clk),.rst(rst),.flush_i(flush),.kill_pending_i(1'b0),
    .kill_valid_i(kill),.kill_tag_i(boundary),
    .recovery_preview_valid_i(preview),.recovery_preview_tag_i(boundary),
    .reuse_block_i(32'b0),.resolve_valid_i(1'b0),.resolve_tag_i(9'b0),.resolve_npc_i(64'b0),
    .alloc_valid_i(alloc),.alloc_ready_o(ar),.alloc_tag_o(at),.alloc_meta_i(metadata),
    .alloc_rd_write_i(writes),.alloc_rd_fp_i(fp),.alloc_serial_i(serial),
    .alloc_rd_arch_i(10'b0),.alloc_pnew_i(12'b0),.alloc_pold_i(12'b0),
    .store_done_valid_i(1'b0),.store_done_tag_i(9'b0),.store_done_error_i(1'b0),.store_done_tval_i(64'b0),
    .owner_query_tag_i(18'b0),.wb_owner_cert_i(18'b0),
    .wb_valid_i(wb),.wb_tag_i(wt),.wb_data_i(128'b0),.wb_exception_i(wx),
    .wb_cause_i({6'd15,6'd15}),.wb_tval_i(128'h188),.wb_fflags_i(10'b0),.wb_accept_o(wa),
    .short_valid_i(4'b0),.short_tag_i(36'b0),.short_preg_i(24'b0),
    .commit_ready_i(ready),.commit_valid_o(cv),.commit_tag_o(ct),
    .count_o(count),.head_slot_o(head),.kill_mask_o(kills),.recover_o(recover),
    .pair_store_candidate_valid_o(candidate),.pair_store_candidate_tag_o(tag)
  );
  task tick;begin @(posedge clk);#1;end endtask
  task check(input condition,input[767:0]message);
    begin checks+=1;if(condition!==1'b1)$fatal(1,"%0s",message);end
  endtask
  function[M-1:0] md(input[7:0]kind);md=M'(kind)<<196;endfunction
  task reset_phase;
    begin rst=1;alloc=0;writes=0;serial=0;fp=0;wb=0;wx=0;ready=0;flush=0;kill=0;preview=0;
      repeat(2)tick;rst=0;tick;end
  endtask
  task prefix;
    begin alloc=3;metadata={md(`R64_K_BRANCH),md(`R64_K_NORMAL)};writes=3;serial=0;#1;
      check(ar==3,"prefix resources");first=at;tick;alloc=0;writes=0;end
  endtask
  task push_third(input[7:0]kind,input writer,input serialized);
    begin alloc=1;metadata={M'(0),md(kind)};writes={1'b0,writer};serial={1'b0,serialized};#1;
      check(ar[0],"third resources");third=at[8:0];tick;alloc=0;writes=0;serial=0;#1;
      check(tag==third,"third tag not actual Q generation/slot");end
  endtask
  task finish_prefix;
    begin wb=3;wt=first;wx=0;#1;check(wa==3,"prefix WB not accepted");tick;wb=0;end
  endtask
  task check_candidate(input expect_valid);
    begin #1;check(candidate==(EXPECT&&expect_valid),"third candidate eligibility mismatch");cases+=1;end
  endtask
  initial begin
    // Kind is resident metadata, not a third wide retirement bus.
    for(integer k=0;k<17;k+=1)begin
      reset_phase;prefix;push_third(8'(k),0,0);check_candidate(k==`R64_K_STORE);
    end
    reset_phase;prefix;push_third(`R64_K_STORE,1,0);check_candidate(0);
    reset_phase;prefix;push_third(`R64_K_STORE,0,1);check_candidate(0);
    // Completion of the third owner is projected into validity immediately,
    // including a fault, while the full-tag data identity remains unchanged.
    for(integer fault=0;fault<2;fault+=1)begin
      reset_phase;prefix;push_third(`R64_K_STORE,0,0);check_candidate(1);
      wt={9'b0,third};wb=1;wx=2'(fault);#1;
      check(wa==1&&!candidate&&tag==third,"actual third WB did not suppress current certificate");
      tick;wb=0;wx=0;check_candidate(0);
    end
    reset_phase;prefix;push_third(`R64_K_STORE,0,0);
    wt={9'b0,third^9'h20};wb=1;#1;
    check(wa==0,"stale generation WB was accepted");check_candidate(1);
    check(tag==third,"stale WB changed Q candidate identity");tick;wb=0;check_candidate(1);
    // A same-edge third birth is not a resident candidate on actual retire11.
    reset_phase;prefix;finish_prefix;ready=3;alloc=1;writes=0;
    metadata={M'(0),md(`R64_K_STORE)};#1;
    third=at[8:0];check(count==2&&cv==3&&ar[0]&&!candidate,"same-edge third birth projected into certificate");
    tick;ready=0;alloc=0;
    check(count==1&&ct[8:0]==third&&!candidate,"birth/retire conservation");
    // Count/valid loss and actual accepted recovery revoke the certificate.
    reset_phase;prefix;push_third(`R64_K_STORE,0,0);
    boundary=first[17:9];preview=1;tick;preview=0;kill=1;#1;
    check(kills[third[4:0]]&&!candidate,"accepted kill kept third certificate");
    tick;kill=0;while(recover)tick;check(count==2&&!candidate,"undo retained removed third");
    reset_phase;prefix;push_third(`R64_K_STORE,0,0);flush=1;#1;check(!candidate,"full flush kept certificate");tick;
    flush=0;check(count==0&&!candidate,"empty ROB retained candidate");
    // Advance real allocations/retirements to slot31, then the next third
    // owner wraps through slot0 with its own actual generation.
    reset_phase;
    for(integer n=0;n<15;n+=1)begin
      prefix;finish_prefix;ready=3;tick;ready=0;
    end
    alloc=1;metadata={M'(0),md(`R64_K_NORMAL)};writes=1;#1;old_third=at[8:0];tick;alloc=0;writes=0;
    wb=1;wt={9'b0,old_third};tick;wb=0;ready=1;tick;ready=0;
    check(head==31,"wrap fixture head");
    prefix;push_third(`R64_K_STORE,0,0);
    check(first[4:0]==31&&first[13:9]==0&&third[4:0]==1&&third[8:5]!=0,"wrapped resident identity");
    check_candidate(1);
    wt={9'b0,{4'b0,third[4:0]}};wb=1;#1;check(wa==0,"wrapped stale full tag accepted");check_candidate(1);
    tick;wb=0;finish_prefix;ready=3;tick;ready=0;
    check(ct[8:0]==third&&count==1,"wrapped third was not exact new head");
    $display("[PASS] tb_r64_dual_retire_candidate N3=%0d M=%0d cases=%0d checks=%0d",N3,M,cases,checks);$finish;
  end
  initial begin #50000;$fatal(1,"candidate timeout");end
endmodule
