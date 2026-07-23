`include "define.v"

module OooMemAxiBridge #(
  // Only the uninstantiated F1 dual-bridge wrapper enables peer D-cache
  // invalidation.  Existing canonical single-bridge behavior remains the
  // default and ignores the peer inputs completely.
  parameter ENABLE_PEER_INVALIDATE = 0
) (
  input clk,
  input rst,
  input flush_i,
  input mmu_flush_i,
  // Registered synchronous-DMA completion event.  It is independent of
  // pipeline/MMU flush and only changes D-cache visibility.
  input dcache_dma_invalidate_all_i,
  input peer_invalidate_valid_i,
  input [`XLEN-1:0] peer_invalidate_addr_i,
  input [`STRB_W-1:0] peer_invalidate_wstrb_i,

  input [1:0] priv_mode_i,
  input [`XLEN-1:0] mstatus_i,
  input [`XLEN-1:0] satp_i,
  input svpbmt_en_i,
  input [`PMP_CFG_BUS_W-1:0] pmpcfg_i,
  input [`PMP_ADDR_BUS_W-1:0] pmpaddr_i,

  input mem0_req_valid_i,
  output mem0_req_ready_o,
  input mem0_req_write_i,
  // 【LSQ·SQ 切换】三个事务属性位(spec ooo-lsq-implementation-plan.md §3.6):
  //   probe: write 探测——翻译+PMP 走完后不写内存, PA 经 rsp_rdata 回传(fault 路径复用);
  //   pretrans: 地址已是 PA(SQ drain 落存)——跳过翻译与 PMP(probe 拍已查);
  //   nokill: 事务不可被 flush 丢弃(已退休 store 的落存写必达)。
  // 三位全 0 时本模块行为与旧版逐位一致。
  input mem0_req_probe_i,
  input mem0_req_pretrans_i,
  input mem0_req_nokill_i,
  // Typed final-PA provenance.  Ordinary VA requests carry invalid/RSVD;
  // only a pretranslated SQ drain may carry a valid class captured by its
  // earlier side-effect-free probe.
  input mem0_req_attr_valid_i,
  input [1:0] mem0_req_class_i,
  // Migration-only compatibility view.  It is asserted against the typed
  // payload and is never used for routing or state.
  input mem0_req_cacheable_i,
  input [1:0] mem0_req_owner_kind_i,
  input [4:0] mem0_req_owner_token_i,
  input [1:0] mem0_req_mmu_epoch_i,
  input [`XLEN-1:0] mem0_req_fault_tval_i,
  // Registered MIQ-head truth.  Equality is a side-effect qualification only:
  // it must never feed request-ready or response-ready/transport advancement.
  input mem0_expected_valid_i,
  input [1:0] mem0_expected_owner_kind_i,
  input [4:0] mem0_expected_owner_token_i,
  input [1:0] mem0_expected_mmu_epoch_i,
  input mem0_expected_tval_valid_i,
  input [`XLEN-1:0] mem0_expected_fault_tval_i,
  input mem0_expected_effective_killed_i,
  // Edge-old tracker metadata for the active-token query.  This proves global
  // liveness/ABA safety but does not prove MIQ in-order head ownership.
  input mem0_tracker_expected_valid_i,
  input [1:0] mem0_tracker_expected_owner_kind_i,
  input [4:0] mem0_tracker_expected_owner_token_i,
  input [1:0] mem0_tracker_expected_mmu_epoch_i,
  input mem0_station_expected_valid_i,
  input [1:0] mem0_station_expected_owner_kind_i,
  input [4:0] mem0_station_expected_owner_token_i,
  input [1:0] mem0_station_expected_mmu_epoch_i,
  // T4M: backend MIQ/ROB owns whether the current in-order device read may
  // become externally visible.  cancel is the ROB-walk killed-head path.
  input mem0_device_release_i,
  input mem0_device_cancel_i,
  input [`XLEN-1:0] mem0_req_addr_i,
  input [`XLEN-1:0] mem0_req_wdata_i,
  input [`STRB_W-1:0] mem0_req_wstrb_i,
  output mem0_rsp_valid_o,
  input mem0_rsp_ready_i,
  output [`XLEN-1:0] mem0_rsp_rdata_o,
  output mem0_rsp_error_o,
  output mem0_rsp_page_fault_o,
  output mem0_rsp_attr_valid_o,
  output [1:0] mem0_rsp_class_o,
  output mem0_rsp_cacheable_o,
  output [1:0] mem0_rsp_owner_kind_o,
  output [4:0] mem0_rsp_owner_token_o,
  output [1:0] mem0_rsp_mmu_epoch_o,
  output [`XLEN-1:0] mem0_rsp_fault_tval_o,
  // Two independent, no-backpressure owner terminals.  drop0 is the active
  // FSM owner after its real external drain/cancel terminal; drop1 is a plain
  // request-station owner cancelled before stage advance.  They may coincide.
  output mem0_drop0_valid_o,
  output [1:0] mem0_drop0_owner_kind_o,
  output [4:0] mem0_drop0_owner_token_o,
  output [1:0] mem0_drop0_mmu_epoch_o,
  output [`XLEN-1:0] mem0_drop0_fault_tval_o,
  output mem0_drop1_valid_o,
  output [1:0] mem0_drop1_owner_kind_o,
  output [4:0] mem0_drop1_owner_token_o,
  output [1:0] mem0_drop1_mmu_epoch_o,
  output [`XLEN-1:0] mem0_drop1_fault_tval_o,
  // Two independent token queries sent to the external edge-old owner tracker.
  // Back-to-back response+advance needs the old active and next station owner
  // verified on the same edge; a muxed single query would validate one with
  // the other's metadata.
  output mem0_owner_query_valid_o,
  output [4:0] mem0_owner_query_token_o,
  output mem0_station_query_valid_o,
  output [4:0] mem0_station_query_token_o,
  // v8t/F3 final-PA store-queue query.  Payload is a direct view of the
  // registered active load and is held in S_SQ_QUERY until one exact
  // allow/forward/replay decision is returned.
  output mem0_sq_query_valid_o,
  output [1:0] mem0_sq_query_owner_kind_o,
  output [4:0] mem0_sq_query_owner_token_o,
  output [1:0] mem0_sq_query_mmu_epoch_o,
  output [`XLEN-1:0] mem0_sq_query_paddr_o,
  output mem0_sq_query_attr_valid_o,
  output [1:0] mem0_sq_query_class_o,
  output [`STRB_W-1:0] mem0_sq_query_wstrb_o,
  input mem0_sq_query_allow_i,
  input mem0_sq_query_forward_i,
  input mem0_sq_query_replay_i,
  input mem0_sq_query_retry_ready_i,
  input [`XLEN-1:0] mem0_sq_query_forward_data_i,
  // Edge-old bridge residency used only to suppress an SQ bulk release while
  // the exact STORE token still resides in station/active/held-response state.
  output [31:0] mem0_owner_residency_mask_o,
  // Zero-latency reduction of bridge-owned registered facts.  This is a
  // local mem0 quiet fact only; it is not the final dual-memory/global quiet.
  output mem0_idle_o,
  // 当前特权/satp 上下文下数据访问是否经 Sv39 翻译(供后端 load-vs-SQ 判定选 blind 模式)
  output translate_active_o,

  // Authorized local store/A-D maintenance exported to a peer cache.  These
  // are direct views of the existing exact-owner B-terminal authority and its
  // captured payload, never transport-lane or request-bus reconstruction.
  output peer_maintenance_valid_o,
  output [`XLEN-1:0] peer_maintenance_addr_o,
  output [`STRB_W-1:0] peer_maintenance_wstrb_o,

  output lsu_axi_arvalid_o,
  input lsu_axi_arready_i,
  output [`XLEN-1:0] lsu_axi_araddr_o,
  output [3:0] lsu_axi_arid_o,
  output [7:0] lsu_axi_arlen_o,
  output [2:0] lsu_axi_arsize_o,
  output [1:0] lsu_axi_arburst_o,
  output [2:0] lsu_axi_arprot_o,
  input lsu_axi_rvalid_i,
  output lsu_axi_rready_o,
  input [`XLEN-1:0] lsu_axi_rdata_i,
  input [1:0] lsu_axi_rresp_i,
  output lsu_axi_awvalid_o,
  input lsu_axi_awready_i,
  output [`XLEN-1:0] lsu_axi_awaddr_o,
  output [3:0] lsu_axi_awid_o,
  output [7:0] lsu_axi_awlen_o,
  output [2:0] lsu_axi_awsize_o,
  output [1:0] lsu_axi_awburst_o,
  output lsu_axi_wvalid_o,
  input lsu_axi_wready_i,
  output [`XLEN-1:0] lsu_axi_wdata_o,
  output [`STRB_W-1:0] lsu_axi_wstrb_o,
  output lsu_axi_wlast_o,
  input lsu_axi_bvalid_i,
  output lsu_axi_bready_o,
  input [1:0] lsu_axi_bresp_i
);

  // 【AXI4 化 S4】常量协议位: LSU ID 恒 4'd1、单 beat(LEN=0/WLAST=1)、INCR、
  // data access(ARPROT[2]=0)。AWSIZE 必须随逻辑访问宽度；A/D PTE 写固定 8B。
  assign lsu_axi_arid_o = 4'd1;
  assign lsu_axi_arlen_o = 8'd0;
  assign lsu_axi_arburst_o = 2'b01;
  assign lsu_axi_arprot_o = 3'b000;
  assign lsu_axi_awid_o = 4'd1;
  assign lsu_axi_awlen_o = 8'd0;
  assign lsu_axi_awsize_o =
      (state_q == S_AD_UPDATE) ? 3'd3 :
      axsize_from_bytes(access_size_from_wstrb(wstrb_q));
  assign lsu_axi_awburst_o = 2'b01;
  assign lsu_axi_wlast_o = 1'b1;

  localparam [3:0] S_IDLE = 4'd0;
  localparam [3:0] S_WALK_AR = 4'd1;
  localparam [3:0] S_WALK_R = 4'd2;
  localparam [3:0] S_READ_ADDR = 4'd3;
  localparam [3:0] S_READ_DATA = 4'd4;
  localparam [3:0] S_WRITE_REQ = 4'd5;
  localparam [3:0] S_WRITE_RESP = 4'd6;
  localparam [3:0] S_RESP = 4'd7;
  localparam [3:0] S_AD_UPDATE = 4'd8;   // HW A/D: 写回 leaf PTE 置 A(D)位, 再续原访问
  // 【SRAM 同步读】dcache 判决态: 上拍已发 dcache 单口读(发射拍), 本拍 SRAM rdata
  // 有效, 判 hit(→S_RESP)/miss(当拍发 AR)。load hit 1→2 拍是一期接受的代价。
  localparam [3:0] S_LOOKUP = 4'd9;
  // T4M: final PA is outside cacheable PMEM.  No data AR is presented until
  // the exact MIQ owner reaches ROB head; a killed owner is quietly cancelled.
  localparam [3:0] S_DEVICE_WAIT = 4'd10;
  // Non-assert fail-closed quarantine for a request whose captured station
  // tuple did not match the edge-old external owner tracker.  It performs no
  // transport or architectural side effect and requires an explicit flush.
  localparam [3:0] S_OWNER_HOLD = 4'd11;
  localparam [3:0] S_SQ_QUERY = 4'd12;
  localparam [1:0] MEM_OWNER_LOAD = 2'b00;
  localparam [`XLEN-1:0] PTE_A_BIT = {{(`XLEN-7){1'b0}}, 7'h40};  // bit 6 (Accessed)
  localparam [`XLEN-1:0] PTE_D_BIT = {{(`XLEN-8){1'b0}}, 8'h80};  // bit 7 (Dirty)
  // 【LSQ Phase2+3】8KB(2^10×8B)直映对 CoreMark 工作集 miss 率 47.6%——
  // 容量拉到 32KB(2^12), miss 流转 hit 流(hit 已 1 req/拍 back-to-back)。
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
  reg [`XLEN-1:0] ad_pte_q;    // HW A/D: 置位后的 leaf PTE(供 S_AD_UPDATE 写 + TLB 填)
  reg [`XLEN-1:0] wdata_q;
  reg [`STRB_W-1:0] wstrb_q;
  reg [`XLEN-1:0] rsp_rdata_q;
  reg rsp_error_q;
  reg rsp_page_fault_q;
  reg aw_done_q;
  reg w_done_q;
  reg drop_rsp_q;
  // T4I 后统一以 B 作为 store 的完成点：LSU lane adapter 的上游
  // AW/W fire 只表示命令被其寄存，不代表所有下游 beat 已完成。
  // 等待聚合 B 可防止 split write 被后续访存越过，并向上传递
  // adapter 粘滞 BRESP。
  // 【LSQ·SQ 切换】当前事务属性(advance 拍锁存, 每次 accept 覆盖)。pretrans 的效果
  // (跳过翻译/PMP)全部在 advance 拍组合完成, 无需再寄存进 FSM。
  reg probe_q;
  reg nokill_q;
  reg [1:0] active_owner_kind_q;
  reg [4:0] active_owner_token_q;
  reg [1:0] active_mmu_epoch_q;
  reg [`XLEN-1:0] active_fault_tval_q;
  reg active_owner_verified_q;
  reg [1:0] verified_owner_kind_q;
  reg [4:0] verified_owner_token_q;
  reg [1:0] verified_mmu_epoch_q;
  reg write_escaped_q;
  // A write that was exact when killed may outlive the MIQ head because AXI
  // VALID cannot be withdrawn after presentation.  Preserve only the narrow
  // authority needed to invalidate a possible cache alias at its eventual B;
  // this bit never authorizes response, fill, or data RMW side effects.
  reg killed_write_maintenance_authorized_q;
  // Held response provenance is a distinct snapshot.  It cannot borrow the
  // active registers because a killed S_RESP owner may be atomically replaced
  // by a queued nokill request on the same edge.
  reg [1:0] rsp_owner_kind_q;
  reg [4:0] rsp_owner_token_q;
  reg [1:0] rsp_mmu_epoch_q;
  reg [`XLEN-1:0] rsp_fault_tval_q;
  // 【P5 刀 M·桥侧 req 寄存站】req fire(=accept)拍只锁存 CPU 侧请求 8 字段, 零计算;
  // 翻译(DTLB CAM)/PMP/dcache 发射/全部分流决策整体推迟到 stage_advance 拍
  // (accept_request 改从寄存站取数)。必须留在 fire 拍的只有字段锁存本身——core 侧
  // req mux 是组合的、次拍即消失(SQ drain fire 次拍 drain_inflight_q 置位撤 valid,
  // probe 同理)。CSR 上下文(priv/mstatus/satp/svpbmt/pmp)不进寄存站: 寄存站占用 ⇒
  // MIQ 非空 ⇒ mem_idle=0 ⇒ head0-CSR/sfence 被 serialize-at-retire 挡住不能退休,
  // advance 拍上下文与 fire 拍必同(NpcSimTop 跨模块立即断言固化, 勿改为多锁上下文)。
  reg stg_valid_q;
  reg [`XLEN-1:0] stg_addr_q;
  reg [`XLEN-1:0] stg_wdata_q;
  reg [`STRB_W-1:0] stg_wstrb_q;
  reg stg_write_q;
  reg stg_probe_q;
  reg stg_pretrans_q;
  reg stg_nokill_q;
  reg stg_attr_valid_q;
  reg [1:0] stg_class_q;
  reg [1:0] stg_owner_kind_q;
  reg [4:0] stg_owner_token_q;
  reg [1:0] stg_mmu_epoch_q;
  reg [`XLEN-1:0] stg_fault_tval_q;
  // 【line-dcache】本读事务是否跨 8B line(跨线走窗口读不 fill; 不跨线发对齐
  // AR, 回填 line 并把窗口视图给 CPU)。read_exact_q 还覆盖 uncacheable：这类
  // 访问必须保留原 PA/size，不能把 MMIO 扩大成带额外读副作用的 8B line 访问。
  reg read_cross_q;
  reg read_exact_q;
  // Final-PA typed provenance after PMA and PBMT.  This is the single active
  // transaction truth used after a walk/A-D update and on post-target R/B
  // errors; it is never reconstructed from PA or a legacy Boolean.
  reg access_attr_valid_q;
  reg [1:0] access_class_q;
  wire access_cacheable_w = access_attr_valid_q &&
                            (access_class_q == `OOO_MEM_CLASS_CACHED);
  wire access_nc_w = access_attr_valid_q &&
                     (access_class_q == `OOO_MEM_CLASS_NC);
  wire access_io_w = access_attr_valid_q &&
                     (access_class_q == `OOO_MEM_CLASS_IO);

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
    input [1:0] level;
    begin
      // Leaf PBMT legality is intentionally absent here.  It has one owner:
      // OooTypedMemoryClassifier.  Non-leaf PBMT remains structurally illegal.
      pte_reserved_fault =
          (pte_leaf(pte) ?
           (((pte & (`SV39_PTE_RESERVED_MASK_SVPBMT &
                                 ~`SV39_PTE_N)) != {`XLEN{1'b0}}) ||
            (((pte & `SV39_PTE_N) != {`XLEN{1'b0}}) &&
             ((level != 2'd0) || (pte[13:10] != 4'b1000)))) :
           (((pte & `SV39_PTE_RESERVED_MASK_SVPBMT) !=
             {`XLEN{1'b0}}) ||
            ((pte & `SV39_PTE_NONLEAF_RESERVED_MASK) != {`XLEN{1'b0}}) ||
            (pte[`SV39_PTE_PBMT_HI:`SV39_PTE_PBMT_LO] != 2'b00)));
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

  // HW A/D(Svadu, 对齐 NEMU): 权限 fault 只含真权限(R/W/X、U/S、MXR/SUM)。
  // A/D 缺失不再 fault, 改由 walker S_AD_UPDATE 写回 PTE 置位(见 data_ad_update_needed)。
  function data_permission_fault;
    input [`XLEN-1:0] pte;
    input write_access;
    input [1:0] priv_mode;
    input [`XLEN-1:0] status;
    begin
      data_permission_fault =
          (write_access ? !pte[2] : !data_read_ok(pte, status)) ||
          !data_user_ok(pte, priv_mode, status);
    end
  endfunction

  // A/D 需 HW 更新: 真权限已过但 A=0(任意访问)或 D=0(store)。
  function data_ad_update_needed;
    input [`XLEN-1:0] pte;
    input write_access;
    begin
      data_ad_update_needed = !pte[6] || (write_access && !pte[7]);
    end
  endfunction

  function [`XLEN-1:0] leaf_paddr;
    input [`XLEN-1:0] pte;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      // Svnapot 64KiB leaf: PTE.PPN[3:0] 是 NAPOT 编码(1000)，真实 PA
      // 低 4 个 PPN bit 必须来自 VA[15:12]，否则 store 会落到错误 64KiB 子页。
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

  function normalized_wstrb_legal;
    input [`STRB_W-1:0] wstrb;
    begin
      case (wstrb)
        8'h01,
        8'h03,
        8'h0f,
        8'hff: normalized_wstrb_legal = 1'b1;
        default: normalized_wstrb_legal = 1'b0;
      endcase
    end
  endfunction

  // AXI AxSIZE 编码: log2(字节数)。输入为 1/2/4/8。
  function [2:0] axsize_from_bytes;
    input [3:0] nbytes;
    begin
      axsize_from_bytes = (nbytes >= 4'd8) ? 3'd3 :
                          (nbytes >= 4'd4) ? 3'd2 :
                          (nbytes >= 4'd2) ? 3'd1 : 3'd0;
    end
  endfunction

  wire [1:0] req_priv_w = effective_data_priv(priv_mode_i, mstatus_i);
  wire ctx_translate_w = sv39_enabled(req_priv_w, satp_i);
  // pretrans 请求地址已是 PA:跳过翻译(req_cache_addr_w 直取 req_addr)与 PMP(probe 拍已查)。
  // 【刀 M】req_* 簇整体换源为寄存站字段(advance 拍求值), 不再直连 mem0_req_* 输入。
  wire req_translate_w = ctx_translate_w && !stg_pretrans_q;
  wire mem0_req_fire_w = mem0_req_valid_i && mem0_req_ready_o;
  wire aw_fire_w = lsu_axi_awvalid_o && lsu_axi_awready_i;
  wire w_fire_w = lsu_axi_wvalid_o && lsu_axi_wready_i;
  // mem1(双发射 load 第二端口)死硅删除后,单 outstanding 桥只服务 mem0:
  // 响应就绪/请求选择都直取 mem0,active_port 归属随之消失。
  wire rsp_ready_w = mem0_rsp_ready_i;
  // Declared before the identity predicates and assigned after them.  This
  // keeps the registered AXI-owner outputs free to use one common recovery
  // domain without relying on a net-declaration forward reference.
  wire cpu_kill_w;
  wire lookup_hit_fusion_w;
  wire active_sq_query_valid_w;
  wire station_sq_lookahead_query_w;
  wire active_sq_query_read_lookup_fire_w;
  wire station_sq_lookahead_lookup_fire_w;
  wire [`XLEN-1:0] req_cache_addr_w;
  wire req_effective_attr_valid_w;
  wire [1:0] req_effective_class_w;
  wire req_dcacheable_w;
  wire req_line_cross_w;
  wire active_rsp_identity_consistent_w =
      (active_owner_kind_q == rsp_owner_kind_q) &&
      (active_owner_token_q == rsp_owner_token_q) &&
      (active_mmu_epoch_q == rsp_mmu_epoch_q);
  wire active_rsp_tval_echo_match_w =
      (active_fault_tval_q == rsp_fault_tval_q);
  wire active_expected_identity_match_w = mem0_expected_valid_i &&
      (active_owner_kind_q == mem0_expected_owner_kind_i) &&
      (active_owner_token_q == mem0_expected_owner_token_i) &&
      (active_mmu_epoch_q == mem0_expected_mmu_epoch_i);
  wire active_expected_tval_echo_match_w =
      (active_fault_tval_q == mem0_expected_fault_tval_i);
  wire active_tracker_identity_match_w = mem0_tracker_expected_valid_i &&
      (active_owner_kind_q == mem0_tracker_expected_owner_kind_i) &&
      (active_owner_token_q == mem0_tracker_expected_owner_token_i) &&
      (active_mmu_epoch_q == mem0_tracker_expected_mmu_epoch_i);
  wire rsp_expected_identity_match_w = mem0_expected_valid_i &&
      (rsp_owner_kind_q == mem0_expected_owner_kind_i) &&
      (rsp_owner_token_q == mem0_expected_owner_token_i) &&
      (rsp_mmu_epoch_q == mem0_expected_mmu_epoch_i);
  wire rsp_expected_tval_echo_match_w =
      (rsp_fault_tval_q == mem0_expected_fault_tval_i);
  wire visible_rsp_expected_identity_match_w = lookup_hit_fusion_w ?
      active_expected_identity_match_w : rsp_expected_identity_match_w;
  wire visible_rsp_expected_tval_echo_match_w = lookup_hit_fusion_w ?
      active_expected_tval_echo_match_w : rsp_expected_tval_echo_match_w;
  wire station_expected_identity_match_w = mem0_station_expected_valid_i &&
      (stg_owner_kind_q == mem0_station_expected_owner_kind_i) &&
      (stg_owner_token_q == mem0_station_expected_owner_token_i) &&
      (stg_mmu_epoch_q == mem0_station_expected_mmu_epoch_i);
  wire active_sticky_identity_match_w = active_owner_verified_q &&
      (active_owner_kind_q == verified_owner_kind_q) &&
      (active_owner_token_q == verified_owner_token_q) &&
      (active_mmu_epoch_q == verified_mmu_epoch_q);
  // ROB-walk branch recovery is selective: the backend marks only the exact
  // younger MIQ owner ineffective and does not assert the full-core flush.
  // Admit that condition into the bridge recovery domain only when all three
  // independent owner views agree.  A raw effective-killed bit, an MIQ token
  // alias, or a retired nokill store is never sufficient authority.
  wire active_selective_recovery_w =
      mem0_expected_effective_killed_i && !nokill_q &&
      active_expected_identity_match_w &&
      active_sticky_identity_match_w;
  assign cpu_kill_w = flush_i || drop_rsp_q || active_selective_recovery_w;
  // nokill 事务(退休 store 落存)进行期间, flush/drop 对 FSM 推进与响应握手均无效——
  // 写必达。nokill_q 是"当前事务"属性(accept 拍覆盖), 非 IDLE 态即有效。
  wire nokill_busy_w = nokill_q && (state_q != S_IDLE);
  // FSM 正常推进分支选择条件(flush/drop 拍走 drain 分支; nokill 事务免疫)。
  wire fsm_normal_w = !cpu_kill_w || nokill_busy_w;
  // 【store RMW】dcache store write-update 判决拍占宏口: 该拍压 stage_advance
  // (store 后 1 bubble, 观察点从旧 req_ready 压制改为寄存站保持), 阻止
  // S_IDLE/S_RESP back-to-back advance 发 lookup 抢口。
  wire dcache_rmw_busy_w;
  // 【刀 M】stage_advance = FSM 收下寄存站项的时机(原 req_slot_ready 的 state 条件
  // + rmw_busy 迁入 + nokill 豁免 cpu_kill), advance 拍执行迁移后的 accept_request。
  // S_IDLE/S_RESP 态 drop_rsp_q 恒 0(FSM 不变量, BRG-ADV-NODROP 断言化), 故 cpu_kill
  // 项在可 advance 的状态里实际等价 flush_i——nokill(SQ drain 落存)项 flush 拍照常
  // 进 FSM(写必达), 非 nokill 项 flush 拍被挡且同拍被寄存站 flush 臂清除。
  // 刀D 融合谓词: S_LOOKUP 命中拍组合响应(load hit 流 1 拍/load)。声明先行、
  // assign 在 dcache hit 判定之后(iverilog14 net-decl-assign 前向引用禁令的
  // 拆声明修复形态)。谓词含 !cpu_kill(p42 型污染防线: 被 kill load 禁经融合臂交付)。
  wire stage_advance_w = stg_valid_q && !dcache_rmw_busy_w &&
                         ((state_q == S_IDLE) ||
                          ((state_q == S_RESP) && rsp_ready_w) ||
                          (lookup_hit_fusion_w && rsp_ready_w)) &&
                         (!cpu_kill_w || stg_nokill_q);
  assign mem0_owner_query_valid_o = (state_q != S_IDLE);
  assign mem0_owner_query_token_o = active_owner_token_q;
  // Tracker lookup observes the registered station, not its downstream
  // advance.  Keeping this Q-only prevents response backpressure from entering
  // the tracker/terminal-credit cone while preserving the advance-time check.
  assign mem0_station_query_valid_o = stg_valid_q;
  assign mem0_station_query_token_o = stg_owner_token_q;
  wire sq_query_owner_exact_w = active_expected_identity_match_w &&
      active_tracker_identity_match_w && active_sticky_identity_match_w &&
      !mem0_expected_effective_killed_i;
  // Present either the ordinary registered active query or, on a retiring
  // cache hit, the registered station load.  The station source is still a
  // final-PA query: backend accepts it only as the exact MIQ next head on the
  // same edge that current head is consumed.  Both sources share one SQ CAM.
  assign active_sq_query_valid_w = (state_q == S_SQ_QUERY) &&
      (active_owner_kind_q == MEM_OWNER_LOAD) && !cpu_kill_w;
  assign mem0_sq_query_valid_o = active_sq_query_valid_w ||
                                 station_sq_lookahead_query_w;
  assign mem0_sq_query_owner_kind_o = station_sq_lookahead_query_w ?
      stg_owner_kind_q : active_owner_kind_q;
  assign mem0_sq_query_owner_token_o = station_sq_lookahead_query_w ?
      stg_owner_token_q : active_owner_token_q;
  assign mem0_sq_query_mmu_epoch_o = station_sq_lookahead_query_w ?
      stg_mmu_epoch_q : active_mmu_epoch_q;
  assign mem0_sq_query_paddr_o = station_sq_lookahead_query_w ?
      req_cache_addr_w : paddr_q;
  assign mem0_sq_query_attr_valid_o = station_sq_lookahead_query_w ?
      req_effective_attr_valid_w : access_attr_valid_q;
  assign mem0_sq_query_class_o = station_sq_lookahead_query_w ?
      req_effective_class_w :
      (access_attr_valid_q ? access_class_q : `OOO_MEM_CLASS_RSVD);
  assign mem0_sq_query_wstrb_o = station_sq_lookahead_query_w ?
      stg_wstrb_q : wstrb_q;
  wire sq_query_decision_onehot_w =
      (mem0_sq_query_allow_i && !mem0_sq_query_forward_i &&
       !mem0_sq_query_replay_i) ||
      (!mem0_sq_query_allow_i && mem0_sq_query_forward_i &&
       !mem0_sq_query_replay_i) ||
      (!mem0_sq_query_allow_i && !mem0_sq_query_forward_i &&
       mem0_sq_query_replay_i);
  wire sq_query_retry_fire_w = mem0_sq_query_valid_o &&
      sq_query_decision_onehot_w && mem0_sq_query_replay_i &&
      mem0_sq_query_retry_ready_i;
  wire req_write_w = stg_write_q;
  wire [`XLEN-1:0] req_addr_w = stg_addr_q;
  wire [`XLEN-1:0] req_wdata_w = stg_wdata_q;
  wire [`STRB_W-1:0] req_wstrb_w = stg_wstrb_q;
  wire [3:0] req_access_size_w = access_size_from_wstrb(req_wstrb_w);
  wire [3:0] active_access_size_w = access_size_from_wstrb(wstrb_q);
  wire req_dtlb_context_hit_w;
  wire [`XLEN-1:0] req_dtlb_pte_w;
  wire [1:0] req_dtlb_level_w;
  wire [`XLEN-1:0] req_translated_paddr_w;
  wire req_dtlb_perm_fault_w =
      req_dtlb_context_hit_w &&
      (pte_reserved_fault(req_dtlb_pte_w, req_dtlb_level_w) ||
       data_permission_fault(req_dtlb_pte_w, req_write_w, req_priv_w,
                             mstatus_i));
  // HW A/D: TLB 命中项若 A/D 不足(如 load 填的 A=1/D=0 项被 store 命中)→ 视为 miss,
  // 走 walk 触发 S_AD_UPDATE 置位后重填。TLB 命中仅当真权限过 且 A/D 已足。
  wire req_dtlb_ad_needed_w =
      req_dtlb_context_hit_w && !req_dtlb_perm_fault_w &&
      data_ad_update_needed(req_dtlb_pte_w, req_write_w);
  wire req_dtlb_hit_w =
      req_dtlb_context_hit_w && !req_dtlb_perm_fault_w && !req_dtlb_ad_needed_w;
  assign req_cache_addr_w =
      req_dtlb_hit_w ? req_translated_paddr_w : req_addr_w;
  wire req_pmp_fault_raw_w;
  wire req_data_pmp_fault_w =
      (!req_translate_w || req_dtlb_hit_w) && req_pmp_fault_raw_w &&
      !stg_pretrans_q;
  wire req_pma_fault_raw_w;
  wire req_pma_attr_valid_raw_w;
  wire [1:0] req_pma_class_raw_w;
  wire req_typed_attr_valid_w;
  wire [1:0] req_typed_class_w;
  wire req_typed_fault_w;
  wire req_typed_page_fault_w;
  wire req_typed_access_fault_w;
  wire req_typed_pbmt_fault_w;
  wire req_typed_cacheable_w;
  wire req_typed_serialized_w;
  // Plain Verilog case/default gives an X/Z-safe fail-closed admission and
  // still synthesizes as the small typed decoder it describes.
  reg req_pretrans_attr_admitted_r;
  always @(*) begin
    req_pretrans_attr_admitted_r = 1'b0;
    case ({stg_attr_valid_q, stg_class_q})
      {1'b1, `OOO_MEM_CLASS_CACHED},
      {1'b1, `OOO_MEM_CLASS_NC},
      {1'b1, `OOO_MEM_CLASS_IO}: req_pretrans_attr_admitted_r = 1'b1;
      default: req_pretrans_attr_admitted_r = 1'b0;
    endcase
  end
  wire req_pretrans_attr_fault_w =
      stg_pretrans_q && !req_pretrans_attr_admitted_r;
  wire req_data_pma_fault_w = req_pretrans_attr_fault_w ||
                              req_typed_access_fault_w;
  assign req_effective_attr_valid_w =
      stg_pretrans_q ? req_pretrans_attr_admitted_r :
      (req_typed_attr_valid_w && !req_data_pmp_fault_w &&
       !req_dtlb_perm_fault_w);
  assign req_effective_class_w = req_effective_attr_valid_w ?
      (stg_pretrans_q ? stg_class_q : req_typed_class_w) :
      `OOO_MEM_CLASS_RSVD;
  wire req_addr_dcacheable_w;
  assign req_dcacheable_w = req_effective_attr_valid_w &&
                            (req_effective_class_w ==
                             `OOO_MEM_CLASS_CACHED);
  wire req_nc_w = req_effective_attr_valid_w &&
                  (req_effective_class_w == `OOO_MEM_CLASS_NC);
  wire req_io_w = req_effective_attr_valid_w &&
                  (req_effective_class_w == `OOO_MEM_CLASS_IO);
  // F4 lookahead is restricted to the same direct-final-PA cases that the
  // normal accept path can prove in this cycle: Bare/pretranslated or a valid
  // DTLB hit, typed cached class, no fault, and a single cache line.  A miss,
  // walk, NC/IO, store/probe, or uncertain byte mask follows the F3 path.
  // Present the Q-only station query independently of response READY.  The
  // backend may then classify this source without feeding its retry/pop mux
  // back into current response credit.  Only the allow-qualified lookup fire
  // below consumes rsp_ready_w and may promote the station owner.
  assign station_sq_lookahead_query_w = lookup_hit_fusion_w &&
      stg_valid_q && !dcache_rmw_busy_w && station_expected_identity_match_w &&
      !mem0_expected_effective_killed_i && !mmu_flush_i &&
      !req_write_w && !stg_probe_q &&
      (stg_owner_kind_q == MEM_OWNER_LOAD) &&
      (!req_translate_w || req_dtlb_hit_w) &&
      !req_typed_page_fault_w && !req_dtlb_perm_fault_w &&
      !req_data_pmp_fault_w && !req_data_pma_fault_w &&
      req_dcacheable_w && !req_line_cross_w &&
      normalized_wstrb_legal(stg_wstrb_q);
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, addr_q, walk_level_q);
  wire [`XLEN-1:0] walk_leaf_paddr_w =
      leaf_paddr(lsu_axi_rdata_i, addr_q, walk_level_q);
  wire walk_leaf_pmp_fault_w;
  wire walk_leaf_pma_fault_raw_w;
  wire walk_leaf_pma_attr_valid_raw_w;
  wire [1:0] walk_leaf_pma_class_raw_w;
  wire walk_leaf_classified_attr_valid_w;
  wire [1:0] walk_leaf_classified_class_w;
  wire walk_leaf_attr_valid_w;
  wire [1:0] walk_leaf_class_w;
  wire walk_leaf_typed_fault_w;
  wire walk_leaf_page_fault_w;
  wire walk_leaf_pma_fault_w;
  wire walk_leaf_pbmt_fault_w;
  wire walk_leaf_cacheable_w;
  wire walk_leaf_serialized_w;
  wire walk_leaf_addr_dcacheable_w;
  wire walk_leaf_dcacheable_w = walk_leaf_attr_valid_w &&
                                (walk_leaf_class_w == `OOO_MEM_CLASS_CACHED);
  wire walk_leaf_nc_w = walk_leaf_attr_valid_w &&
                        (walk_leaf_class_w == `OOO_MEM_CLASS_NC);
  wire walk_leaf_io_w = walk_leaf_attr_valid_w &&
                        (walk_leaf_class_w == `OOO_MEM_CLASS_IO);
  wire paddr_dcacheable_w = access_cacheable_w;
  wire write_paddr_virtio_blk_w =
      ((paddr_q & `NPC_AXI_VIRTIO_BLK_MASK) == `NPC_AXI_VIRTIO_BLK_BASE);
  wire dtlb_leaf_ok_w =
      (state_q == S_WALK_R) && lsu_axi_rvalid_i &&
      (lsu_axi_rresp_i == 2'b00) &&
      !pte_invalid(lsu_axi_rdata_i) &&
      !pte_reserved_fault(lsu_axi_rdata_i, walk_level_q) &&
      pte_leaf(lsu_axi_rdata_i) &&
      !superpage_misaligned(lsu_axi_rdata_i, walk_level_q) &&
      !data_permission_fault(lsu_axi_rdata_i, write_q, access_priv_q,
                             mstatus_i);
  wire walk_ad_needed_w = data_ad_update_needed(lsu_axi_rdata_i, write_q);
  // B terminal and B success are deliberately distinct.  A lane adapter may
  // have completed an earlier split beat before a later beat reports error;
  // therefore every terminal conservatively maintains a possible hot alias,
  // while only an all-OK data-store terminal may write-update cache data.
  wire data_store_b_terminal_w =
      (state_q == S_WRITE_RESP) && lsu_axi_bvalid_i;
  wire data_store_b_ok_w =
      data_store_b_terminal_w && (lsu_axi_bresp_i == 2'b00);
  wire ad_update_b_terminal_w =
      (state_q == S_AD_UPDATE) && lsu_axi_bvalid_i;
  // A/D 写回 B 成功拍: 用 ad_pte_q 填 TLB(A/D 已置)+ 续原访问。
  wire ad_update_b_ok_w =
      ad_update_b_terminal_w && (lsu_axi_bresp_i == 2'b00);
  // Once registered AW/W VALID is visible, AXI makes the write irrevocable
  // even before READY.  The kill-edge capture is deliberately stricter than
  // the later maintenance use: all three owner views must still name the
  // exact edge-old transaction, and a retirement (nokill) store is excluded.
  wire write_irrevocably_presented_w = write_escaped_q || aw_fire_w ||
      w_fire_w ||
      (((state_q == S_WRITE_REQ) || (state_q == S_AD_UPDATE)) &&
       (lsu_axi_awvalid_o || lsu_axi_wvalid_o));
  wire killed_write_maintenance_capture_w =
      mem0_expected_effective_killed_i && !nokill_q &&
      active_expected_identity_match_w && active_tracker_identity_match_w &&
      active_sticky_identity_match_w && write_irrevocably_presented_w;
  wire killed_write_maintenance_authorized_w =
      killed_write_maintenance_authorized_q ||
      killed_write_maintenance_capture_w;
  // 无需更新 → S_WALK_R 填原始 PTE(A/D 已足); 需更新 → 待 S_AD_UPDATE 写完填 ad_pte_q。
  wire dtlb_fill_valid_w =
      active_expected_identity_match_w && active_tracker_identity_match_w &&
      active_sticky_identity_match_w && fsm_normal_w &&
      !mem0_expected_effective_killed_i &&
      !killed_write_maintenance_authorized_w &&
      ((dtlb_leaf_ok_w && walk_leaf_attr_valid_w && !walk_ad_needed_w) ||
       ad_update_b_ok_w);
  wire [`XLEN-1:0] dtlb_fill_pte_w =
      ad_update_b_ok_w ? ad_pte_q : lsu_axi_rdata_i;
  wire dcache_read_fill_valid_w =
      active_expected_identity_match_w && active_tracker_identity_match_w &&
      active_sticky_identity_match_w && fsm_normal_w &&
      !mem0_expected_effective_killed_i &&
      (state_q == S_READ_DATA) && lsu_axi_rvalid_i &&
      (lsu_axi_rresp_i == 2'b00) && access_cacheable_w && !read_exact_q;
  // Store/PTE aliases are maintained on every B terminal.  Data RMW is
  // separately enabled only for an all-OK final-cacheable data store; B error,
  // PBMT NC/IO, and A/D maintenance all take the valid-only invalidate path.
  wire dcache_store_commit_w =
      active_tracker_identity_match_w && active_sticky_identity_match_w &&
      write_irrevocably_presented_w &&
      (active_expected_identity_match_w ||
       killed_write_maintenance_authorized_w) &&
      (data_store_b_terminal_w || ad_update_b_terminal_w);
  // A killed write that already escaped still needs a conservative alias
  // invalidate, but may not use sticky verification to authorize an RMW data
  // update.  RMW therefore requires a current exact owner and non-killed head.
  wire dcache_store_rmw_en_w = data_store_b_ok_w && access_cacheable_w &&
      active_expected_identity_match_w && active_tracker_identity_match_w &&
      active_sticky_identity_match_w && fsm_normal_w &&
      !mem0_expected_effective_killed_i &&
      !killed_write_maintenance_authorized_w;
  wire dcache_store_cacheable_w =
      ad_update_b_terminal_w || access_cacheable_w;
  wire [`XLEN-1:0] dcache_store_addr_w =
      ad_update_b_terminal_w ? walk_pte_addr_w : paddr_q;
  wire [`XLEN-1:0] dcache_store_wdata_w = wdata_q;
  wire [`STRB_W-1:0] dcache_store_wstrb_w =
      ad_update_b_terminal_w ? {`STRB_W{1'b1}} : wstrb_q;

  assign peer_maintenance_valid_o = dcache_store_commit_w;
  assign peer_maintenance_addr_o = dcache_store_addr_w;
  assign peer_maintenance_wstrb_o = dcache_store_wstrb_w;

  // v8t/F3: every ordinary load, including DTLB hit, PTW miss and A/D
  // continuation, first registers final PA/class in S_SQ_QUERY.  Only an
  // exact allow may launch the cache macro; replay/forward own no target.
  assign active_sq_query_read_lookup_fire_w = active_sq_query_valid_w &&
      sq_query_decision_onehot_w && mem0_sq_query_allow_i &&
      access_cacheable_w;
  assign station_sq_lookahead_lookup_fire_w =
      station_sq_lookahead_query_w && rsp_ready_w &&
      sq_query_decision_onehot_w &&
      mem0_sq_query_allow_i && req_dcacheable_w;
  wire sq_query_read_lookup_fire_w = active_sq_query_read_lookup_fire_w ||
      station_sq_lookahead_lookup_fire_w;
  // Historical white-box TB probe names remain observational aliases only;
  // neither alias owns target admission after v8t/F3.
  wire req_read_lookup_fire_w = sq_query_read_lookup_fire_w;
  wire req_read_lookup_issue_w = sq_query_read_lookup_fire_w;
  wire walk_lookup_payload_owner_w = (state_q == S_WALK_R);
  wire dcache_lookup_en_w =
      !dcache_rmw_busy_w && sq_query_read_lookup_fire_w;
  // Address bits are the registered final PA only.  The SQ compare/class
  // decision reaches lookup enable but never enters this macro address cone.
  wire [`XLEN-1:0] dcache_lookup_addr_w =
      station_sq_lookahead_lookup_fire_w ? req_cache_addr_w : paddr_q;
  wire dcache_lookup_hit_w;
  wire [`XLEN-1:0] dcache_lookup_line_w;
  // S_LOOKUP 判决: 跨线阻断统一用锁存 read_cross_q(accept 拍按 VA 低 3 位判,
  // VA/PA 页内偏移相同故对 walk 路同样成立), 窗口移位统一用锁存 paddr_q[2:0]。
  wire dcache_lookup_hit_final_w = dcache_lookup_hit_w && !read_cross_q;
  // 刀D 融合谓词 assign(声明见 stage_advance_w 前): hit 锥输入全 FF/锁存
  // (lookup_pend/cacheable/valid FF+锁存 tag 比较), 无 fetch 窗口②那样的当拍
  // snoop 地址比较链——无需降级臂(详 design/arch/knife-d-dcache-hit-fusion.md)。
  // 【T2 回滚(2026-07-10)】实验证明回吐 +0.143 CPI 超预估一倍, T1 已切断贯通链
  // 尾段——恢复刀 D 融合, STA 实验对比见 timing-t124 task-report 决策建议 1。
  assign lookup_hit_fusion_w = (state_q == S_LOOKUP) &&
                               dcache_lookup_hit_final_w && !cpu_kill_w;

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
    .lookup_level_o(req_dtlb_level_w),
    .lookup_paddr_o(req_translated_paddr_w),
    .fill_valid_i(dtlb_fill_valid_w),
    .fill_vaddr_i(addr_q),
    .fill_satp_i(satp_i),
    .fill_pte_i(dtlb_fill_pte_w),
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

  // Typed PMA owns the implemented-region class.  A pretranslated drain is
  // deliberately excluded: its class must be the exact probe provenance,
  // never a second address-based classification.
  // PBMT/PTE legality must be evaluated before PMP/PMA fault selection.
  // Therefore a final leaf remains classifier-valid even when PMP denies it;
  // final routable provenance is separately masked below.
  wire req_classify_valid_w =
      (!req_translate_w || req_dtlb_hit_w) && !stg_pretrans_q &&
      !req_dtlb_perm_fault_w;
  OooTypedPmaChecker u_req_pma_checker (
    .paddr_i(req_cache_addr_w),
    .access_size_i(req_access_size_w),
    .access_read_i(req_classify_valid_w && !req_write_w),
    .access_write_i(req_classify_valid_w && req_write_w),
    .fault_o(req_pma_fault_raw_w),
    .attr_valid_o(req_pma_attr_valid_raw_w),
    .class_o(req_pma_class_raw_w)
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

  wire walk_leaf_classify_valid_w = dtlb_leaf_ok_w;
  OooTypedPmaChecker u_walk_leaf_pma_checker (
    .paddr_i(walk_leaf_paddr_w),
    .access_size_i(active_access_size_w),
    .access_read_i(walk_leaf_classify_valid_w && !write_q),
    .access_write_i(walk_leaf_classify_valid_w && write_q),
    .fault_o(walk_leaf_pma_fault_raw_w),
    .attr_valid_o(walk_leaf_pma_attr_valid_raw_w),
    .class_o(walk_leaf_pma_class_raw_w)
  );

  // The typed classifier is the only PBMT/PMA merge owner.  pbmt_valid means
  // "translated leaf exists", independently of whether PBMTE is enabled.
  OooTypedMemoryClassifier u_req_post_translate_class (
    .clk(clk),
    .rst(rst),
    .access_valid_i(req_classify_valid_w),
    .pma_fault_i(req_pma_fault_raw_w),
    .pma_attr_valid_i(req_pma_attr_valid_raw_w),
    .pma_class_i(req_pma_class_raw_w),
    .pbmt_valid_i(req_translate_w),
    .pbmte_i(svpbmt_en_i),
    .pbmt_i(req_dtlb_pte_w[`SV39_PTE_PBMT_HI:`SV39_PTE_PBMT_LO]),
    .attr_valid_o(req_typed_attr_valid_w),
    .class_o(req_typed_class_w),
    .fault_valid_o(req_typed_fault_w),
    .page_fault_o(req_typed_page_fault_w),
    .access_fault_o(req_typed_access_fault_w),
    .pbmt_fault_o(req_typed_pbmt_fault_w),
    .cacheable_o(req_typed_cacheable_w),
    .serialized_o(req_typed_serialized_w)
  );

  OooTypedMemoryClassifier u_walk_post_translate_class (
    .clk(clk),
    .rst(rst),
    .access_valid_i(walk_leaf_classify_valid_w),
    .pma_fault_i(walk_leaf_pma_fault_raw_w),
    .pma_attr_valid_i(walk_leaf_pma_attr_valid_raw_w),
    .pma_class_i(walk_leaf_pma_class_raw_w),
    .pbmt_valid_i(1'b1),
    .pbmte_i(access_svpbmt_en_q),
    .pbmt_i(lsu_axi_rdata_i[`SV39_PTE_PBMT_HI:`SV39_PTE_PBMT_LO]),
    .attr_valid_o(walk_leaf_classified_attr_valid_w),
    .class_o(walk_leaf_classified_class_w),
    .fault_valid_o(walk_leaf_typed_fault_w),
    .page_fault_o(walk_leaf_page_fault_w),
    .access_fault_o(walk_leaf_pma_fault_w),
    .pbmt_fault_o(walk_leaf_pbmt_fault_w),
    .cacheable_o(walk_leaf_cacheable_w),
    .serialized_o(walk_leaf_serialized_w)
  );

  // Classifier outputs describe PBMT/PMA legality only.  PMP is a later
  // pre-target authorization stage and must poison final provenance without
  // suppressing an older PBMT page fault.
  assign walk_leaf_attr_valid_w = walk_leaf_classified_attr_valid_w &&
                                  !walk_leaf_pmp_fault_w;
  assign walk_leaf_class_w = walk_leaf_attr_valid_w ?
      walk_leaf_classified_class_w : `OOO_MEM_CLASS_RSVD;

  // F9：priv-spec 要求 PMP 适用于地址翻译期间对页表的隐式访问。旧实现只检查最终数据 PA
  // (req/leaf)，每级 PTE 读地址（walk_pte_addr_w）绕过了 PMP——OS 把页表放入对 S 态拒绝
  // 的 PMP 区时硬件仍能读出 PTE，绕过 M 态隔离。这里对 PTE 读地址补 PMP 检查（8B 读，
  // 隐式页表访问按 S-mode 检查；U/S 发起者在 PMP 上都不能借 walker 提权）。
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

  // T4F / PTW-PMP-G1：A/D 回写是另一笔隐式 8B store，PTE READ 许可
  // 不能推出 WRITE 许可。独立 checker 只落在 S_WALK_R leaf 决策锥；deny
  // 直接形成原 load/store 的 access fault，绝不进入 S_AD_UPDATE/呈现 AW/W。
  wire walk_pte_write_pmp_fault_w;
  PmpChecker u_walk_pte_write_pmp_checker (
    .paddr_i(walk_pte_addr_w),
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
      dtlb_leaf_ok_w && !walk_leaf_pmp_fault_w && walk_ad_needed_w &&
      walk_pte_write_pmp_fault_w;

  OooDataWordCache #(
    .ENABLE_PEER_INVALIDATE(ENABLE_PEER_INVALIDATE)
  ) u_dcache (
    .clk(clk),
    .rst(rst),
    .dma_invalidate_all_i(dcache_dma_invalidate_all_i),
    .peer_invalidate_valid_i(peer_invalidate_valid_i),
    .peer_invalidate_addr_i(peer_invalidate_addr_i),
    .peer_invalidate_wstrb_i(peer_invalidate_wstrb_i),
    .req_lookup_addr_i(req_cache_addr_w),
    .req_nbytes_i(req_access_size_w),
    .req_cacheable_o(req_addr_dcacheable_w),
    .req_line_cross_o(req_line_cross_w),
    .walk_lookup_addr_i(walk_leaf_paddr_w),
    .walk_cacheable_o(walk_leaf_addr_dcacheable_w),
    // 单读口两拍协议: 发射拍状态互斥 mux(req/walk/A-D 三源), 判决在 S_LOOKUP。
    .lookup_en_i(dcache_lookup_en_w),
    .lookup_addr_i(dcache_lookup_addr_w),
    .lookup_hit_o(dcache_lookup_hit_w),
    .lookup_line_o(dcache_lookup_line_w),
    .fill_valid_i(dcache_read_fill_valid_w),
    .fill_addr_i({paddr_q[`XLEN-1:3], 3'b000}),
    .fill_data_i(lsu_axi_rdata_i),
    // 【store RMW·二期赎回】只有真 cacheable store B-ok 走 2 拍
    // RMW write-update; B-error/PBMT NC/IO/HW A/D 终点一律无条件失效。
    .store_commit_i(dcache_store_commit_w),
    .store_rmw_en_i(dcache_store_rmw_en_w),
    .store_cacheable_i(dcache_store_cacheable_w),
    // HW A/D: every PTE-write terminal maintains the PTE address; data-store
    // terminals maintain the translated store PA.
    .store_addr_i(dcache_store_addr_w),
    .store_wdata_i(dcache_store_wdata_w),
    .store_wstrb_i(dcache_store_wstrb_w),
    .rmw_busy_o(dcache_rmw_busy_w)
  );

  // (sim 统计探针已精确化：NpcSimTop 改为 access 打一拍 + 直接采判决拍
  //  dcache_lookup_hit_final_w，此处原粘滞近似探针删除。)

  // 【刀 M】ready = 寄存站可收新请求(空位, 或本拍 advance 腾位=back-to-back)。
  // ① `!flush_i` 必须保留(关键决策, 非可选): MIQ 的 flush 分支是 else-if 结构,
  //    flush 拍 push 被忽略——若 flush 拍允许 fire 会产生"桥内有事务、MIQ 无记账"
  //    (rsp 无主/序配对破坏)。ready 含 !flush_i ⟺ MIQ 不 push, 保住寄存站项↔MIQ
  //    项双射(BRG-NOFIRE-FLUSH 断言化)。flush_i 为寄存源, 不损时序。
  // ② drop_rsp_q 退出 ready: drain 窗口寄存站可提前收下 correct-path 请求排队
  //    (免费 skid, 部分抵消 +1 拍 CPI), advance 由 state 门天然挡住。
  // ③ rmw_busy 退出 ready(迁入 stage_advance): RMW 判决拍请求可进站, lookup/rsp
  //    推迟——bubble 数不变, 观察点从 ready 压制变寄存站保持。
  // 【mmu_flush 打拍配套】mmu_flush 拍同样压 ready(复位分支吞 fire 请求防悬空)
  assign mem0_req_ready_o = !flush_i && !mmu_flush_i &&
                            (!stg_valid_q || stage_advance_w);

  // 刀D 融合拍: hit 拍组合交付 rsp(payload 与现行锁存表达式同源); 反压/kill 拍
  // 融合关闭走落寄存 S_RESP 路径(天然 skid)。
  assign mem0_rsp_valid_o =
      ((state_q == S_RESP) && (!cpu_kill_w || nokill_busy_w)) ||
      lookup_hit_fusion_w;
  assign mem0_rsp_rdata_o = lookup_hit_fusion_w ?
      (dcache_lookup_line_w >> {paddr_q[2:0], 3'b000}) : rsp_rdata_q;
  assign mem0_rsp_error_o = lookup_hit_fusion_w ? 1'b0 : rsp_error_q;
  assign mem0_rsp_page_fault_o = lookup_hit_fusion_w ? 1'b0 : rsp_page_fault_q;
  assign mem0_rsp_attr_valid_o = access_attr_valid_q;
  assign mem0_rsp_class_o = access_attr_valid_q ? access_class_q :
                            `OOO_MEM_CLASS_RSVD;
  assign mem0_rsp_cacheable_o = mem0_rsp_attr_valid_o &&
                                (mem0_rsp_class_o == `OOO_MEM_CLASS_CACHED);
  // A fused lookup response belongs to the active transaction; a held S_RESP
  // belongs to its distinct response snapshot.  Neither path reconstructs from
  // the current request bus or ROB tag.
  assign mem0_rsp_owner_kind_o = lookup_hit_fusion_w ?
      active_owner_kind_q : rsp_owner_kind_q;
  assign mem0_rsp_owner_token_o = lookup_hit_fusion_w ?
      active_owner_token_q : rsp_owner_token_q;
  assign mem0_rsp_mmu_epoch_o = lookup_hit_fusion_w ?
      active_mmu_epoch_q : rsp_mmu_epoch_q;
  assign mem0_rsp_fault_tval_o = lookup_hit_fusion_w ?
      active_fault_tval_q : rsp_fault_tval_q;
  reg [31:0] owner_residency_mask_r;
  always @(*) begin
    owner_residency_mask_r = 32'b0;
    if (state_q != S_IDLE)
      owner_residency_mask_r[active_owner_token_q] = 1'b1;
    if (stg_valid_q)
      owner_residency_mask_r[stg_owner_token_q] = 1'b1;
    // S_RESP is intentionally listed as a distinct semantic residency even
    // though the exact invariant normally aliases its token with active.
    if (state_q == S_RESP)
      owner_residency_mask_r[rsp_owner_token_q] = 1'b1;
  end
  assign mem0_owner_residency_mask_o = owner_residency_mask_r;
  // Q0 MMU-epoch barrier fact: do not register this output.  Registering it
  // would leave one false-idle cycle after a request enters the station.  The
  // expression intentionally excludes READY/fire/equality/live context inputs
  // so a future context lock cannot create a quiet/ready combinational loop.
  wire bridge_registered_facts_idle_w =
      (state_q == S_IDLE) &&
      !stg_valid_q &&
      !drop_rsp_q &&
      !nokill_busy_w &&
      !aw_done_q &&
      !w_done_q &&
      !dcache_rmw_busy_w &&
      (owner_residency_mask_r == 32'b0);
  assign mem0_idle_o = bridge_registered_facts_idle_w;
  assign translate_active_o = ctx_translate_w;

  // 【SRAM 同步读】read miss 的 AR 从 fire 拍推迟到 S_LOOKUP 判决拍(晚 1 拍),
  // 地址/strb 统一取锁存 paddr_q/wstrb_q, 原 req_* 直通支路随之删除。
  // S_LOOKUP 项的 !rmw_busy 与 FSM 转移侧一致(读口互斥安全网, 状态互斥下恒真)。
  // T4E: once an AR has been presented and stalled, AXI requires VALID and
  // every payload field to remain stable through the eventual handshake.
  // S_WALK_AR/S_READ_ADDR are registered owners, so flush/drop must drain the
  // address handshake instead of combinationally withdrawing VALID.  Only the
  // one-cycle speculative S_LOOKUP arm may be cancelled before it is owned by
  // S_READ_ADDR; a stalled S_LOOKUP AR moves to S_READ_ADDR at the same edge.
  assign lsu_axi_arvalid_o =
      (active_owner_verified_q && (state_q == S_WALK_AR) &&
       !walk_pte_pmp_fault_w) ||
      (active_owner_verified_q && (state_q == S_READ_ADDR)) ||
      (active_owner_verified_q && !cpu_kill_w && (state_q == S_DEVICE_WAIT) &&
       mem0_device_release_i && !mem0_device_cancel_i) ||
      (active_owner_verified_q && !cpu_kill_w &&
       (state_q == S_LOOKUP) && !dcache_lookup_hit_final_w &&
       !dcache_rmw_busy_w);
  wire [`XLEN-1:0] pend_read_araddr_w =
      read_exact_q ? paddr_q : {paddr_q[`XLEN-1:3], 3'b000};
  assign lsu_axi_araddr_o =
      (state_q == S_WALK_AR) ? walk_pte_addr_w : pend_read_araddr_w;
  // 【AXI4 化 S3】walk/cache line 读=8B；uncacheable 或跨 line 的 exact 读保留
  // 原始 PA/size。下游 lane adapter 负责标准 byte-lane 映射；MMIO 不得被扩大读。
  assign lsu_axi_arsize_o =
      (state_q == S_WALK_AR) ? 3'd3 :
      (read_exact_q ? axsize_from_bytes(access_size_from_wstrb(wstrb_q)) : 3'd3);
  assign lsu_axi_rready_o = (state_q == S_WALK_R) || (state_q == S_READ_DATA);
  // HW A/D: S_AD_UPDATE 复用写通道写回 leaf PTE(awaddr=PTE 地址, wdata=置位 PTE, wstrb=全 8B),
  // 写必达(不受 cpu_kill 门控; flush 由 FSM 完成写后 drop, 幂等)。S_WRITE_REQ
  // 也一旦进入 registered VALID owner 后必须逐通道保持到 handshake；即使两个
  // 通道都尚未 fire，flush 也不能撤回已经呈现的 VALID/payload。
  assign lsu_axi_awvalid_o =
      (active_owner_verified_q && (state_q == S_WRITE_REQ) && !aw_done_q) ||
      (active_owner_verified_q && (state_q == S_AD_UPDATE) && !aw_done_q);
  assign lsu_axi_awaddr_o =
      (state_q == S_AD_UPDATE) ? walk_pte_addr_w : paddr_q;
  assign lsu_axi_wvalid_o =
      (active_owner_verified_q && (state_q == S_WRITE_REQ) && !w_done_q) ||
      (active_owner_verified_q && (state_q == S_AD_UPDATE) && !w_done_q);
  assign lsu_axi_wdata_o = (state_q == S_AD_UPDATE) ? ad_pte_q : wdata_q;
  assign lsu_axi_wstrb_o = (state_q == S_AD_UPDATE) ? {`STRB_W{1'b1}} : wstrb_q;
  // 所有 store 与 HW A/D 写回均等 B；聚合 BRESP 是唯一完成点。
  assign lsu_axi_bready_o =
      (state_q == S_WRITE_RESP) || (state_q == S_AD_UPDATE);

  // Exact owner drop terminals.  These predicates mirror the real FSM edges
  // that retire a killed transport owner; flush itself is not a terminal when
  // an AXI R/B drain remains outstanding.
  reg active_drop_terminal_r;
  always @(*) begin
    active_drop_terminal_r = 1'b0;
    // S_RESP/LOOKUP kill is already a terminal independent of whether a
    // queued nokill station can advance.  Keep this raw terminal independent
    // of station advancement and response backpressure: downstream terminal
    // credit otherwise forms a cross-module combinational loop back here.
    if (cpu_kill_w && !nokill_busy_w) begin
      case (state_q)
        S_SQ_QUERY,
        S_LOOKUP,
        S_DEVICE_WAIT,
        S_OWNER_HOLD,
        S_RESP: active_drop_terminal_r = 1'b1;
        S_WALK_AR: active_drop_terminal_r =
            walk_pte_pmp_fault_w || !active_owner_verified_q;
        S_WALK_R,
        S_READ_DATA: active_drop_terminal_r = lsu_axi_rvalid_i;
        // Entering S_WRITE_REQ has already presented registered AW/W owners;
        // cancellation is no longer legal, so the exact terminal is B only.
        S_WRITE_REQ: active_drop_terminal_r =
            !active_owner_verified_q && !write_escaped_q;
        S_WRITE_RESP: active_drop_terminal_r = lsu_axi_bvalid_i;
        S_AD_UPDATE: active_drop_terminal_r =
            (aw_done_q || aw_fire_w) && (w_done_q || w_fire_w) &&
            lsu_axi_bvalid_i;
        default: active_drop_terminal_r = 1'b0;
      endcase
    end
  end

  // A non-nokill station cannot advance on flush by construction, so its raw
  // terminal must not read the downstream advance/ready cone.
  wire station_drop_terminal_w =
      flush_i && stg_valid_q && !stg_nokill_q;
  assign mem0_drop0_valid_o = active_drop_terminal_r;
  wire drop0_uses_rsp_snapshot_w = (state_q == S_RESP);
  assign mem0_drop0_owner_kind_o = drop0_uses_rsp_snapshot_w ?
      rsp_owner_kind_q : active_owner_kind_q;
  assign mem0_drop0_owner_token_o = drop0_uses_rsp_snapshot_w ?
      rsp_owner_token_q : active_owner_token_q;
  assign mem0_drop0_mmu_epoch_o = drop0_uses_rsp_snapshot_w ?
      rsp_mmu_epoch_q : active_mmu_epoch_q;
  assign mem0_drop0_fault_tval_o = drop0_uses_rsp_snapshot_w ?
      rsp_fault_tval_q : active_fault_tval_q;
  assign mem0_drop1_valid_o = station_drop_terminal_w;
  assign mem0_drop1_owner_kind_o = stg_owner_kind_q;
  assign mem0_drop1_owner_token_o = stg_owner_token_q;
  assign mem0_drop1_mmu_epoch_o = stg_mmu_epoch_q;
  assign mem0_drop1_fault_tval_o = stg_fault_tval_q;

  // 【刀 M】accept_request 的调用时机从 req fire 拍改为 stage_advance 拍, 全部
  // 数据源经 req_*_w 簇取自寄存站(stg_*); 分流决策文本与旧版逐字一致。
  task automatic accept_request;
    begin
      write_q <= req_write_w;
      paging_q <= req_translate_w;
      access_priv_q <= req_priv_w;
      access_svpbmt_en_q <= svpbmt_en_i;
      addr_q <= req_addr_w;
      paddr_q <= req_cache_addr_w;
      read_cross_q <= req_line_cross_w;
      read_exact_q <= !req_dcacheable_w || req_line_cross_w;
      access_attr_valid_q <= req_effective_attr_valid_w;
      access_class_q <= req_effective_class_w;
      wdata_q <= req_wdata_w;
      wstrb_q <= req_wstrb_w;
      probe_q <= stg_probe_q && req_write_w;
      nokill_q <= stg_nokill_q;
      active_owner_kind_q <= stg_owner_kind_q;
      active_owner_token_q <= stg_owner_token_q;
      active_mmu_epoch_q <= stg_mmu_epoch_q;
      active_fault_tval_q <= stg_fault_tval_q;
      // Preload the distinct response snapshot exactly once with the accepted
      // owner.  It remains frozen through S_RESP stalls and is independently
      // selected from active on the response port.
      rsp_owner_kind_q <= stg_owner_kind_q;
      rsp_owner_token_q <= stg_owner_token_q;
      rsp_mmu_epoch_q <= stg_mmu_epoch_q;
      rsp_fault_tval_q <= stg_fault_tval_q;
      active_owner_verified_q <= station_expected_identity_match_w;
      verified_owner_kind_q <= mem0_station_expected_owner_kind_i;
      verified_owner_token_q <= mem0_station_expected_owner_token_i;
      verified_mmu_epoch_q <= mem0_station_expected_mmu_epoch_i;
      write_escaped_q <= 1'b0;
      rsp_rdata_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
      rsp_page_fault_q <= 1'b0;
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
      if (!station_expected_identity_match_w) begin
        state_q <= S_OWNER_HOLD;
      end else if (req_typed_page_fault_w) begin
        rsp_error_q <= 1'b1;
        rsp_page_fault_q <= 1'b1;
        state_q <= S_RESP;
      end else if (req_translate_w && req_dtlb_perm_fault_w) begin
        rsp_error_q <= 1'b1;
        rsp_page_fault_q <= 1'b1;
        state_q <= S_RESP;
      end else if (req_translate_w && !req_dtlb_hit_w &&
                   !canonical_sv39(req_addr_w)) begin
        rsp_error_q <= 1'b1;
        rsp_page_fault_q <= 1'b1;
        state_q <= S_RESP;
      end else if (req_data_pmp_fault_w) begin
        rsp_error_q <= 1'b1;
        rsp_page_fault_q <= 1'b0;
        state_q <= S_RESP;
      end else if (req_data_pma_fault_w) begin
        rsp_error_q <= 1'b1;
        rsp_page_fault_q <= 1'b0;
        state_q <= S_RESP;
      end else if (req_translate_w && !req_dtlb_hit_w) begin
        walk_level_q <= 2'd2;
        walk_ppn_q <= satp_i[43:0];
        state_q <= S_WALK_AR;
      end else if (req_write_w) begin
        if (stg_probe_q) begin
          // 【LSQ·SQ 切换】write 探测:翻译+PMP 已过, 不写内存, PA 经 rsp_rdata 回传。
          rsp_rdata_q <= req_cache_addr_w;
          state_q <= S_RESP;
        end else begin
          state_q <= S_WRITE_REQ;
        end
      end else begin
        // v8t/F3 ordinary loads stop at a registered final-PA boundary before
        // any cache/NC/IO target admission.  Atomic/LR reads retain their
        // existing ROB-head singleton routing and never query the plain SQ.
        // v8u/F4 is the sole exception to the extra state: when the retiring
        // hit and exact next-head SQ allow already fired this station's
        // synchronous cache lookup, the newly active owner enters S_LOOKUP
        // directly so next cycle's SRAM result has the matching active Q.
        if (stg_owner_kind_q == MEM_OWNER_LOAD) begin
          state_q <= station_sq_lookahead_lookup_fire_w ?
                     S_LOOKUP : S_SQ_QUERY;
        end else if (req_dcacheable_w) begin
          state_q <= S_LOOKUP;
        end else if (req_nc_w) begin
          state_q <= S_READ_ADDR;
        end else if (req_io_w) begin
          state_q <= S_DEVICE_WAIT;
        end else begin
          rsp_error_q <= 1'b1;
          rsp_page_fault_q <= 1'b0;
          state_q <= S_RESP;
        end
      end
    end
  endtask

  // Capture only while the edge-old expected owner is still exact.  A later
  // MIQ advance may make active_expected_identity_match_w false, but the
  // escaped write still owns one conservative invalidate at its real B.  B
  // terminal wins over same-cycle capture because the authority is consumed.
  always @(posedge clk) begin
    if (rst)
      killed_write_maintenance_authorized_q <= 1'b0;
    else if (stage_advance_w)
      killed_write_maintenance_authorized_q <= 1'b0;
    else if (data_store_b_terminal_w || ad_update_b_terminal_w)
      killed_write_maintenance_authorized_q <= 1'b0;
    else if (killed_write_maintenance_capture_w)
      killed_write_maintenance_authorized_q <= 1'b1;
  end

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
      ad_pte_q <= {`XLEN{1'b0}};
      read_cross_q <= 1'b0;
      read_exact_q <= 1'b0;
      access_attr_valid_q <= 1'b0;
      access_class_q <= `OOO_MEM_CLASS_RSVD;
      wdata_q <= {`XLEN{1'b0}};
      wstrb_q <= {`STRB_W{1'b0}};
      rsp_rdata_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
      rsp_page_fault_q <= 1'b0;
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
      drop_rsp_q <= 1'b0;
      probe_q <= 1'b0;
      nokill_q <= 1'b0;
      active_owner_kind_q <= 2'b00;
      active_owner_token_q <= 5'b0;
      active_mmu_epoch_q <= 2'b0;
      active_fault_tval_q <= {`XLEN{1'b0}};
      rsp_owner_kind_q <= 2'b00;
      rsp_owner_token_q <= 5'b0;
      rsp_mmu_epoch_q <= 2'b0;
      rsp_fault_tval_q <= {`XLEN{1'b0}};
      active_owner_verified_q <= 1'b0;
      verified_owner_kind_q <= 2'b00;
      verified_owner_token_q <= 5'b0;
      verified_mmu_epoch_q <= 2'b0;
      write_escaped_q <= 1'b0;
    end else begin
      if (aw_fire_w || w_fire_w)
        write_escaped_q <= 1'b1;
      // 【刀 M】寄存站项进 FSM(stage_advance 拍)最高优先: 只可能发生在 S_IDLE 或
      // S_RESP&&rsp_ready(两态 drop_rsp_q 恒 0、无遗留清理义务, done 位由
      // accept_request 清零)。nokill 项经 (!cpu_kill_w||stg_nokill_q) 豁免, flush
      // 拍也照常进 FSM(写必达; 此时若在 S_RESP, 被顶替的旧响应本就属被 kill 事务,
      // 与旧 flush-drain 臂的丢弃行为一致); 非 nokill 项 flush/drop 拍 advance=0,
      // FSM 走下方 drain/正常分支。
      if (stage_advance_w) begin
        accept_request();
      end else if (cpu_kill_w && !nokill_busy_w) begin
      case (state_q)
        S_IDLE: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end

        // SQ query/cache lookup 尚未形成跨拍 external owner，flush 可当拍取消。
        S_SQ_QUERY,
        S_LOOKUP: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end

        // 尚未 release 的 device read 从未呈现 AR，可在 global flush/drop
        // 拍直接释放；ROB-walk selective kill 走正常分支的 cancel quiet rsp。
        S_DEVICE_WAIT: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end

        S_OWNER_HOLD: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end

        // T4E AXI AR hold：注册地址态一旦对外呈现 VALID，即使 flush/drop
        // 也必须保持 VALID+payload 到 READY。握手后进入 R drain，残响应只吞不交付。
        // PTE 地址 PMP 已拒绝时从未呈现 VALID，可直接释放。
        S_WALK_AR: begin
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          if (walk_pte_pmp_fault_w) begin
            state_q <= S_IDLE;
            drop_rsp_q <= 1'b0;
          end else begin
            state_q <= lsu_axi_arready_i ? S_WALK_R : S_WALK_AR;
            drop_rsp_q <= 1'b1;
          end
        end

        S_READ_ADDR: begin
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          state_q <= lsu_axi_arready_i ? S_READ_DATA : S_READ_ADDR;
          drop_rsp_q <= 1'b1;
        end

        S_WALK_R, S_READ_DATA: begin
          // 【AXI4 化 S1】flush 拍不再依赖 xbar abort 吞 R——本地自吞: R 到达拍
          // 释放, 未到则置 drop_rsp_q 持械等待(rready 随 state 保持; dcache/DTLB
          // fill 经 !cpu_kill_w 门 drain 期自动禁止)。
          if (lsu_axi_rvalid_i) begin
            state_q <= S_IDLE;
            drop_rsp_q <= 1'b0;
          end else begin
            drop_rsp_q <= 1'b1;
          end
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
        end

        S_WRITE_REQ: begin
          // AW/W are independent registered owners.  Even when neither has
          // fired yet, a flush must hold both VALID/payloads until their own
          // handshakes, then wait for the unique B terminal before dropping.
          aw_done_q <= aw_done_q || aw_fire_w;
          w_done_q <= w_done_q || w_fire_w;
          drop_rsp_q <= 1'b1;
          state_q <= ((aw_done_q || aw_fire_w) &&
                      (w_done_q || w_fire_w)) ? S_WRITE_RESP : S_WRITE_REQ;
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

        S_AD_UPDATE: begin
          // A/D 写必达: 完成 AW/W + 吸收 B 后 drop(不续访问; re-exec 幂等重走)。
          if (aw_fire_w) aw_done_q <= 1'b1;
          if (w_fire_w) w_done_q <= 1'b1;
          if ((aw_done_q || aw_fire_w) && (w_done_q || w_fire_w) &&
              lsu_axi_bvalid_i) begin
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            drop_rsp_q <= 1'b0;
            state_q <= S_IDLE;
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
          // 【刀 M】accept 调用已上提为 stage_advance 最高优先分支, 本臂只清 done 位。
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
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
                         pte_reserved_fault(lsu_axi_rdata_i, walk_level_q) ||
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
              end else if (walk_leaf_page_fault_w) begin
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b1;
                state_q <= S_RESP;
              end else if (walk_leaf_pmp_fault_w) begin
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b0;
                state_q <= S_RESP;
              end else if (walk_leaf_pma_fault_w) begin
                // 最终 data PA 未落入真实实现窗口：在任何 A/D 写或 data
                // AW/W/AR 前形成原 load/store 的 access fault。
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b0;
                state_q <= S_RESP;
              end else if (walk_ad_needed_w &&
                           walk_pte_write_pmp_fault_w) begin
                // PTE 可读但不可写：原始 load/store 报 access fault，不是 page fault。
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b0;
                state_q <= S_RESP;
              end else if (walk_ad_needed_w) begin
                // HW A/D: 真权限过但 A/D 不足 → 写回置位 PTE(S_AD_UPDATE), B 后再续访问。
                ad_pte_q <= lsu_axi_rdata_i | PTE_A_BIT |
                            (write_q ? PTE_D_BIT : {`XLEN{1'b0}});
                paddr_q <= walk_leaf_paddr_w;
                read_exact_q <= !walk_leaf_dcacheable_w || read_cross_q;
                access_attr_valid_q <= walk_leaf_attr_valid_w;
                access_class_q <= walk_leaf_class_w;
                aw_done_q <= 1'b0;
                w_done_q <= 1'b0;
                state_q <= S_AD_UPDATE;
              end else begin
                paddr_q <= walk_leaf_paddr_w;
                read_exact_q <= !walk_leaf_dcacheable_w || read_cross_q;
                access_attr_valid_q <= walk_leaf_attr_valid_w;
                access_class_q <= walk_leaf_class_w;
                if (write_q) begin
                  if (probe_q) begin
                    // 【LSQ·SQ 切换】PTW 完成的 write 探测同样短路:PA 回传, 不写。
                    rsp_rdata_q <= walk_leaf_paddr_w;
                    rsp_error_q <= 1'b0;
                    rsp_page_fault_q <= 1'b0;
                    state_q <= S_RESP;
                  end else begin
                    state_q <= S_WRITE_REQ;
                  end
                end else begin
                  if (active_owner_kind_q == MEM_OWNER_LOAD)
                    state_q <= S_SQ_QUERY;
                  else if (walk_leaf_dcacheable_w)
                    state_q <= S_LOOKUP;
                  else if (walk_leaf_nc_w)
                    state_q <= S_READ_ADDR;
                  else if (walk_leaf_io_w)
                    state_q <= S_DEVICE_WAIT;
                  else begin
                    rsp_error_q <= 1'b1;
                    rsp_page_fault_q <= 1'b0;
                    state_q <= S_RESP;
                  end
                end
              end
            end else begin
              walk_ppn_q <= lsu_axi_rdata_i[53:10];
              walk_level_q <= walk_level_q - 2'd1;
              state_q <= S_WALK_AR;
            end
          end
        end

        S_SQ_QUERY: begin
          // Decision is side-effect free.  forward is captured into the
          // existing held-response Q; allow captures either the synchronous
          // cache lookup or a registered NC/IO target state.  An exact replay
          // handshake transfers the owner into the bank-local backend retry
          // holder and releases this bridge; an uncredited/invalid decision
          // keeps every active payload bit stable.
          if (mem0_sq_query_valid_o && sq_query_decision_onehot_w &&
              mem0_sq_query_forward_i) begin
            rsp_rdata_q <= mem0_sq_query_forward_data_i;
            rsp_error_q <= 1'b0;
            rsp_page_fault_q <= 1'b0;
            state_q <= S_RESP;
          end else if (mem0_sq_query_valid_o &&
                       sq_query_decision_onehot_w &&
                       mem0_sq_query_allow_i) begin
            if (access_cacheable_w)
              state_q <= S_LOOKUP;
            else if (access_nc_w)
              state_q <= S_READ_ADDR;
            else if (access_io_w)
              state_q <= S_DEVICE_WAIT;
            else begin
              rsp_error_q <= 1'b1;
              rsp_page_fault_q <= 1'b0;
              state_q <= S_RESP;
            end
          end else if (sq_query_retry_fire_w) begin
            state_q <= S_IDLE;
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            drop_rsp_q <= 1'b0;
          end else begin
            state_q <= S_SQ_QUERY;
          end
        end

        S_DEVICE_WAIT: begin
          // cancel 必须先于 release：即便上游合同被破坏，也不能把 killed
          // device read 变成外部 AR side effect。
          if (mem0_device_cancel_i) begin
            rsp_rdata_q <= {`XLEN{1'b0}};
            rsp_error_q <= 1'b0;
            rsp_page_fault_q <= 1'b0;
            state_q <= S_RESP;
          end else if (mem0_device_release_i) begin
            state_q <= lsu_axi_arready_i ? S_READ_DATA : S_READ_ADDR;
          end
        end

        S_LOOKUP: begin
          // 判决拍: SRAM rdata 对应上拍锁存的 lookup 地址(该地址已同拍锁进
          // paddr_q)。命中数据统一按 paddr_q[2:0] 右移出窗口视图, 跨线由
          // read_cross_q 阻断按 miss 走 AXI 窗口读。
          if (dcache_lookup_hit_final_w) begin
            if (lookup_hit_fusion_w && rsp_ready_w) begin
              // 刀D 融合拍: rsp 本拍已组合交付。有下一项时本臂不执行(最高优先
              // advance 分支已 accept_request 决定去向); 走到这里=站空或 rmw
              // 占口, 回 IDLE 等下一项。
              state_q <= S_IDLE;
              aw_done_q <= 1'b0;
              w_done_q <= 1'b0;
            end else begin
              // rsp 反压 或 kill 拍(融合谓词含 !cpu_kill): 落寄存进 S_RESP
              // (kill 事务由 S_RESP 的 rsp_valid 门与 drain 逻辑照常清理)
              rsp_rdata_q <= dcache_lookup_line_w >> {paddr_q[2:0], 3'b000};
              rsp_error_q <= 1'b0;
              rsp_page_fault_q <= 1'b0;
              state_q <= S_RESP;
            end
          end else begin
            // miss/跨线: 当拍发 AR(arvalid 组合含 S_LOOKUP-miss 项)。转移条件
            // 与 arvalid 的 !rmw_busy 门一致, 保持 AR 握手协议自洽。
            state_q <= (lsu_axi_arready_i && !dcache_rmw_busy_w) ?
                       S_READ_DATA : S_READ_ADDR;
          end
        end

        S_READ_ADDR: begin
          if (lsu_axi_arready_i) begin
            state_q <= S_READ_DATA;
          end
        end

        S_READ_DATA: begin
          if (lsu_axi_rvalid_i) begin
            // cache line: AXI 返回对齐 line → CPU 视图右移窗口偏移；
            // exact(uncacheable/跨 line): lane adapter 已重组为低位窗口，原样返回。
            rsp_rdata_q <= read_exact_q ? lsu_axi_rdata_i :
                           (lsu_axi_rdata_i >> {paddr_q[2:0], 3'b000});
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

        S_AD_UPDATE: begin
          // HW A/D 写(AW/W→B): 写成功后 TLB 已填置位 PTE(ad_update_b_ok_w), 续原 leaf 访问决策。
          if (aw_fire_w) aw_done_q <= 1'b1;
          if (w_fire_w) w_done_q <= 1'b1;
          if ((aw_done_q || aw_fire_w) && (w_done_q || w_fire_w) &&
              lsu_axi_bvalid_i) begin
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            if (lsu_axi_bresp_i != 2'b00) begin
              rsp_error_q <= 1'b1;         // A/D 写总线异常 → access fault
              rsp_page_fault_q <= 1'b0;
              // PTE maintenance failed before any data target existed.  Do
              // not leak the candidate data PA class as post-target provenance.
              access_attr_valid_q <= 1'b0;
              access_class_q <= `OOO_MEM_CLASS_RSVD;
              state_q <= S_RESP;
            end else if (write_q) begin
              if (probe_q) begin
                rsp_rdata_q <= paddr_q;    // probe 短路: 返回 PA(=walk_leaf_paddr)
                rsp_error_q <= 1'b0;
                rsp_page_fault_q <= 1'b0;
                state_q <= S_RESP;
              end else begin
                state_q <= S_WRITE_REQ;    // 真 store: 续写数据
              end
            end else begin
              if (active_owner_kind_q == MEM_OWNER_LOAD)
                state_q <= S_SQ_QUERY;
              else if (access_cacheable_w)
                state_q <= S_LOOKUP;
              else if (access_nc_w)
                state_q <= S_READ_ADDR;
              else if (access_io_w)
                state_q <= S_DEVICE_WAIT;
              else begin
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b0;
                state_q <= S_RESP;
              end
            end
          end
        end

        S_RESP: begin
          // 【刀 M】back-to-back accept 已上提为 stage_advance 分支(该分支同时覆盖
          // rsp 消费拍), 本臂只处理"rsp 被消费且无寄存站项可进"的回 IDLE。
          if (rsp_ready_w) begin
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            state_q <= S_IDLE;
          end
        end

        S_OWNER_HOLD: begin
          state_q <= S_OWNER_HOLD;
        end

        default: begin
          state_q <= S_IDLE;
        end
      endcase
      end
    end
  end

  // 【刀 M】寄存站装载/弹出/flush。fire 优先(fire ⇒ ready ⇒ 空位或本拍 advance
  // 腾位, 覆盖写即弹出+重装); flush 拍 ready 含 !flush_i 恒无 fire; nokill 项对
  // flush 免疫——可在 flush 拍经 advance 弹出, 或原地存活等待 advance(写必达)。
  // payload 在 valid=0 拍留脏(全核 valid-only 惯例, 消费方不得读)。
  always @(posedge clk) begin
    if (rst) begin
      stg_valid_q <= 1'b0;
      stg_addr_q <= {`XLEN{1'b0}};
      stg_wdata_q <= {`XLEN{1'b0}};
      stg_wstrb_q <= {`STRB_W{1'b0}};
      stg_write_q <= 1'b0;
      stg_probe_q <= 1'b0;
      stg_pretrans_q <= 1'b0;
      stg_nokill_q <= 1'b0;
      stg_attr_valid_q <= 1'b0;
      stg_class_q <= `OOO_MEM_CLASS_RSVD;
      stg_owner_kind_q <= 2'b00;
      stg_owner_token_q <= 5'b0;
      stg_mmu_epoch_q <= 2'b0;
      stg_fault_tval_q <= {`XLEN{1'b0}};
    end else if (mem0_req_fire_w) begin
      stg_valid_q <= 1'b1;
      stg_addr_q <= mem0_req_addr_i;
      stg_wdata_q <= mem0_req_wdata_i;
      stg_wstrb_q <= mem0_req_wstrb_i;
      stg_write_q <= mem0_req_write_i;
      stg_probe_q <= mem0_req_probe_i;
      stg_pretrans_q <= mem0_req_pretrans_i;
      stg_nokill_q <= mem0_req_nokill_i;
      stg_attr_valid_q <= mem0_req_attr_valid_i;
      stg_class_q <= mem0_req_attr_valid_i ? mem0_req_class_i :
                     `OOO_MEM_CLASS_RSVD;
      stg_owner_kind_q <= mem0_req_owner_kind_i;
      stg_owner_token_q <= mem0_req_owner_token_i;
      stg_mmu_epoch_q <= mem0_req_mmu_epoch_i;
      stg_fault_tval_q <= mem0_req_fault_tval_i;
    end else if (stage_advance_w) begin
      stg_valid_q <= 1'b0;
    end else if (flush_i && !stg_nokill_q) begin
      stg_valid_q <= 1'b0;
    end
  end

`ifdef OOO_ASSERT
  // V8W OOO-4 selective branch-recovery contract.  The recovery authority is
  // the conjunction of the MIQ head, owner tracker and bridge sticky identity;
  // an effective-killed bit alone may not alter transport ownership.  Owners
  // that have not reached AXI terminate immediately, while an accepted R beat
  // is drained exactly once and may not start another read transaction.
  reg assert_selective_preaxi_terminal_r;
  reg assert_selective_r_terminal_r;
  always @(posedge clk) begin
    if (rst) begin
      assert_selective_preaxi_terminal_r <= 1'b0;
      assert_selective_r_terminal_r <= 1'b0;
    end else begin
      if (active_selective_recovery_w &&
          (!mem0_expected_effective_killed_i || nokill_q ||
           !active_expected_identity_match_w ||
           !active_tracker_identity_match_w ||
           !active_sticky_identity_match_w)) begin
        $error("[V8W-RECOVERY-AUTHORITY] selective recovery lacked exact active identity @%0t",
               $time);
        $fatal;
      end
      if (active_selective_recovery_w &&
          ((state_q == S_SQ_QUERY) || (state_q == S_LOOKUP) ||
           (state_q == S_DEVICE_WAIT) || (state_q == S_OWNER_HOLD) ||
           (state_q == S_RESP)) &&
          (!mem0_drop0_valid_o || mem0_rsp_valid_o ||
           dcache_lookup_en_w || lsu_axi_arvalid_o ||
           lsu_axi_awvalid_o || lsu_axi_wvalid_o)) begin
        $error("[V8W-RECOVERY-PREAXI] recovered owner leaked a target or lacked terminal @%0t",
               $time);
        $fatal;
      end
      if (active_selective_recovery_w &&
          ((state_q == S_WALK_R) || (state_q == S_READ_DATA)) &&
          lsu_axi_rvalid_i && !mem0_drop0_valid_o) begin
        $error("[V8W-RECOVERY-R-DRAIN] accepted recovered R lacked exact terminal @%0t",
               $time);
        $fatal;
      end
      if (assert_selective_preaxi_terminal_r && (state_q != S_IDLE)) begin
        $error("[V8W-RECOVERY-PREAXI-RELEASE] pre-AXI owner did not release @%0t",
               $time);
        $fatal;
      end
      if (assert_selective_r_terminal_r &&
          ((state_q != S_IDLE) || lsu_axi_arvalid_o || mem0_rsp_valid_o)) begin
        $error("[V8W-RECOVERY-R-NO-CONTINUE] drained R continued transport @%0t",
               $time);
        $fatal;
      end
      assert_selective_preaxi_terminal_r <= active_selective_recovery_w &&
          ((state_q == S_SQ_QUERY) || (state_q == S_LOOKUP) ||
           (state_q == S_DEVICE_WAIT) || (state_q == S_OWNER_HOLD));
      // drop_rsp_q is the registered drain obligation.  Include it so a
      // delayed R terminal is checked even after the live MIQ kill view has
      // disappeared; the active owner snapshot remains authoritative until
      // that beat is consumed.
      assert_selective_r_terminal_r <=
          (active_selective_recovery_w || drop_rsp_q) &&
          ((state_q == S_WALK_R) || (state_q == S_READ_DATA)) &&
          lsu_axi_rvalid_i;
    end
  end

  // Q0 bridge-idle contract.  Safety rejects a false quiet while any local
  // registered owner/channel/macro-tail fact remains.  Completeness rejects a
  // sticky-low implementation that would deadlock the later epoch barrier.
  // External AXI RVALID/BVALID inputs are deliberately absent: with no local
  // owner, unsolicited environment inputs are not bridge residency.
  always @(posedge clk) begin
    if (!rst) begin
      if ((state_q != S_IDLE) &&
          (^active_owner_token_q === 1'bx)) begin
        $error("[V8L-BRIDGE-ACTIVE-TOKEN-KNOWN] active owner token is unknown @%0t",
               $time);
        $fatal;
      end
      if (stg_valid_q && (^stg_owner_token_q === 1'bx)) begin
        $error("[V8L-BRIDGE-STAGE-TOKEN-KNOWN] station owner token is unknown @%0t",
               $time);
        $fatal;
      end
      if ((state_q == S_RESP) &&
          (^rsp_owner_token_q === 1'bx)) begin
        $error("[V8L-BRIDGE-RSP-TOKEN-KNOWN] response owner token is unknown @%0t",
               $time);
        $fatal;
      end
      if (active_owner_verified_q &&
          (^verified_owner_token_q === 1'bx)) begin
        $error("[V8L-BRIDGE-VERIFIED-TOKEN-KNOWN] verified owner token is unknown @%0t",
               $time);
        $fatal;
      end
      if (mem0_idle_o &&
          ((state_q != S_IDLE) || stg_valid_q || drop_rsp_q ||
           nokill_busy_w || aw_done_q || w_done_q || dcache_rmw_busy_w ||
           mem0_owner_query_valid_o || mem0_station_query_valid_o ||
           (|mem0_owner_residency_mask_o) ||
           mem0_rsp_valid_o || mem0_drop0_valid_o || mem0_drop1_valid_o ||
           lsu_axi_arvalid_o || lsu_axi_rready_o ||
           lsu_axi_awvalid_o || lsu_axi_wvalid_o || lsu_axi_bready_o)) begin
        $error("[S2-Q0-BRG-IDLE-SAFETY] idle exposed residual owner/channel @%0t",
               $time);
        $fatal;
      end
      if (((state_q == S_IDLE) && !stg_valid_q && !drop_rsp_q &&
           !nokill_busy_w && !aw_done_q && !w_done_q &&
           !dcache_rmw_busy_w && (owner_residency_mask_r == 32'b0)) &&
          !mem0_idle_o) begin
        $error("[S2-Q0-BRG-IDLE-LIVENESS] empty registered state did not report idle @%0t",
               $time);
        $fatal;
      end
    end
  end

  reg assert_pte_write_deny_r;
  always @(posedge clk) begin
    if (rst) begin
      assert_pte_write_deny_r <= 1'b0;
    end else begin
      if (walk_ad_write_deny_w &&
          (lsu_axi_awvalid_o || lsu_axi_wvalid_o)) begin
        $error("[MEM-PTW-PMP-WRITE] denied PTE write exposed AW/W @%0t", $time);
        $fatal;
      end
      if (assert_pte_write_deny_r &&
          ((state_q != S_RESP) || !rsp_error_q || rsp_page_fault_q)) begin
        $error("[MEM-PTW-PMP-WRITE] deny did not become access-fault response @%0t",
               $time);
        $fatal;
      end
      assert_pte_write_deny_r <= !cpu_kill_w && walk_ad_write_deny_w;
    end
  end

  // v8u/F4 typed final-PA lookup authorization.  Every cache lookup is owned
  // by one exact SQ allow.  The normal source is active final-PA Q; the only
  // alternative is the registered station final-PA lookahead on a retiring
  // cache hit.  PTW/D-TLB/A-D transport may not bypass either query source.
  always @(posedge clk) begin
    if (!rst) begin
      if (active_sq_query_read_lookup_fire_w && !access_cacheable_w) begin
        $error("[V8T-SQ-QUERY-CACHE-CLASS] non-CACHED query issued lookup @%0t",
               $time);
        $fatal;
      end
      if (station_sq_lookahead_lookup_fire_w && !req_dcacheable_w) begin
        $error("[V8U-SQ-LOOKAHEAD-CACHE-CLASS] non-CACHED station query issued lookup @%0t",
               $time);
        $fatal;
      end
      if (dcache_lookup_en_w &&
          (!(active_sq_query_read_lookup_fire_w ||
             station_sq_lookahead_lookup_fire_w) ||
           !mem0_sq_query_valid_o ||
           !mem0_sq_query_allow_i || !sq_query_decision_onehot_w)) begin
        $error("[V8T-SQ-QUERY-CACHE-AUTH] lookup bypassed exact SQ allow @%0t",
               $time);
        $fatal;
      end
      if (active_sq_query_read_lookup_fire_w &&
          (dcache_lookup_addr_w !== paddr_q)) begin
        $error("[V8T-SQ-QUERY-CACHE-PA] lookup address differs from final PA Q @%0t",
               $time);
        $fatal;
      end
      if (station_sq_lookahead_lookup_fire_w &&
          (dcache_lookup_addr_w !== req_cache_addr_w)) begin
        $error("[V8U-SQ-LOOKAHEAD-CACHE-PA] station lookup address differs from final PA @%0t",
               $time);
        $fatal;
      end
      if (dcache_read_fill_valid_w && !access_cacheable_w) begin
        $error("[S1-TYPED-DCACHE-FILL] non-CACHED transaction attempted fill @%0t",
               $time);
        $fatal;
      end
      if (dcache_store_rmw_en_w && !access_cacheable_w) begin
        $error("[S1-TYPED-DCACHE-RMW] non-CACHED store attempted RMW @%0t", $time);
        $fatal;
      end
    end
  end

  // 【store RMW 读口互斥】RMW 判决拍宏口被占时，SQ allow lookup/fill/
  // S_LOOKUP 判决均不得抢用该口。
  always @(posedge clk) begin
    if (!rst && dcache_rmw_busy_w &&
        (sq_query_read_lookup_fire_w || dcache_read_fill_valid_w ||
         (state_q == S_LOOKUP))) begin
      $error("[MEM-RMW-PORT] RMW 判决拍出现 query-lookup/fill/S_LOOKUP: state=%0d query=%b fill=%b @%0t",
             state_q, sq_query_read_lookup_fire_w,
             dcache_read_fill_valid_w, $time);
      $fatal;
    end
  end

  // 【刀 M·寄存站契约断言族】全部立即断言形态(SVA 命中 0 教训)。
  reg assert_stg_valid_r;
  reg assert_fire_r;
  reg assert_nokill_hold_r;
  reg assert_req_pma_deny_r;
  reg assert_walk_pma_deny_r;
  reg [`XLEN-1:0] assert_stg_addr_r;
  reg [`XLEN-1:0] assert_stg_wdata_r;
  reg [`STRB_W-1:0] assert_stg_wstrb_r;
  reg [6:0] assert_stg_attr_r;
  reg assert_pretrans_advance_r;
  reg assert_pretrans_attr_valid_r;
  reg [1:0] assert_pretrans_class_r;
  reg assert_ar_stalled_r;
  reg [`XLEN-1:0] assert_araddr_r;
  reg [3:0] assert_arid_r;
  reg [7:0] assert_arlen_r;
  reg [2:0] assert_arsize_r;
  reg [1:0] assert_arburst_r;
  reg [2:0] assert_arprot_r;
  reg [72:0] assert_stg_owner_r;
  reg assert_rsp_stalled_r;
  reg [72:0] assert_rsp_owner_r;
  reg assert_sq_query_replay_r;
  reg assert_sq_query_forward_r;
  reg assert_sq_query_retry_fire_r;
  reg assert_station_fast_lookup_r;
  reg [72:0] assert_station_fast_owner_r;
  reg [`XLEN-1:0] assert_station_fast_paddr_r;
  reg [83:0] assert_sq_query_payload_r;
  reg [72:0] assert_sq_query_owner_r;
  reg [`XLEN-1:0] assert_sq_query_forward_data_r;
  reg assert_aw_stalled_r;
  reg [`XLEN-1:0] assert_awaddr_r;
  reg [3:0] assert_awid_r;
  reg [7:0] assert_awlen_r;
  reg [2:0] assert_awsize_r;
  reg [1:0] assert_awburst_r;
  reg assert_w_stalled_r;
  reg [`XLEN-1:0] assert_wdata_r;
  reg [`STRB_W-1:0] assert_wstrb_r;
  reg assert_wlast_r;
  always @(posedge clk) begin
    if (rst) begin
      assert_stg_valid_r <= 1'b0;
      assert_fire_r <= 1'b0;
      assert_nokill_hold_r <= 1'b0;
      assert_req_pma_deny_r <= 1'b0;
      assert_walk_pma_deny_r <= 1'b0;
      assert_ar_stalled_r <= 1'b0;
      assert_rsp_stalled_r <= 1'b0;
      assert_sq_query_replay_r <= 1'b0;
      assert_sq_query_forward_r <= 1'b0;
      assert_sq_query_retry_fire_r <= 1'b0;
      assert_station_fast_lookup_r <= 1'b0;
      assert_station_fast_owner_r <= 73'b0;
      assert_station_fast_paddr_r <= {`XLEN{1'b0}};
      assert_aw_stalled_r <= 1'b0;
      assert_w_stalled_r <= 1'b0;
      assert_pretrans_advance_r <= 1'b0;
    end else begin
      // BRG-NOFIRE-FLUSH: flush 拍不得 fire(ready 含 !flush_i ⟺ 寄存站↔MIQ 双射,
      // MIQ flush 分支是 else-if、flush 拍 push 被忽略)。
      if (mem0_req_fire_w && flush_i) begin
        $error("[BRG-NOFIRE-FLUSH] flush 拍出现 mem0_req fire @%0t", $time);
        $fatal;
      end
      if (mem0_req_fire_w && (mem0_req_owner_kind_i == 2'b11)) begin
        $display("[S2-G1-BRG-REQ-RESERVED] reserved owner entered station @%0t", $time);
        $fatal;
      end
      if (stage_advance_w && !station_expected_identity_match_w) begin
        $display("[S2-G1-BRG-STATION-OWNER] station tuple mismatched edge-old tracker @%0t", $time);
        $fatal;
      end
      if ((state_q != S_IDLE) &&
          (!active_rsp_identity_consistent_w ||
           !active_rsp_tval_echo_match_w)) begin
        $display("[S2-G1-BRG-ACTIVE-RSP-ECHO] active/rsp provenance diverged @%0t", $time);
        $fatal;
      end
      if (active_owner_verified_q && !active_sticky_identity_match_w) begin
        $display("[S2-G1-BRG-STICKY-OWNER] active identity diverged from verified snapshot @%0t", $time);
        $fatal;
      end
      if ((state_q != S_IDLE) && active_owner_verified_q &&
          !active_tracker_identity_match_w) begin
        $display("[S2-G1-BRG-ACTIVE-TRACKER] active tuple mismatched edge-old tracker @%0t", $time);
        $fatal;
      end
      if (mem0_rsp_valid_o && !visible_rsp_expected_identity_match_w) begin
        $display("[S2-G1-BRG-RSP-OWNER] response transport mismatched edge-old owner @%0t", $time);
        $fatal;
      end
      if (mem0_rsp_valid_o && visible_rsp_expected_identity_match_w &&
          mem0_expected_tval_valid_i &&
          !visible_rsp_expected_tval_echo_match_w) begin
        $display("[S2-G1-BRG-RSP-TVAL-ECHO] response tval drifted from MIQ capture @%0t", $time);
        $fatal;
      end
      if (mem0_drop0_valid_o && mem0_drop1_valid_o &&
          (mem0_drop0_owner_token_o == mem0_drop1_owner_token_o)) begin
        $display("[S2-G1-BRG-DROP-DUP] active and station drops named one token @%0t", $time);
        $fatal;
      end
      if (mem0_rsp_valid_o && mem0_drop0_valid_o) begin
        $display("[S2-G1-BRG-RSP-DROP-OVERLAP] active owner responded and dropped together @%0t", $time);
        $fatal;
      end
      if (!fsm_normal_w && (dtlb_fill_valid_w || dcache_read_fill_valid_w)) begin
        $display("[S2-G1-BRG-KILL-FILL] killed owner changed DTLB/D-cache fill state @%0t", $time);
        $fatal;
      end
      if (dcache_store_commit_w && !active_expected_identity_match_w &&
          !killed_write_maintenance_authorized_w) begin
        $display("[S2-G1-BRG-KILLED-WRITE-AUTH] cache maintenance lacked exact/current or captured owner authority @%0t", $time);
        $fatal;
      end
      if (killed_write_maintenance_authorized_w &&
          (dtlb_fill_valid_w || dcache_read_fill_valid_w ||
           dcache_store_rmw_en_w)) begin
        $display("[S2-G1-BRG-KILLED-WRITE-SIDEEFFECT] killed escaped write attempted fill/RMW @%0t", $time);
        $fatal;
      end
      if ((peer_maintenance_valid_o !== dcache_store_commit_w) ||
          (peer_maintenance_valid_o &&
           ((peer_maintenance_addr_o !== dcache_store_addr_w) ||
            (peer_maintenance_wstrb_o !== dcache_store_wstrb_w)))) begin
        $error("[BRG-PEER-MAINT-AUTH] exported peer maintenance drifted from authorized local facts @%0t",
               $time);
        $fatal;
      end
      if (dcache_store_commit_w &&
          !normalized_wstrb_legal(dcache_store_wstrb_w)) begin
        $error("[BRG-PEER-WSTRB] authorized maintenance mask is not normalized: addr=%h wstrb=%h @%0t",
               dcache_store_addr_w, dcache_store_wstrb_w, $time);
        $fatal;
      end
      // BRG-ADV-NODROP: advance 只可能发生在 drop_rsp_q=0 的拍
      // (S_IDLE/S_RESP 态 drop 恒 0 的 FSM 不变量, 上提 accept 分支依赖它)。
      if (stage_advance_w && drop_rsp_q) begin
        $error("[BRG-ADV-NODROP] drop_rsp_q=1 拍出现 stage_advance @%0t", $time);
        $fatal;
      end
      if (mem0_req_fire_w &&
          (mem0_req_cacheable_i !==
           (mem0_req_attr_valid_i &&
            (mem0_req_class_i == `OOO_MEM_CLASS_CACHED)))) begin
        $error("[S1-TYPED-LEGACY-REQ] request Boolean diverged from typed payload @%0t",
               $time);
        $fatal;
      end
      if (mem0_req_fire_w && !mem0_req_pretrans_i &&
          ((mem0_req_attr_valid_i !== 1'b0) ||
           (mem0_req_class_i !== `OOO_MEM_CLASS_RSVD))) begin
        $error("[S1-TYPED-ORDINARY-REQ] VA request carried forged final-PA attr @%0t",
               $time);
        $fatal;
      end
      if (stage_advance_w && stg_pretrans_q &&
          !req_pretrans_attr_admitted_r) begin
        $error("[S1-TYPED-PRETRANS-INVALID] drain lacks legal typed provenance @%0t",
               $time);
        $fatal;
      end
      if (assert_pretrans_advance_r &&
          ((access_attr_valid_q !== assert_pretrans_attr_valid_r) ||
           (access_class_q !== assert_pretrans_class_r))) begin
        $error("[S1-TYPED-PRETRANS-ECHO] bridge changed SQ drain typed provenance @%0t",
               $time);
        $fatal;
      end
      if (assert_req_pma_deny_r &&
          ((state_q != S_RESP) || !rsp_error_q || rsp_page_fault_q ||
           lsu_axi_arvalid_o || lsu_axi_awvalid_o || lsu_axi_wvalid_o)) begin
        $error("[MEM-PMA-DIRECT] deny did not become quiet access-fault response @%0t",
               $time);
        $fatal;
      end
      if (assert_walk_pma_deny_r &&
          ((state_q != S_RESP) || !rsp_error_q || rsp_page_fault_q ||
           lsu_axi_arvalid_o || lsu_axi_awvalid_o || lsu_axi_wvalid_o)) begin
        $error("[MEM-PMA-WALK] leaf deny did not become quiet access-fault response @%0t",
               $time);
        $fatal;
      end
      // F3 active query and F4 exact station lookahead are the only lookup
      // owners; PTW receive, A/D B and an unqualified station advance remain
      // forbidden direct lookup sources.
      if (dcache_lookup_en_w &&
          !((state_q == S_SQ_QUERY) ||
            station_sq_lookahead_lookup_fire_w)) begin
        $error("[V8U-SQ-QUERY-LOOKUP-STATE] 非授权 query 拍出现 dcache lookup @%0t",
               $time);
        $fatal;
      end
      // V8T query is a registered, exact, bank-local decision point.  The
      // decision must be X-safe one-hot and cannot itself look like a target,
      // response, or terminal event.
      if (mem0_sq_query_valid_o) begin
        if (station_sq_lookahead_query_w) begin
          if ((state_q != S_LOOKUP) || !lookup_hit_fusion_w ||
              !station_expected_identity_match_w ||
              (stg_owner_kind_q != MEM_OWNER_LOAD) ||
              !req_effective_attr_valid_w || !req_dcacheable_w ||
              req_line_cross_w ||
              !normalized_wstrb_legal(stg_wstrb_q) ||
              ({mem0_sq_query_owner_kind_o,
                mem0_sq_query_owner_token_o,
                mem0_sq_query_mmu_epoch_o,
                mem0_sq_query_paddr_o,
                mem0_sq_query_attr_valid_o,
                mem0_sq_query_class_o,
                mem0_sq_query_wstrb_o} !==
               {stg_owner_kind_q, stg_owner_token_q,
                stg_mmu_epoch_q, req_cache_addr_w,
                req_effective_attr_valid_w, req_effective_class_w,
                stg_wstrb_q})) begin
            $display("[V8U-SQ-LOOKAHEAD-EXACT] station query escaped exact final-PA payload state=%0d token=%0d @%0t",
                     state_q, stg_owner_token_q, $time);
            $fatal;
          end
        end else if ((state_q != S_SQ_QUERY) ||
                     (active_owner_kind_q != MEM_OWNER_LOAD) ||
                     !sq_query_owner_exact_w || cpu_kill_w ||
                     !access_attr_valid_q ||
                     !normalized_wstrb_legal(wstrb_q) ||
                     ({mem0_sq_query_owner_kind_o,
                       mem0_sq_query_owner_token_o,
                       mem0_sq_query_mmu_epoch_o,
                       mem0_sq_query_paddr_o,
                       mem0_sq_query_attr_valid_o,
                       mem0_sq_query_class_o,
                       mem0_sq_query_wstrb_o} !==
                      {active_owner_kind_q, active_owner_token_q,
                       active_mmu_epoch_q, paddr_q, access_attr_valid_q,
                       access_class_q, wstrb_q})) begin
          $display("[V8T-SQ-QUERY-EXACT] query escaped registered exact load payload state=%0d kind=%0d expected=%0b tracker=%0b sticky=%0b killed=%0b cpu_kill=%0b attr=%0b class=%0d strb=%h @%0t",
                   state_q, active_owner_kind_q,
                   active_expected_identity_match_w,
                   active_tracker_identity_match_w,
                   active_sticky_identity_match_w,
                   mem0_expected_effective_killed_i, cpu_kill_w,
                   access_attr_valid_q, access_class_q, wstrb_q, $time);
          $fatal;
        end
        if (station_sq_lookahead_lookup_fire_w &&
            (!rsp_ready_w || !stage_advance_w)) begin
          $display("[V8U-SQ-LOOKAHEAD-READY] station lookup fired without current response advance @%0t",
                   $time);
          $fatal;
        end
        case ({mem0_sq_query_allow_i, mem0_sq_query_forward_i,
               mem0_sq_query_replay_i})
          3'b100,
          3'b010,
          3'b001: begin end
          default: begin
            $display("[V8T-SQ-QUERY-ONEHOT] decision is not known one-hot @%0t",
                     $time);
            $fatal;
          end
        endcase
        if (!station_sq_lookahead_query_w &&
            (mem0_sq_query_forward_i || mem0_sq_query_replay_i) &&
            (dcache_lookup_en_w || lsu_axi_arvalid_o ||
             lsu_axi_awvalid_o || lsu_axi_wvalid_o ||
             mem0_rsp_valid_o || mem0_drop0_valid_o ||
             peer_maintenance_valid_o)) begin
          $display("[V8T-SQ-QUERY-NO-TARGET] forward/replay leaked a target or terminal event @%0t",
                   $time);
          $fatal;
        end
        if (station_sq_lookahead_query_w &&
            (mem0_sq_query_retry_ready_i ||
             ((mem0_sq_query_forward_i || mem0_sq_query_replay_i) &&
              dcache_lookup_en_w) ||
             (mem0_sq_query_allow_i && !dcache_lookup_en_w))) begin
          $display("[V8U-SQ-LOOKAHEAD-AUTH] station decision violated lookup/retry contract @%0t",
                   $time);
          $fatal;
        end
      end
      // A station fast lookup is captured by the synchronous macro on the
      // same edge as station->active.  Before this edge can retire the result,
      // the active Q, final PA and macro pending bit must still name that B.
      if (assert_station_fast_lookup_r &&
          ((state_q != S_LOOKUP) ||
           ({active_owner_kind_q, active_owner_token_q,
             active_mmu_epoch_q, active_fault_tval_q} !==
            assert_station_fast_owner_r) ||
           (paddr_q !== assert_station_fast_paddr_r) ||
           !access_cacheable_w || !u_dcache.lookup_pend_q)) begin
        $display("[V8U-SQ-LOOKAHEAD-RETURN-OWNER] synchronous cache result lost station owner state=%0d token=%0d @%0t",
                 state_q, active_owner_token_q, $time);
        $fatal;
      end
      // A replay keeps the entire active query payload registered.  SQ state
      // may change and select a different decision next cycle, but no payload
      // bit or exact owner may drift while the bridge remains live.
      if (assert_sq_query_replay_r && !cpu_kill_w &&
          (!mem0_sq_query_valid_o ||
           ({mem0_sq_query_owner_kind_o,
             mem0_sq_query_owner_token_o,
             mem0_sq_query_mmu_epoch_o,
             mem0_sq_query_paddr_o,
             mem0_sq_query_attr_valid_o,
             mem0_sq_query_class_o,
             mem0_sq_query_wstrb_o} !== assert_sq_query_payload_r))) begin
        $display("[V8T-SQ-QUERY-REPLAY-HOLD] replay changed or lost query payload @%0t",
                 $time);
        $fatal;
      end
      if (assert_sq_query_retry_fire_r &&
          ((state_q != S_IDLE) || mem0_owner_query_valid_o ||
           mem0_rsp_valid_o || mem0_drop0_valid_o ||
           dcache_lookup_en_w || lsu_axi_arvalid_o ||
           lsu_axi_awvalid_o || lsu_axi_wvalid_o)) begin
        $display("[V8T-SQ-QUERY-RETRY-HANDOFF] retry did not release bridge quietly @%0t",
                 $time);
        $fatal;
      end
      // Forward capture is unconditional at the query edge.  On the next
      // cycle it is either the exact held response, or a same-snapshot drop
      // when a kill arrives; it never waits for WB/FP credit to capture data.
      if (assert_sq_query_forward_r) begin
        if (!cpu_kill_w) begin
          if (!mem0_rsp_valid_o ||
              (mem0_rsp_rdata_o !== assert_sq_query_forward_data_r) ||
              mem0_rsp_error_o || mem0_rsp_page_fault_o ||
              ({mem0_rsp_owner_kind_o, mem0_rsp_owner_token_o,
                mem0_rsp_mmu_epoch_o, mem0_rsp_fault_tval_o} !==
               assert_sq_query_owner_r)) begin
            $display("[V8T-SQ-QUERY-FORWARD-CAPTURE] forward did not become exact held response @%0t",
                     $time);
            $fatal;
          end
        end else if (!mem0_drop0_valid_o ||
                     ({mem0_drop0_owner_kind_o,
                       mem0_drop0_owner_token_o,
                       mem0_drop0_mmu_epoch_o,
                       mem0_drop0_fault_tval_o} !==
                      assert_sq_query_owner_r)) begin
          $display("[V8T-SQ-QUERY-FORWARD-DROP] killed captured forward lacked exact drop @%0t",
                   $time);
          $fatal;
        end
      end
      // BRG-STG-HOLD: 上拍占用且未重装(fire), 本拍仍占用 ⇒ 字段冻结(PSR-HOLD 型)。
      if (assert_stg_valid_r && !assert_fire_r && stg_valid_q &&
          ((stg_addr_q != assert_stg_addr_r) ||
           (stg_wdata_q != assert_stg_wdata_r) ||
           (stg_wstrb_q != assert_stg_wstrb_r) ||
           ({stg_write_q, stg_probe_q, stg_pretrans_q, stg_nokill_q,
             stg_attr_valid_q, stg_class_q} !=
            assert_stg_attr_r) ||
           ({stg_owner_kind_q, stg_owner_token_q, stg_mmu_epoch_q,
             stg_fault_tval_q} != assert_stg_owner_r))) begin
        $error("[BRG-STG-HOLD] stall 拍寄存站字段被改写 @%0t", $time);
        $fatal;
      end
      // BRG-STG-NOKILL: flush 拍未 advance 的 nokill 项次拍必须存活(写必达)。
      if (assert_nokill_hold_r && !stg_valid_q) begin
        $error("[BRG-STG-NOKILL] flush 拍 nokill 寄存站项被丢弃 @%0t", $time);
        $fatal;
      end
      // MEM-AR-HOLD：上拍 VALID&&!READY 后，本拍必须继续 VALID 且 payload
      // 逐位冻结；覆盖 WALK/DATA 两类 owner 以及 flush/drop/repeated-flush。
      if (assert_ar_stalled_r &&
          (!lsu_axi_arvalid_o ||
           (lsu_axi_araddr_o !== assert_araddr_r) ||
           (lsu_axi_arid_o !== assert_arid_r) ||
           (lsu_axi_arlen_o !== assert_arlen_r) ||
           (lsu_axi_arsize_o !== assert_arsize_r) ||
           (lsu_axi_arburst_o !== assert_arburst_r) ||
           (lsu_axi_arprot_o !== assert_arprot_r))) begin
        $error("[MEM-AR-HOLD] stalled AR withdrew VALID or changed payload @%0t",
               $time);
        $fatal;
      end
      // A held bridge response may either remain valid with a frozen tuple or
      // be converted by flush into the exact active drop terminal.  It may not
      // disappear or be relabeled.
      if (assert_rsp_stalled_r) begin
        if (mem0_rsp_valid_o) begin
          if ({mem0_rsp_owner_kind_o, mem0_rsp_owner_token_o,
               mem0_rsp_mmu_epoch_o, mem0_rsp_fault_tval_o} !=
              assert_rsp_owner_r) begin
            $display("[S2-G1-BRG-RSP-HOLD] stalled response tuple changed @%0t", $time);
            $fatal;
          end
        end else if (mem0_drop0_valid_o) begin
          if ({mem0_drop0_owner_kind_o, mem0_drop0_owner_token_o,
               mem0_drop0_mmu_epoch_o, mem0_drop0_fault_tval_o} !=
              assert_rsp_owner_r) begin
            $display("[S2-G1-BRG-RSP-DROP-ECHO] held response drop used wrong tuple @%0t", $time);
            $fatal;
          end
        end else begin
          $display("[S2-G1-BRG-RSP-HOLD] stalled response vanished without fire/drop @%0t", $time);
          $fatal;
        end
      end
      if (assert_aw_stalled_r &&
          (!lsu_axi_awvalid_o ||
           (lsu_axi_awaddr_o !== assert_awaddr_r) ||
           (lsu_axi_awid_o !== assert_awid_r) ||
           (lsu_axi_awlen_o !== assert_awlen_r) ||
           (lsu_axi_awsize_o !== assert_awsize_r) ||
           (lsu_axi_awburst_o !== assert_awburst_r))) begin
        $display("[S2-G1-BRG-AW-HOLD] stalled AW withdrew VALID or changed payload @%0t", $time);
        $fatal;
      end
      if (assert_w_stalled_r &&
          (!lsu_axi_wvalid_o ||
           (lsu_axi_wdata_o !== assert_wdata_r) ||
           (lsu_axi_wstrb_o !== assert_wstrb_r) ||
           (lsu_axi_wlast_o !== assert_wlast_r))) begin
        $display("[S2-G1-BRG-W-HOLD] stalled W withdrew VALID or changed payload @%0t", $time);
        $fatal;
      end
      // MEM-DEVICE-OWNER: wait/cancel 绝不能呈现 data AR；release/cancel
      // 互斥。registered S_READ_ADDR owner 已形成后仍由 MEM-AR-HOLD 管理。
      if (mem0_device_release_i && mem0_device_cancel_i) begin
        $error("[MEM-DEVICE-OWNER] release/cancel overlap @%0t", $time);
        $fatal;
      end
      if ((state_q == S_DEVICE_WAIT) &&
          ((!mem0_device_release_i || mem0_device_cancel_i) &&
           lsu_axi_arvalid_o)) begin
        $error("[MEM-DEVICE-OWNER] unowned/killed device read presented AR: pa=%h @%0t",
               paddr_q, $time);
        $fatal;
      end
      if ((state_q == S_DEVICE_WAIT) &&
          (write_q || !access_io_w || !read_exact_q)) begin
        $error("[MEM-DEVICE-OWNER] invalid wait payload: write=%b attr=%b class=%b exact=%b pa=%h @%0t",
               write_q, access_attr_valid_q, access_class_q, read_exact_q,
               paddr_q, $time);
        $fatal;
      end
      if ((state_q == S_DEVICE_WAIT) && access_nc_w) begin
        $error("[S1-TYPED-NC-NO-WAIT] NC read entered IO head-wait @%0t", $time);
        $fatal;
      end
      if ((state_q == S_RESP) && !access_attr_valid_q &&
          (access_class_q != `OOO_MEM_CLASS_RSVD)) begin
        $error("[S1-TYPED-FAULT-POISON] invalid response retained routable class @%0t",
               $time);
        $fatal;
      end
      if (access_attr_valid_q &&
          !((access_class_q == `OOO_MEM_CLASS_CACHED) ||
            (access_class_q == `OOO_MEM_CLASS_NC) ||
            (access_class_q == `OOO_MEM_CLASS_IO))) begin
        $error("[S1-TYPED-ACTIVE-LEGAL] active transaction has illegal class @%0t",
               $time);
        $fatal;
      end
      if (mem0_rsp_cacheable_o !==
          (mem0_rsp_attr_valid_o &&
           (mem0_rsp_class_o == `OOO_MEM_CLASS_CACHED))) begin
        $error("[S1-TYPED-LEGACY-RSP] response Boolean diverged from typed payload @%0t",
               $time);
        $fatal;
      end
      assert_stg_valid_r <= stg_valid_q;
      assert_fire_r <= mem0_req_fire_w;
      assert_nokill_hold_r <= flush_i && stg_valid_q && stg_nokill_q &&
                              !stage_advance_w;
      assert_req_pma_deny_r <= stage_advance_w && req_data_pma_fault_w;
      assert_walk_pma_deny_r <=
          fsm_normal_w && dtlb_leaf_ok_w && walk_leaf_pma_fault_w;
      assert_pretrans_advance_r <= stage_advance_w && stg_pretrans_q &&
                                   req_pretrans_attr_admitted_r;
      assert_pretrans_attr_valid_r <= req_effective_attr_valid_w;
      assert_pretrans_class_r <= req_effective_class_w;
      assert_ar_stalled_r <= lsu_axi_arvalid_o && !lsu_axi_arready_i;
      assert_rsp_stalled_r <= mem0_rsp_valid_o && !mem0_rsp_ready_i;
      assert_sq_query_replay_r <= active_sq_query_valid_w &&
                                  sq_query_decision_onehot_w &&
                                  mem0_sq_query_replay_i &&
                                  !mem0_sq_query_retry_ready_i;
      assert_sq_query_forward_r <= active_sq_query_valid_w &&
                                   sq_query_decision_onehot_w &&
                                   mem0_sq_query_forward_i;
      assert_sq_query_retry_fire_r <= sq_query_retry_fire_w;
      assert_station_fast_lookup_r <=
          station_sq_lookahead_lookup_fire_w;
      assert_station_fast_owner_r <=
          {stg_owner_kind_q, stg_owner_token_q, stg_mmu_epoch_q,
           stg_fault_tval_q};
      assert_station_fast_paddr_r <= req_cache_addr_w;
      assert_sq_query_payload_r <=
          {mem0_sq_query_owner_kind_o, mem0_sq_query_owner_token_o,
           mem0_sq_query_mmu_epoch_o, mem0_sq_query_paddr_o,
           mem0_sq_query_attr_valid_o, mem0_sq_query_class_o,
           mem0_sq_query_wstrb_o};
      assert_sq_query_owner_r <=
          {active_owner_kind_q, active_owner_token_q, active_mmu_epoch_q,
           active_fault_tval_q};
      assert_sq_query_forward_data_r <= mem0_sq_query_forward_data_i;
      assert_aw_stalled_r <= lsu_axi_awvalid_o && !lsu_axi_awready_i;
      assert_w_stalled_r <= lsu_axi_wvalid_o && !lsu_axi_wready_i;
      assert_araddr_r <= lsu_axi_araddr_o;
      assert_arid_r <= lsu_axi_arid_o;
      assert_arlen_r <= lsu_axi_arlen_o;
      assert_arsize_r <= lsu_axi_arsize_o;
      assert_arburst_r <= lsu_axi_arburst_o;
      assert_arprot_r <= lsu_axi_arprot_o;
      assert_rsp_owner_r <= {mem0_rsp_owner_kind_o, mem0_rsp_owner_token_o,
                             mem0_rsp_mmu_epoch_o, mem0_rsp_fault_tval_o};
      assert_awaddr_r <= lsu_axi_awaddr_o;
      assert_awid_r <= lsu_axi_awid_o;
      assert_awlen_r <= lsu_axi_awlen_o;
      assert_awsize_r <= lsu_axi_awsize_o;
      assert_awburst_r <= lsu_axi_awburst_o;
      assert_wdata_r <= lsu_axi_wdata_o;
      assert_wstrb_r <= lsu_axi_wstrb_o;
      assert_wlast_r <= lsu_axi_wlast_o;
      assert_stg_addr_r <= stg_addr_q;
      assert_stg_wdata_r <= stg_wdata_q;
      assert_stg_wstrb_r <= stg_wstrb_q;
      assert_stg_attr_r <= {stg_write_q, stg_probe_q, stg_pretrans_q,
                            stg_nokill_q, stg_attr_valid_q, stg_class_q};
      assert_stg_owner_r <= {stg_owner_kind_q, stg_owner_token_q,
                             stg_mmu_epoch_q, stg_fault_tval_q};
    end
  end
`endif

endmodule
