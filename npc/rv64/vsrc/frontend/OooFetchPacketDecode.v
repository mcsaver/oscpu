`include "define.v"

// Pure combinational decode of a two-word fetch response into two front-end
// instruction slots. Policy decisions stay in OooCoreTopGlue.
module OooFetchPacketDecode (
  input [`XLEN-1:0] rsp_pc_i,
  input [`INST_W-1:0] rsp_inst0_i,
  input [1:0] rsp_resp0_i,
  input [`INST_W-1:0] rsp_inst1_i,
  input [1:0] rsp_resp1_i,
  // rsp_resp0_i 覆盖 packet 低地址起的连续字节数；其后由 rsp_resp1_i 覆盖。
  // 普通包为 4，跨页包为第一页实际剩余字节数。
  input [2:0] rsp_resp0_bytes_i,

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

  // 【B2 S1】per-slot 分支识别 + B-imm 提取(解压后 inst 上判定, RVC 分支已展开为
  // 32b B-type)。bimm 供 resp 拍 BPU lookup 的静态兜底(imm 符号位); 非分支 slot
  // gate 为 0(=静态 not-taken 安全值, 消费端本就有 branch 谓词门, don't-care)。
  output dec0_branch_o,
  output [12:0] dec0_bimm_o,
  output dec1_branch_o,
  output [12:0] dec1_bimm_o,

  output [`XLEN-1:0] packet_next_pc_o,
  output [`XLEN-1:0] packet_raw_next_pc_o,
  // 首个失败 fetch portion 的精确地址；下游以同一 packet owner 同时保存。
  output [`XLEN-1:0] fault_tval_o
);

  localparam [1:0] RESP_OK = 2'b00;

  // 按字节区间 [start,start+size) 合并两个 segment response。若区间跨 split，
  // first segment fault 优先；否则选择实际覆盖该区间的 segment。
  function [1:0] byte_range_resp;
    input [3:0] start_byte;
    input [3:0] size_bytes;
    input [2:0] resp0_bytes;
    input [1:0] resp0;
    input [1:0] resp1;
    reg [4:0] end_byte;
    begin
      end_byte = {1'b0, start_byte} + {1'b0, size_bytes};
      if ((start_byte < {1'b0, resp0_bytes}) && (resp0 != RESP_OK)) begin
        byte_range_resp = resp0;
      end else if (end_byte > {2'b00, resp0_bytes}) begin
        byte_range_resp = resp1;
      end else begin
        byte_range_resp = resp0;
      end
    end
  endfunction

  wire [15:0] half0_w = rsp_inst0_i[15:0];
  wire [15:0] half1_w = rsp_inst0_i[31:16];
  wire [15:0] half2_w = rsp_inst1_i[15:0];
  // R2.3 timing hint: raw packet successor is payload only. It deliberately
  // ignores response provenance; a miss/fault has no successor-consume token.
  wire raw_dec0_compressed_w = (half0_w[1:0] != 2'b11);
  wire [15:0] raw_dec1_half_w =
      raw_dec0_compressed_w ? half1_w : half2_w;
  wire raw_dec1_compressed_w = (raw_dec1_half_w[1:0] != 2'b11);
  wire [3:0] raw_packet_bytes_w =
      raw_dec0_compressed_w ?
      (raw_dec1_compressed_w ? 4'd4 : 4'd6) :
      (raw_dec1_compressed_w ? 4'd6 : 4'd8);

  // 长度只能在 prefix 所需 segment 全部 OK 后读取。若 prefix 自身 fault，使用安全 C.NOP
  // 形状提供确定性 next_pc/inst；fault response 仍在下方胜出，禁止无效 tail bits 吞 fault。
  wire [1:0] dec0_prefix_resp_w =
      byte_range_resp(4'd0, 4'd2, rsp_resp0_bytes_i,
                      rsp_resp0_i, rsp_resp1_i);
  wire dec0_prefix_valid_w = (dec0_prefix_resp_w == RESP_OK);
  wire [15:0] dec0_half_w = dec0_prefix_valid_w ? half0_w : 16'h0001;
  wire dec0_compressed_w = (dec0_half_w[1:0] != 2'b11);
  wire [3:0] dec0_len_bytes_w = dec0_compressed_w ? 4'd2 : 4'd4;
  wire [`XLEN-1:0] dec0_len_w = dec0_compressed_w ? 64'd2 : 64'd4;
  wire [1:0] dec0_range_resp_w =
      byte_range_resp(4'd0, dec0_len_bytes_w, rsp_resp0_bytes_i,
                      rsp_resp0_i, rsp_resp1_i);

  wire [3:0] dec1_start_byte_w = dec0_len_bytes_w;
  wire [15:0] dec1_packet_half_w = dec0_compressed_w ? half1_w : half2_w;
  wire [1:0] dec1_prefix_resp_w =
      byte_range_resp(dec1_start_byte_w, 4'd2, rsp_resp0_bytes_i,
                      rsp_resp0_i, rsp_resp1_i);
  wire dec1_prefix_valid_w = (dec0_range_resp_w == RESP_OK) &&
                             (dec1_prefix_resp_w == RESP_OK);
  wire [15:0] dec1_half_w = dec1_prefix_valid_w ?
                            dec1_packet_half_w : 16'h0001;
  wire dec1_compressed_w = (dec1_half_w[1:0] != 2'b11);
  wire [3:0] dec1_len_bytes_w = dec1_compressed_w ? 4'd2 : 4'd4;
  wire [`XLEN-1:0] dec1_len_w = dec1_compressed_w ? 64'd2 : 64'd4;
  wire [1:0] dec1_range_resp_w =
      byte_range_resp(dec1_start_byte_w, dec1_len_bytes_w,
                      rsp_resp0_bytes_i, rsp_resp0_i, rsp_resp1_i);
  wire [1:0] dec1_effective_resp_w =
      (dec0_range_resp_w != RESP_OK) ? dec0_range_resp_w : dec1_range_resp_w;

  wire [`INST_W-1:0] dec0_rvc_inst_w;
  wire [`INST_W-1:0] dec1_rvc_inst_w;
  wire [`INST_W-1:0] dec1_raw32_w =
      dec0_compressed_w ? {half2_w, half1_w} : rsp_inst1_i;

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
  // 完整指令区间 fault 时也必须净化 inst：prefix 可能位于成功 segment，而 32b tail
  // 来自 fault segment。若保留 tail 垃圾，仍会被下游 semihost peer 比较等旁路消费。
  assign dec0_inst_o = (dec0_range_resp_w != RESP_OK) ? 32'h0000_0013 :
                       dec0_compressed_w ? dec0_rvc_inst_w : rsp_inst0_i;
  assign dec0_resp_o = dec0_range_resp_w;
  assign dec0_control_stop_o =
      (dec0_resp_o != 2'b00) ||
      (dec0_inst_o[6:0] == `OPCODE_BRANCH) ||
      (dec0_inst_o[6:0] == `OPCODE_JAL) ||
      (dec0_inst_o[6:0] == `OPCODE_JALR) ||
      (dec0_inst_o[6:0] == `OPCODE_SYSTEM);

  assign dec1_pc_o = dec0_next_pc_o;
  assign dec1_next_pc_o = dec1_pc_o + dec1_len_w;
  assign dec1_inst_o = (dec1_effective_resp_w != RESP_OK) ? 32'h0000_0013 :
                       dec1_compressed_w ? dec1_rvc_inst_w : dec1_raw32_w;
  // slot0 fault 后 slot1 没有架构 owner；沿用 slot0 fault 可阻止垃圾 slot1 形成副作用。
  assign dec1_resp_o = dec1_effective_resp_w;
  assign dec1_control_stop_o =
      (dec1_resp_o != 2'b00) ||
      (dec1_inst_o[6:0] == `OPCODE_BRANCH) ||
      (dec1_inst_o[6:0] == `OPCODE_JAL) ||
      (dec1_inst_o[6:0] == `OPCODE_JALR) ||
      (dec1_inst_o[6:0] == `OPCODE_SYSTEM);

  // T3L: B-imm stays in its raw 13-bit form across the module boundary. The
  // predictor consumes bit 12; OooFetchBranchTarget owns RV64 page correction.
  assign dec0_branch_o = (dec0_inst_o[6:0] == `OPCODE_BRANCH);
  assign dec0_bimm_o = dec0_branch_o ?
      {dec0_inst_o[31], dec0_inst_o[7], dec0_inst_o[30:25],
       dec0_inst_o[11:8], 1'b0} : 13'b0;
  assign dec1_branch_o = (dec1_inst_o[6:0] == `OPCODE_BRANCH);
  assign dec1_bimm_o = dec1_branch_o ?
      {dec1_inst_o[31], dec1_inst_o[7], dec1_inst_o[30:25],
       dec1_inst_o[11:8], 1'b0} : 13'b0;

  assign packet_next_pc_o = dec1_next_pc_o;
  assign packet_raw_next_pc_o =
      rsp_pc_i + {{(`XLEN-4){1'b0}}, raw_packet_bytes_w};
  assign fault_tval_o =
      rsp_pc_i + {{(`XLEN-3){1'b0}}, rsp_resp0_bytes_i};

endmodule
