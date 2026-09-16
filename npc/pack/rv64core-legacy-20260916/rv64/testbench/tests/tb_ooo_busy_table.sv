`include "define.v"

module tb_ooo_busy_table;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;

  reg clk;
  reg rst;
  reg flush;
  reg alloc0_valid;
  reg [PHY_REG_ADDR_W-1:0] alloc0_pdest;
  reg alloc1_valid;
  reg [PHY_REG_ADDR_W-1:0] alloc1_pdest;
  reg wakeup0_valid;
  reg [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
  reg wakeup1_valid;
  reg [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
  reg [PHY_REG_ADDR_W-1:0] query0_preg;
  wire query0_ready;
  reg [PHY_REG_ADDR_W-1:0] query1_preg;
  wire query1_ready;
  reg [PHY_REG_ADDR_W-1:0] query2_preg;
  wire query2_ready;
  reg [PHY_REG_ADDR_W-1:0] query3_preg;
  wire query3_ready;

  OooBusyTable dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_pdest_i(alloc0_pdest),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_pdest_i(alloc1_pdest),
    .wakeup0_valid_i(wakeup0_valid),
    .wakeup0_pdest_i(wakeup0_pdest),
    .wakeup1_valid_i(wakeup1_valid),
    .wakeup1_pdest_i(wakeup1_pdest),
    .query0_preg_i(query0_preg),
    .query0_ready_o(query0_ready),
    .query1_preg_i(query1_preg),
    .query1_ready_o(query1_ready),
    .query2_preg_i(query2_preg),
    .query2_ready_o(query2_ready),
    .query3_preg_i(query3_preg),
    .query3_ready_o(query3_ready)
  );

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      alloc0_valid = 1'b0;
      alloc0_pdest = 6'd0;
      alloc1_valid = 1'b0;
      alloc1_pdest = 6'd0;
      wakeup0_valid = 1'b0;
      wakeup0_pdest = 6'd0;
      wakeup1_valid = 1'b0;
      wakeup1_pdest = 6'd0;
      query0_preg = 6'd0;
      query1_preg = 6'd0;
      query2_preg = 6'd0;
      query3_preg = 6'd0;
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

    query0_preg = 6'd0;
    query1_preg = 6'd32;
    #1;
    tb_check1("p0 ready after reset", query0_ready, 1'b1);
    tb_check1("p32 ready after reset", query1_ready, 1'b1);

    alloc0_valid = 1'b1;
    alloc0_pdest = 6'd32;
    alloc1_valid = 1'b1;
    alloc1_pdest = 6'd33;
    query0_preg = 6'd32;
    query1_preg = 6'd33;
    #1;
    tb_check1("alloc0 same-cycle busy", query0_ready, 1'b0);
    tb_check1("alloc1 same-cycle busy", query1_ready, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    query0_preg = 6'd32;
    query1_preg = 6'd33;
    #1;
    tb_check1("p32 stays busy", query0_ready, 1'b0);
    tb_check1("p33 stays busy", query1_ready, 1'b0);

    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd32;
    query0_preg = 6'd32;
    #1;
    tb_check1("wakeup same-cycle ready", query0_ready, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    query0_preg = 6'd32;
    #1;
    tb_check1("p32 ready after wakeup", query0_ready, 1'b1);

    // checkpoint capture/restore 场景已删（dead silicon，ROB-walk 取代）；
    // 净效果 = busy 状态回到 capture 前（p33 busy, p34 ready），此处直接保持该态。
    clear_inputs();

    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd33;
    alloc0_valid = 1'b1;
    alloc0_pdest = 6'd33;
    query0_preg = 6'd33;
    #1;
    tb_check1("alloc wins over wakeup", query0_ready, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    query0_preg = 6'd33;
    #1;
    tb_check1("p33 remains busy after alloc+wakeup", query0_ready, 1'b0);

    flush = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    query0_preg = 6'd33;
    #1;
    tb_check1("flush resets ready", query0_ready, 1'b1);

    tb_finish("tb_ooo_busy_table");
  end
endmodule
