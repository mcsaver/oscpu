`include "define.v"

// External next-edge checker for the local RV64 AMO physical-write singleton.
// The checker is verification-only and consumes production state read-only.
module tb_v9n_amo_owner_residency;
  localparam integer ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam integer PRODUCER_ID_W = ROB_INDEX_W + `OOO_PRODUCER_GEN_W;

  tb_ooo_int_backend u_tb();

  reg expect_resident_q;
  reg [ROB_INDEX_W-1:0] expect_rob_idx_q;
  reg [PRODUCER_ID_W-1:0] expect_producer_id_q;
  reg [1:0] expect_owner_kind_q;
  reg [4:0] expect_owner_token_q;
  reg [1:0] expect_mmu_epoch_q;
  reg pass_reported_q;

  initial pass_reported_q = 1'b0;

  wire expected_holder_resident_w =
      u_tb.dut.mem_pending_q &&
      u_tb.dut.mem_amo_q &&
      u_tb.dut.mem_amo_write_sent_q &&
      (u_tb.dut.mem_rob_idx_q === expect_rob_idx_q) &&
      (u_tb.dut.mem_producer_id_q === expect_producer_id_q) &&
      (u_tb.dut.mem_owner_kind_q === expect_owner_kind_q) &&
      (u_tb.dut.mem_owner_token_q === expect_owner_token_q) &&
      (u_tb.dut.mem_mmu_epoch_q === expect_mmu_epoch_q);

  wire exact_terminal_w = u_tb.dut.mem_rsp_final_fire_w &&
      (u_tb.dut.mem_rsp_owner_kind_i === expect_owner_kind_q) &&
      (u_tb.dut.mem_rsp_owner_token_i === expect_owner_token_q) &&
      (u_tb.dut.mem_rsp_mmu_epoch_i === expect_mmu_epoch_q);

  task automatic report_failure;
    begin
      $display("[CHECK-FAIL] V9N AMO owner residency lost before exact terminal");
      $display("[FAIL] tb_v9n_amo_owner_residency errors=1");
      $finish;
    end
  endtask

  always @(posedge u_tb.clk) begin
    if (u_tb.rst) begin
      expect_resident_q <= 1'b0;
      expect_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      expect_producer_id_q <= {PRODUCER_ID_W{1'b0}};
      expect_owner_kind_q <= 2'b0;
      expect_owner_token_q <= 5'b0;
      expect_mmu_epoch_q <= 2'b0;
    end else begin
      if (expect_resident_q) begin
        if (!expected_holder_resident_w)
          report_failure();
        if (exact_terminal_w) begin
          expect_resident_q <= 1'b0;
          if (!pass_reported_q) begin
            $display("[V9N-AMO-NEXT-EDGE-OWNER] launch=1 preserved=1 exact_terminal=1 PASS");
            $display("[PASS] tb_v9n_amo_owner_residency");
            pass_reported_q <= 1'b1;
          end
        end
      end

      if (u_tb.dut.push_amo_write_w) begin
        if (expect_resident_q)
          report_failure();
        expect_resident_q <= 1'b1;
        expect_rob_idx_q <= u_tb.dut.mem_rob_idx_q;
        expect_producer_id_q <= u_tb.dut.mem_producer_id_q;
        expect_owner_kind_q <= u_tb.dut.mem_owner_kind_q;
        expect_owner_token_q <= u_tb.dut.mem_owner_token_q;
        expect_mmu_epoch_q <= u_tb.dut.mem_mmu_epoch_q;
      end
    end
  end
endmodule
