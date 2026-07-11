`timescale 1ns/1ps

module tb_miq_full_pop;
  localparam ENTRY_N = 4;
  localparam ENTRY_W = 2;
  localparam ROB_W = 4;
  localparam PREG_W = 6;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg flush = 1'b0;
  reg push_valid = 1'b0;
  reg [1:0] push_kind = 2'd0;
  reg [ROB_W-1:0] push_rob = 0;
  reg [PREG_W-1:0] push_pdest = 0;
  reg push_pdest_fp = 1'b0;
  reg [1:0] push_size = 2'd3;
  reg push_unsigned = 1'b0;
  reg [63:0] push_addr = 0;
  reg [63:0] push_wdata = 0;
  reg [7:0] push_wstrb = 0;
  reg pop_valid = 1'b0;
  reg kill_valid = 1'b0;
  reg [ROB_W-1:0] kill_rob = 0;
  reg [ROB_W-1:0] rob_head = 0;

  wire head_valid;
  wire [1:0] head_kind;
  wire head_killed;
  wire [ROB_W-1:0] head_rob;
  wire [PREG_W-1:0] head_pdest;
  wire head_pdest_fp;
  wire [1:0] head_size;
  wire head_unsigned;
  wire [63:0] head_addr;
  wire [63:0] head_wdata;
  wire [7:0] head_wstrb;
  wire [ENTRY_W:0] count;
  wire empty;
  wire full;
  wire [ENTRY_N-1:0] entry_valid;
  wire [ENTRY_N*2-1:0] entry_kind;
  wire [ENTRY_N*ROB_W-1:0] entry_rob;
  wire [ENTRY_N*64-1:0] entry_addr;

  always #5 clk = ~clk;

  OooMemInflightQueue #(
    .ENTRY_N(ENTRY_N),
    .ENTRY_W(ENTRY_W),
    .ROB_INDEX_W(ROB_W),
    .PHY_REG_ADDR_W(PREG_W)
  ) dut (
    .clk(clk), .rst(rst), .flush_i(flush),
    .push_valid_i(push_valid), .push_kind_i(push_kind),
    .push_rob_idx_i(push_rob), .push_pdest_i(push_pdest),
    .push_pdest_fp_i(push_pdest_fp), .push_size_i(push_size),
    .push_unsigned_i(push_unsigned), .push_eff_addr_i(push_addr),
    .push_wdata_i(push_wdata), .push_wstrb_i(push_wstrb),
    .pop_valid_i(pop_valid), .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob), .rob_head_idx_i(rob_head),
    .head_valid_o(head_valid), .head_kind_o(head_kind),
    .head_killed_o(head_killed), .head_rob_idx_o(head_rob),
    .head_pdest_o(head_pdest), .head_pdest_fp_o(head_pdest_fp),
    .head_size_o(head_size), .head_unsigned_o(head_unsigned),
    .head_eff_addr_o(head_addr), .head_wdata_o(head_wdata),
    .head_wstrb_o(head_wstrb), .count_o(count), .empty_o(empty),
    .full_o(full), .entry_valid_o(entry_valid), .entry_kind_o(entry_kind),
    .entry_rob_idx_o(entry_rob), .entry_addr_o(entry_addr)
  );

  task push_one;
    input [ROB_W-1:0] rob;
    begin
      push_rob = rob;
      push_addr = 64'h1000 + (rob << 3);
      push_valid = 1'b1;
      @(posedge clk);
      #1;
      push_valid = 1'b0;
    end
  endtask

  initial begin
    repeat (2) @(posedge clk);
    #1 rst = 1'b0;

    push_one(4'd1);
    push_one(4'd2);
    push_one(4'd3);
    push_one(4'd4);
    if (!full || count != 5'd4 || head_rob != 4'd1) begin
      $display("SETUP_FAIL full=%0d count=%0d head=%0d", full, count, head_rob);
      $finish_and_return(2);
    end

    // This is the exact contract the parent advertises as slot-open:
    // full queue, old response pops, new accepted request pushes in the same cycle.
    push_rob = 4'd5;
    push_addr = 64'h1028;
    push_valid = 1'b1;
    pop_valid = 1'b1;
    @(posedge clk);
    #1;
    push_valid = 1'b0;
    pop_valid = 1'b0;

    if (count == 5'd3 && head_rob == 4'd2) begin
      $display("BUG_REPRODUCED count=%0d head=%0d new_rob5_not_accounted", count, head_rob);
      $finish_and_return(0);
    end

    $display("BUG_NOT_REPRODUCED count=%0d head=%0d full=%0d", count, head_rob, full);
    $finish_and_return(1);
  end
endmodule
