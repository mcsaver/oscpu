`timescale 1ns/1ps

module tb_miq_flush_drain_pop;
  reg clk = 1'b0;
  reg rst = 1'b1;
  reg flush = 1'b0;
  reg push = 1'b0;
  reg pop = 1'b0;
  wire head_valid;
  wire [1:0] head_kind;
  wire [2:0] count;
  wire empty;
  wire full;

  always #5 clk = ~clk;

  OooMemInflightQueue dut (
    .clk(clk), .rst(rst), .flush_i(flush),
    .push_valid_i(push), .push_kind_i(2'd2), .push_rob_idx_i(4'd3),
    .push_pdest_i(6'b0), .push_pdest_fp_i(1'b0), .push_size_i(2'd3),
    .push_unsigned_i(1'b0), .push_eff_addr_i(64'h8000_1000),
    .push_wdata_i(64'h55aa), .push_wstrb_i(8'hff),
    .pop_valid_i(pop), .kill_valid_i(1'b0), .kill_rob_idx_i(4'b0),
    .rob_head_idx_i(4'b0), .head_valid_o(head_valid),
    .head_kind_o(head_kind), .count_o(count), .empty_o(empty), .full_o(full)
  );

  initial begin
    repeat (2) @(posedge clk);
    #1 rst = 1'b0;

    push = 1'b1;
    @(posedge clk);
    #1 push = 1'b0;
    if (count != 3'd1 || !head_valid || head_kind != 2'd2) begin
      $display("SETUP_FAIL count=%0d valid=%0d kind=%0d", count, head_valid, head_kind);
      $finish_and_return(2);
    end

    // A nokill DRAIN response is consumed in exactly the cycle a global flush arrives.
    flush = 1'b1;
    pop = 1'b1;
    @(posedge clk);
    #1 flush = 1'b0;
    pop = 1'b0;

    repeat (3) @(posedge clk);
    #1;
    if (count == 3'd1 && head_valid && head_kind == 2'd2) begin
      $display("BUG_REPRODUCED ghost_drain count=%0d kind=%0d", count, head_kind);
      $finish_and_return(0);
    end

    $display("BUG_NOT_REPRODUCED count=%0d valid=%0d kind=%0d", count, head_valid, head_kind);
    $finish_and_return(1);
  end
endmodule
