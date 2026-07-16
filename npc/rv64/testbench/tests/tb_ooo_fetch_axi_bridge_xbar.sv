`include "define.v"
`include "tb_common.svh"

// IFU-AXI-G1 集成合同：bridge flush-drain 必须真正释放 AxiXbar 的 B owner，
// 不能只在 bridge 内部看见 IDLE。M0=真实 IFU bridge，M1=后一笔合成 LSU write。
module tb_ooo_fetch_axi_bridge_xbar;
  localparam integer M_COUNT = 2;
  localparam integer S_COUNT = 1;
  localparam [`XLEN-1:0] PTE_ADDR = 64'h0000_0000_8100_2020;
  localparam [`XLEN-1:0] PTE_DATA = 64'h0000_0000_1234_004f;
  localparam [`XLEN-1:0] LSU_ADDR = 64'h0000_0000_8200_0080;
  localparam [`XLEN-1:0] LSU_DATA = 64'hfeed_face_cafe_beef;
  localparam [3:0] S_IDLE_TB = 4'd0;
  localparam [3:0] S_AD_UPDATE_TB = 4'd8;

  reg clk;
  reg rst;
  reg mmu_flush;
  reg fetch_req_valid;
  reg [`XLEN-1:0] fetch_req_pc;

  wire ifu_arvalid;
  wire ifu_arready;
  wire [`XLEN-1:0] ifu_araddr;
  wire [3:0] ifu_arid;
  wire [7:0] ifu_arlen;
  wire [2:0] ifu_arsize;
  wire [1:0] ifu_arburst;
  wire [2:0] ifu_arprot;
  wire ifu_rvalid;
  wire ifu_rready;
  wire [`XLEN-1:0] ifu_rdata;
  wire [1:0] ifu_rresp;

  wire ifu_awvalid;
  wire ifu_awready;
  wire [`XLEN-1:0] ifu_awaddr;
  wire [3:0] ifu_awid;
  wire [7:0] ifu_awlen;
  wire [2:0] ifu_awsize;
  wire [1:0] ifu_awburst;
  wire ifu_wvalid;
  wire ifu_wready;
  wire [`XLEN-1:0] ifu_wdata;
  wire [`STRB_W-1:0] ifu_wstrb;
  wire ifu_wlast;
  wire ifu_bvalid;
  wire ifu_bready;
  wire [1:0] ifu_bresp;

  reg lsu_awvalid;
  reg [`XLEN-1:0] lsu_awaddr;
  reg lsu_wvalid;
  reg [`XLEN-1:0] lsu_wdata;
  reg [`STRB_W-1:0] lsu_wstrb;
  wire lsu_awready;
  wire lsu_wready;
  wire lsu_bvalid;
  reg lsu_bready;
  wire [1:0] lsu_bresp;

  wire [M_COUNT-1:0] m_arready;
  wire [M_COUNT-1:0] m_rvalid;
  wire [M_COUNT*`XLEN-1:0] m_rdata;
  wire [M_COUNT*2-1:0] m_rresp;
  wire [M_COUNT*4-1:0] m_rid;
  wire [M_COUNT-1:0] m_rlast;
  wire [M_COUNT-1:0] m_awready;
  wire [M_COUNT-1:0] m_wready;
  wire [M_COUNT-1:0] m_bvalid;
  wire [M_COUNT*2-1:0] m_bresp;
  wire [M_COUNT*4-1:0] m_bid;

  wire [S_COUNT-1:0] s_arvalid;
  reg [S_COUNT-1:0] s_arready;
  wire [S_COUNT*`XLEN-1:0] s_araddr;
  wire [S_COUNT*3-1:0] s_arprot;
  reg [S_COUNT-1:0] s_rvalid;
  wire [S_COUNT-1:0] s_rready;
  reg [S_COUNT*`XLEN-1:0] s_rdata;
  reg [S_COUNT*2-1:0] s_rresp;
  wire [S_COUNT-1:0] s_awvalid;
  reg [S_COUNT-1:0] s_awready;
  wire [S_COUNT*`XLEN-1:0] s_awaddr;
  wire [S_COUNT-1:0] s_wvalid;
  reg [S_COUNT-1:0] s_wready;
  wire [S_COUNT*`XLEN-1:0] s_wdata;
  wire [S_COUNT*`STRB_W-1:0] s_wstrb;
  reg [S_COUNT-1:0] s_bvalid;
  wire [S_COUNT-1:0] s_bready;
  reg [S_COUNT*2-1:0] s_bresp;

  wire fetch_req_ready_unused;
  wire [`XLEN-1:0] fetch_req_owner_pc;
  wire fetch_rsp_valid_unused;
  wire [`INST_W-1:0] fetch_rsp_inst0_unused;
  wire [1:0] fetch_rsp_resp0_unused;
  wire [`INST_W-1:0] fetch_rsp_inst1_unused;
  wire [1:0] fetch_rsp_resp1_unused;

  assign ifu_arready = m_arready[0];
  assign ifu_rvalid = m_rvalid[0];
  assign ifu_rdata = m_rdata[0 +: `XLEN];
  assign ifu_rresp = m_rresp[0 +: 2];
  assign ifu_awready = m_awready[0];
  assign ifu_wready = m_wready[0];
  assign ifu_bvalid = m_bvalid[0];
  assign ifu_bresp = m_bresp[0 +: 2];
  assign lsu_awready = m_awready[1];
  assign lsu_wready = m_wready[1];
  assign lsu_bvalid = m_bvalid[1];
  assign lsu_bresp = m_bresp[2 +: 2];

  OooFetchAxiBridge u_bridge (
    .clk(clk),
    .rst(rst),
    .mmu_flush_i(mmu_flush),
    .invalidate_valid_i(1'b0),
    .invalidate_addr_i({`XLEN{1'b0}}),
    .priv_mode_i(`PRIV_S),
    .satp_i({`XLEN{1'b0}}),
    .svpbmt_en_i(1'b0),
    .pmpcfg_i({`PMP_CFG_BUS_W{1'b0}}),
    .pmpaddr_i({`PMP_ADDR_BUS_W{1'b0}}),
    .fetch_req_valid_i(fetch_req_valid),
    .fetch_req_ready_o(fetch_req_ready_unused),
    .fetch_req_pc_i(fetch_req_pc),
    .fetch_req_owner_pc_o(fetch_req_owner_pc),
    .fetch_rsp_valid_o(fetch_rsp_valid_unused),
    .fetch_rsp_ready_i(1'b0),
    .fetch_rsp_inst0_o(fetch_rsp_inst0_unused),
    .fetch_rsp_resp0_o(fetch_rsp_resp0_unused),
    .fetch_rsp_inst1_o(fetch_rsp_inst1_unused),
    .fetch_rsp_resp1_o(fetch_rsp_resp1_unused),
    .ifu_axi_arvalid_o(ifu_arvalid),
    .ifu_axi_arready_i(ifu_arready),
    .ifu_axi_araddr_o(ifu_araddr),
    .ifu_axi_arid_o(ifu_arid),
    .ifu_axi_arlen_o(ifu_arlen),
    .ifu_axi_arsize_o(ifu_arsize),
    .ifu_axi_arburst_o(ifu_arburst),
    .ifu_axi_arprot_o(ifu_arprot),
    .ifu_axi_rvalid_i(ifu_rvalid),
    .ifu_axi_rready_o(ifu_rready),
    .ifu_axi_rdata_i(ifu_rdata),
    .ifu_axi_rresp_i(ifu_rresp),
    .ifu_axi_awvalid_o(ifu_awvalid),
    .ifu_axi_awready_i(ifu_awready),
    .ifu_axi_awaddr_o(ifu_awaddr),
    .ifu_axi_awid_o(ifu_awid),
    .ifu_axi_awlen_o(ifu_awlen),
    .ifu_axi_awsize_o(ifu_awsize),
    .ifu_axi_awburst_o(ifu_awburst),
    .ifu_axi_wvalid_o(ifu_wvalid),
    .ifu_axi_wready_i(ifu_wready),
    .ifu_axi_wdata_o(ifu_wdata),
    .ifu_axi_wstrb_o(ifu_wstrb),
    .ifu_axi_wlast_o(ifu_wlast),
    .ifu_axi_bvalid_i(ifu_bvalid),
    .ifu_axi_bready_o(ifu_bready),
    .ifu_axi_bresp_i(ifu_bresp)
  );

  AxiXbar #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W),
    .M_COUNT(M_COUNT),
    .S_COUNT(S_COUNT),
    .DEFAULT_SLAVE(0),
    .SLAVE_BASE({`XLEN{1'b0}}),
    .SLAVE_MASK({`XLEN{1'b0}})
  ) u_xbar (
    .clk(clk),
    .rst(rst),
    .m_arvalid_i({1'b0, ifu_arvalid}),
    .m_arready_o(m_arready),
    .m_araddr_i({{`XLEN{1'b0}}, ifu_araddr}),
    .m_arid_i({4'd0, ifu_arid}),
    .m_arlen_i({8'd0, ifu_arlen}),
    .m_arsize_i({3'd3, ifu_arsize}),
    .m_arburst_i({2'b01, ifu_arburst}),
    .m_arprot_i({3'b000, ifu_arprot}),
    .m_rvalid_o(m_rvalid),
    .m_rready_i({1'b0, ifu_rready}),
    .m_rdata_o(m_rdata),
    .m_rresp_o(m_rresp),
    .m_rid_o(m_rid),
    .m_rlast_o(m_rlast),
    .m_awvalid_i({lsu_awvalid, ifu_awvalid}),
    .m_awready_o(m_awready),
    .m_awaddr_i({lsu_awaddr, ifu_awaddr}),
    .m_awid_i({4'd2, ifu_awid}),
    .m_awlen_i({8'd0, ifu_awlen}),
    .m_awsize_i({3'd3, ifu_awsize}),
    .m_awburst_i({2'b01, ifu_awburst}),
    .m_wvalid_i({lsu_wvalid, ifu_wvalid}),
    .m_wready_o(m_wready),
    .m_wdata_i({lsu_wdata, ifu_wdata}),
    .m_wstrb_i({lsu_wstrb, ifu_wstrb}),
    .m_wlast_i({1'b1, ifu_wlast}),
    .m_bvalid_o(m_bvalid),
    .m_bready_i({lsu_bready, ifu_bready}),
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
    .s_wvalid_o(s_wvalid),
    .s_wready_i(s_wready),
    .s_wdata_o(s_wdata),
    .s_wstrb_o(s_wstrb),
    .s_bvalid_i(s_bvalid),
    .s_bready_o(s_bready),
    .s_bresp_i(s_bresp)
  );

  always #5 clk = ~clk;

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic tb_check64_local;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  integer waits;
  reg lsu_reached_slave;

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    mmu_flush = 1'b0;
    fetch_req_valid = 1'b0;
    fetch_req_pc = {`XLEN{1'b0}};
    lsu_awvalid = 1'b0;
    lsu_awaddr = LSU_ADDR;
    lsu_wvalid = 1'b0;
    lsu_wdata = LSU_DATA;
    lsu_wstrb = {`STRB_W{1'b1}};
    lsu_bready = 1'b1;
    s_arready = {S_COUNT{1'b0}};
    s_rvalid = {S_COUNT{1'b0}};
    s_rdata = {S_COUNT*`XLEN{1'b0}};
    s_rresp = {S_COUNT*2{1'b0}};
    s_awready = {S_COUNT{1'b1}};
    s_wready = {S_COUNT{1'b1}};
    s_bvalid = {S_COUNT{1'b0}};
    s_bresp = {S_COUNT*2{1'b0}};
    repeat (3) tick();
    rst = 1'b0;
    tick();

    // 自然 walk→A=0 已由 bridge TB 覆盖；先经真实 request fire 建立 T4A
    // immutable-context owner，再投影到 write owner 专测互连生命周期。
    // T4A 的 AWADDR 来自 S_WALK_CHECK 原子捕获的 registered PTE 地址，
    // 因而直接种入该边界产物，不能再依赖 live walk_ppn 组合重建。
    @(negedge clk);
    fetch_req_pc = 64'h0000_0000_0000_4000;
    fetch_req_valid = 1'b1;
    #1;
    tb_check1("IFU context seed request ready", fetch_req_ready_unused, 1'b1);
    tick();
    fetch_req_valid = 1'b0;
    tick();
    tick();
    @(negedge clk);
    u_bridge.state_q = S_AD_UPDATE_TB;
    u_bridge.walk_second_q = 1'b0;
    u_bridge.walk_level_q = 2'd0;
    u_bridge.walk_ppn_q = 44'h0000_081002;
    u_bridge.walk_pte_addr_q = PTE_ADDR;
    u_bridge.ad_pte_q = PTE_DATA;
    u_bridge.aw_done_q = 1'b0;
    u_bridge.w_done_q = 1'b0;
    #1;
    tb_check1("IFU bridge presents AW", ifu_awvalid, 1'b1);
    tb_check1("IFU bridge presents W", ifu_wvalid, 1'b1);
    tb_check64_local("IFU bridge active owner PC", fetch_req_owner_pc,
                     64'h0000_0000_0000_4000);
    tb_check64_local("IFU PTE address", ifu_awaddr, PTE_ADDR);

    // master-side capture -> slave grant -> slave AW/W fire，之后故意延迟 B。
    tick();
    tb_check1("xbar captured IFU AW", u_xbar.wr_aw_hold_q[0], 1'b1);
    tb_check1("xbar captured IFU W", u_xbar.wr_w_hold_q[0], 1'b1);
    tick();
    tb_check1("xbar grants IFU owner", u_xbar.wr_active_q[0], 1'b1);
    #1;
    tb_check1("slave sees IFU AW", s_awvalid[0], 1'b1);
    tb_check1("slave sees IFU W", s_wvalid[0], 1'b1);
    tb_check64_local("slave IFU AWADDR", s_awaddr[0 +: `XLEN], PTE_ADDR);
    tb_check64_local("slave IFU WDATA", s_wdata[0 +: `XLEN], PTE_DATA);
    tick();
    tb_check1("slave accepted IFU AW", u_xbar.wr_aw_sent_q[0], 1'b1);
    tb_check1("slave accepted IFU W", u_xbar.wr_w_sent_q[0], 1'b1);

    // B pending 时 flush；同时把 M1 写排队到 xbar master-side hold。
    mmu_flush = 1'b1;
    tick();
    mmu_flush = 1'b0;
    lsu_awvalid = 1'b1;
    lsu_wvalid = 1'b1;
    #1;
    tb_check1("later master AW can enter hold", lsu_awready, 1'b1);
    tb_check1("later master W can enter hold", lsu_wready, 1'b1);
    tick();
    lsu_awvalid = 1'b0;
    lsu_wvalid = 1'b0;

    // 关键 RED：旧 bridge 已撤 BREADY，xbar owner 永不释放；修复后本拍消费 B。
    s_bvalid[0] = 1'b1;
    s_bresp[1:0] = 2'b00;
    #1;
    tb_check1("flushed IFU keeps slave BREADY", s_bready[0], 1'b1);
    tb_check1("IFU receives owned B", ifu_bvalid, 1'b1);
    tick();
    s_bvalid[0] = 1'b0;
    #1;
    tb_check1("IFU bridge drops to IDLE after B", u_bridge.state_q == S_IDLE_TB, 1'b1);
    tb_check1("xbar releases IFU write owner", u_xbar.wr_active_q[0], 1'b0);

    // 外部进展判据：不能只看 internal owner bit；后一 master 必须真的到 slave。
    waits = 0;
    lsu_reached_slave = 1'b0;
    while (!lsu_reached_slave && (waits < 8)) begin
      if (s_awvalid[0] && s_wvalid[0] &&
          (s_awaddr[0 +: `XLEN] == LSU_ADDR) &&
          (s_wdata[0 +: `XLEN] == LSU_DATA)) begin
        lsu_reached_slave = 1'b1;
      end else begin
        tick();
        waits = waits + 1;
      end
    end
    tb_check1("later master reaches slave after IFU B", lsu_reached_slave, 1'b1);
    if (lsu_reached_slave) begin
      tb_check64_local("later master AWADDR intact", s_awaddr[0 +: `XLEN], LSU_ADDR);
      tb_check64_local("later master WDATA intact", s_wdata[0 +: `XLEN], LSU_DATA);
      tick();
      s_bvalid[0] = 1'b1;
      #1;
      tb_check1("later master receives B", lsu_bvalid, 1'b1);
      tb_check1("later master B response OK", lsu_bresp == 2'b00, 1'b1);
      tick();
      s_bvalid[0] = 1'b0;
      #1;
      tb_check1("xbar releases later owner", u_xbar.wr_active_q[0], 1'b0);
    end

    tb_finish("tb_ooo_fetch_axi_bridge_xbar");
  end
endmodule
