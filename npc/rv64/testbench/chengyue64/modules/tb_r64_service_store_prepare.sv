`timescale 1ns / 1ps
module tb_r64_service_store_prepare;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1;
  reg pv = 0;
  reg [13:0] pid = 0, cid = 0;
  reg [4:0] pt = 0;
  reg [63:0] pa = 0, pd = 0;
  reg [3:0] cop = 1;
  reg [1:0] cfast = 1;
  integer activations = 0, cache_accepts = 0;
  reg [1:0] cv = 0, crr = 3, kr = 3, krv = 0;
  reg [9:0] ct = 0;
  reg [127:0] ca = 0, cd = 0, krd = 0;
  reg [2:0] av = 0, arr = 7;
  reg [191:0] aa = 0;
  reg [ 13:0] krt = 0;
  wire [1:0] cr, crv, cre, kv, krr, kcache;
  wire [9:0] crt;
  wire [127:0] crd, ka, kd, kx;
  wire [2:0] ar, arv, are, arc;
  wire [191:0] ard;
  wire [13:0] kt;
  wire [3:0] ko;
  wire [5:0] kz;
  wire [15:0] ks;
  wire [9:0] km;
  wire idle;
  reg store_valid = 0, store_ready = 0, store_error = 0;
  reg [6:0] store_token = 0;
  wire store_return_valid, store_return_ready, store_return_error;
  wire [4:0] store_return_token;
  R64MemoryService #(
    .CPU_PREPARE_HINTS(1), .PREPARE_ID_W(14),
    .AUX  (3),
    .SRC_W(2)
  ) dut (
    .cpu_prepare_valid_i(pv), .cpu_prepare_id_i(pid), .cpu_identity_i(cid),
    .cpu_prepare_token_i(pt), .cpu_prepare_addr_i(pa), .cpu_prepare_data_i(pd),
    .cpu_prepare_size_i(3'd3), .cpu_prepare_strb_i(8'hff), .cpu_prepare_amo_i(5'd0),
    .cpu_fast_store_i(cfast), .cpu_request_i(cv),
    .clk_i(clk),
    .rst_i(rst),
    .cpu_store_rsp_valid_o(store_return_valid),
    .cpu_store_rsp_ready_i(store_ready),
    .cpu_store_rsp_token_o(store_return_token),
    .cpu_store_rsp_error_o(store_return_error),
    .cache_store_rsp_valid_i(store_valid),
    .cache_store_rsp_ready_o(store_return_ready),
    .cache_store_rsp_token_i(store_token),
    .cache_store_rsp_error_i(store_error),
    .cpu_valid_i(cv),
    .cpu_ready_o(cr),
    .cpu_token_i(ct),
    .cpu_addr_i(ca),
    .cpu_data_i(cd),
    .cpu_op_i(cop),
    .cpu_cache_i(2'b11),
    .cpu_size_i(6'h1b),
    .cpu_strb_i(16'h00ff),
    .cpu_amo_i(10'b0),
    .cpu_rsp_valid_o(crv),
    .cpu_rsp_ready_i(crr),
    .cpu_rsp_token_o(crt),
    .cpu_rsp_data_o(crd),
    .cpu_rsp_error_o(cre),
    .aux_valid_i(av),
    .aux_ready_o(ar),
    .aux_addr_i(aa),
    .aux_data_i(192'b0),
    .aux_expected_i(192'b0),
    .aux_op_i(6'b0),
    .aux_cache_i(3'b111),
    .aux_size_i(9'hdb),
    .aux_strb_i(24'b0),
    .aux_rsp_valid_o(arv),
    .aux_rsp_ready_i(arr),
    .aux_rsp_data_o(ard),
    .aux_rsp_error_o(are),
    .aux_rsp_compare_o(arc),
    .cache_valid_o(kv),
    .cache_ready_i(kr),
    .cache_token_o(kt),
    .cache_addr_o(ka),
    .cache_data_o(kd),
    .cache_expected_o(kx),
    .cache_op_o(ko),
    .cache_cache_o(kcache),
    .cache_size_o(kz),
    .cache_strb_o(ks),
    .cache_amo_o(km),
    .cache_rsp_valid_i(krv),
    .cache_rsp_ready_o(krr),
    .cache_rsp_token_i(krt),
    .cache_rsp_data_i(krd),
    .cache_rsp_error_i(2'b0),
    .cache_rsp_compare_i(2'b0),
    .idle_o(idle)
  );
  task tick;
    begin @(negedge clk); #1; end
  endtask
  task clear;
    begin
      rst=1; cv=0; av=0; pv=0; krv=0; kr=3; cfast=1; cop=1;
      tick(); rst=0; tick();
    end
  endtask
  task prepare;
    input [13:0] identity;
    input [4:0] token;
    input [63:0] address, data;
    begin
      pv=1; pid=identity; pt=token; pa=address; pd=data;
      tick();
    end
  endtask
  task request;
    input [13:0] identity;
    input [4:0] token;
    input [63:0] address, data;
    begin cid=identity; ct=token; ca=address; cd=data; cv=1; #1; end
  endtask
  always @(posedge clk) if(!rst) begin
    if(dut.prepare_fire_w) activations=activations+1;
    if(kv[0] && kr[0]) cache_accepts=cache_accepts+1;
  end
  initial begin
    clear();
    prepare(14'h125,5'd5,64'h80001008,64'haabbccdd);
    repeat(5) begin
      if(kv || !idle) $fatal(1,"hint created cache/service owner without real request");
      tick();
    end
    request(14'h125,5'd5,64'h80001008,64'haabbccdd);
    if(!cr[0] || !kv[0] || !dut.prepare_fire_w || kt[6:0]!=5 ||
        ka[63:0]!=ca[63:0] || kd[63:0]!=cd[63:0])
      $fatal(1,"matching store did not activate registered preparation");
    tick(); cv=0; pv=0; #1;
    if(!idle || dut.valid_q[0]!=0) $fatal(1,"direct activation allocated duplicate queue owner");

    // A stalled activation falls back to ordinary queue capture immediately;
    // later hint replacement cannot change the retained packet.
    clear(); prepare(14'h226,6,64'h80002000,64'h11112222); kr=0;
    request(14'h226,6,64'h80002000,64'h11112222);
    if(!cr[0] || !kv[0] || dut.prepare_fire_w) $fatal(1,"blocked cache changed CPU admission");
    tick(); cv=0;
    prepare(14'h327,7,64'h80003000,64'hbad);
    repeat(4) begin
      if(kv!=1 || ka[63:0]!=64'h80002000 || kd[63:0]!=64'h11112222 || kt[6:0]!=6)
        $fatal(1,"hint replacement mutated accepted stalled owner");
      tick();
    end
    kr=3; tick(); pv=0; tick();
    if(!idle) $fatal(1,"fallback queue failed to drain");

    // Same LSQ slot with different generation must use real request payload.
    clear(); prepare(14'h125,5,64'h80001008,64'hbad);
    request(14'h525,5,64'h80005008,64'h55556666);
    if(kv || dut.prepare_fire_w || !cr[0]) $fatal(1,"stale full identity activated");
    tick(); cv=0; pv=0; #1;
    if(kv!=1 || ka[63:0]!=64'h80005008 || kd[63:0]!=64'h55556666)
      $fatal(1,"stale hint blocked or corrupted real fallback");
    tick();

    // Hint owns no priority: a waiting page walker wins its RR turn.
    clear(); prepare(14'h628,8,64'h80006000,64'h7777);
    av=1; aa=64'h80007000;
    request(14'h628,8,64'h80006000,64'h7777);
    if(!ar[0] || cr[0] || dut.prepare_fire_w || kv)
      $fatal(1,"young hint displaced older auxiliary arbitration");
    tick(); av=0; #1;
    if(kv!=1 || ka[63:0]!=64'h80007000 || dut.prepare_fire_w)
      $fatal(1,"nonempty queue allowed prepared overtaking");
    // The CPU request may now enter the ordinary second slot, behind the PTE.
    if(!cr[0]) $fatal(1,"real head store blocked by stale hint");
    tick(); cv=0; pv=0; #1;
    if(kv!=1 || ka[63:0]!=64'h80006000 || kd[63:0]!=64'h7777)
      $fatal(1,"real request lost behind older PTE");
    tick();

    clear(); request(14'h729,9,64'h80008000,64'h9999);
    if(kv || !cr[0]) $fatal(1,"missing hint did not use ordinary path");
    tick(); cv=0; #1;
    if(kv!=1 || ka[63:0]!=64'h80008000) $fatal(1,"missing-hint fallback lost");
    tick();
    if(activations!=1 || cache_accepts!=6)
      $fatal(1,"non-vacuous activation/terminal count %0d %0d",activations,cache_accepts);
    $display("[PASS] tb_r64_service_store_prepare activations=%0d cache_accepts=%0d no-owner stale-full-id backpressure aux-priority fallback",activations,cache_accepts);
    $finish;
  end
  initial begin #10000; $fatal(1,"timeout"); end
endmodule
