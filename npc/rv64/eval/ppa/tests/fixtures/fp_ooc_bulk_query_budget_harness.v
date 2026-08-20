module fp_ooc_bulk_query_budget_harness (
  input  wire       clk,
  input  wire [1:0] data_i,
  output wire [1:0] dynamic_o,
  output wire       constant_o
);
  wire data0_a_w;
  wire data0_b_w;
  wire data0_c_w;
  wire data1_w;
  wire state0_d_w;
  wire state1_d_w;
  wire q0_w;
  wire q1_w;
  wire q0_a_w;
  wire q0_b_w;
  wire q1_a_w;
  wire q1_b_w;
  wire q1_c_w;
  wire q1_d_w;

  // data_i[0] is deliberately the non-final worst input source.  The focused
  // collector must retain only ordinary Tcl values before querying data_i[1].
  BUFX1H7L u_data0_a (.A(data_i[0]), .Y(data0_a_w));
  BUFX1H7L u_data0_b (.A(data0_a_w), .Y(data0_b_w));
  BUFX1H7L u_data0_c (.A(data0_b_w), .Y(data0_c_w));
  BUFX1H7L u_data1   (.A(data_i[1]), .Y(data1_w));

  // Cross-coupled through the register boundaries only: this creates real
  // Q->D timing classes without a combinational loop.
  OR2X1H7L u_state0_d (.A(data0_c_w), .B(q1_w), .Y(state0_d_w));
  OR2X1H7L u_state1_d (.A(data1_w),   .B(q0_w), .Y(state1_d_w));
  DFFQX1H7L u_state0_q (.CK(clk), .D(state0_d_w), .Q(q0_w));
  DFFQX1H7L u_state1_q (.CK(clk), .D(state1_d_w), .Q(q1_w));

  // dynamic_o[0] has two distinct register-Q launch paths.  dynamic_o[1] is
  // intentionally the non-first endpoint with the longest cumulative delay.
  BUFX1H7L u_q0_a (.A(q0_w), .Y(q0_a_w));
  BUFX1H7L u_q0_b (.A(q0_a_w), .Y(q0_b_w));
  OR2X1H7L u_dynamic0 (.A(q0_b_w), .B(q1_w), .Y(dynamic_o[0]));

  BUFX1H7L u_q1_a (.A(q1_w), .Y(q1_a_w));
  BUFX1H7L u_q1_b (.A(q1_a_w), .Y(q1_b_w));
  BUFX1H7L u_q1_c (.A(q1_b_w), .Y(q1_c_w));
  BUFX1H7L u_q1_d (.A(q1_c_w), .Y(q1_d_w));
  BUFX1H7L u_dynamic1 (.A(q1_d_w), .Y(dynamic_o[1]));

  // The structural contract, never a missing timing path, classifies this bit.
  TIELOH7L u_constant (.Z(constant_o));
endmodule
