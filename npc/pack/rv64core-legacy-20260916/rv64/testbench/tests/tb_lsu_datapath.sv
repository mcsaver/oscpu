`include "define.v"

module tb_lsu_datapath;
  `include "tb_common.svh"

  reg [`XLEN-1:0] eff_addr;
  reg [`XLEN-1:0] store_data;
  reg [`XLEN_BIT_SHIFT-1:0] byte_shift;
  reg [1:0] load_size;
  reg load_unsigned;
  reg [`XLEN-1:0] mem_rdata;
  wire [`XLEN-1:0] mem_addr;
  wire [`XLEN-1:0] mem_wdata;
  wire [`XLEN-1:0] load_data;

  LSUDataPath dut (
    .eff_addr_i(eff_addr),
    .store_data_i(store_data),
    .byte_shift_i(byte_shift),
    .load_size_i(load_size),
    .load_unsigned_i(load_unsigned),
    .mem_rdata_i(mem_rdata),
    .mem_addr_o(mem_addr),
    .mem_wdata_o(mem_wdata),
    .load_data_o(load_data)
  );

  initial begin
    tb_errors = 0;

    eff_addr = 32'h8000_0002;
    store_data = 32'haabb_ccdd;
    byte_shift = {`XLEN_BIT_SHIFT{1'b0}};
    load_size = `MEM_SIZE_WORD;
    load_unsigned = 1'b0;
    mem_rdata = 32'h8877_6655;
    #1;
    tb_check32("byte addr", mem_addr, 32'h8000_0002);
    tb_check32("store data", mem_wdata, 32'haabb_ccdd);

    byte_shift = {`XLEN_BIT_SHIFT{1'b0}};
    mem_rdata = 32'h0000_0088;
    load_size = `MEM_SIZE_BYTE; load_unsigned = 1'b0; #1;
    tb_check32("signed byte", load_data, 32'hffff_ff88);

    mem_rdata = 32'h0000_8877;
    load_size = `MEM_SIZE_HALF; load_unsigned = 1'b0; #1;
    tb_check32("signed half", load_data, 32'hffff_8877);

    load_size = `MEM_SIZE_HALF; load_unsigned = 1'b1; #1;
    tb_check32("unsigned half", load_data, 32'h0000_8877);

    mem_rdata = 32'h8877_6655;
    load_size = `MEM_SIZE_WORD; #1;
    tb_check32("word", load_data, 32'h8877_6655);

    tb_finish("tb_lsu_datapath");
  end
endmodule
