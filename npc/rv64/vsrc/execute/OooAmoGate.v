`include "define.v"

// 原子访存结果（RV64A AMO：amoswap/add/xor/and/or/min/max[u]，W/D）：
// 从 OooIntBackend 抽出的纯组合 owner。输入指令、内存旧值 load_data、rs2、访问宽度，
// 输出符号规整后的旧值与按 amo 操作算出的新值（写回内存）。
// 行为与原 OooIntBackend 内联 amo_old_value/amo_result_value 等价。
module OooAmoGate (
  input  [`INST_W-1:0] inst_i,
  input  [`XLEN-1:0]   load_data_i,
  input  [`XLEN-1:0]   src2_i,
  input  [1:0]         size_i,
  output [`XLEN-1:0]   old_value_o,
  output [`XLEN-1:0]   result_o
);

  // 与父模块同义的 32->64 符号扩展（trivial helper，随 owner 复制以保持自包含）。
  function [`XLEN-1:0] sign_extend_word;
    input [31:0] word;
    begin
      sign_extend_word = {{(`XLEN-32){word[31]}}, word};
    end
  endfunction

  function [`XLEN-1:0] amo_old_value;
    input [`XLEN-1:0] load_data;
    input [1:0] size;
    begin
      amo_old_value = (size == `MEM_SIZE_WORD) ?
                      sign_extend_word(load_data[31:0]) : load_data;
    end
  endfunction

  function [`XLEN-1:0] amo_result_value;
    input [`INST_W-1:0] inst;
    input [`XLEN-1:0] old_value;
    input [`XLEN-1:0] src2;
    input [1:0] size;
    reg signed [31:0] old_s32;
    reg signed [31:0] src_s32;
    reg signed [`XLEN-1:0] old_s64;
    reg signed [`XLEN-1:0] src_s64;
    reg [31:0] old_u32;
    reg [31:0] src_u32;
    reg [31:0] result32;
    begin
      old_s32 = old_value[31:0];
      src_s32 = src2[31:0];
      old_s64 = old_value;
      src_s64 = src2;
      old_u32 = old_value[31:0];
      src_u32 = src2[31:0];
      if (size == `MEM_SIZE_WORD) begin
        case (inst[31:27])
          5'b00001: result32 = src2[31:0];
          5'b00000: result32 = old_u32 + src_u32;
          5'b00100: result32 = old_u32 ^ src_u32;
          5'b01100: result32 = old_u32 & src_u32;
          5'b01000: result32 = old_u32 | src_u32;
          5'b10000: result32 = (old_s32 < src_s32) ? old_u32 : src_u32;
          5'b10100: result32 = (old_s32 > src_s32) ? old_u32 : src_u32;
          5'b11000: result32 = (old_u32 < src_u32) ? old_u32 : src_u32;
          5'b11100: result32 = (old_u32 > src_u32) ? old_u32 : src_u32;
          default:  result32 = old_u32;
        endcase
        amo_result_value = sign_extend_word(result32);
      end else begin
        case (inst[31:27])
          5'b00001: amo_result_value = src2;
          5'b00000: amo_result_value = old_value + src2;
          5'b00100: amo_result_value = old_value ^ src2;
          5'b01100: amo_result_value = old_value & src2;
          5'b01000: amo_result_value = old_value | src2;
          5'b10000: amo_result_value = (old_s64 < src_s64) ? old_value : src2;
          5'b10100: amo_result_value = (old_s64 > src_s64) ? old_value : src2;
          5'b11000: amo_result_value = (old_value < src2) ? old_value : src2;
          5'b11100: amo_result_value = (old_value > src2) ? old_value : src2;
          default:  amo_result_value = old_value;
        endcase
      end
    end
  endfunction

  assign old_value_o = amo_old_value(load_data_i, size_i);
  assign result_o = amo_result_value(inst_i, old_value_o, src2_i, size_i);

endmodule
