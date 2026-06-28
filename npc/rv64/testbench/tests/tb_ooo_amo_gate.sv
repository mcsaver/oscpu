`include "define.v"

// OooAmoGate 专属 testbench：RV64A AMO 结果（doubleword 路径）几个代表 op。
// inst[31:27] 选 amo 操作。穷举/字宽/符号扩展由 official rv64ua 回归兜底。
module tb_ooo_amo_gate;
  `include "tb_common.svh"

  reg [`INST_W-1:0] inst;
  reg [`XLEN-1:0] load_data, src2;
  reg [1:0] size;
  wire [`XLEN-1:0] old_value, result;

  OooAmoGate dut (
    .inst_i(inst), .load_data_i(load_data), .src2_i(src2), .size_i(size),
    .old_value_o(old_value), .result_o(result)
  );

  task automatic chk;
    input [1023:0] what; input [4:0] op5;
    input [`XLEN-1:0] old_v, b; input [`XLEN-1:0] exp_old, exp_res;
    begin
      inst = {op5, 27'b0}; load_data = old_v; src2 = b; size = 2'b11; // doubleword
      #1;
      if (old_value !== exp_old) begin tb_errors=tb_errors+1;
        $display("[CHECK-FAIL] %0s old got=0x%016x exp=0x%016x", what, old_value, exp_old); end
      if (result !== exp_res) begin tb_errors=tb_errors+1;
        $display("[CHECK-FAIL] %0s res got=0x%016x exp=0x%016x", what, result, exp_res); end
    end
  endtask

  initial begin
    tb_errors = 0;
    chk("AMOADD",  5'b00000, 64'd10, 64'd5, 64'd10, 64'd15);
    chk("AMOSWAP", 5'b00001, 64'd10, 64'd5, 64'd10, 64'd5);
    chk("AMOAND",  5'b01100, 64'hFF, 64'h0F, 64'hFF, 64'h0F);
    chk("AMOOR",   5'b01000, 64'hF0, 64'h0F, 64'hF0, 64'hFF);
    chk("AMOXOR",  5'b00100, 64'hFF, 64'h0F, 64'hFF, 64'hF0);
    chk("AMOMAXU", 5'b11100, 64'd5, 64'd3, 64'd5, 64'd5);
    chk("AMOMINU", 5'b11000, 64'd5, 64'd3, 64'd5, 64'd3);

    tb_finish("tb_ooo_amo_gate");
  end
endmodule
