`include "define.v"

module tb_axi_plic;
  `include "tb_common.svh"

  reg clk;
  reg rst;

  reg arvalid;
  wire arready;
  reg [`XLEN-1:0] araddr;
  wire rvalid;
  reg rready;
  wire [`XLEN-1:0] rdata;
  wire [1:0] rresp;

  reg awvalid;
  wire awready;
  reg [`XLEN-1:0] awaddr;
  reg wvalid;
  wire wready;
  reg [`XLEN-1:0] wdata;
  reg [`STRB_W-1:0] wstrb;
  wire bvalid;
  reg bready;
  wire [1:0] bresp;

  reg [31:0] source_irq;
  wire external_irq;

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
    .s_axi_rvalid_o(rvalid),
    .s_axi_rready_i(rready),
    .s_axi_rdata_o(rdata),
    .s_axi_rresp_o(rresp),
    .s_axi_awvalid_i(awvalid),
    .s_axi_awready_o(awready),
    .s_axi_awaddr_i(awaddr),
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

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      arvalid = 1'b0;
      araddr = {`XLEN{1'b0}};
      rready = 1'b0;
      awvalid = 1'b0;
      awaddr = {`XLEN{1'b0}};
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
    begin
      araddr = addr;
      arvalid = 1'b1;
      rready = 1'b0;
      #1;
      tb_check1("read arready", arready, 1'b1);
      `TB_TICK(clk);
      arvalid = 1'b0;
      #1;
      tb_check1("read rvalid", rvalid, 1'b1);
      tb_check32("read data low", rdata[31:0], exp_data);
      tb_check32("read data high", rdata[`XLEN-1:32], 32'h0);
      tb_check32("read resp", {30'b0, rresp}, 32'h0);
      rready = 1'b1;
      `TB_TICK(clk);
      rready = 1'b0;
    end
  endtask

  task automatic axi_read_double;
    input [`XLEN-1:0] addr;
    input [31:0] exp_low;
    input [31:0] exp_high;
    begin
      araddr = addr;
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
    end
  endtask

  task automatic axi_write_word;
    input [`XLEN-1:0] addr;
    input [31:0] data;
    input [`STRB_W-1:0] strb;
    begin
      awaddr = addr;
      wdata = {{(`XLEN-32){1'b0}}, data};
      wstrb = strb;
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
      awvalid = 1'b1;
      wvalid = 1'b0;
      bready = 1'b0;
      #1;
      tb_check1("split awready", awready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      wdata = {{(`XLEN-32){1'b0}}, data};
      wstrb = {{(`STRB_W-4){1'b0}}, 4'hf};
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
