`include "tb_r64_rr_complete_admit_chain.sv"
module tb_r64_load_notice_q_chain;
  tb_r64_rr_complete_admit_chain #(.NOTICE_Q(1),.TEST_NAME("tb_r64_load_notice_q_chain")) test();
endmodule
