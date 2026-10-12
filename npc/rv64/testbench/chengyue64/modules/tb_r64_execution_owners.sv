`timescale 1ns/1ps
// Independent full-tag/value-lease truth table. No ROB or execution pipeline
// is instantiated, so neither a copied backend nor its timing is the oracle.
module tb_r64_execution_owners;
  reg clk=0; always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] kill=0;
  reg [1:0] birth=0,wr=0,fp=0,wb=0;
  reg [17:0] tags=0,wb_tags=0;
  reg [11:0] preg=0;
  reg [3:0] qv=0;
  reg [35:0] qt=0;
  reg [23:0] qp=0;
  wire [3:0] accept;
  R64ExecutionOwners dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
    .birth_load_i(2'b0),.load_capture_i(2'b0),.load_tag_i(18'b0),
    .load_promise_o(),.load_preg_o(),.birth_i(birth),.birth_write_i(wr),.birth_fp_i(fp),.birth_tag_i(tags),
    .birth_preg_i(preg),.wb_accept_i(wb),.wb_tag_i(wb_tags),
    .query_valid_i(qv),.query_tag_i(qt),.query_preg_i(qp),.query_accept_o(accept));
  task tick; begin @(posedge clk);#1;@(negedge clk);end endtask
  task expect_mask;
    input[3:0] expected; input[511:0] why;
    begin #1;if(accept!==expected)$fatal(1,"%0s got=%b expected=%b",why,accept,expected);end
  endtask
  initial begin
    tick();rst=0;
    birth=3;wr=3;fp=2;tags={9'd33,9'd32};preg={6'd41,6'd40};tick();birth=0;
    qv=15;qt={9'd33,9'd32,9'd0,9'd32};qp={6'd41,6'd39,6'd40,6'd40};
    expect_mask(1,"full generation, physical destination and FP identity");
    wb=1;wb_tags=0;tick();wb=0;
    expect_mask(1,"stale generation WB destroyed a newer lease");
    wb_tags=32; // Merely presenting a matching tag has no terminal authority.
    tick();expect_mask(1,"unaccepted WB destroyed lease");
    wb=1;tick();wb=0;expect_mask(0,"accepted WB failed to terminate lease");
    birth=1;wr=1;fp=0;tags=64;preg=42;tick();birth=0;
    qt={9'd64,9'd32,9'd64,9'd64};qp={6'd0,6'd40,6'd42,6'd42};
    expect_mask(3,"slot reuse retained old-generation destination");
    kill=1;expect_mask(0,"local selective cancellation exposed fast value");tick();kill=0;
    expect_mask(0,"cancelled lease returned after event");
    birth=1;wr=1;tags=96;preg=43;tick();birth=0;
    qt={4{9'd96}};qp={4{6'd43}};expect_mask(15,"post-cancel generation birth");
    flush=1;expect_mask(0,"full flush exposed fast value");tick();flush=0;
    expect_mask(0,"flush did not terminate all leases");
    birth=1;wr=0;tags=128;preg=44;tick();birth=0;
    qt={4{9'd128}};qp={4{6'd44}};expect_mask(0,"non-writer acquired a fast lease");
    $display("[PASS] tb_r64_execution_owners fulltag/preg/FP/WB/stale/reuse/kill/flush");$finish;
  end
endmodule
