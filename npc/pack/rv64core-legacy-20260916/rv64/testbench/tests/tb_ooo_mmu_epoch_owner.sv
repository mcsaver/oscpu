`timescale 1ns/1ps

module tb_ooo_mmu_epoch_owner;
  localparam integer CAUSE_W = 4;
  localparam integer PAYLOAD_W = 16;

  reg clk;
  reg rst;
  reg request_valid;
  wire request_ready;
  reg [CAUSE_W-1:0] request_cause;
  reg [PAYLOAD_W-1:0] request_payload;
  reg abort_valid;
  reg mem_context_quiet;
  reg owner_live_empty;
  wire capture_block;
  wire grant_valid;
  reg grant_ready;
  wire [CAUSE_W-1:0] grant_cause;
  wire [PAYLOAD_W-1:0] grant_payload;
  wire [1:0] mmu_epoch;

  OooMmuEpochOwner #(
    .CAUSE_W(CAUSE_W),
    .PAYLOAD_W(PAYLOAD_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .request_valid_i(request_valid),
    .request_ready_o(request_ready),
    .request_cause_i(request_cause),
    .request_payload_i(request_payload),
    .abort_valid_i(abort_valid),
    .mem_context_quiet_i(mem_context_quiet),
    .owner_live_empty_i(owner_live_empty),
    .capture_block_o(capture_block),
    .grant_valid_o(grant_valid),
    .grant_ready_i(grant_ready),
    .grant_cause_o(grant_cause),
    .grant_payload_o(grant_payload),
    .mmu_epoch_o(mmu_epoch)
  );

  always #5 clk = ~clk;

  task automatic fail;
    input [8*112-1:0] message;
    begin
      $display("[MMU-EPOCH-Q1][FAIL] %0s", message);
      $fatal(1);
    end
  endtask

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic complete_quiet_event;
    input [CAUSE_W-1:0] cause;
    input [PAYLOAD_W-1:0] payload;
    input [1:0] expected_epoch;
    begin
      @(negedge clk);
      request_valid = 1'b1;
      request_cause = cause;
      request_payload = payload;
      #1;
      if (!capture_block || !request_ready || grant_valid)
        fail("quiet helper request did not present blocked+ready without grant");

      tick();
      @(negedge clk);
      request_valid = 1'b0;
      #1;
      if (!capture_block || request_ready || grant_valid)
        fail("captured quiet helper request did not enter locked drain");

      tick();
      if (!grant_valid || grant_cause !== cause ||
          grant_payload !== payload ||
          mmu_epoch !== (expected_epoch - 2'b01))
        fail("quiet helper did not expose held pre-increment grant bundle");

      tick();
      if (grant_valid || capture_block || mmu_epoch !== expected_epoch)
        fail("quiet helper grant did not consume exactly once and advance epoch");
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    request_valid = 1'b0;
    request_cause = 4'b0001;
    request_payload = 16'h0000;
    abort_valid = 1'b0;
    mem_context_quiet = 1'b0;
    owner_live_empty = 1'b1;
    grant_ready = 1'b0;

    repeat (2) tick();
    rst = 1'b0;
    tick();
    if (capture_block || grant_valid || mmu_epoch !== 2'b00)
      fail("reset did not leave an unlocked epoch-zero owner");

    // Q1A-A0a: 即使没有 request，abort 展示拍也必须 look-ahead block。
    @(negedge clk);
    abort_valid = 1'b1;
    #1;
    if (!capture_block || request_ready || grant_valid)
      fail("idle abort did not immediately block capture");
    tick();
    @(negedge clk);
    abort_valid = 1'b0;
    #1;
    if (capture_block || grant_valid || mmu_epoch !== 2'b00)
      fail("idle abort changed epoch or failed to return unlocked");

    // Q1A-A0: abort 与首个 request 同拍时，必须立即封住入口且不能捕获。
    @(negedge clk);
    abort_valid = 1'b1;
    request_valid = 1'b1;
    request_cause = 4'b0001;
    request_payload = 16'h0A00;
    #1;
    if (!capture_block || request_ready || grant_valid)
      fail("abort and request raced into a visible handshake");
    tick();
    @(negedge clk);
    abort_valid = 1'b0;
    #1;
    if (!capture_block || request_ready || grant_valid || mmu_epoch !== 2'b00)
      fail("aborted request was recaptured without a valid-low rearm");
    tick();
    if (!capture_block || request_ready || grant_valid || mmu_epoch !== 2'b00)
      fail("continuous cancelled request escaped abort rearm");
    @(negedge clk);
    request_valid = 1'b0;
    #1;
    if (!capture_block || request_ready || grant_valid)
      fail("abort rearm opened before the valid-low edge");
    tick();
    if (capture_block || grant_valid || mmu_epoch !== 2'b00)
      fail("valid-low did not rearm the aborted owner");

    // Q1A-A1: LOCKED_DRAIN 中 abort 清 held bundle，且 epoch 不变。
    @(negedge clk);
    request_valid = 1'b1;
    request_cause = 4'b0010;
    request_payload = 16'h0A11;
    tick();
    @(negedge clk);
    request_valid = 1'b0;
    abort_valid = 1'b1;
    #1;
    if (!capture_block || request_ready || grant_valid)
      fail("drain abort exposed a request or grant handshake");
    tick();
    @(negedge clk);
    abort_valid = 1'b0;
    #1;
    if (capture_block || grant_valid || mmu_epoch !== 2'b00 ||
        grant_cause !== 4'b0000 || grant_payload !== 16'h0000)
      fail("drain abort did not clear held bundle/state");

    // Q1A-A2: 已到 COMMIT 且 consumer ready 的同拍 abort 必须赢过 grant。
    @(negedge clk);
    request_valid = 1'b1;
    request_cause = 4'b0100;
    request_payload = 16'h0A22;
    tick();
    @(negedge clk);
    request_valid = 1'b0;
    mem_context_quiet = 1'b1;
    owner_live_empty = 1'b1;
    tick();
    if (!grant_valid || grant_payload !== 16'h0A22)
      fail("commit-abort setup did not reach a held grant");
    @(negedge clk);
    grant_ready = 1'b1;
    abort_valid = 1'b1;
    #1;
    if (grant_valid || request_ready || !capture_block)
      fail("abort did not suppress a ready grant in its presentation cycle");
    tick();
    @(negedge clk);
    abort_valid = 1'b0;
    grant_ready = 1'b0;
    mem_context_quiet = 1'b0;
    #1;
    if (grant_valid || capture_block || mmu_epoch !== 2'b00)
      fail("commit abort advanced epoch or left owner busy");

    // Q1A-A3: backpressured sticky grant 也可被同一 abort 原子取消。
    @(negedge clk);
    request_valid = 1'b1;
    request_cause = 4'b1000;
    request_payload = 16'h0A33;
    tick();
    @(negedge clk);
    request_valid = 1'b0;
    mem_context_quiet = 1'b1;
    tick();
    if (!grant_valid || grant_payload !== 16'h0A33)
      fail("backpressure-abort setup did not reach grant");
    tick();
    if (!grant_valid || mmu_epoch !== 2'b00)
      fail("backpressured grant did not remain sticky before abort");
    @(negedge clk);
    abort_valid = 1'b1;
    #1;
    if (grant_valid || !capture_block)
      fail("abort did not suppress a backpressured grant");
    tick();
    @(negedge clk);
    abort_valid = 1'b0;
    mem_context_quiet = 1'b0;
    #1;
    if (grant_valid || capture_block || mmu_epoch !== 2'b00)
      fail("backpressure abort failed to clear without epoch advance");

    // G1: 请求首次出现的同一组合拍已经 block，不能等到下一沿。
    @(negedge clk);
    request_valid = 1'b1;
    request_cause = 4'b0001;
    request_payload = 16'hA11A;
    #1;
    if (!capture_block)
      fail("first request did not block capture in its presentation cycle");
    if (!request_ready || grant_valid)
      fail("first request was not accepted only through the request handshake");

    tick();
    @(negedge clk);
    request_valid = 1'b0;
    #1;
    if (!capture_block || request_ready || grant_valid)
      fail("captured request did not enter locked drain");

    // quiet 与 live-token-empty 必须分别承重，删除任一条件都会在这里被杀死。
    tick();
    if (grant_valid || mmu_epoch !== 2'b00)
      fail("quiet-low request advanced to grant");
    tick();
    if (grant_valid || mmu_epoch !== 2'b00)
      fail("quiet-low request advanced after an extra wait cycle");

    @(negedge clk);
    mem_context_quiet = 1'b1;
    owner_live_empty = 1'b0;
    tick();
    if (grant_valid || mmu_epoch !== 2'b00)
      fail("live token did not block epoch grant");

    @(negedge clk);
    owner_live_empty = 1'b1;
    tick();
    if (!grant_valid || grant_cause !== 4'b0001 ||
        grant_payload !== 16'hA11A || mmu_epoch !== 2'b00)
      fail("full quiet did not expose the held grant before epoch advance");

    // G2: grant 可背压，第二请求 B 必须保持，不能覆盖 pending A。
    @(negedge clk);
    request_valid = 1'b1;
    request_cause = 4'b0011;
    request_payload = 16'hB22B;
    #1;
    if (!capture_block || request_ready || !grant_valid ||
        grant_cause !== 4'b0001 || grant_payload !== 16'hA11A)
      fail("second request overwrote or bypassed backpressured grant A");

    tick();
    if (!grant_valid || grant_cause !== 4'b0001 ||
        grant_payload !== 16'hA11A || mmu_epoch !== 2'b00)
      fail("grant A did not hold for first backpressure cycle");
    tick();
    if (!grant_valid || grant_cause !== 4'b0001 ||
        grant_payload !== 16'hA11A || mmu_epoch !== 2'b00)
      fail("grant A did not hold for second backpressure cycle");

    @(negedge clk);
    grant_ready = 1'b1;
    tick();
    if (grant_valid || !capture_block || !request_ready || mmu_epoch !== 2'b01)
      fail("grant A consume edge either accepted B early or failed epoch advance");

    // B 在 grant edge 前 ready=0；只允许下一沿真正捕获。
    tick();
    if (grant_valid || !capture_block || request_ready || mmu_epoch !== 2'b01)
      fail("held request B did not enter locked drain on the post-grant edge");
    @(negedge clk);
    request_valid = 1'b0;

    tick();
    if (!grant_valid || grant_cause !== 4'b0011 ||
        grant_payload !== 16'hB22B || mmu_epoch !== 2'b01)
      fail("multi-cause request B did not produce one held grant");
    tick();
    if (grant_valid || capture_block || mmu_epoch !== 2'b10)
      fail("multi-cause request advanced epoch by other than exactly one");

    // G3: 再完成两次单 cause，四个总 event 必须 0->1->2->3->0。
    complete_quiet_event(4'b0100, 16'hC33C, 2'b11);
    complete_quiet_event(4'b1000, 16'hD44D, 2'b00);
    tick();
    if (grant_valid || capture_block || mmu_epoch !== 2'b00)
      fail("epoch changed without a fifth grant event");

    $display("[MMU-EPOCH-Q1][PASS] same-cycle-block/quiet/hold/second-request/multi-cause/wrap");
    $display("[MMU-EPOCH-Q1A][PASS] abort-idle/drain/commit/backpressure/epoch-stable");
    $display("[MMU-EPOCH-Q1A-REARM][PASS] continuous-valid-blocked-until-valid-low");
    $display("[PASS] tb_ooo_mmu_epoch_owner");
    $finish;
  end
endmodule
