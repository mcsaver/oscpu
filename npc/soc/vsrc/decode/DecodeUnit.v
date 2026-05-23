`include "define.v"

module DecodeUnit (
  input [`INST_W-1:0] inst_i,
  output reg [`CTRL_BUS_W-1:0] ctrl_o,
  output [`REG_ADDR_W-1:0] rs1_idx_o,
  output [`REG_ADDR_W-1:0] rs2_idx_o,
  output [`REG_ADDR_W-1:0] rd_idx_o
);

  wire [6:0] opcode_w = inst_i[6:0];
  wire [2:0] funct3_w = inst_i[14:12];
  wire [6:0] funct7_w = inst_i[31:25];
  wire [11:0] funct12_w = inst_i[31:20];

  assign rs1_idx_o = inst_i[19:15];
  assign rs2_idx_o = inst_i[24:20];
  assign rd_idx_o = inst_i[11:7];

  function is_zb_op_imm;
    input [2:0] funct3;
    input [6:0] funct7;
    input [4:0] imm5;
    begin
      is_zb_op_imm = 1'b0;
      if (funct3 == `FUNCT3_SLL) begin
        case (funct7)
          7'h14,
          7'h24,
          7'h34: is_zb_op_imm = 1'b1;
          7'h30: begin
            case (imm5)
              5'h00,
              5'h01,
              5'h02,
              5'h04,
              5'h05: is_zb_op_imm = 1'b1;
              default: begin end
            endcase
          end
          default: begin end
        endcase
      end else if (funct3 == `FUNCT3_SRL_SRA) begin
        case (funct7)
          7'h30,
          7'h24: is_zb_op_imm = 1'b1;
          7'h14: is_zb_op_imm = (imm5 == 5'h07);
          7'h34: is_zb_op_imm = (imm5 == 5'h18);
          default: begin end
        endcase
      end
    end
  endfunction

  function is_zb_op;
    input [2:0] funct3;
    input [6:0] funct7;
    input [4:0] rs2_idx;
    begin
      is_zb_op = 1'b0;
      case ({funct7, funct3})
        {7'h10, `FUNCT3_SLT},
        {7'h10, `FUNCT3_XOR},
        {7'h10, `FUNCT3_OR},
        {7'h20, `FUNCT3_AND},
        {7'h20, `FUNCT3_OR},
        {7'h20, `FUNCT3_XOR},
        {7'h30, `FUNCT3_SLL},
        {7'h30, `FUNCT3_SRL_SRA},
        {7'h05, `FUNCT3_XOR},
        {7'h05, `FUNCT3_SRL_SRA},
        {7'h05, `FUNCT3_OR},
        {7'h05, `FUNCT3_AND},
        {7'h05, `FUNCT3_SLL},
        {7'h05, `FUNCT3_SLT},
        {7'h05, `FUNCT3_SLTU},
        {7'h14, `FUNCT3_SLL},
        {7'h24, `FUNCT3_SLL},
        {7'h24, `FUNCT3_SRL_SRA},
        {7'h34, `FUNCT3_SLL}: is_zb_op = 1'b1;
        {7'h04, `FUNCT3_XOR}: is_zb_op = (rs2_idx == {`REG_ADDR_W{1'b0}});
        default: begin end
      endcase
    end
  endfunction

  // 译码阶段一次性产出统一控制包，后级不再回头理解 opcode，能保持模块边界清晰。
  always @(*) begin
    ctrl_o = {`CTRL_BUS_W{1'b0}};

    ctrl_o[`CTRL_VALID_BIT] = 1'b1;
    ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b1;
    ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_X;
    ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_RS1;
    ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_RS2;
    ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
    ctrl_o[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = `CMP_OP_NONE;
    ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_WORD;
    ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;

    case (opcode_w)
      `OPCODE_LUI: begin
        ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_U;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_ZERO;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
        ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_COPY_B;
        ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_IMM;
      end

      `OPCODE_AUIPC: begin
        ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_U;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_PC;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
        ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
        ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;
      end

      `OPCODE_JAL: begin
        ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_JAL_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_J;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_PC;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
        ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
        ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_PC4;
      end

      `OPCODE_JALR: begin
        if (funct3_w == `FUNCT3_ADD_SUB) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
          ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
          ctrl_o[`CTRL_JALR_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
          ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_I;
          ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_RS1;
          ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
          ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
          ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_PC4;
        end
      end

      `OPCODE_BRANCH: begin
        ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RS2_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_BRANCH_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_B;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_PC;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
        ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;

        case (funct3_w)
          `FUNCT3_BEQ: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = `CMP_OP_EQ;
          end
          `FUNCT3_BNE: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = `CMP_OP_NE;
          end
          `FUNCT3_BLT: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = `CMP_OP_LT;
          end
          `FUNCT3_BGE: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = `CMP_OP_GE;
          end
          `FUNCT3_BLTU: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = `CMP_OP_LTU;
          end
          `FUNCT3_BGEU: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = `CMP_OP_GEU;
          end
          default: begin
            ctrl_o[`CTRL_BRANCH_BIT] = 1'b0;
          end
        endcase
      end

      `OPCODE_LOAD: begin
        ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_LOAD_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_MEM_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_I;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_RS1;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
        ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
        ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;

        case (funct3_w)
          `FUNCT3_LB: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_BYTE;
          end
          `FUNCT3_LH: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_HALF;
          end
          `FUNCT3_LW: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_WORD;
          end
          `FUNCT3_LBU: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_BYTE;
            ctrl_o[`CTRL_MEM_UNSIGNED_BIT] = 1'b1;
          end
          `FUNCT3_LHU: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_HALF;
            ctrl_o[`CTRL_MEM_UNSIGNED_BIT] = 1'b1;
          end
          default: begin
            ctrl_o[`CTRL_LOAD_BIT] = 1'b0;
            ctrl_o[`CTRL_RD_EN_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_MEM_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_WB_BIT] = 1'b0;
            ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;
          end
        endcase
      end

      `OPCODE_STORE: begin
        ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RS2_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_STORE_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_MEM_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_S;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_RS1;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
        ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;

        case (funct3_w)
          `FUNCT3_SB: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_BYTE;
          end
          `FUNCT3_SH: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_HALF;
          end
          `FUNCT3_SW: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_WORD;
          end
          default: begin
            ctrl_o[`CTRL_STORE_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_MEM_BIT] = 1'b0;
          end
        endcase
      end

      `OPCODE_OP_IMM: begin
        ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_I;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_RS1;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
        ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;

        case (funct3_w)
          `FUNCT3_ADD_SUB: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
          end
          `FUNCT3_SLT: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SLT;
          end
          `FUNCT3_SLTU: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SLTU;
          end
          `FUNCT3_XOR: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_XOR;
          end
          `FUNCT3_OR: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_OR;
          end
          `FUNCT3_AND: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_AND;
          end
          `FUNCT3_SLL: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SLL;
            end
          end
          `FUNCT3_SRL_SRA: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SRL;
            end else if (funct7_w == `FUNCT7_ALT) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SRA;
            end
          end
          default: begin
            ctrl_o[`CTRL_RD_EN_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_WB_BIT] = 1'b0;
            ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;
          end
        endcase

        if (is_zb_op_imm(funct3_w, funct7_w, inst_i[24:20])) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_BITMANIP_BIT] = 1'b1;
        end
      end

      `OPCODE_OP: begin
        ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RS2_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_RS1;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_RS2;
        ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;

        case (funct3_w)
          `FUNCT3_ADD_SUB: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
            end else if (funct7_w == `FUNCT7_ALT) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SUB;
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              // RV32M 使用独立扩展结果通路，保留统一写回边界，避免把乘除法硬塞进基础 ALU 编码。
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          `FUNCT3_SLL: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SLL;
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          `FUNCT3_SLT: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SLT;
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          `FUNCT3_SLTU: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SLTU;
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          `FUNCT3_XOR: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_XOR;
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          `FUNCT3_SRL_SRA: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SRL;
            end else if (funct7_w == `FUNCT7_ALT) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SRA;
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          `FUNCT3_OR: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_OR;
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          `FUNCT3_AND: begin
            if (funct7_w == `FUNCT7_STD) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_AND;
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          default: begin
            ctrl_o[`CTRL_RD_EN_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_WB_BIT] = 1'b0;
            ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;
          end
        endcase

        if (is_zb_op(funct3_w, funct7_w, rs2_idx_o)) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_BITMANIP_BIT] = 1'b1;
        end
      end

      `OPCODE_SYSTEM: begin
        if (funct3_w == `FUNCT3_ADD_SUB) begin
          ctrl_o[`CTRL_SYSTEM_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
          if ((rs1_idx_o == {`REG_ADDR_W{1'b0}}) &&
              (rd_idx_o == {`REG_ADDR_W{1'b0}})) begin
            case (funct12_w)
              `SYSTEM_FUNCT12_ECALL: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_ECALL_BIT] = 1'b1;
              end
              `SYSTEM_FUNCT12_EBREAK: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_EBREAK_BIT] = 1'b1;
              end
              `SYSTEM_FUNCT12_MRET: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_MRET_BIT] = 1'b1;
              end
              `SYSTEM_FUNCT12_WFI: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_WFI_BIT] = 1'b1;
              end
              default: begin
                ctrl_o[`CTRL_SYSTEM_BIT] = 1'b0;
                ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b0;
              end
            endcase
          end else begin
            ctrl_o[`CTRL_SYSTEM_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b0;
          end
        end else if ((funct3_w == 3'b001) || (funct3_w == 3'b010) || (funct3_w == 3'b011) ||
                     (funct3_w == 3'b101) || (funct3_w == 3'b110) || (funct3_w == 3'b111)) begin
          // Zicsr 指令统一走 CSR 控制位；具体读改写规则由执行级根据 funct3/rs1 决定。
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_SYSTEM_BIT] = 1'b1;
          ctrl_o[`CTRL_CSR_BIT] = 1'b1;
          ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
          ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_CSR;
          if ((funct3_w == 3'b001) || (funct3_w == 3'b010) || (funct3_w == 3'b011)) begin
            ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
          end
        end
      end

      `OPCODE_MISC_MEM: begin
        if ((funct3_w == `FUNCT3_FENCE) || (funct3_w == `FUNCT3_FENCE_I)) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_FENCE_BIT] = 1'b1;
          ctrl_o[`CTRL_MISC_MEM_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        end
      end

      default: begin
        ctrl_o[`CTRL_VALID_BIT] = 1'b1;
      end
    endcase
  end

endmodule
