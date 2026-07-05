`include "define.v"

module tb_ooo_muldiv_unit;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;

  reg clk;
  reg rst;
  reg flush;

  reg req_valid;
  wire req_ready;
  reg [ROB_INDEX_W-1:0] req_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] req_pdest;
  reg [`INST_W-1:0] req_inst;
  reg [`XLEN-1:0] req_src1;
  reg [`XLEN-1:0] req_src2;
  reg req_word;

  wire resp_valid;
  reg resp_ready;
  wire [ROB_INDEX_W-1:0] resp_rob_idx;
  wire [PHY_REG_ADDR_W-1:0] resp_pdest;
  wire [`XLEN-1:0] resp_data;

  OooMulDivUnit #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .kill_valid_i(1'b0),                        // UC-A kill 端口: TB 禁用(=0), 单元行为退化为原逻辑
    .kill_rob_idx_i({ROB_INDEX_W{1'b0}}),
    .rob_head_idx_i({ROB_INDEX_W{1'b0}}),
    .req_valid_i(req_valid),
    .req_ready_o(req_ready),
    .req_rob_idx_i(req_rob_idx),
    .req_pdest_i(req_pdest),
    .req_inst_i(req_inst),
    .req_src1_i(req_src1),
    .req_src2_i(req_src2),
    .req_word_i(req_word),
    .resp_valid_o(resp_valid),
    .resp_ready_i(resp_ready),
    .resp_rob_idx_o(resp_rob_idx),
    .resp_pdest_o(resp_pdest),
    .resp_data_o(resp_data)
  );

  function [`INST_W-1:0] rv64m_inst;
    input [2:0] funct3;
    begin
      rv64m_inst = {7'b0000001, 5'd2, 5'd1, funct3, 5'd3, `OPCODE_OP};
    end
  endfunction

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

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      flush = 1'b0;
      req_valid = 1'b0;
      req_rob_idx = {ROB_INDEX_W{1'b0}};
      req_pdest = {PHY_REG_ADDR_W{1'b0}};
      req_inst = {`INST_W{1'b0}};
      req_src1 = {`XLEN{1'b0}};
      req_src2 = {`XLEN{1'b0}};
      req_word = 1'b0;
      resp_ready = 1'b0;
      `TB_TICK(clk)
      `TB_TICK(clk)
      rst = 1'b0;
      `TB_TICK(clk)
    end
  endtask

  task automatic issue_req;
    input [1023:0] name;
    input [2:0] funct3;
    input word_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      tb_check1({name, " ready before request"}, req_ready, 1'b1);
      req_valid = 1'b1;
      req_inst = rv64m_inst(funct3);
      req_src1 = src1;
      req_src2 = src2;
      req_word = word_op;
      req_rob_idx = rob_idx;
      req_pdest = pdest;
      `TB_TICK(clk)
      req_valid = 1'b0;
      req_inst = {`INST_W{1'b0}};
      req_src1 = {`XLEN{1'b0}};
      req_src2 = {`XLEN{1'b0}};
      req_word = 1'b0;
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
    input [2:0] funct3;
    input word_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    input [`XLEN-1:0] exp_data;
    begin
      issue_req(name, funct3, word_op, src1, src2, 4'ha, 6'd21);
      expect_resp(name, exp_data, 4'ha, 6'd21, 80);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    run_case("mul low signed operands", 3'b000, 1'b0, 64'd7,
             64'hffff_ffff_ffff_fffd, 64'hffff_ffff_ffff_ffeb);
    run_case("mulh signed signed", 3'b001, 1'b0,
             64'hffff_ffff_ffff_fffe, 64'd3,
             64'hffff_ffff_ffff_ffff);
    run_case("mulhsu signed unsigned", 3'b010, 1'b0,
             64'hffff_ffff_ffff_fffe, 64'd3,
             64'hffff_ffff_ffff_ffff);
    run_case("mulhu unsigned high", 3'b011, 1'b0,
             64'h8000_0000_0000_0000, 64'd2,
             64'h0000_0000_0000_0001);
    run_case("mulw sign extend", 3'b000, 1'b1,
             64'h0000_0001_0000_0003, 64'd2,
             64'h0000_0000_0000_0006);

    run_case("div signed", 3'b100, 1'b0,
             64'hffff_ffff_ffff_ff9c, 64'd7,
             64'hffff_ffff_ffff_fff2);
    run_case("rem signed", 3'b110, 1'b0,
             64'hffff_ffff_ffff_ff9c, 64'd7,
             64'hffff_ffff_ffff_fffe);
    run_case("divu unsigned", 3'b101, 1'b0, 64'd100, 64'd7, 64'd14);
    run_case("remu unsigned", 3'b111, 1'b0, 64'd100, 64'd7, 64'd2);
    run_case("div by zero", 3'b100, 1'b0,
             64'h1234_5678_9abc_def0, 64'd0,
             64'hffff_ffff_ffff_ffff);
    run_case("rem by zero", 3'b110, 1'b0,
             64'h1234_5678_9abc_def0, 64'd0,
             64'h1234_5678_9abc_def0);
    run_case("div overflow", 3'b100, 1'b0,
             64'h8000_0000_0000_0000, 64'hffff_ffff_ffff_ffff,
             64'h8000_0000_0000_0000);
    run_case("divw overflow", 3'b100, 1'b1,
             64'hffff_ffff_8000_0000, 64'hffff_ffff_ffff_ffff,
             64'hffff_ffff_8000_0000);
    run_case("divuw", 3'b101, 1'b1,
             64'h0000_0000_ffff_ffff, 64'd2,
             64'h0000_0000_7fff_ffff);
    run_case("remuw", 3'b111, 1'b1,
             64'h0000_0000_ffff_ffff, 64'd2,
             64'h0000_0000_0000_0001);

    issue_req("busy div", 3'b100, 1'b0, 64'd100, 64'd3, 4'h3, 6'd9);
    tb_check1("div run not ready", req_ready, 1'b0);
    req_valid = 1'b1;
    req_inst = rv64m_inst(3'b000);
    req_src1 = 64'd5;
    req_src2 = 64'd5;
    req_word = 1'b0;
    req_rob_idx = 4'h4;
    req_pdest = 6'd10;
    `TB_TICK(clk)
    req_valid = 1'b0;
    tb_check1("busy request ignored", req_ready, 1'b0);
    expect_resp("busy div original response", 64'd33, 4'h3, 6'd9, 80);

    issue_req("flush div", 3'b100, 1'b0, 64'd77, 64'd5, 4'h5, 6'd11);
    `TB_TICK(clk)
    `TB_TICK(clk)
    flush = 1'b1;
    `TB_TICK(clk)
    flush = 1'b0;
    tb_check1("flush clears response", resp_valid, 1'b0);
    tb_check1("flush returns ready", req_ready, 1'b1);

    tb_finish("tb_ooo_muldiv_unit");
  end

endmodule
