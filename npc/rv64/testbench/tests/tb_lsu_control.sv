`include "define.v"

module tb_lsu_control;
  `include "tb_common.svh"

  reg [`XLEN_BYTE_W-1:0] addr_low;
  reg [1:0] mem_size;
  reg mem_unsigned;
  wire [`XLEN_BIT_SHIFT-1:0] byte_shift;
  wire [`STRB_W-1:0] mem_wstrb;
  wire [1:0] load_size;
  wire load_unsigned;
  wire misaligned;

  LSUControl dut (
    .addr_low_i(addr_low),
    .mem_size_i(mem_size),
    .mem_unsigned_i(mem_unsigned),
    .byte_shift_o(byte_shift),
    .mem_wstrb_o(mem_wstrb),
    .load_size_o(load_size),
    .load_unsigned_o(load_unsigned),
    .misaligned_o(misaligned)
  );

  initial begin
    tb_errors = 0;

    addr_low = 3'd2; mem_size = `MEM_SIZE_BYTE; mem_unsigned = 1'b1; #1;
    tb_check32("byte shift", {26'b0, byte_shift}, 32'd0);
    tb_check32("byte wstrb", {24'b0, mem_wstrb}, 32'h0000_0001);
    tb_check1("byte aligned", misaligned, 1'b0);
    tb_check1("unsigned pass", load_unsigned, 1'b1);

    addr_low = 3'd2; mem_size = `MEM_SIZE_HALF; mem_unsigned = 1'b0; #1;
    tb_check32("half wstrb", {24'b0, mem_wstrb}, 32'h0000_0003);
    tb_check1("half aligned", misaligned, 1'b0);

    addr_low = 3'd1; mem_size = `MEM_SIZE_HALF; #1;
    tb_check1("half misaligned", misaligned, 1'b1);

    addr_low = 3'd0; mem_size = `MEM_SIZE_WORD; #1;
    tb_check32("word wstrb", {24'b0, mem_wstrb}, 32'h0000_000f);
    tb_check1("word aligned", misaligned, 1'b0);

    addr_low = 3'd3; mem_size = `MEM_SIZE_WORD; #1;
    tb_check1("word misaligned", misaligned, 1'b1);
    tb_check32("load size pass", {30'b0, load_size}, {30'b0, `MEM_SIZE_WORD});

    tb_finish("tb_lsu_control");
  end
endmodule
