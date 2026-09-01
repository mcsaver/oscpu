`timescale 1ns/1ps
`include "tensor_npu_defs.vh"

module tb_decoder_regfile;
  reg clk;
  reg rst;

  reg         cmd_is_64;
  reg  [63:0] cmd_bits;
  wire        dec_legal;
  wire [`NPU_OP_W-1:0] dec_op;
  wire [4:0]  dec_rs_addr;
  wire [4:0]  dec_imm5;
  wire [5:0]  dec_dst;
  wire [5:0]  dec_src0;
  wire [5:0]  dec_src1;
  wire [5:0]  dec_src2;
  wire [4:0]  dec_flags;
  wire [1:0]  dec_sync_engine;

  reg                         cfg_valid;
  reg  [`NPU_OP_W-1:0]        cfg_op;
  reg  [63:0]                 cfg_rs_value;
  reg  [4:0]                  cfg_imm5;
  wire                        cfg_error;
  wire [`NPU_ERROR_W-1:0]     cfg_error_code;

  reg                         desc_write_valid;
  reg  [5:0]                  desc_write_id;
  reg  [2:0]                  desc_write_word;
  reg  [63:0]                 desc_write_data;
  wire                        desc_write_error;
  wire [`NPU_ERROR_W-1:0]     desc_write_error_code;

  reg                         sync_tag_write_valid;
  reg  [63:0]                 sync_tag_write_data;
  reg                         sync_tag_ack;
  wire [63:0]                 sync_tag;
  wire                        sync_tag_valid;

  reg  [5:0]                  read0_id;
  reg  [5:0]                  read1_id;
  reg  [5:0]                  read2_id;
  reg  [5:0]                  read3_id;
  reg  [5:0]                  read4_id;
  wire [`NPU_DESC_W-1:0]      read0_desc;
  wire [`NPU_DESC_W-1:0]      read1_desc;
  wire [`NPU_DESC_W-1:0]      read2_desc;
  wire [`NPU_DESC_W-1:0]      read3_desc;
  wire [`NPU_DESC_W-1:0]      read4_desc;
  wire [4:0]                  read0_words_valid;
  wire [4:0]                  read1_words_valid;
  wire [4:0]                  read2_words_valid;
  wire [4:0]                  read3_words_valid;
  wire [4:0]                  read4_words_valid;

  wire                        csr_saturate;
  wire                        csr_sym_saturate;
  wire [3:0]                  csr_round_mode;
  wire [3:0]                  csr_rsqrt_iter;
  wire [63:0]                 csr_padding;
  wire [63:0]                 csr_inserts;
  wire [63:0]                 csr_stencil;
  wire [63:0]                 csr_dma_idx;
  wire [4:0]                  csr_quant_id;
  wire [4:0]                  csr_kzp_id;

  integer checks;

  TensorNpuCommandDecoder u_decoder (
    .cmd_is_64_i(cmd_is_64),
    .cmd_bits_i(cmd_bits),
    .legal_o(dec_legal),
    .op_o(dec_op),
    .rs_addr_o(dec_rs_addr),
    .imm5_o(dec_imm5),
    .dst_id_o(dec_dst),
    .src0_id_o(dec_src0),
    .src1_id_o(dec_src1),
    .src2_id_o(dec_src2),
    .flags_o(dec_flags),
    .sync_engine_o(dec_sync_engine)
  );

  TensorNpuRegisterFile u_regfile (
    .clk(clk),
    .rst(rst),
    .cfg_valid_i(cfg_valid),
    .cfg_op_i(cfg_op),
    .cfg_rs_value_i(cfg_rs_value),
    .cfg_imm5_i(cfg_imm5),
    .cfg_error_o(cfg_error),
    .cfg_error_code_o(cfg_error_code),
    .desc_write_valid_i(desc_write_valid),
    .desc_write_id_i(desc_write_id),
    .desc_write_word_i(desc_write_word),
    .desc_write_data_i(desc_write_data),
    .desc_write_error_o(desc_write_error),
    .desc_write_error_code_o(desc_write_error_code),
    .sync_tag_write_valid_i(sync_tag_write_valid),
    .sync_tag_write_data_i(sync_tag_write_data),
    .sync_tag_ack_i(sync_tag_ack),
    .sync_tag_o(sync_tag),
    .sync_tag_valid_o(sync_tag_valid),
    .read0_id_i(read0_id),
    .read1_id_i(read1_id),
    .read2_id_i(read2_id),
    .read3_id_i(read3_id),
    .read4_id_i(read4_id),
    .read0_desc_o(read0_desc),
    .read1_desc_o(read1_desc),
    .read2_desc_o(read2_desc),
    .read3_desc_o(read3_desc),
    .read4_desc_o(read4_desc),
    .read0_words_valid_o(read0_words_valid),
    .read1_words_valid_o(read1_words_valid),
    .read2_words_valid_o(read2_words_valid),
    .read3_words_valid_o(read3_words_valid),
    .read4_words_valid_o(read4_words_valid),
    .csr_saturate_o(csr_saturate),
    .csr_sym_saturate_o(csr_sym_saturate),
    .csr_round_mode_o(csr_round_mode),
    .csr_rsqrt_iter_o(csr_rsqrt_iter),
    .csr_padding_o(csr_padding),
    .csr_inserts_o(csr_inserts),
    .csr_stencil_o(csr_stencil),
    .csr_dma_idx_o(csr_dma_idx),
    .csr_quant_id_o(csr_quant_id),
    .csr_kzp_id_o(csr_kzp_id)
  );

  function automatic [31:0] enc_cfg;
    input [4:0] subop;
    input [4:0] rs_addr;
    input [4:0] imm5;
    begin
      enc_cfg = {7'b0000101, subop, rs_addr, `NPU_FUNCT3_CONFIG,
                 imm5, `NPU_CUSTOM2_OPCODE};
    end
  endfunction

  function automatic [31:0] enc_tcr;
    input [4:0] subop;
    input [4:0] rs_addr;
    input [4:0] imm5;
    begin
      enc_tcr = {7'b0000111, subop, rs_addr, `NPU_FUNCT3_CONFIG,
                 imm5, `NPU_CUSTOM2_OPCODE};
    end
  endfunction

  function automatic [63:0] enc_tiu;
    input [2:0] variant;
    input       rq;
    input       relu;
    input [4:0] dst;
    input [4:0] src0;
    input [4:0] src1;
    input [4:0] src2;
    reg [31:0] lo;
    reg [31:0] hi;
    begin
      hi = {7'b0000101, 5'b00101, dst, `NPU_FUNCT3_TENSOR,
            src0, `NPU_CUSTOM2_OPCODE};
      lo = {5'b00000, 1'b0, 1'b1, variant, rq, relu, src2,
            `NPU_FUNCT3_TENSOR, src1, `NPU_CUSTOM2_OPCODE};
      enc_tiu = {hi, lo};
    end
  endfunction

  function automatic [63:0] enc_dma;
    input [2:0] variant;
    input [5:0] dst;
    input [5:0] src0;
    input [5:0] src1;
    reg [31:0] lo;
    reg [31:0] hi;
    begin
      hi = {7'b0000111, 4'b0000, dst, `NPU_FUNCT3_TENSOR,
            5'b00000, `NPU_CUSTOM2_OPCODE};
      lo = {5'b00000, 1'b0, 1'b1, variant, src1, src0[5],
            `NPU_FUNCT3_TENSOR, src0[4:0], `NPU_CUSTOM2_OPCODE};
      enc_dma = {hi, lo};
    end
  endfunction

  task automatic expect_decode;
    input        is_64;
    input [63:0] bits;
    input        exp_legal;
    input [`NPU_OP_W-1:0] exp_op;
    input [4:0]  exp_rs;
    input [4:0]  exp_imm;
    input [5:0]  exp_dst;
    input [5:0]  exp_src0;
    input [5:0]  exp_src1;
    input [5:0]  exp_src2;
    input [4:0]  exp_flags;
    begin
      cmd_is_64 = is_64;
      cmd_bits = bits;
      #1;
      checks = checks + 1;
      if ((dec_legal !== exp_legal) ||
          (dec_op !== exp_op) ||
          (dec_rs_addr !== exp_rs) ||
          (dec_imm5 !== exp_imm) ||
          (dec_dst !== exp_dst) ||
          (dec_src0 !== exp_src0) ||
          (dec_src1 !== exp_src1) ||
          (dec_src2 !== exp_src2) ||
          (dec_flags !== exp_flags)) begin
        $fatal(1, "decode mismatch check=%0d legal=%0b/%0b op=%0d/%0d rs=%0d/%0d imm=%0d/%0d dst=%0d/%0d src=%0d,%0d,%0d/%0d,%0d,%0d flags=%0h/%0h bits=%h",
               checks, dec_legal, exp_legal, dec_op, exp_op,
               dec_rs_addr, exp_rs, dec_imm5, exp_imm,
               dec_dst, exp_dst, dec_src0, dec_src1, dec_src2,
               exp_src0, exp_src1, exp_src2, dec_flags, exp_flags, bits);
      end
    end
  endtask

  task automatic cfg_write;
    input [`NPU_OP_W-1:0] op;
    input [4:0] imm5;
    input [63:0] data;
    input exp_error;
    input [`NPU_ERROR_W-1:0] exp_code;
    begin
      cfg_op = op;
      cfg_imm5 = imm5;
      cfg_rs_value = data;
      cfg_valid = 1'b1;
      #1;
      checks = checks + 1;
      if ((cfg_error !== exp_error) || (cfg_error_code !== exp_code))
        $fatal(1, "cfg legality mismatch check=%0d op=%0d imm=%0d err=%0b/%0b code=%0d/%0d",
               checks, op, imm5, cfg_error, exp_error, cfg_error_code, exp_code);
      @(posedge clk);
      #1;
      cfg_valid = 1'b0;
    end
  endtask

  task automatic desc_write;
    input [5:0] id;
    input [2:0] word_idx;
    input [63:0] data;
    input exp_error;
    input [`NPU_ERROR_W-1:0] exp_code;
    begin
      desc_write_id = id;
      desc_write_word = word_idx;
      desc_write_data = data;
      desc_write_valid = 1'b1;
      #1;
      checks = checks + 1;
      if ((desc_write_error !== exp_error) ||
          (desc_write_error_code !== exp_code))
        $fatal(1, "descriptor legality mismatch check=%0d id=%0d word=%0d err=%0b/%0b code=%0d/%0d",
               checks, id, word_idx, desc_write_error, exp_error,
               desc_write_error_code, exp_code);
      @(posedge clk);
      #1;
      desc_write_valid = 1'b0;
    end
  endtask

  task automatic expect_read0;
    input [5:0] id;
    input [4:0] exp_valid;
    input [319:0] exp_data;
    begin
      read0_id = id;
      #1;
      checks = checks + 1;
      if ((read0_words_valid !== exp_valid) || (read0_desc !== exp_data))
        $fatal(1, "read0 mismatch check=%0d id=%0d valid=%05b/%05b data=%h/%h",
               checks, id, read0_words_valid, exp_valid, read0_desc, exp_data);
    end
  endtask

  always #5 clk <= ~clk;

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    checks = 0;
    cmd_is_64 = 1'b0;
    cmd_bits = 64'd0;
    cfg_valid = 1'b0;
    cfg_op = `NPU_OP_INVALID;
    cfg_rs_value = 64'd0;
    cfg_imm5 = 5'd0;
    desc_write_valid = 1'b0;
    desc_write_id = 6'd0;
    desc_write_word = 3'd0;
    desc_write_data = 64'd0;
    sync_tag_write_valid = 1'b0;
    sync_tag_write_data = 64'd0;
    sync_tag_ack = 1'b0;
    read0_id = 6'd0;
    read1_id = 6'd0;
    read2_id = 6'd0;
    read3_id = 6'd0;
    read4_id = 6'd0;

    repeat (2) @(posedge clk);
    #1;
    rst = 1'b0;

    // 单字 config/TCR/sync 编码。
    expect_decode(1'b0, {32'd0, enc_cfg(5'b00000, 5'd3, 5'd0)},
                  1'b1, `NPU_OP_CFG_SATU, 5'd3, 5'd0,
                  6'd0, 6'd0, 6'd0, 6'd0, 5'd0);
    expect_decode(1'b0, {32'd0, enc_tcr(5'b00000, 5'd7, 5'd23)},
                  1'b1, `NPU_OP_TCR_TR, 5'd7, 5'd23,
                  6'd0, 6'd0, 6'd0, 6'd0, 5'd0);
    expect_decode(1'b0, {32'd0, enc_tcr(5'b01001, 5'd0, 5'd31)},
                  1'b1, `NPU_OP_CFG_QUANT, 5'd0, 5'd31,
                  6'd0, 6'd0, 6'd0, 6'd0, 5'd0);
    expect_decode(1'b0, {32'd0, enc_tcr(5'b01001, 5'd1, 5'd31)},
                  1'b0, `NPU_OP_INVALID, 5'd1, 5'd31,
                  6'd0, 6'd0, 6'd0, 6'd0, 5'd0);
    expect_decode(1'b0, {32'd0, enc_cfg(5'b01110, 5'd4, 5'd2)},
                  1'b1, `NPU_OP_SYNC, 5'd4, 5'd2,
                  6'd0, 6'd0, 6'd0, 6'd0, 5'd0);
    if (dec_sync_engine !== 2'd2)
      $fatal(1, "sync engine mismatch got=%0d expected=2", dec_sync_engine);
    expect_decode(1'b0, {32'd0, enc_cfg(5'b01110, 5'd4, 5'd3)},
                  1'b0, `NPU_OP_INVALID, 5'd4, 5'd3,
                  6'd0, 6'd0, 6'd0, 6'd0, 5'd0);

    // 双 word TIU/GDMA 编码与非法 fixed-bit。
    expect_decode(1'b1, enc_tiu(3'b000, 1'b1, 1'b1,
                                5'd9, 5'd10, 5'd11, 5'd12),
                  1'b1, `NPU_OP_MM2_NN, 5'd12, 5'd11,
                  6'd9, 6'd10, 6'd11, 6'd12, 5'b00011);
    expect_decode(1'b1, enc_tiu(3'b001, 1'b0, 1'b0,
                                5'd1, 5'd2, 5'd3, 5'd4),
                  1'b1, `NPU_OP_MM2_NT, 5'd4, 5'd3,
                  6'd1, 6'd2, 6'd3, 6'd4, 5'b00100);
    expect_decode(1'b1, enc_tiu(3'b010, 1'b0, 1'b0,
                                5'd1, 5'd2, 5'd3, 5'd4),
                  1'b1, `NPU_OP_MM2_TT, 5'd4, 5'd3,
                  6'd1, 6'd2, 6'd3, 6'd4, 5'b01000);
    expect_decode(1'b1, enc_tiu(3'b111, 1'b0, 1'b0,
                                5'd1, 5'd2, 5'd3, 5'd4),
                  1'b1, `NPU_OP_UNSUPPORTED, 5'd4, 5'd3,
                  6'd1, 6'd2, 6'd3, 6'd4, 5'b11100);
    expect_decode(1'b1, enc_dma(3'b000, 6'd35, 6'd42, 6'd0),
                  1'b1, `NPU_OP_DMA_LD, 5'd1, 5'd10,
                  6'd35, 6'd42, 6'd0, 6'd0, 5'b00000);
    expect_decode(1'b1, enc_dma(3'b010, 6'd35, 6'd42, 6'd0),
                  1'b1, `NPU_OP_DMA_ST, 5'd1, 5'd10,
                  6'd35, 6'd42, 6'd0, 6'd0, 5'b01000);
    expect_decode(1'b1, enc_dma(3'b000, 6'd35, 6'd42, 6'd45),
                  1'b0, `NPU_OP_INVALID, 5'd27, 5'd10,
                  6'd35, 6'd42, 6'd45, 6'd0, 5'b00010);
    expect_decode(1'b1, enc_tiu(3'b000, 1'b0, 1'b0,
                                5'd1, 5'd2, 5'd3, 5'd4) ^ 64'h1,
                  1'b0, `NPU_OP_INVALID, 5'd4, 5'd3,
                  6'd0, 6'd0, 6'd0, 6'd0, 5'd0);

    // reset、ca0、配置 CSR 与 TCR 类内局部索引映射。
    expect_read0(6'd0, 5'b00001, 320'd0);
    if (sync_tag_valid !== 1'b0)
      $fatal(1, "sync tag valid after reset");

    cfg_write(`NPU_OP_CFG_SATU, 5'd0, 64'h3, 1'b0, `NPU_ERR_NONE);
    if ((csr_saturate !== 1'b1) || (csr_sym_saturate !== 1'b1))
      $fatal(1, "saturate CSR mismatch");
    cfg_write(`NPU_OP_CFG_ROUND, 5'd0, 64'hd, 1'b0, `NPU_ERR_NONE);
    cfg_write(`NPU_OP_CFG_RSQRT_ITER, 5'd0, 64'h7, 1'b0, `NPU_ERR_NONE);
    cfg_write(`NPU_OP_CFG_PAD, 5'd0, 64'h0102_0304_0506_0708,
              1'b0, `NPU_ERR_NONE);
    cfg_write(`NPU_OP_CFG_INSRT, 5'd0, 64'h1112_1314_1516_1718,
              1'b0, `NPU_ERR_NONE);
    cfg_write(`NPU_OP_CFG_STENCIL, 5'd0, 64'h2122_2324_2526_2728,
              1'b0, `NPU_ERR_NONE);
    cfg_write(`NPU_OP_CFG_DMAIDX, 5'd0, 64'h3132_3334_3536_3738,
              1'b0, `NPU_ERR_NONE);
    cfg_write(`NPU_OP_CFG_QUANT, 5'd31, 64'd0, 1'b0, `NPU_ERR_NONE);
    cfg_write(`NPU_OP_CFG_KZP, 5'd30, 64'd0, 1'b0, `NPU_ERR_NONE);
    if ((csr_round_mode !== 4'hd) || (csr_rsqrt_iter !== 4'h7) ||
        (csr_padding !== 64'h0102_0304_0506_0708) ||
        (csr_inserts !== 64'h1112_1314_1516_1718) ||
        (csr_stencil !== 64'h2122_2324_2526_2728) ||
        (csr_dma_idx !== 64'h3132_3334_3536_3738) ||
        (csr_quant_id !== 5'd31) || (csr_kzp_id !== 5'd30))
      $fatal(1, "scalar CSR mismatch");

    cfg_write(`NPU_OP_TCR_CR, 5'd0, 64'hffff_ffff_ffff_ffff,
              1'b0, `NPU_ERR_NONE);
    expect_read0(6'd0, 5'b00001, 320'd0);
    cfg_write(`NPU_OP_TCR_CR, 5'd1, 64'h1111_2222_3333_4444,
              1'b0, `NPU_ERR_NONE);
    expect_read0(6'd1, 5'b00001, 320'h1111_2222_3333_4444);
    cfg_write(`NPU_OP_TCR_CR, 5'd8, 64'hdead_beef_dead_beef,
              1'b1, `NPU_ERR_DESC_ID);
    expect_read0(6'd8, 5'b00000, 320'd0);

    cfg_write(`NPU_OP_TCR_TR, 5'd23, 64'h3131_3131_3131_3131,
              1'b0, `NPU_ERR_NONE);
    desc_write(6'd31, 3'd1, 64'h3131_0000_0000_0001,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd31, 3'd2, 64'h3131_0000_0000_0002,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd31, 3'd3, 64'h3131_0000_0000_0003,
               1'b0, `NPU_ERR_NONE);
    expect_read0(6'd31, 5'b01111,
                 {64'd0, 64'h3131_0000_0000_0003,
                  64'h3131_0000_0000_0002, 64'h3131_0000_0000_0001,
                  64'h3131_3131_3131_3131});
    cfg_write(`NPU_OP_TCR_TR, 5'd24, 64'hffff, 1'b1, `NPU_ERR_DESC_ID);
    cfg_write(`NPU_OP_TCR_GR, 5'd7, 64'h3939_3939_3939_3939,
              1'b0, `NPU_ERR_NONE);
    desc_write(6'd39, 3'd1, 64'h3939_0000_0000_0001,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd39, 3'd2, 64'h3939_0000_0000_0002,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd39, 3'd3, 64'h3939_0000_0000_0003,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd39, 3'd4, 64'h3939_0000_0000_0004,
               1'b0, `NPU_ERR_NONE);
    expect_read0(6'd39, 5'b11111,
                 {64'h3939_0000_0000_0004, 64'h3939_0000_0000_0003,
                  64'h3939_0000_0000_0002, 64'h3939_0000_0000_0001,
                  64'h3939_3939_3939_3939});
    cfg_write(`NPU_OP_TCR_GR, 5'd8, 64'hffff, 1'b1, `NPU_ERR_DESC_ID);

    // descriptor word mask、ca0 保护与多读端口一致性。
    desc_write(6'd8, 3'd1, 64'haaaa_bbbb_cccc_dddd,
               1'b0, `NPU_ERR_NONE);
    expect_read0(6'd8, 5'b00010,
                 {192'd0, 64'haaaa_bbbb_cccc_dddd, 64'd0});
    cfg_write(`NPU_OP_TCR_TR, 5'd0, 64'h0808_0808_0808_0808,
              1'b0, `NPU_ERR_NONE);
    desc_write(6'd8, 3'd2, 64'h2222_2222_2222_2222,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd8, 3'd3, 64'h3333_3333_3333_3333,
               1'b0, `NPU_ERR_NONE);
    expect_read0(6'd8, 5'b01111,
                 {64'd0, 64'h3333_3333_3333_3333,
                  64'h2222_2222_2222_2222, 64'haaaa_bbbb_cccc_dddd,
                  64'h0808_0808_0808_0808});
    desc_write(6'd0, 3'd0, 64'hffff_ffff_ffff_ffff,
               1'b0, `NPU_ERR_NONE);
    expect_read0(6'd0, 5'b00001, 320'd0);
    desc_write(6'd0, 3'd1, 64'h1, 1'b1, `NPU_ERR_DESC_WORD);
    desc_write(6'd8, 3'd4, 64'h1, 1'b1, `NPU_ERR_DESC_WORD);
    cfg_write(`NPU_OP_TCR_GR, 5'd0, 64'h3232_0000_0000_0000,
              1'b0, `NPU_ERR_NONE);
    desc_write(6'd32, 3'd1, 64'h3232_0000_0000_0001,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd32, 3'd2, 64'h3232_0000_0000_0002,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd32, 3'd3, 64'h3232_0000_0000_0003,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd32, 3'd4, 64'h4444_4444_4444_4444,
               1'b0, `NPU_ERR_NONE);
    desc_write(6'd32, 3'd5, 64'h5, 1'b1, `NPU_ERR_DESC_WORD);
    desc_write(6'd40, 3'd0, 64'h0, 1'b1, `NPU_ERR_DESC_ID);

    read0_id = 6'd1;
    read1_id = 6'd8;
    read2_id = 6'd31;
    read3_id = 6'd32;
    read4_id = 6'd39;
    #1;
    checks = checks + 1;
    if ((read0_desc[63:0] !== 64'h1111_2222_3333_4444) ||
        ((read1_desc & {64'd0, {256{1'b1}}}) !==
         {64'd0, 64'h3333_3333_3333_3333,
          64'h2222_2222_2222_2222, 64'haaaa_bbbb_cccc_dddd,
          64'h0808_0808_0808_0808}) ||
        ((read2_desc & {64'd0, {256{1'b1}}}) !==
         {64'd0, 64'h3131_0000_0000_0003,
          64'h3131_0000_0000_0002, 64'h3131_0000_0000_0001,
          64'h3131_3131_3131_3131}) ||
        (read3_desc !==
         {64'h4444_4444_4444_4444, 64'h3232_0000_0000_0003,
          64'h3232_0000_0000_0002, 64'h3232_0000_0000_0001,
          64'h3232_0000_0000_0000}) ||
        (read4_desc !==
         {64'h3939_0000_0000_0004, 64'h3939_0000_0000_0003,
          64'h3939_0000_0000_0002, 64'h3939_0000_0000_0001,
          64'h3939_3939_3939_3939}) ||
        (read0_words_valid !== 5'b00001) ||
        (read1_words_valid !== 5'b01111) ||
        (read2_words_valid !== 5'b01111) ||
        (read3_words_valid !== 5'b11111) ||
        (read4_words_valid !== 5'b11111))
      $fatal(1, "five-port descriptor read mismatch");

    // sync tag write 优先于同拍 ack，valid/payload 必须保持到后续 ack。
    sync_tag_write_data = 64'h7319_7319_7319_7319;
    sync_tag_write_valid = 1'b1;
    sync_tag_ack = 1'b1;
    @(posedge clk);
    #1;
    sync_tag_write_valid = 1'b0;
    sync_tag_ack = 1'b0;
    if ((sync_tag_valid !== 1'b1) ||
        (sync_tag !== 64'h7319_7319_7319_7319))
      $fatal(1, "sync tag write/ack priority mismatch");
    repeat (2) @(posedge clk);
    #1;
    if ((sync_tag_valid !== 1'b1) ||
        (sync_tag !== 64'h7319_7319_7319_7319))
      $fatal(1, "sync tag did not hold");
    sync_tag_ack = 1'b1;
    @(posedge clk);
    #1;
    sync_tag_ack = 1'b0;
    if ((sync_tag_valid !== 1'b0) || (sync_tag !== 64'd0))
      $fatal(1, "sync tag ack did not clear");

    $display("[NPU-DECODER-REGFILE][PASS] checks=%0d", checks);
    $finish;
  end

endmodule
