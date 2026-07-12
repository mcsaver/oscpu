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
  localparam [3:0] S_LOOKUP = 4'd9;     // 取指包 cache SRAM 同步读判决拍(fire 次拍, ready=0)
  // 【AXI4 化 S1】mmu_flush 命中在飞 AXI 读(AR 已 fire、R 未归)时的自吞排水态:
  // rready 保持拉高吞掉 R 后才回 IDLE; 期间 fetch_req_ready=0(防新请求与残 R 串包)。
  // 取代旧"xbar abort 边带吞 R"机制——master 自吞使互连成为纯标准 AXI4。
  localparam [3:0] S_DRAIN = 4'd10;
  localparam [`XLEN-1:0] PTE_A_BIT = {{(`XLEN-7){1'b0}}, 7'h40};  // bit 6 (Accessed)
  localparam [1:0] RESP_OK = 2'b00;
  localparam [1:0] RESP_ACCESS_FAULT = 2'b01;
  localparam [1:0] RESP_PAGE_FAULT = 2'b10;
  localparam ITLB_INDEX_W = 6;

  reg [3:0] state_q;
  reg paging_q;
  reg [1:0] req_priv_q;
  reg [`XLEN-1:0] req_satp_q;
  reg req_svpbmt_en_q;
  reg walk_second_q;
  reg [1:0] walk_level_q;
  reg [43:0] walk_ppn_q;
  reg [`XLEN-1:0] pc_q;
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

  assign ifu_axi_arsize_o = (state_q == S_WALK_AR) ? 3'd3 : 3'd1;
  assign ifu_axi_arprot_o = (state_q == S_WALK_AR) ? 3'b000 : 3'b100;

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
      (!paging_q || req_itlb_hit_w);
  // 刀F 融合拍专用 hit: 用不含窗口②当拍 snoop 地址比较的 no_snoop 版, 叠加
  // !invalidate_valid_i(单 bit)关断——invalidate 拍融合降级走精确寄存路径
  // (S_RESP, +1 拍), 切断 SQ snoop 跨模块链与取指发射决策(ready/fire/SRAM addr)
  // 的串联(全核 top 违例族修复)。invalidate_valid_i=0 时本式==cache_hit_w。
  wire cache_hit_no_snoop_raw_w;
  wire cache_hit_fusion_w = cache_hit_no_snoop_raw_w && !invalidate_valid_i &&
      !req_exec_pmp_fault_w && !req_exec1_pmp_fault_w &&
      (!paging_q || req_itlb_hit_w);
  wire fetch_cache_context_unused_w;
  wire [`INST_W-1:0] cache_inst0_w;
  wire [`INST_W-1:0] cache_inst1_w;
  wire [1:0] cache_resp0_w;
  wire [1:0] cache_resp1_w;
  wire req_itlb_context_hit_w;
  wire [`XLEN-1:0] req_itlb_pte_w;
  wire [1:0] req_itlb_level_w;
  wire [`XLEN-1:0] req_itlb_paddr_w;
  // 判决拍(S_LOOKUP)复检链全部改用 fire 拍锁存值: svpbmt/priv/paging/pc 取
  // req_svpbmt_en_q/req_priv_q/paging_q/pc_q, 与 cache 内部锁存的请求同参照系。
  // pmpcfg/pmpaddr 仍取当拍输入(CSR 写经串行化, 无在飞取指请求交叠)。
  wire req_itlb_perm_fault_w =
      req_itlb_context_hit_w &&
      (pte_reserved_fault(req_itlb_pte_w, req_svpbmt_en_q, req_itlb_level_w) ||
       exec_permission_fault(req_itlb_pte_w, req_priv_q));
  assign req_itlb_hit_w = req_itlb_context_hit_w && !req_itlb_perm_fault_w;
  wire [`XLEN-1:0] req_exec_paddr_w =
      (paging_q && req_itlb_hit_w) ? req_itlb_paddr_w : pc_q;
  wire [`XLEN-1:0] req_exec1_paddr_w = req_exec_paddr_w + 64'd4;
  wire req_exec_pmp_fault_raw_w;
  wire req_exec1_pmp_fault_raw_w;
  assign req_exec_pmp_fault_w =
      (!paging_q || req_itlb_hit_w) && req_exec_pmp_fault_raw_w;
  assign req_exec1_pmp_fault_w =
      (!paging_q || req_itlb_hit_w) && req_exec1_pmp_fault_raw_w;
  wire fetch_req_fire_w = fetch_req_valid_i && fetch_req_ready_o;
  wire [`XLEN-1:0] pc_second_page_vaddr_w =
      {pc_q[`XLEN-1:12], 12'b0} + 64'd4096;
  wire [`XLEN-1:0] walk_vaddr_w =
      walk_second_q ? pc_second_page_vaddr_w : pc_q;
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, walk_vaddr_w, walk_level_q);

  // Miss path：每拍只处理一个已注册的 2B frontier。RDATA 仅决定下一拍 offset；
  // 不允许 RDATA→length→ARVALID/ARADDR 的同拍组合链。
  wire [`XLEN-1:0] fetch_current_vaddr_w =
      pc_q + {{(`XLEN-3){1'b0}}, fetch_offset_q};
  wire fetch_current_on_second_w =
      fetch_current_vaddr_w[`XLEN-1:12] != pc_q[`XLEN-1:12];
  wire [`XLEN-1:0] fetch_current_paddr_w = !paging_q ?
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
      pc_q + {{(`XLEN-3){1'b0}}, fetch_next_offset_w};
  wire fetch_next_cross_page_w =
      fetch_next_vaddr_w[`XLEN-1:12] != pc_q[`XLEN-1:12];
  wire itlb_fill_valid_w =
      !mmu_flush_i && (state_q == S_WALK_R) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !pte_invalid(ifu_axi_rdata_i) &&
      !pte_reserved_fault(ifu_axi_rdata_i, req_svpbmt_en_q, walk_level_q) &&
      (pte_leaf(ifu_axi_rdata_i)) &&
      !superpage_misaligned(ifu_axi_rdata_i, walk_level_q) &&
      !exec_permission_fault(ifu_axi_rdata_i, req_priv_q) &&
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

  // 两拍 lookup 协议: fire 拍(fetch_req_fire_w)发射 lookup_en 并传当拍请求上下文,
  // cache 内部锁存; 判决拍(S_LOOKUP)输出 cache_hit_raw_w/inst/resp 针对锁存请求有效。
  OooFetchPacketCache u_fetch_packet_cache (
    .clk(clk),
    .rst(rst),
    .clear_i(mmu_flush_i),
    .lookup_en_i(fetch_req_fire_w),
    .lookup_paging_i(req_paging_w),
    .lookup_priv_i(priv_mode_i),
    .lookup_satp_i(satp_i),
    .lookup_pc_i(fetch_req_pc_i),
    .lookup_context_hit_o(fetch_cache_context_unused_w),
    .lookup_hit_o(cache_hit_raw_w),
    .lookup_hit_no_snoop_o(cache_hit_no_snoop_raw_w),
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

  // ITLB lookup 消费点已移到 S_LOOKUP 判决拍, 输入改用 fire 拍锁存值, 使其组合
  // 输出与取指包 cache SRAM rdata_o 在判决拍对齐(ITLB 本体保持 FF 组合读, 不 SRAM 化)。
  OooSv39Tlb #(
    .INDEX_W(ITLB_INDEX_W)
  ) u_itlb (
    .clk(clk),
    .rst(rst),
    .clear_i(mmu_flush_i),
    .lookup_valid_i(paging_q),
    .lookup_vaddr_i(pc_q),
    .lookup_satp_i(req_satp_q),
    .lookup_context_hit_o(req_itlb_context_hit_w),
    .lookup_pte_o(req_itlb_pte_w),
    .lookup_level_o(req_itlb_level_w),
    .lookup_paddr_o(req_itlb_paddr_w),
    .fill_valid_i(itlb_fill_valid_w),
    .fill_vaddr_i(walk_vaddr_w),
    .fill_satp_i(req_satp_q),
    .fill_pte_i(ifu_axi_rdata_i),
    .fill_level_i(walk_level_q)
  );

  PmpChecker u_req_exec_pmp_checker (
    .paddr_i(req_exec_paddr_w),
    .access_size_i(4'd4),
    .priv_mode_i(req_priv_q),
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
    .priv_mode_i(req_priv_q),
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
    .priv_mode_i(req_priv_q),
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
    .priv_mode_i(req_priv_q),
    .access_read_i(1'b0),
    .access_write_i(1'b0),
    .access_exec_i(1'b1),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_leaf_current_pmp_fault_w)
  );

  // F9：取指页表 walk 的各级 PTE 读地址也必须受 PMP（priv-spec 隐式页表访问）。PTE 读是
  // 隐式数据读（非取指），故按 read 检查、8B、用被翻译取指的特权级 req_priv_q。旧实现各级
  // PTE 读地址绕过 PMP，OS 把页表放入对 S 态拒绝的 PMP 区时硬件仍能读出 PTE。
  wire walk_pte_pmp_fault_w;
  PmpChecker u_walk_pte_pmp_checker (
    .paddr_i(walk_pte_addr_w),
    .access_size_i(4'd8),
    .priv_mode_i(req_priv_q),
    .access_read_i(1'b1),
    .access_write_i(1'b0),
    .access_exec_i(1'b0),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_pte_pmp_fault_w)
  );

  // packet cache 使用 PC+satp/priv 做上下文 tag；ITLB 命中只缓存翻译，不绕过取指权限。
  // 刀F 融合拍: S_LOOKUP 命中拍组合响应(payload 走 cache_*_w 直出), 同拍可接受新请求
  // (该拍即新 fire 拍)——hit 流恢复 1 包/拍。miss/fault 拍 ready=0, walk/AXI 路径不变;
  // rsp 不 ready 时走落寄存进 S_RESP 的既有路径(S_RESP=天然 skid)。
  wire lookup_hit_resp_w = (state_q == S_LOOKUP) && cache_hit_fusion_w;
  // 【mmu_flush 打拍配套】flush 拍不受理新请求: 复位分支会吞掉同拍 fire 的请求
  // (sequencer 记账悬空→挂死), flush 拍压 ready 使请求次拍重发。
  assign fetch_req_ready_o = !mmu_flush_i &&
                             ((state_q == S_IDLE) ||
                              ((state_q == S_RESP) && fetch_rsp_ready_i) ||
                              (lookup_hit_resp_w && fetch_rsp_ready_i));
  assign fetch_rsp_valid_o = (state_q == S_RESP) || lookup_hit_resp_w;
  assign fetch_rsp_inst0_o = lookup_hit_resp_w ? cache_inst0_w : inst0_q;
  assign fetch_rsp_inst1_o = lookup_hit_resp_w ? cache_inst1_w : inst1_q;
  assign fetch_rsp_resp0_o = lookup_hit_resp_w ? cache_resp0_w : resp0_q;
  assign fetch_rsp_resp1_o = lookup_hit_resp_w ? cache_resp1_w : resp1_q;
  // successful-prefix/fault-suffix ABI：hit/完整成功恒 split=4；fault 的 split=首个
  // 失败 halfword offset F（允许 F=0）。decoder 以真实长度决定 fault 属于哪一槽。
  assign fetch_rsp_resp0_bytes_o = lookup_hit_resp_w ? 3'd4 : resp0_bytes_q;

  // 【AXI4 化 S1】flush 拍不发新 AR(撤销待发读, 无 orphan; 已 fire 的读走 S_DRAIN 自吞)
  assign ifu_axi_arvalid_o =
      (((state_q == S_WALK_AR) && !walk_pte_pmp_fault_w) ||
       ((state_q == S_AR0) && !fetch_current_pmp_fault_w)) && !mmu_flush_i;
  assign ifu_axi_araddr_o =
      (state_q == S_WALK_AR) ? walk_pte_addr_w : fetch_current_paddr_w;
  assign ifu_axi_rready_o =
      (state_q == S_WALK_R) || (state_q == S_R0) ||
      (state_q == S_DRAIN);
  // 【AXI4 化 S1】在飞 AXI 读判定(等 R 态=AR 已 fire): flush 拍若 R 未同拍到达,
  // 转 S_DRAIN 吞 R; R 同拍 fire 则本拍即消费完, 直接回 IDLE。
  wire ifu_axi_read_inflight_w =
      (state_q == S_WALK_R) || (state_q == S_R0) ||
      (state_q == S_DRAIN);
  wire ifu_axi_r_fire_w = ifu_axi_rvalid_i && ifu_axi_rready_o;

  // HW A 更新写通道：awaddr = 本级 leaf PTE 地址(walk_pte_addr_w 在 S_AD_UPDATE 期间仍有效,
  // 因 walk_ppn_q/walk_level_q 不变), wdata = 置 A 位的 PTE, wstrb 全 8B。AW/W 可独立
  // 握手；valid 一经呈现到 fire 前不可撤回。mmu_flush 只置 ad_drop_q，仍补齐 channel 并收 B。
  assign ifu_axi_awvalid_o = (state_q == S_AD_UPDATE) && !aw_done_q;
  assign ifu_axi_awaddr_o = walk_pte_addr_w;
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

  always @(posedge clk) begin
    if (rst) begin
      // rst 代表 bridge+xbar/slave 共同复位，允许清除全部事务 owner。
      state_q <= S_IDLE;
      paging_q <= 1'b0;
      req_priv_q <= `PRIV_M;
      req_satp_q <= {`XLEN{1'b0}};
      req_svpbmt_en_q <= 1'b0;
      walk_second_q <= 1'b0;
      walk_level_q <= 2'd0;
      walk_ppn_q <= 44'd0;
      pc_q <= {`XLEN{1'b0}};
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
      // mmu_flush 不是 AXI reset：未呈现 write 时仍按旧合同清 fetch 语义；已发读未归
      // 则进 S_DRAIN 自吞。S_AD_UPDATE 必须落到下方 case 并行记录当拍 AW/W/B fire。
      state_q <= (ifu_axi_read_inflight_w && !ifu_axi_r_fire_w) ?
                 S_DRAIN : S_IDLE;
      paging_q <= 1'b0;
      req_priv_q <= `PRIV_M;
      req_satp_q <= {`XLEN{1'b0}};
      req_svpbmt_en_q <= 1'b0;
      walk_second_q <= 1'b0;
      walk_level_q <= 2'd0;
      walk_ppn_q <= 44'd0;
      pc_q <= {`XLEN{1'b0}};
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
    end else begin
      case (state_q)
        S_IDLE: begin
          // fire 拍只锁存请求上下文并发射 cache 同步读(lookup_en_i=fetch_req_fire_w),
          // hit/fault/walk 判决整体移到次拍 S_LOOKUP(SRAM 1-cycle 同步读合同)。
          if (fetch_req_fire_w) begin
            pc_q <= fetch_req_pc_i;
            paddr0_q <= fetch_req_pc_i;
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
            paging_q <= req_paging_w;
            req_priv_q <= priv_mode_i;
            req_satp_q <= satp_i;
            req_svpbmt_en_q <= svpbmt_en_i;
            state_q <= S_LOOKUP;
          end
        end

        S_LOOKUP: begin
          // 判决拍: cache_hit_raw_w=SRAM 同步读结果, ITLB/PMP 复检用 fire 拍锁存值。
          // 刀F 融合拍: hit 响应本拍组合交付(见 fetch_rsp_valid_o 组合臂); miss/fault
          // 拍 ready=0；miss 进入 registered CHECK→AR→R，mmu_flush 经顶部复位
          // 分支回 S_IDLE，本判决自然作废。
          if (cache_hit_w) begin
            if (cache_hit_fusion_w && fetch_rsp_ready_i) begin
              if (fetch_req_valid_i) begin
                // 融合拍=新 fire 拍: 锁新上下文+发射新 SRAM 读(lookup_en_i 自动覆盖),
                // 留在 S_LOOKUP —— hit 稳态 1 包/拍。
                pc_q <= fetch_req_pc_i;
                paddr0_q <= fetch_req_pc_i;
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
                paging_q <= req_paging_w;
                req_priv_q <= priv_mode_i;
                req_satp_q <= satp_i;
                req_svpbmt_en_q <= svpbmt_en_i;
                state_q <= S_LOOKUP;
              end else begin
                // 响应已组合交付且无新请求 → 直接回 IDLE(不经 S_RESP)
                state_q <= S_IDLE;
              end
            end else begin
              // rsp 反压 或 invalidate 拍融合关断: 落寄存进 S_RESP(天然 skid;
              // 精确 hit 语义含窗口②在此路径照常成立)
              inst0_q <= cache_inst0_w;
              inst1_q <= cache_inst1_w;
              resp0_q <= cache_resp0_w;
              resp1_q <= cache_resp1_w;
              resp0_bytes_q <= 3'd4;
              state_q <= S_RESP;
            end
          end else if (paging_q && req_itlb_perm_fault_w) begin
            resp0_q <= RESP_OK;
            resp1_q <= RESP_PAGE_FAULT;
            resp0_bytes_q <= 3'd0;
            state_q <= S_RESP;
          end else if (paging_q && req_itlb_hit_w) begin
            paddr0_q <= req_itlb_paddr_w;
            state_q <= S_AR0;
          end else if (paging_q) begin
            if (canonical_sv39(pc_q)) begin
              walk_second_q <= 1'b0;
              walk_level_q <= 2'd2;
              walk_ppn_q <= req_satp_q[43:0];
              state_q <= S_WALK_AR;
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

        S_WALK_AR: begin
          // PTE 隐式 data read 先做 8B PMP。无论第几页，失败 owner 都是当前
          // registered halfword frontier；此前成功 prefix 保留，年轻访问停止。
          if (walk_pte_pmp_fault_w) begin
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
            debug_last_pte_addr_q <= walk_pte_addr_w;
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
                                            req_svpbmt_en_q,
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
                  exec_permission_fault(ifu_axi_rdata_i, req_priv_q)) begin
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
              // walk_ppn_q/walk_level_q 保持不变 → walk_pte_addr_w 仍指向本 leaf PTE。
              // 置 A 后真 fault 已排除, 故不会与 fault 竞争(fault 分支在前, 优先)。
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
                  paddr0_q <= leaf_paddr(ifu_axi_rdata_i, pc_q,
                                         walk_level_q);
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
                  if (paging_q && !second_page_ready_q) begin
                    if (canonical_sv39(pc_second_page_vaddr_w)) begin
                      walk_second_q <= 1'b1;
                      walk_level_q <= 2'd2;
                      walk_ppn_q <= req_satp_q[43:0];
                      state_q <= S_WALK_AR;
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
              state_q <= S_WALK_AR;
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
          // back-to-back accept: 与 S_IDLE 同为 fire 拍, 只锁存请求并进 S_LOOKUP
          // (fetch_req_fire_w = valid && S_RESP && rsp_ready, 同拍发射 lookup_en_i)。
          if (fetch_rsp_ready_i) begin
            if (fetch_req_valid_i) begin
              pc_q <= fetch_req_pc_i;
              paddr0_q <= fetch_req_pc_i;
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
              paging_q <= req_paging_w;
              req_priv_q <= priv_mode_i;
              req_satp_q <= satp_i;
              req_svpbmt_en_q <= svpbmt_en_i;
              state_q <= S_LOOKUP;
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
  // IFU-AXI-G1 外部协议 shadow：只从端口 valid/fire 建 owner，不复用 aw_done/w_done/ad_drop，
  // 避免实现与断言共享同一错误状态。综合时 OOO_ASSERT 关闭，不进入 PPA。
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
