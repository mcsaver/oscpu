`include "define.v"

module OooMulDivUnit #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W
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
  input [PRODUCER_ID_W-1:0] req_producer_id_i,
  input [PHY_REG_ADDR_W-1:0] req_pdest_i,
  input [`INST_W-1:0] req_inst_i,
  input [`XLEN-1:0] req_src1_i,
  input [`XLEN-1:0] req_src2_i,
  input req_word_i,

  output resp_valid_o,
  input resp_ready_i,
  output [ROB_INDEX_W-1:0] resp_rob_idx_o,
  output [PRODUCER_ID_W-1:0] resp_producer_id_o,
  output [PHY_REG_ADDR_W-1:0] resp_pdest_o,
  output [`XLEN-1:0] resp_data_o,

  output owner_valid_o,
  output [PRODUCER_ID_W-1:0] owner_producer_id_o
);

  localparam STATE_IDLE = 3'd0;
  localparam STATE_REQ_BUF = 3'd1;
  localparam STATE_MUL_RUN = 3'd2;
  localparam STATE_DIV_RUN = 3'd3;
  localparam STATE_RESP = 3'd4;

  reg [2:0] state_q;
  // T3Q: 非穿透请求级只捕获完整 payload；abs/CLZ/3x 与迭代状态初始化统一从下一拍 Q 侧出发。
  // v8h: ProducerId 是 holder 唯一身份状态；raw ROB index 只从低位投影。
  reg [PRODUCER_ID_W-1:0] producer_id_q;
  reg [PHY_REG_ADDR_W-1:0] req_pdest_q;
  reg [`INST_W-1:0] req_inst_q;
  reg [`XLEN-1:0] req_src1_q;
  reg [`XLEN-1:0] req_src2_q;
  reg req_word_q;
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
  // radix-4: 3×multiplicand 在乘法期间与 multiplicand 保持 ×3 关系(两者同步 <<2),
  // 装载拍算一次并寄存,移出每拍迭代环(镜像 div_d3_q 的时序优化)。
  reg [(`XLEN*2)-1:0] mul_m3_q;
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
  wire [2:0] req_funct3_w = req_inst_q[14:12];
  wire req_is_div_w = req_funct3_w[2];
  wire req_is_rem_w = req_inst_q[13];
  wire req_signed_w = !req_inst_q[12];
  wire [`XLEN-1:0] req_mul_op1_w =
      req_word_q ? sign_extend_word(req_src1_q[31:0]) : req_src1_q;
  wire [`XLEN-1:0] req_mul_op2_w =
      req_word_q ? sign_extend_word(req_src2_q[31:0]) : req_src2_q;
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
  wire req_word_unsigned_w = req_word_q && req_inst_q[12];
  wire [`XLEN-1:0] req_op1_w =
      req_word_q ? (req_word_unsigned_w ? zero_extend_word(req_src1_q[31:0]) :
                                          sign_extend_word(req_src1_q[31:0])) :
                   req_src1_q;
  wire [`XLEN-1:0] req_op2_w =
      req_word_q ? (req_word_unsigned_w ? zero_extend_word(req_src2_q[31:0]) :
                                          sign_extend_word(req_src2_q[31:0])) :
                   req_src2_q;
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
      req_word_q ? sign_extend_word(req_special_result_w[31:0]) :
                   req_special_result_w;

  // radix-4 无符号数字迭代(非 Booth): 每拍消费 multiplier 低 2 位 digit∈{0..3},
  // addend 从 {0, M, M<<1, 3M(寄存)} 四选一,加法器仍是同一条 128 位。
  // 移位丢高位安全: digit_k 非零时部分积 digit_k×M×4^k ≤ 幅值积 < 2^128(multiplier ≥ digit_k×4^k)。
  wire [1:0] mul_digit_w = mul_multiplier_q[1:0];
  wire [(`XLEN*2)-1:0] mul_addend_w =
      (mul_digit_w == 2'd3) ? mul_m3_q :
      (mul_digit_w == 2'd2) ? {mul_multiplicand_q[(`XLEN*2)-2:0], 1'b0} :
      (mul_digit_w == 2'd1) ? mul_multiplicand_q : {(`XLEN*2){1'b0}};
  wire [(`XLEN*2)-1:0] mul_acc_next_w = mul_acc_q + mul_addend_w;
  wire [(`XLEN*2)-1:0] mul_multiplicand_next_w =
      {mul_multiplicand_q[(`XLEN*2)-3:0], 2'b00};
  // 3M<<2 = 3×(M<<2),×3 关系逐拍保持,零额外加法
  wire [(`XLEN*2)-1:0] mul_m3_next_w = {mul_m3_q[(`XLEN*2)-3:0], 2'b00};
  wire [`XLEN-1:0] mul_multiplier_next_w =
      {2'b00, mul_multiplier_q[`XLEN-1:2]};
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

  // MUL 侧 CLZ 早退出 + 操作数 swap。幅值乘法可交换,mul_neg=op1_neg^op2_neg 与角色
  // 无关(MULHSU 的非对称符号提取在 swap 之前的原始角色上完成)——swap 符号代价为零。
  // 选小幅值当 multiplier(a<b ⇒ clz(a)≥clz(b),无符号比较与 clz 比较单调等价)。
  wire mul_swap_w = req_mul_op1_abs_w < req_mul_op2_abs_w;
  wire [`XLEN-1:0] mul_mcand_sel_w =
      mul_swap_w ? req_mul_op2_abs_w : req_mul_op1_abs_w;
  wire [`XLEN-1:0] mul_mplier_sel_w =
      mul_swap_w ? req_mul_op1_abs_w : req_mul_op2_abs_w;
  wire [6:0] mul_clz_w = div_clz64(mul_mplier_sel_w);
  wire [6:0] mul_clz_even_w = {mul_clz_w[6:1], 1'b0};
  wire [6:0] mul_count_init_w = 7'd64 - mul_clz_even_w;
  // 零特判必须查两侧: 只查固定一侧在 op1=0+swap 场景漏判 → count_init=0 绕回
  // ~64 拍(结果仍正确、全门禁假 pass)。任一幅值 0 ⇒ 积恒 0,全变体(含 MULH 族
  // 高位/negate/word sext)结果都是 0,装载拍直进 RESP。
  wire mul_any_zero_w = (req_mul_op1_abs_w == {`XLEN{1'b0}}) ||
                        (req_mul_op2_abs_w == {`XLEN{1'b0}});

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

  // UC-A mispredict-kill: age 表达式与 OooFpArithGate fp_meta_killed 同构 —— 严格年轻 '>'(kill 点自身
  // NOT killed)、三操作数同宽 ROB_INDEX_W 无符号模减(ROB 环上把队头旋到 0 天然处理 wrap)。
  // 刀X 修复: 原 function 形态在 iverilog 下函数体引用的 kill_valid_i/kill_rob_idx_i/rob_head_idx_i
  // 不进连续赋值敏感列表(hidden dependency), kill 脉冲被无视——展开为显式 wire。
  // 两仿真器中仅展开形态在 iverilog 下正确(另一家两形态一致)。函数体引用模块级变量禁令家族。
  wire [ROB_INDEX_W-1:0] kill_age_thresh_w = kill_rob_idx_i - rob_head_idx_i;
  wire [ROB_INDEX_W-1:0] owner_rob_idx_w =
      producer_id_q[ROB_INDEX_W-1:0];
  wire [ROB_INDEX_W-1:0] kill_age_owner_w = owner_rob_idx_w - rob_head_idx_i;
  wire kill_inflight_w =
      (state_q != STATE_IDLE) && kill_valid_i &&
      (kill_age_owner_w > kill_age_thresh_w);

  assign req_ready_o = (state_q == STATE_IDLE) && !rst && !flush_i && !kill_valid_i;
  // 组合抹 resp_valid_o(载重项, 对齐 FP out_valid_o 的 && !killed): kill 命中 STATE_RESP 当拍即不写脏值
  assign resp_valid_o = (state_q == STATE_RESP) && !rst && !flush_i &&
                        !kill_inflight_w;
  assign resp_rob_idx_o = owner_rob_idx_w;
  assign resp_producer_id_o = producer_id_q;
  assign resp_pdest_o = resp_pdest_q;
  assign resp_data_o = resp_data_q;
  assign owner_valid_o = state_q != STATE_IDLE;
  assign owner_producer_id_o = producer_id_q;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      state_q <= STATE_IDLE;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
      req_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      req_inst_q <= {`INST_W{1'b0}};
      req_src1_q <= {`XLEN{1'b0}};
      req_src2_q <= {`XLEN{1'b0}};
      req_word_q <= 1'b0;
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
      mul_m3_q <= {(`XLEN*2){1'b0}};
      mul_multiplier_q <= {`XLEN{1'b0}};
      mul_count_q <= 7'd0;
      mul_funct3_q <= 3'b000;
      mul_word_q <= 1'b0;
      mul_neg_q <= 1'b0;
    end else if (kill_inflight_w) begin
      // UC-A/T3Q: kill 命中缓冲或在飞 op → 强制回 IDLE，抹身份防止下一拍初始化或脏写回。
      state_q <= STATE_IDLE;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
      req_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      req_inst_q <= {`INST_W{1'b0}};
      req_src1_q <= {`XLEN{1'b0}};
      req_src2_q <= {`XLEN{1'b0}};
      req_word_q <= 1'b0;
      resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      resp_data_q <= {`XLEN{1'b0}};
    end else begin
      case (state_q)
        STATE_IDLE: begin
          if (req_fire_w) begin
            // 非穿透边界：该拍只锁存请求，禁止从外部 payload 直接初始化运算数据通路。
            producer_id_q <= req_producer_id_i;
            req_pdest_q <= req_pdest_i;
            req_inst_q <= req_inst_i;
            req_src1_q <= req_src1_i;
            req_src2_q <= req_src2_i;
            req_word_q <= req_word_i;
            state_q <= STATE_REQ_BUF;
          end
        end

        STATE_REQ_BUF: begin
          resp_pdest_q <= req_pdest_q;
          if (!req_is_div_w) begin
            if (mul_any_zero_w) begin
              // R1 防线: 任一幅值 0 装载拍直进 RESP,禁走 count_init=0 绕回
              resp_data_q <= {`XLEN{1'b0}};
              state_q <= STATE_RESP;
            end else begin
              mul_acc_q <= {(`XLEN*2){1'b0}};
              mul_multiplicand_q <= {{`XLEN{1'b0}}, mul_mcand_sel_w};
              // 3M 装载拍预算(128 位语境下 (M<<1)+M,有效宽 66 位),镜像 div_d3_q
              mul_m3_q <= {{(`XLEN-1){1'b0}}, mul_mcand_sel_w, 1'b0} +
                          {{`XLEN{1'b0}}, mul_mcand_sel_w};
              mul_multiplier_q <= mul_mplier_sel_w;
              mul_count_q <= mul_count_init_w;
              mul_funct3_q <= req_funct3_w;
              mul_word_q <= req_word_q;
              mul_neg_q <= req_mul_neg_w;
              state_q <= STATE_MUL_RUN;
            end
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
            div_word_q <= req_word_q;
            state_q <= STATE_DIV_RUN;
          end
        end

        STATE_MUL_RUN: begin
          mul_acc_q <= mul_acc_next_w;
          mul_multiplicand_q <= mul_multiplicand_next_w;
          mul_m3_q <= mul_m3_next_w;
          mul_multiplier_q <= mul_multiplier_next_w;
          mul_count_q <= mul_count_q - 7'd2;  // radix-4: 每拍消费 2 位
          if (mul_count_q == 7'd2) begin      // 处理完最后 2 位即收尾(镜像 DIV)
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
            producer_id_q <= {PRODUCER_ID_W{1'b0}};
            resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
            resp_data_q <= {`XLEN{1'b0}};
          end
        end

        default: begin
          state_q <= STATE_IDLE;
          producer_id_q <= {PRODUCER_ID_W{1'b0}};
        end
      endcase
    end
  end

`ifdef OOO_ASSERT
  // MD-I8: capture 后必须先驻留非穿透请求级，且完整 payload 与 capture 拍逐位一致。
  reg md_req_capture_pending_q;
  reg [PRODUCER_ID_W-1:0] md_req_producer_id_q;
  reg [PHY_REG_ADDR_W-1:0] md_req_pdest_q;
  reg [`INST_W-1:0] md_req_inst_q;
  reg [`XLEN-1:0] md_req_src1_q;
  reg [`XLEN-1:0] md_req_src2_q;
  reg md_req_word_q;
  always @(posedge clk) begin
    if (rst || flush_i || kill_inflight_w) begin
      md_req_capture_pending_q <= 1'b0;
    end else begin
      if (md_req_capture_pending_q) begin
        if ((state_q != STATE_REQ_BUF) ||
            (producer_id_q !== md_req_producer_id_q) ||
            (req_pdest_q !== md_req_pdest_q) ||
            (req_inst_q !== md_req_inst_q) ||
            (req_src1_q !== md_req_src1_q) ||
            (req_src2_q !== md_req_src2_q) ||
            (req_word_q !== md_req_word_q)) begin
          $error("[MD-I8] request buffer 未形成完整非穿透 capture @%0t", $time);
          $fatal;
        end
        md_req_capture_pending_q <= 1'b0;
      end
      if ((state_q == STATE_IDLE) && req_fire_w) begin
        md_req_capture_pending_q <= 1'b1;
        md_req_producer_id_q <= req_producer_id_i;
        md_req_pdest_q <= req_pdest_i;
        md_req_inst_q <= req_inst_i;
        md_req_src1_q <= req_src1_i;
        md_req_src2_q <= req_src2_i;
        md_req_word_q <= req_word_i;
      end
      if ((state_q == STATE_REQ_BUF) && req_ready_o) begin
        $error("[MD-I8] request buffer 驻留时错误开放 ready @%0t", $time);
        $fatal;
      end
      if ((owner_valid_o !== (state_q != STATE_IDLE)) ||
          (owner_producer_id_o !== producer_id_q) ||
          (resp_rob_idx_o !== producer_id_q[ROB_INDEX_W-1:0]) ||
          (resp_producer_id_o !== producer_id_q)) begin
        $error("[V8H-MD-PID-PROJECTION] holder identity projection mismatch @%0t", $time);
        $fatal;
      end
      if ((rst || flush_i || kill_valid_i) && req_ready_o) begin
        $error("[V8H-MD-REQ-GUARD] request ready during reset/flush/kill @%0t", $time);
        $fatal;
      end
    end
  end

  // MD-I6/MD-I7: MUL 早退出等价与拍数不变量(sim-only,行为乘法金标准)。
  // golden 在装载拍用 * 一步算出最终期望 resp_data(含 negate+funct3 切片+word sext),
  // RESP 拍纯等值比对——断言逻辑最小化,写错方向假 fail 的面最小。
  wire [(`XLEN*2)-1:0] md_g_prod_w = req_mul_op1_abs_w * req_mul_op2_abs_w;
  wire [(`XLEN*2)-1:0] md_g_sprod_w =
      req_mul_neg_w ? (~md_g_prod_w + {{((`XLEN*2)-1){1'b0}}, 1'b1}) : md_g_prod_w;
  reg [`XLEN-1:0] md_g_raw_w;
  always @(*) begin
    case (req_funct3_w)
      3'b000: md_g_raw_w = md_g_sprod_w[`XLEN-1:0];
      3'b001,
      3'b010,
      3'b011: md_g_raw_w = md_g_sprod_w[(`XLEN*2)-1:`XLEN];
      default: md_g_raw_w = {`XLEN{1'b0}};
    endcase
  end
  wire [`XLEN-1:0] md_g_final_w =
      req_word_q ? sign_extend_word(md_g_raw_w[31:0]) : md_g_raw_w;

  reg [`XLEN-1:0] md_mul_golden_q;
  reg md_mul_golden_valid_q;
  reg [6:0] md_mul_expect_iters_q;
  reg [7:0] md_mul_iters_q;
  wire md_mul_load_w = (state_q == STATE_REQ_BUF) && !req_is_div_w;
  always @(posedge clk) begin
    if (rst || flush_i || kill_inflight_w) begin
      md_mul_golden_valid_q <= 1'b0;
      md_mul_iters_q <= 8'd0;
    end else if (md_mul_load_w) begin
      md_mul_golden_q <= md_g_final_w;
      md_mul_golden_valid_q <= 1'b1;
      md_mul_expect_iters_q <= mul_any_zero_w ? 7'd0 : (mul_count_init_w >> 1);
      md_mul_iters_q <= 8'd0;
      // MD-I7: 非零装载的 count_init 恒偶且 >=2(零特判保证不进 MUL_RUN 绕回)
      if (!mul_any_zero_w &&
          (mul_count_init_w[0] || (mul_count_init_w < 7'd2))) begin
        $error("[MD-I7] MUL count_init=%0d 非偶或 <2 @%0t", mul_count_init_w, $time);
        $fatal;
      end
    end else if (state_q == STATE_REQ_BUF) begin
      md_mul_golden_valid_q <= 1'b0;  // DIV 装载: 清 MUL golden,DIV 的 RESP 不比对
      md_mul_iters_q <= 8'd0;
    end else if (state_q == STATE_MUL_RUN) begin
      md_mul_iters_q <= md_mul_iters_q + 8'd1;
      // 拍数精确不变量: MUL_RUN 总拍数必须恰为 count_init/2——早退出被放宽/绕回即 fire
      if ((mul_count_q == 7'd2) &&
          ((md_mul_iters_q + 8'd1) != {1'b0, md_mul_expect_iters_q})) begin
        $error("[MD-I7] MUL 拍数=%0d != 预期 %0d @%0t",
               md_mul_iters_q + 8'd1, md_mul_expect_iters_q, $time);
        $fatal;
      end
    end else if ((state_q == STATE_RESP) && resp_valid_o && resp_ready_i) begin
      // MD-I6: RESP 消费拍终值等价比对(迭代路径与零特判路径统一在此)
      if (md_mul_golden_valid_q && (resp_data_o !== md_mul_golden_q)) begin
        $error("[MD-I6] MUL resp=%h != golden=%h @%0t",
               resp_data_o, md_mul_golden_q, $time);
        $fatal;
      end
      md_mul_golden_valid_q <= 1'b0;
    end
  end
`endif

endmodule
