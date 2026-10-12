// Independent two-lane translation endpoint. Requests transfer opaque tokens;
// four accepted token/protection leases per lane survive every SFENCE and
// requester cancellation. A lease ends only on the protected response fire.
// The requester must not recycle a token until that fire. No ROB/LSQ format
// or cancel knowledge is required by this service.
module R64DataTranslationService #(
  parameter TOKEN_W = 5
) (
  input clk_i, rst_i,
  input [1:0] req_valid_i,
  output [1:0] req_ready_o,
  input [2*TOKEN_W-1:0] req_token_i,
  input [127:0] req_vaddr_i,
  input [3:0] req_access_i,
  input [7:0] req_protection_i,
  input [1:0] req_ad_update_i,
  output [1:0] rsp_valid_o,
  input [1:0] rsp_ready_i,
  output [2*TOKEN_W-1:0] rsp_token_o,
  output [127:0] rsp_paddr_o,
  output [3:0] rsp_class_o,
  output [1:0] rsp_fault_o, rsp_needs_ad_o,
  output [9:0] rsp_cause_o,
  output idle_o,
  input [1:0] privilege_i,
  input [63:0] mstatus_i, satp_i,
  input pbmt_enable_i,
  input [15:0] pmp_active_i,
  input [895:0] pmp_lower_i, pmp_upper_i,
  input [63:0] pmp_permission_i,
  input tlb_invalidate_i, tlb_all_vaddr_i, tlb_all_asid_i,
  input [26:0] tlb_vpn_i,
  input [15:0] tlb_asid_i,
  output [1:0] mem_valid_o,
  input [1:0] mem_ready_i,
  output [1:0] mem_compare_or_o,
  output [111:0] mem_addr_o,
  output [127:0] mem_expected_o, mem_or_mask_o,
  input [1:0] mem_rsp_valid_i,
  output [1:0] mem_rsp_ready_o,
  input [127:0] mem_rdata_i,
  input [1:0] mem_error_i, mem_compare_ok_i
);
  wire [1:0] request_valid, translation_ready, lane_idle;
  wire [1:0] raw_valid, raw_ready, protected_valid, protected_ready;
  wire [127:0] pa;
  wire [3:0] pbmt, effective_priv, raw_pma_class;
  wire [1:0] needs_ad, tf, raw_pma_fault;
  wire [9:0] cause;
  wire [7:0] raw_protection, final_protection;
  wire [129:0] raw_last;
  assign idle_o = &lane_idle;
  genvar g;
  generate
    for (g = 0; g < 2; g = g + 1) begin : g_translation
      R64Translation #(
        .DATA_PROTECTION  (1),
        .RESERVED_TERMINAL(0)
      ) translation (
        .req_protection_i(req_protection_i[g*4+:4]),
        .rsp_protection_o(raw_protection[g*4+:4]),
        .rsp_last_o(raw_last[g*65+:65]),
        .rsp_pma_class_o(raw_pma_class[g*2+:2]),
        .rsp_pma_fault_o(raw_pma_fault[g]),
        .clk_i(clk_i),
        .rst_i(rst_i),
        .req_valid_i(request_valid[g]),
        .req_ready_o(translation_ready[g]),
        .req_poison_i(1'b0),
        .req_vaddr_i(req_vaddr_i[g*64+:64]),
        .req_access_i(req_access_i[g*2+:2]),
        .req_priv_i(privilege_i),
        .req_mstatus_i(mstatus_i),
        .req_satp_i(satp_i),
        .req_ad_update_i(req_ad_update_i[g]),
        .req_pbmt_enable_i(pbmt_enable_i),
        .rsp_valid_o(raw_valid[g]),
        .rsp_ready_i(raw_ready[g]),
        .rsp_priv_o(effective_priv[g*2+:2]),
        .rsp_paddr_o(pa[g*64+:64]),
        .rsp_pbmt_o(pbmt[g*2+:2]),
        .rsp_needs_ad_o(needs_ad[g]),
        .rsp_fault_o(tf[g]),
        .rsp_cause_o(cause[g*5+:5]),
        .invalidate_i(tlb_invalidate_i),
        .invalidate_all_vaddr_i(tlb_all_vaddr_i),
        .invalidate_all_asid_i(tlb_all_asid_i),
        .invalidate_vpn_i(tlb_vpn_i),
        .invalidate_asid_i(tlb_asid_i),
        .mem_valid_o(mem_valid_o[g]),
        .mem_ready_i(mem_ready_i[g]),
        .mem_compare_or_o(mem_compare_or_o[g]),
        .mem_addr_o(mem_addr_o[g*56+:56]),
        .mem_expected_o(mem_expected_o[g*64+:64]),
        .mem_or_mask_o(mem_or_mask_o[g*64+:64]),
        .mem_rsp_valid_i(mem_rsp_valid_i[g]),
        .mem_rsp_ready_o(mem_rsp_ready_o[g]),
        .mem_rdata_i(mem_rdata_i[g*64+:64]),
        .mem_error_i(mem_error_i[g]),
        .mem_compare_ok_i(mem_compare_ok_i[g])
      );
      // Generic translation overflow and protection READY preserve terminals under arbitrary backpressure.
      R64DataProtection #(
        .PMA_PREPARED(1)
      ) protection (
        .req_pma_class_i(raw_pma_class[g*2+:2]),
        .req_pma_fault_i(raw_pma_fault[g]),
        .clk_i(clk_i),
        .rst_i(rst_i),
        .req_valid_i(raw_valid[g]),
        .req_ready_o(raw_ready[g]),
        .req_paddr_i(pa[g*64+:64]),
        .req_last_i(raw_last[g*65+:65]),
        .req_protection_i(raw_protection[g*4+:4]),
        .req_priv_i(effective_priv[g*2+:2]),
        .req_pbmt_i(pbmt[g*2+:2]),
        .req_fault_i(tf[g]),
        .req_needs_ad_i(needs_ad[g]),
        .req_cause_i(cause[g*5+:5]),
        .pmp_active_i(pmp_active_i),
        .pmp_lower_i(pmp_lower_i),
        .pmp_upper_i(pmp_upper_i),
        .pmp_permission_i(pmp_permission_i),
        .rsp_valid_o(protected_valid[g]),
        .rsp_ready_i(protected_ready[g]),
        .rsp_paddr_o(rsp_paddr_o[g*64+:64]),
        .rsp_class_o(rsp_class_o[g*2+:2]),
        .rsp_fault_o(rsp_fault_o[g]),
        .rsp_needs_ad_o(rsp_needs_ad_o[g]),
        .rsp_cause_o(rsp_cause_o[g*5+:5]),
        .rsp_protection_o(final_protection[g*4+:4])
      );
      reg [TOKEN_W-1:0] token_q[0:3];
      reg [3:0] protection_q[0:3];
      reg [1:0] head_q, tail_q;
      reg [2:0] count_q;
      wire credit_w = count_q < 4;
      wire accept_w = req_valid_i[g] && req_ready_o[g];
      wire terminal_w = rsp_valid_o[g] && rsp_ready_i[g];
      assign request_valid[g] = req_valid_i[g] && credit_w && !rst_i;
      assign req_ready_o[g] = translation_ready[g] && credit_w && !rst_i;
      assign rsp_valid_o[g] = protected_valid[g] && count_q != 0 && !rst_i;
      assign protected_ready[g] = rsp_ready_i[g] && count_q != 0 && !rst_i;
      assign rsp_token_o[g*TOKEN_W+:TOKEN_W] = token_q[head_q];
      assign lane_idle[g] = count_q == 0;
      always @(posedge clk_i)
        if (rst_i) begin
          count_q <= 0;
          head_q <= 0;
          tail_q <= 0;
        end else begin
          case ({accept_w, terminal_w})
            2'b10: count_q <= count_q + 1'b1;
            2'b01: count_q <= count_q - 1'b1;
            default: begin end
          endcase
          if (accept_w) begin
            token_q[tail_q] <= req_token_i[g*TOKEN_W+:TOKEN_W];
            protection_q[tail_q] <= req_protection_i[g*4+:4];
            tail_q <= tail_q + 1'b1;
          end
          if (terminal_w) head_q <= head_q + 1'b1;
        end
`ifdef R64_ASSERT
      always @(posedge clk_i)
        if (!rst_i) begin
          if (count_q > 4 || (accept_w && !credit_w))
            $fatal(1, "R64DataTranslationService token capacity violation");
          if (protected_valid[g] && (count_q == 0 ||
              final_protection[g*4+:4] !== protection_q[head_q]))
            $fatal(1, "R64DataTranslationService response crossed token attributes");
        end
`endif
    end
  endgenerate
endmodule
