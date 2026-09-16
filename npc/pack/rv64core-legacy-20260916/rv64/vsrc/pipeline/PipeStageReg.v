// PipeStageReg — 标准级间寄存器原语（级间边界显式化治理的基础单元）。
// 语义：单缓冲弹性流水寄存。up 侧 valid/ready 握手装载，down 侧 valid/ready 消费；
// stall(down_ready_i=0) 时 valid 与 payload 整拍冻结；flush_i/kill_i 清 valid(payload 留脏)。
// - flush_i：全局清空（trap/serial 等 nuke 族），优先级最高，同拍压过装载。
// - kill_i：投机 squash 命中（使用方已完成年龄判定后给出的单 bit 结论；
//   本原语不解析 payload，rob_idx 年龄比较必须留在使用方——kill 窗口覆盖是使用方契约）。
// - up_ready_o = !valid_q || down_ready_i：ready 组合依赖 valid/下游 ready 合法（契约①），
//   不依赖 up_valid_i，结构上无 valid↔ready 组合环。
// (* keep_hierarchy *)：综合时保留模块边界，ABC 沿寄存器切 cone（治理的综合收益机制）。
(* keep_hierarchy *)
module PipeStageReg #(
  parameter WIDTH = 32
) (
  input clk,
  input rst,
  input flush_i,
  input kill_i,
  input up_valid_i,
  output up_ready_o,
  input [WIDTH-1:0] up_payload_i,
  output down_valid_o,
  input down_ready_i,
  output [WIDTH-1:0] down_payload_o
);
  reg valid_q;
  reg [WIDTH-1:0] payload_q;

  wire up_fire_w = up_valid_i && up_ready_o;
  wire down_fire_w = down_valid_o && down_ready_i;

  assign up_ready_o = !valid_q || down_ready_i;
  assign down_valid_o = valid_q;
  assign down_payload_o = payload_q;

  always @(posedge clk) begin
    if (rst || flush_i || kill_i) begin
      // flush/kill 只清 valid：payload 留脏是刻意的（与全核 valid-only 复位惯例一致），
      // 消费方不得在 valid=0 时读 payload。
      valid_q <= 1'b0;
    end else if (up_fire_w) begin
      valid_q <= 1'b1;
    end else if (down_fire_w) begin
      valid_q <= 1'b0;
    end
    if (!rst && !flush_i && !kill_i && up_fire_w) begin
      payload_q <= up_payload_i;
    end
  end

`ifdef OOO_ASSERT
  // 级间寄存三条承重不变量（用户治理指示：每条边界配立即断言，进 check-contract 计数）。
  reg assert_valid_prev_q;
  reg [WIDTH-1:0] assert_payload_prev_q;
  reg assert_hold_expect_q;
  reg assert_flush_prev_q;
  always @(posedge clk) begin
    if (rst) begin
      assert_valid_prev_q <= 1'b0;
      assert_payload_prev_q <= {WIDTH{1'b0}};
      assert_hold_expect_q <= 1'b0;
      assert_flush_prev_q <= 1'b0;
    end else begin
      // PSR-HOLD: stall(占用且下游不收)且无 flush/kill → 次拍 valid 保持且 payload 冻结。
      assert_hold_expect_q <= valid_q && !down_ready_i && !flush_i && !kill_i;
      assert_valid_prev_q <= valid_q;
      assert_payload_prev_q <= payload_q;
      assert_flush_prev_q <= flush_i || kill_i;
      if (assert_hold_expect_q && (!valid_q || (payload_q !== assert_payload_prev_q)))
        $error("[CONTRACT-PSR-HOLD] stall 拍未冻结: valid=%0d payload变化=%0d @%0t",
               valid_q, (payload_q !== assert_payload_prev_q), $time);
      // PSR-FLUSH-EMPTY: flush/kill 拍后一拍必空。
      if (assert_flush_prev_q && valid_q)
        $error("[CONTRACT-PSR-FLUSH-EMPTY] flush/kill 后一拍 valid 仍为 1 @%0t", $time);
    end
  end
`endif
endmodule
