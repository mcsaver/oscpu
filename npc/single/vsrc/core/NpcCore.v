`include "define.v"

module NpcCore (
  input clk,
  input rst,

  output ifu_axi_arvalid_o,
  input ifu_axi_arready_i,
  output [`XLEN-1:0] ifu_axi_araddr_o,
  input ifu_axi_rvalid_i,
  output ifu_axi_rready_o,
  input [`XLEN-1:0] ifu_axi_rdata_i,
  input [1:0] ifu_axi_rresp_i,

  output lsu_axi_arvalid_o,
  input lsu_axi_arready_i,
  output [`XLEN-1:0] lsu_axi_araddr_o,
  input lsu_axi_rvalid_i,
  output lsu_axi_rready_o,
  input [`XLEN-1:0] lsu_axi_rdata_i,
  input [1:0] lsu_axi_rresp_i,
  output lsu_axi_awvalid_o,
  input lsu_axi_awready_i,
  output [`XLEN-1:0] lsu_axi_awaddr_o,
  output lsu_axi_wvalid_o,
  input lsu_axi_wready_i,
  output [`XLEN-1:0] lsu_axi_wdata_o,
  output [3:0] lsu_axi_wstrb_o,
  input lsu_axi_bvalid_i,
  output lsu_axi_bready_o,
  input [1:0] lsu_axi_bresp_i,

  input irq_software_i,
  input irq_timer_i,
  input irq_external_i,

  output commit_valid_o,
  output [`XLEN-1:0] commit_pc_o,
  output [`INST_W-1:0] commit_inst_o,
  output [`XLEN-1:0] commit_next_pc_o,
  output commit_rd_en_o,
  output [`REG_ADDR_W-1:0] commit_rd_addr_o,
  output [`XLEN-1:0] commit_rd_data_o,

  output trap_valid_o,
  output [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output [`XLEN-1:0] trap_pc_o,
  output [`XLEN-1:0] trap_tval_o,
  output exit_valid_o,
  output exit_is_ecall_o,
  output exit_is_ebreak_o,
  output [`XLEN-1:0] exit_code_o,
  output halted_o,

  output [`XLEN-1:0] debug_pc_o,
  output [`CORE_STATE_W-1:0] debug_state_o,
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o
);

  function [`XLEN-1:0] rv32b_result;
    /* verilator lint_off UNUSEDSIGNAL */
    input [`INST_W-1:0] inst;
    /* verilator lint_on UNUSEDSIGNAL */
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    reg [4:0] imm5;
    reg [4:0] shamt;
    reg [5:0] inv_shamt;
    integer i;
    begin
      imm5 = inst[24:20];
      shamt = src2[`SHIFT_AMT_W-1:0];
      inv_shamt = 6'd32 - {1'b0, shamt};
      rv32b_result = {`XLEN{1'b0}};

      if (inst[6:0] == `OPCODE_OP_IMM) begin
        case ({inst[31:25], inst[14:12]})
          {7'h14, `FUNCT3_SLL}:     rv32b_result = src1 | (32'h1 << imm5);
          {7'h24, `FUNCT3_SLL}:     rv32b_result = src1 & ~(32'h1 << imm5);
          {7'h34, `FUNCT3_SLL}:     rv32b_result = src1 ^ (32'h1 << imm5);
          {7'h30, `FUNCT3_SRL_SRA}: rv32b_result = (imm5 == 5'h0) ? src1 :
                                                     ((src1 >> imm5) | (src1 << (6'd32 - {1'b0, imm5})));
          {7'h24, `FUNCT3_SRL_SRA}: rv32b_result = {{(`XLEN-1){1'b0}}, src1[imm5]};
          {7'h14, `FUNCT3_SRL_SRA}: rv32b_result = {
              (src1[31:24] != 8'h00) ? 8'hff : 8'h00,
              (src1[23:16] != 8'h00) ? 8'hff : 8'h00,
              (src1[15:8]  != 8'h00) ? 8'hff : 8'h00,
              (src1[7:0]   != 8'h00) ? 8'hff : 8'h00
          };
          {7'h34, `FUNCT3_SRL_SRA}: rv32b_result = {src1[7:0], src1[15:8], src1[23:16], src1[31:24]};
          {7'h30, `FUNCT3_SLL}: begin
            case (imm5)
              5'h00: begin
                rv32b_result = 32'd32;
                for (i = 0; i < 32; i = i + 1) begin
                  if (src1[31 - i] && (rv32b_result == 32'd32))
                    rv32b_result = i;
                end
              end
              5'h01: begin
                rv32b_result = 32'd32;
                for (i = 0; i < 32; i = i + 1) begin
                  if (src1[i] && (rv32b_result == 32'd32))
                    rv32b_result = i;
                end
              end
              5'h02: begin
                rv32b_result = {`XLEN{1'b0}};
                for (i = 0; i < 32; i = i + 1)
                  rv32b_result = rv32b_result + {{(`XLEN-1){1'b0}}, src1[i]};
              end
              5'h04: rv32b_result = {{24{src1[7]}}, src1[7:0]};
              5'h05: rv32b_result = {{16{src1[15]}}, src1[15:0]};
              default: begin end
            endcase
          end
          default: begin end
        endcase
      end else begin
        case ({inst[31:25], inst[14:12]})
          {7'h10, `FUNCT3_SLT}:     rv32b_result = (src1 << 1) + src2;
          {7'h10, `FUNCT3_XOR}:     rv32b_result = (src1 << 2) + src2;
          {7'h10, `FUNCT3_OR}:      rv32b_result = (src1 << 3) + src2;
          {7'h20, `FUNCT3_AND}:     rv32b_result = src1 & ~src2;
          {7'h20, `FUNCT3_OR}:      rv32b_result = src1 | ~src2;
          {7'h20, `FUNCT3_XOR}:     rv32b_result = ~(src1 ^ src2);
          {7'h30, `FUNCT3_SLL}:     rv32b_result = (shamt == 5'h0) ? src1 :
                                                     ((src1 << shamt) | (src1 >> inv_shamt));
          {7'h30, `FUNCT3_SRL_SRA}: rv32b_result = (shamt == 5'h0) ? src1 :
                                                     ((src1 >> shamt) | (src1 << inv_shamt));
          {7'h05, `FUNCT3_XOR}:     rv32b_result = ($signed(src1) < $signed(src2)) ? src1 : src2;
          {7'h05, `FUNCT3_SRL_SRA}: rv32b_result = (src1 < src2) ? src1 : src2;
          {7'h05, `FUNCT3_OR}:      rv32b_result = ($signed(src1) > $signed(src2)) ? src1 : src2;
          {7'h05, `FUNCT3_AND}:     rv32b_result = (src1 > src2) ? src1 : src2;
          {7'h14, `FUNCT3_SLL}:     rv32b_result = src1 | (32'h1 << shamt);
          {7'h24, `FUNCT3_SLL}:     rv32b_result = src1 & ~(32'h1 << shamt);
          {7'h24, `FUNCT3_SRL_SRA}: rv32b_result = {{(`XLEN-1){1'b0}}, src1[shamt]};
          {7'h34, `FUNCT3_SLL}:     rv32b_result = src1 ^ (32'h1 << shamt);
          {7'h04, `FUNCT3_XOR}:     rv32b_result = {16'h0000, src1[15:0]};
          {7'h05, `FUNCT3_SLL}: begin
            rv32b_result = {`XLEN{1'b0}};
            for (i = 0; i < 32; i = i + 1) begin
              if (src2[i])
                rv32b_result = rv32b_result ^ (src1 << i);
            end
          end
          {7'h05, `FUNCT3_SLT}: begin
            rv32b_result = {`XLEN{1'b0}};
            for (i = 0; i < 32; i = i + 1) begin
              if (src2[i])
                rv32b_result = rv32b_result ^ (src1 >> (31 - i));
            end
          end
          {7'h05, `FUNCT3_SLTU}: begin
            rv32b_result = {`XLEN{1'b0}};
            for (i = 1; i < 32; i = i + 1) begin
              if (src2[i])
                rv32b_result = rv32b_result ^ (src1 >> (32 - i));
            end
          end
          default: begin end
        endcase
      end
    end
  endfunction

  // BPU/cache 等结构参数统一由 define.v 管理，避免 core 内部再散落可调常量。

  wire fetch_pending_w;
  wire [`XLEN-1:0] fetch_pc_w;
  wire if_stage_valid_w;
  wire [`XLEN-1:0] if_stage_pc_w;
  wire [`INST_W-1:0] if_stage_inst_w;
  wire [`XLEN-1:0] if_stage_inst_len_w;
  wire [`XLEN-1:0] if_stage_pred_pc_w;
  wire [`BPU_BHT_INDEX_W-1:0] if_stage_bht_idx_w;
  wire if_stage_error_w;
  wire ifu_cpu_req_valid_w;
  wire ifu_cpu_req_ready_w;
  wire [`XLEN-1:0] ifu_cpu_req_addr_w;
  wire ifu_cpu_rsp_valid_w;
  wire ifu_cpu_rsp_ready_w;
  wire [`XLEN-1:0] ifu_cpu_rsp_data_w;
  wire ifu_cpu_rsp_error_w;

  wire if_id_valid_q;
  wire [`XLEN-1:0] if_id_pc_q;
  wire [`INST_W-1:0] if_id_inst_q;
  wire [`XLEN-1:0] if_id_inst_len_q;
  wire [`XLEN-1:0] if_id_pred_pc_q;
  wire [`BPU_BHT_INDEX_W-1:0] if_id_bht_idx_q;
  wire if_id_error_q;

  wire id_ex_valid_q;
  wire [`XLEN-1:0] id_ex_pc_q;
  wire [`INST_W-1:0] id_ex_inst_q;
  wire [`XLEN-1:0] id_ex_inst_len_q;
  wire [`XLEN-1:0] id_ex_pred_pc_q;
  wire [`BPU_BHT_INDEX_W-1:0] id_ex_bht_idx_q;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [`CTRL_BUS_W-1:0] id_ex_ctrl_q;
  /* verilator lint_on UNUSEDSIGNAL */
  wire [`XLEN-1:0] id_ex_imm_q;
  wire [`REG_ADDR_W-1:0] id_ex_rs1_idx_q;
  wire [`REG_ADDR_W-1:0] id_ex_rs2_idx_q;
  wire [`REG_ADDR_W-1:0] id_ex_rd_idx_q;
  wire [`XLEN-1:0] id_ex_rs1_data_q;
  wire [`XLEN-1:0] id_ex_rs2_data_q;
  wire id_ex_fetch_error_q;

  wire ex_mem_valid_q;
  wire [`XLEN-1:0] ex_mem_pc_q;
  wire [`INST_W-1:0] ex_mem_inst_q;
  wire [`XLEN-1:0] ex_mem_next_pc_q;
  wire ex_mem_load_q;
  wire ex_mem_store_q;
  wire ex_mem_rd_en_q;
  wire ex_mem_need_wb_q;
  wire [1:0] ex_mem_mem_size_q;
  wire ex_mem_mem_unsigned_q;
  wire [`REG_ADDR_W-1:0] ex_mem_rd_idx_q;
  wire [`XLEN-1:0] ex_mem_wb_data_q;
  wire [`XLEN-1:0] ex_mem_mem_addr_q;
  wire [`XLEN-1:0] ex_mem_store_data_q;
  wire mem_pending_w;
  wire lsu_cpu_req_valid_w;
  wire lsu_cpu_req_ready_w;
  wire lsu_cpu_req_write_w;
  wire [`XLEN-1:0] lsu_cpu_req_addr_w;
  wire [`XLEN-1:0] lsu_cpu_req_wdata_w;
  wire [3:0] lsu_cpu_req_wstrb_w;
  wire lsu_cpu_rsp_valid_w;
  wire lsu_cpu_rsp_ready_w;
  wire [`XLEN-1:0] lsu_cpu_rsp_rdata_w;
  wire lsu_cpu_rsp_error_w;

  wire mem_wb_valid_q;
  wire [`XLEN-1:0] mem_wb_pc_q;
  wire [`INST_W-1:0] mem_wb_inst_q;
  wire [`XLEN-1:0] mem_wb_next_pc_q;
  wire mem_wb_rd_en_q;
  wire mem_wb_need_wb_q;
  wire [`REG_ADDR_W-1:0] mem_wb_rd_idx_q;
  wire [`XLEN-1:0] mem_wb_wb_data_q;

  wire [`XLEN-1:0] csr_rdata_w;
  wire csr_illegal_w;
  wire [`XLEN-1:0] csr_trap_target_w;
  wire [`XLEN-1:0] csr_mepc_w;
  wire csr_irq_pending_w;
  wire [`TRAP_CAUSE_W-1:0] csr_irq_cause_w;

  reg halt_q;
  reg fatal_trap_q;
  reg exit_is_ebreak_q;
  reg [`XLEN-1:0] exit_code_q;
  reg [`TRAP_CAUSE_W-1:0] fatal_cause_q;
  reg [`XLEN-1:0] fatal_pc_q;
  reg [`XLEN-1:0] fatal_tval_q;
  reg [`XLEN-1:0] stop_pc_q;
  reg rf_wen_q;
  reg [`REG_ADDR_W-1:0] rf_waddr_q;
  reg [`XLEN-1:0] rf_wdata_q;
  reg cache_flush_active_q;
  reg mul_req_issued_q;
  wire rf_we_w = rf_wen_q && ~halt_q && ~fatal_trap_q;
  wire [`REG_ADDR_W-1:0] rf_waddr_w = rf_waddr_q;
  wire [`XLEN-1:0] rf_wdata_w = rf_wdata_q;

  wire [`CTRL_BUS_W-1:0] dec_ctrl_w;
  wire [`REG_ADDR_W-1:0] dec_rs1_idx_w;
  wire [`REG_ADDR_W-1:0] dec_rs2_idx_w;
  wire [`REG_ADDR_W-1:0] dec_rd_idx_w;
  wire [`XLEN-1:0] dec_imm_w;
  wire [`XLEN-1:0] rf_rs1_data_w;
  wire [`XLEN-1:0] rf_rs2_data_w;
  wire [`XLEN-1:0] rf_a0_data_w;

  wire id_ex_rs1_en_w = id_ex_ctrl_q[`CTRL_RS1_EN_BIT];
  wire id_ex_rs2_en_w = id_ex_ctrl_q[`CTRL_RS2_EN_BIT];
  wire id_ex_load_w = id_ex_ctrl_q[`CTRL_LOAD_BIT];
  wire id_ex_store_w = id_ex_ctrl_q[`CTRL_STORE_BIT];
  wire id_ex_branch_w = id_ex_ctrl_q[`CTRL_BRANCH_BIT];
  wire id_ex_jal_w = id_ex_ctrl_q[`CTRL_JAL_BIT];
  wire id_ex_jalr_w = id_ex_ctrl_q[`CTRL_JALR_BIT];
  wire id_ex_ecall_w = id_ex_ctrl_q[`CTRL_ECALL_BIT];
  wire id_ex_ebreak_w = id_ex_ctrl_q[`CTRL_EBREAK_BIT];
  wire id_ex_csr_w = id_ex_ctrl_q[`CTRL_CSR_BIT];
  wire id_ex_mret_w = id_ex_ctrl_q[`CTRL_MRET_BIT];
  wire id_ex_muldiv_w = id_ex_ctrl_q[`CTRL_MULDIV_BIT];
  wire id_ex_mul_w = id_ex_muldiv_w && ~id_ex_inst_q[14];
  wire id_ex_divrem_w = id_ex_muldiv_w && id_ex_inst_q[14];
  wire id_ex_mul_exec_w;
  wire id_ex_divrem_exec_w;
  wire id_ex_bitmanip_w = id_ex_ctrl_q[`CTRL_BITMANIP_BIT];
  wire id_ex_fence_i_w = id_ex_ctrl_q[`CTRL_FENCE_BIT] &&
                         (id_ex_inst_q[14:12] == `FUNCT3_FENCE_I);
  wire [1:0] id_ex_op1_sel_w = id_ex_ctrl_q[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB];
  wire [1:0] id_ex_op2_sel_w = id_ex_ctrl_q[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB];
  wire [3:0] id_ex_alu_op_w = id_ex_ctrl_q[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB];
  wire [2:0] id_ex_cmp_op_w = id_ex_ctrl_q[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
  wire [1:0] id_ex_mem_size_w = id_ex_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
  wire id_ex_mem_unsigned_w = id_ex_ctrl_q[`CTRL_MEM_UNSIGNED_BIT];
  wire [2:0] id_ex_wb_sel_w = id_ex_ctrl_q[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB];

  wire ex_mem_is_mem_w = ex_mem_load_q | ex_mem_store_q;
  wire ex_mem_load_w = ex_mem_load_q;
  wire ex_mem_writes_rd_w = ex_mem_valid_q &&
                             ex_mem_need_wb_q &&
                             ex_mem_rd_en_q &&
                             (ex_mem_rd_idx_q != {`REG_ADDR_W{1'b0}}) &&
                             ~ex_mem_load_w;
  wire mem_wb_writes_rd_w = mem_wb_valid_q &&
                             mem_wb_need_wb_q &&
                             mem_wb_rd_en_q &&
                             (mem_wb_rd_idx_q != {`REG_ADDR_W{1'b0}});

  wire [`XLEN-1:0] ex_rs1_forward_w =
      (id_ex_rs1_en_w && mem_response_w && ex_mem_load_w && ex_mem_need_wb_q &&
       (ex_mem_rd_idx_q == id_ex_rs1_idx_q)) ? lsu_mem_load_data_w :
      (id_ex_rs1_en_w && ex_mem_writes_rd_w && (ex_mem_rd_idx_q == id_ex_rs1_idx_q)) ? ex_mem_wb_data_q :
      (id_ex_rs1_en_w && mem_wb_writes_rd_w && (mem_wb_rd_idx_q == id_ex_rs1_idx_q)) ? mem_wb_wb_data_q :
      (id_ex_rs1_en_w && rf_we_w && (rf_waddr_w == id_ex_rs1_idx_q)) ? rf_wdata_w :
      id_ex_rs1_data_q;
  wire [`XLEN-1:0] ex_rs2_forward_w =
      (id_ex_rs2_en_w && mem_response_w && ex_mem_load_w && ex_mem_need_wb_q &&
       (ex_mem_rd_idx_q == id_ex_rs2_idx_q)) ? lsu_mem_load_data_w :
      (id_ex_rs2_en_w && ex_mem_writes_rd_w && (ex_mem_rd_idx_q == id_ex_rs2_idx_q)) ? ex_mem_wb_data_q :
      (id_ex_rs2_en_w && mem_wb_writes_rd_w && (mem_wb_rd_idx_q == id_ex_rs2_idx_q)) ? mem_wb_wb_data_q :
      (id_ex_rs2_en_w && rf_we_w && (rf_waddr_w == id_ex_rs2_idx_q)) ? rf_wdata_w :
      id_ex_rs2_data_q;
  wire [`XLEN-1:0] ex_a0_forward_w =
      (mem_response_w && ex_mem_load_w && ex_mem_need_wb_q &&
       (ex_mem_rd_idx_q == 5'd10)) ? lsu_mem_load_data_w :
      (ex_mem_writes_rd_w && (ex_mem_rd_idx_q == 5'd10)) ? ex_mem_wb_data_q :
      (mem_wb_writes_rd_w && (mem_wb_rd_idx_q == 5'd10)) ? mem_wb_wb_data_q :
      (rf_we_w && (rf_waddr_w == 5'd10)) ? rf_wdata_w :
      rf_a0_data_w;
  wire ex_rs1_load_wait_w = id_ex_rs1_en_w && ex_mem_valid_q && ex_mem_load_w &&
                             ex_mem_need_wb_q && ex_mem_rd_en_q &&
                             (ex_mem_rd_idx_q != {`REG_ADDR_W{1'b0}}) &&
                             (ex_mem_rd_idx_q == id_ex_rs1_idx_q) && ~mem_response_w;
  wire ex_rs2_load_wait_w = id_ex_rs2_en_w && ex_mem_valid_q && ex_mem_load_w &&
                             ex_mem_need_wb_q && ex_mem_rd_en_q &&
                             (ex_mem_rd_idx_q != {`REG_ADDR_W{1'b0}}) &&
                             (ex_mem_rd_idx_q == id_ex_rs2_idx_q) && ~mem_response_w;
  wire ex_operand_load_wait_w = ex_rs1_load_wait_w | ex_rs2_load_wait_w;

  wire [`XLEN-1:0] ex_pc_plus4_w = id_ex_pc_q + id_ex_inst_len_q;
  wire [`XLEN-1:0] ex_addr_sum_w = ex_rs1_forward_w + id_ex_imm_q;
  wire [`XLEN-1:0] ex_alu_src1_w = (id_ex_op1_sel_w == `OP1_SEL_PC) ? id_ex_pc_q :
                                   (id_ex_op1_sel_w == `OP1_SEL_ZERO) ? {`XLEN{1'b0}} :
                                   ex_rs1_forward_w;
  wire [`XLEN-1:0] ex_alu_src2_w = (id_ex_op2_sel_w == `OP2_SEL_IMM) ? id_ex_imm_q :
                                   (id_ex_op2_sel_w == `OP2_SEL_FOUR) ? id_ex_inst_len_q :
                                   ex_rs2_forward_w;
  wire [`XLEN-1:0] ex_alu_result_w;
  wire [`XLEN-1:0] ex_ext_result_w;
  wire [`XLEN-1:0] ex_exec_result_w;
  wire [`XLEN-1:0] ex_mul_result_w;
  wire [`XLEN-1:0] ex_mul_rsp_data_w;
  wire [`XLEN-1:0] ex_div_result_w;
  wire ex_mul_req_ready_w;
  wire ex_mul_rsp_valid_w;
  wire ex_div_req_ready_w;
  wire ex_div_rsp_valid_w;
  wire ex_muldiv_wait_w;
  wire ex_mul_req_valid_w;
  wire ex_mul_rsp_ready_w;
  wire ex_mul_req_fire_w;
  wire ex_mul_rsp_consumed_w;
  wire ex_div_req_valid_w;
  wire ex_div_rsp_ready_w;
  wire ex_cmp_true_w;
  wire [`XLEN-1:0] ex_branch_target_w = id_ex_pc_q + id_ex_imm_q;
  wire [`XLEN-1:0] ex_jal_target_w = id_ex_pc_q + id_ex_imm_q;
  wire [`XLEN-1:0] ex_jalr_target_w = {ex_addr_sum_w[`XLEN-1:1], 1'b0};
  wire ex_control_redirect_w = id_ex_jal_w | id_ex_jalr_w | (id_ex_branch_w & ex_cmp_true_w);
  wire [`XLEN-1:0] ex_control_target_w = id_ex_jalr_w ? ex_jalr_target_w :
                                         id_ex_jal_w ? ex_jal_target_w :
                                         ex_branch_target_w;
  wire [`XLEN-1:0] ex_control_next_pc_w = ex_control_redirect_w ? ex_control_target_w :
                                                                  ex_pc_plus4_w;
  wire ex_redirect_misaligned_w = ex_control_redirect_w && ex_control_target_w[0];

  /* verilator lint_off UNUSEDSIGNAL */
  wire [`XLEN-1:0] lsu_ex_bus_addr_w;
  wire [`XLEN-1:0] lsu_ex_bus_wdata_w;
  wire [3:0] lsu_ex_bus_wstrb_w;
  wire [`XLEN-1:0] lsu_ex_load_unused_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire lsu_ex_misaligned_w;

  wire [`XLEN-1:0] lsu_mem_load_data_w;
  wire mem_response_w;
  wire mem_fault_w;

  wire [`XLEN-1:0] ex_wbu_data_w;
  assign ex_mul_result_w = ex_mul_rsp_data_w;
  assign ex_ext_result_w = id_ex_muldiv_w ? (id_ex_divrem_w ? ex_div_result_w : ex_mul_result_w) :
                                           id_ex_bitmanip_w ? rv32b_result(id_ex_inst_q, ex_rs1_forward_w, ex_rs2_forward_w) :
                                           {`XLEN{1'b0}};
  assign ex_exec_result_w = (id_ex_muldiv_w | id_ex_bitmanip_w) ? ex_ext_result_w : ex_alu_result_w;

  wire dec_uses_rs1_w = dec_ctrl_w[`CTRL_RS1_EN_BIT];
  wire dec_uses_rs2_w = dec_ctrl_w[`CTRL_RS2_EN_BIT];
  wire [`XLEN-1:0] dec_rs1_data_w =
      (dec_uses_rs1_w && mem_response_w && ex_mem_load_w && ex_mem_need_wb_q &&
       (ex_mem_rd_idx_q == dec_rs1_idx_w)) ? lsu_mem_load_data_w :
      (dec_uses_rs1_w && ex_mem_writes_rd_w && (ex_mem_rd_idx_q == dec_rs1_idx_w)) ? ex_mem_wb_data_q :
      (dec_uses_rs1_w && mem_wb_writes_rd_w && (mem_wb_rd_idx_q == dec_rs1_idx_w)) ? mem_wb_wb_data_q :
      (dec_uses_rs1_w && rf_we_w && (rf_waddr_w == dec_rs1_idx_w)) ? rf_wdata_w :
      rf_rs1_data_w;
  wire [`XLEN-1:0] dec_rs2_data_w =
      (dec_uses_rs2_w && mem_response_w && ex_mem_load_w && ex_mem_need_wb_q &&
       (ex_mem_rd_idx_q == dec_rs2_idx_w)) ? lsu_mem_load_data_w :
      (dec_uses_rs2_w && ex_mem_writes_rd_w && (ex_mem_rd_idx_q == dec_rs2_idx_w)) ? ex_mem_wb_data_q :
      (dec_uses_rs2_w && mem_wb_writes_rd_w && (mem_wb_rd_idx_q == dec_rs2_idx_w)) ? mem_wb_wb_data_q :
      (dec_uses_rs2_w && rf_we_w && (rf_waddr_w == dec_rs2_idx_w)) ? rf_wdata_w :
      rf_rs2_data_w;

  wire ex_fetch_fault_w = id_ex_fetch_error_q;
  wire ex_illegal_w = id_ex_ctrl_q[`CTRL_ILLEGAL_BIT] | csr_illegal_w;
  assign id_ex_mul_exec_w = id_ex_mul_w && ~ex_fetch_fault_w && ~ex_illegal_w;
  assign id_ex_divrem_exec_w = id_ex_divrem_w && ~ex_fetch_fault_w && ~ex_illegal_w;
  assign ex_mul_req_valid_w = id_ex_valid_q && id_ex_mul_exec_w && ~mul_req_issued_q &&
                              ~ex_operand_load_wait_w &&
                              ~mem_fault_w && ~halt_q && ~fatal_trap_q;
  assign ex_mul_req_fire_w = ex_mul_req_valid_w && ex_mul_req_ready_w;
  assign ex_mul_rsp_ready_w = ex_fire_w && id_ex_mul_w;
  assign ex_mul_rsp_consumed_w = ex_mul_rsp_valid_w && ex_mul_rsp_ready_w;
  assign ex_muldiv_wait_w = id_ex_valid_q &&
                            ((id_ex_mul_exec_w && ~ex_mul_rsp_valid_w) ||
                             (id_ex_divrem_exec_w && ~ex_div_rsp_valid_w));
  assign ex_div_req_valid_w = id_ex_valid_q && id_ex_divrem_exec_w &&
                              ex_div_req_ready_w && ~ex_operand_load_wait_w &&
                              ~mem_fault_w &&
                              ~halt_q && ~fatal_trap_q;
  assign ex_div_rsp_ready_w = ex_fire_w && id_ex_divrem_w;
  wire ex_load_store_misaligned_w = (id_ex_load_w | id_ex_store_w) && lsu_ex_misaligned_w;
  wire [`TRAP_CAUSE_W-1:0] ex_exception_cause_w =
      ex_fetch_fault_w ? `EXC_INST_ACCESS_FAULT :
      ex_illegal_w ? `EXC_ILLEGAL_INST :
      ex_redirect_misaligned_w ? `EXC_INST_ADDR_MISALIGN :
      ex_load_store_misaligned_w ? (id_ex_load_w ? `EXC_LOAD_ADDR_MISALIGN : `EXC_STORE_ADDR_MISALIGN) :
      `EXC_ECALL_MMODE;
  wire [`XLEN-1:0] ex_exception_tval_w =
      ex_fetch_fault_w ? id_ex_pc_q :
      ex_illegal_w ? id_ex_inst_q :
      ex_redirect_misaligned_w ? ex_control_target_w :
      ex_load_store_misaligned_w ? ex_addr_sum_w :
      {`XLEN{1'b0}};
  wire [`XLEN-1:0] trap_target_w = csr_trap_target_w;

  wire ex_fire_w;
  wire ex_exception_w;
  wire ex_exception_fatal_w;
  wire ex_interrupt_w;
  wire ex_interrupt_fatal_w;
  wire ex_mret_redirect_w;
  wire cache_flush_valid_w;
  wire [`XLEN-1:0] cache_flush_redirect_pc_w;
  wire ex_any_flush_w;
  wire [`XLEN-1:0] ex_next_pc_w = ex_mret_redirect_w ? csr_mepc_w :
                                  (id_ex_branch_w | id_ex_jal_w | id_ex_jalr_w) ? ex_control_next_pc_w :
                                  ex_pc_plus4_w;
  wire id_accept_w;
  wire if_id_consume_w;
  wire if_id_can_refill_w;
  wire ebreak_fire_w;
  wire pipeline_normal_update_w;
  wire if_redirect_valid_w;
  wire [`XLEN-1:0] if_redirect_pc_w;
  wire ex_mem_leave_update_w;
  wire ex_mem_load_update_w;
  wire mem_wb_from_mem_w;
  wire mem_wb_from_ex_w;
  wire mem_wb_load_w;
  wire bpu_update_valid_w;
  wire [`XLEN-1:0] mem_wb_load_wb_data_w =
      mem_wb_from_mem_w ? (ex_mem_load_w ? lsu_mem_load_data_w : ex_mem_wb_data_q) :
                          ex_mem_wb_data_q;
  wire dcache_flush_done_w;
  wire fence_flush_candidate_w = id_ex_valid_q && id_ex_fence_i_w &&
                                 ~halt_q && ~fatal_trap_q &&
                                 ~ex_fetch_fault_w && ~ex_illegal_w;
  wire dcache_flush_can_start_w = fence_flush_candidate_w &&
                                  ~cache_flush_active_q &&
                                  ~ex_mem_valid_q &&
                                  ~mem_pending_w;
  wire dcache_flush_req_w = cache_flush_active_q || dcache_flush_can_start_w;
  wire fence_flush_wait_w = fence_flush_candidate_w &&
                            ~(cache_flush_active_q && dcache_flush_done_w);

  CacheControl u_cache_control (
    .ex_fire_i(ex_fire_w),
    .fence_i_i(id_ex_fence_i_w),
    .exception_i(ex_exception_w | ex_interrupt_w),
    .seq_pc_i(ex_pc_plus4_w),
    .flush_valid_o(cache_flush_valid_w),
    .flush_redirect_pc_o(cache_flush_redirect_pc_w)
  );

  PipelineControl u_pipeline_control (
    .if_id_valid_i(if_id_valid_q),
    .id_ex_valid_i(id_ex_valid_q),
    .id_ex_load_i(id_ex_load_w),
    .id_ex_ecall_i(id_ex_ecall_w),
    .id_ex_ebreak_i(id_ex_ebreak_w),
    .id_ex_mret_i(id_ex_mret_w),
    .id_ex_branch_i(id_ex_branch_w),
    .id_ex_jal_i(id_ex_jal_w),
    .id_ex_jalr_i(id_ex_jalr_w),
    .id_ex_rd_idx_i(id_ex_rd_idx_q),
    .id_ex_pred_pc_i(id_ex_pred_pc_q),
    .dec_uses_rs1_i(dec_uses_rs1_w),
    .dec_uses_rs2_i(dec_uses_rs2_w),
    .dec_rs1_idx_i(dec_rs1_idx_w),
    .dec_rs2_idx_i(dec_rs2_idx_w),
    .ex_mem_valid_i(ex_mem_valid_q),
    .ex_mem_is_mem_i(ex_mem_is_mem_w),
    .mem_response_i(mem_response_w),
    .mem_fault_i(mem_fault_w),
    .ex_wait_i(ex_muldiv_wait_w | fence_flush_wait_w),
    .halt_i(halt_q),
    .fatal_i(fatal_trap_q),
    .ex_fetch_fault_i(ex_fetch_fault_w),
    .ex_illegal_i(ex_illegal_w),
    .ex_redirect_misaligned_i(ex_redirect_misaligned_w),
    .ex_load_store_misaligned_i(ex_load_store_misaligned_w),
    .irq_pending_i(csr_irq_pending_w),
    .ex_control_next_pc_i(ex_control_next_pc_w),
    .ex_redirect_pc_i(ex_control_next_pc_w),
    .trap_target_i(trap_target_w),
    .csr_mepc_i(csr_mepc_w),
    .cache_flush_valid_i(cache_flush_valid_w),
    .cache_flush_redirect_pc_i(cache_flush_redirect_pc_w),
    .ex_fire_o(ex_fire_w),
    .ex_exception_o(ex_exception_w),
    .ex_exception_fatal_o(ex_exception_fatal_w),
    .ex_interrupt_o(ex_interrupt_w),
    .ex_interrupt_fatal_o(ex_interrupt_fatal_w),
    .ex_mret_redirect_o(ex_mret_redirect_w),
    .ex_any_flush_o(ex_any_flush_w),
    .id_accept_o(id_accept_w),
    .if_id_consume_o(if_id_consume_w),
    .if_id_can_refill_o(if_id_can_refill_w),
    .ebreak_fire_o(ebreak_fire_w),
    .pipeline_normal_update_o(pipeline_normal_update_w),
    .if_redirect_valid_o(if_redirect_valid_w),
    .if_redirect_pc_o(if_redirect_pc_w),
    .ex_mem_leave_update_o(ex_mem_leave_update_w),
    .ex_mem_load_update_o(ex_mem_load_update_w),
    .mem_wb_from_mem_o(mem_wb_from_mem_w),
    .mem_wb_from_ex_o(mem_wb_from_ex_w),
    .mem_wb_load_o(mem_wb_load_w),
    .bpu_update_valid_o(bpu_update_valid_w)
  );

  CsrFile u_csr_file (
    .clk(clk),
    .rst(rst),
    .cycle_count_enable_i(~halt_q & ~fatal_trap_q),
    .csr_valid_i(id_ex_csr_w),
    .csr_addr_i(id_ex_inst_q[31:20]),
    .csr_funct3_i(id_ex_inst_q[14:12]),
    .csr_rs1_idx_i(id_ex_rs1_idx_q),
    .csr_rs1_data_i(ex_rs1_forward_w),
    .csr_zimm_i(id_ex_inst_q[19:15]),
    .csr_commit_i(ex_fire_w),
    .csr_rdata_o(csr_rdata_w),
    .csr_illegal_o(csr_illegal_w),
    .trap_mem_valid_i(mem_fault_w && (trap_target_w != {`XLEN{1'b0}})),
    .trap_mem_pc_i(ex_mem_pc_q),
    .trap_mem_cause_i(ex_mem_load_w ? `EXC_LOAD_ACCESS_FAULT : `EXC_STORE_ACCESS_FAULT),
    .trap_mem_tval_i(ex_mem_mem_addr_q),
    .trap_ex_valid_i(ex_exception_w && ~ex_exception_fatal_w),
    .trap_ex_pc_i(id_ex_pc_q),
    .trap_ex_cause_i(ex_exception_cause_w),
    .trap_ex_tval_i(ex_exception_tval_w),
    .irq_software_i(irq_software_i),
    .irq_timer_i(irq_timer_i),
    .irq_external_i(irq_external_i),
    .irq_pending_o(csr_irq_pending_w),
    .irq_cause_o(csr_irq_cause_w),
    .trap_irq_valid_i(ex_interrupt_w && ~ex_interrupt_fatal_w),
    .trap_irq_pc_i(id_ex_pc_q),
    .trap_irq_cause_i(csr_irq_cause_w),
    .mret_valid_i(ex_mret_redirect_w),
    .trap_target_o(csr_trap_target_w),
    .mepc_o(csr_mepc_w)
  );

  IfStage u_if_stage (
    .clk(clk),
    .rst(rst),
    .flush_i(ex_any_flush_w),
    .redirect_valid_i(if_redirect_valid_w),
    .redirect_pc_i(if_redirect_pc_w),
    .pipe_ready_i(if_id_can_refill_w),
    .halt_i(halt_q),
    .fatal_i(fatal_trap_q),
    .bpu_update_valid_i(bpu_update_valid_w),
    .bpu_update_pc_i(id_ex_pc_q),
    .bpu_update_inst_i(id_ex_inst_q),
    .bpu_update_seq_pc_i(ex_pc_plus4_w),
    .bpu_update_next_pc_i(ex_control_next_pc_w),
    .bpu_update_taken_i(ex_control_redirect_w),
    .bpu_update_bht_idx_i(id_ex_bht_idx_q),
    .pipe_valid_o(if_stage_valid_w),
    .pipe_pc_o(if_stage_pc_w),
    .pipe_inst_o(if_stage_inst_w),
    .pipe_inst_len_o(if_stage_inst_len_w),
    .pipe_pred_pc_o(if_stage_pred_pc_w),
    .pipe_bht_idx_o(if_stage_bht_idx_w),
    .pipe_error_o(if_stage_error_w),
    .ifu_req_valid_o(ifu_cpu_req_valid_w),
    .ifu_req_ready_i(ifu_cpu_req_ready_w),
    .ifu_req_addr_o(ifu_cpu_req_addr_w),
    .ifu_rsp_valid_i(ifu_cpu_rsp_valid_w),
    .ifu_rsp_ready_o(ifu_cpu_rsp_ready_w),
    .ifu_rsp_data_i(ifu_cpu_rsp_data_w),
    .ifu_rsp_error_i(ifu_cpu_rsp_error_w),
    .fetch_pc_o(fetch_pc_w),
    .fetch_pending_o(fetch_pending_w)
  );

  ICache u_icache (
    .clk(clk),
    .rst(rst),
    .abort_i(ex_any_flush_w),
    .invalidate_i(cache_flush_valid_w),
    .cpu_req_valid_i(ifu_cpu_req_valid_w),
    .cpu_req_ready_o(ifu_cpu_req_ready_w),
    .cpu_req_addr_i(ifu_cpu_req_addr_w),
    .cpu_rsp_valid_o(ifu_cpu_rsp_valid_w),
    .cpu_rsp_ready_i(ifu_cpu_rsp_ready_w),
    .cpu_rsp_data_o(ifu_cpu_rsp_data_w),
    .cpu_rsp_error_o(ifu_cpu_rsp_error_w),
    .axi_arvalid_o(ifu_axi_arvalid_o),
    .axi_arready_i(ifu_axi_arready_i),
    .axi_araddr_o(ifu_axi_araddr_o),
    .axi_rvalid_i(ifu_axi_rvalid_i),
    .axi_rready_o(ifu_axi_rready_o),
    .axi_rdata_i(ifu_axi_rdata_i),
    .axi_rresp_i(ifu_axi_rresp_i)
  );

  IfIdPipeReg u_if_id_pipe (
    .clk(clk),
    .rst(rst),
    .clear_i(ex_any_flush_w),
    .consume_i(if_id_consume_w),
    .load_i(if_stage_valid_w),
    .load_pc_i(if_stage_pc_w),
    .load_inst_i(if_stage_inst_w),
    .load_inst_len_i(if_stage_inst_len_w),
    .load_pred_pc_i(if_stage_pred_pc_w),
    .load_bht_idx_i(if_stage_bht_idx_w),
    .load_error_i(if_stage_error_w),
    .valid_o(if_id_valid_q),
    .pc_o(if_id_pc_q),
    .inst_o(if_id_inst_q),
    .inst_len_o(if_id_inst_len_q),
    .pred_pc_o(if_id_pred_pc_q),
    .bht_idx_o(if_id_bht_idx_q),
    .error_o(if_id_error_q)
  );

  DecodeStage u_decode_stage (
    .inst_i(if_id_inst_q),
    .ctrl_o(dec_ctrl_w),
    .rs1_idx_o(dec_rs1_idx_w),
    .rs2_idx_o(dec_rs2_idx_w),
    .rd_idx_o(dec_rd_idx_w),
    .imm_o(dec_imm_w)
  );

  RegisterFile u_regfile (
    .clk(clk),
    .rst(rst),
    .rs1_addr_i(dec_rs1_idx_w),
    .rs2_addr_i(dec_rs2_idx_w),
    .rs1_data_o(rf_rs1_data_w),
    .rs2_data_o(rf_rs2_data_w),
    .a0_data_o(rf_a0_data_w),
    .debug_gprs_o(debug_gprs_o),
    .wen_i(rf_we_w),
    .waddr_i(rf_waddr_w),
    .wdata_i(rf_wdata_w)
  );

  ALU u_alu (
    .src1_i(ex_alu_src1_w),
    .src2_i(ex_alu_src2_w),
    .alu_op_i(id_ex_alu_op_w),
    .result_o(ex_alu_result_w)
  );

  CompareUnit u_compare (
    .lhs_i(ex_rs1_forward_w),
    .rhs_i(ex_rs2_forward_w),
    .cmp_op_i(id_ex_cmp_op_w),
    .cmp_true_o(ex_cmp_true_w)
  );

  Rv32Multiplier u_rv32_multiplier (
    .clk(clk),
    .rst(rst),
    .flush_i(mem_fault_w | ex_interrupt_w | halt_q | fatal_trap_q),
    .req_valid_i(ex_mul_req_valid_w),
    .req_ready_o(ex_mul_req_ready_w),
    .req_funct3_i(id_ex_inst_q[14:12]),
    .req_src1_i(ex_rs1_forward_w),
    .req_src2_i(ex_rs2_forward_w),
    .rsp_valid_o(ex_mul_rsp_valid_w),
    .rsp_ready_i(ex_mul_rsp_ready_w),
    .rsp_data_o(ex_mul_rsp_data_w)
  );

  Rv32Divider u_rv32_divider (
    .clk(clk),
    .rst(rst),
    .flush_i(mem_fault_w | ex_interrupt_w | halt_q | fatal_trap_q),
    .req_valid_i(ex_div_req_valid_w),
    .req_ready_o(ex_div_req_ready_w),
    .req_funct3_i(id_ex_inst_q[14:12]),
    .req_src1_i(ex_rs1_forward_w),
    .req_src2_i(ex_rs2_forward_w),
    .rsp_valid_o(ex_div_rsp_valid_w),
    .rsp_ready_i(ex_div_rsp_ready_w),
    .rsp_data_o(ex_div_result_w)
  );

  LSU u_lsu_ex (
    .eff_addr_i(ex_addr_sum_w),
    .store_data_i(ex_rs2_forward_w),
    .mem_size_i(id_ex_mem_size_w),
    .mem_unsigned_i(id_ex_mem_unsigned_w),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(lsu_ex_bus_addr_w),
    .mem_wdata_o(lsu_ex_bus_wdata_w),
    .mem_wstrb_o(lsu_ex_bus_wstrb_w),
    .load_data_o(lsu_ex_load_unused_w),
    .misaligned_o(lsu_ex_misaligned_w)
  );

  WBU u_wbu (
    .wb_sel_i(id_ex_wb_sel_w),
    .alu_data_i(ex_exec_result_w),
    .load_data_i({`XLEN{1'b0}}),
    .pc_plus4_i(ex_pc_plus4_w),
    .imm_data_i(id_ex_imm_q),
    .csr_data_i(csr_rdata_w),
    .wb_data_o(ex_wbu_data_w)
  );

  IdExPipeReg u_id_ex_pipe (
    .clk(clk),
    .rst(rst),
    .clear_i(mem_fault_w | ex_exception_w | ex_interrupt_w | ebreak_fire_w),
    .kill_i(pipeline_normal_update_w & ex_fire_w),
    .load_i(pipeline_normal_update_w & id_accept_w),
    .load_pc_i(if_id_pc_q),
    .load_inst_i(if_id_inst_q),
    .load_inst_len_i(if_id_inst_len_q),
    .load_pred_pc_i(if_id_pred_pc_q),
    .load_bht_idx_i(if_id_bht_idx_q),
    .load_ctrl_i(dec_ctrl_w),
    .load_imm_i(dec_imm_w),
    .load_rs1_idx_i(dec_rs1_idx_w),
    .load_rs2_idx_i(dec_rs2_idx_w),
    .load_rd_idx_i(dec_rd_idx_w),
    .load_rs1_data_i(dec_rs1_data_w),
    .load_rs2_data_i(dec_rs2_data_w),
    .load_fetch_error_i(if_id_error_q),
    .valid_o(id_ex_valid_q),
    .pc_o(id_ex_pc_q),
    .inst_o(id_ex_inst_q),
    .inst_len_o(id_ex_inst_len_q),
    .pred_pc_o(id_ex_pred_pc_q),
    .bht_idx_o(id_ex_bht_idx_q),
    .ctrl_o(id_ex_ctrl_q),
    .imm_o(id_ex_imm_q),
    .rs1_idx_o(id_ex_rs1_idx_q),
    .rs2_idx_o(id_ex_rs2_idx_q),
    .rd_idx_o(id_ex_rd_idx_q),
    .rs1_data_o(id_ex_rs1_data_q),
    .rs2_data_o(id_ex_rs2_data_q),
    .fetch_error_o(id_ex_fetch_error_q)
  );

  ExMemPipeReg u_ex_mem_pipe (
    .clk(clk),
    .rst(rst),
    .clear_i(mem_fault_w),
    .leave_i(ex_mem_leave_update_w),
    .load_i(ex_mem_load_update_w),
    .load_pc_i(id_ex_pc_q),
    .load_inst_i(id_ex_inst_q),
    .load_next_pc_i(ex_next_pc_w),
    .load_is_load_i(id_ex_load_w),
    .load_is_store_i(id_ex_store_w),
    .load_rd_en_i(id_ex_ctrl_q[`CTRL_RD_EN_BIT]),
    .load_need_wb_i(id_ex_ctrl_q[`CTRL_NEED_WB_BIT]),
    .load_mem_size_i(id_ex_mem_size_w),
    .load_mem_unsigned_i(id_ex_mem_unsigned_w),
    .load_rd_idx_i(id_ex_rd_idx_q),
    .load_wb_data_i(ex_wbu_data_w),
    .load_mem_addr_i(ex_addr_sum_w),
    .load_store_data_i(ex_rs2_forward_w),
    .valid_o(ex_mem_valid_q),
    .pc_o(ex_mem_pc_q),
    .inst_o(ex_mem_inst_q),
    .next_pc_o(ex_mem_next_pc_q),
    .is_load_o(ex_mem_load_q),
    .is_store_o(ex_mem_store_q),
    .rd_en_o(ex_mem_rd_en_q),
    .need_wb_o(ex_mem_need_wb_q),
    .mem_size_o(ex_mem_mem_size_q),
    .mem_unsigned_o(ex_mem_mem_unsigned_q),
    .rd_idx_o(ex_mem_rd_idx_q),
    .wb_data_o(ex_mem_wb_data_q),
    .mem_addr_o(ex_mem_mem_addr_q),
    .store_data_o(ex_mem_store_data_q)
  );

  MemoryStage u_memory_stage (
    .clk(clk),
    .rst(rst),
    .update_en_i(pipeline_normal_update_w),
    .clear_i(mem_fault_w),
    .ex_valid_i(ex_mem_valid_q & ~halt_q & ~fatal_trap_q),
    .ex_load_i(ex_mem_load_q),
    .ex_store_i(ex_mem_store_q),
    .ex_mem_size_i(ex_mem_mem_size_q),
    .ex_mem_unsigned_i(ex_mem_mem_unsigned_q),
    .ex_mem_addr_i(ex_mem_mem_addr_q),
    .ex_store_data_i(ex_mem_store_data_q),
    .lsu_req_valid_o(lsu_cpu_req_valid_w),
    .lsu_req_ready_i(lsu_cpu_req_ready_w),
    .lsu_req_write_o(lsu_cpu_req_write_w),
    .lsu_req_addr_o(lsu_cpu_req_addr_w),
    .lsu_req_wdata_o(lsu_cpu_req_wdata_w),
    .lsu_req_wstrb_o(lsu_cpu_req_wstrb_w),
    .lsu_rsp_valid_i(lsu_cpu_rsp_valid_w),
    .lsu_rsp_ready_o(lsu_cpu_rsp_ready_w),
    .lsu_rsp_rdata_i(lsu_cpu_rsp_rdata_w),
    .lsu_rsp_error_i(lsu_cpu_rsp_error_w),
    .load_data_o(lsu_mem_load_data_w),
    .response_o(mem_response_w),
    .fault_o(mem_fault_w),
    .pending_o(mem_pending_w)
  );

  DCache u_dcache (
    .clk(clk),
    .rst(rst),
    .invalidate_i(cache_flush_valid_w),
    .flush_i(dcache_flush_req_w),
    .flush_done_o(dcache_flush_done_w),
    .cpu_req_valid_i(lsu_cpu_req_valid_w),
    .cpu_req_ready_o(lsu_cpu_req_ready_w),
    .cpu_req_write_i(lsu_cpu_req_write_w),
    .cpu_req_addr_i(lsu_cpu_req_addr_w),
    .cpu_req_wdata_i(lsu_cpu_req_wdata_w),
    .cpu_req_wstrb_i(lsu_cpu_req_wstrb_w),
    .cpu_rsp_valid_o(lsu_cpu_rsp_valid_w),
    .cpu_rsp_ready_i(lsu_cpu_rsp_ready_w),
    .cpu_rsp_rdata_o(lsu_cpu_rsp_rdata_w),
    .cpu_rsp_error_o(lsu_cpu_rsp_error_w),
    .axi_arvalid_o(lsu_axi_arvalid_o),
    .axi_arready_i(lsu_axi_arready_i),
    .axi_araddr_o(lsu_axi_araddr_o),
    .axi_rvalid_i(lsu_axi_rvalid_i),
    .axi_rready_o(lsu_axi_rready_o),
    .axi_rdata_i(lsu_axi_rdata_i),
    .axi_rresp_i(lsu_axi_rresp_i),
    .axi_awvalid_o(lsu_axi_awvalid_o),
    .axi_awready_i(lsu_axi_awready_i),
    .axi_awaddr_o(lsu_axi_awaddr_o),
    .axi_wvalid_o(lsu_axi_wvalid_o),
    .axi_wready_i(lsu_axi_wready_i),
    .axi_wdata_o(lsu_axi_wdata_o),
    .axi_wstrb_o(lsu_axi_wstrb_o),
    .axi_bvalid_i(lsu_axi_bvalid_i),
    .axi_bready_o(lsu_axi_bready_o),
    .axi_bresp_i(lsu_axi_bresp_i)
  );

  MemWbPipeReg u_mem_wb_pipe (
    .clk(clk),
    .rst(rst),
    .load_i(mem_wb_load_w),
    .load_pc_i(ex_mem_pc_q),
    .load_inst_i(ex_mem_inst_q),
    .load_next_pc_i(ex_mem_next_pc_q),
    .load_rd_en_i(ex_mem_rd_en_q),
    .load_need_wb_i(ex_mem_need_wb_q),
    .load_rd_idx_i(ex_mem_rd_idx_q),
    .load_wb_data_i(mem_wb_load_wb_data_w),
    .valid_o(mem_wb_valid_q),
    .pc_o(mem_wb_pc_q),
    .inst_o(mem_wb_inst_q),
    .next_pc_o(mem_wb_next_pc_q),
    .rd_en_o(mem_wb_rd_en_q),
    .need_wb_o(mem_wb_need_wb_q),
    .rd_idx_o(mem_wb_rd_idx_q),
    .wb_data_o(mem_wb_wb_data_q)
  );

  assign commit_valid_o = mem_wb_valid_q && (~halt_q) && (~fatal_trap_q);
  assign commit_pc_o = mem_wb_pc_q;
  assign commit_inst_o = mem_wb_inst_q;
  assign commit_next_pc_o = mem_wb_next_pc_q;
  assign commit_rd_en_o = mem_wb_writes_rd_w;
  assign commit_rd_addr_o = mem_wb_rd_idx_q;
  assign commit_rd_data_o = mem_wb_wb_data_q;

  assign trap_valid_o = fatal_trap_q;
  assign trap_cause_o = fatal_cause_q;
  assign trap_pc_o = fatal_pc_q;
  assign trap_tval_o = fatal_tval_q;
  assign exit_valid_o = halt_q;
  assign exit_is_ecall_o = 1'b0;
  assign exit_is_ebreak_o = exit_is_ebreak_q;
  assign exit_code_o = exit_code_q;
  assign halted_o = halt_q | fatal_trap_q;

  assign debug_pc_o = halted_o ? stop_pc_q : fetch_pc_w;
  assign debug_state_o = halt_q ? `CORE_STATE_HALT :
                         fatal_trap_q ? `CORE_STATE_TRAP :
                         {(fetch_pending_w | mem_pending_w |
                           ex_muldiv_wait_w | fence_flush_wait_w),
                          if_id_valid_q, id_ex_valid_q, ex_mem_valid_q};

  always @(posedge clk) begin
    if (rst || mem_fault_w || ex_interrupt_w || halt_q || fatal_trap_q ||
        !id_ex_valid_q || !id_ex_mul_exec_w) begin
      mul_req_issued_q <= 1'b0;
    end else if (ex_mul_req_fire_w) begin
      // ID/EX 在等待乘法流水返回期间保持同一条指令，这个位防止每拍重复发射同一乘法。
      mul_req_issued_q <= 1'b1;
    end else if (ex_mul_rsp_consumed_w) begin
      mul_req_issued_q <= 1'b0;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      halt_q <= 1'b0;
      fatal_trap_q <= 1'b0;
      exit_is_ebreak_q <= 1'b0;
      exit_code_q <= {`XLEN{1'b0}};
      fatal_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      fatal_pc_q <= {`XLEN{1'b0}};
      fatal_tval_q <= {`XLEN{1'b0}};
      stop_pc_q <= `RESET_PC;
      rf_wen_q <= 1'b0;
      rf_waddr_q <= {`REG_ADDR_W{1'b0}};
      rf_wdata_q <= {`XLEN{1'b0}};
      cache_flush_active_q <= 1'b0;
    end else begin
      rf_wen_q <= 1'b0;

      if (mem_fault_w || ex_exception_w || ex_interrupt_w || ebreak_fire_w || halt_q || fatal_trap_q) begin
        cache_flush_active_q <= 1'b0;
      end else if (dcache_flush_can_start_w) begin
        cache_flush_active_q <= 1'b1;
      end else if (cache_flush_active_q && dcache_flush_done_w && ex_fire_w) begin
        cache_flush_active_q <= 1'b0;
      end

      if (mem_fault_w) begin
        if (trap_target_w == {`XLEN{1'b0}}) begin
          fatal_trap_q <= 1'b1;
          fatal_cause_q <= ex_mem_load_w ? `EXC_LOAD_ACCESS_FAULT : `EXC_STORE_ACCESS_FAULT;
          fatal_pc_q <= ex_mem_pc_q;
          fatal_tval_q <= ex_mem_mem_addr_q;
          stop_pc_q <= ex_mem_pc_q;
        end
      end else if (ex_exception_w) begin
        if (ex_exception_fatal_w) begin
          fatal_trap_q <= 1'b1;
          fatal_cause_q <= ex_exception_cause_w;
          fatal_pc_q <= id_ex_pc_q;
          fatal_tval_q <= ex_exception_tval_w;
          stop_pc_q <= id_ex_pc_q;
        end
      end else if (ex_interrupt_w) begin
        if (ex_interrupt_fatal_w) begin
          fatal_trap_q <= 1'b1;
          fatal_cause_q <= csr_irq_cause_w;
          fatal_pc_q <= id_ex_pc_q;
          fatal_tval_q <= {`XLEN{1'b0}};
          stop_pc_q <= id_ex_pc_q;
        end
      end else if (ebreak_fire_w) begin
        halt_q <= 1'b1;
        exit_is_ebreak_q <= 1'b1;
        exit_code_q <= ex_a0_forward_w;
        stop_pc_q <= id_ex_pc_q;
      end else begin
        if (mem_wb_from_mem_w) begin
          rf_wen_q <= ex_mem_load_w && ex_mem_need_wb_q && ex_mem_rd_en_q &&
                      (ex_mem_rd_idx_q != {`REG_ADDR_W{1'b0}});
          rf_waddr_q <= ex_mem_rd_idx_q;
          rf_wdata_q <= lsu_mem_load_data_w;
        end else if (mem_wb_from_ex_w) begin
          rf_wen_q <= ex_mem_need_wb_q && ex_mem_rd_en_q &&
                      (ex_mem_rd_idx_q != {`REG_ADDR_W{1'b0}});
          rf_waddr_q <= ex_mem_rd_idx_q;
          rf_wdata_q <= ex_mem_wb_data_q;
        end
      end
    end
  end

endmodule
