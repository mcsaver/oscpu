`include "define.v"

module tb_ooo_free_list;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam FREE_COUNT_W = 7;

  reg clk;
  reg rst;
  reg flush;
  reg alloc0_valid;
  wire alloc0_ready;
  wire [PHY_REG_ADDR_W-1:0] alloc0_preg;
  reg alloc1_valid;
  wire alloc1_ready;
  wire [PHY_REG_ADDR_W-1:0] alloc1_preg;
  reg free0_valid;
  reg [PHY_REG_ADDR_W-1:0] free0_preg;
  reg free1_valid;
  reg [PHY_REG_ADDR_W-1:0] free1_preg;
  wire [FREE_COUNT_W-1:0] free_count;
  wire empty;
  wire full;
  integer i;

  OooFreeList dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_ready_o(alloc0_ready),
    .alloc0_preg_o(alloc0_preg),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_ready_o(alloc1_ready),
    .alloc1_preg_o(alloc1_preg),
    .free0_valid_i(free0_valid),
    .free0_preg_i(free0_preg),
    .free1_valid_i(free1_valid),
    .free1_preg_i(free1_preg),
    .free_count_o(free_count),
    .empty_o(empty),
    .full_o(full)
  );

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      alloc0_valid = 1'b0;
      alloc1_valid = 1'b0;
      free0_valid = 1'b0;
      free0_preg = 6'd0;
      free1_valid = 1'b0;
      free1_preg = 6'd0;
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

    tb_check32("initial free count", {25'b0, free_count}, 32'd32);
    tb_check1("initial not empty", empty, 1'b0);
    tb_check32("initial alloc0 preg", {26'b0, alloc0_preg}, 32'd32);
    tb_check32("initial alloc1 preg", {26'b0, alloc1_preg}, 32'd32);

    alloc0_valid = 1'b1;
    alloc1_valid = 1'b1;
    #1;
    tb_check1("alloc0 ready", alloc0_ready, 1'b1);
    tb_check1("alloc1 ready", alloc1_ready, 1'b1);
    tb_check32("alloc0 p32", {26'b0, alloc0_preg}, 32'd32);
    tb_check32("alloc1 p33", {26'b0, alloc1_preg}, 32'd33);
    `TB_TICK(clk);
    tb_check32("after two alloc count", {25'b0, free_count}, 32'd30);
    tb_check32("next alloc0 p34", {26'b0, alloc0_preg}, 32'd34);
    tb_check32("next alloc1 p35", {26'b0, alloc1_preg}, 32'd35);

    clear_inputs();

    alloc0_valid = 1'b1;
    alloc1_valid = 1'b1;
    free0_valid = 1'b1;
    free0_preg = 6'd1;
    free1_valid = 1'b1;
    free1_preg = 6'd2;
    `TB_TICK(clk);
    tb_check32("alloc and free keep count", {25'b0, free_count}, 32'd30);
    clear_inputs();

    alloc0_valid = 1'b1;
    alloc1_valid = 1'b1;
    for (i = 0; i < 14; i = i + 1) begin
      `TB_TICK(clk);
    end
    #1;
    tb_check32("freed p1 becomes visible", {26'b0, alloc0_preg}, 32'd1);
    tb_check32("freed p2 becomes visible", {26'b0, alloc1_preg}, 32'd2);
    `TB_TICK(clk);
    clear_inputs();
    tb_check1("empty after draining", empty, 1'b1);

    free0_valid = 1'b1;
    free0_preg = 6'd0;
    `TB_TICK(clk);
    free0_valid = 1'b0;
    #1;
    tb_check32("free p0 ignored", {25'b0, free_count}, 32'd0);

    flush = 1'b1;
    `TB_TICK(clk);
    flush = 1'b0;
    #1;
    tb_check32("flush restores freelist", {25'b0, free_count}, 32'd32);
    tb_check32("flush restores first preg", {26'b0, alloc0_preg}, 32'd32);

    tb_finish("tb_ooo_free_list");
  end
endmodule
