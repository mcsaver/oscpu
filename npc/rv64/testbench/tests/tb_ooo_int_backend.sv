`include "define.v"

module tb_ooo_int_backend;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam ROB_COUNT_W = 5;
  localparam FREE_COUNT_W = 7;
  localparam ISSUE_COUNT_W = 4;
  localparam FP_ISSUE_PACKET_W =
      ROB_INDEX_W + `INST_W + (5 * PHY_REG_ADDR_W) + 3;

  reg clk;
  reg rst;
  reg flush;
  reg checkpoint_restore;

  reg dispatch0_valid;
  wire dispatch0_ready;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`XLEN-1:0] dispatch0_pred_npc;
  reg [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx;
  reg dispatch0_pred_taken;
  reg [`INST_W-1:0] dispatch0_inst;
  reg [`CTRL_BUS_W-1:0] dispatch0_ctrl;
  reg [`REG_ADDR_W-1:0] dispatch0_rs1_arch;
  reg [`REG_ADDR_W-1:0] dispatch0_rs2_arch;
  reg [`REG_ADDR_W-1:0] dispatch0_rd_arch;
  reg [`XLEN-1:0] dispatch0_imm;
  reg dispatch0_is_fp;
  reg dispatch0_fp_load;
  reg dispatch0_fp_store;
  reg dispatch0_fp_double;
  reg dispatch0_fp_gpr_write;
  reg dispatch0_fp_gpr_src;
  reg dispatch0_fp_fs1_en;
  reg dispatch0_fp_fs2_en;
  reg dispatch0_fp_fs3_en;

  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`XLEN-1:0] dispatch1_pred_npc;
  reg [`BPU_BHT_INDEX_W-1:0] dispatch1_bht_idx;
  reg dispatch1_pred_taken;
  reg [`INST_W-1:0] dispatch1_inst;
  reg [`CTRL_BUS_W-1:0] dispatch1_ctrl;
  reg [`REG_ADDR_W-1:0] dispatch1_rs1_arch;
  reg [`REG_ADDR_W-1:0] dispatch1_rs2_arch;
  reg [`REG_ADDR_W-1:0] dispatch1_rd_arch;
  reg [`XLEN-1:0] dispatch1_imm;
  reg dispatch1_is_fp;
  reg dispatch1_fp_load;
  reg dispatch1_fp_store;
  reg dispatch1_fp_double;
  reg dispatch1_fp_gpr_write;
  reg dispatch1_fp_gpr_src;
  reg dispatch1_fp_fs1_en;
  reg dispatch1_fp_fs2_en;
  reg dispatch1_fp_fs3_en;

  reg commit_ready;
  wire commit0_valid;
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

  wire [FREE_COUNT_W-1:0] free_count;
  wire [ROB_COUNT_W-1:0] rob_count;
  wire [ISSUE_COUNT_W-1:0] issue_count;
  wire execute0_valid;
  wire execute1_valid;
  wire branch_resolve_valid;
  wire [`XLEN-1:0] branch_resolve_pc;
  wire [`XLEN-1:0] branch_resolve_next_pc;
  wire branch_resolve_misaligned;
  wire [ROB_INDEX_W-1:0] branch_resolve_rob_idx;
  wire branch_resolve_mispredict;
  wire branch_resolve_is_branch;
  wire branch_resolve_taken;
  wire branch_resolve_pred_taken;
  wire [`BPU_BHT_INDEX_W-1:0] branch_resolve_bht_idx;
  wire dispatch_branch_resolve_valid;
  wire [`XLEN-1:0] dispatch_branch_resolve_pc;
  wire [`XLEN-1:0] dispatch_branch_resolve_next_pc;
  wire dispatch_branch_resolve_misaligned;
  wire mem_req_valid;
  wire mem_req_write;
  wire mem_req_probe;
  wire mem_req_pretrans;
  wire mem_req_nokill;
  wire mem_req_attr_valid;
  wire [1:0] mem_req_class;
  wire mem_req_cacheable;
  wire [1:0] mem_req_owner_kind;
  wire [4:0] mem_req_owner_token;
  wire [1:0] mem_req_mmu_epoch;
  wire [`XLEN-1:0] mem_req_fault_tval;
  wire mem_req_device_release;
  wire mem_req_device_cancel;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  reg mem_req_ready;
  wire mem_rsp_ready;
  reg mem_rsp_valid;
  reg [`XLEN-1:0] mem_rsp_rdata;
  reg mem_rsp_error;
  reg mem_rsp_cacheable;
  reg tb_mem_rsp_attr_valid;
  reg [1:0] tb_mem_rsp_class;
  wire mem_expected_valid;
  wire [1:0] mem_expected_owner_kind;
  wire [4:0] mem_expected_owner_token;
  wire [1:0] mem_expected_mmu_epoch;
  wire mem_expected_tval_valid;
  wire [`XLEN-1:0] mem_expected_fault_tval;
  wire mem_expected_effective_killed;
  reg mem_translate_active;
  reg [PHY_REG_ADDR_W-1:0] t3g_load0_pdest;
  reg [PHY_REG_ADDR_W-1:0] t3g_load1_pdest;
  reg [PHY_REG_ADDR_W-1:0] t3g_dependent_pdest;
  // Icarus forbids an automatic task local on the RHS of procedural force.
  // The selective-kill task copies its real branch ROB identity here first.
  reg [ROB_INDEX_W-1:0] t3v_force_branch_rob;

  wire unused_mem_ready = mem_rsp_ready;

  OooIntBackend dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .checkpoint_capture_i(1'b0),
    .checkpoint_restore_i(checkpoint_restore),
    .checkpoint_quiesce_i(1'b0),
    .mem_issue_block_i(1'b0),
    .pending_branch_fast_valid_i(1'b0),
    .pending_branch_fast_pc_i({`XLEN{1'b0}}),
    .recover_gprs_i({(`XLEN * `REG_NUM){1'b0}}),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i(dispatch0_pred_npc),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_ctrl_i(dispatch0_ctrl),
    .dispatch0_rs1_arch_i(dispatch0_rs1_arch),
    .dispatch0_rs2_arch_i(dispatch0_rs2_arch),
    .dispatch0_rd_arch_i(dispatch0_rd_arch),
    .dispatch0_imm_i(dispatch0_imm),
    .dispatch0_bht_idx_i(dispatch0_bht_idx),
    .dispatch0_pred_taken_i(dispatch0_pred_taken),
    .dispatch0_is_fp_i(dispatch0_is_fp),
    .dispatch0_fp_load_i(dispatch0_fp_load),
    .dispatch0_fp_store_i(dispatch0_fp_store),
    .dispatch0_fp_double_i(dispatch0_fp_double),
    .dispatch0_fp_gpr_write_i(dispatch0_fp_gpr_write),
    .dispatch0_fp_gpr_src_i(dispatch0_fp_gpr_src),
    .dispatch0_fp_fs1_en_i(dispatch0_fp_fs1_en),
    .dispatch0_fp_fs2_en_i(dispatch0_fp_fs2_en),
    .dispatch0_fp_fs3_en_i(dispatch0_fp_fs3_en),
    .dispatch1_is_fp_i(dispatch1_is_fp),
    .dispatch1_fp_load_i(dispatch1_fp_load),
    .dispatch1_fp_store_i(dispatch1_fp_store),
    .dispatch1_fp_double_i(dispatch1_fp_double),
    .dispatch1_fp_gpr_write_i(dispatch1_fp_gpr_write),
    .dispatch1_fp_gpr_src_i(dispatch1_fp_gpr_src),
    .dispatch1_fp_fs1_en_i(dispatch1_fp_fs1_en),
    .dispatch1_fp_fs2_en_i(dispatch1_fp_fs2_en),
    .dispatch1_fp_fs3_en_i(dispatch1_fp_fs3_en),
    .frm_i(3'b000),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_optional_i(1'b0),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_pred_npc_i(dispatch1_pred_npc),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_ctrl_i(dispatch1_ctrl),
    .dispatch1_rs1_arch_i(dispatch1_rs1_arch),
    .dispatch1_rs2_arch_i(dispatch1_rs2_arch),
    .dispatch1_rd_arch_i(dispatch1_rd_arch),
    .dispatch1_imm_i(dispatch1_imm),
    .dispatch1_bht_idx_i(dispatch1_bht_idx),
    .dispatch1_pred_taken_i(dispatch1_pred_taken),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(mem_req_ready),
    .mem_req_write_o(mem_req_write),
    .mem_req_probe_o(mem_req_probe),
    .mem_req_pretrans_o(mem_req_pretrans),
    .mem_req_nokill_o(mem_req_nokill),
    .mem_req_attr_valid_o(mem_req_attr_valid),
    .mem_req_class_o(mem_req_class),
    .mem_req_cacheable_o(mem_req_cacheable),
    .mem_req_owner_kind_o(mem_req_owner_kind),
    .mem_req_owner_token_o(mem_req_owner_token),
    .mem_req_mmu_epoch_o(mem_req_mmu_epoch),
    .mem_req_fault_tval_o(mem_req_fault_tval),
    .mem_req_device_release_o(mem_req_device_release),
    .mem_req_device_cancel_o(mem_req_device_cancel),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(mem_rsp_valid),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_rsp_rdata_i(mem_rsp_rdata),
    .mem_rsp_error_i(mem_rsp_error),
    .mem_rsp_page_fault_i(1'b0),
    .mem_rsp_attr_valid_i(tb_mem_rsp_attr_valid),
    .mem_rsp_class_i(tb_mem_rsp_class),
    .mem_rsp_cacheable_i(mem_rsp_cacheable),
    // The leaf TB models an in-order bridge by echoing the registered MIQ-head
    // tuple.  Drop/query/residency behavior is covered by the bridge/full-chain
    // focused benches rather than guessed in this functional backend model.
    .mem_rsp_owner_kind_i(mem_expected_owner_kind),
    .mem_rsp_owner_token_i(mem_expected_owner_token),
    .mem_rsp_mmu_epoch_i(mem_expected_mmu_epoch),
    .mem_rsp_fault_tval_i(mem_expected_fault_tval),
    .mem_expected_valid_o(mem_expected_valid),
    .mem_expected_owner_kind_o(mem_expected_owner_kind),
    .mem_expected_owner_token_o(mem_expected_owner_token),
    .mem_expected_mmu_epoch_o(mem_expected_mmu_epoch),
    .mem_expected_tval_valid_o(mem_expected_tval_valid),
    .mem_expected_fault_tval_o(mem_expected_fault_tval),
    .mem_expected_effective_killed_o(mem_expected_effective_killed),
    .mem_owner_query_valid_i(1'b0),
    .mem_owner_query_token_i(5'b0),
    .mem_tracker_expected_valid_o(),
    .mem_tracker_expected_owner_kind_o(),
    .mem_tracker_expected_owner_token_o(),
    .mem_tracker_expected_mmu_epoch_o(),
    .mem_station_query_valid_i(1'b0),
    .mem_station_query_token_i(5'b0),
    .mem_station_expected_valid_o(),
    .mem_station_expected_owner_kind_o(),
    .mem_station_expected_owner_token_o(),
    .mem_station_expected_mmu_epoch_o(),
    .mem_drop0_valid_i(1'b0),
    .mem_drop0_owner_kind_i(2'b11),
    .mem_drop0_owner_token_i(5'b0),
    .mem_drop0_mmu_epoch_i(2'b0),
    .mem_drop0_fault_tval_i({`XLEN{1'b0}}),
    .mem_drop1_valid_i(1'b0),
    .mem_drop1_owner_kind_i(2'b11),
    .mem_drop1_owner_token_i(5'b0),
    .mem_drop1_mmu_epoch_i(2'b0),
    .mem_drop1_fault_tval_i({`XLEN{1'b0}}),
    .mem_bridge_owner_residency_mask_i(32'b0),
    .mem_translate_active_i(mem_translate_active),
    .commit_ready_i(commit_ready),
    .commit1_block_i(1'b0),
    .commit0_valid_o(commit0_valid),
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
    .free_count_o(free_count),
    .rob_count_o(rob_count),
	    .issue_count_o(issue_count),
	    .execute0_valid_o(execute0_valid),
	    .execute1_valid_o(execute1_valid),
	    .branch_resolve_valid_o(branch_resolve_valid),
	    .branch_resolve_pc_o(branch_resolve_pc),
	    .branch_resolve_next_pc_o(branch_resolve_next_pc),
	    .branch_resolve_misaligned_o(branch_resolve_misaligned),
	    .branch_resolve_rob_idx_o(branch_resolve_rob_idx),
	    .branch_resolve_mispredict_o(branch_resolve_mispredict),
	    .branch_resolve_is_branch_o(branch_resolve_is_branch),
	    .branch_resolve_taken_o(branch_resolve_taken),
	    .branch_resolve_pred_taken_o(branch_resolve_pred_taken),
	    .branch_resolve_bht_idx_o(branch_resolve_bht_idx),
	    .dispatch_branch_resolve_valid_o(dispatch_branch_resolve_valid),
	    .dispatch_branch_resolve_pc_o(dispatch_branch_resolve_pc),
	    .dispatch_branch_resolve_next_pc_o(dispatch_branch_resolve_next_pc),
	    .dispatch_branch_resolve_misaligned_o(dispatch_branch_resolve_misaligned)
	  );

`ifdef S2_G1_RSP_TRACE
  // Optional focused trace.  It is compiled out of the canonical module test
  // and exists only to distinguish a real in-flight response from a stale
  // outer-transport beat before the assert build intentionally terminates.
  always @(posedge clk) begin
    if (!rst && mem_rsp_valid)
      $display("[S2-G1-RSP-TRACE] t=%0t ready=%0b miq_count=%0d head=%0b kind=%0d effective_kill=%0b pop_transport=%0b owner_match=%0b mem_pending=%0b flush=%0b restore=%0b",
               $time, mem_rsp_ready, dut.miq_count_w,
               dut.miq_head_valid_w, dut.miq_head_kind_w,
               dut.miq_head_effective_killed_w,
               dut.miq_pop_transport_w, dut.miq_pop_owner_match_w,
               dut.mem_pending_q, flush, checkpoint_restore);
  end
`endif

  wire unused_next_pc_w = (|commit0_next_pc) | (|commit1_next_pc) |
                          branch_resolve_valid | (|branch_resolve_pc) |
                          (|branch_resolve_next_pc) |
                          branch_resolve_misaligned |
                          dispatch_branch_resolve_valid |
                          (|dispatch_branch_resolve_pc) |
                          (|dispatch_branch_resolve_next_pc) |
                          dispatch_branch_resolve_misaligned;

  function [`CTRL_BUS_W-1:0] make_alu_ctrl;
    input [1:0] op1_sel;
    input [1:0] op2_sel;
    input [3:0] alu_op;
    input rs1_en;
    input rs2_en;
    input rd_en;
    begin
      make_alu_ctrl = {`CTRL_BUS_W{1'b0}};
      make_alu_ctrl[`CTRL_VALID_BIT] = 1'b1;
      make_alu_ctrl[`CTRL_RS1_EN_BIT] = rs1_en;
      make_alu_ctrl[`CTRL_RS2_EN_BIT] = rs2_en;
      make_alu_ctrl[`CTRL_RD_EN_BIT] = rd_en;
      make_alu_ctrl[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = op1_sel;
      make_alu_ctrl[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = op2_sel;
      make_alu_ctrl[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = alu_op;
      make_alu_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      make_alu_ctrl[`CTRL_NEED_WB_BIT] = rd_en;
      make_alu_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = rd_en ? `WB_SEL_ALU : `WB_SEL_NONE;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_store_ctrl;
    input [1:0] mem_size;
    begin
      make_store_ctrl = make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b0);
      make_store_ctrl[`CTRL_STORE_BIT] = 1'b1;
      make_store_ctrl[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = mem_size;
      make_store_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_load_ctrl;
    input [1:0] mem_size;
    input mem_unsigned;
    begin
      make_load_ctrl = make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                     `ALU_OP_ADD, 1'b0, 1'b0, 1'b1);
      make_load_ctrl[`CTRL_LOAD_BIT] = 1'b1;
      make_load_ctrl[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = mem_size;
      make_load_ctrl[`CTRL_MEM_UNSIGNED_BIT] = mem_unsigned;
      make_load_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
      make_load_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_amo_ctrl;
    input [1:0] mem_size;
    input is_lr;
    input is_sc;
    begin
      make_amo_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_ZERO,
                                    `ALU_OP_ADD, 1'b1, !is_lr, 1'b1);
      make_amo_ctrl[`CTRL_LOAD_BIT] = !is_sc;
      make_amo_ctrl[`CTRL_STORE_BIT] = !is_lr;
      make_amo_ctrl[`CTRL_AMO_BIT] = 1'b1;
      make_amo_ctrl[`CTRL_AMO_LR_BIT] = is_lr;
      make_amo_ctrl[`CTRL_AMO_SC_BIT] = is_sc;
      make_amo_ctrl[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = mem_size;
      make_amo_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
      make_amo_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_bitmanip_ctrl;
    begin
      make_bitmanip_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2,
                                         `ALU_OP_ADD, 1'b1, 1'b0, 1'b1);
      make_bitmanip_ctrl[`CTRL_BITMANIP_BIT] = 1'b1;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_bitmanip_op_ctrl;
    begin
      make_bitmanip_op_ctrl = make_bitmanip_ctrl();
      make_bitmanip_op_ctrl[`CTRL_RS2_EN_BIT] = 1'b1;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_muldiv_ctrl;
    begin
      make_muldiv_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2,
                                      `ALU_OP_ADD, 1'b1, 1'b1, 1'b1);
      make_muldiv_ctrl[`CTRL_MULDIV_BIT] = 1'b1;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_fp_arith_ctrl;
    begin
      make_fp_arith_ctrl = {`CTRL_BUS_W{1'b0}};
      make_fp_arith_ctrl[`CTRL_VALID_BIT] = 1'b1;
      make_fp_arith_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
    end
  endfunction

  function [`INST_W-1:0] inst_op_imm;
    input [6:0] funct7;
    input [4:0] imm5;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_op_imm = {funct7, imm5, rs1, funct3, rd, `OPCODE_OP_IMM};
    end
  endfunction

  function [`INST_W-1:0] inst_op;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_op = {funct7, rs2, rs1, funct3, rd, `OPCODE_OP};
    end
  endfunction

  function [`INST_W-1:0] inst_op_fp;
    input [6:0] funct7;
    input [4:0] fs2;
    input [4:0] fs1;
    input [2:0] rm;
    input [4:0] frd;
    begin
      inst_op_fp = {funct7, fs2, fs1, rm, frd, `OPCODE_OP_FP};
    end
  endfunction

  function [`INST_W-1:0] inst_amo;
    input [4:0] funct5;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_amo = {funct5, 2'b00, rs2, rs1, funct3, rd, `OPCODE_AMO};
    end
  endfunction

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic tb_check_fp_issue_packet;
    input [1023:0] what;
    input [FP_ISSUE_PACKET_W-1:0] got;
    input [FP_ISSUE_PACKET_W-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%0h expected=0x%0h",
                 what, got, exp);
      end
    end
  endtask

  function [`XLEN-1:0] ref_clmul;
    input [1:0] op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    integer i;
    begin
      ref_clmul = {`XLEN{1'b0}};
      if (op == 2'd0) begin
        for (i = 0; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 << i);
        end
      end else if (op == 2'd1) begin
        for (i = 0; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 >> (63 - i));
        end
      end else begin
        for (i = 1; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 >> (64 - i));
        end
      end
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_branch_ctrl;
    input [2:0] cmp_op;
    begin
      make_branch_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2,
                                       `ALU_OP_ADD, 1'b1, 1'b1, 1'b0);
      make_branch_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
      make_branch_ctrl[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = cmp_op;
    end
  endfunction

  task automatic clear_dispatch;
    begin
      flush = 1'b0;
      checkpoint_restore = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_pred_npc = {`XLEN{1'b0}};
      dispatch0_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
      dispatch0_pred_taken = 1'b0;
      dispatch0_inst = 32'h0;
      dispatch0_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch0_rs1_arch = 5'd0;
      dispatch0_rs2_arch = 5'd0;
      dispatch0_rd_arch = 5'd0;
      dispatch0_imm = 32'h0;
      dispatch0_is_fp = 1'b0;
      dispatch0_fp_load = 1'b0;
      dispatch0_fp_store = 1'b0;
      dispatch0_fp_double = 1'b0;
      dispatch0_fp_gpr_write = 1'b0;
      dispatch0_fp_gpr_src = 1'b0;
      dispatch0_fp_fs1_en = 1'b0;
      dispatch0_fp_fs2_en = 1'b0;
      dispatch0_fp_fs3_en = 1'b0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_pred_npc = {`XLEN{1'b0}};
      dispatch1_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
      dispatch1_pred_taken = 1'b0;
      dispatch1_inst = 32'h0;
      dispatch1_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch1_rs1_arch = 5'd0;
      dispatch1_rs2_arch = 5'd0;
      dispatch1_rd_arch = 5'd0;
      dispatch1_imm = 32'h0;
      dispatch1_is_fp = 1'b0;
      dispatch1_fp_load = 1'b0;
      dispatch1_fp_store = 1'b0;
      dispatch1_fp_double = 1'b0;
      dispatch1_fp_gpr_write = 1'b0;
      dispatch1_fp_gpr_src = 1'b0;
      dispatch1_fp_fs1_en = 1'b0;
      dispatch1_fp_fs2_en = 1'b0;
      dispatch1_fp_fs3_en = 1'b0;
    end
  endtask

  task automatic reset_dut;
    begin
	      clk = 1'b0;
	      rst = 1'b1;
	      commit_ready = 1'b1;
	      mem_req_ready = 1'b1;
	      mem_rsp_valid = 1'b0;
	      mem_rsp_rdata = {`XLEN{1'b0}};
	      mem_rsp_error = 1'b0;
	      mem_rsp_cacheable = 1'b1;
	      tb_mem_rsp_attr_valid = 1'b1;
	      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
	      mem_translate_active = 1'b0;
	      clear_dispatch();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic set_dispatch0;
    input [`XLEN-1:0] pc;
    input [`CTRL_BUS_W-1:0] ctrl;
    input [`REG_ADDR_W-1:0] rs1;
    input [`REG_ADDR_W-1:0] rs2;
    input [`REG_ADDR_W-1:0] rd;
    input [`XLEN-1:0] imm;
    begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = pc;
      dispatch0_inst = ctrl[`CTRL_STORE_BIT] ? 32'h0000_3023 : pc;
      dispatch0_ctrl = ctrl;
      dispatch0_rs1_arch = rs1;
      dispatch0_rs2_arch = rs2;
      dispatch0_rd_arch = rd;
      dispatch0_imm = imm;
    end
  endtask

  task automatic set_dispatch1;
    input [`XLEN-1:0] pc;
    input [`CTRL_BUS_W-1:0] ctrl;
    input [`REG_ADDR_W-1:0] rs1;
    input [`REG_ADDR_W-1:0] rs2;
    input [`REG_ADDR_W-1:0] rd;
    input [`XLEN-1:0] imm;
    begin
      dispatch1_valid = 1'b1;
      dispatch1_pc = pc;
      dispatch1_inst = ctrl[`CTRL_STORE_BIT] ? 32'h0000_3023 : pc;
      dispatch1_ctrl = ctrl;
      dispatch1_rs1_arch = rs1;
      dispatch1_rs2_arch = rs2;
      dispatch1_rd_arch = rd;
      dispatch1_imm = imm;
    end
  endtask

  task automatic set_fp_binary0;
    input [`XLEN-1:0] pc;
    input [6:0] funct7;
    input [4:0] fs2;
    input [4:0] fs1;
    input [4:0] frd;
    input fp_double;
    begin
      set_dispatch0(pc, make_fp_arith_ctrl(), 5'd0, 5'd0, frd, 64'd0);
      dispatch0_inst = inst_op_fp(funct7, fs2, fs1, 3'b000, frd);
      dispatch0_is_fp = 1'b1;
      dispatch0_fp_load = 1'b0;
      dispatch0_fp_store = 1'b0;
      dispatch0_fp_double = fp_double;
      dispatch0_fp_gpr_write = 1'b0;
      dispatch0_fp_gpr_src = 1'b0;
      dispatch0_fp_fs1_en = 1'b1;
      dispatch0_fp_fs2_en = 1'b1;
      dispatch0_fp_fs3_en = 1'b0;
    end
  endtask

  task automatic set_fp_binary1;
    input [`XLEN-1:0] pc;
    input [6:0] funct7;
    input [4:0] fs2;
    input [4:0] fs1;
    input [4:0] frd;
    input fp_double;
    begin
      set_dispatch1(pc, make_fp_arith_ctrl(), 5'd0, 5'd0, frd, 64'd0);
      dispatch1_inst = inst_op_fp(funct7, fs2, fs1, 3'b000, frd);
      dispatch1_is_fp = 1'b1;
      dispatch1_fp_load = 1'b0;
      dispatch1_fp_store = 1'b0;
      dispatch1_fp_double = fp_double;
      dispatch1_fp_gpr_write = 1'b0;
      dispatch1_fp_gpr_src = 1'b0;
      dispatch1_fp_fs1_en = 1'b1;
      dispatch1_fp_fs2_en = 1'b1;
      dispatch1_fp_fs3_en = 1'b0;
    end
  endtask

  task automatic check_mem0_request;
    input [1023:0] label;
    input exp_write;
    input [`XLEN-1:0] exp_addr;
    input check_wdata;
    input [`XLEN-1:0] exp_wdata;
    input check_wstrb;
    input [`STRB_W-1:0] exp_wstrb;
    begin
      tb_check1({label, " request visible"}, mem_req_valid, 1'b1);
      tb_check1({label, " request write"}, mem_req_write, exp_write);
      tb_check64({label, " request addr"}, mem_req_addr, exp_addr);
      if (!mem_req_pretrans) begin
        tb_check1({label, " ordinary request has no typed attr"},
                  mem_req_attr_valid, 1'b0);
        tb_check32({label, " ordinary request class is RSVD poison"},
                   {30'b0, mem_req_class},
                   {30'b0, `OOO_MEM_CLASS_RSVD});
      end
      if (check_wdata) begin
        tb_check64({label, " request wdata"}, mem_req_wdata, exp_wdata);
      end
      if (check_wstrb) begin
        tb_check32({label, " request wstrb"},
                   {{(32-`STRB_W){1'b0}}, mem_req_wstrb},
                   {{(32-`STRB_W){1'b0}}, exp_wstrb});
      end
    end
  endtask

  task automatic wait_mem0_request;
    input [1023:0] label;
    input exp_write;
    input [`XLEN-1:0] exp_addr;
    input check_wdata;
    input [`XLEN-1:0] exp_wdata;
    input check_wstrb;
    input [`STRB_W-1:0] exp_wstrb;
    integer wait_cycles;
    begin
      #1;
      wait_cycles = 0;
      while (!mem_req_valid && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      check_mem0_request(label, exp_write, exp_addr, check_wdata,
                         exp_wdata, check_wstrb, exp_wstrb);
    end
  endtask

  task automatic complete_mem0_response;
    input [1023:0] label;
    input [`XLEN-1:0] rsp_data;
    input exp_commit;
    input exp_rd_en;
    input check_data;
    input [`XLEN-1:0] exp_data;
    integer wait_cycles;
    begin
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = rsp_data;
      mem_rsp_error = 1'b0;
      #1;
      wait_cycles = 0;
      while (!mem_rsp_ready && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " rsp ready"}, mem_rsp_ready, 1'b1);
      // T3W：response/formal-WB 拍只把完成态写入 ROB；architectural
      // commit 必须等下一拍从 ROB Q 发出，不能重新引入 WB-to-head bypass。
      tb_check1({label, " no commit on response/formal-WB"},
                commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;
      tb_check1({label, " commit valid from ROB Q"},
                commit0_valid, exp_commit);
      if (exp_commit) begin
        tb_check1({label, " commit rd en from ROB Q"},
                  commit0_rd_en, exp_rd_en);
        if (check_data)
          tb_check64({label, " commit data from ROB Q"},
                     commit0_data, exp_data);
        `TB_TICK(clk);
        #1;
        tb_check1({label, " commit exactly once"}, commit0_valid, 1'b0);
      end
    end
  endtask

  // T4N helper.  Caller has already accepted the speculative probe request.
  // Probe success only fills SQ; the later pretranslated write and its B
  // response are the physical request and precise ROB terminal respectively.
  task automatic complete_sq_store_after_probe;
    input [1023:0] label;
    input [`XLEN-1:0] store_va;
    input [`XLEN-1:0] store_pa;
    input probe_cacheable;
    input b_error;
    integer wait_cycles;
    begin
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = store_pa;
      mem_rsp_error = 1'b0;
      mem_rsp_cacheable = probe_cacheable;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = probe_cacheable ? `OOO_MEM_CLASS_CACHED :
                                           `OOO_MEM_CLASS_NC;
      #1;
      tb_check1({label, " probe response ready"}, mem_rsp_ready, 1'b1);
      tb_check1({label, " probe success has no formal WB"},
                dut.mem_wb_fire_w, 1'b0);
      tb_check1({label, " probe success has no commit"}, commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      wait_cycles = 0;
      while (!mem_req_valid && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      check_mem0_request({label, " physical"}, 1'b1, store_pa,
                         1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1({label, " physical request not probe"}, mem_req_probe, 1'b0);
      tb_check1({label, " physical request pretranslated"},
                mem_req_pretrans, 1'b1);
      tb_check1({label, " physical request nokill"}, mem_req_nokill, 1'b1);
      tb_check1({label, " physical request preserves post-translate class"},
                mem_req_cacheable, probe_cacheable);
      tb_check1({label, " physical request typed attr valid"},
                mem_req_attr_valid, 1'b1);
      tb_check32({label, " physical request exact typed class"},
                 {30'b0, mem_req_class},
                 probe_cacheable ? {30'b0, `OOO_MEM_CLASS_CACHED} :
                                   {30'b0, `OOO_MEM_CLASS_NC});
      `TB_TICK(clk);
      #1;
      tb_check1({label, " physical request fires once"}, mem_req_valid, 1'b0);
      tb_check1({label, " no commit before B"}, commit0_valid, 1'b0);

      mem_rsp_valid = 1'b1;
      mem_rsp_error = b_error;
      #1;
      wait_cycles = 0;
      while (!mem_rsp_ready && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " B response ready"}, mem_rsp_ready, 1'b1);
      tb_check1({label, " B response retains typed attr"},
                tb_mem_rsp_attr_valid, 1'b1);
      tb_check32({label, " B response retains exact class"},
                 {30'b0, tb_mem_rsp_class},
                 probe_cacheable ? {30'b0, `OOO_MEM_CLASS_CACHED} :
                                   {30'b0, `OOO_MEM_CLASS_NC});
      tb_check1({label, " B response owns formal WB"},
                dut.miq_drain_wb_fire_w, 1'b1);
      tb_check1({label, " B formal exception"},
                dut.wb0_exception_w, b_error);
      if (b_error) begin
        tb_check32({label, " B error cause7"},
                   {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                   {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
        tb_check64({label, " B error tval original VA"},
                   dut.wb0_tval_w, store_va);
      end
      tb_check1({label, " no commit on B/formal-WB"}, commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      mem_rsp_cacheable = 1'b1;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      #1;
      tb_check1({label, " commit after B"}, commit0_valid, 1'b1);
      tb_check1({label, " commit exception"}, commit0_exception, b_error);
      if (b_error) begin
        tb_check32({label, " commit cause7"},
                   {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                   {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
        tb_check64({label, " commit tval original VA"},
                   commit0_tval, store_va);
      end
      `TB_TICK(clk);
      #1;
      tb_check1({label, " commit exactly once"}, commit0_valid, 1'b0);
    end
  endtask

  // 【P5 刀 B】IQ dispatch→issue 同拍 bypass 已删除:dispatch 拍只入队(issue_count=2),
  // 次拍从寄存项双发,再次拍 EX/formal-WB；T3W 再下一拍从 ROB Q commit。
  task automatic tick_dispatch_to_commit;
    input [1023:0] label;
    input [`XLEN-1:0] exp0;
    input [`XLEN-1:0] exp1;
    begin
      #1;
      tb_check1({label, " dispatch0 ready"}, dispatch0_ready, 1'b1);
      tb_check1({label, " dispatch1 ready"}, dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32({label, " rob has two entries"}, {27'b0, rob_count}, 32'd2);
      tb_check32({label, " ready uops queued in iq"}, {28'b0, issue_count}, 32'd2);
      tb_check1({label, " no same-cycle execute"}, execute0_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32({label, " queued pair issues"}, {28'b0, issue_count}, 32'd0);
      tb_check1({label, " execute0 captures"}, execute0_valid, 1'b1);
      tb_check1({label, " execute1 captures"}, execute1_valid, 1'b1);
      tb_check1({label, " no commit0 on formal WB"}, commit0_valid, 1'b0);
      tb_check1({label, " no commit1 on formal WB"}, commit1_valid, 1'b0);
      tb_check1({label, " formal WB0 valid"}, dut.wb0_valid_w, 1'b1);
      tb_check1({label, " formal WB1 valid"}, dut.wb1_valid_w, 1'b1);
      tb_check64({label, " formal WB0 data"}, dut.wb0_data_w, exp0);
      tb_check64({label, " formal WB1 data"}, dut.wb1_data_w, exp1);

      `TB_TICK(clk);
      #1;
      tb_check1({label, " commit0 valid from ROB Q"}, commit0_valid, 1'b1);
      tb_check1({label, " commit1 valid from ROB Q"}, commit1_valid, 1'b1);
      tb_check64({label, " commit0 data from ROB Q"}, commit0_data, exp0);
      tb_check64({label, " commit1 data from ROB Q"}, commit1_data, exp1);
      tb_check32({label, " ROB holds pair through Q commit window"},
                 {27'b0, rob_count}, 32'd2);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " rob drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " iq drains"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " freelist recovers"}, {25'b0, free_count}, 32'd32);
    end
  endtask

  // T3P：两个复杂 fixed-compute uop（当前用于 Zb）不得占 lane1；它们保持
  // ROB/IQ 身份并依次晋升 lane0。与上面的 simple-ALU 双发 helper 分开，避免
  // 测试把旧 lane1 类别所有权误当成功能合同。
  task automatic tick_lane0_serial_pair_to_commit;
    input [1023:0] label;
    input [`XLEN-1:0] exp0;
    input [`XLEN-1:0] exp1;
    begin
      #1;
      tb_check1({label, " dispatch0 ready"}, dispatch0_ready, 1'b1);
      tb_check1({label, " dispatch1 ready"}, dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32({label, " pair resident"}, {28'b0, issue_count}, 32'd2);
      tb_check1({label, " older complex owns lane0"},
                dut.issue0_valid_w, 1'b1);
      tb_check1({label, " complex excluded from lane1"},
                dut.issue1_valid_w, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " younger complex remains"},
                 {28'b0, issue_count}, 32'd1);
      tb_check1({label, " first formal WB valid"}, dut.wb0_valid_w, 1'b1);
      tb_check64({label, " first formal WB data"}, dut.wb0_data_w, exp0);
      tb_check1({label, " no first commit on formal WB"},
                commit0_valid, 1'b0);
      tb_check1({label, " younger promoted to lane0"},
                dut.issue0_valid_w, 1'b1);
      tb_check1({label, " promoted complex still not lane1"},
                dut.issue1_valid_w, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " IQ drains after promotion"},
                 {28'b0, issue_count}, 32'd0);
      tb_check1({label, " second formal WB valid"}, dut.wb0_valid_w, 1'b1);
      tb_check64({label, " second formal WB data"}, dut.wb0_data_w, exp1);
      tb_check1({label, " first commit valid from ROB Q"},
                commit0_valid, 1'b1);
      tb_check64({label, " first commit data from ROB Q"},
                 commit0_data, exp0);
      tb_check1({label, " younger cannot retire beside older before Q"},
                commit1_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1({label, " second commit valid from ROB Q"},
                commit0_valid, 1'b1);
      tb_check64({label, " second commit data from ROB Q"},
                 commit0_data, exp1);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " ROB drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " IQ remains empty"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " freelist recovers"},
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic wait_commit0_data64;
    input [1023:0] label;
    input [`XLEN-1:0] exp_data;
    input integer max_cycles;
    integer wait_cycles;
    reg formal_wb_seen;
    begin
      wait_cycles = 0;
      formal_wb_seen = 1'b0;
      while (!commit0_valid && (wait_cycles < max_cycles)) begin
        if (dut.wb0_valid_w) begin
          formal_wb_seen = 1'b1;
          tb_check1({label, " no commit on formal WB"},
                    commit0_valid, 1'b0);
          tb_check64({label, " formal WB data"}, dut.wb0_data_w, exp_data);
        end
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " formal WB observed before Q commit"},
                formal_wb_seen, 1'b1);
      tb_check1({label, " commit0 valid"}, commit0_valid, 1'b1);
      tb_check1({label, " commit0 rd en"}, commit0_rd_en, 1'b1);
      if (commit0_valid) begin
        tb_check64({label, " commit0 data"}, commit0_data, exp_data);
      end
      `TB_TICK(clk);
      #1;
      tb_check1({label, " commit exactly once"}, commit0_valid, 1'b0);
      tb_check32({label, " rob drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " iq drains"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " freelist recovers"}, {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic run_clmul_backend_case;
    input [1023:0] label;
    input [`XLEN-1:0] pc;
    input [2:0] funct3;
    input [4:0] rd;
    input [1:0] op;
    begin
      set_dispatch0(pc, make_bitmanip_op_ctrl(), 5'd22, 5'd23, rd, 64'd0);
      dispatch0_inst = inst_op(7'h05, 5'd23, 5'd22, funct3, rd);
      #1;
      tb_check1({label, " dispatch ready"}, dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1({label, " does not use ex0 one-cycle path"},
                execute0_valid, 1'b0);
      tb_check1({label, " waits for long-op response"}, commit0_valid, 1'b0);
      tb_check32({label, " rob holds long op"}, {27'b0, rob_count}, 32'd1);
      wait_commit0_data64(label,
                          ref_clmul(op, 64'h1234_5678_9abc_def0,
                                    64'hfedc_ba98_7654_3210),
                          90);
    end
  endtask

  // lane1 访存的 IQ pop 与主请求端口必须由同一个 owner/fire 判据驱动。
  // 前一组 RED 锁住 lane0 异常释放端口的真分叉；后一组 guard 固化 WB 等待窗不可达证明。
  task automatic run_lane1_mem_exception_owner_red;
    reg owner_violation;
    reg [ROB_INDEX_W-1:0] lane1_rob;
    begin
      reset_dut();

      set_dispatch0(32'h8000_4ff0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'h0000_0301);
      set_dispatch1(32'h8000_4ff4,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd1);
      tick_dispatch_to_commit("lane1 owner A base setup", 64'h301, 64'd1);

      set_dispatch0(32'h8000_5000,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd1, 5'd0, 5'd27, 64'd0);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd1,
                                `FUNCT3_LD, 5'd27);
      set_dispatch1(32'h8000_5004,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd28, 64'h8000_0280);
      #1;
      tb_check1("lane1 owner A dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("lane1 owner A dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("lane1 owner A reaches lane0 mem exception",
                dut.issue0_valid_w && dut.issue0_is_mem_w &&
                dut.issue0_mem_exception_w, 1'b1);
      tb_check1("lane1 owner A reaches normal lane1 mem offer",
                dut.issue1_valid_w && dut.issue1_is_mem_w &&
                !dut.issue1_mem_exception_w && !dut.issue1_sq_fwd_w, 1'b1);
      lane1_rob = dut.issue1_rob_idx_w;
      $display("[RED-OBS] lane1-owner-A issue1_fire=%0b req_valid=%0b req_fire=%0b mem_req_valid=%0b",
               dut.issue1_fire_w, dut.issue1_mem_req_valid_w,
               dut.issue1_mem_request_fire_w, mem_req_valid);
      owner_violation =
          dut.issue1_fire_w && dut.issue1_is_mem_w &&
          !dut.issue1_mem_exception_w && !dut.issue1_sq_fwd_w &&
          !(dut.issue1_mem_request_fire_w &&
            dut.issue1_mem_req_valid_w && mem_req_valid);
      tb_check1("lane1 owner A pop implies matching request fire",
                !owner_violation, 1'b1);
      tb_check1("lane1 owner A request is read", mem_req_write, 1'b0);
      tb_check64("lane1 owner A request address", mem_req_addr,
                 64'h8000_0280);
      tb_check1("lane1 owner A request mux fire",
                dut.mem_req_fire_any_w, 1'b1);
      tb_check1("lane1 owner A selects issue1 owner",
                dut.push_issue1_w, 1'b1);
      tb_check1("lane1 owner A pushes miq", dut.miq_push_valid_w, 1'b1);
      tb_check32("lane1 owner A miq kind is load",
                 {30'b0, dut.miq_push_kind_w}, 32'd0);
      tb_check32("lane1 owner A miq rob matches issue1",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_push_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, lane1_rob});
      `TB_TICK(clk);
      #1;
      $display("[RED-OBS] lane1-owner-A post-edge issue_count=%0d rob_count=%0d miq_count=%0d commit0=%0b commit1=%0b",
               issue_count, rob_count, dut.miq_count_w,
               commit0_valid, commit1_valid);
      tb_check1("lane1 owner A miq head valid", dut.miq_head_valid_w, 1'b1);
      tb_check32("lane1 owner A miq head kind is load",
                 {30'b0, dut.miq_head_kind_w}, 32'd0);
      tb_check32("lane1 owner A miq head rob preserved",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_head_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, lane1_rob});
      if (owner_violation) begin
        tb_check32("lane1 owner A violated pair popped from iq",
                   {28'b0, issue_count}, 32'd0);
        tb_check32("lane1 owner A violated lane1 remains unfinished in rob",
                   {27'b0, rob_count}, 32'd2);
        tb_check1("lane1 owner A violated lane1 cannot commit",
                  commit1_valid, 1'b0);
      end
    end
  endtask

  // 审查反例：lane0 虽为本地异常、不占 bridge port，但它若被更老未完成 uop
  // 挡住，lane1 也不能先产生 request。否则 req mux/MIQ 会在 IQ 未 pop 时接收
  // 一个没有 issue owner 的幽灵事务。
  task automatic run_lane1_head_blocked_exception_owner_guard;
    begin
      reset_dut();

      set_dispatch0(32'h8000_5050,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'h0000_0301);
      set_dispatch1(32'h8000_5054,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd1);
      tick_dispatch_to_commit("lane1 owner blocked setup", 64'h301, 64'd1);

      // 先让一个更老 CLMUL 离开 IQ、留在长操作单元中，使后续 LR 尚非 ROB head。
      set_dispatch0(32'h8000_5060, make_bitmanip_op_ctrl(),
                    5'd0, 5'd0, 5'd3, 64'd0);
      dispatch0_inst = inst_op(7'h05, 5'd0, 5'd0, 3'b001, 5'd3);
      #1;
      tb_check1("lane1 owner blocked clmul dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      `TB_TICK(clk);
      #1;
      tb_check32("lane1 owner blocked clmul leaves iq",
                 {28'b0, issue_count}, 32'd0);
      tb_check32("lane1 owner blocked clmul holds rob",
                 {27'b0, rob_count}, 32'd1);
      tb_check1("lane1 owner blocked clmul not complete",
                commit0_valid, 1'b0);

      set_dispatch0(32'h8000_5070,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd1, 5'd0, 5'd27, 64'd0);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd1,
                                `FUNCT3_LD, 5'd27);
      set_dispatch1(32'h8000_5074,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd28, 64'h8000_0280);
      #1;
      tb_check1("lane1 owner blocked dispatch0 ready", dispatch0_ready,
                1'b1);
      tb_check1("lane1 owner blocked dispatch1 ready", dispatch1_ready,
                1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("lane1 owner blocked reaches lane0 mem exception",
                dut.issue0_valid_w && dut.issue0_is_mem_w &&
                dut.issue0_mem_exception_w, 1'b1);
      tb_check1("lane1 owner blocked lane0 cannot fire before rob head",
                dut.issue0_mem_can_fire_w, 1'b0);
      tb_check1("lane1 owner blocked port owner is unavailable",
                dut.issue1_mem_port_available_w, 1'b0);
      tb_check1("lane1 owner blocked reaches normal lane1 mem offer",
                dut.issue1_valid_w && dut.issue1_is_mem_w &&
                !dut.issue1_mem_exception_w && !dut.issue1_sq_fwd_w, 1'b1);
      $display("[RED-OBS] lane1-owner-blocked issue0_can=%0b issue1_ready=%0b issue1_fire=%0b req_valid=%0b req_fire=%0b mem_req_valid=%0b",
               dut.issue0_mem_can_fire_w, dut.issue1_ready_w,
               dut.issue1_fire_w, dut.issue1_mem_req_valid_w,
               dut.issue1_mem_request_fire_w, mem_req_valid);
      tb_check1("lane1 owner blocked holds lane1 in iq",
                dut.issue1_fire_w, 1'b0);
      tb_check1("lane1 owner blocked forbids ownerless req valid",
                dut.issue1_mem_req_valid_w, 1'b0);
      tb_check1("lane1 owner blocked forbids ownerless bridge request",
                mem_req_valid, 1'b0);
      tb_check1("lane1 owner blocked forbids request mux fire",
                dut.mem_req_fire_any_w, 1'b0);
      tb_check1("lane1 owner blocked forbids miq push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("lane1 owner blocked keeps memory pair in iq",
                 {28'b0, issue_count}, 32'd2);
      tb_check32("lane1 owner blocked keeps miq empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check32("lane1 owner blocked keeps three rob entries",
                 {27'b0, rob_count}, 32'd3);
      tb_check1("lane1 owner blocked keeps miq head invalid",
                dut.miq_head_valid_w, 1'b0);
    end
  endtask

  task automatic run_lane1_mem_wb_wait_owner_guard;
    begin
      reset_dut();

      // 先建立一个未返回的 MMIO load(LEGACY)，再让两条 ALU 占满 EX->WB 两口；同拍把
      // 下一组 ALU+load 填入 IQ，从合法接口抵达 rsp-wait 与 lane1 offer 重叠窗。
      set_dispatch0(32'h8000_5100,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd12, 64'h0000_0200);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("lane1 owner B seed legacy request", mem_req_valid, 1'b1);
      `TB_TICK(clk);
      #1;

      set_dispatch0(32'h8000_5110,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd13, 64'd21);
      set_dispatch1(32'h8000_5114,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd14, 64'd22);
      #1;
      tb_check1("lane1 owner B wb-fill dispatch0 ready", dispatch0_ready,
                1'b1);
      tb_check1("lane1 owner B wb-fill dispatch1 ready", dispatch1_ready,
                1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      set_dispatch0(32'h8000_5120,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd15, 64'd23);
      set_dispatch1(32'h8000_5124,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd16, 64'h8000_0280);
      #1;
      tb_check1("lane1 owner B overlap dispatch0 ready", dispatch0_ready,
                1'b1);
      tb_check1("lane1 owner B overlap dispatch1 ready", dispatch1_ready,
                1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;

      tb_check1("lane1 owner B reaches rsp waiting for wb",
                dut.mem_rsp_waiting_for_wb_w, 1'b1);
      tb_check1("lane1 owner B reaches normal lane1 mem offer",
                dut.issue1_valid_w && dut.issue1_is_mem_w &&
                !dut.issue1_mem_exception_w && !dut.issue1_sq_fwd_w, 1'b1);
      $display("[RED-OBS] lane1-owner-B rsp_wait=%0b issue1_ready=%0b issue1_fire=%0b req_valid=%0b req_fire=%0b mem_req_valid=%0b",
               dut.mem_rsp_waiting_for_wb_w, dut.issue1_ready_w,
               dut.issue1_fire_w, dut.issue1_mem_req_valid_w,
               dut.issue1_mem_request_fire_w, mem_req_valid);
      // 静态蕴含链：rsp_wait -> !mem_legacy_slot_open -> !mem_request_slot_open
      // -> !issue1_mem_req_valid。因此该怀疑窗合法接口下不可达，保留动态 guard 防回归。
      tb_check1("lane1 owner B legacy slot closes while rsp waits",
                dut.mem_legacy_slot_open_w, 1'b0);
      tb_check1("lane1 owner B request slot closes while rsp waits",
                dut.mem_request_slot_open_w, 1'b0);
      tb_check1("lane1 owner B cannot request without matching IQ pop",
                dut.issue1_mem_req_valid_w, 1'b0);
    end
  endtask

  // R3.2 integration proof: two independent fixed-latency producers fire
  // together, then two consumers dispatched on that fire edge select on the
  // very next cycle and read the two distinct registered EX payloads.
  task automatic run_r3p2_dual_producer_consumer;
    begin
      reset_dut();

      set_dispatch0(32'h8000_7200,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd11);
      set_dispatch1(32'h8000_7204,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd6, 64'd22);
      #1;
      tb_check1("R3.2 dual producers lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3.2 dual producers lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("R3.2 dual producer0 fires", dut.issue0_fire_w, 1'b1);
      tb_check1("R3.2 dual producer1 fires", dut.issue1_fire_w, 1'b1);

      set_dispatch0(32'h8000_7208,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd7, 64'd1);
      set_dispatch1(32'h8000_720c,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd6, 5'd0, 5'd8, 64'd2);
      #1;
      tb_check1("R3.2 dual consumers lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3.2 dual consumers lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("R3.2 consumer0 fires N+1", dut.issue0_fire_w, 1'b1);
      tb_check1("R3.2 consumer1 fires N+1", dut.issue1_fire_w, 1'b1);
      tb_check32("R3.2 consumer0 PC", dut.issue0_pc_w[31:0],
                 32'h8000_7208);
      tb_check32("R3.2 consumer1 PC", dut.issue1_pc_w[31:0],
                 32'h8000_720c);
      tb_check1("R3.2 consumer0 uses EX0", dut.issue0_src1_ex0_fwd_hit_w,
                1'b1);
      tb_check1("R3.2 consumer0 does not use EX1",
                dut.issue0_src1_ex1_fwd_hit_w, 1'b0);
      tb_check1("R3.2 consumer1 uses EX1", dut.issue1_src1_ex1_fwd_hit_w,
                1'b1);
      tb_check64("R3.2 consumer0 forwarded value",
                 dut.issue0_src1_data_w, 64'd11);
      tb_check64("R3.2 consumer1 forwarded value",
                 dut.issue1_src1_value_w, 64'd22);

      `TB_TICK(clk);
      #1;
      tb_check64("R3.2 dual result0", dut.wb0_data_w, 64'd12);
      tb_check64("R3.2 dual result1", dut.wb1_data_w, 64'd24);
      repeat (3) begin
        `TB_TICK(clk);
      end
      #1;
      tb_check32("R3.2 dual ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("R3.2 dual IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("R3.2 dual freelist recovers", {25'b0, free_count},
                 32'd32);
    end
  endtask

  // A nontrivial 64-uop RAW chain is kept one entry ahead of issue.  Every
  // producer is therefore required to fire in cycle N and its consumer in
  // cycle N+1; every consumer must use the registered EX0 payload, and the
  // architectural result sequence must commit as 1..64.
  task automatic run_r3p2_raw_chain_64;
    integer dispatched;
    integer fired;
    integer committed;
    integer cycle_count;
    integer previous_fire_cycle;
    begin
      reset_dut();

      set_dispatch0(32'h8000_a000,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_a004,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd5, 64'd1);
      #1;
      tb_check1("R3.2 chain seed lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3.2 chain seed lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);

      dispatched = 2;
      fired = 0;
      committed = 0;
      cycle_count = 0;
      previous_fire_cycle = -1;

      while ((committed < 64) && (cycle_count < 160)) begin
        clear_dispatch();
        if (dispatched < 64) begin
          set_dispatch0(32'h8000_a000 + (dispatched * 4),
                        make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                        5'd5, 5'd0, 5'd5, 64'd1);
        end
        #1;

        if (dispatched < 64) begin
          tb_check1("R3.2 chain continuous dispatch", dispatch0_ready,
                    1'b1);
          if (dispatch0_ready)
            dispatched = dispatched + 1;
        end

        if (fired < 64) begin
          tb_check1("R3.2 chain issue0 fires", dut.issue0_fire_w, 1'b1);
          tb_check1("R3.2 chain never consumes issue1", dut.issue1_fire_w,
                    1'b0);
          if (dut.issue0_fire_w) begin
            tb_check32("R3.2 chain fire PC", dut.issue0_pc_w[31:0],
                       32'h8000_a000 + (fired * 4));
            if (fired != 0) begin
              tb_check32("R3.2 chain producer N to consumer N+1",
                         cycle_count - previous_fire_cycle, 32'd1);
              tb_check1("R3.2 chain registered EX0 hit",
                        dut.issue0_src1_ex0_fwd_hit_w, 1'b1);
              tb_check64("R3.2 chain forwarded value",
                         dut.issue0_src1_data_w, fired);
            end
            previous_fire_cycle = cycle_count;
            fired = fired + 1;
          end
        end

        if (commit0_valid) begin
          tb_check32("R3.2 chain commit PC", commit0_pc[31:0],
                     32'h8000_a000 + (committed * 4));
          tb_check64("R3.2 chain result sequence", commit0_data,
                     committed + 1);
          committed = committed + 1;
        end
        tb_check1("R3.2 chain single commit lane", commit1_valid, 1'b0);

        `TB_TICK(clk);
        cycle_count = cycle_count + 1;
      end
      clear_dispatch();
      #1;

      tb_check32("R3.2 chain dispatched all", dispatched, 32'd64);
      tb_check32("R3.2 chain fired all", fired, 32'd64);
      tb_check32("R3.2 chain committed all", committed, 32'd64);
      tb_check32("R3.2 chain ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("R3.2 chain IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("R3.2 chain freelist recovers", {25'b0, free_count},
                 32'd32);
      $display("[R3.2-RAW64] fired=%0d committed=%0d cycles=%0d",
               fired, committed, cycle_count);
    end
  endtask

  task automatic run_lane1_prf_wb_wakeup;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    begin
      reset_dut();

      // P 与依赖者 A 同拍 dispatch；P 发射的同一拍再 dispatch 依赖者 C。
      // T3M：P 的 WB 拍 A/C 都不得 select；该沿同时写 PRF 与 sticky，N+1
      // 按年龄分别占 issue0/1，并从 regs_q 取得 P 的值。这里证明 issue1 的合法活路径
      // 不依赖 issue0-current-result mux，也为以后重新评估物理删除保留常驻覆盖。
      set_dispatch0(32'h8000_0600,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h1122_3344_5566_7780);
      set_dispatch1(32'h8000_0604,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd7, 5'd0, 5'd8, 64'd5);
      #1;
      tb_check1("lane1 PRF setup dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("lane1 PRF setup dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check32("lane1 PRF setup keeps P/A resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("lane1 PRF P selected alone", dut.issue0_valid_w, 1'b1);
      tb_check32("lane1 PRF P occupies issue0", dut.issue0_pc_w[31:0],
                 32'h8000_0600);
      tb_check1("lane1 PRF A still waits", dut.issue1_valid_w, 1'b0);

      set_dispatch0(32'h8000_0608,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd7, 5'd0, 5'd9, 64'd9);
      #1;
      tb_check1("lane1 PRF C dispatches while P issues", dispatch0_ready,
                1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("lane1 PRF producer WB visible", dut.wb0_valid_w, 1'b1);
      tb_check64("lane1 PRF producer formal WB data",
                 dut.wb0_data_w, 64'h1122_3344_5566_7780);
      producer_pdest = dut.wb0_pdest_w;
      // R3.2 lookahead wake is absorbed at the producer-fire edge, so A
      // and same-edge-dispatched C both select now, while producer formal WB
      // and the matching registered EX payload are visible.
      tb_check1("R3.2 A selects with producer EX", dut.issue0_valid_w, 1'b1);
      tb_check1("R3.2 C selects with producer EX", dut.issue1_valid_w, 1'b1);
      tb_check32("R3.2 A issue PC", dut.issue0_pc_w[31:0], 32'h8000_0604);
      tb_check32("R3.2 C issue PC", dut.issue1_pc_w[31:0], 32'h8000_0608);
      tb_check1("R3.2 A fires", dut.issue0_fire_w, 1'b1);
      tb_check1("R3.2 C fires", dut.issue1_fire_w, 1'b1);
      tb_check32("R3.2 A source tag", {26'b0, dut.issue0_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check32("R3.2 C source tag", {26'b0, dut.issue1_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check1("R3.2 A EX0 hit", dut.issue0_src1_ex0_fwd_hit_w, 1'b1);
      tb_check1("R3.2 C EX0 hit", dut.issue1_src1_ex0_fwd_hit_w, 1'b1);
      tb_check32("R3.2 C forwarded source low",
                 dut.issue1_src1_value_w[31:0], 32'h5566_7780);
      tb_check32("R3.2 C forwarded source high",
                 dut.issue1_src1_value_w[63:32], 32'h1122_3344);

      `TB_TICK(clk);
      #1;
      tb_check1("R3.2 A formal WB visible", dut.wb0_valid_w, 1'b1);
      tb_check1("R3.2 C formal WB visible", dut.wb1_valid_w, 1'b1);
      tb_check1("R3.2 producer commits while consumers WB",
                commit0_valid, 1'b1);
      tb_check64("R3.2 A formal WB data", dut.wb0_data_w,
                 64'h1122_3344_5566_7785);
      tb_check64("R3.2 C formal WB data", dut.wb1_data_w,
                 64'h1122_3344_5566_7789);

      `TB_TICK(clk);
      #1;
      tb_check1("R3.2 A result commits", commit0_valid, 1'b1);
      tb_check1("R3.2 C result commits", commit1_valid, 1'b1);
      tb_check32("R3.2 A result low", commit0_data[31:0], 32'h5566_7785);
      tb_check32("R3.2 A result high", commit0_data[63:32], 32'h1122_3344);
      tb_check32("R3.2 C result low", commit1_data[31:0], 32'h5566_7789);
      tb_check32("R3.2 C result high", commit1_data[63:32], 32'h1122_3344);

      `TB_TICK(clk);
      #1;
      tb_check32("lane1 PRF ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("lane1 PRF IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("lane1 PRF freelist recovers", {25'b0, free_count}, 32'd32);
    end
  endtask

  // T3B 集成契约：MulDiv/CLMUL 的 formal WB 仍负责 ROB done、PRF 正式写入和
  // IQ ready 状态更新，但不能回灌 select/PRF fast payload。依赖者必须在响应拍
  // 保持等待，下一拍才从已登记的 PRF 值发射。
  task automatic run_t3b_divu_wb0_isolation;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    begin
      reset_dut();

      set_dispatch0(32'h8000_6400, make_muldiv_ctrl(),
                    5'd0, 5'd0, 5'd5, 64'd0);
      dispatch0_inst = inst_op(`FUNCT7_MULDIV, 5'd0, 5'd0,
                               3'b101, 5'd5);
      set_dispatch1(32'h8000_6404,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd6, 64'd1);
      #1;
      tb_check1("T3B DIVU WB0 producer dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("T3B DIVU WB0 dependent dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check32("T3B DIVU WB0 pair resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("T3B DIVU WB0 producer selected",
                dut.issue0_valid_w, 1'b1);
      tb_check32("T3B DIVU WB0 producer PC",
                 dut.issue0_pc_w[31:0], 32'h8000_6400);
      tb_check1("T3B DIVU WB0 dependent waits before response",
                dut.issue1_valid_w, 1'b0);
      producer_pdest = dut.issue0_pdest_w;

      // T3Q：issue 拍只捕获完整 MulDiv request，下一拍才从 buffer Q 初始化；
      // 外部输入清零不得穿透到预处理。
      `TB_TICK(clk);
      #1;
      tb_check1("T3Q DIVU request buffered before preprocess",
                dut.u_muldiv_unit.state_q == 3'd1, 1'b1);
      tb_check1("T3Q DIVU buffer has no early response",
                dut.muldiv_resp_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU response maps formal WB0",
                dut.muldiv_rsp_to_wb0_w, 1'b1);
      tb_check1("T3B DIVU formal WB0 valid", dut.wb0_valid_w, 1'b1);
      tb_check32("T3B DIVU formal WB0 pdest",
                 {26'b0, dut.wb0_pdest_w}, {26'b0, producer_pdest});
      tb_check64("T3B DIVU formal WB0 data",
                 dut.wb0_data_w, 64'hffff_ffff_ffff_ffff);
      tb_check1("T3B DIVU producer does not commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3B DIVU dependent cannot select on response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B DIVU dependent remains resident on response",
                 {28'b0, issue_count}, 32'd1);

      // formal WB 在该上升沿写 PRF/ready；响应后的 N+1 周期才允许发射。
      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU dependent selects at N+1",
                dut.issue0_valid_w, 1'b1);
      tb_check1("T3B DIVU producer commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B DIVU producer commit data from ROB Q",
                 commit0_data, 64'hffff_ffff_ffff_ffff);
      tb_check32("T3B DIVU dependent PC at N+1",
                 dut.issue0_pc_w[31:0], 32'h8000_6404);
      tb_check32("T3B DIVU dependent source tag",
                 {26'b0, dut.issue0_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check64("T3B DIVU dependent reads registered PRF",
                 dut.issue0_src1_data_w, 64'hffff_ffff_ffff_ffff);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU dependent formal WB visible",
                dut.wb0_valid_w, 1'b1);
      tb_check64("T3B DIVU dependent formal WB result",
                 dut.wb0_data_w, 64'd0);
      tb_check1("T3B DIVU dependent does not commit on formal WB",
                commit0_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU dependent commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B DIVU dependent result from ROB Q",
                 commit0_data, 64'd0);

      `TB_TICK(clk);
      #1;
      tb_check32("T3B DIVU WB0 ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T3B DIVU WB0 IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("T3B DIVU WB0 freelist recovers",
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic run_t3b_clmul_wb0_isolation;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    reg early_issue;
    integer wait_cycles;
    begin
      reset_dut();

      set_dispatch0(32'h8000_6500,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'd3);
      set_dispatch1(32'h8000_6504,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd5);
      tick_dispatch_to_commit("T3B CLMUL operand setup", 64'd3, 64'd5);

      set_dispatch0(32'h8000_6510, make_bitmanip_op_ctrl(),
                    5'd1, 5'd2, 5'd3, 64'd0);
      dispatch0_inst = inst_op(7'h05, 5'd2, 5'd1,
                               `FUNCT3_SLL, 5'd3);
      set_dispatch1(32'h8000_6514,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd3, 5'd0, 5'd4, 64'd1);
      #1;
      tb_check1("T3B CLMUL WB0 producer dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("T3B CLMUL WB0 dependent dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check32("T3B CLMUL WB0 pair resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("T3B CLMUL WB0 producer selected",
                dut.issue0_valid_w, 1'b1);
      tb_check32("T3B CLMUL WB0 producer PC",
                 dut.issue0_pc_w[31:0], 32'h8000_6510);
      producer_pdest = dut.issue0_pdest_w;

      `TB_TICK(clk);
      #1;
      early_issue = 1'b0;
      wait_cycles = 0;
      while (!dut.clmul_rsp_to_wb0_w && (wait_cycles < 70)) begin
        if (dut.issue0_valid_w || dut.issue1_valid_w)
          early_issue = 1'b1;
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      if (dut.issue0_valid_w || dut.issue1_valid_w)
        early_issue = 1'b1;

      tb_check1("T3B CLMUL dependent never selects before response",
                early_issue, 1'b0);
      tb_check1("T3B CLMUL response reaches formal WB0",
                dut.clmul_rsp_to_wb0_w, 1'b1);
      tb_check1("T3B CLMUL formal WB0 valid", dut.wb0_valid_w, 1'b1);
      tb_check32("T3B CLMUL formal WB0 pdest",
                 {26'b0, dut.wb0_pdest_w}, {26'b0, producer_pdest});
      tb_check64("T3B CLMUL formal WB0 data",
                 dut.wb0_data_w, ref_clmul(2'd0, 64'd3, 64'd5));
      tb_check1("T3B CLMUL producer does not commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3B CLMUL dependent cannot select on response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B CLMUL dependent remains resident on response",
                 {28'b0, issue_count}, 32'd1);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B CLMUL dependent selects at N+1",
                dut.issue0_valid_w, 1'b1);
      tb_check1("T3B CLMUL producer commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B CLMUL producer commit data from ROB Q",
                 commit0_data, ref_clmul(2'd0, 64'd3, 64'd5));
      tb_check32("T3B CLMUL dependent PC at N+1",
                 dut.issue0_pc_w[31:0], 32'h8000_6514);
      tb_check32("T3B CLMUL dependent source tag",
                 {26'b0, dut.issue0_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check64("T3B CLMUL dependent reads registered PRF",
                 dut.issue0_src1_data_w, 64'd15);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B CLMUL dependent formal WB visible",
                dut.wb0_valid_w, 1'b1);
      tb_check64("T3B CLMUL dependent formal WB result",
                 dut.wb0_data_w, 64'd16);
      tb_check1("T3B CLMUL dependent does not commit on formal WB",
                commit0_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B CLMUL dependent commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B CLMUL dependent result from ROB Q",
                 commit0_data, 64'd16);

      `TB_TICK(clk);
      #1;
      tb_check32("T3B CLMUL WB0 ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T3B CLMUL WB0 IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("T3B CLMUL WB0 freelist recovers",
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic run_t3b_divu_wb1_isolation;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    begin
      reset_dut();

      // 两条 ready uop 同拍发射：较老 ALU 自然占 WB0，DIVU 除零响应自然落 WB1。
      set_dispatch0(32'h8000_6600,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'd7);
      set_dispatch1(32'h8000_6604, make_muldiv_ctrl(),
                    5'd0, 5'd0, 5'd2, 64'd0);
      dispatch1_inst = inst_op(`FUNCT7_MULDIV, 5'd0, 5'd0,
                               3'b101, 5'd2);
      #1;
      tb_check1("T3B DIVU WB1 older ALU dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("T3B DIVU WB1 producer dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("T3B DIVU WB1 older ALU selected",
                dut.issue0_valid_w, 1'b1);
      tb_check1("T3B DIVU WB1 producer selected",
                dut.issue1_valid_w, 1'b1);
      tb_check32("T3B DIVU WB1 producer PC",
                 dut.issue1_pc_w[31:0], 32'h8000_6604);
      producer_pdest = dut.issue1_pdest_w;

      // 生产者正在 issue 时插入依赖者，rename map 已指向其 pdest。
      set_dispatch0(32'h8000_6608,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd2, 5'd0, 5'd3, 64'd1);
      #1;
      tb_check1("T3B DIVU WB1 dependent dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("T3Q DIVU WB1 request buffered before preprocess",
                dut.u_muldiv_unit.state_q == 3'd1, 1'b1);
      tb_check1("T3Q DIVU WB1 buffer has no early response",
                dut.muldiv_resp_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;

      tb_check1("T3B DIVU response maps formal WB1",
                dut.muldiv_rsp_to_wb1_w, 1'b1);
      tb_check1("T3B DIVU formal WB1 valid", dut.wb1_valid_w, 1'b1);
      tb_check32("T3B DIVU formal WB1 pdest",
                 {26'b0, dut.wb1_pdest_w}, {26'b0, producer_pdest});
      tb_check64("T3B DIVU formal WB1 data",
                 dut.wb1_data_w, 64'hffff_ffff_ffff_ffff);
      tb_check1("T3B DIVU older ALU formal WB0 valid",
                dut.wb0_valid_w, 1'b1);
      tb_check64("T3B DIVU older ALU formal WB0 data",
                 dut.wb0_data_w, 64'd7);
      tb_check1("T3B DIVU WB1 pair has no commit on formal WB",
                commit0_valid || commit1_valid, 1'b0);
      tb_check1("T3B DIVU WB1 dependent cannot select on response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B DIVU WB1 dependent remains resident",
                 {28'b0, issue_count}, 32'd1);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU WB1 dependent selects at N+1",
                dut.issue0_valid_w, 1'b1);
      tb_check1("T3B DIVU WB1 older ALU commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check1("T3B DIVU WB1 producer commits from ROB Q",
                commit1_valid, 1'b1);
      tb_check64("T3B DIVU WB1 older ALU commit data",
                 commit0_data, 64'd7);
      tb_check64("T3B DIVU WB1 producer commit data",
                 commit1_data, 64'hffff_ffff_ffff_ffff);
      tb_check32("T3B DIVU WB1 dependent PC at N+1",
                 dut.issue0_pc_w[31:0], 32'h8000_6608);
      tb_check32("T3B DIVU WB1 dependent source tag",
                 {26'b0, dut.issue0_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check64("T3B DIVU WB1 dependent reads registered PRF",
                 dut.issue0_src1_data_w, 64'hffff_ffff_ffff_ffff);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU WB1 dependent formal WB visible",
                dut.wb0_valid_w, 1'b1);
      tb_check64("T3B DIVU WB1 dependent formal WB result",
                 dut.wb0_data_w, 64'd0);
      tb_check1("T3B DIVU WB1 dependent does not commit on formal WB",
                commit0_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU WB1 dependent commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B DIVU WB1 dependent result from ROB Q",
                 commit0_data, 64'd0);

      `TB_TICK(clk);
      #1;
      tb_check32("T3B DIVU WB1 ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T3B DIVU WB1 IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("T3B DIVU WB1 freelist recovers",
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  // T3B domain exclusion：整数与 FP 物理寄存器编号空间可以出现相同数值，
  // 但 FP load response 只能写 FP PRF / 广播 fp_wake1，绝不能借 integer formal WB
  // 误唤醒同编号的整数 IQ source。用固定延迟 CLMUL 持有 GPR preg，再让单发
  // FP load 从独立 FP free-list 取得同号 preg，构造真实 tag alias。
  task automatic run_t3b_fp_load_tag_alias_exclusion;
    reg [PHY_REG_ADDR_W-1:0] gpr_pdest;
    reg [PHY_REG_ADDR_W-1:0] fp_pdest;
    begin
      reset_dut();

      // CLMUL 固定运行 64 拍，给后续 FP load response 留出稳定的整数等待窗。
      set_dispatch0(32'h8000_6700, make_bitmanip_op_ctrl(),
                    5'd0, 5'd0, 5'd5, 64'd0);
      dispatch0_inst = inst_op(7'h05, 5'd0, 5'd0,
                               `FUNCT3_SLL, 5'd5);
      #1;
      tb_check1("T3B FP-load alias CLMUL dispatch ready",
                dispatch0_ready, 1'b1);
      gpr_pdest = dut.dispatch0_pdest_w;
      tb_check1("T3B FP-load alias GPR pdest nonzero",
                gpr_pdest != {PHY_REG_ADDR_W{1'b0}}, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3B FP-load alias CLMUL selected",
                dut.issue0_valid_w && dut.issue0_is_clmul_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B FP-load alias CLMUL remains inflight",
                dut.clmul_resp_valid_w, 1'b0);

      // 单发 lane0 FP load 使用 FP alloc0，因此复位后的首个 FPR preg 与上面的
      // 首个 GPR preg 数值相同；两个 free-list 仍是完全独立的状态域。
      set_dispatch0(32'h8000_6704,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'h8000_02a0);
      dispatch0_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd9,
                        `OPCODE_LOAD_FP};
      dispatch0_is_fp = 1'b1;
      dispatch0_fp_load = 1'b1;
      dispatch0_fp_double = 1'b1;
      #1;
      tb_check1("T3B FP-load alias dispatch ready", dispatch0_ready, 1'b1);
      fp_pdest = dut.fpld0_new_pdest_w;
      tb_check32("T3B FP-load/GPR numeric tag aliases",
                 {26'b0, fp_pdest}, {26'b0, gpr_pdest});
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3S FP-load alias capture has no early request",
                mem_req_valid, 1'b0);
      tb_check1("T3S FP-load alias reservation capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B FP-load alias request visible", mem_req_valid, 1'b1);
      tb_check1("T3B FP-load alias request is read", mem_req_write, 1'b0);
      tb_check32("T3B FP-load alias request address",
                 mem_req_addr[31:0], 32'h8000_02a0);

      // load 发射同拍把真正依赖 CLMUL GPR preg 的整数 uop 放入 IQ。
      set_dispatch0(32'h8000_6708,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd6, 64'd1);
      #1;
      tb_check1("T3B FP-load alias dependent dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3B FP-load alias dependent resident",
                 {28'b0, issue_count}, 32'd1);
      tb_check32("T3B FP-load alias dependent source tag",
                 {26'b0, dut.u_dispatch_backend.u_issue_queue.src1_preg_q[0]},
                 {26'b0, gpr_pdest});
      tb_check1("T3B FP-load alias dependent waits before response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0123_4567_89ab_cdef;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3B FP-load alias response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3B FP-load alias classified FP", dut.mem_rsp_fp_load_w,
                1'b1);
      tb_check32("T3B FP-load alias response keeps numeric tag",
                 {26'b0, dut.miq_head_pdest_w}, {26'b0, gpr_pdest});
      tb_check1("T3B FP-load alias FP wake1 valid", dut.fp_wake1_valid_w,
                1'b1);
      tb_check32("T3B FP-load alias FP wake1 tag",
                 {26'b0, dut.fp_wake1_preg_w}, {26'b0, gpr_pdest});
      tb_check32("T3B FP-load alias integer WB0 pdest is p0",
                 {26'b0, dut.wb0_pdest_w}, 32'd0);
      tb_check1("T3B FP-load alias cannot wake integer issue",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B FP-load alias integer resident preserved",
                 {28'b0, issue_count}, 32'd1);
      $display("[T3B-COVERAGE-OBS] fp-load alias gpr_pdest=%0d fp_pdest=%0d int_wb_pdest=%0d int_issue={%0b,%0b}",
               gpr_pdest, fp_pdest, dut.wb0_pdest_w, dut.issue0_valid_w,
               dut.issue1_valid_w);

      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      // 本场景只验证 response 拍跨域隔离；复位清理长操作和未提交依赖者。
      reset_dut();
    end
  endtask

  // T3B fault exclusion：accepted integer load access-fault 仍必须由 formal WB
  // 携带 exception/cause/tval 完成 ROB 身份，但 fault payload 不是合法 operand，
  // response 拍不得使 integer dependent 发射。
  task automatic run_t3b_integer_load_fault_exclusion;
    reg [PHY_REG_ADDR_W-1:0] load_pdest;
    begin
      reset_dut();

      set_dispatch0(32'h8000_6800,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd10, 64'h8000_02c0);
      #1;
      tb_check1("T3B load-fault dispatch ready", dispatch0_ready, 1'b1);
      load_pdest = dut.dispatch0_pdest_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3S load-fault capture has no early request",
                mem_req_valid, 1'b0);
      tb_check1("T3S load-fault reservation capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B load-fault request visible", mem_req_valid, 1'b1);
      tb_check1("T3B load-fault request is read", mem_req_write, 1'b0);
      tb_check32("T3B load-fault request address",
                 mem_req_addr[31:0], 32'h8000_02c0);

      // 请求发射同拍插入依赖者，证明 fault response 不会被 fast CAM 消费。
      set_dispatch0(32'h8000_6804,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd10, 5'd0, 5'd11, 64'd1);
      #1;
      tb_check1("T3B load-fault dependent dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3B load-fault dependent waits before response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B load-fault dependent resident",
                 {28'b0, issue_count}, 32'd1);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'hfeed_face_dead_beef;
      mem_rsp_error = 1'b1;
      #1;
      tb_check1("T3B load-fault response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3B load-fault maps formal WB0",
                dut.mem_rsp_to_wb0_w, 1'b1);
      tb_check1("T3B load-fault formal WB0 valid", dut.wb0_valid_w, 1'b1);
      tb_check32("T3B load-fault formal WB0 pdest",
                 {26'b0, dut.wb0_pdest_w}, {26'b0, load_pdest});
      tb_check1("T3B load-fault formal exception",
                dut.wb0_exception_w, 1'b1);
      tb_check32("T3B load-fault formal cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_LOAD_ACCESS_FAULT});
      tb_check64("T3B load-fault formal tval",
                 dut.wb0_tval_w, 64'h0000_0000_8000_02c0);
      tb_check1("T3B load-fault cannot same-cycle wake dependent",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check1("T3B load-fault has no commit on formal WB",
                commit0_valid, 1'b0);
      $display("[T3B-COVERAGE-OBS] load-fault pdest=%0d formal={valid=%0b exc=%0b cause=%0d tval=0x%016h}",
               load_pdest, dut.wb0_valid_w, dut.wb0_exception_w,
               dut.wb0_cause_w, dut.wb0_tval_w);

      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3B load-fault commit visible from ROB Q",
                commit0_valid, 1'b1);
      tb_check1("T3B load-fault commit exception from ROB Q",
                commit0_exception, 1'b1);
      tb_check32("T3B load-fault commit cause from ROB Q",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_LOAD_ACCESS_FAULT});
      tb_check64("T3B load-fault commit tval from ROB Q", commit0_tval,
                 64'h0000_0000_8000_02c0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B load-fault commits exactly once", commit0_valid, 1'b0);
      reset_dut();
    end
  endtask

  // T4H：桥侧 PMA deny 复用 PROBE response ABI；后端必须把它形成精确
  // store-access-fault，而不是回填/退休 SQ entry 后等待 drain 错误。
  task automatic run_t4h_store_probe_pma_fault_precise;
    localparam [`XLEN-1:0] STORE_PC = 64'h0000_0000_8000_68c0;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_1800_0040;
    begin
      reset_dut();
      set_dispatch0(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      // SQ allocation/retire classification consumes the architectural opcode,
      // while the focused TB supplies ctrl/imm directly.
      dispatch0_inst = 32'h0000_3023;  // sd x0,0(x0)
      #1;
      tb_check1("T4H store-fault dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4H store PMA probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b1, {`STRB_W{1'b1}});
      tb_check1("T4H plain store request is probe",
                dut.mem_req_probe_o, 1'b1);
      `TB_TICK(clk);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b1;
      #1;
      tb_check1("T4H probe fault response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4H probe fault maps formal WB", dut.mem_rsp_to_wb0_w,
                1'b1);
      tb_check1("T4H probe fault formal exception", dut.wb0_exception_w,
                1'b1);
      tb_check32("T4H probe fault formal cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
      tb_check64("T4H probe fault formal tval", dut.wb0_tval_w, STORE_VA);
      tb_check1("T4H fault probe cannot fill SQ", dut.sq_fill_probe_w,
                1'b0);
      tb_check1("T4H fault probe cannot request drain",
                dut.sq_drain_req_valid_w, 1'b0);
      tb_check1("T4H no commit on formal WB", commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4H store fault commits from ROB Q", commit0_valid, 1'b1);
      tb_check1("T4H store fault commit exception", commit0_exception, 1'b1);
      tb_check32("T4H store fault commit cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
      tb_check64("T4H store fault commit tval", commit0_tval, STORE_VA);
      tb_check1("T4H exception store remains non-drainable",
                dut.sq_drain_req_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T4H store fault commits exactly once", commit0_valid, 1'b0);
      tb_check1("T4H no retired-store bus request", mem_req_valid, 1'b0);
      $display("[T4H-PMA-PRECISE-STORE] cause=7 tval=%h SQ-fill=0 drain=0",
               STORE_VA);
      reset_dut();
    end
  endtask

  // T4N: residual write-side bus error is precise at B, even when translation
  // changed the address.  The physical request uses PA; cause/tval retain
  // store-access-fault/original VA and the write is issued exactly once.
  task automatic run_t4n_store_b_error_precise;
    localparam [`XLEN-1:0] STORE_PC = 64'h0000_0000_8000_68e0;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_1040;
    localparam [`XLEN-1:0] STORE_PA = 64'h0000_0000_8000_1240;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      set_dispatch0(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      #1;
      tb_check1("T4N B-error store dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4N B-error probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b1, {`STRB_W{1'b1}});
      tb_check1("T4N B-error first request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);
      #1;
      complete_sq_store_after_probe("T4N B-error store",
                                    STORE_VA, STORE_PA, 1'b1, 1'b1);
      tb_check32("T4N B-error ROB drained", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N B-error SQ drained",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-B-ERROR-PRECISE] va=0x%016h pa=0x%016h cause=7",
               STORE_VA, STORE_PA);
      reset_dut();
    end
  endtask

  // R4 S0: the translation response owns the final PMA/PBMT class.  A PBMT
  // NC/IO store may still translate to PMEM, so the SQ must retain cacheable=0
  // and replay that exact attribute with the later pretranslated ROB-head write.
  task automatic run_r4_s0_store_class_propagation;
    localparam [`XLEN-1:0] STORE_PC = 64'h0000_0000_8000_68e8;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_1080;
    localparam [`XLEN-1:0] STORE_PA = 64'h0000_0000_8000_1280;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      set_dispatch0(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      #1;
      tb_check1("R4 S0 PBMT store dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("R4 S0 PBMT store probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("R4 S0 first request is translation probe",
                mem_req_probe, 1'b1);
      `TB_TICK(clk);
      #1;
      complete_sq_store_after_probe("R4 S0 PBMT-NC store",
                                    STORE_VA, STORE_PA, 1'b0, 1'b0);
      tb_check32("R4 S0 PBMT store ROB drained",
                 {27'b0, rob_count}, 32'd0);
      tb_check32("R4 S0 PBMT store SQ drained",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[R4-S0-STORE-CLASS] va=0x%016h pa=0x%016h cacheable=0 PASS",
               STORE_VA, STORE_PA);
      reset_dut();
    end
  endtask

  // T4N reviewer P1-1: translated plain stores that cross a 4 KiB boundary
  // terminate locally.  They still own an SQ entry, so the local exception
  // event must mark that exact ROB entry terminal before commit0 releases it.
  task automatic run_t4n_page_end_store_local_exception;
    input fp_store_case;
    reg [1023:0] label;
    reg [`XLEN-1:0] store_pc;
    reg [`XLEN-1:0] store_va;
    integer wait_cycles;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      label = fp_store_case ? "T4N FSD page-end" : "T4N SD page-end";
      store_pc = fp_store_case ? 64'h0000_0000_8000_68f4 :
                                 64'h0000_0000_8000_68f0;
      store_va = fp_store_case ? 64'h0000_0000_4000_2ffc :
                                 64'h0000_0000_4000_1ffc;
      set_dispatch0(store_pc, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, store_va);
      if (fp_store_case) begin
        dispatch0_inst = {7'd0, 5'd0, 5'd0, 3'b011, 5'd0,
                          `OPCODE_STORE_FP};  // fsd f0,0(x0)
        dispatch0_is_fp = 1'b1;
        dispatch0_fp_store = 1'b1;
        dispatch0_fp_double = 1'b1;
        dispatch0_fp_fs2_en = 1'b1;
      end else begin
        dispatch0_inst = 32'h0000_3023;  // sd x0,0(x0)
      end
      #1;
      tb_check1({label, " dispatch ready"}, dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      wait_cycles = 0;
      while (!(dut.mem_issue_res_consume_fire_w &&
               dut.issue0_mem_exception_w) && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " local exception consumes reservation"},
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1({label, " classified cross-page exception"},
                dut.issue0_xpage_misalign_w, 1'b1);
      tb_check1({label, " produces SQ terminal"},
                dut.sq_terminal_valid_w, 1'b1);
      tb_check32({label, " terminal ROB identity"},
                 {{(32-ROB_INDEX_W){1'b0}}, dut.sq_terminal_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q});
      tb_check1({label, " cannot issue a bridge request"},
                mem_req_valid, 1'b0);
      tb_check32({label, " SQ owner resident before terminal edge"},
                 {29'b0, dut.sq_count_w}, 32'd1);

      `TB_TICK(clk);
      #1;
      tb_check1({label, " formal WB valid"}, dut.wb0_valid_w, 1'b1);
      tb_check1({label, " formal WB exception"}, dut.wb0_exception_w, 1'b1);
      tb_check32({label, " formal WB cause"},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ADDR_MISALIGN});
      tb_check64({label, " formal WB tval"}, dut.wb0_tval_w, store_va);
      tb_check1({label, " no commit on formal WB"}, commit0_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1({label, " commits as exception at commit0"},
                commit0_valid && commit0_exception, 1'b1);
      tb_check1({label, " SQ release is terminal-ready"},
                dut.sq_release_ready_w, 1'b1);
      tb_check32({label, " commit cause"},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ADDR_MISALIGN});
      tb_check64({label, " commit tval"}, commit0_tval, store_va);
      `TB_TICK(clk);
      #1;
      tb_check32({label, " ROB released"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " SQ released"}, {29'b0, dut.sq_count_w}, 32'd0);
      tb_check1({label, " never requested memory"}, mem_req_valid, 1'b0);
      $display("[T4N-PAGE-END-STORE-TERMINAL] kind=%s va=0x%016h",
               fp_store_case ? "FSD" : "SD", store_va);
      reset_dut();
    end
  endtask

  // Two independent terminal producers can be live in one cycle: an older
  // accepted physical store receives B while a younger translated SD/FSD
  // terminates locally at the page end.  Both tags must become sticky without
  // backpressuring either producer, then release strictly in ROB order.
  task automatic run_t4n_b_local_terminal_collision;
    input fp_store_case;
    localparam [`XLEN-1:0] OLDER_VA = 64'h0000_0000_4000_3a00;
    localparam [`XLEN-1:0] OLDER_PA = 64'h0000_0000_8000_5a00;
    reg [`XLEN-1:0] younger_va;
    reg [ROB_INDEX_W-1:0] older_rob;
    reg [ROB_INDEX_W-1:0] younger_rob;
    reg older_terminal_seen;
    reg younger_terminal_seen;
    integer wait_cycles;
    integer slot;
    begin
      reset_dut();
      mem_translate_active = 1'b1;

      set_dispatch0(32'h8000_68f6, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, OLDER_VA);
      dispatch0_inst = 32'h0000_3023;
      #1;
      older_rob = dut.dispatch0_rob_idx_w;
      tb_check1("T4N dual-terminal older dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4N dual-terminal older probe", 1'b1, OLDER_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N dual-terminal older request is probe",
                mem_req_probe, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = OLDER_PA;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N dual-terminal probe response ready",
                mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      wait_mem0_request("T4N dual-terminal older physical", 1'b1, OLDER_PA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N dual-terminal physical request pretranslated",
                mem_req_pretrans, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N dual-terminal older DRAIN owns MIQ",
                 {28'b0, dut.miq_count_w}, 32'd1);

      younger_va = fp_store_case ? 64'h0000_0000_4000_6ffc :
                                   64'h0000_0000_4000_5ffc;
      set_dispatch0(fp_store_case ? 32'h8000_6902 : 32'h8000_68fe,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, younger_va);
      if (fp_store_case) begin
        dispatch0_inst = {7'd0, 5'd0, 5'd0, 3'b011, 5'd0,
                          `OPCODE_STORE_FP};
        dispatch0_is_fp = 1'b1;
        dispatch0_fp_store = 1'b1;
        dispatch0_fp_double = 1'b1;
        dispatch0_fp_fs2_en = 1'b1;
      end else begin
        dispatch0_inst = 32'h0000_3023;
      end
      #1;
      younger_rob = dut.dispatch0_rob_idx_w;
      tb_check1("T4N dual-terminal younger dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.mem_issue_res_valid_q &&
               dut.issue0_mem_exception_w) && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T4N dual-terminal local candidate resident",
                dut.mem_issue_res_valid_q && dut.issue0_mem_exception_w, 1'b1);

      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N dual-terminal B response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N dual-terminal response source fires",
                dut.sq_response_terminal_w, 1'b1);
      tb_check1("T4N dual-terminal local source fires",
                dut.sq_local_store_exception_w, 1'b1);
      tb_check1("T4N dual-terminal local consume is not backpressured",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check32("T4N dual-terminal response tag",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_head_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, older_rob});
      tb_check32("T4N dual-terminal local tag",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q},
                 {{(32-ROB_INDEX_W){1'b0}}, younger_rob});
`ifdef T4N_DUAL_TERMINAL_NEGATIVE
      // 非真空 mutation：模拟旧单 terminal/tag mux 丢掉 local port；正常构建
      // 不定义该宏。后续 sticky/release 检查必须稳定转 RED。
      force dut.u_store_queue.terminal1_hit_w = 4'b0000;
      $display("[T4N-DUAL-TERMINAL-NEGATIVE] forced second terminal CAM hit low");
`endif
      `TB_TICK(clk);
`ifdef T4N_DUAL_TERMINAL_NEGATIVE
      release dut.u_store_queue.terminal1_hit_w;
`endif
      mem_rsp_valid = 1'b0;
      #1;

      older_terminal_seen = 1'b0;
      younger_terminal_seen = 1'b0;
      for (slot = 0; slot < 4; slot = slot + 1) begin
        if (dut.sq_snoop_valid_w[slot] && dut.sq_snoop_terminal_w[slot] &&
            (dut.sq_snoop_rob_idx_w[slot*ROB_INDEX_W +: ROB_INDEX_W] ==
             older_rob))
          older_terminal_seen = 1'b1;
        if (dut.sq_snoop_valid_w[slot] && dut.sq_snoop_terminal_w[slot] &&
            (dut.sq_snoop_rob_idx_w[slot*ROB_INDEX_W +: ROB_INDEX_W] ==
             younger_rob))
          younger_terminal_seen = 1'b1;
      end
      tb_check1("T4N dual-terminal older tag sticky",
                older_terminal_seen, 1'b1);
      tb_check1("T4N dual-terminal younger tag sticky",
                younger_terminal_seen, 1'b1);
      tb_check1("T4N dual-terminal older store commits first",
                commit0_valid && !commit0_exception, 1'b1);
      tb_check1("T4N dual-terminal younger cannot commit1",
                commit1_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N dual-terminal younger remains after older release",
                 {29'b0, dut.sq_count_w}, 32'd1);
      tb_check1("T4N dual-terminal younger exception becomes commit0",
                commit0_valid && commit0_exception, 1'b1);
      tb_check64("T4N dual-terminal younger tval", commit0_tval, younger_va);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N dual-terminal ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N dual-terminal SQ drains",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-B-LOCAL-DUAL-TERMINAL] younger=%s older_rob=%0d younger_rob=%0d PASS",
               fp_store_case ? "FSD" : "SD", older_rob, younger_rob);
      reset_dut();
    end
  endtask

  // T4N reviewer P1-2: an older normal ALU may retire, but a younger store
  // exception must remain resident and become commit0 on the following cycle.
  task automatic run_t4n_older_alu_probe_fault_exception_order;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_3400;
    integer wait_cycles;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_68f8,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'h55);
      set_dispatch1(32'h8000_68fc, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      dispatch1_inst = 32'h0000_3023;
      #1;
      tb_check1("T4N older+fault dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("T4N older+fault dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4N younger store fault probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N younger store request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);

      tb_mem_rsp_attr_valid = 1'b0;
      tb_mem_rsp_class = `OOO_MEM_CLASS_RSVD;
      mem_rsp_cacheable = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b1;
      #1;
      wait_cycles = 0;
      while (!mem_rsp_ready && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T4N younger probe fault response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N pretarget probe fault has invalid attr",
                tb_mem_rsp_attr_valid, 1'b0);
      tb_check32("T4N pretarget probe fault has RSVD poison",
                 {30'b0, tb_mem_rsp_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check1("T4N pretarget probe fault cannot fill SQ",
                dut.sq_fill_valid_w, 1'b0);
      tb_check1("T4N commit held during fault WB", commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      mem_rsp_cacheable = 1'b1;
      commit_ready = 1'b1;
      #1;
      tb_check1("T4N older normal retires", commit0_valid, 1'b1);
      tb_check1("T4N exception structurally forbidden on commit1",
                commit1_valid, 1'b0);
      tb_check1("T4N no trap before exception becomes head",
                commit0_exception, 1'b0);
      tb_check32("T4N pair remains two-deep before older retire",
                 {27'b0, rob_count}, 32'd2);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N fault store remains after older retire",
                 {27'b0, rob_count}, 32'd1);
      tb_check1("T4N fault store becomes commit0 exception",
                commit0_valid && commit0_exception, 1'b1);
      tb_check1("T4N fault store release ready at commit0",
                dut.sq_release_ready_w, 1'b1);
      tb_check32("T4N fault store cause7",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
      tb_check64("T4N fault store original VA", commit0_tval, STORE_VA);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N ordered exception ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N ordered exception SQ drains",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-OLDER-ALU-YOUNGER-STORE-FAULT] commit1 blocked; next-cycle commit0 trap PASS");
      reset_dut();
    end
  endtask

  // T4N reviewer P2: checkpoint restore flushes MIQ, so SQ precommit request
  // grant must be masked in the same combinational cycle.  Otherwise SQ marks
  // request_sent while the matching MIQ push is discarded by its flush arm.
  task automatic run_t4n_sq_checkpoint_restore_no_fire;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_3800;
    localparam [`XLEN-1:0] STORE_PA = 64'h0000_0000_8000_4800;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      set_dispatch0(32'h8000_6908, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      dispatch0_inst = 32'h0000_3023;
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4N restore store probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = STORE_PA;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N restore probe response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      tb_check32("T4N restore setup SQ resident",
                 {29'b0, dut.sq_count_w}, 32'd1);
      tb_check1("T4N restore setup physical request eligible",
                dut.sq_drain_valid_w, 1'b1);

      checkpoint_restore = 1'b1;
      mem_req_ready = 1'b1;
      #1;
      tb_check1("T4N restore masks SQ grant", dut.grant_sq_w, 1'b0);
      tb_check1("T4N restore masks external request", mem_req_valid, 1'b0);
      tb_check1("T4N restore forbids SQ request fire",
                dut.sq_drain_req_fire_w, 1'b0);
      tb_check1("T4N restore forbids MIQ push", dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check32("T4N restore preserves SQ owner",
                 {29'b0, dut.sq_count_w}, 32'd1);
      tb_check32("T4N restore leaves MIQ empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check1("T4N restore did not mark request sent",
                dut.sq_snoop_request_sent_w[dut.sq_snoop_head_w], 1'b0);
      tb_check1("T4N request resumes after restore", mem_req_valid, 1'b1);
      tb_check64("T4N resumed request keeps PA", mem_req_addr, STORE_PA);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N resumed request owns MIQ",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("T4N resumed physical request is at-most-once",
                mem_req_valid, 1'b0);

      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N resumed B response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("T4N resumed store commits", commit0_valid, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N restore scenario ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N restore scenario SQ drains",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-CHECKPOINT-RESTORE-SQ-GATE] no fire/no owner loss PASS");
      reset_dut();
    end
  endtask

  // Two stores expose the arbitration counterexample directly: while store1's
  // successful probe fill makes its physical request eligible, store2 is held
  // in the reservation.  SQ must win; store2 may transfer to the buffer but may
  // not report a bridge fire.  Responses/commits then remain in physical order.
  task automatic run_t4n_two_store_priority_order;
    localparam [`XLEN-1:0] VA0 = 64'h0000_0000_4000_2000;
    localparam [`XLEN-1:0] PA0 = 64'h0000_0000_8000_2000;
    localparam [`XLEN-1:0] VA1 = 64'h0000_0000_4000_3000;
    localparam [`XLEN-1:0] PA1 = 64'h0000_0000_8000_3000;
    integer wait_cycles;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      set_dispatch0(32'h8000_6900, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, VA0);
      set_dispatch1(32'h8000_6904, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, VA1);
      #1;
      tb_check1("T4N two-store dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("T4N two-store dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();

      wait_mem0_request("T4N store0 probe", 1'b1, VA0,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N store0 request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);
      // Hold the bridge request side so store1 becomes a resident reservation
      // instead of escaping before store0 probe response creates SQ priority.
      mem_req_ready = 1'b0;
      #1;
      wait_cycles = 0;
      while (!dut.mem_issue_res_valid_q && (wait_cycles < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T4N store1 resident before store0 fill",
                dut.mem_issue_res_valid_q, 1'b1);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = PA0;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N store0 probe response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N store0 probe has no WB", dut.mem_wb_fire_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_req_ready = 1'b1;
      #1;

      tb_check1("T4N SQ wins request grant", dut.grant_sq_w, 1'b1);
      tb_check1("T4N younger issue loses request grant",
                dut.grant_issue0_w, 1'b0);
      tb_check1("T4N younger has no false request fire",
                dut.issue0_mem_request_fire_w, 1'b0);
      tb_check1("T4N younger transfers to buffer",
                dut.issue0_mem_buffer_fire_w, 1'b1);
      tb_check64("T4N first physical write uses PA0", mem_req_addr, PA0);
      tb_check1("T4N first physical write pretrans", mem_req_pretrans, 1'b1);
      `TB_TICK(clk);
      #1;

      // Buffered store1 probe follows, but store0 remains the only physical
      // write owner until its B terminal/commit.
      tb_check1("T4N buffered store1 probe visible", mem_req_valid, 1'b1);
      tb_check1("T4N buffered store1 is probe", mem_req_probe, 1'b1);
      tb_check64("T4N buffered store1 probe VA", mem_req_addr, VA1);
      tb_check1("T4N store0 cannot commit before B", commit0_valid, 1'b0);
      `TB_TICK(clk);
      #1;

      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N store0 B ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N store0 B owns WB", dut.miq_drain_wb_fire_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("T4N store0 commits after B", commit0_valid, 1'b1);
      tb_check1("T4N store1 cannot commit with store0", commit1_valid, 1'b0);

      // Store1 probe response can fill on the same edge that store0 terminal
      // releases; it still cannot physically write until becoming ROB head.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = PA1;
      #1;
      tb_check1("T4N store1 probe response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N store1 probe has no WB", dut.mem_wb_fire_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("T4N second physical write visible", mem_req_valid, 1'b1);
      tb_check64("T4N second physical write uses PA1", mem_req_addr, PA1);
      tb_check1("T4N second physical write pretrans", mem_req_pretrans, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T4N second physical write at-most-once", mem_req_valid, 1'b0);

      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("T4N store1 B ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("T4N store1 commits after B", commit0_valid, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N two-store ROB drained", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N two-store SQ drained", {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-TWO-STORE-ORDER] sq-priority/no-false-fire/order PASS");
      reset_dut();
    end
  endtask

  // S1/T4M/T4N interaction: every ordinary load is unknown-class until bridge
  // translation/PMA.  A younger device candidate must not occupy bridge's
  // device wait while an older filled SQ owner still needs that same bridge
  // for physical write/B; cover both translated PMEM-looking VA and Bare UART.
  task automatic run_t4n_t4m_store_before_device_candidate;
    input translate_mode;
    input [`XLEN-1:0] load_candidate_addr;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_4000;
    localparam [`XLEN-1:0] STORE_PA = 64'h0000_0000_8000_4000;
    integer wait_cycles;
    begin
      reset_dut();
      mem_translate_active = translate_mode;
      set_dispatch0(32'h8000_6920, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      set_dispatch1(32'h8000_6924,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd9, load_candidate_addr);
      #1;
      tb_check1("T4N/T4M pair dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("T4N/T4M pair dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();

      wait_mem0_request("T4N/T4M older store probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N/T4M older request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      wait_cycles = 0;
      while (!dut.mem_issue_res_valid_q && (wait_cycles < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T4N/T4M younger load resident",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("T4N/T4M resident is load", dut.issue0_is_load_w, 1'b1);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = STORE_PA;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N/T4M store probe response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_req_ready = 1'b1;
      #1;

      tb_check1("T4N/T4M unknown-class younger load blind-blocked",
                dut.issue0_load_waits_for_inflight_store_w, 1'b1);
      tb_check1("T4N/T4M younger load has no request-valid",
                dut.issue0_mem_req_valid_w, 1'b0);
      tb_check1("T4N/T4M older store physical grant", dut.grant_sq_w, 1'b1);
      tb_check64("T4N/T4M older store physical PA", mem_req_addr, STORE_PA);
      `TB_TICK(clk);
      #1;
      tb_check1("T4N/T4M younger load remains resident through write",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("T4N/T4M no younger request before B", mem_req_valid, 1'b0);
      tb_check1("T4N/T4M no store commit before B", commit0_valid, 1'b0);

      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("T4N/T4M store B ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("T4N/T4M store commits after B", commit0_valid, 1'b1);
      // B has made the older SQ entry terminal, so the younger request may be
      // exposed immediately; it still cannot receive IO release until the
      // store commit/release edge makes the load exact ROB head.
      tb_check1("T4N/T4M younger load issues immediately after B terminal",
                mem_req_valid, 1'b1);
      tb_check1("T4N/T4M younger request is read", mem_req_write, 1'b0);
      tb_check1("T4N/T4M younger request is not pretranslated",
                mem_req_pretrans, 1'b0);
      tb_check1("T4N/T4M ordinary load request attr invalid",
                mem_req_attr_valid, 1'b0);
      tb_check32("T4N/T4M ordinary load request class poison",
                 {30'b0, mem_req_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check64("T4N/T4M younger request keeps candidate address",
                 mem_req_addr, load_candidate_addr);
      tb_check1("T4N/T4M no device release before store commit edge",
                mem_req_device_release, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T4N/T4M younger request fires exactly once",
                mem_req_valid, 1'b0);
      tb_check1("T4N/T4M load MIQ owner enables device release",
                mem_req_device_release, 1'b1);
      // Both variants model a post-translation IO response.  The translated
      // variant is the counterexample where a PMEM-looking VA becomes IO.
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_IO;
      mem_rsp_cacheable = 1'b0;
      complete_mem0_response("T4N/T4M younger final-IO load", 64'h55aa,
                             1'b1, 1'b1, 1'b1, 64'h55aa);
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      mem_rsp_cacheable = 1'b1;
      $display("[T4N-T4M-STORE-BEFORE-DEVICE] translate=%0d store write/B/commit precedes load release PASS",
               translate_mode);
      reset_dut();
    end
  endtask

  // S1 deadlock barrier must retain its safe forwarding escape hatch.  A
  // real older CACHED store is probe-filled but not B-terminal; a fully
  // covered younger Bare load forwards locally while sq_block remains high,
  // never creating a second bridge request.
  task automatic run_s1_sq_forward_bypasses_blind_barrier;
    localparam [`XLEN-1:0] STORE_ADDR = 64'h0000_0000_8000_6a80;
    localparam [`XLEN-1:0] STORE_DATA = 64'h1122_3344_5566_7788;
    localparam [`XLEN-1:0] STORE_PC = 64'h0000_0000_8000_69a0;
    localparam [`XLEN-1:0] LOAD_PC = 64'h0000_0000_8000_69a4;
    reg [ROB_INDEX_W-1:0] load_rob;
    integer wait_cycles;
    integer store_commit_count;
    integer load_commit_count;
    reg load_commit_data_ok;
    integer commit_cycles;
    begin
      reset_dut();

      // Materialize nonzero store data in x1 with a real dual-ALU setup.
      set_dispatch0(32'h8000_6980,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, STORE_DATA);
      set_dispatch1(32'h8000_6984,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'h55);
      tick_dispatch_to_commit("S1 SQ-forward data setup", STORE_DATA, 64'h55);

      set_dispatch0(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd1, 5'd0, STORE_ADDR);
      dispatch0_ctrl[`CTRL_RS2_EN_BIT] = 1'b1;
      dispatch0_inst = 32'h0010_3023;  // sd x1,0(x0)
      #1;
      tb_check1("S1 SQ-forward store dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("S1 SQ-forward store probe", 1'b1, STORE_ADDR,
                        1'b1, STORE_DATA, 1'b1, {`STRB_W{1'b1}});
      tb_check1("S1 SQ-forward first request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);

      // Fill CACHED provenance, then backpressure the physical drain so the
      // older entry remains nonterminal during younger load issue.
      mem_req_ready = 1'b0;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      mem_rsp_cacheable = 1'b1;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = STORE_ADDR;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("S1 SQ-forward probe response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("S1 SQ-forward older SQ entry nonterminal",
                dut.sq_snoop_valid_w[dut.sq_snoop_head_w] &&
                !dut.sq_snoop_terminal_w[dut.sq_snoop_head_w], 1'b1);
      tb_check1("S1 SQ-forward physical drain held by backpressure",
                dut.grant_sq_w && !dut.sq_drain_req_fire_w, 1'b1);

      set_dispatch0(LOAD_PC, make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd3, STORE_ADDR);
      #1;
      load_rob = dut.dispatch0_rob_idx_w;
      tb_check1("S1 SQ-forward younger load dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!dut.issue0_sq_fwd_w && (wait_cycles < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("S1 SQ-forward blind barrier remains asserted",
                dut.issue0_sq_block_r, 1'b1);
      tb_check1("S1 SQ-forward complete cover enables bypass",
                dut.issue0_sq_fwd_w, 1'b1);
      tb_check64("S1 SQ-forward exact local data",
                 dut.issue0_sq_fwd_data_w, STORE_DATA);
      tb_check1("S1 SQ-forward load creates no bridge request",
                dut.issue0_mem_req_valid_w, 1'b0);
      tb_check1("S1 SQ-forward load is locally fireable",
                dut.issue0_mem_can_fire_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S1 SQ-forward exactly one formal WB",
                dut.wb0_valid_w && (dut.wb0_rob_idx_w == load_rob), 1'b1);
      tb_check64("S1 SQ-forward formal WB data", dut.wb0_data_w, STORE_DATA);
      tb_check1("S1 SQ-forward cannot commit ahead of store B",
                commit0_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("S1 SQ-forward formal WB not duplicated",
                !((dut.wb0_valid_w && (dut.wb0_rob_idx_w == load_rob)) ||
                  (dut.wb1_valid_w && (dut.wb1_rob_idx_w == load_rob))),
                1'b1);

      // Finish the older physical store and then observe each architectural
      // commit exactly once; the load may retire beside or just after store.
      mem_req_ready = 1'b1;
      #1;
      tb_check1("S1 SQ-forward physical drain becomes fireable",
                mem_req_valid && mem_req_pretrans, 1'b1);
      tb_check1("S1 SQ-forward drain typed CACHED",
                mem_req_attr_valid &&
                (mem_req_class == `OOO_MEM_CLASS_CACHED), 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S1 SQ-forward physical drain at-most-once",
                mem_req_valid, 1'b0);
      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("S1 SQ-forward B response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;

      store_commit_count = 0;
      load_commit_count = 0;
      load_commit_data_ok = 1'b1;
      for (commit_cycles = 0; commit_cycles < 4;
           commit_cycles = commit_cycles + 1) begin
        if (commit0_valid && (commit0_pc == STORE_PC))
          store_commit_count = store_commit_count + 1;
        if (commit0_valid && (commit0_pc == LOAD_PC)) begin
          load_commit_count = load_commit_count + 1;
          if (commit0_data !== STORE_DATA) load_commit_data_ok = 1'b0;
        end
        if (commit1_valid && (commit1_pc == LOAD_PC)) begin
          load_commit_count = load_commit_count + 1;
          if (commit1_data !== STORE_DATA) load_commit_data_ok = 1'b0;
        end
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S1 SQ-forward store commits exactly once",
                 store_commit_count, 32'd1);
      tb_check32("S1 SQ-forward load commits exactly once",
                 load_commit_count, 32'd1);
      tb_check1("S1 SQ-forward commit data exact", load_commit_data_ok, 1'b1);
      tb_check32("S1 SQ-forward ROB drained", {27'b0, rob_count}, 32'd0);
      tb_check32("S1 SQ-forward SQ drained",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[S1-SQ-FORWARD-BYPASS] block=1 fwd=1 local-WB/commit exactly-once PASS");
      reset_dut();
    end
  endtask

  // T4S：FP capacity 只观察 class/payload intent；packet valid 仅在 actual
  // accept 处控制状态更新。定向保留 invalid FP-looking payload，证明它既不
  // 修改 FP rename/IQ/free-list/ROB，也不阻塞另一条合法 lane0 整数 uop。
  task automatic run_t4s_fp_raw_intent_state_isolation;
    reg [3:0] fp_iq_before;
    reg [FREE_COUNT_W-1:0] fp_free_before;
    reg [ROB_COUNT_W-1:0] rob_before;
    reg [ISSUE_COUNT_W-1:0] issue_before;
    reg [FREE_COUNT_W-1:0] int_free_before;
    reg [PHY_REG_ADDR_W-1:0] map7_before;
    reg [PHY_REG_ADDR_W-1:0] map8_before;
    begin
      reset_dut();
      fp_iq_before = dut.u_fp_backend.fp_iq_count_w;
      fp_free_before = dut.u_fp_backend.fp_free_count_w;
      rob_before = rob_count;
      issue_before = issue_count;
      int_free_before = free_count;
      map7_before = dut.u_fp_backend.fp_map_q[7];
      map8_before = dut.u_fp_backend.fp_map_q[8];

      set_fp_binary0(32'h8000_69c0, 7'b0000001,
                     5'd2, 5'd1, 5'd7, 1'b1);
      set_fp_binary1(32'h8000_69c4, 7'b0000001,
                     5'd4, 5'd3, 5'd8, 1'b1);
      dispatch0_valid = 1'b0;
      dispatch1_valid = 1'b0;
      #1;
      tb_check1("T4S invalid arithmetic keeps lane0 raw intent",
                dut.d0_fp_arith_w, 1'b1);
      tb_check1("T4S invalid arithmetic keeps lane1 raw intent",
                dut.d1_fp_arith_w, 1'b1);
      tb_check1("T4S invalid arithmetic no DBE lane0 fire",
                dut.dispatch0_fire_w, 1'b0);
      tb_check1("T4S invalid arithmetic no DBE lane1 fire",
                dut.dispatch1_fire_w, 1'b0);
      tb_check1("T4S invalid arithmetic no FP lane0 fire",
                dut.u_fp_backend.disp_fire_w, 1'b0);
      tb_check1("T4S invalid arithmetic no FP lane1 fire",
                dut.u_fp_backend.disp1_fire_w, 1'b0);
      tb_check1("T4S invalid arithmetic no lane0 allocation",
                dut.u_fp_backend.alloc0_valid_w, 1'b0);
      tb_check1("T4S invalid arithmetic no lane1 allocation",
                dut.u_fp_backend.alloc1_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("T4S invalid arithmetic FP IQ unchanged",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w},
                 {28'b0, fp_iq_before});
      tb_check32("T4S invalid arithmetic FP free-list unchanged",
                 {25'b0, dut.u_fp_backend.fp_free_count_w},
                 {25'b0, fp_free_before});
      tb_check32("T4S invalid arithmetic ROB unchanged",
                 {27'b0, rob_count}, {27'b0, rob_before});
      tb_check32("T4S invalid arithmetic integer IQ unchanged",
                 {28'b0, issue_count}, {28'b0, issue_before});
      tb_check32("T4S invalid arithmetic integer free-list unchanged",
                 {25'b0, free_count}, {25'b0, int_free_before});
      tb_check32("T4S invalid arithmetic lane0 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[7]},
                 {26'b0, map7_before});
      tb_check32("T4S invalid arithmetic lane1 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[8]},
                 {26'b0, map8_before});

      clear_dispatch();
      set_dispatch0(32'h8000_69c8,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h8000_0200);
      dispatch0_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd7,
                        `OPCODE_LOAD_FP};
      dispatch0_is_fp = 1'b1;
      dispatch0_fp_load = 1'b1;
      dispatch0_fp_double = 1'b1;
      dispatch0_valid = 1'b0;
      set_dispatch1(32'h8000_69cc,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'h8000_0208);
      dispatch1_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd8,
                        `OPCODE_LOAD_FP};
      dispatch1_is_fp = 1'b1;
      dispatch1_fp_load = 1'b1;
      dispatch1_fp_double = 1'b1;
      dispatch1_valid = 1'b0;
      #1;
      tb_check1("T4S invalid load keeps lane0 raw intent",
                dut.u_fp_backend.fpld0_alloc_valid_i, 1'b1);
      tb_check1("T4S invalid load keeps lane1 raw intent",
                dut.u_fp_backend.fpld1_alloc_valid_i, 1'b1);
      tb_check1("T4S invalid load no lane0 fire",
                dut.u_fp_backend.fpld0_fire_w, 1'b0);
      tb_check1("T4S invalid load no lane1 fire",
                dut.u_fp_backend.fpld1_fire_w, 1'b0);
      tb_check1("T4S invalid load no lane0 allocation",
                dut.u_fp_backend.alloc0_valid_w, 1'b0);
      tb_check1("T4S invalid load no lane1 allocation",
                dut.u_fp_backend.alloc1_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("T4S invalid load FP IQ unchanged",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w},
                 {28'b0, fp_iq_before});
      tb_check32("T4S invalid load FP free-list unchanged",
                 {25'b0, dut.u_fp_backend.fp_free_count_w},
                 {25'b0, fp_free_before});
      tb_check32("T4S invalid load ROB unchanged",
                 {27'b0, rob_count}, {27'b0, rob_before});
      tb_check32("T4S invalid load lane0 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[7]},
                 {26'b0, map7_before});
      tb_check32("T4S invalid load lane1 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[8]},
                 {26'b0, map8_before});

      clear_dispatch();
      set_dispatch0(32'h8000_69d0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_69d4,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'h8000_0210);
      dispatch1_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd8,
                        `OPCODE_LOAD_FP};
      dispatch1_is_fp = 1'b1;
      dispatch1_fp_load = 1'b1;
      dispatch1_fp_double = 1'b1;
      dispatch1_valid = 1'b0;
      #1;
      tb_check1("T4S invalid lane1 load keeps raw intent",
                dut.u_fp_backend.fpld1_alloc_valid_i, 1'b1);
      tb_check1("T4S valid integer lane0 remains ready",
                dispatch0_ready, 1'b1);
      tb_check1("T4S valid integer lane0 fires",
                dut.dispatch0_fire_w, 1'b1);
      tb_check1("T4S invalid FP-looking lane1 does not fire",
                dut.dispatch1_fire_w, 1'b0);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T4S valid integer adds exactly one ROB entry",
                 {27'b0, rob_count}, {27'b0, rob_before} + 32'd1);
      tb_check32("T4S invalid lane1 keeps FP IQ unchanged",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w},
                 {28'b0, fp_iq_before});
      tb_check32("T4S invalid lane1 keeps FP free-list unchanged",
                 {25'b0, dut.u_fp_backend.fp_free_count_w},
                 {25'b0, fp_free_before});
      tb_check32("T4S invalid lane1 keeps FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[8]},
                 {26'b0, map8_before});
      $display("[T4S-FP-RAW-INTENT] invalid payload state isolation PASS");
      reset_dut();
    end
  endtask

  // T3C RED：通过合法 dispatch 把 FP IQ 填到 7/8。mandatory 双 FP pair 此时
  // 需要两个槽，必须整体阻塞；旧顶层却把 lane1 的 fp_ok=0 当成 valid=0 送给
  // DispatchBackend，导致 lane0 被误判成单发并单边改写 FP rename/IQ/ROB。
  task automatic run_t3c_fp_mandatory_pair_atomicity_red;
    reg [3:0] fp_iq_before;
    reg [FREE_COUNT_W-1:0] fp_free_before;
    reg [ROB_COUNT_W-1:0] rob_before;
    reg [PHY_REG_ADDR_W-1:0] map9_before;
    reg [PHY_REG_ADDR_W-1:0] map10_before;
    reg resource_recovered;
    integer lane0_fire_count;
    integer lane1_fire_count;
    integer wait_cycles;
    begin
      reset_dut();

      // f1 = FDIV.D f0,f0：真实 56-step 长操作，保证随后依赖 f1 的 FADD.D
      // 在填充阶段全部常驻 FP IQ，不依赖任何内部 force。
      set_fp_binary0(32'h8000_6a00, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      tb_check1("T3C FP seed FDIV dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3C FP seed enters IQ",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd1);
      tb_check1("T3Q FP seed selected at raw IQ boundary",
                dut.u_fp_backend.iq_issue_valid_w, 1'b1);
      tb_check1("T3Q FP issue stage is non-fallthrough",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);

      // 首对依赖者入队时，FDIV 同拍离开 IQ 进入 long-op：1 + 2 - 1 = 2。
      set_fp_binary0(32'h8000_6a10, 7'b0000001,
                     5'd0, 5'd1, 5'd2, 1'b1);
      set_fp_binary1(32'h8000_6a14, 7'b0000001,
                     5'd0, 5'd1, 5'd3, 1'b1);
      #1;
      tb_check1("T3C FP fill pair0 lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("T3C FP fill pair0 lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q FP seed captured in issue stage",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check1("T3Q FP seed not launched on capture edge",
                dut.u_fp_backend.long_meta_valid_q, 1'b0);
      tb_check32("T3C FP fill count two",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd2);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3C FP seed is long-op inflight",
                dut.u_fp_backend.long_meta_valid_q, 1'b1);
      tb_check1("T3C FP divider busy",
                dut.u_fp_backend.long_div_busy_w, 1'b1);
      tb_check32("T3C FP fill count two",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd2);

      set_fp_binary0(32'h8000_6a18, 7'b0000001,
                     5'd0, 5'd1, 5'd4, 1'b1);
      set_fp_binary1(32'h8000_6a1c, 7'b0000001,
                     5'd0, 5'd1, 5'd5, 1'b1);
      #1;
      tb_check1("T3C FP fill pair1 lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("T3C FP fill pair1 lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3C FP fill count four",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd4);

      set_fp_binary0(32'h8000_6a20, 7'b0000001,
                     5'd0, 5'd1, 5'd6, 1'b1);
      set_fp_binary1(32'h8000_6a24, 7'b0000001,
                     5'd0, 5'd1, 5'd7, 1'b1);
      #1;
      tb_check1("T3C FP fill pair2 lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("T3C FP fill pair2 lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3C FP fill count six",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd6);

      set_fp_binary0(32'h8000_6a28, 7'b0000001,
                     5'd0, 5'd1, 5'd8, 1'b1);
      #1;
      tb_check1("T3C FP fill single ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3C FP legal boundary is seven of eight",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd7);
      tb_check32("T3C FP boundary free count",
                 {25'b0, dut.u_fp_backend.fp_free_count_w}, 32'd24);
      tb_check32("T3C FP boundary ROB count",
                 {27'b0, rob_count}, 32'd8);

      // 保持同一 mandatory pair 的 raw-valid，模拟前端在 ready 前不得 pop。
      // 两条均写 FPR 且均依赖 f1；只剩一个 FP IQ slot 时必须 ready={0,0}。
      set_fp_binary0(32'h8000_6a30, 7'b0000001,
                     5'd0, 5'd1, 5'd9, 1'b1);
      set_fp_binary1(32'h8000_6a34, 7'b0000001,
                     5'd0, 5'd1, 5'd10, 1'b1);
      #1;
      fp_iq_before = dut.u_fp_backend.fp_iq_count_w;
      fp_free_before = dut.u_fp_backend.fp_free_count_w;
      rob_before = rob_count;
      map9_before = dut.u_fp_backend.fp_map_q[9];
      map10_before = dut.u_fp_backend.fp_map_q[10];
      lane0_fire_count = 0;
      lane1_fire_count = 0;
      resource_recovered = 1'b0;

      $display("[T3C-RED-OBS] blocked raw_fp_ready={%0b,%0b} top_ready={%0b,%0b} fp_fire={%0b,%0b} fp_iq=%0d fp_free=%0d rob=%0d",
               dut.fp_disp_ready_w, dut.fp_disp1_ready_w,
               dispatch0_ready, dispatch1_ready,
               dut.u_fp_backend.disp_fire_w,
               dut.u_fp_backend.disp1_fire_w,
               dut.u_fp_backend.fp_iq_count_w,
               dut.u_fp_backend.fp_free_count_w, rob_count);
      tb_check1("T3C mandatory pair blocks lane0", dispatch0_ready, 1'b0);
      tb_check1("T3C mandatory pair blocks lane1", dispatch1_ready, 1'b0);
      tb_check1("T3C mandatory pair no FP lane0 fire",
                dut.u_fp_backend.disp_fire_w, 1'b0);
      tb_check1("T3C mandatory pair no FP lane1 fire",
                dut.u_fp_backend.disp1_fire_w, 1'b0);

      if (dispatch0_valid && dispatch0_ready)
        lane0_fire_count = lane0_fire_count + 1;
      if (dispatch1_valid && dispatch1_ready)
        lane1_fire_count = lane1_fire_count + 1;
      `TB_TICK(clk);
      #1;

      $display("[T3C-RED-OBS] blocked-post fp_iq=%0d fp_free=%0d rob=%0d map9=%0d map10=%0d fires={%0d,%0d}",
               dut.u_fp_backend.fp_iq_count_w,
               dut.u_fp_backend.fp_free_count_w, rob_count,
               dut.u_fp_backend.fp_map_q[9],
               dut.u_fp_backend.fp_map_q[10],
               lane0_fire_count, lane1_fire_count);
      tb_check32("T3C blocked FP IQ state unchanged",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w},
                 {28'b0, fp_iq_before});
      tb_check32("T3C blocked FP free state unchanged",
                 {25'b0, dut.u_fp_backend.fp_free_count_w},
                 {25'b0, fp_free_before});
      tb_check32("T3C blocked ROB state unchanged",
                 {27'b0, rob_count}, {27'b0, rob_before});
      tb_check32("T3C blocked lane0 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[9]},
                 {26'b0, map9_before});
      tb_check32("T3C blocked lane1 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[10]},
                 {26'b0, map10_before});

      // raw-valid 保持到资源恢复。修复后，FDIV 完成并释放足够 IQ credit 后，
      // pair 应在同一拍恰好各接收一次；旧 RTL 会重复接收 lane0/饿死 lane1。
      wait_cycles = 0;
      while ((lane1_fire_count == 0) && (wait_cycles < 90)) begin
        if (dut.u_fp_backend.fp_iq_count_w <= 4'd6)
          resource_recovered = 1'b1;
        if (dispatch0_valid && dispatch0_ready)
          lane0_fire_count = lane0_fire_count + 1;
        if (dispatch1_valid && dispatch1_ready)
          lane1_fire_count = lane1_fire_count + 1;
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      clear_dispatch();
      #1;

      $display("[T3C-RED-OBS] recovery wait=%0d recovered=%0b fires={%0d,%0d} fp_iq=%0d fp_free=%0d rob=%0d map9=%0d map10=%0d",
               wait_cycles, resource_recovered,
               lane0_fire_count, lane1_fire_count,
               dut.u_fp_backend.fp_iq_count_w,
               dut.u_fp_backend.fp_free_count_w, rob_count,
               dut.u_fp_backend.fp_map_q[9],
               dut.u_fp_backend.fp_map_q[10]);
      tb_check1("T3C FP IQ resource eventually recovers",
                resource_recovered, 1'b1);
      tb_check32("T3C mandatory lane0 accepted exactly once",
                 lane0_fire_count, 32'd1);
      tb_check32("T3C mandatory lane1 accepted exactly once",
                 lane1_fire_count, 32'd1);
      tb_check1("T3C lane0 FP map updates after atomic accept",
                dut.u_fp_backend.fp_map_q[9] != map9_before, 1'b1);
      tb_check1("T3C lane1 FP map updates after atomic accept",
                dut.u_fp_backend.fp_map_q[10] != map10_before, 1'b1);

      // RED 之后清理长操作/队列，避免污染本文件既有回归；tb_errors 保留。
      reset_dut();
    end
  endtask

  // T3Q issue-packet 边界定向验证：全部场景只通过合法 dispatch/ROB 顺序构造，
  // 不 force 内部信号。更老 FDIV 持有 long 单元，使第二条 FDIV packet 在 stage
  // 自然反压；再分别碰撞全局 flush、older branch kill 与 younger branch kill。
  task automatic run_t3q_fp_issue_stage_contracts;
    reg [FP_ISSUE_PACKET_W-1:0] held_packet;
    reg [ROB_INDEX_W-1:0] held_rob;
    reg [ROB_INDEX_W-1:0] branch_rob;
    reg [ROB_INDEX_W-1:0] younger_fp_rob;
    reg [`INST_W-1:0] expected_inst;
    integer wait_cycles;
    integer hold_cycles;
    begin
      // ---------------------------------------------------------------------
      // A. long-op busy 必须让整包跨多个上升沿冻结；flush 当拍组合屏蔽，
      //    沿后只清 valid（payload 留脏不作检查）。
      // ---------------------------------------------------------------------
      reset_dut();
      set_fp_binary0(32'h8000_6b00, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      tb_check1("T3Q hold seed FDIV dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.long_div_busy_w &&
               dut.u_fp_backend.long_meta_valid_q) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q hold seed reaches long busy",
                dut.u_fp_backend.long_div_busy_w &&
                dut.u_fp_backend.long_meta_valid_q, 1'b1);

      expected_inst = inst_op_fp(7'b0001101, 5'd0, 5'd0, 3'b000, 5'd2);
      set_fp_binary0(32'h8000_6b04, 7'b0001101,
                     5'd0, 5'd0, 5'd2, 1'b1);
      #1;
      tb_check1("T3Q held FDIV dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.fp_issue_stage_valid_w &&
               (dut.u_fp_backend.issue_inst_w === expected_inst)) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q held FDIV reaches issue stage",
                dut.u_fp_backend.fp_issue_stage_valid_w &&
                (dut.u_fp_backend.issue_inst_w === expected_inst), 1'b1);
      tb_check1("T3Q held FDIV is backpressured",
                dut.u_fp_backend.issue_ready_w, 1'b0);
      tb_check1("T3Q held FDIV does not launch",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      held_packet = dut.u_fp_backend.fp_issue_stage_down_payload_w;
      held_rob = dut.u_fp_backend.issue_rob_idx_w;

      for (hold_cycles = 0; hold_cycles < 3;
           hold_cycles = hold_cycles + 1) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        tb_check1("T3Q long busy keeps stage valid",
                  dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
        tb_check1("T3Q long busy keeps stage stalled",
                  dut.u_fp_backend.issue_ready_w, 1'b0);
        tb_check1("T3Q stalled packet cannot launch",
                  dut.u_fp_backend.issue_fire_w, 1'b0);
        tb_check_fp_issue_packet("T3Q stalled payload remains frozen",
            dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      end
      $display("[T3Q-FP-STAGE-HOLD] cycles=%0d rob=%0d packet=0x%0h",
               hold_cycles, held_rob, held_packet);

      flush = 1'b1;
      #1;
      tb_check1("T3Q flush collision retains raw q before edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check1("T3Q flush masks visible issue immediately",
                dut.u_fp_backend.issue_valid_w, 1'b0);
      tb_check1("T3Q flush forbids issue launch",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      tb_check1("T3Q flush forbids IQ refill/pop",
                dut.u_fp_backend.iq_issue_ready_w, 1'b0);
      tb_check_fp_issue_packet("T3Q flush collision preserves pre-edge packet",
          dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q flush clears issue stage after edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);
      tb_check1("T3Q flush clears long metadata",
                dut.u_fp_backend.long_meta_valid_q, 1'b0);
      $display("[T3Q-FP-STAGE-FLUSH] raw_before=1 masked_before=1 raw_after=%0b",
               dut.u_fp_backend.fp_issue_stage_valid_w);

      // ---------------------------------------------------------------------
      // B. branch(ROB1) 与 younger FDIV(ROB2) 同包进入各自 IQ；两条边界同拍
      //    捕获后，resolve q 的合法 kill 必须组合屏蔽并沿清 younger packet。
      //    更老、已在飞的 seed FDIV(ROB0)必须继续存活。
      // ---------------------------------------------------------------------
      reset_dut();
      set_fp_binary0(32'h8000_6b20, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      tb_check1("T3Q younger-kill seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.long_div_busy_w &&
               dut.u_fp_backend.long_meta_valid_q) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q younger-kill seed reaches long busy",
                dut.u_fp_backend.long_div_busy_w &&
                dut.u_fp_backend.long_meta_valid_q, 1'b1);

      set_dispatch0(32'h8000_6b24, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_bht_idx = 10'h2d1;
      set_fp_binary1(32'h8000_6b28, 7'b0001101,
                     5'd0, 5'd0, 5'd2, 1'b1);
      expected_inst = inst_op_fp(7'b0001101, 5'd0, 5'd0, 3'b000, 5'd2);
      #1;
      tb_check1("T3Q younger-kill branch dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("T3Q younger-kill FP dispatch ready",
                dispatch1_ready, 1'b1);
      branch_rob = dut.dispatch0_rob_idx_w;
      younger_fp_rob = dut.dispatch1_rob_idx_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q younger-kill branch issues legally",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check1("T3Q younger-kill FP selected at raw IQ boundary",
                dut.u_fp_backend.iq_issue_valid_w, 1'b1);
      tb_check1("T3Q younger-kill stage still non-fallthrough",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q younger-kill resolve q valid", branch_resolve_valid, 1'b1);
      tb_check1("T3Q younger-kill resolve is mispredict",
                branch_resolve_mispredict, 1'b1);
      tb_check32("T3Q younger-kill branch ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
                 {{(32-ROB_INDEX_W){1'b0}}, branch_rob});
      tb_check1("T3Q younger packet captured before kill edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check32("T3Q younger packet keeps ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.u_fp_backend.issue_rob_idx_w},
                 {{(32-ROB_INDEX_W){1'b0}}, younger_fp_rob});
      tb_check32("T3Q younger packet keeps instruction",
                 dut.u_fp_backend.issue_inst_w, expected_inst);
      tb_check1("T3Q staged FP is younger than branch",
                ((younger_fp_rob - dut.rob_head_idx_w) >
                 (branch_rob - dut.rob_head_idx_w)), 1'b1);
      tb_check1("T3Q younger packet is kill hit",
                dut.u_fp_backend.fp_issue_stage_kill_w, 1'b1);
      tb_check1("T3Q younger kill masks visible issue",
                dut.u_fp_backend.issue_valid_w, 1'b0);
      tb_check1("T3Q younger kill forbids launch",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      tb_check1("T3Q younger kill forbids IQ refill/pop",
                dut.u_fp_backend.iq_issue_ready_w, 1'b0);
      tb_check1("T3Q older long metadata survives kill collision",
                dut.u_fp_backend.long_meta_valid_q, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q younger packet clears after kill edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);
      tb_check1("T3Q older long metadata survives younger kill",
                dut.u_fp_backend.long_meta_valid_q, 1'b1);
      tb_check1("T3Q older long operation remains busy",
                dut.u_fp_backend.long_div_busy_w, 1'b1);
      $display("[T3Q-FP-STAGE-KILL-YOUNGER] branch_rob=%0d fp_rob=%0d raw_after=%0b older_long=%0b",
               branch_rob, younger_fp_rob,
               dut.u_fp_backend.fp_issue_stage_valid_w,
               dut.u_fp_backend.long_meta_valid_q);

      // ---------------------------------------------------------------------
      // C. held FDIV(ROB1) 比 mispredict branch(ROB2) 更老。kill 拍仍须组合
      //    屏蔽执行/refill，但年龄 miss 不得清 packet；kill 沿后 payload 继续 hold。
      // ---------------------------------------------------------------------
      reset_dut();
      set_fp_binary0(32'h8000_6b40, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      tb_check1("T3Q older-survivor seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.long_div_busy_w &&
               dut.u_fp_backend.long_meta_valid_q) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q older-survivor seed reaches long busy",
                dut.u_fp_backend.long_div_busy_w &&
                dut.u_fp_backend.long_meta_valid_q, 1'b1);

      expected_inst = inst_op_fp(7'b0001101, 5'd0, 5'd0, 3'b000, 5'd2);
      set_fp_binary0(32'h8000_6b44, 7'b0001101,
                     5'd0, 5'd0, 5'd2, 1'b1);
      #1;
      tb_check1("T3Q older-survivor held FP dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.fp_issue_stage_valid_w &&
               (dut.u_fp_backend.issue_inst_w === expected_inst)) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q older-survivor packet reaches stage",
                dut.u_fp_backend.fp_issue_stage_valid_w &&
                (dut.u_fp_backend.issue_inst_w === expected_inst), 1'b1);
      held_packet = dut.u_fp_backend.fp_issue_stage_down_payload_w;
      held_rob = dut.u_fp_backend.issue_rob_idx_w;

      set_dispatch0(32'h8000_6b48, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_bht_idx = 10'h16e;
      #1;
      tb_check1("T3Q older-survivor branch dispatch ready",
                dispatch0_ready, 1'b1);
      branch_rob = dut.dispatch0_rob_idx_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q older-survivor branch issues legally",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check_fp_issue_packet("T3Q packet holds while branch issues",
          dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q older-survivor resolve q valid",
                branch_resolve_valid, 1'b1);
      tb_check1("T3Q older-survivor resolve is mispredict",
                branch_resolve_mispredict, 1'b1);
      tb_check32("T3Q older-survivor branch ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
                 {{(32-ROB_INDEX_W){1'b0}}, branch_rob});
      tb_check1("T3Q survivor is older than branch",
                ((held_rob - dut.rob_head_idx_w) <
                 (branch_rob - dut.rob_head_idx_w)), 1'b1);
      tb_check1("T3Q older packet is kill miss",
                dut.u_fp_backend.fp_issue_stage_kill_w, 1'b0);
      tb_check1("T3Q kill still masks older visible issue",
                dut.u_fp_backend.issue_valid_w, 1'b0);
      tb_check1("T3Q older survivor cannot launch on kill",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      tb_check1("T3Q older survivor raw stage stays valid",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check_fp_issue_packet("T3Q older survivor packet stable on kill",
          dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q older survivor remains after kill edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check1("T3Q older survivor visible again after kill",
                dut.u_fp_backend.issue_valid_w, 1'b1);
      tb_check1("T3Q older survivor remains backpressured",
                dut.u_fp_backend.issue_ready_w, 1'b0);
      tb_check1("T3Q older survivor still cannot launch",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      tb_check_fp_issue_packet("T3Q older survivor payload holds after kill",
          dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      $display("[T3Q-FP-STAGE-KILL-OLDER-SURVIVOR] fp_rob=%0d branch_rob=%0d raw_after=%0b payload=0x%0h",
               held_rob, branch_rob,
               dut.u_fp_backend.fp_issue_stage_valid_w, held_packet);

      reset_dut();
    end
  endtask

  // T3S：lane0 memory reservation 必须是严格 non-fallthrough 边界。
  // bridge backpressure 时 reservation payload 保持，IQ raw lane0 不得借
  // 同拍 down-ready replacement 离队；flush 必须在产生副作用前清空。
  task automatic run_t3s_mem_issue_reservation_contract;
    reg [`XLEN-1:0] held_pc;
    reg [`XLEN-1:0] held_imm;
    reg [`CTRL_BUS_W-1:0] held_ctrl;
    reg [ROB_INDEX_W-1:0] held_rob;
    reg [ROB_INDEX_W-1:0] younger_rob;
    integer hold_cycles;
    integer younger_fire_count;
    integer younger_commit_count;
    integer younger_wb_count;
    integer observe_cycles;
    begin
      reset_dut();
      younger_fire_count = 0;
      younger_commit_count = 0;
      younger_wb_count = 0;
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6c00,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h8000_0310);
      #1;
      tb_check1("T3S hold seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3S hold seed capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check1("T3S hold seed no early request", mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3S hold reservation valid",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("T3S hold request valid under bridge stall",
                mem_req_valid, 1'b1);
      tb_check1("T3S occupied reservation freezes IQ lane0",
                dut.iq_issue0_ready_w, 1'b0);
      tb_check32("T3S held request address", mem_req_addr[31:0],
                 32'h8000_0310);
      held_pc = dut.mem_issue_res_pc_q;
      held_imm = dut.mem_issue_res_imm_q;
      held_ctrl = dut.mem_issue_res_ctrl_q;
      held_rob = dut.mem_issue_res_rob_idx_q;

      // younger simple 可进入 IQ，但 reservation 占用期间 raw lane0 不得 pop。
      set_dispatch0(32'h8000_6c04,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'd9);
      #1;
      tb_check1("T3S younger dispatch while reservation held",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3S younger enters IQ while held",
                 {28'b0, issue_count}, 32'd1);
      // T3V：resident memory reservation 是虚拟 lane0 owner。IQ 的 raw lane0
      // 必须保持安静，但 oldest-ready simple integer 可从真实 lane1 前进。
      tb_check1("T3V held memory excludes raw IQ lane0 owner",
                dut.iq_issue0_valid_w, 1'b0);
      tb_check1("T3V held memory promotes younger simple to lane1",
                dut.issue1_valid_w, 1'b1);
      tb_check1("T3V promoted younger lane1 is fireable",
                dut.issue1_fire_w, 1'b1);
      tb_check32("T3V promoted younger lane1 keeps PC",
                 dut.issue1_pc_w[31:0], 32'h8000_6c04);
      tb_check64("T3V promoted younger lane1 computes nine",
                 dut.issue1_alu_result_w, 64'd9);
      younger_rob = dut.issue1_rob_idx_w;
      tb_check64("T3V dedicated memory AGU ignores lane1 ALU",
                 dut.mem_issue_res_eff_addr_w, 64'h8000_0310);
      for (hold_cycles = 0; hold_cycles < 3;
           hold_cycles = hold_cycles + 1) begin
        tb_check1("T3S stalled reservation remains valid",
                  dut.mem_issue_res_valid_q, 1'b1);
        tb_check1("T3S stalled reservation keeps raw IQ lane0 frozen",
                  dut.iq_issue0_ready_w, 1'b0);
        tb_check64("T3S stalled reservation PC stable",
                   dut.mem_issue_res_pc_q, held_pc);
        tb_check64("T3S stalled reservation imm stable",
                   dut.mem_issue_res_imm_q, held_imm);
        tb_check32("T3S stalled reservation ROB stable",
                   {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q},
                   {{(32-ROB_INDEX_W){1'b0}}, held_rob});
        tb_check64("T3V stalled request remains reservation AGU owned",
                   mem_req_addr, 64'h8000_0310);
        if (dut.mem_issue_res_ctrl_q !== held_ctrl) begin
          $display("[CHECK-FAIL] T3S stalled reservation ctrl changed got=0x%0h expected=0x%0h",
                   dut.mem_issue_res_ctrl_q, held_ctrl);
          tb_errors = tb_errors + 1;
        end
        if (dut.issue0_fire_w &&
            (dut.issue0_pc_w[31:0] == 32'h8000_6c04))
          younger_fire_count = younger_fire_count + 1;
        if (dut.issue1_fire_w &&
            (dut.issue1_pc_w[31:0] == 32'h8000_6c04))
          younger_fire_count = younger_fire_count + 1;
        `TB_TICK(clk);
        #1;
        if (dut.wb0_valid_w && (dut.wb0_rob_idx_w == younger_rob)) begin
          younger_wb_count = younger_wb_count + 1;
          tb_check64("T3V promoted younger WB0 data", dut.wb0_data_w, 64'd9);
        end
        if (dut.wb1_valid_w && (dut.wb1_rob_idx_w == younger_rob)) begin
          younger_wb_count = younger_wb_count + 1;
          tb_check64("T3V promoted younger WB1 data", dut.wb1_data_w, 64'd9);
        end
        tb_check1("T3V younger WB cannot pass older load",
                  commit0_valid || commit1_valid, 1'b0);
      end
      tb_check32("T3V promoted younger leaves IQ while held",
                 {28'b0, issue_count}, 32'd0);
      tb_check1("T3V raw IQ lane0 remains quiet after promotion",
                dut.iq_issue0_valid_w, 1'b0);
      tb_check1("T3V lane1 does not replay promoted younger",
                dut.issue1_valid_w, 1'b0);
      tb_check32("T3V promoted younger writes back exactly once while held",
                 younger_wb_count, 32'd1);

      mem_req_ready = 1'b1;
      #1;
      tb_check1("T3S held request becomes fireable", mem_req_valid, 1'b1);
      tb_check1("T3V reservation owns MIQ push", dut.push_issue0_w, 1'b1);
      tb_check32("T3V MIQ metadata uses captured ROB",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_push_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, held_rob});
      tb_check64("T3V MIQ address uses dedicated AGU",
                 dut.miq_push_addr_w, 64'h8000_0310);
      tb_check1("T3V memory consume excludes generic issue0 fire",
                dut.issue0_fire_w, 1'b0);
      tb_check1("T3V memory consume has no younger lane1 replay",
                dut.issue1_fire_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3S consumed reservation clears",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("T3S no same-cycle full-pop refill",
                dut.mem_issue_res_capture_w, 1'b0);
      // younger 已在 reservation hold 窗口从 lane1 exactly-once 执行；station
      // 释放后不能在 lane0/lane1 重新出现，也不能越过未完成的 older load 提交。
      if (dut.wb0_valid_w && (dut.wb0_rob_idx_w == younger_rob)) begin
        younger_wb_count = younger_wb_count + 1;
        tb_check64("T3V no duplicate younger WB0 after release",
                   dut.wb0_data_w, 64'd9);
      end
      if (dut.wb1_valid_w && (dut.wb1_rob_idx_w == younger_rob)) begin
        younger_wb_count = younger_wb_count + 1;
        tb_check64("T3V no duplicate younger WB1 after release",
                   dut.wb1_data_w, 64'd9);
      end
      tb_check32("T3V released station keeps younger out of IQ",
                 {28'b0, issue_count}, 32'd0);
      tb_check1("T3V released station has no lane0 replay",
                dut.issue0_valid_w || dut.issue0_fire_w, 1'b0);
      tb_check1("T3V released station has no lane1 replay",
                dut.issue1_valid_w || dut.issue1_fire_w, 1'b0);
      tb_check32("T3V younger WB remains exactly once after release",
                 younger_wb_count, 32'd1);
      tb_check1("T3V younger formal WB cannot pass older load",
                commit0_valid || commit1_valid, 1'b0);

      // Complete the older load only after the younger ALU has written back.
      // ROB ordering may expose the younger commit on either commit lane beside
      // the load, so count by PC rather than assuming a fixed lane.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0123_4567_89ab_cdef;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3V older load response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3V older response formal WB has no Q commit",
                commit0_valid || commit1_valid, 1'b0);
      if (commit0_valid && (commit0_pc[31:0] == 32'h8000_6c04)) begin
        younger_commit_count = younger_commit_count + 1;
        tb_check64("T3V younger commit0 data", commit0_data, 64'd9);
      end
      if (commit1_valid && (commit1_pc[31:0] == 32'h8000_6c04)) begin
        younger_commit_count = younger_commit_count + 1;
        tb_check64("T3V younger commit1 data", commit1_data, 64'd9);
      end
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      for (observe_cycles = 0; observe_cycles < 4;
           observe_cycles = observe_cycles + 1) begin
        if (dut.issue0_fire_w &&
            (dut.issue0_pc_w[31:0] == 32'h8000_6c04))
          younger_fire_count = younger_fire_count + 1;
        if (dut.issue1_fire_w &&
            (dut.issue1_pc_w[31:0] == 32'h8000_6c04))
          younger_fire_count = younger_fire_count + 1;
        if (dut.wb0_valid_w && (dut.wb0_rob_idx_w == younger_rob)) begin
          younger_wb_count = younger_wb_count + 1;
          tb_check64("T3V younger later WB0 data", dut.wb0_data_w, 64'd9);
        end
        if (dut.wb1_valid_w && (dut.wb1_rob_idx_w == younger_rob)) begin
          younger_wb_count = younger_wb_count + 1;
          tb_check64("T3V younger later WB1 data", dut.wb1_data_w, 64'd9);
        end
        if (commit0_valid && (commit0_pc[31:0] == 32'h8000_6c04)) begin
          younger_commit_count = younger_commit_count + 1;
          tb_check64("T3V younger later commit0 data", commit0_data, 64'd9);
        end
        if (commit1_valid && (commit1_pc[31:0] == 32'h8000_6c04)) begin
          younger_commit_count = younger_commit_count + 1;
          tb_check64("T3V younger later commit1 data", commit1_data, 64'd9);
        end
        `TB_TICK(clk);
        #1;
      end
      tb_check32("T3V younger fires exactly once",
                 younger_fire_count, 32'd1);
      tb_check32("T3V younger writes back exactly once",
                 younger_wb_count, 32'd1);
      tb_check32("T3V younger commits exactly once",
                 younger_commit_count, 32'd1);
      tb_check32("T3V release sequence drains ROB",
                 {27'b0, rob_count}, 32'd0);
      $display("[T3V-MEM-RES-RELEASE] younger_fire=%0d younger_wb=%0d younger_commit=%0d",
               younger_fire_count, younger_wb_count, younger_commit_count);
      $display("[T3S-MEM-RES-HOLD] cycles=%0d rob=%0d addr=0x%08h younger_iq=%0d",
               hold_cycles, held_rob, held_imm[31:0], issue_count);

      // 独立复位后建立一个未请求 reservation，flush 必须无副作用清除。
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6c10,
                    make_store_ctrl(`MEM_SIZE_WORD),
                    5'd0, 5'd0, 5'd0, 64'h8000_0320);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3S flush seed capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3S flush seed reservation valid",
                dut.mem_issue_res_valid_q, 1'b1);
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      mem_req_ready = 1'b1;
      #1;
      tb_check1("T3S flush clears reservation",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("T3S flush prevents request side effect", mem_req_valid, 1'b0);
      $display("[T3S-MEM-RES-FLUSH] valid=%0b req=%0b",
               dut.mem_issue_res_valid_q, mem_req_valid);
      reset_dut();
    end
  endtask

  // T3T 活性反例：younger memory 不得越过 IQ 中任何 older valid 项进入
  // reservation。这样 station 不会挡住稍后 wake 的 older branch，backend 也
  // 无需让 raw IQ 动态选择 resident execution owner。AMO/LR 仍叠加 ROB-head
  // admission，覆盖 older 已离开 IQ、但尚未完成退休的窗口。
  task automatic run_t3s_mem_issue_age_liveness;
    integer wait_cycles;
    begin
      // predicted-correct：branch 未 ready 时 younger load 必须留在 IQ；branch
      // fire 后 load 才可晋升并在下一沿进入 station。
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6d00,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_6d04, make_branch_ctrl(`CMP_OP_EQ),
                    5'd5, 5'd0, 5'd0, 64'd8);
      dispatch1_pred_npc = 64'h8000_6d08;
      dispatch1_pred_taken = 1'b0;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3S age producer owns lane0",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6d00);

      set_dispatch0(32'h8000_6d08,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h8000_0330);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3T younger load blocked by older branch",
                dut.mem_issue_res_capture_w, 1'b0);
      tb_check1("R3.2 older branch is the execution owner",
                dut.issue0_valid_w, 1'b1);
      tb_check32("T3T branch-load pair remains in IQ",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("T3T no premature station before branch",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check32("T3T older branch owns lane0 first",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6d04);
      tb_check32("T3T execution mux selects older branch",
                 dut.issue0_pc_w[31:0], 32'h8000_6d04);
      tb_check1("T3T older branch sees shallow IQ ready",
                dut.iq_issue0_ready_w, 1'b1);
      tb_check1("T3T older branch fires",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check1("T3T branch cycle emits no memory request",
                mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3T correct branch resolve emitted",
                branch_resolve_valid, 1'b1);
      tb_check1("T3T correct branch does not squash load",
                branch_resolve_mispredict, 1'b0);
      tb_check1("T3T load promotes only after branch pop",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check32("T3T promoted load identity",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6d08);
      `TB_TICK(clk);
      #1;
      tb_check1("T3T promoted load enters reservation",
                dut.mem_issue_res_valid_q, 1'b1);
      $display("[T3T-MEM-RES-OLDEST-CORRECT] branch=0x%08h resident=0x%08h",
               32'h8000_6d04, dut.mem_issue_res_pc_q[31:0]);

      // predicted-wrong：younger load 从未进入 station，resolve 直接从 IQ kill，
      // 当拍与下一拍都不得出现 ghost memory request。
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6d20,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_6d24, make_branch_ctrl(`CMP_OP_EQ),
                    5'd5, 5'd0, 5'd0, 64'd8);
      dispatch1_pred_npc = 64'h8000_6d2c;
      dispatch1_pred_taken = 1'b1;
      `TB_TICK(clk);
      clear_dispatch();
      set_dispatch0(32'h8000_6d28,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h8000_0340);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3T wrong-path load remains blocked",
                dut.mem_issue_res_capture_w, 1'b0);
      tb_check1("T3T wrong-path branch fires first",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check1("T3T wrong-path load never entered station",
                dut.mem_issue_res_valid_q, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3T mispredict resolve emitted",
                branch_resolve_mispredict, 1'b1);
      tb_check1("T3T mispredict masks younger execution",
                dut.issue0_valid_w, 1'b0);
      tb_check1("T3T mispredict exposes no ghost request",
                mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3T mispredict keeps station empty",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check32("T3T mispredict removes wrong-path IQ entry",
                 {28'b0, issue_count}, 32'd0);
      $display("[T3T-MEM-RES-OLDEST-MISPREDICT] valid=%0b req=%0b",
               dut.mem_issue_res_valid_q, mem_req_valid);

      // Exact LR contract：IQ oldest gate 先挡住 older branch，branch pop 后又由
      // AMO-head gate 等待退休边界；两层准入均不得 pop/capture LR。
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6d40,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_6d44, make_branch_ctrl(`CMP_OP_EQ),
                    5'd5, 5'd0, 5'd0, 64'd8);
      dispatch1_pred_npc = 64'h8000_6d48;
      dispatch1_pred_taken = 1'b0;
      `TB_TICK(clk);
      clear_dispatch();
      set_dispatch0(32'h8000_6d48,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd7, 64'h8000_0350);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd7);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3T LR blocked behind older branch",
                dut.mem_issue_res_capture_w, 1'b0);
      tb_check32("T3T older branch owns lane0 before LR",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6d44);
      tb_check1("T3T older branch fires before LR",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      wait_cycles = 0;
      while (!dut.mem_issue_res_capture_w && (wait_cycles < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3T LR eventually admitted at ROB head",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check1("T3T LR admission sees valid ROB head",
                dut.rob_head_valid_w, 1'b1);
      tb_check32("T3T LR raw ROB equals head",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.iq_issue0_rob_idx_w},
                 {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w});
      `TB_TICK(clk);
      #1;
      tb_check1("T3T head LR enters reservation",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check32("T3T resident LR remains ROB head",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q},
                 {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w});
      $display("[T3T-MEM-RES-AMO-HEAD] wait=%0d rob=%0d",
               wait_cycles, dut.mem_issue_res_rob_idx_q);
      reset_dut();
    end
  endtask

  // T3V post-reservation buffer 也必须参加 selective ROB-walk kill。buffer
  // handoff 由合法的 older LEGACY LR pending + younger plain load 自然构造；只对白盒
  // delayed resolve pulse 做层次注入，以命中“buffer 已驻留但尚未 fire”的窗口。
  task automatic run_t3v_mem_buffer_selective_kill_contract;
    reg [ROB_INDEX_W-1:0] buffer_rob;
    integer quiet_cycles;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;

      // LR remains the intentional LEGACY singleton owner.  Plain loads no
      // longer become LEGACY merely because their VA resembles MMIO.
      set_dispatch0(32'h8000_6d60,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd10, 64'h0000_0200);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd10);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V buffer-kill seed capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill seed request visible", mem_req_valid, 1'b1);
      tb_check1("T3V buffer-kill seed is LEGACY push",
                dut.miq_push_valid_w &&
                (dut.miq_push_kind_w == 2'd3), 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill seed pending", dut.mem_pending_q, 1'b1);
      tb_check32("T3V buffer-kill seed occupies one MIQ entry",
                 {28'b0, dut.miq_count_w}, 32'd1);

      // Keep this correctly predicted branch in ROB as an older selective-kill
      // boundary.  commit_ready=0 prevents it from retiring before injection.
      set_dispatch0(32'h8000_6d64, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_pred_taken = 1'b1;
      dispatch0_pred_npc = 64'h8000_6d6c;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V buffer-kill older branch fires",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      t3v_force_branch_rob = dut.issue0_rob_idx_w;
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill older branch resolves",
                branch_resolve_valid, 1'b1);
      tb_check1("T3V buffer-kill seed resolve is initially correct",
                branch_resolve_mispredict, 1'b0);
      `TB_TICK(clk);
      #1;

      // A younger plain store consumes its reservation into mem_buffer because
      // the older LEGACY request remains pending.  No bridge request fires.
      set_dispatch0(32'h8000_6d68,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h8000_03c0);
      dispatch0_inst = 32'h0000_3023;  // sd x0,0(x0)
      #1;
      buffer_rob = dut.dispatch0_rob_idx_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V buffer-kill younger capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill real buffer handoff",
                dut.issue0_mem_buffer_fire_w, 1'b1);
      tb_check1("T3V buffer-kill handoff has no request",
                dut.mem_req_fire_any_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill younger resident in buffer",
                dut.mem_buffer_valid_q, 1'b1);
      tb_check32("T3V buffer-kill buffer ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_buffer_rob_idx_q},
                 {{(32-ROB_INDEX_W){1'b0}}, buffer_rob});
      tb_check64("T3V buffer-kill buffer address",
                 dut.mem_buffer_eff_addr_q, 64'h8000_03c0);
      tb_check1("T3V buffer-kill buffer still cannot request",
                dut.mem_buffer_req_valid_w, 1'b0);

      // Inject a delayed mispredict for the still-resident older branch.  This
      // is intentionally white-box only at the resolve boundary; ROB ages,
      // reservation->buffer handoff, and all memory ownership are real.
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      #1;
      tb_check1("T3V buffer-kill recognizes younger buffer",
                dut.mem_buffer_kill_w, 1'b1);
      tb_check1("T3V buffer-kill non-fired window",
                dut.mem_buffer_req_fire_w, 1'b0);
      tb_check1("T3V buffer-kill injects no MIQ owner",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      tb_check1("T3V buffer-kill clears younger buffer",
                dut.mem_buffer_valid_q, 1'b0);
      tb_check32("T3V buffer-kill preserves older MIQ only",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("T3V buffer-kill exposes no request after kill",
                mem_req_valid, 1'b0);

      // Retire the old LEGACY response, opening the slot.  A surviving ghost
      // buffer would now request immediately, so observe several quiet cycles.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0000_0000_cafe_babe;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3V buffer-kill old response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      commit_ready = 1'b1;
      #1;
      tb_check32("T3V buffer-kill old MIQ drains",
                 {28'b0, dut.miq_count_w}, 32'd0);
      for (quiet_cycles = 0; quiet_cycles < 4;
           quiet_cycles = quiet_cycles + 1) begin
        tb_check1("T3V buffer-kill no ghost request", mem_req_valid, 1'b0);
        tb_check1("T3V buffer-kill no ghost MIQ push",
                  dut.miq_push_valid_w, 1'b0);
        tb_check1("T3V buffer-kill no ghost WB0",
                  !(dut.wb0_valid_w &&
                    (dut.wb0_rob_idx_w == buffer_rob)), 1'b1);
        tb_check1("T3V buffer-kill no ghost WB1",
                  !(dut.wb1_valid_w &&
                    (dut.wb1_rob_idx_w == buffer_rob)), 1'b1);
        tb_check1("T3V buffer-kill no ghost commit0",
                  !(commit0_valid &&
                    (commit0_pc[31:0] == 32'h8000_6d68)), 1'b1);
        tb_check1("T3V buffer-kill no ghost commit1",
                  !(commit1_valid &&
                    (commit1_pc[31:0] == 32'h8000_6d68)), 1'b1);
        `TB_TICK(clk);
        #1;
      end
      $display("[T3V-MEM-BUFFER-KILL] boundary_rob=%0d killed_rob=%0d quiet_cycles=%0d",
               t3v_force_branch_rob, buffer_rob, quiet_cycles);
      reset_dut();
    end
  endtask

  task automatic seed_s2_g1_selective_kill_boundary;
    input [`XLEN-1:0] branch_pc;
    output [ROB_INDEX_W-1:0] boundary_rob;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;
      set_dispatch0(branch_pc, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_pred_taken = 1'b1;
      dispatch0_pred_npc = branch_pc + 64'd8;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("S2-G1 boundary branch fires",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      boundary_rob = dut.issue0_rob_idx_w;
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 boundary branch resolves", branch_resolve_valid, 1'b1);
      tb_check1("S2-G1 boundary branch is initially correct",
                branch_resolve_mispredict, 1'b0);
      `TB_TICK(clk);
      #1;
    end
  endtask

  // S2-G1: same-cycle selective kill must drain the exact response and create
  // one accounting terminal, while suppressing every architectural side
  // effect even when both formal WB slots are unavailable.
  task automatic run_s2_g1_effective_kill_response_contract;
    reg [ROB_INDEX_W-1:0] boundary_rob;
    reg [4:0] owner_token;
    integer wait_cycles;
    begin
      seed_s2_g1_selective_kill_boundary(64'h8000_6e80,
                                         boundary_rob);
      set_dispatch0(64'h8000_6e88,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd18, 64'h8000_0500);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("S2-G1 killed LOAD capture",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 killed LOAD request fire",
                dut.issue0_mem_request_fire_w, 1'b1);
      tb_check32("S2-G1 killed LOAD request kind",
                 {30'b0, dut.miq_push_kind_w}, 32'd0);
      `TB_TICK(clk);
      #1;
      tb_check32("S2-G1 killed LOAD MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);
      owner_token = dut.miq_head_owner_token_w;

      t3v_force_branch_rob = boundary_rob;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      force dut.wb_slot_free_w = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1122_3344_5566_7788;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("S2-G1 killed LOAD effective kill",
                dut.miq_head_effective_killed_w, 1'b1);
      tb_check1("S2-G1 killed LOAD drains without WB credit",
                mem_rsp_ready, 1'b1);
      tb_check1("S2-G1 killed LOAD exact pop", dut.miq_pop_w, 1'b1);
      tb_check1("S2-G1 killed LOAD has no WB", dut.mem_wb_fire_w, 1'b0);
      tb_check1("S2-G1 killed LOAD lane0 terminal",
                dut.mem_terminal_ingress_valid_w[0], 1'b1);
      tb_check32("S2-G1 killed LOAD terminal token",
                 {27'b0, dut.mem_terminal_ingress_token_w[4:0]},
                 {27'b0, owner_token});
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      release dut.wb_slot_free_w;
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      tb_check32("S2-G1 killed LOAD MIQ drains",
                 {28'b0, dut.miq_count_w}, 32'd0);
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 killed LOAD owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check32("S2-G1 killed LOAD terminal queue drains",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);

      seed_s2_g1_selective_kill_boundary(64'h8000_6ea0,
                                         boundary_rob);
      set_dispatch0(64'h8000_6ea8,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h8000_0520);
      dispatch0_inst = 32'h0000_3023;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("S2-G1 killed PROBE capture",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 killed PROBE request fire",
                dut.issue0_mem_request_fire_w, 1'b1);
      tb_check32("S2-G1 killed PROBE request kind",
                 {30'b0, dut.miq_push_kind_w}, 32'd1);
      `TB_TICK(clk);
      #1;
      owner_token = dut.miq_head_owner_token_w;

      t3v_force_branch_rob = boundary_rob;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      force dut.wb_slot_free_w = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0000_0000_9000_0520;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("S2-G1 killed PROBE effective kill",
                dut.miq_head_effective_killed_w, 1'b1);
      tb_check1("S2-G1 killed PROBE drains without WB credit",
                mem_rsp_ready, 1'b1);
      tb_check1("S2-G1 killed PROBE exact pop", dut.miq_pop_w, 1'b1);
      tb_check1("S2-G1 killed PROBE has no WB",
                dut.mem_wb_fire_w, 1'b0);
      tb_check1("S2-G1 killed PROBE has no SQ fill",
                dut.sq_fill_valid_w, 1'b0);
      tb_check1("S2-G1 killed PROBE has no SQ terminal",
                dut.sq_probe_terminal_w, 1'b0);
      tb_check1("S2-G1 killed PROBE lane0 terminal",
                dut.mem_terminal_ingress_valid_w[0], 1'b1);
      tb_check32("S2-G1 killed PROBE terminal token",
                 {27'b0, dut.mem_terminal_ingress_token_w[4:0]},
                 {27'b0, owner_token});
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      release dut.wb_slot_free_w;
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 killed PROBE owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check32("S2-G1 killed PROBE terminal queue drains",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);
      $display("[T4S-EFFKILL-RSP] LOAD+PROBE exact-pop/terminal once, WB/SQ side effects zero PASS");
      reset_dut();
    end
  endtask

  task automatic seed_s2_g1_amo_read;
    input [`XLEN-1:0] pc;
    output [4:0] owner_token;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;
      set_dispatch0(pc,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b0),
                    5'd0, 5'd0, 5'd19, 64'd0);
      dispatch0_inst = inst_amo(5'b00000, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd19);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("S2-G1 AMO read", 1'b0, 64'd0,
                        1'b0, {`XLEN{1'b0}},
                        1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      #1;
      tb_check32("S2-G1 AMO read MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("S2-G1 AMO read pending", dut.mem_pending_q, 1'b1);
      owner_token = dut.miq_head_owner_token_w;
    end
  endtask

  // S2-G1 AMO read/restore priority, inter-phase lane5 accounting and the
  // selected-grant-only write transition are checked independently.
  task automatic run_s2_g1_amo_restore_and_grant_contract;
    reg [4:0] owner_token;
    integer wait_cycles;
    begin
      seed_s2_g1_amo_read(64'h8000_6ec0, owner_token);
      checkpoint_restore = 1'b1;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0102_0304_0506_0708;
      force dut.wb_slot_free_w = 1'b0;
      #1;
      tb_check1("S2-G1 AMO read+restore effective kill",
                dut.miq_head_effective_killed_w, 1'b1);
      tb_check1("S2-G1 AMO read+restore drains without WB credit",
                mem_rsp_ready, 1'b1);
      tb_check1("S2-G1 AMO read+restore is final",
                dut.mem_rsp_final_fire_w, 1'b1);
      tb_check1("S2-G1 AMO read+restore cannot enter write phase",
                dut.mem_amo_read_rsp_w, 1'b0);
      tb_check1("S2-G1 AMO read+restore has no WB",
                dut.mem_wb_fire_w, 1'b0);
      tb_check1("S2-G1 AMO read+restore lane0 terminal",
                dut.mem_terminal_ingress_valid_w[0], 1'b1);
      tb_check1("S2-G1 AMO read+restore no lane5 duplicate",
                dut.mem_terminal_ingress_valid_w[5], 1'b0);
      tb_check1("S2-G1 AMO read+restore no request",
                mem_req_valid, 1'b0);
      tb_check1("S2-G1 AMO read+restore no MIQ push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      mem_rsp_valid = 1'b0;
      release dut.wb_slot_free_w;
      #1;
      tb_check1("S2-G1 AMO read+restore clears pending",
                dut.mem_pending_q, 1'b0);
      tb_check32("S2-G1 AMO read+restore drains MIQ",
                 {28'b0, dut.miq_count_w}, 32'd0);
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 AMO read+restore owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);

      seed_s2_g1_amo_read(64'h8000_6ee0, owner_token);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'd7;
      #1;
      tb_check1("S2-G1 AMO read success enters interphase",
                dut.mem_amo_read_rsp_w, 1'b1);
      tb_check1("S2-G1 AMO read success is not terminal",
                dut.mem_terminal_ingress_valid_w[0], 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("S2-G1 AMO write phase resident",
                dut.mem_amo_write_phase_q, 1'b1);
      tb_check1("S2-G1 AMO write not sent",
                dut.mem_amo_write_sent_q, 1'b0);
      tb_check32("S2-G1 AMO read popped MIQ",
                 {28'b0, dut.miq_count_w}, 32'd0);

      checkpoint_restore = 1'b1;
      #1;
      tb_check1("S2-G1 AMO interphase cancel",
                dut.mem_amo_interphase_cancel_w, 1'b1);
      tb_check1("S2-G1 AMO interphase lane5",
                dut.mem_terminal_ingress_valid_w[5], 1'b1);
      tb_check32("S2-G1 AMO interphase token",
                 {27'b0, dut.mem_terminal_ingress_token_w[29:25]},
                 {27'b0, owner_token});
      tb_check1("S2-G1 AMO interphase restore gates request",
                mem_req_valid, 1'b0);
      tb_check1("S2-G1 AMO interphase restore gates push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check1("S2-G1 AMO interphase clears pending",
                dut.mem_pending_q, 1'b0);
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 AMO lane5 owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);

      seed_s2_g1_amo_read(64'h8000_6f00, owner_token);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'd9;
      #1;
      tb_check1("S2-G1 AMO grant seed read response",
                dut.mem_amo_read_rsp_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      force dut.grant_amo_write_w = 1'b0;
      #1;
      tb_check1("S2-G1 AMO raw write remains eligible",
                dut.mem_amo_write_req_valid_w, 1'b1);
      tb_check1("S2-G1 AMO unselected write has no request",
                mem_req_valid, 1'b0);
      tb_check1("S2-G1 AMO unselected write has no push",
                dut.push_amo_write_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 AMO unselected write stays unsent",
                dut.mem_amo_write_sent_q, 1'b0);
      release dut.grant_amo_write_w;
      #1;
      tb_check1("S2-G1 AMO selected write requests",
                mem_req_valid, 1'b1);
      tb_check1("S2-G1 AMO selected write pushes",
                dut.push_amo_write_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 AMO selected write sent once",
                dut.mem_amo_write_sent_q, 1'b1);
      tb_check32("S2-G1 AMO selected write MIQ owner",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("S2-G1 AMO selected write does not repeat",
                mem_req_valid, 1'b0);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = { `XLEN{1'b0} };
      #1;
      tb_check1("S2-G1 AMO selected write response ready",
                mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 AMO selected write owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      $display("[T4S-AMO-RESTORE] read+restore lane0, interphase lane5, selected-grant-only write PASS");
      reset_dut();
    end
  endtask

  task automatic run_s2_g1_empty_miq_stale_drain_contract;
    begin
      reset_dut();
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'hdead_beef_cafe_f00d;
      #1;
      tb_check32("S2-G1 stale drain starts empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check1("S2-G1 stale drain transport ready", mem_rsp_ready, 1'b1);
      tb_check1("S2-G1 stale drain presents pop transport",
                dut.miq_pop_transport_w, 1'b1);
      tb_check1("S2-G1 stale drain has no exact pop",
                dut.miq_pop_w, 1'b0);
      tb_check1("S2-G1 stale drain has no WB",
                dut.mem_wb_fire_w, 1'b0);
      tb_check1("S2-G1 stale drain has no terminal",
                |dut.mem_terminal_ingress_valid_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check32("S2-G1 stale drain remains empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check32("S2-G1 stale drain creates no owner",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      $display("[T4S-STALE-DRAIN] empty MIQ drains transport with zero side effects PASS");
      reset_dut();
    end
  endtask

  // MIQ full+head-pop must backpressure the parent for one cycle.  The fifth
  // request remains in the memory station, then fires on the cycle after the
  // old head pop with its original metadata.
  task automatic run_t3v_miq_full_pop_parent_backpressure_contract;
    integer fill_idx;
    reg [ROB_INDEX_W-1:0] fifth_rob;
    reg [PHY_REG_ADDR_W-1:0] fifth_pdest;
    reg [`XLEN-1:0] fill_addr;
    begin
      reset_dut();
      mem_req_ready = 1'b1;
      mem_rsp_valid = 1'b0;

      for (fill_idx = 0; fill_idx < 4; fill_idx = fill_idx + 1) begin
        fill_addr = 64'h8000_0400 + (fill_idx * 64'd8);
        set_dispatch0(64'h8000_6e00 + (fill_idx * 64'd4),
                      make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                      5'd0, 5'd0, 5'd12 + fill_idx, fill_addr);
        #1;
        tb_check1("T3V MIQ fill dispatch ready", dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        tb_check1("T3V MIQ fill capture pending",
                  dut.mem_issue_res_capture_w, 1'b1);
        `TB_TICK(clk);
        #1;
        tb_check1("T3V MIQ fill request fires",
                  dut.issue0_mem_request_fire_w, 1'b1);
        tb_check64("T3V MIQ fill request address",
                   dut.miq_push_addr_w, fill_addr);
        `TB_TICK(clk);
        #1;
        tb_check32("T3V MIQ fill count increments",
                   {28'b0, dut.miq_count_w}, fill_idx + 1);
      end
      tb_check1("T3V MIQ reaches full", dut.miq_full_w, 1'b1);

      set_dispatch0(32'h8000_6e10,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd16, 64'h8000_0440);
      #1;
      fifth_rob = dut.dispatch0_rob_idx_w;
      fifth_pdest = dut.dispatch0_pdest_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V MIQ fifth capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V MIQ fifth station resident",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("T3V MIQ full blocks fifth request", mem_req_valid, 1'b0);

      // Pop the old head while full.  Parent credit is based on old full, so
      // no fifth request/consume/push is allowed in this cycle.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1111_2222_3333_4444;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3V MIQ full-pop response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3V MIQ full-pop really pops", dut.miq_pop_w, 1'b1);
      tb_check1("T3V MIQ full-pop keeps old full visible", dut.miq_full_w, 1'b1);
      tb_check1("T3V MIQ full-pop parent request blocked", mem_req_valid, 1'b0);
      tb_check1("T3V MIQ full-pop station not consumed",
                dut.mem_issue_res_consume_fire_w, 1'b0);
      tb_check1("T3V MIQ full-pop has no push",
                dut.miq_push_valid_w, 1'b0);
      tb_check1("T3V MIQ full-pop has no buffer handoff",
                dut.issue0_mem_buffer_fire_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      // Old pop has now created real credit.  The same station request fires
      // exactly one cycle later and carries the fifth uop's frozen metadata.
      tb_check32("T3V MIQ post-pop count is three",
                 {28'b0, dut.miq_count_w}, 32'd3);
      tb_check1("T3V MIQ fifth station survives pop",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("T3V MIQ fifth request fires next cycle",
                dut.issue0_mem_request_fire_w, 1'b1);
      tb_check1("T3V MIQ fifth owns push", dut.push_issue0_w, 1'b1);
      tb_check32("T3V MIQ fifth push ROB",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_push_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, fifth_rob});
      tb_check32("T3V MIQ fifth push pdest",
                 {{(32-PHY_REG_ADDR_W){1'b0}}, dut.miq_push_pdest_w},
                 {{(32-PHY_REG_ADDR_W){1'b0}}, fifth_pdest});
      tb_check32("T3V MIQ fifth push size",
                 {30'b0, dut.miq_push_size_w},
                 {30'b0, `MEM_SIZE_DWORD});
      tb_check1("T3V MIQ fifth push unsigned",
                dut.miq_push_unsigned_w, 1'b1);
      tb_check64("T3V MIQ fifth push address",
                 dut.miq_push_addr_w, 64'h8000_0440);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V MIQ fifth station clears after fire",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check32("T3V MIQ returns to full after fifth push",
                 {28'b0, dut.miq_count_w}, 32'd4);
      $display("[T3V-MIQ-FULL-POP] fifth_rob=%0d fifth_pdest=%0d addr=0x%016h",
               fifth_rob, fifth_pdest, 64'h8000_0440);
      reset_dut();
    end
  endtask

  // T3V LR/SC reservation identity includes access width.  A same-address SC
  // with a different width is a local failure (status=1, no request).  A
  // same-width SC whose byte address is misaligned can still match the LR
  // reservation granule, but must complete as a precise local exception and
  // consume the reservation.
  task automatic run_t3v_lrsc_width_and_exception_contract;
    begin
      // LR.W -> SC.D at the same naturally aligned address: address match is
      // insufficient; width mismatch must force a local failed-SC completion.
      reset_dut();
      set_dispatch0(32'h8000_6da0,
                    make_amo_ctrl(`MEM_SIZE_WORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd20, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LW, 5'd20);
      #1;
      tb_check1("T3V LR.W seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T3V LR.W seed", 1'b0, 64'h0000_0380,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      // The in-order bridge cannot return a response before the request
      // station fire has created its MIQ owner.
      `TB_TICK(clk);
      #1;
      complete_mem0_response("T3V LR.W seed", 64'h0000_0000_89ab_cdef,
                             1'b1, 1'b1, 1'b1,
                             64'hffff_ffff_89ab_cdef);
      tb_check1("T3V LR.W establishes reservation",
                dut.reservation_valid_q, 1'b1);
      tb_check32("T3V LR.W reservation remembers word width",
                 {30'b0, dut.reservation_size_q},
                 {30'b0, `MEM_SIZE_WORD});

      set_dispatch0(32'h8000_6da4,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd21, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00011, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd21);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V LR.W-SC.D capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.W-SC.D width mismatch",
                dut.issue0_sc_success_w, 1'b0);
      tb_check1("T3V LR.W-SC.D consumes locally",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("T3V LR.W-SC.D has no request", mem_req_valid, 1'b0);
      tb_check1("T3V LR.W-SC.D has no MIQ push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.W-SC.D formal WB visible", dut.wb0_valid_w, 1'b1);
      tb_check64("T3V LR.W-SC.D formal status is one",
                 dut.wb0_data_w, 64'd1);
      tb_check1("T3V LR.W-SC.D has no commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3V LR.W-SC.D clears reservation",
                dut.reservation_valid_q, 1'b0);
      tb_check1("T3V LR.W-SC.D never reaches bridge", mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.W-SC.D commits failed status from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3V LR.W-SC.D Q status is one", commit0_data, 64'd1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.W-SC.D completion does not repeat",
                commit0_valid, 1'b0);

      // Reverse mismatch: LR.D -> SC.W must obey the same identity rule.
      reset_dut();
      set_dispatch0(32'h8000_6db0,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd22, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd22);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T3V LR.D seed", 1'b0, 64'h0000_0380,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      #1;
      complete_mem0_response("T3V LR.D seed", 64'h1122_3344_5566_7788,
                             1'b1, 1'b1, 1'b1,
                             64'h1122_3344_5566_7788);
      tb_check1("T3V LR.D establishes reservation",
                dut.reservation_valid_q, 1'b1);
      tb_check32("T3V LR.D reservation remembers dword width",
                 {30'b0, dut.reservation_size_q},
                 {30'b0, `MEM_SIZE_DWORD});

      set_dispatch0(32'h8000_6db4,
                    make_amo_ctrl(`MEM_SIZE_WORD, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd23, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00011, 5'd0, 5'd0,
                                `FUNCT3_LW, 5'd23);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V LR.D-SC.W capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.D-SC.W width mismatch",
                dut.issue0_sc_success_w, 1'b0);
      tb_check1("T3V LR.D-SC.W consumes locally",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("T3V LR.D-SC.W has no request", mem_req_valid, 1'b0);
      tb_check1("T3V LR.D-SC.W has no MIQ push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.D-SC.W formal WB visible", dut.wb0_valid_w, 1'b1);
      tb_check64("T3V LR.D-SC.W formal status is one",
                 dut.wb0_data_w, 64'd1);
      tb_check1("T3V LR.D-SC.W has no commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3V LR.D-SC.W clears reservation",
                dut.reservation_valid_q, 1'b0);
      tb_check1("T3V LR.D-SC.W never reaches bridge", mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.D-SC.W commits failed status from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3V LR.D-SC.W Q status is one", commit0_data, 64'd1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.D-SC.W completion does not repeat",
                commit0_valid, 1'b0);

      // LR.D reserves the 8-byte granule at 0x380.  SC.D at 0x384 still
      // matches that granule but is itself misaligned: exception, no request,
      // and the reservation must be consumed exactly once.
      reset_dut();
      set_dispatch0(32'h8000_6dc0,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd24, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd24);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T3V LR.D misalign seed", 1'b0, 64'h0000_0380,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      #1;
      complete_mem0_response("T3V LR.D misalign seed",
                             64'ha5a5_5a5a_0123_4567,
                             1'b1, 1'b1, 1'b1,
                             64'ha5a5_5a5a_0123_4567);
      tb_check1("T3V misalign seed reservation valid",
                dut.reservation_valid_q, 1'b1);

      set_dispatch0(32'h8000_6dc4,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd25, 64'h0000_0384);
      dispatch0_inst = inst_amo(5'b00011, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd25);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V matching misaligned SC capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V matching misaligned SC sees reservation",
                dut.issue0_sc_success_w, 1'b1);
      tb_check1("T3V matching misaligned SC is local exception",
                dut.issue0_mem_exception_w, 1'b1);
      tb_check1("T3V matching misaligned SC consumes locally",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("T3V matching misaligned SC has no request",
                mem_req_valid, 1'b0);
      tb_check1("T3V matching misaligned SC has no MIQ push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V matching misaligned SC formal WB visible",
                dut.wb0_valid_w, 1'b1);
      tb_check1("T3V matching misaligned SC formal exception",
                dut.wb0_exception_w, 1'b1);
      tb_check32("T3V matching misaligned SC formal cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ADDR_MISALIGN});
      tb_check64("T3V matching misaligned SC formal tval",
                 dut.wb0_tval_w, 64'h0000_0384);
      tb_check1("T3V matching misaligned SC has no commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3V matching misaligned SC clears reservation",
                dut.reservation_valid_q, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V matching misaligned SC commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check1("T3V matching misaligned SC Q exception",
                commit0_exception, 1'b1);
      tb_check32("T3V matching misaligned SC Q cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ADDR_MISALIGN});
      tb_check64("T3V matching misaligned SC Q tval",
                 commit0_tval, 64'h0000_0384);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V matching misaligned SC completion does not repeat",
                commit0_valid, 1'b0);
      $display("[T3V-LRSC-WIDTH-MISALIGN] mismatch_pairs=2 matching_misaligned=1 reservation_valid=%0b",
               dut.reservation_valid_q);
      reset_dut();
    end
  endtask

  // R3：锁住物理 ALU terminal 的资源边界，而非程序序 lane 语义。它仍完成
  // fixed-latency ALU，但 LSU/request/MIQ owner 均归唯一 Universal terminal。
  task automatic run_r3_alu_terminal_no_lsu_contract;
    begin
      reset_dut();
      set_dispatch0(32'h8000_6dc0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd3, 64'd11);
      set_dispatch1(32'h8000_6dc4,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd4, 64'd13);
      #1;
      tb_check1("R3 terminal contract dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3 terminal contract dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("R3 live physical ALU-terminal owner",
                dut.issue1_valid_w, 1'b1);
      tb_check1("R3 live physical ALU-terminal fires",
                dut.issue1_fire_w, 1'b1);
      tb_check1("R3 ALU terminal load class is zero",
                dut.issue1_is_load_w, 1'b0);
      tb_check1("R3 ALU terminal store class is zero",
                dut.issue1_is_store_w, 1'b0);
      tb_check1("R3 ALU terminal AMO class is zero",
                dut.issue1_is_amo_w, 1'b0);
      tb_check1("R3 ALU terminal memory owner is zero",
                dut.issue1_is_mem_w, 1'b0);
      tb_check1("R3 ALU terminal request valid is zero",
                dut.issue1_mem_req_valid_w, 1'b0);
      tb_check1("R3 ALU terminal request fire is zero",
                dut.issue1_mem_request_fire_w, 1'b0);
      tb_check1("R3 ALU terminal MIQ owner is zero",
                dut.push_issue1_w, 1'b0);
      tb_check1("R3 ALU terminal emits no memory request",
                mem_req_valid, 1'b0);
      $display("[R3-ALU-TERMINAL-NO-LSU] live=%0b fire=%0b req=%0b push=%0b",
               dut.issue1_valid_w, dut.issue1_fire_w,
               dut.issue1_mem_req_valid_w, dut.push_issue1_w);
      reset_dut();
    end
  endtask

  // R3.1 P0: a younger ordinary load may reserve/present valid before ROB
  // head, but its unknown request attr must remain invalid/RSVD.  Final IO
  // serialization is owned by bridge plus the exact MIQ/ROB release signal.
  task automatic run_r3p1_swapped_mmio_atomic_contract;
    begin
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6dd0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd6, 64'd17);
      set_dispatch1(32'h8000_6dd4,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h0000_0200);
      #1;
      tb_check1("R3.1 MMIO pair dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3.1 MMIO pair dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      force dut.issue1_ready_w = 1'b0;
      #1;
      tb_check1("R3.1 MMIO pair is capability-swapped",
                dut.iq_issue_pair_swapped_w, 1'b1);
      tb_check32("R3.1 MMIO Universal owns younger",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6dd4);
      tb_check32("R3.1 MMIO ALU terminal owns older",
                 dut.issue1_pc_w[31:0], 32'h8000_6dd0);
      tb_check1("R3.1 ready10 blocks memory IQ pop",
                dut.iq_issue0_ready_w, 1'b0);
      tb_check1("R3.1 ready10 blocks reservation capture",
                dut.mem_issue_res_capture_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("R3.1 ready10 holds both IQ entries",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("R3.1 ready10 leaves reservation empty",
                dut.mem_issue_res_valid_q, 1'b0);

      release dut.issue1_ready_w;
      #1;
      tb_check1("R3.1 ready11 older ALU fires", dut.issue1_fire_w, 1'b1);
      tb_check1("R3.1 ready11 younger MMIO captures",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("R3.1 ready11 drains pair from IQ",
                 {28'b0, issue_count}, 32'd0);
      tb_check1("R3.1 MMIO reservation established",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("R3.1 older ALU reaches WB1", dut.wb1_valid_w, 1'b1);
      tb_check1("R3.1 no retire on older formal WB", commit0_valid, 1'b0);
      tb_check1("R3.1 ordinary load may present valid before older retires",
                mem_req_valid, 1'b1);
      tb_check1("R3.1 backpressure prevents early request fire",
                dut.mem_req_fire_any_w, 1'b0);
      tb_check1("R3.1 early request attr invalid",
                mem_req_attr_valid, 1'b0);
      tb_check32("R3.1 early request class poison",
                 {30'b0, mem_req_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});

      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 older ALU retires before MMIO", commit0_valid, 1'b1);
      tb_check32("R3.1 older ALU retire PC", commit0_pc[31:0],
                 32'h8000_6dd0);
      tb_check1("R3.1 load valid remains held under backpressure",
                mem_req_valid, 1'b1);
      tb_check1("R3.1 held load still has no request fire",
                dut.mem_req_fire_any_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 older ALU retires exactly once", commit0_valid, 1'b0);

      mem_req_ready = 1'b1;
      #1;
      tb_check1("R3.1 ordinary request remains live at ROB head",
                mem_req_valid, 1'b1);
      tb_check1("R3.1 MMIO request is read", mem_req_write, 1'b0);
      tb_check64("R3.1 MMIO request address", mem_req_addr, 64'h0000_0200);
      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 IO candidate request fires exactly once",
                mem_req_valid, 1'b0);
      tb_check1("R3.1 exact MIQ owner enables device release",
                mem_req_device_release, 1'b1);
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_IO;
      mem_rsp_cacheable = 1'b0;
      complete_mem0_response("R3.1 swapped MMIO", 64'h0000_0000_1234_5678,
                             1'b1, 1'b1, 1'b1,
                             64'h0000_0000_1234_5678);
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      mem_rsp_cacheable = 1'b1;
      tb_check32("R3.1 MMIO ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("R3.1 MMIO IQ drains", {28'b0, issue_count}, 32'd0);
      $display("[R3P1-SWAPPED-FINAL-IO] unknown request + exact owner release PASS");
      reset_dut();
    end
  endtask


  // T3U：queue-head CSR 模式下，任何非 ROB-head memory 都必须留在 IQ。
  // 用已完成但被 commit_ready 挡在 ROB head 的 ALU 制造最小反例；这与
  // “较老已完成 CSR 等 mem_idle、较年轻 load 占 reservation”的互等窗口

  // R3.1 long-latency proof: a real 32-iteration DIVU holds the old ROB head
  // while exactly eight independent younger ALUs leave the IQ and reach
  // formal WB.  Retirement must then flatten in original program order.
  task automatic run_r3p1_divu_eight_younger_contract;
    localparam [`XLEN-1:0] OLD_PC = 64'h0000_0000_8000_6e20;
    localparam [`XLEN-1:0] YOUNGER_PC = 64'h0000_0000_8000_6e40;
    reg [ROB_INDEX_W-1:0] old_rob;
    reg [ROB_INDEX_W-1:0] first_younger_rob;
    reg [7:0] younger_wb_mask;
    reg [`XLEN-1:0] expected_commit_pc;
    integer younger_i;
    integer cycle_count;
    integer younger_wb_count;
    integer old_wb_count;
    integer commit_seen;
    integer wb_delta;
    begin
      reset_dut();

      // Seed UINT64_MAX / 3 in architectural x1/x2 so DIVU takes the iterative
      // path rather than the divide-by-zero fast terminal.
      set_dispatch0(32'h8000_6e00,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'hffff_ffff_ffff_ffff);
      set_dispatch1(32'h8000_6e04,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd3);
      tick_dispatch_to_commit("R3.1 DIVU operand setup",
                              64'hffff_ffff_ffff_ffff, 64'd3);

      set_dispatch0(OLD_PC[31:0], make_muldiv_ctrl(),
                    5'd1, 5'd2, 5'd9, 64'd0);
      dispatch0_inst = inst_op(`FUNCT7_MULDIV, 5'd2, 5'd1,
                               3'b101, 5'd9);
      #1;
      tb_check1("R3.1 DIVU old dispatch ready", dispatch0_ready, 1'b1);
      old_rob = dut.dispatch0_rob_idx_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("R3.1 DIVU old selected", dut.issue0_valid_w, 1'b1);
      tb_check32("R3.1 DIVU old PC", dut.issue0_pc_w[31:0], OLD_PC[31:0]);
      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 DIVU request buffered",
                dut.u_muldiv_unit.state_q == 3'd1, 1'b1);

      // Feed eight independent younger ALUs at the architectural two-wide
      // rate while observing issue/WB/retirement in the same loop.  No
      // internal ready/valid boundary is forced apart.
      younger_wb_mask = 8'h00;
      younger_wb_count = 0;
      old_wb_count = 0;
      commit_seen = 0;
      cycle_count = 0;
      younger_i = 0;
      #1;
      while ((commit_seen < 9) && (cycle_count < 80)) begin
        if (younger_i < 8) begin
          set_dispatch0(YOUNGER_PC[31:0] + (younger_i * 4),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd10 + younger_i,
                        64'h100 + younger_i);
          set_dispatch1(YOUNGER_PC[31:0] + ((younger_i + 1) * 4),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd11 + younger_i,
                        64'h101 + younger_i);
          #1;
          tb_check1("R3.1 DIVU younger dispatch0 ready",
                    dispatch0_ready, 1'b1);
          tb_check1("R3.1 DIVU younger dispatch1 ready",
                    dispatch1_ready, 1'b1);
          if (younger_i == 0)
            first_younger_rob = dut.dispatch0_rob_idx_w;
        end

        if (dut.wb0_valid_w) begin
          wb_delta = dut.wb0_rob_idx_w - first_younger_rob;
          if ((wb_delta >= 0) && (wb_delta < 8)) begin
            if (younger_wb_mask[wb_delta])
              $display("[R3P1-DIVU-DUP-WB] cycle=%0d lane=0 rob=%0d delta=%0d",
                       cycle_count, dut.wb0_rob_idx_w, wb_delta);
            tb_check1("R3.1 no repeated younger WB on terminal0",
                      younger_wb_mask[wb_delta], 1'b0);
            younger_wb_mask[wb_delta] = 1'b1;
            younger_wb_count = younger_wb_count + 1;
          end
        end
        if (dut.wb1_valid_w) begin
          wb_delta = dut.wb1_rob_idx_w - first_younger_rob;
          if ((wb_delta >= 0) && (wb_delta < 8)) begin
            if (younger_wb_mask[wb_delta])
              $display("[R3P1-DIVU-DUP-WB] cycle=%0d lane=1 rob=%0d delta=%0d",
                       cycle_count, dut.wb1_rob_idx_w, wb_delta);
            tb_check1("R3.1 no repeated younger WB on terminal1",
                      younger_wb_mask[wb_delta], 1'b0);
            younger_wb_mask[wb_delta] = 1'b1;
            younger_wb_count = younger_wb_count + 1;
          end
        end

        if ((dut.wb0_valid_w && (dut.wb0_rob_idx_w == old_rob)) ||
            (dut.wb1_valid_w && (dut.wb1_rob_idx_w == old_rob))) begin
          old_wb_count = old_wb_count + 1;
          tb_check32("R3.1 all eight WB before old DIVU",
                     {24'b0, younger_wb_mask}, 32'h0000_00ff);
          tb_check1("R3.1 old DIVU formal WB has no same-cycle retire",
                    commit0_valid || commit1_valid, 1'b0);
        end

        if (old_wb_count == 0)
          tb_check1("R3.1 no younger retirement before old DIVU WB",
                    commit0_valid || commit1_valid, 1'b0);

        if (commit0_valid) begin
          expected_commit_pc = (commit_seen == 0) ? OLD_PC :
              (YOUNGER_PC + ((commit_seen - 1) * 4));
          tb_check32("R3.1 flattened commit0 program order",
                     commit0_pc[31:0], expected_commit_pc[31:0]);
          commit_seen = commit_seen + 1;
        end
        if (commit1_valid) begin
          expected_commit_pc = (commit_seen == 0) ? OLD_PC :
              (YOUNGER_PC + ((commit_seen - 1) * 4));
          tb_check32("R3.1 flattened commit1 program order",
                     commit1_pc[31:0], expected_commit_pc[31:0]);
          commit_seen = commit_seen + 1;
        end

        `TB_TICK(clk);
        clear_dispatch();
        if (younger_i < 8)
          younger_i = younger_i + 2;
        #1;
        cycle_count = cycle_count + 1;
        if ((younger_i == 8) && (cycle_count == 4)) begin
          tb_check32("R3.1 DIVU ROB holds old plus eight",
                     {27'b0, rob_count}, 32'd9);
          tb_check1("R3.1 DIVU remains in iterative run",
                    dut.u_muldiv_unit.state_q == 3'd3, 1'b1);
        end
      end

      tb_check32("R3.1 DIVU younger distinct WB mask",
                 {24'b0, younger_wb_mask}, 32'h0000_00ff);
      tb_check32("R3.1 DIVU younger WB exactly once",
                 younger_wb_count, 32'd8);
      tb_check32("R3.1 DIVU old WB exactly once", old_wb_count, 32'd1);
      tb_check32("R3.1 DIVU ordered commit count", commit_seen, 32'd9);
      tb_check32("R3.1 DIVU ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("R3.1 DIVU IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("R3.1 DIVU free-list recovers",
                 {25'b0, free_count}, 32'd32);
      $display("[R3P1-DIVU-8-YOUNGER] cycles=%0d mask=%02h commits=%0d PASS",
               cycle_count, younger_wb_mask, commit_seen);
      reset_dut();
    end
  endtask

  // 具有相同 admission 前件。
  task automatic run_t3u_csr_queue_head_mem_admission;
    integer wait_cycles;
    begin
      if (`OOO_CSR_QUEUE_HEAD) begin
        reset_dut();
        mem_req_ready = 1'b0;
        commit_ready = 1'b0;

        set_dispatch0(32'h8000_6e00,
                      make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                    `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                      5'd0, 5'd0, 5'd3, 64'd1);
        #1;
        tb_check1("T3U CSR-QH older done uop dispatch ready",
                  dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        `TB_TICK(clk);
        #1;
        `TB_TICK(clk);
        #1;
        tb_check32("T3U CSR-QH older done uop leaves IQ",
                   {28'b0, issue_count}, 32'd0);
        tb_check32("T3U CSR-QH older done uop remains ROB head",
                   {27'b0, rob_count}, 32'd1);
        tb_check32("T3U CSR-QH older done uop is head zero",
                   {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w}, 32'd0);

        set_dispatch0(32'h8000_6e04,
                      make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                      5'd0, 5'd0, 5'd7, 64'h8000_0360);
        #1;
        tb_check1("T3U CSR-QH younger load dispatch ready",
                  dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        tb_check1("T3U CSR-QH younger load is IQ oldest",
                  dut.iq_issue0_mem_class_w, 1'b1);
        tb_check1("T3U CSR-QH younger load is not ROB head",
                  dut.iq_issue0_rob_idx_w != dut.rob_head_idx_w, 1'b1);
        tb_check1("T3U CSR-QH non-head load admission closes",
                  dut.mem_issue_res_admit_w, 1'b0);
        tb_check1("T3U CSR-QH non-head load cannot capture",
                  dut.mem_issue_res_capture_w, 1'b0);
        tb_check1("T3U CSR-QH reservation stays idle",
                  dut.mem_issue_res_valid_q, 1'b0);
        tb_check1("T3U CSR-QH mem_idle remains available to older head",
                  dut.mem_idle_o, 1'b1);

        commit_ready = 1'b1;
        wait_cycles = 0;
        while (!dut.mem_issue_res_capture_w && (wait_cycles < 100)) begin
          `TB_TICK(clk);
          #1;
          wait_cycles = wait_cycles + 1;
        end
        tb_check1("T3U CSR-QH load eventually captures at ROB head",
                  dut.mem_issue_res_capture_w, 1'b1);
        tb_check1("T3U CSR-QH eventual capture sees ROB head",
                  dut.iq_issue0_rob_idx_w == dut.rob_head_idx_w, 1'b1);
        tb_check1("T3U CSR-QH eventual capture has valid ROB head",
                  dut.rob_head_valid_w, 1'b1);
        $display("[T3U-CSR-QH-MEM-ADMISSION] wait=%0d raw_rob=%0d head=%0d idle=%0b",
                 wait_cycles, dut.iq_issue0_rob_idx_w,
                 dut.rob_head_idx_w, dut.mem_idle_o);
        reset_dut();
      end
    end
  endtask

  // P0-A focused truth table: no clock edge is taken while internal owners are
  // forced, so this probes only the combinational write-enable topology and
  // cannot create a synthetic ROB completion.  Both physical WB lanes cover
  // all five sources at nonzero/p0 destinations; FPWB also keeps rd-disable
  // separate from p0 so either gate cannot hide a regression in the other.
`ifdef OOO_ASSERT
  task automatic run_p0_wb_write_valid_source_matrix;
    begin
      tb_check1("P0-A idle wb0 write invalid", dut.gpr_wb0_write_valid_w,
                1'b0);
      tb_check1("P0-A idle wb1 write invalid", dut.gpr_wb1_write_valid_w,
                1'b0);

      force dut.ex0_valid_q = 1'b1;
      force dut.ex0_pdest_q = 6'd1;
      #1;
      tb_check1("P0-A wb0 EX source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 EX legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      release dut.ex0_valid_q;
      release dut.ex0_pdest_q;
      #1;

      force dut.mem_rsp_to_wb0_w = 1'b1;
      force dut.mem_rsp_int_pdest_w = 6'd2;
      #1;
      tb_check1("P0-A wb0 MEM source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 MEM legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      force dut.mem_rsp_int_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 MEM p0 rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 MEM p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.mem_rsp_to_wb0_w;
      release dut.mem_rsp_int_pdest_w;
      #1;

      force dut.muldiv_rsp_to_wb0_w = 1'b1;
      force dut.muldiv_resp_pdest_w = 6'd3;
      #1;
      tb_check1("P0-A wb0 MULDIV source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 MULDIV legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      force dut.muldiv_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 MULDIV p0 rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 MULDIV p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.muldiv_rsp_to_wb0_w;
      release dut.muldiv_resp_pdest_w;
      #1;

      force dut.clmul_rsp_to_wb0_w = 1'b1;
      force dut.clmul_resp_pdest_w = 6'd4;
      #1;
      tb_check1("P0-A wb0 CLMUL source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 CLMUL legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      force dut.clmul_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 CLMUL p0 rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 CLMUL p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.clmul_rsp_to_wb0_w;
      release dut.clmul_resp_pdest_w;
      #1;

      force dut.fpwb_to_wb0_w = 1'b1;
      force dut.fpwb_rd_en_w = 1'b1;
      force dut.fpwb_pdest_w = 6'd5;
      #1;
      tb_check1("P0-A wb0 FPWB source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 FPWB legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      force dut.fpwb_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 FPWB p0 rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 FPWB p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      force dut.fpwb_pdest_w = 6'd5;
      force dut.fpwb_rd_en_w = 1'b0;
      #1;
      tb_check1("P0-A wb0 FPWB rd-disable rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 FPWB rd-disable legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.fpwb_to_wb0_w;
      release dut.fpwb_rd_en_w;
      release dut.fpwb_pdest_w;
      #1;

      force dut.ex0_valid_q = 1'b1;
      force dut.ex0_pdest_q = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 p0 rejects write", dut.gpr_wb0_write_valid_w,
                1'b0);
      tb_check1("P0-A wb0 EX p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.ex0_valid_q;
      release dut.ex0_pdest_q;
      #1;

      force dut.ex1_valid_q = 1'b1;
      force dut.ex1_pdest_q = 6'd6;
      #1;
      tb_check1("P0-A wb1 EX source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 EX legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      release dut.ex1_valid_q;
      release dut.ex1_pdest_q;
      #1;

      force dut.mem_rsp_to_wb1_w = 1'b1;
      force dut.mem_rsp_int_pdest_w = 6'd7;
      #1;
      tb_check1("P0-A wb1 MEM source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 MEM legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      force dut.mem_rsp_int_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 MEM p0 rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 MEM p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.mem_rsp_to_wb1_w;
      release dut.mem_rsp_int_pdest_w;
      #1;

      force dut.muldiv_rsp_to_wb1_w = 1'b1;
      force dut.muldiv_resp_pdest_w = 6'd8;
      #1;
      tb_check1("P0-A wb1 MULDIV source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 MULDIV legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      force dut.muldiv_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 MULDIV p0 rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 MULDIV p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.muldiv_rsp_to_wb1_w;
      release dut.muldiv_resp_pdest_w;
      #1;

      force dut.clmul_rsp_to_wb1_w = 1'b1;
      force dut.clmul_resp_pdest_w = 6'd9;
      #1;
      tb_check1("P0-A wb1 CLMUL source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 CLMUL legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      force dut.clmul_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 CLMUL p0 rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 CLMUL p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.clmul_rsp_to_wb1_w;
      release dut.clmul_resp_pdest_w;
      #1;

      force dut.fpwb_to_wb1_w = 1'b1;
      force dut.fpwb_rd_en_w = 1'b1;
      force dut.fpwb_pdest_w = 6'd10;
      #1;
      tb_check1("P0-A wb1 FPWB source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 FPWB legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      force dut.fpwb_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 FPWB p0 rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 FPWB p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      force dut.fpwb_pdest_w = 6'd10;
      force dut.fpwb_rd_en_w = 1'b0;
      #1;
      tb_check1("P0-A wb1 FPWB rd-disable rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 FPWB rd-disable legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.fpwb_to_wb1_w;
      release dut.fpwb_rd_en_w;
      release dut.fpwb_pdest_w;
      #1;

      force dut.ex1_valid_q = 1'b1;
      force dut.ex1_pdest_q = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 p0 rejects write", dut.gpr_wb1_write_valid_w,
                1'b0);
      tb_check1("P0-A wb1 EX p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.ex1_valid_q;
      release dut.ex1_pdest_q;
      #1;

      $display("[P0-A-WB-VALID-SOURCE-MATRIX] 22/22 PASS: 2 lanes x (5 nonzero + 5 p0), plus 2 FP rd-disable");
    end
  endtask
`endif

  initial begin
    tb_errors = 0;
    reset_dut();

`ifdef INT_WB_VALID_SOURCE_FOCUSED
    run_p0_wb_write_valid_source_matrix();
`elsif INT_WB_WRITE_VALID_EQUIV_NEGATIVE
    // 只 force shadow，功能 write-enable/PRF/ROB 都不受扰动；精确证明
    // cycle-exact equivalence 断言对单拍 mismatch 非真空。
    if (dut.gpr_wb0_write_valid_w || dut.gpr_wb0_legacy_write_valid_w)
      $fatal(1, "[INT-WB0-WRITE-VALID-EQUIV-NEGATIVE-SETUP] idle values are not zero");
    force dut.gpr_wb0_legacy_write_valid_w = 1'b1;
    #1;
    if (dut.gpr_wb0_write_valid_w !== 1'b0)
      $fatal(1, "[INT-WB0-WRITE-VALID-EQUIV-NEGATIVE-SETUP] functional valid was perturbed");
    $display("[INT-WB0-WRITE-VALID-EQUIV-NEGATIVE] forced local=%b legacy=%b",
             dut.gpr_wb0_write_valid_w,
             dut.gpr_wb0_legacy_write_valid_w);
    `TB_TICK(clk);
    release dut.gpr_wb0_legacy_write_valid_w;
    $display("[INT-WB0-WRITE-VALID-EQUIV-NEGATIVE-DONE] completed one assertion edge");
    $finish_and_return(0);
`elsif INT_WB_SOURCE_ONEHOT_NEGATIVE
    // 两个 source select 重叠，但各自 pdest=p0 且 formal valid 被静默；因此
    // 只应命中 onehot0，不会伪造 ROB completion 或 equivalence mismatch。
    force dut.mem_rsp_to_wb0_w = 1'b1;
    force dut.clmul_rsp_to_wb0_w = 1'b1;
    force dut.mem_rsp_int_pdest_w = {PHY_REG_ADDR_W{1'b0}};
    force dut.clmul_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
    force dut.wb0_valid_w = 1'b0;
    #1;
    if ((dut.wb0_source_count_w !== 3'd2) ||
        dut.gpr_wb0_write_valid_w ||
        dut.gpr_wb0_legacy_write_valid_w)
      $fatal(1, "[INT-WB0-SOURCE-ONEHOT0-NEGATIVE-SETUP] expected isolated two-source overlap");
    $display("[INT-WB0-SOURCE-ONEHOT0-NEGATIVE] forced sources=%b",
             dut.wb0_source_onehot_w);
    `TB_TICK(clk);
    release dut.mem_rsp_to_wb0_w;
    release dut.clmul_rsp_to_wb0_w;
    release dut.mem_rsp_int_pdest_w;
    release dut.clmul_resp_pdest_w;
    release dut.wb0_valid_w;
    $display("[INT-WB0-SOURCE-ONEHOT0-NEGATIVE-DONE] completed one assertion edge");
    $finish_and_return(0);
`else
`ifdef T3U_CSR_QH_DIRECTED
    run_t3u_csr_queue_head_mem_admission();
`else
    tb_check32("initial freelist count", {25'b0, free_count}, 32'd32);
    tb_check32("initial rob count", {27'b0, rob_count}, 32'd0);
    tb_check32("initial issue count", {28'b0, issue_count}, 32'd0);

`ifdef INT_DISPATCH_PACKET_PACKED_NEGATIVE
    // 独立负探针：生产前端保证 packet densely packed；这里在 IntBackend
    // 边界直接制造唯一违约形状 (valid0,valid1)=(0,1)，证明 OOO_ASSERT
    // 的 carrying-contract marker 有牙。宏默认不定义，常规模块回归不进入本臂。
    clear_dispatch();
    set_dispatch1(32'h8000_0df4,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd6, 64'd1);
    dispatch0_valid = 1'b0;
    #1;
    if (dispatch0_valid || !dispatch1_valid || dut.dispatch0_fire_w ||
        dut.dispatch1_fire_w)
      $fatal(1, "[INT-DISPATCH-PACKET-PACKED-NEGATIVE-SETUP] expected valid={0,1} fire={0,0}, got valid={%0b,%0b} fire={%0b,%0b}",
             dispatch0_valid, dispatch1_valid,
             dut.dispatch0_fire_w, dut.dispatch1_fire_w);
    $display("[INT-DISPATCH-PACKET-PACKED-NEGATIVE] presenting valid={%0b,%0b} fire={%0b,%0b}",
             dispatch0_valid, dispatch1_valid,
             dut.dispatch0_fire_w, dut.dispatch1_fire_w);
    `TB_TICK(clk);
    $display("[INT-DISPATCH-PACKET-PACKED-NEGATIVE-DONE] completed one assertion edge");
    $finish_and_return(0);
`endif

`ifdef FP_PAIR_ATOMIC_NEGATIVE
    // 非真空负探针：先建立有容量的合法 mandatory 双 FP packet，确认两 lane
    // 原本都会 fire，再只压掉 lane1 的消费边界 fire，跨沿验证原子断言有牙。
    set_fp_binary0(32'h8000_0e00, 7'b0000001,
                   5'd0, 5'd0, 5'd9, 1'b1);
    set_fp_binary1(32'h8000_0e04, 7'b0000001,
                   5'd0, 5'd0, 5'd10, 1'b1);
    #1;
    if (!(dispatch0_ready && dispatch1_ready &&
          dut.dispatch0_fire_w && dut.dispatch1_fire_w))
      $fatal(1, "[FP-PAIR-ATOMIC-NEGATIVE-SETUP] legal pair did not reach dual-fire window");
    force dut.dispatch1_fire_w = 1'b0;
    $display("[FP-PAIR-ATOMIC-NEGATIVE] forced fire={%0b,%0b} in legal mandatory window",
             dut.dispatch0_fire_w, dut.dispatch1_fire_w);
    `TB_TICK(clk);
    release dut.dispatch1_fire_w;
    #1;
    $display("[FP-PAIR-ATOMIC-NEGATIVE] completed one assertion edge");
    $finish_and_return(0);
`endif

`ifdef INT_WB_PDEST_UNIQUE_NEGATIVE
    // 非真空负探针：lane0 是真实非零整数目的 ALU，lane1 是无目的但仍经 EX
    // 正式完成的 ALU。这样双 formal-WB valid 真实成立而 lane1 fast valid 为 0；
    // 仅 force formal wb1 pdest 即可孤立命中 unique marker，不扰动 fast-subset 断言。
    set_dispatch0(32'h8000_0e10,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd5, 64'd17);
    set_dispatch1(32'h8000_0e14,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b0),
                  5'd0, 5'd0, 5'd0, 64'd23);
    #1;
    if (!(dispatch0_ready && dispatch1_ready))
      $fatal(1, "[INT-WB-PDEST-UNIQUE-NEGATIVE-SETUP] legal dual dispatch not ready");
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    if (!(dut.issue0_valid_w && dut.issue1_valid_w))
      $fatal(1, "[INT-WB-PDEST-UNIQUE-NEGATIVE-SETUP] legal dual EX issue window absent");
    `TB_TICK(clk);
    #1;
    if (!(dut.wb0_valid_w && dut.wb1_valid_w &&
          (dut.wb0_pdest_w != {PHY_REG_ADDR_W{1'b0}}) &&
          (dut.wb1_pdest_w == {PHY_REG_ADDR_W{1'b0}})))
      $fatal(1, "[INT-WB-PDEST-UNIQUE-NEGATIVE-SETUP] expected dual formal-WB/nonzero-zero pdest window absent");
    force dut.wb1_pdest_w = dut.wb0_pdest_w;
    $display("[INT-WB-PDEST-UNIQUE-NEGATIVE] forced formal pdest={%0d,%0d} valid={%0b,%0b}",
             dut.wb0_pdest_w, dut.wb1_pdest_w,
             dut.wb0_valid_w, dut.wb1_valid_w);
    // flush 只用于静默同沿 ROB slot-identity 哨兵；EX_q 的双 formal-WB valid
    // 在该沿前仍真实有效，IntBackend unique 断言刻意不受 flush 门控。
    flush = 1'b1;
    `TB_TICK(clk);
    release dut.wb1_pdest_w;
    #1;
    $display("[INT-WB-PDEST-UNIQUE-NEGATIVE] completed one assertion edge");
    $finish_and_return(0);
`endif

`ifdef INT_ALU_TERMINAL_CAPABILITY_NEGATIVE
    // R3.4 non-vacuous negative: start from a real dual-simple issue window,
    // then violate only the physical ALU-terminal allow-list.  The terminal's
    // removed complex/WBU arms must not turn malformed upstream control into
    // a silently accepted completion.
    set_dispatch0(32'h8000_0e20,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd7, 64'd29);
    set_dispatch1(32'h8000_0e24,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd8, 64'd31);
    #1;
    if (!(dispatch0_ready && dispatch1_ready))
      $fatal(1, "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-SETUP] dual-simple dispatch not ready");
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    if (!(dut.issue1_valid_w && dut.issue1_fire_w))
      $fatal(1, "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-SETUP] live ALU-terminal issue window absent");
    force dut.issue1_ctrl_w[`CTRL_BITMANIP_BIT] = 1'b1;
    $display("[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-BITMANIP] forced live ctrl=%h",
             dut.issue1_ctrl_w);
    `TB_TICK(clk);
    release dut.issue1_ctrl_w[`CTRL_BITMANIP_BIT];

    reset_dut();
    set_dispatch0(32'h8000_0e30,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd9, 64'd37);
    set_dispatch1(32'h8000_0e34,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd10, 64'd41);
    #1;
    if (!(dispatch0_ready && dispatch1_ready))
      $fatal(1, "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-SETUP] WB-select pair not ready");
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    if (!(dut.issue1_valid_w && dut.issue1_fire_w))
      $fatal(1, "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-SETUP] WB-select issue window absent");
    force dut.issue1_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_PC4;
    $display("[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-WBSEL] forced live ctrl=%h",
             dut.issue1_ctrl_w);
    `TB_TICK(clk);
    release dut.issue1_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB];
    #1;
    $display("[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-DONE] completed two assertion edges");
    $finish_and_return(0);
`endif

`ifdef RAW_I1_NEGATIVE_PROBE
    // 非真空负探针：先建立两个合法 independent integer issue lane，再只 force
    // issue1 enabled source tag 撞 issue0 integer pdest，证明 RAW-I1 立即断言有牙。
    set_dispatch0(32'h8000_0f00,
                  make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2, `ALU_OP_ADD,
                                1'b1, 1'b1, 1'b1),
                  5'd1, 5'd2, 5'd5, 64'd0);
    set_dispatch1(32'h8000_0f04,
                  make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2, `ALU_OP_ADD,
                                1'b1, 1'b1, 1'b1),
                  5'd3, 5'd4, 5'd6, 64'd0);
    #1;
    tb_check1("RAW-I1 probe dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("RAW-I1 probe dispatch1 ready", dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("RAW-I1 probe reaches issue0", dut.issue0_valid_w, 1'b1);
    tb_check1("RAW-I1 probe reaches issue1", dut.issue1_valid_w, 1'b1);
    force dut.issue1_src1_preg_w = dut.issue0_pdest_w;
    $display("[RAW-I1-NEGATIVE-PROBE] forced issue1 src1=%0d to issue0 pdest=%0d",
             dut.issue1_src1_preg_w, dut.issue0_pdest_w);
    `TB_TICK(clk);
    #1;
    $finish_and_return(0);
`endif

    run_t4h_store_probe_pma_fault_precise();
    run_t4n_store_b_error_precise();
    run_r4_s0_store_class_propagation();
    run_t4n_page_end_store_local_exception(1'b0);
    run_t4n_page_end_store_local_exception(1'b1);
    run_t4n_b_local_terminal_collision(1'b0);
    run_t4n_b_local_terminal_collision(1'b1);
    run_t4n_older_alu_probe_fault_exception_order();
    run_t4n_sq_checkpoint_restore_no_fire();
    run_t4n_two_store_priority_order();
    run_t4n_t4m_store_before_device_candidate(
        1'b1, 64'h0000_0000_8000_5000);
    run_t4n_t4m_store_before_device_candidate(
        1'b0, 64'h0000_0000_1000_0000);
    run_s1_sq_forward_bypasses_blind_barrier();

    set_dispatch0(32'h8000_0000,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd5, 32'd7);
    set_dispatch1(32'h8000_0004,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd6, 32'd9);
    tick_dispatch_to_commit("dual independent addi", 32'd7, 32'd9);

    set_dispatch0(32'h8000_0010,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd7, 32'd7);
    set_dispatch1(32'h8000_0014,
                  make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b1, 1'b0, 1'b1),
                  5'd7, 5'd0, 5'd8, 32'd3);
    #1;
    tb_check1("dependent dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("dependent dispatch1 ready", dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    // R3.2: producer actual fire sets sticky ready at the edge that also
    // registers its EX result.  The dependent selects in the following cycle
    // and consumes only the registered EX forwarding payload.
    tb_check32("dependent pair queued", {28'b0, issue_count}, 32'd2);
    `TB_TICK(clk);
    #1;
    tb_check32("consumer resident during lookahead select",
               {28'b0, issue_count}, 32'd1);
    tb_check1("producer formal WB visible", dut.wb0_valid_w, 1'b1);
    tb_check64("producer formal WB data", dut.wb0_data_w, 64'd7);
    tb_check1("producer does not commit on formal WB", commit0_valid, 1'b0);
    tb_check1("consumer selects one cycle after producer fire",
              dut.issue0_valid_w, 1'b1);
    tb_check1("consumer source hits registered EX0",
              dut.issue0_src1_ex0_fwd_hit_w, 1'b1);
    tb_check64("consumer forwarded source value",
               dut.issue0_src1_data_w, 64'd7);

    `TB_TICK(clk);
    #1;
    tb_check32("consumer leaves IQ after lookahead fire",
               {28'b0, issue_count}, 32'd0);
    tb_check1("producer commits from ROB Q", commit0_valid, 1'b1);
    tb_check64("producer result from ROB Q", commit0_data, 64'd7);
    tb_check1("consumer formal WB visible", dut.wb0_valid_w, 1'b1);
    tb_check64("consumer formal WB uses registered EX forward",
               dut.wb0_data_w, 64'd10);

    `TB_TICK(clk);
    #1;
    tb_check1("consumer commits from ROB Q", commit0_valid, 1'b1);
    tb_check64("consumer result from ROB Q", commit0_data, 64'd10);

    `TB_TICK(clk);
    #1;
    tb_check32("dependent rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("dependent iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("dependent freelist recovers", {25'b0, free_count}, 32'd32);

    run_r3p2_dual_producer_consumer();
    run_r3p2_raw_chain_64();
    run_lane1_prf_wb_wakeup();
    run_t3b_divu_wb0_isolation();
    run_t3b_clmul_wb0_isolation();
    // T3P lane1-simple owner 后 long-op 只从 lane0 发射；旧“DIVU 直接占
    // lane1 并以同拍 ALU 挤到 WB1”的构造已不可达。WB0 sticky 隔离仍由上面
    // DIVU/CLMUL 两个真实 long-op 用例覆盖，双 formal-WB 由独立碰撞用例覆盖。
    run_t3b_fp_load_tag_alias_exclusion();
    run_t3b_integer_load_fault_exclusion();
    run_t4s_fp_raw_intent_state_isolation();
    run_t3c_fp_mandatory_pair_atomicity_red();
    run_t3q_fp_issue_stage_contracts();

    set_dispatch0(32'h8000_0800,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd5, 32'd1);
    #1;
    tb_check1("branch bypass producer dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check32("branch producer queued in iq", {28'b0, issue_count}, 32'd1);

    set_dispatch0(32'h8000_0804,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd5, 5'd0, 5'd0, 32'd8);
    #1;
    // domain-A(OOO_DBRANCH_DOMAIN_A=1): dispatch 拍快解析对分支禁用(fast 路不产生
    // mispredict/ROB-walk kill, 会放走 wrong-path); 分支恒经 IQ 由 issue 级 resolve。
    tb_check1("branch dispatch fast resolve disabled (domain-A)",
              dispatch_branch_resolve_valid, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    repeat (4) begin
      `TB_TICK(clk);
    end
    #1;
    tb_check32("branch bypass rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("branch bypass iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("branch bypass freelist recovers", {25'b0, free_count}, 32'd32);

    // T3N：lane0 raw resolve 在 issue 拍只写 coherent PipeStageReg；公开
    // redirect/kill/BPU bundle 下一拍 exactly-once 出现。DispatchBackend 删除旧
    // kill_q 后应在同一 q 拍直接驱动 ROB/IQ kill；stage invalid 后 dirty
    // mispredict payload 绝不能继续产生 kill。
    set_dispatch0(32'h8000_0810,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd0, 5'd0, 5'd0, 64'd8);
    // 非零/非默认 metadata 锁住 bundle 字段顺序；pred_taken=1 与错误的
    // pred_npc=0 可同时保持本例为真实 mispredict。
    dispatch0_bht_idx = 10'h2a5;
    dispatch0_pred_taken = 1'b1;
    #1;
    tb_check1("T3N staged branch dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N branch selected on lane0", dut.issue0_valid_w, 1'b1);
    tb_check1("T3N lane0 control-flow fire", dut.issue0_ctrlflow_fire_w, 1'b1);
    tb_check1("T3N public resolve absent in raw issue cycle",
              branch_resolve_valid, 1'b0);
    tb_check1("T3N ROB kill absent before resolve q",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N public resolve valid exactly next cycle",
              branch_resolve_valid, 1'b1);
    tb_check64("T3N staged resolve pc",
               branch_resolve_pc, 64'h0000_0000_8000_0810);
    tb_check64("T3N staged resolve target",
               branch_resolve_next_pc, 64'h0000_0000_8000_0818);
    tb_check1("T3N staged resolve aligned", branch_resolve_misaligned, 1'b0);
    tb_check1("T3N staged resolve mispredict", branch_resolve_mispredict, 1'b1);
    tb_check1("T3N staged resolve branch kind", branch_resolve_is_branch, 1'b1);
    tb_check1("T3N staged resolve taken", branch_resolve_taken, 1'b1);
    tb_check1("T3N staged resolve predicted taken metadata",
              branch_resolve_pred_taken, 1'b1);
    tb_check32("T3N staged resolve BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'h0000_02a5);
    tb_check1("T3N resolve q directly drives ROB kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b1);
    tb_check1("T3N branch shares EX boundary cycle", dut.ex0_valid_q, 1'b1);
    tb_check32("T3N resolve/ex ROB identity",
               {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
               {{(32-ROB_INDEX_W){1'b0}}, dut.ex0_rob_idx_q});
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N resolve pulse consumed once", branch_resolve_valid, 1'b0);
    tb_check1("T3N dirty payload cannot repeat mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check1("T3N dirty payload cannot repeat ROB kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    repeat (5) begin
      `TB_TICK(clk);
      clear_dispatch();
    end
    #1;
    tb_check32("T3N staged branch ROB drains", {27'b0, rob_count}, 32'd0);
    tb_check32("T3N staged branch IQ drains", {28'b0, issue_count}, 32'd0);
    tb_check32("T3N staged branch freelist recovers",
               {25'b0, free_count}, 32'd32);

    // q 已有效时，flush 必须在同一个组合拍立即屏蔽整包；不能等上升沿，
    // 否则 dirty mispredict 会多打一拍 redirect/kill/BPU update。
    set_dispatch0(32'h8000_0820,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd0, 5'd0, 5'd0, 64'd8);
    dispatch0_bht_idx = 10'h155;
    dispatch0_pred_taken = 1'b1;
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N flush-collision branch reaches raw lane0",
              dut.issue0_ctrlflow_fire_w, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N flush-collision setup has resolve q",
              branch_resolve_valid, 1'b1);
    tb_check1("T3N flush-collision setup has mispredict",
              branch_resolve_mispredict, 1'b1);
    flush = 1'b1;
    #1;
    tb_check1("T3N flush masks resolve valid immediately",
              branch_resolve_valid, 1'b0);
    tb_check64("T3N flush masks resolve pc", branch_resolve_pc, 64'd0);
    tb_check64("T3N flush masks resolve next pc",
               branch_resolve_next_pc, 64'd0);
    tb_check1("T3N flush masks resolve misaligned",
              branch_resolve_misaligned, 1'b0);
    tb_check32("T3N flush masks resolve ROB index",
               {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx}, 32'd0);
    tb_check1("T3N flush masks resolve mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check1("T3N flush masks resolve branch kind",
              branch_resolve_is_branch, 1'b0);
    tb_check1("T3N flush masks resolve taken",
              branch_resolve_taken, 1'b0);
    tb_check1("T3N flush masks resolve pred_taken",
              branch_resolve_pred_taken, 1'b0);
    tb_check32("T3N flush masks resolve BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'd0);
    tb_check1("T3N flush masks direct ROB kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N flush clears resolve stage", branch_resolve_valid, 1'b0);

    // T3Q：checkpoint_restore 可作为模块接口上的独立脉冲出现。即使顶层当前
    // ROB-walk 配置把该链静态关闭，模块也不得在子单元 flush 的同一拍从 IQ
    // pop 一个 long-op，否则上游记为已发射而 MulDiv 会丢弃请求。
    set_dispatch0(32'h8000_0824, make_muldiv_ctrl(),
                  5'd0, 5'd0, 5'd1, 64'd0);
    dispatch0_inst = inst_op(`FUNCT7_MULDIV, 5'd0, 5'd0,
                             3'b101, 5'd1);
    #1;
    tb_check1("T3Q restore collision MulDiv dispatch ready",
              dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3Q restore collision MulDiv selected",
              dut.issue0_is_muldiv_w, 1'b1);
    checkpoint_restore = 1'b1;
    #1;
    tb_check1("T3Q restore masks lane0 ready",
              dut.issue0_ready_w, 1'b0);
    tb_check1("T3Q restore forbids lane0 fire",
              dut.issue0_fire_w, 1'b0);
    tb_check1("T3Q restore forbids MulDiv request valid",
              dut.muldiv_req_valid_w, 1'b0);
    $display("[T3Q-CHECKPOINT-RESTORE-NO-ISSUE] ready=%0b fire=%0b req_valid=%0b",
             dut.issue0_ready_w, dut.issue0_fire_w,
             dut.muldiv_req_valid_w);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check32("T3Q restore leaves MulDiv idle",
               {29'b0, dut.u_muldiv_unit.state_q}, 32'd0);
    reset_dut();

    // checkpoint_restore 与 flush 共享 resolve-stage flush 语义，也必须同拍
    // 屏蔽公开 payload。该 TB 的 recover_gprs 为零，因此碰撞验证后重新 reset
    // 恢复 canonical rename map。
    set_dispatch0(32'h8000_0828,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd0, 5'd0, 5'd0, 64'd8);
    dispatch0_bht_idx = 10'h0d3;
    dispatch0_pred_taken = 1'b1;
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N checkpoint-collision branch reaches raw lane0",
              dut.issue0_ctrlflow_fire_w, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N checkpoint-collision setup has resolve q",
              branch_resolve_valid, 1'b1);
    checkpoint_restore = 1'b1;
    #1;
    tb_check1("T3N checkpoint masks resolve valid immediately",
              branch_resolve_valid, 1'b0);
    tb_check64("T3N checkpoint masks resolve pc", branch_resolve_pc, 64'd0);
    tb_check64("T3N checkpoint masks resolve next pc",
               branch_resolve_next_pc, 64'd0);
    tb_check1("T3N checkpoint masks resolve mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check32("T3N checkpoint masks resolve ROB index",
               {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx}, 32'd0);
    tb_check32("T3N checkpoint masks resolve BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'd0);
    tb_check1("T3N checkpoint masks direct ROB kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    reset_dut();

    // 两条预测正确的顺序分支（均 not-taken）验证 stage 可连续每拍
    // consume/capture，且 lane1 分支先留队、次拍晋升 lane0；两个 payload 不得
    // 合并、丢失或乱序，也都不得触发 kill。
    set_dispatch0(32'h8000_0830,
                  make_branch_ctrl(`CMP_OP_NE),
                  5'd0, 5'd0, 5'd0, 64'd8);
    set_dispatch1(32'h8000_0834,
                  make_branch_ctrl(`CMP_OP_NE),
                  5'd0, 5'd0, 5'd0, 64'd8);
    dispatch0_pred_npc = 64'h0000_0000_8000_0834;
    dispatch1_pred_npc = 64'h0000_0000_8000_0838;
    dispatch0_bht_idx = 10'h155;
    dispatch1_bht_idx = 10'h2aa;
    #1;
    tb_check1("T3N branch pair lane0 dispatch ready", dispatch0_ready, 1'b1);
    tb_check1("T3N branch pair lane1 dispatch ready", dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N first branch issues on lane0", dut.issue0_ctrlflow_fire_w, 1'b1);
    tb_check1("T3N second branch not exposed on lane1", dut.issue1_valid_w, 1'b0);
    tb_check1("T3N branch stream has initial stage latency",
              branch_resolve_valid, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N first correct branch resolve", branch_resolve_valid, 1'b1);
    tb_check64("T3N first correct branch pc",
               branch_resolve_pc, 64'h0000_0000_8000_0830);
    tb_check64("T3N first correct branch next pc",
               branch_resolve_next_pc, 64'h0000_0000_8000_0834);
    tb_check1("T3N first correct branch not taken", branch_resolve_taken, 1'b0);
    tb_check1("T3N first correct branch no mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check32("T3N first correct branch keeps lane0 BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'h0000_0155);
    tb_check1("T3N second branch promotes while first resolves",
              dut.issue0_ctrlflow_fire_w, 1'b1);
    tb_check64("T3N promoted second branch raw pc",
               dut.issue0_pc_w, 64'h0000_0000_8000_0834);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N second correct branch resolve", branch_resolve_valid, 1'b1);
    tb_check64("T3N second correct branch pc",
               branch_resolve_pc, 64'h0000_0000_8000_0834);
    tb_check64("T3N second correct branch next pc",
               branch_resolve_next_pc, 64'h0000_0000_8000_0838);
    tb_check1("T3N second correct branch no mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check32("T3N promoted branch keeps lane1 BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'h0000_02aa);
    tb_check1("T3N correct branch stream never kills",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N two-branch stream ends exactly once",
              branch_resolve_valid, 1'b0);
    repeat (3) begin
      `TB_TICK(clk);
      clear_dispatch();
    end
    #1;
    tb_check32("T3N correct branch pair ROB drains", {27'b0, rob_count}, 32'd0);
    tb_check32("T3N correct branch pair IQ drains", {28'b0, issue_count}, 32'd0);

    // branch 最初是第二候选时必须留队，不能落到 lane1；下一拍它晋升 lane0，
    // 同时允许更年轻 ALU 走 lane1。若该 branch mispredict，年轻 ALU 即使已经
    // 进入 EX/WB，也不得越过 branch 提交。
    reset_dut();
    set_dispatch0(32'h8000_0840,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b0),
                  5'd0, 5'd0, 5'd0, 64'd1);
    set_dispatch1(32'h8000_0844,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd0, 5'd0, 5'd0, 64'd8);
    dispatch1_bht_idx = 10'h31c;
    #1;
    tb_check1("T3N second-candidate packet lane0 dispatch ready",
              dispatch0_ready, 1'b1);
    tb_check1("T3N second-candidate packet lane1 dispatch ready",
              dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N older ALU owns issue0", dut.issue0_valid_w, 1'b1);
    tb_check64("T3N older ALU issue pc", dut.issue0_pc_w,
               64'h0000_0000_8000_0840);
    tb_check1("T3N second-candidate branch excluded from issue1",
              dut.issue1_valid_w, 1'b0);
    tb_check1("T3N skipped branch was genuinely ready",
              dut.u_dispatch_backend.u_issue_queue.select_base_ready_w[1],
              1'b1);
    tb_check1("T3N skipped ready entry is branch",
              dut.u_dispatch_backend.u_issue_queue.ctrl_q[1][`CTRL_BRANCH_BIT],
              1'b1);
    tb_check32("T3N second-candidate branch remains resident",
               {28'b0, issue_count}, 32'd2);

    set_dispatch0(32'h8000_0848,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd9, 64'd99);
    #1;
    tb_check1("T3N younger wrong-path ALU dispatch ready",
              dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N retained branch promotes to lane0",
              dut.issue0_ctrlflow_fire_w, 1'b1);
    tb_check64("T3N promoted branch raw pc", dut.issue0_pc_w,
               64'h0000_0000_8000_0844);
    tb_check1("T3N younger wrong-path ALU may use lane1",
              dut.issue1_fire_w, 1'b1);
    tb_check64("T3N younger wrong-path ALU raw pc", dut.issue1_pc_w,
               64'h0000_0000_8000_0848);
    tb_check1("T3N promoted branch still observes stage latency",
              branch_resolve_valid, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N promoted branch resolve q valid",
              branch_resolve_valid, 1'b1);
    tb_check64("T3N promoted branch resolve pc", branch_resolve_pc,
               64'h0000_0000_8000_0844);
    tb_check1("T3N promoted branch is a mispredict",
              branch_resolve_mispredict, 1'b1);
    tb_check32("T3N second-candidate branch keeps BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'h0000_031c);
    tb_check1("T3N promoted branch q drives kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b1);
    tb_check1("T3N wrong-path ALU reached EX before kill", dut.ex1_valid_q, 1'b1);
    tb_check32("T3N wrong-path EX keeps younger ROB identity",
               {{(32-ROB_INDEX_W){1'b0}}, dut.ex1_rob_idx_q}, 32'd2);
    tb_check1("T3N q kill suppresses head commit", commit0_valid, 1'b0);
    tb_check1("T3N q kill suppresses second commit", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N promoted resolve exactly once", branch_resolve_valid, 1'b0);
    tb_check1("T3N promoted kill exactly once",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    tb_check1("T3N wrong-path cannot commit in first walk cycle",
              (commit0_valid && (commit0_pc == 64'h0000_0000_8000_0848)) ||
              (commit1_valid && (commit1_pc == 64'h0000_0000_8000_0848)),
              1'b0);
    repeat (5) begin
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3N wrong-path never commits during recovery",
                (commit0_valid && (commit0_pc == 64'h0000_0000_8000_0848)) ||
                (commit1_valid && (commit1_pc == 64'h0000_0000_8000_0848)),
                1'b0);
    end
    tb_check32("T3N second-candidate ROB drains",
               {27'b0, rob_count}, 32'd0);
    tb_check32("T3N second-candidate IQ drains",
               {28'b0, issue_count}, 32'd0);
    tb_check32("T3N second-candidate freelist recovers",
               {25'b0, free_count}, 32'd32);

    set_dispatch0(32'h8000_1000,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_COPY_B,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd9, 32'h1234_5000);
    set_dispatch1(32'h8000_1004,
                  make_alu_ctrl(`OP1_SEL_PC, `OP2_SEL_FOUR, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd10, 32'd0);
    tick_dispatch_to_commit("operand select", 32'h1234_5000, 32'h8000_1008);

    set_dispatch0(32'h8000_1800,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_COPY_B,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd17, 64'hf0f1_0001_0000_0000);
    #1;
    tb_check1("bitmanip setup dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    // 【P5 刀 B】setup uop 需 issue(次拍)+EX/commit(再次拍):先排干再投依赖对,
    // 避免 rob 残留与 x17 busy 未清。
    `TB_TICK(clk);
    #1;
    tb_check1("bitmanip setup formal WB visible", dut.wb0_valid_w, 1'b1);
    tb_check1("bitmanip setup does not commit on formal WB",
              commit0_valid, 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check1("bitmanip setup commits from ROB Q", commit0_valid, 1'b1);
    tb_check64("bitmanip setup commit data from ROB Q",
               commit0_data, 64'hf0f1_0001_0000_0000);
    `TB_TICK(clk);
    #1;
    tb_check32("bitmanip setup drains", {27'b0, rob_count}, 32'd0);

    // Zbb count 类指令走 bitmanip helper 的 byte 分层组合树，direct TB 锁住 64-bit 边界值。
    set_dispatch0(32'h8000_1810, make_bitmanip_ctrl(),
                  5'd17, 5'd0, 5'd18, 64'd0);
    dispatch0_inst = inst_op_imm(7'h30, 5'h00, 5'd17,
                                 `FUNCT3_SLL, 5'd18);
    set_dispatch1(32'h8000_1814, make_bitmanip_ctrl(),
                  5'd17, 5'd0, 5'd19, 64'd0);
    dispatch1_inst = inst_op_imm(7'h30, 5'h01, 5'd17,
                                 `FUNCT3_SLL, 5'd19);
    tick_lane0_serial_pair_to_commit("T3P bitmanip clz ctz",
                                     32'd0, 32'd32);

    set_dispatch0(32'h8000_1820, make_bitmanip_ctrl(),
                  5'd17, 5'd0, 5'd20, 64'd0);
    dispatch0_inst = inst_op_imm(7'h30, 5'h02, 5'd17,
                                 `FUNCT3_SLL, 5'd20);
    set_dispatch1(32'h8000_1824, make_bitmanip_ctrl(),
                  5'd0, 5'd0, 5'd21, 64'd0);
    dispatch1_inst = inst_op_imm(7'h30, 5'h00, 5'd0,
                                 `FUNCT3_SLL, 5'd21);
    tick_lane0_serial_pair_to_commit("T3P bitmanip cpop clz-zero",
                                     32'd10, 32'd64);

    set_dispatch0(32'h8000_1840,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                `ALU_OP_COPY_B, 1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd22, 64'h1234_5678_9abc_def0);
    set_dispatch1(32'h8000_1844,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                `ALU_OP_COPY_B, 1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd23, 64'hfedc_ba98_7654_3210);
    tick_dispatch_to_commit("clmul setup operands",
                            64'h1234_5678_9abc_def0,
                            64'hfedc_ba98_7654_3210);

    run_clmul_backend_case("backend clmul", 32'h8000_1850,
                           `FUNCT3_SLL, 5'd24, 2'd0);
    run_clmul_backend_case("backend clmulh", 32'h8000_1860,
                           `FUNCT3_SLT, 5'd25, 2'd1);
    run_clmul_backend_case("backend clmulr", 32'h8000_1870,
                           `FUNCT3_SLTU, 5'd26, 2'd2);

    set_dispatch0(32'h8000_2000,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd11, 32'd11);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    // 【P5 刀 B】dispatch 次拍 issue、再次拍才进 EX;flush 打在 EX 拍。
    tb_check32("flush setup queued", {28'b0, issue_count}, 32'd1);
    `TB_TICK(clk);
    #1;
    tb_check1("flush setup execute valid", execute0_valid, 1'b1);
    flush = 1'b1;
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("flush clears execute0", execute0_valid, 1'b0);
	    tb_check1("flush clears execute1", execute1_valid, 1'b0);
	    tb_check32("flush clears rob", {27'b0, rob_count}, 32'd0);
	    tb_check32("flush clears issue queue", {28'b0, issue_count}, 32'd0);
	    tb_check32("flush restores freelist", {25'b0, free_count}, 32'd32);

    // dual-load 第二端口(mem1)死硅删除:原"两 load 同拍双端口发射"用例已无效,移除。
    // 两 load 串行经主端口 mem0 的覆盖由下方 buffer-seed 用例与 riscv-tests 承担。
	    mem_rsp_valid = 1'b0;
	    set_dispatch0(32'h8000_2600,
	                  make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
	                  5'd0, 5'd0, 5'd15, 32'h8000_0270);  // 【F2】EA 入 pmem: 非 pmem load 现按 MMIO 队头独占, 本场景测 buffer 串行化
	    #1;
	    tb_check1("buffer seed load dispatch ready", dispatch0_ready, 1'b1);
	    t3g_load0_pdest = dut.dispatch0_pdest_w;
	    // 【P5 刀 B】load 不再 dispatch 拍直通:req 在 issue 拍(次拍)组合出 AGU 才可见。
	    tb_check1("no same-cycle load request", mem_req_valid, 1'b0);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check1("T3S buffer seed capture has no early request",
	              mem_req_valid, 1'b0);
	    tb_check1("T3S buffer seed reservation capture pending",
	              dut.mem_issue_res_capture_w, 1'b1);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("buffer seed load request visible", mem_req_valid, 1'b1);
	    tb_check1("buffer seed load is read", mem_req_write, 1'b0);
	    tb_check32("buffer seed load addr", mem_req_addr, 32'h8000_0270);

	    set_dispatch0(32'h8000_2604,
	                  make_load_ctrl(`MEM_SIZE_HALF, 1'b1),
	                  5'd0, 5'd0, 5'd16, 32'h8000_0276);
	    #1;
	    tb_check1("buffered lhu dispatch ready", dispatch0_ready, 1'b1);
	    t3g_load1_pdest = dut.dispatch0_pdest_w;
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check1("T3S lhu capture has no early request",
	              mem_req_valid, 1'b0);
	    tb_check1("T3S lhu reservation capture pending",
	              dut.mem_issue_res_capture_w, 1'b1);
	    `TB_TICK(clk);
	    #1;
	    // 【LSQ/MIQ 语义】plain load 背靠背在飞(rsp 恒配 MIQ 队头), 旧"单例串行等待"
	    // 断言依赖第一条 load 落 MMIO 区占 mem_pending 的巧合, 地址入 pmem 后按真语义更新。
	    // 【P5 刀 B】第二条 load 的 req 同样在其 issue 拍(dispatch 次拍)可见。
	    tb_check1("plain lhu back-to-back issues", mem_req_valid, 1'b1);
	    tb_check1("plain lhu back-to-back is read", mem_req_write, 1'b0);
	    tb_check32("plain lhu back-to-back addr", mem_req_addr, 32'h8000_0276);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("no third request in flight", mem_req_valid, 1'b0);

	    // T3G 正向覆盖：在首条 load 返回前放入真实依赖者。MEM response 拍只
	    // formal-WB；沿上写 PRF/ready sticky，依赖者下一拍从 regs_q 发射。
	    set_dispatch0(32'h8000_2608,
	                  make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
	                                `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
	                  5'd15, 5'd0, 5'd17, 64'd1);
	    #1;
	    tb_check1("load-use dependent dispatch ready", dispatch0_ready, 1'b1);
	    t3g_dependent_pdest = dut.dispatch0_pdest_w;
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check32("load-use dependent remains resident",
	               {28'b0, issue_count}, 32'd1);
	    tb_check1("load-use dependent waits before response",
	              dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);

	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 64'h0000_0000_1234_5678;
		    mem_rsp_error = 1'b0;
		    #1;
		    tb_check1("buffer seed rsp ready", mem_rsp_ready, 1'b1);
		    tb_check1("buffer seed has no commit on formal WB",
		              commit0_valid, 1'b0);
	    tb_check1("load MEM formal WB0 valid", dut.wb0_valid_w, 1'b1);
	    tb_check32("load MEM formal WB0 pdest",
	               {26'b0, dut.wb0_pdest_w},
	               {26'b0, t3g_load0_pdest});
	    tb_check64("load MEM formal WB0 data", dut.wb0_data_w,
	               64'h0000_0000_1234_5678);
	    tb_check1("load-use does not select on response",
	              dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
	    $display("[T3M-RED-OBS] mem-N formal0=%0b pdest=%0d issue={%0b,%0b}",
	             dut.wb0_valid_w, dut.wb0_pdest_w,
	             dut.issue0_valid_w, dut.issue1_valid_w);
	    `TB_TICK(clk);
		    mem_rsp_valid = 1'b0;
		    #1;
		    tb_check1("buffer seed commits from ROB Q", commit0_valid, 1'b1);
		    tb_check64("buffer seed commit data from ROB Q",
		               commit0_data, 64'h0000_0000_1234_5678);
		    tb_check1("load-use selects after sticky edge", dut.issue0_valid_w, 1'b1);
	    tb_check32("load-use selected PC after sticky edge",
	               dut.issue0_pc_w[31:0], 32'h8000_2608);
	    tb_check32("load-use source tag is load pdest",
	               {26'b0, dut.issue0_src1_preg_w},
	               {26'b0, t3g_load0_pdest});
	    tb_check64("load-use source data reads stored PRF",
	               dut.issue0_src1_data_w, 64'h0000_0000_1234_5678);
	    $display("[T3G-COVERAGE-OBS] mem-N+1 issue0_pc=0x%08h preg=%0d stored=0x%016h",
	             dut.issue0_pc_w[31:0], dut.issue0_src1_preg_w,
	             dut.issue0_src1_data_w);
	    // 把 dependent add 推进 EX；下一拍与第二条 load response 形成 EX0+MEM1。
	    `TB_TICK(clk);
	    #1;

	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 64'h0000_0000_0000_1800;
		    mem_rsp_error = 1'b0;
		    #1;
		    tb_check1("buffered lhu rsp ready", mem_rsp_ready, 1'b1);
		    tb_check1("mixed EX/MEM has no commit0 on formal WB",
		              commit0_valid, 1'b0);
		    tb_check1("mixed EX/MEM has no commit1 on formal WB",
		              commit1_valid, 1'b0);
	    // dependent add 此拍占 formal WB0；第二条 load 自然落 formal WB1。
	    tb_check1("dependent EX formal WB0 valid", dut.wb0_valid_w, 1'b1);
	    tb_check32("dependent EX formal WB0 pdest",
	               {26'b0, dut.wb0_pdest_w},
	               {26'b0, t3g_dependent_pdest});
	    tb_check64("dependent EX formal WB0 data", dut.wb0_data_w,
	               64'h0000_0000_1234_5679);
	    tb_check1("buffered lhu formal WB1 valid", dut.wb1_valid_w, 1'b1);
	    tb_check32("buffered lhu formal WB1 pdest",
	               {26'b0, dut.wb1_pdest_w},
	               {26'b0, t3g_load1_pdest});
	    tb_check64("buffered lhu formal WB1 data", dut.wb1_data_w,
	               64'h0000_0000_0000_1800);
	    $display("[T3M-COVERAGE-OBS] mixed ex-formal0={%0b,%0d,0x%016h} mem-formal1={%0b,%0d,0x%016h}",
	             dut.wb0_valid_w, dut.wb0_pdest_w, dut.wb0_data_w,
	             dut.wb1_valid_w, dut.wb1_pdest_w, dut.wb1_data_w);
		    `TB_TICK(clk);
		    mem_rsp_valid = 1'b0;
		    #1;
		    tb_check1("buffered lhu commits from ROB Q",
		              commit0_valid, 1'b1);
		    tb_check64("buffered lhu commit data from ROB Q",
		               commit0_data, 64'h0000_0000_0000_1800);
		    tb_check1("dependent commits beside lhu from ROB Q",
		              commit1_valid, 1'b1);
		    tb_check64("dependent commit data beside lhu",
		               commit1_data, 64'h0000_0000_1234_5679);
		    `TB_TICK(clk);
		    #1;
		    tb_check32("buffered lhu rob drains", {27'b0, rob_count}, 32'd0);
	    tb_check32("buffered lhu iq drains", {28'b0, issue_count}, 32'd0);
	    tb_check32("buffered lhu freelist recovers", {25'b0, free_count}, 32'd32);

		    set_dispatch0(32'h8000_2800,
		                  make_store_ctrl(`MEM_SIZE_WORD),
		                  5'd0, 5'd0, 5'd0, 32'h0000_0200);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check1("T3S store capture has no early request",
	              mem_req_valid, 1'b0);
	    tb_check1("T3S store reservation capture pending",
	              dut.mem_issue_res_capture_w, 1'b1);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("store starts memory request", mem_req_valid, 1'b1);
	    tb_check1("store request is write", mem_req_write, 1'b1);
	    tb_check32("store request addr", mem_req_addr, 32'h0000_0200);
	    tb_check1("store first request is probe", mem_req_probe, 1'b1);

	    // Accept probe, then return a distinct PA.  Probe success must fill SQ
	    // without consuming formal WB or making the ROB entry committable.
	    `TB_TICK(clk);
	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 64'h0000_0000_8000_0200;
	    mem_rsp_error = 1'b0;
	    #1;
	    tb_check1("store probe success ready", mem_rsp_ready, 1'b1);
	    tb_check1("store probe success has no WB", dut.mem_wb_fire_w, 1'b0);
	    tb_check1("store probe success has no commit", commit0_valid, 1'b0);
	    `TB_TICK(clk);
	    mem_rsp_valid = 1'b0;
	    mem_rsp_rdata = {`XLEN{1'b0}};
	    #1;
	    tb_check1("store physical request visible", mem_req_valid, 1'b1);
	    tb_check1("store physical request write", mem_req_write, 1'b1);
	    tb_check64("store physical request uses PA", mem_req_addr,
	               64'h0000_0000_8000_0200);
	    tb_check1("store physical request pretrans", mem_req_pretrans, 1'b1);
	    tb_check1("store physical request nokill", mem_req_nokill, 1'b1);
	    tb_check1("store physical request not probe", mem_req_probe, 1'b0);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("store physical request at-most-once", mem_req_valid, 1'b0);
	    tb_check1("store cannot commit before B", commit0_valid, 1'b0);
	    set_dispatch0(32'h8000_2810,
	                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
	                                1'b0, 1'b0, 1'b1),
	                  5'd0, 5'd0, 5'd13, 32'd21);
	    set_dispatch1(32'h8000_2814,
	                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
	                                1'b0, 1'b0, 1'b1),
	                  5'd0, 5'd0, 5'd14, 32'd22);
	    #1;
	    tb_check1("dual alu dispatch under mem pending lane0 ready", dispatch0_ready, 1'b1);
	    tb_check1("dual alu dispatch under mem pending lane1 ready", dispatch1_ready, 1'b1);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    // 【P5 刀 B】双 ALU 先入队,次拍双发,再次拍进 EX——wb 口占满/rsp 反压后移一拍。
	    tb_check32("dual alu under mem pending queued", {28'b0, issue_count}, 32'd2);
	    `TB_TICK(clk);
	    #1;
	    tb_check32("dual alu under mem pending issues", {28'b0, issue_count}, 32'd0);
	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 32'h0;
	    mem_rsp_error = 1'b0;
	    #1;
	    tb_check1("dual alu under mem pending execute0", execute0_valid, 1'b1);
	    tb_check1("dual alu under mem pending execute1", execute1_valid, 1'b1);
	    tb_check1("full wb ports backpressure mem rsp", mem_rsp_ready, 1'b0);
	    tb_check1("head store cannot commit while rsp backpressured", commit0_valid, 1'b0);

		    `TB_TICK(clk);
		    #1;
		    tb_check1("mem rsp accepted after wb port frees", mem_rsp_ready, 1'b1);
		    tb_check1("store has no commit on response/formal-WB",
		              commit0_valid, 1'b0);
		    tb_check1("younger ALU cannot pass incomplete store",
		              commit1_valid, 1'b0);

		    `TB_TICK(clk);
		    mem_rsp_valid = 1'b0;
		    #1;
		    tb_check1("store commits from ROB Q", commit0_valid, 1'b1);
		    tb_check1("first ALU commits beside store from ROB Q",
		              commit1_valid, 1'b1);
		    tb_check1("store has no rd write", commit0_rd_en, 1'b0);
		    tb_check64("first ALU data beside delayed store",
		               commit1_data, 64'd21);

		    `TB_TICK(clk);
		    #1;
		    tb_check1("second ALU commits after delayed store pair",
		              commit0_valid, 1'b1);
		    tb_check64("second ALU data after delayed store pair",
		               commit0_data, 64'd22);

		    `TB_TICK(clk);
		    #1;
		    tb_check32("dual alu mem overlap rob drains", {27'b0, rob_count}, 32'd0);
	    tb_check32("dual alu mem overlap iq drains", {28'b0, issue_count}, 32'd0);
	    tb_check32("dual alu mem overlap freelist recovers", {25'b0, free_count}, 32'd32);

	    mem_rsp_valid = 1'b0;
	    set_dispatch0(32'h8000_3000,
	                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
	                                1'b0, 1'b0, 1'b1),
	                  5'd0, 5'd0, 5'd12, 32'h0000_0055);
	    set_dispatch1(32'h8000_3004,
	                  make_store_ctrl(`MEM_SIZE_WORD),
	                  5'd0, 5'd0, 5'd0, 32'h0000_0100);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
    // R3 capability steering：较年轻 store 取得 Universal/memory reservation，
    // 较老 simple ALU 同拍改走物理 ALU terminal。仍只有一个 LSU owner；store
    // 必须先原子捕获 reservation，下一拍才可产生唯一 probe request。
    tb_check32("alu+store pair queued", {28'b0, issue_count}, 32'd2);
    `TB_TICK(clk);
    #1;
    tb_check32("R3 ALU+store both leave IQ", {28'b0, issue_count}, 32'd0);
    tb_check1("R3 older ALU executes on ALU terminal", execute1_valid, 1'b1);
    tb_check1("R3 older ALU formal WB1 visible", dut.wb1_valid_w, 1'b1);
    tb_check64("R3 older ALU formal WB1 data",
               dut.wb1_data_w, 64'h0000_0000_0000_0055);
    tb_check1("R3 younger store captured exactly-once reservation",
              dut.mem_issue_res_valid_q, 1'b1);
    tb_check1("R3 ALU has no commit on formal WB", commit0_valid, 1'b0);
    wait_mem0_request("R3 younger store", 1'b1, 32'h0000_0100,
                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
    tb_check1("R3 younger store first request is probe", mem_req_probe, 1'b1);
    `TB_TICK(clk);
    #1;
    tb_check1("R3 request consumes reservation once",
              dut.mem_issue_res_valid_q, 1'b0);
    tb_check1("R3 older ALU commits from ROB Q", commit0_valid, 1'b1);
    tb_check64("R3 older ALU commit data from ROB Q",
               commit0_data, 64'h0000_0000_0000_0055);
    `TB_TICK(clk);
    #1;
    tb_check1("R3 older ALU commits exactly once", commit0_valid, 1'b0);
    complete_sq_store_after_probe("R3 younger store",
                                  64'h0000_0000_0000_0100,
                                  64'h0000_0000_8000_0100,
                                  1'b1, 1'b0);
    tb_check32("R3 younger store rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("R3 younger store iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("R3 younger store freelist recovers", {25'b0, free_count}, 32'd32);

    set_dispatch0(32'h8000_4000,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd1, 32'h0000_0300);
    set_dispatch1(32'h8000_4004,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd2, 32'd5);
    tick_dispatch_to_commit("amo setup base/value", 32'h0000_0300, 32'd5);

    mem_rsp_valid = 1'b0;
    set_dispatch0(32'h8000_4010,
                  make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                  5'd1, 5'd0, 5'd3, 32'd0);
    dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd1, `FUNCT3_LD, 5'd3);
    #1;
    tb_check1("lr.d dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    wait_mem0_request("lr.d", 1'b0, 32'h0000_0300,
                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
    `TB_TICK(clk);
    #1;
    complete_mem0_response("lr.d", 64'h1111_2222_3333_4444,
                           1'b1, 1'b1, 1'b1,
                           64'h1111_2222_3333_4444);

    set_dispatch0(32'h8000_4020,
                  make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1),
                  5'd1, 5'd2, 5'd4, 32'd0);
    dispatch0_inst = inst_amo(5'b00011, 5'd2, 5'd1, `FUNCT3_LD, 5'd4);
    #1;
    tb_check1("sc.d success dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    wait_mem0_request("sc.d success", 1'b1, 32'h0000_0300,
                      1'b1, 32'd5, 1'b1, 8'hff);
    `TB_TICK(clk);
    #1;
    complete_mem0_response("sc.d success", {`XLEN{1'b0}},
                           1'b1, 1'b1, 1'b1, {`XLEN{1'b0}});

    set_dispatch0(32'h8000_4030,
                  make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1),
                  5'd1, 5'd2, 5'd4, 32'd0);
    dispatch0_inst = inst_amo(5'b00011, 5'd2, 5'd1, `FUNCT3_LD, 5'd4);
    #1;
    tb_check1("sc.d fail dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("sc.d fail has no memory write", mem_req_valid, 1'b0);
    tb_check1("T3S sc.d fail reservation capture pending",
              dut.mem_issue_res_capture_w, 1'b1);
    `TB_TICK(clk);
    #1;
    tb_check1("T3S sc.d fail station still has no memory write",
              mem_req_valid, 1'b0);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("sc.d fail formal WB visible", dut.wb0_valid_w, 1'b1);
	    tb_check64("sc.d fail formal status is one", dut.wb0_data_w, 64'd1);
	    tb_check1("sc.d fail has no commit on formal WB",
	              commit0_valid, 1'b0);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("sc.d fail commits from ROB Q", commit0_valid, 1'b1);
	    tb_check64("sc.d fail returns one from ROB Q", commit0_data, 64'd1);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("sc.d fail commits exactly once", commit0_valid, 1'b0);

	    set_dispatch0(32'h8000_4040,
                  make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b0),
                  5'd1, 5'd2, 5'd5, 32'd0);
    dispatch0_inst = inst_amo(5'b00000, 5'd2, 5'd1, `FUNCT3_LD, 5'd5);
    #1;
    tb_check1("amoadd.d dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    wait_mem0_request("amoadd.d read", 1'b0, 32'h0000_0300,
                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
    `TB_TICK(clk);
    #1;
    complete_mem0_response("amoadd.d read", 64'd7,
                           1'b0, 1'b0, 1'b0, {`XLEN{1'b0}});
    wait_mem0_request("amoadd.d write", 1'b1, 32'h0000_0300,
                      1'b1, 32'd12, 1'b0, {`STRB_W{1'b0}});
    `TB_TICK(clk);
    #1;
    complete_mem0_response("amoadd.d write", {`XLEN{1'b0}},
                           1'b1, 1'b1, 1'b1, 64'd7);
    tb_check32("amo sequence rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("amo sequence iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("amo sequence freelist recovers", {25'b0, free_count}, 32'd32);

    set_dispatch0(32'h8000_4050,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd1, 32'h0000_0304);
    set_dispatch1(32'h8000_4054,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd2, 32'd1);
    tick_dispatch_to_commit("amo word x0 setup", 32'h0000_0304, 32'd1);

    mem_rsp_valid = 1'b0;
    set_dispatch0(32'h8000_4060,
                  make_amo_ctrl(`MEM_SIZE_WORD, 1'b0, 1'b0),
                  5'd1, 5'd2, 5'd0, 32'd0);
    dispatch0_inst = inst_amo(5'b00000, 5'd2, 5'd1, `FUNCT3_LW, 5'd0);
    #1;
    tb_check1("amoadd.w x0 dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    wait_mem0_request("amoadd.w x0 read", 1'b0, 32'h0000_0304,
                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
    `TB_TICK(clk);
    #1;
    complete_mem0_response("amoadd.w x0 read", 64'd7,
                           1'b0, 1'b0, 1'b0, {`XLEN{1'b0}});
    wait_mem0_request("amoadd.w x0 write", 1'b1, 32'h0000_0304,
                      1'b1, 32'd8, 1'b1, 8'h0f);
    `TB_TICK(clk);
    #1;
    complete_mem0_response("amoadd.w x0 write", {`XLEN{1'b0}},
                           1'b1, 1'b0, 1'b1, 64'd7);
    tb_check32("amoadd.w x0 rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("amoadd.w x0 iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("amoadd.w x0 freelist recovers", {25'b0, free_count}, 32'd32);

    run_t3s_mem_issue_reservation_contract();
    run_t3s_mem_issue_age_liveness();
    run_t3v_mem_buffer_selective_kill_contract();
    run_s2_g1_effective_kill_response_contract();
    run_s2_g1_amo_restore_and_grant_contract();
`ifndef OOO_ASSERT
    run_s2_g1_empty_miq_stale_drain_contract();
`endif
    run_t3v_miq_full_pop_parent_backpressure_contract();
    run_t3v_lrsc_width_and_exception_contract();
    run_r3_alu_terminal_no_lsu_contract();
    run_r3p1_swapped_mmio_atomic_contract();
    run_r3p1_divu_eight_younger_contract();
`endif
`endif

    // T3P 后 memory/AMO 不再是 lane1 可达类别；IQ focused 用例已覆盖
    // “跳过复杂项选择年轻 simple、复杂项随后晋升 lane0”，下方所有真实访存
    // 场景继续从 lane0 request/MIQ owner 路径验证完整功能。

	    tb_finish("tb_ooo_int_backend");
  end
endmodule
