`include "define.v"

// FP short-arithmetic production wrapper。
// 数值 stage Q 由五个 child 独占；本模块只保留 legacy start/done、S1-S5
// ProducerId/pdest/double/kind/valid、ROB-age kill、AddSub/Mul S4-S5 原子对齐与末级 mux。
module OooFpArithGate #(
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W
) (
  input              clk,
  input              rst,
  input              flush_i,
  input              start_i,
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input  [`XLEN-1:0] frs3_value_i,
  input              double_i,
  input              sub_op_i,
  input              negate_product_i,
  input              subtract_addend_i,
  input  [2:0]       rm_i,
  output [`XLEN-1:0] addsub_value_o,
  output [4:0]       addsub_fflags_o,
  output [`XLEN-1:0] mul_value_o,
  output [4:0]       mul_fflags_o,
  output [`XLEN-1:0] fma_value_o,
  output [4:0]       fma_fflags_o,
  output             done_o,

  input              launch_valid_i,
  input  [PRODUCER_ID_W-1:0] launch_producer_id_i,
  input  [PHY_REG_ADDR_W-1:0] launch_pdest_i,
  input  [1:0]       launch_kind_i,
  input              kill_valid_i,
  input  [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input  [ROB_INDEX_W-1:0] rob_head_idx_i,
  output             out_valid_o,
  output [PRODUCER_ID_W-1:0] out_producer_id_o,
  output [ROB_INDEX_W-1:0] out_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] out_pdest_o,
  output [`XLEN-1:0] out_value_o,
  output [4:0]       out_fflags_o,
  output [4:0] owner_valid_o,
  output [5*PRODUCER_ID_W-1:0] owner_producer_id_o
);

  localparam integer FP_ARITH_LATENCY = 5;

  // -------------------------------------------------------------------------
  // Production numeric children。所有 child 每拍无条件推进；valid/kill 仅在 wrapper。
  // -------------------------------------------------------------------------
  wire [63:0] addsub_d_value_w, addsub_s_value_w;
  wire [4:0] addsub_d_fflags_w, addsub_s_fflags_w;
  OooFpAddSubPipe u_addsub_pipe (
    .clk(clk), .rst(rst), .flush_i(flush_i),
    .frs1_value_i(frs1_value_i), .frs2_value_i(frs2_value_i),
    .sub_op_i(sub_op_i), .rm_i(rm_i),
    .addsub_d_value_q_o(addsub_d_value_w),
    .addsub_d_fflags_q_o(addsub_d_fflags_w),
    .addsub_s_value_q_o(addsub_s_value_w),
    .addsub_s_fflags_q_o(addsub_s_fflags_w)
  );

  wire mul_d_special_w;
  wire [63:0] mul_d_spval_w;
  wire [4:0] mul_d_spff_w;
  wire [105:0] mul_d_product_w;
  wire signed [13:0] mul_d_expz_w;
  wire mul_d_signz_w;
  wire [2:0] mul_d_rm_w;
  wire mul_s_special_w;
  wire [63:0] mul_s_spval_w;
  wire [4:0] mul_s_spff_w;
  wire [47:0] mul_s_product_w;
  wire signed [13:0] mul_s_expz_w;
  wire mul_s_signz_w;
  wire [2:0] mul_s_rm_w;
  OooFpMulProductPipe u_mul_product_pipe (
    .clk(clk), .rst(rst), .flush_i(flush_i),
    .frs1_value_i(frs1_value_i), .frs2_value_i(frs2_value_i), .rm_i(rm_i),
    .mul_d_special_q_o(mul_d_special_w), .mul_d_spval_q_o(mul_d_spval_w),
    .mul_d_spff_q_o(mul_d_spff_w), .mul_d_product_q_o(mul_d_product_w),
    .mul_d_expz_q_o(mul_d_expz_w), .mul_d_signz_q_o(mul_d_signz_w),
    .mul_d_rm_q_o(mul_d_rm_w),
    .mul_s_special_q_o(mul_s_special_w), .mul_s_spval_q_o(mul_s_spval_w),
    .mul_s_spff_q_o(mul_s_spff_w), .mul_s_product_q_o(mul_s_product_w),
    .mul_s_expz_q_o(mul_s_expz_w), .mul_s_signz_q_o(mul_s_signz_w),
    .mul_s_rm_q_o(mul_s_rm_w)
  );

  wire [63:0] mul_d_value_w, mul_s_value_w;
  wire [4:0] mul_d_fflags_w, mul_s_fflags_w;
  OooFpMulNormRoundPipe u_mul_norm_round_pipe (
    .clk(clk), .rst(rst), .flush_i(flush_i),
    // S1 Q 直接进入 S2 combinational；此 module 边界没有额外寄存级。
    .mul_d_special_q_i(mul_d_special_w), .mul_d_spval_q_i(mul_d_spval_w),
    .mul_d_spff_q_i(mul_d_spff_w), .mul_d_product_q_i(mul_d_product_w),
    .mul_d_expz_q_i(mul_d_expz_w), .mul_d_signz_q_i(mul_d_signz_w),
    .mul_d_rm_q_i(mul_d_rm_w),
    .mul_s_special_q_i(mul_s_special_w), .mul_s_spval_q_i(mul_s_spval_w),
    .mul_s_spff_q_i(mul_s_spff_w), .mul_s_product_q_i(mul_s_product_w),
    .mul_s_expz_q_i(mul_s_expz_w), .mul_s_signz_q_i(mul_s_signz_w),
    .mul_s_rm_q_i(mul_s_rm_w),
    .mul_d_value_q_o(mul_d_value_w), .mul_d_fflags_q_o(mul_d_fflags_w),
    .mul_s_value_q_o(mul_s_value_w), .mul_s_fflags_q_o(mul_s_fflags_w)
  );

  wire fma_d_special_w;
  wire [63:0] fma_d_spval_w;
  wire [4:0] fma_d_spff_w;
  wire [127:0] fma_d_mag_w;
  wire fma_d_ressign_w;
  wire signed [31:0] fma_d_refw_w;
  wire [2:0] fma_d_rm_w;
  wire fma_s_special_w;
  wire [63:0] fma_s_spval_w;
  wire [4:0] fma_s_spff_w;
  wire [127:0] fma_s_mag_w;
  wire fma_s_ressign_w;
  wire signed [31:0] fma_s_refw_w;
  wire [2:0] fma_s_rm_w;
  OooFpFmaAlignAddPipe u_fma_align_add_pipe (
    .clk(clk), .rst(rst), .flush_i(flush_i),
    .frs1_value_i(frs1_value_i), .frs2_value_i(frs2_value_i),
    .frs3_value_i(frs3_value_i), .negate_product_i(negate_product_i),
    .subtract_addend_i(subtract_addend_i), .rm_i(rm_i),
    .fma_d_special_q_o(fma_d_special_w), .fma_d_spval_q_o(fma_d_spval_w),
    .fma_d_spff_q_o(fma_d_spff_w), .fma_d_mag_q_o(fma_d_mag_w),
    .fma_d_ressign_q_o(fma_d_ressign_w), .fma_d_refw_q_o(fma_d_refw_w),
    .fma_d_rm_q_o(fma_d_rm_w),
    .fma_s_special_q_o(fma_s_special_w), .fma_s_spval_q_o(fma_s_spval_w),
    .fma_s_spff_q_o(fma_s_spff_w), .fma_s_mag_q_o(fma_s_mag_w),
    .fma_s_ressign_q_o(fma_s_ressign_w), .fma_s_refw_q_o(fma_s_refw_w),
    .fma_s_rm_q_o(fma_s_rm_w)
  );

  wire [63:0] fma_d_value_w, fma_s_value_w;
  wire [4:0] fma_d_fflags_w, fma_s_fflags_w;
  OooFpFmaNormRoundPipe u_fma_norm_round_pipe (
    .clk(clk), .rst(rst), .flush_i(flush_i),
    // S3 full mag/ref/sign/rm/special Q 直接进入 S4 combinational；mag[0] 是 jam。
    .fma_d_special_q_i(fma_d_special_w), .fma_d_spval_q_i(fma_d_spval_w),
    .fma_d_spff_q_i(fma_d_spff_w), .fma_d_mag_q_i(fma_d_mag_w),
    .fma_d_ressign_q_i(fma_d_ressign_w), .fma_d_refw_q_i(fma_d_refw_w),
    .fma_d_rm_q_i(fma_d_rm_w),
    .fma_s_special_q_i(fma_s_special_w), .fma_s_spval_q_i(fma_s_spval_w),
    .fma_s_spff_q_i(fma_s_spff_w), .fma_s_mag_q_i(fma_s_mag_w),
    .fma_s_ressign_q_i(fma_s_ressign_w), .fma_s_refw_q_i(fma_s_refw_w),
    .fma_s_rm_q_i(fma_s_rm_w),
    .fma_d_value_q_o(fma_d_value_w), .fma_d_fflags_q_o(fma_d_fflags_w),
    .fma_s_value_q_o(fma_s_value_w), .fma_s_fflags_q_o(fma_s_fflags_w)
  );

  // 旧 pending 接口：父级保持 double_i/操作数到 done，故 current double mux 保持原契约。
  assign addsub_value_o = double_i ? addsub_d_value_w : addsub_s_value_w;
  assign addsub_fflags_o = double_i ? addsub_d_fflags_w : addsub_s_fflags_w;
  assign mul_value_o = double_i ? mul_d_value_w : mul_s_value_w;
  assign mul_fflags_o = double_i ? mul_d_fflags_w : mul_s_fflags_w;
  assign fma_value_o = double_i ? fma_d_value_w : fma_s_value_w;
  assign fma_fflags_o = double_i ? fma_d_fflags_w : fma_s_fflags_w;

  reg [3:0] latency_cnt;
  always @(posedge clk) begin
    if (rst || flush_i || !start_i) latency_cnt <= 4'd0;
    else if (latency_cnt < FP_ARITH_LATENCY[3:0])
      latency_cnt <= latency_cnt + 4'd1;
  end
  assign done_o = start_i && (latency_cnt == FP_ARITH_LATENCY[3:0]);

  // -------------------------------------------------------------------------
  // S1-S5 transaction owner chain：唯一 valid/PID/pdest/double/kind/kill owner。
  // -------------------------------------------------------------------------
  reg meta_valid_q [1:5];
  reg [PRODUCER_ID_W-1:0] meta_producer_id_q [1:5];
  reg [PHY_REG_ADDR_W-1:0] meta_pdest_q [1:5];
  reg meta_double_q [1:5];
  reg [1:0] meta_kind_q [1:5];

  function fp_meta_younger;
    input [ROB_INDEX_W-1:0] idx;
    input [ROB_INDEX_W-1:0] boundary_idx;
    input [ROB_INDEX_W-1:0] head_idx;
    begin
      fp_meta_younger = (idx - head_idx) > (boundary_idx - head_idx);
    end
  endfunction

  // S3 child outputs become wrapper S4/S5 alignment Q as an atomic 69-bit pair。
  reg [68:0] addsub_s4_result_q, addsub_s5_result_q;
  reg [68:0] mul_s4_result_q, mul_s5_result_q;

  integer mi;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (mi = 1; mi <= 5; mi = mi + 1) begin
        meta_valid_q[mi] <= 1'b0;
        meta_producer_id_q[mi] <= {PRODUCER_ID_W{1'b0}};
        meta_pdest_q[mi] <= {PHY_REG_ADDR_W{1'b0}};
        meta_double_q[mi] <= 1'b0;
        meta_kind_q[mi] <= 2'b00;
      end
      addsub_s4_result_q <= 69'b0;
      addsub_s5_result_q <= 69'b0;
      mul_s4_result_q <= 69'b0;
      mul_s5_result_q <= 69'b0;
    end else begin
      meta_valid_q[1] <= launch_valid_i &&
          !(kill_valid_i && fp_meta_younger(
              launch_producer_id_i[ROB_INDEX_W-1:0],
              kill_rob_idx_i, rob_head_idx_i));
      meta_producer_id_q[1] <= launch_producer_id_i;
      meta_pdest_q[1] <= launch_pdest_i;
      meta_double_q[1] <= double_i;
      meta_kind_q[1] <= launch_kind_i;
      for (mi = 2; mi <= 5; mi = mi + 1) begin
        meta_valid_q[mi] <= meta_valid_q[mi-1] &&
            !(kill_valid_i && fp_meta_younger(
                meta_producer_id_q[mi-1][ROB_INDEX_W-1:0],
                kill_rob_idx_i, rob_head_idx_i));
        meta_producer_id_q[mi] <= meta_producer_id_q[mi-1];
        meta_pdest_q[mi] <= meta_pdest_q[mi-1];
        meta_double_q[mi] <= meta_double_q[mi-1];
        meta_kind_q[mi] <= meta_kind_q[mi-1];
      end
      addsub_s4_result_q <= meta_double_q[3] ?
          {addsub_d_fflags_w, addsub_d_value_w} :
          {addsub_s_fflags_w, addsub_s_value_w};
      addsub_s5_result_q <= addsub_s4_result_q;
      mul_s4_result_q <= meta_double_q[3] ?
          {mul_d_fflags_w, mul_d_value_w} :
          {mul_s_fflags_w, mul_s_value_w};
      mul_s5_result_q <= mul_s4_result_q;
    end
  end

  assign out_valid_o = meta_valid_q[5] &&
      !(kill_valid_i && fp_meta_younger(
          meta_producer_id_q[5][ROB_INDEX_W-1:0],
          kill_rob_idx_i, rob_head_idx_i));
  assign out_producer_id_o = meta_producer_id_q[5];
  assign out_rob_idx_o = out_producer_id_o[ROB_INDEX_W-1:0];
  assign out_pdest_o = meta_pdest_q[5];

  wire [68:0] fma_s5_result_w;
  wire [68:0] selected_s5_result_w;
  assign fma_s5_result_w = meta_double_q[5] ?
      {fma_d_fflags_w, fma_d_value_w} :
      {fma_s_fflags_w, fma_s_value_w};
  assign selected_s5_result_w =
      (meta_kind_q[5] == 2'd2) ? fma_s5_result_w :
      (meta_kind_q[5] == 2'd1) ? mul_s5_result_q :
                                 addsub_s5_result_q;
  assign out_value_o = selected_s5_result_w[63:0];
  assign out_fflags_o = selected_s5_result_w[68:64];

  genvar owner_stage;
  generate
    for (owner_stage = 1; owner_stage <= 5;
         owner_stage = owner_stage + 1) begin : owner_view_gen
      assign owner_valid_o[owner_stage-1] = meta_valid_q[owner_stage];
      assign owner_producer_id_o[
          (owner_stage-1)*PRODUCER_ID_W +: PRODUCER_ID_W] =
          meta_producer_id_q[owner_stage];
    end
  endgenerate

`ifdef OOO_ASSERT
  always @(posedge clk) begin : fp_arith_contract_assert_blk
    integer ai;
    integer aj;
    if (!rst && !flush_i && launch_valid_i && (launch_kind_i == 2'd3))
      $error("[FP-ARITH-CONTRACT] illegal launch_kind_i=3");
    if (!rst && meta_valid_q[5] && (meta_kind_q[5] == 2'd3))
      $error("[FP-ARITH-S5-KIND] resident stage5 kind is illegal");
    if (!rst) begin
      if (out_valid_o &&
          (out_rob_idx_o !== out_producer_id_o[ROB_INDEX_W-1:0])) begin
        $error("[V8I-FP-ARITH-PID-PROJECTION] output raw index diverged from PID");
        $fatal;
      end
      for (ai = 1; ai <= 5; ai = ai + 1) begin
        if (meta_valid_q[ai] && (^meta_producer_id_q[ai] === 1'bx)) begin
          $error("[V8L-FP-ARITH-LEASE-KNOWN] valid metadata stage has unknown PID");
          $fatal;
        end
        for (aj = ai + 1; aj <= 5; aj = aj + 1) begin
          if (meta_valid_q[ai] && meta_valid_q[aj] &&
              (meta_producer_id_q[ai] == meta_producer_id_q[aj])) begin
            $error("[V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline");
            $fatal;
          end
        end
      end
    end
  end
`endif

endmodule
