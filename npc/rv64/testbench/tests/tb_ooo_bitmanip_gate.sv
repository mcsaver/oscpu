`include "define.v"

// OooBitmanipGate smoke testbench：核对接线与几个可确定编码的 Zbb 逻辑/最值 op。
// 穷举位操作正确性由 official rv64uzbb/uzbc/uzbs 回归兜底。
// funct10 = {funct7[6:0], funct3[2:0]}；opcode OP = 7'h33。
module tb_ooo_bitmanip_gate;
  `include "tb_common.svh"

  reg [6:0] opcode;
  reg [9:0] funct10;
  reg [5:0] imm;
  reg [`XLEN-1:0] src1, src2;
  wire [`XLEN-1:0] result;

  OooBitmanipGate dut (
    .opcode_i(opcode), .funct10_i(funct10), .imm_i(imm),
    .src1_i(src1), .src2_i(src2), .result_o(result)
  );

  task automatic chk;
    input [1023:0] what; input [9:0] f10; input [`XLEN-1:0] a, b; input [`XLEN-1:0] exp;
    begin
      opcode = 7'h33; funct10 = f10; imm = 0; src1 = a; src2 = b; #1;
      if (result !== exp) begin tb_errors=tb_errors+1;
        $display("[CHECK-FAIL] %0s got=0x%016x exp=0x%016x", what, result, exp); end
    end
  endtask

  initial begin
    tb_errors = 0;
    // ANDN = src1 & ~src2  ; funct10 = {0100000,111}
    chk("ANDN", 10'b0100000_111, 64'hFF00, 64'h0F0F, 64'hF000);
    // ORN  = src1 | ~src2  ; {0100000,110}
    chk("ORN",  10'b0100000_110, 64'hFF00, 64'h0F0F, 64'hFFFFFFFFFFFFFFF0);
    // XNOR = ~(src1 ^ src2); {0100000,100}
    chk("XNOR", 10'b0100000_100, 64'hFF00, 64'h0F0F, 64'hFFFFFFFFFFFF0FF0);
    // MINU = (src1<src2)?src1:src2 ; {0000101,101}
    chk("MINU", 10'b0000101_101, 64'd5, 64'd3, 64'd3);
    // MAXU = (src1>src2)?src1:src2 ; {0000101,111}
    chk("MAXU", 10'b0000101_111, 64'd5, 64'd3, 64'd5);

    tb_finish("tb_ooo_bitmanip_gate");
  end
endmodule
