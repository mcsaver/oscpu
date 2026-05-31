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
  localparam CACHE_ENTRIES = (1 << CACHE_INDEX_W);

  reg [3:0] state_q;
  reg paging_q;
  reg walk_second_q;
  reg [1:0] walk_level_q;
  reg [43:0] walk_ppn_q;
  reg [`XLEN-1:0] pc_q;
  reg [`XLEN-1:0] paddr0_q;
  reg [`XLEN-1:0] paddr1_q;
  reg [`INST_W-1:0] inst0_q;
  reg [`INST_W-1:0] inst1_q;
  reg [1:0] resp0_q;
  reg [1:0] resp1_q;
  reg [`XLEN-1:0] debug_last_pte_addr_q;
  reg [`XLEN-1:0] debug_last_pte_q;
  reg [1:0] debug_last_pte_level_q;
  reg debug_last_pte_second_q;

  reg [CACHE_ENTRIES-1:0] cache_valid_q;
  reg cache_paging_q [0:CACHE_ENTRIES-1];
  reg [1:0] cache_priv_q [0:CACHE_ENTRIES-1];
  reg [`XLEN-1:0] cache_satp_q [0:CACHE_ENTRIES-1];
  reg [`XLEN-1:0] cache_pc_q [0:CACHE_ENTRIES-1];
  reg [`INST_W-1:0] cache_inst0_q [0:CACHE_ENTRIES-1];
  reg [`INST_W-1:0] cache_inst1_q [0:CACHE_ENTRIES-1];
  reg [1:0] cache_resp0_q [0:CACHE_ENTRIES-1];
  reg [1:0] cache_resp1_q [0:CACHE_ENTRIES-1];

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

  /* verilator lint_off UNUSEDSIGNAL */
  function [CACHE_INDEX_W-1:0] cache_index;
    input [`XLEN-1:0] pc;
    begin
      cache_index = pc[CACHE_INDEX_W:1];
    end
  endfunction

  function cache_overlap;
    input [`XLEN-1:0] fetch_pc;
    input [`XLEN-1:0] store_addr;
    begin
      cache_overlap =
          ((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) <= (fetch_pc + 32'd7)) &&
          (((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) + 32'd3) >= fetch_pc);
    end
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */

  wire req_paging_w = sv39_enabled(priv_mode_i, satp_i);
  wire [CACHE_INDEX_W-1:0] req_cache_idx_w = cache_index(fetch_req_pc_i);
  wire [CACHE_INDEX_W-1:0] fill_cache_idx_w = cache_index(pc_q);
  wire req_cache_invalidated_w =
      invalidate_valid_i && cache_overlap(fetch_req_pc_i, invalidate_addr_i);
  wire fill_cache_invalidated_w =
      invalidate_valid_i && cache_overlap(pc_q, invalidate_addr_i);
  wire cache_context_hit_w =
      cache_valid_q[req_cache_idx_w] &&
      (cache_paging_q[req_cache_idx_w] == req_paging_w) &&
      (!req_paging_w ||
       ((cache_priv_q[req_cache_idx_w] == priv_mode_i) &&
        (cache_satp_q[req_cache_idx_w] == satp_i)));
  wire cache_hit_w =
      cache_context_hit_w &&
      (cache_pc_q[req_cache_idx_w] == fetch_req_pc_i) &&
      !req_cache_invalidated_w;
  wire fetch_req_fire_w = fetch_req_valid_i && fetch_req_ready_o;
  wire fetch_req_direct_miss_fire_w =
      fetch_req_fire_w && !req_paging_w && !cache_hit_w;
  wire [`XLEN-1:0] walk_vaddr_w = walk_second_q ? (pc_q + 64'd4) : pc_q;
  wire [`XLEN-1:0] pc_plus4_w = pc_q + 64'd4;
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, walk_vaddr_w, walk_level_q);
  wire [`XLEN-1:0] fetch0_addr_w = paging_q ? paddr0_q : pc_q;
  wire [`XLEN-1:0] fetch1_addr_w = paging_q ? paddr1_q : pc_plus4_w;
  wire same_fetch_page_w = pc_q[`XLEN-1:12] == pc_plus4_w[`XLEN-1:12];

  // hit 响应一拍后返回；分页开启时绕过虚拟 cache，避免 satp/alias 污染。
  assign fetch_req_ready_o = (state_q == S_IDLE) ||
                             ((state_q == S_RESP) && fetch_rsp_ready_i);
  assign fetch_rsp_valid_o = (state_q == S_RESP);
  assign fetch_rsp_inst0_o = inst0_q;
  assign fetch_rsp_inst1_o = inst1_q;
  assign fetch_rsp_resp0_o = resp0_q;
  assign fetch_rsp_resp1_o = resp1_q;

  assign ifu_axi_arvalid_o =
      (state_q == S_WALK_AR) || (state_q == S_AR0) ||
      (state_q == S_AR1) || fetch_req_direct_miss_fire_w;
  assign ifu_axi_araddr_o =
      (state_q == S_WALK_AR) ? walk_pte_addr_w :
      fetch_req_direct_miss_fire_w ? fetch_req_pc_i :
      ((state_q == S_AR1) ? fetch1_addr_w : fetch0_addr_w);
  assign ifu_axi_rready_o =
      (state_q == S_WALK_R) || (state_q == S_R0) || (state_q == S_R1);

  integer cache_idx;

  always @(posedge clk) begin
    if (rst || mmu_flush_i) begin
      state_q <= S_IDLE;
      paging_q <= 1'b0;
      walk_second_q <= 1'b0;
      walk_level_q <= 2'd0;
      walk_ppn_q <= 44'd0;
      pc_q <= {`XLEN{1'b0}};
      paddr0_q <= {`XLEN{1'b0}};
      paddr1_q <= {`XLEN{1'b0}};
      inst0_q <= {`INST_W{1'b0}};
      inst1_q <= {`INST_W{1'b0}};
      resp0_q <= RESP_OK;
      resp1_q <= RESP_OK;
      debug_last_pte_addr_q <= {`XLEN{1'b0}};
      debug_last_pte_q <= {`XLEN{1'b0}};
      debug_last_pte_level_q <= 2'd0;
      debug_last_pte_second_q <= 1'b0;
      cache_valid_q <= {CACHE_ENTRIES{1'b0}};
    end else begin
      if (invalidate_valid_i) begin
        for (cache_idx = 0; cache_idx < CACHE_ENTRIES; cache_idx = cache_idx + 1) begin
          if (cache_valid_q[cache_idx] &&
              cache_overlap(cache_pc_q[cache_idx], invalidate_addr_i)) begin
            cache_valid_q[cache_idx] <= 1'b0;
          end
        end
      end

      case (state_q)
        S_IDLE: begin
          if (fetch_req_fire_w) begin
            pc_q <= fetch_req_pc_i;
            paddr0_q <= fetch_req_pc_i;
            paddr1_q <= fetch_req_pc_i + 64'd4;
            inst0_q <= {`INST_W{1'b0}};
            inst1_q <= {`INST_W{1'b0}};
            resp0_q <= RESP_OK;
            resp1_q <= RESP_OK;
            paging_q <= req_paging_w;
            if (cache_hit_w) begin
              inst0_q <= cache_inst0_q[req_cache_idx_w];
              inst1_q <= cache_inst1_q[req_cache_idx_w];
              resp0_q <= cache_resp0_q[req_cache_idx_w];
              resp1_q <= cache_resp1_q[req_cache_idx_w];
              state_q <= S_RESP;
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
                  exec_permission_fault(ifu_axi_rdata_i, priv_mode_i)) begin
                if (walk_second_q) begin
                  resp1_q <= RESP_PAGE_FAULT;
                  state_q <= S_AR0;
                end else begin
                  resp0_q <= RESP_PAGE_FAULT;
                  resp1_q <= RESP_PAGE_FAULT;
                  state_q <= S_RESP;
                end
              end else if (walk_second_q) begin
                paddr1_q <= leaf_paddr(ifu_axi_rdata_i, pc_q + 64'd4,
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
                end else if (canonical_sv39(pc_q + 64'd4)) begin
                  walk_second_q <= 1'b1;
                  walk_level_q <= 2'd2;
                  walk_ppn_q <= satp_i[43:0];
                  state_q <= S_WALK_AR;
                end else begin
                  resp1_q <= RESP_PAGE_FAULT;
                  state_q <= S_AR0;
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
            inst0_q <= ifu_axi_rdata_i[`INST_W-1:0];
            resp0_q <= (ifu_axi_rresp_i == RESP_OK) ? resp0_q :
                       RESP_ACCESS_FAULT;
            state_q <= ((ifu_axi_rresp_i != RESP_OK) ||
                        (resp1_q != RESP_OK)) ? S_RESP : S_AR1;
          end
        end

        S_AR1: begin
          if (ifu_axi_arready_i) begin
            state_q <= S_R1;
          end
        end

        S_R1: begin
          if (ifu_axi_rvalid_i) begin
            inst1_q <= ifu_axi_rdata_i[`INST_W-1:0];
            resp1_q <= (ifu_axi_rresp_i == RESP_OK) ? resp1_q :
                       RESP_ACCESS_FAULT;
            if ((resp0_q == RESP_OK) &&
                (ifu_axi_rresp_i == RESP_OK) && !fill_cache_invalidated_w) begin
              // 只缓存完整无错误 packet；分页态 entry 额外带 satp/priv 上下文。
              cache_valid_q[fill_cache_idx_w] <= 1'b1;
              cache_paging_q[fill_cache_idx_w] <= paging_q;
              cache_priv_q[fill_cache_idx_w] <= priv_mode_i;
              cache_satp_q[fill_cache_idx_w] <= satp_i;
              cache_pc_q[fill_cache_idx_w] <= pc_q;
              cache_inst0_q[fill_cache_idx_w] <= inst0_q;
              cache_inst1_q[fill_cache_idx_w] <= ifu_axi_rdata_i[`INST_W-1:0];
              cache_resp0_q[fill_cache_idx_w] <= resp0_q;
              cache_resp1_q[fill_cache_idx_w] <=
                  (ifu_axi_rresp_i == RESP_OK) ? resp1_q : RESP_ACCESS_FAULT;
            end
            state_q <= S_RESP;
          end
        end

        S_RESP: begin
          if (fetch_rsp_ready_i) begin
            if (fetch_req_valid_i) begin
              pc_q <= fetch_req_pc_i;
              paddr0_q <= fetch_req_pc_i;
              paddr1_q <= fetch_req_pc_i + 64'd4;
              inst0_q <= {`INST_W{1'b0}};
              inst1_q <= {`INST_W{1'b0}};
              resp0_q <= RESP_OK;
              resp1_q <= RESP_OK;
              paging_q <= req_paging_w;
              if (cache_hit_w) begin
                inst0_q <= cache_inst0_q[req_cache_idx_w];
                inst1_q <= cache_inst1_q[req_cache_idx_w];
                resp0_q <= cache_resp0_q[req_cache_idx_w];
                resp1_q <= cache_resp1_q[req_cache_idx_w];
                state_q <= S_RESP;
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
