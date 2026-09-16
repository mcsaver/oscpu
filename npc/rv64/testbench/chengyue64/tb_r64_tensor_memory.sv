`timescale 1ns/1ps
module tb_r64_tensor_memory;
 reg clk_i=0;always #5 clk_i=~clk_i;
 reg rst_i=1;reg [8:0] owner_tag_i=0;
 reg nreq_valid_i=0;wire nreq_ready_o;reg nreq_write_i=0;
 reg [63:0] nreq_addr_i=0,nreq_wdata_i=0;reg [7:0] nreq_wstrb_i=0;
 wire nrsp_valid_o;reg nrsp_ready_i=0;wire [63:0] nrsp_rdata_o;wire nrsp_error_o;
 wire req_valid_o;reg req_ready_i=0;wire req_write_o;
 wire [63:0] req_addr_o,req_wdata_o;wire [7:0] req_wstrb_o;wire [8:0] req_tag_o;
 reg rsp_valid_i=0;wire rsp_ready_o;reg [63:0] rsp_rdata_i=0;reg rsp_error_i=0;reg [8:0] rsp_tag_i=0;
 wire write_admitted_o,idle_o,protocol_error_o;
 R64TensorMemory dut(.*);
 integer n,k,admitted=0;reg [63:0] expected;reg [146:0] saved;
 always @(posedge clk_i)if(!rst_i&&write_admitted_o)admitted+=1;
 initial begin
  repeat(4)@(negedge clk_i);rst_i=0;
  for(n=0;n<32;n=n+1)begin
   @(negedge clk_i);nreq_valid_i=1;owner_tag_i=9'h101^9'(n);
   nreq_write_i=n[0];nreq_addr_i=64'h80000001+64'(n);
   nreq_wdata_i=64'h8967452301efcdab^64'(n);nreq_wstrb_i=n%4==1?8'h55:8'h00;
   @(posedge clk_i);if(!nreq_ready_o)$fatal(1,"free owner not ready");
   @(negedge clk_i);nreq_valid_i=0;
   if(!req_valid_o||idle_o||nreq_ready_o)$fatal(1,"request ownership absent");
   saved={req_tag_o,req_write_o,req_addr_o,req_wdata_o,req_wstrb_o};
   for(k=0;k<3;k=k+1)begin
    @(negedge clk_i);
    if({req_tag_o,req_write_o,req_addr_o,req_wdata_o,req_wstrb_o}!==saved[145:0]||!req_valid_o)
     $fatal(1,"external request unstable");
   end
   req_ready_i=1;@(posedge clk_i);@(negedge clk_i);req_ready_i=0;
   repeat(n%5+1)@(negedge clk_i);
   rsp_valid_i=1;rsp_tag_i=owner_tag_i;rsp_rdata_i=64'h55aa23cc00000101^64'(n);rsp_error_i=n%7==0;
   expected=rsp_rdata_i;
   @(posedge clk_i);if(!rsp_ready_o)$fatal(1,"response not accepted");
   @(negedge clk_i);rsp_valid_i=0;
   for(k=0;k<5;k=k+1)begin
    if(!nrsp_valid_o||nrsp_rdata_o!==expected||nrsp_error_o!==(n%7==0)||idle_o||nreq_ready_o)
     $fatal(1,"held NPU response changed");
    @(negedge clk_i);
   end
   nrsp_ready_i=1;@(posedge clk_i);@(negedge clk_i);nrsp_ready_i=0;
   if(!idle_o||protocol_error_o)$fatal(1,"owner did not release");
  end
  if(admitted!=8)$fatal(1,"dirty admission strobe semantics wrong");
  $display("[PASS] tb_r64_tensor_memory");
  $display("transactions=32 externally_stalled_cycles=96 NPU_response_stalled_cycles=160 nonzero_write_admissions=%0d",admitted);
  $finish;
 end
endmodule
