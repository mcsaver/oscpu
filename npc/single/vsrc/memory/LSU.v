`include "define.v"

module LSU (
  input [`XLEN-1:0] eff_addr_i,
  input [`XLEN-1:0] store_data_i,
  input [1:0] mem_size_i,
  input mem_unsigned_i,
  input [`XLEN-1:0] mem_rdata_i,
  output [`XLEN-1:0] mem_addr_o,
  output [`XLEN-1:0] mem_wdata_o,
  output [3:0] mem_wstrb_o,
  output [`XLEN-1:0] load_data_o,
  output misaligned_o
);

  wire [4:0] byte_shift_w;
  wire [1:0] load_size_w;
  wire load_unsigned_w;

  LSUControl u_lsu_control (
    .addr_low_i(eff_addr_i[1:0]),
    .mem_size_i(mem_size_i),
    .mem_unsigned_i(mem_unsigned_i),
    .byte_shift_o(byte_shift_w),
    .mem_wstrb_o(mem_wstrb_o),
    .load_size_o(load_size_w),
    .load_unsigned_o(load_unsigned_w),
    .misaligned_o(misaligned_o)
  );

  LSUDataPath u_lsu_datapath (
    .eff_addr_i(eff_addr_i),
    .store_data_i(store_data_i),
    .byte_shift_i(byte_shift_w),
    .load_size_i(load_size_w),
    .load_unsigned_i(load_unsigned_w),
    .mem_rdata_i(mem_rdata_i),
    .mem_addr_o(mem_addr_o),
    .mem_wdata_o(mem_wdata_o),
    .load_data_o(load_data_o)
  );

endmodule
