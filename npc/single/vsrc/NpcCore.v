`include "define.v"

module NpcCore #(
  parameter [`XLEN-1:0] RESET_PC = `RESET_PC
) (
  input clk,
  input rst,

  output ifu_req_valid_o,
  input ifu_req_ready_i,
  output [`XLEN-1:0] ifu_req_addr_o,
  input ifu_rsp_valid_i,
  input [`XLEN-1:0] ifu_rsp_data_i,
  input ifu_rsp_error_i,

  output lsu_req_valid_o,
  input lsu_req_ready_i,
  output lsu_req_write_o,
  output [`XLEN-1:0] lsu_req_addr_o,
  output [`XLEN-1:0] lsu_req_wdata_o,
  output [3:0] lsu_req_wstrb_o,
  input lsu_rsp_valid_i,
  input [`XLEN-1:0] lsu_rsp_rdata_i,
  input lsu_rsp_error_i,

  output commit_valid_o,
  output [`XLEN-1:0] commit_pc_o,
  output [`INST_W-1:0] commit_inst_o,
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

  reg [`CORE_STATE_W-1:0] state_q;
  reg [`XLEN-1:0] pc_q;
  reg [`INST_W-1:0] inst_q;
  reg [`CTRL_BUS_W-1:0] ctrl_q;
  reg [`XLEN-1:0] imm_q;
  reg [`REG_ADDR_W-1:0] rd_idx_q;
  reg [`XLEN-1:0] rs1_data_q;
  reg [`XLEN-1:0] rs2_data_q;
  reg [`XLEN-1:0] alu_result_q;
  reg [`XLEN-1:0] mem_addr_raw_q;
  reg [`XLEN-1:0] store_data_q;
  reg [`XLEN-1:0] load_data_q;
  reg [`XLEN-1:0] next_pc_q;
  reg [`TRAP_CAUSE_W-1:0] trap_cause_q;
  reg [`XLEN-1:0] trap_pc_q;
  reg [`XLEN-1:0] trap_tval_q;
  reg exit_is_ecall_q;
  reg exit_is_ebreak_q;
  reg [`XLEN-1:0] exit_code_q;

  wire [`CTRL_BUS_W-1:0] dec_ctrl_w;
  wire [`REG_ADDR_W-1:0] dec_rs1_idx_w;
  wire [`REG_ADDR_W-1:0] dec_rs2_idx_w;
  wire [`REG_ADDR_W-1:0] dec_rd_idx_w;
  wire [`XLEN-1:0] rf_rs1_data_w;
  wire [`XLEN-1:0] rf_rs2_data_w;
  wire [`XLEN-1:0] rf_a0_data_w;
  wire [`XLEN-1:0] dec_imm_w;

  wire ctrl_rd_en_w = ctrl_q[`CTRL_RD_EN_BIT];
  wire ctrl_branch_w = ctrl_q[`CTRL_BRANCH_BIT];
  wire ctrl_jal_w = ctrl_q[`CTRL_JAL_BIT];
  wire ctrl_jalr_w = ctrl_q[`CTRL_JALR_BIT];
  wire ctrl_load_w = ctrl_q[`CTRL_LOAD_BIT];
  wire ctrl_store_w = ctrl_q[`CTRL_STORE_BIT];
  wire ctrl_ecall_w = ctrl_q[`CTRL_ECALL_BIT];
  wire ctrl_ebreak_w = ctrl_q[`CTRL_EBREAK_BIT];
  wire [1:0] ctrl_op1_sel_w = ctrl_q[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB];
  wire [1:0] ctrl_op2_sel_w = ctrl_q[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB];
  wire [3:0] ctrl_alu_op_w = ctrl_q[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB];
  wire [2:0] ctrl_cmp_op_w = ctrl_q[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
  wire [1:0] ctrl_mem_size_w = ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
  wire ctrl_mem_unsigned_w = ctrl_q[`CTRL_MEM_UNSIGNED_BIT];
  wire [2:0] ctrl_wb_sel_w = ctrl_q[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB];
  wire ctrl_has_imm_w = (ctrl_q[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] != `IMM_TYPE_X);
  wire ctrl_side_effect_w = ctrl_q[`CTRL_NEED_EXEC_BIT] |
                            ctrl_q[`CTRL_NEED_MEM_BIT] |
                            ctrl_q[`CTRL_NEED_WB_BIT] |
                            ctrl_q[`CTRL_FENCE_BIT] |
                            ctrl_q[`CTRL_SYSTEM_BIT] |
                            ctrl_q[`CTRL_MISC_MEM_BIT];
  wire [`XLEN-1:0] rs1_operand_w = ctrl_q[`CTRL_RS1_EN_BIT] ? rs1_data_q : {`XLEN{1'b0}};
  wire [`XLEN-1:0] rs2_operand_w = ctrl_q[`CTRL_RS2_EN_BIT] ? rs2_data_q : {`XLEN{1'b0}};

  wire [`XLEN-1:0] pc_plus4_w = pc_q + `PC_STEP;
  wire [`XLEN-1:0] alu_src1_w = (ctrl_op1_sel_w == `OP1_SEL_PC) ? pc_q :
                                 (ctrl_op1_sel_w == `OP1_SEL_ZERO) ? {`XLEN{1'b0}} :
                                 rs1_operand_w;
  wire [`XLEN-1:0] alu_src2_w = (ctrl_op2_sel_w == `OP2_SEL_IMM) ? imm_q :
                                 (ctrl_op2_sel_w == `OP2_SEL_FOUR) ? `PC_STEP :
                                 rs2_operand_w;
  wire [`XLEN-1:0] alu_result_w;
  wire cmp_true_w;
  wire [`XLEN-1:0] addr_sum_w = rs1_operand_w + imm_q;
  wire [`XLEN-1:0] branch_target_w = pc_q + imm_q;
  wire [`XLEN-1:0] jal_target_w = pc_q + imm_q;
  wire [`XLEN-1:0] jalr_target_w = {addr_sum_w[`XLEN-1:1], 1'b0};
  wire redirect_valid_w = ctrl_jal_w | ctrl_jalr_w | (ctrl_branch_w & cmp_true_w);
  wire [`XLEN-1:0] redirect_pc_w = ctrl_jalr_w ? jalr_target_w :
                                   ctrl_jal_w ? jal_target_w :
                                   branch_target_w;
  wire redirect_misaligned_w = redirect_valid_w && (redirect_pc_w[1:0] != 2'b00);
  wire [`XLEN-1:0] next_pc_exec_w = redirect_valid_w ? redirect_pc_w : pc_plus4_w;

  wire [`XLEN-1:0] lsu_eff_addr_w = (state_q == `CORE_STATE_EXEC) ? addr_sum_w : mem_addr_raw_q;
  wire [`XLEN-1:0] lsu_store_data_w = (state_q == `CORE_STATE_EXEC) ? rs2_operand_w : store_data_q;
  wire [`XLEN-1:0] lsu_bus_addr_w;
  wire [`XLEN-1:0] lsu_bus_wdata_w;
  wire [3:0] lsu_bus_wstrb_w;
  wire [`XLEN-1:0] lsu_load_data_w;
  wire lsu_misaligned_w;
  wire [`XLEN-1:0] wb_imm_data_w = ctrl_has_imm_w ? imm_q : {`XLEN{1'b0}};
  wire [`XLEN-1:0] wb_data_w;
  wire commit_fire_w = (state_q == `CORE_STATE_WB) && ctrl_q[`CTRL_VALID_BIT] && (~ctrl_q[`CTRL_ILLEGAL_BIT]) && ctrl_side_effect_w;
  wire rf_we_w = commit_fire_w && ctrl_q[`CTRL_NEED_WB_BIT] && ctrl_rd_en_w && (rd_idx_q != {`REG_ADDR_W{1'b0}});

  DecodeUnit u_decode (
    .inst_i(inst_q),
    .ctrl_o(dec_ctrl_w),
    .rs1_idx_o(dec_rs1_idx_w),
    .rs2_idx_o(dec_rs2_idx_w),
    .rd_idx_o(dec_rd_idx_w)
  );

  ImmGen u_imm_gen (
    .inst_i(inst_q),
    .imm_type_i(dec_ctrl_w[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB]),
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
    .waddr_i(rd_idx_q),
    .wdata_i(wb_data_w)
  );

  ALU u_alu (
    .src1_i(alu_src1_w),
    .src2_i(alu_src2_w),
    .alu_op_i(ctrl_alu_op_w),
    .result_o(alu_result_w)
  );

  CompareUnit u_compare (
    .lhs_i(rs1_operand_w),
    .rhs_i(rs2_operand_w),
    .cmp_op_i(ctrl_cmp_op_w),
    .cmp_true_o(cmp_true_w)
  );

  LSU u_lsu (
    .eff_addr_i(lsu_eff_addr_w),
    .store_data_i(lsu_store_data_w),
    .mem_size_i(ctrl_mem_size_w),
    .mem_unsigned_i(ctrl_mem_unsigned_w),
    .mem_rdata_i(lsu_rsp_rdata_i),
    .mem_addr_o(lsu_bus_addr_w),
    .mem_wdata_o(lsu_bus_wdata_w),
    .mem_wstrb_o(lsu_bus_wstrb_w),
    .load_data_o(lsu_load_data_w),
    .misaligned_o(lsu_misaligned_w)
  );

  WBU u_wbu (
    .wb_sel_i(ctrl_wb_sel_w),
    .alu_data_i(alu_result_q),
    .load_data_i(load_data_q),
    .pc_plus4_i(pc_plus4_w),
    .imm_data_i(wb_imm_data_w),
    .wb_data_o(wb_data_w)
  );

  assign ifu_req_valid_o = (state_q == `CORE_STATE_FETCH_REQ);
  assign ifu_req_addr_o = pc_q;

  assign lsu_req_valid_o = (state_q == `CORE_STATE_MEM_REQ);
  assign lsu_req_write_o = ctrl_store_w;
  assign lsu_req_addr_o = lsu_bus_addr_w;
  assign lsu_req_wdata_o = lsu_bus_wdata_w;
  assign lsu_req_wstrb_o = lsu_bus_wstrb_w;

  assign commit_valid_o = commit_fire_w;
  assign commit_pc_o = pc_q;
  assign commit_inst_o = inst_q;
  assign commit_rd_en_o = rf_we_w;
  assign commit_rd_addr_o = rd_idx_q;
  assign commit_rd_data_o = wb_data_w;

  assign trap_valid_o = (state_q == `CORE_STATE_TRAP);
  assign trap_cause_o = trap_cause_q;
  assign trap_pc_o = trap_pc_q;
  assign trap_tval_o = trap_tval_q;
  assign exit_valid_o = (state_q == `CORE_STATE_HALT);
  assign exit_is_ecall_o = exit_is_ecall_q;
  assign exit_is_ebreak_o = exit_is_ebreak_q;
  assign exit_code_o = exit_code_q;
  assign halted_o = (state_q == `CORE_STATE_HALT) || (state_q == `CORE_STATE_TRAP);

  assign debug_pc_o = pc_q;
  assign debug_state_o = state_q;

  // 顶层状态机只维护“一次只允许 1 条在途指令”，这样能用简单控制面拿到精确提交和精确异常。
  always @(posedge clk) begin
    if (rst) begin
      state_q <= `CORE_STATE_RESET;
      pc_q <= RESET_PC;
      inst_q <= {`INST_W{1'b0}};
      ctrl_q <= {`CTRL_BUS_W{1'b0}};
      imm_q <= {`XLEN{1'b0}};
      rd_idx_q <= {`REG_ADDR_W{1'b0}};
      rs1_data_q <= {`XLEN{1'b0}};
      rs2_data_q <= {`XLEN{1'b0}};
      alu_result_q <= {`XLEN{1'b0}};
      mem_addr_raw_q <= {`XLEN{1'b0}};
      store_data_q <= {`XLEN{1'b0}};
      load_data_q <= {`XLEN{1'b0}};
      next_pc_q <= RESET_PC;
      trap_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      trap_pc_q <= {`XLEN{1'b0}};
      trap_tval_q <= {`XLEN{1'b0}};
      exit_is_ecall_q <= 1'b0;
      exit_is_ebreak_q <= 1'b0;
      exit_code_q <= {`XLEN{1'b0}};
    end else begin
      case (state_q)
        `CORE_STATE_RESET: begin
          pc_q <= RESET_PC;
          next_pc_q <= RESET_PC;
          exit_is_ecall_q <= 1'b0;
          exit_is_ebreak_q <= 1'b0;
          exit_code_q <= {`XLEN{1'b0}};
          state_q <= `CORE_STATE_FETCH_REQ;
        end

        `CORE_STATE_FETCH_REQ: begin
          if (ifu_req_ready_i) begin
            if (ifu_rsp_valid_i) begin
              if (ifu_rsp_error_i) begin
                trap_cause_q <= `EXC_INST_ACCESS_FAULT;
                trap_pc_q <= pc_q;
                trap_tval_q <= pc_q;
                state_q <= `CORE_STATE_TRAP;
              end else begin
                inst_q <= ifu_rsp_data_i;
                state_q <= `CORE_STATE_DECODE;
              end
            end else begin
              state_q <= `CORE_STATE_FETCH_WAIT;
            end
          end
        end

        `CORE_STATE_FETCH_WAIT: begin
          if (ifu_rsp_valid_i) begin
            if (ifu_rsp_error_i) begin
              trap_cause_q <= `EXC_INST_ACCESS_FAULT;
              trap_pc_q <= pc_q;
              trap_tval_q <= pc_q;
              state_q <= `CORE_STATE_TRAP;
            end else begin
              inst_q <= ifu_rsp_data_i;
              state_q <= `CORE_STATE_DECODE;
            end
          end
        end

        `CORE_STATE_DECODE: begin
          ctrl_q <= dec_ctrl_w;
          imm_q <= dec_imm_w;
          rd_idx_q <= dec_rd_idx_w;
          rs1_data_q <= dec_ctrl_w[`CTRL_RS1_EN_BIT] ? rf_rs1_data_w : {`XLEN{1'b0}};
          rs2_data_q <= dec_ctrl_w[`CTRL_RS2_EN_BIT] ? rf_rs2_data_w : {`XLEN{1'b0}};

          if (dec_ctrl_w[`CTRL_ILLEGAL_BIT]) begin
            trap_cause_q <= `EXC_ILLEGAL_INST;
            trap_pc_q <= pc_q;
            trap_tval_q <= inst_q;
            state_q <= `CORE_STATE_TRAP;
          end else begin
            state_q <= `CORE_STATE_EXEC;
          end
        end

        `CORE_STATE_EXEC: begin
          alu_result_q <= alu_result_w;
          next_pc_q <= next_pc_exec_w;
          mem_addr_raw_q <= addr_sum_w;
          store_data_q <= rs2_data_q;

          // 当前还没有完整 CSR/trap handler，所以把 ecall/ebreak 显式收口成 EEI 退出协议，仿真环境能区分“主动退出”和“异常停机”。
          if (ctrl_ecall_w) begin
            trap_cause_q <= `EXC_ECALL_MMODE;
            trap_pc_q <= pc_q;
            trap_tval_q <= {`XLEN{1'b0}};
            exit_is_ecall_q <= 1'b1;
            exit_is_ebreak_q <= 1'b0;
            exit_code_q <= rf_a0_data_w;
            state_q <= `CORE_STATE_HALT;
          end else if (ctrl_ebreak_w) begin
            trap_cause_q <= `EXC_BREAKPOINT;
            trap_pc_q <= pc_q;
            trap_tval_q <= {`XLEN{1'b0}};
            exit_is_ecall_q <= 1'b0;
            exit_is_ebreak_q <= 1'b1;
            exit_code_q <= rf_a0_data_w;
            state_q <= `CORE_STATE_HALT;
          end else if (redirect_misaligned_w) begin
            exit_is_ecall_q <= 1'b0;
            exit_is_ebreak_q <= 1'b0;
            trap_cause_q <= `EXC_INST_ADDR_MISALIGN;
            trap_pc_q <= pc_q;
            trap_tval_q <= redirect_pc_w;
            state_q <= `CORE_STATE_TRAP;
          end else if ((ctrl_load_w || ctrl_store_w) && lsu_misaligned_w) begin
            exit_is_ecall_q <= 1'b0;
            exit_is_ebreak_q <= 1'b0;
            trap_cause_q <= ctrl_load_w ? `EXC_LOAD_ADDR_MISALIGN : `EXC_STORE_ADDR_MISALIGN;
            trap_pc_q <= pc_q;
            trap_tval_q <= addr_sum_w;
            state_q <= `CORE_STATE_TRAP;
          end else if (ctrl_load_w || ctrl_store_w) begin
            state_q <= `CORE_STATE_MEM_REQ;
          end else begin
            state_q <= `CORE_STATE_WB;
          end
        end

        `CORE_STATE_MEM_REQ: begin
          if (lsu_req_ready_i) begin
            if (lsu_rsp_valid_i) begin
              if (lsu_rsp_error_i) begin
                exit_is_ecall_q <= 1'b0;
                exit_is_ebreak_q <= 1'b0;
                trap_cause_q <= ctrl_load_w ? `EXC_LOAD_ACCESS_FAULT : `EXC_STORE_ACCESS_FAULT;
                trap_pc_q <= pc_q;
                trap_tval_q <= mem_addr_raw_q;
                state_q <= `CORE_STATE_TRAP;
              end else begin
                load_data_q <= lsu_load_data_w;
                state_q <= `CORE_STATE_WB;
              end
            end else begin
              state_q <= `CORE_STATE_MEM_WAIT;
            end
          end
        end

        `CORE_STATE_MEM_WAIT: begin
          if (lsu_rsp_valid_i) begin
            if (lsu_rsp_error_i) begin
              exit_is_ecall_q <= 1'b0;
              exit_is_ebreak_q <= 1'b0;
              trap_cause_q <= ctrl_load_w ? `EXC_LOAD_ACCESS_FAULT : `EXC_STORE_ACCESS_FAULT;
              trap_pc_q <= pc_q;
              trap_tval_q <= mem_addr_raw_q;
              state_q <= `CORE_STATE_TRAP;
            end else begin
              load_data_q <= lsu_load_data_w;
              state_q <= `CORE_STATE_WB;
            end
          end
        end

        `CORE_STATE_WB: begin
          pc_q <= next_pc_q;
          state_q <= `CORE_STATE_FETCH_REQ;
        end

        `CORE_STATE_HALT: begin
          state_q <= `CORE_STATE_HALT;
        end

        `CORE_STATE_TRAP: begin
          state_q <= `CORE_STATE_TRAP;
        end

        default: begin
          state_q <= `CORE_STATE_RESET;
        end
      endcase
    end
  end

endmodule
