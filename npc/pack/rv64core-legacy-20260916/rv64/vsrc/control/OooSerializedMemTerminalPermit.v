// V16A：把 exact memory-terminal 事实绑定到当前 serialized owner。
//
// 本模块不拥有 memory token，也不产生 dequeue/free。ready_o 只是一次性
// control permit；consumer 仍须当拍重查 raw backend drain、FENCE mem_idle
// 与既有 trap/exit/CSR 优先级。
module OooSerializedMemTerminalPermit (
  input wire clk,
  input wire rst,

  input wire cancel_i,
  input wire stop_pending_i,
  input wire backend_drained_q_i,
  input wire [2:0] owner_i,
  input wire mem_owner_terminalized_i,
  input wire consume_i,

  output wire ready_o
);

  reg permit_valid_q;
  reg [2:0] permit_owner_q;

  wire owner_exact_one_w =
      (owner_i == 3'b001) ||
      (owner_i == 3'b010) ||
      (owner_i == 3'b100);
  wire owner_matches_w = owner_i == permit_owner_q;
  wire arm_w =
      !permit_valid_q && !cancel_i && !consume_i &&
      stop_pending_i && backend_drained_q_i && owner_exact_one_w &&
      mem_owner_terminalized_i;

  // V16B: cancel_i 是父层冻结的 feedback-free 高优先级 kill，而不是含
  // drain_complete 的完整 holder clear。它必须在 clear 沿之前立即封住
  // ready，避免 held permit 与 ROB-head trap/recovery 同拍产生低优先级
  // terminal side effect；terminal scalar 仍只进入 permit D。
  assign ready_o =
      !cancel_i && permit_valid_q && stop_pending_i && owner_exact_one_w &&
      owner_matches_w;

  always @(posedge clk) begin
    if (rst) begin
      permit_valid_q <= 1'b0;
      permit_owner_q <= 3'b000;
    end else if (cancel_i || consume_i || !stop_pending_i ||
                 !owner_exact_one_w ||
                 (permit_valid_q && !owner_matches_w)) begin
      // clear-dominant：flush/cancel/consume/owner handoff 都禁止旧 permit
      // 在同沿重新 arm；新 owner 必须重新观察一次 exact terminal。
      permit_valid_q <= 1'b0;
      permit_owner_q <= 3'b000;
    end else if (arm_w) begin
      permit_valid_q <= 1'b1;
      permit_owner_q <= owner_i;
    end
  end

`ifdef OOO_ASSERT
  reg clear_prev_q;
  reg arm_prev_q;
  reg [2:0] arm_owner_prev_q;

  always @(posedge clk) begin
    if (rst) begin
      clear_prev_q <= 1'b0;
      arm_prev_q <= 1'b0;
      arm_owner_prev_q <= 3'b000;
    end else begin
      if (permit_valid_q &&
          !((permit_owner_q == 3'b001) ||
            (permit_owner_q == 3'b010) ||
            (permit_owner_q == 3'b100))) begin
        $error("[V16A-SERIALIZED-PERMIT-OWNER-SHAPE] valid permit has non-onehot owner=%b @%0t",
               permit_owner_q, $time);
        $fatal;
      end
      if (ready_o &&
          (cancel_i || !permit_valid_q || !stop_pending_i || !owner_exact_one_w ||
           !owner_matches_w)) begin
        $error("[V16B-SERIALIZED-PERMIT-READY-SHAPE] ready escaped cancel/owner/stop identity cancel=%b valid=%b stop=%b owner=%b held=%b @%0t",
               cancel_i, permit_valid_q, stop_pending_i, owner_i,
               permit_owner_q, $time);
        $fatal;
      end
      if (clear_prev_q && permit_valid_q) begin
        $error("[V16A-SERIALIZED-PERMIT-CLEAR-PRIORITY] prior cancel/consume/drop/mismatch did not clear permit @%0t",
               $time);
        $fatal;
      end
      if (arm_prev_q &&
          (!permit_valid_q || (permit_owner_q != arm_owner_prev_q))) begin
        $error("[V16A-SERIALIZED-PERMIT-ARM-HOLD] exact arm did not capture owner=%b valid=%b held=%b @%0t",
               arm_owner_prev_q, permit_valid_q, permit_owner_q, $time);
        $fatal;
      end

      clear_prev_q <=
          cancel_i || consume_i || !stop_pending_i || !owner_exact_one_w ||
          (permit_valid_q && !owner_matches_w);
      arm_prev_q <= arm_w;
      arm_owner_prev_q <= owner_i;
    end
  end
`endif

endmodule
