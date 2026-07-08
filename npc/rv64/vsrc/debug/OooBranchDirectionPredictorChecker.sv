// OooBranchDirectionPredictor 外部观测 checker。
// 只用于仿真/测试的 debug 层：用独立参考表审核 lookup/update 可见语义，不进入综合核心。
`include "define.v"
`include "common/OooBranchDirectionPredictorFacts.vh"

module OooBranchDirectionPredictorChecker (
  input wire clk,
  input wire rst,
  input wire clear_i,

  input wire [`XLEN-1:0] lookup0_pc_i,
  input wire [`XLEN-1:0] lookup0_imm_i,
  input wire [`BPU_BHT_INDEX_W-1:0] lookup0_bht_idx_i,
  input wire lookup0_bht_valid_i,
  input wire lookup0_pred_taken_i,
  input wire lookup0_predict_strong_i,

  input wire [`XLEN-1:0] lookup1_pc_i,
  input wire [`XLEN-1:0] lookup1_imm_i,
  input wire [`BPU_BHT_INDEX_W-1:0] lookup1_bht_idx_i,
  input wire lookup1_bht_valid_i,
  input wire lookup1_pred_taken_i,
  input wire lookup1_predict_strong_i,

  input wire update_valid_i,
  input wire [`XLEN-1:0] update_pc_i,
  input wire [`BPU_BHT_INDEX_W-1:0] update_bht_idx_i,
  input wire update_taken_i
);

  reg [`BPU_BHT_ENTRIES-1:0] model_bht_valid_q;
  reg [1:0] model_bht_q [0:`BPU_BHT_ENTRIES-1];
  reg [`BPU_BHT_INDEX_W-1:0] model_ghr_q;
  reg [`BPU_LOCAL_HISTORY_ENTRIES-1:0] model_local_hist_valid_q;
  reg [`BPU_LOCAL_HISTORY_W-1:0] model_local_hist_q
      [0:`BPU_LOCAL_HISTORY_ENTRIES-1];
  reg [`BPU_LOCAL_PHT_ENTRIES-1:0] model_local_pht_valid_q;
  reg [1:0] model_local_pht_q [0:`BPU_LOCAL_PHT_ENTRIES-1];

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
  wire [`BPU_BHT_INDEX_W-1:0] exp_lookup0_bht_idx_w =
      lookup0_pc_idx_w ^ model_ghr_q;
  wire [`BPU_BHT_INDEX_W-1:0] exp_lookup1_bht_idx_w =
      lookup1_pc_idx_w ^ model_ghr_q;
  wire exp_lookup0_bht_valid_w = model_bht_valid_q[exp_lookup0_bht_idx_w];
  wire exp_lookup1_bht_valid_w = model_bht_valid_q[exp_lookup1_bht_idx_w];
  wire [1:0] lookup0_gshare_ctr_w = model_bht_q[exp_lookup0_bht_idx_w];
  wire [1:0] lookup1_gshare_ctr_w = model_bht_q[exp_lookup1_bht_idx_w];
  wire lookup0_static_taken_w = lookup0_imm_i[`XLEN-1];
  wire lookup1_static_taken_w = lookup1_imm_i[`XLEN-1];
  wire exp_lookup0_gshare_taken_w =
      bht_counter_taken(exp_lookup0_bht_valid_w, lookup0_gshare_ctr_w,
                        lookup0_static_taken_w);
  wire exp_lookup1_gshare_taken_w =
      bht_counter_taken(exp_lookup1_bht_valid_w, lookup1_gshare_ctr_w,
                        lookup1_static_taken_w);
  wire exp_lookup0_gshare_strong_w =
      counter_strong(exp_lookup0_bht_valid_w, lookup0_gshare_ctr_w);
  wire exp_lookup1_gshare_strong_w =
      counter_strong(exp_lookup1_bht_valid_w, lookup1_gshare_ctr_w);

  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] lookup0_local_hist_idx_w =
      lookup0_pc_i[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] lookup1_local_hist_idx_w =
      lookup1_pc_i[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire lookup0_local_hist_valid_w =
      model_local_hist_valid_q[lookup0_local_hist_idx_w];
  wire lookup1_local_hist_valid_w =
      model_local_hist_valid_q[lookup1_local_hist_idx_w];
  wire [`BPU_LOCAL_HISTORY_W-1:0] lookup0_local_hist_w =
      lookup0_local_hist_valid_w ?
      model_local_hist_q[lookup0_local_hist_idx_w] :
      {`BPU_LOCAL_HISTORY_W{1'b0}};
  wire [`BPU_LOCAL_HISTORY_W-1:0] lookup1_local_hist_w =
      lookup1_local_hist_valid_w ?
      model_local_hist_q[lookup1_local_hist_idx_w] :
      {`BPU_LOCAL_HISTORY_W{1'b0}};
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] lookup0_local_pc_idx_w =
      lookup0_pc_i[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] lookup1_local_pc_idx_w =
      lookup1_pc_i[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] lookup0_local_pht_idx_w =
      {lookup0_local_pc_idx_w, lookup0_local_hist_w};
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] lookup1_local_pht_idx_w =
      {lookup1_local_pc_idx_w, lookup1_local_hist_w};
  wire exp_lookup0_local_valid_w =
      model_local_pht_valid_q[lookup0_local_pht_idx_w];
  wire exp_lookup1_local_valid_w =
      model_local_pht_valid_q[lookup1_local_pht_idx_w];
  wire [1:0] lookup0_local_ctr_w =
      model_local_pht_q[lookup0_local_pht_idx_w];
  wire [1:0] lookup1_local_ctr_w =
      model_local_pht_q[lookup1_local_pht_idx_w];
  wire exp_lookup0_local_taken_w =
      bht_counter_taken(exp_lookup0_local_valid_w, lookup0_local_ctr_w,
                        lookup0_static_taken_w);
  wire exp_lookup1_local_taken_w =
      bht_counter_taken(exp_lookup1_local_valid_w, lookup1_local_ctr_w,
                        lookup1_static_taken_w);
  wire exp_lookup0_local_strong_w =
      counter_strong(exp_lookup0_local_valid_w, lookup0_local_ctr_w);
  wire exp_lookup1_local_strong_w =
      counter_strong(exp_lookup1_local_valid_w, lookup1_local_ctr_w);
  wire exp_lookup0_pred_taken_w =
      (exp_lookup0_local_valid_w && !exp_lookup0_gshare_strong_w) ?
      exp_lookup0_local_taken_w :
      exp_lookup0_gshare_strong_w ? exp_lookup0_local_taken_w :
                                    exp_lookup0_gshare_taken_w;
  wire exp_lookup1_pred_taken_w =
      (exp_lookup1_local_valid_w && !exp_lookup1_gshare_strong_w) ?
      exp_lookup1_local_taken_w :
      exp_lookup1_gshare_strong_w ? exp_lookup1_local_taken_w :
                                    exp_lookup1_gshare_taken_w;
  wire exp_lookup0_predict_strong_w =
      exp_lookup0_gshare_strong_w || exp_lookup0_local_strong_w;
  wire exp_lookup1_predict_strong_w =
      exp_lookup1_gshare_strong_w || exp_lookup1_local_strong_w;

  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] update_local_hist_idx_w =
      update_pc_i[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire update_local_hist_valid_w =
      model_local_hist_valid_q[update_local_hist_idx_w];
  wire [`BPU_LOCAL_HISTORY_W-1:0] update_local_hist_w =
      update_local_hist_valid_w ?
      model_local_hist_q[update_local_hist_idx_w] :
      {`BPU_LOCAL_HISTORY_W{1'b0}};
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] update_local_pc_idx_w =
      update_pc_i[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] update_local_pht_idx_w =
      {update_local_pc_idx_w, update_local_hist_w};
  wire [1:0] update_bht_counter_w =
      model_bht_valid_q[update_bht_idx_i] ?
      model_bht_q[update_bht_idx_i] : `BPU_COUNTER_INIT;
  wire [1:0] update_local_pht_counter_w =
      model_local_pht_valid_q[update_local_pht_idx_w] ?
      model_local_pht_q[update_local_pht_idx_w] : `BPU_COUNTER_INIT;

  wire [`OOO_BPU_FACTS_W-1:0] facts_w;
  assign facts_w[`OOO_BPU_LOOKUP0_VALID] = lookup0_bht_valid_i;
  assign facts_w[`OOO_BPU_LOOKUP0_TAKEN] = lookup0_pred_taken_i;
  assign facts_w[`OOO_BPU_LOOKUP0_STRONG] = lookup0_predict_strong_i;
  assign facts_w[`OOO_BPU_LOOKUP1_VALID] = lookup1_bht_valid_i;
  assign facts_w[`OOO_BPU_LOOKUP1_TAKEN] = lookup1_pred_taken_i;
  assign facts_w[`OOO_BPU_LOOKUP1_STRONG] = lookup1_predict_strong_i;
  assign facts_w[`OOO_BPU_UPDATE] = update_valid_i;
  assign facts_w[`OOO_BPU_UPDATE_TAKEN] = update_taken_i;
  assign facts_w[`OOO_BPU_CLEAR] = clear_i;
  assign facts_w[`OOO_BPU_LOOKUP0_STATIC_TAKEN] = lookup0_static_taken_w;
  assign facts_w[`OOO_BPU_LOOKUP1_STATIC_TAKEN] = lookup1_static_taken_w;

  wire _unused_facts_w =
      |facts_w | (|update_pc_i) | (|update_bht_idx_i);

`ifdef OOO_ASSERT
  always @(posedge clk) begin
    if (!rst) begin
      if (lookup0_bht_idx_i !== exp_lookup0_bht_idx_w) begin
        $error("[BPU-L0-IDX] lookup0 index mismatch: got=%h exp=%h pc=%h @%0t",
               lookup0_bht_idx_i, exp_lookup0_bht_idx_w, lookup0_pc_i, $time);
        $fatal;
      end
      if (lookup1_bht_idx_i !== exp_lookup1_bht_idx_w) begin
        $error("[BPU-L1-IDX] lookup1 index mismatch: got=%h exp=%h pc=%h @%0t",
               lookup1_bht_idx_i, exp_lookup1_bht_idx_w, lookup1_pc_i, $time);
        $fatal;
      end
      if (lookup0_bht_valid_i !== exp_lookup0_bht_valid_w) begin
        $error("[BPU-L0-VALID] lookup0 BHT valid mismatch: got=%b exp=%b idx=%h @%0t",
               lookup0_bht_valid_i, exp_lookup0_bht_valid_w,
               exp_lookup0_bht_idx_w, $time);
        $fatal;
      end
      if (lookup1_bht_valid_i !== exp_lookup1_bht_valid_w) begin
        $error("[BPU-L1-VALID] lookup1 BHT valid mismatch: got=%b exp=%b idx=%h @%0t",
               lookup1_bht_valid_i, exp_lookup1_bht_valid_w,
               exp_lookup1_bht_idx_w, $time);
        $fatal;
      end
      if (lookup0_pred_taken_i !== exp_lookup0_pred_taken_w) begin
        $error("[BPU-L0-PRED] lookup0 prediction mismatch: got=%b exp=%b pc=%h @%0t",
               lookup0_pred_taken_i, exp_lookup0_pred_taken_w,
               lookup0_pc_i, $time);
        $fatal;
      end
      if (lookup1_pred_taken_i !== exp_lookup1_pred_taken_w) begin
        $error("[BPU-L1-PRED] lookup1 prediction mismatch: got=%b exp=%b pc=%h @%0t",
               lookup1_pred_taken_i, exp_lookup1_pred_taken_w,
               lookup1_pc_i, $time);
        $fatal;
      end
      if (lookup0_predict_strong_i !== exp_lookup0_predict_strong_w) begin
        $error("[BPU-L0-STRONG] lookup0 strength mismatch: got=%b exp=%b pc=%h @%0t",
               lookup0_predict_strong_i, exp_lookup0_predict_strong_w,
               lookup0_pc_i, $time);
        $fatal;
      end
      if (lookup1_predict_strong_i !== exp_lookup1_predict_strong_w) begin
        $error("[BPU-L1-STRONG] lookup1 strength mismatch: got=%b exp=%b pc=%h @%0t",
               lookup1_predict_strong_i, exp_lookup1_predict_strong_w,
               lookup1_pc_i, $time);
        $fatal;
      end
    end
  end
`endif

  always @(posedge clk) begin
    if (rst || clear_i) begin
      model_ghr_q <= {`BPU_BHT_INDEX_W{1'b0}};
      model_bht_valid_q <= {`BPU_BHT_ENTRIES{1'b0}};
      model_local_hist_valid_q <= {`BPU_LOCAL_HISTORY_ENTRIES{1'b0}};
      model_local_pht_valid_q <= {`BPU_LOCAL_PHT_ENTRIES{1'b0}};
    end else if (update_valid_i) begin
      model_bht_valid_q[update_bht_idx_i] <= 1'b1;
      model_bht_q[update_bht_idx_i] <=
          counter_train(update_bht_counter_w, update_taken_i);
      model_ghr_q <= {model_ghr_q[`BPU_BHT_INDEX_W-2:0], update_taken_i};

      model_local_pht_valid_q[update_local_pht_idx_w] <= 1'b1;
      model_local_pht_q[update_local_pht_idx_w] <=
          counter_train(update_local_pht_counter_w, update_taken_i);
      model_local_hist_valid_q[update_local_hist_idx_w] <= 1'b1;
      model_local_hist_q[update_local_hist_idx_w] <=
          {update_local_hist_w[`BPU_LOCAL_HISTORY_W-2:0], update_taken_i};
    end
  end

endmodule
