`include "define.v"

module OooFetchAxiBridge (
  input clk,
  input rst,
  input mmu_flush_i,

  input invalidate_valid_i,
  input [`XLEN-1:0] invalidate_addr_i,

  input [1:0] priv_mode_i,
  input [`XLEN-1:0] satp_i,
  input svpbmt_en_i,
  input [`PMP_CFG_BUS_W-1:0] pmpcfg_i,
  input [`PMP_ADDR_BUS_W-1:0] pmpaddr_i,

  input fetch_req_valid_i,
  output fetch_req_ready_o,
  input [`XLEN-1:0] fetch_req_pc_i,
  output [`XLEN-1:0] fetch_req_owner_pc_o,
  output fetch_rsp_valid_o,
  input fetch_rsp_ready_i,
  output [`INST_W-1:0] fetch_rsp_inst0_o,
  output [1:0] fetch_rsp_resp0_o,
  output [`INST_W-1:0] fetch_rsp_inst1_o,
  output [1:0] fetch_rsp_resp1_o,
  // resp0 负责 packet 低地址起的成功 prefix。完整成功/缓存包恒为 4；首个失败
  // halfword 在 F 时为 F（允许 0）。decoder 以 split 和真实 RVC 长度归一到 slot resp。
  output [2:0] fetch_rsp_resp0_bytes_o,

  output ifu_axi_arvalid_o,
  input ifu_axi_arready_i,
  output [`XLEN-1:0] ifu_axi_araddr_o,
  output [3:0] ifu_axi_arid_o,
  output [7:0] ifu_axi_arlen_o,
  output [2:0] ifu_axi_arsize_o,
  output [1:0] ifu_axi_arburst_o,
  output [2:0] ifu_axi_arprot_o,
  input ifu_axi_rvalid_i,
  output ifu_axi_rready_o,
  input [`XLEN-1:0] ifu_axi_rdata_i,
  input [1:0] ifu_axi_rresp_i,

  // HW-managed A 更新写通道（Svadu，对齐 NEMU）：取指到 A=0 的可执行页时，
  // 不再 page fault，改经 S_AD_UPDATE 写回 PTE 置 A 位。取指只置 A（不置 D）。
  output ifu_axi_awvalid_o,
  input ifu_axi_awready_i,
  output [`XLEN-1:0] ifu_axi_awaddr_o,
  output [3:0] ifu_axi_awid_o,
  output [7:0] ifu_axi_awlen_o,
  output [2:0] ifu_axi_awsize_o,
  output [1:0] ifu_axi_awburst_o,
  output ifu_axi_wvalid_o,
  input ifu_axi_wready_i,
  output [`XLEN-1:0] ifu_axi_wdata_o,
  output [`STRB_W-1:0] ifu_axi_wstrb_o,
  output ifu_axi_wlast_o,
  input ifu_axi_bvalid_i,
  output ifu_axi_bready_o,
  input [1:0] ifu_axi_bresp_i
);

  // 单 beat AXI4 元数据。read SIZE/PROT 由当前 owner 决定：PTE walk 是
  // data+8B，instruction footprint 是 exec+2B；write 仅用于对齐 8B PTE A 更新。
  assign ifu_axi_arid_o = 4'd0;
  assign ifu_axi_arlen_o = 8'd0;
  assign ifu_axi_arburst_o = 2'b01;
  assign ifu_axi_awid_o = 4'd0;
  assign ifu_axi_awlen_o = 8'd0;
  assign ifu_axi_awsize_o = 3'd3;
  assign ifu_axi_awburst_o = 2'b01;
  assign ifu_axi_wlast_o = 1'b1;

  localparam [3:0] S_IDLE = 4'd0;
  localparam [3:0] S_WALK_AR = 4'd1;
  localparam [3:0] S_WALK_R = 4'd2;
  localparam [3:0] S_AR0 = 4'd3;
  localparam [3:0] S_R0 = 4'd4;
  localparam [3:0] S_AR1 = 4'd5;
  localparam [3:0] S_R1 = 4'd6;
  localparam [3:0] S_RESP = 4'd7;
  localparam [3:0] S_AD_UPDATE = 4'd8;  // HW A 更新: 写回 leaf PTE 置 A 位, 再 re-walk 续原取指
  localparam [3:0] S_LOOKUP = 4'd9;     // cache 判决拍；只把结果落入 registered response
  // 【AXI4 化 S1】mmu_flush 命中在飞 AXI 读(AR 已 fire、R 未归)时的自吞排水态:
  // rready 保持拉高吞掉 R 后才回 IDLE; 期间 fetch_req_ready=0(防新请求与残 R 串包)。
  // 取代旧"xbar abort 边带吞 R"机制——master 自吞使互连成为纯标准 AXI4。
  localparam [3:0] S_DRAIN = 4'd10;
  localparam [3:0] S_CACHE_READ = 4'd11; // 已锁存请求驱动 SRAM 同步读的发射拍
  localparam [3:0] S_WALK_CHECK = 4'd12; // 本地寄存 PTE 地址与 PMP 判决，再发 AXI AR
  // mmu_flush 不能撤回已经呈现且被反压的 AXI AR。两种 owner 分态保留原
  // payload 真源，不新增宽地址寄存器；AR fire 后统一进 S_DRAIN 吞 R。
  localparam [3:0] S_WALK_AR_DROP = 4'd13;
  localparam [3:0] S_FETCH_AR_DROP = 4'd14;
  localparam [`XLEN-1:0] PTE_A_BIT = {{(`XLEN-7){1'b0}}, 7'h40};  // bit 6 (Accessed)
  localparam [1:0] RESP_OK = 2'b00;
  localparam [1:0] RESP_ACCESS_FAULT = 2'b01;
  localparam [1:0] RESP_PAGE_FAULT = 2'b10;
  localparam ITLB_INDEX_W = 6;

  reg [3:0] state_q;
  // T4A fixed-role immutable-context pipeline.  Candidate registers sample
  // raw live inputs every cycle with no valid/ready/fire/state/flush gate.
  // The one-cycle S_CACHE_READ boundary then copies that exact request into a
  // transaction-stable execution context.  This physically removes T3Z's
  // high-fanout active-bank selector from every PMP/AXI/xbar cone.
  reg fetch_ctx_candidate_paging_q;
  reg [1:0] fetch_ctx_candidate_priv_q;
  reg [`XLEN-1:0] fetch_ctx_candidate_satp_q;
  reg fetch_ctx_candidate_svpbmt_en_q;
  reg [`XLEN-1:0] fetch_ctx_candidate_pc_q;
  reg fetch_ctx_exec_paging_q;
  reg [1:0] fetch_ctx_exec_priv_q;
  reg [`XLEN-1:0] fetch_ctx_exec_satp_q;
  reg fetch_ctx_exec_svpbmt_en_q;
  reg [`XLEN-1:0] fetch_ctx_exec_pc_q;

  // Preserve the historical XMR/debug aliases as the architectural owner
  // view only.  Immediately after request fire S_CACHE_READ observes the new
  // candidate; at its closing edge exec captures the same value, so the owner
  // handoff is value-stable.  Internal transaction datapaths do not use these
  // aliases: lookup uses candidate explicitly and all later work uses exec.
  wire fetch_ctx_owner_candidate_w = (state_q == S_CACHE_READ);
  wire paging_q = fetch_ctx_owner_candidate_w ?
      fetch_ctx_candidate_paging_q : fetch_ctx_exec_paging_q;
  wire [1:0] req_priv_q = fetch_ctx_owner_candidate_w ?
      fetch_ctx_candidate_priv_q : fetch_ctx_exec_priv_q;
  wire [`XLEN-1:0] req_satp_q = fetch_ctx_owner_candidate_w ?
      fetch_ctx_candidate_satp_q : fetch_ctx_exec_satp_q;
  wire req_svpbmt_en_q = fetch_ctx_owner_candidate_w ?
      fetch_ctx_candidate_svpbmt_en_q : fetch_ctx_exec_svpbmt_en_q;
  wire [`XLEN-1:0] pc_q = fetch_ctx_owner_candidate_w ?
      fetch_ctx_candidate_pc_q : fetch_ctx_exec_pc_q;
  reg walk_second_q;
  reg [1:0] walk_level_q;
  reg [43:0] walk_ppn_q;
  reg [`XLEN-1:0] walk_pte_addr_q;
  reg walk_pte_pmp_fault_q;
  // T3W: S_CACHE_READ captures the ITLB result at the same edge that the
  // synchronous packet-cache lookup is launched.  S_LOOKUP therefore runs
  // PMP from this registered translation instead of serializing
  // exec PC -> ITLB -> PMP -> response payload D in one cycle.
  reg lookup_itlb_hit_q;
  reg lookup_itlb_perm_fault_q;
  reg [`XLEN-1:0] lookup_exec_paddr_q;
  reg [`XLEN-1:0] paddr0_q;
  reg [`XLEN-1:0] paddr1_q;
  reg packet_cross_page_q;
  reg second_page_ready_q;
  reg [2:0] fetch_offset_q;
  reg [`XLEN-1:0] fetch_data_q;
  reg [`INST_W-1:0] inst0_q;
  reg [`INST_W-1:0] inst1_q;
  reg [1:0] resp0_q;
  reg [1:0] resp1_q;
  reg [2:0] resp0_bytes_q;
  reg [`XLEN-1:0] debug_last_pte_addr_q;
  reg [`XLEN-1:0] debug_last_pte_q;
  reg [1:0] debug_last_pte_level_q;
  reg debug_last_pte_second_q;
  reg [`XLEN-1:0] ad_pte_q;   // HW A: 置 A 位后的 leaf PTE(供 S_AD_UPDATE 写通道)
  reg aw_done_q;              // S_AD_UPDATE 的 AW 已握手(吸收 awready/wready 偏斜)
  reg w_done_q;               // S_AD_UPDATE 的 W 已握手
  // mmu_flush 只作废旧取指语义，不能撤回已经呈现的 AXI write。该位 sticky 到 B completion，
  // 让同一 S_AD_UPDATE 状态继续补齐 AW/W 并消费 B，完成后直接丢弃而非 re-walk/报旧 fault。
  reg ad_drop_q;

  wire ifu_axi_walk_ar_owner_w =
      (state_q == S_WALK_AR) || (state_q == S_WALK_AR_DROP);
  assign ifu_axi_arsize_o = ifu_axi_walk_ar_owner_w ? 3'd3 : 3'd1;
  assign ifu_axi_arprot_o = ifu_axi_walk_ar_owner_w ? 3'b000 : 3'b100;

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
    input [1:0] level;
    begin
      pte_reserved_fault =
          (pte_leaf(pte) ?
           (((pte & ((svpbmt_en ? `SV39_PTE_RESERVED_MASK_SVPBMT :
                                  `SV39_PTE_RESERVED_MASK) &
                                 ~`SV39_PTE_N)) != {`XLEN{1'b0}}) ||
            (((pte & `SV39_PTE_N) != {`XLEN{1'b0}}) &&
             ((level != 2'd0) || (pte[13:10] != 4'b1000)))) :
           (((pte & (svpbmt_en ? `SV39_PTE_RESERVED_MASK_SVPBMT :
                                  `SV39_PTE_RESERVED_MASK)) !=
             {`XLEN{1'b0}}) ||
            ((pte & `SV39_PTE_NONLEAF_RESERVED_MASK) != {`XLEN{1'b0}}) ||
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

  // HW-managed A（Svadu，对齐 NEMU）：A 缺失不再算权限 fault，改由 S_AD_UPDATE 写回置位。
  // 真权限（X、U/S）仍在此判。
  function exec_permission_fault;
    input [`XLEN-1:0] pte;
    input [1:0] priv_mode;
    begin
      exec_permission_fault =
          !pte[3] ||
          ((priv_mode == `PRIV_U) ? !pte[4] : pte[4]);
    end
  endfunction

  // 取指到真权限全通过但 A=0 的 leaf → 触发 HW A 更新（写 PTE|A 后 re-walk），非 fault。
  function exec_ad_update_needed;
    input [`XLEN-1:0] pte;
    begin
      exec_ad_update_needed = !pte[6];
    end
  endfunction

  function [`XLEN-1:0] leaf_paddr;
    input [`XLEN-1:0] pte;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      // Svnapot 64KiB leaf: PTE.PPN[3:0] 是 NAPOT 编码(1000)，真实 PA
      // 低 4 个 PPN bit 必须来自 VA[15:12]，否则会写到 64KiB 窗口中间。
      leaf_paddr = {8'b0,
                    (level == 2'd2) ?
                    {pte[53:28], vaddr[29:21], vaddr[20:12]} :
                    (level == 2'd1) ?
                    {pte[53:28], pte[27:19], vaddr[20:12]} :
                    (((pte & `SV39_PTE_N) != {`XLEN{1'b0}}) ?
                     {pte[53:14], vaddr[15:12]} :
                     pte[53:10]),
                    vaddr[11:0]};
    end
  endfunction

  function [`XLEN-1:0] insert_fetch_halfword;
    input [`XLEN-1:0] packet;
    input [2:0] byte_offset;
    input [15:0] halfword;
    begin
      insert_fetch_halfword = packet;
      case (byte_offset)
        3'd0: insert_fetch_halfword[15:0] = halfword;
        3'd2: insert_fetch_halfword[31:16] = halfword;
        3'd4: insert_fetch_halfword[47:32] = halfword;
        3'd6: insert_fetch_halfword[63:48] = halfword;
        default: insert_fetch_halfword = packet;
      endcase
    end
  endfunction

  wire req_paging_w = sv39_enabled(priv_mode_i, satp_i);
  wire cache_hit_raw_w;
  // 声明前置，iverilog 14 拒绝前向引用（下方 cache_hit_w 提前引用这三个信号）
  wire req_itlb_hit_w;
  wire req_exec_pmp_fault_w;
  wire req_exec1_pmp_fault_w;
  // Fast hit 只接受两个固定 4B checker 都放行的保守充分条件。任何固定窗口拒绝
  // 都只降级到下方 exact-halfword slow path，不能直接成为架构 fault。PMP checker
  // 永远运行；S/U + 全零 pmpcfg 的 default-deny 不能再借 cache 绕过。
  wire cache_hit_w = cache_hit_raw_w &&
      !req_exec_pmp_fault_w && !req_exec1_pmp_fault_w &&
      (!fetch_ctx_exec_paging_q || lookup_itlb_hit_q);
  // T3R 后 response 不再组合穿透 cache payload，no-snoop hit 仅保留模块端口
  // 兼容性，bridge 只消费含完整 invalidate 窗口的 cache_hit_raw_w。
  wire fetch_cache_no_snoop_unused_w;
  wire fetch_cache_context_unused_w;
  wire [`INST_W-1:0] cache_inst0_w;
  wire [`INST_W-1:0] cache_inst1_w;
  wire [1:0] cache_resp0_w;
  wire [1:0] cache_resp1_w;
  wire req_itlb_context_hit_w;
  wire [`XLEN-1:0] req_itlb_pte_w;
  wire [1:0] req_itlb_level_w;
  wire [`XLEN-1:0] req_itlb_paddr_w;
  // S_CACHE_READ 的 ITLB lookup/permission 只读 candidate；拍尾将结果与
  // candidate→exec 交接同时寄存。S_LOOKUP 后不得再读 candidate。
  // pmpcfg/pmpaddr 仍取当拍输入(CSR 写经串行化, 无在飞取指请求交叠)。
  wire req_itlb_perm_fault_w =
      req_itlb_context_hit_w &&
      (pte_reserved_fault(req_itlb_pte_w,
                          fetch_ctx_candidate_svpbmt_en_q,
                          req_itlb_level_w) ||
       exec_permission_fault(req_itlb_pte_w,
                             fetch_ctx_candidate_priv_q));
  assign req_itlb_hit_w = req_itlb_context_hit_w && !req_itlb_perm_fault_w;
  wire [`XLEN-1:0] req_exec_paddr_w =
      (fetch_ctx_candidate_paging_q && req_itlb_hit_w) ?
      req_itlb_paddr_w : fetch_ctx_candidate_pc_q;
  wire [`XLEN-1:0] req_exec1_paddr_w = lookup_exec_paddr_q + 64'd4;
  wire req_exec_pmp_fault_raw_w;
  wire req_exec1_pmp_fault_raw_w;
  assign req_exec_pmp_fault_w =
      (!fetch_ctx_exec_paging_q || lookup_itlb_hit_q) &&
      req_exec_pmp_fault_raw_w;
  assign req_exec1_pmp_fault_w =
      (!fetch_ctx_exec_paging_q || lookup_itlb_hit_q) &&
      req_exec1_pmp_fault_raw_w;
  wire fetch_req_fire_w = fetch_req_valid_i && fetch_req_ready_o;
  wire fetch_rsp_fire_w = fetch_rsp_valid_o && fetch_rsp_ready_i;
  wire [`XLEN-1:0] pc_second_page_vaddr_w =
      {fetch_ctx_exec_pc_q[`XLEN-1:12], 12'b0} + 64'd4096;
  wire [`XLEN-1:0] walk_vaddr_w =
      walk_second_q ? pc_second_page_vaddr_w : fetch_ctx_exec_pc_q;
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, walk_vaddr_w, walk_level_q);

  // Miss path：每拍只处理一个已注册的 2B frontier。RDATA 仅决定下一拍 offset；
  // 不允许 RDATA→length→ARVALID/ARADDR 的同拍组合链。
  wire [`XLEN-1:0] fetch_current_vaddr_w =
      fetch_ctx_exec_pc_q + {{(`XLEN-3){1'b0}}, fetch_offset_q};
  wire fetch_current_on_second_w =
      fetch_current_vaddr_w[`XLEN-1:12] !=
      fetch_ctx_exec_pc_q[`XLEN-1:12];
  wire [`XLEN-1:0] fetch_current_paddr_w = !fetch_ctx_exec_paging_q ?
      fetch_current_vaddr_w :
      fetch_current_on_second_w ?
          (paddr1_q + {{(`XLEN-12){1'b0}}, fetch_current_vaddr_w[11:0]}) :
          (paddr0_q + {{(`XLEN-3){1'b0}}, fetch_offset_q});
  wire [5:0] fetch_r_lane_shift_w = {fetch_current_paddr_w[2:0], 3'b000};
  wire [`XLEN-1:0] fetch_r_low_window_w =
      ifu_axi_rdata_i >> fetch_r_lane_shift_w;
  wire [15:0] fetch_r_halfword_w = fetch_r_low_window_w[15:0];
  wire [`XLEN-1:0] fetch_data_after_r_w =
      insert_fetch_halfword(fetch_data_q, fetch_offset_q, fetch_r_halfword_w);

  reg fetch_more_after_r_r;
  reg [2:0] fetch_next_offset_r;
  always @(*) begin
    fetch_more_after_r_r = 1'b0;
    fetch_next_offset_r = fetch_offset_q;
    case (fetch_offset_q)
      3'd0: begin
        fetch_more_after_r_r = 1'b1;
        fetch_next_offset_r = 3'd2;
      end
      3'd2: begin
        // L0=C 时当前 halfword 是 L1 prefix；否则是 L0 tail。
        fetch_more_after_r_r =
            (fetch_data_after_r_w[1:0] == 2'b11) ||
            (fetch_data_after_r_w[17:16] == 2'b11);
        fetch_next_offset_r = 3'd4;
      end
      3'd4: begin
        // L0=C 时当前是 L1 tail，必完成；L0=32 时当前是 L1 prefix。
        fetch_more_after_r_r =
            (fetch_data_after_r_w[1:0] == 2'b11) &&
            (fetch_data_after_r_w[33:32] == 2'b11);
        fetch_next_offset_r = 3'd6;
      end
      default: begin
        fetch_more_after_r_r = 1'b0;
        fetch_next_offset_r = fetch_offset_q;
      end
    endcase
  end
  wire fetch_more_after_r_w = fetch_more_after_r_r;
  wire [2:0] fetch_next_offset_w = fetch_next_offset_r;
  wire [`XLEN-1:0] fetch_next_vaddr_w =
      fetch_ctx_exec_pc_q + {{(`XLEN-3){1'b0}}, fetch_next_offset_w};
  wire fetch_next_cross_page_w =
      fetch_next_vaddr_w[`XLEN-1:12] != fetch_ctx_exec_pc_q[`XLEN-1:12];
  wire itlb_fill_valid_w =
      !mmu_flush_i && (state_q == S_WALK_R) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !pte_invalid(ifu_axi_rdata_i) &&
      !pte_reserved_fault(ifu_axi_rdata_i,
                          fetch_ctx_exec_svpbmt_en_q,
                          walk_level_q) &&
      (pte_leaf(ifu_axi_rdata_i)) &&
      !superpage_misaligned(ifu_axi_rdata_i, walk_level_q) &&
      !exec_permission_fault(ifu_axi_rdata_i,
                             fetch_ctx_exec_priv_q) &&
      // HW A: 首遍读到 A=0 的 PTE 不填 TLB(否则缓存 A=0 项); 待 S_AD_UPDATE 写完 re-walk
      // 读回 A=1 的 PTE 再填。TLB 因此永不缓存 A=0, TLB 命中路径无需 A 门控。
      !exec_ad_update_needed(ifu_axi_rdata_i);
  wire fetch_cache_fill_complete_w =
      (state_q == S_R0) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !fetch_more_after_r_w && !packet_cross_page_q;
  // 只缓存 exact 成功 footprint；未取 tail 在 fetch_data_q reset 后保持确定性 0。
  // 跨页包仍不缓存，避免 fast checker 的 paddr0+4 误代第二物理页。
  wire fetch_cache_fill_valid_w = fetch_cache_fill_complete_w;
  wire [`INST_W-1:0] fetch_cache_fill_inst0_w =
      fetch_data_after_r_w[`INST_W-1:0];
  wire [`INST_W-1:0] fetch_cache_fill_inst1_w =
      fetch_data_after_r_w[`XLEN-1:`INST_W];
  wire [1:0] fetch_cache_fill_resp0_w = RESP_OK;
  wire [1:0] fetch_cache_fill_resp1_w = RESP_OK;

  // T3R 请求非穿透边界：外部 fire 只锁存完整请求上下文。下一拍
  // S_CACHE_READ 才用 q 驱动同步 SRAM，同拍发射 cache 语义 lookup。这使
  // frontend ready/control 锥只到请求寄存器 D 端，不再直达 SRAM addr/en 与 lkp_inv。
  wire fetch_cache_read_window_w = (state_q == S_CACHE_READ);
  wire fetch_cache_lookup_issue_w = (state_q == S_CACHE_READ);
  OooFetchPacketCache u_fetch_packet_cache (
    .clk(clk),
    .rst(rst),
    .clear_i(mmu_flush_i),
    .lookup_read_en_i(fetch_cache_read_window_w),
    .lookup_en_i(fetch_cache_lookup_issue_w),
    .lookup_paging_i(fetch_ctx_candidate_paging_q),
    .lookup_priv_i(fetch_ctx_candidate_priv_q),
    .lookup_satp_i(fetch_ctx_candidate_satp_q),
    .lookup_pc_i(fetch_ctx_candidate_pc_q),
    .lookup_context_hit_o(fetch_cache_context_unused_w),
    .lookup_hit_o(cache_hit_raw_w),
    .lookup_hit_no_snoop_o(fetch_cache_no_snoop_unused_w),
    .lookup_inst0_o(cache_inst0_w),
    .lookup_resp0_o(cache_resp0_w),
    .lookup_inst1_o(cache_inst1_w),
    .lookup_resp1_o(cache_resp1_w),
    .fill_valid_i(fetch_cache_fill_valid_w),
    .fill_paging_i(fetch_ctx_exec_paging_q),
    .fill_priv_i(fetch_ctx_exec_priv_q),
    .fill_satp_i(fetch_ctx_exec_satp_q),
    .fill_pc_i(fetch_ctx_exec_pc_q),
    .fill_inst0_i(fetch_cache_fill_inst0_w),
    .fill_resp0_i(fetch_cache_fill_resp0_w),
    .fill_inst1_i(fetch_cache_fill_inst1_w),
    .fill_resp1_i(fetch_cache_fill_resp1_w),
    .invalidate_valid_i(invalidate_valid_i),
    .invalidate_addr_i(invalidate_addr_i)
  );

  // ITLB lookup 输入使用 fire 拍锁存值；结果在 S_CACHE_READ 末端打拍，
  // 与取指包 cache SRAM rdata_o 一起在 S_LOOKUP 对齐。ITLB 本体仍是 FF
  // 组合读，但不再与完整 PMP 树串在同一条 response payload 路径上。
  OooSv39Tlb #(
    .INDEX_W(ITLB_INDEX_W)
  ) u_itlb (
    .clk(clk),
    .rst(rst),
    .clear_i(mmu_flush_i),
    .lookup_valid_i(fetch_ctx_candidate_paging_q),
    .lookup_vaddr_i(fetch_ctx_candidate_pc_q),
    .lookup_satp_i(fetch_ctx_candidate_satp_q),
    .lookup_context_hit_o(req_itlb_context_hit_w),
    .lookup_pte_o(req_itlb_pte_w),
    .lookup_level_o(req_itlb_level_w),
    .lookup_paddr_o(req_itlb_paddr_w),
    .fill_valid_i(itlb_fill_valid_w),
    .fill_vaddr_i(walk_vaddr_w),
    .fill_satp_i(fetch_ctx_exec_satp_q),
    .fill_pte_i(ifu_axi_rdata_i),
    .fill_level_i(walk_level_q)
  );

  PmpChecker u_req_exec_pmp_checker (
    .paddr_i(lookup_exec_paddr_q),
    .access_size_i(4'd4),
    .priv_mode_i(fetch_ctx_exec_priv_q),
    .access_read_i(1'b0),
    .access_write_i(1'b0),
    .access_exec_i(1'b1),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(req_exec_pmp_fault_raw_w)
  );

  PmpChecker u_req_exec1_pmp_checker (
    .paddr_i(req_exec1_paddr_w),
    .access_size_i(4'd4),
    .priv_mode_i(fetch_ctx_exec_priv_q),
    .access_read_i(1'b0),
    .access_write_i(1'b0),
    .access_exec_i(1'b1),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(req_exec1_pmp_fault_raw_w)
  );

  // 架构 fault owner：AR 前按完全相同的 PA/2B 检查。固定 4B checker 只服务
  // cache fast gate，绝不复用为 slow-path fault 判决。
  wire fetch_current_pmp_fault_w;
  PmpChecker u_fetch_current_pmp_checker (
    .paddr_i(fetch_current_paddr_w),
    .access_size_i(4'd2),
    .priv_mode_i(fetch_ctx_exec_priv_q),
    .access_read_i(1'b0),
    .access_write_i(1'b0),
    .access_exec_i(1'b1),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(fetch_current_pmp_fault_w)
  );

  // Leaf PTE 的 A=0 更新是可见 memory side effect；必须先用当前 frontier 的
  // exact PA/2B 完成 EXEC PMP 判决，再允许写 A。S_AR0 会在真正发数据 AR 前复检。
  wire [`XLEN-1:0] walk_leaf_current_paddr_w =
      leaf_paddr(ifu_axi_rdata_i, fetch_current_vaddr_w, walk_level_q);
  wire walk_leaf_current_pmp_fault_w;
  PmpChecker u_walk_leaf_current_pmp_checker (
    .paddr_i(walk_leaf_current_paddr_w),
    .access_size_i(4'd2),
    .priv_mode_i(fetch_ctx_exec_priv_q),
    .access_read_i(1'b0),
    .access_write_i(1'b0),
    .access_exec_i(1'b1),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_leaf_current_pmp_fault_w)
  );

  // F9：取指页表 walk 的各级 PTE 读地址也必须受 PMP（priv-spec 隐式页表访问）。PTE 读是
  // 隐式数据读（非取指），故按 read/8B/S-mode 检查。旧实现各级
  // PTE 读地址绕过 PMP，OS 把页表放入对 S 态拒绝的 PMP 区时硬件仍能读出 PTE。
  wire walk_pte_pmp_fault_w;
  PmpChecker u_walk_pte_pmp_checker (
    .paddr_i(walk_pte_addr_w),
    .access_size_i(4'd8),
    .priv_mode_i(`PRIV_S),
    .access_read_i(1'b1),
    .access_write_i(1'b0),
    .access_exec_i(1'b0),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_pte_pmp_fault_w)
  );

  // T4F / PTW-PMP-G1：A-bit 回写是独立的隐式 8B store。用 registered
  // PTE address 做 S-mode WRITE 判定；deny 留在 leaf R 决策锥，不进入
  // S_AD_UPDATE，也不会把 PMP 树串进 AWVALID/WVALID owner。
  wire walk_pte_write_pmp_fault_w;
  PmpChecker u_walk_pte_write_pmp_checker (
    .paddr_i(walk_pte_addr_q),
    .access_size_i(4'd8),
    .priv_mode_i(`PRIV_S),
    .access_read_i(1'b0),
    .access_write_i(1'b1),
    .access_exec_i(1'b0),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_pte_write_pmp_fault_w)
  );

  wire walk_ad_write_deny_w =
      (state_q == S_WALK_R) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !pte_invalid(ifu_axi_rdata_i) &&
      !pte_reserved_fault(ifu_axi_rdata_i,
                          fetch_ctx_exec_svpbmt_en_q,
                          walk_level_q) &&
      pte_leaf(ifu_axi_rdata_i) &&
      !superpage_misaligned(ifu_axi_rdata_i, walk_level_q) &&
      !exec_permission_fault(ifu_axi_rdata_i, fetch_ctx_exec_priv_q) &&
      !walk_leaf_current_pmp_fault_w &&
      exec_ad_update_needed(ifu_axi_rdata_i) &&
      walk_pte_write_pmp_fault_w;

  // packet cache 使用 PC+satp/priv 做上下文 tag；ITLB 命中只缓存翻译，不绕过取指权限。
  // T3R 响应非穿透边界：S_LOOKUP 只能把 cache hit/fault 结果落入 q，
  // 对外 valid/payload 只由 S_RESP/q 驱动。S_RESP 消费旧响应同拍仍可锁存下一
  // 个完整请求，但新请求要到下拍 S_CACHE_READ 才能触及 SRAM。
  // 【mmu_flush 打拍配套】flush 拍不受理新请求: 复位分支会吞掉同拍 fire 的请求
  // (sequencer 记账悬空→挂死), flush 拍压 ready 使请求次拍重发。
  assign fetch_req_ready_o = !mmu_flush_i &&
                             ((state_q == S_IDLE) ||
                              ((state_q == S_RESP) && fetch_rsp_ready_i));
  assign fetch_req_owner_pc_o = pc_q;
  assign fetch_rsp_valid_o = (state_q == S_RESP);
  assign fetch_rsp_inst0_o = inst0_q;
  assign fetch_rsp_inst1_o = inst1_q;
  assign fetch_rsp_resp0_o = resp0_q;
  assign fetch_rsp_resp1_o = resp1_q;
  // successful-prefix/fault-suffix ABI：hit/完整成功恒 split=4；fault 的 split=首个
  // 失败 halfword offset F（允许 F=0）。decoder 以真实长度决定 fault 属于哪一槽。
  assign fetch_rsp_resp0_bytes_o = resp0_bytes_q;

  // AXI VALID-until-fire：普通 AR owner 由 registered state + authorization
  // 驱动；若 mmu_flush 命中已呈现请求，FSM 转对应 DROP owner，继续保持
  // valid/payload 到 fire，再由 S_DRAIN 自吞 R。flush 只能取消尚未呈现
  // ARVALID 的 PMP-fault/前置计算状态，不能组合门控一个现存 owner。
  assign ifu_axi_arvalid_o =
      (((state_q == S_WALK_AR) && !walk_pte_pmp_fault_q) ||
       ((state_q == S_AR0) && !fetch_current_pmp_fault_w) ||
       (state_q == S_WALK_AR_DROP) ||
       (state_q == S_FETCH_AR_DROP));
  assign ifu_axi_araddr_o =
      ifu_axi_walk_ar_owner_w ? walk_pte_addr_q : fetch_current_paddr_w;
  assign ifu_axi_rready_o =
      (state_q == S_WALK_R) || (state_q == S_R0) ||
      (state_q == S_DRAIN);
  // 【AXI4 化 S1】在飞 AXI 读判定(等 R 态=AR 已 fire): flush 拍若 R 未同拍到达,
  // 转 S_DRAIN 吞 R; R 同拍 fire 则本拍即消费完, 直接回 IDLE。
  wire ifu_axi_read_inflight_w =
      (state_q == S_WALK_R) || (state_q == S_R0) ||
      (state_q == S_DRAIN);
  wire ifu_axi_r_fire_w = ifu_axi_rvalid_i && ifu_axi_rready_o;

  // HW A 更新写通道：awaddr = registered 本级 leaf PTE 地址，wdata = 置 A 位的 PTE，
  // wstrb 全 8B。AW/W 可独立
  // 握手；valid 一经呈现到 fire 前不可撤回。mmu_flush 只置 ad_drop_q，仍补齐 channel 并收 B。
  assign ifu_axi_awvalid_o = (state_q == S_AD_UPDATE) && !aw_done_q;
  assign ifu_axi_awaddr_o = walk_pte_addr_q;
  assign ifu_axi_wvalid_o = (state_q == S_AD_UPDATE) && !w_done_q;
  assign ifu_axi_wdata_o = ad_pte_q;
  assign ifu_axi_wstrb_o = {`STRB_W{1'b1}};
  assign ifu_axi_bready_o = (state_q == S_AD_UPDATE);
  wire ifu_ad_aw_fire_w = ifu_axi_awvalid_o && ifu_axi_awready_i;
  wire ifu_ad_w_fire_w = ifu_axi_wvalid_o && ifu_axi_wready_i;
  wire ifu_ad_aw_accepted_next_w = aw_done_q || ifu_ad_aw_fire_w;
  wire ifu_ad_w_accepted_next_w = w_done_q || ifu_ad_w_fire_w;
  wire ifu_ad_b_fire_w = ifu_axi_bvalid_i && ifu_axi_bready_o;
  wire ifu_ad_write_complete_w = ifu_ad_aw_accepted_next_w &&
                                 ifu_ad_w_accepted_next_w && ifu_ad_b_fire_w;

  // Fixed-role context pipeline is deliberately outside the main FSM/flush
  // priority tree.  Candidate always samples raw live inputs.  Exec captures
  // the previous candidate only while the registered state is S_CACHE_READ;
  // NBA semantics make this the exact request sampled on the preceding fire.
  // A flush on that edge may update invalid exec payload, but never enters a
  // wide D gate; S_AD_UPDATE is a different state and therefore holds exec.
  always @(posedge clk) begin
    if (rst) begin
      fetch_ctx_candidate_paging_q <= 1'b0;
      fetch_ctx_candidate_priv_q <= `PRIV_M;
      fetch_ctx_candidate_satp_q <= {`XLEN{1'b0}};
      fetch_ctx_candidate_svpbmt_en_q <= 1'b0;
      fetch_ctx_candidate_pc_q <= {`XLEN{1'b0}};
      fetch_ctx_exec_paging_q <= 1'b0;
      fetch_ctx_exec_priv_q <= `PRIV_M;
      fetch_ctx_exec_satp_q <= {`XLEN{1'b0}};
      fetch_ctx_exec_svpbmt_en_q <= 1'b0;
      fetch_ctx_exec_pc_q <= {`XLEN{1'b0}};
    end else begin
      fetch_ctx_candidate_paging_q <= req_paging_w;
      fetch_ctx_candidate_priv_q <= priv_mode_i;
      fetch_ctx_candidate_satp_q <= satp_i;
      fetch_ctx_candidate_svpbmt_en_q <= svpbmt_en_i;
      fetch_ctx_candidate_pc_q <= fetch_req_pc_i;
      if (state_q == S_CACHE_READ) begin
        fetch_ctx_exec_paging_q <= fetch_ctx_candidate_paging_q;
        fetch_ctx_exec_priv_q <= fetch_ctx_candidate_priv_q;
        fetch_ctx_exec_satp_q <= fetch_ctx_candidate_satp_q;
        fetch_ctx_exec_svpbmt_en_q <= fetch_ctx_candidate_svpbmt_en_q;
        fetch_ctx_exec_pc_q <= fetch_ctx_candidate_pc_q;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      // rst 代表 bridge+xbar/slave 共同复位，允许清除全部事务 owner。
      state_q <= S_IDLE;
      walk_second_q <= 1'b0;
      walk_level_q <= 2'd0;
      walk_ppn_q <= 44'd0;
      walk_pte_addr_q <= {`XLEN{1'b0}};
      walk_pte_pmp_fault_q <= 1'b0;
      lookup_itlb_hit_q <= 1'b0;
      lookup_itlb_perm_fault_q <= 1'b0;
      lookup_exec_paddr_q <= {`XLEN{1'b0}};
      paddr0_q <= {`XLEN{1'b0}};
      paddr1_q <= {`XLEN{1'b0}};
      packet_cross_page_q <= 1'b0;
      second_page_ready_q <= 1'b0;
      fetch_offset_q <= 3'd0;
      fetch_data_q <= {`XLEN{1'b0}};
      inst0_q <= {`INST_W{1'b0}};
      inst1_q <= {`INST_W{1'b0}};
      resp0_q <= RESP_OK;
      resp1_q <= RESP_OK;
      resp0_bytes_q <= 3'd4;
      debug_last_pte_addr_q <= {`XLEN{1'b0}};
      debug_last_pte_q <= {`XLEN{1'b0}};
      debug_last_pte_level_q <= 2'd0;
      debug_last_pte_second_q <= 1'b0;
      ad_pte_q <= {`XLEN{1'b0}};
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
      ad_drop_q <= 1'b0;
    end else if (mmu_flush_i && (state_q != S_AD_UPDATE)) begin
      // mmu_flush 不是 AXI reset。已呈现的 ARVALID 必须先保持到 fire：
      // 普通 owner 在反压时切入同 payload 的 DROP owner；ready 同拍则本拍
      // 已完成 AR，直接等待并吞掉 R。该分支刻意不清 payload 真源。
      if (ifu_axi_arvalid_o) begin
        if (ifu_axi_arready_i) begin
          state_q <= S_DRAIN;
        end else if (state_q == S_WALK_AR) begin
          state_q <= S_WALK_AR_DROP;
        end else if (state_q == S_AR0) begin
          state_q <= S_FETCH_AR_DROP;
        end
        // 已在 DROP owner 且继续反压时，state/payload 隐式保持。
      end else begin
        // 未呈现 AR 的语义可以取消；已 fire 的读必须走 S_DRAIN 自吞。
        // S_AD_UPDATE 落到下方 case，并行记录当拍 AW/W/B fire。
        state_q <= (ifu_axi_read_inflight_w && !ifu_axi_r_fire_w) ?
                   S_DRAIN : S_IDLE;
        walk_second_q <= 1'b0;
        walk_level_q <= 2'd0;
        walk_ppn_q <= 44'd0;
        lookup_itlb_hit_q <= 1'b0;
        lookup_itlb_perm_fault_q <= 1'b0;
        lookup_exec_paddr_q <= {`XLEN{1'b0}};
        paddr0_q <= {`XLEN{1'b0}};
        paddr1_q <= {`XLEN{1'b0}};
        packet_cross_page_q <= 1'b0;
        second_page_ready_q <= 1'b0;
        fetch_offset_q <= 3'd0;
        fetch_data_q <= {`XLEN{1'b0}};
        inst0_q <= {`INST_W{1'b0}};
        inst1_q <= {`INST_W{1'b0}};
        resp0_q <= RESP_OK;
        resp1_q <= RESP_OK;
        resp0_bytes_q <= 3'd4;
        debug_last_pte_addr_q <= {`XLEN{1'b0}};
        debug_last_pte_q <= {`XLEN{1'b0}};
        debug_last_pte_level_q <= 2'd0;
        debug_last_pte_second_q <= 1'b0;
        ad_pte_q <= {`XLEN{1'b0}};
        aw_done_q <= 1'b0;
        w_done_q <= 1'b0;
        ad_drop_q <= 1'b0;
      end
    end else begin
      case (state_q)
        S_IDLE: begin
          // 外部 fire 只锁存不可重建的请求上下文；派生 scratch 由下拍
          // S_CACHE_READ 的本地 state owner 初始化，避免 frontend ready/control
          // 锥穿过接收拍的宽寄存器 D mux。物理 SRAM 读仍在该拍发射。
          if (fetch_req_fire_w) begin
            state_q <= S_CACHE_READ;
          end
        end

        S_CACHE_READ: begin
          // 读地址、paging/priv/satp 均来自上拍锁存 q。SRAM 与 cache
          // 判决上下文在本拍同时发射；ITLB translation/permission 与 SRAM
          // read 在本边界一起打拍，次拍 S_LOOKUP 只串 registered PA -> PMP。
          // 与 lookup 不相关的派生 scratch 也只由这个 registered state 初始化：
          // cache/ITLB 本拍只读 pc/context，故这些值在 S_LOOKUP 前落稳即可。
          paddr0_q <= fetch_ctx_candidate_pc_q;
          paddr1_q <= {`XLEN{1'b0}};
          packet_cross_page_q <= 1'b0;
          walk_second_q <= 1'b0;
          second_page_ready_q <= 1'b0;
          fetch_offset_q <= 3'd0;
          fetch_data_q <= {`XLEN{1'b0}};
          inst0_q <= {`INST_W{1'b0}};
          inst1_q <= {`INST_W{1'b0}};
          resp0_q <= RESP_OK;
          resp1_q <= RESP_OK;
          resp0_bytes_q <= 3'd4;
          lookup_itlb_hit_q <= req_itlb_hit_w;
          lookup_itlb_perm_fault_q <= req_itlb_perm_fault_w;
          lookup_exec_paddr_q <= req_exec_paddr_w;
          state_q <= S_LOOKUP;
        end

        S_LOOKUP: begin
          // 判决拍: cache_hit_raw_w=SRAM 同步读结果, ITLB/PMP 复检用 accept 拍锁存值。
          // hit 只落入 response q 并进 S_RESP，不允许 cache payload/ready 在本拍
          // 组合交付或融合新请求。miss 进入 registered CHECK→AR→R。
          if (cache_hit_w) begin
            inst0_q <= cache_inst0_w;
            inst1_q <= cache_inst1_w;
            resp0_q <= cache_resp0_w;
            resp1_q <= cache_resp1_w;
            resp0_bytes_q <= 3'd4;
            state_q <= S_RESP;
          end else if (fetch_ctx_exec_paging_q &&
                       lookup_itlb_perm_fault_q) begin
            resp0_q <= RESP_OK;
            resp1_q <= RESP_PAGE_FAULT;
            resp0_bytes_q <= 3'd0;
            state_q <= S_RESP;
          end else if (fetch_ctx_exec_paging_q && lookup_itlb_hit_q) begin
            paddr0_q <= lookup_exec_paddr_q;
            state_q <= S_AR0;
          end else if (fetch_ctx_exec_paging_q) begin
            if (canonical_sv39(fetch_ctx_exec_pc_q)) begin
              walk_second_q <= 1'b0;
              walk_level_q <= 2'd2;
              walk_ppn_q <= fetch_ctx_exec_satp_q[43:0];
              state_q <= S_WALK_CHECK;
            end else begin
              resp0_q <= RESP_OK;
              resp1_q <= RESP_PAGE_FAULT;
              resp0_bytes_q <= 3'd0;
              state_q <= S_RESP;
            end
          end else begin
            state_q <= S_AR0;
          end
        end

        S_WALK_CHECK: begin
          // T4A PTW authorization boundary: compute PTE address and its 8B
          // implicit-data PMP result locally, then register both.  The next
          // S_WALK_AR cycle drives AXI only from these q values, so exec
          // context/PMP can no longer cross xbar into another master's state.
          walk_pte_addr_q <= walk_pte_addr_w;
          walk_pte_pmp_fault_q <= walk_pte_pmp_fault_w;
          state_q <= S_WALK_AR;
        end

        S_WALK_AR: begin
          // 无论第几页，失败 owner 都是当前 registered halfword frontier；
          // 此前成功 prefix 保留，年轻访问停止。
          if (walk_pte_pmp_fault_q) begin
            inst0_q <= fetch_data_q[`INST_W-1:0];
            inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
            resp0_q <= RESP_OK;
            resp1_q <= RESP_ACCESS_FAULT;
            resp0_bytes_q <= fetch_offset_q;
            state_q <= S_RESP;
          end else if (ifu_axi_arready_i) begin
            state_q <= S_WALK_R;
          end
        end

        S_WALK_R: begin
          if (ifu_axi_rvalid_i) begin
            debug_last_pte_addr_q <= walk_pte_addr_q;
            debug_last_pte_q <= ifu_axi_rdata_i;
            debug_last_pte_level_q <= walk_level_q;
            debug_last_pte_second_q <= walk_second_q;
            if (ifu_axi_rresp_i != RESP_OK) begin
              inst0_q <= fetch_data_q[`INST_W-1:0];
              inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
              resp0_q <= RESP_OK;
              resp1_q <= RESP_ACCESS_FAULT;
              resp0_bytes_q <= fetch_offset_q;
              state_q <= S_RESP;
            end else if (pte_invalid(ifu_axi_rdata_i) ||
                         pte_reserved_fault(ifu_axi_rdata_i,
                                            fetch_ctx_exec_svpbmt_en_q,
                                            walk_level_q) ||
                         (!pte_leaf(ifu_axi_rdata_i) &&
                          (walk_level_q == 2'd0))) begin
              inst0_q <= fetch_data_q[`INST_W-1:0];
              inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
              resp0_q <= RESP_OK;
              resp1_q <= RESP_PAGE_FAULT;
              resp0_bytes_q <= fetch_offset_q;
              state_q <= S_RESP;
            end else if (pte_leaf(ifu_axi_rdata_i)) begin
              if (superpage_misaligned(ifu_axi_rdata_i, walk_level_q) ||
                  exec_permission_fault(ifu_axi_rdata_i,
                                        fetch_ctx_exec_priv_q)) begin
                inst0_q <= fetch_data_q[`INST_W-1:0];
                inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
                resp0_q <= RESP_OK;
                resp1_q <= RESP_PAGE_FAULT;
                resp0_bytes_q <= fetch_offset_q;
                state_q <= S_RESP;
              end else if (walk_leaf_current_pmp_fault_w) begin
                inst0_q <= fetch_data_q[`INST_W-1:0];
                inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
                resp0_q <= RESP_OK;
                resp1_q <= RESP_ACCESS_FAULT;
                resp0_bytes_q <= fetch_offset_q;
                state_q <= S_RESP;
              // HW A: 真权限+PMP 全过但 A=0 → 写回 PTE|A 后 re-walk 本级(读回 A=1 续原取指)。
              // walk_ppn_q/walk_level_q 与 registered PTE address 保持不变。
              // 置 A 后真 fault 已排除, 故不会与 fault 竞争(fault 分支在前, 优先)。
              end else if (exec_ad_update_needed(ifu_axi_rdata_i) &&
                           walk_pte_write_pmp_fault_w) begin
                // PTE 可读但不可写：按原取指类型返回 instruction access fault。
                inst0_q <= fetch_data_q[`INST_W-1:0];
                inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
                resp0_q <= RESP_OK;
                resp1_q <= RESP_ACCESS_FAULT;
                resp0_bytes_q <= fetch_offset_q;
                state_q <= S_RESP;
              end else if (exec_ad_update_needed(ifu_axi_rdata_i)) begin
                ad_pte_q <= ifu_axi_rdata_i | PTE_A_BIT;
                aw_done_q <= 1'b0;
                w_done_q <= 1'b0;
                ad_drop_q <= 1'b0;
                state_q <= S_AD_UPDATE;
              end else begin
                if (walk_second_q) begin
                  paddr1_q <= leaf_paddr(ifu_axi_rdata_i,
                                         pc_second_page_vaddr_w,
                                         walk_level_q);
                  second_page_ready_q <= 1'b1;
                  state_q <= S_AR0;
                end else begin
                  paddr0_q <= leaf_paddr(ifu_axi_rdata_i,
                                         fetch_ctx_exec_pc_q,
                                         walk_level_q);
                  state_q <= S_AR0;
                end
              end
            end else begin
              walk_ppn_q <= ifu_axi_rdata_i[53:10];
              walk_level_q <= walk_level_q - 2'd1;
              state_q <= S_WALK_CHECK;
            end
          end
        end

        S_AR0: begin
          // CHECK→AR：PMP fault suppresses ARVALID and closes at this frontier。
          if (fetch_current_pmp_fault_w) begin
            inst0_q <= fetch_data_q[`INST_W-1:0];
            inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
            resp0_q <= RESP_OK;
            resp1_q <= RESP_ACCESS_FAULT;
            resp0_bytes_q <= fetch_offset_q;
            state_q <= S_RESP;
          end else if (ifu_axi_arready_i) begin
            state_q <= S_R0;
          end
        end

        S_WALK_AR_DROP, S_FETCH_AR_DROP: begin
          // 已被 flush 作废、但此前已呈现并被反压的 AR owner。payload 真源在
          // 进入本态时冻结；重复 flush 也不能撤 valid。AR fire 后才有 R，
          // 因而先转 S_DRAIN，再由该态拉高 RREADY 吞回包。
          if (ifu_axi_arready_i) begin
            state_q <= S_DRAIN;
          end
        end

        S_R0: begin
          if (ifu_axi_rvalid_i) begin
            if (ifu_axi_rresp_i != RESP_OK) begin
              inst0_q <= fetch_data_q[`INST_W-1:0];
              inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
              resp0_q <= RESP_OK;
              resp1_q <= RESP_ACCESS_FAULT;
              resp0_bytes_q <= fetch_offset_q;
              state_q <= S_RESP;
            end else begin
              fetch_data_q <= fetch_data_after_r_w;
              if (fetch_more_after_r_w) begin
                fetch_offset_q <= fetch_next_offset_w;
                if (fetch_next_cross_page_w) begin
                  packet_cross_page_q <= 1'b1;
                  if (fetch_ctx_exec_paging_q &&
                      !second_page_ready_q) begin
                    if (canonical_sv39(pc_second_page_vaddr_w)) begin
                      walk_second_q <= 1'b1;
                      walk_level_q <= 2'd2;
                      walk_ppn_q <= fetch_ctx_exec_satp_q[43:0];
                      state_q <= S_WALK_CHECK;
                    end else begin
                      inst0_q <= fetch_data_after_r_w[`INST_W-1:0];
                      inst1_q <= fetch_data_after_r_w[`XLEN-1:`INST_W];
                      resp0_q <= RESP_OK;
                      resp1_q <= RESP_PAGE_FAULT;
                      resp0_bytes_q <= fetch_next_offset_w;
                      state_q <= S_RESP;
                    end
                  end else begin
                    state_q <= S_AR0;
                  end
                end else begin
                  state_q <= S_AR0;
                end
              end else begin
                inst0_q <= fetch_data_after_r_w[`INST_W-1:0];
                inst1_q <= fetch_data_after_r_w[`XLEN-1:`INST_W];
                resp0_q <= RESP_OK;
                resp1_q <= RESP_OK;
                resp0_bytes_q <= 3'd4;
                state_q <= S_RESP;
              end
            end
          end
        end

        S_AR1, S_R1: begin
          // legacy state encodings retained for debug compatibility; exact fetch never enters them.
          state_q <= S_IDLE;
        end

        S_AD_UPDATE: begin
          // 写回 PTE|A: 完成 AW/W + 吸收 B 后 re-walk 本级(walk_ppn_q/walk_level_q 未改,
          // 重读同一 leaf PTE 此时 A=1 → exec_ad_update_needed=0 → 走正常 leaf-OK 续流)。
          // mmu_flush 只 sticky-drop 旧 fetch 语义；已呈现 AXI write 仍补齐 AW/W 并消费 B。
          // 除全局 rst 外，先承认同拍 channel fire，再由 effective_drop 选择 completion 后继。
          if (mmu_flush_i) ad_drop_q <= 1'b1;
          if (ifu_ad_aw_fire_w) aw_done_q <= 1'b1;
          if (ifu_ad_w_fire_w) w_done_q <= 1'b1;
          if (ifu_ad_write_complete_w) begin
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            ad_drop_q <= 1'b0;
            if (ad_drop_q || mmu_flush_i) begin
              // 已作废请求只关闭总线 owner；BRESP 不再属于任何架构可见 fetch。
              state_q <= S_IDLE;
            end else if (ifu_axi_bresp_i == RESP_OK) begin
              state_q <= S_WALK_CHECK;
            end else begin
              // A 写失败(极罕见: PTE 落不可写区) → 取指 access fault, 避免 A=0 无限重试。
              inst0_q <= fetch_data_q[`INST_W-1:0];
              inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
              resp0_q <= RESP_OK;
              resp1_q <= RESP_ACCESS_FAULT;
              resp0_bytes_q <= fetch_offset_q;
              state_q <= S_RESP;
            end
          end
        end

        S_RESP: begin
          // 消费旧响应同拍可 replacement-accept 下一完整请求；本拍仍不读
          // SRAM，新 owner 下拍进 S_CACHE_READ；这里只锁住不可重建的请求上下文，
          // 派生 scratch 由 S_CACHE_READ 初始化，downstream ready 不会穿透宽 D mux。
          if (fetch_rsp_fire_w) begin
            if (fetch_req_fire_w) begin
              state_q <= S_CACHE_READ;
            end else begin
              state_q <= S_IDLE;
            end
          end
        end

        S_DRAIN: begin
          // 【AXI4 化 S1】吞掉被 flush 作废的在飞 R(单 beat), 吞完回 IDLE。
          // 本态 fetch_req_ready=0/arvalid=0/rsp_valid=0, 仅 rready=1。
          if (ifu_axi_rvalid_i) begin
            state_q <= S_IDLE;
          end
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
    end
  end

`ifdef OOO_ASSERT
  reg assert_pte_write_deny_r;
  always @(posedge clk) begin
    if (rst) begin
      assert_pte_write_deny_r <= 1'b0;
    end else begin
      if (walk_ad_write_deny_w &&
          (ifu_axi_awvalid_o || ifu_axi_wvalid_o))
        $error("[IFU-PTW-PMP-WRITE] denied PTE write exposed AW/W");
      if (assert_pte_write_deny_r &&
          ((state_q != S_RESP) || (resp0_q != RESP_OK) ||
           (resp1_q != RESP_ACCESS_FAULT)))
        $error("[IFU-PTW-PMP-WRITE] deny did not become access-fault response");
      assert_pte_write_deny_r <= !mmu_flush_i && walk_ad_write_deny_w;
    end
  end

  // IFU-AXI-G1 外部协议 shadow：只从端口 valid/fire 建 owner，不复用 aw_done/w_done/ad_drop，
  // 避免实现与断言共享同一错误状态。综合时 OOO_ASSERT 关闭，不进入 PPA。
  reg ar_assert_stall_q;
  reg [`XLEN-1:0] ar_assert_addr_q;
  reg [3:0] ar_assert_id_q;
  reg [7:0] ar_assert_len_q;
  reg [2:0] ar_assert_size_q;
  reg [1:0] ar_assert_burst_q;
  reg [2:0] ar_assert_prot_q;
  reg ar_assert_drop_fire_q;
  reg ad_assert_open_q;
  reg ad_assert_aw_seen_q;
  reg ad_assert_w_seen_q;
  reg ad_assert_drop_q;
  reg ad_assert_expect_idle_q;
  reg ad_assert_aw_stall_q;
  reg [`XLEN-1:0] ad_assert_awaddr_q;
  reg [3:0] ad_assert_awid_q;
  reg [7:0] ad_assert_awlen_q;
  reg [2:0] ad_assert_awsize_q;
  reg [1:0] ad_assert_awburst_q;
  reg ad_assert_w_stall_q;
  reg [`XLEN-1:0] ad_assert_wdata_q;
  reg [`STRB_W-1:0] ad_assert_wstrb_q;
  reg ad_assert_wlast_q;
  wire ad_assert_aw_fire_w = ifu_axi_awvalid_o && ifu_axi_awready_i;
  wire ad_assert_w_fire_w = ifu_axi_wvalid_o && ifu_axi_wready_i;
  wire ad_assert_b_fire_w = ifu_axi_bvalid_i && ifu_axi_bready_o;
  // 断言 completion 只消费 shadow seen + 原始端口 fire，刻意不复用生产
  // aw_done_q/w_done_q/ifu_ad_write_complete_w，避免 completion 编码与 checker 同盲。
  wire ad_assert_complete_w =
      (ad_assert_aw_seen_q || ad_assert_aw_fire_w) &&
      (ad_assert_w_seen_q || ad_assert_w_fire_w) && ad_assert_b_fire_w;

  always @(posedge clk) begin
    if (rst) begin
      ar_assert_stall_q <= 1'b0;
      ar_assert_addr_q <= {`XLEN{1'b0}};
      ar_assert_id_q <= 4'd0;
      ar_assert_len_q <= 8'd0;
      ar_assert_size_q <= 3'd0;
      ar_assert_burst_q <= 2'd0;
      ar_assert_prot_q <= 3'd0;
      ar_assert_drop_fire_q <= 1'b0;
      ad_assert_open_q <= 1'b0;
      ad_assert_aw_seen_q <= 1'b0;
      ad_assert_w_seen_q <= 1'b0;
      ad_assert_drop_q <= 1'b0;
      ad_assert_expect_idle_q <= 1'b0;
      ad_assert_aw_stall_q <= 1'b0;
      ad_assert_awaddr_q <= {`XLEN{1'b0}};
      ad_assert_awid_q <= 4'd0;
      ad_assert_awlen_q <= 8'd0;
      ad_assert_awsize_q <= 3'd0;
      ad_assert_awburst_q <= 2'd0;
      ad_assert_w_stall_q <= 1'b0;
      ad_assert_wdata_q <= {`XLEN{1'b0}};
      ad_assert_wstrb_q <= {`STRB_W{1'b0}};
      ad_assert_wlast_q <= 1'b0;
    end else begin
      // Pure port-level AXI read shadow.  No flush exemption is legal once
      // ARVALID has been observed under backpressure.
      if (ar_assert_stall_q &&
          ((ifu_axi_arvalid_o !== 1'b1) ||
           (ifu_axi_araddr_o !== ar_assert_addr_q) ||
           (ifu_axi_arid_o !== ar_assert_id_q) ||
           (ifu_axi_arlen_o !== ar_assert_len_q) ||
           (ifu_axi_arsize_o !== ar_assert_size_q) ||
           (ifu_axi_arburst_o !== ar_assert_burst_q) ||
           (ifu_axi_arprot_o !== ar_assert_prot_q)))
        $error("[IFU-AR-HOLD] stalled AR valid/payload changed before fire");
      // IFU is already a standard-lane master and therefore intentionally
      // bypasses the LSU logical-window adapter: instruction beats are
      // naturally aligned 2B transfers; PTW beats are aligned 8B transfers.
      if (ifu_axi_arvalid_o && ifu_axi_arprot_o[2] &&
          ((ifu_axi_arsize_o !== 3'd1) || ifu_axi_araddr_o[0])) begin
        $error("[IFU-AXI-LANE] instruction AR is not a natural 2B beat");
        $fatal;
      end
      if (ifu_axi_arvalid_o && !ifu_axi_arprot_o[2] &&
          ((ifu_axi_arsize_o !== 3'd3) || (|ifu_axi_araddr_o[2:0]))) begin
        $error("[IFU-AXI-LANE] PTW AR is not an aligned 8B beat");
        $fatal;
      end
      if (ifu_axi_awvalid_o &&
          ((ifu_axi_awsize_o !== 3'd3) || (|ifu_axi_awaddr_o[2:0]))) begin
        $error("[IFU-AXI-LANE] PTE AW is not an aligned 8B beat");
        $fatal;
      end
      if (ifu_axi_wvalid_o && (ifu_axi_wstrb_o !== {`STRB_W{1'b1}})) begin
        $error("[IFU-AXI-LANE] PTE WSTRB is not full-width");
        $fatal;
      end
      if (((state_q == S_WALK_AR_DROP) ||
           (state_q == S_FETCH_AR_DROP)) &&
          ((ifu_axi_arvalid_o !== 1'b1) || fetch_req_ready_o ||
           fetch_rsp_valid_o || ifu_axi_rready_o || ifu_axi_awvalid_o ||
           ifu_axi_wvalid_o || ifu_axi_bready_o ||
           fetch_cache_fill_valid_w || itlb_fill_valid_w))
        $error("[IFU-AR-DROP-OWNER] dropped AR owner emitted unrelated protocol activity");
      if (ar_assert_drop_fire_q && (state_q != S_DRAIN))
        $error("[IFU-AR-DROP-DRAIN] dropped AR fire did not enter R drain");

      ar_assert_stall_q <= ifu_axi_arvalid_o && !ifu_axi_arready_i;
      if (ifu_axi_arvalid_o && !ifu_axi_arready_i) begin
        ar_assert_addr_q <= ifu_axi_araddr_o;
        ar_assert_id_q <= ifu_axi_arid_o;
        ar_assert_len_q <= ifu_axi_arlen_o;
        ar_assert_size_q <= ifu_axi_arsize_o;
        ar_assert_burst_q <= ifu_axi_arburst_o;
        ar_assert_prot_q <= ifu_axi_arprot_o;
      end
      ar_assert_drop_fire_q <=
          ((state_q == S_WALK_AR_DROP) ||
           (state_q == S_FETCH_AR_DROP)) &&
          ifu_axi_arvalid_o && ifu_axi_arready_i;

      if (ad_assert_aw_stall_q &&
          ((ifu_axi_awvalid_o !== 1'b1) ||
           (ifu_axi_awaddr_o !== ad_assert_awaddr_q) ||
           (ifu_axi_awid_o !== ad_assert_awid_q) ||
           (ifu_axi_awlen_o !== ad_assert_awlen_q) ||
           (ifu_axi_awsize_o !== ad_assert_awsize_q) ||
           (ifu_axi_awburst_o !== ad_assert_awburst_q)))
        $error("[IFU-AD-AW-HOLD] stalled AW valid/payload changed before fire");
      if (ad_assert_w_stall_q &&
          ((ifu_axi_wvalid_o !== 1'b1) ||
           (ifu_axi_wdata_o !== ad_assert_wdata_q) ||
           (ifu_axi_wstrb_o !== ad_assert_wstrb_q) ||
           (ifu_axi_wlast_o !== ad_assert_wlast_q)))
        $error("[IFU-AD-W-HOLD] stalled W valid/payload changed before fire");
      if (ad_assert_open_q && (state_q != S_AD_UPDATE))
        $error("[IFU-AD-OWNER-LIVE] write owner left S_AD_UPDATE before complete B");
      if (ad_assert_open_q && !ad_assert_aw_seen_q &&
          (ifu_axi_awvalid_o !== 1'b1))
        $error("[IFU-AD-OWNER-LIVE] pending AW was withdrawn before fire");
      if (ad_assert_open_q && !ad_assert_w_seen_q &&
          (ifu_axi_wvalid_o !== 1'b1))
        $error("[IFU-AD-OWNER-LIVE] pending W was withdrawn before fire");
      if (ad_assert_open_q && ad_assert_aw_seen_q &&
          (ifu_axi_awvalid_o === 1'b1))
        $error("[IFU-AD-OWNER-LIVE] accepted AW was re-issued");
      if (ad_assert_open_q && ad_assert_w_seen_q &&
          (ifu_axi_wvalid_o === 1'b1))
        $error("[IFU-AD-OWNER-LIVE] accepted W was re-issued");
      if (ad_assert_open_q && (ifu_axi_bready_o !== 1'b1))
        $error("[IFU-AD-BREADY-HOLD] write owner withdrew BREADY before completion");
      if (ad_assert_b_fire_w &&
          !(ad_assert_aw_seen_q || ad_assert_aw_fire_w))
        $error("[IFU-AD-B-ORDER] B fired before AW was accepted");
      if (ad_assert_b_fire_w &&
          !(ad_assert_w_seen_q || ad_assert_w_fire_w))
        $error("[IFU-AD-B-ORDER] B fired before W was accepted");
      if (ad_assert_drop_q &&
          (fetch_req_ready_o || fetch_rsp_valid_o || ifu_axi_arvalid_o))
        $error("[IFU-AD-DROP-QUIET] dropped write emitted fetch/response/read activity");
      if (ad_assert_expect_idle_q && (state_q != S_IDLE))
        $error("[IFU-AD-DROP-COMPLETE] dropped write did not retire to IDLE after B");

      ad_assert_expect_idle_q <= 1'b0;
      if (!ad_assert_open_q && (ifu_axi_awvalid_o || ifu_axi_wvalid_o)) begin
        ad_assert_open_q <= 1'b1;
        ad_assert_aw_seen_q <= ad_assert_aw_fire_w;
        ad_assert_w_seen_q <= ad_assert_w_fire_w;
        ad_assert_drop_q <= mmu_flush_i;
      end else if (ad_assert_open_q) begin
        if (ad_assert_aw_fire_w) ad_assert_aw_seen_q <= 1'b1;
        if (ad_assert_w_fire_w) ad_assert_w_seen_q <= 1'b1;
        if (mmu_flush_i) ad_assert_drop_q <= 1'b1;
      end

      if (ad_assert_complete_w) begin
        ad_assert_open_q <= 1'b0;
        ad_assert_aw_seen_q <= 1'b0;
        ad_assert_w_seen_q <= 1'b0;
        ad_assert_drop_q <= 1'b0;
        ad_assert_expect_idle_q <= ad_assert_drop_q || mmu_flush_i;
      end

      ad_assert_aw_stall_q <= ifu_axi_awvalid_o && !ifu_axi_awready_i;
      if (ifu_axi_awvalid_o && !ifu_axi_awready_i) begin
        ad_assert_awaddr_q <= ifu_axi_awaddr_o;
        ad_assert_awid_q <= ifu_axi_awid_o;
        ad_assert_awlen_q <= ifu_axi_awlen_o;
        ad_assert_awsize_q <= ifu_axi_awsize_o;
        ad_assert_awburst_q <= ifu_axi_awburst_o;
      end
      ad_assert_w_stall_q <= ifu_axi_wvalid_o && !ifu_axi_wready_i;
      if (ifu_axi_wvalid_o && !ifu_axi_wready_i) begin
        ad_assert_wdata_q <= ifu_axi_wdata_o;
        ad_assert_wstrb_q <= ifu_axi_wstrb_o;
        ad_assert_wlast_q <= ifu_axi_wlast_o;
      end
    end
  end

  // T3R 双侧非穿透合同 shadow。断言只观察外部 fire、FSM 和寄存器，
  // 不复用 cache hit 生产逻辑，避免 checker 与实现共享盲区。
  reg t3r_assert_prev_valid_q;
  reg [3:0] t3r_assert_prev_state_q;
  reg t3r_assert_capture_q;
  reg [`XLEN-1:0] t3r_assert_pc_q;
  reg t3r_assert_paging_q;
  reg [1:0] t3r_assert_priv_q;
  reg [`XLEN-1:0] t3r_assert_satp_q;
  reg t3r_assert_svpbmt_q;
  reg t3r_assert_rsp_stall_q;
  reg [`INST_W-1:0] t3r_assert_rsp_inst0_q;
  reg [`INST_W-1:0] t3r_assert_rsp_inst1_q;
  reg [1:0] t3r_assert_rsp_resp0_q;
  reg [1:0] t3r_assert_rsp_resp1_q;
  reg [2:0] t3r_assert_rsp_split_q;
  reg t3w_assert_itlb_capture_q;
  reg t3w_assert_itlb_hit_q;
  reg t3w_assert_itlb_perm_fault_q;
  reg [`XLEN-1:0] t3w_assert_exec_paddr_q;
  reg t3x_assert_scratch_init_q;
  reg t3z_assert_sample_q;
  reg t3z_assert_fire_q;
  reg t3z_assert_flush_q;
  reg t3z_assert_rsp_stall_q;
  reg t3z_assert_replace_q;
  reg t4a_assert_exec_capture_q;
  reg t4a_assert_ptw_capture_q;
  reg [`XLEN-1:0] t4a_assert_ptw_addr_q;
  reg t4a_assert_ptw_fault_q;
  reg t3z_assert_active_paging_q;
  reg [1:0] t3z_assert_active_priv_q;
  reg [`XLEN-1:0] t3z_assert_active_satp_q;
  reg t3z_assert_active_svpbmt_q;
  reg [`XLEN-1:0] t3z_assert_active_pc_q;
  reg t3z_assert_live_paging_q;
  reg [1:0] t3z_assert_live_priv_q;
  reg [`XLEN-1:0] t3z_assert_live_satp_q;
  reg t3z_assert_live_svpbmt_q;
  reg [`XLEN-1:0] t3z_assert_live_pc_q;

  always @(posedge clk) begin
    if (rst) begin
      t3r_assert_prev_valid_q <= 1'b0;
      t3r_assert_prev_state_q <= S_IDLE;
      t3r_assert_capture_q <= 1'b0;
      t3r_assert_pc_q <= {`XLEN{1'b0}};
      t3r_assert_paging_q <= 1'b0;
      t3r_assert_priv_q <= `PRIV_M;
      t3r_assert_satp_q <= {`XLEN{1'b0}};
      t3r_assert_svpbmt_q <= 1'b0;
      t3r_assert_rsp_stall_q <= 1'b0;
      t3r_assert_rsp_inst0_q <= {`INST_W{1'b0}};
      t3r_assert_rsp_inst1_q <= {`INST_W{1'b0}};
      t3r_assert_rsp_resp0_q <= RESP_OK;
      t3r_assert_rsp_resp1_q <= RESP_OK;
      t3r_assert_rsp_split_q <= 3'd0;
      t3w_assert_itlb_capture_q <= 1'b0;
      t3w_assert_itlb_hit_q <= 1'b0;
      t3w_assert_itlb_perm_fault_q <= 1'b0;
      t3w_assert_exec_paddr_q <= {`XLEN{1'b0}};
      t3x_assert_scratch_init_q <= 1'b0;
      t3z_assert_sample_q <= 1'b0;
      t3z_assert_fire_q <= 1'b0;
      t3z_assert_flush_q <= 1'b0;
      t3z_assert_rsp_stall_q <= 1'b0;
      t3z_assert_replace_q <= 1'b0;
      t4a_assert_exec_capture_q <= 1'b0;
      t4a_assert_ptw_capture_q <= 1'b0;
      t4a_assert_ptw_addr_q <= {`XLEN{1'b0}};
      t4a_assert_ptw_fault_q <= 1'b0;
      t3z_assert_active_paging_q <= 1'b0;
      t3z_assert_active_priv_q <= `PRIV_M;
      t3z_assert_active_satp_q <= {`XLEN{1'b0}};
      t3z_assert_active_svpbmt_q <= 1'b0;
      t3z_assert_active_pc_q <= {`XLEN{1'b0}};
      t3z_assert_live_paging_q <= 1'b0;
      t3z_assert_live_priv_q <= `PRIV_M;
      t3z_assert_live_satp_q <= {`XLEN{1'b0}};
      t3z_assert_live_svpbmt_q <= 1'b0;
      t3z_assert_live_pc_q <= {`XLEN{1'b0}};
    end else begin
      // T4A independent two-stage shadow.  Candidate is checked against raw
      // inputs sampled on the prior edge.  Exec is checked against the prior
      // architectural owner: S_CACHE_READ must capture it, every other state
      // must hold it.  The expected data never comes from a production mux.
      if (t3z_assert_sample_q) begin
        if ((fetch_ctx_candidate_paging_q !== t3z_assert_live_paging_q) ||
            (fetch_ctx_candidate_priv_q !== t3z_assert_live_priv_q) ||
            (fetch_ctx_candidate_satp_q !== t3z_assert_live_satp_q) ||
            (fetch_ctx_candidate_svpbmt_en_q !==
             t3z_assert_live_svpbmt_q) ||
            (fetch_ctx_candidate_pc_q !== t3z_assert_live_pc_q))
          $error("[T4A-CANDIDATE-TRACK] candidate context did not capture prior raw live inputs");

        if (t3z_assert_fire_q) begin
          if ((state_q != S_CACHE_READ) ||
              (paging_q !== t3z_assert_live_paging_q) ||
              (req_priv_q !== t3z_assert_live_priv_q) ||
              (req_satp_q !== t3z_assert_live_satp_q) ||
              (req_svpbmt_en_q !== t3z_assert_live_svpbmt_q) ||
              (pc_q !== t3z_assert_live_pc_q))
            $error("[T4A-FIRE-CANDIDATE] request fire did not expose the captured candidate in S_CACHE_READ");
        end

        if ((fetch_ctx_exec_paging_q !== t3z_assert_active_paging_q) ||
            (fetch_ctx_exec_priv_q !== t3z_assert_active_priv_q) ||
            (fetch_ctx_exec_satp_q !== t3z_assert_active_satp_q) ||
            (fetch_ctx_exec_svpbmt_en_q !==
             t3z_assert_active_svpbmt_q) ||
            (fetch_ctx_exec_pc_q !== t3z_assert_active_pc_q)) begin
          if (t4a_assert_exec_capture_q)
            $error("[T4A-EXEC-HANDOFF] S_CACHE_READ did not capture the complete candidate context into exec");
          else
            $error("[T4A-EXEC-HOLD] execution context changed outside S_CACHE_READ");
        end

        // Expected owner selection is derived from the independent FSM state,
        // never from the production fetch_ctx_owner_candidate_w predicate.
        // This keeps a corrupted production predicate from making both sides
        // of the assertion wrong in the same way.
        if (state_q == S_CACHE_READ) begin
          if ((paging_q !== fetch_ctx_candidate_paging_q) ||
              (req_priv_q !== fetch_ctx_candidate_priv_q) ||
              (req_satp_q !== fetch_ctx_candidate_satp_q) ||
              (req_svpbmt_en_q !== fetch_ctx_candidate_svpbmt_en_q) ||
              (pc_q !== fetch_ctx_candidate_pc_q))
            $error("[T4A-OWNER-MUX] S_CACHE_READ owner did not select candidate context");
        end else begin
          if ((paging_q !== fetch_ctx_exec_paging_q) ||
              (req_priv_q !== fetch_ctx_exec_priv_q) ||
              (req_satp_q !== fetch_ctx_exec_satp_q) ||
              (req_svpbmt_en_q !== fetch_ctx_exec_svpbmt_en_q) ||
              (pc_q !== fetch_ctx_exec_pc_q))
            $error("[T4A-OWNER-MUX] non-S_CACHE_READ owner did not select execution context");
        end

        if (t4a_assert_exec_capture_q &&
            ((paging_q !== t3z_assert_active_paging_q) ||
             (req_priv_q !== t3z_assert_active_priv_q) ||
             (req_satp_q !== t3z_assert_active_satp_q) ||
             (req_svpbmt_en_q !== t3z_assert_active_svpbmt_q) ||
             (pc_q !== t3z_assert_active_pc_q)))
          $error("[T4A-OWNER-HANDOFF] candidate-to-exec owner handoff changed value");

        if (t3z_assert_flush_q && (pc_q !== t3z_assert_active_pc_q))
          $error("[T4A-FLUSH-OWNER-HOLD] MMU flush changed the request owner");
        if (t3z_assert_rsp_stall_q &&
            (pc_q !== t3z_assert_active_pc_q))
          $error("[T4A-RSP-OWNER-HOLD] response backpressure changed the execution owner");
        if (t3z_assert_replace_q &&
            ((state_q != S_CACHE_READ) ||
             (pc_q !== t3z_assert_live_pc_q)))
          $error("[T4A-ATOMIC-REPLACE] response replacement did not expose the new candidate owner");
      end

      if ((state_q == S_WALK_CHECK) &&
          (fetch_req_ready_o || fetch_rsp_valid_o || ifu_axi_arvalid_o ||
           ifu_axi_awvalid_o || ifu_axi_wvalid_o || ifu_axi_rready_o ||
           ifu_axi_bready_o || fetch_cache_fill_valid_w || itlb_fill_valid_w))
        $error("[T4A-PTW-CHECK-QUIET] PTW authorization boundary exposed protocol activity");
      if (t3r_assert_prev_valid_q && (state_q == S_WALK_AR) &&
          (t3r_assert_prev_state_q != S_WALK_CHECK) &&
          (t3r_assert_prev_state_q != S_WALK_AR))
        $error("[T4A-PTW-AR-PREDECESSOR] PTW AR escaped its registered authorization boundary");
      if (t4a_assert_ptw_capture_q &&
          ((state_q != S_WALK_AR) ||
           (walk_pte_addr_q !== t4a_assert_ptw_addr_q) ||
           (walk_pte_pmp_fault_q !== t4a_assert_ptw_fault_q)))
        $error("[T4A-PTW-AUTH-CAPTURE] PTW address/PMP decision was not captured atomically");

      if ((fetch_cache_read_window_w !== fetch_cache_lookup_issue_w) ||
          (fetch_cache_lookup_issue_w !== (state_q == S_CACHE_READ)))
        $error("[IFU-T3R-CACHE-ISSUE] SRAM read and semantic lookup escaped registered request state");
      if (((state_q == S_CACHE_READ) || (state_q == S_LOOKUP)) &&
          (fetch_req_ready_o || fetch_rsp_valid_o || ifu_axi_arvalid_o ||
           ifu_axi_awvalid_o || ifu_axi_wvalid_o || ifu_axi_rready_o ||
           ifu_axi_bready_o || fetch_cache_fill_valid_w || itlb_fill_valid_w))
        $error("[IFU-T3R-CACHE-QUIET] cache read/decision state exposed handshake, AXI traffic, or stale-owner fill");
      if (fetch_rsp_valid_o !== (state_q == S_RESP))
        $error("[IFU-T3R-RSP-REGISTERED] fetch response valid is not owned exclusively by S_RESP");
      if (fetch_req_fire_w &&
          !((state_q == S_IDLE) ||
            ((state_q == S_RESP) && fetch_rsp_fire_w)))
        $error("[IFU-T3R-REQ-OWNER] request fired outside IDLE or atomic response replacement");
      if (t3r_assert_prev_valid_q && (state_q == S_LOOKUP) &&
          (t3r_assert_prev_state_q != S_CACHE_READ))
        $error("[IFU-T3R-LOOKUP-PREDECESSOR] cache decision did not follow registered SRAM read");
      if (t3w_assert_itlb_capture_q && !mmu_flush_i &&
          ((state_q != S_LOOKUP) ||
           (lookup_itlb_hit_q !== t3w_assert_itlb_hit_q) ||
           (lookup_itlb_perm_fault_q !== t3w_assert_itlb_perm_fault_q) ||
           (lookup_exec_paddr_q !== t3w_assert_exec_paddr_q)))
        $error("[T3W-IFU-ITLB-PMP-BOUNDARY] registered ITLB owner changed before PMP decision");

      if (t3r_assert_capture_q && !mmu_flush_i &&
          ((state_q != S_CACHE_READ) ||
           (pc_q !== t3r_assert_pc_q) ||
           (paging_q !== t3r_assert_paging_q) ||
           (req_priv_q !== t3r_assert_priv_q) ||
           (req_satp_q !== t3r_assert_satp_q) ||
           (req_svpbmt_en_q !== t3r_assert_svpbmt_q)))
        $error("[IFU-T3R-REQ-CAPTURE] accepted immutable request context was not captured atomically");

      if (t3x_assert_scratch_init_q && !mmu_flush_i &&
          ((state_q != S_LOOKUP) ||
           (paddr0_q !== t3r_assert_pc_q) ||
           (paddr1_q !== {`XLEN{1'b0}}) ||
           (packet_cross_page_q !== 1'b0) ||
           (walk_second_q !== 1'b0) ||
           (second_page_ready_q !== 1'b0) ||
           (fetch_offset_q !== 3'd0) ||
           (fetch_data_q !== {`XLEN{1'b0}}) ||
           (inst0_q !== {`INST_W{1'b0}}) ||
           (inst1_q !== {`INST_W{1'b0}}) ||
           (resp0_q !== RESP_OK) ||
           (resp1_q !== RESP_OK) ||
           (resp0_bytes_q !== 3'd4)))
        $error("[IFU-T3X-SCRATCH-INIT] derived request scratch was not initialized at the registered cache-read boundary");

      if (t3r_assert_rsp_stall_q && !mmu_flush_i &&
          ((fetch_rsp_valid_o !== 1'b1) ||
           (fetch_rsp_inst0_o !== t3r_assert_rsp_inst0_q) ||
           (fetch_rsp_inst1_o !== t3r_assert_rsp_inst1_q) ||
           (fetch_rsp_resp0_o !== t3r_assert_rsp_resp0_q) ||
           (fetch_rsp_resp1_o !== t3r_assert_rsp_resp1_q) ||
           (fetch_rsp_resp0_bytes_o !== t3r_assert_rsp_split_q)))
        $error("[IFU-T3R-RSP-HOLD] registered fetch response payload changed under backpressure");

      t3r_assert_prev_valid_q <= 1'b1;
      t3r_assert_prev_state_q <= state_q;
      t3z_assert_sample_q <= 1'b1;
      t3z_assert_fire_q <= fetch_req_fire_w;
      t3z_assert_flush_q <= mmu_flush_i;
      t3z_assert_rsp_stall_q <= fetch_rsp_valid_o && !fetch_rsp_ready_i;
      t3z_assert_replace_q <= fetch_req_fire_w && fetch_rsp_fire_w;
      t4a_assert_exec_capture_q <= (state_q == S_CACHE_READ);
      t4a_assert_ptw_capture_q <=
          (state_q == S_WALK_CHECK) && !mmu_flush_i;
      if ((state_q == S_WALK_CHECK) && !mmu_flush_i) begin
        t4a_assert_ptw_addr_q <= walk_pte_addr_w;
        t4a_assert_ptw_fault_q <= walk_pte_pmp_fault_w;
      end
      t3z_assert_active_paging_q <= paging_q;
      t3z_assert_active_priv_q <= req_priv_q;
      t3z_assert_active_satp_q <= req_satp_q;
      t3z_assert_active_svpbmt_q <= req_svpbmt_en_q;
      t3z_assert_active_pc_q <= pc_q;
      t3z_assert_live_paging_q <= req_paging_w;
      t3z_assert_live_priv_q <= priv_mode_i;
      t3z_assert_live_satp_q <= satp_i;
      t3z_assert_live_svpbmt_q <= svpbmt_en_i;
      t3z_assert_live_pc_q <= fetch_req_pc_i;
      t3w_assert_itlb_capture_q <= (state_q == S_CACHE_READ) && !mmu_flush_i;
      t3x_assert_scratch_init_q <= (state_q == S_CACHE_READ) && !mmu_flush_i;
      if ((state_q == S_CACHE_READ) && !mmu_flush_i) begin
        t3w_assert_itlb_hit_q <= req_itlb_hit_w;
        t3w_assert_itlb_perm_fault_q <= req_itlb_perm_fault_w;
        t3w_assert_exec_paddr_q <= req_exec_paddr_w;
      end
      t3r_assert_capture_q <= fetch_req_fire_w;
      if (fetch_req_fire_w) begin
        t3r_assert_pc_q <= fetch_req_pc_i;
        t3r_assert_paging_q <= req_paging_w;
        t3r_assert_priv_q <= priv_mode_i;
        t3r_assert_satp_q <= satp_i;
        t3r_assert_svpbmt_q <= svpbmt_en_i;
      end
      t3r_assert_rsp_stall_q <= !mmu_flush_i && fetch_rsp_valid_o &&
                               !fetch_rsp_ready_i;
      if (!mmu_flush_i && fetch_rsp_valid_o && !fetch_rsp_ready_i) begin
        t3r_assert_rsp_inst0_q <= fetch_rsp_inst0_o;
        t3r_assert_rsp_inst1_q <= fetch_rsp_inst1_o;
        t3r_assert_rsp_resp0_q <= fetch_rsp_resp0_o;
        t3r_assert_rsp_resp1_q <= fetch_rsp_resp1_o;
        t3r_assert_rsp_split_q <= fetch_rsp_resp0_bytes_o;
      end
    end
  end

  // IFU-ACCESS-G1 provenance shadow：fetch response 反压时 split 与 valid 同 payload 保持；
  // 合法边界仅 {0,2,4,6}，其中 0 是 first-halfword fault 的必要编码。
  reg g2_assert_rsp_stall_q;
  reg [2:0] g2_assert_resp0_bytes_q;
  always @(posedge clk) begin
    if (rst) begin
      g2_assert_rsp_stall_q <= 1'b0;
      g2_assert_resp0_bytes_q <= 3'd0;
    end else begin
      if (g2_assert_rsp_stall_q && !mmu_flush_i &&
          ((fetch_rsp_valid_o !== 1'b1) ||
           (fetch_rsp_resp0_bytes_o !== g2_assert_resp0_bytes_q)))
        $error("[IFU-FETCH-G2-HOLD] stalled fetch response withdrew/changed resp0 byte boundary");
      if (fetch_rsp_valid_o &&
          ((^fetch_rsp_resp0_bytes_o === 1'bx) ||
           fetch_rsp_resp0_bytes_o[0] ||
           (fetch_rsp_resp0_bytes_o > 3'd6)))
        $error("[IFU-ACCESS-SPLIT-RANGE] valid fetch response has illegal split");
      if (fetch_rsp_valid_o &&
          (fetch_rsp_resp0_o == RESP_OK) && (fetch_rsp_resp1_o == RESP_OK) &&
          (fetch_rsp_resp0_bytes_o !== 3'd4))
        $error("[IFU-ACCESS-SUCCESS-SPLIT] successful fetch response split is not four");
      if (fetch_rsp_valid_o && (fetch_rsp_resp1_o != RESP_OK) &&
          (fetch_rsp_resp0_o != RESP_OK))
        $error("[IFU-ACCESS-FAULT-ABI] fault response is not successful-prefix/fault-suffix");

      g2_assert_rsp_stall_q <= !mmu_flush_i && fetch_rsp_valid_o &&
                              !fetch_rsp_ready_i;
      if (!mmu_flush_i && fetch_rsp_valid_o && !fetch_rsp_ready_i)
        g2_assert_resp0_bytes_q <= fetch_rsp_resp0_bytes_o;
    end
  end
`endif

endmodule
