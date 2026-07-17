`timescale 1ns/1ps
`include "define.v"

module tb_s2_g1_miq_mismatch_drain #(
  parameter MUTATION = 1
);
  reg clk;
  reg rst;
  reg flush;
  reg push_valid;
  reg pop_valid;
  reg [1:0] pop_owner_kind;
  reg [4:0] pop_owner_token;
  reg [1:0] pop_mmu_epoch;
  reg [`XLEN-1:0] pop_fault_tval;
  wire pop_owner_match;
  wire pop_tval_echo_match;
  wire [2:0] count;
  wire head_valid;
  wire [1:0] head_owner_kind;
  wire [4:0] head_owner_token;
  wire [1:0] head_mmu_epoch;
  wire [63:0] head_fault_tval;
  wire [31:0] occupancy_token_mask;

  OooMemInflightQueue dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .push_valid_i(push_valid),
    .push_kind_i(2'd0),
    .push_owner_kind_i(2'b00),
    .push_owner_token_i(5'd3),
    .push_mmu_epoch_i(2'b10),
    .push_fault_tval_i(64'h0000_0000_8123_4567),
    .push_rob_idx_i(4'd9),
    .push_pdest_i(6'd12),
    .push_pdest_fp_i(1'b0),
    .push_size_i(2'd3),
    .push_unsigned_i(1'b0),
    .push_eff_addr_i(64'h0000_0000_8123_4567),
    .push_wdata_i(64'b0),
    .push_wstrb_i(8'b0),
    .pop_valid_i(pop_valid),
    .pop_owner_kind_i(pop_owner_kind),
    .pop_owner_token_i(pop_owner_token),
    .pop_mmu_epoch_i(pop_mmu_epoch),
    .pop_fault_tval_i(pop_fault_tval),
    .pop_owner_match_o(pop_owner_match),
    .pop_tval_echo_match_o(pop_tval_echo_match),
    .kill_valid_i(1'b0),
    .kill_rob_idx_i(4'b0),
    .rob_head_idx_i(4'b0),
    .head_valid_o(head_valid),
    .head_owner_kind_o(head_owner_kind),
    .head_owner_token_o(head_owner_token),
    .head_mmu_epoch_o(head_mmu_epoch),
    .head_fault_tval_o(head_fault_tval),
    .occupancy_token_mask_o(occupancy_token_mask),
    .count_o(count)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    flush = 1'b0;
    push_valid = 1'b0;
    pop_valid = 1'b0;
    pop_owner_kind = 2'b00;
    pop_owner_token = 5'd3;
    pop_mmu_epoch = 2'b10;
    pop_fault_tval = 64'h0000_0000_8123_4567;
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    push_valid = 1'b1;
    @(posedge clk);
    @(negedge clk);
    push_valid = 1'b0;
    if (MUTATION == 1)
      pop_owner_kind = 2'b01;
    else if (MUTATION == 2)
      pop_owner_token = 5'd4;
    else if (MUTATION == 3)
      pop_mmu_epoch = 2'b11;
    else
      pop_fault_tval = 64'h0000_0000_8123_4566;
    pop_valid = 1'b1;
    #1;
    if ((MUTATION <= 3) && pop_owner_match) begin
      $display("[S2-G1-MIQ-MISMATCH][FAIL] identity mutation %0d matched", MUTATION);
      $fatal(1);
    end
    if ((MUTATION == 4) && (!pop_owner_match || pop_tval_echo_match)) begin
      $display("[S2-G1-MIQ-MISMATCH][FAIL] tval drift changed identity or escaped echo check");
      $fatal(1);
    end
    if (head_fault_tval != 64'h0000_0000_8123_4567) begin
      $display("[S2-G1-MIQ-MISMATCH][FAIL] response echo replaced captured tval");
      $fatal(1);
    end
    @(posedge clk);
    #1;
    if (MUTATION <= 3) begin
      if (count != 3'd1 || !head_valid || head_owner_kind != 2'b00 ||
          head_owner_token != 5'd3 || head_mmu_epoch != 2'b10 ||
          head_fault_tval != 64'h0000_0000_8123_4567 ||
          occupancy_token_mask != 32'h0000_0008) begin
        $display("[S2-G1-MIQ-MISMATCH][FAIL] mutation %0d changed retained owner", MUTATION);
        $fatal(1);
      end
      $display("[S2-G1-MIQ-MISMATCH][PASS] identity mutation %0d retained owner", MUTATION);
    end else begin
      if (count != 3'd0 || head_valid || occupancy_token_mask != 32'h0) begin
        $display("[S2-G1-MIQ-MISMATCH][FAIL] tval-only drift blocked exact identity completion");
        $fatal(1);
      end
      $display("[S2-G1-MIQ-TVAL][PASS] tval drift consumed 9-bit owner with captured provenance");
    end
    $finish;
  end
endmodule
