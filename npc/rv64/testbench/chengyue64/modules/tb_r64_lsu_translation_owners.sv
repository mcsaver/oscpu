`timescale 1ns / 1ps
module tb_r64_lsu_translation_owners;
  localparam INDEX_W = 5;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1;
  reg [1:0] offer = 0, rsp_valid = 0;
  wire [1:0] credit, fire, rsp_ready, rsp_fire;
  reg [2*INDEX_W-1:0] in_slot = 0;
  reg [7:0] in_protection = 0;
  wire [2*INDEX_W-1:0] rsp_slot;
  wire [7:0] rsp_protection;
  assign fire = offer & credit & {2{!rst}};
  R64LsuTranslationOwners #(
    .INDEX_W(INDEX_W)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .in_fire_i(fire),
    .in_ready_o(credit),
    .in_slot_i(in_slot),
    .in_protection_i(in_protection),
    .rsp_valid_i(rsp_valid),
    .rsp_ready_o(rsp_ready),
    .rsp_fire_o(rsp_fire),
    .rsp_slot_o(rsp_slot),
    .rsp_protection_o(rsp_protection)
  );

  // 用只追加的接收事件记录独立核对 DUT 的环形指针。
  // 指令取消属于消费者；标记死亡后，已接受的 owner 仍须返回才能复用槽位。
  reg [INDEX_W-1:0] accepted_slot[0:1][0:255];
  reg [3:0] accepted_protection[0:1][0:255];
  integer produced[0:1], consumed[0:1];
  reg [31:0] cancelled_slot = 0;
  integer lane, pending, full_pop = 0, simultaneous = 0, cancelled_drains = 0;
  always @(posedge clk) begin
    if (rst) begin
      produced[0] = 0;
      produced[1] = 0;
      consumed[0] = 0;
      consumed[1] = 0;
      if (rsp_ready !== 0 || rsp_fire !== 0)
        $fatal(1, "reset must suppress translation responses");
    end else begin
      for (lane = 0; lane < 2; lane = lane + 1) begin
        pending = produced[lane] - consumed[lane];
        if (credit[lane] !== (pending < 4) ||
            rsp_ready[lane] !== (pending != 0) ||
            rsp_fire[lane] !== ((pending != 0) && rsp_valid[lane]))
          $fatal(1, "translation owner credit/response mismatch lane %0d pending %0d", lane, pending);
        if (pending != 0 &&
            (rsp_slot[lane*INDEX_W+:INDEX_W] !== accepted_slot[lane][consumed[lane]] ||
             rsp_protection[lane*4+:4] !== accepted_protection[lane][consumed[lane]]))
          $fatal(1, "translation owner slot/protection order mismatch lane %0d", lane);
        if (pending == 4 && rsp_valid[lane] && offer[lane]) begin
          if (fire[lane]) $fatal(1, "full queue borrowed same-cycle response credit");
          full_pop = full_pop + 1;
        end
        if (rsp_fire[lane]) begin
          if (cancelled_slot[rsp_slot[lane*INDEX_W+:INDEX_W]])
            cancelled_drains = cancelled_drains + 1;
          consumed[lane] = consumed[lane] + 1;
        end
        if (fire[lane]) begin
          accepted_slot[lane][produced[lane]] = in_slot[lane*INDEX_W+:INDEX_W];
          accepted_protection[lane][produced[lane]] = in_protection[lane*4+:4];
          produced[lane] = produced[lane] + 1;
        end
        if (fire[lane] && rsp_fire[lane]) simultaneous = simultaneous + 1;
      end
    end
  end

  task step;
    input [1:0] requests, responses;
    input [INDEX_W-1:0] slot0, slot1;
    input [3:0] protection0, protection1;
    begin
      @(negedge clk);
      offer = requests;
      rsp_valid = responses;
      in_slot = {slot1, slot0};
      in_protection = {protection1, protection0};
      @(negedge clk);
      offer = 0;
      rsp_valid = 0;
    end
  endtask

  integer n, before0, before1;
  initial begin
    repeat (3) @(negedge clk);
    rst = 0;
    // 空队列响应不能消费本边沿才捕获的 owner。
    step(3, 3, 1, 2, 4'h3, 4'hc);
    if (consumed[0] != 0 || consumed[1] != 0)
      $fatal(1, "new owner bypassed registered response readiness");
    step(3, 0, 3, 4, 4'h9, 4'h6);
    step(3, 0, 5, 6, 4'he, 4'h1);
    step(3, 0, 7, 8, 4'h4, 4'hb);
    if (credit !== 0) $fatal(1, "both lanes must be full");
    // 有效与已取消 owner 在顺序服务响应中交错返回。
    cancelled_slot = 32'h00000132;  // 槽位 1、4、5、8
    repeat (3) step(3, 0, 31, 30, 4'h0, 4'hf);
    before0 = produced[0];
    before1 = produced[1];
    step(3, 1, 9, 10, 4'h8, 4'h7);
    if (produced[0] != before0 || produced[1] != before1 || credit !== 1)
      $fatal(1, "full response changed same-cycle admission or other lane credit");
    // lane0 已有 Q 态信用；lane1 响应到达时仍为满队列。
    step(3, 3, 9, 10, 4'h8, 4'h7);
    step(3, 0, 11, 12, 4'h2, 4'hd);
    repeat (4) step(0, 3, 0, 0, 0, 0);
    if (rsp_ready !== 0 || produced[0] != consumed[0] || produced[1] != consumed[1] ||
        cancelled_drains != 4 || full_pop != 2)
      $fatal(1, "cancelled owner drain/accounting failed: dead %0d full %0d",
             cancelled_drains, full_pop);
    cancelled_slot = 0;
    // 每路保留一个 owner，反复同拍入队/出队并越过指针环回。
    step(3, 0, 13, 14, 4'h5, 4'ha);
    for (n = 0; n < 64; n = n + 1)
      step(3, 3, INDEX_W'(n), INDEX_W'(31-n), 4'(n), 4'(15-n));
    step(0, 1, 0, 0, 0, 0);
    if (rsp_ready !== 2 || credit !== 3)
      $fatal(1, "independent final drain changed retained lane");
    step(0, 2, 0, 0, 0, 0);
    if (rsp_ready !== 0 || produced[0] != consumed[0] || produced[1] != consumed[1] ||
        simultaneous != 129)
      $fatal(1, "stream drain/accounting failed");
    // 同步复位清除在飞账本并屏蔽响应接收。
    step(3, 0, 15, 16, 4'hf, 4'h0);
    rst = 1;
    rsp_valid = 3;
    #1;
    if (rsp_ready !== 0 || rsp_fire !== 0) $fatal(1, "reset response qualification");
    @(negedge clk);
    rst = 0;
    rsp_valid = 0;
    #1;
    if (rsp_ready !== 0 || credit !== 3) $fatal(1, "reset retained owner state");
    $display("[PASS] tb_r64_lsu_translation_owners Q credit, dual-lane order, slot/protection, wrap, cancelled drain");
    $finish;
  end
  initial begin
    #100000;
    $fatal(1, "translation owner test timeout");
  end
endmodule
