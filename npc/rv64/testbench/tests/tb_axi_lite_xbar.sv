module tb_axi_lite_xbar;
  `include "tb_common.svh"

  localparam ADDR_W = 32;
  localparam DATA_W = 32;
  localparam STRB_W = DATA_W / 8;
  localparam ARUSER_W = 1;
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

  reg clk;
  reg rst;

  reg [M_COUNT-1:0] m_arvalid;
  wire [M_COUNT-1:0] m_arready;
  reg [M_COUNT*ADDR_W-1:0] m_araddr;
  reg [M_COUNT*ARUSER_W-1:0] m_aruser;
  reg [M_COUNT-1:0] m_read_abort;
  wire [M_COUNT-1:0] m_rvalid;
  reg [M_COUNT-1:0] m_rready;
  wire [M_COUNT*DATA_W-1:0] m_rdata;
  wire [M_COUNT*2-1:0] m_rresp;

  reg [M_COUNT-1:0] m_awvalid;
  wire [M_COUNT-1:0] m_awready;
  reg [M_COUNT*ADDR_W-1:0] m_awaddr;
  reg [M_COUNT-1:0] m_wvalid;
  wire [M_COUNT-1:0] m_wready;
  reg [M_COUNT*DATA_W-1:0] m_wdata;
  reg [M_COUNT*STRB_W-1:0] m_wstrb;
  wire [M_COUNT-1:0] m_bvalid;
  reg [M_COUNT-1:0] m_bready;
  wire [M_COUNT*2-1:0] m_bresp;

  wire [S_COUNT-1:0] s_arvalid;
  reg [S_COUNT-1:0] s_arready;
  wire [S_COUNT*ADDR_W-1:0] s_araddr;
  wire [S_COUNT*ARUSER_W-1:0] s_aruser;
  reg [S_COUNT-1:0] s_rvalid;
  wire [S_COUNT-1:0] s_rready;
  reg [S_COUNT*DATA_W-1:0] s_rdata;
  reg [S_COUNT*2-1:0] s_rresp;

  wire [S_COUNT-1:0] s_awvalid;
  reg [S_COUNT-1:0] s_awready;
  wire [S_COUNT*ADDR_W-1:0] s_awaddr;
  wire [S_COUNT-1:0] s_wvalid;
  reg [S_COUNT-1:0] s_wready;
  wire [S_COUNT*DATA_W-1:0] s_wdata;
  wire [S_COUNT*STRB_W-1:0] s_wstrb;
  reg [S_COUNT-1:0] s_bvalid;
  wire [S_COUNT-1:0] s_bready;
  reg [S_COUNT*2-1:0] s_bresp;

  AxiLiteXbar #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .STRB_W(STRB_W),
    .ARUSER_W(ARUSER_W),
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
    .m_aruser_i(m_aruser),
    .m_read_abort_i(m_read_abort),
    .m_rvalid_o(m_rvalid),
    .m_rready_i(m_rready),
    .m_rdata_o(m_rdata),
    .m_rresp_o(m_rresp),
    .m_awvalid_i(m_awvalid),
    .m_awready_o(m_awready),
    .m_awaddr_i(m_awaddr),
    .m_wvalid_i(m_wvalid),
    .m_wready_o(m_wready),
    .m_wdata_i(m_wdata),
    .m_wstrb_i(m_wstrb),
    .m_bvalid_o(m_bvalid),
    .m_bready_i(m_bready),
    .m_bresp_o(m_bresp),
    .s_arvalid_o(s_arvalid),
    .s_arready_i(s_arready),
    .s_araddr_o(s_araddr),
    .s_aruser_o(s_aruser),
    .s_rvalid_i(s_rvalid),
    .s_rready_o(s_rready),
    .s_rdata_i(s_rdata),
    .s_rresp_i(s_rresp),
    .s_awvalid_o(s_awvalid),
    .s_awready_i(s_awready),
    .s_awaddr_o(s_awaddr),
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
      m_aruser = {M_COUNT*ARUSER_W{1'b0}};
      m_read_abort = {M_COUNT{1'b0}};
      m_rready = {M_COUNT{1'b0}};
      m_awvalid = {M_COUNT{1'b0}};
      m_awaddr = {M_COUNT*ADDR_W{1'b0}};
      m_wvalid = {M_COUNT{1'b0}};
      m_wdata = {M_COUNT*DATA_W{1'b0}};
      m_wstrb = {M_COUNT*STRB_W{1'b0}};
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

  task automatic drive_read;
    input integer mid;
    input [ADDR_W-1:0] addr;
    input user;
    begin
      m_araddr[mid*ADDR_W +: ADDR_W] = addr;
      m_aruser[mid*ARUSER_W +: ARUSER_W] = user;
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
    input user;
    begin
      tb_check1({what, " arvalid"}, s_arvalid[sid], 1'b1);
      tb_check32({what, " araddr"}, s_araddr[sid*ADDR_W +: ADDR_W], addr);
      tb_check1({what, " aruser"}, s_aruser[sid], user);
    end
  endtask

  task automatic check_master_read_data;
    input [1023:0] what;
    input integer mid;
    input [DATA_W-1:0] data;
    input [1:0] resp;
    begin
      tb_check1({what, " rvalid"}, m_rvalid[mid], 1'b1);
      tb_check32({what, " rdata"}, m_rdata[mid*DATA_W +: DATA_W], data);
      tb_check32({what, " rresp"}, {30'b0, m_rresp[mid*2 +: 2]}, {30'b0, resp});
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    drive_read(0, 32'h3000_0010, 1'b1);
    m_rready[0] = 1'b1;
    s_arready[2] = 1'b1;
    #1;
    tb_check1("default read grants master0", m_arready[0], 1'b1);
    `TB_TICK(clk);
    m_arvalid[0] = 1'b0;
    #1;
    check_slave_read_addr("default read", 2, 32'h3000_0010, 1'b1);
    `TB_TICK(clk);
    s_arready[2] = 1'b0;
    drive_read_response(2, 32'hd00d_0001, 2'b10);
    #1;
    tb_check1("default read slave ready", s_rready[2], 1'b1);
    check_master_read_data("default read", 0, 32'hd00d_0001, 2'b10);
    `TB_TICK(clk);
    s_rvalid[2] = 1'b0;
    m_rready[0] = 1'b0;

    drive_read(0, 32'h0000_0020, 1'b0);
    s_arready[0] = 1'b1;
    #1;
    tb_check1("buffered read grants master0", m_arready[0], 1'b1);
    `TB_TICK(clk);
    m_arvalid[0] = 1'b0;
    #1;
    check_slave_read_addr("buffered read", 0, 32'h0000_0020, 1'b0);
    `TB_TICK(clk);
    s_arready[0] = 1'b0;
    drive_read_response(0, 32'hcafe_1000, 2'b01);
    #1;
    tb_check1("buffered read accepts slave response", s_rready[0], 1'b1);
    check_master_read_data("buffered read direct", 0, 32'hcafe_1000, 2'b01);
    `TB_TICK(clk);
    s_rvalid[0] = 1'b0;
    #1;
    check_master_read_data("buffered read stored", 0, 32'hcafe_1000, 2'b01);
    m_rready[0] = 1'b1;
    `TB_TICK(clk);
    m_rready[0] = 1'b0;
    #1;
    tb_check1("buffered read consumed", m_rvalid[0], 1'b0);

    drive_read(1, 32'h1000_0040, 1'b1);
    s_arready[1] = 1'b1;
    #1;
    tb_check1("abort read grants master1", m_arready[1], 1'b1);
    `TB_TICK(clk);
    m_arvalid[1] = 1'b0;
    #1;
    check_slave_read_addr("abort read", 1, 32'h1000_0040, 1'b1);
    `TB_TICK(clk);
    s_arready[1] = 1'b0;
    m_read_abort[1] = 1'b1;
    `TB_TICK(clk);
    drive_read_response(1, 32'hbad0_0001, 2'b11);
    #1;
    tb_check1("abort read drains slave response", s_rready[1], 1'b1);
    tb_check1("abort read suppresses master response", m_rvalid[1], 1'b0);
    `TB_TICK(clk);
    s_rvalid[1] = 1'b0;
    m_read_abort[1] = 1'b0;
    #1;
    drive_read(1, 32'h1000_0044, 1'b0);
    s_arready[1] = 1'b1;
    #1;
    tb_check1("abort read releases master1", m_arready[1], 1'b1);
    `TB_TICK(clk);
    m_arvalid[1] = 1'b0;
    `TB_TICK(clk);
    s_arready[1] = 1'b0;
    m_rready[1] = 1'b1;
    drive_read_response(1, 32'h1234_5678, 2'b00);
    #1;
    check_master_read_data("post-abort read", 1, 32'h1234_5678, 2'b00);
    `TB_TICK(clk);
    s_rvalid[1] = 1'b0;
    m_rready[1] = 1'b0;

    drive_read(0, 32'h0000_0100, 1'b0);
    drive_read(1, 32'h0000_0200, 1'b1);
    s_arready[0] = 1'b1;
    #1;
    tb_check1("round-robin prefers master1 after master0", m_arready[1], 1'b1);
    tb_check1("round-robin holds master0", m_arready[0], 1'b0);
    `TB_TICK(clk);
    m_arvalid[1] = 1'b0;
    #1;
    check_slave_read_addr("round-robin master1", 0, 32'h0000_0200, 1'b1);
    `TB_TICK(clk);
    drive_read_response(0, 32'h1111_0001, 2'b00);
    m_rready[1] = 1'b1;
    #1;
    check_master_read_data("round-robin master1", 1, 32'h1111_0001, 2'b00);
    `TB_TICK(clk);
    s_rvalid[0] = 1'b0;
    m_rready[1] = 1'b0;
    #1;
    tb_check1("round-robin returns to master0", m_arready[0], 1'b1);
    `TB_TICK(clk);
    m_arvalid[0] = 1'b0;
    `TB_TICK(clk);
    m_rready[0] = 1'b1;
    drive_read_response(0, 32'h2222_0000, 2'b00);
    #1;
    check_master_read_data("round-robin master0", 0, 32'h2222_0000, 2'b00);
    `TB_TICK(clk);
    s_rvalid[0] = 1'b0;
    s_arready[0] = 1'b0;
    m_rready[0] = 1'b0;

    m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_0080;
    m_awvalid[1] = 1'b1;
    #1;
    tb_check1("split write accepts aw", m_awready[1], 1'b1);
    `TB_TICK(clk);
    m_awvalid[1] = 1'b0;
    m_wdata[1*DATA_W +: DATA_W] = 32'hfeed_beef;
    m_wstrb[1*STRB_W +: STRB_W] = 4'ha;
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
    tb_check32("split write slave wdata", s_wdata[1*DATA_W +: DATA_W], 32'hfeed_beef);
    tb_check32("split write slave wstrb", {28'h0, s_wstrb[1*STRB_W +: STRB_W]}, 32'ha);
    s_awready[1] = 1'b1;
    s_wready[1] = 1'b1;
    `TB_TICK(clk);
    s_awready[1] = 1'b0;
    s_wready[1] = 1'b0;
    s_bresp[1*2 +: 2] = 2'b01;
    s_bvalid[1] = 1'b1;
    m_bready[1] = 1'b1;
    #1;
    tb_check1("split write bvalid", m_bvalid[1], 1'b1);
    tb_check32("split write bresp", {30'b0, m_bresp[1*2 +: 2]}, 32'h1);
    tb_check1("split write slave bready", s_bready[1], 1'b1);
    `TB_TICK(clk);

    tb_finish("tb_axi_lite_xbar");
  end
endmodule
