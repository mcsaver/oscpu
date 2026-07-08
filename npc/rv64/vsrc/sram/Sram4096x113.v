// Sram4096x113 — d-cache tag+data 拼宽专用 1RW 同步读 SRAM 行为模型。
// 综合时经 SYNTH_BLACKBOX_MODULES 黑盒化(实现来自工艺宏/fakeram)；仿真时本文件即真源。
// 语义：en_i 且 we_i=0 时读 addr_i，次拍 rdata_o 有效；en_i 且 we_i=1 时写。
// 读写共享单地址口(1RW)，使用方必须保证读/写状态互斥(读写同拍视为违约)。
// 内容无复位、上电未定义——全清/失效语义由使用方 valid FF 承担。
module Sram4096x113 (
  input clk,
  input en_i,
  input we_i,
  input [11:0] addr_i,
  input [112:0] wdata_i,
  output reg [112:0] rdata_o
);
  reg [112:0] mem_q [0:4095];
  always @(posedge clk) begin
    if (en_i) begin
      if (we_i) begin
        mem_q[addr_i] <= wdata_i;
      end else begin
        rdata_o <= mem_q[addr_i];
      end
    end
  end
endmodule
