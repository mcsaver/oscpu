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

  output ifu_axi_arvalid_o,
  input ifu_axi_arready_i,
  output [`XLEN-1:0] ifu_axi_araddr_o,
  input ifu_axi_rvalid_i,
  output ifu_axi_rready_o,
  input [`XLEN-1:0] ifu_axi_rdata_i,
  input [1:0] ifu_axi_rresp_i,

  // HW-managed A 更新写通道（Svadu，对齐 NEMU）：取指到 A=0 的可执行页时，
  // 不再 page fault，改经 S_AD_UPDATE 写回 PTE 置 A 位。取指只置 A（不置 D）。
  output ifu_axi_awvalid_o,
  input ifu_axi_awready_i,
  output [`XLEN-1:0] ifu_axi_awaddr_o,
  output ifu_axi_wvalid_o,
  input ifu_axi_wready_i,
  output [`XLEN-1:0] ifu_axi_wdata_o,
  output [`STRB_W-1:0] ifu_axi_wstrb_o,
  input ifu_axi_bvalid_i,
  output ifu_axi_bready_o,
  input [1:0] ifu_axi_bresp_i
);

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
  reg [`XLEN-1:0] ad_pte_q;   // HW A: 置 A 位后的 leaf PTE(供 S_AD_UPDATE 写通道)
  reg aw_done_q;              // S_AD_UPDATE 的 AW 已握手(吸收 awready/wready 偏斜)
  reg w_done_q;               // S_AD_UPDATE 的 W 已握手

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
  wire cache_hit_raw_w;
  wire pmp_active_w = (pmpcfg_i != {`PMP_CFG_BUS_W{1'b0}});
  // 声明前置，iverilog 14 拒绝前向引用（下方 cache_hit_w 提前引用这三个信号）
  wire req_itlb_hit_w;
  wire req_exec_pmp_fault_w;
  wire req_exec1_pmp_fault_w;
  // 为什么这么改：原实现只要 PMP 有任何活动条目就整体禁用取指包 cache
  // (cache_hit && !pmp_active)，导致真实 Linux/OpenSBI(总会配 PMP)下每次取指都
  // miss、退到慢速 AXI 取指，CPI 近乎翻倍。其实 PMP 权限本就每拍按当前 pmpcfg
  // 独立计算(req_exec_pmp_fault_w)；安全做法是命中时仍要求 PMP 放行，而不是禁用
  // 整个 cache。这样 PMP 会 fault 时 cache_hit=0 落到下方 fault 分支(语义不变)，
  // PMP 放行(Linux 下 DRAM 整片 RWX 的常态)时命中生效、恢复性能。
  // 非 PMP 场景(pmp_active=0)走 1'b1 分支，行为与原实现逐位一致。
  // SRAM 化后本式仅在 S_LOOKUP(判决拍)有意义：cache_hit_raw_w 是 SRAM 同步读结果，
  // ITLB/PMP 复检全部用 fire 拍锁存的请求上下文(paging_q/pc_q/req_priv_q/req_satp_q)。
  wire cache_hit_w = cache_hit_raw_w &&
      (pmp_active_w ? (!req_exec_pmp_fault_w && !req_exec1_pmp_fault_w &&
                       (!paging_q || req_itlb_hit_w))
                    : 1'b1);
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
  // direct miss 的 AR 从 fire 拍移到 S_LOOKUP 判决拍(同步读 +1 拍)。
  wire lookup_direct_miss_w =
      (state_q == S_LOOKUP) && !paging_q && !req_exec_pmp_fault_w &&
      !cache_hit_w;
  wire [`XLEN-1:0] pc_packet_end_w = pc_q + 64'd7;
  wire [`XLEN-1:0] pc_second_page_vaddr_w =
      {pc_q[`XLEN-1:12], 12'b0} + 64'd4096;
  wire [`XLEN-1:0] walk_vaddr_w =
      walk_second_q ? pc_second_page_vaddr_w : pc_q;
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, walk_vaddr_w, walk_level_q);
  wire [`XLEN-1:0] walk_leaf_exec_paddr_w =
      leaf_paddr(ifu_axi_rdata_i, walk_vaddr_w, walk_level_q);
  wire [`XLEN-1:0] walk_leaf_exec1_paddr_w =
      walk_leaf_exec_paddr_w + 64'd4;
  wire walk_leaf_exec_pmp_fault_w;
  wire walk_leaf_exec1_pmp_fault_w;
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
      !pte_reserved_fault(ifu_axi_rdata_i, req_svpbmt_en_q, walk_level_q) &&
      (pte_leaf(ifu_axi_rdata_i)) &&
      !superpage_misaligned(ifu_axi_rdata_i, walk_level_q) &&
      !exec_permission_fault(ifu_axi_rdata_i, req_priv_q) &&
      // HW A: 首遍读到 A=0 的 PTE 不填 TLB(否则缓存 A=0 项); 待 S_AD_UPDATE 写完 re-walk
      // 读回 A=1 的 PTE 再填。TLB 因此永不缓存 A=0, TLB 命中路径无需 A 门控。
      !exec_ad_update_needed(ifu_axi_rdata_i);
  wire fetch_cache_fill_r0_w =
      (state_q == S_R0) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !packet_cross_page_q &&
      (resp0_q == RESP_OK) && (resp1_q == RESP_OK);
  // 不缓存跨页取指包:跨页包槽1 在下一物理页,而命中复检的 req_exec1_paddr_w=paddr0+4 是错页地址,
  // PMP 运行期 allow→deny 第二页且无取指 cache 失效时会绕过槽1 PMP(known-issues 隐患B)。
  // 跨页包改为每次重取(经 walk-leaf checker 用正确物理地址重查两页 PMP),结构性消除该隐患;
  // 交付不受影响(走 inst*_q 寄存器,与 fill 分离),跨页包稀少(PC 跨 4KB 边界),CPI 影响可忽略。
  wire fetch_cache_fill_r1_w =
      (state_q == S_R1) && ifu_axi_rvalid_i &&
      (ifu_axi_rresp_i == RESP_OK) &&
      !packet_cross_page_q &&
      (resp0_q == RESP_OK);
  // 填充恒开：缓存的是真实取回的指令字节，存入安全；是否供给由 cache_hit_w 的
  // PMP 放行门控决定。原来的 !pmp_active_w 门控会在 PMP 下让 cache 永不填充。
  wire fetch_cache_fill_valid_w =
      (fetch_cache_fill_r0_w || fetch_cache_fill_r1_w);
  wire [`INST_W-1:0] fetch_cache_fill_inst0_w =
      fetch_cache_fill_r1_w ? merged_cross_packet_w[`INST_W-1:0] :
                              fetch_beat_inst0_w;
  wire [`INST_W-1:0] fetch_cache_fill_inst1_w =
      fetch_cache_fill_r1_w ? merged_cross_packet_w[`XLEN-1:`INST_W] :
                              fetch_beat_inst1_w;
  wire [1:0] fetch_cache_fill_resp0_w =
      fetch_cache_fill_r1_w ? resp0_q : RESP_OK;
  wire [1:0] fetch_cache_fill_resp1_w = resp1_q;

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

  PmpChecker u_walk_leaf_exec_pmp_checker (
    .paddr_i(walk_leaf_exec_paddr_w),
    .access_size_i(4'd4),
    .priv_mode_i(req_priv_q),
    .access_read_i(1'b0),
    .access_write_i(1'b0),
    .access_exec_i(1'b1),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_leaf_exec_pmp_fault_w)
  );

  PmpChecker u_walk_leaf_exec1_pmp_checker (
    .paddr_i(walk_leaf_exec1_paddr_w),
    .access_size_i(4'd4),
    .priv_mode_i(req_priv_q),
    .access_read_i(1'b0),
    .access_write_i(1'b0),
    .access_exec_i(1'b1),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .fault_o(walk_leaf_exec1_pmp_fault_w)
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
  wire lookup_hit_resp_w = (state_q == S_LOOKUP) && cache_hit_w;
  assign fetch_req_ready_o = (state_q == S_IDLE) ||
                             ((state_q == S_RESP) && fetch_rsp_ready_i) ||
                             (lookup_hit_resp_w && fetch_rsp_ready_i);
  assign fetch_rsp_valid_o = (state_q == S_RESP) || lookup_hit_resp_w;
  assign fetch_rsp_inst0_o = lookup_hit_resp_w ? cache_inst0_w : inst0_q;
  assign fetch_rsp_inst1_o = lookup_hit_resp_w ? cache_inst1_w : inst1_q;
  assign fetch_rsp_resp0_o = lookup_hit_resp_w ? cache_resp0_w : resp0_q;
  assign fetch_rsp_resp1_o = lookup_hit_resp_w ? cache_resp1_w : resp1_q;

  assign ifu_axi_arvalid_o =
      ((state_q == S_WALK_AR) && !walk_pte_pmp_fault_w) || (state_q == S_AR0) ||
      (state_q == S_AR1) ||
      lookup_direct_miss_w;
  // direct miss 在 S_LOOKUP 发 AR 时 paging_q=0, fetch0_addr_w=pc_q(=fire 拍锁存的
  // 请求 PC), 无需单列 araddr 臂。
  assign ifu_axi_araddr_o =
      (state_q == S_WALK_AR) ? walk_pte_addr_w :
      (state_q == S_AR1) ? paddr1_q :
      fetch0_addr_w;
  assign ifu_axi_rready_o =
      (state_q == S_WALK_R) || (state_q == S_R0) || (state_q == S_R1);

  // HW A 更新写通道：awaddr = 本级 leaf PTE 地址(walk_pte_addr_w 在 S_AD_UPDATE 期间仍有效,
  // 因 walk_ppn_q/walk_level_q 不变), wdata = 置 A 位的 PTE, wstrb 全 8B。写落 always-ready
  // PMEM(页表所在), AW/W 同拍握手; aw_done_q/w_done_q 吸收任何 awready/wready 偏斜。
  // mmu_flush 期丢写对取指侧正确(A 更新是优化, re-fetch 幂等重做)。
  assign ifu_axi_awvalid_o = (state_q == S_AD_UPDATE) && !aw_done_q;
  assign ifu_axi_awaddr_o = walk_pte_addr_w;
  assign ifu_axi_wvalid_o = (state_q == S_AD_UPDATE) && !w_done_q;
  assign ifu_axi_wdata_o = ad_pte_q;
  assign ifu_axi_wstrb_o = {`STRB_W{1'b1}};
  assign ifu_axi_bready_o = (state_q == S_AD_UPDATE);
  wire ifu_ad_aw_fire_w = ifu_axi_awvalid_o && ifu_axi_awready_i;
  wire ifu_ad_w_fire_w = ifu_axi_wvalid_o && ifu_axi_wready_i;

  always @(posedge clk) begin
    if (rst || mmu_flush_i) begin
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
      ad_pte_q <= {`XLEN{1'b0}};
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
    end else begin
      case (state_q)
        S_IDLE: begin
          // fire 拍只锁存请求上下文并发射 cache 同步读(lookup_en_i=fetch_req_fire_w),
          // hit/fault/walk 判决整体移到次拍 S_LOOKUP(SRAM 1-cycle 同步读合同)。
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
            req_svpbmt_en_q <= svpbmt_en_i;
            state_q <= S_LOOKUP;
          end
        end

        S_LOOKUP: begin
          // 判决拍: cache_hit_raw_w=SRAM 同步读结果, ITLB/PMP 复检用 fire 拍锁存值。
          // 刀F 融合拍: hit 响应本拍组合交付(见 fetch_rsp_valid_o 组合臂); miss/fault
          // 拍 ready=0; direct miss 的 AR 由 lookup_direct_miss_w 当拍发起;
          // mmu_flush 经顶部复位分支回 S_IDLE, 本判决自然作废。
          if (cache_hit_w) begin
            if (fetch_rsp_ready_i) begin
              if (fetch_req_valid_i) begin
                // 融合拍=新 fire 拍: 锁新上下文+发射新 SRAM 读(lookup_en_i 自动覆盖),
                // 留在 S_LOOKUP —— hit 稳态 1 包/拍。
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
                req_svpbmt_en_q <= svpbmt_en_i;
                state_q <= S_LOOKUP;
              end else begin
                // 响应已组合交付且无新请求 → 直接回 IDLE(不经 S_RESP)
                state_q <= S_IDLE;
              end
            end else begin
              // rsp 反压: 落寄存进 S_RESP(天然 skid, dec_en 一拍性/失效窗口问题随之消失)
              inst0_q <= cache_inst0_w;
              inst1_q <= cache_inst1_w;
              resp0_q <= cache_resp0_w;
              resp1_q <= cache_resp1_w;
              state_q <= S_RESP;
            end
          end else if (req_exec_pmp_fault_w) begin
            resp0_q <= RESP_ACCESS_FAULT;
            resp1_q <= RESP_ACCESS_FAULT;
            state_q <= S_RESP;
          end else if (paging_q && req_itlb_perm_fault_w) begin
            resp0_q <= RESP_PAGE_FAULT;
            resp1_q <= RESP_PAGE_FAULT;
            state_q <= S_RESP;
          end else if (paging_q && req_itlb_hit_w) begin
            paddr0_q <= req_itlb_paddr_w;
            resp0_q <= RESP_OK;
            if (same_fetch_page_w) begin
              paddr1_q <= req_itlb_paddr_w + 64'd4;
              resp1_q <= req_exec1_pmp_fault_w ? RESP_ACCESS_FAULT :
                                                  RESP_OK;
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
          end else if (paging_q) begin
            if (canonical_sv39(pc_q)) begin
              walk_second_q <= 1'b0;
              walk_level_q <= 2'd2;
              walk_ppn_q <= req_satp_q[43:0];
              state_q <= S_WALK_AR;
            end else begin
              resp0_q <= RESP_PAGE_FAULT;
              resp1_q <= RESP_PAGE_FAULT;
              state_q <= S_RESP;
            end
          end else begin
            resp1_q <= req_exec1_pmp_fault_w ? RESP_ACCESS_FAULT : RESP_OK;
            state_q <= ifu_axi_arready_i ? S_R0 : S_AR0;
          end
        end

        S_WALK_AR: begin
          // F9：PTE 读地址 PMP 违例 → 取指 access fault（非 page fault）。镜像 rresp≠OK 的
          // 跨页双路处理：second 页 walk 失败只标 resp1 并回去取第一页，否则两槽都 access fault。
          if (walk_pte_pmp_fault_w) begin
            if (walk_second_q) begin
              resp1_q <= RESP_ACCESS_FAULT;
              state_q <= S_AR0;
            end else begin
              resp0_q <= RESP_ACCESS_FAULT;
              resp1_q <= RESP_ACCESS_FAULT;
              state_q <= S_RESP;
            end
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
              if (walk_second_q) begin
                resp1_q <= RESP_ACCESS_FAULT;
                state_q <= S_AR0;
              end else begin
                resp0_q <= RESP_ACCESS_FAULT;
                resp1_q <= RESP_ACCESS_FAULT;
                state_q <= S_RESP;
              end
            end else if (pte_invalid(ifu_axi_rdata_i) ||
                         pte_reserved_fault(ifu_axi_rdata_i,
                                            req_svpbmt_en_q,
                                            walk_level_q) ||
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
              end else if (walk_leaf_exec_pmp_fault_w) begin
                if (walk_second_q) begin
                  resp1_q <= RESP_ACCESS_FAULT;
                  state_q <= S_AR0;
                end else begin
                  resp0_q <= RESP_ACCESS_FAULT;
                  resp1_q <= RESP_ACCESS_FAULT;
                  state_q <= S_RESP;
                end
              // HW A: 真权限+PMP 全过但 A=0 → 写回 PTE|A 后 re-walk 本级(读回 A=1 续原取指)。
              // walk_ppn_q/walk_level_q 保持不变 → walk_pte_addr_w 仍指向本 leaf PTE。
              // 置 A 后真 fault 已排除, 故不会与 fault 竞争(fault 分支在前, 优先)。
              end else if (exec_ad_update_needed(ifu_axi_rdata_i)) begin
                ad_pte_q <= ifu_axi_rdata_i | PTE_A_BIT;
                aw_done_q <= 1'b0;
                w_done_q <= 1'b0;
                state_q <= S_AD_UPDATE;
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
                  resp1_q <= walk_leaf_exec1_pmp_fault_w ?
                             RESP_ACCESS_FAULT : RESP_OK;
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

        S_AD_UPDATE: begin
          // 写回 PTE|A: 完成 AW/W + 吸收 B 后 re-walk 本级(walk_ppn_q/walk_level_q 未改,
          // 重读同一 leaf PTE 此时 A=1 → exec_ad_update_needed=0 → 走正常 leaf-OK 续流)。
          // mmu_flush 会打回 S_IDLE 丢写(A 更新幂等, re-fetch 重做), 不损正确性。
          if (ifu_ad_aw_fire_w) aw_done_q <= 1'b1;
          if (ifu_ad_w_fire_w) w_done_q <= 1'b1;
          if ((aw_done_q || ifu_ad_aw_fire_w) &&
              (w_done_q || ifu_ad_w_fire_w) && ifu_axi_bvalid_i) begin
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            if (ifu_axi_bresp_i == RESP_OK) begin
              state_q <= S_WALK_AR;
            end else begin
              // A 写失败(极罕见: PTE 落不可写区) → 取指 access fault, 避免 A=0 无限重试。
              if (walk_second_q) begin
                resp1_q <= RESP_ACCESS_FAULT;
                state_q <= S_AR0;
              end else begin
                resp0_q <= RESP_ACCESS_FAULT;
                resp1_q <= RESP_ACCESS_FAULT;
                state_q <= S_RESP;
              end
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
              req_svpbmt_en_q <= svpbmt_en_i;
              state_q <= S_LOOKUP;
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
