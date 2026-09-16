`include "define.v"
`include "tb_common.svh"

// IFU-ACCESS-G1 永久回归：两条变长指令的物理读取范围由真实长度
// N=L0+L1 决定。instruction read 必须按 2B halfword 递增发起；bridge 后接
// 真实 packet decoder，最终检查 RRESP 的 slot owner，并以 poison 证明 [N,8)
// 不得参与架构结果。PTE 的 ARSIZE/ARPROT 由独立 attrs TB 检查，本 TB 只把
// page walk 当翻译 reference model，避免属性 RED 污染 N>B 的 walk 矩阵。
module tb_ooo_fetch_access_footprint;
  reg clk;
  reg rst;
  reg mmu_flush;
  reg invalidate_valid;
  reg [`XLEN-1:0] invalidate_addr;
  reg [1:0] priv_mode;
  reg [`XLEN-1:0] satp;
  reg svpbmt_en;
  reg [`PMP_CFG_BUS_W-1:0] pmpcfg;
  reg [`PMP_ADDR_BUS_W-1:0] pmpaddr;
  reg fetch_req_valid;
  wire fetch_req_ready;
  reg [`XLEN-1:0] fetch_req_pc;
  wire fetch_rsp_valid;
  reg fetch_rsp_ready;
  wire [`INST_W-1:0] fetch_rsp_inst0;
  wire [1:0] fetch_rsp_resp0;
  wire [`INST_W-1:0] fetch_rsp_inst1;
  wire [1:0] fetch_rsp_resp1;
  wire [2:0] fetch_rsp_resp0_bytes;

  wire ifu_axi_arvalid;
  reg ifu_axi_arready;
  wire [`XLEN-1:0] ifu_axi_araddr;
  wire [2:0] ifu_axi_arsize;
  reg ifu_axi_rvalid;
  wire ifu_axi_rready;
  reg [`XLEN-1:0] ifu_axi_rdata;
  reg [1:0] ifu_axi_rresp;
  wire ifu_axi_awvalid;
  reg ifu_axi_awready;
  wire ifu_axi_wvalid;
  reg ifu_axi_wready;
  reg ifu_axi_bvalid;
  wire ifu_axi_bready;
  reg [1:0] ifu_axi_bresp;

  reg [`XLEN-1:0] rsp_pc;
  wire [`XLEN-1:0] dec0_pc;
  wire [`XLEN-1:0] dec0_next_pc;
  wire [`INST_W-1:0] dec0_inst;
  wire [1:0] dec0_resp;
  wire dec0_control_stop;
  wire [`XLEN-1:0] dec1_pc;
  wire [`XLEN-1:0] dec1_next_pc;
  wire [`INST_W-1:0] dec1_inst;
  wire [1:0] dec1_resp;
  wire dec1_control_stop;
  wire dec0_branch;
  wire [12:0] dec0_bimm;
  wire dec1_branch;
  wire [12:0] dec1_bimm;
  wire [`XLEN-1:0] packet_next_pc;

  localparam [1:0] RESP_OK = 2'b00;
  localparam [1:0] RESP_ACCESS_FAULT = 2'b01;
  localparam [1:0] AXI_SLVERR = 2'b10;
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8100_0000;
  localparam [`XLEN-1:0] L1_PT = 64'h0000_0000_8100_1000;
  localparam [`XLEN-1:0] L0_PT = 64'h0000_0000_8100_2000;
  localparam [`XLEN-1:0] FETCH_PA0 = 64'h0000_0000_8200_4000;
  localparam [`XLEN-1:0] FETCH_PA1 = 64'h0000_0000_8200_9000;
  localparam [`XLEN-1:0] PC_DIRECT = 64'h0000_0000_8000_1000;
  localparam [`XLEN-1:0] PC_PMP_ALIGNED = 64'h0000_0000_8000_2000;
  localparam [`XLEN-1:0] PC_PMP_HALF = 64'h0000_0000_8000_2002;
  localparam [`XLEN-1:0] PC_FFA = 64'h0000_0000_0000_4ffa;
  localparam [`XLEN-1:0] PC_FFC = 64'h0000_0000_0000_4ffc;
  localparam [`XLEN-1:0] PC_FFE = 64'h0000_0000_0000_4ffe;
  localparam [`XLEN-1:0] SATP_VALUE =
      64'h8000_0000_0000_0000 | (ROOT_PT >> 12);
  localparam [`XLEN-1:0] PTE_NONLEAF_FLAGS = 64'h001;
  localparam [`XLEN-1:0] PTE_USER_X_FLAGS = 64'h0df;
  localparam [`PMP_CFG_BUS_W-1:0] PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ALLOW_ALL_ADDR =
      {`PMP_ADDR_BUS_W{1'b1}};

  // 低地址在右：C/C=N4，C/U 与 U/C=N6，U/U=N8。
  localparam [`XLEN-1:0] STREAM_CC_A = 64'h4070_5013_0001_0001;
  localparam [`XLEN-1:0] STREAM_CC_B = 64'hdead_beef_0001_0001;
  localparam [`XLEN-1:0] STREAM_CU_A = 64'hbeef_0010_0093_0001;
  localparam [`XLEN-1:0] STREAM_CU_B = 64'hcafe_0010_0093_0001;
  localparam [`XLEN-1:0] STREAM_UC_A = 64'hbeef_0001_0010_0093;
  localparam [`XLEN-1:0] STREAM_UC_B = 64'hcafe_0001_0010_0093;
  localparam [`XLEN-1:0] STREAM_UU = 64'h0010_0113_0010_0093;

  OooFetchAxiBridge u_bridge (
    .clk(clk),
    .rst(rst),
    .mmu_flush_i(mmu_flush),
    .invalidate_valid_i(invalidate_valid),
    .invalidate_addr_i(invalidate_addr),
    .priv_mode_i(priv_mode),
    .satp_i(satp),
    .svpbmt_en_i(svpbmt_en),
    .pmpcfg_i(pmpcfg),
    .pmpaddr_i(pmpaddr),
    .fetch_req_valid_i(fetch_req_valid),
    .fetch_req_ready_o(fetch_req_ready),
    .fetch_req_pc_i(fetch_req_pc),
    .fetch_rsp_valid_o(fetch_rsp_valid),
    .fetch_rsp_ready_i(fetch_rsp_ready),
    .fetch_rsp_inst0_o(fetch_rsp_inst0),
    .fetch_rsp_resp0_o(fetch_rsp_resp0),
    .fetch_rsp_inst1_o(fetch_rsp_inst1),
    .fetch_rsp_resp1_o(fetch_rsp_resp1),
    .fetch_rsp_resp0_bytes_o(fetch_rsp_resp0_bytes),
    .ifu_axi_arvalid_o(ifu_axi_arvalid),
    .ifu_axi_arready_i(ifu_axi_arready),
    .ifu_axi_araddr_o(ifu_axi_araddr),
    .ifu_axi_arsize_o(ifu_axi_arsize),
    .ifu_axi_rvalid_i(ifu_axi_rvalid),
    .ifu_axi_rready_o(ifu_axi_rready),
    .ifu_axi_rdata_i(ifu_axi_rdata),
    .ifu_axi_rresp_i(ifu_axi_rresp),
    .ifu_axi_awvalid_o(ifu_axi_awvalid),
    .ifu_axi_awready_i(ifu_axi_awready),
    .ifu_axi_wvalid_o(ifu_axi_wvalid),
    .ifu_axi_wready_i(ifu_axi_wready),
    .ifu_axi_bvalid_i(ifu_axi_bvalid),
    .ifu_axi_bready_o(ifu_axi_bready),
    .ifu_axi_bresp_i(ifu_axi_bresp)
  );

  OooFetchPacketDecode u_decode (
    .rsp_pc_i(rsp_pc),
    .rsp_inst0_i(fetch_rsp_inst0),
    .rsp_resp0_i(fetch_rsp_resp0),
    .rsp_inst1_i(fetch_rsp_inst1),
    .rsp_resp1_i(fetch_rsp_resp1),
    .rsp_resp0_bytes_i(fetch_rsp_resp0_bytes),
    .dec0_pc_o(dec0_pc),
    .dec0_next_pc_o(dec0_next_pc),
    .dec0_inst_o(dec0_inst),
    .dec0_resp_o(dec0_resp),
    .dec0_control_stop_o(dec0_control_stop),
    .dec1_pc_o(dec1_pc),
    .dec1_next_pc_o(dec1_next_pc),
    .dec1_inst_o(dec1_inst),
    .dec1_resp_o(dec1_resp),
    .dec1_control_stop_o(dec1_control_stop),
    .dec0_branch_o(dec0_branch),
    .dec0_bimm_o(dec0_bimm),
    .dec1_branch_o(dec1_branch),
    .dec1_bimm_o(dec1_bimm),
    .packet_next_pc_o(packet_next_pc),
    .packet_raw_next_pc_o()
  );

  always #5 clk = ~clk;

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
    input [`XLEN-1:0] base;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      pte_addr = base + {{(`XLEN-12){1'b0}}, vpn_by_level(vaddr, level),
                         3'b000};
    end
  endfunction

  function [`XLEN-1:0] pte_for_page;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] flags;
    begin
      pte_for_page = ((paddr >> 12) << 10) | flags;
    end
  endfunction

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  reg case_paging_q;
  reg [`XLEN-1:0] case_pc_q;
  reg [`XLEN-1:0] case_stream_q;
  integer case_n_bytes_q;
  integer case_l0_bytes_q;
  integer case_boundary_q;
  integer case_fault_offset_q;
  reg [1:0] case_fault_rresp_q;

  integer fetch_ar_count_q;
  reg [`XLEN-1:0] fetch_ar_addr_q [0:7];
  reg [2:0] fetch_ar_size_q [0:7];
  reg second_walk_seen_q;
  reg fault_offset_seen_q;
  reg unexpected_ar_q;
  reg case_timeout_q;

  reg [`INST_W-1:0] cap_dec0_inst_q;
  reg [1:0] cap_dec0_resp_q;
  reg [`INST_W-1:0] cap_dec1_inst_q;
  reg [1:0] cap_dec1_resp_q;
  reg [`XLEN-1:0] cap_dec1_pc_q;
  reg [`XLEN-1:0] cap_packet_next_pc_q;
  reg [1:0] cap_raw_resp0_q;
  reg [1:0] cap_raw_resp1_q;
  reg [2:0] cap_raw_split_q;

  integer footprint_rows_q;
  integer footprint_fail_q;
  integer rresp_rows_q;
  integer rresp_fail_q;
  integer poison_rows_q;
  integer poison_fail_q;
  integer walk_rows_q;
  integer walk_fail_q;
  integer pmp_rows_q;
  integer pmp_fail_q;
  integer alignment_rows_q;
  integer alignment_fail_q;
  integer sequence_rows_q;
  integer sequence_fail_q;
  integer lifecycle_rows_q;
  integer lifecycle_fail_q;
  integer rresp_owner0_rows_q;
  integer rresp_owner1_rows_q;
  integer rresp_exokay_rows_q;
  integer rresp_slverr_rows_q;
  integer rresp_decerr_rows_q;
  integer pmp_owner0_rows_q;
  integer pmp_owner1_rows_q;

  reg success_side_effect_monitor_q;
  reg fault_side_effect_monitor_q;
  reg fault_frontier_seen_q;
  integer success_cache_fill_count_q;
  integer success_sram_write_count_q;
  integer fault_cache_fill_count_q;
  integer fault_sram_write_count_q;
  integer fault_younger_ar_count_q;

  always @(posedge clk) begin
    if (!rst && success_side_effect_monitor_q) begin
      if (u_bridge.fetch_cache_fill_valid_w === 1'b1)
        success_cache_fill_count_q <= success_cache_fill_count_q + 1;
      else if (u_bridge.fetch_cache_fill_valid_w !== 1'b0)
        success_cache_fill_count_q <= success_cache_fill_count_q + 1000;
      if (u_bridge.u_fetch_packet_cache.sram_we_w === 1'b1)
        success_sram_write_count_q <= success_sram_write_count_q + 1;
      else if (u_bridge.u_fetch_packet_cache.sram_we_w !== 1'b0)
        success_sram_write_count_q <= success_sram_write_count_q + 1000;
    end
    if (!rst && fault_side_effect_monitor_q) begin
      if (u_bridge.fetch_cache_fill_valid_w !== 1'b0)
        fault_cache_fill_count_q <= fault_cache_fill_count_q + 1;
      if (u_bridge.u_fetch_packet_cache.sram_we_w !== 1'b0)
        fault_sram_write_count_q <= fault_sram_write_count_q + 1;
      if (fault_frontier_seen_q && (ifu_axi_arvalid !== 1'b0))
        fault_younger_ar_count_q <= fault_younger_ar_count_q + 1;
    end
  end

  task automatic record_footprint;
    input [1023:0] what;
    input ok;
    begin
      footprint_rows_q = footprint_rows_q + 1;
      if (ok) begin
        $display("[ACCESS-G1-FOOTPRINT-PASS] %0s", what);
      end else begin
        footprint_fail_q = footprint_fail_q + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [ACCESS-G1-FOOTPRINT-RED] %0s", what);
      end
    end
  endtask

  task automatic record_rresp;
    input [1023:0] what;
    input ok;
    input integer fault_offset;
    input [1:0] source_rresp;
    input owner0;
    begin
      rresp_rows_q = rresp_rows_q + 1;
      if (owner0) rresp_owner0_rows_q = rresp_owner0_rows_q + 1;
      else rresp_owner1_rows_q = rresp_owner1_rows_q + 1;
      case (source_rresp)
        2'b01: rresp_exokay_rows_q = rresp_exokay_rows_q + 1;
        2'b10: rresp_slverr_rows_q = rresp_slverr_rows_q + 1;
        2'b11: rresp_decerr_rows_q = rresp_decerr_rows_q + 1;
        default: begin end
      endcase
      if (ok) begin
        $display("[ACCESS-G1-RRESP-PASS] %0s F=%0d source=%0b owner=%0s",
                 what, fault_offset, source_rresp, owner0 ? "L0" : "L1");
      end else begin
        rresp_fail_q = rresp_fail_q + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [ACCESS-G1-RRESP-RED] %0s F=%0d got=%0b/%0b",
                 what, fault_offset, cap_dec0_resp_q, cap_dec1_resp_q);
      end
    end
  endtask

  task automatic record_alignment;
    input [1023:0] what;
    input ok;
    begin
      alignment_rows_q = alignment_rows_q + 1;
      if (ok) begin
        $display("[ACCESS-G1-ALIGNMENT-PASS] %0s", what);
      end else begin
        alignment_fail_q = alignment_fail_q + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [ACCESS-G1-ALIGNMENT-RED] %0s", what);
      end
    end
  endtask

  task automatic record_sequence;
    input [1023:0] what;
    input ok;
    begin
      sequence_rows_q = sequence_rows_q + 1;
      if (ok) begin
        $display("[ACCESS-G1-SEQUENCE-PASS] %0s", what);
      end else begin
        sequence_fail_q = sequence_fail_q + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [ACCESS-G1-SEQUENCE-RED] %0s", what);
      end
    end
  endtask

  task automatic record_lifecycle;
    input [1023:0] what;
    input ok;
    begin
      lifecycle_rows_q = lifecycle_rows_q + 1;
      if (ok) begin
        $display("[ACCESS-G1-LIFECYCLE-PASS] %0s", what);
      end else begin
        lifecycle_fail_q = lifecycle_fail_q + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [ACCESS-G1-LIFECYCLE-RED] %0s", what);
      end
    end
  endtask

  task automatic record_poison;
    input [1023:0] what;
    input ok;
    begin
      poison_rows_q = poison_rows_q + 1;
      if (ok) begin
        $display("[ACCESS-G1-POISON-PASS] %0s", what);
      end else begin
        poison_fail_q = poison_fail_q + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [ACCESS-G1-POISON-RED] %0s", what);
      end
    end
  endtask

  task automatic record_walk;
    input [1023:0] what;
    input ok;
    input integer boundary;
    input integer n_bytes;
    begin
      walk_rows_q = walk_rows_q + 1;
      if (ok) begin
        $display("[ACCESS-G1-WALK-PASS] %0s B=%0d N=%0d second=%0b",
                 what, boundary, n_bytes, second_walk_seen_q);
      end else begin
        walk_fail_q = walk_fail_q + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [ACCESS-G1-WALK-RED] %0s B=%0d N=%0d second=%0b expected=%0b",
                 what, boundary, n_bytes, second_walk_seen_q,
                 n_bytes > boundary);
      end
    end
  endtask

  task automatic record_pmp;
    input [1023:0] what;
    input ok;
    begin
      pmp_rows_q = pmp_rows_q + 1;
      if (ok) begin
        $display("[ACCESS-G1-PMP-PASS] %0s", what);
      end else begin
        pmp_fail_q = pmp_fail_q + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [ACCESS-G1-PMP-RED] %0s raw=%0b/%0b split=%0d ar_count=%0d",
                 what, cap_raw_resp0_q, cap_raw_resp1_q,
                 cap_raw_split_q, fetch_ar_count_q);
      end
    end
  endtask

  task automatic reset_case;
    integer i;
    begin
      rst = 1'b1;
      mmu_flush = 1'b0;
      invalidate_valid = 1'b0;
      invalidate_addr = {`XLEN{1'b0}};
      priv_mode = case_paging_q ? `PRIV_U : `PRIV_M;
      satp = case_paging_q ? SATP_VALUE : {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      fetch_rsp_ready = 1'b0;
      ifu_axi_arready = 1'b1;
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      ifu_axi_rresp = RESP_OK;
      ifu_axi_awready = 1'b1;
      ifu_axi_wready = 1'b1;
      ifu_axi_bvalid = 1'b0;
      ifu_axi_bresp = RESP_OK;
      rsp_pc = case_pc_q;
      fetch_ar_count_q = 0;
      second_walk_seen_q = 1'b0;
      fault_offset_seen_q = 1'b0;
      unexpected_ar_q = 1'b0;
      case_timeout_q = 1'b0;
      case_fault_rresp_q = AXI_SLVERR;
      success_side_effect_monitor_q = 1'b0;
      fault_side_effect_monitor_q = 1'b0;
      fault_frontier_seen_q = 1'b0;
      success_cache_fill_count_q = 0;
      success_sram_write_count_q = 0;
      fault_cache_fill_count_q = 0;
      fault_sram_write_count_q = 0;
      fault_younger_ar_count_q = 0;
      for (i = 0; i < 8; i = i + 1) begin
        fetch_ar_addr_q[i] = {`XLEN{1'b0}};
        fetch_ar_size_q[i] = 3'd0;
      end
      repeat (3) tick();
      rst = 1'b0;
      tick();
    end
  endtask

  task automatic start_case;
    input paging;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] stream;
    input integer n_bytes;
    input integer l0_bytes;
    input integer boundary;
    input integer fault_offset;
    integer waits;
    begin
      case_paging_q = paging;
      case_pc_q = pc;
      case_stream_q = stream;
      case_n_bytes_q = n_bytes;
      case_l0_bytes_q = l0_bytes;
      case_boundary_q = boundary;
      case_fault_offset_q = fault_offset;
      reset_case();
      fetch_req_pc = pc;
      fetch_req_valid = 1'b1;
      waits = 0;
      while ((fetch_req_ready !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      if (fetch_req_ready !== 1'b1) begin
        case_timeout_q = 1'b1;
      end else begin
        tick();
      end
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
    end
  endtask

  // 服务真实 AR/R。PTE 地址来自三级 Sv39 reference map；instruction narrow read
  // 使用标准 AXI byte lane：DPI low-window 数据由 slave 放入 ARADDR[2:0] 对应 lane，
  // bridge 必须再按已锁存的物理地址抽取 16-bit halfword。
  task automatic service_until_response;
    integer cycles;
    integer rwaits;
    integer logical_offset;
    reg [`XLEN-1:0] araddr_v;
    reg [`XLEN-1:0] next_page_vaddr_v;
    reg [`XLEN-1:0] rdata_v;
    reg [15:0] halfword_v;
    reg [1:0] rresp_v;
    reg pte_read_v;
    begin
      cycles = 0;
      while ((fetch_rsp_valid !== 1'b1) && !case_timeout_q &&
             (cycles < 500)) begin
        if (ifu_axi_arvalid === 1'b1) begin
          araddr_v = ifu_axi_araddr;
          next_page_vaddr_v = {case_pc_q[`XLEN-1:12], 12'b0} + 64'd4096;
          rdata_v = {`XLEN{1'b0}};
          rresp_v = RESP_OK;
          pte_read_v = 1'b0;
          logical_offset = -1;

          if (case_paging_q &&
              ((araddr_v == pte_addr(ROOT_PT, case_pc_q, 2'd2)) ||
               (araddr_v == pte_addr(ROOT_PT, next_page_vaddr_v, 2'd2)))) begin
            pte_read_v = 1'b1;
            rdata_v = pte_for_page(L1_PT, PTE_NONLEAF_FLAGS);
          end else if (case_paging_q &&
                       ((araddr_v == pte_addr(L1_PT, case_pc_q, 2'd1)) ||
                        (araddr_v == pte_addr(L1_PT, next_page_vaddr_v,
                                              2'd1)))) begin
            pte_read_v = 1'b1;
            rdata_v = pte_for_page(L0_PT, PTE_NONLEAF_FLAGS);
          end else if (case_paging_q &&
                       (araddr_v == pte_addr(L0_PT, case_pc_q, 2'd0))) begin
            pte_read_v = 1'b1;
            rdata_v = pte_for_page(FETCH_PA0, PTE_USER_X_FLAGS);
          end else if (case_paging_q &&
                       (araddr_v == pte_addr(L0_PT, next_page_vaddr_v,
                                             2'd0))) begin
            pte_read_v = 1'b1;
            second_walk_seen_q = 1'b1;
            rdata_v = pte_for_page(FETCH_PA1, PTE_USER_X_FLAGS);
          end else if (!case_paging_q && (araddr_v >= case_pc_q) &&
                       (araddr_v < (case_pc_q + 64'd8))) begin
            logical_offset = araddr_v - case_pc_q;
          end else if (case_paging_q &&
                       (araddr_v >= (FETCH_PA0 + {52'd0,
                                                  case_pc_q[11:0]})) &&
                       (araddr_v < (FETCH_PA0 + 64'd4096))) begin
            logical_offset = araddr_v -
                             (FETCH_PA0 + {52'd0, case_pc_q[11:0]});
          end else if (case_paging_q && (araddr_v >= FETCH_PA1) &&
                       (araddr_v < (FETCH_PA1 + 64'd8))) begin
            logical_offset = case_boundary_q + (araddr_v - FETCH_PA1);
          end else begin
            unexpected_ar_q = 1'b1;
          end

          if (!pte_read_v && (logical_offset >= 0) &&
              (logical_offset < 8)) begin
            if (fetch_ar_count_q < 8) begin
              fetch_ar_addr_q[fetch_ar_count_q] = araddr_v;
              fetch_ar_size_q[fetch_ar_count_q] = ifu_axi_arsize;
            end
            fetch_ar_count_q = fetch_ar_count_q + 1;
            if (ifu_axi_arsize == 3'd1) begin
              halfword_v = (case_stream_q >> (logical_offset * 8));
              rdata_v = {{(`XLEN-16){1'b0}}, halfword_v} <<
                        ({61'd0, araddr_v[2:0]} * 8);
            end else begin
              // 旧 RTL 的 8B exact-address ABI 仅用于构造可信 RED 对照：返回完整
              // low-window，保证失败来自 size/count/owner，而不是测试模型故意毁数据。
              rdata_v = case_stream_q >> (logical_offset * 8);
            end
            if (logical_offset == case_fault_offset_q) begin
              rresp_v = case_fault_rresp_q;
              fault_offset_seen_q = 1'b1;
            end
          end

          tick();
          rwaits = 0;
          while ((ifu_axi_rready !== 1'b1) && (rwaits < 30)) begin
            tick();
            rwaits = rwaits + 1;
          end
          if (ifu_axi_rready !== 1'b1) begin
            case_timeout_q = 1'b1;
          end else begin
            ifu_axi_rdata = rdata_v;
            ifu_axi_rresp = rresp_v;
            ifu_axi_rvalid = 1'b1;
            if (rresp_v != RESP_OK) fault_frontier_seen_q = 1'b1;
            tick();
            ifu_axi_rvalid = 1'b0;
            ifu_axi_rdata = {`XLEN{1'b0}};
            ifu_axi_rresp = RESP_OK;
          end
        end else begin
          tick();
        end
        cycles = cycles + 1;
      end
      if (fetch_rsp_valid !== 1'b1) case_timeout_q = 1'b1;
    end
  endtask

  task automatic capture_and_consume_response;
    begin
      if (fetch_rsp_valid === 1'b1) begin
        cap_dec0_inst_q = dec0_inst;
        cap_dec0_resp_q = dec0_resp;
        cap_dec1_inst_q = dec1_inst;
        cap_dec1_resp_q = dec1_resp;
        cap_dec1_pc_q = dec1_pc;
        cap_packet_next_pc_q = packet_next_pc;
        cap_raw_resp0_q = fetch_rsp_resp0;
        cap_raw_resp1_q = fetch_rsp_resp1;
        cap_raw_split_q = fetch_rsp_resp0_bytes;
        fetch_rsp_ready = 1'b1;
        tick();
        fetch_rsp_ready = 1'b0;
      end else begin
        cap_dec0_inst_q = {`INST_W{1'bx}};
        cap_dec0_resp_q = 2'bxx;
        cap_dec1_inst_q = {`INST_W{1'bx}};
        cap_dec1_resp_q = 2'bxx;
        cap_dec1_pc_q = {`XLEN{1'bx}};
        cap_packet_next_pc_q = {`XLEN{1'bx}};
        cap_raw_resp0_q = 2'bxx;
        cap_raw_resp1_q = 2'bxx;
        cap_raw_split_q = 3'bxxx;
      end
    end
  endtask

  task automatic run_footprint_case;
    input [1023:0] what;
    input [`XLEN-1:0] stream;
    input integer n_bytes;
    input integer l0_bytes;
    integer i;
    integer exp_count;
    reg ok;
    begin
      start_case(1'b0, PC_DIRECT, stream, n_bytes, l0_bytes, 8, -1);
      success_side_effect_monitor_q = 1'b1;
      service_until_response();
      capture_and_consume_response();
      success_side_effect_monitor_q = 1'b0;
      exp_count = n_bytes / 2;
      ok = !case_timeout_q && !unexpected_ar_q &&
           (fetch_ar_count_q == exp_count) &&
           (success_cache_fill_count_q == 1) &&
           (success_sram_write_count_q == 1) &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_OK) &&
           (cap_raw_split_q == 3'd4) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK) &&
           (cap_dec1_pc_q == (PC_DIRECT + l0_bytes)) &&
           (cap_packet_next_pc_q == (PC_DIRECT + n_bytes));
      for (i = 0; i < exp_count; i = i + 1) begin
        if ((fetch_ar_addr_q[i] !== (PC_DIRECT + (i * 2))) ||
            (fetch_ar_size_q[i] !== 3'd1)) ok = 1'b0;
      end
      if (ok)
        $display("[ACCESS-G1-SUCCESS-SIDE-EFFECT] %0s cache_fill=1 sram_write=1 PASS",
                 what);
      record_footprint(what, ok);
    end
  endtask

  task automatic run_alignment_case;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] stream;
    input integer n_bytes;
    input integer l0_bytes;
    integer i;
    integer exp_count;
    reg ok;
    begin
      start_case(1'b0, pc, stream, n_bytes, l0_bytes, 8, -1);
      service_until_response();
      capture_and_consume_response();
      exp_count = n_bytes / 2;
      ok = !case_timeout_q && !unexpected_ar_q &&
           (fetch_ar_count_q == exp_count) &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_OK) &&
           (cap_raw_split_q == 3'd4) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK) &&
           (cap_dec1_pc_q == (pc + l0_bytes)) &&
           (cap_packet_next_pc_q == (pc + n_bytes));
      for (i = 0; i < exp_count; i = i + 1) begin
        if ((fetch_ar_addr_q[i] !== (pc + (i * 2))) ||
            (fetch_ar_addr_q[i][2:0] !== ((pc + (i * 2)) & 64'h7)) ||
            (fetch_ar_size_q[i] !== 3'd1)) ok = 1'b0;
      end
      record_alignment(what, ok);
    end
  endtask

  task automatic run_rresp_case;
    input [1023:0] what;
    input [`XLEN-1:0] stream;
    input integer n_bytes;
    input integer l0_bytes;
    input integer fault_offset;
    input [1:0] source_rresp;
    integer i;
    integer exp_count;
    reg [1:0] exp0;
    reg [1:0] exp1;
    reg ok;
    begin
      start_case(1'b0, PC_DIRECT, stream, n_bytes, l0_bytes, 8,
                 fault_offset);
      case_fault_rresp_q = source_rresp;
      fault_side_effect_monitor_q = 1'b1;
      service_until_response();
      capture_and_consume_response();
      repeat (2) tick();
      fault_side_effect_monitor_q = 1'b0;
      exp0 = (fault_offset < l0_bytes) ? RESP_ACCESS_FAULT : RESP_OK;
      exp1 = RESP_ACCESS_FAULT;
      exp_count = (fault_offset / 2) + 1;
      ok = !case_timeout_q && !unexpected_ar_q && fault_offset_seen_q &&
           (fetch_ar_count_q == exp_count) &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_ACCESS_FAULT) &&
           (cap_raw_split_q == fault_offset[2:0]) &&
           (cap_dec0_resp_q == exp0) && (cap_dec1_resp_q == exp1) &&
           (fault_cache_fill_count_q == 0) &&
           (fault_sram_write_count_q == 0) &&
           (fault_younger_ar_count_q == 0) &&
           (ifu_axi_arvalid === 1'b0);
      for (i = 0; i < exp_count; i = i + 1) begin
        if ((fetch_ar_addr_q[i] !== (PC_DIRECT + (i * 2))) ||
            (fetch_ar_size_q[i] !== 3'd1)) ok = 1'b0;
      end
      if ((cap_dec0_resp_q == exp0) && (cap_dec1_resp_q == exp1))
        $display("[ACCESS-G1-RRESP-OWNER-CONTROL-PASS] %0s F=%0d source=%0b owner=%0s fill=0 write=0 younger_ar=0 quiet=2",
                 what, fault_offset, source_rresp,
                 (fault_offset < l0_bytes) ? "L0" : "L1");
      record_rresp(what, ok, fault_offset, source_rresp,
                   fault_offset < l0_bytes);
    end
  endtask

  task automatic run_rresp_source_matrix;
    input [1:0] source_rresp;
    begin
      run_rresp_case("C/C", STREAM_CC_A, 4, 2, 0, source_rresp);
      run_rresp_case("C/C", STREAM_CC_A, 4, 2, 2, source_rresp);
      run_rresp_case("C/U", STREAM_CU_A, 6, 2, 0, source_rresp);
      run_rresp_case("C/U", STREAM_CU_A, 6, 2, 2, source_rresp);
      run_rresp_case("C/U", STREAM_CU_A, 6, 2, 4, source_rresp);
      run_rresp_case("U/C", STREAM_UC_A, 6, 4, 0, source_rresp);
      run_rresp_case("U/C", STREAM_UC_A, 6, 4, 2, source_rresp);
      run_rresp_case("U/C", STREAM_UC_A, 6, 4, 4, source_rresp);
      run_rresp_case("U/U", STREAM_UU, 8, 4, 0, source_rresp);
      run_rresp_case("U/U", STREAM_UU, 8, 4, 2, source_rresp);
      run_rresp_case("U/U", STREAM_UU, 8, 4, 4, source_rresp);
      run_rresp_case("U/U", STREAM_UU, 8, 4, 6, source_rresp);
    end
  endtask

  task automatic run_rresp_valid_gate_case;
    integer waits;
    reg [`XLEN-1:0] rdata_v;
    reg ok;
    begin
      start_case(1'b0, PC_DIRECT, STREAM_CC_A, 4, 2, 8, -1);
      ok = 1'b1;
      waits = 0;
      while ((ifu_axi_arvalid !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      ok = ok && (ifu_axi_arvalid === 1'b1) &&
           (ifu_axi_araddr === PC_DIRECT) && (ifu_axi_arsize === 3'd1);
      tick();

      // RRESP 在 RVALID=0 时不属于任何完成事务；同时 bridge 保持单 outstanding，
      // younger offset2 不能提前形成 AR owner。
      ifu_axi_rresp = 2'b11;
      repeat (2) begin
        tick();
        ok = ok && (fetch_rsp_valid === 1'b0) &&
             (ifu_axi_arvalid === 1'b0) &&
             (u_bridge.fetch_cache_fill_valid_w === 1'b0) &&
             (u_bridge.u_fetch_packet_cache.sram_we_w === 1'b0);
      end
      rdata_v = {{(`XLEN-16){1'b0}}, STREAM_CC_A[15:0]} <<
                ({61'd0, PC_DIRECT[2:0]} * 8);
      ifu_axi_rdata = rdata_v;
      ifu_axi_rresp = RESP_OK;
      ifu_axi_rvalid = 1'b1;
      tick();
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};

      waits = 0;
      while ((ifu_axi_arvalid !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      ok = ok && (ifu_axi_arvalid === 1'b1) &&
           (ifu_axi_araddr === (PC_DIRECT + 64'd2)) &&
           (ifu_axi_arsize === 3'd1);
      tick();
      rdata_v = {{(`XLEN-16){1'b0}}, STREAM_CC_A[31:16]} <<
                ({61'd0, (PC_DIRECT[2:0] + 3'd2)} * 8);
      ifu_axi_rdata = rdata_v;
      ifu_axi_rresp = RESP_OK;
      ifu_axi_rvalid = 1'b1;
      tick();
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      ifu_axi_rresp = RESP_OK;

      waits = 0;
      while ((fetch_rsp_valid !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      capture_and_consume_response();
      ok = ok && !case_timeout_q &&
           (cap_dec0_resp_q == RESP_OK) &&
           (cap_dec1_resp_q == RESP_OK) &&
           (cap_packet_next_pc_q == (PC_DIRECT + 64'd4));
      if (ok)
        $display("[ACCESS-G1-RRESP-VALID-GATE] invalid_cycles=2 outstanding=1 younger_ar=0 source_ignored=DECERR PASS");
      record_lifecycle("RRESP is sampled only on RVALID/RREADY and one halfword is outstanding", ok);
    end
  endtask

  task automatic run_poison_pair;
    input [1023:0] what;
    input [`XLEN-1:0] stream_a;
    input [`XLEN-1:0] stream_b;
    input integer n_bytes;
    input integer l0_bytes;
    reg [`INST_W-1:0] a_dec0_inst;
    reg [1:0] a_dec0_resp;
    reg [`INST_W-1:0] a_dec1_inst;
    reg [1:0] a_dec1_resp;
    reg [`XLEN-1:0] a_dec1_pc;
    reg [`XLEN-1:0] a_next_pc;
    reg [1:0] a_raw_resp0;
    reg [1:0] a_raw_resp1;
    reg [2:0] a_raw_split;
    reg timeout_a;
    reg ok;
    begin
      start_case(1'b0, PC_DIRECT, stream_a, n_bytes, l0_bytes, 8, -1);
      service_until_response();
      capture_and_consume_response();
      a_dec0_inst = cap_dec0_inst_q;
      a_dec0_resp = cap_dec0_resp_q;
      a_dec1_inst = cap_dec1_inst_q;
      a_dec1_resp = cap_dec1_resp_q;
      a_dec1_pc = cap_dec1_pc_q;
      a_next_pc = cap_packet_next_pc_q;
      a_raw_resp0 = cap_raw_resp0_q;
      a_raw_resp1 = cap_raw_resp1_q;
      a_raw_split = cap_raw_split_q;
      timeout_a = case_timeout_q || unexpected_ar_q;

      start_case(1'b0, PC_DIRECT, stream_b, n_bytes, l0_bytes, 8, -1);
      service_until_response();
      capture_and_consume_response();
      ok = !timeout_a && !case_timeout_q && !unexpected_ar_q &&
           (a_dec0_inst == cap_dec0_inst_q) &&
           (a_dec0_resp == cap_dec0_resp_q) &&
           (a_dec1_inst == cap_dec1_inst_q) &&
           (a_dec1_resp == cap_dec1_resp_q) &&
           (a_dec1_pc == cap_dec1_pc_q) &&
           (a_next_pc == cap_packet_next_pc_q) &&
           (a_raw_resp0 == RESP_OK) && (a_raw_resp1 == RESP_OK) &&
           (a_raw_split == 3'd4) &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_OK) &&
           (cap_raw_split_q == 3'd4) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK) &&
           (cap_dec1_pc_q == (PC_DIRECT + l0_bytes)) &&
           (cap_packet_next_pc_q == (PC_DIRECT + n_bytes));
      record_poison(what, ok);
    end
  endtask

  task automatic run_poison_empty_control;
    reg ok;
    begin
      start_case(1'b0, PC_DIRECT, STREAM_UU, 8, 4, 8, -1);
      service_until_response();
      capture_and_consume_response();
      ok = !case_timeout_q && !unexpected_ar_q &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_OK) &&
           (cap_raw_split_q == 3'd4) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK) &&
           (cap_dec1_pc_q == (PC_DIRECT + 4)) &&
           (cap_packet_next_pc_q == (PC_DIRECT + 8));
      record_poison("U/U N=8 has empty poison suffix", ok);
    end
  endtask

  task automatic run_walk_case;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] stream;
    input integer n_bytes;
    input integer l0_bytes;
    input integer boundary;
    integer i;
    integer exp_count;
    integer second_data_count;
    reg [`XLEN-1:0] exp_addr;
    reg ok;
    begin
      start_case(1'b1, pc, stream, n_bytes, l0_bytes, boundary, -1);
      service_until_response();
      capture_and_consume_response();
      exp_count = n_bytes / 2;
      second_data_count = 0;
      ok = !case_timeout_q && !unexpected_ar_q &&
           (second_walk_seen_q == (n_bytes > boundary)) &&
           (fetch_ar_count_q == exp_count) &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_OK) &&
           (cap_raw_split_q == 3'd4) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK) &&
           (cap_dec1_pc_q == (pc + l0_bytes)) &&
           (cap_packet_next_pc_q == (pc + n_bytes));
      for (i = 0; i < exp_count; i = i + 1) begin
        if ((i * 2) < boundary) begin
          exp_addr = FETCH_PA0 + {52'd0, pc[11:0]} + (i * 2);
        end else begin
          exp_addr = FETCH_PA1 + ((i * 2) - boundary);
          second_data_count = second_data_count + 1;
        end
        if ((fetch_ar_addr_q[i] !== exp_addr) ||
            (fetch_ar_size_q[i] !== 3'd1)) ok = 1'b0;
      end
      if (second_data_count != ((n_bytes > boundary) ?
          ((n_bytes - boundary) / 2) : 0)) ok = 1'b0;
      if (second_walk_seen_q == (n_bytes > boundary))
        $display("[ACCESS-G1-WALK-PRESENCE-CONTROL-PASS] %0s B=%0d N=%0d",
                 what, boundary, n_bytes);
      record_walk(what, ok, boundary, n_bytes);
    end
  endtask

  task automatic clear_access_observation;
    integer i;
    begin
      fetch_ar_count_q = 0;
      second_walk_seen_q = 1'b0;
      fault_offset_seen_q = 1'b0;
      unexpected_ar_q = 1'b0;
      case_timeout_q = 1'b0;
      for (i = 0; i < 8; i = i + 1) begin
        fetch_ar_addr_q[i] = {`XLEN{1'b0}};
        fetch_ar_size_q[i] = 3'd0;
      end
    end
  endtask

  task automatic issue_request_without_reset;
    input [`XLEN-1:0] pc;
    integer waits;
    begin
      fetch_req_pc = pc;
      fetch_req_valid = 1'b1;
      waits = 0;
      while ((fetch_req_ready !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      if (fetch_req_ready !== 1'b1) begin
        case_timeout_q = 1'b1;
      end else begin
        tick();
      end
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
    end
  endtask

  task automatic configure_tor_exec_until;
    input [`XLEN-1:0] upper_exclusive;
    begin
      pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
      // entry0 TOR + X：S-mode 对 [0,upper) 可执行，upper 起 default-deny。
      pmpcfg[0 +: `PMP_CFG_ENTRY_W] = 8'h0c;
      pmpaddr[0 +: `XLEN] = upper_exclusive >> 2;
    end
  endtask

  task automatic run_pmp_frontier_case;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] stream;
    input integer n_bytes;
    input integer l0_bytes;
    input integer fault_offset;
    integer i;
    integer exp_count;
    reg [1:0] exp_dec0;
    reg ok;
    begin
      case_paging_q = 1'b0;
      case_pc_q = pc;
      case_stream_q = stream;
      case_n_bytes_q = n_bytes;
      case_l0_bytes_q = l0_bytes;
      case_boundary_q = 8;
      case_fault_offset_q = -1;
      reset_case();
      priv_mode = `PRIV_S;
      satp = {`XLEN{1'b0}};
      configure_tor_exec_until(pc + fault_offset);
      issue_request_without_reset(pc);
      service_until_response();
      capture_and_consume_response();

      exp_count = fault_offset / 2;
      exp_dec0 = (fault_offset < l0_bytes) ? RESP_ACCESS_FAULT : RESP_OK;
      ok = !case_timeout_q && !unexpected_ar_q &&
           (fetch_ar_count_q == exp_count) &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_ACCESS_FAULT) &&
           (cap_raw_split_q == fault_offset[2:0]) &&
           (cap_dec0_resp_q == exp_dec0) &&
           (cap_dec1_resp_q == RESP_ACCESS_FAULT);
      for (i = 0; i < exp_count; i = i + 1) begin
        if ((fetch_ar_addr_q[i] !== (pc + (i * 2))) ||
            (fetch_ar_size_q[i] !== 3'd1)) ok = 1'b0;
      end
      if ((cap_dec0_resp_q == exp_dec0) &&
          (cap_dec1_resp_q == RESP_ACCESS_FAULT)) begin
        $display("[ACCESS-G1-PMP-OWNER-CONTROL-PASS] %0s F=%0d owner=%0s younger_ar=0",
                 what, fault_offset,
                 (fault_offset < l0_bytes) ? "L0" : "L1");
      end
      if (fault_offset < l0_bytes)
        pmp_owner0_rows_q = pmp_owner0_rows_q + 1;
      else
        pmp_owner1_rows_q = pmp_owner1_rows_q + 1;
      record_pmp(what, ok);
    end
  endtask

  task automatic run_pmp_cached_default_deny;
    reg fill_ok;
    reg ok;
    begin
      case_paging_q = 1'b0;
      case_pc_q = PC_PMP_ALIGNED;
      case_stream_q = STREAM_CC_A;
      case_n_bytes_q = 4;
      case_l0_bytes_q = 2;
      case_boundary_q = 8;
      case_fault_offset_q = -1;
      reset_case();

      // M-mode 无匹配默认允许，先把 bare packet 填入 cache。
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
      issue_request_without_reset(PC_PMP_ALIGNED);
      service_until_response();
      capture_and_consume_response();
      fill_ok = !case_timeout_q && !unexpected_ar_q &&
                (fetch_ar_count_q == 2) &&
                (cap_raw_resp0_q == RESP_OK) &&
                (cap_raw_resp1_q == RESP_OK) &&
                (cap_raw_split_q == 3'd4);

      // cache 不清，切到 S-mode + pmpcfg=0；raw hit 必须降级并在 F=0 fault。
      clear_access_observation();
      priv_mode = `PRIV_S;
      issue_request_without_reset(PC_PMP_ALIGNED);
      service_until_response();
      capture_and_consume_response();
      ok = fill_ok && !case_timeout_q && !unexpected_ar_q &&
           (fetch_ar_count_q == 0) &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_ACCESS_FAULT) &&
           (cap_raw_split_q == 3'd0) &&
           (cap_dec0_resp_q == RESP_ACCESS_FAULT) &&
           (cap_dec1_resp_q == RESP_ACCESS_FAULT);
      record_pmp("M-fill then S/no-PMP cache hit default-denies at F=0", ok);
    end
  endtask

  task automatic run_pmp_fixed_reject_exact_ok;
    reg fill_ok;
    reg ok;
    begin
      case_paging_q = 1'b0;
      case_pc_q = PC_PMP_ALIGNED;
      case_stream_q = STREAM_CC_A;
      case_n_bytes_q = 4;
      case_l0_bytes_q = 2;
      case_boundary_q = 8;
      case_fault_offset_q = -1;
      reset_case();
      priv_mode = `PRIV_S;
      satp = {`XLEN{1'b0}};
      // 只允许真实 C/C 的前 4B；固定第二个 4B checker 必拒绝。
      configure_tor_exec_until(PC_PMP_ALIGNED + 64'd4);
      issue_request_without_reset(PC_PMP_ALIGNED);
      service_until_response();
      capture_and_consume_response();
      fill_ok = !case_timeout_q && !unexpected_ar_q &&
                (fetch_ar_count_q == 2) &&
                (cap_raw_resp0_q == RESP_OK) &&
                (cap_raw_resp1_q == RESP_OK) &&
                (cap_raw_split_q == 3'd4);

      clear_access_observation();
      issue_request_without_reset(PC_PMP_ALIGNED);
      service_until_response();
      capture_and_consume_response();
      ok = fill_ok && !case_timeout_q && !unexpected_ar_q &&
           // raw hit conservative reject 必须精确重读 0/2，而不是快返或架构 fault。
           (fetch_ar_count_q == 2) &&
           (fetch_ar_addr_q[0] == PC_PMP_ALIGNED) &&
           (fetch_ar_addr_q[1] == (PC_PMP_ALIGNED + 64'd2)) &&
           (fetch_ar_size_q[0] == 3'd1) && (fetch_ar_size_q[1] == 3'd1) &&
           (cap_raw_resp0_q == RESP_OK) &&
           (cap_raw_resp1_q == RESP_OK) &&
           (cap_raw_split_q == 3'd4) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK);
      record_pmp("fixed-window reject falls back to exact C/C slow path", ok);
    end
  endtask

  task automatic run_dual_source_program_order;
    reg younger_pmp_control_ok;
    reg older_rresp_ok;
    begin
      case_paging_q = 1'b0;
      case_pc_q = PC_PMP_HALF;
      case_stream_q = STREAM_UU;
      case_n_bytes_q = 8;
      case_l0_bytes_q = 4;
      case_boundary_q = 8;
      case_fault_offset_q = -1;
      reset_case();
      priv_mode = `PRIV_S;
      satp = {`XLEN{1'b0}};
      configure_tor_exec_until(PC_PMP_HALF + 64'd2);
      issue_request_without_reset(PC_PMP_HALF);
      service_until_response();
      capture_and_consume_response();
      younger_pmp_control_ok = !case_timeout_q && !unexpected_ar_q &&
          (fetch_ar_count_q == 1) &&
          (cap_raw_split_q == 3'd2) &&
          (cap_dec0_resp_q == RESP_ACCESS_FAULT) &&
          (cap_dec1_resp_q == RESP_ACCESS_FAULT);

      case_fault_offset_q = 0;
      reset_case();
      priv_mode = `PRIV_S;
      satp = {`XLEN{1'b0}};
      configure_tor_exec_until(PC_PMP_HALF + 64'd2);
      case_fault_rresp_q = 2'b11;
      fault_side_effect_monitor_q = 1'b1;
      issue_request_without_reset(PC_PMP_HALF);
      service_until_response();
      capture_and_consume_response();
      repeat (2) tick();
      fault_side_effect_monitor_q = 1'b0;
      older_rresp_ok = !case_timeout_q && !unexpected_ar_q &&
          fault_offset_seen_q &&
          (fetch_ar_count_q == 1) &&
          (cap_raw_split_q == 3'd0) &&
          (cap_dec0_resp_q == RESP_ACCESS_FAULT) &&
          (cap_dec1_resp_q == RESP_ACCESS_FAULT) &&
          (fault_cache_fill_count_q == 0) &&
          (fault_sram_write_count_q == 0) &&
          (fault_younger_ar_count_q == 0);
      if (younger_pmp_control_ok && older_rresp_ok)
        $display("[ACCESS-G1-DUAL-SOURCE-ORDER] control=PMP@F2 older=DECERR@F0 result=F0 outstanding=1 younger_ar=0 PASS");
      record_lifecycle("older RRESP F0 wins before configured younger PMP F2", younger_pmp_control_ok && older_rresp_ok);
    end
  endtask

  task automatic run_back_to_back_no_reset;
    reg ok;
    begin
      // A: 带任意未使用 tail 的 C/C success。
      start_case(1'b0, PC_DIRECT + 64'h100, STREAM_CC_B, 4, 2, 8, -1);
      service_until_response();
      capture_and_consume_response();
      ok = !case_timeout_q && !unexpected_ar_q &&
           (fetch_ar_count_q == 2) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK);

      // B: 不复位的 U/U success，形成 poison-success 后继。
      clear_access_observation();
      case_pc_q = PC_DIRECT + 64'h120;
      case_stream_q = STREAM_UU;
      case_n_bytes_q = 8;
      case_l0_bytes_q = 4;
      case_boundary_q = 8;
      case_fault_offset_q = -1;
      case_fault_rresp_q = AXI_SLVERR;
      rsp_pc = case_pc_q;
      issue_request_without_reset(case_pc_q);
      service_until_response();
      capture_and_consume_response();
      ok = ok && !case_timeout_q && !unexpected_ar_q &&
           (fetch_ar_count_q == 4) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK);

      // C: 不复位的 U/U F4 error，形成 success-fault 后继。
      clear_access_observation();
      case_pc_q = PC_DIRECT + 64'h140;
      case_stream_q = STREAM_UU;
      case_n_bytes_q = 8;
      case_l0_bytes_q = 4;
      case_fault_offset_q = 4;
      case_fault_rresp_q = 2'b11;
      rsp_pc = case_pc_q;
      issue_request_without_reset(case_pc_q);
      service_until_response();
      capture_and_consume_response();
      ok = ok && !case_timeout_q && !unexpected_ar_q &&
           (fetch_ar_count_q == 3) &&
           (cap_raw_split_q == 3'd4) &&
           (cap_dec0_resp_q == RESP_OK) &&
           (cap_dec1_resp_q == RESP_ACCESS_FAULT);

      // D: 不复位的 C/C success，证明 fault owner/frontier 已清理。
      clear_access_observation();
      case_pc_q = PC_DIRECT + 64'h160;
      case_stream_q = STREAM_CC_A;
      case_n_bytes_q = 4;
      case_l0_bytes_q = 2;
      case_fault_offset_q = -1;
      case_fault_rresp_q = AXI_SLVERR;
      rsp_pc = case_pc_q;
      issue_request_without_reset(case_pc_q);
      service_until_response();
      capture_and_consume_response();
      ok = ok && !case_timeout_q && !unexpected_ar_q &&
           (fetch_ar_count_q == 2) &&
           (cap_raw_split_q == 3'd4) &&
           (cap_dec0_resp_q == RESP_OK) && (cap_dec1_resp_q == RESP_OK);
      if (ok)
        $display("[ACCESS-G1-BACK-TO-BACK] packets=4 reset_between=0 poison_success=1 success_fault=1 fault_success=1 PASS");
      record_sequence("four packets preserve and clear access owner state without reset", ok);
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    footprint_rows_q = 0;
    footprint_fail_q = 0;
    rresp_rows_q = 0;
    rresp_fail_q = 0;
    poison_rows_q = 0;
    poison_fail_q = 0;
    walk_rows_q = 0;
    walk_fail_q = 0;
    pmp_rows_q = 0;
    pmp_fail_q = 0;
    alignment_rows_q = 0;
    alignment_fail_q = 0;
    sequence_rows_q = 0;
    sequence_fail_q = 0;
    lifecycle_rows_q = 0;
    lifecycle_fail_q = 0;
    rresp_owner0_rows_q = 0;
    rresp_owner1_rows_q = 0;
    rresp_exokay_rows_q = 0;
    rresp_slverr_rows_q = 0;
    rresp_decerr_rows_q = 0;
    pmp_owner0_rows_q = 0;
    pmp_owner1_rows_q = 0;
    success_side_effect_monitor_q = 1'b0;
    fault_side_effect_monitor_q = 1'b0;
    fault_frontier_seen_q = 1'b0;

    run_footprint_case("C/C offsets={0,2} ARSIZE=2B", STREAM_CC_A, 4, 2);
    run_footprint_case("C/U offsets={0,2,4} ARSIZE=2B", STREAM_CU_A, 6, 2);
    run_footprint_case("U/C offsets={0,2,4} ARSIZE=2B", STREAM_UC_A, 6, 4);
    run_footprint_case("U/U offsets={0,2,4,6} ARSIZE=2B", STREAM_UU, 8, 4);

    run_poison_pair("C/C poison[4,8) invariant", STREAM_CC_A, STREAM_CC_B,
                    4, 2);
    run_poison_pair("C/U poison[6,8) invariant", STREAM_CU_A, STREAM_CU_B,
                    6, 2);
    run_poison_pair("U/C poison[6,8) invariant", STREAM_UC_A, STREAM_UC_B,
                    6, 4);
    run_poison_empty_control();

    // PC beat-lane 0/2/4/6 × C/C、C/U、U/C、U/U，覆盖跨 8B lane 回卷。
    run_alignment_case("A0 C/C", PC_DIRECT + 64'd0, STREAM_CC_A, 4, 2);
    run_alignment_case("A0 C/U", PC_DIRECT + 64'd0, STREAM_CU_A, 6, 2);
    run_alignment_case("A0 U/C", PC_DIRECT + 64'd0, STREAM_UC_A, 6, 4);
    run_alignment_case("A0 U/U", PC_DIRECT + 64'd0, STREAM_UU, 8, 4);
    run_alignment_case("A2 C/C", PC_DIRECT + 64'd2, STREAM_CC_A, 4, 2);
    run_alignment_case("A2 C/U", PC_DIRECT + 64'd2, STREAM_CU_A, 6, 2);
    run_alignment_case("A2 U/C", PC_DIRECT + 64'd2, STREAM_UC_A, 6, 4);
    run_alignment_case("A2 U/U", PC_DIRECT + 64'd2, STREAM_UU, 8, 4);
    run_alignment_case("A4 C/C", PC_DIRECT + 64'd4, STREAM_CC_A, 4, 2);
    run_alignment_case("A4 C/U", PC_DIRECT + 64'd4, STREAM_CU_A, 6, 2);
    run_alignment_case("A4 U/C", PC_DIRECT + 64'd4, STREAM_UC_A, 6, 4);
    run_alignment_case("A4 U/U", PC_DIRECT + 64'd4, STREAM_UU, 8, 4);
    run_alignment_case("A6 C/C", PC_DIRECT + 64'd6, STREAM_CC_A, 4, 2);
    run_alignment_case("A6 C/U", PC_DIRECT + 64'd6, STREAM_CU_A, 6, 2);
    run_alignment_case("A6 U/C", PC_DIRECT + 64'd6, STREAM_UC_A, 6, 4);
    run_alignment_case("A6 U/U", PC_DIRECT + 64'd6, STREAM_UU, 8, 4);

    // F0/F2/F4/F6 与每个真实 instruction halfword，分别激活三种非 OK RRESP。
    run_rresp_source_matrix(2'b01);
    run_rresp_source_matrix(2'b10);
    run_rresp_source_matrix(2'b11);
    run_rresp_valid_gate_case();

    // B=2/4/6 × N=4/6/8：只有 N>B 才允许第二页 L0 walk。
    run_walk_case("B2 C/C", PC_FFE, STREAM_CC_A, 4, 2, 2);
    run_walk_case("B2 C/U", PC_FFE, STREAM_CU_A, 6, 2, 2);
    run_walk_case("B2 U/C", PC_FFE, STREAM_UC_A, 6, 4, 2);
    run_walk_case("B2 U/U", PC_FFE, STREAM_UU, 8, 4, 2);
    run_walk_case("B4 C/C", PC_FFC, STREAM_CC_A, 4, 2, 4);
    run_walk_case("B4 C/U", PC_FFC, STREAM_CU_A, 6, 2, 4);
    run_walk_case("B4 U/C", PC_FFC, STREAM_UC_A, 6, 4, 4);
    run_walk_case("B4 U/U", PC_FFC, STREAM_UU, 8, 4, 4);
    run_walk_case("B6 C/C", PC_FFA, STREAM_CC_A, 4, 2, 6);
    run_walk_case("B6 C/U", PC_FFA, STREAM_CU_A, 6, 2, 6);
    run_walk_case("B6 U/C", PC_FFA, STREAM_UC_A, 6, 4, 6);
    run_walk_case("B6 U/U", PC_FFA, STREAM_UU, 8, 4, 6);

    run_pmp_frontier_case("PMP C/C F=0", PC_PMP_ALIGNED,
                          STREAM_CC_A, 4, 2, 0);
    run_pmp_frontier_case("PMP C/C F=2", PC_PMP_HALF,
                          STREAM_CC_A, 4, 2, 2);
    run_pmp_frontier_case("PMP C/U F=0", PC_PMP_ALIGNED,
                          STREAM_CU_A, 6, 2, 0);
    run_pmp_frontier_case("PMP C/U F=2", PC_PMP_HALF,
                          STREAM_CU_A, 6, 2, 2);
    run_pmp_frontier_case("PMP C/U F=4", PC_PMP_ALIGNED,
                          STREAM_CU_A, 6, 2, 4);
    run_pmp_frontier_case("PMP U/C F=0", PC_PMP_ALIGNED,
                          STREAM_UC_A, 6, 4, 0);
    run_pmp_frontier_case("PMP U/C F=2", PC_PMP_HALF,
                          STREAM_UC_A, 6, 4, 2);
    run_pmp_frontier_case("PMP U/C F=4", PC_PMP_ALIGNED,
                          STREAM_UC_A, 6, 4, 4);
    run_pmp_frontier_case("PMP U/U F=0", PC_PMP_ALIGNED,
                          STREAM_UU, 8, 4, 0);
    run_pmp_frontier_case("PMP U/U F=2", PC_PMP_HALF,
                          STREAM_UU, 8, 4, 2);
    run_pmp_frontier_case("PMP U/U F=4", PC_PMP_ALIGNED,
                          STREAM_UU, 8, 4, 4);
    run_pmp_frontier_case("PMP U/U F=6", PC_PMP_HALF,
                          STREAM_UU, 8, 4, 6);
    run_pmp_cached_default_deny();
    run_pmp_fixed_reject_exact_ok();
    run_dual_source_program_order();
    run_back_to_back_no_reset();

    $display("[ACCESS-G1-SUMMARY] footprint rows=%0d fail=%0d",
             footprint_rows_q, footprint_fail_q);
    $display("[ACCESS-G1-SUMMARY] poison rows=%0d fail=%0d",
             poison_rows_q, poison_fail_q);
    $display("[ACCESS-G1-SUMMARY] rresp rows=%0d fail=%0d",
             rresp_rows_q, rresp_fail_q);
    $display("[ACCESS-G1-SUMMARY] walk rows=%0d fail=%0d",
             walk_rows_q, walk_fail_q);
    $display("[ACCESS-G1-SUMMARY] pmp rows=%0d fail=%0d",
             pmp_rows_q, pmp_fail_q);
    $display("[ACCESS-G1-SUMMARY] alignment rows=%0d fail=%0d",
             alignment_rows_q, alignment_fail_q);
    $display("[ACCESS-G1-SUMMARY] lifecycle rows=%0d fail=%0d",
             lifecycle_rows_q, lifecycle_fail_q);
    $display("[ACCESS-G1-SUMMARY] sequence rows=%0d fail=%0d",
             sequence_rows_q, sequence_fail_q);
    if ((footprint_rows_q == 4) && (footprint_fail_q == 0) &&
        (poison_rows_q == 4) && (poison_fail_q == 0) &&
        (rresp_rows_q == 36) && (rresp_fail_q == 0) &&
        (rresp_owner0_rows_q == 18) && (rresp_owner1_rows_q == 18) &&
        (rresp_exokay_rows_q == 12) && (rresp_slverr_rows_q == 12) &&
        (rresp_decerr_rows_q == 12) &&
        (walk_rows_q == 12) && (walk_fail_q == 0) &&
        (pmp_rows_q == 14) && (pmp_fail_q == 0) &&
        (pmp_owner0_rows_q == 6) && (pmp_owner1_rows_q == 6) &&
        (alignment_rows_q == 16) && (alignment_fail_q == 0) &&
        (lifecycle_rows_q == 2) && (lifecycle_fail_q == 0) &&
        (sequence_rows_q == 1) && (sequence_fail_q == 0) &&
        (tb_errors == 0)) begin
      $display("[ACCESS-G1-MATRIX] footprint=4 poison=4 alignment=16 rresp=36 rresp_owner=18/18 rresp_sources=12/12/12 walk=12 pmp=14 pmp_owner=6/6 lifecycle=2 sequence=1 PASS");
    end else begin
      tb_errors = tb_errors + 1;
      $display("[ACCESS-G1-MATRIX-FAIL] footprint=%0d/%0d poison=%0d/%0d alignment=%0d/%0d rresp=%0d/%0d owner=%0d/%0d sources=%0d/%0d/%0d walk=%0d/%0d pmp=%0d/%0d pmp_owner=%0d/%0d lifecycle=%0d/%0d sequence=%0d/%0d",
               footprint_rows_q, footprint_fail_q,
               poison_rows_q, poison_fail_q,
               alignment_rows_q, alignment_fail_q,
               rresp_rows_q, rresp_fail_q,
               rresp_owner0_rows_q, rresp_owner1_rows_q,
               rresp_exokay_rows_q, rresp_slverr_rows_q,
               rresp_decerr_rows_q,
               walk_rows_q, walk_fail_q,
               pmp_rows_q, pmp_fail_q,
               pmp_owner0_rows_q, pmp_owner1_rows_q,
               lifecycle_rows_q, lifecycle_fail_q,
               sequence_rows_q, sequence_fail_q);
    end
    tb_finish("tb_ooo_fetch_access_footprint");
  end

endmodule
