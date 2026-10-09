// 取指访问服务：透明入口保持、地址翻译与同步 I-cache。
// 已接受请求（包括已毒化请求）恰好返回一次；Stream 负责顺序关联与丢弃过期结果。
// 排空期间服务继续推进，run 只控制外侧新请求。
module R64FetchAccess #(
  parameter PREPARED_PROTECTION = 0,
  parameter integer ICACHE_SET_W = 6
) (
  input          clk_i,
  input          rst_i,
  // redirect 标记已接受事务为过期；在飞响应仍继续排空。
  input          cancel_i,
  input          req_valid_i,
  output         req_ready_o,
  input  [ 63:0] req_pc_i,
  input  [  1:0] priv_i,
  input  [ 63:0] mstatus_i,
  input  [ 63:0] satp_i,
  input          pbmt_enable_i,
  output         rsp_valid_o,
  input          rsp_ready_i,
  output [127:0] rsp_data_o,
  output         rsp_fault_o,
  output [  4:0] rsp_cause_o,
  output [  7:0] rsp_access_mask_o,
  input          icache_invalidate_i,
  input          tlb_invalidate_i,
  input          tlb_all_vaddr_i,
  input          tlb_all_asid_i,
  input  [ 26:0] tlb_vpn_i,
  input  [ 15:0] tlb_asid_i,
  // 保护检查使用同一翻译结果保存的物理地址与特权。
  output [ 63:0] protect_paddr_o,
  output [  1:0] protect_priv_o,
  input  [  7:0] protect_fault_mask_i,
  input          protect_uncached_i,
  input  [129:0] protect_facts_i,
  output         cache_cmd_valid_o,
  input          cache_cmd_ready_i,
  output [ 63:0] cache_cmd_addr_o,
  output [  7:0] cache_cmd_len_o,
  output [  2:0] cache_cmd_size_o,
  input          cache_beat_valid_i,
  output         cache_beat_ready_o,
  input  [ 63:0] cache_beat_data_i,
  input  [  1:0] cache_beat_resp_i,
  input          cache_beat_last_i,
  output         pte_valid_o,
  input          pte_ready_i,
  output         pte_compare_or_o,
  output [ 55:0] pte_addr_o,
  output [ 63:0] pte_expected_o,
  output [ 63:0] pte_or_mask_o,
  input          pte_rsp_valid_i,
  output         pte_rsp_ready_o,
  input  [ 63:0] pte_rdata_i,
  input          pte_error_i,
  input          pte_compare_ok_i
);
  wire translation_v_w, translation_r_w, translation_fault_w, translation_ad_w;
  wire [1:0] translation_pbmt_w;
  wire [4:0] translation_cause_w;
  // The Stream accepts against an explicit free owner, not a combinational
  // result from the current translation. Empty ingress stays transparent;
  // only a blocked transfer occupies this slot. Every accepted owner drains.
  reg if_req_valid_q, if_req_poison_q;
  reg [135:0] if_req_payload_q;
  wire if_req_ready_w;
  wire [63:0] if_req_va_w, if_req_satp_w;
  wire [1:0] if_req_priv_w;
  wire [4:0] if_req_status_w;
  wire if_req_pbmt_w;
  wire [63:0] if_req_mstatus_w = {44'b0, if_req_status_w[4:2], 4'b0, if_req_status_w[1:0], 11'b0};
  wire if_req_cancel_w = cancel_i || tlb_invalidate_i;
  wire if_req_poison_w = if_req_cancel_w || (if_req_valid_q && if_req_poison_q);
  assign req_ready_o = !rst_i && !if_req_valid_q;
  assign {if_req_va_w, if_req_priv_w, if_req_satp_w, if_req_status_w, if_req_pbmt_w} =
      if_req_valid_q ? if_req_payload_q : {req_pc_i, priv_i, satp_i, mstatus_i[19:17],
                                           mstatus_i[12:11], pbmt_enable_i};
  // Free payload writes do not wait for the long Translation ready decision.
  always @(posedge clk_i)
    if (!if_req_valid_q)
      if_req_payload_q <= {
        req_pc_i, priv_i, satp_i, mstatus_i[19:17], mstatus_i[12:11], pbmt_enable_i
      };
  always @(posedge clk_i) begin
    if (rst_i) begin
      if_req_valid_q  <= 0;
      if_req_poison_q <= 0;
    end else if (if_req_valid_q) begin
      if (if_req_cancel_w) if_req_poison_q <= 1;
      if (if_req_ready_w) if_req_valid_q <= 0;
    end else if (req_valid_i && !if_req_ready_w) begin
      if_req_valid_q  <= 1;
      if_req_poison_q <= if_req_cancel_w;
    end
  end
  R64FetchTranslation u_translation (
    .req_protection_i(4'b0),
    .rsp_protection_o(),
    .rsp_last_o(),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .req_valid_i(if_req_valid_q || req_valid_i),
    .req_ready_o(if_req_ready_w),
    .req_poison_i(if_req_poison_w),
    .req_vaddr_i(if_req_va_w),
    .req_access_i(2'd0),
    .req_priv_i(if_req_priv_w),
    .req_mstatus_i(if_req_mstatus_w),
    .req_satp_i(if_req_satp_w),
    .req_ad_update_i(1'b1),
    .req_pbmt_enable_i(if_req_pbmt_w),
    .rsp_valid_o(translation_v_w),
    .rsp_ready_i(translation_r_w),
    .rsp_priv_o(protect_priv_o),
    .rsp_paddr_o(protect_paddr_o),
    .rsp_pbmt_o(translation_pbmt_w),
    .rsp_needs_ad_o(translation_ad_w),
    .rsp_fault_o(translation_fault_w),
    .rsp_cause_o(translation_cause_w),
    .invalidate_i(tlb_invalidate_i),
    .invalidate_all_vaddr_i(tlb_all_vaddr_i),
    .invalidate_all_asid_i(tlb_all_asid_i),
    .invalidate_vpn_i(tlb_vpn_i),
    .invalidate_asid_i(tlb_asid_i),
    .mem_valid_o(pte_valid_o),
    .mem_ready_i(pte_ready_i),
    .mem_compare_or_o(pte_compare_or_o),
    .mem_addr_o(pte_addr_o),
    .mem_expected_o(pte_expected_o),
    .mem_or_mask_o(pte_or_mask_o),
    .mem_rsp_valid_i(pte_rsp_valid_i),
    .mem_rsp_ready_o(pte_rsp_ready_o),
    .mem_rdata_i(pte_rdata_i),
    .mem_error_i(pte_error_i),
    .mem_compare_ok_i(pte_compare_ok_i)
  );
  R64ICache #(
    .SET_W(ICACHE_SET_W),
    .PREPARED_PROTECTION(PREPARED_PROTECTION)
  ) u_cache (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .invalidate_i(icache_invalidate_i),
    .req_valid_i(translation_v_w),
    .req_ready_o(translation_r_w),
    .req_paddr_i(protect_paddr_o),
    .req_uncached_i(protect_uncached_i || translation_pbmt_w != 0),
    .req_fault_i(translation_fault_w),
    .req_cause_i(translation_cause_w),
    .req_access_mask_i(protect_fault_mask_i),
    .req_protection_facts_i(protect_facts_i),
    .rsp_valid_o(rsp_valid_o),
    .rsp_ready_i(rsp_ready_i),
    .rsp_data_o(rsp_data_o),
    .rsp_fault_o(rsp_fault_o),
    .rsp_cause_o(rsp_cause_o),
    .rsp_access_mask_o(rsp_access_mask_o),
    .cmd_valid_o(cache_cmd_valid_o),
    .cmd_ready_i(cache_cmd_ready_i),
    .cmd_addr_o(cache_cmd_addr_o),
    .cmd_len_o(cache_cmd_len_o),
    .cmd_size_o(cache_cmd_size_o),
    .beat_valid_i(cache_beat_valid_i),
    .beat_ready_o(cache_beat_ready_o),
    .beat_data_i(cache_beat_data_i),
    .beat_resp_i(cache_beat_resp_i),
    .beat_last_i(cache_beat_last_i)
  );
  wire unused_translation_ad_w = translation_ad_w;
`ifdef R64_ASSERT
  always @(posedge clk_i)
    if (!rst_i && translation_v_w && !translation_fault_w && translation_ad_w)
      $fatal(1, "fetch translation returned unauthorized A update");
`endif
endmodule
