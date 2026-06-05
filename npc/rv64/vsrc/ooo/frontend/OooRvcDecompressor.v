`include "define.v"

// RV64 OoO 前端的压缩指令解压器：纯组合地把 16-bit RVC 半字展开为 32-bit 标准指令。
// 单独成模块后，RVC 指令表可以脱离 OooAluFetchCore 做审计和后续覆盖补强。
module OooRvcDecompressor (
  input [15:0] inst_i,
  output [`INST_W-1:0] inst_o
);

  // Helper inputs are sliced to the RVC fields they really encode, so
  // reserved or alignment bits stay visible in the decode table instead of
  // being hidden by module-wide unused-signal waivers.
  function [`INST_W-1:0] enc_r;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
      enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    end
  endfunction

  function [`INST_W-1:0] enc_i;
    input [11:0] imm;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
      enc_i = {imm, rs1, funct3, rd, opcode};
    end
  endfunction

  function [`INST_W-1:0] enc_s;
    input [11:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    begin
      enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], `OPCODE_STORE};
    end
  endfunction

  function [`INST_W-1:0] enc_s_op;
    input [11:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
      enc_s_op = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    end
  endfunction

  function [`INST_W-1:0] enc_b;
    input [12:1] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    begin
      enc_b = {imm[12], imm[10:5], rs2, rs1, funct3,
               imm[4:1], imm[11], `OPCODE_BRANCH};
    end
  endfunction

  function [`INST_W-1:0] enc_u;
    input [19:0] imm;
    input [4:0] rd;
    input [6:0] opcode;
    begin
      enc_u = {imm, rd, opcode};
    end
  endfunction

  function [`INST_W-1:0] enc_j;
    input [20:1] imm;
    input [4:0] rd;
    begin
      enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, `OPCODE_JAL};
    end
  endfunction


  function [4:0] rvc_rdp;
    input [2:0] rd_p;
    begin
      rvc_rdp = {2'b01, rd_p};
    end
  endfunction

  function [4:0] rvc_rs1p;
    input [2:0] rs1_p;
    begin
      rvc_rs1p = {2'b01, rs1_p};
    end
  endfunction

  function [4:0] rvc_rs2p;
    input [2:0] rs2_p;
    begin
      rvc_rs2p = {2'b01, rs2_p};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_addi4spn;
    input [3:0] inst_10_7;
    input [1:0] inst_12_11;
    input inst_5;
    input inst_6;
    begin
      rvc_imm_addi4spn =
          {22'b0, inst_10_7, inst_12_11, inst_5, inst_6, 2'b00};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_lw_sw;
    input inst_5;
    input [2:0] inst_12_10;
    input inst_6;
    begin
      rvc_imm_lw_sw = {25'b0, inst_5, inst_12_10, inst_6, 2'b00};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_ld_sd;
    input [1:0] inst_6_5;
    input [2:0] inst_12_10;
    begin
      rvc_imm_ld_sd = {24'b0, inst_6_5, inst_12_10, 3'b000};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_6;
    input inst_12;
    input [4:0] inst_6_2;
    begin
      rvc_imm_6 = {{26{inst_12}}, inst_12, inst_6_2};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_j;
    input inst_12;
    input inst_8;
    input [1:0] inst_10_9;
    input inst_6;
    input inst_7;
    input inst_2;
    input inst_11;
    input [2:0] inst_5_3;
    begin
      rvc_imm_j = {{20{inst_12}}, inst_12, inst_8, inst_10_9,
                   inst_6, inst_7, inst_2, inst_11, inst_5_3, 1'b0};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_addi16sp;
    input inst_12;
    input [1:0] inst_4_3;
    input inst_5;
    input inst_2;
    input inst_6;
    begin
      rvc_imm_addi16sp = {{22{inst_12}}, inst_12, inst_4_3,
                          inst_5, inst_2, inst_6, 4'b0000};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_b;
    input inst_12;
    input [1:0] inst_6_5;
    input inst_2;
    input [1:0] inst_11_10;
    input [1:0] inst_4_3;
    begin
      rvc_imm_b = {{23{inst_12}}, inst_12, inst_6_5, inst_2,
                   inst_11_10, inst_4_3, 1'b0};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_lwsp;
    input [1:0] inst_3_2;
    input inst_12;
    input [2:0] inst_6_4;
    begin
      rvc_imm_lwsp = {24'b0, inst_3_2, inst_12, inst_6_4, 2'b00};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_ldsp;
    input [2:0] inst_4_2;
    input inst_12;
    input [1:0] inst_6_5;
    begin
      rvc_imm_ldsp = {23'b0, inst_4_2, inst_12, inst_6_5, 3'b000};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_swsp;
    input [1:0] inst_8_7;
    input [3:0] inst_12_9;
    begin
      rvc_imm_swsp = {24'b0, inst_8_7, inst_12_9, 2'b00};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_sdsp;
    input [2:0] inst_9_7;
    input [2:0] inst_12_10;
    begin
      rvc_imm_sdsp = {23'b0, inst_9_7, inst_12_10, 3'b000};
    end
  endfunction

  function [5:0] rvc_shamt;
    input inst_12;
    input [4:0] inst_6_2;
    begin
      rvc_shamt = {inst_12, inst_6_2};
    end
  endfunction

  function [`INST_W-1:0] decompress_rvc;
    input [15:0] inst;
    reg [`XLEN-1:0] imm;
    reg [4:0] rd;
    reg [4:0] rs2;
    reg [4:0] rs1p;
    reg [4:0] rs2p;
    reg [5:0] shamt;
    begin
      decompress_rvc = 32'h0000_0000;
      rd = inst[11:7];
      rs2 = inst[6:2];
      rs1p = rvc_rs1p(inst[9:7]);
      rs2p = rvc_rs2p(inst[4:2]);
      shamt = rvc_shamt(inst[12], inst[6:2]);

      case (inst[1:0])
        2'b00: begin
          case (inst[15:13])
            3'b000: begin
              imm = rvc_imm_addi4spn(inst[10:7], inst[12:11],
                                      inst[5], inst[6]);
              if (imm != {`XLEN{1'b0}})
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_ADD_SUB,
                          rvc_rdp(inst[4:2]), `OPCODE_OP_IMM);
            end
            3'b001: begin
              imm = rvc_imm_ld_sd(inst[6:5], inst[12:10]);
              decompress_rvc =
                  enc_i(imm[11:0], rs1p, `FUNCT3_LD,
                        rvc_rdp(inst[4:2]), `OPCODE_LOAD_FP);
            end
            3'b010: begin
              imm = rvc_imm_lw_sw(inst[5], inst[12:10], inst[6]);
              decompress_rvc =
                  enc_i(imm[11:0], rs1p, `FUNCT3_LW,
                        rvc_rdp(inst[4:2]), `OPCODE_LOAD);
            end
            3'b011: begin
              imm = rvc_imm_ld_sd(inst[6:5], inst[12:10]);
              decompress_rvc =
                  enc_i(imm[11:0], rs1p, `FUNCT3_LD,
                        rvc_rdp(inst[4:2]), `OPCODE_LOAD);
            end
            3'b101: begin
              imm = rvc_imm_ld_sd(inst[6:5], inst[12:10]);
              decompress_rvc =
                  enc_s_op(imm[11:0], rs2p, rs1p, `FUNCT3_SD,
                           `OPCODE_STORE_FP);
            end
            3'b110: begin
              imm = rvc_imm_lw_sw(inst[5], inst[12:10], inst[6]);
              decompress_rvc = enc_s(imm[11:0], rs2p, rs1p, `FUNCT3_SW);
            end
            3'b111: begin
              imm = rvc_imm_ld_sd(inst[6:5], inst[12:10]);
              decompress_rvc = enc_s(imm[11:0], rs2p, rs1p, `FUNCT3_SD);
            end
            default: begin end
          endcase
        end

        2'b01: begin
          case (inst[15:13])
            3'b000: begin
              imm = rvc_imm_6(inst[12], inst[6:2]);
              decompress_rvc =
                  enc_i(imm[11:0], rd, `FUNCT3_ADD_SUB, rd,
                        `OPCODE_OP_IMM);
            end
            3'b001: begin
              imm = rvc_imm_6(inst[12], inst[6:2]);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], rd, `FUNCT3_ADD_SUB, rd,
                          `OPCODE_OP_IMM_32);
            end
            3'b010: begin
              imm = rvc_imm_6(inst[12], inst[6:2]);
              decompress_rvc =
                  enc_i(imm[11:0], 5'd0, `FUNCT3_ADD_SUB, rd,
                        `OPCODE_OP_IMM);
            end
            3'b011: begin
              if (rd == 5'd2) begin
                imm = rvc_imm_addi16sp(inst[12], inst[4:3],
                                        inst[5], inst[2], inst[6]);
                if (imm != {`XLEN{1'b0}})
                  decompress_rvc =
                      enc_i(imm[11:0], 5'd2, `FUNCT3_ADD_SUB, 5'd2,
                            `OPCODE_OP_IMM);
              end else begin
                imm = rvc_imm_6(inst[12], inst[6:2]);
                if ((rd != 5'd0) && (imm != {`XLEN{1'b0}}))
                  decompress_rvc = enc_u(imm[19:0], rd, `OPCODE_LUI);
              end
            end
            3'b100: begin
              case (inst[11:10])
                2'b00: begin
                  decompress_rvc =
                      enc_i({6'b000000, shamt}, rs1p,
                            `FUNCT3_SRL_SRA, rs1p, `OPCODE_OP_IMM);
                end
                2'b01: begin
                  decompress_rvc =
                      enc_i({6'b010000, shamt}, rs1p,
                            `FUNCT3_SRL_SRA, rs1p, `OPCODE_OP_IMM);
                end
                2'b10: begin
                  imm = rvc_imm_6(inst[12], inst[6:2]);
                  decompress_rvc =
                      enc_i(imm[11:0], rs1p, `FUNCT3_AND, rs1p,
                            `OPCODE_OP_IMM);
                end
                2'b11: begin
                  if (inst[12] == 1'b0) begin
                    case (inst[6:5])
                      2'b00: decompress_rvc =
                          enc_r(`FUNCT7_ALT, rs2p, rs1p, `FUNCT3_ADD_SUB,
                                rs1p, `OPCODE_OP);
                      2'b01: decompress_rvc =
                          enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_XOR,
                                rs1p, `OPCODE_OP);
                      2'b10: decompress_rvc =
                          enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_OR,
                                rs1p, `OPCODE_OP);
                      2'b11: decompress_rvc =
                          enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_AND,
                                rs1p, `OPCODE_OP);
                      default: begin end
                    endcase
                  end else begin
                    case (inst[6:5])
                      2'b00: decompress_rvc =
                          enc_r(`FUNCT7_ALT, rs2p, rs1p, `FUNCT3_ADD_SUB,
                                rs1p, `OPCODE_OP_32);
                      2'b01: decompress_rvc =
                          enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_ADD_SUB,
                                rs1p, `OPCODE_OP_32);
                      default: begin end
                    endcase
                  end
                end
                default: begin end
              endcase
            end
            3'b101: begin
              imm = rvc_imm_j(inst[12], inst[8], inst[10:9],
                              inst[6], inst[7], inst[2],
                              inst[11], inst[5:3]);
              decompress_rvc = enc_j(imm[20:1], 5'd0);
            end
            3'b110: begin
              imm = rvc_imm_b(inst[12], inst[6:5], inst[2],
                              inst[11:10], inst[4:3]);
              decompress_rvc = enc_b(imm[12:1], 5'd0, rs1p, `FUNCT3_BEQ);
            end
            3'b111: begin
              imm = rvc_imm_b(inst[12], inst[6:5], inst[2],
                              inst[11:10], inst[4:3]);
              decompress_rvc = enc_b(imm[12:1], 5'd0, rs1p, `FUNCT3_BNE);
            end
            default: begin end
          endcase
        end

        2'b10: begin
          case (inst[15:13])
            3'b000: begin
              decompress_rvc =
                  enc_i({6'b000000, shamt}, rd, `FUNCT3_SLL, rd,
                        `OPCODE_OP_IMM);
            end
            3'b001: begin
              imm = rvc_imm_ldsp(inst[4:2], inst[12], inst[6:5]);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_LD, rd,
                          `OPCODE_LOAD_FP);
            end
            3'b010: begin
              imm = rvc_imm_lwsp(inst[3:2], inst[12], inst[6:4]);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_LW, rd, `OPCODE_LOAD);
            end
            3'b011: begin
              imm = rvc_imm_ldsp(inst[4:2], inst[12], inst[6:5]);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_LD, rd, `OPCODE_LOAD);
            end
            3'b100: begin
              if (inst[12] == 1'b0) begin
                if (rs2 == 5'd0) begin
                  if (rd != 5'd0)
                    decompress_rvc =
                        enc_i(12'h000, rd, `FUNCT3_ADD_SUB, 5'd0,
                              `OPCODE_JALR);
                end else begin
                  decompress_rvc =
                      enc_r(`FUNCT7_STD, rs2, 5'd0, `FUNCT3_ADD_SUB, rd,
                            `OPCODE_OP);
                end
              end else begin
                if (rs2 == 5'd0) begin
                  if (rd == 5'd0)
                    decompress_rvc =
                        {12'h001, 5'd0, `FUNCT3_ADD_SUB, 5'd0,
                         `OPCODE_SYSTEM};
                  else
                    decompress_rvc =
                        enc_i(12'h000, rd, `FUNCT3_ADD_SUB, 5'd1,
                              `OPCODE_JALR);
                end else begin
                  decompress_rvc =
                      enc_r(`FUNCT7_STD, rs2, rd, `FUNCT3_ADD_SUB, rd,
                            `OPCODE_OP);
                end
              end
            end
            3'b101: begin
              imm = rvc_imm_sdsp(inst[9:7], inst[12:10]);
              decompress_rvc =
                  enc_s_op(imm[11:0], rs2, 5'd2, `FUNCT3_SD,
                           `OPCODE_STORE_FP);
            end
            3'b110: begin
              imm = rvc_imm_swsp(inst[8:7], inst[12:9]);
              decompress_rvc = enc_s(imm[11:0], rs2, 5'd2, `FUNCT3_SW);
            end
            3'b111: begin
              imm = rvc_imm_sdsp(inst[9:7], inst[12:10]);
              decompress_rvc = enc_s(imm[11:0], rs2, 5'd2, `FUNCT3_SD);
            end
            default: begin end
          endcase
        end

        default: begin end
      endcase
    end
  endfunction

  assign inst_o = decompress_rvc(inst_i);

endmodule
