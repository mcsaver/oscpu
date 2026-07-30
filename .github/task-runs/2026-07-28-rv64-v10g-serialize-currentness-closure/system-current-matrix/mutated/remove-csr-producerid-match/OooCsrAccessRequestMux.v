`include "include/define.v"

module OooCsrAccessRequestMux #(
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W
) (
  input wire core_commit0_valid_i,
  input wire core_commit0_exception_i,
  input wire [`XLEN-1:0] core_commit0_pc_i,
  input wire [`INST_W-1:0] core_commit0_inst_i,
  input wire [PRODUCER_ID_W-1:0] core_commit0_producer_id_i,

  input wire pending_system_i,
  input wire pending_system_csr_i,
  input wire pending_system_dispatched_i,
  input wire pending_system_sfence_i,
  input wire [`XLEN-1:0] pending_system_pc_i,
  input wire [`INST_W-1:0] pending_system_inst_i,
  input wire pending_system_producer_valid_i,
  input wire [PRODUCER_ID_W-1:0] pending_system_producer_id_i,

  input wire dispatch_valid_i,
  input wire dispatch0_system_i,
  input wire dispatch1_barrier_i,
  input wire head0_csr_raw_i,
  input wire head1_csr_raw_i,
  input wire [`INST_W-1:0] head_inst0_i,
  input wire [`INST_W-1:0] head_inst1_i,

  input wire stop_pending_i,
  input wire drain_complete_i,
  input wire [`XLEN * `REG_NUM - 1:0] debug_gprs_i,

  output wire core_commit0_csr_o,
  output wire pending_system_csr_commit_o,
  output wire head0_csr_commit_o,
  output wire head1_csr_probe_o,
  output wire csr_access_valid_o,
  output wire [`INST_W-1:0] csr_access_inst_o,
  output wire [11:0] csr_access_addr_o,
  output wire [2:0] csr_access_funct3_o,
  output wire [`REG_ADDR_W-1:0] csr_access_rs1_idx_o,
  output wire [`XLEN-1:0] csr_access_rs1_data_o,
  output wire csr_access_set_clear_noop_o,
  output wire csr_access_need_write_o,
  output wire csr_probe_valid_o,
  output wire [11:0] csr_probe_addr_o,
  output wire [2:0] csr_probe_funct3_o,
  output wire [`REG_ADDR_W-1:0] csr_probe_rs1_idx_o,
  output wire pending_system_satp_write_commit_o,
  output wire pending_system_sfence_commit_o
);

  assign core_commit0_csr_o =
      core_commit0_valid_i && !core_commit0_exception_i &&
      (core_commit0_inst_i[6:0] == `OPCODE_SYSTEM) &&
      (core_commit0_inst_i[14:12] != 3'b000);
  wire pending_system_csr_logical_claim_w =
      pending_system_i && pending_system_csr_i && pending_system_dispatched_i;
  // raw lease 与 logical claim 任一存在都封住 queue-head fallback。这样即使
  // metadata 被部分清除，仍不会把 exact-match failure 重新解释成普通 CSR。
  wire pending_system_csr_claim_seal_w =
      pending_system_producer_valid_i || pending_system_csr_logical_claim_w;
  wire pending_system_csr_pid_match_w =
      core_commit0_producer_id_i == pending_system_producer_id_i;
  wire pending_system_csr_pc_match_w =
      core_commit0_pc_i == pending_system_pc_i;
  assign pending_system_csr_commit_o =
      pending_system_csr_logical_claim_w &&
      pending_system_producer_valid_i && core_commit0_csr_o &&
      pending_system_csr_pc_match_w;
  assign head0_csr_commit_o =
      `OOO_CSR_QUEUE_HEAD && core_commit0_csr_o &&
      !pending_system_csr_claim_seal_w;
  assign head1_csr_probe_o =
      dispatch_valid_i && !dispatch0_system_i && dispatch1_barrier_i &&
      head1_csr_raw_i;

  assign csr_access_inst_o =
      core_commit0_csr_o ? core_commit0_inst_i :
      pending_system_i ? pending_system_inst_i :
      head1_csr_probe_o ? head_inst1_i : head_inst0_i;
  assign csr_access_addr_o = csr_access_inst_o[31:20];
  assign csr_access_funct3_o = csr_access_inst_o[14:12];
  assign csr_access_rs1_idx_o = csr_access_inst_o[19:15];
  assign csr_access_rs1_data_o =
      debug_gprs_i[csr_access_rs1_idx_o * `XLEN +: `XLEN];

  assign csr_access_set_clear_noop_o =
      ((csr_access_funct3_o == 3'b010) ||
       (csr_access_funct3_o == 3'b011) ||
       (csr_access_funct3_o == 3'b110) ||
       (csr_access_funct3_o == 3'b111)) &&
      (csr_access_rs1_idx_o == {`REG_ADDR_W{1'b0}});
  assign csr_access_need_write_o =
      (csr_access_funct3_o == 3'b001) ||
      (csr_access_funct3_o == 3'b101) ||
      !csr_access_set_clear_noop_o;
  assign csr_access_valid_o =
      core_commit0_csr_o ||
      (pending_system_i && pending_system_csr_i) ||
      head0_csr_raw_i ||
      head1_csr_probe_o;

  // T3K: legality belongs to the current fetch head, not to the late
  // commit/pending selector used for CSR readback and architectural writes.
  // Keep this view physically head-only so commit completion cannot enter the
  // pending-trap capture cone through CsrFile legality.
  wire [`INST_W-1:0] csr_probe_inst_w =
      head1_csr_probe_o ? head_inst1_i : head_inst0_i;
  assign csr_probe_valid_o = head0_csr_raw_i || head1_csr_probe_o;
  assign csr_probe_addr_o = csr_probe_inst_w[31:20];
  assign csr_probe_funct3_o = csr_probe_inst_w[14:12];
  assign csr_probe_rs1_idx_o = csr_probe_inst_w[19:15];

  assign pending_system_satp_write_commit_o =
      pending_system_csr_commit_o &&
      (csr_access_addr_o == `CSR_SATP) &&
      csr_access_need_write_o;
  assign pending_system_sfence_commit_o =
      stop_pending_i && drain_complete_i &&
      pending_system_i && pending_system_sfence_i;

endmodule
