// CSR illegal probe 的 lane 归属属于 control plane，不放在 core glue 手拼。
module OooCsrIllegalProbeGate (
  input head0_csr_raw_i,
  input head1_csr_probe_i,
  input csr_illegal_i,

  output head0_csr_illegal_o,
  output head1_csr_illegal_o
);

  assign head0_csr_illegal_o =
      head0_csr_raw_i && !head1_csr_probe_i && csr_illegal_i;
  assign head1_csr_illegal_o =
      head1_csr_probe_i && csr_illegal_i;

endmodule
