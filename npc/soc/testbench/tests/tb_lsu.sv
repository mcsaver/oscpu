`include "define.v"

module tb_lsu;
  `include "tb_common.svh"

  reg [`XLEN-1:0] eff_addr;
  reg [`XLEN-1:0] store_data;
  reg [1:0] mem_size;
  reg mem_unsigned;
  reg [`XLEN-1:0] mem_rdata;
  wire [`XLEN-1:0] mem_addr;
  wire [`XLEN-1:0] mem_wdata;
  wire [3:0] mem_wstrb;
  wire [`XLEN-1:0] load_data;
  wire misaligned;

  LSU dut (
    .eff_addr_i(eff_addr),
    .store_data_i(store_data),
    .mem_size_i(mem_size),
    .mem_unsigned_i(mem_unsigned),
    .mem_rdata_i(mem_rdata),
    .mem_addr_o(mem_addr),
    .mem_wdata_o(mem_wdata),
    .mem_wstrb_o(mem_wstrb),
    .load_data_o(load_data),
    .misaligned_o(misaligned)
  );

  initial begin
    tb_errors = 0;

    eff_addr = 32'h8000_0003;
    store_data = 32'h0000_00aa;
    mem_size = `MEM_SIZE_BYTE;
    mem_unsigned = 1'b0;
    mem_rdata = 32'h8000_ff7f;
    #1;
    tb_check32("byte addr", mem_addr, 32'h8000_0000);
    tb_check32("byte wdata", mem_wdata, 32'haa00_0000);
    tb_check32("byte wstrb", {28'b0, mem_wstrb}, 32'h0000_0008);
    tb_check32("byte load signed", load_data, 32'hffff_ff80);
    tb_check1("byte aligned", misaligned, 1'b0);

    eff_addr = 32'h8000_0001;
    mem_size = `MEM_SIZE_HALF;
    #1;
    tb_check1("half misaligned", misaligned, 1'b1);

    eff_addr = 32'h8000_0002;
    mem_size = `MEM_SIZE_HALF;
    mem_unsigned = 1'b1;
    #1;
    tb_check32("half wstrb", {28'b0, mem_wstrb}, 32'h0000_000c);
    tb_check32("half load unsigned", load_data, 32'h0000_8000);

    tb_finish("tb_lsu");
  end
endmodule
