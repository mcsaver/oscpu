`timescale 1ns/1ps

module tb_s2_g1_miq_owner_ports;
  reg clk;
  reg rst;
  reg [1:0] push_owner_kind;
  reg [4:0] push_owner_token;
  reg [1:0] push_mmu_epoch;
  reg [63:0] push_fault_tval;
  reg [1:0] pop_owner_kind;
  reg [4:0] pop_owner_token;
  reg [1:0] pop_mmu_epoch;
  reg [63:0] pop_fault_tval;
  wire pop_owner_match;
  wire pop_tval_echo_match;
  wire [1:0] head_owner_kind;
  wire [4:0] head_owner_token;
  wire [1:0] head_mmu_epoch;
  wire [63:0] head_fault_tval;
  wire [31:0] occupancy_token_mask;

  OooMemInflightQueue dut (
    .clk(clk),
    .rst(rst),
    .push_owner_kind_i(push_owner_kind),
    .push_owner_token_i(push_owner_token),
    .push_mmu_epoch_i(push_mmu_epoch),
    .push_fault_tval_i(push_fault_tval),
    .pop_owner_kind_i(pop_owner_kind),
    .pop_owner_token_i(pop_owner_token),
    .pop_mmu_epoch_i(pop_mmu_epoch),
    .pop_fault_tval_i(pop_fault_tval),
    .pop_owner_match_o(pop_owner_match),
    .pop_tval_echo_match_o(pop_tval_echo_match),
    .head_owner_kind_o(head_owner_kind),
    .head_owner_token_o(head_owner_token),
    .head_mmu_epoch_o(head_mmu_epoch),
    .head_fault_tval_o(head_fault_tval),
    .occupancy_token_mask_o(occupancy_token_mask)
  );

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    push_owner_kind = 2'b01;
    push_owner_token = 5'd7;
    push_mmu_epoch = 2'b10;
    push_fault_tval = 64'h1000;
    pop_owner_kind = 2'b01;
    pop_owner_token = 5'd7;
    pop_mmu_epoch = 2'b10;
    pop_fault_tval = 64'h1000;
    #1;
    $display("[S2-G1-MIQ][PASS] exact-owner ABI elaborated");
    $finish;
  end
endmodule
