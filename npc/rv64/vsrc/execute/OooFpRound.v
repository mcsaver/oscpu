// OooFpRound.v — FP execute 子系统共享舍入/规格化 helper。
// 前导零计数（lzc）、规格化左移量、右移带粘滞位（shift-right-jam）、
// round-to-nearest-even 进位判定、u64 最高位/低位或、以及 over/under/inexact
// 标志映射（`FP_FLAG_OF/UF/NX 宏由 include/define.v 统一定义）。被 convert 与 arith
// （addsub/mul/fma）owner 共用；用 `include 注入到各模块 scope。注意 Verilator 的
// `define 跨文件全局，故本头不用 `ifndef guard；且对本头每模块只 include 一次。

  function fp_round_increment;
    input sign;
    input [2:0] rm;
    input lsb;
    input guard;
    input sticky;
    begin
      case (rm)
        3'b000,
        3'b111: fp_round_increment = guard && (sticky || lsb);
        3'b001: fp_round_increment = 1'b0;
        3'b010: fp_round_increment = sign && (guard || sticky);
        3'b011: fp_round_increment = !sign && (guard || sticky);
        3'b100: fp_round_increment = guard;
        default: fp_round_increment = guard && (sticky || lsb);
      endcase
    end
  endfunction

  function [5:0] fp_u64_msb_index;
    input [63:0] value;
    reg [31:0] stage32;
    reg [15:0] stage16;
    reg [7:0] stage8;
    reg [3:0] stage4;
    reg [1:0] stage2;
    begin
      fp_u64_msb_index[5] = |value[63:32];
      stage32 = fp_u64_msb_index[5] ? value[63:32] : value[31:0];
      fp_u64_msb_index[4] = |stage32[31:16];
      stage16 = fp_u64_msb_index[4] ? stage32[31:16] : stage32[15:0];
      fp_u64_msb_index[3] = |stage16[15:8];
      stage8 = fp_u64_msb_index[3] ? stage16[15:8] : stage16[7:0];
      fp_u64_msb_index[2] = |stage8[7:4];
      stage4 = fp_u64_msb_index[2] ? stage8[7:4] : stage8[3:0];
      fp_u64_msb_index[1] = |stage4[3:2];
      stage2 = fp_u64_msb_index[1] ? stage4[3:2] : stage4[1:0];
      fp_u64_msb_index[0] = stage2[1];
    end
  endfunction

  function fp_u64_low_or;
    input [63:0] value;
    input [6:0] bit_count;
    reg [7:0] byte_or;
    reg [7:0] partial_byte;
    reg full_byte_or;
    reg partial_or;
    begin
      byte_or[0] = |value[7:0];
      byte_or[1] = |value[15:8];
      byte_or[2] = |value[23:16];
      byte_or[3] = |value[31:24];
      byte_or[4] = |value[39:32];
      byte_or[5] = |value[47:40];
      byte_or[6] = |value[55:48];
      byte_or[7] = |value[63:56];

      case (bit_count[6:3])
        4'd0: full_byte_or = 1'b0;
        4'd1: full_byte_or = byte_or[0];
        4'd2: full_byte_or = |byte_or[1:0];
        4'd3: full_byte_or = |byte_or[2:0];
        4'd4: full_byte_or = |byte_or[3:0];
        4'd5: full_byte_or = |byte_or[4:0];
        4'd6: full_byte_or = |byte_or[5:0];
        4'd7: full_byte_or = |byte_or[6:0];
        default: full_byte_or = |byte_or;
      endcase

      case (bit_count[6:3])
        4'd0: partial_byte = value[7:0];
        4'd1: partial_byte = value[15:8];
        4'd2: partial_byte = value[23:16];
        4'd3: partial_byte = value[31:24];
        4'd4: partial_byte = value[39:32];
        4'd5: partial_byte = value[47:40];
        4'd6: partial_byte = value[55:48];
        4'd7: partial_byte = value[63:56];
        default: partial_byte = 8'b0;
      endcase

      case (bit_count[2:0])
        3'd0: partial_or = 1'b0;
        3'd1: partial_or = partial_byte[0];
        3'd2: partial_or = |partial_byte[1:0];
        3'd3: partial_or = |partial_byte[2:0];
        3'd4: partial_or = |partial_byte[3:0];
        3'd5: partial_or = |partial_byte[4:0];
        3'd6: partial_or = |partial_byte[5:0];
        default: partial_or = |partial_byte[6:0];
      endcase

      fp_u64_low_or = full_byte_or | partial_or;
    end
  endfunction

  function [6:0] fp_lzc_64;
    input [63:0] value;
    reg [31:0] stage32;
    reg [15:0] stage16;
    reg [7:0] stage8;
    reg [3:0] stage4;
    reg [1:0] stage2;
    begin
      if (value == 64'b0) begin
        fp_lzc_64 = 7'd64;
      end else begin
        fp_lzc_64 = 7'd0;
        fp_lzc_64[5] = ~|value[63:32];
        stage32 = fp_lzc_64[5] ? value[31:0] : value[63:32];
        fp_lzc_64[4] = ~|stage32[31:16];
        stage16 = fp_lzc_64[4] ? stage32[15:0] : stage32[31:16];
        fp_lzc_64[3] = ~|stage16[15:8];
        stage8 = fp_lzc_64[3] ? stage16[7:0] : stage16[15:8];
        fp_lzc_64[2] = ~|stage8[7:4];
        stage4 = fp_lzc_64[2] ? stage8[3:0] : stage8[7:4];
        fp_lzc_64[1] = ~|stage4[3:2];
        stage2 = fp_lzc_64[1] ? stage4[1:0] : stage4[3:2];
        fp_lzc_64[0] = ~stage2[1];
      end
    end
  endfunction

  function [6:0] fp_lzc_56;
    input [55:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 8'b0});
      fp_lzc_56 = (count > 7'd56) ? 7'd56 : count;
    end
  endfunction

  function [5:0] fp_lzc_27;
    input [26:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 37'b0});
      fp_lzc_27 = (count > 7'd27) ? 6'd27 : count[5:0];
    end
  endfunction

  function [7:0] fp_lzc_128;
    input [127:0] value;
    reg [6:0] high_count;
    reg [6:0] low_count;
    begin
      high_count = fp_lzc_64(value[127:64]);
      low_count = fp_lzc_64(value[63:0]);
      fp_lzc_128 = (high_count != 7'd64) ?
                   {1'b0, high_count} : (8'd64 + {1'b0, low_count});
    end
  endfunction

  function [7:0] fp_lzc_106;
    input [105:0] value;
    reg [7:0] count;
    begin
      count = fp_lzc_128({value, 22'b0});
      fp_lzc_106 = (count > 8'd106) ? 8'd106 : count;
    end
  endfunction

  function [5:0] fp_lzc_48;
    input [47:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 16'b0});
      fp_lzc_48 = (count > 7'd48) ? 6'd48 : count[5:0];
    end
  endfunction

  function [5:0] fp_norm_shift_53;
    input [52:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 11'b0});
      fp_norm_shift_53 = (count > 7'd52) ? 6'd52 : count[5:0];
    end
  endfunction

  function [4:0] fp_norm_shift_24;
    input [23:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 40'b0});
      fp_norm_shift_24 = (count > 7'd23) ? 5'd23 : count[4:0];
    end
  endfunction

  function [55:0] fp_shift_right_jam_56;
    input [55:0] value;
    input [6:0] shamt;
    reg [55:0] stage;
    reg [55:0] stage_next;
    begin
      if (shamt == 7'd0) begin
        fp_shift_right_jam_56 = value;
      end else if (shamt >= 7'd56) begin
        fp_shift_right_jam_56 = {55'b0, |value};
      end else begin
        stage = value;
        if (shamt[0]) begin
          stage_next = {1'b0, stage[55:1]};
          stage_next[0] = stage_next[0] | stage[0];
          stage = stage_next;
        end
        if (shamt[1]) begin
          stage_next = {2'b0, stage[55:2]};
          stage_next[0] = stage_next[0] | (|stage[1:0]);
          stage = stage_next;
        end
        if (shamt[2]) begin
          stage_next = {4'b0, stage[55:4]};
          stage_next[0] = stage_next[0] | (|stage[3:0]);
          stage = stage_next;
        end
        if (shamt[3]) begin
          stage_next = {8'b0, stage[55:8]};
          stage_next[0] = stage_next[0] | (|stage[7:0]);
          stage = stage_next;
        end
        if (shamt[4]) begin
          stage_next = {16'b0, stage[55:16]};
          stage_next[0] = stage_next[0] | (|stage[15:0]);
          stage = stage_next;
        end
        if (shamt[5]) begin
          stage_next = {32'b0, stage[55:32]};
          stage_next[0] = stage_next[0] | (|stage[31:0]);
          stage = stage_next;
        end
        fp_shift_right_jam_56 = stage;
      end
    end
  endfunction

  function [26:0] fp_shift_right_jam_27;
    input [26:0] value;
    input [5:0] shamt;
    reg [26:0] stage;
    reg [26:0] stage_next;
    begin
      if (shamt == 6'd0) begin
        fp_shift_right_jam_27 = value;
      end else if (shamt >= 6'd27) begin
        fp_shift_right_jam_27 = {26'b0, |value};
      end else begin
        stage = value;
        if (shamt[0]) begin
          stage_next = {1'b0, stage[26:1]};
          stage_next[0] = stage_next[0] | stage[0];
          stage = stage_next;
        end
        if (shamt[1]) begin
          stage_next = {2'b0, stage[26:2]};
          stage_next[0] = stage_next[0] | (|stage[1:0]);
          stage = stage_next;
        end
        if (shamt[2]) begin
          stage_next = {4'b0, stage[26:4]};
          stage_next[0] = stage_next[0] | (|stage[3:0]);
          stage = stage_next;
        end
        if (shamt[3]) begin
          stage_next = {8'b0, stage[26:8]};
          stage_next[0] = stage_next[0] | (|stage[7:0]);
          stage = stage_next;
        end
        if (shamt[4]) begin
          stage_next = {16'b0, stage[26:16]};
          stage_next[0] = stage_next[0] | (|stage[15:0]);
          stage = stage_next;
        end
        fp_shift_right_jam_27 = stage;
      end
    end
  endfunction

  function [105:0] fp_shift_right_jam_106;
    input [105:0] value;
    input [7:0] shamt;
    reg [105:0] stage;
    reg [105:0] stage_next;
    begin
      if (shamt == 8'd0) begin
        fp_shift_right_jam_106 = value;
      end else if (shamt >= 8'd106) begin
        fp_shift_right_jam_106 = {105'b0, |value};
      end else begin
        stage = value;
        if (shamt[0]) begin
          stage_next = {1'b0, stage[105:1]};
          stage_next[0] = stage_next[0] | stage[0];
          stage = stage_next;
        end
        if (shamt[1]) begin
          stage_next = {2'b0, stage[105:2]};
          stage_next[0] = stage_next[0] | (|stage[1:0]);
          stage = stage_next;
        end
        if (shamt[2]) begin
          stage_next = {4'b0, stage[105:4]};
          stage_next[0] = stage_next[0] | (|stage[3:0]);
          stage = stage_next;
        end
        if (shamt[3]) begin
          stage_next = {8'b0, stage[105:8]};
          stage_next[0] = stage_next[0] | (|stage[7:0]);
          stage = stage_next;
        end
        if (shamt[4]) begin
          stage_next = {16'b0, stage[105:16]};
          stage_next[0] = stage_next[0] | (|stage[15:0]);
          stage = stage_next;
        end
        if (shamt[5]) begin
          stage_next = {32'b0, stage[105:32]};
          stage_next[0] = stage_next[0] | (|stage[31:0]);
          stage = stage_next;
        end
        if (shamt[6]) begin
          stage_next = {64'b0, stage[105:64]};
          stage_next[0] = stage_next[0] | (|stage[63:0]);
          stage = stage_next;
        end
        fp_shift_right_jam_106 = stage;
      end
    end
  endfunction

  function [47:0] fp_shift_right_jam_48;
    input [47:0] value;
    input [5:0] shamt;
    reg [47:0] stage;
    reg [47:0] stage_next;
    begin
      if (shamt == 6'd0) begin
        fp_shift_right_jam_48 = value;
      end else if (shamt >= 6'd48) begin
        fp_shift_right_jam_48 = {47'b0, |value};
      end else begin
        stage = value;
        if (shamt[0]) begin
          stage_next = {1'b0, stage[47:1]};
          stage_next[0] = stage_next[0] | stage[0];
          stage = stage_next;
        end
        if (shamt[1]) begin
          stage_next = {2'b0, stage[47:2]};
          stage_next[0] = stage_next[0] | (|stage[1:0]);
          stage = stage_next;
        end
        if (shamt[2]) begin
          stage_next = {4'b0, stage[47:4]};
          stage_next[0] = stage_next[0] | (|stage[3:0]);
          stage = stage_next;
        end
        if (shamt[3]) begin
          stage_next = {8'b0, stage[47:8]};
          stage_next[0] = stage_next[0] | (|stage[7:0]);
          stage = stage_next;
        end
        if (shamt[4]) begin
          stage_next = {16'b0, stage[47:16]};
          stage_next[0] = stage_next[0] | (|stage[15:0]);
          stage = stage_next;
        end
        if (shamt[5]) begin
          stage_next = {32'b0, stage[47:32]};
          stage_next[0] = stage_next[0] | (|stage[31:0]);
          stage = stage_next;
        end
        fp_shift_right_jam_48 = stage;
      end
    end
  endfunction

  function [4:0] fp_round_flags_s;
    input sign;
    input [7:0] exp_z;
    input [23:0] mant24;
    input guard;
    input sticky;
    reg inexact;
    begin
      inexact = guard | sticky;
      fp_round_flags_s = 5'b00000;
      if (exp_z >= 8'hff) begin
        fp_round_flags_s = `FP_FLAG_OF | `FP_FLAG_NX;
      end else if ((exp_z == 8'd1) && !mant24[23] && inexact) begin
        fp_round_flags_s = `FP_FLAG_UF | `FP_FLAG_NX;
      end else if (inexact) begin
        fp_round_flags_s = `FP_FLAG_NX;
      end
    end
  endfunction

  function [4:0] fp_round_flags_d;
    input sign;
    input [10:0] exp_z;
    input [52:0] mant53;
    input guard;
    input sticky;
    reg inexact;
    begin
      inexact = guard | sticky;
      fp_round_flags_d = 5'b00000;
      if (exp_z >= 11'h7ff) begin
        fp_round_flags_d = `FP_FLAG_OF | `FP_FLAG_NX;
      end else if ((exp_z == 11'd1) && !mant53[52] && inexact) begin
        fp_round_flags_d = `FP_FLAG_UF | `FP_FLAG_NX;
      end else if (inexact) begin
        fp_round_flags_d = `FP_FLAG_NX;
      end
    end
  endfunction
