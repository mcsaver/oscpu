`include "define.v"

module OooBranchDirectionPredictor (
  input clk,
  input rst,
  input clear_i,

  input [`XLEN-1:0] lookup0_pc_i,
  input lookup0_static_taken_i,
  output [`BPU_BHT_INDEX_W-1:0] lookup0_bht_idx_o,
  output lookup0_bht_valid_o,
  output lookup0_pred_taken_o,
  output lookup0_predict_strong_o,

  input [`XLEN-1:0] lookup1_pc_i,
  input lookup1_static_taken_i,
  output [`BPU_BHT_INDEX_W-1:0] lookup1_bht_idx_o,
  output lookup1_bht_valid_o,
  output lookup1_pred_taken_o,
  output lookup1_predict_strong_o,

  input update_valid_i,
  input [`XLEN-1:0] update_pc_i,
  input [`BPU_BHT_INDEX_W-1:0] update_bht_idx_i,
  input update_taken_i
);

  reg [`BPU_BHT_ENTRIES-1:0] bht_valid_q;
  reg [1:0] bht_q [0:`BPU_BHT_ENTRIES-1];
  reg [`BPU_BHT_INDEX_W-1:0] ghr_q;
  reg [`BPU_LOCAL_HISTORY_ENTRIES-1:0] local_hist_valid_q;
  reg [`BPU_LOCAL_HISTORY_W-1:0] local_hist_q
      [0:`BPU_LOCAL_HISTORY_ENTRIES-1];

  function bht_counter_taken;
    input valid;
    input [1:0] counter;
    input static_taken;
    begin
      bht_counter_taken = valid ? (counter >= 2'd2) : static_taken;
    end
  endfunction

  function counter_strong;
    input valid;
    input [1:0] counter;
    begin
      counter_strong = valid &&
          ((counter == 2'd0) || (counter == 2'd3));
    end
  endfunction

  function [1:0] counter_train;
    input [1:0] counter;
    input taken;
    begin
      if (taken) begin
        counter_train = (counter == 2'd3) ? 2'd3 : (counter + 2'd1);
      end else begin
        counter_train = (counter == 2'd0) ? 2'd0 : (counter - 2'd1);
      end
    end
  endfunction

  wire [`BPU_BHT_INDEX_W-1:0] lookup0_pc_idx_w =
      lookup0_pc_i[`BPU_BHT_INDEX_W:1];
  wire [`BPU_BHT_INDEX_W-1:0] lookup1_pc_idx_w =
      lookup1_pc_i[`BPU_BHT_INDEX_W:1];
  wire [`BPU_BHT_INDEX_W-1:0] lookup0_bht_idx_w =
      lookup0_pc_idx_w ^ ghr_q;
  wire [`BPU_BHT_INDEX_W-1:0] lookup1_bht_idx_w =
      lookup1_pc_idx_w ^ ghr_q;
  wire lookup0_static_taken_w = lookup0_static_taken_i;
  wire lookup1_static_taken_w = lookup1_static_taken_i;

  assign lookup0_bht_idx_o = lookup0_bht_idx_w;
  assign lookup1_bht_idx_o = lookup1_bht_idx_w;

  assign lookup0_bht_valid_o = bht_valid_q[lookup0_bht_idx_w];
  assign lookup1_bht_valid_o = bht_valid_q[lookup1_bht_idx_w];

  wire [1:0] lookup0_gshare_ctr_w = bht_q[lookup0_bht_idx_w];
  wire [1:0] lookup1_gshare_ctr_w = bht_q[lookup1_bht_idx_w];
  wire lookup0_gshare_taken_w =
      bht_counter_taken(lookup0_bht_valid_o, lookup0_gshare_ctr_w,
                        lookup0_static_taken_w);
  wire lookup1_gshare_taken_w =
      bht_counter_taken(lookup1_bht_valid_o, lookup1_gshare_ctr_w,
                        lookup1_static_taken_w);
  wire lookup0_gshare_strong_w =
      counter_strong(lookup0_bht_valid_o, lookup0_gshare_ctr_w);
  wire lookup1_gshare_strong_w =
      counter_strong(lookup1_bht_valid_o, lookup1_gshare_ctr_w);

  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] lookup0_local_hist_idx_w =
      lookup0_pc_i[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] lookup1_local_hist_idx_w =
      lookup1_pc_i[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire lookup0_local_hist_valid_w =
      local_hist_valid_q[lookup0_local_hist_idx_w];
  wire lookup1_local_hist_valid_w =
      local_hist_valid_q[lookup1_local_hist_idx_w];
  wire [`BPU_LOCAL_HISTORY_W-1:0] lookup0_local_hist_w =
      lookup0_local_hist_valid_w ? local_hist_q[lookup0_local_hist_idx_w] :
                                   {`BPU_LOCAL_HISTORY_W{1'b0}};
  wire [`BPU_LOCAL_HISTORY_W-1:0] lookup1_local_hist_w =
      lookup1_local_hist_valid_w ? local_hist_q[lookup1_local_hist_idx_w] :
                                   {`BPU_LOCAL_HISTORY_W{1'b0}};
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] lookup0_local_pc_idx_w =
      lookup0_pc_i[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] lookup1_local_pc_idx_w =
      lookup1_pc_i[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] lookup0_local_pht_idx_w =
      {lookup0_local_pc_idx_w, lookup0_local_hist_w};
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] lookup1_local_pht_idx_w =
      {lookup1_local_pc_idx_w, lookup1_local_hist_w};
  wire lookup0_local_valid_w;
  wire lookup1_local_valid_w;
  wire [1:0] lookup0_local_ctr_w;
  wire [1:0] lookup1_local_ctr_w;

  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] update_local_hist_idx_w =
      update_pc_i[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire update_local_hist_valid_w =
      local_hist_valid_q[update_local_hist_idx_w];
  wire [`BPU_LOCAL_HISTORY_W-1:0] update_local_hist_w =
      update_local_hist_valid_w ? local_hist_q[update_local_hist_idx_w] :
                                  {`BPU_LOCAL_HISTORY_W{1'b0}};
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] update_local_pc_idx_w =
      update_pc_i[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] update_local_pht_idx_w =
      {update_local_pc_idx_w, update_local_hist_w};

  OooBranchLocalPht u_local_pht (
    .clk(clk),
    .rst(rst),
    .clear_i(clear_i),
    .lookup0_idx_i(lookup0_local_pht_idx_w),
    .lookup0_valid_o(lookup0_local_valid_w),
    .lookup0_ctr_o(lookup0_local_ctr_w),
    .lookup1_idx_i(lookup1_local_pht_idx_w),
    .lookup1_valid_o(lookup1_local_valid_w),
    .lookup1_ctr_o(lookup1_local_ctr_w),
    .update_valid_i(update_valid_i),
    .update_idx_i(update_local_pht_idx_w),
    .update_taken_i(update_taken_i)
  );
  wire lookup0_local_taken_w =
      bht_counter_taken(lookup0_local_valid_w, lookup0_local_ctr_w,
                        lookup0_static_taken_w);
  wire lookup1_local_taken_w =
      bht_counter_taken(lookup1_local_valid_w, lookup1_local_ctr_w,
                        lookup1_static_taken_w);
  wire lookup0_local_strong_w =
      counter_strong(lookup0_local_valid_w, lookup0_local_ctr_w);
  wire lookup1_local_strong_w =
      counter_strong(lookup1_local_valid_w, lookup1_local_ctr_w);

  assign lookup0_pred_taken_o =
      (lookup0_local_valid_w && !lookup0_gshare_strong_w) ?
      lookup0_local_taken_w :
      lookup0_local_strong_w ? lookup0_local_taken_w :
                               lookup0_gshare_taken_w;
  assign lookup1_pred_taken_o =
      (lookup1_local_valid_w && !lookup1_gshare_strong_w) ?
      lookup1_local_taken_w :
      lookup1_local_strong_w ? lookup1_local_taken_w :
                               lookup1_gshare_taken_w;
  assign lookup0_predict_strong_o =
      lookup0_gshare_strong_w || lookup0_local_strong_w;
  assign lookup1_predict_strong_o =
      lookup1_gshare_strong_w || lookup1_local_strong_w;

  wire [1:0] update_bht_counter_w =
      bht_valid_q[update_bht_idx_i] ? bht_q[update_bht_idx_i] :
                                      `BPU_COUNTER_INIT;
  wire unused_predictor_input_bits_w =
      (|lookup0_pc_i) | lookup0_static_taken_i |
      (|lookup1_pc_i) | lookup1_static_taken_i | (|update_pc_i);

  // 【BPU update 两拍流水(2026-07-10 时序债修复)】OOC 实测 update in→reg 57ns
  // local-PHT 的相同 S1→S2/read-before-write 合同由 OooBranchLocalPht 的
  // 16×256 bank-local 流水拥有；parent 只保留 BHT/local-history 的 S1/S2。
  // 语义: 训练晚 1 拍零正确性影响(启发式); back-to-back 同表项 RAW(stage1
  // 读到未含上一条训练的旧值)=丢一次计数器增量, 可容忍。
  // GHR 留 stage1 当拍更新(链短, lookup 用最新全局历史保精度)。
  reg upd_valid_q;
  reg upd_taken_q;
  reg [`BPU_BHT_INDEX_W-1:0] upd_bht_idx_q;
  reg [`BPU_LOCAL_HISTORY_INDEX_W-1:0] upd_lhist_idx_q;
  reg [`BPU_LOCAL_HISTORY_W-1:0] upd_lhist_q;
  reg [1:0] upd_bht_ctr_q;

  always @(posedge clk) begin
    if (rst || clear_i) begin
      // 预测表 payload 在 invalid 时不可见，清表只清 valid 和全局历史。
      // clear 同时清 update 流水在飞项(fence.i/satp 语境下丢一次训练无害)。
      ghr_q <= {`BPU_BHT_INDEX_W{1'b0}};
      bht_valid_q <= {`BPU_BHT_ENTRIES{1'b0}};
      local_hist_valid_q <= {`BPU_LOCAL_HISTORY_ENTRIES{1'b0}};
      upd_valid_q <= 1'b0;
    end else begin
      // stage1: 寄存输入+读老值; GHR 当拍更新
      upd_valid_q <= update_valid_i;
      if (update_valid_i) begin
        upd_taken_q <= update_taken_i;
        upd_bht_idx_q <= update_bht_idx_i;
        upd_lhist_idx_q <= update_local_hist_idx_w;
        upd_lhist_q <= update_local_hist_w;
        upd_bht_ctr_q <= update_bht_counter_w;
        ghr_q <= {ghr_q[`BPU_BHT_INDEX_W-2:0], update_taken_i};
      end
      // stage2: 训练+写表
      if (upd_valid_q) begin
        bht_valid_q[upd_bht_idx_q] <= 1'b1;
        bht_q[upd_bht_idx_q] <= counter_train(upd_bht_ctr_q, upd_taken_q);
        local_hist_valid_q[upd_lhist_idx_q] <= 1'b1;
        local_hist_q[upd_lhist_idx_q] <=
            {upd_lhist_q[`BPU_LOCAL_HISTORY_W-2:0], upd_taken_q};
      end
    end
  end

endmodule
