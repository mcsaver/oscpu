`timescale 1ns/1ps
module tb_r64_data_terminal;
reg clk=0;always #5 clk=~clk;reg rst=1;integer cycle=0,sent=0,received=0;reg bad;
reg inv=0,req_valid=0;reg[63:0]request_va=0;
always @(negedge clk)begin inv=(cycle==15||cycle==32);req_valid=!rst&&sent<64&&cycle%4!=3;request_va=64'h80000000+sent*8;end
wire  req_ready_o0;
wire [3:0] rsp_protection_o0;
wire [64:0] rsp_last_o0;
wire [1:0] rsp_pma_class_o0;
wire  rsp_pma_fault_o0;
wire  rsp_valid_o0;
wire [1:0] rsp_priv_o0;
wire [63:0] rsp_paddr_o0;
wire [1:0] rsp_pbmt_o0;
wire  rsp_needs_ad_o0;
wire  rsp_fault_o0;
wire [4:0] rsp_cause_o0;
wire  mem_valid_o0;
wire  mem_compare_or_o0;
wire [55:0] mem_addr_o0;
wire [63:0] mem_expected_o0;
wire [63:0] mem_or_mask_o0;
wire  mem_rsp_ready_o0;
R64DataTranslation #(.RESERVED_TERMINAL(0)) dut0(.clk_i(clk),.rst_i(rst),.req_valid_i(req_valid),.req_ready_o(req_ready_o0),.req_protection_i(4'd3),.rsp_protection_o(rsp_protection_o0),.rsp_last_o(rsp_last_o0),.rsp_pma_class_o(rsp_pma_class_o0),.rsp_pma_fault_o(rsp_pma_fault_o0),.req_poison_i(1'b0),.req_vaddr_i(request_va),.req_access_i(2'd1),.req_priv_i(2'd3),.req_mstatus_i(64'b0),.req_satp_i(64'b0),.req_ad_update_i(1'b0),.req_pbmt_enable_i(1'b0),.rsp_valid_o(rsp_valid_o0),.rsp_ready_i(!bad),.rsp_priv_o(rsp_priv_o0),.rsp_paddr_o(rsp_paddr_o0),.rsp_pbmt_o(rsp_pbmt_o0),.rsp_needs_ad_o(rsp_needs_ad_o0),.rsp_fault_o(rsp_fault_o0),.rsp_cause_o(rsp_cause_o0),.invalidate_i(inv),.invalidate_all_vaddr_i(1'b1),.invalidate_all_asid_i(1'b1),.invalidate_vpn_i(27'b0),.invalidate_asid_i(16'b0),.mem_valid_o(mem_valid_o0),.mem_ready_i(1'b1),.mem_compare_or_o(mem_compare_or_o0),.mem_addr_o(mem_addr_o0),.mem_expected_o(mem_expected_o0),.mem_or_mask_o(mem_or_mask_o0),.mem_rsp_valid_i(1'b0),.mem_rsp_ready_o(mem_rsp_ready_o0),.mem_rdata_i(64'b0),.mem_error_i(1'b0),.mem_compare_ok_i(1'b0));
wire  req_ready_o1;
wire [3:0] rsp_protection_o1;
wire [64:0] rsp_last_o1;
wire [1:0] rsp_pma_class_o1;
wire  rsp_pma_fault_o1;
wire  rsp_valid_o1;
wire [1:0] rsp_priv_o1;
wire [63:0] rsp_paddr_o1;
wire [1:0] rsp_pbmt_o1;
wire  rsp_needs_ad_o1;
wire  rsp_fault_o1;
wire [4:0] rsp_cause_o1;
wire  mem_valid_o1;
wire  mem_compare_or_o1;
wire [55:0] mem_addr_o1;
wire [63:0] mem_expected_o1;
wire [63:0] mem_or_mask_o1;
wire  mem_rsp_ready_o1;
R64DataTranslation #(.RESERVED_TERMINAL(1)) dut1(.clk_i(clk),.rst_i(rst),.req_valid_i(req_valid),.req_ready_o(req_ready_o1),.req_protection_i(4'd3),.rsp_protection_o(rsp_protection_o1),.rsp_last_o(rsp_last_o1),.rsp_pma_class_o(rsp_pma_class_o1),.rsp_pma_fault_o(rsp_pma_fault_o1),.req_poison_i(1'b0),.req_vaddr_i(request_va),.req_access_i(2'd1),.req_priv_i(2'd3),.req_mstatus_i(64'b0),.req_satp_i(64'b0),.req_ad_update_i(1'b0),.req_pbmt_enable_i(1'b0),.rsp_valid_o(rsp_valid_o1),.rsp_ready_i(!bad),.rsp_priv_o(rsp_priv_o1),.rsp_paddr_o(rsp_paddr_o1),.rsp_pbmt_o(rsp_pbmt_o1),.rsp_needs_ad_o(rsp_needs_ad_o1),.rsp_fault_o(rsp_fault_o1),.rsp_cause_o(rsp_cause_o1),.invalidate_i(inv),.invalidate_all_vaddr_i(1'b1),.invalidate_all_asid_i(1'b1),.invalidate_vpn_i(27'b0),.invalidate_asid_i(16'b0),.mem_valid_o(mem_valid_o1),.mem_ready_i(1'b1),.mem_compare_or_o(mem_compare_or_o1),.mem_addr_o(mem_addr_o1),.mem_expected_o(mem_expected_o1),.mem_or_mask_o(mem_or_mask_o1),.mem_rsp_valid_i(1'b0),.mem_rsp_ready_o(mem_rsp_ready_o1),.mem_rdata_i(64'b0),.mem_error_i(1'b0),.mem_compare_ok_i(1'b0));
initial begin bad=$test$plusargs("bad-terminal");repeat(3)@(negedge clk);#1 rst=0;end
always @(posedge clk)if(!rst)begin
cycle=cycle+1;
if(!bad)begin
if(req_ready_o0!==req_ready_o1||rsp_valid_o0!==rsp_valid_o1)$fatal(1,"terminal visible handshake differs");
if(rsp_valid_o1)begin
if(rsp_paddr_o1!==64'h80000000+received*8||rsp_last_o1!==65'h80000007+received*8||rsp_fault_o1||rsp_pma_class_o1!=0||rsp_pma_fault_o1)$fatal(1,"terminal owner packet mismatch");
if(rsp_paddr_o0!==rsp_paddr_o1||rsp_last_o0!==rsp_last_o1||rsp_protection_o0!==rsp_protection_o1||rsp_priv_o0!==rsp_priv_o1||rsp_pbmt_o0!==rsp_pbmt_o1||rsp_needs_ad_o0!==rsp_needs_ad_o1||rsp_fault_o0!==rsp_fault_o1||rsp_cause_o0!==rsp_cause_o1||rsp_pma_class_o0!==rsp_pma_class_o1||rsp_pma_fault_o0!==rsp_pma_fault_o1)$fatal(1,"terminal 147-bit packet differs");
received=received+1;end end
if(mem_valid_o0||mem_valid_o1)$fatal(1,"bare terminal issued PTE transaction");
if(req_valid&&req_ready_o1)sent=sent+1;
if(received==64)begin $display("[PASS] tb_r64_data_terminal reserved 64 owners, default exact cycle/packet; invalidate boundaries");$finish;end
if(cycle==200)$fatal(1,"terminal progress timeout");
end
endmodule
