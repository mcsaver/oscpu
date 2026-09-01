`include "tensor_npu_defs.vh"

// Tensor 扩展指令固定字段译码器。
// 该模块没有状态：64-bit TIU/GDMA 的 LO/HI 配对必须在进入本模块前完成。
module TensorNpuCommandDecoder (
  input              cmd_is_64_i,
  input      [63:0]  cmd_bits_i,

  output reg                         legal_o,
  output reg [`NPU_OP_W-1:0]         op_o,
  output reg [4:0]                   rs_addr_o,
  output reg [4:0]                   imm5_o,
  output reg [5:0]                   dst_id_o,
  output reg [5:0]                   src0_id_o,
  output reg [5:0]                   src1_id_o,
  output reg [5:0]                   src2_id_o,
  output reg [4:0]                   flags_o,
  output reg [1:0]                   sync_engine_o
);

  wire [31:0] lo_w = cmd_bits_i[31:0];
  wire [31:0] hi_w = cmd_bits_i[63:32];

  wire cfg_fixed_w =
      (lo_w[31:25] == 7'b0000101) &&
      (lo_w[14:12] == `NPU_FUNCT3_CONFIG) &&
      (lo_w[6:0] == `NPU_CUSTOM2_OPCODE);

  wire tcr_fixed_w =
      (lo_w[31:25] == 7'b0000111) &&
      (lo_w[14:12] == `NPU_FUNCT3_CONFIG) &&
      (lo_w[6:0] == `NPU_CUSTOM2_OPCODE);

  wire tiu_fixed_w =
      (hi_w[31:25] == 7'b0000101) &&
      (hi_w[14:12] == `NPU_FUNCT3_TENSOR) &&
      (hi_w[6:0] == `NPU_CUSTOM2_OPCODE) &&
      (lo_w[31:27] == 5'b00000) &&
      (lo_w[25] == 1'b1) &&
      (lo_w[14:12] == `NPU_FUNCT3_TENSOR) &&
      (lo_w[6:0] == `NPU_CUSTOM2_OPCODE);

  wire gdma_fixed_w =
      (hi_w[31:25] == 7'b0000111) &&
      (hi_w[24:21] == 4'b0000) &&
      (hi_w[14:12] == `NPU_FUNCT3_TENSOR) &&
      (hi_w[6:0] == `NPU_CUSTOM2_OPCODE) &&
      (lo_w[31:27] == 5'b00000) &&
      (lo_w[25] == 1'b1) &&
      (lo_w[14:12] == `NPU_FUNCT3_TENSOR) &&
      (lo_w[6:0] == `NPU_CUSTOM2_OPCODE);

  // 组合译码只产生事实，不持有 command 生命周期。
  always @(*) begin
    legal_o = 1'b0;
    op_o = `NPU_OP_INVALID;
    rs_addr_o = lo_w[19:15];
    imm5_o = lo_w[11:7];
    dst_id_o = 6'd0;
    src0_id_o = 6'd0;
    src1_id_o = 6'd0;
    src2_id_o = 6'd0;
    flags_o = 5'd0;
    sync_engine_o = lo_w[8:7];

    if (!cmd_is_64_i) begin
      if (cfg_fixed_w) begin
        case (lo_w[24:20])
          5'b00000: begin legal_o = 1'b1; op_o = `NPU_OP_CFG_SATU; end
          5'b00001: begin legal_o = 1'b1; op_o = `NPU_OP_CFG_PAD; end
          5'b00010: begin legal_o = 1'b1; op_o = `NPU_OP_CFG_INSRT; end
          5'b00011: begin legal_o = 1'b1; op_o = `NPU_OP_CFG_STENCIL; end
          5'b00101: begin legal_o = 1'b1; op_o = `NPU_OP_CFG_ROUND; end
          5'b00111: begin legal_o = 1'b1; op_o = `NPU_OP_CFG_RSQRT_ITER; end
          5'b01001: begin legal_o = 1'b1; op_o = `NPU_OP_CFG_DMAIDX; end
          5'b01010,
          5'b01011,
          5'b01100,
          5'b01101: begin legal_o = 1'b1; op_o = `NPU_OP_UNSUPPORTED; end
          5'b01110: begin
            // engine 只允许 0=all、1=TIU、2=GDMA；高位必须为零。
            legal_o = (lo_w[11:7] <= 5'd2);
            op_o = legal_o ? `NPU_OP_SYNC : `NPU_OP_INVALID;
          end
          default: begin legal_o = 1'b0; op_o = `NPU_OP_INVALID; end
        endcase
      end else if (tcr_fixed_w) begin
        case (lo_w[24:20])
          5'b00000: begin legal_o = 1'b1; op_o = `NPU_OP_TCR_TR; end
          5'b00001: begin legal_o = 1'b1; op_o = `NPU_OP_TCR_CR; end
          5'b00010: begin legal_o = 1'b1; op_o = `NPU_OP_TCR_GR; end
          5'b01001: begin
            legal_o = (lo_w[19:15] == 5'd0);
            op_o = legal_o ? `NPU_OP_CFG_QUANT : `NPU_OP_INVALID;
          end
          5'b01010: begin
            legal_o = (lo_w[19:15] == 5'd0);
            op_o = legal_o ? `NPU_OP_CFG_KZP : `NPU_OP_INVALID;
          end
          5'b01011,
          5'b01100: begin legal_o = 1'b1; op_o = `NPU_OP_UNSUPPORTED; end
          default: begin legal_o = 1'b0; op_o = `NPU_OP_INVALID; end
        endcase
      end
    end else begin
      if (tiu_fixed_w) begin
        dst_id_o = {1'b0, hi_w[19:15]};
        src0_id_o = {1'b0, hi_w[11:7]};
        src1_id_o = {1'b0, lo_w[11:7]};
        src2_id_o = {1'b0, lo_w[19:15]};
        flags_o = lo_w[24:20];
        legal_o = 1'b1;

        if ((hi_w[24:20] == 5'b00101) && (lo_w[26] == 1'b0)) begin
          case (lo_w[24:22])
            3'b000: op_o = `NPU_OP_MM2_NN;
            3'b001: op_o = `NPU_OP_MM2_NT;
            3'b010: op_o = `NPU_OP_MM2_TT;
            default: op_o = `NPU_OP_UNSUPPORTED;
          endcase
        end else begin
          op_o = `NPU_OP_UNSUPPORTED;
        end
      end else if (gdma_fixed_w) begin
        dst_id_o = hi_w[20:15];
        src0_id_o = {lo_w[15], lo_w[11:7]};
        src1_id_o = lo_w[21:16];
        flags_o = lo_w[24:20];
        legal_o = 1'b1;

        // 基础 dma.ld/st 只有一个 6-bit source，LO[21:16] 在 PDF appendix 中为保留位。
        if ((lo_w[26] == 1'b0) && (lo_w[24:22] == 3'b000) &&
            (lo_w[21:16] == 6'd0))
          op_o = `NPU_OP_DMA_LD;
        else if ((lo_w[26] == 1'b0) && (lo_w[24:22] == 3'b010) &&
                 (lo_w[21:16] == 6'd0))
          op_o = `NPU_OP_DMA_ST;
        else if ((lo_w[26] == 1'b0) &&
                 ((lo_w[24:22] == 3'b000) ||
                  (lo_w[24:22] == 3'b010))) begin
          legal_o = 1'b0;
          op_o = `NPU_OP_INVALID;
        end
        else
          op_o = `NPU_OP_UNSUPPORTED;
      end
    end
  end

endmodule
