`include "tb_r64_load_resolved_value.sv"
module tb_r64_load_notice_q_transport;
  tb_r64_load_resolved_value #(.NOTICE_Q(1),.TEST_NAME("tb_r64_load_notice_q_transport")) test();
endmodule
