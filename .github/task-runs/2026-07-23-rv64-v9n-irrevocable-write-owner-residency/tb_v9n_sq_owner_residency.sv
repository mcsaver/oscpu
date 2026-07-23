`include "define.v"

// External next-edge checker for the local RV64 STORE physical-write owner.
// It observes the existing leaf TB and production SQ through read-only
// hierarchy references; no checker signal participates in the RTL datapath.
module tb_v9n_sq_owner_residency;
  localparam integer ENTRY_COUNT = 4;
  localparam integer ENTRY_COUNT_W = 2;
  localparam integer ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam integer PRODUCER_ID_W = ROB_INDEX_W + `OOO_PRODUCER_GEN_W;

  tb_ooo_store_queue u_tb();

  reg expect_resident_q;
  reg [ENTRY_COUNT_W-1:0] expect_idx_q;
  reg [ROB_INDEX_W-1:0] expect_rob_idx_q;
  reg [PRODUCER_ID_W-1:0] expect_producer_id_q;
  reg [1:0] expect_owner_kind_q;
  reg [4:0] expect_owner_token_q;
  reg [1:0] expect_mmu_epoch_q;
  reg pass_reported_q;

  initial pass_reported_q = 1'b0;

  wire [ENTRY_COUNT * 2 - 1:0] owner_kind_pack_w = {
      u_tb.dut.owner_kind_q[3], u_tb.dut.owner_kind_q[2],
      u_tb.dut.owner_kind_q[1], u_tb.dut.owner_kind_q[0]};
  wire [ENTRY_COUNT * 2 - 1:0] mmu_epoch_pack_w = {
      u_tb.dut.mmu_epoch_q[3], u_tb.dut.mmu_epoch_q[2],
      u_tb.dut.mmu_epoch_q[1], u_tb.dut.mmu_epoch_q[0]};

  wire expected_holder_resident_w =
      u_tb.snoop_valid[expect_idx_q] &&
      u_tb.snoop_owner_valid[expect_idx_q] &&
      u_tb.snoop_request_sent[expect_idx_q] &&
      !u_tb.snoop_terminal[expect_idx_q] &&
      (u_tb.snoop_rob_idx[
          expect_idx_q * ROB_INDEX_W +: ROB_INDEX_W] ===
       expect_rob_idx_q) &&
      (u_tb.snoop_producer_id[
          expect_idx_q * PRODUCER_ID_W +: PRODUCER_ID_W] ===
       expect_producer_id_q) &&
      (owner_kind_pack_w[expect_idx_q * 2 +: 2] ===
       expect_owner_kind_q) &&
      (u_tb.snoop_owner_token[expect_idx_q * 5 +: 5] ===
       expect_owner_token_q) &&
      (mmu_epoch_pack_w[expect_idx_q * 2 +: 2] ===
       expect_mmu_epoch_q);

  wire terminal0_exact_w = u_tb.terminal_valid &&
      (u_tb.terminal_rob_idx === expect_rob_idx_q) &&
      (u_tb.terminal_owner_kind === expect_owner_kind_q) &&
      (u_tb.terminal_owner_token === expect_owner_token_q) &&
      (u_tb.terminal_mmu_epoch === expect_mmu_epoch_q);
  wire terminal1_exact_w = u_tb.terminal1_valid &&
      (u_tb.terminal1_rob_idx === expect_rob_idx_q) &&
      (u_tb.terminal1_owner_kind === expect_owner_kind_q) &&
      (u_tb.terminal1_owner_token === expect_owner_token_q) &&
      (u_tb.terminal1_mmu_epoch === expect_mmu_epoch_q);
  wire exact_terminal_w = terminal0_exact_w || terminal1_exact_w;

  task automatic report_failure;
    begin
      $display("[CHECK-FAIL] V9N STORE owner residency lost before exact terminal");
      $display("[FAIL] tb_v9n_sq_owner_residency errors=1");
      $finish;
    end
  endtask

  always @(posedge u_tb.clk) begin
    if (u_tb.rst) begin
      expect_resident_q <= 1'b0;
      expect_idx_q <= {ENTRY_COUNT_W{1'b0}};
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
            $display("[V9N-SQ-NEXT-EDGE-OWNER] launch=1 preserved=1 exact_terminal=1 PASS");
            $display("[PASS] tb_v9n_sq_owner_residency");
            pass_reported_q <= 1'b1;
          end
        end
      end

      if (u_tb.req_fire && u_tb.req_valid) begin
        if (expect_resident_q)
          report_failure();
        expect_resident_q <= 1'b1;
        expect_idx_q <= u_tb.snoop_head;
        expect_rob_idx_q <= u_tb.req_rob_idx;
        expect_producer_id_q <= u_tb.req_producer_id;
        expect_owner_kind_q <= u_tb.req_owner_kind;
        expect_owner_token_q <= u_tb.req_owner_token;
        expect_mmu_epoch_q <= u_tb.req_mmu_epoch;
      end
    end
  end
endmodule
