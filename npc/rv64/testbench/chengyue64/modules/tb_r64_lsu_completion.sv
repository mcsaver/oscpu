`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_lsu_completion;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0;
  reg [31:0] kill = 0;
  reg [ 1:0] fire = 0;
  wire [1:0] ready, valid;
  reg [1:0] consume = 0;
  reg [17:0] tags = 0;
  reg [279:0] packets = 0;
  wire [17:0] output_tag;
  wire [279:0] output_packet;
  wire [31:0] reuse;
  wire idle;
  R64LsuCompletion dut (
    .clk_i(clk),
    .rst_i(rst),
    .flush_i(flush),
    .kill_mask_i(kill),
    .in_fire_i(fire),
    .in_ready_o(ready),
    .in_tag_i(tags),
    .in_result_i(packets),
    .out_valid_o(valid),
    .out_ready_i(consume),
    .out_tag_o(output_tag),
    .out_result_o(output_packet),
    .reuse_block_o(reuse),
    .idle_o(idle)
  );
  integer l, t, returns = 0;
  reg [31:0] live = 0, killed = 0;
  reg [  1:0] held = 0;
  reg [ 17:0] heldtag;
  reg [279:0] heldpacket;
  always @(posedge clk)
    if (!rst) begin
      for (l = 0; l < 2; l = l + 1) begin
        if (held[l] && !flush && !kill[heldtag[l*9+:5]] &&
            (!valid[l] || output_tag[l*9+:9] !== heldtag[l*9+:9] ||
             output_packet[l*140+:140] !== heldpacket[l*140+:140]))
          $fatal(1, "backpressured completion migrated or changed");
        if (valid[l] && consume[l]) begin
          t = output_tag[l*9+:5];
          if (!live[t] || killed[t] || output_packet[l*140+:64] !== 64'h1000 + t)
            $fatal(1, "bad completion");
          live[t] = 0;
          returns = returns + 1;
        end
        if (fire[l]) live[tags[l*9+:5]] = 1;
      end
      held = valid & ~consume;
      heldtag = output_tag;
      heldpacket = output_packet;
    end
  task pair;
    input [4:0] first;
    begin
      @(negedge clk);
      if (ready != 3) $fatal(1, "pair lacks credits");
      fire = 3;
      tags = {4'b0, first + 5'd1, 4'b0, first};
      packets = 0;
      packets[0+:64] = 64'h1000 + first;
      packets[140+:64] = 64'h1001 + first;
      @(negedge clk);
      fire = 0;
    end
  endtask
  initial begin
    repeat (3) @(negedge clk);
    rst = 0;
    pair(0);
    pair(2);
    repeat (5) @(negedge clk);
    if (ready != 0) $fatal(1, "full completion queue overcredits");
    // Kill one tail and the other lane's head; unaffected held head must stay.
    kill   = (32'b1 << 2) | (32'b1 << 1);
    killed = kill;
    @(negedge clk);
    kill = 0;
    repeat (3) @(negedge clk);
    consume = 3;
    repeat (3) @(negedge clk);
    consume = 0;
    if (!idle || returns != 2) $fatal(1, "kill compaction failed");
    pair(4);
    pair(6);
    @(negedge clk);
    flush  = 1;
    killed = killed | 32'hf0;
    @(negedge clk);
    flush = 0;
    if (!idle || reuse != 0) $fatal(1, "flush retained completion");
    pair(8);
    consume = 1;
    repeat (2) @(negedge clk);
    consume = 2;
    repeat (2) @(negedge clk);
    if (!idle || returns != 4) $fatal(1, "asymmetric completion progress");
    // Both old heads cancel while two new results enter the Q-free slots.
    // Incoming publication must survive removal without using the old payload.
    consume = 0;
    pair(10);
    @(negedge clk);
    kill = (32'b1 << 10) | (32'b1 << 11);
    killed = killed | kill;
    fire = 3;
    tags = {9'd13, 9'd12};
    packets[0+:64] = 64'h100c;
    packets[140+:64] = 64'h100d;
    consume = 3;
    #1;
    if (ready != 3 || valid != 0) $fatal(1, "cancel/capture Q credit or visibility");
    @(negedge clk);
    fire = 0;
    kill = 0;
    #1;
    if (valid != 3) $fatal(1, "cancel/capture lost incoming owners");
    repeat (2) @(negedge clk);
    if (!idle || returns != 6) $fatal(1, "cancel/capture drain failed");
    // Consumption and capture in the same lane edge rotate storage ownership.
    consume = 0;
    pair(14);
    @(negedge clk);
    fire = 3;
    tags = {9'd17, 9'd16};
    packets[0+:64] = 64'h1010;
    packets[140+:64] = 64'h1011;
    consume = 3;
    @(negedge clk);
    fire = 0;
    if (valid != 3) $fatal(1, "consume/capture inserted a bubble");
    repeat (2) @(negedge clk);
    if (!idle || returns != 10) $fatal(1, "consume/capture drain failed");
    // A dead first winner leaves port0 empty; the live second must retain
    // its own payload/lane while WB is blocked, then depart exactly once.
    consume=0;
    @(negedge clk);
    fire=2'b10; tags={9'd19,9'd18};
    packets[0+:64]=64'h1012; packets[140+:64]=64'h1013;
    @(negedge clk); fire=0;
    repeat(4) @(negedge clk);
    if((valid!=1 && valid!=2) || !reuse[19] || reuse[18])
      $fatal(1,"sparse second completion created wrong owner");
    consume=3;
    repeat(3) @(negedge clk);
    if(!idle || returns!=11) $fatal(1,"sparse second completion lost/duplicated");
    $display("[PASS] tb_r64_lsu_completion held/kill/flush/independent-lane/cancel-capture/consume-capture checks");
    $finish;
  end
  initial begin
    #10000;
    $fatal(1, "timeout");
  end
endmodule
