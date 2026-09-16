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

  AxiCrossbar #(
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

  // 对完整 AW/W holder 的 grant 拍做四象限定向检查。用 AW-first 再 W
  // 构造 holder，显式绕开 live complete-pair 候选；ready_pair[1] 对应
  // AWREADY，ready_pair[0] 对应 WREADY。grant 后 live master payload 会在
  // 00 用例中被 poison，以证明 held direct 与 retry 都只读取 holder。
  task automatic run_write_grant_ready_case;
    input [1:0] ready_pair;
    input [ADDR_W-1:0] held_addr;
    input [2:0] held_size;
    input [3:0] held_id;
    input [DATA_W-1:0] held_data;
    input [STRB_W-1:0] held_strb;
    begin
      reset_dut();

      m_awaddr[1*ADDR_W +: ADDR_W] = held_addr;
      m_awid[1*4 +: 4] = held_id;
      m_awlen[1*8 +: 8] = 8'd0;
      m_awsize[1*3 +: 3] = held_size;
      m_awburst[1*2 +: 2] = 2'b01;
      m_awvalid[1] = 1'b1;
      m_wdata[1*DATA_W +: DATA_W] = held_data;
      m_wstrb[1*STRB_W +: STRB_W] = held_strb;
      m_wlast[1] = 1'b1;
      s_awready[1] = ready_pair[1];
      s_wready[1] = ready_pair[0];
      s_bresp[1*2 +: 2] = 2'b10;
      if (ready_pair == 2'b11) begin
        // 即使 target 在 grant 拍过早给出 BVALID，也不得在 registered
        // owner + dual-sent 建立前路由或拉高 BREADY。
        m_bready[1] = 1'b1;
      end
      #1;
      tb_check1("grant matrix accepts held aw", m_awready[1], 1'b1);
      tb_check1("grant matrix aw-only has no live offer",
                dut.wr_live_offer_r[1], 1'b0);
      `TB_TICK(clk);

      m_awvalid[1] = 1'b0;
      m_wvalid[1] = 1'b1;
      #1;
      tb_check1("grant matrix accepts held w", m_wready[1], 1'b1);
      tb_check1("grant matrix w-only has no live offer",
                dut.wr_live_offer_r[1], 1'b0);
      tb_check1("grant matrix half holder keeps target aw quiet",
                s_awvalid[1], 1'b0);
      tb_check1("grant matrix half holder keeps target w quiet",
                s_wvalid[1], 1'b0);
      `TB_TICK(clk);

      if (ready_pair == 2'b11) begin
        // 首次 BVALID 精确放在 holder 已形成、target AW/W direct offer
        // 出现的 grant 拍，避免在 target 尚未看到请求时制造非法响应。
        s_bvalid[1] = 1'b1;
      end

      if (ready_pair == 2'b00) begin
        // holder 已完整；重新拉 VALID 并改成下一笔 poison payload。
        // holder 已满使 READY 必须为 0，target 仍只能看到上一笔已锁存内容。
        m_awvalid[1] = 1'b1;
        m_wvalid[1] = 1'b1;
        m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_0bad;
        m_awid[1*4 +: 4] = 4'hf;
        m_awsize[1*3 +: 3] = 3'd7;
        m_wdata[1*DATA_W +: DATA_W] = 32'hdead_0bad;
        m_wstrb[1*STRB_W +: STRB_W] = {STRB_W{1'b0}};
      end else begin
        m_wvalid[1] = 1'b0;
      end
      #1;

      tb_check1("grant matrix direct offer", dut.wr_grant_offer_r[1], 1'b1);
      tb_check1("grant matrix direct owner", dut.wr_grant_master_r[1], 1'b1);
      tb_check1("grant matrix direct awvalid", s_awvalid[1], 1'b1);
      tb_check1("grant matrix direct wvalid", s_wvalid[1], 1'b1);
      tb_check32("grant matrix direct awaddr",
                 s_awaddr[1*ADDR_W +: ADDR_W], held_addr);
      tb_check32("grant matrix direct awsize",
                 {29'h0, s_awsize[1*3 +: 3]}, {29'h0, held_size});
      tb_check32("grant matrix direct wdata",
                 s_wdata[1*DATA_W +: DATA_W], held_data);
      tb_check32("grant matrix direct wstrb",
                 {28'h0, s_wstrb[1*STRB_W +: STRB_W]},
                 {{(32-STRB_W){1'b0}}, held_strb});
      tb_check1("grant matrix holder blocks live aw", m_awready[1], 1'b0);
      tb_check1("grant matrix holder blocks live w", m_wready[1], 1'b0);
      tb_check1("grant matrix blocks ownerless master b", m_bvalid[1], 1'b0);
      tb_check1("grant matrix blocks ownerless slave b", s_bready[1], 1'b0);

      // grant edge 原子建立 owner/active，并以当拍每通道 fire 精确播种 sent。
      `TB_TICK(clk);
      #1;
      tb_check1("grant matrix registered active", dut.wr_active_q[1], 1'b1);
      tb_check1("grant matrix registered owner", dut.wr_owner_q[1], 1'b1);
      tb_check1("grant matrix aw sent seed",
                dut.wr_aw_sent_q[1], ready_pair[1]);
      tb_check1("grant matrix w sent seed",
                dut.wr_w_sent_q[1], ready_pair[0]);
      tb_check1("grant matrix retries only missing aw",
                s_awvalid[1], !ready_pair[1]);
      tb_check1("grant matrix retries only missing w",
                s_wvalid[1], !ready_pair[0]);
      if (!ready_pair[1]) begin
        tb_check32("grant matrix retry awaddr",
                   s_awaddr[1*ADDR_W +: ADDR_W], held_addr);
        tb_check32("grant matrix retry awsize",
                   {29'h0, s_awsize[1*3 +: 3]}, {29'h0, held_size});
      end
      if (!ready_pair[0]) begin
        tb_check32("grant matrix retry wdata",
                   s_wdata[1*DATA_W +: DATA_W], held_data);
        tb_check32("grant matrix retry wstrb",
                   {28'h0, s_wstrb[1*STRB_W +: STRB_W]},
                   {{(32-STRB_W){1'b0}}, held_strb});
      end

      if (ready_pair == 2'b11) begin
        // grant 拍的 BVALID 必须到这一拍、registered 授权成立后才可见。
        tb_check1("grant cycle bvalid delayed to registered owner",
                  m_bvalid[1], 1'b1);
        tb_check1("grant cycle bready delayed to registered owner",
                  s_bready[1], 1'b1);
        tb_check32("grant cycle registered bresp",
                   {30'h0, m_bresp[1*2 +: 2]}, 32'h2);
        tb_check32("grant cycle registered bid",
                   {28'h0, m_bid[1*4 +: 4]}, {28'h0, held_id});
        `TB_TICK(clk);
        s_bvalid[1] = 1'b0;
        m_bready[1] = 1'b0;
      end else begin
        // 只给缺失通道 READY；已接受通道 VALID 必须一直为 0。
        s_awready[1] = 1'b1;
        s_wready[1] = 1'b1;
        `TB_TICK(clk);
        #1;
        tb_check1("grant matrix retry completes aw sent",
                  dut.wr_aw_sent_q[1], 1'b1);
        tb_check1("grant matrix retry completes w sent",
                  dut.wr_w_sent_q[1], 1'b1);
        tb_check1("grant matrix accepted aw stays quiet", s_awvalid[1], 1'b0);
        tb_check1("grant matrix accepted w stays quiet", s_wvalid[1], 1'b0);

        // 清除 00 poison，随后按正常 registered B 路径终止事务。
        m_awvalid[1] = 1'b0;
        m_wvalid[1] = 1'b0;
        s_awready[1] = 1'b0;
        s_wready[1] = 1'b0;
        s_bvalid[1] = 1'b1;
        m_bready[1] = 1'b1;
        #1;
        tb_check1("grant matrix registered bvalid", m_bvalid[1], 1'b1);
        tb_check1("grant matrix registered bready", s_bready[1], 1'b1);
        tb_check32("grant matrix registered bresp",
                   {30'h0, m_bresp[1*2 +: 2]}, 32'h2);
        tb_check32("grant matrix registered bid",
                   {28'h0, m_bid[1*4 +: 4]}, {28'h0, held_id});
        `TB_TICK(clk);
        s_bvalid[1] = 1'b0;
        m_bready[1] = 1'b0;
      end
      #1;
      tb_check1("grant matrix terminal releases target",
                dut.wr_active_q[1], 1'b0);
      tb_check1("grant matrix terminal releases master",
                dut.wr_master_busy_q[1], 1'b0);
      $display("[AXI-XBAR-GRANT-READY] ready=%02b direct=1 exact_retry=1 registered_b=1 PASS",
               ready_pair);
    end
  endtask

  // Live complete pair must reach the selected target in the same cycle as
  // master AW/W fire.  The target READY matrix seeds registered sent bits;
  // early B is hidden until registered active+dual-sent authority exists.
  task automatic run_write_live_ready_case;
    input [1:0] ready_pair;
    input [ADDR_W-1:0] live_addr;
    input [2:0] live_size;
    input [3:0] live_id;
    input [DATA_W-1:0] live_data;
    input [STRB_W-1:0] live_strb;
    begin
      reset_dut();

      m_awaddr[1*ADDR_W +: ADDR_W] = live_addr;
      m_awid[1*4 +: 4] = live_id;
      m_awlen[1*8 +: 8] = 8'd0;
      m_awsize[1*3 +: 3] = live_size;
      m_awburst[1*2 +: 2] = 2'b01;
      m_awvalid[1] = 1'b1;
      m_wdata[1*DATA_W +: DATA_W] = live_data;
      m_wstrb[1*STRB_W +: STRB_W] = live_strb;
      m_wlast[1] = 1'b1;
      m_wvalid[1] = 1'b1;
      s_awready[1] = ready_pair[1];
      s_wready[1] = ready_pair[0];
      // Deliberately early response: it must remain backpressured until the
      // live edge has established a registered owner and both sent bits.
      s_bvalid[1] = 1'b1;
      s_bresp[1*2 +: 2] = 2'b10;
      m_bready[1] = 1'b1;
      #1;

      tb_check1("live matrix master aw fire", m_awready[1], 1'b1);
      tb_check1("live matrix master w fire", m_wready[1], 1'b1);
      tb_check1("live matrix offer", dut.wr_live_offer_r[1], 1'b1);
      tb_check1("live matrix owner", dut.wr_live_master_r[1], 1'b1);
      tb_check1("live matrix excludes held grant",
                dut.wr_grant_offer_r[1], 1'b0);
      tb_check1("live matrix target awvalid", s_awvalid[1], 1'b1);
      tb_check1("live matrix target wvalid", s_wvalid[1], 1'b1);
      tb_check32("live matrix target awaddr",
                 s_awaddr[1*ADDR_W +: ADDR_W], live_addr);
      tb_check32("live matrix target awsize",
                 {29'h0, s_awsize[1*3 +: 3]}, {29'h0, live_size});
      tb_check32("live matrix target wdata",
                 s_wdata[1*DATA_W +: DATA_W], live_data);
      tb_check32("live matrix target wstrb",
                 {28'h0, s_wstrb[1*STRB_W +: STRB_W]},
                 {{(32-STRB_W){1'b0}}, live_strb});
      tb_check1("live matrix blocks ownerless master b", m_bvalid[1], 1'b0);
      tb_check1("live matrix blocks ownerless target b", s_bready[1], 1'b0);
      tb_check1("live matrix target inactive before edge",
                dut.wr_active_q[1], 1'b0);

      `TB_TICK(clk);
      m_awvalid[1] = 1'b0;
      m_wvalid[1] = 1'b0;
      // Poison all live inputs after the acquisition edge.  Any missing
      // target channel must retry exclusively from registered payload Q.
      m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_0bad;
      m_awid[1*4 +: 4] = 4'hf;
      m_awsize[1*3 +: 3] = 3'd7;
      m_wdata[1*DATA_W +: DATA_W] = 32'hdead_0bad;
      m_wstrb[1*STRB_W +: STRB_W] = {STRB_W{1'b0}};
      #1;

      tb_check1("live matrix registered active", dut.wr_active_q[1], 1'b1);
      tb_check1("live matrix registered owner", dut.wr_owner_q[1], 1'b1);
      tb_check1("live matrix aw sent seed",
                dut.wr_aw_sent_q[1], ready_pair[1]);
      tb_check1("live matrix w sent seed",
                dut.wr_w_sent_q[1], ready_pair[0]);
      tb_check1("live matrix clears aw holder",
                dut.wr_aw_hold_q[1], 1'b0);
      tb_check1("live matrix clears w holder",
                dut.wr_w_hold_q[1], 1'b0);
      tb_check1("live matrix master busy",
                dut.wr_master_busy_q[1], 1'b1);
      tb_check1("live matrix retries only missing aw",
                s_awvalid[1], !ready_pair[1]);
      tb_check1("live matrix retries only missing w",
                s_wvalid[1], !ready_pair[0]);
      if (!ready_pair[1]) begin
        tb_check32("live matrix retry awaddr",
                   s_awaddr[1*ADDR_W +: ADDR_W], live_addr);
        tb_check32("live matrix retry awsize",
                   {29'h0, s_awsize[1*3 +: 3]}, {29'h0, live_size});
      end
      if (!ready_pair[0]) begin
        tb_check32("live matrix retry wdata",
                   s_wdata[1*DATA_W +: DATA_W], live_data);
        tb_check32("live matrix retry wstrb",
                   {28'h0, s_wstrb[1*STRB_W +: STRB_W]},
                   {{(32-STRB_W){1'b0}}, live_strb});
      end

      if (ready_pair == 2'b11) begin
        tb_check1("live matrix registered bvalid", m_bvalid[1], 1'b1);
        tb_check1("live matrix registered bready", s_bready[1], 1'b1);
        tb_check32("live matrix registered bresp",
                   {30'h0, m_bresp[1*2 +: 2]}, 32'h2);
        tb_check32("live matrix registered bid",
                   {28'h0, m_bid[1*4 +: 4]}, {28'h0, live_id});
      end else begin
        tb_check1("live matrix partial hides early master b",
                  m_bvalid[1], 1'b0);
        tb_check1("live matrix partial holds early target b",
                  s_bready[1], 1'b0);
        s_awready[1] = 1'b1;
        s_wready[1] = 1'b1;
        `TB_TICK(clk);
        #1;
        tb_check1("live matrix retry completes aw",
                  dut.wr_aw_sent_q[1], 1'b1);
        tb_check1("live matrix retry completes w",
                  dut.wr_w_sent_q[1], 1'b1);
        tb_check1("live matrix accepted aw remains quiet",
                  s_awvalid[1], 1'b0);
        tb_check1("live matrix accepted w remains quiet",
                  s_wvalid[1], 1'b0);
        tb_check1("live matrix bvalid after registered dual sent",
                  m_bvalid[1], 1'b1);
        tb_check1("live matrix bready after registered dual sent",
                  s_bready[1], 1'b1);
        tb_check32("live matrix delayed bid",
                   {28'h0, m_bid[1*4 +: 4]}, {28'h0, live_id});
      end

      `TB_TICK(clk);
      s_bvalid[1] = 1'b0;
      m_bready[1] = 1'b0;
      s_awready[1] = 1'b0;
      s_wready[1] = 1'b0;
      #1;
      tb_check1("live matrix terminal releases target",
                dut.wr_active_q[1], 1'b0);
      tb_check1("live matrix terminal releases master",
                dut.wr_master_busy_q[1], 1'b0);
      tb_check1("live matrix no residual aw holder",
                dut.wr_aw_hold_q[1], 1'b0);
      tb_check1("live matrix no residual w holder",
                dut.wr_w_hold_q[1], 1'b0);
      tb_check1("live matrix no duplicate held grant",
                dut.wr_grant_offer_r[1], 1'b0);
      tb_check1("live matrix no duplicate target aw",
                s_awvalid[1], 1'b0);
      tb_check1("live matrix no duplicate target w",
                s_wvalid[1], 1'b0);
      $display("[AXI-XBAR-LIVE-READY] ready=%02b direct=1 exact_retry=1 early_b=1 residual_holder=0 PASS",
               ready_pair);
    end
  endtask

  task automatic run_write_same_target_rr_contention;
    begin
      reset_dut();
      m_awaddr[0*ADDR_W +: ADDR_W] = 32'h1000_0100;
      m_awid[0*4 +: 4] = 4'h4;
      m_awlen[0*8 +: 8] = 8'd0;
      m_awsize[0*3 +: 3] = 3'd2;
      m_awburst[0*2 +: 2] = 2'b01;
      m_wdata[0*DATA_W +: DATA_W] = 32'h4444_0000;
      m_wstrb[0*STRB_W +: STRB_W] = 4'hf;
      m_wlast[0] = 1'b1;
      m_awvalid[0] = 1'b1;
      m_wvalid[0] = 1'b1;

      m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_0110;
      m_awid[1*4 +: 4] = 4'h5;
      m_awlen[1*8 +: 8] = 8'd0;
      m_awsize[1*3 +: 3] = 3'd1;
      m_awburst[1*2 +: 2] = 2'b01;
      m_wdata[1*DATA_W +: DATA_W] = 32'h5555_1111;
      m_wstrb[1*STRB_W +: STRB_W] = 4'h3;
      m_wlast[1] = 1'b1;
      m_awvalid[1] = 1'b1;
      m_wvalid[1] = 1'b1;
      s_awready[1] = 1'b1;
      s_wready[1] = 1'b1;
      #1;
      tb_check1("rr contention captures master0 aw", m_awready[0], 1'b1);
      tb_check1("rr contention captures master0 w", m_wready[0], 1'b1);
      tb_check1("rr contention captures master1 aw", m_awready[1], 1'b1);
      tb_check1("rr contention captures master1 w", m_wready[1], 1'b1);
      // 同 target 有两个 live pair 时，资格集合不是唯一 source；live
      // path 必须 action-quiet，两笔都在 edge 上进入 holder 后交给既有 RR。
      tb_check1("rr contention blocks ambiguous live offer",
                dut.wr_live_offer_r[1], 1'b0);
      tb_check1("rr contention keeps target aw quiet on live conflict",
                s_awvalid[1], 1'b0);
      tb_check1("rr contention keeps target w quiet on live conflict",
                s_wvalid[1], 1'b0);
      `TB_TICK(clk);
      m_awvalid = {M_COUNT{1'b0}};
      m_wvalid = {M_COUNT{1'b0}};
      #1;

      // reset 后 RR 起点为 master0；两个 complete holders 中只选它。
      tb_check1("rr contention held offer master0",
                dut.wr_grant_offer_r[1], 1'b1);
      tb_check1("rr contention held selects master0",
                dut.wr_grant_master_r[1], 1'b0);
      tb_check32("rr contention held master0 awaddr",
                 s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0100);
      tb_check32("rr contention held master0 wdata",
                 s_wdata[1*DATA_W +: DATA_W], 32'h4444_0000);
      `TB_TICK(clk);
      #1;
      tb_check1("rr contention clears selected master0 aw holder",
                dut.wr_aw_hold_q[0], 1'b0);
      tb_check1("rr contention clears selected master0 w holder",
                dut.wr_w_hold_q[0], 1'b0);
      tb_check1("rr contention keeps master1 aw holder",
                dut.wr_aw_hold_q[1], 1'b1);
      tb_check1("rr contention keeps master1 w holder",
                dut.wr_w_hold_q[1], 1'b1);
      tb_check1("rr contention active owner master0",
                dut.wr_owner_q[1], 1'b0);
      tb_check1("rr contention held owner has dual sent",
                dut.wr_aw_sent_q[1] && dut.wr_w_sent_q[1], 1'b1);

      s_bvalid[1] = 1'b1;
      s_bresp[1*2 +: 2] = 2'b00;
      m_bready[0] = 1'b1;
      #1;
      tb_check1("rr contention master0 bvalid", m_bvalid[0], 1'b1);
      tb_check32("rr contention master0 bid",
                 {28'h0, m_bid[0*4 +: 4]}, 32'h4);
      `TB_TICK(clk);
      s_bvalid[1] = 1'b0;
      m_bready[0] = 1'b0;
      #1;

      // 前一笔 terminal 的同一边沿后，target 已空闲；下一 holder 应直接
      // 出示，无需再插一个 quiet grant cycle。
      tb_check1("rr contention direct offer master1",
                dut.wr_grant_offer_r[1], 1'b1);
      tb_check1("rr contention selects master1",
                dut.wr_grant_master_r[1], 1'b1);
      tb_check32("rr contention master1 awaddr",
                 s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0110);
      tb_check32("rr contention master1 wdata",
                 s_wdata[1*DATA_W +: DATA_W], 32'h5555_1111);
      `TB_TICK(clk);

      s_bvalid[1] = 1'b1;
      m_bready[1] = 1'b1;
      #1;
      tb_check1("rr contention master1 bvalid", m_bvalid[1], 1'b1);
      tb_check32("rr contention master1 bid",
                 {28'h0, m_bid[1*4 +: 4]}, 32'h5);
      `TB_TICK(clk);
      s_bvalid[1] = 1'b0;
      m_bready[1] = 1'b0;
      #1;
      tb_check1("rr contention terminal releases target",
                dut.wr_active_q[1], 1'b0);
      $display("[AXI-XBAR-LIVE-RR] simultaneous_live=2 live_quiet=1 holders=2 held_order=0,1 PASS");
    end
  endtask

  task automatic run_write_unknown_rr_fail_closed;
    begin
      reset_dut();
      m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_0300;
      m_awid[1*4 +: 4] = 4'hc;
      m_awlen[1*8 +: 8] = 8'd0;
      m_awsize[1*3 +: 3] = 3'd2;
      m_awburst[1*2 +: 2] = 2'b01;
      m_wdata[1*DATA_W +: DATA_W] = 32'hcafe_0300;
      m_wstrb[1*STRB_W +: STRB_W] = 4'hf;
      m_wlast[1] = 1'b1;
      m_awvalid[1] = 1'b1;
      m_wvalid[1] = 1'b1;
      s_awready[1] = 1'b1;
      s_wready[1] = 1'b1;
      // RR 在 live pair 出现前即未知：master local READY/holder capture
      // 仍可进展，但 live target acquisition 必须 fail closed。
      dut.wr_rr_q[1] = 1'bx;
      #1;
      tb_check1("unknown rr captures aw holder", m_awready[1], 1'b1);
      tb_check1("unknown rr captures w holder", m_wready[1], 1'b1);
      tb_check1("unknown x rr blocks live offer",
                dut.wr_live_offer_r[1], 1'b0);
      tb_check1("unknown x rr keeps live target aw quiet",
                s_awvalid[1], 1'b0);
      tb_check1("unknown x rr keeps live target w quiet",
                s_wvalid[1], 1'b0);
      `TB_TICK(clk);
      m_awvalid[1] = 1'b0;
      m_wvalid[1] = 1'b0;

      // 完整 holder 已存在时，未知 RR 也不能通过 if/else 的 X optimism
      // 退化成 master1 held grant。X 与 Z 都必须 action-quiet。
      #1;
      tb_check1("unknown x rr blocks grant", dut.wr_grant_valid_r[1], 1'b0);
      tb_check1("unknown x rr blocks offer", dut.wr_grant_offer_r[1], 1'b0);
      tb_check1("unknown x rr blocks target aw", s_awvalid[1], 1'b0);
      tb_check1("unknown x rr blocks target w", s_wvalid[1], 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("unknown x rr preserves aw holder", dut.wr_aw_hold_q[1], 1'b1);
      tb_check1("unknown x rr preserves w holder", dut.wr_w_hold_q[1], 1'b1);

      dut.wr_rr_q[1] = 1'bz;
      #1;
      tb_check1("unknown z rr blocks grant", dut.wr_grant_valid_r[1], 1'b0);
      tb_check1("unknown z rr blocks offer", dut.wr_grant_offer_r[1], 1'b0);
      tb_check1("unknown z rr blocks target aw", s_awvalid[1], 1'b0);
      tb_check1("unknown z rr blocks target w", s_wvalid[1], 1'b0);
      `TB_TICK(clk);

      // 恢复合法 RR 后，同一 holders 必须继续完成，证明 fail-closed
      // 只是暂停仲裁，没有 drop 或破坏 transaction。
      dut.wr_rr_q[1] = 1'b0;
      #1;
      tb_check1("known rr resumes direct offer", dut.wr_grant_offer_r[1], 1'b1);
      tb_check1("known rr selects held master1", dut.wr_grant_master_r[1], 1'b1);
      tb_check32("known rr resumes held awaddr",
                 s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0300);
      tb_check32("known rr resumes held wdata",
                 s_wdata[1*DATA_W +: DATA_W], 32'hcafe_0300);
      `TB_TICK(clk);
      s_bvalid[1] = 1'b1;
      s_bresp[1*2 +: 2] = 2'b00;
      m_bready[1] = 1'b1;
      #1;
      tb_check1("known rr resumed bvalid", m_bvalid[1], 1'b1);
      tb_check32("known rr resumed bid",
                 {28'h0, m_bid[1*4 +: 4]}, 32'hc);
      `TB_TICK(clk);
      s_bvalid[1] = 1'b0;
      m_bready[1] = 1'b0;
      #1;
      tb_check1("known rr resumed terminal", dut.wr_active_q[1], 1'b0);
      $display("[AXI-XBAR-GRANT-RR-UNKNOWN] x_quiet=1 z_quiet=1 resume=1 PASS");
    end
  endtask

  task automatic run_write_different_target_parallel_b_grant;
    begin
      reset_dut();

      // 先让 master0 -> target0 完成 AW/W，并停在 registered B backpressure。
      m_awaddr[0*ADDR_W +: ADDR_W] = 32'h0000_0040;
      m_awid[0*4 +: 4] = 4'h6;
      m_awlen[0*8 +: 8] = 8'd0;
      m_awsize[0*3 +: 3] = 3'd2;
      m_awburst[0*2 +: 2] = 2'b01;
      m_wdata[0*DATA_W +: DATA_W] = 32'h6000_0040;
      m_wstrb[0*STRB_W +: STRB_W] = 4'hf;
      m_wlast[0] = 1'b1;
      m_awvalid[0] = 1'b1;
      m_wvalid[0] = 1'b1;
      s_awready[0] = 1'b1;
      s_wready[0] = 1'b1;
      #1;
      tb_check1("parallel targets captures master0 aw", m_awready[0], 1'b1);
      tb_check1("parallel targets captures master0 w", m_wready[0], 1'b1);
      tb_check1("parallel targets target0 live offer",
                dut.wr_live_offer_r[0], 1'b1);
      tb_check1("parallel targets target0 live owner master0",
                dut.wr_live_master_r[0], 1'b0);
      tb_check1("parallel targets target0 live awvalid", s_awvalid[0], 1'b1);
      tb_check1("parallel targets target0 live wvalid", s_wvalid[0], 1'b1);
      tb_check32("parallel targets target0 live awaddr",
                 s_awaddr[0*ADDR_W +: ADDR_W], 32'h0000_0040);
      tb_check32("parallel targets target0 live wdata",
                 s_wdata[0*DATA_W +: DATA_W], 32'h6000_0040);
      `TB_TICK(clk);
      m_awvalid[0] = 1'b0;
      m_wvalid[0] = 1'b0;
      #1;
      tb_check1("parallel targets target0 live registered active",
                dut.wr_active_q[0], 1'b1);
      tb_check1("parallel targets target0 live dual sent",
                dut.wr_aw_sent_q[0] && dut.wr_w_sent_q[0], 1'b1);
      s_awready[0] = 1'b0;
      s_wready[0] = 1'b0;

      s_bvalid[0] = 1'b1;
      s_bresp[0*2 +: 2] = 2'b01;
      m_bready[0] = 1'b0;
      #1;
      tb_check1("parallel targets target0 registered bvalid",
                m_bvalid[0], 1'b1);
      tb_check32("parallel targets target0 registered bresp",
                 {30'h0, m_bresp[0*2 +: 2]}, 32'h1);
      tb_check32("parallel targets target0 registered bid",
                 {28'h0, m_bid[0*4 +: 4]}, 32'h6);
      tb_check1("parallel targets target0 bready follows stall",
                s_bready[0], 1'b0);

      // target0 的 B owner 保持期间，master1 在不同 target1 形成完整 holder。
      // target1 同拍提前给 BVALID，用于证明 direct grant 尚无 B owner。
      m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_0140;
      m_awid[1*4 +: 4] = 4'h7;
      m_awlen[1*8 +: 8] = 8'd0;
      m_awsize[1*3 +: 3] = 3'd1;
      m_awburst[1*2 +: 2] = 2'b01;
      m_wdata[1*DATA_W +: DATA_W] = 32'h7000_0140;
      m_wstrb[1*STRB_W +: STRB_W] = 4'h3;
      m_wlast[1] = 1'b1;
      m_awvalid[1] = 1'b1;
      m_wvalid[1] = 1'b1;
      s_awready[1] = 1'b1;
      s_wready[1] = 1'b1;
      s_bvalid[1] = 1'b1;
      s_bresp[1*2 +: 2] = 2'b10;
      m_bready[1] = 1'b1;
      #1;
      tb_check1("parallel targets captures master1 aw", m_awready[1], 1'b1);
      tb_check1("parallel targets captures master1 w", m_wready[1], 1'b1);
      // 同一拍观测：target0 仍是 registered B backpressure，target1 已经
      // live offer。两条 target 生命周期不能互相覆盖 owner 或输出。
      tb_check1("parallel targets target0 remains active",
                dut.wr_active_q[0], 1'b1);
      tb_check1("parallel targets target0 owner remains master0",
                dut.wr_owner_q[0], 1'b0);
      tb_check1("parallel targets target0 bvalid holds during target1 grant",
                m_bvalid[0], 1'b1);
      tb_check32("parallel targets target0 bresp holds during target1 grant",
                 {30'h0, m_bresp[0*2 +: 2]}, 32'h1);
      tb_check32("parallel targets target0 bid holds during target1 grant",
                 {28'h0, m_bid[0*4 +: 4]}, 32'h6);
      tb_check1("parallel targets target0 bready still follows master0",
                s_bready[0], 1'b0);

      tb_check1("parallel targets target1 live offer",
                dut.wr_live_offer_r[1], 1'b1);
      tb_check1("parallel targets target1 live owner master1",
                dut.wr_live_master_r[1], 1'b1);
      tb_check1("parallel targets target1 excludes held offer",
                dut.wr_grant_offer_r[1], 1'b0);
      tb_check1("parallel targets target1 awvalid", s_awvalid[1], 1'b1);
      tb_check1("parallel targets target1 wvalid", s_wvalid[1], 1'b1);
      tb_check32("parallel targets target1 awaddr",
                 s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0140);
      tb_check32("parallel targets target1 awsize",
                 {29'h0, s_awsize[1*3 +: 3]}, 32'h1);
      tb_check32("parallel targets target1 wdata",
                 s_wdata[1*DATA_W +: DATA_W], 32'h7000_0140);
      tb_check32("parallel targets target1 wstrb",
                 {28'h0, s_wstrb[1*STRB_W +: STRB_W]}, 32'h3);
      tb_check1("parallel targets master1 has no ownerless b",
                m_bvalid[1], 1'b0);
      tb_check1("parallel targets target1 has no ownerless bready",
                s_bready[1], 1'b0);
      tb_check1("parallel targets target1 not active before grant edge",
                dut.wr_active_q[1], 1'b0);

      // target1 live edge 后两 target 同时 active，owner 分别保持 0/1。
      `TB_TICK(clk);
      m_awvalid[1] = 1'b0;
      m_wvalid[1] = 1'b0;
      #1;
      tb_check1("parallel targets target0 active with target1 active",
                dut.wr_active_q[0], 1'b1);
      tb_check1("parallel targets target1 registered active",
                dut.wr_active_q[1], 1'b1);
      tb_check1("parallel targets target0 registered owner master0",
                dut.wr_owner_q[0], 1'b0);
      tb_check1("parallel targets target1 registered owner master1",
                dut.wr_owner_q[1], 1'b1);
      tb_check1("parallel targets target0 bvalid survives target1 edge",
                m_bvalid[0], 1'b1);
      tb_check1("parallel targets target0 bready remains stalled",
                s_bready[0], 1'b0);
      tb_check1("parallel targets target1 registered bvalid",
                m_bvalid[1], 1'b1);
      tb_check32("parallel targets target1 registered bresp",
                 {30'h0, m_bresp[1*2 +: 2]}, 32'h2);
      tb_check32("parallel targets target1 registered bid",
                 {28'h0, m_bid[1*4 +: 4]}, 32'h7);
      tb_check1("parallel targets target1 registered bready",
                s_bready[1], 1'b1);

      // 先合法终止 target1；target0 的 backpressured B 必须继续保持。
      `TB_TICK(clk);
      s_bvalid[1] = 1'b0;
      m_bready[1] = 1'b0;
      #1;
      tb_check1("parallel targets target1 terminal releases active",
                dut.wr_active_q[1], 1'b0);
      tb_check1("parallel targets target1 terminal releases master",
                dut.wr_master_busy_q[1], 1'b0);
      tb_check1("parallel targets target0 remains active after target1 terminal",
                dut.wr_active_q[0], 1'b1);
      tb_check1("parallel targets target0 bvalid holds after target1 terminal",
                m_bvalid[0], 1'b1);
      tb_check32("parallel targets target0 bid holds after target1 terminal",
                 {28'h0, m_bid[0*4 +: 4]}, 32'h6);

      // 再释放 master0 backpressure；BREADY 必须当拍跟随并只终止 target0。
      m_bready[0] = 1'b1;
      #1;
      tb_check1("parallel targets target0 bready follows release",
                s_bready[0], 1'b1);
      tb_check1("parallel targets target0 bvalid on release",
                m_bvalid[0], 1'b1);
      `TB_TICK(clk);
      s_bvalid[0] = 1'b0;
      m_bready[0] = 1'b0;
      #1;
      tb_check1("parallel targets target0 terminal releases active",
                dut.wr_active_q[0], 1'b0);
      tb_check1("parallel targets target0 terminal releases master",
                dut.wr_master_busy_q[0], 1'b0);
      tb_check1("parallel targets target1 stays released",
                dut.wr_active_q[1], 1'b0);
      $display("[AXI-XBAR-LIVE-PARALLEL-TARGETS] target0_b_hold=1 target1_live=1 owners=0,1 terminals=1 PASS");
    end
  endtask

  // 两个 master 在同一拍形成 complete pair、且分别译码到不同 target 时，
  // 两条 live 路径应独立建立 owner。这个用例专门防止把全局冲突门误写成
  // “任何第二个 live pair 都阻塞”，同时验证不同 target 的 B 生命周期并行。
  task automatic run_write_dual_target_same_cycle_live;
    begin
      reset_dut();

      m_awaddr[0*ADDR_W +: ADDR_W] = 32'h0000_0180;
      m_awid[0*4 +: 4] = 4'h2;
      m_awlen[0*8 +: 8] = 8'd0;
      m_awsize[0*3 +: 3] = 3'd2;
      m_awburst[0*2 +: 2] = 2'b01;
      m_wdata[0*DATA_W +: DATA_W] = 32'h2020_0180;
      m_wstrb[0*STRB_W +: STRB_W] = 4'hf;
      m_wlast[0] = 1'b1;
      m_awvalid[0] = 1'b1;
      m_wvalid[0] = 1'b1;

      m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_0190;
      m_awid[1*4 +: 4] = 4'h3;
      m_awlen[1*8 +: 8] = 8'd0;
      m_awsize[1*3 +: 3] = 3'd1;
      m_awburst[1*2 +: 2] = 2'b01;
      m_wdata[1*DATA_W +: DATA_W] = 32'h3030_0190;
      m_wstrb[1*STRB_W +: STRB_W] = 4'h3;
      m_wlast[1] = 1'b1;
      m_awvalid[1] = 1'b1;
      m_wvalid[1] = 1'b1;

      s_awready[0] = 1'b1;
      s_wready[0] = 1'b1;
      s_awready[1] = 1'b1;
      s_wready[1] = 1'b1;
      #1;
      tb_check1("dual live master0 aw local fire", m_awready[0], 1'b1);
      tb_check1("dual live master0 w local fire", m_wready[0], 1'b1);
      tb_check1("dual live master1 aw local fire", m_awready[1], 1'b1);
      tb_check1("dual live master1 w local fire", m_wready[1], 1'b1);
      tb_check1("dual live target0 offer", dut.wr_live_offer_r[0], 1'b1);
      tb_check1("dual live target1 offer", dut.wr_live_offer_r[1], 1'b1);
      tb_check1("dual live target0 owner master0",
                dut.wr_live_master_r[0], 1'b0);
      tb_check1("dual live target1 owner master1",
                dut.wr_live_master_r[1], 1'b1);
      tb_check1("dual live target0 awvalid", s_awvalid[0], 1'b1);
      tb_check1("dual live target0 wvalid", s_wvalid[0], 1'b1);
      tb_check1("dual live target1 awvalid", s_awvalid[1], 1'b1);
      tb_check1("dual live target1 wvalid", s_wvalid[1], 1'b1);
      tb_check32("dual live target0 awaddr",
                 s_awaddr[0*ADDR_W +: ADDR_W], 32'h0000_0180);
      tb_check32("dual live target1 awaddr",
                 s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_0190);
      tb_check32("dual live target0 wdata",
                 s_wdata[0*DATA_W +: DATA_W], 32'h2020_0180);
      tb_check32("dual live target1 wdata",
                 s_wdata[1*DATA_W +: DATA_W], 32'h3030_0190);

      `TB_TICK(clk);
      m_awvalid = {M_COUNT{1'b0}};
      m_wvalid = {M_COUNT{1'b0}};
      s_awready = {S_COUNT{1'b0}};
      s_wready = {S_COUNT{1'b0}};
      #1;
      tb_check1("dual live target0 registered active",
                dut.wr_active_q[0], 1'b1);
      tb_check1("dual live target1 registered active",
                dut.wr_active_q[1], 1'b1);
      tb_check1("dual live both masters busy",
                dut.wr_master_busy_q[0] && dut.wr_master_busy_q[1], 1'b1);
      tb_check1("dual live no master0 residual holder",
                dut.wr_aw_hold_q[0] || dut.wr_w_hold_q[0], 1'b0);
      tb_check1("dual live no master1 residual holder",
                dut.wr_aw_hold_q[1] || dut.wr_w_hold_q[1], 1'b0);

      s_bvalid[0] = 1'b1;
      s_bresp[0*2 +: 2] = 2'b01;
      s_bvalid[1] = 1'b1;
      s_bresp[1*2 +: 2] = 2'b10;
      m_bready[0] = 1'b1;
      m_bready[1] = 1'b1;
      #1;
      tb_check1("dual live master0 bvalid", m_bvalid[0], 1'b1);
      tb_check1("dual live master1 bvalid", m_bvalid[1], 1'b1);
      tb_check32("dual live master0 bid",
                 {28'h0, m_bid[0*4 +: 4]}, 32'h2);
      tb_check32("dual live master1 bid",
                 {28'h0, m_bid[1*4 +: 4]}, 32'h3);
      tb_check1("dual live target0 bready", s_bready[0], 1'b1);
      tb_check1("dual live target1 bready", s_bready[1], 1'b1);
      `TB_TICK(clk);
      s_bvalid = {S_COUNT{1'b0}};
      m_bready = {M_COUNT{1'b0}};
      #1;
      tb_check1("dual live target0 terminal", dut.wr_active_q[0], 1'b0);
      tb_check1("dual live target1 terminal", dut.wr_active_q[1], 1'b0);
      $display("[AXI-XBAR-LIVE-DUAL-TARGET] simultaneous=2 owners=0,1 dual_b=1 PASS");
    end
  endtask

  // 任意旧 complete holder 存在时，新的 live pair 即使去往不同 target 也
  // 必须先进入本地 holders；旧笔按 held path 取得 owner 后，新笔下一拍再由
  // 正常 held path 服务。这是保守年龄边界，也是 live 优化的关键安全门。
  task automatic run_write_older_holder_blocks_live;
    begin
      reset_dut();

      // AW-first + W-second，显式形成 master0 -> target0 的旧 complete holder。
      m_awaddr[0*ADDR_W +: ADDR_W] = 32'h0000_01a0;
      m_awid[0*4 +: 4] = 4'h4;
      m_awlen[0*8 +: 8] = 8'd0;
      m_awsize[0*3 +: 3] = 3'd2;
      m_awburst[0*2 +: 2] = 2'b01;
      m_awvalid[0] = 1'b1;
      #1;
      tb_check1("older holder accepts master0 aw", m_awready[0], 1'b1);
      `TB_TICK(clk);
      m_awvalid[0] = 1'b0;
      m_wdata[0*DATA_W +: DATA_W] = 32'h4040_01a0;
      m_wstrb[0*STRB_W +: STRB_W] = 4'hf;
      m_wlast[0] = 1'b1;
      m_wvalid[0] = 1'b1;
      #1;
      tb_check1("older holder accepts master0 w", m_wready[0], 1'b1);
      `TB_TICK(clk);
      m_wvalid[0] = 1'b0;

      // 旧 holder 已存在；同拍让 master1 的新 complete pair 去往 target1。
      m_awaddr[1*ADDR_W +: ADDR_W] = 32'h1000_01b0;
      m_awid[1*4 +: 4] = 4'h5;
      m_awlen[1*8 +: 8] = 8'd0;
      m_awsize[1*3 +: 3] = 3'd1;
      m_awburst[1*2 +: 2] = 2'b01;
      m_wdata[1*DATA_W +: DATA_W] = 32'h5050_01b0;
      m_wstrb[1*STRB_W +: STRB_W] = 4'h3;
      m_wlast[1] = 1'b1;
      m_awvalid[1] = 1'b1;
      m_wvalid[1] = 1'b1;
      s_awready[0] = 1'b1;
      s_wready[0] = 1'b1;
      s_awready[1] = 1'b1;
      s_wready[1] = 1'b1;
      #1;
      tb_check1("older holder target0 held offer",
                dut.wr_grant_offer_r[0], 1'b1);
      tb_check1("older holder target0 owner master0",
                dut.wr_grant_master_r[0], 1'b0);
      tb_check1("older holder new master1 aw local fire", m_awready[1], 1'b1);
      tb_check1("older holder new master1 w local fire", m_wready[1], 1'b1);
      tb_check1("older holder globally blocks target1 live offer",
                dut.wr_live_offer_r[1], 1'b0);
      tb_check1("older holder keeps target1 aw quiet", s_awvalid[1], 1'b0);
      tb_check1("older holder keeps target1 w quiet", s_wvalid[1], 1'b0);

      `TB_TICK(clk);
      m_awvalid[1] = 1'b0;
      m_wvalid[1] = 1'b0;
      #1;
      tb_check1("older holder target0 registered active",
                dut.wr_active_q[0], 1'b1);
      tb_check1("older holder captured master1 aw holder",
                dut.wr_aw_hold_q[1], 1'b1);
      tb_check1("older holder captured master1 w holder",
                dut.wr_w_hold_q[1], 1'b1);
      tb_check1("older holder target1 resumes via held offer",
                dut.wr_grant_offer_r[1], 1'b1);
      tb_check1("older holder target1 held owner master1",
                dut.wr_grant_master_r[1], 1'b1);
      tb_check32("older holder target1 held awaddr",
                 s_awaddr[1*ADDR_W +: ADDR_W], 32'h1000_01b0);
      tb_check32("older holder target1 held wdata",
                 s_wdata[1*DATA_W +: DATA_W], 32'h5050_01b0);

      `TB_TICK(clk);
      s_awready = {S_COUNT{1'b0}};
      s_wready = {S_COUNT{1'b0}};
      #1;
      tb_check1("older holder both targets active",
                dut.wr_active_q[0] && dut.wr_active_q[1], 1'b1);
      tb_check1("older holder target0 owner stable",
                dut.wr_owner_q[0], 1'b0);
      tb_check1("older holder target1 owner registered",
                dut.wr_owner_q[1], 1'b1);

      s_bvalid[0] = 1'b1;
      s_bvalid[1] = 1'b1;
      s_bresp[0*2 +: 2] = 2'b00;
      s_bresp[1*2 +: 2] = 2'b00;
      m_bready[0] = 1'b1;
      m_bready[1] = 1'b1;
      #1;
      tb_check1("older holder master0 bvalid", m_bvalid[0], 1'b1);
      tb_check1("older holder master1 bvalid", m_bvalid[1], 1'b1);
      tb_check32("older holder master0 bid",
                 {28'h0, m_bid[0*4 +: 4]}, 32'h4);
      tb_check32("older holder master1 bid",
                 {28'h0, m_bid[1*4 +: 4]}, 32'h5);
      `TB_TICK(clk);
      s_bvalid = {S_COUNT{1'b0}};
      m_bready = {M_COUNT{1'b0}};
      #1;
      tb_check1("older holder target0 terminal", dut.wr_active_q[0], 1'b0);
      tb_check1("older holder target1 terminal", dut.wr_active_q[1], 1'b0);
      $display("[AXI-XBAR-LIVE-OLDER-HOLDER] old_held_first=1 new_live_quiet=1 new_held_next=1 PASS");
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
    // crossbar 视角: 被 flush 作废的读也是一个正常完成的读(master rready 收下丢弃)。
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
    run_write_grant_ready_case(2'b11, 32'h1000_0200, 3'd2,
                               4'h8, 32'h1111_aaaa, 4'hf);
    run_write_grant_ready_case(2'b10, 32'h1000_0210, 3'd1,
                               4'h9, 32'h2222_bbbb, 4'h3);
    run_write_grant_ready_case(2'b01, 32'h1000_0220, 3'd0,
                               4'ha, 32'h3333_cccc, 4'h1);
    run_write_grant_ready_case(2'b00, 32'h1000_0230, 3'd2,
                               4'hb, 32'h4444_dddd, 4'hc);
    run_write_live_ready_case(2'b11, 32'h1000_0240, 3'd2,
                              4'h8, 32'h5555_eeee, 4'hf);
    run_write_live_ready_case(2'b10, 32'h1000_0250, 3'd1,
                              4'h9, 32'h6666_ffff, 4'h3);
    run_write_live_ready_case(2'b01, 32'h1000_0260, 3'd0,
                              4'ha, 32'h7777_1111, 4'h1);
    run_write_live_ready_case(2'b00, 32'h1000_0270, 3'd2,
                              4'hb, 32'h8888_2222, 4'hc);
    run_write_same_target_rr_contention();
    run_write_unknown_rr_fail_closed();
    run_write_different_target_parallel_b_grant();
    run_write_dual_target_same_cycle_live();
    run_write_older_holder_blocks_live();
    $display("[AXI-XBAR-LIVE-PAIR-OFFER] held_ready_matrix=1 live_ready_matrix=1 poison=1 early_b=1 rr=1 rr_unknown=1 parallel_targets=1 dual_target=1 older_holder=1 PASS");
    tb_finish("tb_axi_xbar");
  end
endmodule
