`include "define.v"

// 独立 radix-4 除法器：按商的有效位数对齐，避免大被除数/大除数仍迭代 32 次。
// 每次迭代并行计算三个候选余数，借位选择商位；符号修正在单独一拍完成。
module OooDivUnit #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W
) (
  input clk, input rst, input flush_i,
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,
  input req_valid_i, output req_ready_o,
  input [PRODUCER_ID_W-1:0] req_producer_id_i,
  input [PHY_REG_ADDR_W-1:0] req_pdest_i,
  input [`INST_W-1:0] req_inst_i,
  input [63:0] req_src1_i, input [63:0] req_src2_i, input req_word_i,
  output resp_valid_o, input resp_ready_i,
  output [ROB_INDEX_W-1:0] resp_rob_idx_o,
  output [PRODUCER_ID_W-1:0] resp_producer_id_o,
  output [PHY_REG_ADDR_W-1:0] resp_pdest_o,
  output [63:0] resp_data_o,
  output owner_valid_o,
  output [PRODUCER_ID_W-1:0] owner_producer_id_o
);
  localparam [2:0] IDLE=3'd0, PREPARE=3'd1, DIVIDE=3'd3,
                   RESPONSE=3'd4, FIX_SIGN=3'd5;
  reg [2:0] state_q;
  reg [PRODUCER_ID_W-1:0] producer_id_q;
  reg [PHY_REG_ADDR_W-1:0] pdest_q;
  reg [63:0] src1_q, src2_q, result_q;
  reg signed_q, word_q, rem_result_q;
  reg quotient_negative_q, remainder_negative_q;
  reg [63:0] quotient_q, remainder_q;
  reg [65:0] divisor_q, divisor3_q;
  reg [5:0] shift_q;

  function [6:0] clz64;
    input [63:0] value;
    reg [63:0] scan;
    reg [6:0] count;
    begin
      scan=value; count=0;
      if (scan[63:32] == 0) begin count=count+7'd32; scan=scan<<32; end
      if (scan[63:48] == 0) begin count=count+7'd16; scan=scan<<16; end
      if (scan[63:56] == 0) begin count=count+7'd8; scan=scan<<8; end
      if (scan[63:60] == 0) begin count=count+7'd4; scan=scan<<4; end
      if (scan[63:62] == 0) begin count=count+7'd2; scan=scan<<2; end
      if (!scan[63]) count=count+7'd1;
      clz64=(value==0) ? 7'd64 : count;
    end
  endfunction

  wire [63:0] operand1_w = word_q ?
      {{32{signed_q && src1_q[31]}},src1_q[31:0]} : src1_q;
  wire [63:0] operand2_w = word_q ?
      {{32{signed_q && src2_q[31]}},src2_q[31:0]} : src2_q;
  wire negative1_w = signed_q && operand1_w[63];
  wire negative2_w = signed_q && operand2_w[63];
  wire [63:0] absolute1_w = negative1_w ? (~operand1_w+64'd1) : operand1_w;
  wire [63:0] absolute2_w = negative2_w ? (~operand2_w+64'd1) : operand2_w;
  wire [6:0] quotient_msb_w = clz64(absolute2_w)-clz64(absolute1_w);
  wire [5:0] initial_shift_w = {quotient_msb_w[5:1],1'b0};
  wire [65:0] aligned_divisor_w = {2'b00,absolute2_w} << initial_shift_w;
  wire zero_divisor_w = (absolute2_w == 0);
  wire overflow_w = signed_q && operand1_w == 64'h8000_0000_0000_0000 &&
                                                   operand2_w == 64'hffff_ffff_ffff_ffff;
  wire [63:0] special_result_w = rem_result_q ?
      (zero_divisor_w ? operand1_w : 64'd0) :
      (zero_divisor_w ? 64'hffff_ffff_ffff_ffff : operand1_w);

  wire [66:0] difference1_w = {3'b000,remainder_q} - {1'b0,divisor_q};
  wire [66:0] difference2_w = {3'b000,remainder_q} - {divisor_q,1'b0};
  wire [66:0] difference3_w = {3'b000,remainder_q} - {1'b0,divisor3_q};
  reg [1:0] digit_w;
  reg [63:0] remainder_next_w;
  always @(*) begin
    digit_w=2'd0; remainder_next_w=remainder_q;
    if (!difference3_w[66]) begin
      digit_w=2'd3; remainder_next_w=difference3_w[63:0];
    end else if (!difference2_w[66]) begin
      digit_w=2'd2; remainder_next_w=difference2_w[63:0];
    end else if (!difference1_w[66]) begin
      digit_w=2'd1; remainder_next_w=difference1_w[63:0];
    end
  end
  wire [63:0] quotient_next_w = quotient_q | ({62'd0,digit_w} << shift_q);
  wire [63:0] magnitude_w = rem_result_q ? remainder_q : quotient_q;
  wire negative_result_w = rem_result_q ? remainder_negative_q : quotient_negative_q;
  wire [63:0] fixed_result_w = negative_result_w ? (~magnitude_w+64'd1) : magnitude_w;
  wire [ROB_INDEX_W-1:0] owner_age_w = producer_id_q[ROB_INDEX_W-1:0]-rob_head_idx_i;
  wire [ROB_INDEX_W-1:0] kill_age_w = kill_rob_idx_i-rob_head_idx_i;
  wire killed_w = owner_valid_o && kill_valid_i && owner_age_w > kill_age_w;

  assign req_ready_o = state_q==IDLE && !rst && !flush_i && !kill_valid_i;
  assign resp_valid_o = state_q==RESPONSE && !rst && !flush_i && !killed_w;
  assign resp_data_o = result_q;
  assign resp_producer_id_o = producer_id_q;
  assign resp_rob_idx_o = producer_id_q[ROB_INDEX_W-1:0];
  assign resp_pdest_o = pdest_q;
  assign owner_valid_o = state_q!=IDLE;
  assign owner_producer_id_o = producer_id_q;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      state_q<=IDLE; producer_id_q<={PRODUCER_ID_W{1'b0}};
      pdest_q<={PHY_REG_ADDR_W{1'b0}}; result_q<=64'd0;
      src1_q<=64'd0; src2_q<=64'd0;
      signed_q<=0; word_q<=0; rem_result_q<=0;
      quotient_negative_q<=0; remainder_negative_q<=0;
      quotient_q<=64'd0; remainder_q<=64'd0;
      divisor_q<=66'd0; divisor3_q<=66'd0; shift_q<=6'd0;
    end else if (killed_w) begin
      state_q<=IDLE;
    end else begin
      case (state_q)
        IDLE: if (req_valid_i && req_ready_o) begin
          producer_id_q<=req_producer_id_i; pdest_q<=req_pdest_i;
          src1_q<=req_src1_i; src2_q<=req_src2_i;
          signed_q<=!req_inst_i[12]; rem_result_q<=req_inst_i[13];
          word_q<=req_word_i; state_q<=PREPARE;
        end
        PREPARE: begin
          quotient_q<=64'd0; remainder_q<=absolute1_w;
          quotient_negative_q<=negative1_w ^ negative2_w;
          remainder_negative_q<=negative1_w;
          if (zero_divisor_w || overflow_w) begin
            result_q<=word_q ? {{32{special_result_w[31]}},special_result_w[31:0]} :
                               special_result_w;
            state_q<=RESPONSE;
          end else if (absolute1_w < absolute2_w) begin
            state_q<=FIX_SIGN;
          end else begin
            shift_q<=initial_shift_w;
            divisor_q<=aligned_divisor_w;
            divisor3_q<=aligned_divisor_w+{aligned_divisor_w[64:0],1'b0};
            state_q<=DIVIDE;
          end
        end
        DIVIDE: begin
          quotient_q<=quotient_next_w; remainder_q<=remainder_next_w;
          divisor_q<=divisor_q>>2; divisor3_q<=divisor3_q>>2;
          shift_q<=shift_q-6'd2;
          if (shift_q==0) state_q<=FIX_SIGN;
        end
        FIX_SIGN: begin
          result_q<=word_q ? {{32{fixed_result_w[31]}},fixed_result_w[31:0]} : fixed_result_w;
          state_q<=RESPONSE;
        end
        RESPONSE: if (resp_ready_i) state_q<=IDLE;
        default: state_q<=IDLE;
      endcase
    end
  end
`ifdef OOO_ASSERT
  always @(posedge clk) if (!rst && !flush_i) begin
    if (state_q==DIVIDE && divisor_q==0) $error("[DIVISOR] zero iterative divisor");
    if (state_q==DIVIDE && shift_q[0]) $error("[DIVISOR] unaligned radix-4 digit");
    if (resp_valid_o && killed_w) $error("[DIVISOR] killed result escaped");
  end
`endif
endmodule
