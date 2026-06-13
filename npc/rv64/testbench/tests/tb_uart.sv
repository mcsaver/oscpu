module tb_uart;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg read_valid;
  reg [11:0] read_addr;
  wire [31:0] read_data;
  reg write_valid;
  reg [11:0] write_addr;
  reg [31:0] write_data;
  reg [3:0] write_strb;
  reg rx_valid;
  reg [7:0] rx_data;
  wire rx_ready;
  wire tx_valid;
  wire [7:0] tx_data;
  wire access_valid;
  wire access_write;
  wire irq;

  reg read_valid64;
  reg [11:0] read_addr64;
  wire [63:0] read_data64;
  reg write_valid64;
  reg [11:0] write_addr64;
  reg [63:0] write_data64;
  reg [7:0] write_strb64;
  reg rx_valid64;
  reg [7:0] rx_data64;
  wire rx_ready64;
  wire tx_valid64;
  wire [7:0] tx_data64;
  wire access_valid64;
  wire access_write64;
  wire irq64;

  Uart dut (
    .clk(clk),
    .rst(rst),
    .reg_read_valid_i(read_valid),
    .reg_read_addr_i(read_addr),
    .reg_read_data_o(read_data),
    .reg_write_valid_i(write_valid),
    .reg_write_addr_i(write_addr),
    .reg_write_data_i(write_data),
    .reg_write_strb_i(write_strb),
    .rx_valid_i(rx_valid),
    .rx_data_i(rx_data),
    .rx_ready_o(rx_ready),
    .tx_valid_o(tx_valid),
    .tx_data_o(tx_data),
    .access_valid_o(access_valid),
    .access_write_o(access_write),
    .irq_o(irq)
  );

  Uart #(
    .DATA_W(64),
    .STRB_W(8)
  ) dut64 (
    .clk(clk),
    .rst(rst),
    .reg_read_valid_i(read_valid64),
    .reg_read_addr_i(read_addr64),
    .reg_read_data_o(read_data64),
    .reg_write_valid_i(write_valid64),
    .reg_write_addr_i(write_addr64),
    .reg_write_data_i(write_data64),
    .reg_write_strb_i(write_strb64),
    .rx_valid_i(rx_valid64),
    .rx_data_i(rx_data64),
    .rx_ready_o(rx_ready64),
    .tx_valid_o(tx_valid64),
    .tx_data_o(tx_data64),
    .access_valid_o(access_valid64),
    .access_write_o(access_write64),
    .irq_o(irq64)
  );

  task automatic tb_check64_local;
    input [1023:0] what;
    input [63:0] got;
    input [63:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      read_valid = 1'b0;
      read_addr = 12'h000;
      write_valid = 1'b0;
      write_addr = 12'h000;
      write_data = 32'h0;
      write_strb = 4'h0;
      rx_valid = 1'b0;
      rx_data = 8'h00;
      read_valid64 = 1'b0;
      read_addr64 = 12'h000;
      write_valid64 = 1'b0;
      write_addr64 = 12'h000;
      write_data64 = 64'h0;
      write_strb64 = 8'h0;
      rx_valid64 = 1'b0;
      rx_data64 = 8'h00;
      `TB_TICK(clk);
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    read_valid = 1'b1;
    read_addr = 12'h000;
    #1;
    tb_check32("uart low word reset", read_data, 32'h0001_0000);

    read_addr = 12'h004;
    write_valid = 1'b0;
    write_addr = 12'h000;
    write_data = 32'h0;
    write_strb = 4'h0;
    #1;
    tb_check32("status read", read_data, 32'h0000_6001);
    tb_check1("read access", access_valid, 1'b1);
    tb_check1("read access write", access_write, 1'b0);
    tb_check1("reset irq", irq, 1'b0);

    read_valid = 1'b0;
    write_valid = 1'b1;
    write_addr = 12'h000;
    write_data = 32'h0000_0055;
    write_strb = 4'b0001;
    #1;
    tb_check1("tx valid", tx_valid, 1'b1);
    tb_check32("tx data", {24'b0, tx_data}, 32'h0000_0055);
    tb_check1("write access", access_valid, 1'b1);
    tb_check1("write access write", access_write, 1'b1);

    write_data = 32'h0000_0200;
    write_strb = 4'b0010;
    #1;
    tb_check1("ier write no tx", tx_valid, 1'b0);
    `TB_TICK(clk);
    write_valid = 1'b0;
    #1;
    tb_check1("thre irq after ier", irq, 1'b1);

    read_valid = 1'b1;
    read_addr = 12'h000;
    #1;
    tb_check32("iir reports thre", read_data, 32'h0002_0200);
    `TB_TICK(clk);
    read_valid = 1'b0;
    #1;
    tb_check1("iir read keeps level irq", irq, 1'b1);

    write_valid = 1'b1;
    write_data = 32'h0000_0000;
    write_strb = 4'b0010;
    `TB_TICK(clk);
    write_valid = 1'b0;
    #1;
    tb_check1("ier disable drops irq", irq, 1'b0);

    tb_check1("rx ready when empty", rx_ready, 1'b1);
    rx_valid = 1'b1;
    rx_data = 8'h5a;
    #1;
    tb_check1("rx accepts first byte", rx_ready, 1'b1);
    `TB_TICK(clk);
    rx_valid = 1'b0;
    rx_data = 8'h00;
    #1;
    tb_check1("rx holding byte is not ready", rx_ready, 1'b0);
    tb_check1("rx data without ier has no irq", irq, 1'b0);

    read_valid = 1'b1;
    read_addr = 12'h004;
    #1;
    tb_check32("rx lsr reports data ready", read_data, 32'h0000_6101);
    tb_check1("lsr read keeps rx byte", rx_ready, 1'b0);
    read_addr = 12'h000;
    #1;
    tb_check32("rx rbr read returns byte", read_data, 32'h0001_005a);
    tb_check1("rbr read opens rx ready", rx_ready, 1'b1);
    `TB_TICK(clk);
    read_valid = 1'b0;
    #1;
    tb_check1("rx ready after consume", rx_ready, 1'b1);
    read_valid = 1'b1;
    read_addr = 12'h004;
    #1;
    tb_check32("rx lsr clears after consume", read_data, 32'h0000_6001);
    read_valid = 1'b0;

    write_valid = 1'b1;
    write_addr = 12'h000;
    write_data = 32'h0000_0100;
    write_strb = 4'b0010;
    `TB_TICK(clk);
    write_valid = 1'b0;
    rx_valid = 1'b1;
    rx_data = 8'h5b;
    `TB_TICK(clk);
    rx_valid = 1'b0;
    rx_data = 8'h00;
    #1;
    tb_check1("rx ier raises irq", irq, 1'b1);
    read_valid = 1'b1;
    read_addr = 12'h000;
    #1;
    tb_check32("rx iir reports rda", read_data, 32'h0004_015b);
    `TB_TICK(clk);
    read_valid = 1'b0;
    #1;
    tb_check1("rx irq clears after rbr", irq, 1'b0);

    write_valid = 1'b1;
    write_data = 32'h0001_0000;
    write_strb = 4'b0100;
    `TB_TICK(clk);
    write_data = 32'h0000_0200;
    write_strb = 4'b0010;
    `TB_TICK(clk);
    write_valid = 1'b0;
    read_valid = 1'b1;
    read_addr = 12'h000;
    #1;
    tb_check32("iir reports fifo and thre", read_data, 32'h00c2_0200);
    read_valid = 1'b0;

    write_valid = 1'b1;
    write_data = 32'h0000_0000;
    write_strb = 4'b0010;
    `TB_TICK(clk);
    write_valid = 1'b0;

    write_addr = 12'h004;
    write_data = 32'h0000_0043;
    write_strb = 4'b0001;
    write_valid = 1'b1;
    #1;
    tb_check1("status write no tx", tx_valid, 1'b0);

    write_addr = 12'h000;
    write_strb = 4'b0010;
    #1;
    tb_check1("non lane0 no tx", tx_valid, 1'b0);

    write_data = 32'h8000_0000;
    write_strb = 4'b1000;
    `TB_TICK(clk);
    write_data = 32'h0000_0034;
    write_strb = 4'b0001;
    #1;
    tb_check1("dlab dll write no tx", tx_valid, 1'b0);
    `TB_TICK(clk);
    write_data = 32'h0000_1200;
    write_strb = 4'b0010;
    #1;
    tb_check1("dlab dlm write no tx", tx_valid, 1'b0);
    `TB_TICK(clk);
    read_valid = 1'b1;
    read_addr = 12'h000;
    write_valid = 1'b0;
    #1;
    tb_check32("dlab exposes divisor", read_data, 32'h80c1_1234);
    read_valid = 1'b0;
    write_valid = 1'b1;
    write_data = 32'h0000_0000;
    write_strb = 4'b1000;
    `TB_TICK(clk);
    write_data = 32'h0000_0044;
    write_strb = 4'b0001;
    #1;
    tb_check1("thr write after dlab tx", tx_valid, 1'b1);
    tb_check32("thr write after dlab data", {24'b0, tx_data}, 32'h0000_0044);

    write_valid = 1'b0;
    read_valid = 1'b0;

    read_valid64 = 1'b1;
    read_addr64 = 12'h000;
    #1;
    tb_check64_local("uart64 low window reset", read_data64,
                     64'h0000_6001_0001_0000);
    tb_check1("uart64 read access", access_valid64, 1'b1);
    tb_check1("uart64 read access write", access_write64, 1'b0);

    read_addr64 = 12'h004;
    #1;
    tb_check64_local("uart64 status window reset", read_data64,
                     64'h0000_0000_0000_6001);
    read_valid64 = 1'b0;

    tb_check1("uart64 rx ready when empty", rx_ready64, 1'b1);
    rx_valid64 = 1'b1;
    rx_data64 = 8'ha5;
    `TB_TICK(clk);
    rx_valid64 = 1'b0;
    rx_data64 = 8'h00;
    read_valid64 = 1'b1;
    read_addr64 = 12'h000;
    #1;
    tb_check64_local("uart64 rx rbr window", read_data64,
                     64'h0000_6101_0001_00a5);
    `TB_TICK(clk);
    read_valid64 = 1'b0;

    write_valid64 = 1'b1;
    write_addr64 = 12'h000;
    write_data64 = 64'h0000_0000_0000_0200;
    write_strb64 = 8'b0000_0010;
    #1;
    tb_check1("uart64 ier write no tx", tx_valid64, 1'b0);
    tb_check1("uart64 write access", access_valid64, 1'b1);
    tb_check1("uart64 write access write", access_write64, 1'b1);
    `TB_TICK(clk);
    write_valid64 = 1'b0;
    #1;
    tb_check1("uart64 irq after ier", irq64, 1'b1);

    read_valid64 = 1'b1;
    read_addr64 = 12'h000;
    #1;
    tb_check64_local("uart64 iir reports thre", read_data64,
                     64'h0000_6001_0002_0200);
    read_valid64 = 1'b0;

    write_valid64 = 1'b1;
    write_data64 = 64'h0000_0000_8000_0000;
    write_strb64 = 8'b0000_1000;
    `TB_TICK(clk);
    write_data64 = 64'h0000_0000_0000_1234;
    write_strb64 = 8'b0000_0011;
    #1;
    tb_check1("uart64 dlab divisor no tx", tx_valid64, 1'b0);
    `TB_TICK(clk);
    write_valid64 = 1'b0;

    read_valid64 = 1'b1;
    read_addr64 = 12'h000;
    #1;
    tb_check64_local("uart64 dlab exposes divisor", read_data64,
                     64'h0000_6001_8002_1234);
    read_valid64 = 1'b0;

    tb_finish("tb_uart");
  end
endmodule
