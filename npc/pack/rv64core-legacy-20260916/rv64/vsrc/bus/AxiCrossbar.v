// 参数化 single-beat crossbar: master 口 AXI4 / slave 口 AXI4-Lite 转换互连。
// master 口收完整 AXI4 信号集(ID/LEN/SIZE/BURST/PROT/LAST), 单 outstanding
// 单 beat(LEN 恒 0); R/B 按 owner 记账回环 RID/BID, RLAST 恒 1。slave 口保留
// 单 beat 握手，并把 ARSIZE/ARPROT 与 ARADDR 一起锁存下传。SLAVE_EXEC_MASK 在
// 仲裁前把 instruction read 的非可执行目标改投 default-error，设备侧永远看不到
// 这类 ARVALID，因此拒绝取指不会触发 UART/CLINT/PLIC 等 read side effect。
// 【AXI4 化 S2(2026-07-10)】读 abort 边带(m_read_abort_i)与 rd_drop_q 吞 R 机制
// 已删除——在飞读的丢弃责任移交 master 桥自吞(fetch 桥 S_DRAIN/mem 桥 drop_rsp_q,
// 见 design/specs/axi4-bus.md §2)。"master 暂不 ready 也先收 R 进 buffer 防
// IFU 阻塞 LSU 死锁"的反死锁逻辑原样保留。
// 【AXI4 化 S3/S4(2026-07-10)】arstrb(非标)→ARSIZE、aruser→ARPROT[2]; 补
// ID/LEN/BURST/LAST 常量位与 RID/BID 回环(rd_id_q/wr_id_q 按 slave 锁存,
// buffer 路径 rd_resp_id_q 同存)。

module AxiCrossbar #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8,
  parameter M_COUNT = 2,
  parameter S_COUNT = 1,
  parameter DEFAULT_SLAVE = 0,
  parameter [S_COUNT*ADDR_W-1:0] SLAVE_BASE = {S_COUNT{32'h0000_0000}},
  parameter [S_COUNT*ADDR_W-1:0] SLAVE_MASK = {S_COUNT{32'h0000_0000}},
  parameter [S_COUNT-1:0] SLAVE_EXEC_MASK = {S_COUNT{1'b1}}
) (
  input clk,
  input rst,

  input [M_COUNT-1:0] m_arvalid_i,
  output [M_COUNT-1:0] m_arready_o,
  input [M_COUNT*ADDR_W-1:0] m_araddr_i,
  input [M_COUNT*4-1:0] m_arid_i,
  input [M_COUNT*8-1:0] m_arlen_i,
  input [M_COUNT*3-1:0] m_arsize_i,
  input [M_COUNT*2-1:0] m_arburst_i,
  input [M_COUNT*3-1:0] m_arprot_i,
  output [M_COUNT-1:0] m_rvalid_o,
  input [M_COUNT-1:0] m_rready_i,
  output [M_COUNT*DATA_W-1:0] m_rdata_o,
  output [M_COUNT*2-1:0] m_rresp_o,
  output [M_COUNT*4-1:0] m_rid_o,
  output [M_COUNT-1:0] m_rlast_o,

  input [M_COUNT-1:0] m_awvalid_i,
  output [M_COUNT-1:0] m_awready_o,
  input [M_COUNT*ADDR_W-1:0] m_awaddr_i,
  input [M_COUNT*4-1:0] m_awid_i,
  input [M_COUNT*8-1:0] m_awlen_i,
  input [M_COUNT*3-1:0] m_awsize_i,
  input [M_COUNT*2-1:0] m_awburst_i,
  input [M_COUNT-1:0] m_wvalid_i,
  output [M_COUNT-1:0] m_wready_o,
  input [M_COUNT*DATA_W-1:0] m_wdata_i,
  input [M_COUNT*STRB_W-1:0] m_wstrb_i,
  input [M_COUNT-1:0] m_wlast_i,
  output [M_COUNT-1:0] m_bvalid_o,
  input [M_COUNT-1:0] m_bready_i,
  output [M_COUNT*2-1:0] m_bresp_o,
  output [M_COUNT*4-1:0] m_bid_o,

  output [S_COUNT-1:0] s_arvalid_o,
  input [S_COUNT-1:0] s_arready_i,
  output [S_COUNT*ADDR_W-1:0] s_araddr_o,
  output [S_COUNT*3-1:0] s_arsize_o,
  output [S_COUNT*3-1:0] s_arprot_o,
  input [S_COUNT-1:0] s_rvalid_i,
  output [S_COUNT-1:0] s_rready_o,
  input [S_COUNT*DATA_W-1:0] s_rdata_i,
  input [S_COUNT*2-1:0] s_rresp_i,

  output [S_COUNT-1:0] s_awvalid_o,
  input [S_COUNT-1:0] s_awready_i,
    output [S_COUNT*ADDR_W-1:0] s_awaddr_o,
    output [S_COUNT*3-1:0]      s_awsize_o,
  output [S_COUNT-1:0] s_wvalid_o,
  input [S_COUNT-1:0] s_wready_i,
  output [S_COUNT*DATA_W-1:0] s_wdata_o,
  output [S_COUNT*STRB_W-1:0] s_wstrb_o,
  input [S_COUNT-1:0] s_bvalid_i,
  output [S_COUNT-1:0] s_bready_o,
  input [S_COUNT*2-1:0] s_bresp_i
);

  localparam MASTER_W = (M_COUNT <= 1) ? 1 : $clog2(M_COUNT);
  localparam SLAVE_W = (S_COUNT <= 1) ? 1 : $clog2(S_COUNT);

  // 单 outstanding 单 beat互连不消费 burst 元数据；read SIZE 已成为 slave ABI，
  // 不得再并入 unused。
    wire unused_axi4_meta_w = |{m_arlen_i, m_arburst_i,
                                m_awlen_i, m_awburst_i, m_wlast_i};

  function [ADDR_W-1:0] m_addr_slice;
    input [M_COUNT*ADDR_W-1:0] bus;
    input [MASTER_W-1:0] idx;
    begin
      m_addr_slice = bus[idx*ADDR_W +: ADDR_W];
    end
  endfunction

  function [DATA_W-1:0] m_data_slice;
    input [M_COUNT*DATA_W-1:0] bus;
    input [MASTER_W-1:0] idx;
    begin
      m_data_slice = bus[idx*DATA_W +: DATA_W];
    end
  endfunction

  function [STRB_W-1:0] m_strb_slice;
    input [M_COUNT*STRB_W-1:0] bus;
    input [MASTER_W-1:0] idx;
    begin
      m_strb_slice = bus[idx*STRB_W +: STRB_W];
    end
  endfunction

  function [2:0] m_prot_slice;
    input [M_COUNT*3-1:0] bus;
    input [MASTER_W-1:0] idx;
    begin
      m_prot_slice = bus[idx*3 +: 3];
    end
  endfunction

  function [2:0] m_size_slice;
    input [M_COUNT*3-1:0] bus;
    input [MASTER_W-1:0] idx;
    begin
      m_size_slice = bus[idx*3 +: 3];
    end
  endfunction

  function [3:0] m_id_slice;
    input [M_COUNT*4-1:0] bus;
    input [MASTER_W-1:0] idx;
    begin
      m_id_slice = bus[idx*4 +: 4];
    end
  endfunction

  function [ADDR_W-1:0] s_base_slice;
    input [SLAVE_W-1:0] idx;
    begin
      s_base_slice = SLAVE_BASE[idx*ADDR_W +: ADDR_W];
    end
  endfunction

  function [ADDR_W-1:0] s_mask_slice;
    input [SLAVE_W-1:0] idx;
    begin
      s_mask_slice = SLAVE_MASK[idx*ADDR_W +: ADDR_W];
    end
  endfunction

  function [MASTER_W-1:0] master_idx;
    input [MASTER_W-1:0] idx;
    begin
      master_idx = idx;
    end
  endfunction

  function [SLAVE_W-1:0] slave_idx;
    input [SLAVE_W-1:0] idx;
    begin
      slave_idx = idx;
    end
  endfunction

  function integer master_int;
    input [MASTER_W-1:0] idx;
    begin
      master_int = idx;
    end
  endfunction

  function [SLAVE_W-1:0] default_slave_idx;
    begin
      default_slave_idx = (DEFAULT_SLAVE < S_COUNT) ? slave_idx(DEFAULT_SLAVE) :
                          {SLAVE_W{1'b0}};
    end
  endfunction

  function [SLAVE_W-1:0] decode_slave;
    input [ADDR_W-1:0] addr;
    integer k;
    reg found;
    begin
      decode_slave = default_slave_idx();
      found = 1'b0;
      for (k = 0; k < S_COUNT; k = k + 1) begin
        if (!found && ((addr & s_mask_slice(k)) == s_base_slice(k))) begin
          decode_slave = slave_idx(k);
          found = 1'b1;
        end
      end
    end
  endfunction

  function [SLAVE_W-1:0] decode_read_slave;
    input [ADDR_W-1:0] addr;
    input [2:0] prot;
    reg [SLAVE_W-1:0] decoded;
    begin
      decoded = decode_slave(addr);
      decode_read_slave = (prot[2] && !SLAVE_EXEC_MASK[decoded]) ?
                          default_slave_idx() : decoded;
    end
  endfunction

  reg [M_COUNT-1:0] m_arready_r;
  reg [M_COUNT-1:0] m_awready_r;
  reg [M_COUNT-1:0] m_wready_r;
  reg [M_COUNT-1:0] m_rvalid_r;
  reg [M_COUNT*DATA_W-1:0] m_rdata_r;
  reg [M_COUNT*2-1:0] m_rresp_r;
  reg [M_COUNT*4-1:0] m_rid_r;
  reg [M_COUNT-1:0] m_bvalid_r;
  reg [M_COUNT*2-1:0] m_bresp_r;
  reg [M_COUNT*4-1:0] m_bid_r;

  reg [S_COUNT-1:0] s_arvalid_r;
  reg [S_COUNT*ADDR_W-1:0] s_araddr_r;
  reg [S_COUNT*3-1:0] s_arsize_r;
  reg [S_COUNT*3-1:0] s_arprot_r;
  reg [S_COUNT-1:0] s_rready_r;
  reg [S_COUNT-1:0] s_awvalid_r;
    reg [S_COUNT*ADDR_W-1:0] s_awaddr_r;
    reg [S_COUNT*3-1:0]      s_awsize_r;
  reg [S_COUNT-1:0] s_wvalid_r;
  reg [S_COUNT*DATA_W-1:0] s_wdata_r;
  reg [S_COUNT*STRB_W-1:0] s_wstrb_r;
  reg [S_COUNT-1:0] s_bready_r;

  reg [M_COUNT-1:0] rd_master_busy_q;
  reg [M_COUNT-1:0] rd_resp_valid_q;
  reg [DATA_W-1:0] rd_resp_data_q [0:M_COUNT-1];
  reg [1:0] rd_resp_resp_q [0:M_COUNT-1];
  reg [3:0] rd_resp_id_q [0:M_COUNT-1];
  reg [S_COUNT-1:0] rd_active_q;
  reg [S_COUNT-1:0] rd_ar_sent_q;
  reg [MASTER_W-1:0] rd_owner_q [0:S_COUNT-1];
  reg [MASTER_W-1:0] rd_rr_q [0:S_COUNT-1];
  reg [ADDR_W-1:0] rd_addr_q [0:S_COUNT-1];
  reg [2:0] rd_size_q [0:S_COUNT-1];
  reg [2:0] rd_prot_q [0:S_COUNT-1];
  reg [3:0] rd_id_q [0:S_COUNT-1];

  reg [M_COUNT-1:0] wr_master_busy_q;
  reg [M_COUNT-1:0] wr_aw_hold_q;
  reg [M_COUNT-1:0] wr_w_hold_q;
    reg [ADDR_W-1:0] wr_awaddr_q [0:M_COUNT-1];
    reg [2:0]        wr_awsize_q [0:M_COUNT-1];
  reg [3:0] wr_awid_q [0:M_COUNT-1];
  reg [SLAVE_W-1:0] wr_awtarget_q [0:M_COUNT-1];
  reg [DATA_W-1:0] wr_wdata_q [0:M_COUNT-1];
  reg [STRB_W-1:0] wr_wstrb_q [0:M_COUNT-1];

  reg [S_COUNT-1:0] wr_active_q;
  reg [S_COUNT-1:0] wr_aw_sent_q;
  reg [S_COUNT-1:0] wr_w_sent_q;
  reg [MASTER_W-1:0] wr_owner_q [0:S_COUNT-1];
  reg [MASTER_W-1:0] wr_rr_q [0:S_COUNT-1];
    reg [ADDR_W-1:0] wr_addr_q [0:S_COUNT-1];
    reg [2:0]        wr_size_q [0:S_COUNT-1];
  reg [DATA_W-1:0] wr_data_q [0:S_COUNT-1];
  reg [STRB_W-1:0] wr_strb_q [0:S_COUNT-1];
  reg [3:0] wr_id_q [0:S_COUNT-1];

  reg [S_COUNT-1:0] rd_grant_valid_r;
  reg [MASTER_W-1:0] rd_grant_master_r [0:S_COUNT-1];
  reg [S_COUNT-1:0] wr_grant_valid_r;
  reg [MASTER_W-1:0] wr_grant_master_r [0:S_COUNT-1];
  // A complete write pair has already been captured in per-master holders
  // before wr_grant_valid_r can assert.  The grant cycle may therefore offer
  // that registered payload directly to the selected target without making
  // master READY depend on target READY.  Per-channel fires seed the normal
  // registered active-owner sent bits on the same edge.
  reg [S_COUNT-1:0] wr_grant_offer_r;
  reg [S_COUNT-1:0] wr_grant_aw_fire_r;
  reg [S_COUNT-1:0] wr_grant_w_fire_r;
  // A locally accepted live complete pair may acquire an inactive target on
  // the same edge.  Selection never reads target READY: READY is sampled only
  // into the per-channel sent seed after owner/payload selection is fixed.
  reg [M_COUNT-1:0] wr_live_pair_r;
  reg wr_any_complete_holder_r;
  reg [S_COUNT-1:0] wr_live_unique_match_r;
  reg [S_COUNT-1:0] wr_live_offer_r;
  reg [MASTER_W-1:0] wr_live_master_r [0:S_COUNT-1];
  reg [S_COUNT-1:0] wr_live_aw_fire_r;
  reg [S_COUNT-1:0] wr_live_w_fire_r;
  reg [SLAVE_W-1:0] artarget_decode_r [0:M_COUNT-1];
  reg [SLAVE_W-1:0] awtarget_decode_r [0:M_COUNT-1];

  assign m_arready_o = m_arready_r;
  assign m_awready_o = m_awready_r;
  assign m_wready_o = m_wready_r;
  assign m_rvalid_o = m_rvalid_r;
  assign m_rdata_o = m_rdata_r;
  assign m_rresp_o = m_rresp_r;
  assign m_rid_o = m_rid_r;
  // 单 beat 互连: RLAST 恒 1。
  assign m_rlast_o = {M_COUNT{1'b1}};
  assign m_bvalid_o = m_bvalid_r;
  assign m_bresp_o = m_bresp_r;
  assign m_bid_o = m_bid_r;

  assign s_arvalid_o = s_arvalid_r;
  assign s_araddr_o = s_araddr_r;
  assign s_arsize_o = s_arsize_r;
  assign s_arprot_o = s_arprot_r;
  assign s_rready_o = s_rready_r;
  assign s_awvalid_o = s_awvalid_r;
    assign s_awaddr_o = s_awaddr_r;
    assign s_awsize_o = s_awsize_r;
  assign s_wvalid_o = s_wvalid_r;
  assign s_wdata_o = s_wdata_r;
  assign s_wstrb_o = s_wstrb_r;
  assign s_bready_o = s_bready_r;

  integer s;
  integer m;
  integer step;
  integer cand;
  integer owner;
  integer live_match_count;
  integer b_route_s;
  integer b_route_owner;

  // Keep the master-facing write admission and registered-owner B return in
  // comb processes that do not observe live request inputs.  Besides making
  // their true Q-only/owner-only dependencies explicit, this prevents the
  // live m_awvalid/m_wvalid cone in the request mux below from being merged by
  // full-top scheduling with IFU AWREADY/BVALID maintenance feedback.
  always @(*) begin
    m_awready_r = ~wr_aw_hold_q & ~wr_master_busy_q;
    m_wready_r = ~wr_w_hold_q & ~wr_master_busy_q;
  end

  always @(*) begin
    m_bvalid_r = {M_COUNT{1'b0}};
    m_bresp_r = {M_COUNT*2{1'b0}};
    m_bid_r = {M_COUNT*4{1'b0}};
    s_bready_r = {S_COUNT{1'b0}};
    b_route_owner = 0;
    for (b_route_s = 0; b_route_s < S_COUNT;
         b_route_s = b_route_s + 1) begin
      if (wr_active_q[b_route_s] && wr_aw_sent_q[b_route_s] &&
          wr_w_sent_q[b_route_s]) begin
        b_route_owner = master_int(wr_owner_q[b_route_s]);
        m_bvalid_r[b_route_owner] = s_bvalid_i[b_route_s];
        m_bresp_r[b_route_owner*2 +: 2] =
            s_bresp_i[b_route_s*2 +: 2];
        m_bid_r[b_route_owner*4 +: 4] = wr_id_q[b_route_s];
        s_bready_r[b_route_s] = m_bready_i[b_route_owner];
      end
    end
  end

  always @(*) begin
    m_arready_r = {M_COUNT{1'b0}};
    m_rvalid_r = {M_COUNT{1'b0}};
    m_rdata_r = {M_COUNT*DATA_W{1'b0}};
    m_rresp_r = {M_COUNT*2{1'b0}};
    m_rid_r = {M_COUNT*4{1'b0}};

    s_arvalid_r = {S_COUNT{1'b0}};
    s_araddr_r = {S_COUNT*ADDR_W{1'b0}};
    s_arsize_r = {S_COUNT*3{1'b0}};
    s_arprot_r = {S_COUNT*3{1'b0}};
    s_rready_r = {S_COUNT{1'b0}};
    s_awvalid_r = {S_COUNT{1'b0}};
        s_awaddr_r = {S_COUNT*ADDR_W{1'b0}};
        s_awsize_r = {S_COUNT*3{1'b0}};
    s_wvalid_r = {S_COUNT{1'b0}};
    s_wdata_r = {S_COUNT*DATA_W{1'b0}};
    s_wstrb_r = {S_COUNT*STRB_W{1'b0}};

    rd_grant_valid_r = {S_COUNT{1'b0}};
    wr_grant_valid_r = {S_COUNT{1'b0}};
    wr_grant_offer_r = {S_COUNT{1'b0}};
    wr_grant_aw_fire_r = {S_COUNT{1'b0}};
    wr_grant_w_fire_r = {S_COUNT{1'b0}};
    wr_live_pair_r = {M_COUNT{1'b0}};
    wr_any_complete_holder_r = 1'b0;
    wr_live_unique_match_r = {S_COUNT{1'b0}};
    wr_live_offer_r = {S_COUNT{1'b0}};
    wr_live_aw_fire_r = {S_COUNT{1'b0}};
    wr_live_w_fire_r = {S_COUNT{1'b0}};
    cand = 0;
    owner = 0;
    // 每个 master 的目标 slave 只译码一次，再供各 slave 仲裁器复用。
    for (m = 0; m < M_COUNT; m = m + 1) begin
      artarget_decode_r[m] = decode_read_slave(
          m_addr_slice(m_araddr_i, m), m_prot_slice(m_arprot_i, m));
      awtarget_decode_r[m] = decode_slave(m_addr_slice(m_awaddr_i, m));
    end
    for (s = 0; s < S_COUNT; s = s + 1) begin
      rd_grant_master_r[s] = {MASTER_W{1'b0}};
      wr_grant_master_r[s] = {MASTER_W{1'b0}};
      wr_live_master_r[s] = {MASTER_W{1'b0}};
    end

    for (m = 0; m < M_COUNT; m = m + 1) begin
      if (rd_resp_valid_q[m]) begin
        m_rvalid_r[m] = 1'b1;
        m_rdata_r[m*DATA_W +: DATA_W] = rd_resp_data_q[m];
        m_rresp_r[m*2 +: 2] = rd_resp_resp_q[m];
        m_rid_r[m*4 +: 4] = rd_resp_id_q[m];
      end
    end

    for (s = 0; s < S_COUNT; s = s + 1) begin
      if (!rd_active_q[s]) begin
        if (M_COUNT == 2) begin
          // 当前 RV64 平台真实使用 IFU/LSU 两个 master；显式两路选择避免综合成可变扫描链。
          if (rd_rr_q[s] == master_idx(0)) begin
            if (m_arvalid_i[0] && !rd_master_busy_q[0] && (artarget_decode_r[0] == slave_idx(s))) begin
              rd_grant_valid_r[s] = 1'b1;
              rd_grant_master_r[s] = master_idx(0);
              m_arready_r[0] = 1'b1;
            end else if (m_arvalid_i[1] && !rd_master_busy_q[1] && (artarget_decode_r[1] == slave_idx(s))) begin
              rd_grant_valid_r[s] = 1'b1;
              rd_grant_master_r[s] = master_idx(1);
              m_arready_r[1] = 1'b1;
            end
          end else begin
            if (m_arvalid_i[1] && !rd_master_busy_q[1] && (artarget_decode_r[1] == slave_idx(s))) begin
              rd_grant_valid_r[s] = 1'b1;
              rd_grant_master_r[s] = master_idx(1);
              m_arready_r[1] = 1'b1;
            end else if (m_arvalid_i[0] && !rd_master_busy_q[0] && (artarget_decode_r[0] == slave_idx(s))) begin
              rd_grant_valid_r[s] = 1'b1;
              rd_grant_master_r[s] = master_idx(0);
              m_arready_r[0] = 1'b1;
            end
          end
        end else begin
          for (step = 0; step < M_COUNT; step = step + 1) begin
            cand = master_int(rd_rr_q[s]) + step;
            if (cand >= M_COUNT) cand = cand - M_COUNT;
            if (!rd_grant_valid_r[s] &&
                m_arvalid_i[cand] && !rd_master_busy_q[cand] &&
                (artarget_decode_r[cand] == slave_idx(s))) begin
              rd_grant_valid_r[s] = 1'b1;
              rd_grant_master_r[s] = master_idx(cand);
              m_arready_r[cand] = 1'b1;
            end
          end
        end
      end

      if (rd_active_q[s] && !rd_ar_sent_q[s]) begin
        s_arvalid_r[s] = 1'b1;
        s_araddr_r[s*ADDR_W +: ADDR_W] = rd_addr_q[s];
        s_arsize_r[s*3 +: 3] = rd_size_q[s];
        s_arprot_r[s*3 +: 3] = rd_prot_q[s];
      end

      if (rd_active_q[s] && rd_ar_sent_q[s]) begin
        owner = master_int(rd_owner_q[s]);
        if (!rd_resp_valid_q[owner]) begin
          // R 通道是严格非穿透的 registered response slice：slave response
          // 无论 master 当拍是否 ready，都先进入 per-master rd_resp_*_q，
          // 下一拍才由上面的 buffer owner 驱动 m_r*。这既保留“先释放
          // slave、避免跨 master 结构死锁”的性质，也切断
          // rd_active/slave-R mux -> master consumer 的跨模块长组合路径。
          s_rready_r[s] = 1'b1;
        end
      end
    end

    for (m = 0; m < M_COUNT; m = m + 1) begin
      // A complete older holder anywhere in this single-outstanding
      // crossbar conservatively keeps the live path quiet.  Unknown holder
      // state is also treated as occupied, so it cannot be bypassed through
      // X optimism.
      case ({wr_aw_hold_q[m], wr_w_hold_q[m]})
        2'b11: wr_any_complete_holder_r = 1'b1;
        2'b10, 2'b01, 2'b00: begin end
        default: wr_any_complete_holder_r = 1'b1;
      endcase

      // Four-state exact admission: both channels must really fire and all
      // payload used by target decode/registration must be known.  Spell the
      // two local READY predicates directly from their registered Q sources
      // instead of reading m_*ready_r back inside this monolithic comb block.
      // The expressions are exactly equivalent to the assignments above, but
      // the Q-only form keeps full-top scheduling from manufacturing a false
      // m_valid -> comb block -> m_ready dependency.  Target READY is absent.
      case ({m_awvalid_i[m], m_wvalid_i[m], wr_aw_hold_q[m],
             wr_w_hold_q[m], wr_master_busy_q[m]})
        5'b11000: begin
          if ((^{m_addr_slice(m_awaddr_i, m),
                 m_size_slice(m_awsize_i, m),
                 m_id_slice(m_awid_i, m),
                 m_data_slice(m_wdata_i, m),
                 m_strb_slice(m_wstrb_i, m)}) !== 1'bx) begin
            wr_live_pair_r[m] = 1'b1;
          end
        end
        default: begin end
      endcase
    end

    for (s = 0; s < S_COUNT; s = s + 1) begin
      live_match_count = 0;
      for (m = 0; m < M_COUNT; m = m + 1) begin
        if (wr_live_pair_r[m] &&
            (awtarget_decode_r[m] == slave_idx(s)))
          live_match_count = live_match_count + 1;
      end
      if (live_match_count == 1)
        wr_live_unique_match_r[s] = 1'b1;

      if (!wr_active_q[s]) begin
        if (M_COUNT == 2) begin
          // 写通道同样针对真实两 master 路径展开，保留 AW/W hold 后再 grant 的协议边界。
          // Explicit four-state decode is intentional: an unknown/corrupt RR
          // owner must not be turned into an X-optimistic master1 grant.
          case (wr_rr_q[s])
            master_idx(0): begin
              if (wr_aw_hold_q[0] && wr_w_hold_q[0] &&
                  !wr_master_busy_q[0] &&
                  (wr_awtarget_q[0] == slave_idx(s))) begin
                wr_grant_valid_r[s] = 1'b1;
                wr_grant_master_r[s] = master_idx(0);
              end else if (wr_aw_hold_q[1] && wr_w_hold_q[1] &&
                           !wr_master_busy_q[1] &&
                           (wr_awtarget_q[1] == slave_idx(s))) begin
                wr_grant_valid_r[s] = 1'b1;
                wr_grant_master_r[s] = master_idx(1);
              end
            end
            master_idx(1): begin
              if (wr_aw_hold_q[1] && wr_w_hold_q[1] &&
                  !wr_master_busy_q[1] &&
                  (wr_awtarget_q[1] == slave_idx(s))) begin
                wr_grant_valid_r[s] = 1'b1;
                wr_grant_master_r[s] = master_idx(1);
              end else if (wr_aw_hold_q[0] && wr_w_hold_q[0] &&
                           !wr_master_busy_q[0] &&
                           (wr_awtarget_q[0] == slave_idx(s))) begin
                wr_grant_valid_r[s] = 1'b1;
                wr_grant_master_r[s] = master_idx(0);
              end
            end
            default: begin
              // Fail closed until RR state is known again.
            end
          endcase
        end else begin
          // Generic configurations also reject unknown or out-of-range RR
          // encodings before using them as an array index.
          if (((^wr_rr_q[s]) !== 1'bx) &&
              (master_int(wr_rr_q[s]) < M_COUNT)) begin
            for (step = 0; step < M_COUNT; step = step + 1) begin
              cand = master_int(wr_rr_q[s]) + step;
              if (cand >= M_COUNT) cand = cand - M_COUNT;
              if (!wr_grant_valid_r[s] &&
                  wr_aw_hold_q[cand] && wr_w_hold_q[cand] &&
                  !wr_master_busy_q[cand] &&
                  (wr_awtarget_q[cand] == slave_idx(s))) begin
                wr_grant_valid_r[s] = 1'b1;
                wr_grant_master_r[s] = master_idx(cand);
              end
            end
          end
        end
      end

      // Live complete-pair target acquisition.  Existing complete holders
      // have strict priority.  For the real two-master configuration, reuse
      // the target's registered RR pointer and a four-state case so corrupt
      // RR state cannot silently choose a master.  Different targets may each
      // select their uniquely decoded live master in the same cycle.
      if (!rst && !wr_active_q[s] && !wr_any_complete_holder_r &&
          wr_live_unique_match_r[s]) begin
        if (M_COUNT == 2) begin
          case (wr_rr_q[s])
            master_idx(0): begin
              if (wr_live_pair_r[0] &&
                  (awtarget_decode_r[0] == slave_idx(s))) begin
                wr_live_offer_r[s] = 1'b1;
                wr_live_master_r[s] = master_idx(0);
              end else if (wr_live_pair_r[1] &&
                           (awtarget_decode_r[1] == slave_idx(s))) begin
                wr_live_offer_r[s] = 1'b1;
                wr_live_master_r[s] = master_idx(1);
              end
            end
            master_idx(1): begin
              if (wr_live_pair_r[1] &&
                  (awtarget_decode_r[1] == slave_idx(s))) begin
                wr_live_offer_r[s] = 1'b1;
                wr_live_master_r[s] = master_idx(1);
              end else if (wr_live_pair_r[0] &&
                           (awtarget_decode_r[0] == slave_idx(s))) begin
                wr_live_offer_r[s] = 1'b1;
                wr_live_master_r[s] = master_idx(0);
              end
            end
            default: begin
              // Fail closed until RR state is known again.
            end
          endcase
        end else if (((^wr_rr_q[s]) !== 1'bx) &&
                     (master_int(wr_rr_q[s]) < M_COUNT)) begin
          for (step = 0; step < M_COUNT; step = step + 1) begin
            cand = master_int(wr_rr_q[s]) + step;
            if (cand >= M_COUNT) cand = cand - M_COUNT;
            if (!wr_live_offer_r[s] && wr_live_pair_r[cand] &&
                (awtarget_decode_r[cand] == slave_idx(s))) begin
              wr_live_offer_r[s] = 1'b1;
              wr_live_master_r[s] = master_idx(cand);
            end
          end
        end
      end

      // VALID-only held-grant offer.  Arbitration, target decode and every
      // payload bit come from holder Q.  READY is sampled only into the
      // registered sent bookkeeping below; it never feeds master READY,
      // grant selection, owner selection or B routing.
      if (!rst && !wr_active_q[s] && wr_grant_valid_r[s]) begin
        owner = master_int(wr_grant_master_r[s]);
        wr_grant_offer_r[s] = 1'b1;
        s_awvalid_r[s] = 1'b1;
        s_awaddr_r[s*ADDR_W +: ADDR_W] = wr_awaddr_q[owner];
        s_awsize_r[s*3 +: 3] = wr_awsize_q[owner];
        s_wvalid_r[s] = 1'b1;
        s_wdata_r[s*DATA_W +: DATA_W] = wr_wdata_q[owner];
        s_wstrb_r[s*STRB_W +: STRB_W] = wr_wstrb_q[owner];
        case (s_awready_i[s])
          1'b1: wr_grant_aw_fire_r[s] = 1'b1;
          default: wr_grant_aw_fire_r[s] = 1'b0;
        endcase
        case (s_wready_i[s])
          1'b1: wr_grant_w_fire_r[s] = 1'b1;
          default: wr_grant_w_fire_r[s] = 1'b0;
        endcase
      end


      // VALID-only live offer.  Payload comes from the same master-side pair
      // whose local AW/W fires established wr_live_pair_r.  Target READY is
      // sampled only after this selection into the registered sent seed.
      else if (wr_live_offer_r[s]) begin
        owner = master_int(wr_live_master_r[s]);
        s_awvalid_r[s] = 1'b1;
        s_awaddr_r[s*ADDR_W +: ADDR_W] =
            m_addr_slice(m_awaddr_i, owner);
        s_awsize_r[s*3 +: 3] = m_size_slice(m_awsize_i, owner);
        s_wvalid_r[s] = 1'b1;
        s_wdata_r[s*DATA_W +: DATA_W] =
            m_data_slice(m_wdata_i, owner);
        s_wstrb_r[s*STRB_W +: STRB_W] =
            m_strb_slice(m_wstrb_i, owner);
        case (s_awready_i[s])
          1'b1: wr_live_aw_fire_r[s] = 1'b1;
          default: wr_live_aw_fire_r[s] = 1'b0;
        endcase
        case (s_wready_i[s])
          1'b1: wr_live_w_fire_r[s] = 1'b1;
          default: wr_live_w_fire_r[s] = 1'b0;
        endcase
      end

      if (wr_active_q[s] && !wr_aw_sent_q[s]) begin
        s_awvalid_r[s] = 1'b1;
                s_awaddr_r[s*ADDR_W +: ADDR_W] = wr_addr_q[s];
                s_awsize_r[s*3 +: 3] = wr_size_q[s];
      end

      if (wr_active_q[s] && !wr_w_sent_q[s]) begin
        s_wvalid_r[s] = 1'b1;
        s_wdata_r[s*DATA_W +: DATA_W] = wr_data_q[s];
        s_wstrb_r[s*STRB_W +: STRB_W] = wr_strb_q[s];
      end

    end
  end

  always @(posedge clk) begin
    if (rst) begin
      rd_master_busy_q <= {M_COUNT{1'b0}};
      rd_resp_valid_q <= {M_COUNT{1'b0}};
      wr_master_busy_q <= {M_COUNT{1'b0}};
      wr_aw_hold_q <= {M_COUNT{1'b0}};
      wr_w_hold_q <= {M_COUNT{1'b0}};
      rd_active_q <= {S_COUNT{1'b0}};
      rd_ar_sent_q <= {S_COUNT{1'b0}};
      wr_active_q <= {S_COUNT{1'b0}};
      wr_aw_sent_q <= {S_COUNT{1'b0}};
      wr_w_sent_q <= {S_COUNT{1'b0}};
      for (m = 0; m < M_COUNT; m = m + 1) begin
        rd_resp_data_q[m] <= {DATA_W{1'b0}};
        rd_resp_resp_q[m] <= 2'b00;
        rd_resp_id_q[m] <= 4'd0;
                wr_awaddr_q[m] <= {ADDR_W{1'b0}};
                wr_awsize_q[m] <= 3'b000;
        wr_awid_q[m] <= 4'd0;
        wr_awtarget_q[m] <= {SLAVE_W{1'b0}};
        wr_wdata_q[m] <= {DATA_W{1'b0}};
        wr_wstrb_q[m] <= {STRB_W{1'b0}};
      end
      for (s = 0; s < S_COUNT; s = s + 1) begin
        rd_owner_q[s] <= {MASTER_W{1'b0}};
        rd_rr_q[s] <= {MASTER_W{1'b0}};
        rd_addr_q[s] <= {ADDR_W{1'b0}};
        rd_size_q[s] <= 3'd0;
        rd_prot_q[s] <= 3'd0;
        rd_id_q[s] <= 4'd0;
        wr_owner_q[s] <= {MASTER_W{1'b0}};
        wr_rr_q[s] <= {MASTER_W{1'b0}};
                wr_addr_q[s] <= {ADDR_W{1'b0}};
                wr_size_q[s] <= 3'b000;
        wr_data_q[s] <= {DATA_W{1'b0}};
        wr_strb_q[s] <= {STRB_W{1'b0}};
        wr_id_q[s] <= 4'd0;
      end
    end else begin
      for (m = 0; m < M_COUNT; m = m + 1) begin
        if (rd_resp_valid_q[m] && m_rready_i[m]) begin
          rd_resp_valid_q[m] <= 1'b0;
          rd_master_busy_q[m] <= 1'b0;
        end

      end

      for (s = 0; s < S_COUNT; s = s + 1) begin
        if (rd_active_q[s] && !rd_ar_sent_q[s] &&
            s_arvalid_r[s] && s_arready_i[s]) begin
          rd_ar_sent_q[s] <= 1'b1;
        end

        if (rd_active_q[s] && rd_ar_sent_q[s] &&
            s_rvalid_i[s] && s_rready_r[s]) begin
          rd_active_q[s] <= 1'b0;
          rd_ar_sent_q[s] <= 1'b0;
          // 始终捕获，不允许以 m_rready_i 构造 fall-through bypass。
          // busy 只能在下一拍真正的 buffered master R fire 时释放。
          rd_resp_valid_q[master_int(rd_owner_q[s])] <= 1'b1;
          rd_resp_data_q[master_int(rd_owner_q[s])] <=
              s_rdata_i[s*DATA_W +: DATA_W];
          rd_resp_resp_q[master_int(rd_owner_q[s])] <=
              s_rresp_i[s*2 +: 2];
          rd_resp_id_q[master_int(rd_owner_q[s])] <= rd_id_q[s];
        end

        if (!rd_active_q[s] && rd_grant_valid_r[s]) begin
          rd_active_q[s] <= 1'b1;
          rd_ar_sent_q[s] <= 1'b0;
          rd_owner_q[s] <= rd_grant_master_r[s];
          rd_addr_q[s] <= m_addr_slice(m_araddr_i, master_int(rd_grant_master_r[s]));
          rd_size_q[s] <= m_size_slice(m_arsize_i, master_int(rd_grant_master_r[s]));
          rd_prot_q[s] <= m_prot_slice(m_arprot_i, master_int(rd_grant_master_r[s]));
          rd_id_q[s] <= m_id_slice(m_arid_i, master_int(rd_grant_master_r[s]));
          rd_master_busy_q[master_int(rd_grant_master_r[s])] <= 1'b1;
          rd_rr_q[s] <= (master_int(rd_grant_master_r[s]) == (M_COUNT - 1)) ?
                         {MASTER_W{1'b0}} :
                         master_idx(master_int(rd_grant_master_r[s]) + 1);
        end
      end

      for (m = 0; m < M_COUNT; m = m + 1) begin
        if (m_awvalid_i[m] && m_awready_r[m]) begin
          wr_aw_hold_q[m] <= 1'b1;
                    wr_awaddr_q[m] <= m_addr_slice(m_awaddr_i, m);
                    wr_awsize_q[m] <= m_size_slice(m_awsize_i, m);
          wr_awid_q[m] <= m_id_slice(m_awid_i, m);
          wr_awtarget_q[m] <= awtarget_decode_r[m];
        end

        if (m_wvalid_i[m] && m_wready_r[m]) begin
          wr_w_hold_q[m] <= 1'b1;
          wr_wdata_q[m] <= m_data_slice(m_wdata_i, m);
          wr_wstrb_q[m] <= m_strb_slice(m_wstrb_i, m);
        end
      end

      for (s = 0; s < S_COUNT; s = s + 1) begin
        if (wr_active_q[s] && !wr_aw_sent_q[s] &&
            s_awvalid_r[s] && s_awready_i[s]) begin
          wr_aw_sent_q[s] <= 1'b1;
        end

        if (wr_active_q[s] && !wr_w_sent_q[s] &&
            s_wvalid_r[s] && s_wready_i[s]) begin
          wr_w_sent_q[s] <= 1'b1;
        end

        if (wr_active_q[s] && wr_aw_sent_q[s] && wr_w_sent_q[s] &&
            s_bvalid_i[s] && s_bready_r[s]) begin
          wr_active_q[s] <= 1'b0;
          wr_aw_sent_q[s] <= 1'b0;
          wr_w_sent_q[s] <= 1'b0;
          wr_master_busy_q[master_int(wr_owner_q[s])] <= 1'b0;
        end

        if (!wr_active_q[s] && wr_grant_valid_r[s]) begin
          wr_active_q[s] <= 1'b1;
          wr_aw_sent_q[s] <= wr_grant_aw_fire_r[s];
          wr_w_sent_q[s] <= wr_grant_w_fire_r[s];
          wr_owner_q[s] <= wr_grant_master_r[s];
                        wr_addr_q[s] <= wr_awaddr_q[master_int(wr_grant_master_r[s])];
                        wr_size_q[s] <= wr_awsize_q[master_int(wr_grant_master_r[s])];
          wr_data_q[s] <= wr_wdata_q[master_int(wr_grant_master_r[s])];
          wr_strb_q[s] <= wr_wstrb_q[master_int(wr_grant_master_r[s])];
          wr_id_q[s] <= wr_awid_q[master_int(wr_grant_master_r[s])];
          wr_aw_hold_q[master_int(wr_grant_master_r[s])] <= 1'b0;
          wr_w_hold_q[master_int(wr_grant_master_r[s])] <= 1'b0;
          wr_master_busy_q[master_int(wr_grant_master_r[s])] <= 1'b1;
          wr_rr_q[s] <= (master_int(wr_grant_master_r[s]) == (M_COUNT - 1)) ?
                         {MASTER_W{1'b0}} :
                         master_idx(master_int(wr_grant_master_r[s]) + 1);
        end

        // This block is intentionally after generic master holder capture and
        // the held-grant handoff.  Its nonblocking assignments therefore make
        // live acquisition atomic: the selected pair becomes the registered
        // target owner while both just-captured holders are cleared, preventing
        // the same real write from being granted again after B terminal.
        else if (wr_live_offer_r[s]) begin
          wr_active_q[s] <= 1'b1;
          wr_aw_sent_q[s] <= wr_live_aw_fire_r[s];
          wr_w_sent_q[s] <= wr_live_w_fire_r[s];
          wr_owner_q[s] <= wr_live_master_r[s];
          wr_addr_q[s] <=
              m_addr_slice(m_awaddr_i, master_int(wr_live_master_r[s]));
          wr_size_q[s] <=
              m_size_slice(m_awsize_i, master_int(wr_live_master_r[s]));
          wr_data_q[s] <=
              m_data_slice(m_wdata_i, master_int(wr_live_master_r[s]));
          wr_strb_q[s] <=
              m_strb_slice(m_wstrb_i, master_int(wr_live_master_r[s]));
          wr_id_q[s] <=
              m_id_slice(m_awid_i, master_int(wr_live_master_r[s]));
          wr_aw_hold_q[master_int(wr_live_master_r[s])] <= 1'b0;
          wr_w_hold_q[master_int(wr_live_master_r[s])] <= 1'b0;
          wr_master_busy_q[master_int(wr_live_master_r[s])] <= 1'b1;
          wr_rr_q[s] <=
              (master_int(wr_live_master_r[s]) == (M_COUNT - 1)) ?
              {MASTER_W{1'b0}} :
              master_idx(master_int(wr_live_master_r[s]) + 1);
        end
      end
    end
  end

`ifdef OOO_ASSERT
  // The assertion shadows below are checker-local state.  Their unpacked-array
  // elements are sampled only at the end of this same clocked process and read
  // before that sampling point on the next edge.  Deliberate blocking updates
  // preserve that one-edge history while avoiding Verilator BLKLOOPINIT (which
  // does not support procedural-loop NBAs into unpacked arrays).
  /* verilator lint_off BLKSEQ */
  reg [S_COUNT-1:0] assert_grant_offer_q;
  reg [S_COUNT-1:0] assert_grant_aw_fire_q;
  reg [S_COUNT-1:0] assert_grant_w_fire_q;
  reg [MASTER_W-1:0] assert_grant_owner_q [0:S_COUNT-1];
  reg [ADDR_W-1:0] assert_grant_addr_q [0:S_COUNT-1];
  reg [2:0] assert_grant_size_q [0:S_COUNT-1];
  reg [DATA_W-1:0] assert_grant_data_q [0:S_COUNT-1];
  reg [STRB_W-1:0] assert_grant_strb_q [0:S_COUNT-1];
  reg [S_COUNT-1:0] assert_live_offer_q;
  reg [S_COUNT-1:0] assert_live_aw_fire_q;
  reg [S_COUNT-1:0] assert_live_w_fire_q;
  reg [MASTER_W-1:0] assert_live_owner_q [0:S_COUNT-1];
  reg [ADDR_W-1:0] assert_live_addr_q [0:S_COUNT-1];
  reg [2:0] assert_live_size_q [0:S_COUNT-1];
  reg [DATA_W-1:0] assert_live_data_q [0:S_COUNT-1];
  reg [STRB_W-1:0] assert_live_strb_q [0:S_COUNT-1];
  reg [3:0] assert_live_id_q [0:S_COUNT-1];
  reg [S_COUNT-1:0] assert_wr_active_q;
  reg [S_COUNT-1:0] assert_wr_terminal_q;
  reg [MASTER_W-1:0] assert_wr_owner_q [0:S_COUNT-1];
  reg [ADDR_W-1:0] assert_wr_addr_q [0:S_COUNT-1];
  reg [2:0] assert_wr_size_q [0:S_COUNT-1];
  reg [DATA_W-1:0] assert_wr_data_q [0:S_COUNT-1];
  reg [STRB_W-1:0] assert_wr_strb_q [0:S_COUNT-1];
  reg [3:0] assert_wr_id_q [0:S_COUNT-1];
  reg [S_COUNT-1:0] assert_b_stall_q;
  reg [MASTER_W-1:0] assert_b_stall_owner_q [0:S_COUNT-1];
  reg [1:0] assert_b_stall_resp_q [0:S_COUNT-1];
  reg [3:0] assert_b_stall_id_q [0:S_COUNT-1];
  integer assert_s;
  integer assert_t;
  integer assert_m;

  always @(posedge clk) begin
    if (rst) begin
      assert_grant_offer_q <= {S_COUNT{1'b0}};
      assert_grant_aw_fire_q <= {S_COUNT{1'b0}};
      assert_grant_w_fire_q <= {S_COUNT{1'b0}};
      assert_live_offer_q <= {S_COUNT{1'b0}};
      assert_live_aw_fire_q <= {S_COUNT{1'b0}};
      assert_live_w_fire_q <= {S_COUNT{1'b0}};
      assert_wr_active_q <= {S_COUNT{1'b0}};
      assert_wr_terminal_q <= {S_COUNT{1'b0}};
      assert_b_stall_q <= {S_COUNT{1'b0}};
      for (assert_s = 0; assert_s < S_COUNT; assert_s = assert_s + 1) begin
        assert_grant_owner_q[assert_s] = {MASTER_W{1'b0}};
        assert_grant_addr_q[assert_s] = {ADDR_W{1'b0}};
        assert_grant_size_q[assert_s] = 3'd0;
        assert_grant_data_q[assert_s] = {DATA_W{1'b0}};
        assert_grant_strb_q[assert_s] = {STRB_W{1'b0}};
        assert_live_owner_q[assert_s] = {MASTER_W{1'b0}};
        assert_live_addr_q[assert_s] = {ADDR_W{1'b0}};
        assert_live_size_q[assert_s] = 3'd0;
        assert_live_data_q[assert_s] = {DATA_W{1'b0}};
        assert_live_strb_q[assert_s] = {STRB_W{1'b0}};
        assert_live_id_q[assert_s] = 4'd0;
        assert_wr_owner_q[assert_s] = {MASTER_W{1'b0}};
        assert_wr_addr_q[assert_s] = {ADDR_W{1'b0}};
        assert_wr_size_q[assert_s] = 3'd0;
        assert_wr_data_q[assert_s] = {DATA_W{1'b0}};
        assert_wr_strb_q[assert_s] = {STRB_W{1'b0}};
        assert_wr_id_q[assert_s] = 4'd0;
        assert_b_stall_owner_q[assert_s] = {MASTER_W{1'b0}};
        assert_b_stall_resp_q[assert_s] = 2'b00;
        assert_b_stall_id_q[assert_s] = 4'd0;
      end
    end else begin
      for (assert_m = 0; assert_m < M_COUNT; assert_m = assert_m + 1) begin
        if ((m_awready_r[assert_m] !==
             (!wr_aw_hold_q[assert_m] && !wr_master_busy_q[assert_m])) ||
            (m_wready_r[assert_m] !==
             (!wr_w_hold_q[assert_m] && !wr_master_busy_q[assert_m]))) begin
          $error("[XBAR-W-GRANT-MASTER-READY-LOCAL] master READY escaped holder/busy formula @%0t", $time);
          $fatal;
        end
      end

      for (assert_s = 0; assert_s < S_COUNT; assert_s = assert_s + 1) begin
        if (wr_grant_offer_r[assert_s]) begin
          // Icarus 12 mis-evaluates $isunknown on this variable-indexed
          // concatenation.  Case equality keeps the checker four-state and
          // portable while preserving the same fail-closed contract.
          if (((^wr_grant_master_r[assert_s]) === 1'bx) ||
              ((^s_awready_i[assert_s]) === 1'bx) ||
              ((^s_wready_i[assert_s]) === 1'bx)) begin
            $error("[XBAR-W-GRANT-KNOWN] target=%0d owner=%b awready=%b wready=%b contains X @%0t",
                   assert_s, wr_grant_master_r[assert_s],
                   s_awready_i[assert_s], s_wready_i[assert_s], $time);
            $fatal;
          end
          if (wr_active_q[assert_s] || !wr_grant_valid_r[assert_s] ||
              !wr_aw_hold_q[master_int(wr_grant_master_r[assert_s])] ||
              !wr_w_hold_q[master_int(wr_grant_master_r[assert_s])] ||
              (wr_awtarget_q[master_int(wr_grant_master_r[assert_s])] !=
               slave_idx(assert_s)) ||
              !s_awvalid_r[assert_s] || !s_wvalid_r[assert_s]) begin
            $error("[XBAR-W-GRANT-SOURCE] direct offer lacks exact inactive-target held-pair grant @%0t", $time);
            $fatal;
          end
          if ((s_awaddr_r[assert_s*ADDR_W +: ADDR_W] !==
               wr_awaddr_q[master_int(wr_grant_master_r[assert_s])]) ||
              (s_awsize_r[assert_s*3 +: 3] !==
               wr_awsize_q[master_int(wr_grant_master_r[assert_s])]) ||
              (s_wdata_r[assert_s*DATA_W +: DATA_W] !==
               wr_wdata_q[master_int(wr_grant_master_r[assert_s])]) ||
              (s_wstrb_r[assert_s*STRB_W +: STRB_W] !==
               wr_wstrb_q[master_int(wr_grant_master_r[assert_s])])) begin
            $error("[XBAR-W-GRANT-PAYLOAD] direct offer differs from selected holder Q @%0t", $time);
            $fatal;
          end
          if ((wr_grant_aw_fire_r[assert_s] !==
               (s_awvalid_r[assert_s] && s_awready_i[assert_s])) ||
              (wr_grant_w_fire_r[assert_s] !==
               (s_wvalid_r[assert_s] && s_wready_i[assert_s]))) begin
            $error("[XBAR-W-GRANT-FIRE] direct fire bookkeeping mismatch @%0t", $time);
            $fatal;
          end
          if (s_bready_r[assert_s] ||
              m_bvalid_r[master_int(wr_grant_master_r[assert_s])]) begin
            $error("[XBAR-W-GRANT-NO-B] B routed before registered owner/sent state @%0t", $time);
            $fatal;
          end
        end

        if (wr_live_offer_r[assert_s]) begin
          if (((^wr_live_master_r[assert_s]) === 1'bx) ||
              ((^s_awready_i[assert_s]) === 1'bx) ||
              ((^s_wready_i[assert_s]) === 1'bx)) begin
            $error("[XBAR-W-LIVE-KNOWN] target=%0d owner=%b awready=%b wready=%b contains X @%0t",
                   assert_s, wr_live_master_r[assert_s],
                   s_awready_i[assert_s], s_wready_i[assert_s], $time);
            $fatal;
          end
          if (rst || wr_active_q[assert_s] ||
              wr_any_complete_holder_r || wr_grant_offer_r[assert_s] ||
              !wr_live_unique_match_r[assert_s] ||
              !wr_live_pair_r[master_int(wr_live_master_r[assert_s])] ||
              (awtarget_decode_r[
                  master_int(wr_live_master_r[assert_s])] !=
               slave_idx(assert_s)) ||
              !s_awvalid_r[assert_s] || !s_wvalid_r[assert_s]) begin
            $error("[XBAR-W-LIVE-SOURCE] live offer lacks exact inactive-target complete-pair acquisition @%0t", $time);
            $fatal;
          end
          if ((s_awaddr_r[assert_s*ADDR_W +: ADDR_W] !==
               m_addr_slice(m_awaddr_i,
                   master_int(wr_live_master_r[assert_s]))) ||
              (s_awsize_r[assert_s*3 +: 3] !==
               m_size_slice(m_awsize_i,
                   master_int(wr_live_master_r[assert_s]))) ||
              (s_wdata_r[assert_s*DATA_W +: DATA_W] !==
               m_data_slice(m_wdata_i,
                   master_int(wr_live_master_r[assert_s]))) ||
              (s_wstrb_r[assert_s*STRB_W +: STRB_W] !==
               m_strb_slice(m_wstrb_i,
                   master_int(wr_live_master_r[assert_s])))) begin
            $error("[XBAR-W-LIVE-PAYLOAD] live target payload differs from selected master fire @%0t", $time);
            $fatal;
          end
          if ((wr_live_aw_fire_r[assert_s] !==
               (s_awvalid_r[assert_s] && s_awready_i[assert_s])) ||
              (wr_live_w_fire_r[assert_s] !==
               (s_wvalid_r[assert_s] && s_wready_i[assert_s]))) begin
            $error("[XBAR-W-LIVE-FIRE] live target fire bookkeeping mismatch @%0t", $time);
            $fatal;
          end
          if (s_bready_r[assert_s] ||
              m_bvalid_r[master_int(wr_live_master_r[assert_s])]) begin
            $error("[XBAR-W-LIVE-NO-B] B routed before registered live owner/sent state @%0t", $time);
            $fatal;
          end
        end

        if (assert_grant_offer_q[assert_s]) begin
          if (!wr_active_q[assert_s] ||
              (wr_owner_q[assert_s] !== assert_grant_owner_q[assert_s]) ||
              (wr_aw_sent_q[assert_s] !==
               assert_grant_aw_fire_q[assert_s]) ||
              (wr_w_sent_q[assert_s] !==
               assert_grant_w_fire_q[assert_s]) ||
              !wr_master_busy_q[master_int(assert_grant_owner_q[assert_s])]) begin
            $error("[XBAR-W-GRANT-SEED] grant edge failed to establish exact owner/sent state @%0t", $time);
            $fatal;
          end
          if ((!assert_grant_aw_fire_q[assert_s] &&
               (!s_awvalid_r[assert_s] ||
                (s_awaddr_r[assert_s*ADDR_W +: ADDR_W] !==
                 assert_grant_addr_q[assert_s]) ||
                (s_awsize_r[assert_s*3 +: 3] !==
                 assert_grant_size_q[assert_s]))) ||
              (!assert_grant_w_fire_q[assert_s] &&
               (!s_wvalid_r[assert_s] ||
                (s_wdata_r[assert_s*DATA_W +: DATA_W] !==
                 assert_grant_data_q[assert_s]) ||
                (s_wstrb_r[assert_s*STRB_W +: STRB_W] !==
                 assert_grant_strb_q[assert_s]))) ||
              (assert_grant_aw_fire_q[assert_s] &&
               s_awvalid_r[assert_s]) ||
              (assert_grant_w_fire_q[assert_s] &&
               s_wvalid_r[assert_s])) begin
            $error("[XBAR-W-GRANT-HANDOFF] accepted channel repeated or stalled payload changed @%0t", $time);
            $fatal;
          end
        end

        if (assert_live_offer_q[assert_s]) begin
          if (!wr_active_q[assert_s] ||
              (wr_owner_q[assert_s] !== assert_live_owner_q[assert_s]) ||
              (wr_aw_sent_q[assert_s] !==
               assert_live_aw_fire_q[assert_s]) ||
              (wr_w_sent_q[assert_s] !==
               assert_live_w_fire_q[assert_s]) ||
              (wr_addr_q[assert_s] !== assert_live_addr_q[assert_s]) ||
              (wr_size_q[assert_s] !== assert_live_size_q[assert_s]) ||
              (wr_data_q[assert_s] !== assert_live_data_q[assert_s]) ||
              (wr_strb_q[assert_s] !== assert_live_strb_q[assert_s]) ||
              (wr_id_q[assert_s] !== assert_live_id_q[assert_s]) ||
              wr_aw_hold_q[master_int(assert_live_owner_q[assert_s])] ||
              wr_w_hold_q[master_int(assert_live_owner_q[assert_s])] ||
              !wr_master_busy_q[
                  master_int(assert_live_owner_q[assert_s])]) begin
            $error("[XBAR-W-LIVE-SEED] live edge failed atomic owner/sent/payload handoff or left a residual holder @%0t", $time);
            $fatal;
          end
          if ((!assert_live_aw_fire_q[assert_s] &&
               (!s_awvalid_r[assert_s] ||
                (s_awaddr_r[assert_s*ADDR_W +: ADDR_W] !==
                 assert_live_addr_q[assert_s]) ||
                (s_awsize_r[assert_s*3 +: 3] !==
                 assert_live_size_q[assert_s]))) ||
              (!assert_live_w_fire_q[assert_s] &&
               (!s_wvalid_r[assert_s] ||
                (s_wdata_r[assert_s*DATA_W +: DATA_W] !==
                 assert_live_data_q[assert_s]) ||
                (s_wstrb_r[assert_s*STRB_W +: STRB_W] !==
                 assert_live_strb_q[assert_s]))) ||
              (assert_live_aw_fire_q[assert_s] &&
               s_awvalid_r[assert_s]) ||
              (assert_live_w_fire_q[assert_s] &&
               s_wvalid_r[assert_s])) begin
            $error("[XBAR-W-LIVE-HANDOFF] accepted live channel repeated or registered retry payload changed @%0t", $time);
            $fatal;
          end
        end

        if (assert_wr_active_q[assert_s] &&
            !assert_wr_terminal_q[assert_s]) begin
          if (!wr_active_q[assert_s] ||
              (wr_owner_q[assert_s] !== assert_wr_owner_q[assert_s]) ||
              (wr_addr_q[assert_s] !== assert_wr_addr_q[assert_s]) ||
              (wr_size_q[assert_s] !== assert_wr_size_q[assert_s]) ||
              (wr_data_q[assert_s] !== assert_wr_data_q[assert_s]) ||
              (wr_strb_q[assert_s] !== assert_wr_strb_q[assert_s]) ||
              (wr_id_q[assert_s] !== assert_wr_id_q[assert_s]) ||
              !wr_master_busy_q[
                  master_int(assert_wr_owner_q[assert_s])]) begin
            $error("[XBAR-W-OWNER-STABLE] active owner/payload changed or released before exact B terminal @%0t", $time);
            $fatal;
          end
        end

        if (assert_b_stall_q[assert_s]) begin
          if (!wr_active_q[assert_s] ||
              !wr_aw_sent_q[assert_s] || !wr_w_sent_q[assert_s] ||
              (wr_owner_q[assert_s] !==
               assert_b_stall_owner_q[assert_s]) ||
              !wr_master_busy_q[
                  master_int(assert_b_stall_owner_q[assert_s])] ||
              !m_bvalid_r[
                  master_int(assert_b_stall_owner_q[assert_s])] ||
              (m_bresp_r[
                  master_int(assert_b_stall_owner_q[assert_s])*2 +: 2] !==
               assert_b_stall_resp_q[assert_s]) ||
              (m_bid_r[
                  master_int(assert_b_stall_owner_q[assert_s])*4 +: 4] !==
               assert_b_stall_id_q[assert_s])) begin
            $error("[XBAR-W-B-STALL-STABLE] B backpressure changed owner/id/resp or released state @%0t", $time);
            $fatal;
          end
        end

        if ((s_bready_r[assert_s] ||
             (wr_active_q[assert_s] &&
              m_bvalid_r[master_int(wr_owner_q[assert_s])])) &&
            (!wr_active_q[assert_s] || !wr_aw_sent_q[assert_s] ||
             !wr_w_sent_q[assert_s])) begin
          $error("[XBAR-W-B-REGISTERED-AUTH] B route lacks registered active+dual-sent authorization @%0t", $time);
          $fatal;
        end

        for (assert_t = assert_s + 1; assert_t < S_COUNT;
             assert_t = assert_t + 1) begin
          if (wr_grant_offer_r[assert_s] && wr_grant_offer_r[assert_t] &&
              (wr_grant_master_r[assert_s] ==
               wr_grant_master_r[assert_t])) begin
            $error("[XBAR-W-GRANT-MASTER-ONEHOT] one master granted to multiple targets @%0t", $time);
            $fatal;
          end
          if (wr_live_offer_r[assert_s] && wr_live_offer_r[assert_t] &&
              (wr_live_master_r[assert_s] ==
               wr_live_master_r[assert_t])) begin
            $error("[XBAR-W-LIVE-MASTER-ONEHOT] one live master acquired multiple targets @%0t", $time);
            $fatal;
          end
          if ((wr_grant_offer_r[assert_s] &&
               wr_live_offer_r[assert_t] &&
               (wr_grant_master_r[assert_s] ==
                wr_live_master_r[assert_t])) ||
              (wr_live_offer_r[assert_s] &&
               wr_grant_offer_r[assert_t] &&
               (wr_live_master_r[assert_s] ==
                wr_grant_master_r[assert_t]))) begin
            $error("[XBAR-W-OFFER-MASTER-ONEHOT] one master selected by held and live targets @%0t", $time);
            $fatal;
          end
          if (wr_active_q[assert_s] && wr_active_q[assert_t] &&
              (wr_owner_q[assert_s] == wr_owner_q[assert_t])) begin
            $error("[XBAR-W-ACTIVE-MASTER-ONEHOT] one master owns multiple active targets @%0t", $time);
            $fatal;
          end
        end

        assert_grant_offer_q[assert_s] <= wr_grant_offer_r[assert_s];
        assert_grant_aw_fire_q[assert_s] <=
            wr_grant_aw_fire_r[assert_s];
        assert_grant_w_fire_q[assert_s] <=
            wr_grant_w_fire_r[assert_s];
        assert_grant_owner_q[assert_s] = wr_grant_master_r[assert_s];
        assert_grant_addr_q[assert_s] =
            s_awaddr_r[assert_s*ADDR_W +: ADDR_W];
        assert_grant_size_q[assert_s] =
            s_awsize_r[assert_s*3 +: 3];
        assert_grant_data_q[assert_s] =
            s_wdata_r[assert_s*DATA_W +: DATA_W];
        assert_grant_strb_q[assert_s] =
            s_wstrb_r[assert_s*STRB_W +: STRB_W];
        assert_live_offer_q[assert_s] <= wr_live_offer_r[assert_s];
        assert_live_aw_fire_q[assert_s] <= wr_live_aw_fire_r[assert_s];
        assert_live_w_fire_q[assert_s] <= wr_live_w_fire_r[assert_s];
        assert_live_owner_q[assert_s] = wr_live_master_r[assert_s];
        assert_live_addr_q[assert_s] =
            s_awaddr_r[assert_s*ADDR_W +: ADDR_W];
        assert_live_size_q[assert_s] =
            s_awsize_r[assert_s*3 +: 3];
        assert_live_data_q[assert_s] =
            s_wdata_r[assert_s*DATA_W +: DATA_W];
        assert_live_strb_q[assert_s] =
            s_wstrb_r[assert_s*STRB_W +: STRB_W];
        assert_live_id_q[assert_s] =
            m_id_slice(m_awid_i, master_int(wr_live_master_r[assert_s]));
        assert_wr_active_q[assert_s] <= wr_active_q[assert_s];
        assert_wr_terminal_q[assert_s] <=
            wr_active_q[assert_s] && wr_aw_sent_q[assert_s] &&
            wr_w_sent_q[assert_s] && s_bvalid_i[assert_s] &&
            s_bready_r[assert_s];
        assert_wr_owner_q[assert_s] = wr_owner_q[assert_s];
        assert_wr_addr_q[assert_s] = wr_addr_q[assert_s];
        assert_wr_size_q[assert_s] = wr_size_q[assert_s];
        assert_wr_data_q[assert_s] = wr_data_q[assert_s];
        assert_wr_strb_q[assert_s] = wr_strb_q[assert_s];
        assert_wr_id_q[assert_s] = wr_id_q[assert_s];
        assert_b_stall_q[assert_s] <=
            wr_active_q[assert_s] && wr_aw_sent_q[assert_s] &&
            wr_w_sent_q[assert_s] &&
            m_bvalid_r[master_int(wr_owner_q[assert_s])] &&
            !m_bready_i[master_int(wr_owner_q[assert_s])];
        assert_b_stall_owner_q[assert_s] = wr_owner_q[assert_s];
        assert_b_stall_resp_q[assert_s] =
            m_bresp_r[master_int(wr_owner_q[assert_s])*2 +: 2];
        assert_b_stall_id_q[assert_s] =
            m_bid_r[master_int(wr_owner_q[assert_s])*4 +: 4];
      end
    end
  end
  /* verilator lint_on BLKSEQ */
`endif

endmodule
