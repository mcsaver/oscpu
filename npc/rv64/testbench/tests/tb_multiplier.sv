`include "define.v"

module tb_multiplier;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush;
  reg req_valid;
  wire req_ready;
  reg [2:0] req_funct3;
  reg [`XLEN-1:0] req_src1;
  reg [`XLEN-1:0] req_src2;
  wire rsp_valid;
  reg rsp_ready;
  wire [`XLEN-1:0] rsp_data;

  Rv32Multiplier dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .req_valid_i(req_valid),
    .req_ready_o(req_ready),
    .req_funct3_i(req_funct3),
    .req_src1_i(req_src1),
    .req_src2_i(req_src2),
    .rsp_valid_o(rsp_valid),
    .rsp_ready_i(rsp_ready),
    .rsp_data_o(rsp_data)
  );

  task automatic reset_dut;
    begin
      rst = 1'b1;
      flush = 1'b0;
      req_valid = 1'b0;
      rsp_ready = 1'b0;
      req_funct3 = 3'b000;
      req_src1 = {`XLEN{1'b0}};
      req_src2 = {`XLEN{1'b0}};
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  task automatic issue_wait;
    input [1023:0] name;
    input [2:0] funct3;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    input [`XLEN-1:0] exp;
    integer guard;
    begin
      guard = 0;
      while (!req_ready && guard < 8) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1({name, " ready"}, req_ready, 1'b1);
      req_funct3 = funct3;
      req_src1 = src1;
      req_src2 = src2;
      req_valid = 1'b1;
      `TB_TICK(clk);
      req_valid = 1'b0;

      guard = 0;
      while (!rsp_valid && guard < 8) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1({name, " rsp_valid"}, rsp_valid, 1'b1);
      if (rsp_data !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 name, rsp_data, exp);
      end
      rsp_ready = 1'b1;
      `TB_TICK(clk);
      rsp_ready = 1'b0;
      #1;
      tb_check1({name, " rsp consumed"}, rsp_valid, 1'b0);
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    reset_dut();

    issue_wait("mul low signed-compatible", 3'b000,
               64'hffff_ffff_ffff_fffe, 64'd3,
               64'hffff_ffff_ffff_fffa);
    issue_wait("mulh signed", 3'b001,
               64'h8000_0000_0000_0000, 64'd2,
               64'hffff_ffff_ffff_ffff);
    issue_wait("mulhsu signed-unsigned", 3'b010,
               64'hffff_ffff_ffff_fffe, 64'h8000_0000_0000_0000,
               64'hffff_ffff_ffff_ffff);
    issue_wait("mulhu unsigned", 3'b011,
               64'hffff_ffff_ffff_ffff, 64'hffff_ffff_ffff_ffff,
               64'hffff_ffff_ffff_fffe);

    req_funct3 = 3'b000;
    req_src1 = 32'd9;
    req_src2 = 32'd7;
    req_valid = 1'b1;
    `TB_TICK(clk);
    req_valid = 1'b0;
    repeat (2) `TB_TICK(clk);
    flush = 1'b1;
    `TB_TICK(clk);
    flush = 1'b0;
    #1;
    tb_check1("flush clears pipeline", rsp_valid, 1'b0);

    tb_finish("tb_multiplier");
  end
endmodule
