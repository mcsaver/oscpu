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
  output [PRODUCER_ID_W-1:0] owner_producer_id_o,
  output [(1 << PRODUCER_ID_W)-1:0] owner_live_mask_o
);
  localparam RESULT_DEPTH=8;
  wire request_is_div_w=req_inst_i[14];
  wire div_ready_w, div_valid_w, div_owner_w;
  wire [PRODUCER_ID_W-1:0] div_pid_w;
  wire [PHY_REG_ADDR_W-1:0] div_pdest_w;
  wire [63:0] div_result_w;
  wire [ROB_INDEX_W-1:0] div_rob_unused_w;
  wire [PRODUCER_ID_W-1:0] div_owner_pid_w;

  reg [2:0] mul_valid_q;
  reg [2:0] mul_killed_q;
  reg [PRODUCER_ID_W-1:0] mul_pid_q [0:2];
  reg [PHY_REG_ADDR_W-1:0] mul_pdest_q [0:2];
  wire [2:0] mul_kill_now_w;
  reg [3:0] reserved_q;
  reg [2:0] result_read_q, result_write_q;
  reg [3:0] result_count_q;
  reg [RESULT_DEPTH-1:0] result_present_q, result_killed_q;
  reg [PRODUCER_ID_W-1:0] result_pid_q [0:RESULT_DEPTH-1];
  reg [PHY_REG_ADDR_W-1:0] result_pdest_q [0:RESULT_DEPTH-1];
  reg [63:0] result_data_q [0:RESULT_DEPTH-1];
  wire [RESULT_DEPTH-1:0] result_kill_now_w;
  wire arithmetic_valid_w;
  wire [63:0] arithmetic_result_w;
  wire mul_req_ready_w=reserved_q < 4'd8 && !rst && !flush_i && !kill_valid_i;
  wire mul_req_fire_w=req_valid_i && !request_is_div_w && mul_req_ready_w;
  wire mul_head_present_w=(result_count_q != 0);
  wire mul_head_dead_w=result_killed_q[result_read_q] || result_kill_now_w[result_read_q];
  wire mul_response_valid_w=mul_head_present_w && !mul_head_dead_w && !rst && !flush_i;

  // 租约只观察寄存状态，包含待排空的被杀项；不会用当拍 ready 提前释放身份。
  reg [(1 << PRODUCER_ID_W)-1:0] mul_live_mask_w;
  integer live_idx;
  always @(*) begin
    mul_live_mask_w={(1 << PRODUCER_ID_W){1'b0}};
    for (live_idx=0; live_idx<3; live_idx=live_idx+1)
      if (mul_valid_q[live_idx]) mul_live_mask_w[mul_pid_q[live_idx]]=1'b1;
    for (live_idx=0; live_idx<RESULT_DEPTH; live_idx=live_idx+1)
      if (result_present_q[live_idx]) mul_live_mask_w[result_pid_q[live_idx]]=1'b1;
  end
  wire [(1 << PRODUCER_ID_W)-1:0] div_live_mask_w=div_owner_w ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}},1'b1} << div_owner_pid_w) :
      {(1 << PRODUCER_ID_W){1'b0}};
  assign owner_live_mask_o=mul_live_mask_w | div_live_mask_w;

  wire [ROB_INDEX_W-1:0] kill_age_w=kill_rob_idx_i-rob_head_idx_i;
  genvar entry;
  generate
    for (entry=0; entry<3; entry=entry+1) begin : gen_pipeline_kill
      wire [ROB_INDEX_W-1:0] age_w=mul_pid_q[entry][ROB_INDEX_W-1:0]-rob_head_idx_i;
      assign mul_kill_now_w[entry]=kill_valid_i && age_w>kill_age_w;
    end
    for (entry=0; entry<RESULT_DEPTH; entry=entry+1) begin : gen_result_kill
      wire [ROB_INDEX_W-1:0] age_w=result_pid_q[entry][ROB_INDEX_W-1:0]-rob_head_idx_i;
      assign result_kill_now_w[entry]=kill_valid_i && age_w>kill_age_w;
    end
  endgenerate

  reg response_locked_q, response_div_q;
  wire select_div_w=response_locked_q ? response_div_q : div_valid_w;
  wire selected_valid_w=select_div_w ? div_valid_w : mul_response_valid_w;
  wire mul_response_ready_w=!select_div_w && resp_ready_i;
  wire result_pop_w=mul_head_present_w && (mul_head_dead_w || mul_response_ready_w);
  wire result_push_w=mul_valid_q[2];

  assign req_ready_o=request_is_div_w ? div_ready_w : mul_req_ready_w;
  assign resp_valid_o=selected_valid_w;
  assign resp_data_o=select_div_w ? div_result_w : result_data_q[result_read_q];
  assign resp_pdest_o=select_div_w ? div_pdest_w : result_pdest_q[result_read_q];
  assign resp_producer_id_o=select_div_w ? div_pid_w : result_pid_q[result_read_q];
  assign resp_rob_idx_o=resp_producer_id_o[ROB_INDEX_W-1:0];
  assign owner_valid_o=(reserved_q != 0) || div_owner_w;
  // 单项投影供诊断使用；重命名出生检查使用上面的完整 live mask。
  assign owner_producer_id_o=(reserved_q != 0) ?
      (mul_head_present_w ? result_pid_q[result_read_q] :
       mul_valid_q[2] ? mul_pid_q[2] :
       mul_valid_q[1] ? mul_pid_q[1] : mul_pid_q[0]) : div_owner_pid_w;

  OooMulPipeline u_multiply (
    .clk(clk), .rst(rst), .flush_i(flush_i),
    .valid_i(mul_req_fire_w), .src1_i(req_src1_i), .src2_i(req_src2_i),
    .funct3_i(req_inst_i[14:12]), .word_i(req_word_i),
    .valid_o(arithmetic_valid_w), .result_o(arithmetic_result_w)
  );
  OooDivUnit #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W), .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W), .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_divide (
    .clk(clk), .rst(rst), .flush_i(flush_i),
    .kill_valid_i(kill_valid_i), .kill_rob_idx_i(kill_rob_idx_i),
    .rob_head_idx_i(rob_head_idx_i),
    .req_valid_i(req_valid_i && request_is_div_w), .req_ready_o(div_ready_w),
    .req_producer_id_i(req_producer_id_i), .req_pdest_i(req_pdest_i),
    .req_inst_i(req_inst_i), .req_src1_i(req_src1_i), .req_src2_i(req_src2_i),
    .req_word_i(req_word_i), .resp_valid_o(div_valid_w),
    .resp_ready_i(select_div_w && resp_ready_i), .resp_rob_idx_o(div_rob_unused_w),
    .resp_producer_id_o(div_pid_w), .resp_pdest_o(div_pdest_w), .resp_data_o(div_result_w),
    .owner_valid_o(div_owner_w), .owner_producer_id_o(div_owner_pid_w)
  );

  integer stage_idx;
  integer result_idx;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      mul_valid_q<=3'b000; mul_killed_q<=3'b000;
      reserved_q<=4'd0; result_count_q<=4'd0;
      result_read_q<=3'd0; result_write_q<=3'd0;
      result_present_q<=8'd0; result_killed_q<=8'd0;
      response_locked_q<=1'b0; response_div_q<=1'b0;
    end else begin
      response_locked_q<=selected_valid_w && !resp_ready_i;
      if (!response_locked_q) response_div_q<=select_div_w;

      mul_valid_q<={mul_valid_q[1:0],mul_req_fire_w};
      mul_killed_q<={mul_killed_q[1:0] | mul_kill_now_w[1:0],1'b0};
      if (mul_req_fire_w) begin
        mul_pid_q[0]<=req_producer_id_i; mul_pdest_q[0]<=req_pdest_i;
      end
      for (stage_idx=1; stage_idx<3; stage_idx=stage_idx+1)
        if (mul_valid_q[stage_idx-1]) begin
          mul_pid_q[stage_idx]<=mul_pid_q[stage_idx-1];
          mul_pdest_q[stage_idx]<=mul_pdest_q[stage_idx-1];
        end

      case ({mul_req_fire_w,result_pop_w})
        2'b10: reserved_q<=reserved_q+4'd1;
        2'b01: reserved_q<=reserved_q-4'd1;
        default: begin end
      endcase
      case ({result_push_w,result_pop_w})
        2'b10: result_count_q<=result_count_q+4'd1;
        2'b01: result_count_q<=result_count_q-4'd1;
        default: begin end
      endcase
      for (result_idx=0; result_idx<RESULT_DEPTH; result_idx=result_idx+1)
        if (result_present_q[result_idx] && result_kill_now_w[result_idx])
          result_killed_q[result_idx]<=1'b1;
      if (result_push_w) begin
        result_pid_q[result_write_q]<=mul_pid_q[2];
        result_pdest_q[result_write_q]<=mul_pdest_q[2];
        result_data_q[result_write_q]<=arithmetic_result_w;
        result_killed_q[result_write_q]<=mul_killed_q[2] || mul_kill_now_w[2];
        result_present_q[result_write_q]<=1'b1;
        result_write_q<=result_write_q+3'd1;
      end
      if (result_pop_w) begin
        result_present_q[result_read_q]<=1'b0;
        result_read_q<=result_read_q+3'd1;
      end
    end
  end

`ifdef OOO_ASSERT
  always @(posedge clk) if (!rst && !flush_i) begin
    if (reserved_q>4'd8) $error("[MUL-CREDIT] result reservation overflow");
    if (result_push_w && result_count_q==4'd8)
      $error("[MUL-CREDIT] unreserved pipeline completion");
    if (arithmetic_valid_w !== mul_valid_q[2])
      $error("[MUL-META] numerical and identity pipelines diverged");
    if (result_pop_w && reserved_q==0) $error("[MUL-CREDIT] unowned completion");
    if (resp_valid_o && !owner_live_mask_o[resp_producer_id_o])
      $error("[MULDIV-PID] result has no live producer");
  end
`endif
endmodule
