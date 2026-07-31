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

  always @(*) begin
    m_arready_r = {M_COUNT{1'b0}};
    m_awready_r = {M_COUNT{1'b0}};
    m_wready_r = {M_COUNT{1'b0}};
    m_rvalid_r = {M_COUNT{1'b0}};
    m_rdata_r = {M_COUNT*DATA_W{1'b0}};
    m_rresp_r = {M_COUNT*2{1'b0}};
    m_rid_r = {M_COUNT*4{1'b0}};
    m_bvalid_r = {M_COUNT{1'b0}};
    m_bresp_r = {M_COUNT*2{1'b0}};
    m_bid_r = {M_COUNT*4{1'b0}};

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
    s_bready_r = {S_COUNT{1'b0}};

    rd_grant_valid_r = {S_COUNT{1'b0}};
    wr_grant_valid_r = {S_COUNT{1'b0}};
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
      m_awready_r[m] = !wr_aw_hold_q[m] && !wr_master_busy_q[m];
      m_wready_r[m] = !wr_w_hold_q[m] && !wr_master_busy_q[m];
    end

    for (s = 0; s < S_COUNT; s = s + 1) begin
      if (!wr_active_q[s]) begin
        if (M_COUNT == 2) begin
          // 写通道同样针对真实两 master 路径展开，保留 AW/W hold 后再 grant 的协议边界。
          if (wr_rr_q[s] == master_idx(0)) begin
            if (wr_aw_hold_q[0] && wr_w_hold_q[0] &&
                !wr_master_busy_q[0] && (wr_awtarget_q[0] == slave_idx(s))) begin
              wr_grant_valid_r[s] = 1'b1;
              wr_grant_master_r[s] = master_idx(0);
            end else if (wr_aw_hold_q[1] && wr_w_hold_q[1] &&
                         !wr_master_busy_q[1] && (wr_awtarget_q[1] == slave_idx(s))) begin
              wr_grant_valid_r[s] = 1'b1;
              wr_grant_master_r[s] = master_idx(1);
            end
          end else begin
            if (wr_aw_hold_q[1] && wr_w_hold_q[1] &&
                !wr_master_busy_q[1] && (wr_awtarget_q[1] == slave_idx(s))) begin
              wr_grant_valid_r[s] = 1'b1;
              wr_grant_master_r[s] = master_idx(1);
            end else if (wr_aw_hold_q[0] && wr_w_hold_q[0] &&
                         !wr_master_busy_q[0] && (wr_awtarget_q[0] == slave_idx(s))) begin
              wr_grant_valid_r[s] = 1'b1;
              wr_grant_master_r[s] = master_idx(0);
            end
          end
        end else begin
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

      if (wr_active_q[s] && wr_aw_sent_q[s] && wr_w_sent_q[s]) begin
        owner = master_int(wr_owner_q[s]);
        m_bvalid_r[owner] = s_bvalid_i[s];
        m_bresp_r[owner*2 +: 2] = s_bresp_i[s*2 +: 2];
        m_bid_r[owner*4 +: 4] = wr_id_q[s];
        s_bready_r[s] = m_bready_i[owner];
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
          wr_aw_sent_q[s] <= 1'b0;
          wr_w_sent_q[s] <= 1'b0;
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
      end
    end
  end

endmodule
