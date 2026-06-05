`include "define.v"

module OooMulDivUnit #(
  parameter PHY_REG_ADDR_W = 6,
  parameter ROB_INDEX_W = 4
) (
  input clk,
  input rst,
  input flush_i,

  input req_valid_i,
  output req_ready_o,
  input [ROB_INDEX_W-1:0] req_rob_idx_i,
  input [PHY_REG_ADDR_W-1:0] req_pdest_i,
  input [`INST_W-1:0] req_inst_i,
  input [`XLEN-1:0] req_src1_i,
  input [`XLEN-1:0] req_src2_i,
  input req_word_i,

  output resp_valid_o,
  input resp_ready_i,
  output [ROB_INDEX_W-1:0] resp_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] resp_pdest_o,
  output [`XLEN-1:0] resp_data_o
);

  localparam STATE_IDLE = 2'd0;
  localparam STATE_DIV_RUN = 2'd1;
  localparam STATE_RESP = 2'd2;

  reg [1:0] state_q;
  reg [ROB_INDEX_W-1:0] resp_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] resp_pdest_q;
  reg [`XLEN-1:0] resp_data_q;

  reg [`XLEN-1:0] div_dividend_q;
  reg [`XLEN-1:0] div_divisor_q;
  reg [`XLEN-1:0] div_quot_q;
  reg [`XLEN:0] div_rem_q;
  reg [6:0] div_count_q;
  reg div_rem_result_q;
  reg div_quot_neg_q;
  reg div_rem_neg_q;
  reg div_word_q;

  function [`XLEN-1:0] sign_extend_word;
    input [31:0] word;
    begin
      sign_extend_word = {{32{word[31]}}, word};
    end
  endfunction

  function [`XLEN-1:0] zero_extend_word;
    input [31:0] word;
    begin
      zero_extend_word = {{32{1'b0}}, word};
    end
  endfunction

  function [`XLEN-1:0] mul_result;
    input [`INST_W-1:0] inst;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    input word_op;
    reg [`XLEN-1:0] op1;
    reg [`XLEN-1:0] op2;
    reg mul_op1_signed;
    reg mul_op2_signed;
    reg [`XLEN-1:0] raw_result;
    reg signed [(`XLEN*2)-1:0] mul_op1_ext;
    reg signed [(`XLEN*2)-1:0] mul_op2_ext;
    reg signed [(`XLEN*2)-1:0] selected_prod;
    begin
      op1 = word_op ? sign_extend_word(src1[31:0]) : src1;
      op2 = word_op ? sign_extend_word(src2[31:0]) : src2;
      mul_op1_signed = (inst[14:12] == 3'b001) ||
                       (inst[14:12] == 3'b010);
      mul_op2_signed = (inst[14:12] == 3'b001);
      // 先按 funct3 选择唯一的符号扩展形式，再只生成一个乘积，避免综合出三套并行大乘法器。
      mul_op1_ext = mul_op1_signed ?
                    $signed({{`XLEN{op1[`XLEN-1]}}, op1}) :
                    $signed({{`XLEN{1'b0}}, op1});
      mul_op2_ext = mul_op2_signed ?
                    $signed({{`XLEN{op2[`XLEN-1]}}, op2}) :
                    $signed({{`XLEN{1'b0}}, op2});
      selected_prod = mul_op1_ext * mul_op2_ext;
      case (inst[14:12])
        3'b000: raw_result = selected_prod[`XLEN-1:0];
        3'b001,
        3'b010,
        3'b011: raw_result = selected_prod[(`XLEN*2)-1:`XLEN];
        default: raw_result = {`XLEN{1'b0}};
      endcase
      mul_result = word_op ? sign_extend_word(raw_result[31:0]) : raw_result;
    end
  endfunction

  wire req_fire_w = req_valid_i && req_ready_o;
  wire req_is_div_w = req_inst_i[14];
  wire req_is_rem_w = req_inst_i[13];
  wire req_signed_w = !req_inst_i[12];
  wire req_word_unsigned_w = req_word_i && req_inst_i[12];
  wire [`XLEN-1:0] req_op1_w =
      req_word_i ? (req_word_unsigned_w ? zero_extend_word(req_src1_i[31:0]) :
                                          sign_extend_word(req_src1_i[31:0])) :
                   req_src1_i;
  wire [`XLEN-1:0] req_op2_w =
      req_word_i ? (req_word_unsigned_w ? zero_extend_word(req_src2_i[31:0]) :
                                          sign_extend_word(req_src2_i[31:0])) :
                   req_src2_i;
  wire req_op1_neg_w = req_signed_w && req_op1_w[`XLEN-1];
  wire req_op2_neg_w = req_signed_w && req_op2_w[`XLEN-1];
  wire [`XLEN-1:0] req_op1_abs_w =
      req_op1_neg_w ? (~req_op1_w + {{(`XLEN-1){1'b0}}, 1'b1}) : req_op1_w;
  wire [`XLEN-1:0] req_op2_abs_w =
      req_op2_neg_w ? (~req_op2_w + {{(`XLEN-1){1'b0}}, 1'b1}) : req_op2_w;
  wire [`XLEN-1:0] signed_min_w = {1'b1, {(`XLEN-1){1'b0}}};
  wire [`XLEN-1:0] all_ones_w = {`XLEN{1'b1}};
  wire req_div_by_zero_w = req_op2_w == {`XLEN{1'b0}};
  wire req_signed_overflow_w =
      req_signed_w && (req_op1_w == signed_min_w) && (req_op2_w == all_ones_w);
  wire [`XLEN-1:0] req_special_result_w =
      req_is_rem_w ? (req_div_by_zero_w ? req_op1_w : {`XLEN{1'b0}}) :
                     (req_div_by_zero_w ? all_ones_w : signed_min_w);
  wire [`XLEN-1:0] req_special_result_final_w =
      req_word_i ? sign_extend_word(req_special_result_w[31:0]) :
                   req_special_result_w;
  wire [`XLEN-1:0] req_mul_result_w =
      mul_result(req_inst_i, req_src1_i, req_src2_i, req_word_i);

  wire [`XLEN:0] div_rem_shift_w = {div_rem_q[`XLEN-1:0],
                                    div_dividend_q[`XLEN-1]};
  wire [`XLEN:0] div_divisor_ext_w = {1'b0, div_divisor_q};
  wire div_take_w = div_rem_shift_w >= div_divisor_ext_w;
  wire [`XLEN:0] div_rem_next_w =
      div_take_w ? (div_rem_shift_w - div_divisor_ext_w) : div_rem_shift_w;
  wire [`XLEN-1:0] div_quot_next_w = {div_quot_q[`XLEN-2:0], div_take_w};
  wire [`XLEN-1:0] div_dividend_next_w = {div_dividend_q[`XLEN-2:0], 1'b0};
  wire [`XLEN-1:0] div_quot_fixed_w =
      div_quot_neg_q ? (~div_quot_next_w + {{(`XLEN-1){1'b0}}, 1'b1}) :
                       div_quot_next_w;
  wire [`XLEN-1:0] div_rem_abs_next_w = div_rem_next_w[`XLEN-1:0];
  wire [`XLEN-1:0] div_rem_fixed_w =
      div_rem_neg_q ? (~div_rem_abs_next_w + {{(`XLEN-1){1'b0}}, 1'b1}) :
                      div_rem_abs_next_w;
  wire [`XLEN-1:0] div_result_raw_w =
      div_rem_result_q ? div_rem_fixed_w : div_quot_fixed_w;
  wire [`XLEN-1:0] div_result_final_w =
      div_word_q ? sign_extend_word(div_result_raw_w[31:0]) :
                   div_result_raw_w;

  assign req_ready_o = state_q == STATE_IDLE;
  assign resp_valid_o = state_q == STATE_RESP;
  assign resp_rob_idx_o = resp_rob_idx_q;
  assign resp_pdest_o = resp_pdest_q;
  assign resp_data_o = resp_data_q;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      state_q <= STATE_IDLE;
      resp_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      resp_data_q <= {`XLEN{1'b0}};
      div_dividend_q <= {`XLEN{1'b0}};
      div_divisor_q <= {`XLEN{1'b0}};
      div_quot_q <= {`XLEN{1'b0}};
      div_rem_q <= {(`XLEN+1){1'b0}};
      div_count_q <= 7'd0;
      div_rem_result_q <= 1'b0;
      div_quot_neg_q <= 1'b0;
      div_rem_neg_q <= 1'b0;
      div_word_q <= 1'b0;
    end else begin
      case (state_q)
        STATE_IDLE: begin
          if (req_fire_w) begin
            resp_rob_idx_q <= req_rob_idx_i;
            resp_pdest_q <= req_pdest_i;
            if (!req_is_div_w) begin
              resp_data_q <= req_mul_result_w;
              state_q <= STATE_RESP;
            end else if (req_div_by_zero_w || req_signed_overflow_w) begin
              resp_data_q <= req_special_result_final_w;
              state_q <= STATE_RESP;
            end else begin
              div_dividend_q <= req_op1_abs_w;
              div_divisor_q <= req_op2_abs_w;
              div_quot_q <= {`XLEN{1'b0}};
              div_rem_q <= {(`XLEN+1){1'b0}};
              div_count_q <= 7'd64;
              div_rem_result_q <= req_is_rem_w;
              div_quot_neg_q <= req_signed_w && (req_op1_neg_w ^ req_op2_neg_w);
              div_rem_neg_q <= req_signed_w && req_op1_neg_w;
              div_word_q <= req_word_i;
              state_q <= STATE_DIV_RUN;
            end
          end
        end

        STATE_DIV_RUN: begin
          div_dividend_q <= div_dividend_next_w;
          div_quot_q <= div_quot_next_w;
          div_rem_q <= div_rem_next_w;
          div_count_q <= div_count_q - 7'd1;
          if (div_count_q == 7'd1) begin
            resp_data_q <= div_result_final_w;
            state_q <= STATE_RESP;
          end
        end

        STATE_RESP: begin
          if (resp_ready_i) begin
            state_q <= STATE_IDLE;
            resp_rob_idx_q <= {ROB_INDEX_W{1'b0}};
            resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
            resp_data_q <= {`XLEN{1'b0}};
          end
        end

        default: begin
          state_q <= STATE_IDLE;
        end
      endcase
    end
  end

endmodule
