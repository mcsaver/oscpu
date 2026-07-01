`include "define.v"

module OooMemAxiBridge (
  input clk,
  input rst,
  input flush_i,
  input mmu_flush_i,

  input [1:0] priv_mode_i,
  input [`XLEN-1:0] mstatus_i,
  input [`XLEN-1:0] satp_i,
  input svpbmt_en_i,
  input [`PMP_CFG_BUS_W-1:0] pmpcfg_i,
  input [`PMP_ADDR_BUS_W-1:0] pmpaddr_i,

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

  output lsu_axi_arvalid_o,
  input lsu_axi_arready_i,
  output [`XLEN-1:0] lsu_axi_araddr_o,
  output [`STRB_W-1:0] lsu_axi_arstrb_o,
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
  reg write_q;
  reg paging_q;
  reg [1:0] access_priv_q;
  reg access_svpbmt_en_q;
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
  // B1 访存解耦：cacheable-PMEM store 在数据落 PMEM(AW&W fire)后即报完成、提前推进，
  // 其滞后的 AXI B 由 bpend_q 跟踪器在后台吸收，使紧随的 load 可与 B drain 重叠。
  // 仅对 PMEM(bresp 恒 OK)解耦；MMIO/可错 store 仍等 B 以保精确异常(MEM-I3)。详见
  // design/specs/ooo-mem-axi-bridge-fsm.md 与 design/arch/mem-store-decouple.md。
  reg bpend_q;

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

  function pte_reserved_fault;
    input [`XLEN-1:0] pte;
    input svpbmt_en;
    begin
      pte_reserved_fault =
          ((pte & (svpbmt_en ? `SV39_PTE_RESERVED_MASK_SVPBMT :
                                `SV39_PTE_RESERVED_MASK)) !=
           {`XLEN{1'b0}}) ||
          (!pte_leaf(pte) &&
           (((pte & `SV39_PTE_NONLEAF_RESERVED_MASK) != {`XLEN{1'b0}}) ||
            (svpbmt_en &&
             (pte[`SV39_PTE_PBMT_HI:`SV39_PTE_PBMT_LO] != 2'b00)))) ||
          (pte_leaf(pte) && svpbmt_en &&
           (pte[`SV39_PTE_PBMT_HI:`SV39_PTE_PBMT_LO] == 2'b11));
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
      // 权限判断拆成纯组合 helper，保持 MXR/SUM/U 与 Sv39 A/D 位语义。
      data_permission_fault =
          (write_access ? !pte[2] : !data_read_ok(pte, status)) ||
          !data_user_ok(pte, priv_mode, status) ||
          !pte[6] || (write_access && !pte[7]);
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

  function [3:0] access_size_from_wstrb;
    input [`STRB_W-1:0] wstrb;
    integer byte_idx;
    begin
      access_size_from_wstrb = 4'd0;
      for (byte_idx = 0; byte_idx < `STRB_W; byte_idx = byte_idx + 1) begin
        if (wstrb[byte_idx])
          access_size_from_wstrb = access_size_from_wstrb + 4'd1;
      end
      if (access_size_from_wstrb == 4'd0)
        access_size_from_wstrb = 4'd1;
    end
  endfunction

  wire [1:0] req_priv_w = effective_data_priv(priv_mode_i, mstatus_i);
  wire req_translate_w = sv39_enabled(req_priv_w, satp_i);
  wire mem0_req_fire_w = mem0_req_valid_i && mem0_req_ready_o;
  wire aw_fire_w = lsu_axi_awvalid_o && lsu_axi_awready_i;
  wire w_fire_w = lsu_axi_wvalid_o && lsu_axi_wready_i;
  // mem1(双发射 load 第二端口)死硅删除后,单 outstanding 桥只服务 mem0:
  // 响应就绪/请求选择都直取 mem0,active_port 归属随之消失。
  wire rsp_ready_w = mem0_rsp_ready_i;
  wire cpu_kill_w = flush_i || drop_rsp_q;
  wire req_slot_ready_w = !cpu_kill_w &&
                          ((state_q == S_IDLE) ||
                           ((state_q == S_RESP) && rsp_ready_w));
  wire req_write_w = mem0_req_write_i;
  wire [`XLEN-1:0] req_addr_w = mem0_req_addr_i;
  wire [`XLEN-1:0] req_wdata_w = mem0_req_wdata_i;
  wire [`STRB_W-1:0] req_wstrb_w = mem0_req_wstrb_i;
  wire [3:0] req_access_size_w = access_size_from_wstrb(req_wstrb_w);
  wire [3:0] active_access_size_w = access_size_from_wstrb(wstrb_q);
  wire req_dtlb_context_hit_w;
  wire [`XLEN-1:0] req_dtlb_pte_w;
  wire [1:0] req_dtlb_level_unused_w;
  wire [`XLEN-1:0] req_translated_paddr_w;
  wire req_dtlb_perm_fault_w =
      req_dtlb_context_hit_w &&
      (pte_reserved_fault(req_dtlb_pte_w, svpbmt_en_i) ||
       data_permission_fault(req_dtlb_pte_w, req_write_w, req_priv_w,
                             mstatus_i));
  wire req_dtlb_hit_w = req_dtlb_context_hit_w && !req_dtlb_perm_fault_w;
  wire [`XLEN-1:0] req_cache_addr_w =
      req_dtlb_hit_w ? req_translated_paddr_w : req_addr_w;
  wire req_pmp_fault_raw_w;
  wire req_data_pmp_fault_w =
      (!req_translate_w || req_dtlb_hit_w) && req_pmp_fault_raw_w;
  wire req_dcacheable_unused_w;
  wire req_dcache_hit_raw_w;
  wire [`XLEN-1:0] req_dcache_data_w;
  wire req_dcache_hit_w =
      (!req_translate_w || req_dtlb_hit_w) && req_dcache_hit_raw_w;
  wire req_read_miss_fire_w =
      mem0_req_fire_w && !req_write_w &&
      (!req_translate_w || req_dtlb_hit_w) && !req_data_pmp_fault_w &&
      !req_dcache_hit_w;
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, addr_q, walk_level_q);
  wire [`XLEN-1:0] walk_leaf_paddr_w =
      leaf_paddr(lsu_axi_rdata_i, addr_q, walk_level_q);
  wire walk_leaf_pmp_fault_w;
  wire walk_leaf_dcacheable_unused_w;
  wire walk_leaf_dcache_hit_w;
  wire [`XLEN-1:0] walk_leaf_dcache_data_w;
  wire write_paddr_virtio_blk_w =
      ((paddr_q & `NPC_AXI_VIRTIO_BLK_MASK) == `NPC_AXI_VIRTIO_BLK_BASE);
  wire dtlb_fill_valid_w =
      (state_q == S_WALK_R) && lsu_axi_rvalid_i &&
      (lsu_axi_rresp_i == 2'b00) &&
      !pte_invalid(lsu_axi_rdata_i) &&
      !pte_reserved_fault(lsu_axi_rdata_i, access_svpbmt_en_q) &&
      pte_leaf(lsu_axi_rdata_i) &&
      !superpage_misaligned(lsu_axi_rdata_i, walk_level_q) &&
      !data_permission_fault(lsu_axi_rdata_i, write_q, access_priv_q,
                             mstatus_i);
  wire dcache_read_fill_valid_w =
      !cpu_kill_w && (state_q == S_READ_DATA) && lsu_axi_rvalid_i &&
      (lsu_axi_rresp_i == 2'b00);
  // 解耦 store 在数据落 PMEM 当拍(S_WRITE_REQ 两 beat 完成且走解耦)就必须更新/失效 dcache，
  // 否则跳过 S_WRITE_RESP 会漏掉 dcache 维护、令同地址后续 load 命中旧值(MEM-I2 破坏)。
  wire store_decouple_commit_w =
      (state_q == S_WRITE_REQ) &&
      ((aw_done_q || aw_fire_w) && (w_done_q || w_fire_w)) &&
      store_decouple_w;
  wire dcache_store_commit_w =
      ((state_q == S_WRITE_RESP) && lsu_axi_bvalid_i &&
       (lsu_axi_bresp_i == 2'b00)) ||
      store_decouple_commit_w;

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

  PmpChecker u_req_pmp_checker (
    .paddr_i(req_cache_addr_w),
    .access_size_i(req_access_size_w),
    .priv_mode_i(req_priv_w),
    .access_read_i(!req_write_w),
    .access_write_i(req_write_w),
    .access_exec_i(1'b0),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(req_pmp_fault_raw_w)
  );

  PmpChecker u_walk_leaf_pmp_checker (
    .paddr_i(walk_leaf_paddr_w),
    .access_size_i(active_access_size_w),
    .priv_mode_i(access_priv_q),
    .access_read_i(!write_q),
    .access_write_i(write_q),
    .access_exec_i(1'b0),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_leaf_pmp_fault_w)
  );

  // F9：priv-spec 要求 PMP 适用于地址翻译期间对页表的隐式访问。旧实现只检查最终数据 PA
  // (req/leaf)，每级 PTE 读地址（walk_pte_addr_w）绕过了 PMP——OS 把页表放入对 S 态拒绝
  // 的 PMP 区时硬件仍能读出 PTE，绕过 M 态隔离。这里对 PTE 读地址补 PMP 检查（8B 读，
  // 用被翻译访问的特权级 access_priv_q，与 leaf 检查器一致）。
  wire walk_pte_pmp_fault_w;
  PmpChecker u_walk_pte_pmp_checker (
    .paddr_i(walk_pte_addr_w),
    .access_size_i(4'd8),
    .priv_mode_i(access_priv_q),
    .access_read_i(1'b1),
    .access_write_i(1'b0),
    .access_exec_i(1'b0),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_pte_pmp_fault_w)
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
    // LSQ Phase 1：去掉核弹式全失效（原恒 1），改由 dcache 按 store 真实字节区间对
    // {store_idx-1,idx,+1} 三邻域精确失效/合并（byte-window 模型下等价保持 store→load 可见性）。
    .store_invalidate_all_i(1'b0),
    .store_addr_i(paddr_q),
    .store_data_i(wdata_q),
    .store_wstrb_i(wstrb_q)
  );

  assign mem0_req_ready_o = req_slot_ready_w;

  assign mem0_rsp_valid_o =
      (state_q == S_RESP) && !cpu_kill_w;
  assign mem0_rsp_rdata_o = rsp_rdata_q;
  assign mem0_rsp_error_o = rsp_error_q;
  assign mem0_rsp_page_fault_o = rsp_page_fault_q;

  assign lsu_axi_arvalid_o =
      !cpu_kill_w &&
      (((state_q == S_WALK_AR) && !walk_pte_pmp_fault_w) ||
       (state_q == S_READ_ADDR) ||
       req_read_miss_fire_w);
  assign lsu_axi_araddr_o =
      (state_q == S_WALK_AR) ? walk_pte_addr_w :
      req_read_miss_fire_w ? req_cache_addr_w : paddr_q;
  assign lsu_axi_arstrb_o =
      (state_q == S_WALK_AR) ? {`STRB_W{1'b1}} :
      req_read_miss_fire_w ? req_wstrb_w : wstrb_q;
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
  // 解耦 store 的 B 由跟踪器吸收：bpend_q 期间持续拉 bready。
  assign lsu_axi_bready_o = (state_q == S_WRITE_RESP) || bpend_q;
  // 仅 PMEM store 可提前完成(bresp 恒 OK)；!bpend_q 保证至多一个未收 B。
  wire store_decouple_w =
      ((paddr_q & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE) && !bpend_q;

  task automatic accept_request;
    begin
      write_q <= req_write_w;
      paging_q <= req_translate_w;
      access_priv_q <= req_priv_w;
      access_svpbmt_en_q <= svpbmt_en_i;
      addr_q <= req_addr_w;
      paddr_q <= req_cache_addr_w;
      wdata_q <= req_wdata_w;
      wstrb_q <= req_wstrb_w;
      rsp_rdata_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
      rsp_page_fault_q <= 1'b0;
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
      if (req_data_pmp_fault_w) begin
        rsp_error_q <= 1'b1;
        rsp_page_fault_q <= 1'b0;
        state_q <= S_RESP;
      end else if (req_translate_w && req_dtlb_perm_fault_w) begin
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
      write_q <= 1'b0;
      paging_q <= 1'b0;
      access_priv_q <= `PRIV_M;
      access_svpbmt_en_q <= 1'b0;
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
      bpend_q <= 1'b0;
    end else begin
      // B-drain 跟踪器(状态无关，flush 期间也照常吸收已解耦 store 的 B)
      if (bpend_q && lsu_axi_bvalid_i) begin
        bpend_q <= 1'b0;
      end
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
            accept_request();
          end
        end

        S_WALK_AR: begin
          // F9：PTE 读地址 PMP 违例 → access fault（非 page fault），不发 AR、不读 PTE。
          if (walk_pte_pmp_fault_w) begin
            rsp_error_q <= 1'b1;
            rsp_page_fault_q <= 1'b0;
            state_q <= S_RESP;
          end else if (lsu_axi_arready_i) begin
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
                         pte_reserved_fault(lsu_axi_rdata_i,
                                            access_svpbmt_en_q) ||
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
              end else if (walk_leaf_pmp_fault_w) begin
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b0;
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
            if (store_decouple_w) begin
              // PMEM store：数据已落 PMEM(MEM-I2)，bresp 恒 OK；提前报完成，B 交跟踪器。
              rsp_rdata_q <= {`XLEN{1'b0}};
              rsp_error_q <= 1'b0;
              rsp_page_fault_q <= 1'b0;
              bpend_q <= 1'b1;
              state_q <= S_RESP;
            end else begin
              // MMIO/uncacheable：仍等 B 以保精确总线异常。
              state_q <= S_WRITE_RESP;
            end
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
              accept_request();
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
