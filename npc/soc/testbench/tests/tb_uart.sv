module tb_uart;
  `include "tb_common.svh"

  reg read_valid;
  reg [11:0] read_addr;
  wire [31:0] read_data;
  reg write_valid;
  reg [11:0] write_addr;
  reg [31:0] write_data;
  reg [3:0] write_strb;
  wire tx_valid;
  wire [7:0] tx_data;
  wire access_valid;
  wire access_write;

  Uart dut (
    .reg_read_valid_i(read_valid),
    .reg_read_addr_i(read_addr),
    .reg_read_data_o(read_data),
    .reg_write_valid_i(write_valid),
    .reg_write_addr_i(write_addr),
    .reg_write_data_i(write_data),
    .reg_write_strb_i(write_strb),
    .tx_valid_o(tx_valid),
    .tx_data_o(tx_data),
    .access_valid_o(access_valid),
    .access_write_o(access_write)
  );

  initial begin
    tb_errors = 0;

    read_valid = 1'b1;
    read_addr = 12'h004;
    write_valid = 1'b0;
    write_addr = 12'h000;
    write_data = 32'h0;
    write_strb = 4'h0;
    #1;
    tb_check32("status read", read_data, 32'h0000_6001);
    tb_check1("read access", access_valid, 1'b1);
    tb_check1("read access write", access_write, 1'b0);

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

    write_addr = 12'h004;
    #1;
    tb_check1("status write no tx", tx_valid, 1'b0);

    write_addr = 12'h000;
    write_strb = 4'b0010;
    #1;
    tb_check1("non lane0 no tx", tx_valid, 1'b0);

    tb_finish("tb_uart");
  end
endmodule
