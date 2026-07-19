// R3.3 整数 IQ 的固定 8 项平衡选择器。
//
// 结构目的：把旧的 loop-carried oldest-first scan 改成三层并行前缀网络；不增加
// pipeline stage，也不改变 Universal/ALU terminal 的动态 capability steering。
// 本模块纯组合、无状态，request index 越小代表越老。
module OooIntIssueSelect8 (
  input [7:0] valid_i,
  input [7:0] base_ready_i,
  input [7:0] memory_i,
  input [7:0] alu_capable_i,
  input universal_owner_present_i,

  output [7:0] eligible_o,
  output issue0_found_o,
  output [2:0] issue0_idx_o,
  output [7:0] issue0_onehot_o,
  output issue1_found_o,
  output [2:0] issue1_idx_o,
  output [7:0] issue1_onehot_o,
  output issue_pair_swapped_o
);

  wire [7:0] eligible_w;

  // packed age-order 下，只有队首 memory 可单独占 Universal；索引 1 的 memory
  // 只允许与唯一 older-ready ALU 原子配对。即使非法 hole 态令 valid[0]=0，也不
  // 放宽该门（fail closed，由上层 packed assertion 同时报告）。索引 2..7 必须等待
  // 压缩到前两项。
  assign eligible_w[0] = base_ready_i[0];
  assign eligible_w[1] = base_ready_i[1] &&
      (!memory_i[1] ||
       (!universal_owner_present_i && valid_i[0] && base_ready_i[0] &&
        alu_capable_i[0]));
  assign eligible_w[2] = base_ready_i[2] && !memory_i[2];
  assign eligible_w[3] = base_ready_i[3] && !memory_i[3];
  assign eligible_w[4] = base_ready_i[4] && !memory_i[4];
  assign eligible_w[5] = base_ready_i[5] && !memory_i[5];
  assign eligible_w[6] = base_ready_i[6] && !memory_i[6];
  assign eligible_w[7] = base_ready_i[7] && !memory_i[7];
  assign eligible_o = eligible_w;

  // (any,multi) 是“该区间含至少 1/2 个 request”的饱和计数摘要；combine
  // 为关联运算，因此按距离 1/2/4 的三层并行前缀展开。三个 generate loop
  // 分别综合成 8 组并行小门，不形成 loop-carried 串行 scan。
  wire [7:0] req_s0_any_w = eligible_w;
  wire [7:0] req_s0_multi_w = 8'b0;
  wire [7:0] req_s1_any_w;
  wire [7:0] req_s1_multi_w;
  wire [7:0] req_s2_any_w;
  wire [7:0] req_s2_multi_w;
  wire [7:0] req_s3_any_w;
  wire [7:0] req_s3_multi_w;

  genvar req_g1;
  generate
    for (req_g1 = 0; req_g1 < 8; req_g1 = req_g1 + 1) begin : gen_req_prefix_d1
      if (req_g1 < 1) begin : gen_passthrough
        assign req_s1_any_w[req_g1] = req_s0_any_w[req_g1];
        assign req_s1_multi_w[req_g1] = req_s0_multi_w[req_g1];
      end else begin : gen_combine
        assign req_s1_any_w[req_g1] =
            req_s0_any_w[req_g1] | req_s0_any_w[req_g1-1];
        assign req_s1_multi_w[req_g1] =
            req_s0_multi_w[req_g1] | req_s0_multi_w[req_g1-1] |
            (req_s0_any_w[req_g1] & req_s0_any_w[req_g1-1]);
      end
    end
  endgenerate

  genvar req_g2;
  generate
    for (req_g2 = 0; req_g2 < 8; req_g2 = req_g2 + 1) begin : gen_req_prefix_d2
      if (req_g2 < 2) begin : gen_passthrough
        assign req_s2_any_w[req_g2] = req_s1_any_w[req_g2];
        assign req_s2_multi_w[req_g2] = req_s1_multi_w[req_g2];
      end else begin : gen_combine
        assign req_s2_any_w[req_g2] =
            req_s1_any_w[req_g2] | req_s1_any_w[req_g2-2];
        assign req_s2_multi_w[req_g2] =
            req_s1_multi_w[req_g2] | req_s1_multi_w[req_g2-2] |
            (req_s1_any_w[req_g2] & req_s1_any_w[req_g2-2]);
      end
    end
  endgenerate

  genvar req_g4;
  generate
    for (req_g4 = 0; req_g4 < 8; req_g4 = req_g4 + 1) begin : gen_req_prefix_d4
      if (req_g4 < 4) begin : gen_passthrough
        assign req_s3_any_w[req_g4] = req_s2_any_w[req_g4];
        assign req_s3_multi_w[req_g4] = req_s2_multi_w[req_g4];
      end else begin : gen_combine
        assign req_s3_any_w[req_g4] =
            req_s2_any_w[req_g4] | req_s2_any_w[req_g4-4];
        assign req_s3_multi_w[req_g4] =
            req_s2_multi_w[req_g4] | req_s2_multi_w[req_g4-4] |
            (req_s2_any_w[req_g4] & req_s2_any_w[req_g4-4]);
      end
    end
  endgenerate

  wire [7:0] prior_any_w = {req_s3_any_w[6:0], 1'b0};
  wire [7:0] prior_multi_w = {req_s3_multi_w[6:0], 1'b0};
  wire [7:0] first_req_onehot_w = eligible_w & ~prior_any_w;
  wire [7:0] second_req_onehot_w =
      eligible_w & prior_any_w & ~prior_multi_w;

  // 独立 ALU capability 前缀树。它只求最老 eligible ALU，不重做 wide ctrl decode。
  wire [7:0] alu_req_w = eligible_w & alu_capable_i;
  wire [7:0] alu_s1_any_w;
  wire [7:0] alu_s2_any_w;
  wire [7:0] alu_s3_any_w;

  genvar alu_g1;
  generate
    for (alu_g1 = 0; alu_g1 < 8; alu_g1 = alu_g1 + 1) begin : gen_alu_prefix_d1
      if (alu_g1 < 1) begin : gen_passthrough
        assign alu_s1_any_w[alu_g1] = alu_req_w[alu_g1];
      end else begin : gen_combine
        assign alu_s1_any_w[alu_g1] =
            alu_req_w[alu_g1] | alu_req_w[alu_g1-1];
      end
    end
  endgenerate

  genvar alu_g2;
  generate
    for (alu_g2 = 0; alu_g2 < 8; alu_g2 = alu_g2 + 1) begin : gen_alu_prefix_d2
      if (alu_g2 < 2) begin : gen_passthrough
        assign alu_s2_any_w[alu_g2] = alu_s1_any_w[alu_g2];
      end else begin : gen_combine
        assign alu_s2_any_w[alu_g2] =
            alu_s1_any_w[alu_g2] | alu_s1_any_w[alu_g2-2];
      end
    end
  endgenerate

  genvar alu_g4;
  generate
    for (alu_g4 = 0; alu_g4 < 8; alu_g4 = alu_g4 + 1) begin : gen_alu_prefix_d4
      if (alu_g4 < 4) begin : gen_passthrough
        assign alu_s3_any_w[alu_g4] = alu_s2_any_w[alu_g4];
      end else begin : gen_combine
        assign alu_s3_any_w[alu_g4] =
            alu_s2_any_w[alu_g4] | alu_s2_any_w[alu_g4-4];
      end
    end
  endgenerate

  wire [7:0] prior_alu_any_w = {alu_s3_any_w[6:0], 1'b0};
  wire [7:0] first_alu_onehot_w = alu_req_w & ~prior_alu_any_w;

  wire first_req_valid_w = |first_req_onehot_w;
  wire second_req_valid_w = |second_req_onehot_w;
  wire first_alu_valid_w = |first_alu_onehot_w;
  wire first_req_is_alu_w = |(first_req_onehot_w & alu_capable_i);
  wire [7:0] partner_onehot_w =
      first_req_is_alu_w ? second_req_onehot_w : first_alu_onehot_w;
  wire partner_valid_w = first_req_is_alu_w ?
      second_req_valid_w : first_alu_valid_w;
  wire partner_is_alu_w = |(partner_onehot_w & alu_capable_i);
  wire swap_w = !universal_owner_present_i && first_req_valid_w &&
      first_req_is_alu_w && partner_valid_w && !partner_is_alu_w;

  wire [7:0] issue0_onehot_w = universal_owner_present_i ? 8'b0 :
      (swap_w ? partner_onehot_w : first_req_onehot_w);
  wire [7:0] issue1_onehot_w = universal_owner_present_i ?
      first_alu_onehot_w :
      (swap_w ? first_req_onehot_w : partner_onehot_w);

  // onehot→index 仅是三组平衡 OR；payload array mux 继续复用 IQ 既有实现。
  assign issue0_idx_o[2] = |issue0_onehot_w[7:4];
  assign issue0_idx_o[1] = |(issue0_onehot_w & 8'b1100_1100);
  assign issue0_idx_o[0] = |(issue0_onehot_w & 8'b1010_1010);
  assign issue1_idx_o[2] = |issue1_onehot_w[7:4];
  assign issue1_idx_o[1] = |(issue1_onehot_w & 8'b1100_1100);
  assign issue1_idx_o[0] = |(issue1_onehot_w & 8'b1010_1010);

  assign issue0_found_o = universal_owner_present_i || first_req_valid_w;
  assign issue1_found_o = universal_owner_present_i ?
      first_alu_valid_w : partner_valid_w;
  assign issue0_onehot_o = issue0_onehot_w;
  assign issue1_onehot_o = issue1_onehot_w;
  assign issue_pair_swapped_o = swap_w;

endmodule
