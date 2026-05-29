`include "define.v"

// ALU-only OoO integer backend slice.  The frontend still supplies decoded uops;
// this module closes the loop from rename/issue through PRF read, dual ALU
// execute, writeback wakeup, and in-order ROB commit.
module OooIntBackend #(
  parameter PHY_REG_ADDR_W = 6,
  parameter ROB_INDEX_W = 4,
  parameter ROB_COUNT_W = 5,
  parameter FREE_COUNT_W = 7,
  parameter ISSUE_COUNT_W = 4
) (
  input clk,
  input rst,
  input flush_i,
  input checkpoint_capture_i,
  input checkpoint_restore_i,
  input checkpoint_quiesce_i,
  input mem_issue_block_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch0_ctrl_i,
  input [`REG_ADDR_W-1:0] dispatch0_rs1_arch_i,
  input [`REG_ADDR_W-1:0] dispatch0_rs2_arch_i,
  input [`REG_ADDR_W-1:0] dispatch0_rd_arch_i,
  input [`XLEN-1:0] dispatch0_imm_i,

  input dispatch1_valid_i,
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch1_ctrl_i,
  input [`REG_ADDR_W-1:0] dispatch1_rs1_arch_i,
  input [`REG_ADDR_W-1:0] dispatch1_rs2_arch_i,
  input [`REG_ADDR_W-1:0] dispatch1_rd_arch_i,
  input [`XLEN-1:0] dispatch1_imm_i,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [3:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  output mem1_req_valid_o,
  input mem1_req_ready_i,
  output mem1_req_write_o,
  output [`XLEN-1:0] mem1_req_addr_o,
  output [`XLEN-1:0] mem1_req_wdata_o,
  output [3:0] mem1_req_wstrb_o,
  input mem1_rsp_valid_i,
  output mem1_rsp_ready_o,
  input [`XLEN-1:0] mem1_rsp_rdata_i,
  input mem1_rsp_error_i,

  input commit_ready_i,
  input commit1_block_i,
  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit0_new_pdest_o,
  output [`XLEN-1:0] commit0_data_o,
  output commit0_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit0_cause_o,
  output [`XLEN-1:0] commit0_tval_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit1_new_pdest_o,
  output [`XLEN-1:0] commit1_data_o,
  output commit1_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit1_cause_o,
  output [`XLEN-1:0] commit1_tval_o,

  output [FREE_COUNT_W-1:0] free_count_o,
  output [ROB_COUNT_W-1:0] rob_count_o,
  output [ISSUE_COUNT_W-1:0] issue_count_o,
  output execute0_valid_o,
  output execute1_valid_o,

  output branch_resolve_valid_o,
  output [`XLEN-1:0] branch_resolve_pc_o,
  output [`XLEN-1:0] branch_resolve_next_pc_o,
  output branch_resolve_misaligned_o,
  output dispatch_branch_resolve_valid_o,
  output [`XLEN-1:0] dispatch_branch_resolve_pc_o,
  output [`XLEN-1:0] dispatch_branch_resolve_next_pc_o,
  output dispatch_branch_resolve_misaligned_o
);

  wire wb0_valid_w;
  wire [ROB_INDEX_W-1:0] wb0_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] wb0_pdest_w;
  wire [`XLEN-1:0] wb0_data_w;
  wire wb0_exception_w;
  wire [`TRAP_CAUSE_W-1:0] wb0_cause_w;
  wire [`XLEN-1:0] wb0_tval_w;
  wire wb1_valid_w;
  wire [ROB_INDEX_W-1:0] wb1_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] wb1_pdest_w;
  wire [`XLEN-1:0] wb1_data_w;
  wire wb1_exception_w;
  wire [`TRAP_CAUSE_W-1:0] wb1_cause_w;
  wire [`XLEN-1:0] wb1_tval_w;
  wire issue0_valid_w;
  wire issue0_ready_w;
  wire [`XLEN-1:0] issue0_pc_w;
  wire [`XLEN-1:0] issue0_next_pc_w;
  wire [`INST_W-1:0] issue0_inst_w;
  wire [`CTRL_BUS_W-1:0] issue0_ctrl_w;
  wire [ROB_INDEX_W-1:0] issue0_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_pdest_w;
  wire [`XLEN-1:0] issue0_imm_w;

  wire issue1_valid_w;
  wire issue1_ready_w;
  wire [`XLEN-1:0] issue1_pc_w;
  wire [`XLEN-1:0] issue1_next_pc_w;
  wire [`INST_W-1:0] issue1_inst_w;
  wire [`CTRL_BUS_W-1:0] issue1_ctrl_w;
  wire [ROB_INDEX_W-1:0] issue1_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_src2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_pdest_w;
  wire [`XLEN-1:0] issue1_imm_w;

  wire dispatch0_fire_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg_w;
  wire dispatch0_src1_ready_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg_w;
  wire dispatch0_src2_ready_w;
  wire dispatch1_fire_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg_w;
  wire dispatch1_src1_ready_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg_w;
  wire dispatch1_src2_ready_w;

  wire unused_issue_ctrl_bits_w =
      (|{issue0_ctrl_w[42:24], issue0_ctrl_w[15:0]}) |
      (|{issue1_ctrl_w[42:24], issue1_ctrl_w[15:0]});

  OooDispatchBackend #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_dispatch_backend (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
    .dispatch0_valid_i(dispatch0_valid_i),
    .dispatch0_ready_o(dispatch0_ready_o),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(dispatch0_ctrl_i),
    .dispatch0_rs1_arch_i(dispatch0_rs1_arch_i),
    .dispatch0_rs2_arch_i(dispatch0_rs2_arch_i),
    .dispatch0_rd_arch_i(dispatch0_rd_arch_i),
    .dispatch0_imm_i(dispatch0_imm_i),
    .dispatch1_valid_i(dispatch1_valid_i),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(dispatch1_ready_o),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(dispatch1_ctrl_i),
    .dispatch1_rs1_arch_i(dispatch1_rs1_arch_i),
    .dispatch1_rs2_arch_i(dispatch1_rs2_arch_i),
    .dispatch1_rd_arch_i(dispatch1_rd_arch_i),
    .dispatch1_imm_i(dispatch1_imm_i),
    .wb0_valid_i(wb0_valid_w),
    .wb0_rob_idx_i(wb0_rob_idx_w),
    .wb0_pdest_i(wb0_pdest_w),
    .wb0_data_i(wb0_data_w),
    .wb0_exception_i(wb0_exception_w),
    .wb0_cause_i(wb0_cause_w),
    .wb0_tval_i(wb0_tval_w),
    .wb1_valid_i(wb1_valid_w),
    .wb1_rob_idx_i(wb1_rob_idx_w),
    .wb1_pdest_i(wb1_pdest_w),
    .wb1_data_i(wb1_data_w),
    .wb1_exception_i(wb1_exception_w),
    .wb1_cause_i(wb1_cause_w),
    .wb1_tval_i(wb1_tval_w),
    .issue0_valid_o(issue0_valid_w),
    .issue0_ready_i(issue0_ready_w),
    .issue0_pc_o(issue0_pc_w),
    .issue0_next_pc_o(issue0_next_pc_w),
    .issue0_inst_o(issue0_inst_w),
    .issue0_ctrl_o(issue0_ctrl_w),
    .issue0_rob_idx_o(issue0_rob_idx_w),
    .issue0_src1_preg_o(issue0_src1_preg_w),
    .issue0_src2_preg_o(issue0_src2_preg_w),
    .issue0_pdest_o(issue0_pdest_w),
    .issue0_imm_o(issue0_imm_w),
    .issue1_valid_o(issue1_valid_w),
    .issue1_ready_i(issue1_ready_w),
    .issue1_pc_o(issue1_pc_w),
    .issue1_next_pc_o(issue1_next_pc_w),
    .issue1_inst_o(issue1_inst_w),
    .issue1_ctrl_o(issue1_ctrl_w),
    .issue1_rob_idx_o(issue1_rob_idx_w),
    .issue1_src1_preg_o(issue1_src1_preg_w),
    .issue1_src2_preg_o(issue1_src2_preg_w),
    .issue1_pdest_o(issue1_pdest_w),
    .issue1_imm_o(issue1_imm_w),
    .dispatch0_fire_o(dispatch0_fire_w),
    .dispatch0_src1_preg_o(dispatch0_src1_preg_w),
    .dispatch0_src1_ready_o(dispatch0_src1_ready_w),
    .dispatch0_src2_preg_o(dispatch0_src2_preg_w),
    .dispatch0_src2_ready_o(dispatch0_src2_ready_w),
    .dispatch1_fire_o(dispatch1_fire_w),
    .dispatch1_src1_preg_o(dispatch1_src1_preg_w),
    .dispatch1_src1_ready_o(dispatch1_src1_ready_w),
    .dispatch1_src2_preg_o(dispatch1_src2_preg_w),
    .dispatch1_src2_ready_o(dispatch1_src2_ready_w),
    .commit_ready_i(commit_ready_i && !checkpoint_capture_i &&
                    !checkpoint_restore_i && !checkpoint_quiesce_i),
    .commit1_block_i(commit1_block_i),
    .commit0_valid_o(commit0_valid_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_arch_rd_o(commit0_arch_rd_o),
    .commit0_old_pdest_o(commit0_old_pdest_o),
    .commit0_new_pdest_o(commit0_new_pdest_o),
    .commit0_data_o(commit0_data_o),
    .commit0_exception_o(commit0_exception_o),
    .commit0_cause_o(commit0_cause_o),
    .commit0_tval_o(commit0_tval_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_pc_o(commit1_pc_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_arch_rd_o(commit1_arch_rd_o),
    .commit1_old_pdest_o(commit1_old_pdest_o),
    .commit1_new_pdest_o(commit1_new_pdest_o),
    .commit1_data_o(commit1_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_cause_o(commit1_cause_o),
    .commit1_tval_o(commit1_tval_o),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
    .issue_count_o(issue_count_o)
  );

  wire [`XLEN-1:0] issue0_src1_data_w;
  wire [`XLEN-1:0] issue0_src2_data_w;
  wire [`XLEN-1:0] issue1_src1_data_w;
  wire [`XLEN-1:0] issue1_src2_data_w;
  wire [`XLEN-1:0] dispatch_branch_src1_data_w;
  wire [`XLEN-1:0] dispatch_branch_src2_data_w;

  wire dispatch0_branch_fire_w =
      dispatch0_fire_w && dispatch0_ctrl_i[`CTRL_BRANCH_BIT];
  wire dispatch1_branch_fire_w =
      dispatch1_fire_w && !dispatch1_optional_i &&
      dispatch1_ctrl_i[`CTRL_BRANCH_BIT];
  wire dispatch_branch_from1_w =
      !dispatch1_optional_i && !dispatch0_branch_fire_w &&
      dispatch1_branch_fire_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch_branch_src1_preg_w =
      dispatch_branch_from1_w ? dispatch1_src1_preg_w :
                                dispatch0_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch_branch_src2_preg_w =
      dispatch_branch_from1_w ? dispatch1_src2_preg_w :
                                dispatch0_src2_preg_w;

  OooPhysRegFile #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_phys_reg_file (
    .clk(clk),
    .rst(rst),
    .read0_addr_i(issue0_src1_preg_w),
    .read0_data_o(issue0_src1_data_w),
    .read1_addr_i(issue0_src2_preg_w),
    .read1_data_o(issue0_src2_data_w),
    .read2_addr_i(issue1_src1_preg_w),
    .read2_data_o(issue1_src1_data_w),
    .read3_addr_i(issue1_src2_preg_w),
    .read3_data_o(issue1_src2_data_w),
    .read4_addr_i(dispatch_branch_src1_preg_w),
    .read4_data_o(dispatch_branch_src1_data_w),
    .read5_addr_i(dispatch_branch_src2_preg_w),
    .read5_data_o(dispatch_branch_src2_data_w),
    .write0_valid_i(wb0_valid_w && (wb0_pdest_w != {PHY_REG_ADDR_W{1'b0}})),
    .write0_addr_i(wb0_pdest_w),
    .write0_data_i(wb0_data_w),
    .write1_valid_i(wb1_valid_w && (wb1_pdest_w != {PHY_REG_ADDR_W{1'b0}})),
    .write1_addr_i(wb1_pdest_w),
    .write1_data_i(wb1_data_w)
  );

  function [`XLEN-1:0] select_op1;
    input [1:0] op1_sel;
    input [`XLEN-1:0] rs1_data;
    input [`XLEN-1:0] pc;
    begin
      case (op1_sel)
        `OP1_SEL_RS1:  select_op1 = rs1_data;
        `OP1_SEL_PC:   select_op1 = pc;
        `OP1_SEL_ZERO: select_op1 = {`XLEN{1'b0}};
        default:       select_op1 = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function [`XLEN-1:0] select_op2;
    input [1:0] op2_sel;
    input [`XLEN-1:0] rs2_data;
    input [`XLEN-1:0] imm;
    begin
      case (op2_sel)
        `OP2_SEL_RS2:  select_op2 = rs2_data;
        `OP2_SEL_IMM:  select_op2 = imm;
        `OP2_SEL_FOUR: select_op2 = {{(`XLEN-3){1'b0}}, 3'd4};
        default:       select_op2 = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  /* verilator lint_off UNUSEDSIGNAL */
  function [`XLEN-1:0] rv32m_result;
    input [`INST_W-1:0] inst;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    reg signed [63:0] ss_prod;
    reg signed [63:0] su_prod;
    reg [63:0] uu_prod;
    begin
      ss_prod = $signed({{32{src1[31]}}, src1}) *
                $signed({{32{src2[31]}}, src2});
      su_prod = $signed({{32{src1[31]}}, src1}) *
                $signed({32'b0, src2});
      uu_prod = {32'b0, src1} * {32'b0, src2};
      rv32m_result = {`XLEN{1'b0}};
      case (inst[14:12])
        3'b000: rv32m_result = uu_prod[31:0];
        3'b001: rv32m_result = ss_prod[63:32];
        3'b010: rv32m_result = su_prod[63:32];
        3'b011: rv32m_result = uu_prod[63:32];
        3'b100: begin
          if (src2 == {`XLEN{1'b0}})
            rv32m_result = {`XLEN{1'b1}};
          else if ((src1 == 32'h8000_0000) && (src2 == 32'hffff_ffff))
            rv32m_result = 32'h8000_0000;
          else
            rv32m_result = $signed(src1) / $signed(src2);
        end
        3'b101: begin
          if (src2 == {`XLEN{1'b0}})
            rv32m_result = {`XLEN{1'b1}};
          else
            rv32m_result = src1 / src2;
        end
        3'b110: begin
          if (src2 == {`XLEN{1'b0}})
            rv32m_result = src1;
          else if ((src1 == 32'h8000_0000) && (src2 == 32'hffff_ffff))
            rv32m_result = {`XLEN{1'b0}};
          else
            rv32m_result = $signed(src1) % $signed(src2);
        end
        3'b111: begin
          if (src2 == {`XLEN{1'b0}})
            rv32m_result = src1;
          else
            rv32m_result = src1 % src2;
        end
        default: rv32m_result = {`XLEN{1'b0}};
      endcase
    end
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */

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

  wire issue1_src1_issue0_forward_w =
      issue0_current_result_valid_w &&
      (issue1_src1_preg_w == issue0_pdest_w) &&
      (issue1_src1_preg_w != {PHY_REG_ADDR_W{1'b0}});
  wire issue1_src2_issue0_forward_w =
      issue0_current_result_valid_w &&
      (issue1_src2_preg_w == issue0_pdest_w) &&
      (issue1_src2_preg_w != {PHY_REG_ADDR_W{1'b0}});
  wire [`XLEN-1:0] issue1_src1_value_w =
      issue1_src1_issue0_forward_w ? issue0_wb_data_w :
                                     issue1_src1_data_w;
  wire [`XLEN-1:0] issue1_src2_value_w =
      issue1_src2_issue0_forward_w ? issue0_wb_data_w :
                                     issue1_src2_data_w;

  wire [`XLEN-1:0] issue0_alu_src1_w =
      select_op1(issue0_ctrl_w[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB],
                 issue0_src1_data_w, issue0_pc_w);
  wire [`XLEN-1:0] issue0_alu_src2_w =
      select_op2(issue0_ctrl_w[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB],
                 issue0_src2_data_w, issue0_imm_w);
  wire [`XLEN-1:0] issue1_alu_src1_w =
      select_op1(issue1_ctrl_w[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB],
                 issue1_src1_value_w, issue1_pc_w);
  wire [`XLEN-1:0] issue1_alu_src2_w =
      select_op2(issue1_ctrl_w[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB],
                 issue1_src2_value_w, issue1_imm_w);

  wire [`XLEN-1:0] issue0_alu_result_w;
  wire [`XLEN-1:0] issue1_alu_result_w;
  wire [`XLEN-1:0] issue0_exec_result_w;
  wire [`XLEN-1:0] issue1_exec_result_w;
  wire [`XLEN-1:0] issue0_wb_data_w;
  wire [`XLEN-1:0] issue1_wb_data_w;
  wire issue0_is_branch_w = issue0_valid_w && issue0_ctrl_w[`CTRL_BRANCH_BIT];
  wire issue1_is_branch_w = issue1_valid_w && issue1_ctrl_w[`CTRL_BRANCH_BIT];
  wire issue0_branch_taken_w;
  wire issue1_branch_taken_w;
  wire [`XLEN-1:0] issue0_branch_target_w = issue0_pc_w + issue0_imm_w;
  wire [`XLEN-1:0] issue1_branch_target_w = issue1_pc_w + issue1_imm_w;
  wire [`XLEN-1:0] issue0_branch_next_pc_w =
      issue0_branch_taken_w ? issue0_branch_target_w : issue0_next_pc_w;
  wire [`XLEN-1:0] issue1_branch_next_pc_w =
      issue1_branch_taken_w ? issue1_branch_target_w : issue1_next_pc_w;
  CompareUnit u_branch_compare0 (
    .lhs_i(issue0_src1_data_w),
    .rhs_i(issue0_src2_data_w),
    .cmp_op_i(issue0_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB]),
    .cmp_true_o(issue0_branch_taken_w)
  );

  CompareUnit u_branch_compare1 (
    .lhs_i(issue1_src1_value_w),
    .rhs_i(issue1_src2_value_w),
    .cmp_op_i(issue1_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB]),
    .cmp_true_o(issue1_branch_taken_w)
  );

  ALU u_alu0 (
    .src1_i(issue0_alu_src1_w),
    .src2_i(issue0_alu_src2_w),
    .alu_op_i(issue0_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB]),
    .result_o(issue0_alu_result_w)
  );

  ALU u_alu1 (
    .src1_i(issue1_alu_src1_w),
    .src2_i(issue1_alu_src2_w),
    .alu_op_i(issue1_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB]),
    .result_o(issue1_alu_result_w)
  );

  assign issue0_exec_result_w =
      issue0_ctrl_w[`CTRL_MULDIV_BIT] ?
      rv32m_result(issue0_inst_w, issue0_src1_data_w, issue0_src2_data_w) :
      issue0_ctrl_w[`CTRL_BITMANIP_BIT] ?
      rv32b_result(issue0_inst_w, issue0_src1_data_w, issue0_src2_data_w) :
      issue0_alu_result_w;
  assign issue1_exec_result_w =
      issue1_ctrl_w[`CTRL_MULDIV_BIT] ?
      rv32m_result(issue1_inst_w, issue1_src1_value_w, issue1_src2_value_w) :
      issue1_ctrl_w[`CTRL_BITMANIP_BIT] ?
      rv32b_result(issue1_inst_w, issue1_src1_value_w, issue1_src2_value_w) :
      issue1_alu_result_w;

  WBU u_wbu0 (
    .wb_sel_i(issue0_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB]),
    .alu_data_i(issue0_exec_result_w),
    .load_data_i({`XLEN{1'b0}}),
    .pc_plus4_i(issue0_next_pc_w),
    .imm_data_i(issue0_imm_w),
    .csr_data_i({`XLEN{1'b0}}),
    .wb_data_o(issue0_wb_data_w)
  );

  WBU u_wbu1 (
    .wb_sel_i(issue1_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB]),
    .alu_data_i(issue1_exec_result_w),
    .load_data_i({`XLEN{1'b0}}),
    .pc_plus4_i(issue1_next_pc_w),
    .imm_data_i(issue1_imm_w),
    .csr_data_i({`XLEN{1'b0}}),
    .wb_data_o(issue1_wb_data_w)
  );

  wire issue0_is_load_w = issue0_valid_w && issue0_ctrl_w[`CTRL_LOAD_BIT];
  wire issue0_is_store_w = issue0_valid_w && issue0_ctrl_w[`CTRL_STORE_BIT];
  wire issue0_is_mem_w = issue0_is_load_w || issue0_is_store_w;
  wire issue1_is_load_w = issue1_valid_w && issue1_ctrl_w[`CTRL_LOAD_BIT];
  wire issue1_is_store_w = issue1_valid_w && issue1_ctrl_w[`CTRL_STORE_BIT];
  wire issue1_is_mem_w = issue1_is_load_w || issue1_is_store_w;

  wire [`XLEN-1:0] issue0_mem_addr_w;
  wire [`XLEN-1:0] issue0_mem_wdata_w;
  wire [3:0] issue0_mem_wstrb_w;
  wire [`XLEN-1:0] issue0_mem_load_unused_w;
  wire issue0_mem_misaligned_w;
  wire [`XLEN-1:0] issue1_mem_addr_w;
  wire [`XLEN-1:0] issue1_mem_wdata_w;
  wire [3:0] issue1_mem_wstrb_w;
  wire [`XLEN-1:0] issue1_mem_load_unused_w;
  wire issue1_mem_misaligned_w;

  LSU u_issue0_lsu (
    .eff_addr_i(issue0_alu_result_w),
    .store_data_i(issue0_src2_data_w),
    .mem_size_i(issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .mem_unsigned_i(issue0_ctrl_w[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(issue0_mem_addr_w),
    .mem_wdata_o(issue0_mem_wdata_w),
    .mem_wstrb_o(issue0_mem_wstrb_w),
    .load_data_o(issue0_mem_load_unused_w),
    .misaligned_o(issue0_mem_misaligned_w)
  );

  LSU u_issue1_lsu (
    .eff_addr_i(issue1_alu_result_w),
    .store_data_i(issue1_src2_value_w),
    .mem_size_i(issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .mem_unsigned_i(issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(issue1_mem_addr_w),
    .mem_wdata_o(issue1_mem_wdata_w),
    .mem_wstrb_o(issue1_mem_wstrb_w),
    .load_data_o(issue1_mem_load_unused_w),
    .misaligned_o(issue1_mem_misaligned_w)
  );

  reg mem_pending_q;
  reg [ROB_INDEX_W-1:0] mem_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem_pdest_q;
  reg mem_load_q;
  reg mem_store_q;
  reg [`XLEN-1:0] mem_eff_addr_q;
  reg [1:0] mem_size_q;
  reg mem_unsigned_q;
  reg mem_buffer_valid_q;
  reg [ROB_INDEX_W-1:0] mem_buffer_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem_buffer_pdest_q;
  reg mem_buffer_load_q;
  reg mem_buffer_store_q;
  reg [`XLEN-1:0] mem_buffer_eff_addr_q;
  reg [1:0] mem_buffer_size_q;
  reg mem_buffer_unsigned_q;
  reg [`XLEN-1:0] mem_buffer_wdata_q;
  reg [3:0] mem_buffer_wstrb_q;
  reg mem1_pending_q;
  reg [ROB_INDEX_W-1:0] mem1_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem1_pdest_q;
  reg [`XLEN-1:0] mem1_eff_addr_q;
  reg [1:0] mem1_size_q;
  reg mem1_unsigned_q;

  wire [`XLEN-1:0] mem_rsp_addr_unused_w;
  wire [`XLEN-1:0] mem_rsp_wdata_unused_w;
  wire [3:0] mem_rsp_wstrb_unused_w;
  wire [`XLEN-1:0] mem_rsp_load_data_w;
  wire mem_rsp_misaligned_unused_w;
  wire [`XLEN-1:0] mem1_rsp_addr_unused_w;
  wire [`XLEN-1:0] mem1_rsp_wdata_unused_w;
  wire [3:0] mem1_rsp_wstrb_unused_w;
  wire [`XLEN-1:0] mem1_rsp_load_data_w;
  wire mem1_rsp_misaligned_unused_w;

  LSU u_mem_rsp_lsu (
    .eff_addr_i(mem_eff_addr_q),
    .store_data_i({`XLEN{1'b0}}),
    .mem_size_i(mem_size_q),
    .mem_unsigned_i(mem_unsigned_q),
    .mem_rdata_i(mem_rsp_rdata_i),
    .mem_addr_o(mem_rsp_addr_unused_w),
    .mem_wdata_o(mem_rsp_wdata_unused_w),
    .mem_wstrb_o(mem_rsp_wstrb_unused_w),
    .load_data_o(mem_rsp_load_data_w),
    .misaligned_o(mem_rsp_misaligned_unused_w)
  );

  LSU u_mem1_rsp_lsu (
    .eff_addr_i(mem1_eff_addr_q),
    .store_data_i({`XLEN{1'b0}}),
    .mem_size_i(mem1_size_q),
    .mem_unsigned_i(mem1_unsigned_q),
    .mem_rdata_i(mem1_rsp_rdata_i),
    .mem_addr_o(mem1_rsp_addr_unused_w),
    .mem_wdata_o(mem1_rsp_wdata_unused_w),
    .mem_wstrb_o(mem1_rsp_wstrb_unused_w),
    .load_data_o(mem1_rsp_load_data_w),
    .misaligned_o(mem1_rsp_misaligned_unused_w)
  );

  wire issue0_mem_exception_w = issue0_is_mem_w && issue0_mem_misaligned_w;
  wire issue1_mem_exception_w = issue1_is_mem_w && issue1_mem_misaligned_w;
  wire issue_block_w =
      checkpoint_capture_i || checkpoint_quiesce_i;
  wire mem_issue_block_w = mem_issue_block_i || checkpoint_quiesce_i;
  wire mem_rsp_wants_w = mem_pending_q && mem_rsp_valid_i && !flush_i;
  wire mem1_rsp_wants_w = mem1_pending_q && mem1_rsp_valid_i && !flush_i;
  wire [1:0] wb_free_count_w =
      {1'b0, !ex0_valid_q} + {1'b0, !ex1_valid_q};
  assign mem_rsp_ready_o = mem_rsp_wants_w &&
                           (wb_free_count_w != 2'b00);
  assign mem1_rsp_ready_o =
      mem1_rsp_wants_w &&
      (wb_free_count_w > {1'b0, mem_rsp_wants_w});
  wire mem_rsp_fire_w = mem_rsp_valid_i && mem_rsp_ready_o;
  wire mem1_rsp_fire_w = mem1_rsp_valid_i && mem1_rsp_ready_o;
  wire mem_request_slot_open_w = !mem_pending_q || mem_rsp_fire_w;
  wire mem1_request_slot_open_w = !mem1_pending_q || mem1_rsp_fire_w;
  wire issue1_dual_load_port1_candidate_w =
      issue0_valid_w && issue0_is_load_w && issue1_is_load_w &&
      !issue0_mem_exception_w;
  wire issue1_dual_load_port1_ready_w =
      issue1_dual_load_port1_candidate_w &&
      !mem_buffer_valid_q &&
      mem_request_slot_open_w && mem_req_ready_i &&
      mem1_request_slot_open_w && mem1_req_ready_i;
  wire issue0_mem_can_fire_w =
      issue0_is_mem_w &&
      !mem_issue_block_w &&
      (issue0_mem_exception_w ||
       (!mem_buffer_valid_q && mem_request_slot_open_w &&
        mem_req_ready_i) ||
       (mem_pending_q && !mem_rsp_fire_w && !mem_buffer_valid_q));
  wire issue1_mem_can_fire_w =
      issue1_is_mem_w &&
      !mem_issue_block_w &&
      (issue1_mem_exception_w ||
       (issue1_dual_load_port1_candidate_w ?
        issue1_dual_load_port1_ready_w :
        ((!issue0_is_mem_w || issue0_mem_exception_w) &&
        !mem_buffer_valid_q && mem_request_slot_open_w &&
         mem_req_ready_i)));

  wire mem_rsp_waiting_for_wb_w =
      (mem_rsp_wants_w && !mem_rsp_ready_o) ||
      (mem1_rsp_wants_w && !mem1_rsp_ready_o);

  assign issue0_ready_w = !flush_i && !issue_block_w &&
                          (!issue0_is_mem_w || issue0_mem_can_fire_w);
  assign issue1_ready_w = !flush_i && !issue_block_w &&
                          !mem_rsp_waiting_for_wb_w &&
                          ((!issue0_is_mem_w || issue0_mem_can_fire_w) &&
                           (!issue1_is_mem_w || issue1_mem_can_fire_w));

  wire issue0_fire_w = issue0_valid_w && issue0_ready_w;
  wire issue1_fire_w = issue1_valid_w && issue1_ready_w;
  wire issue0_branch_fire_w = issue0_fire_w && issue0_is_branch_w;
  wire issue1_branch_fire_w = issue1_fire_w && issue1_is_branch_w;

  wire issue0_current_result_valid_w =
      issue0_fire_w && !issue0_is_mem_w &&
      (issue0_pdest_w != {PHY_REG_ADDR_W{1'b0}});
  wire issue1_current_result_valid_w =
      issue1_fire_w && !dispatch1_optional_i && !issue1_is_mem_w &&
      (issue1_pdest_w != {PHY_REG_ADDR_W{1'b0}});
  wire dispatch_branch_src1_issue0_match_w =
      issue0_current_result_valid_w &&
      (issue0_pdest_w == dispatch_branch_src1_preg_w);
  wire dispatch_branch_src1_issue1_match_w =
      issue1_current_result_valid_w &&
      (issue1_pdest_w == dispatch_branch_src1_preg_w);
  wire dispatch_branch_src2_issue0_match_w =
      issue0_current_result_valid_w &&
      (issue0_pdest_w == dispatch_branch_src2_preg_w);
  wire dispatch_branch_src2_issue1_match_w =
      issue1_current_result_valid_w &&
      (issue1_pdest_w == dispatch_branch_src2_preg_w);

  wire dispatch_branch_src1_base_ready_w =
      dispatch_branch_from1_w ? dispatch1_src1_ready_w :
                                dispatch0_src1_ready_w;
  wire dispatch_branch_src2_base_ready_w =
      dispatch_branch_from1_w ? dispatch1_src2_ready_w :
                                dispatch0_src2_ready_w;
  wire dispatch_branch_src1_ready_w =
      dispatch_branch_src1_base_ready_w ||
      dispatch_branch_src1_issue0_match_w ||
      dispatch_branch_src1_issue1_match_w;
  wire dispatch_branch_src2_ready_w =
      dispatch_branch_src2_base_ready_w ||
      dispatch_branch_src2_issue0_match_w ||
      dispatch_branch_src2_issue1_match_w;
  wire dispatch_branch_ready_w =
      (dispatch0_branch_fire_w || dispatch1_branch_fire_w) &&
      dispatch_branch_src1_ready_w && dispatch_branch_src2_ready_w;

  wire [`XLEN-1:0] dispatch_branch_src1_value_w =
      dispatch_branch_src1_issue1_match_w ? issue1_wb_data_w :
      dispatch_branch_src1_issue0_match_w ? issue0_wb_data_w :
                                            dispatch_branch_src1_data_w;
  wire [`XLEN-1:0] dispatch_branch_src2_value_w =
      dispatch_branch_src2_issue1_match_w ? issue1_wb_data_w :
      dispatch_branch_src2_issue0_match_w ? issue0_wb_data_w :
                                            dispatch_branch_src2_data_w;
  wire [`XLEN-1:0] dispatch_branch_pc_w =
      dispatch_branch_from1_w ? dispatch1_pc_i : dispatch0_pc_i;
  wire [`XLEN-1:0] dispatch_branch_fallthrough_w =
      dispatch_branch_from1_w ? dispatch1_next_pc_i : dispatch0_next_pc_i;
  wire [`XLEN-1:0] dispatch_branch_imm_w =
      dispatch_branch_from1_w ? dispatch1_imm_i : dispatch0_imm_i;
  wire [2:0] dispatch_branch_cmp_op_w =
      dispatch_branch_from1_w ?
      dispatch1_ctrl_i[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] :
      dispatch0_ctrl_i[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
  wire dispatch_branch_taken_w;
  wire [`XLEN-1:0] dispatch_branch_target_w =
      dispatch_branch_pc_w + dispatch_branch_imm_w;
  wire [`XLEN-1:0] dispatch_branch_next_pc_w =
      dispatch_branch_taken_w ? dispatch_branch_target_w :
                                dispatch_branch_fallthrough_w;
  wire dispatch_branch_misaligned_w =
      dispatch_branch_taken_w && dispatch_branch_target_w[0];

  CompareUnit u_dispatch_branch_compare (
    .lhs_i(dispatch_branch_src1_value_w),
    .rhs_i(dispatch_branch_src2_value_w),
    .cmp_op_i(dispatch_branch_cmp_op_w),
    .cmp_true_o(dispatch_branch_taken_w)
  );

  wire issue0_mem_request_fire_w =
      issue0_fire_w && issue0_is_mem_w && !issue0_mem_exception_w &&
      mem_request_slot_open_w && mem_req_ready_i && !mem_buffer_valid_q;
  wire issue0_mem_buffer_fire_w =
      issue0_fire_w && issue0_is_mem_w && !issue0_mem_exception_w &&
      mem_pending_q && !mem_rsp_fire_w && !mem_buffer_valid_q;
  wire mem_buffer_req_valid_w =
      mem_buffer_valid_q && mem_request_slot_open_w;
  wire mem_buffer_req_fire_w = mem_buffer_req_valid_w && mem_req_ready_i;
  wire issue0_mem_req_valid_w =
      issue0_valid_w && issue0_is_mem_w && !issue0_mem_exception_w &&
      mem_request_slot_open_w && !mem_buffer_valid_q && !flush_i &&
      !issue_block_w && !mem_issue_block_w;
  wire issue1_mem_request_fire_w =
      issue1_fire_w && issue1_is_mem_w && !issue1_mem_exception_w &&
      !issue0_is_mem_w && mem_request_slot_open_w && mem_req_ready_i &&
      !mem_buffer_valid_q;
  wire issue1_mem1_request_fire_w =
      issue1_fire_w && issue1_is_load_w && !issue1_mem_exception_w &&
      issue1_dual_load_port1_ready_w;
  wire issue1_mem_buffer_fire_w =
      1'b0;
  wire issue1_mem_req_valid_w =
      issue1_valid_w && issue1_is_mem_w && !issue1_mem_exception_w &&
      !issue0_is_mem_w && mem_request_slot_open_w && !mem_buffer_valid_q &&
      !flush_i && !issue_block_w && !mem_issue_block_w;
  wire issue1_mem1_req_valid_w =
      issue1_valid_w && issue1_is_load_w && !issue1_mem_exception_w &&
      issue1_dual_load_port1_ready_w &&
      !flush_i && !issue_block_w && !mem_issue_block_w;
  wire [`XLEN-1:0] mem_buffer_aligned_addr_w =
      mem_buffer_eff_addr_q & {{(`XLEN-2){1'b1}}, 2'b00};

  assign mem_req_valid_o = mem_buffer_req_valid_w || issue0_mem_req_valid_w ||
                           issue1_mem_req_valid_w;
  assign mem_req_write_o = mem_buffer_req_valid_w ? mem_buffer_store_q :
                           issue0_mem_req_valid_w ? issue0_is_store_w :
                                                    issue1_is_store_w;
  assign mem_req_addr_o = mem_buffer_req_valid_w ? mem_buffer_aligned_addr_w :
                          issue0_mem_req_valid_w ? issue0_mem_addr_w :
                                                   issue1_mem_addr_w;
  assign mem_req_wdata_o = mem_buffer_req_valid_w ? mem_buffer_wdata_q :
                           issue0_mem_req_valid_w ? issue0_mem_wdata_w :
                                                    issue1_mem_wdata_w;
  assign mem_req_wstrb_o = mem_buffer_req_valid_w ? mem_buffer_wstrb_q :
                           issue0_mem_req_valid_w ? issue0_mem_wstrb_w :
                                                    issue1_mem_wstrb_w;
  assign mem1_req_valid_o = issue1_mem1_req_valid_w;
  assign mem1_req_write_o = 1'b0;
  assign mem1_req_addr_o = issue1_mem_addr_w;
  assign mem1_req_wdata_o = {`XLEN{1'b0}};
  assign mem1_req_wstrb_o = 4'b0000;
  reg ex0_valid_q;
  reg [ROB_INDEX_W-1:0] ex0_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] ex0_pdest_q;
  reg [`XLEN-1:0] ex0_result_q;
  reg ex0_exception_q;
  reg [`TRAP_CAUSE_W-1:0] ex0_cause_q;
  reg [`XLEN-1:0] ex0_tval_q;
  reg ex1_valid_q;
  reg [ROB_INDEX_W-1:0] ex1_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] ex1_pdest_q;
  reg [`XLEN-1:0] ex1_result_q;
  reg ex1_exception_q;
  reg [`TRAP_CAUSE_W-1:0] ex1_cause_q;
  reg [`XLEN-1:0] ex1_tval_q;
  reg fast_branch_resolve_valid_q;
  reg [`XLEN-1:0] fast_branch_resolve_pc_q;
  reg [`XLEN-1:0] fast_branch_resolve_next_pc_q;
  reg fast_branch_resolve_misaligned_q;

  always @(posedge clk) begin
    if (rst || flush_i || checkpoint_restore_i) begin
      mem_pending_q <= 1'b0;
      mem_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_load_q <= 1'b0;
      mem_store_q <= 1'b0;
      mem_eff_addr_q <= {`XLEN{1'b0}};
      mem_size_q <= 2'b00;
      mem_unsigned_q <= 1'b0;
      mem_buffer_valid_q <= 1'b0;
      mem_buffer_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem_buffer_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_buffer_load_q <= 1'b0;
      mem_buffer_store_q <= 1'b0;
      mem_buffer_eff_addr_q <= {`XLEN{1'b0}};
      mem_buffer_size_q <= 2'b00;
      mem_buffer_unsigned_q <= 1'b0;
      mem_buffer_wdata_q <= {`XLEN{1'b0}};
      mem_buffer_wstrb_q <= 4'b0000;
      mem1_pending_q <= 1'b0;
      mem1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem1_eff_addr_q <= {`XLEN{1'b0}};
      mem1_size_q <= 2'b00;
      mem1_unsigned_q <= 1'b0;
      ex0_valid_q <= 1'b0;
      ex0_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      ex0_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      ex0_result_q <= {`XLEN{1'b0}};
      ex0_exception_q <= 1'b0;
      ex0_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      ex0_tval_q <= {`XLEN{1'b0}};
      ex1_valid_q <= 1'b0;
      ex1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      ex1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      ex1_result_q <= {`XLEN{1'b0}};
      ex1_exception_q <= 1'b0;
      ex1_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      ex1_tval_q <= {`XLEN{1'b0}};
      fast_branch_resolve_valid_q <= 1'b0;
      fast_branch_resolve_pc_q <= {`XLEN{1'b0}};
      fast_branch_resolve_next_pc_q <= {`XLEN{1'b0}};
      fast_branch_resolve_misaligned_q <= 1'b0;
    end else begin
      fast_branch_resolve_valid_q <= dispatch_branch_ready_w;
      fast_branch_resolve_pc_q <= dispatch_branch_ready_w ?
                                  dispatch_branch_pc_w : {`XLEN{1'b0}};
      fast_branch_resolve_next_pc_q <= dispatch_branch_ready_w ?
                                       dispatch_branch_next_pc_w :
                                       {`XLEN{1'b0}};
      fast_branch_resolve_misaligned_q <=
          dispatch_branch_ready_w && dispatch_branch_taken_w &&
          dispatch_branch_target_w[0];

      if (mem_rsp_fire_w) begin
        mem_pending_q <= 1'b0;
        mem_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        mem_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        mem_load_q <= 1'b0;
        mem_store_q <= 1'b0;
        mem_eff_addr_q <= {`XLEN{1'b0}};
        mem_size_q <= 2'b00;
        mem_unsigned_q <= 1'b0;
      end
      if (mem1_rsp_fire_w) begin
        mem1_pending_q <= 1'b0;
        mem1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        mem1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        mem1_eff_addr_q <= {`XLEN{1'b0}};
        mem1_size_q <= 2'b00;
        mem1_unsigned_q <= 1'b0;
      end
      if (mem_buffer_req_fire_w) begin
        mem_buffer_valid_q <= 1'b0;
        mem_buffer_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        mem_buffer_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        mem_buffer_load_q <= 1'b0;
        mem_buffer_store_q <= 1'b0;
        mem_buffer_eff_addr_q <= {`XLEN{1'b0}};
        mem_buffer_size_q <= 2'b00;
        mem_buffer_unsigned_q <= 1'b0;
        mem_buffer_wdata_q <= {`XLEN{1'b0}};
        mem_buffer_wstrb_q <= 4'b0000;
      end
      if (issue0_mem_request_fire_w) begin
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= issue0_rob_idx_w;
        mem_pdest_q <= issue0_pdest_w;
        mem_load_q <= issue0_is_load_w;
        mem_store_q <= issue0_is_store_w;
        mem_eff_addr_q <= issue0_alu_result_w;
        mem_size_q <= issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_unsigned_q <= issue0_ctrl_w[`CTRL_MEM_UNSIGNED_BIT];
      end
      if (issue1_mem_request_fire_w) begin
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= issue1_rob_idx_w;
        mem_pdest_q <= issue1_pdest_w;
        mem_load_q <= issue1_is_load_w;
        mem_store_q <= issue1_is_store_w;
        mem_eff_addr_q <= issue1_alu_result_w;
        mem_size_q <= issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_unsigned_q <= issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT];
      end
      if (issue1_mem1_request_fire_w) begin
        mem1_pending_q <= 1'b1;
        mem1_rob_idx_q <= issue1_rob_idx_w;
        mem1_pdest_q <= issue1_pdest_w;
        mem1_eff_addr_q <= issue1_alu_result_w;
        mem1_size_q <= issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem1_unsigned_q <= issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT];
      end
      if (mem_buffer_req_fire_w) begin
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= mem_buffer_rob_idx_q;
        mem_pdest_q <= mem_buffer_pdest_q;
        mem_load_q <= mem_buffer_load_q;
        mem_store_q <= mem_buffer_store_q;
        mem_eff_addr_q <= mem_buffer_eff_addr_q;
        mem_size_q <= mem_buffer_size_q;
        mem_unsigned_q <= mem_buffer_unsigned_q;
      end
      if (issue0_mem_buffer_fire_w) begin
        mem_buffer_valid_q <= 1'b1;
        mem_buffer_rob_idx_q <= issue0_rob_idx_w;
        mem_buffer_pdest_q <= issue0_pdest_w;
        mem_buffer_load_q <= issue0_is_load_w;
        mem_buffer_store_q <= issue0_is_store_w;
        mem_buffer_eff_addr_q <= issue0_alu_result_w;
        mem_buffer_size_q <= issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_buffer_unsigned_q <= issue0_ctrl_w[`CTRL_MEM_UNSIGNED_BIT];
        mem_buffer_wdata_q <= issue0_mem_wdata_w;
        mem_buffer_wstrb_q <= issue0_mem_wstrb_w;
      end
      if (issue1_mem_buffer_fire_w) begin
        mem_buffer_valid_q <= 1'b1;
        mem_buffer_rob_idx_q <= issue1_rob_idx_w;
        mem_buffer_pdest_q <= issue1_pdest_w;
        mem_buffer_load_q <= issue1_is_load_w;
        mem_buffer_store_q <= issue1_is_store_w;
        mem_buffer_eff_addr_q <= issue1_alu_result_w;
        mem_buffer_size_q <= issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_buffer_unsigned_q <= issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT];
        mem_buffer_wdata_q <= issue1_mem_wdata_w;
        mem_buffer_wstrb_q <= issue1_mem_wstrb_w;
      end

      ex0_valid_q <= issue0_fire_w &&
                     (!issue0_is_mem_w || issue0_mem_exception_w);
      if (issue0_fire_w && !issue0_is_mem_w) begin
        ex0_rob_idx_q <= issue0_rob_idx_w;
        ex0_pdest_q <= issue0_pdest_w;
        ex0_result_q <= issue0_wb_data_w;
        ex0_exception_q <= 1'b0;
        ex0_cause_q <= {`TRAP_CAUSE_W{1'b0}};
        ex0_tval_q <= {`XLEN{1'b0}};
      end else if (issue0_fire_w && issue0_mem_exception_w) begin
        ex0_rob_idx_q <= issue0_rob_idx_w;
        ex0_pdest_q <= issue0_pdest_w;
        ex0_result_q <= {`XLEN{1'b0}};
        ex0_exception_q <= 1'b1;
        ex0_cause_q <= issue0_is_load_w ? `EXC_LOAD_ADDR_MISALIGN :
                                          `EXC_STORE_ADDR_MISALIGN;
        ex0_tval_q <= issue0_alu_result_w;
      end else begin
        ex0_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        ex0_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        ex0_result_q <= {`XLEN{1'b0}};
        ex0_exception_q <= 1'b0;
        ex0_cause_q <= {`TRAP_CAUSE_W{1'b0}};
        ex0_tval_q <= {`XLEN{1'b0}};
      end

      ex1_valid_q <= issue1_fire_w &&
                     (!issue1_is_mem_w || issue1_mem_exception_w);
      if (issue1_fire_w) begin
        ex1_rob_idx_q <= issue1_rob_idx_w;
        ex1_pdest_q <= issue1_pdest_w;
        ex1_result_q <= issue1_mem_exception_w ? {`XLEN{1'b0}} :
                                                  issue1_wb_data_w;
        ex1_exception_q <= issue1_mem_exception_w;
        ex1_cause_q <= issue1_mem_exception_w ?
                       (issue1_is_load_w ? `EXC_LOAD_ADDR_MISALIGN :
                                           `EXC_STORE_ADDR_MISALIGN) :
                       {`TRAP_CAUSE_W{1'b0}};
        ex1_tval_q <= issue1_mem_exception_w ? issue1_alu_result_w :
                                                {`XLEN{1'b0}};
      end else begin
        ex1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        ex1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        ex1_result_q <= {`XLEN{1'b0}};
        ex1_exception_q <= 1'b0;
        ex1_cause_q <= {`TRAP_CAUSE_W{1'b0}};
        ex1_tval_q <= {`XLEN{1'b0}};
      end
    end
  end

  wire mem_rsp_to_wb0_w = mem_rsp_fire_w && !ex0_valid_q;
  wire mem_rsp_to_wb1_w = mem_rsp_fire_w && !mem_rsp_to_wb0_w;
  wire mem1_rsp_to_wb0_w =
      mem1_rsp_fire_w && !ex0_valid_q && !mem_rsp_to_wb0_w;
  wire mem1_rsp_to_wb1_w = mem1_rsp_fire_w && !mem1_rsp_to_wb0_w;
  wire [`XLEN-1:0] mem_rsp_wb_data_w =
      mem_load_q ? mem_rsp_load_data_w : {`XLEN{1'b0}};
  wire [`TRAP_CAUSE_W-1:0] mem_rsp_wb_cause_w =
      mem_load_q ? `EXC_LOAD_ACCESS_FAULT : `EXC_STORE_ACCESS_FAULT;
  wire [`XLEN-1:0] mem1_rsp_wb_data_w = mem1_rsp_load_data_w;

  assign wb0_valid_w = ex0_valid_q || mem_rsp_to_wb0_w || mem1_rsp_to_wb0_w;
  assign wb0_rob_idx_w = ex0_valid_q ? ex0_rob_idx_q :
                         mem_rsp_to_wb0_w ? mem_rob_idx_q :
                                            mem1_rob_idx_q;
  assign wb0_pdest_w = ex0_valid_q ? ex0_pdest_q :
                       mem_rsp_to_wb0_w ? mem_pdest_q : mem1_pdest_q;
  assign wb0_data_w = ex0_valid_q ? ex0_result_q :
                      mem_rsp_to_wb0_w ? mem_rsp_wb_data_w :
                                         mem1_rsp_wb_data_w;
  assign wb0_exception_w = ex0_valid_q ? ex0_exception_q :
                           mem_rsp_to_wb0_w ? mem_rsp_error_i :
                                              mem1_rsp_error_i;
  assign wb0_cause_w = ex0_valid_q ? ex0_cause_q :
                       mem_rsp_to_wb0_w ? mem_rsp_wb_cause_w :
                                          `EXC_LOAD_ACCESS_FAULT;
  assign wb0_tval_w = ex0_valid_q ? ex0_tval_q :
                      mem_rsp_to_wb0_w ? mem_eff_addr_q :
                                         mem1_eff_addr_q;
  assign wb1_valid_w = ex1_valid_q || mem_rsp_to_wb1_w || mem1_rsp_to_wb1_w;
  assign wb1_rob_idx_w = ex1_valid_q ? ex1_rob_idx_q :
                         mem_rsp_to_wb1_w ? mem_rob_idx_q :
                                            mem1_rob_idx_q;
  assign wb1_pdest_w = ex1_valid_q ? ex1_pdest_q :
                       mem_rsp_to_wb1_w ? mem_pdest_q : mem1_pdest_q;
  assign wb1_data_w = ex1_valid_q ? ex1_result_q :
                      mem_rsp_to_wb1_w ? mem_rsp_wb_data_w :
                                         mem1_rsp_wb_data_w;
  assign wb1_exception_w = ex1_valid_q ? ex1_exception_q :
                           mem_rsp_to_wb1_w ? mem_rsp_error_i :
                                              mem1_rsp_error_i;
  assign wb1_cause_w = ex1_valid_q ? ex1_cause_q :
                       mem_rsp_to_wb1_w ? mem_rsp_wb_cause_w :
                                          `EXC_LOAD_ACCESS_FAULT;
  assign wb1_tval_w = ex1_valid_q ? ex1_tval_q :
                      mem_rsp_to_wb1_w ? mem_eff_addr_q :
                                         mem1_eff_addr_q;

  assign execute0_valid_o = wb0_valid_w;
  assign execute1_valid_o = wb1_valid_w;
  assign branch_resolve_valid_o =
      fast_branch_resolve_valid_q || issue0_branch_fire_w ||
      issue1_branch_fire_w;
  assign branch_resolve_pc_o =
      fast_branch_resolve_valid_q ? fast_branch_resolve_pc_q :
      issue0_branch_fire_w ? issue0_pc_w : issue1_pc_w;
  assign branch_resolve_next_pc_o = fast_branch_resolve_valid_q ?
                                    fast_branch_resolve_next_pc_q :
                                    issue0_branch_fire_w ?
                                    issue0_branch_next_pc_w :
                                    issue1_branch_next_pc_w;
  assign branch_resolve_misaligned_o =
      fast_branch_resolve_valid_q ? fast_branch_resolve_misaligned_q :
      issue0_branch_fire_w ? (issue0_branch_taken_w &&
                              issue0_branch_target_w[0]) :
                             (issue1_branch_taken_w &&
                              issue1_branch_target_w[0]);
  assign dispatch_branch_resolve_valid_o = dispatch_branch_ready_w;
  assign dispatch_branch_resolve_pc_o = dispatch_branch_pc_w;
  assign dispatch_branch_resolve_next_pc_o = dispatch_branch_next_pc_w;
  assign dispatch_branch_resolve_misaligned_o = dispatch_branch_misaligned_w;

  wire unused_issue_payload_w =
      (|issue0_inst_w) | (|issue1_inst_w) |
      (|issue0_mem_load_unused_w) | (|issue1_mem_load_unused_w) |
      mem_store_q | mem_rsp_to_wb0_w | mem1_rsp_to_wb0_w |
      (|mem_rsp_addr_unused_w) | (|mem_rsp_wdata_unused_w) |
      (|mem_rsp_wstrb_unused_w) | mem_rsp_misaligned_unused_w |
      (|mem1_rsp_addr_unused_w) | (|mem1_rsp_wdata_unused_w) |
      (|mem1_rsp_wstrb_unused_w) | mem1_rsp_misaligned_unused_w;

endmodule
