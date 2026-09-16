`timescale 1ns/1ps

// Data-MMU context boundary / epoch 的唯一时序 owner。
//
// Q1 叶模块只负责 held request、同拍 capture block、full-quiet 后 sticky
// grant 与 grant-fire 同沿 epoch 推进。effective-value classifier、full quiet
// 生产者和 grant 对应的 CSR/trap/xRET/SFENCE apply 由后续原子集成负责。
module OooMmuEpochOwner #(
  parameter integer CAUSE_W = 4,
  parameter integer PAYLOAD_W = 1
) (
  input wire clk,
  input wire rst,

  input wire request_valid_i,
  output wire request_ready_o,
  input wire [CAUSE_W-1:0] request_cause_i,
  input wire [PAYLOAD_W-1:0] request_payload_i,

  // 已寄存的共享取消事件。active integration 必须把同一个 event 同拍送到
  // CsrFile reservation；本 leaf 只负责立即屏蔽 handshake/grant，并在该沿
  // 原子清除 held owner。abort 不推进 epoch。
  input wire abort_valid_i,

  // 两项都必须来自寄存 owner 事实；禁止从 ready/fire 反推 quiet。
  input wire mem_context_quiet_i,
  input wire owner_live_empty_i,

  // 与 request ready 分离：首次 boundary 出现的同一拍即封住新 memory capture。
  output wire capture_block_o,

  output wire grant_valid_o,
  input wire grant_ready_i,
  output wire [CAUSE_W-1:0] grant_cause_o,
  output wire [PAYLOAD_W-1:0] grant_payload_o,
  output wire [1:0] mmu_epoch_o
);

  localparam [1:0] ST_UNLOCKED = 2'b00;
  localparam [1:0] ST_LOCKED_DRAIN = 2'b01;
  localparam [1:0] ST_COMMIT = 2'b10;

  reg [1:0] state_q;
  reg [CAUSE_W-1:0] held_cause_q;
  reg [PAYLOAD_W-1:0] held_payload_q;
  reg [1:0] mmu_epoch_q;
  reg abort_rearm_q;

  wire parameter_shape_valid_w = (CAUSE_W > 0) && (PAYLOAD_W > 0);
  wire request_cause_valid_w = |request_cause_i;
  wire request_fire_w = request_valid_i && request_ready_o;
  wire full_quiet_w = mem_context_quiet_i && owner_live_empty_i;
  wire grant_fire_w = grant_valid_o && grant_ready_i;

  // Q1-I1：look-ahead 不打一拍，避免 boundary 首拍仍捕获旧 epoch owner。
  assign capture_block_o = abort_valid_i || abort_rearm_q ||
      ((state_q != ST_UNLOCKED) || request_valid_i);
  assign request_ready_o = parameter_shape_valid_w &&
      (state_q == ST_UNLOCKED) && request_cause_valid_w &&
      !abort_valid_i && !abort_rearm_q;
  assign grant_valid_o = (state_q == ST_COMMIT) && !abort_valid_i;
  assign grant_cause_o = held_cause_q;
  assign grant_payload_o = held_payload_q;
  assign mmu_epoch_o = mmu_epoch_q;

  always @(posedge clk) begin
    if (rst) begin
      state_q <= ST_UNLOCKED;
      held_cause_q <= {CAUSE_W{1'b0}};
      held_payload_q <= {PAYLOAD_W{1'b0}};
      mmu_epoch_q <= 2'b00;
      abort_rearm_q <= 1'b0;
    end else if (abort_valid_i) begin
      // Q1A hard priority: abort > grant/apply > normal transition > hold.
      // grant_valid/request_ready 已在本拍组合屏蔽，所以这里不会留下一个
      // abort edge 上的可见 fire，也不会错误推进 epoch。
      state_q <= ST_UNLOCKED;
      held_cause_q <= {CAUSE_W{1'b0}};
      held_payload_q <= {PAYLOAD_W{1'b0}};
      // 被取消的 producer envelope 必须先撤回 valid；否则同一旧请求会在
      // abort 后第一拍被误当成新事务重新捕获。
      abort_rearm_q <= request_valid_i;
    end else begin
      if (abort_rearm_q && !request_valid_i)
        abort_rearm_q <= 1'b0;
      case (state_q)
        ST_UNLOCKED: begin
          if (request_fire_w) begin
            // request bundle 只捕获一次；busy 期间第二请求不能覆盖。
            state_q <= ST_LOCKED_DRAIN;
            held_cause_q <= request_cause_i;
            held_payload_q <= request_payload_i;
          end
        end

        ST_LOCKED_DRAIN: begin
          // 至少经历一个完整封门周期后才采样 full quiet，不做直通 grant。
          if (full_quiet_w)
            state_q <= ST_COMMIT;
        end

        ST_COMMIT: begin
          if (grant_fire_w) begin
            // grant fire 是 context apply 与 epoch publish 的唯一原子边界。
            state_q <= ST_UNLOCKED;
            held_cause_q <= {CAUSE_W{1'b0}};
            held_payload_q <= {PAYLOAD_W{1'b0}};
            mmu_epoch_q <= mmu_epoch_q + 2'b01;
          end
        end

        default: begin
          // release build 也 fail closed：非法态锁死入口，不恢复到 UNLOCKED。
          state_q <= 2'b11;
        end
      endcase
    end
  end

`ifdef OOO_ASSERT
  wire state_legal_w = (state_q == ST_UNLOCKED) ||
      (state_q == ST_LOCKED_DRAIN) || (state_q == ST_COMMIT);

  initial begin
    if (!parameter_shape_valid_w) begin
      $display("[MMU-EPOCH-PARAM] CAUSE_W/PAYLOAD_W must both be positive");
      $fatal;
    end
  end

  reg request_hold_q;
  reg [CAUSE_W-1:0] request_hold_cause_q;
  reg [PAYLOAD_W-1:0] request_hold_payload_q;
  reg reserved_check_q;
  reg [CAUSE_W-1:0] reserved_cause_q;
  reg [PAYLOAD_W-1:0] reserved_payload_q;
  reg grant_hold_q;
  reg [CAUSE_W-1:0] grant_hold_cause_q;
  reg [PAYLOAD_W-1:0] grant_hold_payload_q;
  reg [1:0] grant_hold_epoch_q;
  reg epoch_check_q;
  reg [1:0] epoch_expected_q;
  reg abort_check_q;
  reg [1:0] abort_epoch_q;
  reg abort_request_valid_q;

  always @(posedge clk) begin
    if (rst) begin
      request_hold_q <= 1'b0;
      request_hold_cause_q <= {CAUSE_W{1'b0}};
      request_hold_payload_q <= {PAYLOAD_W{1'b0}};
      reserved_check_q <= 1'b0;
      reserved_cause_q <= {CAUSE_W{1'b0}};
      reserved_payload_q <= {PAYLOAD_W{1'b0}};
      grant_hold_q <= 1'b0;
      grant_hold_cause_q <= {CAUSE_W{1'b0}};
      grant_hold_payload_q <= {PAYLOAD_W{1'b0}};
      grant_hold_epoch_q <= 2'b00;
      epoch_check_q <= 1'b0;
      epoch_expected_q <= 2'b00;
      abort_check_q <= 1'b0;
      abort_epoch_q <= 2'b00;
      abort_request_valid_q <= 1'b0;
    end else begin
      if (!state_legal_w) begin
        $display("[MMU-EPOCH-STATE] illegal FSM encoding %b", state_q);
        $fatal;
      end
      if (request_valid_i && !capture_block_o) begin
        $display("[MMU-EPOCH-FIRST-BLOCK] request presentation did not block capture");
        $fatal;
      end
      if (request_valid_i && !abort_valid_i && !request_cause_valid_w) begin
        $display("[MMU-EPOCH-REQ-CAUSE] valid request carried no cause bit");
        $fatal;
      end
      if ((state_q != ST_UNLOCKED) && request_ready_o) begin
        $display("[MMU-EPOCH-SECOND-REQ] busy owner accepted a second request");
        $fatal;
      end
      if (grant_valid_o && !full_quiet_w) begin
        $display("[MMU-EPOCH-GRANT-QUIET] quiet/live-empty dropped while grant was pending");
        $fatal;
      end
      if (grant_fire_w && (!capture_block_o || request_ready_o)) begin
        $display("[MMU-EPOCH-TRANSITION-GAP] grant edge allowed old-epoch capture");
        $fatal;
      end
      if (abort_valid_i &&
          (!capture_block_o || request_ready_o || grant_valid_o ||
           request_fire_w || grant_fire_w)) begin
        $display("[MMU-EPOCH-ABORT-MASK] abort exposed a request/grant handshake");
        $fatal;
      end
      if (abort_rearm_q &&
          (!capture_block_o || request_ready_o || grant_valid_o)) begin
        $display("[MMU-EPOCH-ABORT-REARM] cancelled request was accepted before valid-low rearm");
        $fatal;
      end
      if (abort_check_q &&
          ((state_q != ST_UNLOCKED) ||
           (abort_rearm_q !== abort_request_valid_q) ||
           (held_cause_q !== {CAUSE_W{1'b0}}) ||
           (held_payload_q !== {PAYLOAD_W{1'b0}}) ||
           (mmu_epoch_o !== abort_epoch_q))) begin
        $display("[MMU-EPOCH-ABORT-CLEAR] abort did not atomically clear owner without epoch advance");
        $fatal;
      end

      if (request_hold_q && !abort_valid_i && !abort_rearm_q &&
          (!request_valid_i ||
           (request_cause_i !== request_hold_cause_q) ||
           (request_payload_i !== request_hold_payload_q))) begin
        $display("[MMU-EPOCH-REQ-HOLD] stalled request bundle changed or withdrew");
        $fatal;
      end
      request_hold_q <= !abort_valid_i && !abort_rearm_q &&
          request_valid_i && !request_ready_o;
      if (!abort_valid_i && !abort_rearm_q &&
          request_valid_i && !request_ready_o) begin
        request_hold_cause_q <= request_cause_i;
        request_hold_payload_q <= request_payload_i;
      end

      if (reserved_check_q && !abort_valid_i &&
          ((held_cause_q !== reserved_cause_q) ||
           (held_payload_q !== reserved_payload_q))) begin
        $display("[MMU-EPOCH-RESERVED-HOLD] captured boundary bundle changed before grant");
        $fatal;
      end
      if (abort_valid_i) begin
        reserved_check_q <= 1'b0;
      end else if (request_fire_w) begin
        reserved_check_q <= 1'b1;
        reserved_cause_q <= request_cause_i;
        reserved_payload_q <= request_payload_i;
      end else if (grant_fire_w) begin
        reserved_check_q <= 1'b0;
      end

      if (grant_hold_q && !abort_valid_i &&
          (!grant_valid_o ||
           (grant_cause_o !== grant_hold_cause_q) ||
           (grant_payload_o !== grant_hold_payload_q) ||
           (mmu_epoch_o !== grant_hold_epoch_q))) begin
        $display("[MMU-EPOCH-GRANT-HOLD] backpressured grant bundle changed or withdrew");
        $fatal;
      end
      grant_hold_q <= !abort_valid_i && grant_valid_o && !grant_ready_i;
      if (!abort_valid_i && grant_valid_o && !grant_ready_i) begin
        grant_hold_cause_q <= grant_cause_o;
        grant_hold_payload_q <= grant_payload_o;
        grant_hold_epoch_q <= mmu_epoch_o;
      end

      if (epoch_check_q && (mmu_epoch_o !== epoch_expected_q)) begin
        $display("[MMU-EPOCH-ADVANCE] epoch changed without one grant-fire increment");
        $fatal;
      end
      epoch_check_q <= 1'b1;
      epoch_expected_q <= mmu_epoch_o + (grant_fire_w ? 2'b01 : 2'b00);
      abort_check_q <= abort_valid_i;
      if (abort_valid_i)
        abort_epoch_q <= mmu_epoch_o;
      if (abort_valid_i)
        abort_request_valid_q <= request_valid_i;
    end
  end
`endif

endmodule
