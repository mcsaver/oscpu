`include "define.v"

// 整数位操作（Zba/Zbb/Zbc/Zbs 中走 bitmanip 路径的指令）：从 OooIntBackend 抽出的
// 纯组合 owner。输入指令 opcode、{funct7,funct3}、imm[5:0]、src1/src2 操作数，输出
// bitmanip 结果。clz/ctz/popcount/rol/ror 等子运算与 dispatcher 内聚于此。
// 行为与原 OooIntBackend 内联 bitmanip_result 等价。
module OooBitmanipGate (
  input  [6:0]       opcode_i,
  input  [9:0]       funct10_i,
  input  [5:0]       imm_i,
  input  [`XLEN-1:0] src1_i,
  input  [`XLEN-1:0] src2_i,
  output reg [`XLEN-1:0] result_o
);

  // 与父模块同义的 32->64 符号扩展（trivial helper，随 owner 复制以保持自包含）。
  function [`XLEN-1:0] sign_extend_word;
    input [31:0] word;
    begin
      sign_extend_word = {{(`XLEN-32){word[31]}}, word};
    end
  endfunction

  function [3:0] bitmanip_clz8;
    input [7:0] value;
    begin
      casez (value)
        8'b1???????: bitmanip_clz8 = 4'd0;
        8'b01??????: bitmanip_clz8 = 4'd1;
        8'b001?????: bitmanip_clz8 = 4'd2;
        8'b0001????: bitmanip_clz8 = 4'd3;
        8'b00001???: bitmanip_clz8 = 4'd4;
        8'b000001??: bitmanip_clz8 = 4'd5;
        8'b0000001?: bitmanip_clz8 = 4'd6;
        8'b00000001: bitmanip_clz8 = 4'd7;
        default:     bitmanip_clz8 = 4'd8;
      endcase
    end
  endfunction

  function [3:0] bitmanip_ctz8;
    input [7:0] value;
    begin
      casez (value)
        8'b???????1: bitmanip_ctz8 = 4'd0;
        8'b??????10: bitmanip_ctz8 = 4'd1;
        8'b?????100: bitmanip_ctz8 = 4'd2;
        8'b????1000: bitmanip_ctz8 = 4'd3;
        8'b???10000: bitmanip_ctz8 = 4'd4;
        8'b??100000: bitmanip_ctz8 = 4'd5;
        8'b?1000000: bitmanip_ctz8 = 4'd6;
        8'b10000000: bitmanip_ctz8 = 4'd7;
        default:     bitmanip_ctz8 = 4'd8;
      endcase
    end
  endfunction

  function [3:0] bitmanip_popcount8;
    input [7:0] value;
    reg [1:0] pair0;
    reg [1:0] pair1;
    reg [1:0] pair2;
    reg [1:0] pair3;
    reg [2:0] nibble0;
    reg [2:0] nibble1;
    begin
      pair0 = {1'b0, value[0]} + {1'b0, value[1]};
      pair1 = {1'b0, value[2]} + {1'b0, value[3]};
      pair2 = {1'b0, value[4]} + {1'b0, value[5]};
      pair3 = {1'b0, value[6]} + {1'b0, value[7]};
      nibble0 = {1'b0, pair0} + {1'b0, pair1};
      nibble1 = {1'b0, pair2} + {1'b0, pair3};
      bitmanip_popcount8 = {1'b0, nibble0} + {1'b0, nibble1};
    end
  endfunction

  function [6:0] bitmanip_clz64;
    input [63:0] value;
    begin
      // Zbb count 类指令用 byte 级优先树表达，避免 64 次循环覆盖结果形成长组合链。
      if (value[63:56] != 8'b0)
        bitmanip_clz64 = {3'b000, bitmanip_clz8(value[63:56])};
      else if (value[55:48] != 8'b0)
        bitmanip_clz64 = 7'd8 + {3'b000, bitmanip_clz8(value[55:48])};
      else if (value[47:40] != 8'b0)
        bitmanip_clz64 = 7'd16 + {3'b000, bitmanip_clz8(value[47:40])};
      else if (value[39:32] != 8'b0)
        bitmanip_clz64 = 7'd24 + {3'b000, bitmanip_clz8(value[39:32])};
      else if (value[31:24] != 8'b0)
        bitmanip_clz64 = 7'd32 + {3'b000, bitmanip_clz8(value[31:24])};
      else if (value[23:16] != 8'b0)
        bitmanip_clz64 = 7'd40 + {3'b000, bitmanip_clz8(value[23:16])};
      else if (value[15:8] != 8'b0)
        bitmanip_clz64 = 7'd48 + {3'b000, bitmanip_clz8(value[15:8])};
      else if (value[7:0] != 8'b0)
        bitmanip_clz64 = 7'd56 + {3'b000, bitmanip_clz8(value[7:0])};
      else
        bitmanip_clz64 = 7'd64;
    end
  endfunction

  function [6:0] bitmanip_ctz64;
    input [63:0] value;
    begin
      if (value[7:0] != 8'b0)
        bitmanip_ctz64 = {3'b000, bitmanip_ctz8(value[7:0])};
      else if (value[15:8] != 8'b0)
        bitmanip_ctz64 = 7'd8 + {3'b000, bitmanip_ctz8(value[15:8])};
      else if (value[23:16] != 8'b0)
        bitmanip_ctz64 = 7'd16 + {3'b000, bitmanip_ctz8(value[23:16])};
      else if (value[31:24] != 8'b0)
        bitmanip_ctz64 = 7'd24 + {3'b000, bitmanip_ctz8(value[31:24])};
      else if (value[39:32] != 8'b0)
        bitmanip_ctz64 = 7'd32 + {3'b000, bitmanip_ctz8(value[39:32])};
      else if (value[47:40] != 8'b0)
        bitmanip_ctz64 = 7'd40 + {3'b000, bitmanip_ctz8(value[47:40])};
      else if (value[55:48] != 8'b0)
        bitmanip_ctz64 = 7'd48 + {3'b000, bitmanip_ctz8(value[55:48])};
      else if (value[63:56] != 8'b0)
        bitmanip_ctz64 = 7'd56 + {3'b000, bitmanip_ctz8(value[63:56])};
      else
        bitmanip_ctz64 = 7'd64;
    end
  endfunction

  function [6:0] bitmanip_cpop64;
    input [63:0] value;
    reg [3:0] pop0;
    reg [3:0] pop1;
    reg [3:0] pop2;
    reg [3:0] pop3;
    reg [3:0] pop4;
    reg [3:0] pop5;
    reg [3:0] pop6;
    reg [3:0] pop7;
    reg [4:0] sum01;
    reg [4:0] sum23;
    reg [4:0] sum45;
    reg [4:0] sum67;
    reg [5:0] sum0123;
    reg [5:0] sum4567;
    begin
      pop0 = bitmanip_popcount8(value[7:0]);
      pop1 = bitmanip_popcount8(value[15:8]);
      pop2 = bitmanip_popcount8(value[23:16]);
      pop3 = bitmanip_popcount8(value[31:24]);
      pop4 = bitmanip_popcount8(value[39:32]);
      pop5 = bitmanip_popcount8(value[47:40]);
      pop6 = bitmanip_popcount8(value[55:48]);
      pop7 = bitmanip_popcount8(value[63:56]);
      sum01 = {1'b0, pop0} + {1'b0, pop1};
      sum23 = {1'b0, pop2} + {1'b0, pop3};
      sum45 = {1'b0, pop4} + {1'b0, pop5};
      sum67 = {1'b0, pop6} + {1'b0, pop7};
      sum0123 = {1'b0, sum01} + {1'b0, sum23};
      sum4567 = {1'b0, sum45} + {1'b0, sum67};
      bitmanip_cpop64 = {1'b0, sum0123} + {1'b0, sum4567};
    end
  endfunction

  function [5:0] bitmanip_clz32;
    input [31:0] value;
    begin
      if (value[31:24] != 8'b0)
        bitmanip_clz32 = {2'b00, bitmanip_clz8(value[31:24])};
      else if (value[23:16] != 8'b0)
        bitmanip_clz32 = 6'd8 + {2'b00, bitmanip_clz8(value[23:16])};
      else if (value[15:8] != 8'b0)
        bitmanip_clz32 = 6'd16 + {2'b00, bitmanip_clz8(value[15:8])};
      else if (value[7:0] != 8'b0)
        bitmanip_clz32 = 6'd24 + {2'b00, bitmanip_clz8(value[7:0])};
      else
        bitmanip_clz32 = 6'd32;
    end
  endfunction

  function [5:0] bitmanip_ctz32;
    input [31:0] value;
    begin
      if (value[7:0] != 8'b0)
        bitmanip_ctz32 = {2'b00, bitmanip_ctz8(value[7:0])};
      else if (value[15:8] != 8'b0)
        bitmanip_ctz32 = 6'd8 + {2'b00, bitmanip_ctz8(value[15:8])};
      else if (value[23:16] != 8'b0)
        bitmanip_ctz32 = 6'd16 + {2'b00, bitmanip_ctz8(value[23:16])};
      else if (value[31:24] != 8'b0)
        bitmanip_ctz32 = 6'd24 + {2'b00, bitmanip_ctz8(value[31:24])};
      else
        bitmanip_ctz32 = 6'd32;
    end
  endfunction

  function [5:0] bitmanip_cpop32;
    input [31:0] value;
    reg [3:0] pop0;
    reg [3:0] pop1;
    reg [3:0] pop2;
    reg [3:0] pop3;
    reg [4:0] sum01;
    reg [4:0] sum23;
    begin
      pop0 = bitmanip_popcount8(value[7:0]);
      pop1 = bitmanip_popcount8(value[15:8]);
      pop2 = bitmanip_popcount8(value[23:16]);
      pop3 = bitmanip_popcount8(value[31:24]);
      sum01 = {1'b0, pop0} + {1'b0, pop1};
      sum23 = {1'b0, pop2} + {1'b0, pop3};
      bitmanip_cpop32 = {1'b0, sum01} + {1'b0, sum23};
    end
  endfunction

  function [31:0] bitmanip_rol32;
    input [31:0] value;
    input [4:0] shamt;
    begin
      bitmanip_rol32 = (shamt == 5'h0) ? value :
                       ((value << shamt) | (value >> (6'd32 - {1'b0, shamt})));
    end
  endfunction

  function [31:0] bitmanip_ror32;
    input [31:0] value;
    input [4:0] shamt;
    begin
      bitmanip_ror32 = (shamt == 5'h0) ? value :
                       ((value >> shamt) | (value << (6'd32 - {1'b0, shamt})));
    end
  endfunction

  always @(*) begin : bitmanip_result_blk
    reg [6:0] opcode;
    reg [9:0] funct10;
    reg [5:0] imm;
    reg [`XLEN-1:0] src1;
    reg [`XLEN-1:0] src2;
    reg [4:0] imm5;
    reg [5:0] shamt;
    reg [6:0] inv_shamt;
    begin
      opcode = opcode_i;
      funct10 = funct10_i;
      imm = imm_i;
      src1 = src1_i;
      src2 = src2_i;
      imm5 = 0;
      shamt = 0;
      inv_shamt = 0;
      result_o = 0;
      imm5 = imm[4:0];
      shamt = src2[`SHIFT_AMT_W-1:0];
      inv_shamt = 7'd64 - {1'b0, shamt};
      result_o = {`XLEN{1'b0}};

      if (opcode == `OPCODE_OP_IMM) begin
        case (funct10)
          {7'h14, `FUNCT3_SLL},
          {7'h15, `FUNCT3_SLL}:     result_o = src1 | (64'h1 << imm);
          {7'h24, `FUNCT3_SLL},
          {7'h25, `FUNCT3_SLL}:     result_o = src1 & ~(64'h1 << imm);
          {7'h34, `FUNCT3_SLL},
          {7'h35, `FUNCT3_SLL}:     result_o = src1 ^ (64'h1 << imm);
          {7'h30, `FUNCT3_SRL_SRA},
          {7'h31, `FUNCT3_SRL_SRA}: result_o = (imm == 6'h0) ? src1 :
                                                     ((src1 >> imm) | (src1 << (7'd64 - {1'b0, imm})));
          {7'h24, `FUNCT3_SRL_SRA},
          {7'h25, `FUNCT3_SRL_SRA}: result_o = {{(`XLEN-1){1'b0}}, src1[imm]};
          {7'h14, `FUNCT3_SRL_SRA}: result_o = {
              (src1[63:56] != 8'h00) ? 8'hff : 8'h00,
              (src1[55:48] != 8'h00) ? 8'hff : 8'h00,
              (src1[47:40] != 8'h00) ? 8'hff : 8'h00,
              (src1[39:32] != 8'h00) ? 8'hff : 8'h00,
              (src1[31:24] != 8'h00) ? 8'hff : 8'h00,
              (src1[23:16] != 8'h00) ? 8'hff : 8'h00,
              (src1[15:8]  != 8'h00) ? 8'hff : 8'h00,
              (src1[7:0]   != 8'h00) ? 8'hff : 8'h00
          };
          {7'h34, `FUNCT3_SRL_SRA},
          {7'h35, `FUNCT3_SRL_SRA}: result_o = {src1[7:0], src1[15:8], src1[23:16], src1[31:24],
                                                     src1[39:32], src1[47:40], src1[55:48], src1[63:56]};
          {7'h30, `FUNCT3_SLL}: begin
            case (imm5)
              5'h00: result_o = {{(`XLEN-7){1'b0}},
                                         bitmanip_clz64(src1)};
              5'h01: result_o = {{(`XLEN-7){1'b0}},
                                         bitmanip_ctz64(src1)};
              5'h02: result_o = {{(`XLEN-7){1'b0}},
                                         bitmanip_cpop64(src1)};
              5'h04: result_o = {{(`XLEN-8){src1[7]}}, src1[7:0]};
              5'h05: result_o = {{(`XLEN-16){src1[15]}}, src1[15:0]};
              default: begin end
            endcase
          end
          default: begin end
        endcase
      end else if (opcode == `OPCODE_OP_IMM_32) begin
        case ({funct10[9:4], funct10[2:0]})
          {6'h02, `FUNCT3_SLL}: result_o = ({{(`XLEN-32){1'b0}}, src1[31:0]}) << imm;
          default: begin end
        endcase
        case (funct10)
          {7'h30, `FUNCT3_SLL}: begin
            case (imm5)
              5'h00: result_o = {{(`XLEN-6){1'b0}}, bitmanip_clz32(src1[31:0])};
              5'h01: result_o = {{(`XLEN-6){1'b0}}, bitmanip_ctz32(src1[31:0])};
              5'h02: result_o = {{(`XLEN-6){1'b0}}, bitmanip_cpop32(src1[31:0])};
              default: begin end
            endcase
          end
          {7'h30, `FUNCT3_SRL_SRA}: begin
            result_o = sign_extend_word(bitmanip_ror32(src1[31:0], imm5));
          end
          default: begin end
        endcase
      end else begin
        case (funct10)
          {7'h04, `FUNCT3_ADD_SUB}: result_o = {{(`XLEN-32){1'b0}}, src1[31:0]} + src2;
          {7'h10, `FUNCT3_SLT}:     result_o = (((opcode == `OPCODE_OP_32) ? {{(`XLEN-32){1'b0}}, src1[31:0]} : src1) << 1) + src2;
          {7'h10, `FUNCT3_XOR}:     result_o = (((opcode == `OPCODE_OP_32) ? {{(`XLEN-32){1'b0}}, src1[31:0]} : src1) << 2) + src2;
          {7'h10, `FUNCT3_OR}:      result_o = (((opcode == `OPCODE_OP_32) ? {{(`XLEN-32){1'b0}}, src1[31:0]} : src1) << 3) + src2;
          {7'h20, `FUNCT3_AND}:     result_o = src1 & ~src2;
          {7'h20, `FUNCT3_OR}:      result_o = src1 | ~src2;
          {7'h20, `FUNCT3_XOR}:     result_o = ~(src1 ^ src2);
          {7'h30, `FUNCT3_SLL}:     result_o = (opcode == `OPCODE_OP_32) ?
                                                     sign_extend_word(bitmanip_rol32(src1[31:0], src2[4:0])) :
                                                     ((shamt == 5'h0) ? src1 :
                                                     ((src1 << shamt) | (src1 >> inv_shamt)));
          {7'h30, `FUNCT3_SRL_SRA}: result_o = (opcode == `OPCODE_OP_32) ?
                                                     sign_extend_word(bitmanip_ror32(src1[31:0], src2[4:0])) :
                                                     ((shamt == 5'h0) ? src1 :
                                                     ((src1 >> shamt) | (src1 << inv_shamt)));
          {7'h05, `FUNCT3_XOR}:     result_o = ($signed(src1) < $signed(src2)) ? src1 : src2;
          {7'h05, `FUNCT3_SRL_SRA}: result_o = (src1 < src2) ? src1 : src2;
          {7'h05, `FUNCT3_OR}:      result_o = ($signed(src1) > $signed(src2)) ? src1 : src2;
          {7'h05, `FUNCT3_AND}:     result_o = (src1 > src2) ? src1 : src2;
          {7'h14, `FUNCT3_SLL}:     result_o = src1 | (64'h1 << shamt);
          {7'h24, `FUNCT3_SLL}:     result_o = src1 & ~(64'h1 << shamt);
          {7'h24, `FUNCT3_SRL_SRA}: result_o = {{(`XLEN-1){1'b0}}, src1[shamt]};
          {7'h34, `FUNCT3_SLL}:     result_o = src1 ^ (64'h1 << shamt);
          {7'h04, `FUNCT3_XOR}:     result_o = {{(`XLEN-16){1'b0}}, src1[15:0]};
          default: begin end
        endcase
      end
    end
  end


endmodule
