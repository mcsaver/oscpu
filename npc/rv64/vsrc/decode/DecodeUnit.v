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
  wire [5:0] funct6_w = inst_i[31:26];
  wire [11:0] funct12_w = inst_i[31:20];

  assign rs1_idx_o = inst_i[19:15];
  assign rs2_idx_o = inst_i[24:20];
  assign rd_idx_o = inst_i[11:7];

  // 大型 case-based Zb 分类器组合块结果(供下方显式 decode always 块的 if 使用)
  reg is_zb_op_imm_w, is_zb_op_w;
  always @(*) begin : is_zb_op_imm_blk
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [4:0] imm5;
    begin
      funct3 = funct3_w;
      funct7 = funct7_w;
      imm5 = inst_i[24:20];
      is_zb_op_imm_w = 0;
      is_zb_op_imm_w = 1'b0;
      if (funct3 == `FUNCT3_SLL) begin
        case (funct7[6:1])
          6'h0a,
          6'h12,
          6'h1a: is_zb_op_imm_w = 1'b1;
          default: begin end
        endcase
        case (funct7)
          7'h14,
          7'h24,
          7'h34: is_zb_op_imm_w = 1'b1;
          7'h30: begin
            case (imm5)
              5'h00,
              5'h01,
              5'h02,
              5'h04,
              5'h05: is_zb_op_imm_w = 1'b1;
              default: begin end
            endcase
          end
          default: begin end
        endcase
      end else if (funct3 == `FUNCT3_SRL_SRA) begin
        case (funct7[6:1])
          6'h18,
          6'h12: is_zb_op_imm_w = 1'b1;
          default: begin end
        endcase
        case (funct7)
          7'h30,
          7'h24: is_zb_op_imm_w = 1'b1;
          7'h14: is_zb_op_imm_w = (imm5 == 5'h07);
          // 【合规修复 2026-07-03: §3.2 zb-overwide】rev8 仅 RV64 编码 funct7=0x35(imm5=0x18);
          // 删 0x34(RV32 rev8.w 变体, 在 RV64 应非法; rv64uzbb-p-rev8 用 0x35=6b80d713, 零回归)。
          7'h35: is_zb_op_imm_w = (imm5 == 5'h18);
          default: begin end
        endcase
      end
    end
  end

  function is_zba_op_imm_32;
    input [2:0] funct3;
    input [5:0] funct6;
    begin
      is_zba_op_imm_32 = (funct3 == `FUNCT3_SLL) && (funct6 == 6'h02);
    end
  endfunction

  function is_zbb_op_imm_32;
    input [2:0] funct3;
    input [6:0] funct7;
    input [4:0] imm5;
    begin
      is_zbb_op_imm_32 = 1'b0;
      if (funct7 == 7'h30) begin
        if (funct3 == `FUNCT3_SRL_SRA) begin
          is_zbb_op_imm_32 = 1'b1;
        end else if (funct3 == `FUNCT3_SLL) begin
          case (imm5)
            5'h00,
            5'h01,
            5'h02: is_zbb_op_imm_32 = 1'b1;
            default: begin end
          endcase
        end
      end
    end
  endfunction

  always @(*) begin : is_zb_op_blk
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [4:0] rs2_idx;
    begin
      funct3 = funct3_w;
      funct7 = funct7_w;
      rs2_idx = inst_i[24:20];
      is_zb_op_w = 0;
      is_zb_op_w = 1'b0;
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
        {7'h34, `FUNCT3_SLL}: is_zb_op_w = 1'b1;
        // 【合规修复 2026-07-03: §3.2 zb-overwide】删 OP 域 zext.h(pack rd,rs,x0): RV64 zext.h 是
        // OP-32(packw, is_zb_op_32:152 已译, rv64uzbb-p-zext_h 用 OP-32=0800c73b), 此 OP 编码 RV64 应非法。
        default: begin end
      endcase
    end
  end

  function is_zb_op_32;
    input [2:0] funct3;
    input [6:0] funct7;
    input [4:0] rs2_idx;
    begin
      is_zb_op_32 = 1'b0;
      case ({funct7, funct3})
        {7'h04, `FUNCT3_ADD_SUB},
        {7'h10, `FUNCT3_SLT},
        {7'h10, `FUNCT3_XOR},
        {7'h10, `FUNCT3_OR},
        {7'h30, `FUNCT3_SLL},
        {7'h30, `FUNCT3_SRL_SRA}: is_zb_op_32 = 1'b1;
        {7'h04, `FUNCT3_XOR}: is_zb_op_32 = (rs2_idx == {`REG_ADDR_W{1'b0}});
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
          `FUNCT3_LD: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_DWORD;
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
          `FUNCT3_LWU: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_WORD;
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
          `FUNCT3_SD: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_DWORD;
          end
          default: begin
            ctrl_o[`CTRL_STORE_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_MEM_BIT] = 1'b0;
          end
        endcase
      end

      `OPCODE_AMO: begin
        ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RS2_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_LOAD_BIT] = 1'b1;
        ctrl_o[`CTRL_STORE_BIT] = 1'b1;
        ctrl_o[`CTRL_AMO_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_MEM_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_X;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_RS1;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_ZERO;
        ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
        ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
        case (funct3_w)
          `FUNCT3_LW: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_WORD;
          end
          `FUNCT3_LD: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = `MEM_SIZE_DWORD;
          end
          default: begin
            ctrl_o[`CTRL_LOAD_BIT] = 1'b0;
            ctrl_o[`CTRL_STORE_BIT] = 1'b0;
            ctrl_o[`CTRL_AMO_BIT] = 1'b0;
            ctrl_o[`CTRL_RD_EN_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_MEM_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_WB_BIT] = 1'b0;
          end
        endcase

        case (inst_i[31:27])
          5'b00010: begin
            // LR 不读取 rs2，但仍设置 reservation 并把旧内存值写回 rd。
            ctrl_o[`CTRL_RS2_EN_BIT] = 1'b0;
            ctrl_o[`CTRL_STORE_BIT] = 1'b0;
            ctrl_o[`CTRL_AMO_LR_BIT] = 1'b1;
            ctrl_o[`CTRL_ILLEGAL_BIT] =
                ctrl_o[`CTRL_ILLEGAL_BIT] |
                (rs2_idx_o != {`REG_ADDR_W{1'b0}});
          end
          5'b00011: begin
            ctrl_o[`CTRL_LOAD_BIT] = 1'b0;
            ctrl_o[`CTRL_AMO_SC_BIT] = 1'b1;
          end
          5'b00001, // amoswap
          5'b00000, // amoadd
          5'b00100, // amoxor
          5'b01100, // amoand
          5'b01000, // amoor
          5'b10000, // amomin
          5'b10100, // amomax
          5'b11000, // amominu
          5'b11100: begin end // amomaxu
          default: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b1;
            ctrl_o[`CTRL_LOAD_BIT] = 1'b0;
            ctrl_o[`CTRL_STORE_BIT] = 1'b0;
            ctrl_o[`CTRL_AMO_BIT] = 1'b0;
            ctrl_o[`CTRL_RD_EN_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_MEM_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_WB_BIT] = 1'b0;
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
            if (funct6_w == 6'b000000) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SLL;
            end
          end
          `FUNCT3_SRL_SRA: begin
            if (funct6_w == 6'b000000) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_SRL;
            end else if (funct6_w == 6'b010000) begin
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

        if (is_zb_op_imm_w) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_BITMANIP_BIT] = 1'b1;
        end
      end

      `OPCODE_OP_IMM_32: begin
        ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_WORD_OP_BIT] = 1'b1;
        ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB] = `IMM_TYPE_I;
        ctrl_o[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = `OP1_SEL_RS1;
        ctrl_o[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = `OP2_SEL_IMM;
        ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;

        case (funct3_w)
          `FUNCT3_ADD_SUB: begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = `ALU_OP_ADD;
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
            ctrl_o[`CTRL_WORD_OP_BIT] = 1'b0;
            ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;
          end
        endcase

        if (is_zba_op_imm_32(funct3_w, funct6_w) ||
            is_zbb_op_imm_32(funct3_w, funct7_w, inst_i[24:20])) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_BITMANIP_BIT] = 1'b1;
          ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
          ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;
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

        if (is_zb_op_w) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_BITMANIP_BIT] = 1'b1;
        end
      end

      `OPCODE_OP_32: begin
        ctrl_o[`CTRL_RS1_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RS2_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
        ctrl_o[`CTRL_WORD_OP_BIT] = 1'b1;
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
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
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
            end else if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          `FUNCT3_XOR,
          `FUNCT3_OR,
          `FUNCT3_AND: begin
            if (funct7_w == `FUNCT7_MULDIV) begin
              ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
              ctrl_o[`CTRL_MULDIV_BIT] = 1'b1;
            end
          end
          default: begin
            ctrl_o[`CTRL_RD_EN_BIT] = 1'b0;
            ctrl_o[`CTRL_NEED_WB_BIT] = 1'b0;
            ctrl_o[`CTRL_WORD_OP_BIT] = 1'b0;
            ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;
          end
        endcase

        if (is_zb_op_32(funct3_w, funct7_w, rs2_idx_o)) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_BITMANIP_BIT] = 1'b1;
          ctrl_o[`CTRL_RD_EN_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_WB_BIT] = 1'b1;
          ctrl_o[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;
        end
      end

      `OPCODE_SYSTEM: begin
        if (funct3_w == `FUNCT3_ADD_SUB) begin
          ctrl_o[`CTRL_SYSTEM_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
          if ((rd_idx_o == {`REG_ADDR_W{1'b0}}) &&
              (funct7_w == `SYSTEM_FUNCT7_SFENCE_VMA)) begin
            // 地址转换 fence 需要同时进入序列化边界，并接受 mstatus.TVM 特权门控。
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_SFENCE_VMA_BIT] = 1'b1;
            ctrl_o[`CTRL_SFENCE_TVM_BIT] = 1'b1;
          end else if ((rd_idx_o == {`REG_ADDR_W{1'b0}}) &&
              (funct7_w == `SYSTEM_FUNCT7_SINVAL_VMA)) begin
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_SFENCE_VMA_BIT] = 1'b1;
            ctrl_o[`CTRL_SFENCE_TVM_BIT] = 1'b1;
          end else if ((rs1_idx_o == {`REG_ADDR_W{1'b0}}) &&
              (rd_idx_o == {`REG_ADDR_W{1'b0}}) &&
              (funct7_w == `SYSTEM_FUNCT7_SFENCE_INVAL) &&
              ((rs2_idx_o == `SYSTEM_RS2_SFENCE_W_INVAL) ||
               (rs2_idx_o == `SYSTEM_RS2_SFENCE_INVAL_IR))) begin
            // Svinval 的写缓冲/取指刷新 fence 不受 TVM 约束，但仍必须作为特权序列化点提交。
            ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
            ctrl_o[`CTRL_SFENCE_VMA_BIT] = 1'b1;
          end else if ((rs1_idx_o == {`REG_ADDR_W{1'b0}}) &&
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
              `SYSTEM_FUNCT12_SRET: begin
                ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
                ctrl_o[`CTRL_SRET_BIT] = 1'b1;
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
        if (funct3_w == `FUNCT3_FENCE) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_FENCE_BIT] = 1'b1;          // 纯内存序 fence：仍作合法 no-op
          ctrl_o[`CTRL_MISC_MEM_BIT] = 1'b1;
          ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
        end else if (funct3_w == `FUNCT3_FENCE_I) begin
          ctrl_o[`CTRL_ILLEGAL_BIT] = 1'b0;
          ctrl_o[`CTRL_MISC_MEM_BIT] = 1'b1;
`ifdef OOO_FENCEI_TRUE_FLUSH
          // flag ON：fence.i 作 stop 类 system，退休拍 mmu_flush(整块清取指 cache)+redirect 到 pc+4。
          // 不设 NEED_EXEC：不进 EXEC，像 sfence/wfi 那样只在退休拍产生副作用。
          ctrl_o[`CTRL_FENCEI_BIT] = 1'b1;
`else
          ctrl_o[`CTRL_FENCE_BIT] = 1'b1;          // flag OFF：回落旧 no-op = 零回归
          ctrl_o[`CTRL_NEED_EXEC_BIT] = 1'b1;
`endif
        end
      end

      default: begin
        ctrl_o[`CTRL_VALID_BIT] = 1'b1;
      end
    endcase
  end

endmodule
