`include "define.v"

module tb_ooo_clmul_unit;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam [1:0] CLMUL_OP_LOW = 2'd0;
  localparam [1:0] CLMUL_OP_HIGH = 2'd1;
  localparam [1:0] CLMUL_OP_REV = 2'd2;

  reg clk;
  reg rst;
  reg flush;
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  reg [ROB_INDEX_W-1:0] rob_head_idx;

  reg req_valid;
  wire req_ready;
  reg [ROB_INDEX_W-1:0] req_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] req_pdest;
  reg [1:0] req_op;
  reg [`XLEN-1:0] req_src1;
  reg [`XLEN-1:0] req_src2;

  wire resp_valid;
  reg resp_ready;
  wire [ROB_INDEX_W-1:0] resp_rob_idx;
  wire [PHY_REG_ADDR_W-1:0] resp_pdest;
  wire [`XLEN-1:0] resp_data;

  OooClmulUnit #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .rob_head_idx_i(rob_head_idx),
    .req_valid_i(req_valid),
    .req_ready_o(req_ready),
    .req_rob_idx_i(req_rob_idx),
    .req_pdest_i(req_pdest),
    .req_op_i(req_op),
    .req_src1_i(req_src1),
    .req_src2_i(req_src2),
    .resp_valid_o(resp_valid),
    .resp_ready_i(resp_ready),
    .resp_rob_idx_o(resp_rob_idx),
    .resp_pdest_o(resp_pdest),
    .resp_data_o(resp_data)
  );

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  function [`XLEN-1:0] ref_clmul;
    input [1:0] op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    integer i;
    begin
      ref_clmul = {`XLEN{1'b0}};
      if (op == CLMUL_OP_LOW) begin
        for (i = 0; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 << i);
        end
      end else if (op == CLMUL_OP_HIGH) begin
        for (i = 0; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 >> (63 - i));
        end
      end else begin
        for (i = 1; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 >> (64 - i));
        end
      end
    end
  endfunction

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      flush = 1'b0;
      kill_valid = 1'b0;
      kill_rob_idx = {ROB_INDEX_W{1'b0}};
      rob_head_idx = {ROB_INDEX_W{1'b0}};
      req_valid = 1'b0;
      req_rob_idx = {ROB_INDEX_W{1'b0}};
      req_pdest = {PHY_REG_ADDR_W{1'b0}};
      req_op = CLMUL_OP_LOW;
      req_src1 = {`XLEN{1'b0}};
      req_src2 = {`XLEN{1'b0}};
      resp_ready = 1'b0;
      `TB_TICK(clk)
      `TB_TICK(clk)
      rst = 1'b0;
      `TB_TICK(clk)
    end
  endtask

  task automatic check_kill_predicate_exhaustive;
    integer head_i;
    integer cut_i;
    integer victim_i;
    reg expected_kill;
    begin
      // 在 IDLE 且 req payload 保持有效时穷举 16x16x16 环形年龄。除了锁定
      // strict-younger 的 `>` 边界，每次 cut/head 只变化而 req 不变的首项也是
      // ambient function 敏感集的定点反例。
      req_valid = 1'b1;
      req_op = CLMUL_OP_LOW;
      req_src1 = 64'h1;
      req_src2 = 64'h1;
      req_pdest = 6'd3;
      kill_valid = 1'b1;
      for (head_i = 0; head_i < 16; head_i = head_i + 1) begin
        rob_head_idx = head_i[ROB_INDEX_W-1:0];
        for (cut_i = 0; cut_i < 16; cut_i = cut_i + 1) begin
          kill_rob_idx = cut_i[ROB_INDEX_W-1:0];
          for (victim_i = 0; victim_i < 16; victim_i = victim_i + 1) begin
            req_rob_idx = victim_i[ROB_INDEX_W-1:0];
            #1;
            expected_kill =
                ((victim_i - head_i) & 15) > ((cut_i - head_i) & 15);
            if (dut.kill_new_req_w !== expected_kill) begin
              tb_errors = tb_errors + 1;
              $display("[CHECK-FAIL] exhaustive kill predicate head=%0d cut=%0d victim=%0d got=%0b expected=%0b",
                       head_i, cut_i, victim_i, dut.kill_new_req_w,
                       expected_kill);
            end
          end
        end
      end
      req_valid = 1'b0;
      req_rob_idx = {ROB_INDEX_W{1'b0}};
      req_pdest = {PHY_REG_ADDR_W{1'b0}};
      kill_valid = 1'b0;
      kill_rob_idx = {ROB_INDEX_W{1'b0}};
      rob_head_idx = {ROB_INDEX_W{1'b0}};
      #1;
    end
  endtask

  task automatic issue_req;
    input [1023:0] name;
    input [1:0] op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      tb_check1({name, " ready before request"}, req_ready, 1'b1);
      req_valid = 1'b1;
      req_op = op;
      req_src1 = src1;
      req_src2 = src2;
      req_rob_idx = rob_idx;
      req_pdest = pdest;
      `TB_TICK(clk)
      req_valid = 1'b0;
      req_op = CLMUL_OP_LOW;
      req_src1 = {`XLEN{1'b0}};
      req_src2 = {`XLEN{1'b0}};
      req_rob_idx = {ROB_INDEX_W{1'b0}};
      req_pdest = {PHY_REG_ADDR_W{1'b0}};
    end
  endtask

  task automatic expect_resp;
    input [1023:0] name;
    input [`XLEN-1:0] exp_data;
    input [ROB_INDEX_W-1:0] exp_rob_idx;
    input [PHY_REG_ADDR_W-1:0] exp_pdest;
    input integer max_cycles;
    integer wait_i;
    begin
      wait_i = 0;
      while (!resp_valid && wait_i < max_cycles) begin
        wait_i = wait_i + 1;
        `TB_TICK(clk)
      end
      tb_check1({name, " resp_valid"}, resp_valid, 1'b1);
      tb_check64({name, " resp_data"}, resp_data, exp_data);
      if (resp_valid) begin
        if (resp_rob_idx !== exp_rob_idx) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] %0s rob got=%0d expected=%0d",
                   name, resp_rob_idx, exp_rob_idx);
        end
        if (resp_pdest !== exp_pdest) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] %0s pdest got=%0d expected=%0d",
                   name, resp_pdest, exp_pdest);
        end
      end
      resp_ready = 1'b1;
      `TB_TICK(clk)
      resp_ready = 1'b0;
    end
  endtask

  task automatic run_case;
    input [1023:0] name;
    input [1:0] op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    begin
      issue_req(name, op, src1, src2, 4'ha, 6'd21);
      expect_resp(name, ref_clmul(op, src1, src2), 4'ha, 6'd21, 80);
    end
  endtask

  initial begin
    integer wait_i;
    tb_errors = 0;
    reset_dut();

    check_kill_predicate_exhaustive();

    // 只切换 ambient kill-valid：candidate/state/head/cut 全保持不变，
    // kill_new_req 必须在同一拍边沿前立即可见。
    req_valid = 1'b1;
    req_rob_idx = 4'd6;
    req_pdest = 6'd12;
    rob_head_idx = 4'd0;
    kill_rob_idx = 4'd2;
    kill_valid = 1'b0;
    #1;
    tb_check1("kill-valid low leaves new request live",
              dut.kill_new_req_w, 1'b0);
    kill_valid = 1'b1;
    #1;
    tb_check1("kill-valid only toggle is immediately visible",
              dut.kill_new_req_w, 1'b1);
    // matching kill 与 request fire 同拍：不得短暂进入 RUN。
    `TB_TICK(clk)
    tb_check1("same-cycle killed request stays idle", req_ready, 1'b1);
    req_valid = 1'b0;
    kill_valid = 1'b0;
    #1;

    // RUN 期间 matching kill 必须立即拉高 kill_inflight，并在该沿清除
    // held producer。随后用相同 ROB index 重发，只允许新结果出现。
    reset_dut();
    issue_req("run victim", CLMUL_OP_LOW, 64'h1234, 64'h5678,
              4'd1, 6'd13);
    `TB_TICK(clk)
    rob_head_idx = 4'd14;
    kill_rob_idx = 4'd15;
    kill_valid = 1'b1;  // victim=1: age=3, cut age=1 => younger across wrap
    #1;
    tb_check1("run kill is immediately visible", dut.kill_inflight_w, 1'b1);
    tb_check1("run kill masks response", resp_valid, 1'b0);
    `TB_TICK(clk)
    kill_valid = 1'b0;
    tb_check1("run kill clears held producer", req_ready, 1'b1);
    issue_req("same-index replacement", CLMUL_OP_LOW, 64'h3, 64'h5,
              4'd1, 6'd27);
    expect_resp("same-index replacement",
                ref_clmul(CLMUL_OP_LOW, 64'h3, 64'h5),
                4'd1, 6'd27, 80);

    // Backpressured RESP 是最后一个 WB producer reference。matching kill 必须在
    // 时钟沿之前组合抹掉 valid，不能等到下一拍再清 state。
    reset_dut();
    issue_req("response victim", CLMUL_OP_HIGH,
              64'h1111_2222_3333_4444, 64'h0101_0101_0101_0101,
              4'd7, 6'd19);
    wait_i = 0;
    while (!resp_valid && wait_i < 80) begin
      wait_i = wait_i + 1;
      `TB_TICK(clk)
    end
    tb_check1("response victim reaches RESP", resp_valid, 1'b1);
    rob_head_idx = 4'd0;
    kill_rob_idx = 4'd2;
    kill_valid = 1'b1;
    #1;
    tb_check1("response kill masks valid in same cycle", resp_valid, 1'b0);
    resp_ready = 1'b0;
    `TB_TICK(clk)
    kill_valid = 1'b0;
    tb_check1("response kill clears backpressured holder", req_ready, 1'b1);
    tb_check1("response kill has no delayed pulse", resp_valid, 1'b0);

    // strict-younger 边界：equal cut 和环回上的 older survivor 都不得被误杀。
    reset_dut();
    rob_head_idx = 4'd14;
    kill_rob_idx = 4'd1;
    kill_valid = 1'b1;
    issue_req("equal-cut survivor", CLMUL_OP_LOW, 64'h9, 64'h7,
              4'd1, 6'd22);
    expect_resp("equal-cut survivor",
                ref_clmul(CLMUL_OP_LOW, 64'h9, 64'h7),
                4'd1, 6'd22, 80);
    issue_req("wrap older survivor", CLMUL_OP_REV, 64'h8000_0000_0000_0001,
              64'hf, 4'd15, 6'd23);
    expect_resp("wrap older survivor",
                ref_clmul(CLMUL_OP_REV, 64'h8000_0000_0000_0001,
                          64'hf),
                4'd15, 6'd23, 80);
    kill_valid = 1'b0;

    run_case("clmul low", CLMUL_OP_LOW,
             64'h1234_5678_9abc_def0, 64'hfedc_ba98_7654_3210);
    run_case("clmulh high", CLMUL_OP_HIGH,
             64'h1234_5678_9abc_def0, 64'hfedc_ba98_7654_3210);
    run_case("clmulr reverse", CLMUL_OP_REV,
             64'h1234_5678_9abc_def0, 64'hfedc_ba98_7654_3210);
    run_case("clmul zero source", CLMUL_OP_LOW,
             64'h0000_0000_0000_0000, 64'hffff_ffff_ffff_ffff);

    issue_req("busy clmul", CLMUL_OP_LOW,
              64'h1111_2222_3333_4444, 64'h0101_0101_0101_0101,
              4'h3, 6'd9);
    tb_check1("clmul run not ready", req_ready, 1'b0);
    req_valid = 1'b1;
    req_op = CLMUL_OP_HIGH;
    req_src1 = 64'hffff_ffff_ffff_ffff;
    req_src2 = 64'hffff_ffff_ffff_ffff;
    req_rob_idx = 4'h4;
    req_pdest = 6'd10;
    `TB_TICK(clk)
    req_valid = 1'b0;
    tb_check1("busy request ignored", req_ready, 1'b0);
    expect_resp("busy clmul original response",
                ref_clmul(CLMUL_OP_LOW, 64'h1111_2222_3333_4444,
                          64'h0101_0101_0101_0101),
                4'h3, 6'd9, 80);

    issue_req("flush clmul", CLMUL_OP_REV, 64'h7777_0000_aaaa_5555,
              64'h8000_0000_0000_0001, 4'h5, 6'd11);
    `TB_TICK(clk)
    `TB_TICK(clk)
    flush = 1'b1;
    `TB_TICK(clk)
    flush = 1'b0;
    tb_check1("flush clears response", resp_valid, 1'b0);
    tb_check1("flush returns ready", req_ready, 1'b1);

    tb_finish("tb_ooo_clmul_unit");
  end

endmodule
