`timescale 1ns/1ps

module tb_s2_g1_sq_owner_ports;
  reg clk;
  reg rst;
  reg owner_bind_valid;
  reg [3:0] owner_bind_rob_idx;
  reg [1:0] owner_bind_kind;
  reg [4:0] owner_bind_token;
  reg [1:0] owner_bind_mmu_epoch;
  reg [63:0] owner_bind_fault_tval;
  reg [1:0] fill0_owner_kind;
  reg [4:0] fill0_owner_token;
  reg [1:0] fill0_mmu_epoch;
  reg [1:0] terminal_owner_kind;
  reg [4:0] terminal_owner_token;
  reg [1:0] terminal_mmu_epoch;
  reg [1:0] terminal1_owner_kind;
  reg [4:0] terminal1_owner_token;
  reg [1:0] terminal1_mmu_epoch;
  wire [1:0] req_owner_kind;
  wire [4:0] req_owner_token;
  wire [1:0] req_mmu_epoch;
  wire [63:0] req_fault_tval;
  wire [31:0] owner_release_mask;

  OooStoreQueue dut (
    .clk(clk),
    .rst(rst),
    .owner_bind_valid_i(owner_bind_valid),
    .owner_bind_rob_idx_i(owner_bind_rob_idx),
    .owner_bind_kind_i(owner_bind_kind),
    .owner_bind_token_i(owner_bind_token),
    .owner_bind_mmu_epoch_i(owner_bind_mmu_epoch),
    .owner_bind_fault_tval_i(owner_bind_fault_tval),
    .fill0_owner_kind_i(fill0_owner_kind),
    .fill0_owner_token_i(fill0_owner_token),
    .fill0_mmu_epoch_i(fill0_mmu_epoch),
    .terminal_owner_kind_i(terminal_owner_kind),
    .terminal_owner_token_i(terminal_owner_token),
    .terminal_mmu_epoch_i(terminal_mmu_epoch),
    .terminal1_owner_kind_i(terminal1_owner_kind),
    .terminal1_owner_token_i(terminal1_owner_token),
    .terminal1_mmu_epoch_i(terminal1_mmu_epoch),
    .req_owner_kind_o(req_owner_kind),
    .req_owner_token_o(req_owner_token),
    .req_mmu_epoch_o(req_mmu_epoch),
    .req_fault_tval_o(req_fault_tval),
    .owner_release_mask_o(owner_release_mask)
  );

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    owner_bind_valid = 1'b0;
    owner_bind_rob_idx = 4'd0;
    owner_bind_kind = 2'b01;
    owner_bind_token = 5'd9;
    owner_bind_mmu_epoch = 2'b01;
    owner_bind_fault_tval = 64'h2000;
    fill0_owner_kind = 2'b01;
    fill0_owner_token = 5'd9;
    fill0_mmu_epoch = 2'b01;
    terminal_owner_kind = 2'b01;
    terminal_owner_token = 5'd9;
    terminal_mmu_epoch = 2'b01;
    terminal1_owner_kind = 2'b01;
    terminal1_owner_token = 5'd9;
    terminal1_mmu_epoch = 2'b01;
    #1;
    $display("[S2-G1-SQ][PASS] bind/fill/terminal owner ABI elaborated");
    $finish;
  end
endmodule
