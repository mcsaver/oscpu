`include "define.v"

module tb_decode_unit;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  reg [`INST_W-1:0] inst;
  wire [`CTRL_BUS_W-1:0] ctrl;
  wire [`REG_ADDR_W-1:0] rs1_idx;
  wire [`REG_ADDR_W-1:0] rs2_idx;
  wire [`REG_ADDR_W-1:0] rd_idx;

  DecodeUnit dut (
    .inst_i(inst),
    .ctrl_o(ctrl),
    .rs1_idx_o(rs1_idx),
    .rs2_idx_o(rs2_idx),
    .rd_idx_o(rd_idx)
  );

  task automatic check_ctrl_bit;
    input [1023:0] name;
    input integer bit_idx;
    input exp;
    begin
      tb_check1(name, ctrl[bit_idx], exp);
    end
  endtask

  task automatic check_ctrl_slice;
    input [1023:0] name;
    input integer msb;
    input integer lsb;
    input [31:0] exp;
    integer width;
    reg [31:0] mask;
    reg [31:0] got;
    begin
      width = msb - lsb + 1;
      mask = 32'hffff_ffff >> (32 - width);
      got = (ctrl >> lsb) & mask;
      tb_check32(name, got, exp);
    end
  endtask

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

  function [`INST_W-1:0] inst_system_fence;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    begin
      inst_system_fence = {funct7, rs2, rs1, `FUNCT3_ADD_SUB,
                           5'd0, `OPCODE_SYSTEM};
    end
  endfunction

  initial begin
    tb_errors = 0;

    inst = rv32_i(12'hfff, 5'd1, `FUNCT3_ADD_SUB, 5'd5, `OPCODE_OP_IMM); #1;
    check_ctrl_bit("addi legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("addi rs1", `CTRL_RS1_EN_BIT, 1'b1);
    check_ctrl_bit("addi rd", `CTRL_RD_EN_BIT, 1'b1);
    check_ctrl_slice("addi imm", `CTRL_IMM_TYPE_MSB, `CTRL_IMM_TYPE_LSB, `IMM_TYPE_I);
    check_ctrl_slice("addi alu", `CTRL_ALU_OP_MSB, `CTRL_ALU_OP_LSB, `ALU_OP_ADD);
    check_ctrl_slice("addi wb", `CTRL_WB_SEL_MSB, `CTRL_WB_SEL_LSB, `WB_SEL_ALU);
    tb_check32("addi rs1 idx", {27'b0, rs1_idx}, 32'd1);
    tb_check32("addi rd idx", {27'b0, rd_idx}, 32'd5);

    inst = rv32_i(12'd4, 5'd2, `FUNCT3_LW, 5'd6, `OPCODE_LOAD); #1;
    check_ctrl_bit("lw load", `CTRL_LOAD_BIT, 1'b1);
    check_ctrl_bit("lw mem", `CTRL_NEED_MEM_BIT, 1'b1);
    check_ctrl_slice("lw size", `CTRL_MEM_SIZE_MSB, `CTRL_MEM_SIZE_LSB, `MEM_SIZE_WORD);
    check_ctrl_slice("lw wb", `CTRL_WB_SEL_MSB, `CTRL_WB_SEL_LSB, `WB_SEL_LOAD);

    inst = rv32_i(12'd1, 5'd2, `FUNCT3_LBU, 5'd6, `OPCODE_LOAD); #1;
    check_ctrl_bit("lbu unsigned", `CTRL_MEM_UNSIGNED_BIT, 1'b1);
    check_ctrl_slice("lbu size", `CTRL_MEM_SIZE_MSB, `CTRL_MEM_SIZE_LSB, `MEM_SIZE_BYTE);

    inst = rv32_s(12'd8, 5'd7, 5'd2, `FUNCT3_SW); #1;
    check_ctrl_bit("sw store", `CTRL_STORE_BIT, 1'b1);
    check_ctrl_bit("sw rs2", `CTRL_RS2_EN_BIT, 1'b1);
    check_ctrl_bit("sw need wb", `CTRL_NEED_WB_BIT, 1'b0);
    check_ctrl_slice("sw imm", `CTRL_IMM_TYPE_MSB, `CTRL_IMM_TYPE_LSB, `IMM_TYPE_S);

    inst = rv32_b(13'd8, 5'd2, 5'd1, `FUNCT3_BEQ); #1;
    check_ctrl_bit("beq branch", `CTRL_BRANCH_BIT, 1'b1);
    check_ctrl_slice("beq cmp", `CTRL_CMP_OP_MSB, `CTRL_CMP_OP_LSB, `CMP_OP_EQ);

    inst = rv32_j(21'd16, 5'd1); #1;
    check_ctrl_bit("jal", `CTRL_JAL_BIT, 1'b1);
    check_ctrl_slice("jal wb", `CTRL_WB_SEL_MSB, `CTRL_WB_SEL_LSB, `WB_SEL_PC4);

    inst = {12'h000, 5'd0, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM}; #1;
    check_ctrl_bit("ecall", `CTRL_ECALL_BIT, 1'b1);
    check_ctrl_bit("ecall system", `CTRL_SYSTEM_BIT, 1'b1);

    inst = {`CSR_MTVEC, 5'd2, 3'b001, 5'd1, `OPCODE_SYSTEM}; #1;
    check_ctrl_bit("csrrw csr", `CTRL_CSR_BIT, 1'b1);
    check_ctrl_bit("csrrw rs1", `CTRL_RS1_EN_BIT, 1'b1);
    check_ctrl_slice("csrrw wb", `CTRL_WB_SEL_MSB, `CTRL_WB_SEL_LSB, `WB_SEL_CSR);

    inst = 32'h1020_0073; #1;
    check_ctrl_bit("sret legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("sret system", `CTRL_SYSTEM_BIT, 1'b1);
    check_ctrl_bit("sret marker", `CTRL_SRET_BIT, 1'b1);

    inst = inst_system_fence(`SYSTEM_FUNCT7_SFENCE_VMA, 5'd2, 5'd1); #1;
    check_ctrl_bit("sfence.vma legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("sfence.vma system", `CTRL_SYSTEM_BIT, 1'b1);
    check_ctrl_bit("sfence.vma serializes", `CTRL_SFENCE_VMA_BIT, 1'b1);
    check_ctrl_bit("sfence.vma tvm gated", `CTRL_SFENCE_TVM_BIT, 1'b1);

    inst = inst_system_fence(`SYSTEM_FUNCT7_SINVAL_VMA, 5'd2, 5'd1); #1;
    check_ctrl_bit("sinval.vma legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("sinval.vma serializes", `CTRL_SFENCE_VMA_BIT, 1'b1);
    check_ctrl_bit("sinval.vma tvm gated", `CTRL_SFENCE_TVM_BIT, 1'b1);

    inst = inst_system_fence(`SYSTEM_FUNCT7_SFENCE_INVAL,
                             `SYSTEM_RS2_SFENCE_W_INVAL, 5'd0); #1;
    check_ctrl_bit("sfence.w.inval legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("sfence.w.inval serializes", `CTRL_SFENCE_VMA_BIT, 1'b1);
    check_ctrl_bit("sfence.w.inval no tvm", `CTRL_SFENCE_TVM_BIT, 1'b0);

    inst = inst_system_fence(`SYSTEM_FUNCT7_SFENCE_INVAL,
                             `SYSTEM_RS2_SFENCE_INVAL_IR, 5'd0); #1;
    check_ctrl_bit("sfence.inval.ir legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("sfence.inval.ir serializes", `CTRL_SFENCE_VMA_BIT, 1'b1);
    check_ctrl_bit("sfence.inval.ir no tvm", `CTRL_SFENCE_TVM_BIT, 1'b0);

    inst = inst_system_fence(`SYSTEM_FUNCT7_SFENCE_INVAL, 5'd2, 5'd0); #1;
    check_ctrl_bit("reserved svinval encoding illegal", `CTRL_ILLEGAL_BIT, 1'b1);

    inst = inst_amo(5'b00000, 5'd7, 5'd6, `FUNCT3_LD, 5'd5); #1;
    check_ctrl_bit("amoadd.d legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("amoadd.d amo", `CTRL_AMO_BIT, 1'b1);
    check_ctrl_bit("amoadd.d load", `CTRL_LOAD_BIT, 1'b1);
    check_ctrl_bit("amoadd.d store", `CTRL_STORE_BIT, 1'b1);
    check_ctrl_bit("amoadd.d rs2 value", `CTRL_RS2_EN_BIT, 1'b1);
    check_ctrl_slice("amoadd.d size", `CTRL_MEM_SIZE_MSB, `CTRL_MEM_SIZE_LSB, `MEM_SIZE_DWORD);
    check_ctrl_slice("amoadd.d addr op2 zero", `CTRL_OP2_SEL_MSB, `CTRL_OP2_SEL_LSB, `OP2_SEL_ZERO);
    tb_check32("amoadd.d rs1 idx", {27'b0, rs1_idx}, 32'd6);
    tb_check32("amoadd.d rs2 idx", {27'b0, rs2_idx}, 32'd7);
    tb_check32("amoadd.d rd idx", {27'b0, rd_idx}, 32'd5);

    inst = inst_amo(5'b00010, 5'd0, 5'd6, `FUNCT3_LW, 5'd5); #1;
    check_ctrl_bit("lr.w legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("lr.w marker", `CTRL_AMO_LR_BIT, 1'b1);
    check_ctrl_bit("lr.w no rs2", `CTRL_RS2_EN_BIT, 1'b0);
    check_ctrl_bit("lr.w no store", `CTRL_STORE_BIT, 1'b0);

    inst = inst_amo(5'b00011, 5'd7, 5'd6, `FUNCT3_LW, 5'd5); #1;
    check_ctrl_bit("sc.w legal", `CTRL_ILLEGAL_BIT, 1'b0);
    check_ctrl_bit("sc.w marker", `CTRL_AMO_SC_BIT, 1'b1);
    check_ctrl_bit("sc.w store", `CTRL_STORE_BIT, 1'b1);
    check_ctrl_bit("sc.w no read response", `CTRL_LOAD_BIT, 1'b0);

    inst = rv32_r(`FUNCT7_MULDIV, 5'd2, 5'd1, 3'b100, 5'd3, `OPCODE_OP); #1;
    check_ctrl_bit("div muldiv", `CTRL_MULDIV_BIT, 1'b1);
    check_ctrl_bit("div legal", `CTRL_ILLEGAL_BIT, 1'b0);

    inst = 32'h0000_0000; #1;
    check_ctrl_bit("zero illegal", `CTRL_ILLEGAL_BIT, 1'b1);

    tb_finish("tb_decode_unit");
  end
endmodule
