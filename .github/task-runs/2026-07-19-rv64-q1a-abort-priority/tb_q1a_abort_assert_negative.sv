`timescale 1ns/1ps

module tb_q1a_abort_assert_negative;
  reg clk;
  reg rst;
  reg request_valid;
  wire request_ready;
  reg [3:0] request_cause;
  reg [15:0] request_payload;
  reg abort_valid;
  reg mem_context_quiet;
  reg owner_live_empty;
  wire capture_block;
  wire grant_valid;
  reg grant_ready;
  wire [3:0] grant_cause;
  wire [15:0] grant_payload;
  wire [1:0] mmu_epoch;
  integer case_id;

  OooMmuEpochOwner #(
    .CAUSE_W(4),
    .PAYLOAD_W(16)
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

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic capture_a;
    begin
      @(negedge clk);
      request_valid = 1'b1;
      request_cause = 4'b0001;
      request_payload = 16'hA11A;
      tick();
      @(negedge clk);
      request_valid = 1'b0;
    end
  endtask

  initial begin
    if (!$value$plusargs("CASE=%d", case_id)) begin
      $display("[MMU-EPOCH-Q1A-NEG][FAIL] missing +CASE=<1..5>");
      $fatal(1);
    end

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

    case (case_id)
      1: begin
        @(negedge clk);
        request_valid = 1'b1;
        request_cause = 4'b0000;
        tick();
      end

      2: begin
        capture_a();
        @(negedge clk);
        request_valid = 1'b1;
        request_cause = 4'b0010;
        request_payload = 16'hB22B;
        tick();
        @(negedge clk);
        request_payload = 16'hDEAD;
        tick();
      end

      3: begin
        capture_a();
        @(negedge clk);
        mem_context_quiet = 1'b1;
        owner_live_empty = 1'b1;
        tick();
        if (!grant_valid) begin
          $display("[MMU-EPOCH-Q1A-NEG][FAIL] case3 did not reach COMMIT");
          $fatal(1);
        end
        @(negedge clk);
        mem_context_quiet = 1'b0;
        tick();
      end

      4: begin
        @(negedge clk);
        force dut.state_q = 2'b11;
        #1;
        if (request_ready || !capture_block || grant_valid) begin
          $display("[MMU-EPOCH-Q1A-NEG][FAIL] illegal state was not fail closed");
          $fatal(1);
        end
        tick();
      end

      5: begin
        // 故障注入只用于证明 abort assertion 非真空；canonical RTL 本身不产生该泄漏。
        @(negedge clk);
        abort_valid = 1'b1;
        force dut.request_ready_o = 1'b1;
        tick();
      end

      default: begin
        $display("[MMU-EPOCH-Q1A-NEG][FAIL] unsupported CASE=%0d", case_id);
        $fatal(1);
      end
    endcase

    $display("[MMU-EPOCH-Q1A-NEG][FAIL] CASE=%0d did not hit its assertion", case_id);
    $fatal(1);
  end
endmodule
