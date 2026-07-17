`timescale 1ns/1ps
`include "define.v"

module tb_s2_g1_miq_protocol_negative #(
  parameter CASE_ID = 0
);
  reg clk;
  reg rst;
  reg push_valid;
  reg [1:0] push_kind;
  reg [1:0] push_owner_kind;
  reg pop_valid;

  OooMemInflightQueue dut (
    .clk(clk),
    .rst(rst),
    .flush_i(1'b0),
    .push_valid_i(push_valid),
    .push_kind_i(push_kind),
    .push_owner_kind_i(push_owner_kind),
    .push_owner_token_i(5'd3),
    .push_mmu_epoch_i(2'b01),
    .push_fault_tval_i(64'h4000),
    .push_rob_idx_i(4'd3),
    .push_pdest_i(6'd1),
    .push_pdest_fp_i(1'b0),
    .push_size_i(2'd3),
    .push_unsigned_i(1'b0),
    .push_eff_addr_i(64'h4000),
    .push_wdata_i(64'b0),
    .push_wstrb_i(8'b0),
    .pop_valid_i(pop_valid),
    .pop_owner_kind_i(2'b00),
    .pop_owner_token_i(5'd3),
    .pop_mmu_epoch_i(2'b01),
    .pop_fault_tval_i(64'h4000),
    .kill_valid_i(1'b0),
    .kill_rob_idx_i(4'b0),
    .rob_head_idx_i(4'b0)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    push_valid = 1'b0;
    push_kind = 2'd0;
    push_owner_kind = 2'b00;
    pop_valid = 1'b0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    if (CASE_ID == 0) begin
      pop_valid = 1'b1;
      @(posedge clk);
    end else if (CASE_ID == 1) begin
      push_owner_kind = 2'b11;
      push_valid = 1'b1;
      @(posedge clk);
    end else if (CASE_ID == 4) begin
      push_owner_kind = 2'b01;
      push_valid = 1'b1;
      @(posedge clk);
    end else begin
      push_valid = 1'b1;
      @(posedge clk);
      @(negedge clk);
      if (CASE_ID == 3)
        pop_valid = 1'b1;
      @(posedge clk);
    end

    #1;
    $display("[S2-G1-MIQ-PROTOCOL][FAIL] case=%0d did not trigger assertion", CASE_ID);
    $fatal(1);
  end
endmodule
