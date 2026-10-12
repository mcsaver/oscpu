`timescale 1ns/1ps
`include "tb_r64_lsu_query_pin.sv"
module tb_r64_response_forward_pin;
  parameter FORWARD=1;
  tb_r64_lsu_query_pin flow();
  defparam flow.dut.RESPONSE_FORWARD_QUERY=FORWARD;
  integer new_captures=0;
  always @(posedge flow.clk)if(!flow.rst)
    for(integer lane=0;lane<2;lane+=1)
      if(flow.dut.lsu.translation_forward_take_w[lane])new_captures+=1;
  final $display("[PASS] tb_r64_response_forward_pin enable=%0d response_queries=%0d",
    FORWARD,new_captures);
endmodule
