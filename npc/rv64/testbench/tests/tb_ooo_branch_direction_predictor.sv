`include "define.v"

module tb_ooo_branch_direction_predictor;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg clear;

  reg [`XLEN-1:0] lookup0_pc;
  reg [`XLEN-1:0] lookup0_imm;
  wire [`BPU_BHT_INDEX_W-1:0] lookup0_bht_idx;
  wire lookup0_bht_valid;
  wire lookup0_pred_taken;
  wire lookup0_predict_strong;

  reg [`XLEN-1:0] lookup1_pc;
  reg [`XLEN-1:0] lookup1_imm;
  wire [`BPU_BHT_INDEX_W-1:0] lookup1_bht_idx;
  wire lookup1_bht_valid;
  wire lookup1_pred_taken;
  wire lookup1_predict_strong;

  reg update_valid;
  reg [`XLEN-1:0] update_pc;
  reg [`BPU_BHT_INDEX_W-1:0] update_bht_idx;
  reg update_taken;

  localparam [`XLEN-1:0] PC0 = 64'h0000_0000_8000_1000;
  localparam [`XLEN-1:0] PC1 = 64'h0000_0000_8000_1020;
  localparam [`XLEN-1:0] IMM_FWD = 64'h0000_0000_0000_0010;
  localparam [`XLEN-1:0] IMM_BACK = 64'hffff_ffff_ffff_fff0;

  OooBranchDirectionPredictor dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .lookup0_pc_i(lookup0_pc),
    .lookup0_imm_i(lookup0_imm),
    .lookup0_bht_idx_o(lookup0_bht_idx),
    .lookup0_bht_valid_o(lookup0_bht_valid),
    .lookup0_pred_taken_o(lookup0_pred_taken),
    .lookup0_predict_strong_o(lookup0_predict_strong),
    .lookup1_pc_i(lookup1_pc),
    .lookup1_imm_i(lookup1_imm),
    .lookup1_bht_idx_o(lookup1_bht_idx),
    .lookup1_bht_valid_o(lookup1_bht_valid),
    .lookup1_pred_taken_o(lookup1_pred_taken),
    .lookup1_predict_strong_o(lookup1_predict_strong),
    .update_valid_i(update_valid),
    .update_pc_i(update_pc),
    .update_bht_idx_i(update_bht_idx),
    .update_taken_i(update_taken)
  );

  OooBranchDirectionPredictorChecker u_checker (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .lookup0_pc_i(lookup0_pc),
    .lookup0_imm_i(lookup0_imm),
    .lookup0_bht_idx_i(lookup0_bht_idx),
    .lookup0_bht_valid_i(lookup0_bht_valid),
    .lookup0_pred_taken_i(lookup0_pred_taken),
    .lookup0_predict_strong_i(lookup0_predict_strong),
    .lookup1_pc_i(lookup1_pc),
    .lookup1_imm_i(lookup1_imm),
    .lookup1_bht_idx_i(lookup1_bht_idx),
    .lookup1_bht_valid_i(lookup1_bht_valid),
    .lookup1_pred_taken_i(lookup1_pred_taken),
    .lookup1_predict_strong_i(lookup1_predict_strong),
    .update_valid_i(update_valid),
    .update_pc_i(update_pc),
    .update_bht_idx_i(update_bht_idx),
    .update_taken_i(update_taken)
  );

  task automatic tick;
    begin
      `TB_TICK(clk)
    end
  endtask

  task automatic settle;
    begin
      #1;
    end
  endtask

  task automatic clear_inputs;
    begin
      clear = 1'b0;
      lookup0_pc = PC0;
      lookup0_imm = IMM_FWD;
      lookup1_pc = PC1;
      lookup1_imm = IMM_BACK;
      update_valid = 1'b0;
      update_pc = PC0;
      update_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
      update_taken = 1'b0;
    end
  endtask

  task automatic train_lookup0;
    input taken;
    begin
      settle();
      update_pc = lookup0_pc;
      update_bht_idx = lookup0_bht_idx;
      update_taken = taken;
      update_valid = 1'b1;
      tick();
      update_valid = 1'b0;
      tick();   // 【update 两拍流水】stage2 写表拍(训练可见性 1→2 拍)
      settle();
    end
  endtask

  task automatic check_bht_idx;
    input [1023:0] what;
    input [`BPU_BHT_INDEX_W-1:0] got;
    input [`BPU_BHT_INDEX_W-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%0x expected=0x%0x",
                 what, got, exp);
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    settle();

    check_bht_idx("reset lookup0 idx", lookup0_bht_idx,
                  PC0[`BPU_BHT_INDEX_W:1]);
    check_bht_idx("reset lookup1 idx", lookup1_bht_idx,
                  PC1[`BPU_BHT_INDEX_W:1]);
    tb_check1("forward static not-taken valid", lookup0_bht_valid, 1'b0);
    tb_check1("forward static not-taken pred", lookup0_pred_taken, 1'b0);
    tb_check1("forward static not-taken strong", lookup0_predict_strong, 1'b0);
    tb_check1("backward static taken valid", lookup1_bht_valid, 1'b0);
    tb_check1("backward static taken pred", lookup1_pred_taken, 1'b1);
    tb_check1("backward static taken strong", lookup1_predict_strong, 1'b0);

    train_lookup0(1'b0);
    tb_check1("one NT train valid", lookup0_bht_valid, 1'b1);
    tb_check1("one NT train pred", lookup0_pred_taken, 1'b0);
    tb_check1("one NT train weak", lookup0_predict_strong, 1'b0);

    train_lookup0(1'b0);
    tb_check1("two NT train valid", lookup0_bht_valid, 1'b1);
    tb_check1("two NT train pred", lookup0_pred_taken, 1'b0);
    tb_check1("two NT train strong", lookup0_predict_strong, 1'b1);

    clear = 1'b1;
    tick();
    clear = 1'b0;
    settle();
    check_bht_idx("clear resets ghr/index", lookup0_bht_idx,
                  PC0[`BPU_BHT_INDEX_W:1]);
    tb_check1("clear drops trained valid", lookup0_bht_valid, 1'b0);
    tb_check1("clear restores static pred", lookup0_pred_taken, 1'b0);
    tb_check1("clear drops strong", lookup0_predict_strong, 1'b0);

    train_lookup0(1'b1);
    check_bht_idx("taken update shifts ghr lookup0", lookup0_bht_idx,
                  PC0[`BPU_BHT_INDEX_W:1] ^ {{(`BPU_BHT_INDEX_W-1){1'b0}}, 1'b1});
    check_bht_idx("taken update shifts ghr lookup1", lookup1_bht_idx,
                  PC1[`BPU_BHT_INDEX_W:1] ^ {{(`BPU_BHT_INDEX_W-1){1'b0}}, 1'b1});
    tb_check1("taken update new idx falls back static", lookup0_bht_valid, 1'b0);

    lookup1_pc = PC1 + 64'd2;
    lookup1_imm = IMM_FWD;
    settle();
    tb_check1("lane1 independent static after ghr shift", lookup1_pred_taken, 1'b0);

    tb_finish("tb_ooo_branch_direction_predictor");
  end
endmodule
