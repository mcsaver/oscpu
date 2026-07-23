`include "define.v"

module OooClmulUnit #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W
) (
  input clk,
  input rst,
  input flush_i,
  // UC-A mispredict-kill: CLMUL 同 MulDiv 缺口(A1 哨兵实测 rv64uzbc-p-clmul 撞号)，补齐 kill 端口
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,

  input req_valid_i,
  output req_ready_o,
  input [PRODUCER_ID_W-1:0] req_producer_id_i,
  input [PHY_REG_ADDR_W-1:0] req_pdest_i,
  input [1:0] req_op_i,
  input [`XLEN-1:0] req_src1_i,
  input [`XLEN-1:0] req_src2_i,

  output resp_valid_o,
  input resp_ready_i,
  output [ROB_INDEX_W-1:0] resp_rob_idx_o,
  output [PRODUCER_ID_W-1:0] resp_producer_id_o,
  output [PHY_REG_ADDR_W-1:0] resp_pdest_o,
  output [`XLEN-1:0] resp_data_o,

  output owner_valid_o,
  output [PRODUCER_ID_W-1:0] owner_producer_id_o
);

  localparam [1:0] STATE_IDLE = 2'd0;
  localparam [1:0] STATE_RUN = 2'd1;
  localparam [1:0] STATE_RESP = 2'd2;

  localparam [1:0] CLMUL_OP_LOW = 2'd0;
  localparam [1:0] CLMUL_OP_HIGH = 2'd1;
  localparam [1:0] CLMUL_OP_REV = 2'd2;

  reg [1:0] state_q;
  // v8h: full ProducerId 是唯一 owner identity；raw index 只从低位投影。
  reg [PRODUCER_ID_W-1:0] producer_id_q;
  reg [PHY_REG_ADDR_W-1:0] resp_pdest_q;
  reg [`XLEN-1:0] resp_data_q;

  reg [1:0] op_q;
  reg [6:0] iter_q;
  reg [`XLEN-1:0] acc_q;
  reg [`XLEN-1:0] lhs_shift_q;
  reg [`XLEN-1:0] rhs_shift_q;
  reg [`XLEN-1:0] rhs_right_shift_q;

  wire req_fire_w = req_valid_i && req_ready_o;
  wire run_low_w = op_q == CLMUL_OP_LOW;
  wire run_high_w = op_q == CLMUL_OP_HIGH;
  wire run_rev_w = op_q == CLMUL_OP_REV;
  wire step_bit_w = run_low_w ? rhs_shift_q[0] : rhs_shift_q[`XLEN-1];
  wire [`XLEN-1:0] step_partial_w =
      run_low_w ? lhs_shift_q : rhs_right_shift_q;
  wire [`XLEN-1:0] step_acc_w =
      acc_q ^ (step_bit_w ? step_partial_w : {`XLEN{1'b0}});
  wire [`XLEN-1:0] lhs_shift_next_w = {lhs_shift_q[`XLEN-2:0], 1'b0};
  wire [`XLEN-1:0] rhs_shift_right_next_w = {1'b0, rhs_shift_q[`XLEN-1:1]};
  wire [`XLEN-1:0] rhs_shift_left_next_w = {rhs_shift_q[`XLEN-2:0], 1'b0};
  wire [`XLEN-1:0] rhs_right_shift_next_w =
      {1'b0, rhs_right_shift_q[`XLEN-1:1]};
  wire iter_last_w = iter_q == 7'd63;

  // UC-A mispredict-kill: age 表达式与 MulDiv 同构（严格年轻 '>'，环形模减）。
  // 禁止把 kill/head/cut 作为 function 的 ambient 依赖：Icarus
  // 不会在只变化这些自由变量时稳定重算连续赋值，会让
  // matching kill 同拍漏出 stale response。三个 ROB index 等宽模减，
  // 自然覆盖 tail/head 环回；严格 '>' 保留 kill 点自身。
  wire [ROB_INDEX_W-1:0] kill_age_thresh_w =
      kill_rob_idx_i - rob_head_idx_i;
  wire [ROB_INDEX_W-1:0] owner_rob_idx_w =
      producer_id_q[ROB_INDEX_W-1:0];
  wire [ROB_INDEX_W-1:0] kill_age_owner_w =
      owner_rob_idx_w - rob_head_idx_i;
  wire kill_inflight_w =
      ((state_q == STATE_RUN) || (state_q == STATE_RESP)) &&
      kill_valid_i && (kill_age_owner_w > kill_age_thresh_w);

  assign req_ready_o = (state_q == STATE_IDLE) && !rst && !flush_i && !kill_valid_i;
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
      resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      resp_data_q <= {`XLEN{1'b0}};
      op_q <= CLMUL_OP_LOW;
      iter_q <= 7'd0;
      acc_q <= {`XLEN{1'b0}};
      lhs_shift_q <= {`XLEN{1'b0}};
      rhs_shift_q <= {`XLEN{1'b0}};
      rhs_right_shift_q <= {`XLEN{1'b0}};
    end else if (kill_inflight_w) begin
      // UC-A: kill 命中在飞 clmul → 强制回 IDLE(覆盖优先), 抹 resp 身份防脏写回
      state_q <= STATE_IDLE;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
      resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      resp_data_q <= {`XLEN{1'b0}};
    end else begin
      case (state_q)
        STATE_IDLE: begin
          if (req_fire_w) begin
            state_q <= STATE_RUN;
            producer_id_q <= req_producer_id_i;
            resp_pdest_q <= req_pdest_i;
            resp_data_q <= {`XLEN{1'b0}};
            op_q <= req_op_i;
            iter_q <= 7'd0;
            acc_q <= {`XLEN{1'b0}};
            lhs_shift_q <= req_src1_i;
            rhs_shift_q <= req_src2_i;
            rhs_right_shift_q <=
                (req_op_i == CLMUL_OP_REV) ?
                {1'b0, req_src1_i[`XLEN-1:1]} : req_src1_i;
          end
        end

        STATE_RUN: begin
          acc_q <= step_acc_w;
          iter_q <= iter_q + 7'd1;
          if (run_low_w) begin
            lhs_shift_q <= lhs_shift_next_w;
            rhs_shift_q <= rhs_shift_right_next_w;
          end else if (run_high_w || run_rev_w) begin
            rhs_shift_q <= rhs_shift_left_next_w;
            rhs_right_shift_q <= rhs_right_shift_next_w;
          end
          if (iter_last_w) begin
            resp_data_q <= step_acc_w;
            state_q <= STATE_RESP;
          end
        end

        STATE_RESP: begin
          if (resp_ready_i) begin
            state_q <= STATE_IDLE;
            producer_id_q <= {PRODUCER_ID_W{1'b0}};
            resp_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
            resp_data_q <= {`XLEN{1'b0}};
            op_q <= CLMUL_OP_LOW;
            iter_q <= 7'd0;
            acc_q <= {`XLEN{1'b0}};
            lhs_shift_q <= {`XLEN{1'b0}};
            rhs_shift_q <= {`XLEN{1'b0}};
            rhs_right_shift_q <= {`XLEN{1'b0}};
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
  always @(posedge clk) begin
    if (!rst) begin
      if ((owner_valid_o !== (state_q != STATE_IDLE)) ||
          (owner_producer_id_o !== producer_id_q) ||
          (resp_rob_idx_o !== producer_id_q[ROB_INDEX_W-1:0]) ||
          (resp_producer_id_o !== producer_id_q)) begin
        $error("[V8H-CLMUL-PID-PROJECTION] holder identity projection mismatch @%0t", $time);
        $fatal;
      end
      if ((rst || flush_i || kill_valid_i) && req_ready_o) begin
        $error("[V8H-CLMUL-REQ-GUARD] request ready during reset/flush/kill @%0t", $time);
        $fatal;
      end
    end
  end
`endif

endmodule
