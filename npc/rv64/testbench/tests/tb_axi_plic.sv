`include "define.v"

module tb_axi_plic;
  `include "tb_common.svh"

  reg clk;
  reg rst;

  reg arvalid;
  wire arready;
  reg [`XLEN-1:0] araddr;
  reg [2:0] arsize;
  wire rvalid;
  reg rready;
  wire [`XLEN-1:0] rdata;
  wire [1:0] rresp;

  reg awvalid;
  wire awready;
  reg [`XLEN-1:0] awaddr;
  reg [2:0] awsize;
  reg wvalid;
  wire wready;
  reg [`XLEN-1:0] wdata;
  reg [`STRB_W-1:0] wstrb;
  wire bvalid;
  reg bready;
  wire [1:0] bresp;

  reg [31:0] source_irq;
  wire external_irq;
  wire [`XLEN-1:0] rdata_w1;
  wire [`XLEN-1:0] rdata_w32;

  AxiPlic #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(arvalid),
    .s_axi_arready_o(arready),
    .s_axi_araddr_i(araddr),
    .s_axi_arsize_i(arsize),
    .s_axi_rvalid_o(rvalid),
    .s_axi_rready_i(rready),
    .s_axi_rdata_o(rdata),
    .s_axi_rresp_o(rresp),
    .s_axi_awvalid_i(awvalid),
    .s_axi_awready_o(awready),
    .s_axi_awaddr_i(awaddr),
    .s_axi_awsize_i(awsize),
    .s_axi_wvalid_i(wvalid),
    .s_axi_wready_o(wready),
    .s_axi_wdata_i(wdata),
    .s_axi_wstrb_i(wstrb),
    .s_axi_bvalid_o(bvalid),
    .s_axi_bready_i(bready),
    .s_axi_bresp_o(bresp),
    .source_irq_i(source_irq),
    .external_irq_o(external_irq)
  );

  // Boundary elaboration/behavior instances share the same legal AXI
  // stimulus.  Their read payloads provide permanent regression evidence that
  // PRIORITY_BITS=1 is WARL-truncated and PRIORITY_BITS=32 preserves the old
  // full-width register behavior.
  AxiPlic #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W),
    .PRIORITY_BITS(1)
  ) dut_w1 (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(arvalid),
    .s_axi_arready_o(),
    .s_axi_araddr_i(araddr),
    .s_axi_arsize_i(arsize),
    .s_axi_rvalid_o(),
    .s_axi_rready_i(rready),
    .s_axi_rdata_o(rdata_w1),
    .s_axi_rresp_o(),
    .s_axi_awvalid_i(awvalid),
    .s_axi_awready_o(),
    .s_axi_awaddr_i(awaddr),
    .s_axi_awsize_i(awsize),
    .s_axi_wvalid_i(wvalid),
    .s_axi_wready_o(),
    .s_axi_wdata_i(wdata),
    .s_axi_wstrb_i(wstrb),
    .s_axi_bvalid_o(),
    .s_axi_bready_i(bready),
    .s_axi_bresp_o(),
    .source_irq_i(source_irq),
    .external_irq_o()
  );

  AxiPlic #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W),
    .PRIORITY_BITS(32)
  ) dut_w32 (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(arvalid),
    .s_axi_arready_o(),
    .s_axi_araddr_i(araddr),
    .s_axi_arsize_i(arsize),
    .s_axi_rvalid_o(),
    .s_axi_rready_i(rready),
    .s_axi_rdata_o(rdata_w32),
    .s_axi_rresp_o(),
    .s_axi_awvalid_i(awvalid),
    .s_axi_awready_o(),
    .s_axi_awaddr_i(awaddr),
    .s_axi_awsize_i(awsize),
    .s_axi_wvalid_i(wvalid),
    .s_axi_wready_o(),
    .s_axi_wdata_i(wdata),
    .s_axi_wstrb_i(wstrb),
    .s_axi_bvalid_o(),
    .s_axi_bready_i(bready),
    .s_axi_bresp_o(),
    .source_irq_i(source_irq),
    .external_irq_o()
  );

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      arvalid = 1'b0;
      araddr = {`XLEN{1'b0}};
      arsize = 3'd2;
      rready = 1'b0;
      awvalid = 1'b0;
      awaddr = {`XLEN{1'b0}};
      awsize = 3'd2;
      wvalid = 1'b0;
      wdata = {`XLEN{1'b0}};
      wstrb = {`STRB_W{1'b0}};
      bready = 1'b0;
      source_irq = 32'h0;
      `TB_TICK(clk);
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  task automatic axi_read_word;
    input [`XLEN-1:0] addr;
    input [31:0] exp_data;
    reg [`XLEN-1:0] exp_bus;
    begin
      araddr = addr ^ {{(`XLEN-1){1'b0}}, 1'b1};
      #0;
      araddr = addr;
      arsize = 3'd2;
      exp_bus = {{(`XLEN-32){1'b0}}, exp_data} <<
                {addr[2:0], 3'b000};
      arvalid = 1'b1;
      rready = 1'b0;
      #1;
      tb_check1("read arready", arready, 1'b1);
      `TB_TICK(clk);
      arvalid = 1'b0;
      #1;
      tb_check1("read rvalid", rvalid, 1'b1);
      tb_check32("read data low", rdata[31:0], exp_bus[31:0]);
      tb_check32("read data high", rdata[`XLEN-1:32], exp_bus[`XLEN-1:32]);
      tb_check32("read resp", {30'b0, rresp}, 32'h0);
      rready = 1'b1;
      `TB_TICK(clk);
      rready = 1'b0;
      // Icarus does not always include memory-array reads hidden in a function
      // in an always-@* sensitivity set.  Return the address to zero so a
      // later read of the same register necessarily re-evaluates readback.
      araddr = {`XLEN{1'b0}};
    end
  endtask

  task automatic axi_read_double;
    input [`XLEN-1:0] addr;
    input [31:0] exp_low;
    input [31:0] exp_high;
    begin
      araddr = addr ^ {{(`XLEN-1){1'b0}}, 1'b1};
      #0;
      araddr = addr;
      arsize = 3'd3;
      arvalid = 1'b1;
      rready = 1'b0;
      #1;
      tb_check1("read64 arready", arready, 1'b1);
      `TB_TICK(clk);
      arvalid = 1'b0;
      #1;
      tb_check1("read64 rvalid", rvalid, 1'b1);
      tb_check32("read64 low", rdata[31:0], exp_low);
      tb_check32("read64 high", rdata[63:32], exp_high);
      rready = 1'b1;
      `TB_TICK(clk);
      rready = 1'b0;
      araddr = {`XLEN{1'b0}};
    end
  endtask

  task automatic axi_write_word;
    input [`XLEN-1:0] addr;
    input [31:0] data;
    input [`STRB_W-1:0] strb;
    begin
      awaddr = addr;
      awsize = 3'd2;
      wdata = {{(`XLEN-32){1'b0}}, data} << {addr[2:0], 3'b000};
      wstrb = strb << addr[2:0];
      awvalid = 1'b1;
      wvalid = 1'b1;
      bready = 1'b0;
      #1;
      tb_check1("write awready", awready, 1'b1);
      tb_check1("write wready", wready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      wvalid = 1'b0;
      #1;
      tb_check1("write bvalid", bvalid, 1'b1);
      tb_check32("write bresp", {30'b0, bresp}, 32'h0);
      bready = 1'b1;
      `TB_TICK(clk);
      bready = 1'b0;
    end
  endtask

  task automatic axi_write_split;
    input [`XLEN-1:0] addr;
    input [31:0] data;
    begin
      awaddr = addr;
      awsize = 3'd2;
      awvalid = 1'b1;
      wvalid = 1'b0;
      bready = 1'b0;
      #1;
      tb_check1("split awready", awready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      wdata = {{(`XLEN-32){1'b0}}, data} << {addr[2:0], 3'b000};
      wstrb = {{(`STRB_W-4){1'b0}}, 4'hf} << addr[2:0];
      wvalid = 1'b1;
      #1;
      tb_check1("split wready", wready, 1'b1);
      `TB_TICK(clk);
      wvalid = 1'b0;
      #1;
      tb_check1("split bvalid", bvalid, 1'b1);
      bready = 1'b1;
      `TB_TICK(clk);
      bready = 1'b0;
    end
  endtask

  task automatic axi_write_double;
    input [`XLEN-1:0] addr;
    input [63:0] data;
    input [`STRB_W-1:0] strb;
    begin
      awaddr = addr;
      awsize = 3'd3;
      wdata = data;
      wstrb = strb;
      awvalid = 1'b1;
      wvalid = 1'b1;
      bready = 1'b0;
      #1;
      tb_check1("write64 awready", awready, 1'b1);
      tb_check1("write64 wready", wready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      wvalid = 1'b0;
      #1;
      tb_check1("write64 bvalid", bvalid, 1'b1);
      bready = 1'b1;
      `TB_TICK(clk);
      bready = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    tb_check1("external irq reset low", external_irq, 1'b0);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_0004, 32'h0);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_1000, 32'h0);

    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_0000, 32'hffff_ffff,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_0000, 32'h0);
    tb_check32("priority bits1 source0 hard zero", rdata_w1[31:0], 32'h0);
    tb_check32("priority bits32 source0 hard zero", rdata_w32[31:0], 32'h0);

    // T4D: priority/threshold are 32-bit WARL MMIO fields backed by the
    // platform's three implemented low bits.  High writes read zero, and a
    // high-byte-only strobe must preserve the implemented value.
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_000c, 32'hffff_fffd,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_000c, 32'h5);
    tb_check32("priority bits1 WARL truncate", rdata_w1[63:32], 32'h1);
    tb_check32("priority bits32 full readback", rdata_w32[63:32], 32'hffff_fffd);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_000c, 32'ha500_0000,
                   {{(`STRB_W-4){1'b0}}, 4'h8});
    tb_check32("priority bits32 high strobe internal",
               dut_w32.priority_q[3], 32'ha5ff_fffd);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_000c, 32'h5);
    tb_check32("priority bits1 high strobe preserve", rdata_w1[63:32], 32'h1);
    tb_check32("priority bits32 high strobe merge", rdata_w32[63:32], 32'ha5ff_fffd);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_0000, 32'hffff_fffc,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_0000, 32'h4);
    tb_check32("threshold bits1 WARL truncate", rdata_w1[31:0], 32'h0);
    tb_check32("threshold bits32 full readback", rdata_w32[31:0], 32'hffff_fffc);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_0000, 32'h5a00_0000,
                   {{(`STRB_W-4){1'b0}}, 4'h8});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_0000, 32'h4);
    tb_check32("threshold bits1 high strobe preserve", rdata_w1[31:0], 32'h0);
    tb_check32("threshold bits32 high strobe merge", rdata_w32[31:0], 32'h5aff_fffc);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1000, 32'hffff_ffff,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1000, 32'h7);
    tb_check32("S threshold bits1 WARL truncate", rdata_w1[31:0], 32'h1);
    tb_check32("S threshold bits32 full readback", rdata_w32[31:0], 32'hffff_ffff);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_000c, 32'h0,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_0000, 32'h0,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1000, 32'h0,
                   {{(`STRB_W-4){1'b0}}, 4'hf});

    axi_write_double(`NPC_AXI_PLIC_BASE + 64'h0000_0000,
                     64'h0000_0005_0000_0000, 8'hf0);
    axi_read_double(`NPC_AXI_PLIC_BASE + 64'h0000_0000, 32'h0, 32'h5);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_0004, 32'h3, {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_2080, 32'h2, {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1000, 32'h0, {{(`STRB_W-4){1'b0}}, 4'hf});
    tb_check1("external irq waits for pending", external_irq, 1'b0);

    source_irq[1] = 1'b1;
    `TB_TICK(clk);
    source_irq[1] = 1'b0;
    // P5 刀P:external_irq_o 出口寄存一拍——pending 入队拍输出仍为旧值,下一拍才可见。
    // 本检查在旧组合直通实现下必失败(负测试证据),不可删/不可弱化。
    tb_check1("external irq registered holds low one beat", external_irq, 1'b0);
    `TB_TICK(clk);
    tb_check1("external irq set by source", external_irq, 1'b1);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_1000, 32'h2);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1);
    tb_check1("claim clears irq", external_irq, 1'b0);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_1000, 32'h0);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1, {{(`STRB_W-4){1'b0}}, 4'hf});

    source_irq[1] = 1'b1;
    `TB_TICK(clk);
    `TB_TICK(clk); // P5 刀P:出口寄存一拍,中断可见性 +1 拍
    tb_check1("level source sets irq", external_irq, 1'b1);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1);
    tb_check1("claim enters in-service", external_irq, 1'b0);
    `TB_TICK(clk);
    tb_check1("in-service blocks repending", external_irq, 1'b0);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1, {{(`STRB_W-4){1'b0}}, 4'hf});
    tb_check1("completion re-pends level source", external_irq, 1'b1);
    source_irq[1] = 1'b0;
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1, {{(`STRB_W-4){1'b0}}, 4'hf});

    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_1000, 32'h2, {{(`STRB_W-4){1'b0}}, 4'hf});
    tb_check1("software pending supports mini boot injection", external_irq, 1'b1);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1000, 32'h4, {{(`STRB_W-4){1'b0}}, 4'hf});
    tb_check1("threshold masks irq", external_irq, 1'b0);
    axi_write_split(`NPC_AXI_PLIC_BASE + 64'h0020_1000, 32'h0);
    tb_check1("split threshold write unmasks irq", external_irq, 1'b1);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1);
    tb_check1("final claim clears irq", external_irq, 1'b0);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1, {{(`STRB_W-4){1'b0}}, 4'hf});

    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_0008, 32'h5, {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_2080, 32'h6, {{(`STRB_W-4){1'b0}}, 4'hf});
    source_irq[2] = 1'b1;
    `TB_TICK(clk);
    source_irq[2] = 1'b0;
    `TB_TICK(clk); // P5 刀P:出口寄存一拍,中断可见性 +1 拍
    tb_check1("source2 irq set", external_irq, 1'b1);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_1000, 32'h4);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h2);
    tb_check1("source2 claim clears irq", external_irq, 1'b0);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h2, {{(`STRB_W-4){1'b0}}, 4'hf});

    source_irq[1] = 1'b1;
    source_irq[2] = 1'b1;
    `TB_TICK(clk);
    source_irq = 32'h0;
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h2);
    tb_check1("source1 remains pending after higher priority source2", external_irq, 1'b1);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h2, {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1, {{(`STRB_W-4){1'b0}}, 4'hf});
    tb_check1("all multi-source claims complete", external_irq, 1'b0);

    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_0004, 32'h6,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_0008, 32'h6,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    source_irq[1] = 1'b1;
    source_irq[2] = 1'b1;
    `TB_TICK(clk);
    source_irq = 32'h0;
    `TB_TICK(clk);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h2);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h2,
                   {{(`STRB_W-4){1'b0}}, 4'hf});

    // Claim source1 and complete an already in-service source2 on the same
    // edge.  Completion is the later state update only for its own ID; the new
    // claim must still enter service without adding an AXI response cycle.
    source_irq[2] = 1'b1;
    `TB_TICK(clk);
    source_irq[2] = 1'b0;
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h2);
    source_irq[1] = 1'b1;
    `TB_TICK(clk);
    source_irq[1] = 1'b0;
    araddr = `NPC_AXI_PLIC_BASE + 64'h0020_1004;
    arsize = 3'd2;
    arvalid = 1'b1;
    rready = 1'b0;
    awaddr = `NPC_AXI_PLIC_BASE + 64'h0020_1004;
    awsize = 3'd2;
    awvalid = 1'b1;
    wdata = 64'h0000_0002_0000_0000;
    wstrb = 8'hf0;
    wvalid = 1'b1;
    bready = 1'b0;
    #1;
    tb_check1("same-cycle claim arready", arready, 1'b1);
    tb_check1("same-cycle complete awready", awready, 1'b1);
    tb_check1("same-cycle complete wready", wready, 1'b1);
    `TB_TICK(clk);
    arvalid = 1'b0;
    awvalid = 1'b0;
    wvalid = 1'b0;
    #1;
    tb_check1("same-cycle claim response", rvalid, 1'b1);
    tb_check32("same-cycle claim ID", rdata[63:32], 32'h1);
    tb_check1("same-cycle complete response", bvalid, 1'b1);
    tb_check1("same-cycle claimed source in service", dut.in_service_q[1], 1'b1);
    tb_check1("same-cycle completed source leaves service", dut.in_service_q[2], 1'b0);
    rready = 1'b1;
    bready = 1'b1;
    `TB_TICK(clk);
    rready = 1'b0;
    bready = 1'b0;
    araddr = {`XLEN{1'b0}};
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h1,
                   {{(`STRB_W-4){1'b0}}, 4'hf});
    $display("[T4D-PLIC-PRIORITY-WARL] high=zero wstrb=preserve tie=low-id params=1,3,32 source0=zero same-cycle=claim+complete");

    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_0024, 32'h7, {{(`STRB_W-4){1'b0}}, 4'hf});
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_2080, 32'h0000_0200,
                   {{(`STRB_W-4){1'b0}}, 4'h2});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_2080, 32'h0000_0206);
    source_irq[9] = 1'b1;
    `TB_TICK(clk);
    source_irq[9] = 1'b0;
    `TB_TICK(clk); // P5 刀P:出口寄存一拍,中断可见性 +1 拍
    tb_check1("byte1 enable strobe accepts source9", external_irq, 1'b1);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_1000, 32'h0000_0200);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h9);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h9, {{(`STRB_W-4){1'b0}}, 4'hf});
    tb_check1("source9 byte1 enable completes", external_irq, 1'b0);

    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0000_1000, 32'h0000_0200,
                   {{(`STRB_W-4){1'b0}}, 4'h2});
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0000_1000, 32'h0000_0200);
    tb_check1("byte1 pending strobe injects source9", external_irq, 1'b1);
    axi_read_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h9);
    axi_write_word(`NPC_AXI_PLIC_BASE + 64'h0020_1004, 32'h9, {{(`STRB_W-4){1'b0}}, 4'hf});
    tb_check1("byte1 software pending completes", external_irq, 1'b0);

    tb_finish("tb_axi_plic");
  end
endmodule
