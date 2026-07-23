module tb_axi_xbar;
  `include "tb_common.svh"

  localparam ADDR_W = 32;
  localparam DATA_W = 32;
  localparam STRB_W = DATA_W / 8;
  localparam M_COUNT = 2;
  localparam S_COUNT = 3;
  localparam DEFAULT_SLAVE = 2;
  localparam [S_COUNT*ADDR_W-1:0] SLAVE_BASE = {
      32'h2000_0000,
      32'h1000_0000,
      32'h0000_0000
  };
  localparam [S_COUNT*ADDR_W-1:0] SLAVE_MASK = {
      32'hffff_f000,
      32'hffff_f000,
      32'hffff_f000
  };

  // 【AXI4 化 S3/S4】master 口全 AXI4: prot 语义 ARPROT[2]=1 表 instruction。
  localparam [2:0] PROT_IFETCH = 3'b100;
  localparam [2:0] PROT_DATA = 3'b000;
  localparam [3:0] ARID_M0 = 4'h6;
  localparam [3:0] ARID_M1 = 4'h9;

  reg clk;
  reg rst;

  reg [M_COUNT-1:0] m_arvalid;
  wire [M_COUNT-1:0] m_arready;
  reg [M_COUNT*ADDR_W-1:0] m_araddr;
  reg [M_COUNT*4-1:0] m_arid;
  reg [M_COUNT*8-1:0] m_arlen;
  reg [M_COUNT*3-1:0] m_arsize;
  reg [M_COUNT*2-1:0] m_arburst;
  reg [M_COUNT*3-1:0] m_arprot;
  wire [M_COUNT-1:0] m_rvalid;
  reg [M_COUNT-1:0] m_rready;
  wire [M_COUNT*DATA_W-1:0] m_rdata;
  wire [M_COUNT*2-1:0] m_rresp;
  wire [M_COUNT*4-1:0] m_rid;
  wire [M_COUNT-1:0] m_rlast;

  reg [M_COUNT-1:0] m_awvalid;
  wire [M_COUNT-1:0] m_awready;
  reg [M_COUNT*ADDR_W-1:0] m_awaddr;
  reg [M_COUNT*4-1:0] m_awid;
  reg [M_COUNT*8-1:0] m_awlen;
  reg [M_COUNT*3-1:0] m_awsize;
  reg [M_COUNT*2-1:0] m_awburst;
  reg [M_COUNT-1:0] m_wvalid;
  wire [M_COUNT-1:0] m_wready;
  reg [M_COUNT*DATA_W-1:0] m_wdata;
  reg [M_COUNT*STRB_W-1:0] m_wstrb;
  reg [M_COUNT-1:0] m_wlast;
  wire [M_COUNT-1:0] m_bvalid;
  reg [M_COUNT-1:0] m_bready;
  wire [M_COUNT*2-1:0] m_bresp;
  wire [M_COUNT*4-1:0] m_bid;

  wire [S_COUNT-1:0] s_arvalid;
  reg [S_COUNT-1:0] s_arready;
  wire [S_COUNT*ADDR_W-1:0] s_araddr;
  wire [S_COUNT*3-1:0] s_arprot;
  reg [S_COUNT-1:0] s_rvalid;
  wire [S_COUNT-1:0] s_rready;
  reg [S_COUNT*DATA_W-1:0] s_rdata;
  reg [S_COUNT*2-1:0] s_rresp;

  wire [S_COUNT-1:0] s_awvalid;
  reg [S_COUNT-1:0] s_awready;
  wire [S_COUNT*ADDR_W-1:0] s_awaddr;
  wire [S_COUNT*3-1:0] s_awsize;
  wire [S_COUNT-1:0] s_wvalid;
  reg [S_COUNT-1:0] s_wready;
  wire [S_COUNT*DATA_W-1:0] s_wdata;
  wire [S_COUNT*STRB_W-1:0] s_wstrb;
  reg [S_COUNT-1:0] s_bvalid;
  wire [S_COUNT-1:0] s_bready;
  reg [S_COUNT*2-1:0] s_bresp;

  AxiXbar #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .STRB_W(STRB_W),
    .M_COUNT(M_COUNT),
    .S_COUNT(S_COUNT),
    .DEFAULT_SLAVE(DEFAULT_SLAVE),
    .SLAVE_BASE(SLAVE_BASE),
    .SLAVE_MASK(SLAVE_MASK)
  ) dut (
    .clk(clk),
    .rst(rst),
    .m_arvalid_i(m_arvalid),
    .m_arready_o(m_arready),
    .m_araddr_i(m_araddr),
    .m_arid_i(m_arid),
    .m_arlen_i(m_arlen),
    .m_arsize_i(m_arsize),
    .m_arburst_i(m_arburst),
    .m_arprot_i(m_arprot),
    .m_rvalid_o(m_rvalid),
    .m_rready_i(m_rready),
    .m_rdata_o(m_rdata),
    .m_rresp_o(m_rresp),
    .m_rid_o(m_rid),
    .m_rlast_o(m_rlast),
    .m_awvalid_i(m_awvalid),
    .m_awready_o(m_awready),
    .m_awaddr_i(m_awaddr),
    .m_awid_i(m_awid),
    .m_awlen_i(m_awlen),
    .m_awsize_i(m_awsize),
    .m_awburst_i(m_awburst),
    .m_wvalid_i(m_wvalid),
    .m_wready_o(m_wready),
    .m_wdata_i(m_wdata),
    .m_wstrb_i(m_wstrb),
    .m_wlast_i(m_wlast),
    .m_bvalid_o(m_bvalid),
    .m_bready_i(m_bready),
    .m_bresp_o(m_bresp),
    .m_bid_o(m_bid),
    .s_arvalid_o(s_arvalid),
    .s_arready_i(s_arready),
    .s_araddr_o(s_araddr),
    .s_arprot_o(s_arprot),
    .s_rvalid_i(s_rvalid),
    .s_rready_o(s_rready),
    .s_rdata_i(s_rdata),
    .s_rresp_i(s_rresp),
    .s_awvalid_o(s_awvalid),
    .s_awready_i(s_awready),
    .s_awaddr_o(s_awaddr),
    .s_awsize_o(s_awsize),
    .s_wvalid_o(s_wvalid),
    .s_wready_i(s_wready),
    .s_wdata_o(s_wdata),
    .s_wstrb_o(s_wstrb),
    .s_bvalid_i(s_bvalid),
    .s_bready_o(s_bready),
    .s_bresp_i(s_bresp)
  );

  task automatic clear_inputs;
    begin
      m_arvalid = {M_COUNT{1'b0}};
      m_araddr = {M_COUNT*ADDR_W{1'b0}};
      m_arid = {M_COUNT*4{1'b0}};
      m_arlen = {M_COUNT*8{1'b0}};
      m_arsize = {M_COUNT*3{1'b0}};
      m_arburst = {M_COUNT*2{1'b0}};
      m_arprot = {M_COUNT*3{1'b0}};
      m_rready = {M_COUNT{1'b0}};
      m_awvalid = {M_COUNT{1'b0}};
      m_awaddr = {M_COUNT*ADDR_W{1'b0}};
      m_awid = {M_COUNT*4{1'b0}};
      m_awlen = {M_COUNT*8{1'b0}};
      m_awsize = {M_COUNT*3{1'b0}};
      m_awburst = {M_COUNT*2{1'b0}};
      m_wvalid = {M_COUNT{1'b0}};
      m_wdata = {M_COUNT*DATA_W{1'b0}};
      m_wstrb = {M_COUNT*STRB_W{1'b0}};
      m_wlast = {M_COUNT{1'b0}};
      m_bready = {M_COUNT{1'b0}};
      s_arready = {S_COUNT{1'b0}};
      s_rvalid = {S_COUNT{1'b0}};
      s_rdata = {S_COUNT*DATA_W{1'b0}};
      s_rresp = {S_COUNT*2{1'b0}};
      s_awready = {S_COUNT{1'b0}};
      s_wready = {S_COUNT{1'b0}};
      s_bvalid = {S_COUNT{1'b0}};
      s_bresp = {S_COUNT*2{1'b0}};
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  function automatic [3:0] master_arid;
    input integer mid;
    begin
      master_arid = (mid == 0) ? ARID_M0 : ARID_M1;
    end
  endfunction

  task automatic drive_read;
    input integer mid;
    input [ADDR_W-1:0] addr;
    input [2:0] prot;
    begin
      drive_read_meta(mid, addr, prot, master_arid(mid), 3'd2);
    end
  endtask

  task automatic drive_read_meta;
    input integer mid;
    input [ADDR_W-1:0] addr;
    input [2:0] prot;
    input [3:0] id;
    input [2:0] size;
    begin
      m_araddr[mid*ADDR_W +: ADDR_W] = addr;
      m_arid[mid*4 +: 4] = id;
      m_arlen[mid*8 +: 8] = 8'd0;
      m_arsize[mid*3 +: 3] = size;
      m_arburst[mid*2 +: 2] = 2'b01;
      m_arprot[mid*3 +: 3] = prot;
      m_arvalid[mid] = 1'b1;
    end
  endtask

  task automatic drive_read_response;
    input integer sid;
    input [DATA_W-1:0] data;
    input [1:0] resp;
    begin
      s_rdata[sid*DATA_W +: DATA_W] = data;
      s_rresp[sid*2 +: 2] = resp;
      s_rvalid[sid] = 1'b1;
    end
  endtask

  task automatic check_slave_read_addr;
    input [1023:0] what;
    input integer sid;
    input [ADDR_W-1:0] addr;
    input [2:0] prot;
    begin
      tb_check1({what, " arvalid"}, s_arvalid[sid], 1'b1);
      tb_check32({what, " araddr"}, s_araddr[sid*ADDR_W +: ADDR_W], addr);
      tb_check32({what, " arprot"}, {29'h0, s_arprot[sid*3 +: 3]},
                 {29'h0, prot});
    end
  endtask

  task automatic check_master_read_data;
    input [1023:0] what;
    input integer mid;
    input [DATA_W-1:0] data;
    input [1:0] resp;
    input [3:0] id;
    begin
      tb_check1({what, " rvalid"}, m_rvalid[mid], 1'b1);
      tb_check32({what, " rdata"}, m_rdata[mid*DATA_W +: DATA_W], data);
      tb_check32({what, " rresp"}, {30'b0, m_rresp[mid*2 +: 2]}, {30'b0, resp});
      tb_check32({what, " rid"}, {28'b0, m_rid[mid*4 +: 4]}, {28'b0, id});
      tb_check1({what, " rlast"}, m_rlast[mid], 1'b1);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    drive_read_meta(0, 32'h3000_0010, PROT_DATA, 4'h5, 3'd0);
    m_rready[0] = 1'b1;
    s_arready[2] = 1'b1;
    #1;
    tb_check1("default read grants master0", m_arready[0], 1'b1);
    `TB_TICK(clk);
    m_arvalid[0] = 1'b0;
    #1;
    check_slave_read_addr("default read", 2, 32'h3000_0010, PROT_DATA);
    `TB_TICK(clk);
    s_arready[2] = 1'b0;
    drive_read_response(2, 32'hd00d_0001, 2'b10);
    #1;
    tb_check1("default read slave ready", s_rready[2], 1'b1);
    tb_check1("default read has no R fall-through", m_rvalid[0], 1'b0);
    `TB_TICK(clk);
    s_rvalid[2] = 1'b0;
    #1;
    check_master_read_data("default read registered", 0,
                           32'hd00d_0001, 2'b10, 4'h5);
    `TB_TICK(clk);
    m_rready[0] = 1'b0;
    #1;
    tb_check1("default read consumed", m_rvalid[0], 1'b0);

    drive_read(0, 32'h0000_0020, PROT_IFETCH);
    s_arready[0] = 1'b1;
    #1;
    tb_check1("buffered read grants master0", m_arready[0], 1'b1);
    `TB_TICK(clk);
    m_arvalid[0] = 1'b0;
    #1;
    check_slave_read_addr("buffered read", 0, 32'h0000_0020, PROT_IFETCH);
    `TB_TICK(clk);
    s_arready[0] = 1'b0;
    drive_read_response(0, 32'hcafe_1000, 2'b01);
    #1;
    tb_check1("buffered read accepts slave response", s_rready[0], 1'b1);
    tb_check1("buffered read has no R fall-through", m_rvalid[0], 1'b0);
    `TB_TICK(clk);
    s_rvalid[0] = 1'b0;
    #1;
    // 所有 response 都走 registered slice；RID 随 data/resp 一起锁存。
    check_master_read_data("buffered read registered", 0,
                           32'hcafe_1000, 2'b01,
                           ARID_M0);
    s_rdata[0*DATA_W +: DATA_W] = 32'hdead_beef;
    s_rresp[0*2 +: 2] = 2'b10;
    `TB_TICK(clk);
    #1;
    check_master_read_data("buffered read stall stable", 0,
                           32'hcafe_1000, 2'b01, ARID_M0);
    m_rready[0] = 1'b1;
    `TB_TICK(clk);
    m_rready[0] = 1'b0;
    #1;
    tb_check1("buffered read consumed", m_rvalid[0], 1'b0);

    // 【AXI4 化 S2】abort 边带已删——丢弃责任移交 master 桥自吞(桥 TB drain 用例)。
    // xbar 视角: 被 flush 作废的读也是一个正常完成的读(master rready 收下丢弃)。
    drive_read(1, 32'h1000_0040, PROT_DATA);
    s_arready[1] = 1'b1;
    #1;
    tb_check1("flushed read still grants master1", m_arready[1], 1'b1);
    `TB_TICK(clk);
    m_arvalid[1] = 1'b0;
    #1;
    check_slave_read_addr("flushed read", 1, 32'h1000_0040, PROT_DATA);
    `TB_TICK(clk);
    s_arready[1] = 1'b0;
    m_rready[1] = 1'b1;   // master 自吞: 保持 rready 收响应
    drive_read_response(1, 32'hbad0_0001, 2'b11);
    #1;
    tb_check1("flushed read has no R fall-through", m_rvalid[1], 1'b0);
    `TB_TICK(clk);
    s_rvalid[1] = 1'b0;
    #1;
    check_master_read_data("flushed read registered", 1,
                           32'hbad0_0001, 2'b11, ARID_M1);
    `TB_TICK(clk);
    m_rready[1] = 1'b0;
    #1;
    drive_read(1, 32'h1000_0044, PROT_IFETCH);
    s_arready[1] = 1'b1;
    #1;
    tb_check1("next read grants master1", m_arready[1], 1'b1);
    `TB_TICK(clk);
    m_arvalid[1] = 1'b0;
    `TB_TICK(clk);
    s_arready[1] = 1'b0;
    m_rready[1] = 1'b1;
    drive_read_response(1, 32'h1234_5678, 2'b00);
    #1;
    tb_check1("post-flush read has no R fall-through", m_rvalid[1], 1'b0);
    `TB_TICK(clk);
    s_rvalid[1] = 1'b0;
    #1;
    check_master_read_data("post-flush read registered", 1,
                           32'h1234_5678, 2'b00, ARID_M1);
    `TB_TICK(clk);
    m_rready[1] = 1'b0;

    drive_read(0, 32'h0000_0100, PROT_IFETCH);
    drive_read(1, 32'h0000_0200, PROT_DATA);
    s_arready[0] = 1'b1;
    #1;
    tb_check1("round-robin prefers master1 after master0", m_arready[1], 1'b1);
    tb_check1("round-robin holds master0", m_arready[0], 1'b0);
    `TB_TICK(clk);
    m_arvalid[1] = 1'b0;
    #1;
    check_slave_read_addr("round-robin master1", 0, 32'h0000_0200, PROT_DATA);
    `TB_TICK(clk);
    drive_read_response(0, 32'h1111_0001, 2'b00);
    m_rready[1] = 1'b1;
    #1;
    tb_check1("round-robin master1 has no R fall-through",
              m_rvalid[1], 1'b0);
    `TB_TICK(clk);
    s_rvalid[0] = 1'b0;
    #1;
    check_master_read_data("round-robin master1 registered", 1,
                           32'h1111_0001, 2'b00, ARID_M1);
    // slave owner 已在 capture 拍释放；即使 master1 的 registered R 尚未
    // consume，另一 master 也必须可取得同一 slave，证明无跨 master HOL。
    tb_check1("round-robin returns to master0", m_arready[0], 1'b1);
    `TB_TICK(clk);
    m_rready[1] = 1'b0;
    m_arvalid[0] = 1'b0;
    #1;
    check_slave_read_addr("round-robin master0", 0,
                          32'h0000_0100, PROT_IFETCH);
    `TB_TICK(clk);
    m_rready[0] = 1'b1;
    drive_read_response(0, 32'h2222_0000, 2'b00);
    #1;
    tb_check1("round-robin master0 has no R fall-through",
              m_rvalid[0], 1'b0);
    `TB_TICK(clk);
    s_rvalid[0] = 1'b0;
    #1;
    check_master_read_data("round-robin master0 registered", 0,
                           32'h2222_0000, 2'b00, ARID_M0);
    `TB_TICK(clk);
    s_arready[0] = 1'b0;
    m_rready[0] = 1'b0;

    m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_0080;
    m_awid[1*4 +: 4] = 4'hb;
    m_awlen[1*8 +: 8] = 8'd0;
    m_awsize[1*3 +: 3] = 3'd0;
    m_awburst[1*2 +: 2] = 2'b01;
    m_awvalid[1] = 1'b1;
    #1;
    tb_check1("split write accepts aw", m_awready[1], 1'b1);
    `TB_TICK(clk);
    m_awvalid[1] = 1'b0;
    m_wdata[1*DATA_W +: DATA_W] = 32'hfeed_beef;
    m_wstrb[1*STRB_W +: STRB_W] = 4'ha;
    m_wlast[1] = 1'b1;
    m_wvalid[1] = 1'b1;
    #1;
    tb_check1("split write accepts w", m_wready[1], 1'b1);
    `TB_TICK(clk);
    m_wvalid[1] = 1'b0;
    `TB_TICK(clk);
    #1;
    tb_check1("split write slave awvalid", s_awvalid[1], 1'b1);
    tb_check1("split write slave wvalid", s_wvalid[1], 1'b1);
    tb_check32("split write slave awaddr", s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0080);
    tb_check32("split write slave awsize",
               {29'h0, s_awsize[1*3 +: 3]}, 32'd0);
    tb_check32("split write slave wdata", s_wdata[1*DATA_W +: DATA_W], 32'hfeed_beef);
    tb_check32("split write slave wstrb", {28'h0, s_wstrb[1*STRB_W +: STRB_W]}, 32'ha);

    // Slave AW/W 均 stall 时，输出必须保持已锁存的 master1 owner 元数据。
    m_awsize[1*3 +: 3] = 3'd7;
    `TB_TICK(clk);
    #1;
    tb_check1("split write stalled awvalid stable", s_awvalid[1], 1'b1);
    tb_check32("split write stalled awaddr stable",
               s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0080);
    tb_check32("split write stalled awsize stable",
               {29'h0, s_awsize[1*3 +: 3]}, 32'd0);

    // master0 先送 W、后送 AW；它只能排队，不能在 master1 的 B 前串 owner。
    m_wdata[0*DATA_W +: DATA_W] = 32'h1234_5678;
    m_wstrb[0*STRB_W +: STRB_W] = 4'hf;
    m_wlast[0] = 1'b1;
    m_wvalid[0] = 1'b1;
    #1;
    tb_check1("w-first write accepts w", m_wready[0], 1'b1);
    `TB_TICK(clk);
    m_wvalid[0] = 1'b0;
    m_awaddr[0*ADDR_W +: ADDR_W] = 32'h1000_0090;
    m_awid[0*4 +: 4] = 4'ha;
    m_awlen[0*8 +: 8] = 8'd0;
    m_awsize[0*3 +: 3] = 3'd2;
    m_awburst[0*2 +: 2] = 2'b01;
    m_awvalid[0] = 1'b1;
    #1;
    tb_check1("w-first write accepts aw", m_awready[0], 1'b1);
    `TB_TICK(clk);
    m_awvalid[0] = 1'b0;
    m_awsize[0*3 +: 3] = 3'd6;
    #1;
    tb_check32("split write keeps owner awaddr",
               s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0080);
    tb_check32("split write keeps owner awsize",
               {29'h0, s_awsize[1*3 +: 3]}, 32'd0);

    s_awready[1] = 1'b1;
    s_wready[1] = 1'b1;
    `TB_TICK(clk);
    s_awready[1] = 1'b0;
    s_wready[1] = 1'b0;
    #1;
    tb_check1("queued owner blocked before first b awvalid",
              s_awvalid[1], 1'b0);
    tb_check1("queued owner blocked before first b wvalid",
              s_wvalid[1], 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check1("queued owner remains blocked without first b",
              s_awvalid[1], 1'b0);

    s_bresp[1*2 +: 2] = 2'b01;
    s_bvalid[1] = 1'b1;
    m_bready[1] = 1'b0;
    #1;
    tb_check1("split write bvalid", m_bvalid[1], 1'b1);
    tb_check32("split write bresp", {30'b0, m_bresp[1*2 +: 2]}, 32'h1);
    tb_check32("split write bid", {28'b0, m_bid[1*4 +: 4]}, 32'hb);
    tb_check1("split write slave B is backpressured", s_bready[1], 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check1("split write BVALID holds under backpressure", m_bvalid[1], 1'b1);
    tb_check1("split write owner remains active under B backpressure",
              dut.wr_active_q[1], 1'b1);
    tb_check1("queued owner remains blocked under B backpressure",
              s_awvalid[1] || s_wvalid[1], 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check1("split write BVALID holds for second backpressure cycle",
              m_bvalid[1], 1'b1);
    tb_check1("split write owner still active before exact B fire",
              dut.wr_active_q[1], 1'b1);
    m_bready[1] = 1'b1;
    #1;
    tb_check1("split write slave bready on release", s_bready[1], 1'b1);
    `TB_TICK(clk);
    s_bvalid[1] = 1'b0;
    m_bready[1] = 1'b0;

    // 首个 B 完成后，排队的 master0 才能成为 slave1 owner。
    `TB_TICK(clk);
    #1;
    tb_check1("w-first write slave awvalid", s_awvalid[1], 1'b1);
    tb_check1("w-first write slave wvalid", s_wvalid[1], 1'b1);
    tb_check32("w-first write slave awaddr",
               s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0090);
    tb_check32("w-first write slave awsize",
               {29'h0, s_awsize[1*3 +: 3]}, 32'd2);
    tb_check32("w-first write slave wdata",
               s_wdata[1*DATA_W +: DATA_W], 32'h1234_5678);
    tb_check32("w-first write slave wstrb",
               {28'h0, s_wstrb[1*STRB_W +: STRB_W]}, 32'hf);
    m_awsize[0*3 +: 3] = 3'd1;
    `TB_TICK(clk);
    #1;
    tb_check1("w-first stalled awvalid stable", s_awvalid[1], 1'b1);
    tb_check32("w-first stalled awaddr stable",
               s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0090);
    tb_check32("w-first stalled awsize stable",
               {29'h0, s_awsize[1*3 +: 3]}, 32'd2);

    s_awready[1] = 1'b1;
    s_wready[1] = 1'b1;
    `TB_TICK(clk);
    s_awready[1] = 1'b0;
    s_wready[1] = 1'b0;
    s_bresp[1*2 +: 2] = 2'b00;
    s_bvalid[1] = 1'b1;
    m_bready[0] = 1'b1;
    #1;
    tb_check1("w-first write bvalid", m_bvalid[0], 1'b1);
    tb_check32("w-first write bresp",
               {30'b0, m_bresp[0*2 +: 2]}, 32'h0);
    tb_check32("w-first write bid",
               {28'b0, m_bid[0*4 +: 4]}, 32'ha);
    tb_check1("w-first write slave bready", s_bready[1], 1'b1);
    `TB_TICK(clk);
    s_bvalid[1] = 1'b0;
    m_bready[0] = 1'b0;

    $display("[IFU-AXI-G1-XBAR-BACKPRESSURE] bvalid_hold_cycles=2 early_release=0 aw_first=1 w_first=1 payload_stability=1 PASS");
    tb_finish("tb_axi_xbar");
  end
endmodule
