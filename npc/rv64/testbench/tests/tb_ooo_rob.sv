`include "define.v"

module tb_ooo_rob;
  `include "tb_common.svh"

  localparam ROB_INDEX_W = 4;
  localparam ROB_COUNT_W = 5;
  localparam PHY_REG_ADDR_W = 6;
  localparam PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W;

  reg clk;
  reg rst;
  reg flush;
  reg dispatch0_valid;
  wire dispatch0_ready;
  wire [ROB_INDEX_W-1:0] dispatch0_rob_idx;
  wire [PRODUCER_ID_W-1:0] dispatch0_producer_id;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`INST_W-1:0] dispatch0_inst;
  reg dispatch0_rd_en;
  reg [`REG_ADDR_W-1:0] dispatch0_arch_rd;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_old_pdest;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_new_pdest;
  reg dispatch1_valid;
  wire dispatch1_ready;
  wire [ROB_INDEX_W-1:0] dispatch1_rob_idx;
  wire [PRODUCER_ID_W-1:0] dispatch1_producer_id;
  wire [PRODUCER_ID_W-1:0] dispatch1_pair_producer_id;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  reg dispatch1_rd_en;
  reg [`REG_ADDR_W-1:0] dispatch1_arch_rd;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_old_pdest;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_new_pdest;
  reg wb0_valid;
  reg [ROB_INDEX_W-1:0] wb0_rob_idx;
  reg [`XLEN-1:0] wb0_data;
  reg wb0_exception;
  reg [`TRAP_CAUSE_W-1:0] wb0_cause;
  reg [`XLEN-1:0] wb0_tval;
  reg [PHY_REG_ADDR_W-1:0] wb0_pdest;
  reg wb1_valid;
  reg [ROB_INDEX_W-1:0] wb1_rob_idx;
  reg [`XLEN-1:0] wb1_data;
  reg wb1_exception;
  reg [`TRAP_CAUSE_W-1:0] wb1_cause;
  reg [`XLEN-1:0] wb1_tval;
  reg [PHY_REG_ADDR_W-1:0] wb1_pdest;
  reg current0_query_valid;
  reg [PRODUCER_ID_W-1:0] current0_query_producer_id;
  wire current0_query_match;
  reg current1_query_valid;
  reg [PRODUCER_ID_W-1:0] current1_query_producer_id;
  wire current1_query_match;
  reg completion0_query_valid;
  reg [PRODUCER_ID_W-1:0] completion0_query_producer_id;
  wire completion0_query_match;
  reg completion1_query_valid;
  reg [PRODUCER_ID_W-1:0] completion1_query_producer_id;
  wire completion1_query_match;
  reg completion2_query_valid;
  reg [PRODUCER_ID_W-1:0] completion2_query_producer_id;
  wire completion2_query_match;
  reg completion3_query_valid;
  reg [PRODUCER_ID_W-1:0] completion3_query_producer_id;
  wire completion3_query_match;
  reg completion4_query_valid;
  reg [PRODUCER_ID_W-1:0] completion4_query_producer_id;
  wire completion4_query_match;
  reg completion5_query_valid;
  reg [PRODUCER_ID_W-1:0] completion5_query_producer_id;
  wire completion5_query_match;
  reg completion6_query_valid;
  reg [PRODUCER_ID_W-1:0] completion6_query_producer_id;
  wire completion6_query_match;
  reg completion7_query_valid;
  reg [PRODUCER_ID_W-1:0] completion7_query_producer_id;
  wire completion7_query_match;
  reg resolve_query_valid;
  reg [PRODUCER_ID_W-1:0] resolve_query_producer_id;
  wire resolve_query_match;
  reg commit_ready;
  reg mem_quiet;
  reg head0_context_permit;
  reg fencei_retire_permit;
  reg pending_csr_owner_valid;
  reg [PRODUCER_ID_W-1:0] pending_csr_owner_producer_id;
  wire head0_retire_candidate_valid;
  wire head0_identity_valid;
  wire [`OOO_CONTEXT_ID_W-1:0] head0_identity;
  wire [PRODUCER_ID_W-1:0] head0_producer_id;
  wire head0_launch_open;
  wire head0_control_event_pregrant;
  wire head0_full_flush_pregrant;
  wire [`REDIR_REASON_W-1:0] head0_full_flush_reason;
  wire commit0_valid;
  wire [PRODUCER_ID_W-1:0] commit0_producer_id;
  wire [`XLEN-1:0] commit0_pc;
  wire [`XLEN-1:0] commit0_next_pc;
  wire [`INST_W-1:0] commit0_inst;
  wire commit0_rd_en;
  wire [`REG_ADDR_W-1:0] commit0_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit0_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit0_new_pdest;
  wire [`XLEN-1:0] commit0_data;
  wire commit0_exception;
  wire [`TRAP_CAUSE_W-1:0] commit0_cause;
  wire [`XLEN-1:0] commit0_tval;
  wire commit1_valid;
  wire [PRODUCER_ID_W-1:0] commit1_producer_id;
  wire [`XLEN-1:0] commit1_pc;
  wire [`XLEN-1:0] commit1_next_pc;
  wire [`INST_W-1:0] commit1_inst;
  wire commit1_rd_en;
  wire [`REG_ADDR_W-1:0] commit1_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit1_new_pdest;
  wire [`XLEN-1:0] commit1_data;
  wire commit1_exception;
  wire [`TRAP_CAUSE_W-1:0] commit1_cause;
  wire [`XLEN-1:0] commit1_tval;
  wire [ROB_COUNT_W-1:0] count;
  wire empty;
  wire full;
  wire arch_commit0_write;
  wire arch_commit1_write;
  wire [`XLEN-1:0] arch_a0;
  wire [`XLEN * `REG_NUM - 1:0] arch_gprs;
  wire commit_exception_trap;
  wire trap_mem_valid;
  wire [`XLEN-1:0] trap_mem_pc;
  wire [`TRAP_CAUSE_W-1:0] trap_mem_cause;
  wire [`XLEN-1:0] trap_mem_tval;
  reg [ROB_INDEX_W-1:0] saved0;
  reg [PRODUCER_ID_W-1:0] saved0_producer;
  reg [ROB_INDEX_W-1:0] saved1;

  // B2 ROB-walk 恢复端口
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  wire recover_active;
  wire walk0_valid;
  wire [PRODUCER_ID_W-1:0] walk0_producer_id;
  wire [`REG_ADDR_W-1:0] walk0_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] walk0_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] walk0_new_pdest;
  wire walk0_rd_en;
  wire walk1_valid;
  wire [PRODUCER_ID_W-1:0] walk1_producer_id;
  wire [`REG_ADDR_W-1:0] walk1_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] walk1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] walk1_new_pdest;
  wire walk1_rd_en;
  wire unused_walk_w = walk0_rd_en | walk1_rd_en |
                       (|walk0_new_pdest) | (|walk1_new_pdest);

  OooRob dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_rob_idx_o(dispatch0_rob_idx),
    .dispatch0_producer_id_o(dispatch0_producer_id),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_rd_en_i(dispatch0_rd_en),
    .dispatch0_is_fp_rd_i(1'b0),
    .dispatch0_arch_rd_i(dispatch0_arch_rd),
    .dispatch0_old_pdest_i(dispatch0_old_pdest),
    .dispatch0_new_pdest_i(dispatch0_new_pdest),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_rob_idx_o(dispatch1_rob_idx),
    .dispatch1_producer_id_o(dispatch1_producer_id),
    .dispatch1_pair_producer_id_o(dispatch1_pair_producer_id),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_rd_en_i(dispatch1_rd_en),
    .dispatch1_is_fp_rd_i(1'b0),
    .dispatch1_arch_rd_i(dispatch1_arch_rd),
    .dispatch1_old_pdest_i(dispatch1_old_pdest),
    .dispatch1_new_pdest_i(dispatch1_new_pdest),
    .wb0_valid_i(wb0_valid),
    .wb0_rob_idx_i(wb0_rob_idx),
    .wb0_data_i(wb0_data),
    .wb0_exception_i(wb0_exception),
    .wb0_cause_i(wb0_cause),
    .wb0_tval_i(wb0_tval),
    .wb0_fflags_i(5'b00000),
    .wb0_pdest_i(wb0_pdest),
    .wb1_valid_i(wb1_valid),
    .wb1_rob_idx_i(wb1_rob_idx),
    .wb1_data_i(wb1_data),
    .wb1_exception_i(wb1_exception),
    .wb1_cause_i(wb1_cause),
    .wb1_tval_i(wb1_tval),
    .wb1_fflags_i(5'b00000),
    .wb1_pdest_i(wb1_pdest),
    .current0_query_valid_i(current0_query_valid),
    .current0_query_producer_id_i(current0_query_producer_id),
    .current0_query_match_o(current0_query_match),
    .current1_query_valid_i(current1_query_valid),
    .current1_query_producer_id_i(current1_query_producer_id),
    .current1_query_match_o(current1_query_match),
    .completion0_query_valid_i(completion0_query_valid),
    .completion0_query_producer_id_i(completion0_query_producer_id),
    .completion0_query_match_o(completion0_query_match),
    .completion1_query_valid_i(completion1_query_valid),
    .completion1_query_producer_id_i(completion1_query_producer_id),
    .completion1_query_match_o(completion1_query_match),
    .completion2_query_valid_i(completion2_query_valid),
    .completion2_query_producer_id_i(completion2_query_producer_id),
    .completion2_query_match_o(completion2_query_match),
    .completion3_query_valid_i(completion3_query_valid),
    .completion3_query_producer_id_i(completion3_query_producer_id),
    .completion3_query_match_o(completion3_query_match),
    .completion4_query_valid_i(completion4_query_valid),
    .completion4_query_producer_id_i(completion4_query_producer_id),
    .completion4_query_match_o(completion4_query_match),
    .completion5_query_valid_i(completion5_query_valid),
    .completion5_query_producer_id_i(completion5_query_producer_id),
    .completion5_query_match_o(completion5_query_match),
    .completion6_query_valid_i(completion6_query_valid),
    .completion6_query_producer_id_i(completion6_query_producer_id),
    .completion6_query_match_o(completion6_query_match),
    .completion7_query_valid_i(completion7_query_valid),
    .completion7_query_producer_id_i(completion7_query_producer_id),
    .completion7_query_match_o(completion7_query_match),
    .resolve_query_valid_i(resolve_query_valid),
    .resolve_query_producer_id_i(resolve_query_producer_id),
    .resolve_query_match_o(resolve_query_match),
    .commit_ready_i(commit_ready),
    .commit_pregrant_ready_i(commit_ready),
    .head0_context_permit_i(head0_context_permit),
    .fencei_retire_permit_i(fencei_retire_permit),
    .pending_csr_owner_valid_i(pending_csr_owner_valid),
    .pending_csr_owner_producer_id_i(pending_csr_owner_producer_id),
    .head0_retire_candidate_valid_o(head0_retire_candidate_valid),
    .head0_identity_valid_o(head0_identity_valid),
    .head0_identity_o(head0_identity),
    .head0_producer_id_o(head0_producer_id),
    .head0_launch_open_o(head0_launch_open),
    .head0_control_event_pregrant_o(head0_control_event_pregrant),
    .head0_full_flush_pregrant_o(head0_full_flush_pregrant),
    .head0_full_flush_reason_o(head0_full_flush_reason),
    .commit1_block_i(1'b0),
    .mem_quiet_i(mem_quiet),
    .commit0_valid_o(commit0_valid),
    .commit0_producer_id_o(commit0_producer_id),
    .commit0_pc_o(commit0_pc),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_arch_rd_o(commit0_arch_rd),
    .commit0_old_pdest_o(commit0_old_pdest),
    .commit0_new_pdest_o(commit0_new_pdest),
    .commit0_data_o(commit0_data),
    .commit0_exception_o(commit0_exception),
    .commit0_cause_o(commit0_cause),
    .commit0_tval_o(commit0_tval),
    .commit1_valid_o(commit1_valid),
    .commit1_producer_id_o(commit1_producer_id),
    .commit1_pc_o(commit1_pc),
    .commit1_next_pc_o(commit1_next_pc),
    .commit1_inst_o(commit1_inst),
    .commit1_rd_en_o(commit1_rd_en),
    .commit1_arch_rd_o(commit1_arch_rd),
    .commit1_old_pdest_o(commit1_old_pdest),
    .commit1_new_pdest_o(commit1_new_pdest),
    .commit1_data_o(commit1_data),
    .commit1_exception_o(commit1_exception),
    .commit1_cause_o(commit1_cause),
    .commit1_tval_o(commit1_tval),
    .count_o(count),
    .empty_o(empty),
    .full_o(full),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .recover_active_o(recover_active),
    .walk0_valid_o(walk0_valid),
    .walk0_producer_id_o(walk0_producer_id),
    .walk0_arch_rd_o(walk0_arch_rd),
    .walk0_old_pdest_o(walk0_old_pdest),
    .walk0_new_pdest_o(walk0_new_pdest),
    .walk0_rd_en_o(walk0_rd_en),
    .walk1_valid_o(walk1_valid),
    .walk1_producer_id_o(walk1_producer_id),
    .walk1_arch_rd_o(walk1_arch_rd),
    .walk1_old_pdest_o(walk1_old_pdest),
    .walk1_new_pdest_o(walk1_new_pdest),
    .walk1_rd_en_o(walk1_rd_en)
  );

  // 用生产侧副作用/陷阱模块消费真实 ROB commit，总线不靠 TB 重写判据。
  // 这样 head1 exception 的定向用例同时覆盖 lane1 trap 选择和 GPR 写抑制。
  OooArchRegFile u_arch_regfile (
    .clk(clk),
    .rst(rst),
    .commit0_valid_i(commit0_valid),
    .commit0_rd_en_i(commit0_rd_en),
    .commit0_arch_rd_i(commit0_arch_rd),
    .commit0_data_i(commit0_data),
    .commit0_exception_i(commit0_exception),
    .commit1_valid_i(commit1_valid),
    .commit1_rd_en_i(commit1_rd_en),
    .commit1_arch_rd_i(commit1_arch_rd),
    .commit1_data_i(commit1_data),
    .commit1_exception_i(commit1_exception),
    .serial_write_valid_i(1'b0),
    .serial_write_arch_rd_i({`REG_ADDR_W{1'b0}}),
    .serial_write_data_i({`XLEN{1'b0}}),
    .commit0_write_o(arch_commit0_write),
    .commit1_write_o(arch_commit1_write),
    .a0_data_o(arch_a0),
    .debug_gprs_o(arch_gprs)
  );

  OooCsrTrapRequestMux u_trap_request_mux (
    .core_commit0_valid_i(commit0_valid),
    .core_commit0_exception_i(commit0_exception),
    .core_commit0_pc_i(commit0_pc),
    .core_commit0_cause_i(commit0_cause),
    .core_commit0_tval_i(commit0_tval),
    .core_commit1_valid_i(commit1_valid),
    .core_commit1_exception_i(commit1_exception),
    .core_commit1_pc_i(commit1_pc),
    .core_commit1_cause_i(commit1_cause),
    .core_commit1_tval_i(commit1_tval),
    .stop_pending_i(1'b0),
    .drain_complete_i(1'b0),
    .pending_arch_trap_i(1'b0),
    .pending_trap_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .pending_trap_pc_i({`XLEN{1'b0}}),
    .pending_trap_tval_i({`XLEN{1'b0}}),
    .pending_system_i(1'b0),
    .pending_system_ecall_i(1'b0),
    .pending_system_mret_i(1'b0),
    .pending_system_irq_i(1'b0),
    .pending_system_pc_i({`XLEN{1'b0}}),
    .pending_system_inst_i({`INST_W{1'b0}}),
    .pending_system_irq_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .csr_ecall_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .pending_system_satp_write_commit_i(1'b0),
    .pending_system_sfence_commit_i(1'b0),
    .core_commit_exception_trap_o(commit_exception_trap),
    .trap_mem_valid_o(trap_mem_valid),
    .trap_mem_pc_o(trap_mem_pc),
    .trap_mem_cause_o(trap_mem_cause),
    .trap_mem_tval_o(trap_mem_tval),
    .pending_system_ecall_trap_o(),
    .pending_arch_trap_fire_o(),
    .trap_ex_valid_o(),
    .trap_ex_pc_o(),
    .trap_ex_cause_o(),
    .trap_ex_tval_o(),
    .trap_irq_valid_o(),
    .trap_irq_pc_o(),
    .trap_irq_cause_o(),
    .mret_valid_o(),
    .sret_valid_o(),
    .real_mret_valid_o(),
    .priv_predictor_boundary_o()
  );

  wire unused_next_pc_w = (|commit0_next_pc) | (|commit1_next_pc) |
                          (|arch_a0);

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
      dispatch0_rd_en = 1'b0;
      dispatch0_arch_rd = 5'd0;
      dispatch0_old_pdest = 6'd0;
      dispatch0_new_pdest = 6'd0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_inst = 32'h0;
      dispatch1_rd_en = 1'b0;
      dispatch1_arch_rd = 5'd0;
      dispatch1_old_pdest = 6'd0;
      dispatch1_new_pdest = 6'd0;
      wb0_valid = 1'b0;
      wb0_rob_idx = 4'd0;
      wb0_data = 32'h0;
      wb0_exception = 1'b0;
      wb0_cause = 5'd0;
      wb0_tval = 32'h0;
      wb0_pdest = {PHY_REG_ADDR_W{1'b0}};
      wb1_valid = 1'b0;
      wb1_rob_idx = 4'd0;
      wb1_data = 32'h0;
      wb1_exception = 1'b0;
      wb1_cause = 5'd0;
      wb1_tval = 32'h0;
      wb1_pdest = {PHY_REG_ADDR_W{1'b0}};
      current0_query_valid = 1'b0;
      current0_query_producer_id = {PRODUCER_ID_W{1'b0}};
      current1_query_valid = 1'b0;
      current1_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion0_query_valid = 1'b0;
      completion0_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion1_query_valid = 1'b0;
      completion1_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion2_query_valid = 1'b0;
      completion2_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion3_query_valid = 1'b0;
      completion3_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion4_query_valid = 1'b0;
      completion4_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion5_query_valid = 1'b0;
      completion5_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion6_query_valid = 1'b0;
      completion6_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion7_query_valid = 1'b0;
      completion7_query_producer_id = {PRODUCER_ID_W{1'b0}};
      resolve_query_valid = 1'b0;
      resolve_query_producer_id = {PRODUCER_ID_W{1'b0}};
      kill_valid = 1'b0;
      kill_rob_idx = 4'd0;
      head0_context_permit = 1'b1;
      fencei_retire_permit = 1'b1;
      pending_csr_owner_valid = 1'b0;
      pending_csr_owner_producer_id = {PRODUCER_ID_W{1'b0}};
      mem_quiet = 1'b1;
    end
  endtask

  // v8j branch-resolve authority is intentionally different from a generic
  // completion query: current self-kill must not reject its own boundary,
  // while prior recovery, invalid, done and stale generation remain hard
  // death edges.  This also locks the killed-now helper's full sensitivity:
  // toggling kill with an unchanged target index must immediately recompute.
  task automatic exercise_v8j_resolve_query;
    reg [PRODUCER_ID_W-1:0] id0;
    reg [PRODUCER_ID_W-1:0] id1;
    reg [PRODUCER_ID_W-1:0] stale_id0;
    reg [PRODUCER_ID_W-1:0] vacant_id;
    begin
      reset_dut();
      commit_ready = 1'b0;

      vacant_id = {dut.slot_generation_q[0], {ROB_INDEX_W{1'b0}}};
      resolve_query_valid = 1'b1;
      resolve_query_producer_id = vacant_id;
      #1;
      tb_check1("v8j vacant exact encoding resolve closed",
                resolve_query_match, 1'b0);

      clear_inputs();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_1200;
      dispatch0_inst = 32'h0000_0013;
      dispatch1_valid = 1'b1;
      dispatch1_pc = 32'h8000_1204;
      dispatch1_inst = 32'h0000_0013;
      #1;
      id0 = dispatch0_producer_id;
      id1 = dispatch1_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;

      resolve_query_valid = 1'b1;
      resolve_query_producer_id = id0;
      #1;
      tb_check1("v8j live exact unfinished resolve open",
                resolve_query_match, 1'b1);
      tb_check32("v8j resolve raw index projects from full PID",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.resolve_query_idx_w},
                 {{(32-ROB_INDEX_W){1'b0}}, id0[ROB_INDEX_W-1:0]});

      stale_id0 = id0;
      stale_id0[ROB_INDEX_W] = ~id0[ROB_INDEX_W];
      resolve_query_producer_id = stale_id0;
      #1;
      tb_check1("v8j same raw index stale generation resolve closed",
                resolve_query_match, 1'b0);

      resolve_query_producer_id = id0;
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id0;
      kill_valid = 1'b1;
      kill_rob_idx = id0[ROB_INDEX_W-1:0];
      #1;
      tb_check1("v8j current self-kill keeps boundary resolve open",
                resolve_query_match, 1'b1);
      tb_check1("v8j generic completion also keeps equal boundary open",
                completion0_query_match, 1'b1);

      // Use the unchanged id1 query to prove killed-now depends on explicit
      // kill inputs, not only on target_idx.  First it is younger than id0;
      // after kill drops it must reopen without changing PID/index.
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id1;
      #1;
      tb_check1("v8j explicit kill masks unchanged younger completion",
                completion0_query_match, 1'b0);
      kill_valid = 1'b0;
      #1;
      tb_check1("v8j kill drop recomputes unchanged completion query",
                completion0_query_match, 1'b1);

      // Start recovery from id0 and prove the specialized query closes on
      // edge-old recover_q, even though id0 itself remains physically live.
      kill_valid = 1'b1;
      kill_rob_idx = id0[ROB_INDEX_W-1:0];
      resolve_query_producer_id = id0;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      resolve_query_valid = 1'b1;
      resolve_query_producer_id = id0;
      #1;
      tb_check1("v8j prior recovery active", recover_active, 1'b1);
      tb_check1("v8j prior recovery closes resolve query",
                resolve_query_match, 1'b0);

      reset_dut();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_1210;
      dispatch0_inst = 32'h0000_0013;
      #1;
      id0 = dispatch0_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      wb0_valid = 1'b1;
      wb0_rob_idx = id0[ROB_INDEX_W-1:0];
      wb0_pdest = {PHY_REG_ADDR_W{1'b0}};
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      resolve_query_valid = 1'b1;
      resolve_query_producer_id = id0;
      #1;
      tb_check1("v8j done slot resolve closed", resolve_query_match, 1'b0);
      flush = 1'b1;
      #1;
      tb_check1("v8j flush keeps resolve closed", resolve_query_match, 1'b0);
      flush = 1'b0;
      rst = 1'b1;
      #1;
      tb_check1("v8j reset masks resolve query", resolve_query_match, 1'b0);
      rst = 1'b0;
      reset_dut();
      $display("[V8J-ROB-RESOLVE-QUERY] exact/stale/done/self-kill/recovery/reset/flush/sensitivity PASS");
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      commit_ready = 1'b1;
      clear_inputs();
      dispatch0_valid = 1'b1;
      dispatch1_valid = 1'b1;
      #1;
      tb_check1("v8e reset blocks presented lane0 allocation",
                dispatch0_ready, 1'b0);
      tb_check1("v8e reset blocks presented lane1 allocation",
                dispatch1_ready, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic set_all_completion_queries;
    input query_valid;
    input [PRODUCER_ID_W-1:0] producer_id;
    begin
      completion0_query_valid = query_valid;
      completion0_query_producer_id = producer_id;
      completion1_query_valid = query_valid;
      completion1_query_producer_id = producer_id;
      completion2_query_valid = query_valid;
      completion2_query_producer_id = producer_id;
      completion3_query_valid = query_valid;
      completion3_query_producer_id = producer_id;
      completion4_query_valid = query_valid;
      completion4_query_producer_id = producer_id;
      completion5_query_valid = query_valid;
      completion5_query_producer_id = producer_id;
      completion6_query_valid = query_valid;
      completion6_query_producer_id = producer_id;
      completion7_query_valid = query_valid;
      completion7_query_producer_id = producer_id;
    end
  endtask

  task automatic check_all_completion_queries;
    input expected;
    begin
      tb_check1("V9O full-C0 completion class 0", completion0_query_match,
                expected);
      tb_check1("V9O full-C0 completion class 1", completion1_query_match,
                expected);
      tb_check1("V9O full-C0 completion class 2", completion2_query_match,
                expected);
      tb_check1("V9O full-C0 completion class 3", completion3_query_match,
                expected);
      tb_check1("V9O full-C0 completion class 4", completion4_query_match,
                expected);
      tb_check1("V9O full-C0 completion class 5", completion5_query_match,
                expected);
      tb_check1("V9O full-C0 completion class 6", completion6_query_match,
                expected);
      tb_check1("V9O full-C0 completion class 7", completion7_query_match,
                expected);
    end
  endtask

  // Drive a real registered exception at ROB index 15 with a live younger
  // entry at index 0.  Before the head becomes done all eight production
  // completion-query classes must see the younger owner; in the true C0
  // full-pregrant cycle the same unchanged PID must be cut in every class.
  task automatic exercise_v9o_full_pregrant_completion_matrix;
    integer advance;
    reg [PRODUCER_ID_W-1:0] head_id;
    reg [PRODUCER_ID_W-1:0] younger_id;
    begin
      reset_dut();
      for (advance = 0; advance < 15; advance = advance + 1) begin
        dispatch0_valid = 1'b1;
        dispatch0_pc = 32'h8000_2000 + (advance * 8);
        dispatch0_inst = 32'h0000_0013;
        #1;
        saved0 = dispatch0_rob_idx;
        `TB_TICK(clk);
        clear_inputs();
        wb0_valid = 1'b1;
        wb0_rob_idx = saved0;
        wb0_data = 32'h2000_0000 + advance;
        `TB_TICK(clk);
        clear_inputs();
        #1;
        tb_check1("V9O wrap setup entry retires", commit0_valid, 1'b1);
        `TB_TICK(clk);
        clear_inputs();
      end

      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_2ff0;
      dispatch0_inst = 32'h0000_0013;
      dispatch1_valid = 1'b1;
      dispatch1_pc = 32'h8000_2ff4;
      dispatch1_inst = 32'h0000_0013;
      #1;
      head_id = dispatch0_producer_id;
      younger_id = dispatch1_producer_id;
      tb_check32("V9O full-C0 wrap head index",
                 {{(32-ROB_INDEX_W){1'b0}}, head_id[ROB_INDEX_W-1:0]},
                 32'd15);
      tb_check32("V9O full-C0 wrap younger index",
                 {{(32-ROB_INDEX_W){1'b0}}, younger_id[ROB_INDEX_W-1:0]},
                 32'd0);
      `TB_TICK(clk);
      clear_inputs();

      set_all_completion_queries(1'b1, younger_id);
      #1;
      check_all_completion_queries(1'b1);

      wb0_valid = 1'b1;
      wb0_rob_idx = head_id[ROB_INDEX_W-1:0];
      wb0_data = 32'h2ff0_0001;
      wb0_exception = 1'b1;
      wb0_cause = `EXC_ILLEGAL_INST;
      wb0_tval = 32'h2ff0_dead;
      `TB_TICK(clk);
      clear_inputs();
      set_all_completion_queries(1'b1, younger_id);
      #1;
      tb_check1("V9O real full-C0 pregrant active",
                head0_full_flush_pregrant, 1'b1);
      tb_check32("V9O real full-C0 reason is trap",
                 {{(32-`REDIR_REASON_W){1'b0}}, head0_full_flush_reason},
                 {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_TRAP});
      check_all_completion_queries(1'b0);
      $display("[V9O-FULL-C0-COMPLETION-MATRIX] classes=8 wrap_head=15 wrap_younger=0 PASS");

      `TB_TICK(clk);
      clear_inputs();
      reset_dut();
    end
  endtask

  task automatic exercise_v8a_lane1_boundary;
    input [`INST_W-1:0] boundary_inst;
    input [3:0] expected_class;
    input [`XLEN-1:0] base_pc;
    begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = base_pc;
      dispatch0_inst = 32'h0000_0013;
      dispatch1_valid = 1'b1;
      dispatch1_pc = base_pc + 32'd4;
      dispatch1_inst = boundary_inst;
      #1;
      saved0 = dispatch0_rob_idx;
      saved1 = dispatch1_rob_idx;
      `TB_TICK(clk);
      clear_inputs();
      wb0_valid = 1'b1;
      wb0_rob_idx = saved0;
      wb0_data = base_pc + 32'd1;
      wb1_valid = 1'b1;
      wb1_rob_idx = saved1;
      wb1_data = base_pc + 32'd2;
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("v8a lane1 csr raw classifier", dut.head1_is_csr_raw_w,
                expected_class[0]);
      tb_check1("v8a lane1 sfence raw classifier", dut.head1_is_sfence_vma_raw_w,
                expected_class[1]);
      tb_check1("v8a lane1 xret raw classifier", dut.head1_is_xret_raw_w,
                expected_class[2]);
      tb_check1("v8a lane1 fencei raw classifier", dut.head1_is_fencei_raw_w,
                expected_class[3]);
      tb_check1("v8a lane1 boundary shadow live",
                dut.head1_context_boundary_shadow_w, 1'b1);
      tb_check1("v8a lane1 boundary does not gate commit0", commit0_valid, 1'b1);
      tb_check1("v8a lane1 boundary does not gate commit1", commit1_valid, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("v8a lane1 boundary pair retired", {27'b0, count}, 32'd0);
    end
  endtask

  task automatic exercise_v8e_producer_id_source;
    reg [PRODUCER_ID_W-1:0] first_slot0_id;
    reg [PRODUCER_ID_W-1:0] first_slot1_id;
    reg [PRODUCER_ID_W-1:0] first_slot2_id;
    reg [PRODUCER_ID_W-1:0] rejected_candidate_id;
    reg [PRODUCER_ID_W-1:0] branch_wrap_old_id;
    reg [PRODUCER_ID_W-1:0] branch_wrap_new_id;
    integer fill_pair;
    begin
      reset_dut();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0e00;
      dispatch0_inst = 32'h0000_0013;
      dispatch1_valid = 1'b1;
      dispatch1_pc = 32'h8000_0e04;
      dispatch1_inst = 32'h0000_0013;
      #1;
      tb_check32("v8e first lane0 producer id",
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch0_producer_id},
                 32'h0000_0000);
      tb_check32("v8e first lane1 producer id",
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch1_producer_id},
                 32'h0000_0001);
      first_slot0_id = dispatch0_producer_id;
      first_slot1_id = dispatch1_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      #1;
      tb_check32("v8e live head producer id",
                 {{(32-PRODUCER_ID_W){1'b0}}, head0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, first_slot0_id});
      tb_check32("v8e commit carrier matches live head",
                 {{(32-PRODUCER_ID_W){1'b0}}, commit0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, first_slot0_id});
      tb_check32("v8e commit1 carrier matches second live slot",
                 {{(32-PRODUCER_ID_W){1'b0}}, commit1_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, first_slot1_id});

      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0e08;
      dispatch0_inst = 32'h0000_0013;
      #1;
      first_slot2_id = dispatch0_producer_id;
      tb_check32("v8e third allocation producer id",
                 {{(32-PRODUCER_ID_W){1'b0}}, first_slot2_id},
                 32'h0000_0002);
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      kill_valid = 1'b1;
      kill_rob_idx = {ROB_INDEX_W{1'b0}};
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      #1;
      tb_check1("v8e recovery exposes walk pair", walk0_valid && walk1_valid,
                1'b1);
      tb_check32("v8e walk0 carrier matches youngest slot",
                 {{(32-PRODUCER_ID_W){1'b0}}, walk0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, first_slot2_id});
      tb_check32("v8e walk1 carrier matches next-youngest slot",
                 {{(32-PRODUCER_ID_W){1'b0}}, walk1_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, first_slot1_id});
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;

      // Ordinary pipeline flush drains ROB-local lifetime but must preserve the
      // encoding source: the next incarnation of slot 0 advances generation.
      flush = 1'b1;
      dispatch0_valid = 1'b1;
      dispatch1_valid = 1'b1;
      #1;
      tb_check1("v8e flush blocks presented lane0 allocation",
                dispatch0_ready, 1'b0);
      tb_check1("v8e flush blocks presented lane1 allocation",
                dispatch1_ready, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0e10;
      dispatch0_inst = 32'h0000_0013;
      #1;
      tb_check32("v8e flush reuses raw slot zero",
                 {{(32-ROB_INDEX_W){1'b0}}, dispatch0_rob_idx},
                 32'h0000_0000);
      tb_check32("v8e flush preserves generation source",
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch0_producer_id},
                 (32'h1 << ROB_INDEX_W));
      tb_check1("v8e same raw slot gets a distinct finite id",
                dispatch0_producer_id != first_slot0_id, 1'b1);

      // A presented valid while full is not an accepted allocation and must
      // not advance any slot generation. Fill all 16 slots, hold one rejected
      // request for two edges, then flush and observe exactly one increment.
      reset_dut();
      commit_ready = 1'b0;
      for (fill_pair = 0; fill_pair < 8; fill_pair = fill_pair + 1) begin
        dispatch0_valid = 1'b1;
        dispatch1_valid = 1'b1;
        dispatch0_pc = 32'h8000_0e40 + (fill_pair * 8);
        dispatch1_pc = 32'h8000_0e44 + (fill_pair * 8);
        dispatch0_inst = 32'h0000_0013;
        dispatch1_inst = 32'h0000_0013;
        `TB_TICK(clk);
        clear_inputs();
        commit_ready = 1'b0;
      end
      #1;
      tb_check1("v8e fill reaches full", full, 1'b1);
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0ef0;
      dispatch0_inst = 32'h0000_0013;
      #1;
      tb_check1("v8e full rejects presented allocation", dispatch0_ready,
                1'b0);
      rejected_candidate_id = dispatch0_producer_id;
      `TB_TICK(clk);
      #1;
      tb_check32("v8e candidate stable across first rejected edge",
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, rejected_candidate_id});
      `TB_TICK(clk);
      #1;
      tb_check32("v8e candidate stable across second rejected edge",
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, rejected_candidate_id});
      flush = 1'b1;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0ef4;
      dispatch0_inst = 32'h0000_0013;
      #1;
      tb_check32("v8e rejected valid does not advance generation",
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch0_producer_id},
                 (32'h1 << ROB_INDEX_W));

      // Real selective recovery across the ring: advance an empty ROB to
      // tail=15, allocate survivor branch@15 plus old@0, squash old@0 through
      // the production walk, then reuse slot 0 without a global flush.
      reset_dut();
      commit_ready = 1'b0;
      for (fill_pair = 0; fill_pair < 7; fill_pair = fill_pair + 1) begin
        dispatch0_valid = 1'b1;
        dispatch1_valid = 1'b1;
        dispatch0_pc = 32'h8000_1000 + (fill_pair * 8);
        dispatch1_pc = 32'h8000_1004 + (fill_pair * 8);
        dispatch0_inst = 32'h0000_0013;
        dispatch1_inst = 32'h0000_0013;
        `TB_TICK(clk);
        clear_inputs();
        commit_ready = 1'b0;
      end
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_1038;
      dispatch0_inst = 32'h0000_0013;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      for (fill_pair = 0; fill_pair < 7; fill_pair = fill_pair + 1) begin
        wb0_valid = 1'b1;
        wb0_rob_idx = fill_pair * 2;
        wb1_valid = 1'b1;
        wb1_rob_idx = (fill_pair * 2) + 1;
        `TB_TICK(clk);
        clear_inputs();
        commit_ready = 1'b0;
      end
      wb0_valid = 1'b1;
      wb0_rob_idx = 4'd14;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b1;
      for (fill_pair = 0; fill_pair < 8; fill_pair = fill_pair + 1) begin
        `TB_TICK(clk);
        clear_inputs();
        commit_ready = 1'b1;
      end
      #1;
      tb_check32("v8e ring setup drains at tail fifteen",
                 {27'b0, count}, 32'd0);
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_10f0;
      dispatch0_inst = 32'h0000_0063;
      dispatch1_valid = 1'b1;
      dispatch1_pc = 32'h8000_10f4;
      dispatch1_inst = 32'h0000_0013;
      #1;
      tb_check32("v8e real-walk survivor branch slot",
                 {{(32-ROB_INDEX_W){1'b0}}, dispatch0_rob_idx}, 32'd15);
      tb_check32("v8e real-walk old producer slot",
                 {{(32-ROB_INDEX_W){1'b0}}, dispatch1_rob_idx}, 32'd0);
      branch_wrap_old_id = dispatch1_producer_id;
      tb_check32("v8e real-walk old slot generation preserved by commit",
                 {{(32-PRODUCER_ID_W){1'b0}}, branch_wrap_old_id},
                 (32'h1 << ROB_INDEX_W));
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      kill_valid = 1'b1;
      kill_rob_idx = 4'd15;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      #1;
      tb_check1("v8e real-walk squashes old slot zero", walk0_valid, 1'b1);
      tb_check32("v8e real-walk carries old slot identity",
                 {{(32-PRODUCER_ID_W){1'b0}}, walk0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, branch_wrap_old_id});
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_10f8;
      dispatch0_inst = 32'h0000_0013;
      #1;
      branch_wrap_new_id = dispatch0_producer_id;
      tb_check32("v8e real-walk reuses raw slot zero",
                 {{(32-ROB_INDEX_W){1'b0}}, dispatch0_rob_idx}, 32'd0);
      tb_check1("v8e real-walk old/new producer ids differ",
                branch_wrap_new_id != branch_wrap_old_id, 1'b1);
      tb_check32("v8e real-walk new slot generation preserved by recovery",
                 {{(32-PRODUCER_ID_W){1'b0}}, branch_wrap_new_id},
                 ((32'h2 & ((32'h1 << PRODUCER_GEN_W) - 1)) << ROB_INDEX_W));

      // Hard reset is permitted to restart the finite encoding only because
      // the task contract requires the whole producer-holder reset domain to
      // drain together.
      reset_dut();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0e20;
      dispatch0_inst = 32'h0000_0013;
      #1;
      tb_check32("v8e hard reset restarts producer encoding",
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch0_producer_id},
                 32'h0000_0000);
      $display("[V8E-PRODUCER-ID-SOURCE-PASS] dual allocation/reset-flush handshake/stall/commit/ring-walk carriers covered");
      reset_dut();
    end
  endtask

  task automatic exercise_v8e_finite_wrap_red;
    reg [PRODUCER_ID_W-1:0] incarnation0_id;
    reg [PRODUCER_ID_W-1:0] incarnation1_id;
    reg [PRODUCER_ID_W-1:0] incarnation2_id;
    begin
      reset_dut();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0f00;
      dispatch0_inst = 32'h0000_0013;
      #1;
      incarnation0_id = dispatch0_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      flush = 1'b1;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0f04;
      dispatch0_inst = 32'h0000_0013;
      #1;
      incarnation1_id = dispatch0_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      flush = 1'b1;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0f08;
      dispatch0_inst = 32'h0000_0013;
      #1;
      incarnation2_id = dispatch0_producer_id;
      tb_check1("v8e wrap characterization first two ids differ",
                incarnation0_id != incarnation1_id, 1'b1);
      tb_check1("v8e finite generation eventually repeats full id",
                incarnation2_id == incarnation0_id, 1'b1);
      tb_check1("v8e allocation stays ready at repeated id",
                dispatch0_ready, 1'b1);
      $display("[V8E-FINITE-WRAP-RED] GEN_W=%0d full identity repeats while allocation remains ready; global collision fence is still absent",
               PRODUCER_GEN_W);
      tb_finish("tb_ooo_rob_v8e_finite_wrap_red");
    end
  endtask

  // v8f query contract: "current" authorizes issue-time observations while
  // "completion-open" additionally requires !done.  Exact generation and
  // first-cycle selective-recovery masking are checked independently of the
  // legacy raw-index WB interface.
  task automatic exercise_v8f_producer_queries;
    reg [PRODUCER_ID_W-1:0] id0;
    reg [PRODUCER_ID_W-1:0] id1;
    reg [PRODUCER_ID_W-1:0] id2;
    reg [PRODUCER_ID_W-1:0] wrong_id;
    reg [PRODUCER_ID_W-1:0] vacant_id;
    begin
      reset_dut();
      commit_ready = 1'b0;

      // Match the residual generation bits of an unallocated slot exactly.
      // Exact encoding alone must never confer authority without valid_q.
      vacant_id = {dut.slot_generation_q[0], {ROB_INDEX_W{1'b0}}};
      current0_query_valid = 1'b1;
      current0_query_producer_id = vacant_id;
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = vacant_id;
      completion3_query_valid = 1'b1;
      completion3_query_producer_id = vacant_id;
      completion4_query_valid = 1'b1;
      completion4_query_producer_id = vacant_id;
      completion5_query_valid = 1'b1;
      completion5_query_producer_id = vacant_id;
      completion6_query_valid = 1'b1;
      completion6_query_producer_id = vacant_id;
      #1;
      tb_check1("v8f vacant slot query matches residual encoding",
                dut.current0_query_exact_w, 1'b1);
      tb_check1("v8f vacant slot is not current",
                current0_query_match, 1'b0);
      tb_check1("v8f vacant slot completion is closed",
                completion0_query_match, 1'b0);
      tb_check1("v8h vacant MulDiv completion is closed",
                completion3_query_match, 1'b0);
      tb_check1("v8h vacant CLMUL completion is closed",
                completion4_query_match, 1'b0);
      tb_check1("v8i vacant FP result completion is closed",
                completion5_query_match, 1'b0);
      tb_check1("v8i vacant FP formal completion is closed",
                completion6_query_match, 1'b0);

      clear_inputs();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_1100;
      dispatch0_inst = 32'h0000_0013;
      dispatch1_valid = 1'b1;
      dispatch1_pc = 32'h8000_1104;
      dispatch1_inst = 32'h0000_0013;
      #1;
      id0 = dispatch0_producer_id;
      id1 = dispatch1_producer_id;
      tb_check1("v8h pair candidate PID is structurally distinct",
                dispatch0_producer_id != dispatch1_pair_producer_id, 1'b1);
      tb_check32("v8g mandatory pair candidate equals accepted lane1",
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch1_pair_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, dispatch1_producer_id});
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;

      current0_query_valid = 1'b1;
      current0_query_producer_id = id0;
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id0;
      current1_query_valid = 1'b1;
      current1_query_producer_id = id1;
      completion1_query_valid = 1'b1;
      completion1_query_producer_id = id1;
      completion2_query_valid = 1'b1;
      completion2_query_producer_id = id1;
      completion3_query_valid = 1'b1;
      completion3_query_producer_id = id0;
      completion4_query_valid = 1'b1;
      completion4_query_producer_id = id1;
      completion5_query_valid = 1'b1;
      completion5_query_producer_id = id0;
      completion6_query_valid = 1'b1;
      completion6_query_producer_id = id1;
      #1;
      tb_check1("v8f live id0 is current", current0_query_match, 1'b1);
      tb_check1("v8f live id0 completion is open",
                completion0_query_match, 1'b1);
      tb_check1("v8f live id1 is current", current1_query_match, 1'b1);
      tb_check1("v8f live id1 completion is open",
                completion1_query_match, 1'b1);
      tb_check1("v8g memory query live id1 completion is open",
                completion2_query_match, 1'b1);
      tb_check1("v8h MulDiv query live id0 completion is open",
                completion3_query_match, 1'b1);
      tb_check1("v8h CLMUL query live id1 completion is open",
                completion4_query_match, 1'b1);
      tb_check1("v8i FP result query live id0 completion is open",
                completion5_query_match, 1'b1);
      tb_check1("v8i FP formal query live id1 completion is open",
                completion6_query_match, 1'b1);
      tb_check1("v8g live unfinished head is launch-open",
                head0_launch_open, 1'b1);

      wrong_id = id0;
      wrong_id[ROB_INDEX_W] = ~id0[ROB_INDEX_W];
      current0_query_producer_id = wrong_id;
      completion0_query_producer_id = wrong_id;
      completion2_query_producer_id = wrong_id;
      completion3_query_producer_id = wrong_id;
      completion4_query_producer_id = wrong_id;
      completion5_query_producer_id = wrong_id;
      completion6_query_producer_id = wrong_id;
      #1;
      tb_check1("v8f wrong generation is not current",
                current0_query_match, 1'b0);
      tb_check1("v8f wrong generation completion is closed",
                completion0_query_match, 1'b0);
      tb_check1("v8g memory wrong generation completion is closed",
                completion2_query_match, 1'b0);
      tb_check1("v8h MulDiv wrong generation completion is closed",
                completion3_query_match, 1'b0);
      tb_check1("v8h CLMUL wrong generation completion is closed",
                completion4_query_match, 1'b0);
      tb_check1("v8i FP result wrong generation completion is closed",
                completion5_query_match, 1'b0);
      tb_check1("v8i FP formal wrong generation completion is closed",
                completion6_query_match, 1'b0);

      current0_query_producer_id = id0;
      completion0_query_producer_id = id0;
      wb0_valid = 1'b1;
      wb0_rob_idx = id0[ROB_INDEX_W-1:0];
      wb0_pdest = {PHY_REG_ADDR_W{1'b0}};
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      current0_query_valid = 1'b1;
      current0_query_producer_id = id0;
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id0;
      completion2_query_valid = 1'b1;
      completion2_query_producer_id = id0;
      completion3_query_valid = 1'b1;
      completion3_query_producer_id = id0;
      completion4_query_valid = 1'b1;
      completion4_query_producer_id = id0;
      completion5_query_valid = 1'b1;
      completion5_query_producer_id = id0;
      completion6_query_valid = 1'b1;
      completion6_query_producer_id = id0;
      current1_query_valid = 1'b1;
      current1_query_producer_id = id1;
      completion1_query_valid = 1'b1;
      completion1_query_producer_id = id1;
      #1;
      tb_check1("v8f done slot remains current", current0_query_match, 1'b1);
      tb_check1("v8f done slot completion closes",
                completion0_query_match, 1'b0);
      tb_check1("v8g memory done slot completion closes",
                completion2_query_match, 1'b0);
      tb_check1("v8h MulDiv done slot completion closes",
                completion3_query_match, 1'b0);
      tb_check1("v8h CLMUL done slot completion closes",
                completion4_query_match, 1'b0);
      tb_check1("v8i FP result done slot completion closes",
                completion5_query_match, 1'b0);
      tb_check1("v8i FP formal done slot completion closes",
                completion6_query_match, 1'b0);
      tb_check1("v8g done head is not launch-open", head0_launch_open, 1'b0);
      tb_check1("v8f other live slot remains current",
                current1_query_match, 1'b1);
      tb_check1("v8f other live slot remains completion-open",
                completion1_query_match, 1'b1);

      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_1108;
      dispatch0_inst = 32'h0000_0013;
      #1;
      id2 = dispatch0_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      current0_query_valid = 1'b1;
      current0_query_producer_id = id2;
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id2;
      completion3_query_valid = 1'b1;
      completion3_query_producer_id = id2;
      completion4_query_valid = 1'b1;
      completion4_query_producer_id = id2;
      current1_query_valid = 1'b1;
      current1_query_producer_id = id1;
      completion1_query_valid = 1'b1;
      completion1_query_producer_id = id1;
      kill_valid = 1'b1;
      kill_rob_idx = id1[ROB_INDEX_W-1:0];
      #1;
      tb_check1("v8f kill-start target is still physically live",
                dut.valid_q[id2[ROB_INDEX_W-1:0]], 1'b1);
      tb_check1("v8f kill-start masks younger current query",
                current0_query_match, 1'b0);
      tb_check1("v8f kill-start masks younger completion query",
                completion0_query_match, 1'b0);
      tb_check1("v8h kill-start masks younger MulDiv query",
                completion3_query_match, 1'b0);
      tb_check1("v8h kill-start masks younger CLMUL query",
                completion4_query_match, 1'b0);
      tb_check1("v8f kill boundary remains current",
                current1_query_match, 1'b1);
      tb_check1("v8f kill boundary remains completion-open",
                completion1_query_match, 1'b1);

      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      current0_query_valid = 1'b1;
      current0_query_producer_id = id2;
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id2;
      completion3_query_valid = 1'b1;
      completion3_query_producer_id = id2;
      completion4_query_valid = 1'b1;
      completion4_query_producer_id = id2;
      current1_query_valid = 1'b1;
      current1_query_producer_id = id1;
      completion1_query_valid = 1'b1;
      completion1_query_producer_id = id1;
      #1;
      tb_check1("v8f recovery window is active", recover_active, 1'b1);
      tb_check1("v8f recovery overlay masks younger current query",
                current0_query_match, 1'b0);
      tb_check1("v8f recovery overlay masks younger completion query",
                completion0_query_match, 1'b0);
      tb_check1("v8h recovery masks younger MulDiv query",
                completion3_query_match, 1'b0);
      tb_check1("v8h recovery masks younger CLMUL query",
                completion4_query_match, 1'b0);
      tb_check1("v8f recovery preserves boundary current query",
                current1_query_match, 1'b1);
      tb_check1("v8f recovery preserves boundary completion query",
                completion1_query_match, 1'b1);

      reset_dut();
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_1110;
      dispatch0_inst = 32'h0000_0013;
      #1;
      id0 = dispatch0_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      current0_query_valid = 1'b1;
      current0_query_producer_id = id0;
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id0;
      completion3_query_valid = 1'b1;
      completion3_query_producer_id = id0;
      completion4_query_valid = 1'b1;
      completion4_query_producer_id = id0;
      flush = 1'b1;
      #1;
      tb_check1("v8f flush masks current query", current0_query_match, 1'b0);
      tb_check1("v8f flush masks completion query",
                completion0_query_match, 1'b0);
      tb_check1("v8h flush masks MulDiv completion query",
                completion3_query_match, 1'b0);
      tb_check1("v8h flush masks CLMUL completion query",
                completion4_query_match, 1'b0);
      $display("[V8F-ROB-PRODUCER-QUERY] vacant/exact/current/open/done/kill/recovery/flush PASS");
      $display("[V8G-ROB-MEMORY-QUERY] query2 generation/done and pair/head Q-only contract PASS");
      $display("[V8H-ROB-LONGOP-QUERY] query3/4 exact-open and pair PID distinct contract PASS");
      reset_dut();
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();
    tb_check1("reset empty", empty, 1'b1);
    tb_check1("v8a reset candidate low", head0_retire_candidate_valid, 1'b0);
    tb_check1("v8a reset identity invalid", head0_identity_valid, 1'b0);

    exercise_v8e_producer_id_source();

    if ($test$plusargs("V8E_SOURCE_ONLY")) begin
      tb_finish("tb_ooo_rob_v8e_source_only");
    end

    if ($test$plusargs("V8E_FINITE_WRAP_RED")) begin
      if (PRODUCER_GEN_W != 1) begin
        $display("[CHECK-FAIL] v8e finite-wrap characterization requires PRODUCER_GEN_W=1");
        $fatal;
      end
      exercise_v8e_finite_wrap_red();
    end

    exercise_v8f_producer_queries();
    exercise_v8j_resolve_query();
    exercise_v9o_full_pregrant_completion_matrix();

    // Kept behind a plusarg so the normal regression remains positive while
    // the task-run negative runner can prove the dual-WB owner contract fires.
    if ($test$plusargs("T3W_ROB_WB_COLLISION_NEGATIVE")) begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0bad;
      dispatch0_inst = 32'h0000_0013;
      #1;
      saved0 = dispatch0_rob_idx;
      `TB_TICK(clk);
      clear_inputs();
      wb0_valid = 1'b1;
      wb0_rob_idx = saved0;
      wb0_data = 32'h1111_1111;
      wb1_valid = 1'b1;
      wb1_rob_idx = saved0;
      wb1_data = 32'h2222_2222;
      `TB_TICK(clk);
      $display("[CHECK-FAIL] dual-WB collision contract did not terminate");
      $fatal;
    end

    // The v8a negative is intentionally non-vacuous: create a live/done head
    // while commit_ready is low, then corrupt only the independent identity
    // observation. OOO_ASSERT must terminate on the frozen marker.
    if ($test$plusargs("S2_Q2_V8A_CANDIDATE_LIVE_NEGATIVE")) begin
      commit_ready = 1'b0;
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0a00;
      dispatch0_inst = 32'h0000_0013;
      #1;
      saved0 = dispatch0_rob_idx;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      wb0_valid = 1'b1;
      wb0_rob_idx = saved0;
      wb0_data = 32'h0a00_0001;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      #1;
      if (head0_retire_candidate_valid !== 1'b1) begin
        $display("[CHECK-FAIL] v8a negative setup never reached a live candidate");
        $fatal;
      end
      force dut.head0_identity_valid_o = 1'b0;
      `TB_TICK(clk);
      release dut.head0_identity_valid_o;
      $display("[CHECK-FAIL] v8a candidate-live assertion did not terminate");
      $fatal;
    end

    // The numeric generate specialization used to keep the disabled dependency
    // cone canonical must preserve explicitly-enabled CSR queue-head behavior.
    if (`OOO_CSR_QUEUE_HEAD ||
        $test$plusargs("S2_Q2_V8A_CSR_QH_ENABLED")) begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0a40;
      dispatch0_inst = 32'h0010_1073;  // csrrw x0,fflags,x0
      #1;
      saved0 = dispatch0_rob_idx;
      `TB_TICK(clk);
      clear_inputs();
      wb0_valid = 1'b1;
      wb0_rob_idx = saved0;
      wb0_data = 32'h0a40_0001;
      `TB_TICK(clk);
      clear_inputs();
      mem_quiet = 1'b0;
      #1;
      tb_check1("v8a csr-qh setup has live candidate",
                head0_retire_candidate_valid, 1'b1);
      tb_check1("v8a csr-qh enabled holds commit while memory busy",
                commit0_valid, 1'b0);
      tb_check1("V9O csr-qh memory hold blocks C0 pregrant",
                head0_full_flush_pregrant, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("v8a csr-qh enabled releases on memory quiet",
                commit0_valid, 1'b1);
      tb_check1("V9O csr-qh emits C0 full-flush pregrant",
                head0_full_flush_pregrant, 1'b1);
      tb_check32("V9O csr-qh pregrant reason",
                 {{(32-`REDIR_REASON_W){1'b0}}, head0_full_flush_reason},
                 {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_CSR_COMMIT});
      tb_check1("V9O csr-qh C0 closes lane0 dispatch", dispatch0_ready, 1'b0);
      tb_check1("V9O csr-qh C0 closes lane1 dispatch", dispatch1_ready, 1'b0);
      $display("[S2-Q2-V8A-CSR-QH-PASS] explicit macro-enable behavior preserved");
      `TB_TICK(clk);
      clear_inputs();
      reset_dut();

      // FP CSR / legacy pending-system ownership uses the same CSR opcode in
      // the ROB but must not be reclassified as a queue-head full-flush event.
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0a60;
      dispatch0_inst = 32'h0010_1073;
      #1;
      saved0 = dispatch0_rob_idx;
      saved0_producer = dispatch0_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      wb0_valid = 1'b1;
      wb0_rob_idx = saved0;
      wb0_data = 32'h0a60_0001;
      `TB_TICK(clk);
      clear_inputs();
      // A live pending lease for another ProducerId must not reclassify head0.
      pending_csr_owner_valid = 1'b1;
      pending_csr_owner_producer_id =
          saved0_producer ^ {{(PRODUCER_ID_W-1){1'b0}}, 1'b1};
      #1;
      tb_check1("V9O mismatched pending owner keeps queue-head full pregrant",
                head0_full_flush_pregrant, 1'b1);
      tb_check32("V9O mismatched pending owner keeps CSR_COMMIT reason",
                 {{(32-`REDIR_REASON_W){1'b0}}, head0_full_flush_reason},
                 {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_CSR_COMMIT});

      // Only the exact typed lease/ProducerId identifies the legacy pending
      // CSR commit owner.  It remains an older control event, so dispatch and
      // younger branch production are closed without requesting FULL_NEXT.
      pending_csr_owner_producer_id = saved0_producer;
      #1;
      tb_check1("V9O pending-owner CSR still retires", commit0_valid, 1'b1);
      tb_check1("V9O pending-owner CSR emits control-event pregrant",
                head0_control_event_pregrant, 1'b1);
      tb_check1("V9O pending-owner CSR has no queue-head pregrant",
                head0_full_flush_pregrant, 1'b0);
      tb_check32("V9O pending-owner CSR pregrant reason is NONE",
                 {{(32-`REDIR_REASON_W){1'b0}}, head0_full_flush_reason},
                 {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_NONE});
      tb_check1("V9O pending-owner commit closes lane0 dispatch",
                dispatch0_ready, 1'b0);
      tb_check1("V9O pending-owner commit closes lane1 dispatch",
                dispatch1_ready, 1'b0);
      $display("[V9O-CSR-OWNER-CLASS-PASS] exact pending CSR ProducerId classified without full flush");
      `TB_TICK(clk);
      clear_inputs();
      reset_dut();
    end

    if ($test$plusargs("S2_Q2_V8A_CSR_QH_EXPLICIT_ZERO")) begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0a80;
      dispatch0_inst = 32'h0010_1073;
      #1;
      saved0 = dispatch0_rob_idx;
      `TB_TICK(clk);
      clear_inputs();
      wb0_valid = 1'b1;
      wb0_rob_idx = saved0;
      wb0_data = 32'h0a80_0001;
      `TB_TICK(clk);
      clear_inputs();
      mem_quiet = 1'b0;
      #1;
      tb_check1("v8a csr-qh explicit zero keeps legacy retirement",
                commit0_valid, 1'b1);
      tb_check1("V9O csr-qh explicit zero has no full pregrant",
                head0_full_flush_pregrant, 1'b0);
      $display("[S2-Q2-V8A-CSR-QH-ZERO-PASS] explicit numeric zero remains disabled");
      `TB_TICK(clk);
      clear_inputs();
      reset_dut();
    end

    // v8a public observation and neutral permit behavior.  The candidate must
    // ignore commit_ready, while either permit can independently hold commit0.
    commit_ready = 1'b0;
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0b00;
    dispatch0_inst = 32'h0000_0013;
    #1;
    saved0 = dispatch0_rob_idx;
    `TB_TICK(clk);
    clear_inputs();
    commit_ready = 1'b0;
    #1;
    tb_check1("v8a live head identity valid before done", head0_identity_valid, 1'b1);
    tb_check1("v8a candidate low before registered done", head0_retire_candidate_valid, 1'b0);
    tb_check32("v8a first public identity", {{(32-`OOO_CONTEXT_ID_W){1'b0}}, head0_identity},
               {{(32-ROB_INDEX_W){1'b0}}, saved0});
    wb0_valid = 1'b1;
    wb0_rob_idx = saved0;
    wb0_data = 32'h0b00_0001;
    `TB_TICK(clk);
    clear_inputs();
    commit_ready = 1'b0;
    #1;
    tb_check1("v8a candidate bypasses commit ready", head0_retire_candidate_valid, 1'b1);
    tb_check1("v8a commit still obeys commit ready", commit0_valid, 1'b0);

    commit_ready = 1'b1;
    head0_context_permit = 1'b0;
    #1;
    tb_check1("v8a context permit independently blocks commit0", commit0_valid, 1'b0);
    tb_check1("v8a context block preserves candidate", head0_retire_candidate_valid, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    commit_ready = 1'b1;
    fencei_retire_permit = 1'b0;
    #1;
    tb_check1("v8a fencei permit independently blocks commit0", commit0_valid, 1'b0);
    tb_check1("v8a fencei block preserves candidate", head0_retire_candidate_valid, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    commit_ready = 1'b1;
    #1;
    tb_check1("v8a tie-high permits preserve legacy retirement", commit0_valid, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("v8a candidate falls after retirement", head0_retire_candidate_valid, 1'b0);
    tb_check1("v8a identity invalid after retirement", head0_identity_valid, 1'b0);

    // A two-ready-entry case closes the retirement-prefix invariant: either
    // permit must hold both lanes and preserve the ROB state, never allow the
    // younger lane to bypass the blocked head.
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0b10;
    dispatch0_inst = 32'h0000_0013;
    dispatch1_valid = 1'b1;
    dispatch1_pc = 32'h8000_0b14;
    dispatch1_inst = 32'h0000_0013;
    #1;
    saved0 = dispatch0_rob_idx;
    saved1 = dispatch1_rob_idx;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("v8a ready pair identity valid", head0_identity_valid, 1'b1);
    tb_check32("v8a second public identity", {{(32-`OOO_CONTEXT_ID_W){1'b0}}, head0_identity},
               {{(32-ROB_INDEX_W){1'b0}}, saved0});
    wb0_valid = 1'b1;
    wb0_rob_idx = saved0;
    wb0_data = 32'h0b10_0001;
    wb1_valid = 1'b1;
    wb1_rob_idx = saved1;
    wb1_data = 32'h0b14_0002;
    `TB_TICK(clk);
    clear_inputs();
    head0_context_permit = 1'b0;
    #1;
    tb_check1("v8a context permit blocks ready pair commit0", commit0_valid, 1'b0);
    tb_check1("v8a context permit blocks ready pair commit1", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("v8a context block preserves ready pair", {27'b0, count}, 32'd2);
    fencei_retire_permit = 1'b0;
    #1;
    tb_check1("v8a fencei permit blocks ready pair commit0", commit0_valid, 1'b0);
    tb_check1("v8a fencei permit blocks ready pair commit1", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("v8a fencei block preserves ready pair", {27'b0, count}, 32'd2);
    tb_check1("v8a ready pair retires with both permits", commit0_valid, 1'b1);
    tb_check1("v8a retirement prefix permits lane1", commit1_valid, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("v8a ready pair drained", {27'b0, count}, 32'd0);

    // Cover every raw lane1 classifier with a simultaneously-retiring pair.
    // Queue-head CSR mode intentionally changes the legacy CSR dual-retire
    // contract, so its dedicated build runs the non-CSR FENCE.I case only.
    if (!`OOO_CSR_QUEUE_HEAD) begin
      exercise_v8a_lane1_boundary(32'h0010_1073, 4'b0001,
                                  32'h8000_0b20);
      exercise_v8a_lane1_boundary(32'h1200_0073, 4'b0010,
                                  32'h8000_0b30);
      exercise_v8a_lane1_boundary(32'h3020_0073, 4'b0100,
                                  32'h8000_0b40);
      exercise_v8a_lane1_boundary(32'h0000_100f, 4'b1000,
                                  32'h8000_0b50);
    end else begin
      exercise_v8a_lane1_boundary(32'h0000_100f, 4'b1000,
                                  32'h8000_0b50);
    end
    $display("[S2-Q2-V8A-DYNAMIC-PASS] candidate/identity/permit/retire-prefix/all-lane1-shadow coverage is non-vacuous");
    reset_dut();

    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0000;
    dispatch0_inst = 32'h0000_0093;
    dispatch0_rd_en = 1'b1;
    dispatch0_arch_rd = 5'd1;
    dispatch0_old_pdest = 6'd1;
    dispatch0_new_pdest = 6'd32;
    dispatch1_valid = 1'b1;
    dispatch1_pc = 32'h8000_0004;
    dispatch1_inst = 32'h0010_0113;
    dispatch1_rd_en = 1'b1;
    dispatch1_arch_rd = 5'd2;
    dispatch1_old_pdest = 6'd2;
    dispatch1_new_pdest = 6'd33;
    #1;
    tb_check1("dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("dispatch1 ready", dispatch1_ready, 1'b1);
    tb_check32("dispatch0 index", {28'b0, dispatch0_rob_idx}, 32'd0);
    tb_check32("dispatch1 index", {28'b0, dispatch1_rob_idx}, 32'd1);
    saved0 = dispatch0_rob_idx;
    saved1 = dispatch1_rob_idx;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("count after dispatch", {27'b0, count}, 32'd2);
    tb_check1("head not done yet", commit0_valid, 1'b0);

    // checkpoint capture/restore 场景已删（dead silicon，ROB-walk 取代）；
    // 净效果 = ROB 回到 capture 前(2 条 idx0/idx1，head 未 done)，此处保持该态。
    clear_inputs();

    wb1_valid = 1'b1;
    wb1_rob_idx = saved1;
    wb1_data = 32'h2222_0002;
    wb1_pdest = 6'd33;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("younger done cannot commit", commit0_valid, 1'b0);

    wb0_valid = 1'b1;
    wb0_rob_idx = saved0;
    wb0_data = 32'h1111_0001;
    wb0_pdest = 6'd32;
    #1;
    tb_check1("writeback edge required before commit0", commit0_valid, 1'b0);
    tb_check1("head blocks younger before registered done", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("commit0 valid from registered done", commit0_valid, 1'b1);
    tb_check1("commit1 valid from registered done", commit1_valid, 1'b1);
    tb_check32("commit0 pc from ROB Q", commit0_pc, 32'h8000_0000);
    tb_check32("commit1 pc from ROB Q", commit1_pc, 32'h8000_0004);
    tb_check32("commit0 data from ROB Q", commit0_data, 32'h1111_0001);
    tb_check32("commit1 data from ROB Q", commit1_data, 32'h2222_0002);
    tb_check32("commit0 old pdest from ROB Q", {26'b0, commit0_old_pdest}, 32'd1);
    tb_check32("commit1 new pdest from ROB Q", {26'b0, commit1_new_pdest}, 32'd33);
    $display("[T3W-ROB-Q-RETIRE] dual writeback is absorbed before exact dual retirement");
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("count after dual commit", {27'b0, count}, 32'd0);

    // T4N reviewer: 异常只能由 commit0 精确退休。即使 lane0 是可退休的正常指令，
    // lane1 异常项也必须留在 ROB，下一拍升为 head 后再宣告 trap。
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0080;
    dispatch0_inst = 32'h0020_0193;
    dispatch0_rd_en = 1'b1;
    dispatch0_arch_rd = 5'd3;
    dispatch0_old_pdest = 6'd3;
    dispatch0_new_pdest = 6'd34;
    dispatch1_valid = 1'b1;
    dispatch1_pc = 32'h8000_0084;
    dispatch1_inst = 32'h0000_2203;  // lw x4,0(x0): fault 时 rd_en 仍非真空
    dispatch1_rd_en = 1'b1;
    dispatch1_arch_rd = 5'd4;
    dispatch1_old_pdest = 6'd4;
    dispatch1_new_pdest = 6'd35;
    #1;
    saved0 = dispatch0_rob_idx;
    saved1 = dispatch1_rob_idx;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("head1 exception pair count after dispatch", {27'b0, count}, 32'd2);

    wb0_valid = 1'b1;
    wb0_rob_idx = saved0;
    wb0_data = 32'h4444_0004;
    wb1_valid = 1'b1;
    wb1_rob_idx = saved1;
    wb1_data = 32'hdead_0005;
    wb1_exception = 1'b1;
    wb1_cause = `EXC_LOAD_ACCESS_FAULT;
    wb1_tval = 32'hdead_1000;
    #1;
    tb_check1("head1 exception pair waits for registered WB commit0", commit0_valid, 1'b0);
    tb_check1("head1 exception pair waits for registered WB commit1", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("head1 exception pair commit0 valid", commit0_valid, 1'b1);
    tb_check1("head1 exception structurally blocks commit1", commit1_valid, 1'b0);
    tb_check32("head1 exception pair count before retire edge", {27'b0, count}, 32'd2);
    tb_check32("head1 exception pair commit0 pc", commit0_pc, 32'h8000_0080);
    tb_check32("head1 exception pair commit0 data", commit0_data, 32'h4444_0004);
    tb_check1("head1 exception pair commit0 is normal", commit0_exception, 1'b0);
    tb_check1("head1 exception does not trap before becoming head", commit_exception_trap, 1'b0);
    tb_check1("head1 exception keeps trap invalid in lane1 cycle", trap_mem_valid, 1'b0);
    tb_check1("head1 exception pair normal lane0 writes GPR", arch_commit0_write, 1'b1);
    tb_check1("blocked exceptional lane1 suppresses GPR write",
              arch_commit1_write, 1'b0);
    $display("[T4N-ROB-HEAD1-EXCEPTION-BLOCK] normal head0 retires alone; exceptional head1 stays resident");
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("exception remains after older-only retire", {27'b0, count}, 32'd1);
    tb_check32("head1 exception pair normal lane0 GPR side effect", arch_gprs[3*`XLEN +: `XLEN],
               32'h4444_0004);
    tb_check32("head1 exception pair exceptional lane1 GPR remains zero",
               arch_gprs[4*`XLEN +: `XLEN], 32'd0);
    tb_check1("exception becomes commit0 at new head", commit0_valid, 1'b1);
    tb_check1("new-head exception cannot pair commit1", commit1_valid, 1'b0);
    tb_check32("new-head exception pc", commit0_pc, 32'h8000_0084);
    tb_check1("new-head exception metadata valid", commit0_exception, 1'b1);
    tb_check32("new-head exception cause", {27'b0, commit0_cause},
               {27'b0, `EXC_LOAD_ACCESS_FAULT});
    tb_check32("new-head exception tval", commit0_tval, 32'hdead_1000);
    tb_check1("new-head exception raises precise trap", commit_exception_trap, 1'b1);
    tb_check1("new-head exception trap valid", trap_mem_valid, 1'b1);
    tb_check1("V9O precise exception emits C0 full-flush pregrant",
              head0_full_flush_pregrant, 1'b1);
    tb_check32("V9O precise exception pregrant reason",
               {{(32-`REDIR_REASON_W){1'b0}}, head0_full_flush_reason},
               {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_TRAP});
    tb_check1("V9O precise exception C0 closes lane0 dispatch",
              dispatch0_ready, 1'b0);
    tb_check1("V9O precise exception C0 closes lane1 dispatch",
              dispatch1_ready, 1'b0);
    tb_check32("new-head trap pc", trap_mem_pc, 32'h8000_0084);
    tb_check32("new-head trap cause", {27'b0, trap_mem_cause},
               {27'b0, `EXC_LOAD_ACCESS_FAULT});
    tb_check32("new-head trap tval", trap_mem_tval, 32'hdead_1000);
    tb_check1("exceptional commit0 suppresses GPR write", arch_commit0_write, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("count after precise exception retire", {27'b0, count}, 32'd0);

    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0100;
    dispatch0_inst = 32'h0000_0073;
    dispatch1_valid = 1'b1;
    dispatch1_pc = 32'h8000_0104;
    dispatch1_inst = 32'h0000_0093;
    #1;
    saved0 = dispatch0_rob_idx;
    saved1 = dispatch1_rob_idx;
    `TB_TICK(clk);
    clear_inputs();

    wb0_valid = 1'b1;
    wb0_rob_idx = saved0;
    wb0_exception = 1'b1;
    wb0_cause = `EXC_ILLEGAL_INST;
    wb0_tval = 32'hfeed_beef;
    wb1_valid = 1'b1;
    wb1_rob_idx = saved1;
    wb1_data = 32'h3333_0003;
    #1;
    tb_check1("exception writeback cannot retire combinationally", commit0_valid, 1'b0);
    tb_check1("younger cannot pass unregistered exception", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("registered exception commits at head", commit0_valid, 1'b1);
    tb_check1("registered exception blocks younger", commit1_valid, 1'b0);
    tb_check1("V9O registered exception full pregrant", head0_full_flush_pregrant,
              1'b1);
    tb_check1("commit0 exception from ROB Q", commit0_exception, 1'b1);
    tb_check32("commit0 cause from ROB Q", {27'b0, commit0_cause}, {27'b0, `EXC_ILLEGAL_INST});
    tb_check32("commit0 tval from ROB Q", commit0_tval, 32'hfeed_beef);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("younger commits next", commit0_valid, 1'b1);
    tb_check32("younger pc preserved", commit0_pc, 32'h8000_0104);
    `TB_TICK(clk);
    #1;
    tb_check32("count after exception sequence", {27'b0, count}, 32'd0);

    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0200;
    `TB_TICK(clk);
    clear_inputs();
    flush = 1'b1;
    `TB_TICK(clk);
    flush = 1'b0;
    #1;
    tb_check1("flush empties rob", empty, 1'b1);

    // ============ B2 ROB-walk 误预测恢复 ============
    // dispatch 5 条(idx0..4，arch_rd=i+1/old=10+i/new=40+i)，kill 存活分支 idx1 → squash idx2/3/4。
    reset_dut();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd1;
    dispatch0_old_pdest = 6'd10; dispatch0_new_pdest = 6'd40; dispatch0_pc = 32'h9000_0000;
    dispatch1_valid = 1'b1; dispatch1_rd_en = 1'b1; dispatch1_arch_rd = 5'd2;
    dispatch1_old_pdest = 6'd11; dispatch1_new_pdest = 6'd41; dispatch1_pc = 32'h9000_0004;
    `TB_TICK(clk); clear_inputs();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd3;
    dispatch0_old_pdest = 6'd12; dispatch0_new_pdest = 6'd42; dispatch0_pc = 32'h9000_0008;
    dispatch1_valid = 1'b1; dispatch1_rd_en = 1'b1; dispatch1_arch_rd = 5'd4;
    dispatch1_old_pdest = 6'd13; dispatch1_new_pdest = 6'd43; dispatch1_pc = 32'h9000_000c;
    `TB_TICK(clk); clear_inputs();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd5;
    dispatch0_old_pdest = 6'd14; dispatch0_new_pdest = 6'd44; dispatch0_pc = 32'h9000_0010;
    `TB_TICK(clk); clear_inputs();
    #1;
    tb_check32("walk: count before kill", {27'b0, count}, 32'd5);

    // 启动 kill（存活 idx1）：本拍冻结 dispatch、尚未 emit
    kill_valid = 1'b1; kill_rob_idx = 4'd1;
    #1;
    tb_check1("walk: kill cycle freezes dispatch", dispatch0_ready, 1'b0);
    tb_check1("walk: kill cycle no emit yet", walk0_valid, 1'b0);
    `TB_TICK(clk); kill_valid = 1'b0;
    #1;
    // recover 拍 B：lane0=idx4(arch5/old14/new44)、lane1=idx3(arch4/old13)
    tb_check1("walk B recover active", recover_active, 1'b1);
    tb_check1("walk B lane0 valid", walk0_valid, 1'b1);
    tb_check32("walk B lane0 arch_rd", {27'b0, walk0_arch_rd}, 32'd5);
    tb_check32("walk B lane0 old_pdest", {26'b0, walk0_old_pdest}, 32'd14);
    tb_check32("walk B lane0 new_pdest", {26'b0, walk0_new_pdest}, 32'd44);
    tb_check1("walk B lane1 valid", walk1_valid, 1'b1);
    tb_check32("walk B lane1 arch_rd", {27'b0, walk1_arch_rd}, 32'd4);
    tb_check32("walk B lane1 old_pdest", {26'b0, walk1_old_pdest}, 32'd13);
    `TB_TICK(clk);
    #1;
    // recover 拍 C：lane0=idx2(arch3/old12)、lane1 到分支边界无效、walk_done
    tb_check1("walk C lane0 valid", walk0_valid, 1'b1);
    tb_check32("walk C lane0 arch_rd", {27'b0, walk0_arch_rd}, 32'd3);
    tb_check32("walk C lane0 old_pdest", {26'b0, walk0_old_pdest}, 32'd12);
    tb_check1("walk C lane1 invalid at branch boundary", walk1_valid, 1'b0);
    `TB_TICK(clk);
    #1;
    // 收尾：count=2(idx0/1 存活)、recover 退出、dispatch 解冻
    tb_check1("walk done recover inactive", recover_active, 1'b0);
    tb_check32("walk done count=2", {27'b0, count}, 32'd2);
    tb_check1("walk done dispatch ready", dispatch0_ready, 1'b1);
    tb_check1("walk done not empty", empty, 1'b0);
    // 存活 idx0/1 仍可按序提交、状态完好
    wb0_valid = 1'b1; wb0_rob_idx = 4'd0; wb0_data = 32'h0000_aaaa;
    wb1_valid = 1'b1; wb1_rob_idx = 4'd1; wb1_data = 32'h0000_bbbb;
    #1;
    tb_check1("walk survivors wait for registered WB", commit0_valid, 1'b0);
    `TB_TICK(clk); clear_inputs();
    #1;
    tb_check1("walk surv commit0 valid", commit0_valid, 1'b1);
    tb_check32("walk surv commit0 pc", commit0_pc, 32'h9000_0000);
    tb_check1("walk surv commit1 valid", commit1_valid, 1'b1);
    tb_check32("walk surv commit1 pc", commit1_pc, 32'h9000_0004);
    tb_check32("walk surv commit0 old_pdest", {26'b0, commit0_old_pdest}, 32'd10);
    `TB_TICK(clk); clear_inputs();
    #1;
    tb_check32("walk surv count=0", {27'b0, count}, 32'd0);

    // 偶数 younger：dispatch 5、kill 存活 idx2 → squash idx3/4(2 条)→走 last_two 单拍终止
    reset_dut();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd1;
    dispatch0_old_pdest = 6'd10; dispatch0_new_pdest = 6'd40; dispatch0_pc = 32'ha000_0000;
    dispatch1_valid = 1'b1; dispatch1_rd_en = 1'b1; dispatch1_arch_rd = 5'd2;
    dispatch1_old_pdest = 6'd11; dispatch1_new_pdest = 6'd41; dispatch1_pc = 32'ha000_0004;
    `TB_TICK(clk); clear_inputs();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd3;
    dispatch0_old_pdest = 6'd12; dispatch0_new_pdest = 6'd42; dispatch0_pc = 32'ha000_0008;
    dispatch1_valid = 1'b1; dispatch1_rd_en = 1'b1; dispatch1_arch_rd = 5'd4;
    dispatch1_old_pdest = 6'd13; dispatch1_new_pdest = 6'd43; dispatch1_pc = 32'ha000_000c;
    `TB_TICK(clk); clear_inputs();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd5;
    dispatch0_old_pdest = 6'd14; dispatch0_new_pdest = 6'd44; dispatch0_pc = 32'ha000_0010;
    `TB_TICK(clk); clear_inputs(); #1;
    tb_check32("walk2: count before kill", {27'b0, count}, 32'd5);
    kill_valid = 1'b1; kill_rob_idx = 4'd2;
    `TB_TICK(clk); kill_valid = 1'b0; #1;
    // recover 单拍：lane0=idx4、lane1=idx3，last_two 同拍收尾
    tb_check1("walk2 lane0 valid", walk0_valid, 1'b1);
    tb_check32("walk2 lane0 arch_rd", {27'b0, walk0_arch_rd}, 32'd5);
    tb_check1("walk2 lane1 valid", walk1_valid, 1'b1);
    tb_check32("walk2 lane1 arch_rd", {27'b0, walk1_arch_rd}, 32'd4);
    `TB_TICK(clk); #1;
    tb_check1("walk2 done via last_two: recover inactive", recover_active, 1'b0);
    tb_check32("walk2 done count=3", {27'b0, count}, 32'd3);

    // 边界：kill 时无更年轻者(存活=最新)→不进 recover、不改 ROB 内容；
    // 但 kill 脉冲当拍仍冻结 dispatch 1 拍（recovering_w=recover_q||kill_valid_i），
    // 与 IQ(按 kill_valid squash/gate)+ dispatch backend(dispatch_freeze=kill_valid_q)严格一致，
    // 否则当拍 ROB 仍放新指令进 ROB、而 IQ 把它的发射项 squash → 僵尸 ROB 项永不 done（B2 实测竞争）。
    reset_dut();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd7;
    dispatch0_old_pdest = 6'd20; dispatch0_new_pdest = 6'd50; dispatch0_pc = 32'h9100_0000;
    `TB_TICK(clk); clear_inputs(); #1;
    tb_check32("walk-edge count=1", {27'b0, count}, 32'd1);
    kill_valid = 1'b1; kill_rob_idx = 4'd0;   // idx0 是最新且存活，无更年轻
    #1;
    tb_check1("walk-edge no younger: not recovering", recover_active, 1'b0);
    tb_check1("walk-edge no younger: dispatch frozen this cycle (kill pulse)", dispatch0_ready, 1'b0);
    `TB_TICK(clk); kill_valid = 1'b0; #1;
    tb_check32("walk-edge count unchanged", {27'b0, count}, 32'd1);

    tb_finish("tb_ooo_rob");
  end
endmodule
