`include "define.v"
`include "tb_common.svh"

// IFU-ACCESS-G1 device firewall RED。slave0=memory、slave1=UART、slave2=default error；
// instruction read 只允许 executable memory，命中 UART 必须改路由到 default，且 UART
// 看不到 AR fire。LSU data read 仍按原地址表访问 UART，作为非退化控制。
module tb_axi_exec_firewall;
  localparam ADDR_W = `XLEN;
  localparam DATA_W = `XLEN;
  localparam STRB_W = `STRB_W;
  localparam M_COUNT = 2;
  localparam S_COUNT = 3;
  localparam DEFAULT_SLAVE = 2;
  localparam M_IFU = 0;
  localparam M_LSU = 1;
  localparam S_MEM = 0;
  localparam S_UART = 1;
  localparam S_DEFAULT = 2;
  localparam [`XLEN-1:0] MEM_BASE = 64'h0000_0000_8000_0000;
  localparam [`XLEN-1:0] UART_BASE = 64'h0000_0000_1000_0000;
  localparam [S_COUNT*ADDR_W-1:0] SLAVE_BASE = {
      {ADDR_W{1'b0}}, UART_BASE, MEM_BASE
  };
  localparam [S_COUNT*ADDR_W-1:0] SLAVE_MASK = {
      {ADDR_W{1'b0}}, 64'hffff_ffff_ffff_f000,
      64'hffff_ffff_e000_0000
  };

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

  wire [S_COUNT-1:0] s_arvalid;
  wire [S_COUNT*ADDR_W-1:0] s_araddr;
  wire [S_COUNT*3-1:0] s_arsize;
  wire [S_COUNT*3-1:0] s_arprot;
  wire [S_COUNT-1:0] s_rready;
  wire [S_COUNT-1:0] s_awvalid;
  wire [S_COUNT*ADDR_W-1:0] s_awaddr;
  wire [S_COUNT*3-1:0] s_awsize;
  wire [S_COUNT-1:0] s_wvalid;
  wire [S_COUNT*DATA_W-1:0] s_wdata;
  wire [S_COUNT*STRB_W-1:0] s_wstrb;
  wire [S_COUNT-1:0] s_bready;

  reg mem_arready;
  reg mem_rvalid;
  reg [DATA_W-1:0] mem_rdata;
  reg [1:0] mem_rresp;
  wire uart_arready;
  wire uart_rvalid;
  wire [DATA_W-1:0] uart_rdata;
  wire [1:0] uart_rresp;
  wire default_arready;
  wire default_rvalid;
  wire [DATA_W-1:0] default_rdata;
  wire [1:0] default_rresp;

  wire [S_COUNT-1:0] s_arready =
      {default_arready, uart_arready, mem_arready};
  wire [S_COUNT-1:0] s_rvalid =
      {default_rvalid, uart_rvalid, mem_rvalid};
  wire [S_COUNT*DATA_W-1:0] s_rdata =
      {default_rdata, uart_rdata, mem_rdata};
  wire [S_COUNT*2-1:0] s_rresp =
      {default_rresp, uart_rresp, mem_rresp};

  wire uart_awready;
  wire uart_wready;
  wire uart_bvalid;
  wire [1:0] uart_bresp;
  wire default_awready;
  wire default_wready;
  wire default_bvalid;
  wire [1:0] default_bresp;
  wire [S_COUNT-1:0] s_awready =
      {default_awready, uart_awready, 1'b0};
  wire [S_COUNT-1:0] s_wready =
      {default_wready, uart_wready, 1'b0};
  wire [S_COUNT-1:0] s_bvalid =
      {default_bvalid, uart_bvalid, 1'b0};
  wire [S_COUNT*2-1:0] s_bresp =
      {default_bresp, uart_bresp, 2'b10};

  reg uart_rx_valid;
  reg [7:0] uart_rx_data;
  wire uart_rx_ready;
  wire uart_access_valid;
  wire uart_access_write;

  AxiCrossbar #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .STRB_W(STRB_W),
    .M_COUNT(M_COUNT),
    .S_COUNT(S_COUNT),
    .DEFAULT_SLAVE(DEFAULT_SLAVE),
    .SLAVE_BASE(SLAVE_BASE),
    .SLAVE_MASK(SLAVE_MASK),
    .SLAVE_EXEC_MASK(3'b001)
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
    .m_rid_o(),
    .m_rlast_o(),
    .m_awvalid_i({M_COUNT{1'b0}}),
    .m_awready_o(),
    .m_awaddr_i({M_COUNT*ADDR_W{1'b0}}),
    .m_awid_i({M_COUNT*4{1'b0}}),
    .m_awlen_i({M_COUNT*8{1'b0}}),
    .m_awsize_i({M_COUNT*3{1'b0}}),
    .m_awburst_i({M_COUNT*2{1'b0}}),
    .m_wvalid_i({M_COUNT{1'b0}}),
    .m_wready_o(),
    .m_wdata_i({M_COUNT*DATA_W{1'b0}}),
    .m_wstrb_i({M_COUNT*STRB_W{1'b0}}),
    .m_wlast_i({M_COUNT{1'b0}}),
    .m_bvalid_o(),
    .m_bready_i({M_COUNT{1'b0}}),
    .m_bresp_o(),
    .m_bid_o(),
    .s_arvalid_o(s_arvalid),
    .s_arready_i(s_arready),
    .s_araddr_o(s_araddr),
    .s_arsize_o(s_arsize),
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

  AxiToUart #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .STRB_W(STRB_W)
  ) u_uart (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(s_arvalid[S_UART]),
    .s_axi_arready_o(uart_arready),
    .s_axi_araddr_i(s_araddr[S_UART*ADDR_W +: ADDR_W]),
    .s_axi_arsize_i(s_arsize[S_UART*3 +: 3]),
    .s_axi_rvalid_o(uart_rvalid),
    .s_axi_rready_i(s_rready[S_UART]),
    .s_axi_rdata_o(uart_rdata),
    .s_axi_rresp_o(uart_rresp),
    .s_axi_awvalid_i(s_awvalid[S_UART]),
    .s_axi_awready_o(uart_awready),
    .s_axi_awaddr_i(s_awaddr[S_UART*ADDR_W +: ADDR_W]),
    .s_axi_awsize_i(s_awsize[S_UART*3 +: 3]),
    .s_axi_wvalid_i(s_wvalid[S_UART]),
    .s_axi_wready_o(uart_wready),
    .s_axi_wdata_i(s_wdata[S_UART*DATA_W +: DATA_W]),
    .s_axi_wstrb_i(s_wstrb[S_UART*STRB_W +: STRB_W]),
    .s_axi_bvalid_o(uart_bvalid),
    .s_axi_bready_i(s_bready[S_UART]),
    .s_axi_bresp_o(uart_bresp),
    .uart_tx_valid_o(),
    .uart_tx_data_o(),
    .uart_access_valid_o(uart_access_valid),
    .uart_access_write_o(uart_access_write),
    .uart_access_addr_o(),
    .uart_access_wdata_o(),
    .uart_access_wstrb_o(),
    .uart_access_rdata_o(),
    .uart_rx_valid_i(uart_rx_valid),
    .uart_rx_data_i(uart_rx_data),
    .uart_rx_ready_o(uart_rx_ready),
    .uart_irq_o()
  );

  AxiDefaultSlave #(.DATA_W(DATA_W)) u_default (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(s_arvalid[S_DEFAULT]),
    .s_axi_arready_o(default_arready),
    .s_axi_rvalid_o(default_rvalid),
    .s_axi_rready_i(s_rready[S_DEFAULT]),
    .s_axi_rdata_o(default_rdata),
    .s_axi_rresp_o(default_rresp),
    .s_axi_awvalid_i(s_awvalid[S_DEFAULT]),
    .s_axi_awready_o(default_awready),
    .s_axi_wvalid_i(s_wvalid[S_DEFAULT]),
    .s_axi_wready_o(default_wready),
    .s_axi_bvalid_o(default_bvalid),
    .s_axi_bready_i(s_bready[S_DEFAULT]),
    .s_axi_bresp_o(default_bresp)
  );

  task automatic tick;
    begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
    end
  endtask

  task automatic reset_dut;
    begin
      rst = 1'b1;
      m_arvalid = {M_COUNT{1'b0}};
      m_araddr = {M_COUNT*ADDR_W{1'b0}};
      m_arid = {M_COUNT*4{1'b0}};
      m_arlen = {M_COUNT*8{1'b0}};
      m_arsize = {M_COUNT*3{1'b0}};
      m_arburst = {M_COUNT*2{1'b0}};
      m_arprot = {M_COUNT*3{1'b0}};
      m_rready = {M_COUNT{1'b0}};
      mem_arready = 1'b0;
      mem_rvalid = 1'b0;
      mem_rdata = {DATA_W{1'b0}};
      mem_rresp = 2'b00;
      uart_rx_valid = 1'b0;
      uart_rx_data = 8'h00;
      tick();
      tick();
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic start_read;
    input [1023:0] what;
    input integer mid;
    input [`XLEN-1:0] addr;
    input [2:0] size;
    input [2:0] prot;
    integer waits;
    begin
      m_araddr[mid*ADDR_W +: ADDR_W] = addr;
      m_arid[mid*4 +: 4] = mid[3:0];
      m_arlen[mid*8 +: 8] = 8'd0;
      m_arsize[mid*3 +: 3] = size;
      m_arburst[mid*2 +: 2] = 2'b01;
      m_arprot[mid*3 +: 3] = prot;
      m_arvalid[mid] = 1'b1;
      m_rready[mid] = 1'b1;
      // 先让组合 ready 收敛，避免同一 active region 内读取旧值后错过 fire。
      #1;
      waits = 0;
      while ((m_arready[mid] !== 1'b1) && (waits < 8)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1({what, " master read granted"}, m_arready[mid], 1'b1);
      tick();
      m_arvalid[mid] = 1'b0;
    end
  endtask

  task automatic wait_response;
    input [1023:0] what;
    input integer mid;
    input [1:0] exp_resp;
    integer waits;
    begin
      // slave 可能刚在调用前拉高 RVALID，先等待 crossbar 组合回传收敛。
      #1;
      waits = 0;
      while ((m_rvalid[mid] !== 1'b1) && (waits < 8)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1({what, " master response valid"}, m_rvalid[mid], 1'b1);
      tb_check32({what, " master response code"},
                 {30'b0, m_rresp[mid*2 +: 2]},
                 {30'b0, exp_resp});
      tick();
      m_rready[mid] = 1'b0;
    end
  endtask

  task automatic check_mem_ar_hold;
    input [1023:0] what;
    input [`XLEN-1:0] exp_addr;
    input [2:0] exp_size;
    input [2:0] exp_prot;
    begin
      tb_check1({what, " ARVALID"}, s_arvalid[S_MEM], 1'b1);
      tb_check32({what, " ARADDR low"},
                 s_araddr[S_MEM*ADDR_W +: 32], exp_addr[31:0]);
      tb_check32({what, " ARADDR high"},
                 s_araddr[S_MEM*ADDR_W + 32 +: 32], exp_addr[63:32]);
      tb_check32({what, " ARSIZE"},
                 {29'b0, s_arsize[S_MEM*3 +: 3]}, {29'b0, exp_size});
      tb_check32({what, " ARPROT"},
                 {29'b0, s_arprot[S_MEM*3 +: 3]}, {29'b0, exp_prot});
      tb_check1({what, " no UART route"}, s_arvalid[S_UART], 1'b0);
      tb_check1({what, " no default route"}, s_arvalid[S_DEFAULT], 1'b0);
    end
  endtask

  initial begin
    clk = 1'b0;
    tb_errors = 0;
    reset_dut();

    // 已被 crossbar 接收的请求必须完全由内部寄存器驱动；slave 背压期间，
    // master 端撤销 VALID 后可以改写 payload，不能污染尚未完成的 AR。
    start_read("stalled executable AR", M_IFU,
               MEM_BASE + 64'h12, 3'd1, 3'b100);
    #1;
    check_mem_ar_hold("stalled executable AR cycle0",
                      MEM_BASE + 64'h12, 3'd1, 3'b100);

    m_araddr[M_IFU*ADDR_W +: ADDR_W] = UART_BASE + 64'h7;
    m_arsize[M_IFU*3 +: 3] = 3'd3;
    m_arprot[M_IFU*3 +: 3] = 3'b000;
    tick();
    check_mem_ar_hold("stalled executable AR cycle1",
                      MEM_BASE + 64'h12, 3'd1, 3'b100);

    m_araddr[M_IFU*ADDR_W +: ADDR_W] = 64'hffff_ffff_ffff_fff0;
    m_arsize[M_IFU*3 +: 3] = 3'd0;
    m_arprot[M_IFU*3 +: 3] = 3'b111;
    tick();
    check_mem_ar_hold("stalled executable AR cycle2",
                      MEM_BASE + 64'h12, 3'd1, 3'b100);

    tick();
    check_mem_ar_hold("stalled executable AR cycle3",
                      MEM_BASE + 64'h12, 3'd1, 3'b100);

    mem_arready = 1'b1;
    tick();
    mem_arready = 1'b0;
    #1;
    tb_check1("accepted memory AR deasserts", s_arvalid[S_MEM], 1'b0);
    mem_rdata = 64'h0123_4567_89ab_cdef;
    mem_rresp = 2'b00;
    mem_rvalid = 1'b1;
    wait_response("stalled executable AR", M_IFU, 2'b00);
    mem_rvalid = 1'b0;

    // 给 UART RBR 放一个字节；错误的 IFU read 会把它 pop 掉。
    uart_rx_data = 8'h5a;
    uart_rx_valid = 1'b1;
    tb_check1("UART accepts seed byte", uart_rx_ready, 1'b1);
    tick();
    uart_rx_valid = 1'b0;
    #1;
    tb_check1("seed byte makes UART busy", uart_rx_ready, 1'b0);

    start_read("IFU UART firewall", M_IFU, UART_BASE, 3'd1, 3'b100);
    #1;
    tb_check1("IFU UART is redirected to default", s_arvalid[S_DEFAULT], 1'b1);
    tb_check1("IFU UART never reaches UART", s_arvalid[S_UART], 1'b0);
    tb_check1("IFU UART has no UART side effect", uart_access_valid, 1'b0);
    tb_check32("IFU redirected ARSIZE preserved",
               {29'b0, s_arsize[S_DEFAULT*3 +: 3]}, 32'd1);
    tb_check32("IFU redirected ARPROT preserved",
               {29'b0, s_arprot[S_DEFAULT*3 +: 3]}, 32'd4);
    tick();
    wait_response("IFU UART firewall", M_IFU, 2'b10);
    tb_check1("IFU UART did not pop RBR", uart_rx_ready, 1'b0);

    // LSU data control：同一设备地址仍应命中 UART 并返回 OK。
    start_read("LSU UART data control", M_LSU,
               UART_BASE + 64'd5, 3'd0, 3'b000);
    #1;
    tb_check1("LSU UART still reaches UART", s_arvalid[S_UART], 1'b1);
    tb_check1("LSU UART still reports access", uart_access_valid, 1'b1);
    tb_check32("LSU UART keeps data ARPROT",
               {29'b0, s_arprot[S_UART*3 +: 3]}, 32'd0);
    tb_check32("LSU UART keeps byte ARSIZE",
               {29'b0, s_arsize[S_UART*3 +: 3]}, 32'd0);
    tick();
    wait_response("LSU UART data control", M_LSU, 2'b00);

    if (tb_errors == 0) begin
      $display("[ACCESS-G1-FIREWALL] stall_cycles=4 ifu_redirect=1 uart_side_effect=0 default_error=2 lsu_data_control=1 PASS");
    end

    tb_finish("tb_axi_exec_firewall");
  end
endmodule
