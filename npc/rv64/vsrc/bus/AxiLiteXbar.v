// 参数化 single-beat AXI-like crossbar。
// 当前 NPC cache miss 侧还没有 AXI4 ID/burst，本模块先把 valid/ready 通道、
// 地址译码和 response route 独立出来，后续扩设备时不再改 core/cache。

module AxiLiteXbar #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8,
  parameter ARUSER_W = 1,
  parameter M_COUNT = 2,
  parameter S_COUNT = 1,
  parameter DEFAULT_SLAVE = 0,
  parameter [S_COUNT*ADDR_W-1:0] SLAVE_BASE = {S_COUNT{32'h0000_0000}},
  parameter [S_COUNT*ADDR_W-1:0] SLAVE_MASK = {S_COUNT{32'h0000_0000}}
) (
  input clk,
  input rst,

  input [M_COUNT-1:0] m_arvalid_i,
  output [M_COUNT-1:0] m_arready_o,
  input [M_COUNT*ADDR_W-1:0] m_araddr_i,
  input [M_COUNT*STRB_W-1:0] m_arstrb_i,
  input [M_COUNT*ARUSER_W-1:0] m_aruser_i,
  input [M_COUNT-1:0] m_read_abort_i,
  output [M_COUNT-1:0] m_rvalid_o,
  input [M_COUNT-1:0] m_rready_i,
  output [M_COUNT*DATA_W-1:0] m_rdata_o,
  output [M_COUNT*2-1:0] m_rresp_o,

  input [M_COUNT-1:0] m_awvalid_i,
  output [M_COUNT-1:0] m_awready_o,
  input [M_COUNT*ADDR_W-1:0] m_awaddr_i,
  input [M_COUNT-1:0] m_wvalid_i,
  output [M_COUNT-1:0] m_wready_o,
  input [M_COUNT*DATA_W-1:0] m_wdata_i,
  input [M_COUNT*STRB_W-1:0] m_wstrb_i,
  output [M_COUNT-1:0] m_bvalid_o,
  input [M_COUNT-1:0] m_bready_i,
  output [M_COUNT*2-1:0] m_bresp_o,

  output [S_COUNT-1:0] s_arvalid_o,
  input [S_COUNT-1:0] s_arready_i,
  output [S_COUNT*ADDR_W-1:0] s_araddr_o,
  output [S_COUNT*STRB_W-1:0] s_arstrb_o,
  output [S_COUNT*ARUSER_W-1:0] s_aruser_o,
  input [S_COUNT-1:0] s_rvalid_i,
  output [S_COUNT-1:0] s_rready_o,
  input [S_COUNT*DATA_W-1:0] s_rdata_i,
  input [S_COUNT*2-1:0] s_rresp_i,

  output [S_COUNT-1:0] s_awvalid_o,
  input [S_COUNT-1:0] s_awready_i,
  output [S_COUNT*ADDR_W-1:0] s_awaddr_o,
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

  function [ARUSER_W-1:0] m_user_slice;
    input [M_COUNT*ARUSER_W-1:0] bus;
    input [MASTER_W-1:0] idx;
    begin
      m_user_slice = bus[idx*ARUSER_W +: ARUSER_W];
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

  reg [M_COUNT-1:0] m_arready_r;
  reg [M_COUNT-1:0] m_awready_r;
  reg [M_COUNT-1:0] m_wready_r;
  reg [M_COUNT-1:0] m_rvalid_r;
  reg [M_COUNT*DATA_W-1:0] m_rdata_r;
  reg [M_COUNT*2-1:0] m_rresp_r;
  reg [M_COUNT-1:0] m_bvalid_r;
  reg [M_COUNT*2-1:0] m_bresp_r;

  reg [S_COUNT-1:0] s_arvalid_r;
  reg [S_COUNT*ADDR_W-1:0] s_araddr_r;
  reg [S_COUNT*STRB_W-1:0] s_arstrb_r;
  reg [S_COUNT*ARUSER_W-1:0] s_aruser_r;
  reg [S_COUNT-1:0] s_rready_r;
  reg [S_COUNT-1:0] s_awvalid_r;
  reg [S_COUNT*ADDR_W-1:0] s_awaddr_r;
  reg [S_COUNT-1:0] s_wvalid_r;
  reg [S_COUNT*DATA_W-1:0] s_wdata_r;
  reg [S_COUNT*STRB_W-1:0] s_wstrb_r;
  reg [S_COUNT-1:0] s_bready_r;

  reg [M_COUNT-1:0] rd_master_busy_q;
  reg [M_COUNT-1:0] rd_resp_valid_q;
  reg [DATA_W-1:0] rd_resp_data_q [0:M_COUNT-1];
  reg [1:0] rd_resp_resp_q [0:M_COUNT-1];
  reg [S_COUNT-1:0] rd_active_q;
  reg [S_COUNT-1:0] rd_ar_sent_q;
  reg [S_COUNT-1:0] rd_drop_q;
  reg [MASTER_W-1:0] rd_owner_q [0:S_COUNT-1];
  reg [MASTER_W-1:0] rd_rr_q [0:S_COUNT-1];
  reg [ADDR_W-1:0] rd_addr_q [0:S_COUNT-1];
  reg [STRB_W-1:0] rd_strb_q [0:S_COUNT-1];
  reg [ARUSER_W-1:0] rd_user_q [0:S_COUNT-1];

  reg [M_COUNT-1:0] wr_master_busy_q;
  reg [M_COUNT-1:0] wr_aw_hold_q;
  reg [M_COUNT-1:0] wr_w_hold_q;
  reg [ADDR_W-1:0] wr_awaddr_q [0:M_COUNT-1];
  reg [SLAVE_W-1:0] wr_awtarget_q [0:M_COUNT-1];
  reg [DATA_W-1:0] wr_wdata_q [0:M_COUNT-1];
  reg [STRB_W-1:0] wr_wstrb_q [0:M_COUNT-1];

  reg [S_COUNT-1:0] wr_active_q;
  reg [S_COUNT-1:0] wr_aw_sent_q;
  reg [S_COUNT-1:0] wr_w_sent_q;
  reg [MASTER_W-1:0] wr_owner_q [0:S_COUNT-1];
  reg [MASTER_W-1:0] wr_rr_q [0:S_COUNT-1];
  reg [ADDR_W-1:0] wr_addr_q [0:S_COUNT-1];
  reg [DATA_W-1:0] wr_data_q [0:S_COUNT-1];
  reg [STRB_W-1:0] wr_strb_q [0:S_COUNT-1];

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
  assign m_bvalid_o = m_bvalid_r;
  assign m_bresp_o = m_bresp_r;

  assign s_arvalid_o = s_arvalid_r;
  assign s_araddr_o = s_araddr_r;
  assign s_arstrb_o = s_arstrb_r;
  assign s_aruser_o = s_aruser_r;
  assign s_rready_o = s_rready_r;
  assign s_awvalid_o = s_awvalid_r;
  assign s_awaddr_o = s_awaddr_r;
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
    m_bvalid_r = {M_COUNT{1'b0}};
    m_bresp_r = {M_COUNT*2{1'b0}};

    s_arvalid_r = {S_COUNT{1'b0}};
    s_araddr_r = {S_COUNT*ADDR_W{1'b0}};
    s_arstrb_r = {S_COUNT*STRB_W{1'b0}};
    s_aruser_r = {S_COUNT*ARUSER_W{1'b0}};
    s_rready_r = {S_COUNT{1'b0}};
    s_awvalid_r = {S_COUNT{1'b0}};
    s_awaddr_r = {S_COUNT*ADDR_W{1'b0}};
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
      artarget_decode_r[m] = decode_slave(m_addr_slice(m_araddr_i, m));
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
      end
    end

    for (s = 0; s < S_COUNT; s = s + 1) begin
      if (!rd_active_q[s]) begin
        if (M_COUNT == 2) begin
          // 当前 RV64 平台真实使用 IFU/LSU 两个 master；显式两路选择避免综合成可变扫描链。
          if (rd_rr_q[s] == master_idx(0)) begin
            if (m_arvalid_i[0] && !rd_master_busy_q[0] &&
                !m_read_abort_i[0] && (artarget_decode_r[0] == slave_idx(s))) begin
              rd_grant_valid_r[s] = 1'b1;
              rd_grant_master_r[s] = master_idx(0);
              m_arready_r[0] = 1'b1;
            end else if (m_arvalid_i[1] && !rd_master_busy_q[1] &&
                         !m_read_abort_i[1] && (artarget_decode_r[1] == slave_idx(s))) begin
              rd_grant_valid_r[s] = 1'b1;
              rd_grant_master_r[s] = master_idx(1);
              m_arready_r[1] = 1'b1;
            end
          end else begin
            if (m_arvalid_i[1] && !rd_master_busy_q[1] &&
                !m_read_abort_i[1] && (artarget_decode_r[1] == slave_idx(s))) begin
              rd_grant_valid_r[s] = 1'b1;
              rd_grant_master_r[s] = master_idx(1);
              m_arready_r[1] = 1'b1;
            end else if (m_arvalid_i[0] && !rd_master_busy_q[0] &&
                         !m_read_abort_i[0] && (artarget_decode_r[0] == slave_idx(s))) begin
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
                !m_read_abort_i[cand] &&
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
        s_arstrb_r[s*STRB_W +: STRB_W] = rd_strb_q[s];
        s_aruser_r[s*ARUSER_W +: ARUSER_W] = rd_user_q[s];
      end

      if (rd_active_q[s] && rd_ar_sent_q[s]) begin
        owner = master_int(rd_owner_q[s]);
        if (rd_drop_q[s] || m_read_abort_i[owner]) begin
          s_rready_r[s] = 1'b1;
        end else if (!rd_resp_valid_q[owner]) begin
          m_rvalid_r[owner] = s_rvalid_i[s];
          m_rdata_r[owner*DATA_W +: DATA_W] = s_rdata_i[s*DATA_W +: DATA_W];
          m_rresp_r[owner*2 +: 2] = s_rresp_i[s*2 +: 2];
          // 即使 master 暂时不 ready，也先把 response 收进 master-side buffer，
          // 释放 slave，避免 IFU response 阻塞 LSU miss 形成结构死锁。
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
      rd_drop_q <= {S_COUNT{1'b0}};
      wr_active_q <= {S_COUNT{1'b0}};
      wr_aw_sent_q <= {S_COUNT{1'b0}};
      wr_w_sent_q <= {S_COUNT{1'b0}};
      for (m = 0; m < M_COUNT; m = m + 1) begin
        rd_resp_data_q[m] <= {DATA_W{1'b0}};
        rd_resp_resp_q[m] <= 2'b00;
        wr_awaddr_q[m] <= {ADDR_W{1'b0}};
        wr_awtarget_q[m] <= {SLAVE_W{1'b0}};
        wr_wdata_q[m] <= {DATA_W{1'b0}};
        wr_wstrb_q[m] <= {STRB_W{1'b0}};
      end
      for (s = 0; s < S_COUNT; s = s + 1) begin
        rd_owner_q[s] <= {MASTER_W{1'b0}};
        rd_rr_q[s] <= {MASTER_W{1'b0}};
        rd_addr_q[s] <= {ADDR_W{1'b0}};
        rd_strb_q[s] <= {STRB_W{1'b0}};
        rd_user_q[s] <= {ARUSER_W{1'b0}};
        wr_owner_q[s] <= {MASTER_W{1'b0}};
        wr_rr_q[s] <= {MASTER_W{1'b0}};
        wr_addr_q[s] <= {ADDR_W{1'b0}};
        wr_data_q[s] <= {DATA_W{1'b0}};
        wr_strb_q[s] <= {STRB_W{1'b0}};
      end
    end else begin
      for (m = 0; m < M_COUNT; m = m + 1) begin
        if (rd_resp_valid_q[m] && m_rready_i[m]) begin
          rd_resp_valid_q[m] <= 1'b0;
          rd_master_busy_q[m] <= 1'b0;
        end

        if (m_read_abort_i[m] && rd_resp_valid_q[m]) begin
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
          rd_drop_q[s] <= 1'b0;
          if (rd_drop_q[s] || m_read_abort_i[master_int(rd_owner_q[s])]) begin
            rd_master_busy_q[master_int(rd_owner_q[s])] <= 1'b0;
          end else if (m_rready_i[master_int(rd_owner_q[s])]) begin
            rd_master_busy_q[master_int(rd_owner_q[s])] <= 1'b0;
          end else begin
            rd_resp_valid_q[master_int(rd_owner_q[s])] <= 1'b1;
            rd_resp_data_q[master_int(rd_owner_q[s])] <= s_rdata_i[s*DATA_W +: DATA_W];
            rd_resp_resp_q[master_int(rd_owner_q[s])] <= s_rresp_i[s*2 +: 2];
          end
        end else if (rd_active_q[s] &&
                     m_read_abort_i[master_int(rd_owner_q[s])]) begin
          if (rd_ar_sent_q[s] || (s_arvalid_r[s] && s_arready_i[s])) begin
            // AR 已经在当前或更早周期被 slave 接收，不能凭空取消；
            // 保持 master busy，等 R 返回后按 drop 丢弃，避免留下 orphan response。
            rd_ar_sent_q[s] <= 1'b1;
            rd_drop_q[s] <= 1'b1;
          end else begin
            rd_active_q[s] <= 1'b0;
            rd_ar_sent_q[s] <= 1'b0;
            rd_drop_q[s] <= 1'b0;
            rd_master_busy_q[master_int(rd_owner_q[s])] <= 1'b0;
          end
        end

        if (!rd_active_q[s] && rd_grant_valid_r[s]) begin
          rd_active_q[s] <= 1'b1;
          rd_ar_sent_q[s] <= 1'b0;
          rd_drop_q[s] <= 1'b0;
          rd_owner_q[s] <= rd_grant_master_r[s];
          rd_addr_q[s] <= m_addr_slice(m_araddr_i, master_int(rd_grant_master_r[s]));
          rd_strb_q[s] <= m_strb_slice(m_arstrb_i, master_int(rd_grant_master_r[s]));
          rd_user_q[s] <= m_user_slice(m_aruser_i, master_int(rd_grant_master_r[s]));
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
          wr_data_q[s] <= wr_wdata_q[master_int(wr_grant_master_r[s])];
          wr_strb_q[s] <= wr_wstrb_q[master_int(wr_grant_master_r[s])];
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
