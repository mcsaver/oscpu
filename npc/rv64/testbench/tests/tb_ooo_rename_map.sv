`include "define.v"

module tb_ooo_rename_map;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;

  reg clk;
  reg rst;
  reg flush;
  reg checkpoint_capture;
  reg checkpoint_restore;
  reg rename0_valid;
  reg [`REG_ADDR_W-1:0] rename0_rs1_arch;
  reg [`REG_ADDR_W-1:0] rename0_rs2_arch;
  reg rename0_rd_en;
  reg [`REG_ADDR_W-1:0] rename0_rd_arch;
  reg [PHY_REG_ADDR_W-1:0] rename0_new_pdest;
  wire [PHY_REG_ADDR_W-1:0] rename0_rs1_preg;
  wire [PHY_REG_ADDR_W-1:0] rename0_rs2_preg;
  wire [PHY_REG_ADDR_W-1:0] rename0_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] rename0_new_pdest_out;
  reg rename1_valid;
  reg [`REG_ADDR_W-1:0] rename1_rs1_arch;
  reg [`REG_ADDR_W-1:0] rename1_rs2_arch;
  reg rename1_rd_en;
  reg [`REG_ADDR_W-1:0] rename1_rd_arch;
  reg [PHY_REG_ADDR_W-1:0] rename1_new_pdest;
  wire [PHY_REG_ADDR_W-1:0] rename1_rs1_preg;
  wire [PHY_REG_ADDR_W-1:0] rename1_rs2_preg;
  wire [PHY_REG_ADDR_W-1:0] rename1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] rename1_new_pdest_out;
  wire [PHY_REG_ADDR_W * `REG_NUM - 1:0] debug_map;

  // B2 ROB-walk 反向恢复端口
  reg restore_valid;
  reg restore0_en;
  reg [`REG_ADDR_W-1:0] restore0_arch;
  reg [PHY_REG_ADDR_W-1:0] restore0_pdest;
  reg restore1_en;
  reg [`REG_ADDR_W-1:0] restore1_arch;
  reg [PHY_REG_ADDR_W-1:0] restore1_pdest;

  OooRenameMap dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .checkpoint_capture_i(checkpoint_capture),
    .checkpoint_restore_i(checkpoint_restore),
    .rename0_valid_i(rename0_valid),
    .rename0_rs1_arch_i(rename0_rs1_arch),
    .rename0_rs2_arch_i(rename0_rs2_arch),
    .rename0_rd_en_i(rename0_rd_en),
    .rename0_rd_arch_i(rename0_rd_arch),
    .rename0_new_pdest_i(rename0_new_pdest),
    .rename0_rs1_preg_o(rename0_rs1_preg),
    .rename0_rs2_preg_o(rename0_rs2_preg),
    .rename0_old_pdest_o(rename0_old_pdest),
    .rename0_new_pdest_o(rename0_new_pdest_out),
    .rename1_valid_i(rename1_valid),
    .rename1_rs1_arch_i(rename1_rs1_arch),
    .rename1_rs2_arch_i(rename1_rs2_arch),
    .rename1_rd_en_i(rename1_rd_en),
    .rename1_rd_arch_i(rename1_rd_arch),
    .rename1_new_pdest_i(rename1_new_pdest),
    .rename1_rs1_preg_o(rename1_rs1_preg),
    .rename1_rs2_preg_o(rename1_rs2_preg),
    .rename1_old_pdest_o(rename1_old_pdest),
    .rename1_new_pdest_o(rename1_new_pdest_out),
    .restore_valid_i(restore_valid),
    .restore0_en_i(restore0_en),
    .restore0_arch_i(restore0_arch),
    .restore0_pdest_i(restore0_pdest),
    .restore1_en_i(restore1_en),
    .restore1_arch_i(restore1_arch),
    .restore1_pdest_i(restore1_pdest),
    .debug_map_o(debug_map)
  );

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      checkpoint_capture = 1'b0;
      checkpoint_restore = 1'b0;
      rename0_valid = 1'b0;
      rename0_rs1_arch = 5'd0;
      rename0_rs2_arch = 5'd0;
      rename0_rd_en = 1'b0;
      rename0_rd_arch = 5'd0;
      rename0_new_pdest = 6'd0;
      rename1_valid = 1'b0;
      rename1_rs1_arch = 5'd0;
      rename1_rs2_arch = 5'd0;
      rename1_rd_en = 1'b0;
      rename1_rd_arch = 5'd0;
      rename1_new_pdest = 6'd0;
      restore_valid = 1'b0;
      restore0_en = 1'b0;
      restore0_arch = 5'd0;
      restore0_pdest = 6'd0;
      restore1_en = 1'b0;
      restore1_arch = 5'd0;
      restore1_pdest = 6'd0;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    rename0_rs1_arch = 5'd1;
    rename0_rs2_arch = 5'd0;
    #1;
    tb_check32("reset x1 map", {26'b0, rename0_rs1_preg}, 32'd1);
    tb_check32("reset x0 map", {26'b0, rename0_rs2_preg}, 32'd0);

    rename0_valid = 1'b1;
    rename0_rd_en = 1'b1;
    rename0_rd_arch = 5'd1;
    rename0_new_pdest = 6'd32;
    rename1_valid = 1'b1;
    rename1_rs1_arch = 5'd1;
    rename1_rs2_arch = 5'd2;
    rename1_rd_en = 1'b1;
    rename1_rd_arch = 5'd2;
    rename1_new_pdest = 6'd33;
    #1;
    tb_check32("lane0 old x1", {26'b0, rename0_old_pdest}, 32'd1);
    tb_check32("lane1 sees lane0 x1", {26'b0, rename1_rs1_preg}, 32'd32);
    tb_check32("lane1 old x2", {26'b0, rename1_old_pdest}, 32'd2);
    `TB_TICK(clk);

    clear_inputs();
    rename0_rs1_arch = 5'd1;
    rename0_rs2_arch = 5'd2;
    #1;
    tb_check32("x1 renamed", {26'b0, rename0_rs1_preg}, 32'd32);
    tb_check32("x2 renamed", {26'b0, rename0_rs2_preg}, 32'd33);

    checkpoint_capture = 1'b1;
    `TB_TICK(clk);
    clear_inputs();

    rename0_valid = 1'b1;
    rename0_rd_en = 1'b1;
    rename0_rd_arch = 5'd1;
    rename0_new_pdest = 6'd40;
    rename1_valid = 1'b1;
    rename1_rd_en = 1'b1;
    rename1_rd_arch = 5'd4;
    rename1_new_pdest = 6'd41;
    `TB_TICK(clk);
    clear_inputs();
    rename0_rs1_arch = 5'd1;
    rename0_rs2_arch = 5'd4;
    #1;
    tb_check32("checkpoint mutation x1", {26'b0, rename0_rs1_preg}, 32'd40);
    tb_check32("checkpoint mutation x4", {26'b0, rename0_rs2_preg}, 32'd41);

    checkpoint_restore = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    rename0_rs1_arch = 5'd1;
    rename0_rs2_arch = 5'd4;
    #1;
    tb_check32("checkpoint restore x1", {26'b0, rename0_rs1_preg}, 32'd32);
    tb_check32("checkpoint restore x4", {26'b0, rename0_rs2_preg}, 32'd4);

    rename0_valid = 1'b1;
    rename0_rd_en = 1'b1;
    rename0_rd_arch = 5'd3;
    rename0_new_pdest = 6'd34;
    rename1_valid = 1'b1;
    rename1_rs1_arch = 5'd3;
    rename1_rd_en = 1'b1;
    rename1_rd_arch = 5'd3;
    rename1_new_pdest = 6'd35;
    #1;
    tb_check32("lane1 WAW old follows lane0", {26'b0, rename1_old_pdest}, 32'd34);
    tb_check32("lane1 RAW follows lane0", {26'b0, rename1_rs1_preg}, 32'd34);
    `TB_TICK(clk);

    clear_inputs();
    rename0_rs1_arch = 5'd3;
    #1;
    tb_check32("lane1 WAW wins map", {26'b0, rename0_rs1_preg}, 32'd35);

    rename0_valid = 1'b1;
    rename0_rd_en = 1'b1;
    rename0_rd_arch = 5'd0;
    rename0_new_pdest = 6'd36;
    `TB_TICK(clk);
    clear_inputs();
    rename0_rs1_arch = 5'd0;
    #1;
    tb_check32("x0 stays p0", {26'b0, rename0_rs1_preg}, 32'd0);

    flush = 1'b1;
    `TB_TICK(clk);
    flush = 1'b0;
    rename0_rs1_arch = 5'd1;
    #1;
    tb_check32("flush restores initial map", {26'b0, rename0_rs1_preg}, 32'd1);

    // ============ B2 ROB-walk 反向恢复端口 ============
    // 造已知映射：x1->p32, x2->p33, x3->p34
    clear_inputs();
    rename0_valid = 1'b1; rename0_rd_en = 1'b1; rename0_rd_arch = 5'd1; rename0_new_pdest = 6'd32;
    rename1_valid = 1'b1; rename1_rd_en = 1'b1; rename1_rd_arch = 5'd2; rename1_new_pdest = 6'd33;
    `TB_TICK(clk); clear_inputs();
    rename0_valid = 1'b1; rename0_rd_en = 1'b1; rename0_rd_arch = 5'd3; rename0_new_pdest = 6'd34;
    `TB_TICK(clk); clear_inputs();
    rename0_rs1_arch = 5'd1; rename0_rs2_arch = 5'd3; #1;
    tb_check32("pre-restore x1=p32", {26'b0, rename0_rs1_preg}, 32'd32);
    tb_check32("pre-restore x3=p34", {26'b0, rename0_rs2_preg}, 32'd34);

    // 恢复 squashed：x3(old=3,younger=lane0)、x1(old=1,older=lane1)
    restore_valid = 1'b1;
    restore0_en = 1'b1; restore0_arch = 5'd3; restore0_pdest = 6'd3;
    restore1_en = 1'b1; restore1_arch = 5'd1; restore1_pdest = 6'd1;
    `TB_TICK(clk); clear_inputs();
    rename0_rs1_arch = 5'd1; rename0_rs2_arch = 5'd3; #1;
    tb_check32("restore x1->old p1", {26'b0, rename0_rs1_preg}, 32'd1);
    tb_check32("restore x3->old p3", {26'b0, rename0_rs2_preg}, 32'd3);
    rename0_rs1_arch = 5'd2; #1;
    tb_check32("restore leaves x2=p33 untouched", {26'b0, rename0_rs1_preg}, 32'd33);

    // 同拍 WAW：两 lane 恢复同一 arch x5；lane1(更老)源序后写胜
    clear_inputs();
    rename0_valid = 1'b1; rename0_rd_en = 1'b1; rename0_rd_arch = 5'd5; rename0_new_pdest = 6'd55;
    `TB_TICK(clk); clear_inputs();
    rename0_rs1_arch = 5'd5; #1;
    tb_check32("pre-WAW x5=p55", {26'b0, rename0_rs1_preg}, 32'd55);
    restore_valid = 1'b1;
    restore0_en = 1'b1; restore0_arch = 5'd5; restore0_pdest = 6'd50;   // younger
    restore1_en = 1'b1; restore1_arch = 5'd5; restore1_pdest = 6'd51;   // older → 胜
    `TB_TICK(clk); clear_inputs();
    rename0_rs1_arch = 5'd5; #1;
    tb_check32("restore same-arch lane1(older) wins", {26'b0, rename0_rs1_preg}, 32'd51);

    // en=0 不恢复
    clear_inputs();
    restore_valid = 1'b1; restore0_en = 1'b0; restore0_arch = 5'd5; restore0_pdest = 6'd9;
    `TB_TICK(clk); clear_inputs();
    rename0_rs1_arch = 5'd5; #1;
    tb_check32("restore en=0 no change", {26'b0, rename0_rs1_preg}, 32'd51);

    tb_finish("tb_ooo_rename_map");
  end
endmodule
