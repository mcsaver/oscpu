`include "define.v"

// Pure combinational decode of a two-word fetch response into two front-end
// instruction slots. Policy decisions stay in OooCoreTopGlue.
module OooFetchPacketDecode (
  input [`XLEN-1:0] rsp_pc_i,
  input [`INST_W-1:0] rsp_inst0_i,
  input [1:0] rsp_resp0_i,
  input [`INST_W-1:0] rsp_inst1_i,
  input [1:0] rsp_resp1_i,

  output [`XLEN-1:0] dec0_pc_o,
  output [`XLEN-1:0] dec0_next_pc_o,
  output [`INST_W-1:0] dec0_inst_o,
  output [1:0] dec0_resp_o,
  output dec0_control_stop_o,

  output [`XLEN-1:0] dec1_pc_o,
  output [`XLEN-1:0] dec1_next_pc_o,
  output [`INST_W-1:0] dec1_inst_o,
  output [1:0] dec1_resp_o,
  output dec1_control_stop_o,

  output [`XLEN-1:0] packet_next_pc_o
);

  wire [15:0] half0_w = rsp_inst0_i[15:0];
  wire [15:0] half1_w = rsp_inst0_i[31:16];
  wire [15:0] half2_w = rsp_inst1_i[15:0];

  wire dec0_compressed_w = (half0_w[1:0] != 2'b11);
  wire [`XLEN-1:0] dec0_len_w = dec0_compressed_w ? 32'd2 : 32'd4;
  wire [15:0] dec1_half_w = dec0_compressed_w ? half1_w : half2_w;
  wire dec1_compressed_w = (dec1_half_w[1:0] != 2'b11);
  wire [`XLEN-1:0] dec1_len_w = dec1_compressed_w ? 32'd2 : 32'd4;

  wire [`INST_W-1:0] dec0_rvc_inst_w;
  wire [`INST_W-1:0] dec1_rvc_inst_w;
  wire [`INST_W-1:0] dec1_raw32_w =
      dec0_compressed_w ? {half2_w, half1_w} : rsp_inst1_i;
  wire dec1_needs_word1_w = !dec0_compressed_w || !dec1_compressed_w;

  OooRvcDecompressor u_dec0_rvc_decompressor (
    .inst_i(half0_w),
    .inst_o(dec0_rvc_inst_w)
  );

  OooRvcDecompressor u_dec1_rvc_decompressor (
    .inst_i(dec1_half_w),
    .inst_o(dec1_rvc_inst_w)
  );

  assign dec0_pc_o = rsp_pc_i;
  assign dec0_next_pc_o = rsp_pc_i + dec0_len_w;
  assign dec0_inst_o = dec0_compressed_w ? dec0_rvc_inst_w : rsp_inst0_i;
  assign dec0_resp_o = rsp_resp0_i;
  assign dec0_control_stop_o =
      (dec0_resp_o != 2'b00) ||
      (dec0_inst_o[6:0] == `OPCODE_BRANCH) ||
      (dec0_inst_o[6:0] == `OPCODE_JAL) ||
      (dec0_inst_o[6:0] == `OPCODE_JALR) ||
      (dec0_inst_o[6:0] == `OPCODE_SYSTEM);

  assign dec1_pc_o = dec0_next_pc_o;
  assign dec1_next_pc_o = dec1_pc_o + dec1_len_w;
  assign dec1_inst_o = dec1_compressed_w ? dec1_rvc_inst_w : dec1_raw32_w;
  assign dec1_resp_o = dec1_needs_word1_w ? rsp_resp1_i : rsp_resp0_i;
  assign dec1_control_stop_o =
      (dec1_resp_o != 2'b00) ||
      (dec1_inst_o[6:0] == `OPCODE_BRANCH) ||
      (dec1_inst_o[6:0] == `OPCODE_JAL) ||
      (dec1_inst_o[6:0] == `OPCODE_JALR) ||
      (dec1_inst_o[6:0] == `OPCODE_SYSTEM);

  assign packet_next_pc_o = dec1_next_pc_o;

endmodule
