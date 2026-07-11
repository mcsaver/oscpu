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
  // 【LSQ·SQ 切换】三个事务属性位(spec ooo-lsq-implementation-plan.md §3.6):
  //   probe: write 探测——翻译+PMP 走完后不写内存, PA 经 rsp_rdata 回传(fault 路径复用);
  //   pretrans: 地址已是 PA(SQ drain 落存)——跳过翻译与 PMP(probe 拍已查);
  //   nokill: 事务不可被 flush 丢弃(已退休 store 的落存写必达)。
  // 三位全 0 时本模块行为与旧版逐位一致。
  input mem0_req_probe_i,
  input mem0_req_pretrans_i,
  input mem0_req_nokill_i,
  input [`XLEN-1:0] mem0_req_addr_i,
  input [`XLEN-1:0] mem0_req_wdata_i,
  input [`STRB_W-1:0] mem0_req_wstrb_i,
  output mem0_rsp_valid_o,
  input mem0_rsp_ready_i,
  output [`XLEN-1:0] mem0_rsp_rdata_o,
  output mem0_rsp_error_o,
  output mem0_rsp_page_fault_o,
  // 当前特权/satp 上下文下数据访问是否经 Sv39 翻译(供后端 load-vs-SQ 判定选 blind 模式)
  output translate_active_o,

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
  // data access(ARPROT[2]=0)、AWSIZE 恒 8B(WSTRB 仍是字节权威)。
  assign lsu_axi_arid_o = 4'd1;
  assign lsu_axi_arlen_o = 8'd0;
  assign lsu_axi_arburst_o = 2'b01;
  assign lsu_axi_arprot_o = 3'b000;
  assign lsu_axi_awid_o = 4'd1;
  assign lsu_axi_awlen_o = 8'd0;
  assign lsu_axi_awsize_o = 3'd3;
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
  // B1 访存解耦：cacheable-PMEM store 在数据落 PMEM(AW&W fire)后即报完成、提前推进，
  // 其滞后的 AXI B 由 bpend_q 跟踪器在后台吸收，使紧随的 load 可与 B drain 重叠。
  // 仅对 PMEM(bresp 恒 OK)解耦；MMIO/可错 store 仍等 B 以保精确异常(MEM-I3)。详见
  // design/specs/ooo-mem-axi-bridge-fsm.md 与 design/arch/mem-store-decouple.md。
  reg bpend_q;
  // 【LSQ·SQ 切换】当前事务属性(advance 拍锁存, 每次 accept 覆盖)。pretrans 的效果
  // (跳过翻译/PMP)全部在 advance 拍组合完成, 无需再寄存进 FSM。
  reg probe_q;
  reg nokill_q;
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
  // 【line-dcache】本读事务是否跨 8B line(跨线走窗口读不 fill; 不跨线发对齐
  // AR, 回填 line 并把窗口视图给 CPU)
  reg read_cross_q;

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
  wire cpu_kill_w = flush_i || drop_rsp_q;
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
  wire lookup_hit_fusion_w;
  wire stage_advance_w = stg_valid_q && !dcache_rmw_busy_w &&
                         ((state_q == S_IDLE) ||
                          ((state_q == S_RESP) && rsp_ready_w) ||
                          (lookup_hit_fusion_w && rsp_ready_w)) &&
                         (!cpu_kill_w || stg_nokill_q);
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
      (pte_reserved_fault(req_dtlb_pte_w, svpbmt_en_i, req_dtlb_level_w) ||
       data_permission_fault(req_dtlb_pte_w, req_write_w, req_priv_w,
                             mstatus_i));
  // HW A/D: TLB 命中项若 A/D 不足(如 load 填的 A=1/D=0 项被 store 命中)→ 视为 miss,
  // 走 walk 触发 S_AD_UPDATE 置位后重填。TLB 命中仅当真权限过 且 A/D 已足。
  wire req_dtlb_ad_needed_w =
      req_dtlb_context_hit_w && !req_dtlb_perm_fault_w &&
      data_ad_update_needed(req_dtlb_pte_w, req_write_w);
  wire req_dtlb_hit_w =
      req_dtlb_context_hit_w && !req_dtlb_perm_fault_w && !req_dtlb_ad_needed_w;
  wire [`XLEN-1:0] req_cache_addr_w =
      req_dtlb_hit_w ? req_translated_paddr_w : req_addr_w;
  wire req_pmp_fault_raw_w;
  wire req_data_pmp_fault_w =
      (!req_translate_w || req_dtlb_hit_w) && req_pmp_fault_raw_w &&
      !stg_pretrans_q;
  wire req_dcacheable_unused_w;
  wire req_line_cross_w;
  wire [`XLEN-1:0] walk_pte_addr_w =
      pte_addr(walk_ppn_q, addr_q, walk_level_q);
  wire [`XLEN-1:0] walk_leaf_paddr_w =
      leaf_paddr(lsu_axi_rdata_i, addr_q, walk_level_q);
  wire walk_leaf_pmp_fault_w;
  wire walk_leaf_dcacheable_unused_w;
  wire write_paddr_virtio_blk_w =
      ((paddr_q & `NPC_AXI_VIRTIO_BLK_MASK) == `NPC_AXI_VIRTIO_BLK_BASE);
  wire dtlb_leaf_ok_w =
      (state_q == S_WALK_R) && lsu_axi_rvalid_i &&
      (lsu_axi_rresp_i == 2'b00) &&
      !pte_invalid(lsu_axi_rdata_i) &&
      !pte_reserved_fault(lsu_axi_rdata_i, access_svpbmt_en_q, walk_level_q) &&
      pte_leaf(lsu_axi_rdata_i) &&
      !superpage_misaligned(lsu_axi_rdata_i, walk_level_q) &&
      !data_permission_fault(lsu_axi_rdata_i, write_q, access_priv_q,
                             mstatus_i);
  wire walk_ad_needed_w = data_ad_update_needed(lsu_axi_rdata_i, write_q);
  // A/D 写回 B 完成拍(bresp OK): 用 ad_pte_q 填 TLB(A/D 已置)+ 续原访问。
  wire ad_update_b_ok_w =
      (state_q == S_AD_UPDATE) && lsu_axi_bvalid_i && (lsu_axi_bresp_i == 2'b00);
  // 无需更新 → S_WALK_R 填原始 PTE(A/D 已足); 需更新 → 待 S_AD_UPDATE 写完填 ad_pte_q。
  wire dtlb_fill_valid_w = (dtlb_leaf_ok_w && !walk_ad_needed_w) || ad_update_b_ok_w;
  wire [`XLEN-1:0] dtlb_fill_pte_w =
      ad_update_b_ok_w ? ad_pte_q : lsu_axi_rdata_i;
  wire dcache_read_fill_valid_w =
      !cpu_kill_w && (state_q == S_READ_DATA) && lsu_axi_rvalid_i &&
      (lsu_axi_rresp_i == 2'b00) && !read_cross_q;
  // 声明前置，iverilog 14 拒绝前向引用(赋值仍在下方 B 通道段)。
  wire store_decouple_w;
  // 解耦 store 在数据落 PMEM 当拍(S_WRITE_REQ 两 beat 完成且走解耦)就必须更新/失效 dcache，
  // 否则跳过 S_WRITE_RESP 会漏掉 dcache 维护、令同地址后续 load 命中旧值(MEM-I2 破坏)。
  // 【store RMW】限定正常推进分支(fsm_normal_w): flush-drain 拍 FSM 进 S_WRITE_RESP
  // 等 B, 改由 b-ok 拍单次提交——否则同一 store 双 commit, 第二次 RMW 读会撞上
  // 第一次的判决拍(1RW 违约)。语义不变: drain store 仍在 B ok 拍维护 dcache。
  wire store_decouple_commit_w =
      fsm_normal_w &&
      (state_q == S_WRITE_REQ) &&
      ((aw_done_q || aw_fire_w) && (w_done_q || w_fire_w)) &&
      store_decouple_w;
  wire dcache_store_commit_w =
      ((state_q == S_WRITE_RESP) && lsu_axi_bvalid_i &&
       (lsu_axi_bresp_i == 2'b00)) ||
      store_decouple_commit_w ||
      ad_update_b_ok_w;   // HW A/D: PTE 写回也维护 dcache(否则读 PTE 得 stale A/D, rv64si-dirty 破)

  // 【SRAM 同步读】dcache 单读口发射条件(三源所在状态互斥, 见 dcache spec):
  //   req 路: 【刀 M】stage_advance 拍 read-可翻译-无 fault(原 fire 拍, 已随寄存站
  //     推迟一拍; 条件须与 accept_request 读分支严格一致);
  //   walk 路: S_WALK_R leaf-ok read——改经 S_LOOKUP 顺手修复旧 walk 组合口
  //     无移位无跨线检查回错值的 bug(判决拍统一 paddr_q 移位/read_cross_q 阻断);
  //   A/D 路: S_AD_UPDATE b-ok read——改用锁存 paddr_q, 消灭对 R 通道残留
  //     lsu_axi_rdata_i 的依赖(第二个既有 bug)。
  wire req_read_lookup_fire_w =
      stage_advance_w && !req_write_w &&
      (!req_translate_w || req_dtlb_hit_w) &&
      !req_data_pmp_fault_w &&
      !(req_translate_w && req_dtlb_perm_fault_w);
  wire walk_read_lookup_fire_w =
      dtlb_leaf_ok_w && !walk_leaf_pmp_fault_w && !walk_ad_needed_w &&
      !write_q;
  wire ad_read_lookup_fire_w =
      ad_update_b_ok_w &&
      (aw_done_q || aw_fire_w) && (w_done_q || w_fire_w) && !write_q;
  // walk/A/D 路只在 FSM 正常推进分支发读(flush/drop 拍事务被释放, 不发)。
  // req 路已由 stage_advance_w 含 (!cpu_kill_w||stg_nokill_q) 与 !rmw_busy 把关
  // (nokill 恒 write, 不落入 read-lookup 分支)。
  // 【store RMW】判决拍宏口被 RMW 占用, lookup 一律不发(!rmw_busy 是安全网:
  // 三源所在状态与 RMW 判决拍状态互斥, 由下方 OOO_ASSERT 证实恒不触发)。
  wire dcache_lookup_en_w =
      !dcache_rmw_busy_w &&
      (req_read_lookup_fire_w ||
       (fsm_normal_w && (walk_read_lookup_fire_w || ad_read_lookup_fire_w)));
  wire [`XLEN-1:0] dcache_lookup_addr_w =
      req_read_lookup_fire_w  ? req_cache_addr_w :
      walk_read_lookup_fire_w ? walk_leaf_paddr_w : paddr_q;
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

  OooDataWordCache u_dcache (
    .clk(clk),
    .rst(rst),
    .req_lookup_addr_i(req_cache_addr_w),
    .req_nbytes_i(req_access_size_w),
    .req_cacheable_o(req_dcacheable_unused_w),
    .req_line_cross_o(req_line_cross_w),
    .walk_lookup_addr_i(walk_leaf_paddr_w),
    .walk_cacheable_o(walk_leaf_dcacheable_unused_w),
    // 单读口两拍协议: 发射拍状态互斥 mux(req/walk/A-D 三源), 判决在 S_LOOKUP。
    .lookup_en_i(dcache_lookup_en_w),
    .lookup_addr_i(dcache_lookup_addr_w),
    .lookup_hit_o(dcache_lookup_hit_w),
    .lookup_line_o(dcache_lookup_line_w),
    .fill_valid_i(dcache_read_fill_valid_w),
    .fill_addr_i({paddr_q[`XLEN-1:3], 3'b000}),
    .fill_data_i(lsu_axi_rdata_i),
    // 【store RMW·二期赎回】真 store commit(S_WRITE_REQ 解耦/S_WRITE_RESP b-ok,
    // 该拍宏读口空闲)走 2 拍 RMW write-update; HW A/D PTE 写回维护路保持无条件
    // 失效(该拍的 read 续访问可能同拍发 lookup, 读口不空闲)。
    .store_commit_i(dcache_store_commit_w),
    .store_rmw_en_i(!ad_update_b_ok_w),
    // HW A/D: PTE 写回拍(ad_update_b_ok_w)对 PTE 地址维护 dcache; 否则用 store 地址。
    .store_addr_i(ad_update_b_ok_w ? walk_pte_addr_w : paddr_q),
    .store_wdata_i(wdata_q),
    .store_wstrb_i(ad_update_b_ok_w ? {`STRB_W{1'b1}} : wstrb_q),
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
  assign translate_active_o = ctx_translate_w;

  // 【SRAM 同步读】read miss 的 AR 从 fire 拍推迟到 S_LOOKUP 判决拍(晚 1 拍),
  // 地址/strb 统一取锁存 paddr_q/wstrb_q, 原 req_* 直通支路随之删除。
  // S_LOOKUP 项的 !rmw_busy 与 FSM 转移侧一致(读口互斥安全网, 状态互斥下恒真)。
  assign lsu_axi_arvalid_o =
      !cpu_kill_w &&
      (((state_q == S_WALK_AR) && !walk_pte_pmp_fault_w) ||
       (state_q == S_READ_ADDR) ||
       ((state_q == S_LOOKUP) && !dcache_lookup_hit_final_w &&
        !dcache_rmw_busy_w));
  wire [`XLEN-1:0] pend_read_araddr_w =
      read_cross_q ? paddr_q : {paddr_q[`XLEN-1:3], 3'b000};
  assign lsu_axi_araddr_o =
      (state_q == S_WALK_AR) ? walk_pte_addr_w : pend_read_araddr_w;
  // 【AXI4 化 S3】arstrb(非标)→ARSIZE: walk/对齐 line 读=8B; 跨线窗口读=实际访问
  // 宽度(log2(popcount(wstrb)), 配非对齐 araddr)。slave 侧(DPI pmem)本就整 8B 读
  // 由 master 取窗口, 行为零变化。
  assign lsu_axi_arsize_o =
      (state_q == S_WALK_AR) ? 3'd3 :
      (read_cross_q ? axsize_from_bytes(access_size_from_wstrb(wstrb_q)) : 3'd3);
  assign lsu_axi_rready_o = (state_q == S_WALK_R) || (state_q == S_READ_DATA);
  wire write_drain_w =
      drop_rsp_q || (flush_i && (aw_done_q || w_done_q));
  // HW A/D: S_AD_UPDATE 复用写通道写回 leaf PTE(awaddr=PTE 地址, wdata=置位 PTE, wstrb=全 8B),
  // 写必达(不受 cpu_kill 门控; flush 由 FSM 完成写后 drop, 幂等)。
  assign lsu_axi_awvalid_o =
      ((state_q == S_WRITE_REQ) && !aw_done_q &&
       (!cpu_kill_w || write_drain_w || nokill_q)) ||
      ((state_q == S_AD_UPDATE) && !aw_done_q);
  assign lsu_axi_awaddr_o =
      (state_q == S_AD_UPDATE) ? walk_pte_addr_w : paddr_q;
  assign lsu_axi_wvalid_o =
      ((state_q == S_WRITE_REQ) && !w_done_q &&
       (!cpu_kill_w || write_drain_w || nokill_q)) ||
      ((state_q == S_AD_UPDATE) && !w_done_q);
  assign lsu_axi_wdata_o = (state_q == S_AD_UPDATE) ? ad_pte_q : wdata_q;
  assign lsu_axi_wstrb_o = (state_q == S_AD_UPDATE) ? {`STRB_W{1'b1}} : wstrb_q;
  // 解耦 store 的 B 由跟踪器吸收：bpend_q 期间持续拉 bready。S_AD_UPDATE 也收 B。
  assign lsu_axi_bready_o =
      (state_q == S_WRITE_RESP) || bpend_q || (state_q == S_AD_UPDATE);
  // 仅 PMEM store 可提前完成(bresp 恒 OK)；!bpend_q 保证至多一个未收 B。
  assign store_decouple_w =
      ((paddr_q & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE) && !bpend_q;

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
      wdata_q <= req_wdata_w;
      wstrb_q <= req_wstrb_w;
      probe_q <= stg_probe_q && req_write_w;
      nokill_q <= stg_nokill_q;
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
        if (stg_probe_q) begin
          // 【LSQ·SQ 切换】write 探测:翻译+PMP 已过, 不写内存, PA 经 rsp_rdata 回传。
          rsp_rdata_q <= req_cache_addr_w;
          state_q <= S_RESP;
        end else begin
          state_q <= S_WRITE_REQ;
        end
      end else begin
        // 【SRAM 同步读】读路径统一经 S_LOOKUP: fire 拍已发 dcache 读
        // (req_read_lookup_fire_w, 与本分支条件严格一致), 次拍判决 hit/miss。
        state_q <= S_LOOKUP;
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
      ad_pte_q <= {`XLEN{1'b0}};
      read_cross_q <= 1'b0;
      wdata_q <= {`XLEN{1'b0}};
      wstrb_q <= {`STRB_W{1'b0}};
      rsp_rdata_q <= {`XLEN{1'b0}};
      rsp_error_q <= 1'b0;
      rsp_page_fault_q <= 1'b0;
      aw_done_q <= 1'b0;
      w_done_q <= 1'b0;
      drop_rsp_q <= 1'b0;
      bpend_q <= 1'b0;
      probe_q <= 1'b0;
      nokill_q <= 1'b0;
    end else begin
      // B-drain 跟踪器(状态无关，flush 期间也照常吸收已解耦 store 的 B)
      if (bpend_q && lsu_axi_bvalid_i) begin
        bpend_q <= 1'b0;
      end
      // 【刀 M】寄存站项进 FSM(stage_advance 拍)最高优先: 只可能发生在 S_IDLE 或
      // S_RESP&&rsp_ready(两态 drop_rsp_q 恒 0、无遗留清理义务, done 位由
      // accept_request 清零)。nokill 项经 (!cpu_kill_w||stg_nokill_q) 豁免, flush
      // 拍也照常进 FSM(写必达; 此时若在 S_RESP, 被顶替的旧响应本就属被 kill 事务,
      // 与旧 flush-drain 臂的丢弃行为一致); 非 nokill 项 flush/drop 拍 advance=0,
      // FSM 走下方 drain/正常分支。
      if (stage_advance_w) begin
        accept_request();
      end else if ((flush_i || drop_rsp_q) && !nokill_busy_w) begin
      case (state_q)
        S_IDLE: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
        end

        // S_LOOKUP: dcache 读无外部副作用, flush 当拍直接释放。
        S_WALK_AR, S_READ_ADDR, S_LOOKUP: begin
          state_q <= S_IDLE;
          aw_done_q <= 1'b0;
          w_done_q <= 1'b0;
          drop_rsp_q <= 1'b0;
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
                         pte_reserved_fault(lsu_axi_rdata_i,
                                            access_svpbmt_en_q,
                                            walk_level_q) ||
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
              end else if (walk_ad_needed_w) begin
                // HW A/D: 真权限过但 A/D 不足 → 写回置位 PTE(S_AD_UPDATE), B 后再续访问。
                ad_pte_q <= lsu_axi_rdata_i | PTE_A_BIT |
                            (write_q ? PTE_D_BIT : {`XLEN{1'b0}});
                paddr_q <= walk_leaf_paddr_w;
                aw_done_q <= 1'b0;
                w_done_q <= 1'b0;
                state_q <= S_AD_UPDATE;
              end else begin
                paddr_q <= walk_leaf_paddr_w;
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
                  // 【SRAM 同步读】leaf-ok read: 当拍已发 dcache 读
                  // (walk_read_lookup_fire_w, addr=walk_leaf_paddr_w), 统一
                  // 进 S_LOOKUP 判决——修复旧 walk 组合口无移位无跨线检查
                  // 直接回整行的错值 bug。
                  state_q <= S_LOOKUP;
                end
              end
            end else begin
              walk_ppn_q <= lsu_axi_rdata_i[53:10];
              walk_level_q <= walk_level_q - 2'd1;
              state_q <= S_WALK_AR;
            end
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
            // 不跨线: AXI 返回对齐 line → CPU 视图右移窗口偏移;
            // 跨线: 窗口读原样。
            rsp_rdata_q <= read_cross_q ? lsu_axi_rdata_i :
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
              // 【SRAM 同步读】续 read: 当拍已发 dcache 读(ad_read_lookup_fire_w,
              // addr=paddr_q, 不再依赖 R 通道残留的 lsu_axi_rdata_i), 统一进
              // S_LOOKUP 判决。
              state_q <= S_LOOKUP;
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
    end else if (mem0_req_fire_w) begin
      stg_valid_q <= 1'b1;
      stg_addr_q <= mem0_req_addr_i;
      stg_wdata_q <= mem0_req_wdata_i;
      stg_wstrb_q <= mem0_req_wstrb_i;
      stg_write_q <= mem0_req_write_i;
      stg_probe_q <= mem0_req_probe_i;
      stg_pretrans_q <= mem0_req_pretrans_i;
      stg_nokill_q <= mem0_req_nokill_i;
    end else if (stage_advance_w) begin
      stg_valid_q <= 1'b0;
    end else if (flush_i && !stg_nokill_q) begin
      stg_valid_q <= 1'b0;
    end
  end

`ifdef OOO_ASSERT
  // 【store RMW 读口互斥】RMW 判决拍(rmw_busy)宏口被占, 桥侧不得出现任何
  // 会用口的动作: 三源 lookup 发射意图/fill/S_LOOKUP 判决。由 FSM 状态互斥
  // (RMW 判决拍状态∈{S_RESP,S_IDLE})+stage_advance 压制(刀 M 后 req 源随
  // advance 迁移, !rmw_busy 项迁入 stage_advance_w)保证, 违反即门控链被破坏。
  always @(posedge clk) begin
    if (!rst && dcache_rmw_busy_w &&
        (req_read_lookup_fire_w || walk_read_lookup_fire_w ||
         ad_read_lookup_fire_w || dcache_read_fill_valid_w ||
         (state_q == S_LOOKUP))) begin
      $error("[MEM-RMW-PORT] RMW 判决拍出现 lookup/fill/S_LOOKUP: state=%0d req=%b walk=%b ad=%b fill=%b @%0t",
             state_q, req_read_lookup_fire_w, walk_read_lookup_fire_w,
             ad_read_lookup_fire_w, dcache_read_fill_valid_w, $time);
      $fatal;
    end
  end

  // 【刀 M·寄存站契约断言族】全部立即断言形态(SVA 命中 0 教训)。
  reg assert_stg_valid_r;
  reg assert_fire_r;
  reg assert_nokill_hold_r;
  reg [`XLEN-1:0] assert_stg_addr_r;
  reg [`XLEN-1:0] assert_stg_wdata_r;
  reg [`STRB_W-1:0] assert_stg_wstrb_r;
  reg [3:0] assert_stg_attr_r;
  always @(posedge clk) begin
    if (rst) begin
      assert_stg_valid_r <= 1'b0;
      assert_fire_r <= 1'b0;
      assert_nokill_hold_r <= 1'b0;
    end else begin
      // BRG-NOFIRE-FLUSH: flush 拍不得 fire(ready 含 !flush_i ⟺ 寄存站↔MIQ 双射,
      // MIQ flush 分支是 else-if、flush 拍 push 被忽略)。
      if (mem0_req_fire_w && flush_i) begin
        $error("[BRG-NOFIRE-FLUSH] flush 拍出现 mem0_req fire @%0t", $time);
        $fatal;
      end
      // BRG-ADV-NODROP: advance 只可能发生在 drop_rsp_q=0 的拍
      // (S_IDLE/S_RESP 态 drop 恒 0 的 FSM 不变量, 上提 accept 分支依赖它)。
      if (stage_advance_w && drop_rsp_q) begin
        $error("[BRG-ADV-NODROP] drop_rsp_q=1 拍出现 stage_advance @%0t", $time);
        $fatal;
      end
      // BRG-STG-LOOKUP: req 源 dcache lookup 只允许出现在 stage_advance 拍
      // (fire 拍恒 0——旧"fire 拍发 lookup"路径已被寄存站切断)。
      if (req_read_lookup_fire_w && !stage_advance_w) begin
        $error("[BRG-STG-LOOKUP] 非 advance 拍出现 req 源 dcache lookup @%0t",
               $time);
        $fatal;
      end
      // BRG-STG-HOLD: 上拍占用且未重装(fire), 本拍仍占用 ⇒ 字段冻结(PSR-HOLD 型)。
      if (assert_stg_valid_r && !assert_fire_r && stg_valid_q &&
          ((stg_addr_q != assert_stg_addr_r) ||
           (stg_wdata_q != assert_stg_wdata_r) ||
           (stg_wstrb_q != assert_stg_wstrb_r) ||
           ({stg_write_q, stg_probe_q, stg_pretrans_q, stg_nokill_q} !=
            assert_stg_attr_r))) begin
        $error("[BRG-STG-HOLD] stall 拍寄存站字段被改写 @%0t", $time);
        $fatal;
      end
      // BRG-STG-NOKILL: flush 拍未 advance 的 nokill 项次拍必须存活(写必达)。
      if (assert_nokill_hold_r && !stg_valid_q) begin
        $error("[BRG-STG-NOKILL] flush 拍 nokill 寄存站项被丢弃 @%0t", $time);
        $fatal;
      end
      assert_stg_valid_r <= stg_valid_q;
      assert_fire_r <= mem0_req_fire_w;
      assert_nokill_hold_r <= flush_i && stg_valid_q && stg_nokill_q &&
                              !stage_advance_w;
      assert_stg_addr_r <= stg_addr_q;
      assert_stg_wdata_r <= stg_wdata_q;
      assert_stg_wstrb_r <= stg_wstrb_q;
      assert_stg_attr_r <= {stg_write_q, stg_probe_q, stg_pretrans_q,
                            stg_nokill_q};
    end
  end
`endif

endmodule
