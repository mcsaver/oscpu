`include "define.v"

module OooMemAxiBridge (
  input clk,
  input rst,
  input flush_i,
  input mmu_flush_i,

  input [1:0] priv_mode_i,
  input [`XLEN-1:0] mstatus_i,
  input [`XLEN-1:0] satp_i,

  input mem0_req_valid_i,
  output mem0_req_ready_o,
  input mem0_req_write_i,
  input [`XLEN-1:0] mem0_req_addr_i,
  input [`XLEN-1:0] mem0_req_wdata_i,
  input [`STRB_W-1:0] mem0_req_wstrb_i,
  output mem0_rsp_valid_o,
  input mem0_rsp_ready_i,
  output [`XLEN-1:0] mem0_rsp_rdata_o,
  output mem0_rsp_error_o,
  output mem0_rsp_page_fault_o,

  input mem1_req_valid_i,
  output mem1_req_ready_o,
  input mem1_req_write_i,
  input [`XLEN-1:0] mem1_req_addr_i,
  input [`XLEN-1:0] mem1_req_wdata_i,
  input [`STRB_W-1:0] mem1_req_wstrb_i,
  output mem1_rsp_valid_o,
  input mem1_rsp_ready_i,
  output [`XLEN-1:0] mem1_rsp_rdata_o,
  output mem1_rsp_error_o,
  output mem1_rsp_page_fault_o,

  output lsu_axi_arvalid_o,
  input lsu_axi_arready_i,
  output [`XLEN-1:0] lsu_axi_araddr_o,
  input lsu_axi_rvalid_i,
  output lsu_axi_rready_o,
  input [`XLEN-1:0] lsu_axi_rdata_i,
  input [1:0] lsu_axi_rresp_i,
  output lsu_axi_awvalid_o,
  input lsu_axi_awready_i,
  output [`XLEN-1:0] lsu_axi_awaddr_o,
  output lsu_axi_wvalid_o,
  input lsu_axi_wready_i,
  output [`XLEN-1:0] lsu_axi_wdata_o,
  output [`STRB_W-1:0] lsu_axi_wstrb_o,
  input lsu_axi_bvalid_i,
  output lsu_axi_bready_o,
  input [1:0] lsu_axi_bresp_i
);

  localparam [3:0] S_IDLE = 4'd0;
  localparam [3:0] S_WALK_AR = 4'd1;
  localparam [3:0] S_WALK_R = 4'd2;
  localparam [3:0] S_READ_ADDR = 4'd3;
  localparam [3:0] S_READ_DATA = 4'd4;
  localparam [3:0] S_WRITE_REQ = 4'd5;
  localparam [3:0] S_WRITE_RESP = 4'd6;
  localparam [3:0] S_RESP = 4'd7;
  localparam DCACHE_INDEX_W = 10;
  localparam DTLB_INDEX_W = 6;

  reg [3:0] state_q;
  reg active_port_q;
  reg write_q;
  reg paging_q;
  reg [1:0] access_priv_q;
  reg [1:0] walk_level_q;
  reg [43:0] walk_ppn_q;
  reg [`XLEN-1:0] addr_q;
  reg [`XLEN-1:0] paddr_q;
  reg [`XLEN-1:0] wdata_q;
  reg [`STRB_W-1:0] wstrb_q;
  reg [`XLEN-1:0] rsp_rdata_q;
  reg rsp_error_q;
  reg rsp_page_fault_q;
  reg aw_done_q;
  reg w_done_q;
  reg drop_rsp_q;

  function [1:0] mstatus_mpp_priv;
    input [`XLEN-1:0] status;
    begin
      case (status & `MSTATUS_MPP_MASK)
        `MSTATUS_MPP_S: mstatus_mpp_priv = `PRIV_S;
        `MSTATUS_MPP_M: mstatus_mpp_priv = `PRIV_M;
        default:        mstatus_mpp_priv = `PRIV_U;
      endcase
    end
  endfunction

  function [1:0] effective_data_priv;
    input [1:0] priv_mode;
    input [`XLEN-1:0] status;
    begin
      effective_data_priv =
          ((priv_mode == `PRIV_M) &&
           ((status & `MSTATUS_MPRV) != {`XLEN{1'b0}})) ?
          mstatus_mpp_priv(status) : priv_mode;
    end
  endfunction

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

  function data_read_ok;
    input [`XLEN-1:0] pte;
    input [`XLEN-1:0] status;
    begin
      data_read_ok =
          pte[1] ||
          (((status & `MSTATUS_MXR) != {`XLEN{1'b0}}) && pte[3]);
    end
  endfunction

  function data_user_ok;
    input [`XLEN-1:0] pte;
    input [1:0] priv_mode;
    input [`XLEN-1:0] status;
    begin
      data_user_ok =
          (priv_mode == `PRIV_U) ? pte[4] :
          (pte[4] ? ((status & `MSTATUS_SUM) != {`XLEN{1'b0}}) : 1'b1);
    end
  endfunction

  function data_permission_fault;
    input [`XLEN-1:0] pte;
    input write_access;
    input [1:0] priv_mode;
    input [`XLEN-1:0] status;
    begin
      // 权限判断拆成纯组合 helper，保持 MXR/SUM/U 语义且去掉函数级 waiver。
      data_permission_fault =
          (write_access ? !pte[2] : !data_read_ok(pte, status)) ||
          !data_user_ok(pte, priv_mode, status);
    end
  endfunction

  function [`XLEN-1:0] leaf_paddr;
    input [`XLEN-1:0] pte;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      // 用组合 mux 直接拼 leaf PPN，便于后续 TLB/page-walk 逻辑 lint 收敛。
      leaf_paddr = {8'b0,
                    (level == 2'd2) ?
                    {pte[53:28], vaddr[29:21], vaddr[20:12]} :
                    (level == 2'd1) ?
                    {pte[53:28], pte[27:19], vaddr[20:12]} :
                    pte[53:10],
                    vaddr[11:0]};
    end
  endfunction

  wire [1:0] req_priv_w = effective_data_priv(priv_mode_i, mstatus_i);
  wire req_translate_w = sv39_enabled(req_priv_w, satp_i);
  wire mem0_req_fire_w = mem0_req_valid_i && mem0_req_ready_o;
  wire mem1_req_fire_w = mem1_req_valid_i && mem1_req_ready_o;
  wire aw_fire_w = lsu_axi_awvalid_o && lsu_axi_awready_i;
  wire w_fire_w = lsu_axi_wvalid_o && lsu_axi_wready_i;
  wire rsp_ready_w = (active_port_q == 1'b0) ? mem0_rsp_ready_i : mem1_rsp_ready_i;
  wire cpu_kill_w = flush_i || drop_rsp_q;
  wire req_slot_ready_w = !cpu_kill_w &&
                          ((state_q == S_IDLE) ||
                           ((state_q == S_RESP) && rsp_ready_w));
  wire req_select_mem1_w = !mem0_req_valid_i && mem1_req_valid_i;
  wire req_write_w = req_select_mem1_w ? mem1_req_write_i : mem0_req_write_i;
  wire [`XLEN-1:0] req_addr_w =
      req_select_mem1_w ? mem1_req_addr_i : mem0_req_addr_i;
  wire [`XLEN-1:0] req_wdata_w =
      req_select_mem1_w ? mem1_req_wdata_i : mem0_req_wdata_i;
  wire [`STRB_W-1:0] req_wstrb_w =
      req_select_mem1_w ? mem1_req_wstrb_i : mem0_req_wstrb_i;
  wire req_dtlb_context_hit_w;
  wire [`XLEN-1:0] req_dtlb_pte_w;
  wire [1:0] req_dtlb_level_unused_w;
  wire [`XLEN-1:0] req_translated_paddr_w;
  wire req_dtlb_perm_fault_w =
      req_dtlb_context_hit_w &&
      data_permission_fault(req_dtlb_pte_w, req_write_w, req_priv_w,
                            mstatus_i);
  wire req_dtlb_hit_w = req_dtlb_context_hit_w && !req_dtlb_perm_fault_w;
  wire [`XLEN-1:0] req_cache_addr_w =
      req_dtlb_hit_w ? req_translated_paddr_w : req_addr_w;
  wire req_dcacheable_unused_w;
  wire req_dcache_hit_raw_w;
  wire [`XLEN-1:0] req_dcache_data_w;
  wire req_dcache_hit_w =
      (!req_translate_w || req_dtlb_hit_w) && req_dcache_hit_raw_w;
  wire req_read_miss_fire_w =
      (mem0_req_fire_w || mem1_req_fire_w) && !req_write_w &&
      (!req_translate_w || req_dtlb_hit_w) && !req_dcache_hit_w;
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, addr_q, walk_level_q);
  wire [`XLEN-1:0] walk_leaf_paddr_w =
      leaf_paddr(lsu_axi_rdata_i, addr_q, walk_level_q);
  wire walk_leaf_dcacheable_unused_w;
  wire walk_leaf_dcache_hit_w;
  wire [`XLEN-1:0] walk_leaf_dcache_data_w;
  wire write_paddr_virtio_blk_w =
      ((paddr_q & `NPC_AXI_VIRTIO_BLK_MASK) == `NPC_AXI_VIRTIO_BLK_BASE);
  wire dtlb_fill_valid_w =
      (state_q == S_WALK_R) && lsu_axi_rvalid_i &&
      (lsu_axi_rresp_i == 2'b00) &&
      !pte_invalid(lsu_axi_rdata_i) &&
      pte_leaf(lsu_axi_rdata_i) &&
      !superpage_misaligned(lsu_axi_rdata_i, walk_level_q) &&
      !data_permission_fault(lsu_axi_rdata_i, write_q, access_priv_q,
                             mstatus_i);
  wire dcache_read_fill_valid_w =
      !cpu_kill_w && (state_q == S_READ_DATA) && lsu_axi_rvalid_i &&
      (lsu_axi_rresp_i == 2'b00);
  wire dcache_store_commit_w =
      (state_q == S_WRITE_RESP) && lsu_axi_bvalid_i &&
      (lsu_axi_bresp_i == 2'b00);

  OooSv39Tlb #(
    .INDEX_W(DTLB_INDEX_W)
  ) u_dtlb (
    .clk(clk),
    .rst(rst),
    .clear_i(mmu_flush_i),
    .lookup_valid_i(req_translate_w),
    .lookup_vaddr_i(req_addr_w),
    .lookup_satp_i(satp_i),
    .lookup_context_hit_o(req_dtlb_context_hit_w),
    .lookup_pte_o(req_dtlb_pte_w),
    .lookup_level_o(req_dtlb_level_unused_w),
    .lookup_paddr_o(req_translated_paddr_w),
    .fill_valid_i(dtlb_fill_valid_w),
    .fill_vaddr_i(addr_q),
    .fill_satp_i(satp_i),
    .fill_pte_i(lsu_axi_rdata_i),
    .fill_level_i(walk_level_q)
  );

  OooDataWordCache #(
    .INDEX_W(DCACHE_INDEX_W)
  ) u_dcache (
    .clk(clk),
    .rst(rst),
    .req_lookup_addr_i(req_cache_addr_w),
    .req_cacheable_o(req_dcacheable_unused_w),
    .req_hit_o(req_dcache_hit_raw_w),
    .req_data_o(req_dcache_data_w),
    .walk_lookup_addr_i(walk_leaf_paddr_w),
    .walk_cacheable_o(walk_leaf_dcacheable_unused_w),
    .walk_hit_o(walk_leaf_dcache_hit_w),
    .walk_data_o(walk_leaf_dcache_data_w),
    .fill_valid_i(dcache_read_fill_valid_w),
    .fill_addr_i(paddr_q),
    .fill_data_i(lsu_axi_rdata_i),
    .store_commit_i(dcache_store_commit_w),
    .store_invalidate_all_i(write_paddr_virtio_blk_w),
    .store_addr_i(paddr_q),
    .store_data_i(wdata_q),
    .store_wstrb_i(wstrb_q)
  );

  assign mem0_req_ready_o = req_slot_ready_w;
  assign mem1_req_ready_o = req_slot_ready_w && !mem0_req_valid_i;

  assign mem0_rsp_valid_o =
      (state_q == S_RESP) && !cpu_kill_w && (active_port_q == 1'b0);
  assign mem1_rsp_valid_o =
      (state_q == S_RESP) && !cpu_kill_w && (active_port_q == 1'b1);
  assign mem0_rsp_rdata_o = rsp_rdata_q;
  assign mem1_rsp_rdata_o = rsp_rdata_q;
  assign mem0_rsp_error_o = rsp_error_q;
  assign mem1_rsp_error_o = rsp_error_q;
  assign mem0_rsp_page_fault_o = rsp_page_fault_q;
  assign mem1_rsp_page_fault_o = rsp_page_fault_q;

  assign lsu_axi_arvalid_o =
      !cpu_kill_w &&
      ((state_q == S_WALK_AR) || (state_q == S_READ_ADDR) ||
       req_read_miss_fire_w);
  assign lsu_axi_araddr_o =
      (state_q == S_WALK_AR) ? walk_pte_addr_w :
      req_read_miss_fire_w ? req_cache_addr_w : paddr_q;
  assign lsu_axi_rready_o = (state_q == S_WALK_R) || (state_q == S_READ_DATA);
  wire write_drain_w =
      drop_rsp_q || (flush_i && (aw_done_q || w_done_q));
  assign lsu_axi_awvalid_o =
      (state_q == S_WRITE_REQ) && !aw_done_q &&
      (!cpu_kill_w || write_drain_w);
  assign lsu_axi_awaddr_o = paddr_q;
  assign lsu_axi_wvalid_o =
      (state_q == S_WRITE_REQ) && !w_done_q &&
      (!cpu_kill_w || write_drain_w);
  assign lsu_axi_wdata_o = wdata_q;
  assign lsu_axi_wstrb_o = wstrb_q;
  assign lsu_axi_bready_o = (state_q == S_WRITE_RESP);

  task automatic accept_request;
    input port1;
    begin
      active_port_q <= port1;
      write_q <= req_write_w;
      paging_q <= req_translate_w;
      access_priv_q <= req_priv_w;
      addr_q <= req_addr_w;
      paddr_q <= req_cache_addr_w;
      wdata_q <= req_wdata_w;
      wstrb_q <= req_wstrb_w;
      rsp_rdata_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
      rsp_page_fault_q <= 1'b0;
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
      if (req_translate_w && req_dtlb_perm_fault_w) begin
        rsp_error_q <= 1'b1;
        rsp_page_fault_q <= 1'b1;
        state_q <= S_RESP;
      end else if (req_translate_w && !req_dtlb_hit_w) begin
        if (canonical_sv39(req_addr_w)) begin
          walk_level_q <= 2'd2;
          walk_ppn_q <= satp_i[43:0];
          state_q <= S_WALK_AR;
        end else begin
          rsp_error_q <= 1'b1;
          rsp_page_fault_q <= 1'b1;
          state_q <= S_RESP;
        end
      end else if (req_write_w) begin
        state_q <= S_WRITE_REQ;
      end else if (req_dcache_hit_w) begin
        rsp_rdata_q <= req_dcache_data_w;
        state_q <= S_RESP;
      end else begin
        state_q <= lsu_axi_arready_i ? S_READ_DATA : S_READ_ADDR;
      end
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      state_q <= S_IDLE;
      active_port_q <= 1'b0;
      write_q <= 1'b0;
      paging_q <= 1'b0;
      access_priv_q <= `PRIV_M;
      walk_level_q <= 2'd0;
      walk_ppn_q <= 44'd0;
      addr_q <= {`XLEN{1'b0}};
      paddr_q <= {`XLEN{1'b0}};
      wdata_q <= {`XLEN{1'b0}};
      wstrb_q <= {`STRB_W{1'b0}};
      rsp_rdata_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
      rsp_page_fault_q <= 1'b0;
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
      drop_rsp_q <= 1'b0;
    end else begin
      if (flush_i || drop_rsp_q) begin
      case (state_q)
        S_IDLE: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end

        S_WALK_AR, S_READ_ADDR: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end

        S_WALK_R, S_READ_DATA: begin
          if (flush_i) begin
            // 读事务无外部副作用，flush 会同步请求 xbar abort/drop；
            // 本地直接释放，避免等待一个已被下游取消的 R 响应。
            state_q <= S_IDLE;
            drop_rsp_q <= 1'b0;
          end else if (lsu_axi_rvalid_i) begin
            state_q <= S_IDLE;
            drop_rsp_q <= 1'b0;
          end else begin
            drop_rsp_q <= 1'b1;
          end
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
        end

        S_WRITE_REQ: begin
          if (aw_done_q || w_done_q || aw_fire_w || w_fire_w || drop_rsp_q) begin
            aw_done_q <= aw_done_q || aw_fire_w;
            w_done_q <= w_done_q || w_fire_w;
            drop_rsp_q <= 1'b1;
            state_q <= ((aw_done_q || aw_fire_w) &&
                        (w_done_q || w_fire_w)) ? S_WRITE_RESP : S_WRITE_REQ;
          end else begin
            state_q <= S_IDLE;
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            drop_rsp_q <= 1'b0;
          end
        end

        S_WRITE_RESP: begin
          if (lsu_axi_bvalid_i) begin
            state_q <= S_IDLE;
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            drop_rsp_q <= 1'b0;
          end else begin
            drop_rsp_q <= 1'b1;
          end
        end

        S_RESP: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end

        default: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end
      endcase
      end else begin
      case (state_q)
        S_IDLE: begin
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
          if (mem0_req_fire_w) begin
            accept_request(1'b0);
          end else if (mem1_req_fire_w) begin
            accept_request(1'b1);
          end
        end

        S_WALK_AR: begin
          if (lsu_axi_arready_i) begin
            state_q <= S_WALK_R;
          end
        end

        S_WALK_R: begin
          if (lsu_axi_rvalid_i) begin
            if (lsu_axi_rresp_i != 2'b00) begin
              rsp_error_q <= 1'b1;
              rsp_page_fault_q <= 1'b0;
              state_q <= S_RESP;
            end else if (pte_invalid(lsu_axi_rdata_i) ||
                         (!pte_leaf(lsu_axi_rdata_i) &&
                          (walk_level_q == 2'd0))) begin
              rsp_error_q <= 1'b1;
              rsp_page_fault_q <= 1'b1;
              state_q <= S_RESP;
            end else if (pte_leaf(lsu_axi_rdata_i)) begin
              if (superpage_misaligned(lsu_axi_rdata_i, walk_level_q) ||
                  data_permission_fault(lsu_axi_rdata_i, write_q,
                                        access_priv_q, mstatus_i)) begin
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b1;
                state_q <= S_RESP;
              end else begin
                paddr_q <= walk_leaf_paddr_w;
                if (write_q) begin
                  state_q <= S_WRITE_REQ;
                end else if (walk_leaf_dcache_hit_w) begin
                  rsp_rdata_q <= walk_leaf_dcache_data_w;
                  rsp_error_q <= 1'b0;
                  rsp_page_fault_q <= 1'b0;
                  state_q <= S_RESP;
                end else begin
                  state_q <= S_READ_ADDR;
                end
              end
            end else begin
              walk_ppn_q <= lsu_axi_rdata_i[53:10];
              walk_level_q <= walk_level_q - 2'd1;
              state_q <= S_WALK_AR;
            end
          end
        end

        S_READ_ADDR: begin
          if (lsu_axi_arready_i) begin
            state_q <= S_READ_DATA;
          end
        end

        S_READ_DATA: begin
          if (lsu_axi_rvalid_i) begin
            rsp_rdata_q <= lsu_axi_rdata_i;
            rsp_error_q <= (lsu_axi_rresp_i != 2'b00);
            rsp_page_fault_q <= 1'b0;
            state_q <= S_RESP;
          end
        end

        S_WRITE_REQ: begin
          if (aw_fire_w) begin
            aw_done_q <= 1'b1;
          end
          if (w_fire_w) begin
            w_done_q <= 1'b1;
          end
          if ((aw_done_q || aw_fire_w) && (w_done_q || w_fire_w)) begin
            state_q <= S_WRITE_RESP;
          end
        end

        S_WRITE_RESP: begin
          if (lsu_axi_bvalid_i) begin
            rsp_rdata_q <= {`XLEN{1'b0}};
            rsp_error_q <= (lsu_axi_bresp_i != 2'b00);
            rsp_page_fault_q <= 1'b0;
            state_q <= S_RESP;
          end
        end

        S_RESP: begin
          if (rsp_ready_w) begin
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            if (mem0_req_fire_w) begin
              accept_request(1'b0);
            end else if (mem1_req_fire_w) begin
              accept_request(1'b1);
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
  end

endmodule
