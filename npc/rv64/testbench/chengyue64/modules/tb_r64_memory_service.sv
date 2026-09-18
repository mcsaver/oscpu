`timescale 1ns/1ps
module tb_r64_memory_service;
 reg clk=0;always #5 clk=~clk;
 reg rst=1;reg [1:0] cv=0,crr=3,kr=3,krv=0;
 reg [9:0] ct=0;reg [127:0] ca=0,cd=0,krd=0;
 reg [2:0] av=0,arr=7;reg [191:0] aa=0;
 reg [13:0] krt=0;
 wire [1:0] cr,crv,cre,kv,krr,kcache;wire [9:0] crt;wire [127:0] crd,ka,kd,kx;
 wire [2:0] ar,arv,are,arc;wire [191:0] ard;wire [13:0] kt;
 wire [3:0] ko;wire [5:0] kz;wire [15:0] ks;wire [9:0] km;wire idle;
 R64MemoryService #(.AUX(3),.SRC_W(2)) dut(
  .clk_i(clk),.rst_i(rst),.cpu_valid_i(cv),.cpu_ready_o(cr),.cpu_token_i(ct),
  .cpu_addr_i(ca),.cpu_data_i(cd),.cpu_op_i(4'b0),.cpu_cache_i(2'b11),
  .cpu_size_i(6'h1b),.cpu_strb_i(16'b0),.cpu_amo_i(10'b0),
  .cpu_rsp_valid_o(crv),.cpu_rsp_ready_i(crr),.cpu_rsp_token_o(crt),.cpu_rsp_data_o(crd),.cpu_rsp_error_o(cre),
  .aux_valid_i(av),.aux_ready_o(ar),.aux_addr_i(aa),.aux_data_i(192'b0),.aux_expected_i(192'b0),
  .aux_op_i(6'b0),.aux_cache_i(3'b111),.aux_size_i(9'hdb),.aux_strb_i(24'b0),
  .aux_rsp_valid_o(arv),.aux_rsp_ready_i(arr),.aux_rsp_data_o(ard),.aux_rsp_error_o(are),.aux_rsp_compare_o(arc),
  .cache_valid_o(kv),.cache_ready_i(kr),.cache_token_o(kt),.cache_addr_o(ka),.cache_data_o(kd),
  .cache_expected_o(kx),.cache_op_o(ko),.cache_cache_o(kcache),.cache_size_o(kz),.cache_strb_o(ks),.cache_amo_o(km),
  .cache_rsp_valid_i(krv),.cache_rsp_ready_o(krr),.cache_rsp_token_i(krt),.cache_rsp_data_i(krd),
  .cache_rsp_error_i(2'b0),.cache_rsp_compare_i(2'b0),.idle_o(idle));
 initial begin
  repeat(3)@(negedge clk);rst=0;
  cv=1;ct=5;ca=64'h80001000;
  @(negedge clk);cv=0;
  if(kv!=1||kt[6:0]!=5)$fatal(1,"initial CPU request missing");
  @(negedge clk);
  krv=1;krt=5;krd=64'h55;#1;
  if(crv!=1||crt[4:0]!=5||crd[63:0]!=64'h55)$fatal(1,"initial return routing");
  @(negedge clk);krv=0;
  // Previous CPU admission advanced round-robin to auxiliary zero. Both
  // holders are available, so auxiliary -> zero and CPU zero -> holder one.
  cv=1;ct=9;ca=64'h80003038;av=1;aa=64'h80002010;#1;
  if(!cr[0]||!ar[0])$fatal(1,"dual CPU/PTW admission missing");
  @(negedge clk);cv=0;av=0;kr=0;#1;
  if(kv!=3||kt[6:0]!=7'h20||kt[13:7]!=9||ka[127:64]!=64'h80003038)
   $fatal(1,"accepted rerouted CPU request was erased by destination clear");
  repeat(4)begin @(negedge clk);if(kv!=3)$fatal(1,"held physical request changed");end
  kr=3;@(negedge clk);kr=0;
  krv=3;krt={7'd9,7'h20};krd={64'h99,64'haa};crr=0;arr=0;#1;
  if(crv!=2||krr!=1||crt[9:5]!=9)$fatal(1,"response routing/backpressure");
  @(negedge clk);krv=2;
  if(arv!=1||ard[63:0]!=64'haa)$fatal(1,"PTW completion lost");
  repeat(4)begin @(negedge clk);if(crv!=2||arv!=1)$fatal(1,"held return changed");end
  crr=3;arr=7;@(negedge clk);krv=0;
  @(negedge clk);if(!idle)$fatal(1,"owners did not drain");
  $display("[PASS] tb_r64_memory_service");$finish;
 end
 initial begin #10000;$fatal(1,"timeout");end
endmodule
