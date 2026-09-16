module fp_ooc_pathend_multibit_harness (
  input  wire       clk,
  input  wire [1:0] data_i,
  output wire [1:0] data_o
);
  wire data0_a_w;
  wire data0_b_w;
  wire data0_c_w;
  wire data1_w;
  wire q0_w;
  wire q1_w;

  // Bit zero is intentionally slower, while the family iterator queries bit
  // one last.  This kills any implementation that retains a Search-owned
  // PathEnd from the earlier query instead of materializing ordinary values.
  BUFX1H7L u_data0_a (.A(data_i[0]), .Y(data0_a_w));
  BUFX1H7L u_data0_b (.A(data0_a_w), .Y(data0_b_w));
  BUFX1H7L u_data0_c (.A(data0_b_w), .Y(data0_c_w));
  BUFX1H7L u_data1   (.A(data_i[1]), .Y(data1_w));

  DFFQX1H7L u_state0_q (.CK(clk), .D(data0_c_w), .Q(q0_w));
  DFFQX1H7L u_state1_q (.CK(clk), .D(data1_w),   .Q(q1_w));

  BUFX1H7L u_output0 (.A(q0_w), .Y(data_o[0]));
  BUFX1H7L u_output1 (.A(q1_w), .Y(data_o[1]));
endmodule
