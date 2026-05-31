`include "define.v"

module tb_ooo_mem_axi_bridge;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush;

  reg [1:0] priv_mode;
  reg [`XLEN-1:0] mstatus;
  reg [`XLEN-1:0] satp;

  reg mem0_req_valid;
  wire mem0_req_ready;
  reg mem0_req_write;
  reg [`XLEN-1:0] mem0_req_addr;
  reg [`XLEN-1:0] mem0_req_wdata;
  reg [`STRB_W-1:0] mem0_req_wstrb;
  wire mem0_rsp_valid;
  reg mem0_rsp_ready;
  wire [`XLEN-1:0] mem0_rsp_rdata;
  wire mem0_rsp_error;
  wire mem0_rsp_page_fault;

  reg mem1_req_valid;
  wire mem1_req_ready;
  reg mem1_req_write;
  reg [`XLEN-1:0] mem1_req_addr;
  reg [`XLEN-1:0] mem1_req_wdata;
  reg [`STRB_W-1:0] mem1_req_wstrb;
  wire mem1_rsp_valid;
  reg mem1_rsp_ready;
  wire [`XLEN-1:0] mem1_rsp_rdata;
  wire mem1_rsp_error;
  wire mem1_rsp_page_fault;

  wire lsu_axi_arvalid;
  reg lsu_axi_arready;
  wire [`XLEN-1:0] lsu_axi_araddr;
  reg lsu_axi_rvalid;
  wire lsu_axi_rready;
  reg [`XLEN-1:0] lsu_axi_rdata;
  reg [1:0] lsu_axi_rresp;
  wire lsu_axi_awvalid;
  reg lsu_axi_awready;
  wire [`XLEN-1:0] lsu_axi_awaddr;
  wire lsu_axi_wvalid;
  reg lsu_axi_wready;
  wire [`XLEN-1:0] lsu_axi_wdata;
  wire [`STRB_W-1:0] lsu_axi_wstrb;
  reg lsu_axi_bvalid;
  wire lsu_axi_bready;
  reg [1:0] lsu_axi_bresp;

  OooMemAxiBridge dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .priv_mode_i(priv_mode),
    .mstatus_i(mstatus),
    .satp_i(satp),
    .mem0_req_valid_i(mem0_req_valid),
    .mem0_req_ready_o(mem0_req_ready),
    .mem0_req_write_i(mem0_req_write),
    .mem0_req_addr_i(mem0_req_addr),
    .mem0_req_wdata_i(mem0_req_wdata),
    .mem0_req_wstrb_i(mem0_req_wstrb),
    .mem0_rsp_valid_o(mem0_rsp_valid),
    .mem0_rsp_ready_i(mem0_rsp_ready),
    .mem0_rsp_rdata_o(mem0_rsp_rdata),
    .mem0_rsp_error_o(mem0_rsp_error),
    .mem0_rsp_page_fault_o(mem0_rsp_page_fault),
    .mem1_req_valid_i(mem1_req_valid),
    .mem1_req_ready_o(mem1_req_ready),
    .mem1_req_write_i(mem1_req_write),
    .mem1_req_addr_i(mem1_req_addr),
    .mem1_req_wdata_i(mem1_req_wdata),
    .mem1_req_wstrb_i(mem1_req_wstrb),
    .mem1_rsp_valid_o(mem1_rsp_valid),
    .mem1_rsp_ready_i(mem1_rsp_ready),
    .mem1_rsp_rdata_o(mem1_rsp_rdata),
    .mem1_rsp_error_o(mem1_rsp_error),
    .mem1_rsp_page_fault_o(mem1_rsp_page_fault),
    .lsu_axi_arvalid_o(lsu_axi_arvalid),
    .lsu_axi_arready_i(lsu_axi_arready),
    .lsu_axi_araddr_o(lsu_axi_araddr),
    .lsu_axi_rvalid_i(lsu_axi_rvalid),
    .lsu_axi_rready_o(lsu_axi_rready),
    .lsu_axi_rdata_i(lsu_axi_rdata),
    .lsu_axi_rresp_i(lsu_axi_rresp),
    .lsu_axi_awvalid_o(lsu_axi_awvalid),
    .lsu_axi_awready_i(lsu_axi_awready),
    .lsu_axi_awaddr_o(lsu_axi_awaddr),
    .lsu_axi_wvalid_o(lsu_axi_wvalid),
    .lsu_axi_wready_i(lsu_axi_wready),
    .lsu_axi_wdata_o(lsu_axi_wdata),
    .lsu_axi_wstrb_o(lsu_axi_wstrb),
    .lsu_axi_bvalid_i(lsu_axi_bvalid),
    .lsu_axi_bready_o(lsu_axi_bready),
    .lsu_axi_bresp_i(lsu_axi_bresp)
  );

  task automatic tb_check64;
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

  task automatic tick;
    begin
      `TB_TICK(clk)
    end
  endtask

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      priv_mode = `PRIV_M;
      mstatus = {`XLEN{1'b0}};
      satp = {`XLEN{1'b0}};
      mem0_req_valid = 1'b0;
      mem0_req_write = 1'b0;
      mem0_req_addr = {`XLEN{1'b0}};
      mem0_req_wdata = {`XLEN{1'b0}};
      mem0_req_wstrb = {`STRB_W{1'b0}};
      mem0_rsp_ready = 1'b0;
      mem1_req_valid = 1'b0;
      mem1_req_write = 1'b0;
      mem1_req_addr = {`XLEN{1'b0}};
      mem1_req_wdata = {`XLEN{1'b0}};
      mem1_req_wstrb = {`STRB_W{1'b0}};
      mem1_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b0;
      lsu_axi_rdata = {`XLEN{1'b0}};
      lsu_axi_rresp = 2'b00;
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      lsu_axi_bvalid = 1'b0;
      lsu_axi_bresp = 2'b00;
    end
  endtask

  task automatic issue_mem0_read;
    input [`XLEN-1:0] addr;
    begin
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = addr;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("mem0 read request ready", mem0_req_ready, 1'b1);
      tb_check1("mem0 read issues AR", lsu_axi_arvalid, 1'b1);
      tb_check64("mem0 read AR address", lsu_axi_araddr, addr);
      tick();
      mem0_req_valid = 1'b0;
      lsu_axi_arready = 1'b0;
    end
  endtask

  task automatic held_response_flush_drop;
    begin
      issue_mem0_read(64'h0000_0000_8000_1000);
      #1;
      tb_check1("mem0 read waits for R", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1122_3344_5566_7788;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("mem0 response is held", mem0_rsp_valid, 1'b1);
      tb_check64("mem0 held response data", mem0_rsp_rdata,
                 64'h1122_3344_5566_7788);

      flush = 1'b1;
      #1;
      tb_check1("flush hides held response", mem0_rsp_valid, 1'b0);
      tb_check1("flush blocks new request", mem0_req_ready, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("held response dropped", mem0_rsp_valid, 1'b0);
      tb_check1("bridge accepts request after held drop", mem0_req_ready, 1'b1);

      mem1_req_valid = 1'b1;
      mem1_req_write = 1'b0;
      mem1_req_addr = 64'h0000_0000_8000_2000;
      mem1_rsp_ready = 1'b1;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("mem1 request accepted after drop", mem1_req_ready, 1'b1);
      tick();
      mem1_req_valid = 1'b0;
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h8877_6655_4433_2211;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("mem1 response valid after drop", mem1_rsp_valid, 1'b1);
      tb_check64("mem1 response data after drop", mem1_rsp_rdata,
                 64'h8877_6655_4433_2211);
      tick();
      mem1_rsp_ready = 1'b0;
      #1;
      tb_check1("mem1 response consumed", mem1_rsp_valid, 1'b0);
    end
  endtask

  task automatic inflight_read_flush_drain;
    begin
      issue_mem0_read(64'h0000_0000_8000_3000);
      flush = 1'b1;
      #1;
      tb_check1("flush keeps R drain ready", lsu_axi_rready, 1'b1);
      tb_check1("flush suppresses inflight response", mem0_rsp_valid, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("read drain still waits for R", lsu_axi_rready, 1'b1);
      tb_check1("read drain blocks new request", mem0_req_ready, 1'b0);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'haaaa_bbbb_cccc_dddd;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("drained read has no CPU response", mem0_rsp_valid, 1'b0);
      tb_check1("bridge idle after read drain", mem0_req_ready, 1'b1);
    end
  endtask

  task automatic partial_write_flush_drain;
    begin
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_4000;
      mem0_req_wdata = 64'h0102_0304_0506_0708;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("write request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;

      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("write issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("write issues W", lsu_axi_wvalid, 1'b1);
      tb_check64("write AW address", lsu_axi_awaddr,
                 64'h0000_0000_8000_4000);
      tick();
      lsu_axi_awready = 1'b0;

      flush = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("flush drains remaining W", lsu_axi_wvalid, 1'b1);
      tb_check64("flush drain W data", lsu_axi_wdata,
                 64'h0102_0304_0506_0708);
      tick();
      flush = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("write drain waits for B", lsu_axi_bready, 1'b1);
      tb_check1("write drain suppresses response", mem0_rsp_valid, 1'b0);

      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("bridge idle after write drain", mem0_req_ready, 1'b1);
      tb_check1("write drain never exposes response", mem0_rsp_valid, 1'b0);
    end
  endtask

  wire unused_outputs =
      mem0_rsp_error | mem0_rsp_page_fault | mem1_rsp_error |
      mem1_rsp_page_fault | (|lsu_axi_wstrb);

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    #1;

    held_response_flush_drop();
    inflight_read_flush_drain();
    partial_write_flush_drain();

    tb_check1("unused outputs settle", unused_outputs, unused_outputs);
    tb_finish("tb_ooo_mem_axi_bridge");
  end

endmodule
