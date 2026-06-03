`include "define.v"

module OooFetchAxiBridge (
  input clk,
  input rst,
  input mmu_flush_i,

  input invalidate_valid_i,
  input [`XLEN-1:0] invalidate_addr_i,

  input [1:0] priv_mode_i,
  input [`XLEN-1:0] satp_i,

  input fetch_req_valid_i,
  output fetch_req_ready_o,
  input [`XLEN-1:0] fetch_req_pc_i,
  output fetch_rsp_valid_o,
  input fetch_rsp_ready_i,
  output [`INST_W-1:0] fetch_rsp_inst0_o,
  output [1:0] fetch_rsp_resp0_o,
  output [`INST_W-1:0] fetch_rsp_inst1_o,
  output [1:0] fetch_rsp_resp1_o,

  output ifu_axi_arvalid_o,
  input ifu_axi_arready_i,
  output [`XLEN-1:0] ifu_axi_araddr_o,
  input ifu_axi_rvalid_i,
  output ifu_axi_rready_o,
  input [`XLEN-1:0] ifu_axi_rdata_i,
  input [1:0] ifu_axi_rresp_i
);

  localparam [3:0] S_IDLE = 4'd0;
  localparam [3:0] S_WALK_AR = 4'd1;
  localparam [3:0] S_WALK_R = 4'd2;
  localparam [3:0] S_AR0 = 4'd3;
  localparam [3:0] S_R0 = 4'd4;
  localparam [3:0] S_AR1 = 4'd5;
  localparam [3:0] S_R1 = 4'd6;
  localparam [3:0] S_RESP = 4'd7;
  localparam [1:0] RESP_OK = 2'b00;
  localparam [1:0] RESP_ACCESS_FAULT = 2'b01;
  localparam [1:0] RESP_PAGE_FAULT = 2'b10;
  localparam CACHE_INDEX_W = 12;
  localparam ITLB_INDEX_W = 6;

  reg [3:0] state_q;
  reg paging_q;
  reg [1:0] req_priv_q;
  reg [`XLEN-1:0] req_satp_q;
  reg walk_second_q;
  reg [1:0] walk_level_q;
  reg [43:0] walk_ppn_q;
  reg [`XLEN-1:0] pc_q;
  reg [`XLEN-1:0] paddr0_q;
  reg [`XLEN-1:0] paddr1_q;
  reg packet_cross_page_q;
  reg [2:0] packet_first_bytes_q;
  reg [`XLEN-1:0] first_beat_q;
  reg [`INST_W-1:0] inst0_q;
  reg [`INST_W-1:0] inst1_q;
  reg [1:0] resp0_q;
  reg [1:0] resp1_q;
  reg [`XLEN-1:0] debug_last_pte_addr_q;
  reg [`XLEN-1:0] debug_last_pte_q;
  reg [1:0] debug_last_pte_level_q;
  reg debug_last_pte_second_q;

  function sv39_enabled;
    input [1:0] priv_mode;
    input [`XLEN-1:0] satp;
    begin
      sv39_enabled = (priv_mode != `PRIV_M) && (satp[63:60] == 4'h8);
    end
  endfunction

  function canonical_sv39;
    input [`XLEN-1:0] vaddr;
    begin
      canonical_sv39 = (vaddr[63:39] == {25{vaddr[38]}});
    end
  endfunction

  function [8:0] vpn_by_level;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      case (level)
        2'd2: vpn_by_level = vaddr[38:30];
        2'd1: vpn_by_level = vaddr[29:21];
        default: vpn_by_level = vaddr[20:12];
      endcase
    end
  endfunction

  function [`XLEN-1:0] pte_addr;
    input [43:0] ppn;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      pte_addr = {8'b0, ppn, 12'b0} +
                 {{(`XLEN-12){1'b0}}, vpn_by_level(vaddr, level), 3'b000};
    end
  endfunction

  function pte_invalid;
    input [`XLEN-1:0] pte;
    begin
      pte_invalid = !pte[0] || (!pte[1] && pte[2]);
    end
  endfunction

  function pte_leaf;
    input [`XLEN-1:0] pte;
    begin
      pte_leaf = pte[1] || pte[3];
    end
  endfunction

  function superpage_misaligned;
    input [`XLEN-1:0] pte;
    input [1:0] level;
    begin
      case (level)
        2'd2: superpage_misaligned = (|pte[27:10]);
        2'd1: superpage_misaligned = (|pte[18:10]);
        default: superpage_misaligned = 1'b0;
      endcase
    end
  endfunction

  function exec_permission_fault;
    input [`XLEN-1:0] pte;
    input [1:0] priv_mode;
    begin
      exec_permission_fault =
          !pte[3] ||
          ((priv_mode == `PRIV_U) ? !pte[4] : pte[4]);
    end
  endfunction

  /* verilator lint_off BLKSEQ */
  function [`XLEN-1:0] leaf_paddr;
    input [`XLEN-1:0] pte;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    reg [43:0] leaf_ppn;
    begin
      case (level)
        2'd2: leaf_ppn = {pte[53:28], vaddr[29:21], vaddr[20:12]};
        2'd1: leaf_ppn = {pte[53:28], pte[27:19], vaddr[20:12]};
        default: leaf_ppn = pte[53:10];
      endcase
      leaf_paddr = {8'b0, leaf_ppn, vaddr[11:0]};
    end
  endfunction
  /* verilator lint_on BLKSEQ */

  function [`XLEN-1:0] merge_cross_page_packet;
    input [`XLEN-1:0] first_beat;
    input [`XLEN-1:0] second_beat;
    input [2:0] first_bytes;
    begin
      case (first_bytes)
        3'd1: merge_cross_page_packet = {second_beat[55:0], first_beat[7:0]};
        3'd2: merge_cross_page_packet = {second_beat[47:0], first_beat[15:0]};
        3'd3: merge_cross_page_packet = {second_beat[39:0], first_beat[23:0]};
        3'd4: merge_cross_page_packet = {second_beat[31:0], first_beat[31:0]};
        3'd5: merge_cross_page_packet = {second_beat[23:0], first_beat[39:0]};
        3'd6: merge_cross_page_packet = {second_beat[15:0], first_beat[47:0]};
        3'd7: merge_cross_page_packet = {second_beat[7:0], first_beat[55:0]};
        default: merge_cross_page_packet = first_beat;
      endcase
    end
  endfunction

  wire req_paging_w = sv39_enabled(priv_mode_i, satp_i);
  wire [`XLEN-1:0] req_packet_end_pc_w = fetch_req_pc_i + 64'd7;
  wire [`XLEN-1:0] req_second_page_vaddr_w =
      {fetch_req_pc_i[`XLEN-1:12], 12'b0} + 64'd4096;
  wire [12:0] req_first_page_bytes_full_w =
      13'd4096 - {1'b0, fetch_req_pc_i[11:0]};
  wire req_same_fetch_page_w =
      fetch_req_pc_i[`XLEN-1:12] == req_packet_end_pc_w[`XLEN-1:12];
  wire req_cross_fetch_page_w = !req_same_fetch_page_w;
  wire [2:0] req_first_page_bytes_w =
      req_first_page_bytes_full_w[2:0];
  wire cache_hit_w;
  wire fetch_cache_context_unused_w;
  wire [`INST_W-1:0] cache_inst0_w;
  wire [`INST_W-1:0] cache_inst1_w;
  wire [1:0] cache_resp0_w;
  wire [1:0] cache_resp1_w;
  wire req_itlb_context_hit_w;
  wire [`XLEN-1:0] req_itlb_pte_w;
  wire [1:0] req_itlb_level_unused_w;
  wire [`XLEN-1:0] req_itlb_paddr_w;
  wire req_itlb_perm_fault_w =
      req_itlb_context_hit_w &&
      exec_permission_fault(req_itlb_pte_w, priv_mode_i);
  wire req_itlb_hit_w = req_itlb_context_hit_w && !req_itlb_perm_fault_w;
  wire fetch_req_fire_w = fetch_req_valid_i && fetch_req_ready_o;
  wire fetch_req_direct_miss_fire_w =
      fetch_req_fire_w && !req_paging_w && !cache_hit_w;
  wire [`XLEN-1:0] pc_packet_end_w = pc_q + 64'd7;
  wire [`XLEN-1:0] pc_second_page_vaddr_w =
      {pc_q[`XLEN-1:12], 12'b0} + 64'd4096;
  wire [`XLEN-1:0] walk_vaddr_w =
      walk_second_q ? pc_second_page_vaddr_w : pc_q;
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, walk_vaddr_w, walk_level_q);
  wire [`XLEN-1:0] fetch0_addr_w = paging_q ? paddr0_q : pc_q;
  wire same_fetch_page_w =
      pc_q[`XLEN-1:12] == pc_packet_end_w[`XLEN-1:12];
  wire [`INST_W-1:0] fetch_beat_inst0_w = ifu_axi_rdata_i[`INST_W-1:0];
  wire [`INST_W-1:0] fetch_beat_inst1_w = ifu_axi_rdata_i[`XLEN-1:`INST_W];
  wire [`XLEN-1:0] merged_cross_packet_w =
      merge_cross_page_packet(first_beat_q, ifu_axi_rdata_i,
                              packet_first_bytes_q);
  wire first_inst_cross_page_w =
      packet_cross_page_q && (packet_first_bytes_q < 3'd4);
  wire itlb_fill_valid_w =
      !mmu_flush_i && (state_q == S_WALK_R) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !pte_invalid(ifu_axi_rdata_i) &&
      (pte_leaf(ifu_axi_rdata_i)) &&
      !superpage_misaligned(ifu_axi_rdata_i, walk_level_q) &&
      !exec_permission_fault(ifu_axi_rdata_i, req_priv_q);
  wire fetch_cache_fill_r0_w =
      (state_q == S_R0) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !packet_cross_page_q &&
      (resp0_q == RESP_OK) && (resp1_q == RESP_OK);
  wire fetch_cache_fill_r1_w =
      (state_q == S_R1) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      (resp0_q == RESP_OK);
  wire fetch_cache_fill_valid_w =
      fetch_cache_fill_r0_w || fetch_cache_fill_r1_w;
  wire [`INST_W-1:0] fetch_cache_fill_inst0_w =
      fetch_cache_fill_r1_w ? merged_cross_packet_w[`INST_W-1:0] :
                              fetch_beat_inst0_w;
  wire [`INST_W-1:0] fetch_cache_fill_inst1_w =
      fetch_cache_fill_r1_w ? merged_cross_packet_w[`XLEN-1:`INST_W] :
                              fetch_beat_inst1_w;
  wire [1:0] fetch_cache_fill_resp0_w =
      fetch_cache_fill_r1_w ? resp0_q : RESP_OK;
  wire [1:0] fetch_cache_fill_resp1_w = resp1_q;

  OooFetchPacketCache #(
    .INDEX_W(CACHE_INDEX_W)
  ) u_fetch_packet_cache (
    .clk(clk),
    .rst(rst),
    .clear_i(mmu_flush_i),
    .lookup_paging_i(req_paging_w),
    .lookup_priv_i(priv_mode_i),
    .lookup_satp_i(satp_i),
    .lookup_pc_i(fetch_req_pc_i),
    .lookup_context_hit_o(fetch_cache_context_unused_w),
    .lookup_hit_o(cache_hit_w),
    .lookup_inst0_o(cache_inst0_w),
    .lookup_resp0_o(cache_resp0_w),
    .lookup_inst1_o(cache_inst1_w),
    .lookup_resp1_o(cache_resp1_w),
    .fill_valid_i(fetch_cache_fill_valid_w),
    .fill_paging_i(paging_q),
    .fill_priv_i(req_priv_q),
    .fill_satp_i(req_satp_q),
    .fill_pc_i(pc_q),
    .fill_inst0_i(fetch_cache_fill_inst0_w),
    .fill_resp0_i(fetch_cache_fill_resp0_w),
    .fill_inst1_i(fetch_cache_fill_inst1_w),
    .fill_resp1_i(fetch_cache_fill_resp1_w),
    .invalidate_valid_i(invalidate_valid_i),
    .invalidate_addr_i(invalidate_addr_i)
  );

  OooSv39Tlb #(
    .INDEX_W(ITLB_INDEX_W)
  ) u_itlb (
    .clk(clk),
    .rst(rst),
    .clear_i(mmu_flush_i),
    .lookup_valid_i(req_paging_w),
    .lookup_vaddr_i(fetch_req_pc_i),
    .lookup_satp_i(satp_i),
    .lookup_context_hit_o(req_itlb_context_hit_w),
    .lookup_pte_o(req_itlb_pte_w),
    .lookup_level_o(req_itlb_level_unused_w),
    .lookup_paddr_o(req_itlb_paddr_w),
    .fill_valid_i(itlb_fill_valid_w),
    .fill_vaddr_i(walk_vaddr_w),
    .fill_satp_i(req_satp_q),
    .fill_pte_i(ifu_axi_rdata_i),
    .fill_level_i(walk_level_q)
  );

  // packet cache 使用 PC+satp/priv 做上下文 tag；ITLB 命中只缓存翻译，不绕过取指权限。
  assign fetch_req_ready_o = (state_q == S_IDLE) ||
                             ((state_q == S_RESP) && fetch_rsp_ready_i);
  assign fetch_rsp_valid_o = (state_q == S_RESP);
  assign fetch_rsp_inst0_o = inst0_q;
  assign fetch_rsp_inst1_o = inst1_q;
  assign fetch_rsp_resp0_o = resp0_q;
  assign fetch_rsp_resp1_o = resp1_q;

  assign ifu_axi_arvalid_o =
      (state_q == S_WALK_AR) || (state_q == S_AR0) ||
      (state_q == S_AR1) ||
      fetch_req_direct_miss_fire_w;
  assign ifu_axi_araddr_o =
      (state_q == S_WALK_AR) ? walk_pte_addr_w :
      (state_q == S_AR1) ? paddr1_q :
      fetch_req_direct_miss_fire_w ? fetch_req_pc_i :
      fetch0_addr_w;
  assign ifu_axi_rready_o =
      (state_q == S_WALK_R) || (state_q == S_R0) || (state_q == S_R1);

  always @(posedge clk) begin
    if (rst || mmu_flush_i) begin
      state_q <= S_IDLE;
      paging_q <= 1'b0;
      req_priv_q <= `PRIV_M;
      req_satp_q <= {`XLEN{1'b0}};
      walk_second_q <= 1'b0;
      walk_level_q <= 2'd0;
      walk_ppn_q <= 44'd0;
      pc_q <= {`XLEN{1'b0}};
      paddr0_q <= {`XLEN{1'b0}};
      paddr1_q <= {`XLEN{1'b0}};
      packet_cross_page_q <= 1'b0;
      packet_first_bytes_q <= 3'd0;
      first_beat_q <= {`XLEN{1'b0}};
      inst0_q <= {`INST_W{1'b0}};
      inst1_q <= {`INST_W{1'b0}};
      resp0_q <= RESP_OK;
      resp1_q <= RESP_OK;
      debug_last_pte_addr_q <= {`XLEN{1'b0}};
      debug_last_pte_q <= {`XLEN{1'b0}};
      debug_last_pte_level_q <= 2'd0;
      debug_last_pte_second_q <= 1'b0;
    end else begin
      case (state_q)
        S_IDLE: begin
          if (fetch_req_fire_w) begin
            pc_q <= fetch_req_pc_i;
            paddr0_q <= fetch_req_pc_i;
            paddr1_q <= req_cross_fetch_page_w ? req_second_page_vaddr_w :
                                                   (fetch_req_pc_i + 64'd4);
            packet_cross_page_q <= req_cross_fetch_page_w;
            packet_first_bytes_q <= req_first_page_bytes_w;
            first_beat_q <= {`XLEN{1'b0}};
            inst0_q <= {`INST_W{1'b0}};
            inst1_q <= {`INST_W{1'b0}};
            resp0_q <= RESP_OK;
            resp1_q <= RESP_OK;
            paging_q <= req_paging_w;
            req_priv_q <= priv_mode_i;
            req_satp_q <= satp_i;
            if (cache_hit_w) begin
              inst0_q <= cache_inst0_w;
              inst1_q <= cache_inst1_w;
              resp0_q <= cache_resp0_w;
              resp1_q <= cache_resp1_w;
              state_q <= S_RESP;
            end else if (req_paging_w && req_itlb_perm_fault_w) begin
              resp0_q <= RESP_PAGE_FAULT;
              resp1_q <= RESP_PAGE_FAULT;
              state_q <= S_RESP;
            end else if (req_paging_w && req_itlb_hit_w) begin
              paddr0_q <= req_itlb_paddr_w;
              resp0_q <= RESP_OK;
              if (req_same_fetch_page_w) begin
                paddr1_q <= req_itlb_paddr_w + 64'd4;
                resp1_q <= RESP_OK;
                state_q <= S_AR0;
              end else if (canonical_sv39(req_second_page_vaddr_w)) begin
                walk_second_q <= 1'b1;
                walk_level_q <= 2'd2;
                walk_ppn_q <= satp_i[43:0];
                state_q <= S_WALK_AR;
              end else begin
                resp1_q <= RESP_PAGE_FAULT;
                state_q <= S_AR0;
              end
            end else if (req_paging_w) begin
              if (canonical_sv39(fetch_req_pc_i)) begin
                walk_second_q <= 1'b0;
                walk_level_q <= 2'd2;
                walk_ppn_q <= satp_i[43:0];
                state_q <= S_WALK_AR;
              end else begin
                resp0_q <= RESP_PAGE_FAULT;
                resp1_q <= RESP_PAGE_FAULT;
                state_q <= S_RESP;
              end
            end else begin
              state_q <= ifu_axi_arready_i ? S_R0 : S_AR0;
            end
          end
        end

        S_WALK_AR: begin
          if (ifu_axi_arready_i) begin
            state_q <= S_WALK_R;
          end
        end

        S_WALK_R: begin
          if (ifu_axi_rvalid_i) begin
            debug_last_pte_addr_q <= walk_pte_addr_w;
            debug_last_pte_q <= ifu_axi_rdata_i;
            debug_last_pte_level_q <= walk_level_q;
            debug_last_pte_second_q <= walk_second_q;
            if (ifu_axi_rresp_i != RESP_OK) begin
              if (walk_second_q) begin
                resp1_q <= RESP_ACCESS_FAULT;
                state_q <= S_AR0;
              end else begin
                resp0_q <= RESP_ACCESS_FAULT;
                resp1_q <= RESP_ACCESS_FAULT;
                state_q <= S_RESP;
              end
            end else if (pte_invalid(ifu_axi_rdata_i) ||
                         (!pte_leaf(ifu_axi_rdata_i) &&
                          (walk_level_q == 2'd0))) begin
              if (walk_second_q) begin
                resp1_q <= RESP_PAGE_FAULT;
                state_q <= S_AR0;
              end else begin
                resp0_q <= RESP_PAGE_FAULT;
                resp1_q <= RESP_PAGE_FAULT;
                state_q <= S_RESP;
              end
            end else if (pte_leaf(ifu_axi_rdata_i)) begin
              if (superpage_misaligned(ifu_axi_rdata_i, walk_level_q) ||
                  exec_permission_fault(ifu_axi_rdata_i, req_priv_q)) begin
                if (walk_second_q) begin
                  resp1_q <= RESP_PAGE_FAULT;
                  state_q <= S_AR0;
                end else begin
                  resp0_q <= RESP_PAGE_FAULT;
                  resp1_q <= RESP_PAGE_FAULT;
                  state_q <= S_RESP;
                end
              end else begin
                if (walk_second_q) begin
                paddr1_q <= leaf_paddr(ifu_axi_rdata_i,
                                       pc_second_page_vaddr_w,
                                       walk_level_q);
                resp1_q <= RESP_OK;
                state_q <= S_AR0;
                end else begin
                paddr0_q <= leaf_paddr(ifu_axi_rdata_i, pc_q, walk_level_q);
                resp0_q <= RESP_OK;
                if (same_fetch_page_w) begin
                  paddr1_q <= leaf_paddr(ifu_axi_rdata_i, pc_q,
                                         walk_level_q) + 64'd4;
                  resp1_q <= RESP_OK;
                  state_q <= S_AR0;
                end else if (canonical_sv39(pc_second_page_vaddr_w)) begin
                  walk_second_q <= 1'b1;
                  walk_level_q <= 2'd2;
                  walk_ppn_q <= req_satp_q[43:0];
                  state_q <= S_WALK_AR;
                end else begin
                  resp1_q <= RESP_PAGE_FAULT;
                  state_q <= S_AR0;
                end
              end
              end
            end else begin
              walk_ppn_q <= ifu_axi_rdata_i[53:10];
              walk_level_q <= walk_level_q - 2'd1;
              state_q <= S_WALK_AR;
            end
          end
        end

        S_AR0: begin
          if (ifu_axi_arready_i) begin
            state_q <= S_R0;
          end
        end

        S_R0: begin
          if (ifu_axi_rvalid_i) begin
            first_beat_q <= ifu_axi_rdata_i;
            inst0_q <= fetch_beat_inst0_w;
            inst1_q <= fetch_beat_inst1_w;
            if (ifu_axi_rresp_i != RESP_OK) begin
              resp0_q <= RESP_ACCESS_FAULT;
              resp1_q <= RESP_ACCESS_FAULT;
              state_q <= S_RESP;
            end else if (packet_cross_page_q && (resp1_q == RESP_OK)) begin
              state_q <= S_AR1;
            end else begin
              if (packet_cross_page_q && first_inst_cross_page_w &&
                  (resp1_q != RESP_OK)) begin
                resp0_q <= resp1_q;
              end
              state_q <= S_RESP;
            end
          end
        end

        S_AR1: begin
          if (ifu_axi_arready_i) begin
            state_q <= S_R1;
          end
        end

        S_R1: begin
          if (ifu_axi_rvalid_i) begin
            inst0_q <= merged_cross_packet_w[`INST_W-1:0];
            inst1_q <= merged_cross_packet_w[`XLEN-1:`INST_W];
            if (first_inst_cross_page_w && (ifu_axi_rresp_i != RESP_OK)) begin
              resp0_q <= RESP_ACCESS_FAULT;
            end
            resp1_q <= (ifu_axi_rresp_i == RESP_OK) ? resp1_q :
                       RESP_ACCESS_FAULT;
            state_q <= S_RESP;
          end
        end

        S_RESP: begin
          if (fetch_rsp_ready_i) begin
            if (fetch_req_valid_i) begin
              pc_q <= fetch_req_pc_i;
              paddr0_q <= fetch_req_pc_i;
              paddr1_q <= req_cross_fetch_page_w ? req_second_page_vaddr_w :
                                                     (fetch_req_pc_i + 64'd4);
              packet_cross_page_q <= req_cross_fetch_page_w;
              packet_first_bytes_q <= req_first_page_bytes_w;
              first_beat_q <= {`XLEN{1'b0}};
              inst0_q <= {`INST_W{1'b0}};
              inst1_q <= {`INST_W{1'b0}};
              resp0_q <= RESP_OK;
              resp1_q <= RESP_OK;
              paging_q <= req_paging_w;
              req_priv_q <= priv_mode_i;
              req_satp_q <= satp_i;
              if (cache_hit_w) begin
                inst0_q <= cache_inst0_w;
                inst1_q <= cache_inst1_w;
                resp0_q <= cache_resp0_w;
                resp1_q <= cache_resp1_w;
                state_q <= S_RESP;
              end else if (req_paging_w && req_itlb_perm_fault_w) begin
                resp0_q <= RESP_PAGE_FAULT;
                resp1_q <= RESP_PAGE_FAULT;
                state_q <= S_RESP;
              end else if (req_paging_w && req_itlb_hit_w) begin
                paddr0_q <= req_itlb_paddr_w;
                resp0_q <= RESP_OK;
                if (req_same_fetch_page_w) begin
                  paddr1_q <= req_itlb_paddr_w + 64'd4;
                  resp1_q <= RESP_OK;
                  state_q <= S_AR0;
                end else if (canonical_sv39(req_second_page_vaddr_w)) begin
                  walk_second_q <= 1'b1;
                  walk_level_q <= 2'd2;
                  walk_ppn_q <= satp_i[43:0];
                  state_q <= S_WALK_AR;
                end else begin
                  resp1_q <= RESP_PAGE_FAULT;
                  state_q <= S_AR0;
                end
              end else if (req_paging_w) begin
                if (canonical_sv39(fetch_req_pc_i)) begin
                  walk_second_q <= 1'b0;
                  walk_level_q <= 2'd2;
                  walk_ppn_q <= satp_i[43:0];
                  state_q <= S_WALK_AR;
                end else begin
                  resp0_q <= RESP_PAGE_FAULT;
                  resp1_q <= RESP_PAGE_FAULT;
                  state_q <= S_RESP;
                end
              end else begin
                state_q <= ifu_axi_arready_i ? S_R0 : S_AR0;
              end
            end else begin
              state_q <= S_IDLE;
            end
          end
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
    end
  end

endmodule
