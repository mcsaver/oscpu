`include "define.v"

module OooBranchDirectionPredictor (
  input clk,
  input rst,
  input clear_i,

  input [`XLEN-1:0] lookup0_pc_i,
  input [`XLEN-1:0] lookup0_imm_i,
  output [`BPU_BHT_INDEX_W-1:0] lookup0_bht_idx_o,
  output lookup0_bht_valid_o,
  output lookup0_pred_taken_o,
  output lookup0_predict_strong_o,

  input [`XLEN-1:0] lookup1_pc_i,
  input [`XLEN-1:0] lookup1_imm_i,
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
  reg [`BPU_LOCAL_PHT_ENTRIES-1:0] local_pht_valid_q;
  reg [1:0] local_pht_q [0:`BPU_LOCAL_PHT_ENTRIES-1];

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
  wire lookup0_static_taken_w = lookup0_imm_i[`XLEN-1];
  wire lookup1_static_taken_w = lookup1_imm_i[`XLEN-1];

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
  wire lookup0_local_valid_w =
      local_pht_valid_q[lookup0_local_pht_idx_w];
  wire lookup1_local_valid_w =
      local_pht_valid_q[lookup1_local_pht_idx_w];
  wire [1:0] lookup0_local_ctr_w =
      local_pht_q[lookup0_local_pht_idx_w];
  wire [1:0] lookup1_local_ctr_w =
      local_pht_q[lookup1_local_pht_idx_w];
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
  wire [1:0] update_bht_counter_w =
      bht_valid_q[update_bht_idx_i] ? bht_q[update_bht_idx_i] :
                                      `BPU_COUNTER_INIT;
  wire [1:0] update_local_pht_counter_w =
      local_pht_valid_q[update_local_pht_idx_w] ?
      local_pht_q[update_local_pht_idx_w] : `BPU_COUNTER_INIT;
  wire unused_predictor_input_bits_w =
      (|lookup0_pc_i) | (|lookup0_imm_i) |
      (|lookup1_pc_i) | (|lookup1_imm_i) | (|update_pc_i);

  always @(posedge clk) begin
    if (rst || clear_i) begin
      // 预测表 payload 在 invalid 时不可见，清表只清 valid 和全局历史。
      ghr_q <= {`BPU_BHT_INDEX_W{1'b0}};
      bht_valid_q <= {`BPU_BHT_ENTRIES{1'b0}};
      local_hist_valid_q <= {`BPU_LOCAL_HISTORY_ENTRIES{1'b0}};
      local_pht_valid_q <= {`BPU_LOCAL_PHT_ENTRIES{1'b0}};
    end else if (update_valid_i) begin
      bht_valid_q[update_bht_idx_i] <= 1'b1;
      bht_q[update_bht_idx_i] <=
          counter_train(update_bht_counter_w, update_taken_i);
      ghr_q <= {ghr_q[`BPU_BHT_INDEX_W-2:0], update_taken_i};

      local_pht_valid_q[update_local_pht_idx_w] <= 1'b1;
      local_pht_q[update_local_pht_idx_w] <=
          counter_train(update_local_pht_counter_w, update_taken_i);
      local_hist_valid_q[update_local_hist_idx_w] <= 1'b1;
      local_hist_q[update_local_hist_idx_w] <=
          {update_local_hist_w[`BPU_LOCAL_HISTORY_W-2:0], update_taken_i};
    end
  end

endmodule
