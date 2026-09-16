module fp_ooc_path_arrival_harness (
  input  wire clk,
  input  wire data_i,
  output wire data_o
);
  wire d_w;
  wire q_w;

  BUFX1H7L u_input_buffer (
    .A(data_i),
    .Y(d_w)
  );

  DFFQX1H7L u_state_q (
    .CK(clk),
    .D(d_w),
    .Q(q_w)
  );

  BUFX1H7L u_output_buffer (
    .A(q_w),
    .Y(data_o)
  );
endmodule
