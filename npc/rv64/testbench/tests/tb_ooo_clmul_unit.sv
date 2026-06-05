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
    tb_errors = 0;
    reset_dut();

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
