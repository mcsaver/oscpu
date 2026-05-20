`include "define.v"

module tb_cache_control;
  `include "tb_common.svh"

  reg ex_fire;
  reg fence_i;
  reg exception;
  reg [`XLEN-1:0] seq_pc;
  wire flush_valid;
  wire [`XLEN-1:0] flush_redirect_pc;

  CacheControl dut (
    .ex_fire_i(ex_fire),
    .fence_i_i(fence_i),
    .exception_i(exception),
    .seq_pc_i(seq_pc),
    .flush_valid_o(flush_valid),
    .flush_redirect_pc_o(flush_redirect_pc)
  );

  initial begin
    tb_errors = 0;
    ex_fire = 1'b0; fence_i = 1'b1; exception = 1'b0; seq_pc = 32'h8000_0010; #1;
    tb_check1("no fire no flush", flush_valid, 1'b0);
    ex_fire = 1'b1; #1;
    tb_check1("fence flush", flush_valid, 1'b1);
    tb_check32("redirect pc", flush_redirect_pc, 32'h8000_0010);
    exception = 1'b1; #1;
    tb_check1("exception blocks fence", flush_valid, 1'b0);
    exception = 1'b0; fence_i = 1'b0; #1;
    tb_check1("non fence no flush", flush_valid, 1'b0);

    tb_finish("tb_cache_control");
  end
endmodule
