// 已接受翻译请求的顺序归属账本：两路独立通道，每路四项。
// 信用只依赖已寄存占用；响应出队不提供同拍入口信用。
// 已接受翻译必须排空，因此接口无 kill/flush；LSQ 行生命周期与复用保护仍由 LSU 管理。
module R64LsuTranslationOwners #(
  parameter INDEX_W = 5
) (
  input                    clk_i,
  input                    rst_i,
  input  [            1:0] in_fire_i,
  output [            1:0] in_ready_o,
  input  [  2*INDEX_W-1:0] in_slot_i,
  input  [            7:0] in_protection_i,
  input  [            1:0] rsp_valid_i,
  output [            1:0] rsp_ready_o,
  output [            1:0] rsp_fire_o,
  output [  2*INDEX_W-1:0] rsp_slot_o,
  output [            7:0] rsp_protection_o
);
  reg [INDEX_W-1:0] slot_q[0:1][0:3];
  reg [3:0] protection_q[0:1][0:3];
  reg [1:0] head_q[0:1], tail_q[0:1];
  reg [2:0] count_q[0:1];
  genvar lane;
  generate
    for (lane = 0; lane < 2; lane = lane + 1) begin : g_lane
      // 上游负责实际 fire 的复位与取消资格；本模块保留原有的 Q 态容量查询，
      // 同步复位期间也不额外改变该查询。
      assign in_ready_o[lane] = count_q[lane] < 3'd4;
      assign rsp_ready_o[lane] = count_q[lane] != 0 && !rst_i;
      assign rsp_fire_o[lane] = rsp_valid_i[lane] && rsp_ready_o[lane];
      assign rsp_slot_o[lane*INDEX_W+:INDEX_W] = slot_q[lane][head_q[lane]];
      assign rsp_protection_o[lane*4+:4] = protection_q[lane][head_q[lane]];
      always @(posedge clk_i) begin
        if (rst_i) begin
          head_q[lane] <= 0;
          tail_q[lane] <= 0;
          count_q[lane] <= 0;
        end else begin
          case ({in_fire_i[lane], rsp_fire_o[lane]})
            2'b10: count_q[lane] <= count_q[lane] + 1'b1;
            2'b01: count_q[lane] <= count_q[lane] - 1'b1;
            default: begin
            end
          endcase
          if (in_fire_i[lane]) begin
            slot_q[lane][tail_q[lane]] <= in_slot_i[lane*INDEX_W+:INDEX_W];
            protection_q[lane][tail_q[lane]] <= in_protection_i[lane*4+:4];
            tail_q[lane] <= tail_q[lane] + 1'b1;
          end
          if (rsp_fire_o[lane]) head_q[lane] <= head_q[lane] + 1'b1;
        end
      end
`ifdef R64_ASSERT
      always @(posedge clk_i)
        if (!rst_i) begin
          if (count_q[lane] > 4 || (in_fire_i[lane] && count_q[lane] == 4))
            $fatal(1, "R64Lsu translation accepted FIFO capacity violation");
        end
`endif
    end
  endgenerate
endmodule
