`timescale 1ns/1ps

module tb_s2_g1_bridge_owner_ports;
  reg clk;
  reg rst;
  reg [1:0] req_owner_kind;
  reg [4:0] req_owner_token;
  reg [1:0] req_mmu_epoch;
  reg [63:0] req_fault_tval;
  wire [1:0] rsp_owner_kind;
  wire [4:0] rsp_owner_token;
  wire [1:0] rsp_mmu_epoch;
  wire [63:0] rsp_fault_tval;
  wire drop0_valid;
  wire [1:0] drop0_owner_kind;
  wire [4:0] drop0_owner_token;
  wire [1:0] drop0_mmu_epoch;
  wire [63:0] drop0_fault_tval;
  wire drop1_valid;
  wire [1:0] drop1_owner_kind;
  wire [4:0] drop1_owner_token;
  wire [1:0] drop1_mmu_epoch;
  wire [63:0] drop1_fault_tval;

  OooMemAxiBridge dut (
    .clk(clk),
    .rst(rst),
    .mem0_req_owner_kind_i(req_owner_kind),
    .mem0_req_owner_token_i(req_owner_token),
    .mem0_req_mmu_epoch_i(req_mmu_epoch),
    .mem0_req_fault_tval_i(req_fault_tval),
    .mem0_rsp_owner_kind_o(rsp_owner_kind),
    .mem0_rsp_owner_token_o(rsp_owner_token),
    .mem0_rsp_mmu_epoch_o(rsp_mmu_epoch),
    .mem0_rsp_fault_tval_o(rsp_fault_tval),
    .mem0_drop0_valid_o(drop0_valid),
    .mem0_drop0_owner_kind_o(drop0_owner_kind),
    .mem0_drop0_owner_token_o(drop0_owner_token),
    .mem0_drop0_mmu_epoch_o(drop0_mmu_epoch),
    .mem0_drop0_fault_tval_o(drop0_fault_tval),
    .mem0_drop1_valid_o(drop1_valid),
    .mem0_drop1_owner_kind_o(drop1_owner_kind),
    .mem0_drop1_owner_token_o(drop1_owner_token),
    .mem0_drop1_mmu_epoch_o(drop1_mmu_epoch),
    .mem0_drop1_fault_tval_o(drop1_fault_tval)
  );

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    req_owner_kind = 2'b00;
    req_owner_token = 5'd3;
    req_mmu_epoch = 2'b11;
    req_fault_tval = 64'h3000;
    #1;
    $display("[S2-G1-BRIDGE][PASS] station/active/rsp/drop owner ABI elaborated");
    $finish;
  end
endmodule
