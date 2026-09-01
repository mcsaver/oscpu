`include "tensor_npu_defs.vh"

// 40 项 Tensor 配置寄存器与 MVP 所需 CSR。
// descriptor 数据本体不做复位；复位只清 word-valid，未初始化内容因而永远不会被合法命令消费。
module TensorNpuRegisterFile (
  input                         clk,
  input                         rst,

  input                         cfg_valid_i,
  input      [`NPU_OP_W-1:0]    cfg_op_i,
  input      [63:0]             cfg_rs_value_i,
  input      [4:0]              cfg_imm5_i,
  output reg                    cfg_error_o,
  output reg [`NPU_ERROR_W-1:0] cfg_error_code_o,

  input                         desc_write_valid_i,
  input      [5:0]              desc_write_id_i,
  input      [2:0]              desc_write_word_i,
  input      [63:0]             desc_write_data_i,
  output reg                    desc_write_error_o,
  output reg [`NPU_ERROR_W-1:0] desc_write_error_code_o,

  input                         sync_tag_write_valid_i,
  input      [63:0]             sync_tag_write_data_i,
  input                         sync_tag_ack_i,
  output     [63:0]             sync_tag_o,
  output                        sync_tag_valid_o,

  input      [5:0]              read0_id_i,
  input      [5:0]              read1_id_i,
  input      [5:0]              read2_id_i,
  input      [5:0]              read3_id_i,
  input      [5:0]              read4_id_i,
  output reg [`NPU_DESC_W-1:0]  read0_desc_o,
  output reg [`NPU_DESC_W-1:0]  read1_desc_o,
  output reg [`NPU_DESC_W-1:0]  read2_desc_o,
  output reg [`NPU_DESC_W-1:0]  read3_desc_o,
  output reg [`NPU_DESC_W-1:0]  read4_desc_o,
  output reg [4:0]              read0_words_valid_o,
  output reg [4:0]              read1_words_valid_o,
  output reg [4:0]              read2_words_valid_o,
  output reg [4:0]              read3_words_valid_o,
  output reg [4:0]              read4_words_valid_o,

  output                        csr_saturate_o,
  output                        csr_sym_saturate_o,
  output     [3:0]              csr_round_mode_o,
  output     [3:0]              csr_rsqrt_iter_o,
  output     [63:0]             csr_padding_o,
  output     [63:0]             csr_inserts_o,
  output     [63:0]             csr_stencil_o,
  output     [63:0]             csr_dma_idx_o,
  output     [4:0]              csr_quant_id_o,
  output     [4:0]              csr_kzp_id_o
);

  reg [`NPU_DESC_W-1:0] tcr_data_q [0:`NPU_TCR_COUNT-1];
  reg [4:0] tcr_word_valid_q [0:`NPU_TCR_COUNT-1];

  reg csr_saturate_q;
  reg csr_sym_saturate_q;
  reg [3:0] csr_round_mode_q;
  reg [3:0] csr_rsqrt_iter_q;
  reg [63:0] csr_padding_q;
  reg [63:0] csr_inserts_q;
  reg [63:0] csr_stencil_q;
  reg [63:0] csr_dma_idx_q;
  reg [4:0] csr_quant_id_q;
  reg [4:0] csr_kzp_id_q;
  reg [63:0] sync_tag_q;
  reg sync_tag_valid_q;

  integer reset_idx;
  reg [5:0] cfg_target_id_w;

  assign sync_tag_o = sync_tag_q;
  assign sync_tag_valid_o = sync_tag_valid_q;
  assign csr_saturate_o = csr_saturate_q;
  assign csr_sym_saturate_o = csr_sym_saturate_q;
  assign csr_round_mode_o = csr_round_mode_q;
  assign csr_rsqrt_iter_o = csr_rsqrt_iter_q;
  assign csr_padding_o = csr_padding_q;
  assign csr_inserts_o = csr_inserts_q;
  assign csr_stencil_o = csr_stencil_q;
  assign csr_dma_idx_o = csr_dma_idx_q;
  assign csr_quant_id_o = csr_quant_id_q;
  assign csr_kzp_id_o = csr_kzp_id_q;

  // 配置指令中的 ca/ta/ga 是各自寄存器类内的局部索引；映射到统一 R0..R39。
  always @(*) begin
    cfg_target_id_w = 6'd0;
    cfg_error_o = 1'b0;
    cfg_error_code_o = `NPU_ERR_NONE;

    case (cfg_op_i)
      `NPU_OP_TCR_CR: begin
        cfg_target_id_w = {1'b0, cfg_imm5_i};
        if (cfg_imm5_i >= 5'd8) begin
          cfg_error_o = 1'b1;
          cfg_error_code_o = `NPU_ERR_DESC_ID;
        end
      end
      `NPU_OP_TCR_TR: begin
        cfg_target_id_w = 6'd8 + {1'b0, cfg_imm5_i};
        if (cfg_imm5_i >= 5'd24) begin
          cfg_error_o = 1'b1;
          cfg_error_code_o = `NPU_ERR_DESC_ID;
        end
      end
      `NPU_OP_TCR_GR: begin
        cfg_target_id_w = 6'd32 + {3'd0, cfg_imm5_i[2:0]};
        if (cfg_imm5_i >= 5'd8) begin
          cfg_error_o = 1'b1;
          cfg_error_code_o = `NPU_ERR_DESC_ID;
        end
      end
      `NPU_OP_CFG_SATU,
      `NPU_OP_CFG_PAD,
      `NPU_OP_CFG_INSRT,
      `NPU_OP_CFG_STENCIL,
      `NPU_OP_CFG_ROUND,
      `NPU_OP_CFG_RSQRT_ITER,
      `NPU_OP_CFG_DMAIDX,
      `NPU_OP_CFG_QUANT,
      `NPU_OP_CFG_KZP: begin end
      default: begin
        cfg_error_o = 1'b1;
        cfg_error_code_o = `NPU_ERR_ILLEGAL_ENCODING;
      end
    endcase
  end

  // 平台 descriptor window 合法性：CR=word0，TR=word0..3，GR=word0..4。
  always @(*) begin
    desc_write_error_o = 1'b0;
    desc_write_error_code_o = `NPU_ERR_NONE;
    if (desc_write_id_i >= 6'd40) begin
      desc_write_error_o = 1'b1;
      desc_write_error_code_o = `NPU_ERR_DESC_ID;
    end else if ((desc_write_id_i < 6'd8) && (desc_write_word_i != 3'd0)) begin
      desc_write_error_o = 1'b1;
      desc_write_error_code_o = `NPU_ERR_DESC_WORD;
    end else if ((desc_write_id_i < 6'd32) && (desc_write_word_i >= 3'd4)) begin
      desc_write_error_o = 1'b1;
      desc_write_error_code_o = `NPU_ERR_DESC_WORD;
    end else if (desc_write_word_i >= 3'd5) begin
      desc_write_error_o = 1'b1;
      desc_write_error_code_o = `NPU_ERR_DESC_WORD;
    end
  end

  // 五个异步只读端口综合为显式复制/选择网络；ID 越界返回全零且 valid=0。
  always @(*) begin
    read0_desc_o = {`NPU_DESC_W{1'b0}};
    read1_desc_o = {`NPU_DESC_W{1'b0}};
    read2_desc_o = {`NPU_DESC_W{1'b0}};
    read3_desc_o = {`NPU_DESC_W{1'b0}};
    read4_desc_o = {`NPU_DESC_W{1'b0}};
    read0_words_valid_o = 5'd0;
    read1_words_valid_o = 5'd0;
    read2_words_valid_o = 5'd0;
    read3_words_valid_o = 5'd0;
    read4_words_valid_o = 5'd0;

    if (read0_id_i < 6'd40) begin
      read0_desc_o = (read0_id_i == 6'd0) ? {`NPU_DESC_W{1'b0}} : tcr_data_q[read0_id_i];
      read0_words_valid_o = (read0_id_i == 6'd0) ? 5'b00001 : tcr_word_valid_q[read0_id_i];
    end
    if (read1_id_i < 6'd40) begin
      read1_desc_o = (read1_id_i == 6'd0) ? {`NPU_DESC_W{1'b0}} : tcr_data_q[read1_id_i];
      read1_words_valid_o = (read1_id_i == 6'd0) ? 5'b00001 : tcr_word_valid_q[read1_id_i];
    end
    if (read2_id_i < 6'd40) begin
      read2_desc_o = (read2_id_i == 6'd0) ? {`NPU_DESC_W{1'b0}} : tcr_data_q[read2_id_i];
      read2_words_valid_o = (read2_id_i == 6'd0) ? 5'b00001 : tcr_word_valid_q[read2_id_i];
    end
    if (read3_id_i < 6'd40) begin
      read3_desc_o = (read3_id_i == 6'd0) ? {`NPU_DESC_W{1'b0}} : tcr_data_q[read3_id_i];
      read3_words_valid_o = (read3_id_i == 6'd0) ? 5'b00001 : tcr_word_valid_q[read3_id_i];
    end
    if (read4_id_i < 6'd40) begin
      read4_desc_o = (read4_id_i == 6'd0) ? {`NPU_DESC_W{1'b0}} : tcr_data_q[read4_id_i];
      read4_words_valid_o = (read4_id_i == 6'd0) ? 5'b00001 : tcr_word_valid_q[read4_id_i];
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      csr_saturate_q <= 1'b0;
      csr_sym_saturate_q <= 1'b0;
      csr_round_mode_q <= 4'd0;
      csr_rsqrt_iter_q <= 4'd0;
      csr_padding_q <= 64'd0;
      csr_inserts_q <= 64'd0;
      csr_stencil_q <= 64'd0;
      csr_dma_idx_q <= 64'd0;
      csr_quant_id_q <= 5'd0;
      csr_kzp_id_q <= 5'd0;
      sync_tag_q <= 64'd0;
      sync_tag_valid_q <= 1'b0;
      // 只清 40 组 5-bit valid；descriptor 数据阵列本身不复位，避免无意义的大量初始化事件。
      for (reset_idx = 0; reset_idx < `NPU_TCR_COUNT; reset_idx = reset_idx + 1)
        tcr_word_valid_q[reset_idx] <= 5'd0;
    end else begin
      if (sync_tag_write_valid_i) begin
        sync_tag_q <= sync_tag_write_data_i;
        sync_tag_valid_q <= 1'b1;
      end else if (sync_tag_ack_i) begin
        sync_tag_q <= 64'd0;
        sync_tag_valid_q <= 1'b0;
      end

      if (cfg_valid_i && !cfg_error_o) begin
        case (cfg_op_i)
          `NPU_OP_CFG_SATU: begin
            csr_saturate_q <= cfg_rs_value_i[0];
            csr_sym_saturate_q <= cfg_rs_value_i[1];
          end
          `NPU_OP_CFG_PAD: csr_padding_q <= cfg_rs_value_i;
          `NPU_OP_CFG_INSRT: csr_inserts_q <= cfg_rs_value_i;
          `NPU_OP_CFG_STENCIL: csr_stencil_q <= cfg_rs_value_i;
          `NPU_OP_CFG_ROUND: csr_round_mode_q <= cfg_rs_value_i[3:0];
          `NPU_OP_CFG_RSQRT_ITER: csr_rsqrt_iter_q <= cfg_rs_value_i[3:0];
          `NPU_OP_CFG_DMAIDX: csr_dma_idx_q <= cfg_rs_value_i;
          `NPU_OP_CFG_QUANT: csr_quant_id_q <= cfg_imm5_i;
          `NPU_OP_CFG_KZP: csr_kzp_id_q <= cfg_imm5_i;
          `NPU_OP_TCR_CR,
          `NPU_OP_TCR_TR,
          `NPU_OP_TCR_GR: begin
            // ca0 是硬连零常量；对它的写按规范静默忽略。
            if (cfg_target_id_w != 6'd0) begin
              tcr_data_q[cfg_target_id_w][63:0] <= cfg_rs_value_i;
              tcr_word_valid_q[cfg_target_id_w][0] <= 1'b1;
            end
          end
          default: begin end
        endcase
      end else if (desc_write_valid_i && !desc_write_error_o) begin
        // host descriptor window 同样不能改写 ca0。
        if (desc_write_id_i != 6'd0) begin
          case (desc_write_word_i)
            3'd0: tcr_data_q[desc_write_id_i][63:0] <= desc_write_data_i;
            3'd1: tcr_data_q[desc_write_id_i][127:64] <= desc_write_data_i;
            3'd2: tcr_data_q[desc_write_id_i][191:128] <= desc_write_data_i;
            3'd3: tcr_data_q[desc_write_id_i][255:192] <= desc_write_data_i;
            3'd4: tcr_data_q[desc_write_id_i][319:256] <= desc_write_data_i;
            default: begin end
          endcase
          tcr_word_valid_q[desc_write_id_i][desc_write_word_i] <= 1'b1;
        end
      end
    end
  end

`ifdef NPU_ASSERT
  always @(posedge clk) begin
    if (!rst && cfg_valid_i && desc_write_valid_i)
      $error("NPU I4 违约: config 与 descriptor write 不得同拍");
  end
`endif

endmodule
