`include "define.v"

module OooMulDivUnit #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W
) (
  input clk,
  input rst,
  input flush_i,
  // UC-A mispredict-kill: 整数 MulDiv 补齐 kill 端口(FP 全家已有)，防误预测阴影 wrong-path 结果撞号
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,

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
  localparam STATE_MUL_RUN = 2'd1;
  localparam STATE_DIV_RUN = 2'd2;
  localparam STATE_RESP = 2'd3;

  reg [1:0] state_q;
  reg [ROB_INDEX_W-1:0] resp_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] resp_pdest_q;
  reg [`XLEN-1:0] resp_data_q;

  reg [`XLEN-1:0] div_dividend_q;
  reg [`XLEN-1:0] div_divisor_q;
  // 时序优化：3×divisor 在除法期间恒定，装载时算一次并寄存，移出 radix-4 每拍迭代环
  // (原 div_d3=d1+d2 是 XLEN+2 位加法器,在 partial>=d3 比较的关键路径上)。结果不变。
  reg [`XLEN+1:0] div_d3_q;
  reg [`XLEN-1:0] div_quot_q;
  reg [`XLEN:0] div_rem_q;
  reg [6:0] div_count_q;
  reg div_rem_result_q;
  reg div_quot_neg_q;
  reg div_rem_neg_q;
  reg div_word_q;
  reg [(`XLEN*2)-1:0] mul_acc_q;
  reg [(`XLEN*2)-1:0] mul_multiplicand_q;
  reg [`XLEN-1:0] mul_multiplier_q;
  reg [6:0] mul_count_q;
  reg [2:0] mul_funct3_q;
  reg mul_word_q;
  reg mul_neg_q;

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

  wire req_fire_w = req_valid_i && req_ready_o;
  wire [2:0] req_funct3_w = req_inst_i[14:12];
  wire req_is_div_w = req_funct3_w[2];
  wire req_is_rem_w = req_inst_i[13];
  wire req_signed_w = !req_inst_i[12];
  wire [`XLEN-1:0] req_mul_op1_w =
      req_word_i ? sign_extend_word(req_src1_i[31:0]) : req_src1_i;
  wire [`XLEN-1:0] req_mul_op2_w =
      req_word_i ? sign_extend_word(req_src2_i[31:0]) : req_src2_i;
  wire req_mul_op1_signed_w = (req_funct3_w == 3'b001) ||
                              (req_funct3_w == 3'b010);
  wire req_mul_op2_signed_w = (req_funct3_w == 3'b001);
  wire req_mul_op1_neg_w = req_mul_op1_signed_w && req_mul_op1_w[`XLEN-1];
  wire req_mul_op2_neg_w = req_mul_op2_signed_w && req_mul_op2_w[`XLEN-1];
  wire [`XLEN-1:0] req_mul_op1_abs_w =
      req_mul_op1_neg_w ? (~req_mul_op1_w + {{(`XLEN-1){1'b0}}, 1'b1}) :
                          req_mul_op1_w;
  wire [`XLEN-1:0] req_mul_op2_abs_w =
      req_mul_op2_neg_w ? (~req_mul_op2_w + {{(`XLEN-1){1'b0}}, 1'b1}) :
                          req_mul_op2_w;
  wire req_mul_neg_w = req_mul_op1_neg_w ^ req_mul_op2_neg_w;
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

  wire [(`XLEN*2)-1:0] mul_addend_w =
      mul_multiplier_q[0] ? mul_multiplicand_q : {(`XLEN*2){1'b0}};
  wire [(`XLEN*2)-1:0] mul_acc_next_w = mul_acc_q + mul_addend_w;
  wire [(`XLEN*2)-1:0] mul_multiplicand_next_w =
      {mul_multiplicand_q[(`XLEN*2)-2:0], 1'b0};
  wire [`XLEN-1:0] mul_multiplier_next_w =
      {1'b0, mul_multiplier_q[`XLEN-1:1]};
  wire [(`XLEN*2)-1:0] mul_product_final_w =
      mul_neg_q ? (~mul_acc_next_w + {{((`XLEN*2)-1){1'b0}}, 1'b1}) :
                  mul_acc_next_w;
  reg [`XLEN-1:0] mul_result_raw_w;
  reg [`XLEN-1:0] mul_result_final_w;
  always @(*) begin
    case (mul_funct3_q)
      3'b000: mul_result_raw_w = mul_product_final_w[`XLEN-1:0];
      3'b001,
      3'b010,
      3'b011: mul_result_raw_w = mul_product_final_w[(`XLEN*2)-1:`XLEN];
      default: mul_result_raw_w = {`XLEN{1'b0}};
    endcase
    mul_result_final_w = mul_word_q ? sign_extend_word(mul_result_raw_w[31:0]) :
                                      mul_result_raw_w;
  end

  // CLZ 早终止：按被除数绝对值的实际有效位数定位，只跑必要的迭代，跳过前导零。
  // 小操作数除法(如 n%10/n/10)由此从固定 16/32 拍大幅减少。clz 向下取偶以保持 radix-4
  // 的 2-bit 组对齐(多出的 1 个前导 0 位无害,只产生一个前导商位 0)。op1==0 在装载处特判。
  function [6:0] div_clz64;
    input [`XLEN-1:0] v;
    integer ci;
    reg cdone;
    begin
      div_clz64 = 7'd64;
      cdone = 1'b0;
      for (ci = `XLEN-1; ci >= 0; ci = ci - 1) begin
        if (!cdone && v[ci]) begin
          div_clz64 = 7'd63 - ci[6:0];
          cdone = 1'b1;
        end
      end
    end
  endfunction
  wire [6:0] div_clz_w = div_clz64(req_op1_abs_w);
  wire [6:0] div_clz_even_w = {div_clz_w[6:1], 1'b0};
  wire [`XLEN-1:0] div_dividend_pos_w = req_op1_abs_w << div_clz_even_w;
  wire [6:0] div_count_init_w = 7'd64 - div_clz_even_w;
  wire req_op1_zero_w = (req_op1_abs_w == {`XLEN{1'b0}});

  // 为什么这么改：radix-2 每周期只解出 1 个商位(word 32 拍/dword 64 拍)。改为 radix-4
  // 每周期解出 2 个商位(word 16 拍/dword 32 拍)——把当前部分余数左移 2 位并带入被除数
  // 高 2 位形成 partial，与 {1,2,3}×divisor 比较选商位 q∈{0..3}，减去 q×divisor 得新余数。
  // 余数恒 <divisor(≤2^XLEN-1)，partial 最多 ~4×divisor 需 XLEN+2 位中间宽度。商位拼接、
  // 被除数左移 2 位、count 每拍 -2。结果与 radix-2 等价，但除法延迟再减半。
  wire [`XLEN+1:0] div_partial_w =
      {div_rem_q[`XLEN-1:0], div_dividend_q[`XLEN-1:`XLEN-2]};
  wire [`XLEN+1:0] div_d1_w = {2'b0, div_divisor_q};
  wire [`XLEN+1:0] div_d2_w = {1'b0, div_divisor_q, 1'b0};
  wire [`XLEN+1:0] div_d3_w = div_d3_q;  // 3×divisor 已在装载时寄存(移出迭代环加法器)
  wire [1:0] div_q_digit_w =
      (div_partial_w >= div_d3_w) ? 2'd3 :
      (div_partial_w >= div_d2_w) ? 2'd2 :
      (div_partial_w >= div_d1_w) ? 2'd1 : 2'd0;
  wire [`XLEN+1:0] div_sub_w =
      (div_q_digit_w == 2'd3) ? div_d3_w :
      (div_q_digit_w == 2'd2) ? div_d2_w :
      (div_q_digit_w == 2'd1) ? div_d1_w : {(`XLEN+2){1'b0}};
  wire [`XLEN+1:0] div_partial_rem_w = div_partial_w - div_sub_w;
  wire [`XLEN:0] div_rem_next_w = {1'b0, div_partial_rem_w[`XLEN-1:0]};
  wire [`XLEN-1:0] div_quot_next_w = {div_quot_q[`XLEN-3:0], div_q_digit_w};
  wire [`XLEN-1:0] div_dividend_next_w = {div_dividend_q[`XLEN-3:0], 2'b0};
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

  // UC-A mispredict-kill: age 表达式逐字复用 OooFpArithGate fp_meta_killed —— 严格年轻 '>'(kill 点自身
  // NOT killed)、三操作数同宽 ROB_INDEX_W 无符号模减(ROB 环上把队头旋到 0 天然处理 wrap)。kill_valid_i=0
  // 时恒 0 → 下方 gate 全退化为原逻辑, 行为逐字不变。
  function muldiv_killed;
    input [ROB_INDEX_W-1:0] idx;
    muldiv_killed = kill_valid_i &&
        ((idx - rob_head_idx_i) > (kill_rob_idx_i - rob_head_idx_i));
  endfunction
  wire kill_inflight_w =
      ((state_q == STATE_MUL_RUN) || (state_q == STATE_DIV_RUN) || (state_q == STATE_RESP)) &&
      muldiv_killed(resp_rob_idx_q);
  wire kill_new_req_w = req_fire_w && muldiv_killed(req_rob_idx_i);

  assign req_ready_o = state_q == STATE_IDLE;
  // 组合抹 resp_valid_o(载重项, 对齐 FP out_valid_o 的 && !killed): kill 命中 STATE_RESP 当拍即不写脏值
  assign resp_valid_o = (state_q == STATE_RESP) && !kill_inflight_w;
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
      div_d3_q <= {(`XLEN+2){1'b0}};
      div_quot_q <= {`XLEN{1'b0}};
      div_rem_q <= {(`XLEN+1){1'b0}};
      div_count_q <= 7'd0;
      div_rem_result_q <= 1'b0;
      div_quot_neg_q <= 1'b0;
      div_rem_neg_q <= 1'b0;
      div_word_q <= 1'b0;
      mul_acc_q <= {(`XLEN*2){1'b0}};
      mul_multiplicand_q <= {(`XLEN*2){1'b0}};
      mul_multiplier_q <= {`XLEN{1'b0}};
      mul_count_q <= 7'd0;
      mul_funct3_q <= 3'b000;
      mul_word_q <= 1'b0;
      mul_neg_q <= 1'b0;
    end else if (kill_inflight_w) begin
      // UC-A: kill 命中在飞 op → 强制回 IDLE(覆盖优先, 胜过 case 的 DIV_RUN/RESP 推进), 抹 resp 身份防脏写回
      state_q <= STATE_IDLE;
      resp_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      resp_data_q <= {`XLEN{1'b0}};
    end else begin
      case (state_q)
        STATE_IDLE: begin
          if (req_fire_w && !kill_new_req_w) begin
            resp_rob_idx_q <= req_rob_idx_i;
            resp_pdest_q <= req_pdest_i;
            if (!req_is_div_w) begin
              mul_acc_q <= {(`XLEN*2){1'b0}};
              mul_multiplicand_q <= {{`XLEN{1'b0}}, req_mul_op1_abs_w};
              mul_multiplier_q <= req_mul_op2_abs_w;
              mul_count_q <= 7'd64;
              mul_funct3_q <= req_funct3_w;
              mul_word_q <= req_word_i;
              mul_neg_q <= req_mul_neg_w;
              state_q <= STATE_MUL_RUN;
            end else if (req_div_by_zero_w || req_signed_overflow_w) begin
              resp_data_q <= req_special_result_final_w;
              state_q <= STATE_RESP;
            end else if (req_op1_zero_w) begin
              // 0/d = 0、0%d = 0（d!=0 已由上面排除）；word 下 sign_extend_word(0)=0。
              resp_data_q <= {`XLEN{1'b0}};
              state_q <= STATE_RESP;
            end else begin
              // CLZ 定位：把 abs 左移使其 MSB 到 bit63，只跑有效位的 radix-4 迭代。
              // 取代原 word({abs,32'd0}/32 拍)与 dword(64 拍)固定方案，对小操作数大幅减拍。
              div_dividend_q <= div_dividend_pos_w;
              div_divisor_q <= req_op2_abs_w;
              div_d3_q <= {1'b0, req_op2_abs_w, 1'b0} +
                          {2'b0, req_op2_abs_w};  // 3×divisor 预算并寄存
              div_quot_q <= {`XLEN{1'b0}};
              div_rem_q <= {(`XLEN+1){1'b0}};
              div_count_q <= div_count_init_w;
              div_rem_result_q <= req_is_rem_w;
              div_quot_neg_q <= req_signed_w && (req_op1_neg_w ^ req_op2_neg_w);
              div_rem_neg_q <= req_signed_w && req_op1_neg_w;
              div_word_q <= req_word_i;
              state_q <= STATE_DIV_RUN;
            end
          end
        end

        STATE_MUL_RUN: begin
          mul_acc_q <= mul_acc_next_w;
          mul_multiplicand_q <= mul_multiplicand_next_w;
          mul_multiplier_q <= mul_multiplier_next_w;
          mul_count_q <= mul_count_q - 7'd1;
          if (mul_count_q == 7'd1) begin
            resp_data_q <= mul_result_final_w;
            state_q <= STATE_RESP;
          end
        end

        STATE_DIV_RUN: begin
          div_dividend_q <= div_dividend_next_w;
          div_quot_q <= div_quot_next_w;
          div_rem_q <= div_rem_next_w;
          div_count_q <= div_count_q - 7'd2;  // radix-4: 每拍解 2 个商位
          if (div_count_q == 7'd2) begin       // 处理完最后 2 位即收尾
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
