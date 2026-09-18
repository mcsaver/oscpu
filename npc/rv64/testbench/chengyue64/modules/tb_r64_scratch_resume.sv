`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_scratch_resume;
 localparam M=`R64_META_W;
 reg clk=0;always #5 clk=~clk;
 reg rst=1;reg [1:0] rv=0,rx=0,rs=0;
 reg [2*M-1:0] meta=0;reg irq=0;
 wire [1:0] rr,fire;wire flush,sc,trap,prep;wire [63:0] epc;
 R64Commit #(.SCRATCH_READ_RESUME(1),.HEAD_SERIAL_CLASS(1),.HEAD_SERIAL_STOP(1)) dut(
 .clk_i(clk),.rst_i(rst),.rob_serial_i({(meta[M+196+:8]>=`R64_K_CSR&&meta[M+196+:8]<=`R64_K_TENSOR),
     (meta[196+:8]>=`R64_K_CSR&&meta[196+:8]<=`R64_K_TENSOR)}),.rob_valid_i(rv),.rob_ready_o(rr),
 .rob_tag_i(18'd32),.rob_meta_i(meta),.rob_data_i(128'd0),.rob_exception_i(rx),
 .rob_cause_i(12'd2),.rob_tval_i(128'd0),.rob_rd_write_i(2'd1),.rob_rd_fp_i(2'd0),.rob_fflags_i(10'd0),
 .retire_ready_i(2'd3),.head_exception_i(|rx),.head_serial_i(rs[0]),
 .rob_empty_i(rv==0),.recover_i(1'b0),.lsu_irrevocable_i(1'b0),.serial_irrevocable_i(1'b0),
 .irq_pending_i(irq),.irq_cause_i(6'd7),.trap_target_i(64'h2000),
 .retire_fire_o(fire),.serial_commit_o(sc),.full_flush_o(flush),.trap_o(trap),
 .trap_pc_o(epc),.trap_prepare_o(prep));
 task tick;begin @(posedge clk);#1;end endtask
 task check;input c;input [511:0] msg;begin if(c!==1'b1)$fatal(1,"%0s",msg);end endtask
 task setup;input [31:0] ins;input [7:0] kind;
 begin
  rst=1;rv=0;rx=0;rs=0;irq=0;tick();rst=0;
  meta=0;meta[0+:64]=64'h1000;meta[64+:32]=ins;meta[128+:64]=64'h1004;
  meta[192+:4]=4;meta[196+:8]=kind;rs=1;rv=1;#1;
 end endtask
 task op;input [31:0] ins;input [7:0] kind;input resume;
 begin
  setup(ins,kind);check(sc&&fire==1&&!flush,"serial effect not at original commit edge");
  tick();rv=0;rs=0;#1;
  check(flush==!resume&&!trap,"serial restart whitelist mismatch");
  if(resume)begin
   meta=0;meta[192+:4]=4;rv=1;#1;
   check(fire==1&&!flush,"scratch read unnecessarily discarded the next ordinary owner");
  end
  tick();
 end endtask
 initial begin
  op(32'h340020f3,`R64_K_CSR,1);op(32'h340030f3,`R64_K_CSR,1);
  op(32'h340060f3,`R64_K_CSR,1);op(32'h140070f3,`R64_K_CSR,1);
  op(32'h340010f3,`R64_K_CSR,0);op(32'h3400a0f3,`R64_K_CSR,0);
  op(32'h300020f3,`R64_K_CSR,0);op(32'h0000000f,`R64_K_FENCE,0);
  setup(32'h340020f3,`R64_K_CSR);rx=1;#1;
  check(!sc&&!fire&&!flush,"faulting scratch access retired");tick();rv=0;rs=0;rx=0;
  check(prep&&!flush,"fault lost trap preparation");tick();
  check(flush&&trap&&epc==64'h1000,"faulting scratch access skipped precise trap");
  setup(32'h340020f3,`R64_K_CSR);irq=1;#1;
  check(sc&&!flush,"pending IRQ prevented existing scratch owner retirement");
  tick();rv=0;rs=0;#1;check(!flush,"scratch read inserted a restart before IRQ");
  tick();irq=0;check(prep&&!flush,"IRQ failed to prepare after ROB drain");
  tick();check(flush&&trap&&epc==64'h1004,"IRQ used the wrong retired NPC");
  $display("[PASS] tb_r64_scratch_resume whitelist/write/context/fault/IRQ/next-owner");
  $finish;
 end
endmodule
