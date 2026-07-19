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

  function automatic [63:0] ref_rol64;
    input [63:0] value;
    input [5:0] amount;
    begin
      ref_rol64 = (amount == 0) ? value :
                  ((value << amount) | (value >> (64 - amount)));
    end
  endfunction

  function automatic [63:0] ref_ror64;
    input [63:0] value;
    input [5:0] amount;
    begin
      ref_ror64 = (amount == 0) ? value :
                  ((value >> amount) | (value << (64 - amount)));
    end
  endfunction

  function automatic [31:0] ref_rol32;
    input [31:0] value;
    input [4:0] amount;
    begin
      ref_rol32 = (amount == 0) ? value :
                  ((value << amount) | (value >> (32 - amount)));
    end
  endfunction

  function automatic [31:0] ref_ror32;
    input [31:0] value;
    input [4:0] amount;
    begin
      ref_ror32 = (amount == 0) ? value :
                  ((value >> amount) | (value << (32 - amount)));
    end
  endfunction

  function automatic [63:0] ref_sext32;
    input [31:0] value;
    begin
      ref_sext32 = {{32{value[31]}}, value};
    end
  endfunction

  task automatic chk_rotate;
    input [1023:0] what;
    input [6:0] op;
    input [9:0] f10;
    input [5:0] immediate;
    input [63:0] a;
    input [63:0] b;
    input [63:0] exp;
    begin
      opcode = op;
      funct10 = f10;
      imm = immediate;
      src1 = a;
      src2 = b;
      #1;
      if (result !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s shamt=%0d got=0x%016x exp=0x%016x",
                 what, immediate, result, exp);
      end
    end
  endtask

  initial begin
    integer shamt;
    reg [63:0] rotate_value;
    reg [31:0] rotate_word;
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

    // R3.5 staged rotate network：穷举全部 shift amount，并对两组非对称数据
    // 同时覆盖 ROL/ROR/RORI 与 *W 符号扩展版本。reference 保留直接移位公式，
    // 防止优化实现和测试共用同一结构性错误。
    rotate_value = 64'h0123_4567_89ab_cdef;
    for (shamt = 0; shamt < 64; shamt = shamt + 1) begin
      chk_rotate("ROL", `OPCODE_OP, {7'h30, `FUNCT3_SLL}, shamt[5:0],
                 rotate_value, shamt[5:0],
                 ref_rol64(rotate_value, shamt[5:0]));
      chk_rotate("ROR", `OPCODE_OP, {7'h30, `FUNCT3_SRL_SRA}, shamt[5:0],
                 rotate_value, shamt[5:0],
                 ref_ror64(rotate_value, shamt[5:0]));
      chk_rotate("RORI", `OPCODE_OP_IMM,
                 {6'h18, shamt[5], `FUNCT3_SRL_SRA},
                 shamt[5:0], rotate_value, 64'b0,
                 ref_ror64(rotate_value, shamt[5:0]));
    end
    rotate_value = 64'h8000_0001_0000_0081;
    for (shamt = 0; shamt < 64; shamt = shamt + 1) begin
      chk_rotate("ROL edge", `OPCODE_OP, {7'h30, `FUNCT3_SLL}, shamt[5:0],
                 rotate_value, shamt[5:0],
                 ref_rol64(rotate_value, shamt[5:0]));
      chk_rotate("ROR edge", `OPCODE_OP, {7'h30, `FUNCT3_SRL_SRA}, shamt[5:0],
                 rotate_value, shamt[5:0],
                 ref_ror64(rotate_value, shamt[5:0]));
    end

    rotate_word = 32'h89ab_cdef;
    for (shamt = 0; shamt < 32; shamt = shamt + 1) begin
      chk_rotate("ROLW", `OPCODE_OP_32, {7'h30, `FUNCT3_SLL}, shamt[5:0],
                 {32'b0, rotate_word}, shamt[5:0],
                 ref_sext32(ref_rol32(rotate_word, shamt[4:0])));
      chk_rotate("RORW", `OPCODE_OP_32, {7'h30, `FUNCT3_SRL_SRA}, shamt[5:0],
                 {32'b0, rotate_word}, shamt[5:0],
                 ref_sext32(ref_ror32(rotate_word, shamt[4:0])));
      chk_rotate("RORIW", `OPCODE_OP_IMM_32,
                 {7'h30, `FUNCT3_SRL_SRA}, shamt[5:0],
                 {32'b0, rotate_word}, 64'b0,
                 ref_sext32(ref_ror32(rotate_word, shamt[4:0])));
    end

    tb_finish("tb_ooo_bitmanip_gate");
  end
endmodule
